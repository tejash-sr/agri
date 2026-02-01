"""
AgriSense Pro - Farm Management Routes
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from datetime import datetime

from models.schemas import (
    FarmCreate, FarmUpdate, FarmResponse, BaseResponse, PaginatedResponse
)
from api.routes.auth import get_current_user
from db.database import db, generate_uuid, now_iso

router = APIRouter(prefix="/farms", tags=["Farm Management"])


@router.get("", response_model=List[FarmResponse])
async def get_farms(
    current_user: dict = Depends(get_current_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100)
):
    """
    Get all farms for the current user.
    """
    farms = db.fetch_all(
        """
        SELECT * FROM farms 
        WHERE user_id = ? 
        ORDER BY is_primary DESC, created_at DESC
        LIMIT ? OFFSET ?
        """,
        (current_user["id"], limit, skip)
    )
    
    return [
        FarmResponse(
            id=f["id"],
            user_id=f["user_id"],
            name=f["name"],
            farm_type=f.get("farm_type", "small"),
            address=f.get("address"),
            village=f.get("village"),
            district=f.get("district"),
            state=f.get("state"),
            latitude=f.get("latitude"),
            longitude=f.get("longitude"),
            total_area_acres=f["total_area_acres"],
            cultivable_area_acres=f.get("cultivable_area_acres"),
            soil_type=f.get("soil_type"),
            water_source=f.get("water_source"),
            irrigation_type=f.get("irrigation_type", "manual"),
            elevation_meters=f.get("elevation_meters"),
            annual_rainfall_mm=f.get("annual_rainfall_mm"),
            soil_ph=f.get("soil_ph"),
            organic_matter_percent=f.get("organic_matter_percent"),
            is_primary=bool(f.get("is_primary", 0)),
            created_at=datetime.fromisoformat(f["created_at"]),
            updated_at=datetime.fromisoformat(f["updated_at"])
        )
        for f in farms
    ]


@router.post("", response_model=FarmResponse, status_code=status.HTTP_201_CREATED)
async def create_farm(
    farm_data: FarmCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new farm.
    """
    farm_id = generate_uuid()
    
    # If this is the first farm or marked as primary, update other farms
    if farm_data.is_primary:
        db.execute(
            "UPDATE farms SET is_primary = 0 WHERE user_id = ?",
            (current_user["id"],)
        )
    else:
        # Check if user has any farms
        existing = db.fetch_one(
            "SELECT COUNT(*) as count FROM farms WHERE user_id = ?",
            (current_user["id"],)
        )
        if existing["count"] == 0:
            farm_data.is_primary = True
    
    db.execute("""
        INSERT INTO farms (
            id, user_id, name, farm_type, address, village, district, state,
            latitude, longitude, total_area_acres, cultivable_area_acres,
            soil_type, water_source, irrigation_type, is_primary, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        farm_id,
        current_user["id"],
        farm_data.name,
        farm_data.farm_type.value,
        farm_data.address,
        farm_data.village,
        farm_data.district,
        farm_data.state,
        farm_data.latitude,
        farm_data.longitude,
        farm_data.total_area_acres,
        farm_data.cultivable_area_acres,
        farm_data.soil_type,
        farm_data.water_source,
        farm_data.irrigation_type,
        1 if farm_data.is_primary else 0,
        now_iso(),
        now_iso()
    ))
    
    return FarmResponse(
        id=farm_id,
        user_id=current_user["id"],
        name=farm_data.name,
        farm_type=farm_data.farm_type,
        address=farm_data.address,
        village=farm_data.village,
        district=farm_data.district,
        state=farm_data.state,
        latitude=farm_data.latitude,
        longitude=farm_data.longitude,
        total_area_acres=farm_data.total_area_acres,
        cultivable_area_acres=farm_data.cultivable_area_acres,
        soil_type=farm_data.soil_type,
        water_source=farm_data.water_source,
        irrigation_type=farm_data.irrigation_type,
        is_primary=farm_data.is_primary,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )


@router.get("/{farm_id}", response_model=FarmResponse)
async def get_farm(
    farm_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get a specific farm by ID.
    """
    farm = db.fetch_one(
        "SELECT * FROM farms WHERE id = ? AND user_id = ?",
        (farm_id, current_user["id"])
    )
    
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found"
        )
    
    return FarmResponse(
        id=farm["id"],
        user_id=farm["user_id"],
        name=farm["name"],
        farm_type=farm.get("farm_type", "small"),
        address=farm.get("address"),
        village=farm.get("village"),
        district=farm.get("district"),
        state=farm.get("state"),
        latitude=farm.get("latitude"),
        longitude=farm.get("longitude"),
        total_area_acres=farm["total_area_acres"],
        cultivable_area_acres=farm.get("cultivable_area_acres"),
        soil_type=farm.get("soil_type"),
        water_source=farm.get("water_source"),
        irrigation_type=farm.get("irrigation_type", "manual"),
        elevation_meters=farm.get("elevation_meters"),
        annual_rainfall_mm=farm.get("annual_rainfall_mm"),
        soil_ph=farm.get("soil_ph"),
        organic_matter_percent=farm.get("organic_matter_percent"),
        is_primary=bool(farm.get("is_primary", 0)),
        created_at=datetime.fromisoformat(farm["created_at"]),
        updated_at=datetime.fromisoformat(farm["updated_at"])
    )


