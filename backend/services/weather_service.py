"""
AgriSense Pro - Weather Service
Handles weather data fetching, caching, and farm advisories
"""

import httpx
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List, Tuple
import json

from core.config import settings
from db.database import db, generate_uuid, now_iso


class WeatherService:
    """Weather service for farm weather data and advisories"""
    
    def __init__(self):
        self.api_key = settings.OPENWEATHERMAP_API_KEY
        self.weather_api_key = settings.WEATHERAPI_KEY
        self.base_url = "https://api.openweathermap.org/data/2.5"
        self.cache_ttl = settings.WEATHER_CACHE_TTL
    
    # =========================================================================
    # CURRENT WEATHER
    # =========================================================================
    
    async def get_current_weather(
        self,
        latitude: float,
        longitude: float
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Get current weather for a location.
        
        Returns:
            Tuple of (success: bool, weather_data: Dict)
        """
        # Check cache first
        cached = self._get_cached_weather(latitude, longitude, is_forecast=False)
        if cached:
            return True, cached
        
        # Check if we have a valid API key
        if self.api_key == "YOUR_OPENWEATHERMAP_API_KEY_HERE":
            # Return mock data for development
            return True, self._get_mock_weather(latitude, longitude)
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/weather",
                    params={
                        "lat": latitude,
                        "lon": longitude,
                        "appid": self.api_key,
                        "units": "metric"
                    },
                    timeout=10.0
                )
                
                if response.status_code != 200:
                    return False, {"error": f"Weather API error: {response.status_code}"}
                
                data = response.json()
                
                weather = {
                    "latitude": latitude,
                    "longitude": longitude,
                    "recorded_at": datetime.utcnow().isoformat(),
                    "temperature_celsius": data.get("main", {}).get("temp"),
                    "feels_like_celsius": data.get("main", {}).get("feels_like"),
                    "humidity_percent": data.get("main", {}).get("humidity"),
                    "pressure_hpa": data.get("main", {}).get("pressure"),
                    "wind_speed_kmh": (data.get("wind", {}).get("speed", 0) * 3.6),  # m/s to km/h
                    "wind_direction_deg": data.get("wind", {}).get("deg"),
                    "visibility_km": (data.get("visibility", 10000) / 1000),
                    "rain_mm": data.get("rain", {}).get("1h", 0),
                    "weather_description": data.get("weather", [{}])[0].get("description", "").title(),
                    "icon_code": data.get("weather", [{}])[0].get("icon"),
                }
                
                # Cache the result
                self._cache_weather(weather, is_forecast=False)
                
                return True, weather
                
        except Exception as e:
            return False, {"error": str(e)}
    
    # =========================================================================
    # WEATHER FORECAST
    # =========================================================================
    
    async def get_weather_forecast(
        self,
        latitude: float,
        longitude: float,
        days: int = 7
    ) -> Tuple[bool, List[Dict[str, Any]]]:
        """
        Get weather forecast for a location.
        
        Returns:
            Tuple of (success: bool, forecast_list: List[Dict])
        """
        # Check if we have a valid API key
        if self.api_key == "YOUR_OPENWEATHERMAP_API_KEY_HERE":
            return True, self._get_mock_forecast(days)
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/forecast",
                    params={
                        "lat": latitude,
                        "lon": longitude,
                        "appid": self.api_key,
                        "units": "metric",
                        "cnt": min(days * 8, 40)  # 3-hour intervals, max 5 days
                    },
                    timeout=10.0
                )
                
                if response.status_code != 200:
                    return False, []
                
                data = response.json()
                
                # Process forecast data by day
                daily_forecasts = {}
                for item in data.get("list", []):
                    date = item["dt_txt"].split(" ")[0]
                    
                    if date not in daily_forecasts:
                        daily_forecasts[date] = {
                            "temps": [],
                            "humidity": [],
                            "rain_chance": 0,
                            "description": "",
                            "icon": ""
                        }
                    
                    daily_forecasts[date]["temps"].append(item["main"]["temp"])
                    daily_forecasts[date]["humidity"].append(item["main"]["humidity"])
                    if item.get("rain", {}).get("3h", 0) > 0:
                        daily_forecasts[date]["rain_chance"] = max(
                            daily_forecasts[date]["rain_chance"],
                            int(item.get("pop", 0) * 100)
                        )
                    
                    # Use midday weather for description
                    if "12:00:00" in item["dt_txt"]:
                        daily_forecasts[date]["description"] = item["weather"][0]["description"].title()
                        daily_forecasts[date]["icon"] = item["weather"][0]["icon"]
                
                # Format forecast
                forecasts = []
                for date, values in list(daily_forecasts.items())[:days]:
                    forecasts.append({
                        "date": date,
                        "temp_min": min(values["temps"]),
                        "temp_max": max(values["temps"]),
                        "humidity": int(sum(values["humidity"]) / len(values["humidity"])),
                        "rain_chance": values["rain_chance"],
                        "weather_description": values["description"] or "Clear",
                        "icon_code": values["icon"] or "01d",
                        "wind_speed": 0,
                        "uv_index": 0
                    })
                
                return True, forecasts
                
        except Exception as e:
            return False, []
    
    # =========================================================================
    # FARM WEATHER WITH ADVISORIES
    # =========================================================================
    
    async def get_farm_weather(
        self,
        farm_id: str
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Get weather and farming advisories for a specific farm.
        
        Returns:
            Tuple of (success: bool, result: Dict with weather, forecast, and advisories)
        """
        # Get farm location
        farm = db.fetch_one(
            "SELECT latitude, longitude, soil_type, irrigation_type FROM farms WHERE id = ?",
            (farm_id,)
        )
        
        if not farm or not farm.get("latitude") or not farm.get("longitude"):
            return False, {"error": "Farm location not found"}
        
        lat, lon = farm["latitude"], farm["longitude"]
        
        # Get weather and forecast
        success, current = await self.get_current_weather(lat, lon)
        if not success:
            return False, current
        
        _, forecast = await self.get_weather_forecast(lat, lon, 7)
        
        # Generate advisories
        advisories = self._generate_advisories(current, forecast, farm)
        
        return True, {
            "current": current,
            "forecast": forecast,
            "advisories": advisories
        }
    
    # =========================================================================
    # WEATHER ADVISORIES
    # =========================================================================
    
    def _generate_advisories(
        self,
        current: Dict[str, Any],
        forecast: List[Dict[str, Any]],
        farm: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate farming advisories based on weather conditions."""
        advisories = []
        
        temp = current.get("temperature_celsius", 25)
        humidity = current.get("humidity_percent", 60)
        rain = current.get("rain_mm", 0)
        wind = current.get("wind_speed_kmh", 0)
        
        # Temperature advisories
        if temp > 35:
            advisories.append({
                "title": "High Temperature Alert",
                "description": "Consider additional irrigation and providing shade for sensitive crops.",
                "priority": "high",
                "category": "temperature",
                "icon": "thermostat"
            })
        elif temp < 10:
            advisories.append({
                "title": "Cold Weather Alert",
                "description": "Protect frost-sensitive crops. Consider covering or moving potted plants.",
                "priority": "high",
                "category": "temperature",
                "icon": "ac_unit"
            })
        
        # Rainfall advisories
        upcoming_rain = any(f.get("rain_chance", 0) > 50 for f in forecast[:3])
        if upcoming_rain:
            advisories.append({
                "title": "Rain Expected",
                "description": "Rain expected in the next 3 days. Delay pesticide application and harvest dry crops.",
                "priority": "medium",
                "category": "irrigation",
                "icon": "water_drop"
            })
        elif humidity < 40 and not rain:
            advisories.append({
                "title": "Dry Conditions",
                "description": "Low humidity and no rain. Ensure adequate irrigation for your crops.",
                "priority": "medium",
                "category": "irrigation",
                "icon": "dry"
            })
        
        # Wind advisories
        if wind > 30:
            advisories.append({
                "title": "High Wind Warning",
                "description": "Strong winds may damage tall crops. Consider providing support for vulnerable plants.",
                "priority": "medium",
                "category": "wind",
                "icon": "air"
            })
        
        # Pest/disease advisories
        if humidity > 80 and temp > 20 and temp < 30:
            advisories.append({
                "title": "Fungal Disease Risk",
                "description": "High humidity increases fungal disease risk. Monitor crops and improve air circulation.",
                "priority": "high",
                "category": "pest",
                "icon": "bug_report"
            })
        
        # Harvest advisory
        if not upcoming_rain and humidity < 70 and temp > 20 and temp < 35:
            advisories.append({
                "title": "Good Harvesting Conditions",
                "description": "Weather conditions are favorable for harvesting. Consider harvesting mature crops.",
                "priority": "low",
                "category": "harvest",
                "icon": "agriculture"
            })
        
        return advisories
    
    # =========================================================================
    # CACHING
    # =========================================================================
    
    def _get_cached_weather(
        self,
        latitude: float,
        longitude: float,
        is_forecast: bool = False
    ) -> Optional[Dict[str, Any]]:
        """Get cached weather data if available and not expired."""
        cache_minutes = self.cache_ttl / 60
        
        result = db.fetch_one("""
            SELECT * FROM weather_data 
            WHERE latitude = ? AND longitude = ? AND is_forecast = ?
            AND datetime(created_at) > datetime('now', ?)
            ORDER BY created_at DESC LIMIT 1
        """, (
            round(latitude, 4),
            round(longitude, 4),
            1 if is_forecast else 0,
            f"-{cache_minutes} minutes"
        ))
        
        if result:
            return {
                "latitude": result["latitude"],
                "longitude": result["longitude"],
                "recorded_at": result["recorded_at"],
                "temperature_celsius": result["temperature_celsius"],
                "feels_like_celsius": result["feels_like_celsius"],
                "humidity_percent": result["humidity_percent"],
                "pressure_hpa": result["pressure_hpa"],
                "wind_speed_kmh": result["wind_speed_kmh"],
                "wind_direction_deg": result["wind_direction_deg"],
                "visibility_km": result["visibility_km"],
                "rain_mm": result["rain_mm"],
                "weather_description": result["weather_description"],
                "icon_code": result["icon_code"],
            }
        
        return None
    
    def _cache_weather(
        self,
        weather: Dict[str, Any],
        is_forecast: bool = False
    ):
        """Cache weather data."""
        try:
            db.execute("""
                INSERT INTO weather_data (
                    id, latitude, longitude, recorded_at, temperature_celsius,
                    feels_like_celsius, humidity_percent, pressure_hpa,
                    wind_speed_kmh, wind_direction_deg, visibility_km,
                    rain_mm, weather_description, icon_code, is_forecast, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                generate_uuid(),
                round(weather.get("latitude", 0), 4),
                round(weather.get("longitude", 0), 4),
                weather.get("recorded_at"),
                weather.get("temperature_celsius"),
                weather.get("feels_like_celsius"),
                weather.get("humidity_percent"),
                weather.get("pressure_hpa"),
                weather.get("wind_speed_kmh"),
                weather.get("wind_direction_deg"),
                weather.get("visibility_km"),
                weather.get("rain_mm", 0),
                weather.get("weather_description"),
                weather.get("icon_code"),
                1 if is_forecast else 0,
                now_iso()
            ))
        except Exception:
            pass  # Ignore cache errors
    
    # =========================================================================
    # MOCK DATA (FOR DEVELOPMENT)
    # =========================================================================
    
    def _get_mock_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        """Return mock weather data for development."""
        return {
            "latitude": lat,
            "longitude": lon,
            "recorded_at": datetime.utcnow().isoformat(),
            "temperature_celsius": 28.5,
            "feels_like_celsius": 30.2,
            "humidity_percent": 65,
            "pressure_hpa": 1013.25,
            "wind_speed_kmh": 12.5,
            "wind_direction_deg": 180,
            "visibility_km": 10.0,
            "rain_mm": 0,
            "weather_description": "Partly Cloudy",
            "icon_code": "02d",
        }
    
    def _get_mock_forecast(self, days: int) -> List[Dict[str, Any]]:
        """Return mock forecast data for development."""
        forecasts = []
        today = datetime.now()
        
        conditions = [
            ("Partly Cloudy", "02d", 28, 22, 20),
            ("Sunny", "01d", 30, 21, 10),
            ("Cloudy", "03d", 27, 20, 40),
            ("Light Rain", "10d", 25, 19, 80),
            ("Rainy", "09d", 24, 18, 90),
            ("Cloudy", "04d", 26, 19, 30),
            ("Sunny", "01d", 29, 21, 5),
        ]
        
        for i in range(min(days, 7)):
            date = today + timedelta(days=i)
            cond = conditions[i % len(conditions)]
            
            forecasts.append({
                "date": date.strftime("%Y-%m-%d"),
                "temp_max": cond[2],
                "temp_min": cond[3],
                "humidity": 65,
                "rain_chance": cond[4],
                "weather_description": cond[0],
                "icon_code": cond[1],
                "wind_speed": 12,
                "uv_index": 6
            })
        
        return forecasts


# Global service instance
weather_service = WeatherService()
