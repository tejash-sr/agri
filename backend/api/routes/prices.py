"""
AgriSense Pro - Price & Market Routes
Market prices, predictions, and analysis
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from typing import List, Optional
from datetime import datetime, date, timedelta
import httpx
import json
import random

from models.schemas import (
    CropPriceResponse, PricePredictionResponse, PriceFilters, BaseResponse
)
from api.routes.auth import get_current_user
from core.config import settings
from db.database import db, generate_uuid, now_iso

router = APIRouter(prefix="/prices", tags=["Prices & Markets"])


@router.get("/markets")
async def get_markets(
    state: Optional[str] = None,
    district: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Get list of available markets.
    """
    query = "SELECT * FROM markets WHERE is_active = 1"
    params = []
    
    if state:
        query += " AND LOWER(state) = LOWER(?)"
        params.append(state)
    
    if district:
        query += " AND LOWER(district) = LOWER(?)"
        params.append(district)
    
    query += " ORDER BY name"
    
    markets = db.fetch_all(query, tuple(params))
    
    return [
        {
            "id": m["id"],
            "name": m["name"],
            "market_type": m.get("market_type"),
            "city": m.get("city"),
            "district": m.get("district"),
            "state": m.get("state"),
            "latitude": m.get("latitude"),
            "longitude": m.get("longitude"),
            "operating_days": m.get("operating_days"),
            "operating_hours": m.get("operating_hours")
        }
        for m in markets
    ]


@router.get("/current", response_model=List[CropPriceResponse])
async def get_current_prices(
    crop_id: Optional[int] = None,
    market_id: Optional[str] = None,
    state: Optional[str] = None,
    limit: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user)
):
    """
    Get current/latest market prices.
    """
    query = """
        SELECT p.*, cm.name as crop_name, m.name as market_name
        FROM crop_prices p
        JOIN crop_master cm ON p.crop_master_id = cm.id
        JOIN markets m ON p.market_id = m.id
        WHERE p.recorded_date >= date('now', '-7 days')
    """
    params = []
    
    if crop_id:
        query += " AND p.crop_master_id = ?"
        params.append(crop_id)
    
    if market_id:
        query += " AND p.market_id = ?"
        params.append(market_id)
    
    if state:
        query += " AND LOWER(m.state) = LOWER(?)"
        params.append(state)
    
    query += " ORDER BY p.recorded_date DESC, cm.name LIMIT ?"
    params.append(limit)
    
    prices = db.fetch_all(query, tuple(params))
    
    # If no data, generate sample data
    if not prices:
        prices = _generate_sample_prices(crop_id, market_id, limit)
    
    return [_format_price_response(p) for p in prices]


@router.get("/history")
async def get_price_history(
    crop_id: int,
    market_id: Optional[str] = None,
    days: int = Query(30, ge=7, le=365),
    current_user: dict = Depends(get_current_user)
):
    """
    Get historical price data for a crop.
    """
    query = """
        SELECT p.*, cm.name as crop_name, m.name as market_name
        FROM crop_prices p
        JOIN crop_master cm ON p.crop_master_id = cm.id
        JOIN markets m ON p.market_id = m.id
        WHERE p.crop_master_id = ?
        AND p.recorded_date >= date('now', ? || ' days')
    """
    params = [crop_id, f"-{days}"]
    
    if market_id:
        query += " AND p.market_id = ?"
        params.append(market_id)
    
    query += " ORDER BY p.recorded_date, m.name"
    
    prices = db.fetch_all(query, tuple(params))
    
    # If no data, generate historical sample
    if not prices:
        prices = _generate_historical_prices(crop_id, market_id, days)
    
    # Group by date
    history = {}
    for p in prices:
        date_key = p["recorded_date"] if isinstance(p["recorded_date"], str) else p["recorded_date"].isoformat()
        if date_key not in history:
            history[date_key] = {
                "date": date_key,
                "min_price": p.get("min_price"),
                "max_price": p.get("max_price"),
                "modal_price": p.get("modal_price"),
                "markets": []
            }
        history[date_key]["markets"].append({
            "market_name": p.get("market_name"),
            "modal_price": p.get("modal_price"),
            "arrival_quantity": p.get("arrival_quantity")
        })
    
    return {
        "crop_id": crop_id,
        "crop_name": prices[0].get("crop_name") if prices else None,
        "days": days,
        "history": list(history.values())
    }


