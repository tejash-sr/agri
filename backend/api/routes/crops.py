"""
AgriSense Pro - Crop Management Routes
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from datetime import datetime, date
import json

from models.schemas import (
    CropCreate, CropUpdate, CropResponse, CropRecommendationResponse,
    BaseResponse, CropStatus
)
from api.routes.auth import get_current_user
from db.database import db, generate_uuid, now_iso

router = APIRouter(prefix="/crops", tags=["Crop Management"])


@router.get("/master", response_model=List[dict])
async def get_crop_master():
    """
    Get all available crop types (master data).
    """
    crops = db.fetch_all(
        """
        SELECT id, name, local_name, scientific_name, category, season,
               min_temp_celsius, max_temp_celsius, water_requirement_mm,
               growing_days_min, growing_days_max, soil_types,
               typical_yield_per_acre, yield_unit, image_url, description
        FROM crop_master
        ORDER BY category, name
        """
    )
    
    result = []
    for crop in crops:
        crop_dict = dict(crop)
        # Parse soil_types JSON
        if crop_dict.get("soil_types"):
            try:
                crop_dict["soil_types"] = json.loads(crop_dict["soil_types"])
            except:
                crop_dict["soil_types"] = []
        result.append(crop_dict)
    
    return result


@router.get("/master/{crop_id}")
async def get_crop_master_detail(crop_id: int):
    """
    Get detailed information about a specific crop type.
    """
    crop = db.fetch_one(
        "SELECT * FROM crop_master WHERE id = ?",
        (crop_id,)
    )
    
    if crop is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Crop type not found"
        )
    
    crop_dict = dict(crop)
    if crop_dict.get("soil_types"):
        try:
            crop_dict["soil_types"] = json.loads(crop_dict["soil_types"])
        except:
            crop_dict["soil_types"] = []
    
    return crop_dict


@router.get("", response_model=List[CropResponse])
async def get_crops(
    current_user: dict = Depends(get_current_user),
    farm_id: Optional[str] = None,
    status_filter: Optional[CropStatus] = Query(None, alias="status"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Get all crops for the current user.
    """
    query = """
        SELECT c.*, cm.name as crop_name
        FROM crops c
        LEFT JOIN crop_master cm ON c.crop_master_id = cm.id
        WHERE c.user_id = ?
    """
    params = [current_user["id"]]
    
    if farm_id:
        query += " AND c.farm_id = ?"
        params.append(farm_id)
    
    if status_filter:
        query += " AND c.status = ?"
        params.append(status_filter.value)
    
    query += " ORDER BY c.created_at DESC LIMIT ? OFFSET ?"
    params.extend([limit, skip])
    
    crops = db.fetch_all(query, tuple(params))
    
    return [_format_crop_response(c) for c in crops]


@router.post("", response_model=CropResponse, status_code=status.HTTP_201_CREATED)
async def create_crop(
    crop_data: CropCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new crop record.
    """
    # Verify farm ownership
    farm = db.fetch_one(
        "SELECT id FROM farms WHERE id = ? AND user_id = ?",
        (crop_data.farm_id, current_user["id"])
    )
    
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found"
        )
    
    # Verify crop master exists
    crop_master = db.fetch_one(
        "SELECT name FROM crop_master WHERE id = ?",
        (crop_data.crop_master_id,)
    )
    
    if crop_master is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid crop type"
        )
    
    crop_id = generate_uuid()
    
    db.execute("""
        INSERT INTO crops (
            id, farm_id, zone_id, crop_master_id, user_id, variety,
            status, area_acres, sowing_date, expected_harvest_date,
            notes, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        crop_id,
        crop_data.farm_id,
        crop_data.zone_id,
        crop_data.crop_master_id,
        current_user["id"],
        crop_data.variety,
        "planned",
        crop_data.area_acres,
        crop_data.sowing_date.isoformat() if crop_data.sowing_date else None,
        crop_data.expected_harvest_date.isoformat() if crop_data.expected_harvest_date else None,
        crop_data.notes,
        now_iso(),
        now_iso()
    ))
    
    # Fetch created crop with crop name
    crop = db.fetch_one("""
        SELECT c.*, cm.name as crop_name
        FROM crops c
        LEFT JOIN crop_master cm ON c.crop_master_id = cm.id
        WHERE c.id = ?
    """, (crop_id,))
    
    return _format_crop_response(crop)


