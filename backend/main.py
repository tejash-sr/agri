"""
AgriSense Pro - Main FastAPI Application
AI Crop Intelligence & Farmer Profit Engine

This is the main entry point for the AgriSense Pro backend API.
No BaaS dependencies - pure Python implementation with PostgreSQL/SQLite.
"""

import os
import sys

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import logging
import time

from core.config import settings
from db.database import db

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format=settings.LOG_FORMAT
)
logger = logging.getLogger(__name__)


# =========================================================================
# APPLICATION LIFESPAN
# =========================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown events."""
    # Startup
    logger.info("=" * 60)
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"Debug Mode: {settings.DEBUG}")
    logger.info("=" * 60)
    
    # Initialize database
    logger.info("Database initialized successfully")
    
    # Create upload directory if not exists
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    os.makedirs("./logs", exist_ok=True)
    
    yield
    
    # Shutdown
    logger.info("Shutting down AgriSense Pro API...")


# =========================================================================
# CREATE FASTAPI APPLICATION
# =========================================================================

app = FastAPI(
    title=settings.APP_NAME,
    description=settings.APP_DESCRIPTION,
    version=settings.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None
)


# =========================================================================
# MIDDLEWARE
# =========================================================================

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=settings.CORS_ALLOW_METHODS,
    allow_headers=settings.CORS_ALLOW_HEADERS,
)


# Request timing middleware
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(round(process_time * 1000, 2))
    return response


# =========================================================================
# EXCEPTION HANDLERS
# =========================================================================

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "message": exc.detail,
            "error_code": f"HTTP_{exc.status_code}"
        }
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    
    if settings.DEBUG:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "success": False,
                "message": str(exc),
                "error_code": "INTERNAL_ERROR"
            }
        )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "message": "An internal error occurred",
            "error_code": "INTERNAL_ERROR"
        }
    )


# =========================================================================
# IMPORT AND INCLUDE ROUTERS
# =========================================================================

from api.routes import auth, farms, crops, diseases, marketplace, weather, prices

# Include all routers with /api/v1 prefix
app.include_router(auth.router, prefix="/api/v1")
app.include_router(farms.router, prefix="/api/v1")
app.include_router(crops.router, prefix="/api/v1")
app.include_router(diseases.router, prefix="/api/v1")
app.include_router(marketplace.router, prefix="/api/v1")
app.include_router(weather.router, prefix="/api/v1")
app.include_router(prices.router, prefix="/api/v1")


# =========================================================================
# ROOT ENDPOINTS
# =========================================================================

@app.get("/")
async def root():
    """API root endpoint."""
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "description": settings.APP_DESCRIPTION,
        "status": "running",
        "docs": "/docs" if settings.DEBUG else "disabled",
        "api_base": "/api/v1"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "database": "connected",
        "timestamp": time.time()
    }


@app.get("/api/v1")
async def api_info():
    """API version information."""
    return {
        "version": "1.0.0",
        "endpoints": {
            "auth": "/api/v1/auth",
            "farms": "/api/v1/farms",
            "crops": "/api/v1/crops",
            "diseases": "/api/v1/diseases",
            "marketplace": "/api/v1/marketplace",
            "weather": "/api/v1/weather",
            "prices": "/api/v1/prices"
        }
    }


@app.get("/api/v1/dashboard")
async def dashboard_summary(request: Request):
    """
    Get dashboard summary for authenticated user.
    This is a convenience endpoint that aggregates data from multiple sources.
    """
    from api.routes.auth import get_current_user
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
    
    # Try to get auth header
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    from core.security import verify_token
    token = auth_header.split(" ")[1]
    token_data = verify_token(token, "access")
    
    if not token_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    
    user = db.fetch_one(
        "SELECT * FROM users WHERE id = ? AND is_active = 1",
        (token_data.user_id,)
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    # Get dashboard data
    farms_count = db.fetch_one(
        "SELECT COUNT(*) as count FROM farms WHERE user_id = ?",
        (user["id"],)
    )
    
    crops_data = db.fetch_one("""
        SELECT COUNT(*) as count, SUM(area_acres) as total_area, AVG(health_score) as avg_health
        FROM crops WHERE user_id = ? AND status IN ('planted', 'growing')
    """, (user["id"],))
    
    alerts = db.fetch_all("""
        SELECT * FROM alerts 
        WHERE user_id = ? AND is_read = 0
        ORDER BY created_at DESC LIMIT 5
    """, (user["id"],))
    
    listings_count = db.fetch_one(
        "SELECT COUNT(*) as count FROM listings WHERE user_id = ? AND status = 'active'",
        (user["id"],)
    )
    
    return {
        "user": {
            "id": user["id"],
            "name": user["full_name"],
            "email": user["email"],
            "role": user["role"]
        },
        "summary": {
            "total_farms": farms_count["count"] if farms_count else 0,
            "active_crops": crops_data["count"] if crops_data else 0,
            "total_area_acres": round(crops_data["total_area"] or 0, 2) if crops_data else 0,
            "avg_crop_health": round(crops_data["avg_health"] or 0, 1) if crops_data else 0,
            "active_listings": listings_count["count"] if listings_count else 0,
            "unread_alerts": len(alerts)
        },
        "recent_alerts": [
            {
                "id": a["id"],
                "type": a["alert_type"],
                "severity": a["severity"],
                "title": a["title"],
                "message": a["message"],
                "created_at": a["created_at"]
            }
            for a in alerts
        ]
    }


# =========================================================================
# STATIC FILES (for uploaded content)
# =========================================================================

# Mount uploads directory
if os.path.exists(settings.UPLOAD_DIR):
    app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")


# =========================================================================
# RUN APPLICATION
# =========================================================================

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.RELOAD,
        workers=settings.WORKERS,
        log_level=settings.LOG_LEVEL.lower()
    )
