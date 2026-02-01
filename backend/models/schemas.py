"""
AgriSense Pro - Pydantic Schemas
Request/Response models with validation
"""

from datetime import datetime, date
from typing import Optional, List, Any, Dict
from pydantic import BaseModel, Field, EmailStr, validator
from enum import Enum


# =========================================================================
# ENUMS
# =========================================================================

class UserRole(str, Enum):
    FARMER = "farmer"
    TRADER = "trader"
    EXPERT = "expert"
    ADMIN = "admin"


class FarmType(str, Enum):
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"
    COMMERCIAL = "commercial"


class CropStatus(str, Enum):
    PLANNED = "planned"
    PLANTED = "planted"
    GROWING = "growing"
    HARVESTING = "harvesting"
    HARVESTED = "harvested"
    FAILED = "failed"


class DiseaseSeverity(str, Enum):
    NONE = "none"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AlertType(str, Enum):
    WEATHER = "weather"
    DISEASE = "disease"
    PRICE = "price"
    IRRIGATION = "irrigation"
    HARVEST = "harvest"
    MARKET = "market"
    GENERAL = "general"


class AlertSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    HIGH = "high"
    CRITICAL = "critical"


class ListingStatus(str, Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    SOLD = "sold"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class TransactionType(str, Enum):
    INCOME = "income"
    EXPENSE = "expense"


# =========================================================================
# BASE SCHEMAS
# =========================================================================

class BaseResponse(BaseModel):
    """Base response model"""
    success: bool = True
    message: str = "Success"
    

class PaginatedResponse(BaseResponse):
    """Paginated response model"""
    total: int
    page: int
    per_page: int
    pages: int


class ErrorResponse(BaseModel):
    """Error response model"""
    success: bool = False
    message: str
    error_code: Optional[str] = None
    details: Optional[Dict[str, Any]] = None


# =========================================================================
# AUTH SCHEMAS
# =========================================================================

class UserRegister(BaseModel):
    """User registration request"""
    email: EmailStr
    phone: Optional[str] = None
    password: str = Field(..., min_length=8)
    full_name: str = Field(..., min_length=2, max_length=100)
    role: UserRole = UserRole.FARMER
    
    @validator('phone')
    def validate_phone(cls, v):
        if v:
            import re
            cleaned = v.replace(" ", "").replace("-", "")
            if not re.match(r'^(\+91|91|0)?[6-9]\d{9}$', cleaned):
                raise ValueError('Invalid Indian phone number')
        return v


class UserLogin(BaseModel):
    """User login request"""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """Token response"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshTokenRequest(BaseModel):
    """Refresh token request"""
    refresh_token: str


class PasswordChange(BaseModel):
    """Password change request"""
    current_password: str
    new_password: str = Field(..., min_length=8)


class PasswordReset(BaseModel):
    """Password reset request"""
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """Password reset confirmation"""
    token: str
    new_password: str = Field(..., min_length=8)


# =========================================================================
# USER SCHEMAS
# =========================================================================

class UserBase(BaseModel):
    """User base schema"""
    email: EmailStr
    phone: Optional[str] = None
    full_name: str
    avatar_url: Optional[str] = None
    role: UserRole = UserRole.FARMER


class UserCreate(UserBase):
    """User creation schema"""
    password: str = Field(..., min_length=8)


class UserUpdate(BaseModel):
    """User update schema"""
    full_name: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    language: Optional[str] = None
    preferred_units: Optional[str] = None
    notification_enabled: Optional[bool] = None


class UserResponse(UserBase):
    """User response schema"""
    id: str
    subscription_tier: str = "free"
    address: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    language: str = "en"
    notification_enabled: bool = True
    email_verified: bool = False
    phone_verified: bool = False
    created_at: datetime
    
    class Config:
        from_attributes = True


# =========================================================================
# FARM SCHEMAS
# =========================================================================

class FarmBase(BaseModel):
    """Farm base schema"""
    name: str = Field(..., min_length=1, max_length=100)
    farm_type: FarmType = FarmType.SMALL
    address: Optional[str] = None
    village: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    total_area_acres: float = Field(..., gt=0)
    cultivable_area_acres: Optional[float] = None
    soil_type: Optional[str] = None
    water_source: Optional[str] = None
    irrigation_type: Optional[str] = "manual"


class FarmCreate(FarmBase):
    """Farm creation schema"""
    is_primary: bool = False


class FarmUpdate(BaseModel):
    """Farm update schema"""
    name: Optional[str] = None
    farm_type: Optional[FarmType] = None
    address: Optional[str] = None
    village: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    total_area_acres: Optional[float] = None
    cultivable_area_acres: Optional[float] = None
    soil_type: Optional[str] = None
    water_source: Optional[str] = None
    irrigation_type: Optional[str] = None
    elevation_meters: Optional[float] = None
    annual_rainfall_mm: Optional[float] = None
    soil_ph: Optional[float] = None
    organic_matter_percent: Optional[float] = None
    is_primary: Optional[bool] = None


class FarmResponse(FarmBase):
    """Farm response schema"""
    id: str
    user_id: str
    elevation_meters: Optional[float] = None
    annual_rainfall_mm: Optional[float] = None
    soil_ph: Optional[float] = None
    organic_matter_percent: Optional[float] = None
    is_primary: bool = False
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# =========================================================================
# CROP SCHEMAS
# =========================================================================

class CropBase(BaseModel):
    """Crop base schema"""
    crop_master_id: int
    variety: Optional[str] = None
    area_acres: float = Field(..., gt=0)
    sowing_date: Optional[date] = None
    expected_harvest_date: Optional[date] = None


class CropCreate(CropBase):
    """Crop creation schema"""
    farm_id: str
    zone_id: Optional[str] = None
    notes: Optional[str] = None


class CropUpdate(BaseModel):
    """Crop update schema"""
    variety: Optional[str] = None
    status: Optional[CropStatus] = None
    area_acres: Optional[float] = None
    sowing_date: Optional[date] = None
    expected_harvest_date: Optional[date] = None
    actual_harvest_date: Optional[date] = None
    expected_yield: Optional[float] = None
    actual_yield: Optional[float] = None
    seed_cost: Optional[float] = None
    fertilizer_cost: Optional[float] = None
    pesticide_cost: Optional[float] = None
    labor_cost: Optional[float] = None
    irrigation_cost: Optional[float] = None
    other_cost: Optional[float] = None
    health_score: Optional[int] = Field(None, ge=0, le=100)
    notes: Optional[str] = None


class CropResponse(CropBase):
    """Crop response schema"""
    id: str
    farm_id: str
    zone_id: Optional[str] = None
    user_id: str
    status: CropStatus = CropStatus.PLANNED
    actual_harvest_date: Optional[date] = None
    expected_yield: Optional[float] = None
    actual_yield: Optional[float] = None
    yield_unit: str = "kg"
    seed_cost: float = 0
    fertilizer_cost: float = 0
    pesticide_cost: float = 0
    labor_cost: float = 0
    irrigation_cost: float = 0
    other_cost: float = 0
    health_score: int = 100
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    
    # Computed fields
    total_investment: Optional[float] = None
    crop_name: Optional[str] = None
    
    class Config:
        from_attributes = True


# =========================================================================
# DISEASE SCAN SCHEMAS
# =========================================================================

class DiseaseScanCreate(BaseModel):
    """Disease scan creation schema"""
    image_url: str
    crop_id: Optional[str] = None
    farm_id: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class DiseaseScanResponse(BaseModel):
    """Disease scan response schema"""
    id: str
    user_id: str
    crop_id: Optional[str] = None
    farm_id: Optional[str] = None
    image_url: str
    detected_disease_id: Optional[int] = None
    disease_name: Optional[str] = None
    confidence_score: Optional[float] = None
    severity: DiseaseSeverity = DiseaseSeverity.NONE
    affected_area_percent: Optional[float] = None
    ai_analysis: Optional[str] = None
    recommended_actions: Optional[List[str]] = None
    estimated_yield_impact: Optional[float] = None
    is_verified: bool = False
    created_at: datetime
    
    class Config:
        from_attributes = True


class DiseaseInfo(BaseModel):
    """Disease information schema"""
    id: int
    name: str
    local_name: Optional[str] = None
    category: str
    symptoms: str
    causes: Optional[str] = None
    prevention: Optional[str] = None
    organic_treatment: Optional[str] = None
    chemical_treatment: Optional[str] = None


# =========================================================================
# PRICE SCHEMAS
# =========================================================================

class CropPriceResponse(BaseModel):
    """Crop price response schema"""
    id: str
    crop_master_id: int
    crop_name: Optional[str] = None
    market_id: str
    market_name: Optional[str] = None
    recorded_date: date
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    modal_price: Optional[float] = None
    arrival_quantity: Optional[float] = None
    grade: Optional[str] = None
    variety: Optional[str] = None
    
    class Config:
        from_attributes = True


class PricePredictionResponse(BaseModel):
    """Price prediction response schema"""
    crop_name: str
    market_name: Optional[str] = None
    prediction_date: date
    target_date: date
    predicted_min: float
    predicted_max: float
    predicted_modal: float
    confidence_score: float
    trend: str  # rising, stable, falling
    recommendation: Optional[str] = None
    best_sell_window_start: Optional[date] = None
    best_sell_window_end: Optional[date] = None


# =========================================================================
# MARKETPLACE SCHEMAS
# =========================================================================

class ListingBase(BaseModel):
    """Listing base schema"""
    title: str = Field(..., min_length=5, max_length=200)
    description: Optional[str] = None
    crop_name: str
    variety: Optional[str] = None
    grade: Optional[str] = None
    quantity: float = Field(..., gt=0)
    unit: str = "kg"
    price_per_unit: float = Field(..., gt=0)
    min_order_quantity: Optional[float] = None
    negotiable: bool = True


class ListingCreate(ListingBase):
    """Listing creation schema"""
    crop_id: Optional[str] = None
    crop_master_id: Optional[int] = None
    available_from: Optional[date] = None
    pickup_address: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    delivery_available: bool = False
    delivery_radius_km: Optional[int] = None
    images: Optional[List[str]] = None
    is_organic: bool = False
    certifications: Optional[List[str]] = None


class ListingUpdate(BaseModel):
    """Listing update schema"""
    title: Optional[str] = None
    description: Optional[str] = None
    quantity: Optional[float] = None
    price_per_unit: Optional[float] = None
    min_order_quantity: Optional[float] = None
    negotiable: Optional[bool] = None
    available_from: Optional[date] = None
    delivery_available: Optional[bool] = None
    delivery_radius_km: Optional[int] = None
    images: Optional[List[str]] = None
    status: Optional[ListingStatus] = None


class ListingResponse(ListingBase):
    """Listing response schema"""
    id: str
    user_id: str
    crop_id: Optional[str] = None
    crop_master_id: Optional[int] = None
    available_from: Optional[date] = None
    pickup_address: Optional[str] = None
    city: Optional[str] = None
    district: Optional[str] = None
    state: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    delivery_available: bool = False
    delivery_radius_km: Optional[int] = None
    images: Optional[List[str]] = None
    is_organic: bool = False
    certifications: Optional[List[str]] = None
    status: ListingStatus = ListingStatus.ACTIVE
    views_count: int = 0
    inquiries_count: int = 0
    created_at: datetime
    updated_at: datetime
    
    # Seller info
    seller_name: Optional[str] = None
    seller_phone: Optional[str] = None
    
    class Config:
        from_attributes = True


class ListingInquiryCreate(BaseModel):
    """Listing inquiry creation schema"""
    listing_id: str
    offered_price: Optional[float] = None
    requested_quantity: Optional[float] = None
    message: Optional[str] = None


class ListingInquiryResponse(BaseModel):
    """Listing inquiry response schema"""
    id: str
    listing_id: str
    buyer_id: str
    buyer_name: Optional[str] = None
    offered_price: Optional[float] = None
    requested_quantity: Optional[float] = None
    message: Optional[str] = None
    status: str = "pending"
    seller_response: Optional[str] = None
    responded_at: Optional[datetime] = None
    created_at: datetime


# =========================================================================
# WEATHER SCHEMAS
# =========================================================================

class WeatherResponse(BaseModel):
    """Weather response schema"""
    latitude: float
    longitude: float
    recorded_at: datetime
    temperature_celsius: Optional[float] = None
    feels_like_celsius: Optional[float] = None
    humidity_percent: Optional[int] = None
    pressure_hpa: Optional[float] = None
    wind_speed_kmh: Optional[float] = None
    wind_direction_deg: Optional[int] = None
    visibility_km: Optional[float] = None
    uv_index: Optional[float] = None
    rain_mm: float = 0
    weather_description: Optional[str] = None
    icon_code: Optional[str] = None


class WeatherForecastResponse(BaseModel):
    """Weather forecast response schema"""
    date: date
    temp_min: float
    temp_max: float
    humidity: int
    rain_chance: int
    weather_description: str
    icon_code: str
    wind_speed: float
    uv_index: float


class FarmingAdvisory(BaseModel):
    """Farming advisory based on weather"""
    title: str
    description: str
    priority: str  # high, medium, low
    category: str  # irrigation, pest, harvest, etc.
    icon: str


# =========================================================================
# TRANSACTION SCHEMAS
# =========================================================================

class TransactionBase(BaseModel):
    """Transaction base schema"""
    transaction_type: TransactionType
    category: str
    subcategory: Optional[str] = None
    amount: float = Field(..., gt=0)
    description: Optional[str] = None
    transaction_date: date


class TransactionCreate(TransactionBase):
    """Transaction creation schema"""
    farm_id: Optional[str] = None
    crop_id: Optional[str] = None
    party_name: Optional[str] = None
    party_phone: Optional[str] = None
    payment_method: Optional[str] = None
    reference_number: Optional[str] = None
    tags: Optional[List[str]] = None


class TransactionUpdate(BaseModel):
    """Transaction update schema"""
    category: Optional[str] = None
    subcategory: Optional[str] = None
    amount: Optional[float] = None
    description: Optional[str] = None
    transaction_date: Optional[date] = None
    party_name: Optional[str] = None
    payment_method: Optional[str] = None
    tags: Optional[List[str]] = None


class TransactionResponse(TransactionBase):
    """Transaction response schema"""
    id: str
    user_id: str
    farm_id: Optional[str] = None
    crop_id: Optional[str] = None
    party_name: Optional[str] = None
    party_phone: Optional[str] = None
    payment_method: Optional[str] = None
    reference_number: Optional[str] = None
    tags: Optional[List[str]] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


class FinanceSummary(BaseModel):
    """Finance summary schema"""
    total_income: float
    total_expense: float
    net_profit: float
    profit_margin: float
    income_by_category: Dict[str, float]
    expense_by_category: Dict[str, float]
    monthly_trend: List[Dict[str, Any]]


# =========================================================================
# ALERT SCHEMAS
# =========================================================================

class AlertCreate(BaseModel):
    """Alert creation schema"""
    alert_type: AlertType
    severity: AlertSeverity
    title: str
    message: str
    farm_id: Optional[str] = None
    related_crop_id: Optional[str] = None
    action_required: bool = False
    action_url: Optional[str] = None
    action_label: Optional[str] = None
    scheduled_for: Optional[datetime] = None
    expires_at: Optional[datetime] = None


class AlertResponse(BaseModel):
    """Alert response schema"""
    id: str
    user_id: str
    farm_id: Optional[str] = None
    alert_type: AlertType
    severity: AlertSeverity
    title: str
    message: str
    related_crop_id: Optional[str] = None
    action_required: bool = False
    action_url: Optional[str] = None
    action_label: Optional[str] = None
    is_read: bool = False
    read_at: Optional[datetime] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


# =========================================================================
# IRRIGATION SCHEMAS
# =========================================================================

class IrrigationScheduleCreate(BaseModel):
    """Irrigation schedule creation schema"""
    farm_id: str
    zone_id: Optional[str] = None
    crop_id: Optional[str] = None
    schedule_type: str = "manual"
    start_time: str  # HH:MM format
    duration_minutes: int = Field(..., gt=0)
    days_of_week: List[int] = Field(..., min_items=1)  # 0-6
    soil_moisture_threshold: Optional[float] = None
    weather_aware: bool = False
    skip_if_rain: bool = True
    water_volume_liters: Optional[float] = None


class IrrigationScheduleResponse(BaseModel):
    """Irrigation schedule response schema"""
    id: str
    farm_id: str
    zone_id: Optional[str] = None
    crop_id: Optional[str] = None
    user_id: str
    schedule_type: str
    start_time: str
    duration_minutes: int
    days_of_week: List[int]
    soil_moisture_threshold: Optional[float] = None
    weather_aware: bool = False
    skip_if_rain: bool = True
    water_volume_liters: Optional[float] = None
    is_active: bool = True
    next_run_at: Optional[datetime] = None
    last_run_at: Optional[datetime] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


# =========================================================================
# LEARNING SCHEMAS
# =========================================================================

class LearningContentResponse(BaseModel):
    """Learning content response schema"""
    id: str
    title: str
    description: Optional[str] = None
    content_type: str
    category: str
    content_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    duration_minutes: Optional[int] = None
    body: Optional[str] = None
    difficulty_level: Optional[str] = None
    tags: Optional[List[str]] = None
    views_count: int = 0
    likes_count: int = 0
    author_name: Optional[str] = None
    is_premium: bool = False
    
    class Config:
        from_attributes = True


# =========================================================================
# CARBON & SUSTAINABILITY SCHEMAS
# =========================================================================

class CarbonRecordCreate(BaseModel):
    """Carbon record creation schema"""
    farm_id: str
    record_date: date
    fertilizer_emissions: float = 0
    fuel_emissions: float = 0
    electricity_emissions: float = 0
    livestock_emissions: float = 0
    other_emissions: float = 0
    crop_sequestration: float = 0
    tree_sequestration: float = 0
    soil_sequestration: float = 0
    notes: Optional[str] = None


class CarbonRecordResponse(BaseModel):
    """Carbon record response schema"""
    id: str
    user_id: str
    farm_id: str
    record_date: date
    fertilizer_emissions: float
    fuel_emissions: float
    electricity_emissions: float
    livestock_emissions: float
    other_emissions: float
    crop_sequestration: float
    tree_sequestration: float
    soil_sequestration: float
    net_emissions: float
    notes: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


class SustainabilitySummary(BaseModel):
    """Sustainability summary schema"""
    total_emissions: float
    total_sequestration: float
    net_footprint: float
    carbon_intensity: float  # kg CO2 per acre
    eco_score: int  # 0-100
    recommendations: List[str]
    comparison_to_average: float  # percentage


# =========================================================================
# CROP RECOMMENDATION SCHEMAS
# =========================================================================

class CropRecommendationResponse(BaseModel):
    """Crop recommendation response schema"""
    id: str
    crop_master_id: int
    crop_name: str
    suitability_score: float
    expected_yield_per_acre: Optional[float] = None
    expected_profit_per_acre: Optional[float] = None
    risk_score: Optional[float] = None
    factors: Optional[Dict[str, Any]] = None
    recommendation_text: Optional[str] = None
    recommended_sowing_start: Optional[date] = None
    recommended_sowing_end: Optional[date] = None
    season: Optional[str] = None
    water_requirement: Optional[str] = None
    price_trend: Optional[str] = None
    demand_level: Optional[str] = None
    
    class Config:
        from_attributes = True


# =========================================================================
# DASHBOARD SCHEMAS
# =========================================================================

class DashboardSummary(BaseModel):
    """Dashboard summary schema"""
    user_name: str
    total_farms: int
    total_area_acres: float
    active_crops: int
    unread_alerts: int
    active_listings: int
    weather: Optional[WeatherResponse] = None
    recent_alerts: List[AlertResponse] = []
    crop_health_score: float
    finance_summary: Optional[FinanceSummary] = None


# =========================================================================
# SEARCH & FILTER SCHEMAS
# =========================================================================

class SearchFilters(BaseModel):
    """Generic search filters"""
    query: Optional[str] = None
    page: int = Field(1, ge=1)
    per_page: int = Field(20, ge=1, le=100)
    sort_by: Optional[str] = None
    sort_order: str = "desc"


class ListingFilters(SearchFilters):
    """Listing specific filters"""
    crop_name: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    is_organic: Optional[bool] = None
    delivery_available: Optional[bool] = None


class PriceFilters(SearchFilters):
    """Price specific filters"""
    crop_id: Optional[int] = None
    market_id: Optional[str] = None
    state: Optional[str] = None
    date_from: Optional[date] = None
    date_to: Optional[date] = None