@router.get("/{crop_id}", response_model=CropResponse)
async def get_crop(
    crop_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get a specific crop by ID.
    """
    crop = db.fetch_one("""
        SELECT c.*, cm.name as crop_name
        FROM crops c
        LEFT JOIN crop_master cm ON c.crop_master_id = cm.id
        WHERE c.id = ? AND c.user_id = ?
    """, (crop_id, current_user["id"]))
    
    if crop is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Crop not found"
        )
    
    return _format_crop_response(crop)


@router.put("/{crop_id}", response_model=CropResponse)
async def update_crop(
    crop_id: str,
    crop_data: CropUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update a crop record.
    """
    # Check ownership
    crop = db.fetch_one(
        "SELECT * FROM crops WHERE id = ? AND user_id = ?",
        (crop_id, current_user["id"])
    )
    
    if crop is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Crop not found"
        )
    
    # Build update query
    updates = []
    params = []
    
    update_fields = crop_data.model_dump(exclude_unset=True)
    
    for field, value in update_fields.items():
        if value is not None:
            if field == "status":
                value = value.value
            elif isinstance(value, date):
                value = value.isoformat()
            updates.append(f"{field} = ?")
            params.append(value)
    
    if updates:
        updates.append("updated_at = ?")
        params.append(now_iso())
        params.append(crop_id)
        
        db.execute(
            f"UPDATE crops SET {', '.join(updates)} WHERE id = ?",
            tuple(params)
        )
    
    return await get_crop(crop_id, current_user)


@router.delete("/{crop_id}", response_model=BaseResponse)
async def delete_crop(
    crop_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a crop record.
    """
    crop = db.fetch_one(
        "SELECT * FROM crops WHERE id = ? AND user_id = ?",
        (crop_id, current_user["id"])
    )
    
    if crop is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Crop not found"
        )
    
    db.execute("DELETE FROM crops WHERE id = ?", (crop_id,))
    
    return BaseResponse(message="Crop deleted successfully")


@router.get("/{crop_id}/performance")
async def get_crop_performance(
    crop_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get crop performance analysis.
    """
    crop = db.fetch_one("""
        SELECT c.*, cm.name as crop_name, cm.typical_yield_per_acre
        FROM crops c
        LEFT JOIN crop_master cm ON c.crop_master_id = cm.id
        WHERE c.id = ? AND c.user_id = ?
    """, (crop_id, current_user["id"]))
    
    if crop is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Crop not found"
        )
    
    # Calculate performance metrics
    total_investment = (
        (crop.get("seed_cost") or 0) +
        (crop.get("fertilizer_cost") or 0) +
        (crop.get("pesticide_cost") or 0) +
        (crop.get("labor_cost") or 0) +
        (crop.get("irrigation_cost") or 0) +
        (crop.get("other_cost") or 0)
    )
    
    cost_per_acre = total_investment / crop["area_acres"] if crop["area_acres"] > 0 else 0
    
    expected_yield_total = (crop.get("expected_yield") or 0)
    actual_yield_total = (crop.get("actual_yield") or 0)
    
    yield_achievement = 0
    if expected_yield_total > 0 and actual_yield_total > 0:
        yield_achievement = (actual_yield_total / expected_yield_total) * 100
    
    # Get disease history
    disease_scans = db.fetch_all("""
        SELECT disease_name, severity, confidence_score, created_at
        FROM disease_scans
        WHERE crop_id = ?
        ORDER BY created_at DESC
        LIMIT 5
    """, (crop_id,))
    
    return {
        "crop": _format_crop_response(crop),
        "investment": {
            "seed_cost": crop.get("seed_cost") or 0,
            "fertilizer_cost": crop.get("fertilizer_cost") or 0,
            "pesticide_cost": crop.get("pesticide_cost") or 0,
            "labor_cost": crop.get("labor_cost") or 0,
            "irrigation_cost": crop.get("irrigation_cost") or 0,
            "other_cost": crop.get("other_cost") or 0,
            "total_investment": total_investment,
            "cost_per_acre": round(cost_per_acre, 2)
        },
        "yield": {
            "expected_yield": expected_yield_total,
            "actual_yield": actual_yield_total,
            "yield_unit": crop.get("yield_unit", "kg"),
            "yield_achievement_percent": round(yield_achievement, 1),
            "typical_yield_per_acre": crop.get("typical_yield_per_acre") or 0
        },
        "health": {
            "current_score": crop.get("health_score") or 100,
            "disease_history": disease_scans
        }
    }


