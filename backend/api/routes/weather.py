"""
AgriSense Pro - Weather Routes
Weather data and farming advisories
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime, date, timedelta
import httpx
import json

from models.schemas import WeatherResponse, WeatherForecastResponse, FarmingAdvisory
from api.routes.auth import get_current_user
from core.config import settings
from db.database import db, generate_uuid, now_iso

router = APIRouter(prefix="/weather", tags=["Weather"])


@router.get("/current", response_model=WeatherResponse)
async def get_current_weather(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    current_user: dict = Depends(get_current_user)
):
    """
    Get current weather for specified coordinates.
    Uses OpenWeatherMap API with caching.
    """
    # Check cache first
    cached = db.fetch_one("""
        SELECT * FROM weather_data 
        WHERE latitude = ? AND longitude = ? AND is_forecast = 0
        AND created_at > datetime('now', '-30 minutes')
        ORDER BY created_at DESC LIMIT 1
    """, (round(latitude, 4), round(longitude, 4)))
    
    if cached:
        return _format_weather_response(cached)
    
    # Fetch from API
    weather_data = await _fetch_current_weather(latitude, longitude)
    
    # Cache the result
    _cache_weather_data(weather_data, None, latitude, longitude, False)
    
    return weather_data


@router.get("/forecast", response_model=List[WeatherForecastResponse])
async def get_weather_forecast(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    days: int = Query(7, ge=1, le=14),
    current_user: dict = Depends(get_current_user)
):
    """
    Get weather forecast for specified coordinates.
    """
    # Check cache first
    cached = db.fetch_all("""
        SELECT * FROM weather_data 
        WHERE latitude = ? AND longitude = ? AND is_forecast = 1
        AND created_at > datetime('now', '-6 hours')
        ORDER BY forecast_date
        LIMIT ?
    """, (round(latitude, 4), round(longitude, 4), days))
    
    if len(cached) >= days:
        return [_format_forecast_response(c) for c in cached[:days]]
    
    # Fetch from API
    forecast_data = await _fetch_forecast(latitude, longitude, days)
    
    return forecast_data


@router.get("/farm/{farm_id}")
async def get_farm_weather(
    farm_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get weather for a specific farm.
    """
    farm = db.fetch_one(
        "SELECT * FROM farms WHERE id = ? AND user_id = ?",
        (farm_id, current_user["id"])
    )
    
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    if not farm.get("latitude") or not farm.get("longitude"):
        raise HTTPException(
            status_code=400,
            detail="Farm location not set. Please update farm coordinates."
        )
    
    current = await get_current_weather(
        farm["latitude"],
        farm["longitude"],
        current_user
    )
    
    forecast = await get_weather_forecast(
        farm["latitude"],
        farm["longitude"],
        7,
        current_user
    )
    
    advisories = _generate_farming_advisories(current, forecast)
    
    return {
        "farm_id": farm_id,
        "farm_name": farm["name"],
        "current": current,
        "forecast": forecast,
        "advisories": advisories
    }


@router.get("/advisories")
async def get_farming_advisories(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    current_user: dict = Depends(get_current_user)
):
    """
    Get farming advisories based on weather conditions.
    """
    current = await get_current_weather(latitude, longitude, current_user)
    forecast = await get_weather_forecast(latitude, longitude, 3, current_user)
    
    advisories = _generate_farming_advisories(current, forecast)
    
    return {"advisories": advisories}


async def _fetch_current_weather(lat: float, lon: float) -> WeatherResponse:
    """
    Fetch current weather from OpenWeatherMap API.
    Falls back to simulated data if API key not configured.
    """
    api_key = settings.OPENWEATHERMAP_API_KEY
    
    if api_key and api_key != "YOUR_OPENWEATHERMAP_API_KEY_HERE":
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://api.openweathermap.org/data/2.5/weather",
                    params={
                        "lat": lat,
                        "lon": lon,
                        "appid": api_key,
                        "units": "metric"
                    },
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return WeatherResponse(
                        latitude=lat,
                        longitude=lon,
                        recorded_at=datetime.utcnow(),
                        temperature_celsius=data["main"]["temp"],
                        feels_like_celsius=data["main"]["feels_like"],
                        humidity_percent=data["main"]["humidity"],
                        pressure_hpa=data["main"]["pressure"],
                        wind_speed_kmh=data["wind"]["speed"] * 3.6,  # m/s to km/h
                        wind_direction_deg=data["wind"].get("deg", 0),
                        visibility_km=data.get("visibility", 10000) / 1000,
                        uv_index=0,  # Not in basic API
                        rain_mm=data.get("rain", {}).get("1h", 0),
                        weather_description=data["weather"][0]["description"],
                        icon_code=data["weather"][0]["icon"]
                    )
        except Exception as e:
            print(f"Weather API error: {e}")
    
    # Fallback to simulated data
    return _simulate_weather(lat, lon)


