-- ============================================================================
-- AGRISENSE PRO - Complete PostgreSQL Database Schema
-- AI Crop Intelligence & Farmer Profit Engine
-- Version: 1.0.0
-- ============================================================================
-- This schema is manually designed following best practices:
-- - Proper normalization (3NF where appropriate)
-- - Comprehensive indexing strategy
-- - Foreign key constraints for data integrity
-- - Check constraints for data validation
-- - Timestamps for audit trails
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";  -- For geospatial data (optional)

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

CREATE TYPE user_role AS ENUM ('farmer', 'trader', 'expert', 'admin');
CREATE TYPE farm_type AS ENUM ('small', 'medium', 'large', 'commercial');
CREATE TYPE crop_status AS ENUM ('planned', 'planted', 'growing', 'harvesting', 'harvested', 'failed');
CREATE TYPE disease_severity AS ENUM ('none', 'low', 'medium', 'high', 'critical');
CREATE TYPE alert_type AS ENUM ('weather', 'disease', 'price', 'irrigation', 'harvest', 'market', 'general');
CREATE TYPE alert_severity AS ENUM ('info', 'warning', 'high', 'critical');
CREATE TYPE listing_status AS ENUM ('draft', 'active', 'sold', 'expired', 'cancelled');
CREATE TYPE transaction_type AS ENUM ('income', 'expense');
CREATE TYPE irrigation_type AS ENUM ('drip', 'sprinkler', 'flood', 'manual', 'smart');
CREATE TYPE subscription_tier AS ENUM ('free', 'basic', 'premium', 'enterprise');

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Users Table (Farmers, Traders, Experts)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    role user_role DEFAULT 'farmer',
    subscription_tier subscription_tier DEFAULT 'free',
    
    -- Location info
    address TEXT,
    city VARCHAR(100),
    district VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(50) DEFAULT 'India',
    pincode VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Preferences
    language VARCHAR(10) DEFAULT 'en',
    preferred_units VARCHAR(10) DEFAULT 'metric',
    notification_enabled BOOLEAN DEFAULT TRUE,
    
    -- Verification
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    kyc_verified BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Sessions Table (For JWT refresh tokens)
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(500) NOT NULL,
    device_info TEXT,
    ip_address INET,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_valid BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- FARM MANAGEMENT TABLES
-- ============================================================================

-- Farms Table
CREATE TABLE farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    farm_type farm_type DEFAULT 'small',
    
    -- Location
    address TEXT,
    village VARCHAR(100),
    district VARCHAR(100),
    state VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Size and details
    total_area_acres DECIMAL(10, 2) NOT NULL,
    cultivable_area_acres DECIMAL(10, 2),
    soil_type VARCHAR(50),
    water_source VARCHAR(100),
    irrigation_type irrigation_type DEFAULT 'manual',
    
    -- Digital twin data
    elevation_meters DECIMAL(8, 2),
    annual_rainfall_mm DECIMAL(8, 2),
    soil_ph DECIMAL(4, 2),
    organic_matter_percent DECIMAL(5, 2),
    
    -- Status
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_area CHECK (total_area_acres > 0)
);

-- Farm Zones/Sections
CREATE TABLE farm_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    area_acres DECIMAL(10, 2) NOT NULL,
    soil_type VARCHAR(50),
    irrigation_type irrigation_type,
    current_crop_id UUID,  -- Will reference crops table
    polygon_coordinates JSONB,  -- GeoJSON for zone boundaries
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CROP MANAGEMENT TABLES
-- ============================================================================