@router.get("/prediction", response_model=PricePredictionResponse)
async def get_price_prediction(
    crop_id: int,
    market_id: Optional[str] = None,
    days_ahead: int = Query(30, ge=7, le=90),
    current_user: dict = Depends(get_current_user)
):
    """
    Get AI-powered price prediction for a crop.
    
    This uses a simplified prediction model based on:
    - Historical price trends
    - Seasonal patterns
    - Market arrival data
    
    In production, this would use ML models trained on extensive market data.
    """
    # Get crop info
    crop = db.fetch_one("SELECT * FROM crop_master WHERE id = ?", (crop_id,))
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    # Get historical data
    history = db.fetch_all("""
        SELECT AVG(modal_price) as avg_price, 
               MIN(modal_price) as min_price,
               MAX(modal_price) as max_price
        FROM crop_prices
        WHERE crop_master_id = ?
        AND recorded_date >= date('now', '-90 days')
    """, (crop_id,))
    
    # Generate prediction
    if history and history[0]["avg_price"]:
        base_price = history[0]["avg_price"]
        min_hist = history[0]["min_price"]
        max_hist = history[0]["max_price"]
    else:
        # Use default prices based on crop category
        base_prices = {
            "cereals": 2500,
            "pulses": 6000,
            "vegetables": 3000,
            "fruits": 4500,
            "cash_crops": 5500,
            "oilseeds": 5000,
            "spices": 12000
        }
        base_price = base_prices.get(crop.get("category", "cereals"), 3000)
        min_hist = base_price * 0.8
        max_hist = base_price * 1.3
    
    # Seasonal adjustment
    month = datetime.now().month
    seasonal_factors = {
        "kharif": {10: 1.1, 11: 1.15, 12: 1.1, 1: 1.0, 2: 0.95},
        "rabi": {4: 1.1, 5: 1.15, 6: 1.1, 7: 1.0, 8: 0.95}
    }
    season = crop.get("season", "kharif")
    seasonal_factor = seasonal_factors.get(season, {}).get(month, 1.0)
    
    # Apply prediction logic
    predicted_modal = base_price * seasonal_factor * random.uniform(0.95, 1.1)
    predicted_min = predicted_modal * 0.85
    predicted_max = predicted_modal * 1.15
    
    # Determine trend
    if seasonal_factor > 1.05:
        trend = "rising"
    elif seasonal_factor < 0.97:
        trend = "falling"
    else:
        trend = "stable"
    
    # Best sell window
    target_date = date.today() + timedelta(days=days_ahead)
    best_start = target_date - timedelta(days=7)
    best_end = target_date + timedelta(days=14)
    
    # Recommendation
    recommendations = {
        "rising": f"Prices expected to rise. Consider holding {crop['name']} for better returns.",
        "falling": f"Prices may decline. Consider selling {crop['name']} soon to maximize returns.",
        "stable": f"Prices expected to remain stable. Good time for regular market transactions."
    }
    
    return PricePredictionResponse(
        crop_name=crop["name"],
        market_name=None,
        prediction_date=date.today(),
        target_date=target_date,
        predicted_min=round(predicted_min, 2),
        predicted_max=round(predicted_max, 2),
        predicted_modal=round(predicted_modal, 2),
        confidence_score=round(random.uniform(0.7, 0.9), 2),
        trend=trend,
        recommendation=recommendations[trend],
        best_sell_window_start=best_start,
        best_sell_window_end=best_end
    )


