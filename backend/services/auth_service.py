"""
AgriSense Pro - Authentication Service
Handles user authentication, token management, and password operations
"""

import secrets
import hashlib
from datetime import datetime, timedelta
from typing import Optional, Tuple, Dict, Any

from core.config import settings
from core.security import hash_password, verify_password, create_token_pair, verify_token
from db.database import db, generate_uuid, now_iso


class AuthService:
    """Authentication service for user management"""
    
    def __init__(self):
        self.token_expiry_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
        self.refresh_expiry_days = settings.REFRESH_TOKEN_EXPIRE_DAYS
    
    # =========================================================================
    # USER REGISTRATION
    # =========================================================================
    
    def register_user(
        self,
        email: str,
        password: str,
        full_name: str,
        phone: Optional[str] = None,
        role: str = "farmer"
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Register a new user.
        
        Returns:
            Tuple of (success: bool, result: Dict containing tokens or error)
        """
        # Check email uniqueness
        existing = db.fetch_one(
            "SELECT id FROM users WHERE email = ?",
            (email.lower(),)
        )
        if existing:
            return False, {"error": "Email already registered"}
        
        # Check phone uniqueness if provided
        if phone:
            existing_phone = db.fetch_one(
                "SELECT id FROM users WHERE phone = ?",
                (phone,)
            )
            if existing_phone:
                return False, {"error": "Phone number already registered"}
        
        # Create user
        user_id = generate_uuid()
        password_hash = hash_password(password)
        
        try:
            db.execute("""
                INSERT INTO users (
                    id, email, phone, password_hash, full_name, role,
                    created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                user_id,
                email.lower(),
                phone,
                password_hash,
                full_name,
                role,
                now_iso(),
                now_iso()
            ))
            
            # Generate tokens
            tokens = create_token_pair(user_id, email.lower(), role)
            
            # Create session
            self._create_session(user_id, tokens["refresh_token"])
            
            return True, {
                "user_id": user_id,
                "access_token": tokens["access_token"],
                "refresh_token": tokens["refresh_token"],
                "expires_in": tokens["expires_in"]
            }
        except Exception as e:
            return False, {"error": str(e)}
    
    # =========================================================================
    # USER LOGIN
    # =========================================================================
    
    def login_user(
        self,
        email: str,
        password: str,
        ip_address: Optional[str] = None
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Authenticate user and return tokens.
        
        Returns:
            Tuple of (success: bool, result: Dict containing tokens or error)
        """
        # Find user
        user = db.fetch_one(
            "SELECT * FROM users WHERE email = ? AND is_active = 1",
            (email.lower(),)
        )
        
        if not user:
            return False, {"error": "Invalid email or password"}
        
        # Verify password
        if not verify_password(password, user["password_hash"]):
            return False, {"error": "Invalid email or password"}
        
        # Update last login
        db.execute(
            "UPDATE users SET last_login_at = ? WHERE id = ?",
            (now_iso(), user["id"])
        )
        
        # Generate tokens
        tokens = create_token_pair(user["id"], user["email"], user["role"])
        
        # Create session
        self._create_session(user["id"], tokens["refresh_token"], ip_address)
        
        return True, {
            "user_id": user["id"],
            "access_token": tokens["access_token"],
            "refresh_token": tokens["refresh_token"],
            "expires_in": tokens["expires_in"]
        }
    
    # =========================================================================
    # TOKEN MANAGEMENT
    # =========================================================================
    
    def refresh_tokens(self, refresh_token: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Refresh access token using refresh token.
        
        Returns:
            Tuple of (success: bool, result: Dict containing new tokens or error)
        """
        # Verify token
        token_data = verify_token(refresh_token, "refresh")
        if not token_data:
            return False, {"error": "Invalid or expired refresh token"}
        
        # Check session validity
        session = db.fetch_one(
            "SELECT * FROM user_sessions WHERE refresh_token = ? AND is_valid = 1",
            (refresh_token,)
        )
        
        if not session:
            return False, {"error": "Session not found or invalidated"}
        
        # Get user
        user = db.fetch_one(
            "SELECT * FROM users WHERE id = ? AND is_active = 1",
            (token_data.user_id,)
        )
        
        if not user:
            return False, {"error": "User not found or inactive"}
        
        # Invalidate old session
        db.execute(
            "UPDATE user_sessions SET is_valid = 0 WHERE id = ?",
            (session["id"],)
        )
        
        # Generate new tokens
        tokens = create_token_pair(user["id"], user["email"], user["role"])
        
        # Create new session
        self._create_session(user["id"], tokens["refresh_token"])
        
        return True, {
            "access_token": tokens["access_token"],
            "refresh_token": tokens["refresh_token"],
            "expires_in": tokens["expires_in"]
        }
    
    def invalidate_session(self, user_id: str) -> bool:
        """Invalidate all sessions for a user."""
        try:
            db.execute(
                "UPDATE user_sessions SET is_valid = 0 WHERE user_id = ?",
                (user_id,)
            )
            return True
        except Exception:
            return False
    
    # =========================================================================
    # PASSWORD MANAGEMENT
    # =========================================================================
    
    def initiate_password_reset(self, email: str) -> Tuple[bool, str]:
        """
        Initiate password reset process.
        
        Returns:
            Tuple of (success: bool, reset_token: str)
        """
        user = db.fetch_one(
            "SELECT id, email, full_name FROM users WHERE email = ? AND is_active = 1",
            (email.lower(),)
        )
        
        if not user:
            # Return success anyway to prevent email enumeration
            return True, ""
        
        # Generate reset token
        reset_token = secrets.token_urlsafe(32)
        token_expires = datetime.utcnow() + timedelta(hours=1)
        
        # Store token
        token_id = generate_uuid()
        db.execute("""
            INSERT INTO user_sessions (
                id, user_id, refresh_token, device_info, expires_at, created_at, is_valid
            ) VALUES (?, ?, ?, ?, ?, ?, 1)
        """, (
            token_id,
            user["id"],
            f"reset:{reset_token}",
            "password_reset",
            token_expires.isoformat(),
            now_iso()
        ))
        
        return True, reset_token
    
    def reset_password(self, token: str, new_password: str) -> Tuple[bool, str]:
        """
        Reset password using token.
        
        Returns:
            Tuple of (success: bool, message: str)
        """
        # Find reset token
        session = db.fetch_one("""
            SELECT s.*, u.id as uid 
            FROM user_sessions s 
            JOIN users u ON s.user_id = u.id
            WHERE s.refresh_token = ? 
            AND s.is_valid = 1 
            AND s.device_info = 'password_reset'
            AND u.is_active = 1
        """, (f"reset:{token}",))
        
        if not session:
            return False, "Invalid or expired reset token"
        
        # Check expiration
        expires_at = datetime.fromisoformat(session["expires_at"])
        if datetime.utcnow() > expires_at:
            db.execute(
                "UPDATE user_sessions SET is_valid = 0 WHERE id = ?",
                (session["id"],)
            )
            return False, "Reset token has expired"
        
        # Update password
        new_hash = hash_password(new_password)
        db.execute(
            "UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?",
            (new_hash, now_iso(), session["user_id"])
        )
        
        # Invalidate all sessions
        db.execute(
            "UPDATE user_sessions SET is_valid = 0 WHERE user_id = ?",
            (session["user_id"],)
        )
        
        return True, "Password reset successful"
    
    def change_password(
        self,
        user_id: str,
        current_password: str,
        new_password: str
    ) -> Tuple[bool, str]:
        """
        Change user password.
        
        Returns:
            Tuple of (success: bool, message: str)
        """
        user = db.fetch_one(
            "SELECT password_hash FROM users WHERE id = ?",
            (user_id,)
        )
        
        if not user:
            return False, "User not found"
        
        if not verify_password(current_password, user["password_hash"]):
            return False, "Current password is incorrect"
        
        # Update password
        new_hash = hash_password(new_password)
        db.execute(
            "UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?",
            (new_hash, now_iso(), user_id)
        )
        
        # Invalidate all sessions
        db.execute(
            "UPDATE user_sessions SET is_valid = 0 WHERE user_id = ?",
            (user_id,)
        )
        
        return True, "Password changed successfully"
    
    # =========================================================================
    # EMAIL VERIFICATION
    # =========================================================================
    
    def send_verification_email(self, user_id: str) -> Tuple[bool, str]:
        """
        Generate email verification token.
        
        Returns:
            Tuple of (success: bool, verification_token: str)
        """
        user = db.fetch_one(
            "SELECT email, email_verified FROM users WHERE id = ?",
            (user_id,)
        )
        
        if not user:
            return False, ""
        
        if user.get("email_verified"):
            return True, ""  # Already verified
        
        # Invalidate old tokens
        db.execute("""
            UPDATE user_sessions SET is_valid = 0 
            WHERE user_id = ? AND device_info = 'email_verification'
        """, (user_id,))
        
        # Generate token
        verify_token = secrets.token_urlsafe(32)
        token_expires = datetime.utcnow() + timedelta(hours=24)
        
        token_id = generate_uuid()
        db.execute("""
            INSERT INTO user_sessions (
                id, user_id, refresh_token, device_info, expires_at, created_at, is_valid
            ) VALUES (?, ?, ?, ?, ?, ?, 1)
        """, (
            token_id,
            user_id,
            f"verify:{verify_token}",
            "email_verification",
            token_expires.isoformat(),
            now_iso()
        ))
        
        return True, verify_token
    
    def verify_email(self, token: str) -> Tuple[bool, str]:
        """
        Verify email using token.
        
        Returns:
            Tuple of (success: bool, message: str)
        """
        session = db.fetch_one("""
            SELECT s.*, u.email 
            FROM user_sessions s 
            JOIN users u ON s.user_id = u.id
            WHERE s.refresh_token = ? 
            AND s.is_valid = 1 
            AND s.device_info = 'email_verification'
        """, (f"verify:{token}",))
        
        if not session:
            return False, "Invalid or expired verification token"
        
        # Check expiration
        expires_at = datetime.fromisoformat(session["expires_at"])
        if datetime.utcnow() > expires_at:
            db.execute(
                "UPDATE user_sessions SET is_valid = 0 WHERE id = ?",
                (session["id"],)
            )
            return False, "Verification token has expired"
        
        # Mark as verified
        db.execute(
            "UPDATE users SET email_verified = 1, updated_at = ? WHERE id = ?",
            (now_iso(), session["user_id"])
        )
        
        # Invalidate token
        db.execute(
            "UPDATE user_sessions SET is_valid = 0 WHERE id = ?",
            (session["id"],)
        )
        
        return True, "Email verified successfully"
    
    # =========================================================================
    # HELPER METHODS
    # =========================================================================
    
    def _create_session(
        self,
        user_id: str,
        refresh_token: str,
        ip_address: Optional[str] = None
    ) -> str:
        """Create a new user session."""
        session_id = generate_uuid()
        expires_at = datetime.utcnow() + timedelta(days=self.refresh_expiry_days)
        
        db.execute("""
            INSERT INTO user_sessions (
                id, user_id, refresh_token, ip_address, expires_at, created_at, is_valid
            ) VALUES (?, ?, ?, ?, ?, ?, 1)
        """, (
            session_id,
            user_id,
            refresh_token,
            ip_address,
            expires_at.isoformat(),
            now_iso()
        ))
        
        return session_id
    
    def get_user_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user by ID."""
        return db.fetch_one(
            "SELECT * FROM users WHERE id = ? AND is_active = 1",
            (user_id,)
        )
    
    def update_user_profile(
        self,
        user_id: str,
        updates: Dict[str, Any]
    ) -> Tuple[bool, Dict[str, Any]]:
        """Update user profile."""
        allowed_fields = {
            "full_name", "phone", "avatar_url", "address", "city",
            "district", "state", "pincode", "latitude", "longitude",
            "language", "preferred_units", "notification_enabled"
        }
        
        # Filter updates
        valid_updates = {k: v for k, v in updates.items() if k in allowed_fields and v is not None}
        
        if not valid_updates:
            return False, {"error": "No valid fields to update"}
        
        # Build query
        set_clauses = [f"{k} = ?" for k in valid_updates.keys()]
        set_clauses.append("updated_at = ?")
        values = list(valid_updates.values()) + [now_iso(), user_id]
        
        query = f"UPDATE users SET {', '.join(set_clauses)} WHERE id = ?"
        
        try:
            db.execute(query, tuple(values))
            
            # Return updated user
            user = self.get_user_by_id(user_id)
            return True, {"user": user}
        except Exception as e:
            return False, {"error": str(e)}


# Global service instance
auth_service = AuthService()