async def _fetch_forecast(lat: float, lon: float, days: int) -> List[WeatherForecastResponse]:
    """
    Fetch weather forecast from OpenWeatherMap API.
    """
    api_key = settings.OPENWEATHERMAP_API_KEY
    
    if api_key and api_key != "YOUR_OPENWEATHERMAP_API_KEY_HERE":
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    "https://api.openweathermap.org/data/2.5/forecast",
                    params={
                        "lat": lat,
                        "lon": lon,
                        "appid": api_key,
                        "units": "metric",
                        "cnt": days * 8  # 3-hour intervals
                    },
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    data = response.json()
                    
                    # Group by day
                    daily = {}
                    for item in data["list"]:
                        dt = datetime.fromtimestamp(item["dt"])
                        day_key = dt.date().isoformat()
                        
                        if day_key not in daily:
                            daily[day_key] = {
                                "temps": [],
                                "humidity": [],
                                "rain": 0,
                                "description": item["weather"][0]["description"],
                                "icon": item["weather"][0]["icon"],
                                "wind": []
                            }
                        
                        daily[day_key]["temps"].append(item["main"]["temp"])
                        daily[day_key]["humidity"].append(item["main"]["humidity"])
                        daily[day_key]["rain"] += item.get("rain", {}).get("3h", 0)
                        daily[day_key]["wind"].append(item["wind"]["speed"])
                    
                    forecasts = []
                    for day_str, day_data in list(daily.items())[:days]:
                        forecasts.append(WeatherForecastResponse(
                            date=date.fromisoformat(day_str),
                            temp_min=min(day_data["temps"]),
                            temp_max=max(day_data["temps"]),
                            humidity=int(sum(day_data["humidity"]) / len(day_data["humidity"])),
                            rain_chance=min(100, int(day_data["rain"] * 10)),
                            weather_description=day_data["description"],
                            icon_code=day_data["icon"],
                            wind_speed=sum(day_data["wind"]) / len(day_data["wind"]) * 3.6,
                            uv_index=5.0  # Not in basic API
                        ))
                    
                    return forecasts
        except Exception as e:
            print(f"Forecast API error: {e}")
    
    # Fallback to simulated forecast
    return _simulate_forecast(lat, lon, days)


def _simulate_weather(lat: float, lon: float) -> WeatherResponse:
    """Generate simulated weather data for demo."""
    import random
    
    # Base temperature on latitude (rough approximation)
    base_temp = 30 - abs(lat - 20) * 0.5
    temp = base_temp + random.uniform(-5, 5)
    
    return WeatherResponse(
        latitude=lat,
        longitude=lon,
        recorded_at=datetime.utcnow(),
        temperature_celsius=round(temp, 1),
        feels_like_celsius=round(temp + random.uniform(-2, 3), 1),
        humidity_percent=random.randint(40, 85),
        pressure_hpa=round(random.uniform(1000, 1020), 1),
        wind_speed_kmh=round(random.uniform(5, 25), 1),
        wind_direction_deg=random.randint(0, 360),
        visibility_km=round(random.uniform(5, 15), 1),
        uv_index=round(random.uniform(3, 10), 1),
        rain_mm=random.choice([0, 0, 0, 0.5, 1, 2, 5]),
        weather_description=random.choice([
            "Clear sky", "Partly cloudy", "Cloudy", 
            "Light rain", "Sunny", "Haze"
        ]),
        icon_code=random.choice(["01d", "02d", "03d", "04d", "10d"])
    )


def _simulate_forecast(lat: float, lon: float, days: int) -> List[WeatherForecastResponse]:
    """Generate simulated forecast data for demo."""
    import random
    
    forecasts = []
    base_temp = 30 - abs(lat - 20) * 0.5
    
    for i in range(days):
        forecast_date = date.today() + timedelta(days=i)
        temp_var = random.uniform(-3, 3)
        
        forecasts.append(WeatherForecastResponse(
            date=forecast_date,
            temp_min=round(base_temp + temp_var - 5, 1),
            temp_max=round(base_temp + temp_var + 5, 1),
            humidity=random.randint(45, 80),
            rain_chance=random.randint(0, 70),
            weather_description=random.choice([
                "Sunny", "Partly cloudy", "Cloudy", "Light rain", "Clear"
            ]),
            icon_code=random.choice(["01d", "02d", "03d", "04d", "10d"]),
            wind_speed=round(random.uniform(8, 20), 1),
            uv_index=round(random.uniform(4, 9), 1)
        ))
    
    return forecasts