@router.put("/{farm_id}", response_model=FarmResponse)
async def update_farm(
    farm_id: str,
    farm_data: FarmUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update a farm.
    """
    # Check ownership
    farm = db.fetch_one(
        "SELECT * FROM farms WHERE id = ? AND user_id = ?",
        (farm_id, current_user["id"])
    )
    
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found"
        )
    
    # Build update query
    updates = []
    params = []
    
    update_fields = farm_data.model_dump(exclude_unset=True)
    
    for field, value in update_fields.items():
        if value is not None:
            if field == "farm_type":
                value = value.value
            elif field == "is_primary" and value:
                # Reset other farms' primary status
                db.execute(
                    "UPDATE farms SET is_primary = 0 WHERE user_id = ? AND id != ?",
                    (current_user["id"], farm_id)
                )
                value = 1
            updates.append(f"{field} = ?")
            params.append(value)
    
    if updates:
        updates.append("updated_at = ?")
        params.append(now_iso())
        params.append(farm_id)
        
        db.execute(
            f"UPDATE farms SET {', '.join(updates)} WHERE id = ?",
            tuple(params)
        )
    
    # Fetch updated farm
    return await get_farm(farm_id, current_user)


@router.delete("/{farm_id}", response_model=BaseResponse)
async def delete_farm(
    farm_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a farm.
    """
    # Check ownership
    farm = db.fetch_one(
        "SELECT * FROM farms WHERE id = ? AND user_id = ?",
        (farm_id, current_user["id"])
    )
    
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found"
        )
    
    # Delete farm (cascades to related records)
    db.execute("DELETE FROM farms WHERE id = ?", (farm_id,))
    
    # If deleted farm was primary, make another farm primary
    if farm.get("is_primary"):
        other_farm = db.fetch_one(
            "SELECT id FROM farms WHERE user_id = ? LIMIT 1",
            (current_user["id"],)
        )
        if other_farm:
            db.execute(
                "UPDATE farms SET is_primary = 1 WHERE id = ?",
                (other_farm["id"],)
            )
    
    return BaseResponse(message="Farm deleted successfully")


@router.get("/{farm_id}/summary")
async def get_farm_summary(
    farm_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get farm summary with crop statistics.
    """
    farm = db.fetch_one(
        "SELECT * FROM farms WHERE id = ? AND user_id = ?",
        (farm_id, current_user["id"])
    )
    
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Farm not found"
        )
    
    # Get crop statistics
    crop_stats = db.fetch_one("""
        SELECT 
            COUNT(*) as total_crops,
            COUNT(CASE WHEN status IN ('planted', 'growing') THEN 1 END) as active_crops,
            SUM(area_acres) as total_planted_area,
            AVG(health_score) as avg_health_score,
            SUM(seed_cost + fertilizer_cost + pesticide_cost + labor_cost + irrigation_cost + other_cost) as total_investment
        FROM crops WHERE farm_id = ?
    """, (farm_id,))
    
    # Get recent alerts
    alerts = db.fetch_all("""
        SELECT * FROM alerts 
        WHERE farm_id = ? AND is_read = 0
        ORDER BY created_at DESC
        LIMIT 5
    """, (farm_id,))
    
    return {
        "farm": FarmResponse(
            id=farm["id"],
            user_id=farm["user_id"],
            name=farm["name"],
            farm_type=farm.get("farm_type", "small"),
            address=farm.get("address"),
            village=farm.get("village"),
            district=farm.get("district"),
            state=farm.get("state"),
            latitude=farm.get("latitude"),
            longitude=farm.get("longitude"),
            total_area_acres=farm["total_area_acres"],
            cultivable_area_acres=farm.get("cultivable_area_acres"),
            soil_type=farm.get("soil_type"),
            water_source=farm.get("water_source"),
            irrigation_type=farm.get("irrigation_type", "manual"),
            elevation_meters=farm.get("elevation_meters"),
            annual_rainfall_mm=farm.get("annual_rainfall_mm"),
            soil_ph=farm.get("soil_ph"),
            organic_matter_percent=farm.get("organic_matter_percent"),
            is_primary=bool(farm.get("is_primary", 0)),
            created_at=datetime.fromisoformat(farm["created_at"]),
            updated_at=datetime.fromisoformat(farm["updated_at"])
        ),
        "statistics": {
            "total_crops": crop_stats["total_crops"] or 0,
            "active_crops": crop_stats["active_crops"] or 0,
            "total_planted_area": crop_stats["total_planted_area"] or 0,
            "avg_health_score": round(crop_stats["avg_health_score"] or 0, 1),
            "total_investment": crop_stats["total_investment"] or 0,
            "utilization_percent": round(
                ((crop_stats["total_planted_area"] or 0) / farm["total_area_acres"]) * 100, 1
            ) if farm["total_area_acres"] > 0 else 0
        },
        "unread_alerts": len(alerts),
        "recent_alerts": alerts
    }
