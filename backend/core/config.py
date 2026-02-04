"""
AgriSense Pro - Configuration Management
All configuration via environment variables with sensible defaults for local development
SECURITY: Uses python-dotenv for .env file support and secure secret key generation
"""

import os
import secrets
from datetime import timedelta
from typing import List, Optional
from pydantic_settings import BaseSettings
from pydantic import field_validator
from functools import lru_cache
from pathlib import Path

# Load .env file if it exists
from dotenv import load_dotenv

# Try to load from multiple possible locations
env_paths = [
    Path(__file__).parent.parent / ".env",  # backend/.env
    Path.cwd() / ".env",  # current directory
]

for env_path in env_paths:
    if env_path.exists():
        load_dotenv(env_path)
        break


def generate_secure_key() -> str:
    """Generate a cryptographically secure secret key for development"""
    return secrets.token_urlsafe(64)


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    # =========================================================================
    # APPLICATION SETTINGS
    # =========================================================================
    APP_NAME: str = "AgriSense Pro"
    APP_VERSION: str = "1.0.0"
    APP_DESCRIPTION: str = "AI Crop Intelligence & Farmer Profit Engine"
    DEBUG: bool = True
    ENVIRONMENT: str = "development"  # development, staging, production
    
    # =========================================================================
    # SERVER SETTINGS
    # =========================================================================
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    WORKERS: int = 1
    RELOAD: bool = True
    
    # =========================================================================
    # DATABASE SETTINGS (PostgreSQL)
    # =========================================================================
    # For local development, use SQLite as fallback
    # For production, set DATABASE_URL environment variable
    DATABASE_URL: str = "postgresql://agrisense:agrisense123@localhost:5432/agrisense_db"
    
    # Alternative: Use SQLite for testing without PostgreSQL
    USE_SQLITE: bool = True  # Set to False when PostgreSQL is available
    SQLITE_PATH: str = "./agrisense.db"
    
    # Connection pool settings
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 10
    DB_POOL_TIMEOUT: int = 30
    
    # =========================================================================
    # SECURITY SETTINGS
    # =========================================================================
    # JWT Settings - SECRET_KEY loaded from environment or generated securely
    SECRET_KEY: str = os.environ.get(
        "SECRET_KEY",
        generate_secure_key() if os.environ.get("ENVIRONMENT") != "production" else ""
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Password hashing
    PASSWORD_MIN_LENGTH: int = 8
    BCRYPT_ROUNDS: int = 12
    
    # CORS Settings - Restricted for security
    # Override with CORS_ORIGINS env var as comma-separated list
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://localhost:5060",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:5060",
    ]
    CORS_ALLOW_CREDENTIALS: bool = True
    CORS_ALLOW_METHODS: List[str] = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]
    CORS_ALLOW_HEADERS: List[str] = [
        "Authorization",
        "Content-Type",
        "X-Requested-With",
        "Accept",
        "Origin",
        "X-CSRF-Token",
    ]
    
    @field_validator('SECRET_KEY')
    @classmethod
    def validate_secret_key(cls, v, info):
        """Ensure SECRET_KEY is set in production"""
        env = os.environ.get("ENVIRONMENT", "development")
        if env == "production" and (not v or v == "" or len(v) < 32):
            raise ValueError(
                "SECRET_KEY must be set to a secure value (minimum 32 characters) in production! "
                "Generate one with: python -c \"import secrets; print(secrets.token_urlsafe(64))\""
            )
        if len(v) < 32:
            # Auto-generate for development if too short
            return generate_secure_key()
        return v
    
    @field_validator('CORS_ORIGINS', mode='before')
    @classmethod
    def parse_cors_origins(cls, v):
        """Parse CORS_ORIGINS from comma-separated string if needed"""
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(',') if origin.strip()]
        return v
    
    # =========================================================================
    # EXTERNAL API KEYS (Free Tier Placeholders)
    # =========================================================================
    
    # Weather API - OpenWeatherMap (Free: 1000 calls/day)
    # Sign up: https://openweathermap.org/api
    OPENWEATHERMAP_API_KEY: str = "YOUR_OPENWEATHERMAP_API_KEY_HERE"
    
    # Alternative: WeatherAPI.com (Free: 1M calls/month)
    # Sign up: https://www.weatherapi.com/
    WEATHERAPI_KEY: str = "YOUR_WEATHERAPI_KEY_HERE"
    
    # Maps - OpenStreetMap/Nominatim (Free, no key needed)
    # Or use Mapbox (Free: 50K loads/month)
    MAPBOX_API_KEY: str = "YOUR_MAPBOX_API_KEY_HERE"
    
    # AI/ML - Hugging Face Inference API (Free tier available)
    # Sign up: https://huggingface.co/settings/tokens
    HUGGINGFACE_API_KEY: str = "YOUR_HUGGINGFACE_API_KEY_HERE"
    
    # Alternative AI - Google Gemini (Free tier: 60 QPM)
    # Sign up: https://makersuite.google.com/app/apikey
    GOOGLE_GEMINI_API_KEY: str = "YOUR_GOOGLE_GEMINI_API_KEY_HERE"
    
    # SMS - Twilio (Free trial with credits)
    # Sign up: https://www.twilio.com/try-twilio
    TWILIO_ACCOUNT_SID: str = "YOUR_TWILIO_ACCOUNT_SID_HERE"
    TWILIO_AUTH_TOKEN: str = "YOUR_TWILIO_AUTH_TOKEN_HERE"
    TWILIO_PHONE_NUMBER: str = "+1234567890"
    
    # Email - SendGrid (Free: 100 emails/day)
    # Sign up: https://signup.sendgrid.com/
    SENDGRID_API_KEY: str = "YOUR_SENDGRID_API_KEY_HERE"
    FROM_EMAIL: str = "noreply@agrisensepro.com"
    
    # Market Data - data.gov.in (Free, registration required)
    # Sign up: https://data.gov.in/
    DATA_GOV_IN_API_KEY: str = "YOUR_DATA_GOV_IN_API_KEY_HERE"
    
    # Agricultural Market Data - Agmarknet
    AGMARKNET_API_URL: str = "https://agmarknet.gov.in/api"
    
    # Image Storage - Cloudinary (Free: 25K transformations/month)
    # Sign up: https://cloudinary.com/
    CLOUDINARY_CLOUD_NAME: str = "YOUR_CLOUDINARY_CLOUD_NAME"
    CLOUDINARY_API_KEY: str = "YOUR_CLOUDINARY_API_KEY"
    CLOUDINARY_API_SECRET: str = "YOUR_CLOUDINARY_API_SECRET"
    
    # Push Notifications - Firebase Cloud Messaging (Free)
    # Setup: https://console.firebase.google.com/
    FCM_SERVER_KEY: str = "YOUR_FCM_SERVER_KEY_HERE"
    
    # =========================================================================
    # RATE LIMITING
    # =========================================================================
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_PER_HOUR: int = 1000
    
    # =========================================================================
    # FILE UPLOAD SETTINGS
    # =========================================================================
    MAX_UPLOAD_SIZE_MB: int = 10
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]
    UPLOAD_DIR: str = "./uploads"
    
    # =========================================================================
    # CACHE SETTINGS
    # =========================================================================
    CACHE_TTL_SECONDS: int = 300  # 5 minutes
    WEATHER_CACHE_TTL: int = 1800  # 30 minutes
    PRICE_CACHE_TTL: int = 3600  # 1 hour
    
    # =========================================================================
    # LOGGING
    # =========================================================================
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    LOG_FILE: str = "./logs/agrisense.log"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore"


# Clear cache to allow regeneration
@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


# Create settings instance
settings = get_settings()


# =========================================================================
# HELPER FUNCTIONS
# =========================================================================

def get_database_url() -> str:
    """Get appropriate database URL based on configuration"""
    if settings.USE_SQLITE:
        return f"sqlite:///{settings.SQLITE_PATH}"
    return settings.DATABASE_URL


def get_access_token_expires() -> timedelta:
    """Get access token expiration timedelta"""
    return timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)


def get_refresh_token_expires() -> timedelta:
    """Get refresh token expiration timedelta"""
    return timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)


def is_production() -> bool:
    """Check if running in production environment"""
    return settings.ENVIRONMENT.lower() == "production"


def get_allowed_cors_origins() -> List[str]:
    """Get CORS origins list, adding production domains if configured"""
    origins = list(settings.CORS_ORIGINS)
    # Add any additional production origins from environment
    extra_origins = os.environ.get("EXTRA_CORS_ORIGINS", "")
    if extra_origins:
        origins.extend([o.strip() for o in extra_origins.split(",") if o.strip()])
    return origins