-- Crop Master Data (Reference table)
CREATE TABLE crop_master (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    local_name VARCHAR(100),
    scientific_name VARCHAR(150),
    category VARCHAR(50),  -- cereals, pulses, vegetables, fruits, cash crops
    season VARCHAR(50),  -- kharif, rabi, zaid
    
    -- Growing requirements
    min_temp_celsius DECIMAL(4, 1),
    max_temp_celsius DECIMAL(4, 1),
    water_requirement_mm DECIMAL(8, 2),
    growing_days_min INTEGER,
    growing_days_max INTEGER,
    soil_types TEXT[],
    
    -- Economic data
    typical_yield_per_acre DECIMAL(10, 2),
    yield_unit VARCHAR(20) DEFAULT 'kg',
    
    image_url TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Crops (Actual planted crops on farms)
CREATE TABLE crops (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES farm_zones(id) ON DELETE SET NULL,
    crop_master_id INTEGER REFERENCES crop_master(id),
    user_id UUID NOT NULL REFERENCES users(id),
    
    variety VARCHAR(100),
    status crop_status DEFAULT 'planned',
    area_acres DECIMAL(10, 2) NOT NULL,
    
    -- Timeline
    sowing_date DATE,
    expected_harvest_date DATE,
    actual_harvest_date DATE,
    
    -- Yield data
    expected_yield DECIMAL(10, 2),
    actual_yield DECIMAL(10, 2),
    yield_unit VARCHAR(20) DEFAULT 'kg',
    
    -- Investment tracking
    seed_cost DECIMAL(12, 2) DEFAULT 0,
    fertilizer_cost DECIMAL(12, 2) DEFAULT 0,
    pesticide_cost DECIMAL(12, 2) DEFAULT 0,
    labor_cost DECIMAL(12, 2) DEFAULT 0,
    irrigation_cost DECIMAL(12, 2) DEFAULT 0,
    other_cost DECIMAL(12, 2) DEFAULT 0,
    
    -- Health score (0-100)
    health_score INTEGER DEFAULT 100,
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_crop_area CHECK (area_acres > 0),
    CONSTRAINT valid_health_score CHECK (health_score >= 0 AND health_score <= 100)
);

-- Crop Activities Log
CREATE TABLE crop_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_id UUID NOT NULL REFERENCES crops(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    
    activity_type VARCHAR(50) NOT NULL,  -- sowing, fertilizer, pesticide, irrigation, weeding, harvesting
    activity_date DATE NOT NULL,
    description TEXT,
    quantity DECIMAL(10, 2),
    unit VARCHAR(20),
    cost DECIMAL(12, 2) DEFAULT 0,
    
    -- Weather conditions during activity
    temperature DECIMAL(4, 1),
    humidity INTEGER,
    weather_condition VARCHAR(50),
    
    images TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DISEASE DETECTION TABLES
-- ============================================================================

-- Disease Master Data
CREATE TABLE disease_master (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    local_name VARCHAR(100),
    scientific_name VARCHAR(150),
    category VARCHAR(50),  -- fungal, bacterial, viral, pest, deficiency
    affected_crops INTEGER[],  -- References crop_master.id
    
    symptoms TEXT NOT NULL,
    causes TEXT,
    prevention TEXT,
    organic_treatment TEXT,
    chemical_treatment TEXT,
    
    severity_indicators JSONB,
    image_urls TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Disease Scans (User-submitted disease detection)
CREATE TABLE disease_scans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    farm_id UUID REFERENCES farms(id) ON DELETE SET NULL,
    
    image_url TEXT NOT NULL,
    
    -- AI Detection Results
    detected_disease_id INTEGER REFERENCES disease_master(id),
    disease_name VARCHAR(100),
    confidence_score DECIMAL(5, 4),  -- 0.0000 to 1.0000
    severity disease_severity DEFAULT 'none',
    affected_area_percent DECIMAL(5, 2),
    
    -- AI Analysis
    ai_analysis TEXT,
    recommended_actions TEXT[],
    estimated_yield_impact DECIMAL(5, 2),
    
    -- Location
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- Status
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(id),
    expert_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- WEATHER & CLIMATE TABLES
-- ============================================================================

-- Weather Data (Cached from external APIs)
CREATE TABLE weather_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Current conditions
    temperature_celsius DECIMAL(5, 2),
    feels_like_celsius DECIMAL(5, 2),
    humidity_percent INTEGER,
    pressure_hpa DECIMAL(7, 2),
    wind_speed_kmh DECIMAL(6, 2),
    wind_direction_deg INTEGER,
    visibility_km DECIMAL(6, 2),
    uv_index DECIMAL(4, 2),
    
    -- Precipitation
    rain_mm DECIMAL(6, 2) DEFAULT 0,
    snow_mm DECIMAL(6, 2) DEFAULT 0,
    
    -- Conditions
    weather_code INTEGER,
    weather_description VARCHAR(100),
    icon_code VARCHAR(20),
    
    -- Forecast flag
    is_forecast BOOLEAN DEFAULT FALSE,
    forecast_date DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_humidity CHECK (humidity_percent >= 0 AND humidity_percent <= 100)
);

-- Weather Alerts
CREATE TABLE weather_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    
    alert_type VARCHAR(50) NOT NULL,  -- storm, frost, heatwave, flood, drought
    severity alert_severity NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    
    recommended_actions TEXT[],
    is_read BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PRICE & MARKET TABLES
-- ============================================================================

-- Market Master Data
CREATE TABLE markets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    market_type VARCHAR(50),  -- mandi, apmc, private, cooperative
    
    address TEXT,
    city VARCHAR(100),
    district VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    website TEXT,
    
    operating_days VARCHAR(100),
    operating_hours VARCHAR(100),
    
    available_crops TEXT[],
    facilities TEXT[],
    
    is_verified BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Price Data
CREATE TABLE crop_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_master_id INTEGER NOT NULL REFERENCES crop_master(id),
    market_id UUID NOT NULL REFERENCES markets(id),
    
    recorded_date DATE NOT NULL,
    
    -- Prices per quintal (100 kg)
    min_price DECIMAL(12, 2),
    max_price DECIMAL(12, 2),
    modal_price DECIMAL(12, 2),  -- Most common price
    
    -- Volume
    arrival_quantity DECIMAL(12, 2),  -- In quintals
    
    -- Quality grade
    grade VARCHAR(10),
    variety VARCHAR(100),
    
    -- Source
    source VARCHAR(100),  -- e.g., 'agmarknet', 'manual', 'api'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(crop_master_id, market_id, recorded_date, grade)
);

-- Price Predictions
CREATE TABLE price_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_master_id INTEGER NOT NULL REFERENCES crop_master(id),
    market_id UUID REFERENCES markets(id),
    
    prediction_date DATE NOT NULL,
    target_date DATE NOT NULL,
    
    predicted_min DECIMAL(12, 2),
    predicted_max DECIMAL(12, 2),
    predicted_modal DECIMAL(12, 2),
    confidence_score DECIMAL(5, 4),
    
    -- Factors considered
    factors JSONB,
    
    -- Recommendation
    recommendation TEXT,
    best_sell_window_start DATE,
    best_sell_window_end DATE,
    
    model_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Price Alerts (User-defined)
CREATE TABLE price_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    crop_master_id INTEGER NOT NULL REFERENCES crop_master(id),
    market_id UUID REFERENCES markets(id),
    
    alert_type VARCHAR(20) NOT NULL,  -- 'above', 'below', 'change'
    target_price DECIMAL(12, 2),
    percent_change DECIMAL(5, 2),  -- For 'change' type
    
    is_triggered BOOLEAN DEFAULT FALSE,
    triggered_at TIMESTAMP WITH TIME ZONE,
    triggered_price DECIMAL(12, 2),
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- MARKETPLACE TABLES
-- ============================================================================

-- Marketplace Listings
CREATE TABLE listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    crop_master_id INTEGER REFERENCES crop_master(id),
    
    title VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Product details
    crop_name VARCHAR(100) NOT NULL,
    variety VARCHAR(100),
    grade VARCHAR(20),
    quantity DECIMAL(12, 2) NOT NULL,
    unit VARCHAR(20) DEFAULT 'kg',
    available_from DATE,
    
    -- Pricing
    price_per_unit DECIMAL(12, 2) NOT NULL,
    min_order_quantity DECIMAL(10, 2),
    negotiable BOOLEAN DEFAULT TRUE,
    
    -- Location
    pickup_address TEXT,
    city VARCHAR(100),
    district VARCHAR(100),
    state VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    delivery_available BOOLEAN DEFAULT FALSE,
    delivery_radius_km INTEGER,
    
    -- Media
    images TEXT[],
    
    -- Quality certification
    is_organic BOOLEAN DEFAULT FALSE,
    certifications TEXT[],
    
    -- Status
    status listing_status DEFAULT 'active',
    views_count INTEGER DEFAULT 0,
    inquiries_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT positive_quantity CHECK (quantity > 0),
    CONSTRAINT positive_price CHECK (price_per_unit > 0)
);

