# AgriSense Pro - Backend API

## AI Crop Intelligence & Farmer Profit Engine

A comprehensive REST API backend built with **FastAPI** and **PostgreSQL** (or SQLite for development).

**No BaaS Dependencies** - Pure Python implementation with manual authentication, validation, and error handling.

---

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- PostgreSQL 14+ (optional, SQLite used for development)

### Installation

```bash
# Clone and navigate
cd agrisense_backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### API Documentation
Once running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## 📁 Project Structure

```
agrisense_backend/
├── main.py                 # FastAPI application entry point
├── requirements.txt        # Python dependencies
├── api/
│   ├── routes/
│   │   ├── auth.py        # Authentication endpoints
│   │   ├── farms.py       # Farm management
│   │   ├── crops.py       # Crop management & recommendations
│   │   ├── diseases.py    # Disease detection
│   │   ├── marketplace.py # Farmer marketplace
│   │   ├── weather.py     # Weather intelligence
│   │   └── prices.py      # Market prices & predictions
│   └── middleware/
├── core/
│   ├── config.py          # Configuration & API keys
│   └── security.py        # JWT auth, password hashing
├── db/
│   ├── database.py        # Database connection manager
│   └── schema.sql         # PostgreSQL DDL schema
├── models/
│   └── schemas.py         # Pydantic request/response models
├── services/
└── utils/
```

---

## 🔐 Authentication

### JWT-Based Authentication

```bash
# Register
POST /api/v1/auth/register
{
  "email": "farmer@example.com",
  "password": "SecurePass123!",
  "full_name": "Rajesh Kumar",
  "phone": "+91 98765 43210",
  "role": "farmer"
}

# Login
POST /api/v1/auth/login
{
  "email": "farmer@example.com",
  "password": "SecurePass123!"
}

# Response
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

### Using Tokens
```bash
Authorization: Bearer <access_token>
```

---

## 📊 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | User login |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| POST | `/api/v1/auth/logout` | Logout user |
| GET | `/api/v1/auth/me` | Get current user |
| POST | `/api/v1/auth/change-password` | Change password |

### Farm Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/farms` | List user's farms |
| POST | `/api/v1/farms` | Create new farm |
| GET | `/api/v1/farms/{id}` | Get farm details |
| PUT | `/api/v1/farms/{id}` | Update farm |
| DELETE | `/api/v1/farms/{id}` | Delete farm |
| GET | `/api/v1/farms/{id}/summary` | Farm summary with stats |

### Crop Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/crops/master` | Get crop types catalog |
| GET | `/api/v1/crops` | List user's crops |
| POST | `/api/v1/crops` | Add new crop |
| GET | `/api/v1/crops/{id}` | Get crop details |
| PUT | `/api/v1/crops/{id}` | Update crop |
| DELETE | `/api/v1/crops/{id}` | Delete crop |
| GET | `/api/v1/crops/{id}/performance` | Crop performance analytics |
| GET | `/api/v1/crops/recommendations/{farm_id}` | AI crop recommendations |

### Disease Detection
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/diseases/catalog` | Disease catalog |
| POST | `/api/v1/diseases/scan` | Submit disease scan |
| GET | `/api/v1/diseases/scans` | Scan history |
| GET | `/api/v1/diseases/scans/{id}` | Scan details |
| GET | `/api/v1/diseases/statistics` | Disease statistics |

### Weather Intelligence
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/weather/current` | Current weather |
| GET | `/api/v1/weather/forecast` | 7-14 day forecast |
| GET | `/api/v1/weather/farm/{farm_id}` | Farm weather + advisories |
| GET | `/api/v1/weather/advisories` | Farming advisories |

### Market Prices
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/prices/markets` | List markets |
| GET | `/api/v1/prices/current` | Current prices |
| GET | `/api/v1/prices/history` | Price history |
| GET | `/api/v1/prices/prediction` | AI price prediction |
| GET | `/api/v1/prices/comparison` | Market comparison |
| POST | `/api/v1/prices/alerts` | Create price alert |

### Marketplace
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/marketplace/listings` | Browse listings |
| POST | `/api/v1/marketplace/listings` | Create listing |
| GET | `/api/v1/marketplace/listings/my` | My listings |
| GET | `/api/v1/marketplace/listings/{id}` | Listing details |
| PUT | `/api/v1/marketplace/listings/{id}` | Update listing |
| DELETE | `/api/v1/marketplace/listings/{id}` | Delete listing |
| POST | `/api/v1/marketplace/inquiries` | Send inquiry |

### Dashboard
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/dashboard` | User dashboard summary |

---

## 🔑 API Keys Configuration

Edit `core/config.py` or create `.env` file:

```env
# Weather API (Free: 1000 calls/day)
# Sign up: https://openweathermap.org/api
OPENWEATHERMAP_API_KEY=your_key_here

# AI/ML - HuggingFace (Free tier)
# Sign up: https://huggingface.co/settings/tokens
HUGGINGFACE_API_KEY=your_key_here

# Maps - Mapbox (Free: 50K loads/month)
# Sign up: https://www.mapbox.com/
MAPBOX_API_KEY=your_key_here

# Email - SendGrid (Free: 100 emails/day)
# Sign up: https://signup.sendgrid.com/
SENDGRID_API_KEY=your_key_here

# SMS - Twilio (Free trial)
# Sign up: https://www.twilio.com/try-twilio
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
```

---

## 🗄️ Database Schema

The complete PostgreSQL schema is in `db/schema.sql`. Key tables:

- **users** - User accounts with roles
- **farms** - Farm profiles with location
- **crops** - Planted crops tracking
- **crop_master** - Crop types catalog
- **disease_master** - Disease database
- **disease_scans** - AI scan results
- **markets** - Market locations
- **crop_prices** - Price data
- **listings** - Marketplace listings
- **alerts** - User notifications
- **transactions** - Financial records
- **weather_data** - Cached weather
- **carbon_records** - Sustainability tracking

---

## 🚀 Deployment

### Using Docker

```dockerfile
FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Production Settings

```python
# In .env
DEBUG=false
ENVIRONMENT=production
SECRET_KEY=<generate-secure-key>
DATABASE_URL=postgresql://user:pass@host:5432/agrisense_db
USE_SQLITE=false
```

---

## 📞 Support

For questions or issues:
- Email: support@agrisensepro.com
- GitHub Issues: [Create Issue](https://github.com/tejash-sr/agri/issues)

---

## 📄 License

MIT License - See LICENSE file for details.
