"""
AgriSense Pro - Authentication Routes
Manual implementation of auth endpoints
"""

from fastapi import APIRouter, HTTPException, Depends, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime
from typing import Optional
import uuid

from models.schemas import (
    UserRegister, UserLogin, TokenResponse, RefreshTokenRequest,
    UserResponse, ErrorResponse, PasswordChange, BaseResponse
)
from core.security import (
    hash_password, verify_password, validate_password_strength,
    create_token_pair, verify_token, rate_limiter
)
from core.config import settings
from db.database import db, generate_uuid, now_iso

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()


# =========================================================================
# DEPENDENCY: Get Current User
# =========================================================================

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    """
    Dependency to get current authenticated user from JWT token.
    """
    token = credentials.credentials
    token_data = verify_token(token, "access")
    
    if token_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # Fetch user from database
    user = db.fetch_one(
        "SELECT * FROM users WHERE id = ? AND is_active = 1",
        (token_data.user_id,)
    )
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    return user


async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        HTTPBearer(auto_error=False)
    )
) -> Optional[dict]:
    """
    Optional authentication - returns None if no valid token.
    """
    if credentials is None:
        return None
    
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None


# =========================================================================
# ENDPOINTS
# =========================================================================

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(request: Request, user_data: UserRegister):
    """
    Register a new user.
    
    - Validates email uniqueness
    - Validates password strength
    - Creates user record
    - Returns access and refresh tokens
    """
    # Rate limiting
    client_ip = request.client.host if request.client else "unknown"
    is_allowed, _ = rate_limiter.is_allowed(f"register:{client_ip}", 5, 3600)
    if not is_allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many registration attempts. Please try again later."
        )
    
    # Check if email already exists
    existing_user = db.fetch_one(
        "SELECT id FROM users WHERE email = ?",
        (user_data.email.lower(),)
    )
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Check if phone already exists (if provided)
    if user_data.phone:
        existing_phone = db.fetch_one(
            "SELECT id FROM users WHERE phone = ?",
            (user_data.phone,)
        )
        if existing_phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Phone number already registered"
            )
    
    # Validate password strength
    is_valid, error_msg = validate_password_strength(user_data.password)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg
        )
    
    # Create user
    user_id = generate_uuid()
    password_hash = hash_password(user_data.password)
    
    db.execute("""
        INSERT INTO users (id, email, phone, password_hash, full_name, role, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        user_id,
        user_data.email.lower(),
        user_data.phone,
        password_hash,
        user_data.full_name,
        user_data.role.value,
        now_iso(),
        now_iso()
    ))
    
    # Create tokens
    tokens = create_token_pair(user_id, user_data.email.lower(), user_data.role.value)
    
    # Store refresh token session
    session_id = generate_uuid()
    db.execute("""
        INSERT INTO user_sessions (id, user_id, refresh_token, ip_address, expires_at, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        session_id,
        user_id,
        tokens["refresh_token"],
        client_ip,
        datetime.utcnow().isoformat(),
        now_iso()
    ))
    
    return TokenResponse(**tokens)