-- Listing Inquiries/Bids
CREATE TABLE listing_inquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    buyer_id UUID NOT NULL REFERENCES users(id),
    
    offered_price DECIMAL(12, 2),
    requested_quantity DECIMAL(10, 2),
    message TEXT,
    
    status VARCHAR(20) DEFAULT 'pending',  -- pending, accepted, rejected, completed
    
    seller_response TEXT,
    responded_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FINANCE TABLES
-- ============================================================================

-- Financial Transactions
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES farms(id) ON DELETE SET NULL,
    crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    
    transaction_type transaction_type NOT NULL,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50),
    
    amount DECIMAL(14, 2) NOT NULL,
    description TEXT,
    
    -- Party details
    party_name VARCHAR(200),
    party_phone VARCHAR(20),
    
    -- Payment details
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    
    transaction_date DATE NOT NULL,
    
    -- Attachments
    receipt_images TEXT[],
    
    -- Tags for analytics
    tags TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT positive_amount CHECK (amount > 0)
);

-- Loans Tracking
CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    loan_type VARCHAR(50) NOT NULL,  -- crop_loan, kcc, equipment, land
    lender_name VARCHAR(200) NOT NULL,
    lender_type VARCHAR(50),  -- bank, nbfc, cooperative, mfi
    
    principal_amount DECIMAL(14, 2) NOT NULL,
    interest_rate DECIMAL(5, 2) NOT NULL,
    tenure_months INTEGER NOT NULL,
    
    disbursement_date DATE,
    first_emi_date DATE,
    emi_amount DECIMAL(12, 2),
    
    total_paid DECIMAL(14, 2) DEFAULT 0,
    outstanding_amount DECIMAL(14, 2),
    
    status VARCHAR(20) DEFAULT 'active',  -- pending, active, closed, defaulted
    
    collateral_details TEXT,
    documents TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- IRRIGATION TABLES
