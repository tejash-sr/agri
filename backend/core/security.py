"""
AgriSense Pro - Security Module
Manual implementation of authentication, authorization, and security utilities
No BaaS - Pure Python implementation
"""

import secrets
import hashlib
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, Tuple
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

from .config import settings


# =========================================================================
# PASSWORD HASHING
# =========================================================================

# Create password context with bcrypt
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=settings.BCRYPT_ROUNDS
)


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt.
    
    Args:
        password: Plain text password
        
    Returns:
        Hashed password string
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a password against its hash.
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Stored hashed password
        
    Returns:
        True if password matches, False otherwise
    """
    return pwd_context.verify(plain_password, hashed_password)


def validate_password_strength(password: str) -> Tuple[bool, str]:
    """
    Validate password meets security requirements.
    
    Requirements:
    - Minimum 8 characters
    - At least one uppercase letter
    - At least one lowercase letter
    - At least one digit
    - At least one special character
    
    Args:
        password: Password to validate
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    if len(password) < settings.PASSWORD_MIN_LENGTH:
        return False, f"Password must be at least {settings.PASSWORD_MIN_LENGTH} characters"
    
    if not any(c.isupper() for c in password):
        return False, "Password must contain at least one uppercase letter"
    
    if not any(c.islower() for c in password):
        return False, "Password must contain at least one lowercase letter"
    
    if not any(c.isdigit() for c in password):
        return False, "Password must contain at least one digit"
    
    special_chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    if not any(c in special_chars for c in password):
        return False, "Password must contain at least one special character"
    
    return True, ""


# =========================================================================
# JWT TOKEN MANAGEMENT
# =========================================================================

class TokenData(BaseModel):
    """Token payload data model"""
    user_id: str
    email: Optional[str] = None
    role: str = "farmer"
    token_type: str = "access"
    exp: Optional[datetime] = None


def create_access_token(
    data: Dict[str, Any],
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Create a JWT access token.
    
    Args:
        data: Payload data to encode in token
        expires_delta: Optional custom expiration time
        
    Returns:
        Encoded JWT token string
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.utcnow(),
        "type": "access"
    })
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt


def create_refresh_token(
    data: Dict[str, Any],
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Create a JWT refresh token.
    
    Args:
        data: Payload data to encode in token
        expires_delta: Optional custom expiration time
        
    Returns:
        Encoded JWT refresh token string
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            days=settings.REFRESH_TOKEN_EXPIRE_DAYS
        )
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.utcnow(),
        "type": "refresh",
        "jti": secrets.token_urlsafe(32)  # Unique token ID
    })
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt


def decode_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Decode and validate a JWT token.
    
    Args:
        token: JWT token string
        
    Returns:
        Decoded token payload or None if invalid
    """
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None


def verify_token(token: str, token_type: str = "access") -> Optional[TokenData]:
    """
    Verify a JWT token and extract data.
    
    Args:
        token: JWT token string
        token_type: Expected token type ('access' or 'refresh')
        
    Returns:
        TokenData object or None if invalid
    """
    payload = decode_token(token)
    
    if payload is None:
        return None
    
    # Verify token type
    if payload.get("type") != token_type:
        return None
    
    # Extract user data
    user_id = payload.get("sub") or payload.get("user_id")
    if user_id is None:
        return None
    
    return TokenData(
        user_id=user_id,
        email=payload.get("email"),
        role=payload.get("role", "farmer"),
        token_type=token_type,
        exp=datetime.fromtimestamp(payload.get("exp", 0))
    )


def create_token_pair(user_id: str, email: str, role: str = "farmer") -> Dict[str, str]:
    """
    Create both access and refresh tokens for a user.
    
    Args:
        user_id: User's UUID
        email: User's email
        role: User's role
        
    Returns:
        Dictionary with access_token and refresh_token
    """
    token_data = {
        "sub": user_id,
        "email": email,
        "role": role
    }
    
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }


# =========================================================================
# API KEY GENERATION
# =========================================================================

def generate_api_key() -> str:
    """Generate a secure API key for external integrations"""
    return f"agri_{secrets.token_urlsafe(32)}"


def hash_api_key(api_key: str) -> str:
    """Hash an API key for secure storage"""
    return hashlib.sha256(api_key.encode()).hexdigest()


# =========================================================================
# OTP GENERATION
# =========================================================================

def generate_otp(length: int = 6) -> str:
    """
    Generate a numeric OTP.
    
    Args:
        length: Length of OTP (default 6)
        
    Returns:
        Numeric OTP string
    """
    return ''.join([str(secrets.randbelow(10)) for _ in range(length)])


def generate_otp_expiry(minutes: int = 10) -> datetime:
    """Generate OTP expiry timestamp"""
    return datetime.utcnow() + timedelta(minutes=minutes)


# =========================================================================
# INPUT SANITIZATION
# =========================================================================

def sanitize_input(text: str, max_length: int = 1000) -> str:
    """
    Sanitize user input to prevent XSS and injection attacks.
    
    Args:
        text: Input text to sanitize
        max_length: Maximum allowed length
        
    Returns:
        Sanitized text
    """
    if not text:
        return ""
    
    # Truncate to max length
    text = text[:max_length]
    
    # Remove null bytes
    text = text.replace('\x00', '')
    
    # Basic HTML entity encoding for dangerous characters
    replacements = {
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#x27;',
        '/': '&#x2F;',
    }
    
    for char, replacement in replacements.items():
        text = text.replace(char, replacement)
    
    return text.strip()


def validate_email(email: str) -> bool:
    """
    Validate email format.
    
    Args:
        email: Email address to validate
        
    Returns:
        True if valid, False otherwise
    """
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))


def validate_phone(phone: str) -> bool:
    """
    Validate Indian phone number format.
    
    Args:
        phone: Phone number to validate
        
    Returns:
        True if valid, False otherwise
    """
    import re
    # Indian phone number: +91 followed by 10 digits
    pattern = r'^(\+91|91|0)?[6-9]\d{9}$'
    cleaned = phone.replace(" ", "").replace("-", "")
    return bool(re.match(pattern, cleaned))


# =========================================================================
# RATE LIMITING HELPER
# =========================================================================

class RateLimiter:
    """
    Simple in-memory rate limiter.
    For production, use Redis-based implementation.
    """
    
    def __init__(self):
        self._requests: Dict[str, list] = {}
    
    def is_allowed(
        self,
        key: str,
        max_requests: int,
        window_seconds: int
    ) -> Tuple[bool, int]:
        """
        Check if request is allowed under rate limit.
        
        Args:
            key: Unique identifier (e.g., IP address, user_id)
            max_requests: Maximum requests allowed in window
            window_seconds: Time window in seconds
            
        Returns:
            Tuple of (is_allowed, remaining_requests)
        """
        now = datetime.utcnow()
        window_start = now - timedelta(seconds=window_seconds)
        
        # Get existing requests for this key
        if key not in self._requests:
            self._requests[key] = []
        
        # Filter to only requests within window
        self._requests[key] = [
            req_time for req_time in self._requests[key]
            if req_time > window_start
        ]
        
        # Check if under limit
        if len(self._requests[key]) >= max_requests:
            return False, 0
        
        # Add current request
        self._requests[key].append(now)
        remaining = max_requests - len(self._requests[key])
        
        return True, remaining


# Global rate limiter instance
rate_limiter = RateLimiter()


# =========================================================================
# PERMISSION HELPERS
# =========================================================================

class Permissions:
    """Permission constants and helpers"""
    
    # Role hierarchy
    ROLES = {
        "farmer": 1,
        "trader": 2,
        "expert": 3,
        "admin": 4
    }
    
    @classmethod
    def has_permission(cls, user_role: str, required_role: str) -> bool:
        """Check if user role has required permission level"""
        user_level = cls.ROLES.get(user_role, 0)
        required_level = cls.ROLES.get(required_role, 0)
        return user_level >= required_level
    
    @classmethod
    def is_admin(cls, role: str) -> bool:
        """Check if role is admin"""
        return role == "admin"
    
    @classmethod
    def can_moderate(cls, role: str) -> bool:
        """Check if role can moderate content"""
        return role in ["expert", "admin"]
