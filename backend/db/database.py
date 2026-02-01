"""
AgriSense Pro - Database Connection Manager
Pure Python database handling with connection pooling
Supports both PostgreSQL (production) and SQLite (development)
"""

import sqlite3
import contextlib
from typing import Any, Dict, List, Optional, Tuple, Generator
from datetime import datetime
import json
import uuid
import logging

from core.config import settings, get_database_url

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# =========================================================================
# DATABASE CONNECTION MANAGER
# =========================================================================

class DatabaseManager:
    """
    Database connection manager supporting SQLite and PostgreSQL.
    Implements connection pooling and transaction management.
    """
    
    def __init__(self):
        self.use_sqlite = settings.USE_SQLITE
        self.database_url = get_database_url()
        self._connection_pool: List[Any] = []
        self._pool_size = settings.DB_POOL_SIZE
        
        # Initialize database
        self._init_database()
    
    def _init_database(self):
        """Initialize database connection and create tables if needed"""
        if self.use_sqlite:
            self._init_sqlite()
        else:
            self._init_postgres()
    
    def _init_sqlite(self):
        """Initialize SQLite database with schema"""
        conn = sqlite3.connect(
            settings.SQLITE_PATH,
            check_same_thread=False
        )
        conn.row_factory = sqlite3.Row
        
        # Enable foreign keys
        conn.execute("PRAGMA foreign_keys = ON")
        
        # Create tables
        self._create_sqlite_tables(conn)
        
        conn.commit()
        conn.close()
        
        logger.info(f"SQLite database initialized: {settings.SQLITE_PATH}")
    
    def _init_postgres(self):
        """Initialize PostgreSQL connection pool"""
        try:
            import psycopg2
            from psycopg2 import pool
            
            self._pg_pool = pool.ThreadedConnectionPool(
                minconn=1,
                maxconn=self._pool_size,
                dsn=self.database_url
            )
            logger.info("PostgreSQL connection pool initialized")
        except Exception as e:
            logger.error(f"Failed to initialize PostgreSQL: {e}")
            logger.info("Falling back to SQLite")
            self.use_sqlite = True
            self._init_sqlite()
    
    @contextlib.contextmanager
    def get_connection(self) -> Generator:
        """Get a database connection from the pool"""
        conn = None
        try:
            if self.use_sqlite:
                conn = sqlite3.connect(
                    settings.SQLITE_PATH,
                    check_same_thread=False
                )
                conn.row_factory = sqlite3.Row
                conn.execute("PRAGMA foreign_keys = ON")
            else:
                conn = self._pg_pool.getconn()
            
            yield conn
            
            conn.commit()
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Database error: {e}")
            raise
        finally:
            if conn:
                if self.use_sqlite:
                    conn.close()
                else:
                    self._pg_pool.putconn(conn)
    
    @contextlib.contextmanager
    def get_cursor(self) -> Generator:
        """Get a database cursor with automatic cleanup"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            try:
                yield cursor
            finally:
                cursor.close()
    
    def execute(
        self,
        query: str,
        params: Optional[Tuple] = None
    ) -> Optional[int]:
        """
        Execute a single query.
        
        Returns:
            Last row ID for INSERT, rows affected for UPDATE/DELETE
        """
        with self.get_cursor() as cursor:
            cursor.execute(query, params or ())
            return cursor.lastrowid if cursor.lastrowid else cursor.rowcount
    
    def execute_many(
        self,
        query: str,
        params_list: List[Tuple]
    ) -> int:
        """Execute query with multiple parameter sets"""
        with self.get_cursor() as cursor:
            cursor.executemany(query, params_list)
            return cursor.rowcount
    
    def fetch_one(
        self,
        query: str,
        params: Optional[Tuple] = None
    ) -> Optional[Dict]:
        """Fetch a single row as dictionary"""
        with self.get_cursor() as cursor:
            cursor.execute(query, params or ())
            row = cursor.fetchone()
            if row:
                if self.use_sqlite:
                    return dict(row)
                else:
                    columns = [desc[0] for desc in cursor.description]
                    return dict(zip(columns, row))
            return None
    
    def fetch_all(
        self,
        query: str,
        params: Optional[Tuple] = None
    ) -> List[Dict]:
        """Fetch all rows as list of dictionaries"""
        with self.get_cursor() as cursor:
            cursor.execute(query, params or ())
            rows = cursor.fetchall()
            if self.use_sqlite:
                return [dict(row) for row in rows]
            else:
                columns = [desc[0] for desc in cursor.description]
                return [dict(zip(columns, row)) for row in rows]
    
    def _create_sqlite_tables(self, conn: sqlite3.Connection):
        """Create SQLite tables (simplified version of PostgreSQL schema)"""
        
        cursor = conn.cursor()
        
        # Users table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                email TEXT UNIQUE NOT NULL,
                phone TEXT UNIQUE,
                password_hash TEXT NOT NULL,
                full_name TEXT NOT NULL,
                avatar_url TEXT,
                role TEXT DEFAULT 'farmer',
                subscription_tier TEXT DEFAULT 'free',
                address TEXT,
                city TEXT,
                district TEXT,
                state TEXT,
                country TEXT DEFAULT 'India',
                pincode TEXT,
                latitude REAL,
                longitude REAL,
                language TEXT DEFAULT 'en',
                preferred_units TEXT DEFAULT 'metric',
                notification_enabled INTEGER DEFAULT 1,
                email_verified INTEGER DEFAULT 0,
                phone_verified INTEGER DEFAULT 0,
                kyc_verified INTEGER DEFAULT 0,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                last_login_at TEXT,
                is_active INTEGER DEFAULT 1
            )
        """)
        
        # User sessions table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_sessions (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                refresh_token TEXT NOT NULL,
                device_info TEXT,
                ip_address TEXT,
                expires_at TEXT NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                is_valid INTEGER DEFAULT 1,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        
        # Farms table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS farms (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                name TEXT NOT NULL,
                farm_type TEXT DEFAULT 'small',
                address TEXT,
                village TEXT,
                district TEXT,
                state TEXT,
                latitude REAL,
                longitude REAL,
                total_area_acres REAL NOT NULL,
                cultivable_area_acres REAL,
                soil_type TEXT,
                water_source TEXT,
                irrigation_type TEXT DEFAULT 'manual',
                elevation_meters REAL,
                annual_rainfall_mm REAL,
                soil_ph REAL,
                organic_matter_percent REAL,
                is_primary INTEGER DEFAULT 0,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
        """)
        
        # Crop master table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS crop_master (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                local_name TEXT,
                scientific_name TEXT,
                category TEXT,
                season TEXT,
                min_temp_celsius REAL,
                max_temp_celsius REAL,
                water_requirement_mm REAL,
                growing_days_min INTEGER,
                growing_days_max INTEGER,
                soil_types TEXT,
                typical_yield_per_acre REAL,
                yield_unit TEXT DEFAULT 'kg',
                image_url TEXT,
                description TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Crops table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS crops (
                id TEXT PRIMARY KEY,
                farm_id TEXT NOT NULL,
                zone_id TEXT,
                crop_master_id INTEGER,
                user_id TEXT NOT NULL,
                variety TEXT,
                status TEXT DEFAULT 'planned',
                area_acres REAL NOT NULL,
                sowing_date TEXT,
                expected_harvest_date TEXT,
                actual_harvest_date TEXT,
                expected_yield REAL,
                actual_yield REAL,
                yield_unit TEXT DEFAULT 'kg',
                seed_cost REAL DEFAULT 0,
                fertilizer_cost REAL DEFAULT 0,
                pesticide_cost REAL DEFAULT 0,
                labor_cost REAL DEFAULT 0,
                irrigation_cost REAL DEFAULT 0,
                other_cost REAL DEFAULT 0,
                health_score INTEGER DEFAULT 100,
                notes TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE,
                FOREIGN KEY (crop_master_id) REFERENCES crop_master(id),
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)
        
        # Disease master table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS disease_master (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                local_name TEXT,
                scientific_name TEXT,
                category TEXT,
                affected_crops TEXT,
                symptoms TEXT NOT NULL,
                causes TEXT,
                prevention TEXT,
                organic_treatment TEXT,
                chemical_treatment TEXT,
                severity_indicators TEXT,
                image_urls TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Disease scans table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS disease_scans (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                crop_id TEXT,
                farm_id TEXT,
                image_url TEXT NOT NULL,
                detected_disease_id INTEGER,
                disease_name TEXT,
                confidence_score REAL,
                severity TEXT DEFAULT 'none',
                affected_area_percent REAL,
                ai_analysis TEXT,
                recommended_actions TEXT,
                estimated_yield_impact REAL,
                latitude REAL,
                longitude REAL,
                is_verified INTEGER DEFAULT 0,
                verified_by TEXT,
                expert_notes TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id),
                FOREIGN KEY (crop_id) REFERENCES crops(id),
                FOREIGN KEY (farm_id) REFERENCES farms(id),
                FOREIGN KEY (detected_disease_id) REFERENCES disease_master(id)
            )
        """)
        
        # Markets table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS markets (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                market_type TEXT,
                address TEXT,
                city TEXT,
                district TEXT,
                state TEXT,
                pincode TEXT,
                latitude REAL,
                longitude REAL,
                contact_phone TEXT,
                contact_email TEXT,
                website TEXT,
                operating_days TEXT,
                operating_hours TEXT,
                available_crops TEXT,
                facilities TEXT,
                is_verified INTEGER DEFAULT 1,
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Crop prices table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS crop_prices (
                id TEXT PRIMARY KEY,
                crop_master_id INTEGER NOT NULL,
                market_id TEXT NOT NULL,
                recorded_date TEXT NOT NULL,
                min_price REAL,
                max_price REAL,
                modal_price REAL,
                arrival_quantity REAL,
                grade TEXT,
                variety TEXT,
                source TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (crop_master_id) REFERENCES crop_master(id),
                FOREIGN KEY (market_id) REFERENCES markets(id),
                UNIQUE(crop_master_id, market_id, recorded_date, grade)
            )
        """)
        
        # Listings table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS listings (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                crop_id TEXT,
                crop_master_id INTEGER,
                title TEXT NOT NULL,
                description TEXT,
                crop_name TEXT NOT NULL,
                variety TEXT,
                grade TEXT,
                quantity REAL NOT NULL,
                unit TEXT DEFAULT 'kg',
                available_from TEXT,
                price_per_unit REAL NOT NULL,
                min_order_quantity REAL,
                negotiable INTEGER DEFAULT 1,
                pickup_address TEXT,
                city TEXT,
                district TEXT,
                state TEXT,
                latitude REAL,
                longitude REAL,
                delivery_available INTEGER DEFAULT 0,
                delivery_radius_km INTEGER,
                images TEXT,
                is_organic INTEGER DEFAULT 0,
                certifications TEXT,
                status TEXT DEFAULT 'active',
                views_count INTEGER DEFAULT 0,
                inquiries_count INTEGER DEFAULT 0,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                expires_at TEXT,
                FOREIGN KEY (user_id) REFERENCES users(id),
                FOREIGN KEY (crop_id) REFERENCES crops(id),
                FOREIGN KEY (crop_master_id) REFERENCES crop_master(id)
            )
        """)
        
        # Transactions table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS transactions (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                farm_id TEXT,
                crop_id TEXT,
                transaction_type TEXT NOT NULL,
                category TEXT NOT NULL,
                subcategory TEXT,
                amount REAL NOT NULL,
                description TEXT,
                party_name TEXT,
                party_phone TEXT,
                payment_method TEXT,
                reference_number TEXT,
                transaction_date TEXT NOT NULL,
                receipt_images TEXT,
                tags TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (farm_id) REFERENCES farms(id),
                FOREIGN KEY (crop_id) REFERENCES crops(id)
            )
        """)
        
        # Weather data table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS weather_data (
                id TEXT PRIMARY KEY,
                farm_id TEXT,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                recorded_at TEXT NOT NULL,
                temperature_celsius REAL,
                feels_like_celsius REAL,
                humidity_percent INTEGER,
                pressure_hpa REAL,
                wind_speed_kmh REAL,
                wind_direction_deg INTEGER,
                visibility_km REAL,
                uv_index REAL,
                rain_mm REAL DEFAULT 0,
                snow_mm REAL DEFAULT 0,
                weather_code INTEGER,
                weather_description TEXT,
                icon_code TEXT,
                is_forecast INTEGER DEFAULT 0,
                forecast_date TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE
            )
        """)
        
        # Alerts table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS alerts (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                farm_id TEXT,
                alert_type TEXT NOT NULL,
                severity TEXT NOT NULL,
                title TEXT NOT NULL,
                message TEXT NOT NULL,
                related_crop_id TEXT,
                related_listing_id TEXT,
                action_required INTEGER DEFAULT 0,
                action_url TEXT,
                action_label TEXT,
                is_read INTEGER DEFAULT 0,
                read_at TEXT,
                is_dismissed INTEGER DEFAULT 0,
                scheduled_for TEXT,
                expires_at TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (farm_id) REFERENCES farms(id)
            )
        """)
        
        # Irrigation schedules table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS irrigation_schedules (
                id TEXT PRIMARY KEY,
                farm_id TEXT NOT NULL,
                zone_id TEXT,
                crop_id TEXT,
                user_id TEXT NOT NULL,
                schedule_type TEXT NOT NULL,
                start_time TEXT NOT NULL,
                duration_minutes INTEGER NOT NULL,
                days_of_week TEXT,
                soil_moisture_threshold REAL,
                weather_aware INTEGER DEFAULT 0,
                skip_if_rain INTEGER DEFAULT 1,
                water_volume_liters REAL,
                is_active INTEGER DEFAULT 1,
                next_run_at TEXT,
                last_run_at TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE,
                FOREIGN KEY (user_id) REFERENCES users(id)
            )
        """)
        
        # Learning content table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS learning_content (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                description TEXT,
                content_type TEXT NOT NULL,
                category TEXT NOT NULL,
                content_url TEXT,
                thumbnail_url TEXT,
                duration_minutes INTEGER,
                body TEXT,
                difficulty_level TEXT,
                tags TEXT,
                languages TEXT,
                related_crop_ids TEXT,
                views_count INTEGER DEFAULT 0,
                likes_count INTEGER DEFAULT 0,
                author_name TEXT,
                author_credentials TEXT,
                is_premium INTEGER DEFAULT 0,
                is_published INTEGER DEFAULT 1,
                published_at TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Carbon records table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS carbon_records (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                farm_id TEXT NOT NULL,
                record_date TEXT NOT NULL,
                fertilizer_emissions REAL DEFAULT 0,
                fuel_emissions REAL DEFAULT 0,
                electricity_emissions REAL DEFAULT 0,
                livestock_emissions REAL DEFAULT 0,
                other_emissions REAL DEFAULT 0,
                crop_sequestration REAL DEFAULT 0,
                tree_sequestration REAL DEFAULT 0,
                soil_sequestration REAL DEFAULT 0,
                notes TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE,
                UNIQUE(farm_id, record_date)
            )
        """)
        
        # Crop recommendations table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS crop_recommendations (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                farm_id TEXT NOT NULL,
                crop_master_id INTEGER NOT NULL,
                suitability_score REAL NOT NULL,
                expected_yield_per_acre REAL,
                expected_profit_per_acre REAL,
                risk_score REAL,
                factors TEXT,
                recommendation_text TEXT,
                recommended_sowing_start TEXT,
                recommended_sowing_end TEXT,
                season TEXT,
                water_requirement TEXT,
                irrigation_frequency TEXT,
                price_trend TEXT,
                demand_level TEXT,
                is_viewed INTEGER DEFAULT 0,
                is_followed INTEGER DEFAULT 0,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                valid_until TEXT,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (farm_id) REFERENCES farms(id) ON DELETE CASCADE,
                FOREIGN KEY (crop_master_id) REFERENCES crop_master(id)
            )
        """)
        
        # Create indexes
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_farms_user ON farms(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_crops_farm ON crops(farm_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_crops_user ON crops(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_listings_user ON listings(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_alerts_user ON alerts(user_id)")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_transactions_user ON transactions(user_id)")
        
        # Insert seed data for crop_master
        cursor.execute("SELECT COUNT(*) FROM crop_master")
        if cursor.fetchone()[0] == 0:
            self._seed_crop_master(cursor)
            self._seed_disease_master(cursor)
            self._seed_markets(cursor)
            self._seed_learning_content(cursor)
        
        conn.commit()
        logger.info("SQLite tables created successfully")
    
    def _seed_crop_master(self, cursor):
        """Seed crop master data"""
        crops = [
            ('Rice', 'Dhaan', 'Oryza sativa', 'cereals', 'kharif', 20, 35, 1200, 120, 150, '["clay", "loamy"]', 2000, 'kg'),
            ('Wheat', 'Gehun', 'Triticum aestivum', 'cereals', 'rabi', 10, 25, 450, 120, 140, '["loamy", "clay loam"]', 1800, 'kg'),
            ('Maize', 'Makka', 'Zea mays', 'cereals', 'kharif', 18, 32, 600, 90, 120, '["loamy", "sandy loam"]', 2500, 'kg'),
            ('Cotton', 'Kapas', 'Gossypium hirsutum', 'cash_crops', 'kharif', 21, 35, 700, 150, 180, '["black", "loamy"]', 500, 'kg'),
            ('Sugarcane', 'Ganna', 'Saccharum officinarum', 'cash_crops', 'annual', 20, 35, 2000, 300, 365, '["loamy", "clay loam"]', 35000, 'kg'),
            ('Soybean', 'Soyabean', 'Glycine max', 'pulses', 'kharif', 20, 30, 500, 90, 120, '["loamy", "clay loam"]', 1200, 'kg'),
            ('Groundnut', 'Moongfali', 'Arachis hypogaea', 'oilseeds', 'kharif', 22, 32, 500, 100, 130, '["sandy loam", "loamy"]', 1500, 'kg'),
            ('Tomato', 'Tamatar', 'Solanum lycopersicum', 'vegetables', 'rabi', 15, 30, 600, 90, 120, '["loamy", "sandy loam"]', 10000, 'kg'),
            ('Onion', 'Pyaz', 'Allium cepa', 'vegetables', 'rabi', 13, 28, 400, 120, 150, '["loamy", "sandy loam"]', 12000, 'kg'),
            ('Potato', 'Aloo', 'Solanum tuberosum', 'vegetables', 'rabi', 15, 25, 500, 90, 120, '["sandy loam", "loamy"]', 15000, 'kg'),
            ('Grapes', 'Angoor', 'Vitis vinifera', 'fruits', 'perennial', 15, 35, 700, 365, 365, '["sandy loam", "loamy"]', 8000, 'kg'),
            ('Mango', 'Aam', 'Mangifera indica', 'fruits', 'perennial', 24, 45, 1000, 365, 365, '["loamy", "alluvial"]', 5000, 'kg'),
            ('Banana', 'Kela', 'Musa acuminata', 'fruits', 'perennial', 20, 35, 1800, 270, 365, '["loamy", "clay loam"]', 25000, 'kg'),
            ('Chilli', 'Mirchi', 'Capsicum annuum', 'vegetables', 'kharif', 20, 35, 600, 120, 150, '["loamy", "sandy loam"]', 2500, 'kg'),
            ('Turmeric', 'Haldi', 'Curcuma longa', 'spices', 'kharif', 20, 30, 1500, 240, 270, '["loamy", "clay loam"]', 2500, 'kg'),
        ]
        
        cursor.executemany("""
            INSERT INTO crop_master (name, local_name, scientific_name, category, season, 
                min_temp_celsius, max_temp_celsius, water_requirement_mm, growing_days_min, 
                growing_days_max, soil_types, typical_yield_per_acre, yield_unit)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, crops)
    
    def _seed_disease_master(self, cursor):
        """Seed disease master data"""
        diseases = [
            ('Blast', 'Jhulsa', 'fungal', '[1]', 'Spindle-shaped lesions on leaves', 'Fungus infection', 'Use resistant varieties', 'Trichoderma viride spray', 'Tricyclazole 75% WP'),
            ('Bacterial Leaf Blight', 'Patti Jhulsa', 'bacterial', '[1]', 'Water-soaked lesions at leaf margins', 'Bacterial infection', 'Use certified seeds', 'Copper hydroxide spray', 'Streptocycline 0.01%'),
            ('Powdery Mildew', 'Safed Chita', 'fungal', '[8, 14]', 'White powdery coating on leaves', 'Erysiphe species', 'Proper spacing', 'Milk spray (10%)', 'Sulfur 80% WP'),
            ('Late Blight', 'Picheti Jhulsa', 'fungal', '[8, 10]', 'Dark water-soaked lesions', 'Phytophthora infestans', 'Use disease-free seeds', 'Bordeaux mixture', 'Mancozeb 75% WP'),
            ('Downy Mildew', 'Mridu Romil', 'fungal', '[11]', 'Yellow patches on upper leaf', 'Peronospora species', 'Good air circulation', 'Neem oil spray', 'Metalaxyl 8%'),
            ('Anthracnose', 'Shrinkage', 'fungal', '[8, 12, 14]', 'Dark sunken lesions on fruits', 'Colletotrichum species', 'Crop rotation', 'Trichoderma application', 'Carbendazim 50% WP'),
            ('Yellow Mosaic Virus', 'Peela Mosaic', 'viral', '[6]', 'Yellow and green mosaic pattern', 'Whitefly transmission', 'Control whitefly', 'Neem oil', 'Imidacloprid for vector'),
            ('Rust', 'Ratua', 'fungal', '[2, 6]', 'Orange to brown pustules', 'Puccinia species', 'Use resistant varieties', 'Sulfur dust', 'Propiconazole 25% EC'),
        ]
        
        cursor.executemany("""
            INSERT INTO disease_master (name, local_name, category, affected_crops, symptoms, 
                causes, prevention, organic_treatment, chemical_treatment)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, diseases)
    
    def _seed_markets(self, cursor):
        """Seed market data"""
        markets = [
            (str(uuid.uuid4()), 'Nashik APMC', 'apmc', 'Nashik', 'Nashik', 'Maharashtra', 19.9975, 73.7898),
            (str(uuid.uuid4()), 'Pune Market Yard', 'apmc', 'Pune', 'Pune', 'Maharashtra', 18.5204, 73.8567),
            (str(uuid.uuid4()), 'Azadpur Mandi', 'mandi', 'Delhi', 'North Delhi', 'Delhi', 28.7041, 77.1025),
            (str(uuid.uuid4()), 'Vashi APMC', 'apmc', 'Navi Mumbai', 'Thane', 'Maharashtra', 19.0760, 72.9981),
            (str(uuid.uuid4()), 'Koyambedu Market', 'mandi', 'Chennai', 'Chennai', 'Tamil Nadu', 13.0827, 80.2707),
        ]
        
        cursor.executemany("""
            INSERT INTO markets (id, name, market_type, city, district, state, latitude, longitude)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, markets)
    
    def _seed_learning_content(self, cursor):
        """Seed learning content"""
        content = [
            (str(uuid.uuid4()), 'Organic Farming Basics', 'Learn the fundamentals of organic farming', 'article', 'farming', None, None, 15, 'beginner'),
            (str(uuid.uuid4()), 'Water Conservation Techniques', 'Efficient water management for farms', 'article', 'irrigation', None, None, 20, 'intermediate'),
            (str(uuid.uuid4()), 'Pest Management Guide', 'Integrated pest management strategies', 'article', 'pest_control', None, None, 25, 'intermediate'),
            (str(uuid.uuid4()), 'Soil Health Management', 'Maintaining and improving soil fertility', 'article', 'soil', None, None, 30, 'advanced'),
            (str(uuid.uuid4()), 'Market Price Analysis', 'Understanding market trends', 'article', 'market', None, None, 15, 'beginner'),
        ]
        
        cursor.executemany("""
            INSERT INTO learning_content (id, title, description, content_type, category, 
                content_url, thumbnail_url, duration_minutes, difficulty_level)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, content)


# Global database instance
db = DatabaseManager()


# =========================================================================
# HELPER FUNCTIONS
# =========================================================================

def generate_uuid() -> str:
    """Generate a new UUID string"""
    return str(uuid.uuid4())


def now_iso() -> str:
    """Get current timestamp in ISO format"""
    return datetime.utcnow().isoformat()