-- ============================================================================

-- Irrigation Schedules
CREATE TABLE irrigation_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES farm_zones(id) ON DELETE CASCADE,
    crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id),
    
    schedule_type VARCHAR(20) NOT NULL,  -- manual, auto, smart
    
    -- Timing
    start_time TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    days_of_week INTEGER[],  -- 0=Sunday to 6=Saturday
    
    -- Smart irrigation parameters
    soil_moisture_threshold DECIMAL(5, 2),
    weather_aware BOOLEAN DEFAULT FALSE,
    skip_if_rain BOOLEAN DEFAULT TRUE,
    
    -- Water usage
    water_volume_liters DECIMAL(10, 2),
    
    is_active BOOLEAN DEFAULT TRUE,
    next_run_at TIMESTAMP WITH TIME ZONE,
    last_run_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Irrigation Logs
CREATE TABLE irrigation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID REFERENCES irrigation_schedules(id) ON DELETE SET NULL,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    zone_id UUID REFERENCES farm_zones(id),
    
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    
    water_used_liters DECIMAL(10, 2),
    
    -- Conditions
    soil_moisture_before DECIMAL(5, 2),
    soil_moisture_after DECIMAL(5, 2),
    temperature DECIMAL(5, 2),
    humidity INTEGER,
    
    trigger_type VARCHAR(20),  -- scheduled, manual, auto, smart
    status VARCHAR(20) DEFAULT 'completed',  -- running, completed, failed, skipped
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ALERTS & NOTIFICATIONS TABLES
-- ============================================================================

-- General Alerts
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    
    alert_type alert_type NOT NULL,
    severity alert_severity NOT NULL,
    
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    
    -- Related entities
    related_crop_id UUID REFERENCES crops(id) ON DELETE SET NULL,
    related_listing_id UUID REFERENCES listings(id) ON DELETE SET NULL,
    
    -- Actions
    action_required BOOLEAN DEFAULT FALSE,
    action_url TEXT,
    action_label VARCHAR(50),
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    is_dismissed BOOLEAN DEFAULT FALSE,
    
    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notification Preferences
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Channels
    push_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    
    -- Alert types
    weather_alerts BOOLEAN DEFAULT TRUE,
    disease_alerts BOOLEAN DEFAULT TRUE,
    price_alerts BOOLEAN DEFAULT TRUE,
    irrigation_alerts BOOLEAN DEFAULT TRUE,
    market_alerts BOOLEAN DEFAULT TRUE,
    
    -- Timing
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id)
);

-- ============================================================================
-- LEARNING & ADVISORY TABLES
-- ============================================================================