@router.post("/login", response_model=TokenResponse)
async def login(request: Request, credentials: UserLogin):
    """
    Authenticate user and return tokens.
    
    - Validates email and password
    - Updates last login timestamp
    - Returns access and refresh tokens
    """
    client_ip = request.client.host if request.client else "unknown"
    
    # Rate limiting for login attempts
    is_allowed, _ = rate_limiter.is_allowed(f"login:{client_ip}", 10, 900)
    if not is_allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many login attempts. Please try again in 15 minutes."
        )
    
    # Find user by email
    user = db.fetch_one(
        "SELECT * FROM users WHERE email = ? AND is_active = 1",
        (credentials.email.lower(),)
    )
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Verify password
    if not verify_password(credentials.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Update last login
    db.execute(
        "UPDATE users SET last_login_at = ? WHERE id = ?",
        (now_iso(), user["id"])
    )
    
    # Create tokens
    tokens = create_token_pair(user["id"], user["email"], user["role"])
    
    # Store refresh token session
    session_id = generate_uuid()
    db.execute("""
        INSERT INTO user_sessions (id, user_id, refresh_token, ip_address, expires_at, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        session_id,
        user["id"],
        tokens["refresh_token"],
        client_ip,
        datetime.utcnow().isoformat(),
        now_iso()
    ))
    
    return TokenResponse(**tokens)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: Request, token_request: RefreshTokenRequest):
    """
    Refresh access token using refresh token.
    
    - Validates refresh token
    - Invalidates old session
    - Creates new token pair
    """
    # Verify refresh token
    token_data = verify_token(token_request.refresh_token, "refresh")
    
    if token_data is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
    
    # Check if session exists and is valid
    session = db.fetch_one(
        "SELECT * FROM user_sessions WHERE refresh_token = ? AND is_valid = 1",
        (token_request.refresh_token,)
    )
    
    if session is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session not found or invalidated"
        )
    
    # Invalidate old session
    db.execute(
        "UPDATE user_sessions SET is_valid = 0 WHERE id = ?",
        (session["id"],)
    )
    
    # Get user
    user = db.fetch_one(
        "SELECT * FROM users WHERE id = ? AND is_active = 1",
        (token_data.user_id,)
    )
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    # Create new tokens
    tokens = create_token_pair(user["id"], user["email"], user["role"])
    
    # Store new session
    client_ip = request.client.host if request.client else "unknown"
    session_id = generate_uuid()
    db.execute("""
        INSERT INTO user_sessions (id, user_id, refresh_token, ip_address, expires_at, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        session_id,
        user["id"],
        tokens["refresh_token"],
        client_ip,
        datetime.utcnow().isoformat(),
        now_iso()
    ))
    
    return TokenResponse(**tokens)


@router.post("/logout", response_model=BaseResponse)
async def logout(current_user: dict = Depends(get_current_user)):
    """
    Logout user by invalidating all sessions.
    """
    db.execute(
        "UPDATE user_sessions SET is_valid = 0 WHERE user_id = ?",
        (current_user["id"],)
    )
    
    return BaseResponse(message="Successfully logged out")


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: dict = Depends(get_current_user)):
    """
    Get current authenticated user's profile.
    """
    return UserResponse(
        id=current_user["id"],
        email=current_user["email"],
        phone=current_user.get("phone"),
        full_name=current_user["full_name"],
        avatar_url=current_user.get("avatar_url"),
        role=current_user["role"],
        subscription_tier=current_user.get("subscription_tier", "free"),
        address=current_user.get("address"),
        city=current_user.get("city"),
        district=current_user.get("district"),
        state=current_user.get("state"),
        pincode=current_user.get("pincode"),
        latitude=current_user.get("latitude"),
        longitude=current_user.get("longitude"),
        language=current_user.get("language", "en"),
        notification_enabled=bool(current_user.get("notification_enabled", 1)),
        email_verified=bool(current_user.get("email_verified", 0)),
        phone_verified=bool(current_user.get("phone_verified", 0)),
        created_at=datetime.fromisoformat(current_user["created_at"])
    )


@router.post("/change-password", response_model=BaseResponse)
async def change_password(
    password_data: PasswordChange,
    current_user: dict = Depends(get_current_user)
):
    """
    Change user password.
    
    - Validates current password
    - Validates new password strength
    - Updates password hash
    - Invalidates all sessions
    """
    # Verify current password
    if not verify_password(password_data.current_password, current_user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )
    
    # Validate new password strength
    is_valid, error_msg = validate_password_strength(password_data.new_password)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_msg
        )
    
    # Update password
    new_hash = hash_password(password_data.new_password)
    db.execute(
        "UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?",
        (new_hash, now_iso(), current_user["id"])
    )
    
    # Invalidate all sessions (force re-login)
    db.execute(
        "UPDATE user_sessions SET is_valid = 0 WHERE user_id = ?",
        (current_user["id"],)
    )
    
    return BaseResponse(message="Password changed successfully. Please login again.")


@router.delete("/account", response_model=BaseResponse)
async def delete_account(current_user: dict = Depends(get_current_user)):
    """
    Soft delete user account.
    """
    db.execute(
        "UPDATE users SET is_active = 0, updated_at = ? WHERE id = ?",
        (now_iso(), current_user["id"])
    )
    
    # Invalidate all sessions
    db.execute(
        "UPDATE user_sessions SET is_valid = 0 WHERE user_id = ?",
        (current_user["id"],)
    )
    
    return BaseResponse(message="Account deleted successfully")
