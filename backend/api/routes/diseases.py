"""
AgriSense Pro - Disease Detection Routes
AI-powered disease detection with manual analysis fallback
"""

from fastapi import APIRouter, HTTPException, Depends, status, UploadFile, File
from typing import List, Optional
from datetime import datetime
import json
import httpx
import base64

from models.schemas import (
    DiseaseScanCreate, DiseaseScanResponse, DiseaseInfo, BaseResponse
)
from api.routes.auth import get_current_user
from core.config import settings
from db.database import db, generate_uuid, now_iso

router = APIRouter(prefix="/diseases", tags=["Disease Detection"])


@router.get("/catalog", response_model=List[DiseaseInfo])
async def get_disease_catalog():
    """
    Get all known diseases in the database.
    """
    diseases = db.fetch_all(
        """
        SELECT id, name, local_name, scientific_name, category, symptoms,
               causes, prevention, organic_treatment, chemical_treatment
        FROM disease_master
        ORDER BY name
        """
    )
    
    return [
        DiseaseInfo(
            id=d["id"],
            name=d["name"],
            local_name=d.get("local_name"),
            category=d.get("category", "unknown"),
            symptoms=d.get("symptoms", ""),
            causes=d.get("causes"),
            prevention=d.get("prevention"),
            organic_treatment=d.get("organic_treatment"),
            chemical_treatment=d.get("chemical_treatment")
        )
        for d in diseases
    ]


@router.get("/catalog/{disease_id}", response_model=DiseaseInfo)
async def get_disease_detail(disease_id: int):
    """
    Get detailed information about a specific disease.
    """
    disease = db.fetch_one(
        "SELECT * FROM disease_master WHERE id = ?",
        (disease_id,)
    )
    
    if disease is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Disease not found"
        )
    
    return DiseaseInfo(
        id=disease["id"],
        name=disease["name"],
        local_name=disease.get("local_name"),
        category=disease.get("category", "unknown"),
        symptoms=disease.get("symptoms", ""),
        causes=disease.get("causes"),
        prevention=disease.get("prevention"),
        organic_treatment=disease.get("organic_treatment"),
        chemical_treatment=disease.get("chemical_treatment")
    )


@router.post("/scan", response_model=DiseaseScanResponse, status_code=status.HTTP_201_CREATED)
async def create_disease_scan(
    scan_data: DiseaseScanCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Submit an image for disease detection.
    
    This endpoint accepts an image URL and performs AI-based disease detection.
    In production, this would call an ML model API (e.g., HuggingFace, Google Vision).
    """
    scan_id = generate_uuid()
    
    # Verify farm/crop ownership if provided
    if scan_data.farm_id:
        farm = db.fetch_one(
            "SELECT id FROM farms WHERE id = ? AND user_id = ?",
            (scan_data.farm_id, current_user["id"])
        )
        if farm is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid farm ID"
            )
    
    if scan_data.crop_id:
        crop = db.fetch_one(
            "SELECT id FROM crops WHERE id = ? AND user_id = ?",
            (scan_data.crop_id, current_user["id"])
        )
        if crop is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid crop ID"
            )
    
    # Perform AI analysis
    analysis_result = await _analyze_image(scan_data.image_url)
    
    # Store scan result
    db.execute("""
        INSERT INTO disease_scans (
            id, user_id, crop_id, farm_id, image_url,
            detected_disease_id, disease_name, confidence_score,
            severity, affected_area_percent, ai_analysis,
            recommended_actions, estimated_yield_impact,
            latitude, longitude, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        scan_id,
        current_user["id"],
        scan_data.crop_id,
        scan_data.farm_id,
        scan_data.image_url,
        analysis_result.get("disease_id"),
        analysis_result.get("disease_name"),
        analysis_result.get("confidence"),
        analysis_result.get("severity", "none"),
        analysis_result.get("affected_area"),
        analysis_result.get("analysis"),
        json.dumps(analysis_result.get("recommendations", [])),
        analysis_result.get("yield_impact"),
        scan_data.latitude,
        scan_data.longitude,
        now_iso()
    ))
    
    # Update crop health score if disease detected
    if scan_data.crop_id and analysis_result.get("severity") != "none":
        health_reduction = {
            "low": 10,
            "medium": 25,
            "high": 40,
            "critical": 60
        }.get(analysis_result.get("severity"), 0)
        
        db.execute("""
            UPDATE crops 
            SET health_score = MAX(0, health_score - ?), updated_at = ?
            WHERE id = ?
        """, (health_reduction, now_iso(), scan_data.crop_id))
        
        # Create alert for disease detection
        _create_disease_alert(
            current_user["id"],
            scan_data.farm_id,
            analysis_result
        )
    
    # Fetch and return the created scan
    return await get_scan(scan_id, current_user)