-- Learning Content
CREATE TABLE learning_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    title VARCHAR(200) NOT NULL,
    description TEXT,
    content_type VARCHAR(20) NOT NULL,  -- article, video, infographic, course
    category VARCHAR(50) NOT NULL,
    
    content_url TEXT,
    thumbnail_url TEXT,
    duration_minutes INTEGER,
    
    -- For articles
    body TEXT,
    
    -- Metadata
    difficulty_level VARCHAR(20),  -- beginner, intermediate, advanced
    tags TEXT[],
    languages TEXT[],
    
    -- Related crops
    related_crop_ids INTEGER[],
    
    -- Stats
    views_count INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    
    author_name VARCHAR(100),
    author_credentials VARCHAR(200),
    
    is_premium BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT TRUE,
    
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Learning Progress
CREATE TABLE user_learning_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES learning_content(id) ON DELETE CASCADE,
    
    progress_percent INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    bookmarked BOOLEAN DEFAULT FALSE,
    liked BOOLEAN DEFAULT FALSE,
    
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, content_id),
    CONSTRAINT valid_progress CHECK (progress_percent >= 0 AND progress_percent <= 100)
);

-- ============================================================================
-- SUSTAINABILITY & CARBON TABLES
-- ============================================================================

-- Carbon Footprint Tracking
CREATE TABLE carbon_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    
    record_date DATE NOT NULL,
    
    -- Emissions (in kg CO2 equivalent)
    fertilizer_emissions DECIMAL(10, 2) DEFAULT 0,
    fuel_emissions DECIMAL(10, 2) DEFAULT 0,
    electricity_emissions DECIMAL(10, 2) DEFAULT 0,
    livestock_emissions DECIMAL(10, 2) DEFAULT 0,
    other_emissions DECIMAL(10, 2) DEFAULT 0,
    
    -- Sequestration (negative = carbon absorbed)
    crop_sequestration DECIMAL(10, 2) DEFAULT 0,
    tree_sequestration DECIMAL(10, 2) DEFAULT 0,
    soil_sequestration DECIMAL(10, 2) DEFAULT 0,
    
    -- Net footprint
    net_emissions DECIMAL(10, 2) GENERATED ALWAYS AS (
        fertilizer_emissions + fuel_emissions + electricity_emissions + 
        livestock_emissions + other_emissions - 
        crop_sequestration - tree_sequestration - soil_sequestration
    ) STORED,
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(farm_id, record_date)
);

-- Sustainability Practices
CREATE TABLE sustainability_practices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    
    practice_type VARCHAR(50) NOT NULL,  -- organic, conservation, renewable, water_saving
    practice_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    started_date DATE,
    
    -- Impact metrics
    carbon_offset_kg DECIMAL(10, 2),
    water_saved_liters DECIMAL(12, 2),
    cost_savings DECIMAL(12, 2),
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- VOICE ASSISTANT & AI TABLES
-- ============================================================================

-- Voice Query Logs
CREATE TABLE voice_queries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    audio_url TEXT,
    transcribed_text TEXT NOT NULL,
    detected_language VARCHAR(10),
    
    intent VARCHAR(50),  -- weather_query, price_query, disease_help, etc.
    entities JSONB,
    
    response_text TEXT,
    response_audio_url TEXT,
    
    confidence_score DECIMAL(5, 4),
    processing_time_ms INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CROP RECOMMENDATIONS TABLE
-- ============================================================================

-- AI-Generated Crop Recommendations
CREATE TABLE crop_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    
    crop_master_id INTEGER NOT NULL REFERENCES crop_master(id),
    
    -- Recommendation details
    suitability_score DECIMAL(5, 4) NOT NULL,  -- 0 to 1
    expected_yield_per_acre DECIMAL(10, 2),
    expected_profit_per_acre DECIMAL(12, 2),
    risk_score DECIMAL(5, 4),  -- 0 to 1, lower is better
    
    -- Reasoning
    factors JSONB,  -- soil_match, climate_match, market_demand, etc.
    recommendation_text TEXT,
    
    -- Timing
    recommended_sowing_start DATE,
    recommended_sowing_end DATE,
    
    season VARCHAR(20),
    
    -- Water requirements
    water_requirement VARCHAR(20),  -- low, medium, high
    irrigation_frequency VARCHAR(50),
    
    -- Market insights
    price_trend VARCHAR(20),  -- rising, stable, falling
    demand_level VARCHAR(20),  -- low, medium, high
    
    is_viewed BOOLEAN DEFAULT FALSE,
    is_followed BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until DATE
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_location ON users(state, district);