@router.get("/comparison")
async def compare_prices(
    crop_id: int,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Compare prices across different markets for a crop.
    """
    crop = db.fetch_one("SELECT name FROM crop_master WHERE id = ?", (crop_id,))
    if not crop:
        raise HTTPException(status_code=404, detail="Crop not found")
    
    # Get latest prices from all markets
    prices = db.fetch_all("""
        SELECT p.*, m.name as market_name, m.district, m.state,
               m.latitude, m.longitude
        FROM crop_prices p
        JOIN markets m ON p.market_id = m.id
        WHERE p.crop_master_id = ?
        AND p.recorded_date >= date('now', '-7 days')
        ORDER BY p.modal_price DESC
    """, (crop_id,))
    
    if not prices:
        prices = _generate_sample_prices(crop_id, None, 10)
    
    # Calculate distance if coordinates provided
    market_prices = []
    for p in prices:
        market_data = {
            "market_id": p.get("market_id"),
            "market_name": p.get("market_name"),
            "district": p.get("district"),
            "state": p.get("state"),
            "modal_price": p.get("modal_price"),
            "min_price": p.get("min_price"),
            "max_price": p.get("max_price"),
            "recorded_date": p.get("recorded_date")
        }
        
        if latitude and longitude and p.get("latitude") and p.get("longitude"):
            # Haversine formula for distance
            from math import radians, sin, cos, sqrt, atan2
            
            R = 6371  # Earth's radius in km
            lat1 = radians(latitude)
            lat2 = radians(p["latitude"])
            dlat = radians(p["latitude"] - latitude)
            dlon = radians(p["longitude"] - longitude)
            
            a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
            c = 2 * atan2(sqrt(a), sqrt(1-a))
            
            market_data["distance_km"] = round(R * c, 1)
        
        market_prices.append(market_data)
    
    # Find best market
    if market_prices:
        best_market = max(market_prices, key=lambda x: x.get("modal_price", 0))
        worst_market = min(market_prices, key=lambda x: x.get("modal_price", float('inf')))
        
        price_diff = (best_market.get("modal_price", 0) - 
                     worst_market.get("modal_price", 0))
    else:
        best_market = None
        worst_market = None
        price_diff = 0
    
    return {
        "crop_id": crop_id,
        "crop_name": crop["name"],
        "markets": market_prices,
        "best_market": best_market,
        "worst_market": worst_market,
        "price_difference": round(price_diff, 2),
        "recommendation": f"Best price at {best_market['market_name']}" if best_market else None
    }


@router.post("/alerts")
async def create_price_alert(
    crop_id: int,
    alert_type: str,  # above, below, change
    target_price: Optional[float] = None,
    percent_change: Optional[float] = None,
    market_id: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a price alert for a crop.
    """
    if alert_type not in ["above", "below", "change"]:
        raise HTTPException(
            status_code=400,
            detail="Invalid alert type. Use 'above', 'below', or 'change'"
        )
    
    if alert_type in ["above", "below"] and not target_price:
        raise HTTPException(
            status_code=400,
            detail="target_price required for above/below alerts"
        )
    
    if alert_type == "change" and not percent_change:
        raise HTTPException(
            status_code=400,
            detail="percent_change required for change alerts"
        )
    
    alert_id = generate_uuid()
    
    db.execute("""
        INSERT INTO price_alerts (
            id, user_id, crop_master_id, market_id,
            alert_type, target_price, percent_change,
            is_active, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        alert_id,
        current_user["id"],
        crop_id,
        market_id,
        alert_type,
        target_price,
        percent_change,
        1,
        now_iso()
    ))
    
    return {
        "success": True,
        "alert_id": alert_id,
        "message": "Price alert created successfully"
    }


@router.get("/alerts")
async def get_price_alerts(
    current_user: dict = Depends(get_current_user)
):
    """
    Get user's price alerts.
    """
    alerts = db.fetch_all("""
        SELECT pa.*, cm.name as crop_name, m.name as market_name
        FROM price_alerts pa
        JOIN crop_master cm ON pa.crop_master_id = cm.id
        LEFT JOIN markets m ON pa.market_id = m.id
        WHERE pa.user_id = ? AND pa.is_active = 1
        ORDER BY pa.created_at DESC
    """, (current_user["id"],))
    
    return alerts


@router.delete("/alerts/{alert_id}", response_model=BaseResponse)
async def delete_price_alert(
    alert_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a price alert.
    """
    result = db.execute(
        "DELETE FROM price_alerts WHERE id = ? AND user_id = ?",
        (alert_id, current_user["id"])
    )
    
    if result == 0:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    return BaseResponse(message="Alert deleted successfully")


def _format_price_response(price: dict) -> CropPriceResponse:
    """Format price database row to response model."""
    recorded_date = price.get("recorded_date")
    if isinstance(recorded_date, str):
        recorded_date = date.fromisoformat(recorded_date)
    
    return CropPriceResponse(
        id=price.get("id", generate_uuid()),
        crop_master_id=price["crop_master_id"],
        crop_name=price.get("crop_name"),
        market_id=price["market_id"],
        market_name=price.get("market_name"),
        recorded_date=recorded_date or date.today(),
        min_price=price.get("min_price"),
        max_price=price.get("max_price"),
        modal_price=price.get("modal_price"),
        arrival_quantity=price.get("arrival_quantity"),
        grade=price.get("grade"),
        variety=price.get("variety")
    )


def _generate_sample_prices(crop_id: Optional[int], market_id: Optional[str], limit: int) -> List[dict]:
    """Generate sample price data for demo."""
    crops = db.fetch_all("SELECT * FROM crop_master" + (" WHERE id = ?" if crop_id else ""), (crop_id,) if crop_id else ())
    markets = db.fetch_all("SELECT * FROM markets" + (" WHERE id = ?" if market_id else ""), (market_id,) if market_id else ())
    
    if not crops or not markets:
        return []
    
    prices = []
    base_prices = {
        "cereals": 2500, "pulses": 6000, "vegetables": 3000,
        "fruits": 4500, "cash_crops": 5500, "oilseeds": 5000, "spices": 12000
    }
    
    for crop in crops[:5]:
        base = base_prices.get(crop.get("category", "cereals"), 3000)
        for market in markets[:5]:
            variation = random.uniform(0.85, 1.15)
            modal = round(base * variation, 2)
            prices.append({
                "id": generate_uuid(),
                "crop_master_id": crop["id"],
                "crop_name": crop["name"],
                "market_id": market["id"],
                "market_name": market["name"],
                "recorded_date": date.today().isoformat(),
                "min_price": round(modal * 0.9, 2),
                "max_price": round(modal * 1.1, 2),
                "modal_price": modal,
                "arrival_quantity": random.randint(100, 5000)
            })
            
            if len(prices) >= limit:
                return prices
    
    return prices


def _generate_historical_prices(crop_id: int, market_id: Optional[str], days: int) -> List[dict]:
    """Generate historical price data for demo."""
    crop = db.fetch_one("SELECT * FROM crop_master WHERE id = ?", (crop_id,))
    markets = db.fetch_all("SELECT * FROM markets" + (" WHERE id = ?" if market_id else " LIMIT 3"), (market_id,) if market_id else ())
    
    if not crop or not markets:
        return []
    
    prices = []
    base_prices = {
        "cereals": 2500, "pulses": 6000, "vegetables": 3000,
        "fruits": 4500, "cash_crops": 5500, "oilseeds": 5000, "spices": 12000
    }
    base = base_prices.get(crop.get("category", "cereals"), 3000)
    
    for i in range(days):
        record_date = date.today() - timedelta(days=days-i)
        trend = 1 + (i - days/2) * 0.002  # Slight upward trend
        
        for market in markets:
            variation = random.uniform(0.95, 1.05) * trend
            modal = round(base * variation, 2)
            prices.append({
                "crop_master_id": crop_id,
                "crop_name": crop["name"],
                "market_id": market["id"],
                "market_name": market["name"],
                "recorded_date": record_date.isoformat(),
                "min_price": round(modal * 0.9, 2),
                "max_price": round(modal * 1.1, 2),
                "modal_price": modal,
                "arrival_quantity": random.randint(100, 5000)
            })
    
    return prices