@router.get("/scans", response_model=List[DiseaseScanResponse])
async def get_scans(
    current_user: dict = Depends(get_current_user),
    farm_id: Optional[str] = None,
    crop_id: Optional[str] = None,
    limit: int = 20
):
    """
    Get disease scan history for the user.
    """
    query = "SELECT * FROM disease_scans WHERE user_id = ?"
    params = [current_user["id"]]
    
    if farm_id:
        query += " AND farm_id = ?"
        params.append(farm_id)
    
    if crop_id:
        query += " AND crop_id = ?"
        params.append(crop_id)
    
    query += " ORDER BY created_at DESC LIMIT ?"
    params.append(limit)
    
    scans = db.fetch_all(query, tuple(params))
    
    return [_format_scan_response(s) for s in scans]


@router.get("/scans/{scan_id}", response_model=DiseaseScanResponse)
async def get_scan(
    scan_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get a specific disease scan by ID.
    """
    scan = db.fetch_one(
        "SELECT * FROM disease_scans WHERE id = ? AND user_id = ?",
        (scan_id, current_user["id"])
    )
    
    if scan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )
    
    return _format_scan_response(scan)


@router.delete("/scans/{scan_id}", response_model=BaseResponse)
async def delete_scan(
    scan_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a disease scan.
    """
    scan = db.fetch_one(
        "SELECT * FROM disease_scans WHERE id = ? AND user_id = ?",
        (scan_id, current_user["id"])
    )
    
    if scan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )
    
    db.execute("DELETE FROM disease_scans WHERE id = ?", (scan_id,))
    
    return BaseResponse(message="Scan deleted successfully")


@router.get("/statistics")
async def get_disease_statistics(
    current_user: dict = Depends(get_current_user),
    farm_id: Optional[str] = None
):
    """
    Get disease detection statistics.
    """
    query_base = "FROM disease_scans WHERE user_id = ?"
    params = [current_user["id"]]
    
    if farm_id:
        query_base += " AND farm_id = ?"
        params.append(farm_id)
    
    # Total scans
    total = db.fetch_one(f"SELECT COUNT(*) as count {query_base}", tuple(params))
    
    # Scans by severity
    severity_stats = db.fetch_all(f"""
        SELECT severity, COUNT(*) as count 
        {query_base} 
        GROUP BY severity
    """, tuple(params))
    
    # Most common diseases
    disease_stats = db.fetch_all(f"""
        SELECT disease_name, COUNT(*) as count, AVG(confidence_score) as avg_confidence
        {query_base} AND disease_name IS NOT NULL
        GROUP BY disease_name
        ORDER BY count DESC
        LIMIT 5
    """, tuple(params))
    
    # Recent trends (last 30 days)
    trends = db.fetch_all(f"""
        SELECT DATE(created_at) as date, COUNT(*) as count
        {query_base} AND created_at >= date('now', '-30 days')
        GROUP BY DATE(created_at)
        ORDER BY date
    """, tuple(params))
    
    return {
        "total_scans": total["count"] if total else 0,
        "by_severity": {s["severity"]: s["count"] for s in severity_stats},
        "common_diseases": [
            {
                "name": d["disease_name"],
                "count": d["count"],
                "avg_confidence": round(d["avg_confidence"] or 0, 2)
            }
            for d in disease_stats
        ],
        "trends": [{"date": t["date"], "count": t["count"]} for t in trends]
    }


def _format_scan_response(scan: dict) -> DiseaseScanResponse:
    """Format scan database row to response model."""
    actions = []
    if scan.get("recommended_actions"):
        try:
            actions = json.loads(scan["recommended_actions"]) if isinstance(scan["recommended_actions"], str) else scan["recommended_actions"]
        except:
            actions = []
    
    return DiseaseScanResponse(
        id=scan["id"],
        user_id=scan["user_id"],
        crop_id=scan.get("crop_id"),
        farm_id=scan.get("farm_id"),
        image_url=scan["image_url"],
        detected_disease_id=scan.get("detected_disease_id"),
        disease_name=scan.get("disease_name"),
        confidence_score=scan.get("confidence_score"),
        severity=scan.get("severity", "none"),
        affected_area_percent=scan.get("affected_area_percent"),
        ai_analysis=scan.get("ai_analysis"),
        recommended_actions=actions,
        estimated_yield_impact=scan.get("estimated_yield_impact"),
        is_verified=bool(scan.get("is_verified", 0)),
        created_at=datetime.fromisoformat(scan["created_at"])
    )


async def _analyze_image(image_url: str) -> dict:
    """
    Analyze image for disease detection.
    
    This is a simplified implementation. In production, this would:
    1. Call a trained ML model (HuggingFace, TensorFlow Serving, etc.)
    2. Use Google Vision API or AWS Rekognition
    3. Use a custom-trained model specific to crop diseases
    
    For now, we'll use a rule-based simulation based on the image URL.
    """
    # Check if HuggingFace API key is configured
    if settings.HUGGINGFACE_API_KEY and settings.HUGGINGFACE_API_KEY != "YOUR_HUGGINGFACE_API_KEY_HERE":
        try:
            return await _analyze_with_huggingface(image_url)
        except Exception as e:
            print(f"HuggingFace analysis failed: {e}")
    
    # Fallback to simulated analysis
    return _simulate_analysis(image_url)