def _cache_weather_data(
    weather: WeatherResponse,
    farm_id: Optional[str],
    lat: float,
    lon: float,
    is_forecast: bool
):
    """Cache weather data to database."""
    db.execute("""
        INSERT INTO weather_data (
            id, farm_id, latitude, longitude, recorded_at,
            temperature_celsius, feels_like_celsius, humidity_percent,
            pressure_hpa, wind_speed_kmh, wind_direction_deg,
            visibility_km, uv_index, rain_mm,
            weather_description, icon_code, is_forecast, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        generate_uuid(),
        farm_id,
        round(lat, 4),
        round(lon, 4),
        weather.recorded_at.isoformat(),
        weather.temperature_celsius,
        weather.feels_like_celsius,
        weather.humidity_percent,
        weather.pressure_hpa,
        weather.wind_speed_kmh,
        weather.wind_direction_deg,
        weather.visibility_km,
        weather.uv_index,
        weather.rain_mm,
        weather.weather_description,
        weather.icon_code,
        1 if is_forecast else 0,
        now_iso()
    ))


def _format_weather_response(data: dict) -> WeatherResponse:
    """Format database row to WeatherResponse."""
    return WeatherResponse(
        latitude=data["latitude"],
        longitude=data["longitude"],
        recorded_at=datetime.fromisoformat(data["recorded_at"]),
        temperature_celsius=data.get("temperature_celsius"),
        feels_like_celsius=data.get("feels_like_celsius"),
        humidity_percent=data.get("humidity_percent"),
        pressure_hpa=data.get("pressure_hpa"),
        wind_speed_kmh=data.get("wind_speed_kmh"),
        wind_direction_deg=data.get("wind_direction_deg"),
        visibility_km=data.get("visibility_km"),
        uv_index=data.get("uv_index"),
        rain_mm=data.get("rain_mm", 0),
        weather_description=data.get("weather_description"),
        icon_code=data.get("icon_code")
    )


def _format_forecast_response(data: dict) -> WeatherForecastResponse:
    """Format database row to WeatherForecastResponse."""
    return WeatherForecastResponse(
        date=date.fromisoformat(data["forecast_date"]),
        temp_min=data.get("temperature_celsius", 20) - 5,
        temp_max=data.get("temperature_celsius", 20) + 5,
        humidity=data.get("humidity_percent", 60),
        rain_chance=min(100, int(data.get("rain_mm", 0) * 10)),
        weather_description=data.get("weather_description", "Clear"),
        icon_code=data.get("icon_code", "01d"),
        wind_speed=data.get("wind_speed_kmh", 10),
        uv_index=data.get("uv_index", 5)
    )


def _generate_farming_advisories(
    current: WeatherResponse,
    forecast: List[WeatherForecastResponse]
) -> List[FarmingAdvisory]:
    """Generate farming advisories based on weather conditions."""
    advisories = []
    
    # Temperature advisories
    if current.temperature_celsius and current.temperature_celsius > 35:
        advisories.append(FarmingAdvisory(
            title="Heat Alert",
            description="High temperature detected. Increase irrigation frequency and consider shade nets for sensitive crops.",
            priority="high",
            category="irrigation",
            icon="thermostat"
        ))
    elif current.temperature_celsius and current.temperature_celsius < 10:
        advisories.append(FarmingAdvisory(
            title="Cold Weather Alert",
            description="Low temperature expected. Protect frost-sensitive crops with mulching or covers.",
            priority="high",
            category="protection",
            icon="ac_unit"
        ))
    
    # Rain advisories
    if current.rain_mm and current.rain_mm > 20:
        advisories.append(FarmingAdvisory(
            title="Heavy Rainfall",
            description="Delay irrigation. Check drainage systems and avoid pesticide application.",
            priority="high",
            category="irrigation",
            icon="water_drop"
        ))
    
    # Forecast-based advisories
    rain_days = sum(1 for f in forecast if f.rain_chance > 60)
    if rain_days >= 3:
        advisories.append(FarmingAdvisory(
            title="Rainy Period Ahead",
            description=f"Rain expected for {rain_days} days. Complete harvesting of mature crops and delay new plantings.",
            priority="medium",
            category="harvest",
            icon="thunderstorm"
        ))
    elif rain_days == 0 and len(forecast) >= 5:
        advisories.append(FarmingAdvisory(
            title="Dry Spell Expected",
            description="No rain expected in the coming days. Ensure adequate irrigation scheduling.",
            priority="medium",
            category="irrigation",
            icon="wb_sunny"
        ))
    
    # Humidity advisories
    if current.humidity_percent and current.humidity_percent > 85:
        advisories.append(FarmingAdvisory(
            title="High Humidity Alert",
            description="Increased risk of fungal diseases. Monitor crops closely and ensure proper ventilation.",
            priority="medium",
            category="pest",
            icon="water"
        ))
    
    # Wind advisories
    if current.wind_speed_kmh and current.wind_speed_kmh > 40:
        advisories.append(FarmingAdvisory(
            title="Strong Wind Warning",
            description="High winds detected. Secure shade structures and delay spraying operations.",
            priority="high",
            category="protection",
            icon="air"
        ))
    
    # UV advisories
    if current.uv_index and current.uv_index > 8:
        advisories.append(FarmingAdvisory(
            title="High UV Index",
            description="Extreme UV levels. Avoid field work during peak hours (11am-3pm). Use sun protection.",
            priority="medium",
            category="safety",
            icon="brightness_7"
        ))
    
    # Default positive advisory
    if not advisories:
        advisories.append(FarmingAdvisory(
            title="Good Farming Conditions",
            description="Weather conditions are favorable for most farming activities. Proceed with regular operations.",
            priority="low",
            category="general",
            icon="check_circle"
        ))
    
    return advisories