-- Sessions
CREATE INDEX idx_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(refresh_token);
CREATE INDEX idx_sessions_expires ON user_sessions(expires_at);

-- Farms
CREATE INDEX idx_farms_user ON farms(user_id);
CREATE INDEX idx_farms_location ON farms(state, district);

-- Crops
CREATE INDEX idx_crops_farm ON crops(farm_id);
CREATE INDEX idx_crops_user ON crops(user_id);
CREATE INDEX idx_crops_status ON crops(status);
CREATE INDEX idx_crops_dates ON crops(sowing_date, expected_harvest_date);

-- Disease Scans
CREATE INDEX idx_disease_scans_user ON disease_scans(user_id);
CREATE INDEX idx_disease_scans_crop ON disease_scans(crop_id);
CREATE INDEX idx_disease_scans_date ON disease_scans(created_at DESC);

-- Weather
CREATE INDEX idx_weather_farm ON weather_data(farm_id);
CREATE INDEX idx_weather_location ON weather_data(latitude, longitude);
CREATE INDEX idx_weather_time ON weather_data(recorded_at DESC);

-- Prices
CREATE INDEX idx_prices_crop ON crop_prices(crop_master_id);
CREATE INDEX idx_prices_market ON crop_prices(market_id);
CREATE INDEX idx_prices_date ON crop_prices(recorded_date DESC);
CREATE INDEX idx_prices_composite ON crop_prices(crop_master_id, market_id, recorded_date DESC);

-- Listings
CREATE INDEX idx_listings_user ON listings(user_id);
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_crop ON listings(crop_name);
CREATE INDEX idx_listings_location ON listings(state, district);
CREATE INDEX idx_listings_price ON listings(price_per_unit);