@router.get("/recommendations/{farm_id}", response_model=List[CropRecommendationResponse])
async def get_crop_recommendations(
    farm_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get AI-powered crop recommendations for a farm.
    """
    # Verify farm ownership
    farm = db.fetch_one(
        "SELECT * FROM farms WHERE id = ? AND user_id = ?",
        (farm_id, current_user["id"])
    )
    
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found"
        )
    
    # Check for existing recommendations
    recommendations = db.fetch_all("""
        SELECT r.*, cm.name as crop_name
        FROM crop_recommendations r
        LEFT JOIN crop_master cm ON r.crop_master_id = cm.id
        WHERE r.farm_id = ? AND r.valid_until >= ?
        ORDER BY r.suitability_score DESC
        LIMIT 10
    """, (farm_id, date.today().isoformat()))
    
    if recommendations:
        return [_format_recommendation(r) for r in recommendations]
    
    # Generate new recommendations based on farm data
    generated = _generate_recommendations(farm, current_user["id"])
    
    return generated


def _format_crop_response(crop: dict) -> CropResponse:
    """Format crop database row to response model."""
    total_investment = (
        (crop.get("seed_cost") or 0) +
        (crop.get("fertilizer_cost") or 0) +
        (crop.get("pesticide_cost") or 0) +
        (crop.get("labor_cost") or 0) +
        (crop.get("irrigation_cost") or 0) +
        (crop.get("other_cost") or 0)
    )
    
    sowing_date = None
    if crop.get("sowing_date"):
        sowing_date = date.fromisoformat(crop["sowing_date"]) if isinstance(crop["sowing_date"], str) else crop["sowing_date"]
    
    expected_harvest = None
    if crop.get("expected_harvest_date"):
        expected_harvest = date.fromisoformat(crop["expected_harvest_date"]) if isinstance(crop["expected_harvest_date"], str) else crop["expected_harvest_date"]
    
    actual_harvest = None
    if crop.get("actual_harvest_date"):
        actual_harvest = date.fromisoformat(crop["actual_harvest_date"]) if isinstance(crop["actual_harvest_date"], str) else crop["actual_harvest_date"]
    
    return CropResponse(
        id=crop["id"],
        farm_id=crop["farm_id"],
        zone_id=crop.get("zone_id"),
        crop_master_id=crop["crop_master_id"],
        user_id=crop["user_id"],
        variety=crop.get("variety"),
        status=crop.get("status", "planned"),
        area_acres=crop["area_acres"],
        sowing_date=sowing_date,
        expected_harvest_date=expected_harvest,
        actual_harvest_date=actual_harvest,
        expected_yield=crop.get("expected_yield"),
        actual_yield=crop.get("actual_yield"),
        yield_unit=crop.get("yield_unit", "kg"),
        seed_cost=crop.get("seed_cost") or 0,
        fertilizer_cost=crop.get("fertilizer_cost") or 0,
        pesticide_cost=crop.get("pesticide_cost") or 0,
        labor_cost=crop.get("labor_cost") or 0,
        irrigation_cost=crop.get("irrigation_cost") or 0,
        other_cost=crop.get("other_cost") or 0,
        health_score=crop.get("health_score") or 100,
        notes=crop.get("notes"),
        created_at=datetime.fromisoformat(crop["created_at"]),
        updated_at=datetime.fromisoformat(crop["updated_at"]),
        total_investment=total_investment,
        crop_name=crop.get("crop_name")
    )


def _format_recommendation(rec: dict) -> CropRecommendationResponse:
    """Format recommendation to response model."""
    factors = None
    if rec.get("factors"):
        try:
            factors = json.loads(rec["factors"]) if isinstance(rec["factors"], str) else rec["factors"]
        except:
            factors = {}
    
    return CropRecommendationResponse(
        id=rec["id"],
        crop_master_id=rec["crop_master_id"],
        crop_name=rec.get("crop_name", "Unknown"),
        suitability_score=rec["suitability_score"],
        expected_yield_per_acre=rec.get("expected_yield_per_acre"),
        expected_profit_per_acre=rec.get("expected_profit_per_acre"),
        risk_score=rec.get("risk_score"),
        factors=factors,
        recommendation_text=rec.get("recommendation_text"),
        recommended_sowing_start=date.fromisoformat(rec["recommended_sowing_start"]) if rec.get("recommended_sowing_start") else None,
        recommended_sowing_end=date.fromisoformat(rec["recommended_sowing_end"]) if rec.get("recommended_sowing_end") else None,
        season=rec.get("season"),
        water_requirement=rec.get("water_requirement"),
        price_trend=rec.get("price_trend"),
        demand_level=rec.get("demand_level")
    )


def _generate_recommendations(farm: dict, user_id: str) -> List[CropRecommendationResponse]:
    """
    Generate crop recommendations based on farm characteristics.
    This is a simplified rule-based system. In production, this would use ML models.
    """
    # Get all crop master data
    crops = db.fetch_all("SELECT * FROM crop_master")
    
    recommendations = []
    soil_type = farm.get("soil_type", "").lower()
    
    for crop in crops:
        score = 0.5  # Base score
        factors = {}
        
        # Soil type matching
        soil_types = []
        if crop.get("soil_types"):
            try:
                soil_types = json.loads(crop["soil_types"]) if isinstance(crop["soil_types"], str) else crop["soil_types"]
            except:
                soil_types = []
        
        if soil_type and soil_types:
            if any(st.lower() in soil_type for st in soil_types):
                score += 0.2
                factors["soil_match"] = "High"
            else:
                factors["soil_match"] = "Low"
        
        # Water availability
        water_source = farm.get("water_source", "").lower()
        if water_source and "well" in water_source or "canal" in water_source:
            if (crop.get("water_requirement_mm") or 0) <= 800:
                score += 0.1
                factors["water_match"] = "High"
        
        # Market demand (simplified)
        if crop.get("category") in ["vegetables", "fruits"]:
            score += 0.1
            factors["market_demand"] = "High"
        
        # Season matching
        import calendar
        current_month = datetime.now().month
        season = crop.get("season", "")
        
        if season == "kharif" and 6 <= current_month <= 9:
            score += 0.1
            factors["season_match"] = "High"
        elif season == "rabi" and (current_month >= 10 or current_month <= 2):
            score += 0.1
            factors["season_match"] = "High"
        
        # Risk assessment (simplified)
        risk_score = 0.3  # Base risk
        if crop.get("growing_days_max") and crop["growing_days_max"] > 150:
            risk_score += 0.1
        
        # Create recommendation record
        rec_id = generate_uuid()
        
        db.execute("""
            INSERT INTO crop_recommendations (
                id, user_id, farm_id, crop_master_id, suitability_score,
                expected_yield_per_acre, expected_profit_per_acre, risk_score,
                factors, recommendation_text, season, water_requirement,
                price_trend, demand_level, created_at, valid_until
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            rec_id,
            user_id,
            farm["id"],
            crop["id"],
            round(score, 4),
            crop.get("typical_yield_per_acre"),
            None,  # Would need price data
            round(risk_score, 4),
            json.dumps(factors),
            f"Recommended for {crop['name']} cultivation based on farm conditions.",
            crop.get("season"),
            "medium" if (crop.get("water_requirement_mm") or 0) <= 800 else "high",
            "stable",
            "high" if crop.get("category") in ["vegetables", "fruits"] else "medium",
            now_iso(),
            (date.today().replace(month=date.today().month % 12 + 1) if date.today().month < 12 else date.today().replace(year=date.today().year + 1, month=1)).isoformat()
        ))
        
        recommendations.append(CropRecommendationResponse(
            id=rec_id,
            crop_master_id=crop["id"],
            crop_name=crop["name"],
            suitability_score=round(score, 4),
            expected_yield_per_acre=crop.get("typical_yield_per_acre"),
            expected_profit_per_acre=None,
            risk_score=round(risk_score, 4),
            factors=factors,
            recommendation_text=f"Recommended for {crop['name']} cultivation based on farm conditions.",
            season=crop.get("season"),
            water_requirement="medium" if (crop.get("water_requirement_mm") or 0) <= 800 else "high",
            price_trend="stable",
            demand_level="high" if crop.get("category") in ["vegetables", "fruits"] else "medium"
        ))
    
    # Sort by score and return top 10
    recommendations.sort(key=lambda x: x.suitability_score, reverse=True)
    return recommendations[:10]