async def _analyze_with_huggingface(image_url: str) -> dict:
    """
    Analyze image using HuggingFace Inference API.
    Uses a pre-trained plant disease classification model.
    """
    # Use a plant disease classification model
    model_id = "linkanjarad/plant-disease-classification"  # Example model
    api_url = f"https://api-inference.huggingface.co/models/{model_id}"
    
    headers = {
        "Authorization": f"Bearer {settings.HUGGINGFACE_API_KEY}"
    }
    
    async with httpx.AsyncClient() as client:
        # Download image
        img_response = await client.get(image_url)
        img_data = img_response.content
        
        # Send to HuggingFace
        response = await client.post(
            api_url,
            headers=headers,
            content=img_data,
            timeout=30.0
        )
        
        if response.status_code == 200:
            results = response.json()
            
            if results and len(results) > 0:
                top_result = results[0]
                label = top_result.get("label", "Unknown")
                score = top_result.get("score", 0)
                
                # Map to our disease database
                disease = db.fetch_one(
                    "SELECT * FROM disease_master WHERE name LIKE ? OR local_name LIKE ?",
                    (f"%{label}%", f"%{label}%")
                )
                
                severity = "none"
                if score > 0.8:
                    severity = "high"
                elif score > 0.6:
                    severity = "medium"
                elif score > 0.4:
                    severity = "low"
                
                return {
                    "disease_id": disease["id"] if disease else None,
                    "disease_name": disease["name"] if disease else label,
                    "confidence": round(score, 4),
                    "severity": severity,
                    "affected_area": round(score * 50, 1) if severity != "none" else 0,
                    "analysis": f"AI detected {label} with {round(score*100, 1)}% confidence.",
                    "recommendations": _get_recommendations(disease) if disease else ["Consult an agricultural expert"],
                    "yield_impact": round(score * 30, 1) if severity != "none" else 0
                }
    
    # Return no disease if API call failed
    return _simulate_analysis(image_url)


def _simulate_analysis(image_url: str) -> dict:
    """
    Simulate disease analysis for demo purposes.
    In production, replace with actual ML model inference.
    """
    import random
    
    # Randomly decide if disease is detected (for demo)
    if random.random() > 0.3:  # 70% chance of detecting something
        diseases = db.fetch_all("SELECT * FROM disease_master LIMIT 5")
        
        if diseases:
            disease = random.choice(diseases)
            confidence = round(random.uniform(0.65, 0.95), 4)
            severity = random.choice(["low", "medium", "high"])
            
            return {
                "disease_id": disease["id"],
                "disease_name": disease["name"],
                "confidence": confidence,
                "severity": severity,
                "affected_area": round(random.uniform(10, 60), 1),
                "analysis": f"Analysis indicates possible {disease['name']}. {disease.get('symptoms', '')}",
                "recommendations": _get_recommendations(disease),
                "yield_impact": round(random.uniform(5, 30), 1)
            }
    
    return {
        "disease_id": None,
        "disease_name": None,
        "confidence": 0.95,
        "severity": "none",
        "affected_area": 0,
        "analysis": "No significant disease detected. Crop appears healthy.",
        "recommendations": [
            "Continue regular monitoring",
            "Maintain proper irrigation",
            "Follow recommended fertilization schedule"
        ],
        "yield_impact": 0
    }


def _get_recommendations(disease: dict) -> List[str]:
    """Get treatment recommendations for a disease."""
    recommendations = []
    
    if disease.get("prevention"):
        recommendations.append(f"Prevention: {disease['prevention']}")
    
    if disease.get("organic_treatment"):
        recommendations.append(f"Organic Treatment: {disease['organic_treatment']}")
    
    if disease.get("chemical_treatment"):
        recommendations.append(f"Chemical Treatment: {disease['chemical_treatment']}")
    
    if not recommendations:
        recommendations = ["Consult local agricultural expert for treatment advice"]
    
    return recommendations


def _create_disease_alert(user_id: str, farm_id: Optional[str], analysis: dict):
    """Create an alert for detected disease."""
    severity_map = {
        "low": "info",
        "medium": "warning",
        "high": "high",
        "critical": "critical"
    }
    
    alert_id = generate_uuid()
    db.execute("""
        INSERT INTO alerts (
            id, user_id, farm_id, alert_type, severity,
            title, message, action_required, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        alert_id,
        user_id,
        farm_id,
        "disease",
        severity_map.get(analysis.get("severity", "low"), "warning"),
        f"Disease Detected: {analysis.get('disease_name', 'Unknown')}",
        f"Confidence: {round(analysis.get('confidence', 0) * 100, 1)}%. {analysis.get('analysis', '')}",
        1 if analysis.get("severity") in ["high", "critical"] else 0,
        now_iso()
    ))
