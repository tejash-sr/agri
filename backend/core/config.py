"""
AgriSense Pro - Configuration Management
All configuration via environment variables with sensible defaults for local development
"""

import os
from datetime import timedelta
from typing import Optional
from pydantic_settings import BaseSettings
from functools import lru_cache


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
    # JWT Settings
    SECRET_KEY: str = "YOUR_SECRET_KEY_HERE_CHANGE_IN_PRODUCTION_MIN_32_CHARS"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Password hashing
    PASSWORD_MIN_LENGTH: int = 8
    BCRYPT_ROUNDS: int = 12
    
    # CORS Settings
    CORS_ORIGINS: list = ["*"]  # Restrict in production
    CORS_ALLOW_CREDENTIALS: bool = True
    CORS_ALLOW_METHODS: list = ["*"]
    CORS_ALLOW_HEADERS: list = ["*"]
    
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
    ALLOWED_IMAGE_TYPES: list = ["image/jpeg", "image/png", "image/webp"]
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


# =========================================================================
# ENVIRONMENT VARIABLE TEMPLATE (.env.example)
# =========================================================================
ENV_TEMPLATE = """
# =========================================================================
# AgriSense Pro - Environment Variables
# Copy this file to .env and fill in your values
# =========================================================================

# Application
APP_NAME=AgriSense Pro
DEBUG=true
ENVIRONMENT=development

# Server
HOST=0.0.0.0
PORT=8000

# Database (PostgreSQL)
DATABASE_URL=postgresql://agrisense:agrisense123@localhost:5432/agrisense_db
USE_SQLITE=true

# Security (CHANGE THESE IN PRODUCTION!)
SECRET_KEY=your-super-secret-key-minimum-32-characters-long
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Weather API (Free tier)
# Get key: https://openweathermap.org/api
OPENWEATHERMAP_API_KEY=your_openweathermap_key

# Alternative Weather API
# Get key: https://www.weatherapi.com/
WEATHERAPI_KEY=your_weatherapi_key

# Maps (Free tier)
# Get key: https://www.mapbox.com/
MAPBOX_API_KEY=your_mapbox_key

# AI/ML APIs (Free tier)
# Get key: https://huggingface.co/settings/tokens
HUGGINGFACE_API_KEY=your_huggingface_key

# Google Gemini (Free tier)
# Get key: https://makersuite.google.com/app/apikey
GOOGLE_GEMINI_API_KEY=your_gemini_key

# SMS (Free trial)
# Get: https://www.twilio.com/try-twilio
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=+1234567890

# Email (Free tier)
# Get key: https://signup.sendgrid.com/
SENDGRID_API_KEY=your_sendgrid_key
FROM_EMAIL=noreply@agrisensepro.com

# Market Data
# Register: https://data.gov.in/
DATA_GOV_IN_API_KEY=your_data_gov_key

# Image Storage (Free tier)
# Get: https://cloudinary.com/
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret

# Push Notifications (Free)
# Setup: https://console.firebase.google.com/
FCM_SERVER_KEY=your_fcm_key
"""