-- Transactions
CREATE INDEX idx_transactions_user ON transactions(user_id);
CREATE INDEX idx_transactions_farm ON transactions(farm_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX idx_transactions_type ON transactions(transaction_type, category);

-- Alerts
CREATE INDEX idx_alerts_user ON alerts(user_id);
CREATE INDEX idx_alerts_unread ON alerts(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_alerts_type ON alerts(alert_type, severity);

-- Learning
CREATE INDEX idx_learning_category ON learning_content(category);
CREATE INDEX idx_learning_type ON learning_content(content_type);

-- Carbon
CREATE INDEX idx_carbon_farm ON carbon_records(farm_id);
CREATE INDEX idx_carbon_date ON carbon_records(record_date DESC);

-- Recommendations
CREATE INDEX idx_recommendations_user ON crop_recommendations(user_id);
CREATE INDEX idx_recommendations_farm ON crop_recommendations(farm_id);
CREATE INDEX idx_recommendations_score ON crop_recommendations(suitability_score DESC);

-- ============================================================================
-- INITIAL SEED DATA - CROP MASTER
-- ============================================================================

INSERT INTO crop_master (name, local_name, scientific_name, category, season, min_temp_celsius, max_temp_celsius, water_requirement_mm, growing_days_min, growing_days_max, soil_types, typical_yield_per_acre, yield_unit) VALUES
('Rice', 'Dhaan', 'Oryza sativa', 'cereals', 'kharif', 20, 35, 1200, 120, 150, ARRAY['clay', 'loamy'], 2000, 'kg'),
('Wheat', 'Gehun', 'Triticum aestivum', 'cereals', 'rabi', 10, 25, 450, 120, 140, ARRAY['loamy', 'clay loam'], 1800, 'kg'),
('Maize', 'Makka', 'Zea mays', 'cereals', 'kharif', 18, 32, 600, 90, 120, ARRAY['loamy', 'sandy loam'], 2500, 'kg'),
('Cotton', 'Kapas', 'Gossypium hirsutum', 'cash_crops', 'kharif', 21, 35, 700, 150, 180, ARRAY['black', 'loamy'], 500, 'kg'),
('Sugarcane', 'Ganna', 'Saccharum officinarum', 'cash_crops', 'annual', 20, 35, 2000, 300, 365, ARRAY['loamy', 'clay loam'], 35000, 'kg'),
('Soybean', 'Soyabean', 'Glycine max', 'pulses', 'kharif', 20, 30, 500, 90, 120, ARRAY['loamy', 'clay loam'], 1200, 'kg'),
('Groundnut', 'Moongfali', 'Arachis hypogaea', 'oilseeds', 'kharif', 22, 32, 500, 100, 130, ARRAY['sandy loam', 'loamy'], 1500, 'kg'),
('Tomato', 'Tamatar', 'Solanum lycopersicum', 'vegetables', 'rabi', 15, 30, 600, 90, 120, ARRAY['loamy', 'sandy loam'], 10000, 'kg'),
('Onion', 'Pyaz', 'Allium cepa', 'vegetables', 'rabi', 13, 28, 400, 120, 150, ARRAY['loamy', 'sandy loam'], 12000, 'kg'),
('Potato', 'Aloo', 'Solanum tuberosum', 'vegetables', 'rabi', 15, 25, 500, 90, 120, ARRAY['sandy loam', 'loamy'], 15000, 'kg'),
('Grapes', 'Angoor', 'Vitis vinifera', 'fruits', 'perennial', 15, 35, 700, 365, 365, ARRAY['sandy loam', 'loamy'], 8000, 'kg'),
('Mango', 'Aam', 'Mangifera indica', 'fruits', 'perennial', 24, 45, 1000, 365, 365, ARRAY['loamy', 'alluvial'], 5000, 'kg'),
('Banana', 'Kela', 'Musa acuminata', 'fruits', 'perennial', 20, 35, 1800, 270, 365, ARRAY['loamy', 'clay loam'], 25000, 'kg'),
('Chilli', 'Mirchi', 'Capsicum annuum', 'vegetables', 'kharif', 20, 35, 600, 120, 150, ARRAY['loamy', 'sandy loam'], 2500, 'kg'),
('Turmeric', 'Haldi', 'Curcuma longa', 'spices', 'kharif', 20, 30, 1500, 240, 270, ARRAY['loamy', 'clay loam'], 2500, 'kg');

-- ============================================================================
-- INITIAL SEED DATA - DISEASE MASTER
-- ============================================================================

INSERT INTO disease_master (name, local_name, category, symptoms, causes, prevention, organic_treatment, chemical_treatment, affected_crops) VALUES
('Blast', 'Jhulsa', 'fungal', 'Spindle-shaped lesions on leaves with gray centers and brown margins. Neck rot causing panicle breakage.', 'Fungus Magnaporthe oryzae, spread by wind and water. Favored by high humidity and nitrogen.', 'Use resistant varieties, balanced fertilization, avoid excessive nitrogen, maintain field hygiene.', 'Trichoderma viride spray, neem oil application, silicon foliar spray.', 'Tricyclazole 75% WP @ 0.6g/L, Isoprothiolane 40% EC @ 1.5ml/L', ARRAY[1]),
('Bacterial Leaf Blight', 'Patti Jhulsa', 'bacterial', 'Water-soaked lesions at leaf margins turning yellow to white. Leaves dry from tips.', 'Bacterium Xanthomonas oryzae, spread through infected seeds and irrigation water.', 'Use certified seeds, avoid clipping seedlings, balanced fertilization.', 'Copper hydroxide spray, Pseudomonas fluorescens application.', 'Streptocycline 0.01% + Copper oxychloride 0.25%', ARRAY[1]),
('Powdery Mildew', 'Safed Chita', 'fungal', 'White powdery coating on leaves, stems, and fruits. Leaves curl and turn yellow.', 'Various Erysiphe species, favored by moderate temperature and humidity.', 'Proper spacing, avoid overcrowding, remove infected plant parts.', 'Milk spray (10%), baking soda solution, sulfur dust.', 'Sulfur 80% WP @ 2.5g/L, Hexaconazole 5% EC @ 1ml/L', ARRAY[8, 14]),
('Late Blight', 'Picheti Jhulsa', 'fungal', 'Dark water-soaked lesions on leaves and stems. White fungal growth under humid conditions.', 'Phytophthora infestans, spread by wind and rain. Favors cool, wet conditions.', 'Use disease-free seeds, proper drainage, avoid overhead irrigation.', 'Bordeaux mixture, copper-based fungicides.', 'Mancozeb 75% WP @ 2.5g/L, Metalaxyl + Mancozeb @ 2.5g/L', ARRAY[8, 10]),
('Downy Mildew', 'Mridu Romil', 'fungal', 'Yellow patches on upper leaf surface with grayish-white fungal growth underneath.', 'Various Peronospora species, spread by wind and water splash.', 'Good air circulation, avoid overhead watering, remove infected leaves.', 'Neem oil spray, potassium bicarbonate solution.', 'Metalaxyl 8% + Mancozeb 64% @ 2.5g/L', ARRAY[11]),
('Anthracnose', 'Shrinkage', 'fungal', 'Dark sunken lesions on fruits, leaves and stems. Salmon-colored spore masses in wet weather.', 'Colletotrichum species, spread by rain splash and infected seeds.', 'Use disease-free seeds, crop rotation, remove plant debris.', 'Trichoderma application, neem-based pesticides.', 'Carbendazim 50% WP @ 1g/L, Mancozeb 75% WP @ 2.5g/L', ARRAY[8, 12, 14]),
('Yellow Mosaic Virus', 'Peela Mosaic', 'viral', 'Yellow and green mosaic pattern on leaves. Stunted growth and reduced yield.', 'Transmitted by whiteflies. No cure once infected.', 'Control whitefly population, use resistant varieties, remove infected plants.', 'Neem oil to control vectors, reflective mulches.', 'Imidacloprid 17.8% SL @ 0.5ml/L for vector control', ARRAY[6]),
('Rust', 'Ratua', 'fungal', 'Orange to brown pustules on leaves. Severe infection causes leaf death.', 'Puccinia species, spread by wind. Favors moderate temperature and humidity.', 'Use resistant varieties, early sowing, remove volunteer plants.', 'Sulfur dust application, Trichoderma spray.', 'Propiconazole 25% EC @ 1ml/L, Tebuconazole 25% EC @ 1ml/L', ARRAY[2, 6]);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_farms_updated_at BEFORE UPDATE ON farms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_crops_updated_at BEFORE UPDATE ON crops FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_listings_updated_at BEFORE UPDATE ON listings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON loans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_irrigation_schedules_updated_at BEFORE UPDATE ON irrigation_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_preferences_updated_at BEFORE UPDATE ON notification_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to increment listing views
CREATE OR REPLACE FUNCTION increment_listing_views(listing_uuid UUID)
RETURNS void AS $$
BEGIN
    UPDATE listings SET views_count = views_count + 1 WHERE id = listing_uuid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- User Dashboard Summary View
CREATE VIEW user_dashboard_summary AS
SELECT 
    u.id as user_id,
    u.full_name,
    COUNT(DISTINCT f.id) as total_farms,
    COALESCE(SUM(f.total_area_acres), 0) as total_area,
    COUNT(DISTINCT c.id) as active_crops,
    COUNT(DISTINCT CASE WHEN a.is_read = FALSE THEN a.id END) as unread_alerts,
    COUNT(DISTINCT l.id) as active_listings
FROM users u
LEFT JOIN farms f ON u.id = f.user_id
LEFT JOIN crops c ON u.id = c.user_id AND c.status IN ('planted', 'growing')
LEFT JOIN alerts a ON u.id = a.user_id
LEFT JOIN listings l ON u.id = l.user_id AND l.status = 'active'
GROUP BY u.id, u.full_name;

-- Crop Performance View
CREATE VIEW crop_performance AS
SELECT 
    c.id,
    c.user_id,
    cm.name as crop_name,
    c.variety,
    c.area_acres,
    c.status,
    c.expected_yield,
    c.actual_yield,
    c.health_score,
    (c.seed_cost + c.fertilizer_cost + c.pesticide_cost + c.labor_cost + c.irrigation_cost + c.other_cost) as total_investment,
    c.sowing_date,
    c.expected_harvest_date,
    CASE 
        WHEN c.actual_yield IS NOT NULL AND c.expected_yield > 0 
        THEN ROUND((c.actual_yield / c.expected_yield * 100)::numeric, 2)
        ELSE NULL 
    END as yield_achievement_percent
FROM crops c
JOIN crop_master cm ON c.crop_master_id = cm.id;

-- ============================================================================
-- GRANTS (Adjust based on your database user setup)
-- ============================================================================

-- Example: GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO agrisense_app;
-- Example: GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO agrisense_app;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
