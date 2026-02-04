"""
AgriSense Pro - Notification Service
Handles push notifications, email, SMS, and in-app alerts
"""

import httpx
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List, Tuple
import json

from core.config import settings
from db.database import db, generate_uuid, now_iso


class NotificationService:
    """Notification service for alerts and communications"""
    
    def __init__(self):
        self.sendgrid_api_key = settings.SENDGRID_API_KEY
        self.twilio_sid = settings.TWILIO_ACCOUNT_SID
        self.twilio_token = settings.TWILIO_AUTH_TOKEN
        self.twilio_phone = settings.TWILIO_PHONE_NUMBER
        self.fcm_key = settings.FCM_SERVER_KEY
        self.from_email = settings.FROM_EMAIL
    
    # =========================================================================
    # IN-APP ALERTS
    # =========================================================================
    
    def create_alert(
        self,
        user_id: str,
        alert_type: str,
        severity: str,
        title: str,
        message: str,
        farm_id: Optional[str] = None,
        related_crop_id: Optional[str] = None,
        action_required: bool = False,
        action_url: Optional[str] = None,
        action_label: Optional[str] = None,
        scheduled_for: Optional[datetime] = None,
        expires_at: Optional[datetime] = None
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Create an in-app alert for a user.
        
        Returns:
            Tuple of (success: bool, alert: Dict)
        """
        alert_id = generate_uuid()
        
        try:
            db.execute("""
                INSERT INTO alerts (
                    id, user_id, farm_id, alert_type, severity, title, message,
                    related_crop_id, action_required, action_url, action_label,
                    scheduled_for, expires_at, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                alert_id,
                user_id,
                farm_id,
                alert_type,
                severity,
                title,
                message,
                related_crop_id,
                1 if action_required else 0,
                action_url,
                action_label,
                scheduled_for.isoformat() if scheduled_for else None,
                expires_at.isoformat() if expires_at else None,
                now_iso()
            ))
            
            alert = self.get_alert(alert_id)
            return True, alert or {}
            
        except Exception as e:
            return False, {"error": str(e)}
    
    def get_user_alerts(
        self,
        user_id: str,
        unread_only: bool = False,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get alerts for a user."""
        query = """
            SELECT * FROM alerts 
            WHERE user_id = ? 
            AND is_dismissed = 0
            AND (expires_at IS NULL OR datetime(expires_at) > datetime('now'))
        """
        
        if unread_only:
            query += " AND is_read = 0"
        
        query += " ORDER BY created_at DESC LIMIT ?"
        
        return db.fetch_all(query, (user_id, limit))
    
    def get_alert(self, alert_id: str) -> Optional[Dict[str, Any]]:
        """Get a single alert by ID."""
        return db.fetch_one(
            "SELECT * FROM alerts WHERE id = ?",
            (alert_id,)
        )
    
    def mark_alert_read(self, alert_id: str, user_id: str) -> bool:
        """Mark an alert as read."""
        try:
            db.execute("""
                UPDATE alerts 
                SET is_read = 1, read_at = ? 
                WHERE id = ? AND user_id = ?
            """, (now_iso(), alert_id, user_id))
            return True
        except Exception:
            return False
    
    def dismiss_alert(self, alert_id: str, user_id: str) -> bool:
        """Dismiss an alert."""
        try:
            db.execute("""
                UPDATE alerts 
                SET is_dismissed = 1 
                WHERE id = ? AND user_id = ?
            """, (alert_id, user_id))
            return True
        except Exception:
            return False
    
    def get_unread_count(self, user_id: str) -> int:
        """Get count of unread alerts for a user."""
        result = db.fetch_one("""
            SELECT COUNT(*) as count FROM alerts 
            WHERE user_id = ? AND is_read = 0 AND is_dismissed = 0
            AND (expires_at IS NULL OR datetime(expires_at) > datetime('now'))
        """, (user_id,))
        
        return result["count"] if result else 0
    
    # =========================================================================
    # BULK ALERTS
    # =========================================================================
    
    def create_weather_alerts(
        self,
        latitude: float,
        longitude: float,
        conditions: Dict[str, Any]
    ) -> int:
        """
        Create weather alerts for all farms in an area.
        
        Returns:
            Number of alerts created
        """
        # Find farms in the area (within ~50km)
        delta = 0.5  # Roughly 50km
        farms = db.fetch_all("""
            SELECT f.id, f.user_id, f.name FROM farms f
            WHERE f.latitude BETWEEN ? AND ?
            AND f.longitude BETWEEN ? AND ?
        """, (
            latitude - delta, latitude + delta,
            longitude - delta, longitude + delta
        ))
        
        alert_count = 0
        temp = conditions.get("temperature_celsius", 25)
        rain_chance = conditions.get("rain_chance", 0)
        wind_speed = conditions.get("wind_speed_kmh", 0)
        
        for farm in farms:
            alerts_to_create = []
            
            # High temperature alert
            if temp > 38:
                alerts_to_create.append({
                    "type": "weather",
                    "severity": "high",
                    "title": "Extreme Heat Warning",
                    "message": f"Temperature expected to reach {temp}°C. Take precautions for your crops and livestock."
                })
            
            # Heavy rain alert
            if rain_chance > 80:
                alerts_to_create.append({
                    "type": "weather",
                    "severity": "warning",
                    "title": "Heavy Rain Expected",
                    "message": f"High probability ({rain_chance}%) of rainfall. Consider delaying outdoor activities."
                })
            
            # High wind alert
            if wind_speed > 40:
                alerts_to_create.append({
                    "type": "weather",
                    "severity": "warning",
                    "title": "High Wind Warning",
                    "message": f"Wind speeds up to {wind_speed} km/h expected. Secure loose items and support tall plants."
                })
            
            for alert_data in alerts_to_create:
                success, _ = self.create_alert(
                    user_id=farm["user_id"],
                    alert_type=alert_data["type"],
                    severity=alert_data["severity"],
                    title=alert_data["title"],
                    message=alert_data["message"],
                    farm_id=farm["id"]
                )
                if success:
                    alert_count += 1
        
        return alert_count
    
    def create_price_alerts(
        self,
        crop_name: str,
        market_name: str,
        current_price: float,
        previous_price: float,
        change_percent: float
    ) -> int:
        """
        Create price alerts for users tracking this crop.
        
        Returns:
            Number of alerts created
        """
        if abs(change_percent) < 5:
            return 0  # Only alert for significant changes
        
        # Find users with this crop
        users = db.fetch_all("""
            SELECT DISTINCT u.id, u.notification_enabled
            FROM users u
            JOIN farms f ON f.user_id = u.id
            JOIN crops c ON c.farm_id = f.id
            JOIN crop_master cm ON cm.id = c.crop_master_id
            WHERE cm.name = ? AND u.notification_enabled = 1
        """, (crop_name,))
        
        alert_count = 0
        direction = "increased" if change_percent > 0 else "decreased"
        severity = "info" if abs(change_percent) < 10 else "warning"
        
        for user in users:
            success, _ = self.create_alert(
                user_id=user["id"],
                alert_type="price",
                severity=severity,
                title=f"Price Alert: {crop_name}",
                message=f"{crop_name} price {direction} by {abs(change_percent):.1f}% at {market_name}. Current price: ₹{current_price}/quintal.",
                action_url="/prices",
                action_label="View Prices"
            )
            if success:
                alert_count += 1
        
        return alert_count
    
    # =========================================================================
    # EMAIL NOTIFICATIONS
    # =========================================================================
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        body: str,
        is_html: bool = False
    ) -> Tuple[bool, str]:
        """
        Send an email using SendGrid.
        
        Returns:
            Tuple of (success: bool, message: str)
        """
        if self.sendgrid_api_key == "YOUR_SENDGRID_API_KEY_HERE":
            # Development mode - just log
            print(f"[EMAIL] To: {to_email}, Subject: {subject}")
            return True, "Email sent (dev mode)"
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://api.sendgrid.com/v3/mail/send",
                    headers={
                        "Authorization": f"Bearer {self.sendgrid_api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "personalizations": [{"to": [{"email": to_email}]}],
                        "from": {"email": self.from_email, "name": "AgriSense Pro"},
                        "subject": subject,
                        "content": [{
                            "type": "text/html" if is_html else "text/plain",
                            "value": body
                        }]
                    },
                    timeout=10.0
                )
                
                if response.status_code in [200, 202]:
                    return True, "Email sent successfully"
                else:
                    return False, f"SendGrid error: {response.status_code}"
                    
        except Exception as e:
            return False, str(e)
    
    async def send_password_reset_email(
        self,
        to_email: str,
        user_name: str,
        reset_link: str
    ) -> Tuple[bool, str]:
        """Send password reset email."""
        subject = "Reset Your AgriSense Pro Password"
        body = f"""
        <html>
        <body style="font-family: Arial, sans-serif;">
            <h2>Password Reset Request</h2>
            <p>Hello {user_name},</p>
            <p>We received a request to reset your password. Click the button below to create a new password:</p>
            <p style="margin: 20px 0;">
                <a href="{reset_link}" style="background-color: #2E7D32; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">
                    Reset Password
                </a>
            </p>
            <p>This link will expire in 1 hour.</p>
            <p>If you didn't request this, you can safely ignore this email.</p>
            <hr>
            <p style="color: #666; font-size: 12px;">
                AgriSense Pro - AI Crop Intelligence & Farmer Profit Engine<br>
                Made in India 🇮🇳
            </p>
        </body>
        </html>
        """
        
        return await self.send_email(to_email, subject, body, is_html=True)
    
    async def send_verification_email(
        self,
        to_email: str,
        user_name: str,
        verify_link: str
    ) -> Tuple[bool, str]:
        """Send email verification email."""
        subject = "Verify Your AgriSense Pro Email"
        body = f"""
        <html>
        <body style="font-family: Arial, sans-serif;">
            <h2>Welcome to AgriSense Pro!</h2>
            <p>Hello {user_name},</p>
            <p>Thank you for registering. Please verify your email address to complete your registration:</p>
            <p style="margin: 20px 0;">
                <a href="{verify_link}" style="background-color: #2E7D32; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">
                    Verify Email
                </a>
            </p>
            <p>This link will expire in 24 hours.</p>
            <hr>
            <p style="color: #666; font-size: 12px;">
                AgriSense Pro - AI Crop Intelligence & Farmer Profit Engine<br>
                Made in India 🇮🇳
            </p>
        </body>
        </html>
        """
        
        return await self.send_email(to_email, subject, body, is_html=True)
    
    # =========================================================================
    # SMS NOTIFICATIONS
    # =========================================================================
    
    async def send_sms(
        self,
        to_phone: str,
        message: str
    ) -> Tuple[bool, str]:
        """
        Send an SMS using Twilio.
        
        Returns:
            Tuple of (success: bool, message: str)
        """
        if self.twilio_sid == "YOUR_TWILIO_ACCOUNT_SID_HERE":
            # Development mode
            print(f"[SMS] To: {to_phone}, Message: {message}")
            return True, "SMS sent (dev mode)"
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"https://api.twilio.com/2010-04-01/Accounts/{self.twilio_sid}/Messages.json",
                    auth=(self.twilio_sid, self.twilio_token),
                    data={
                        "From": self.twilio_phone,
                        "To": to_phone,
                        "Body": message
                    },
                    timeout=10.0
                )
                
                if response.status_code in [200, 201]:
                    return True, "SMS sent successfully"
                else:
                    return False, f"Twilio error: {response.status_code}"
                    
        except Exception as e:
            return False, str(e)
    
    async def send_alert_sms(
        self,
        to_phone: str,
        alert_title: str,
        alert_message: str
    ) -> Tuple[bool, str]:
        """Send an alert via SMS."""
        message = f"AgriSense Pro Alert: {alert_title}\n\n{alert_message}"
        
        # Truncate if too long
        if len(message) > 160:
            message = message[:157] + "..."
        
        return await self.send_sms(to_phone, message)
    
    # =========================================================================
    # PUSH NOTIFICATIONS
    # =========================================================================
    
    async def send_push_notification(
        self,
        device_token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None
    ) -> Tuple[bool, str]:
        """
        Send a push notification using Firebase Cloud Messaging.
        
        Returns:
            Tuple of (success: bool, message: str)
        """
        if self.fcm_key == "YOUR_FCM_SERVER_KEY_HERE":
            # Development mode
            print(f"[PUSH] To: {device_token[:20]}..., Title: {title}")
            return True, "Push sent (dev mode)"
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://fcm.googleapis.com/fcm/send",
                    headers={
                        "Authorization": f"key={self.fcm_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "to": device_token,
                        "notification": {
                            "title": title,
                            "body": body,
                            "sound": "default"
                        },
                        "data": data or {}
                    },
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    return True, "Push notification sent"
                else:
                    return False, f"FCM error: {response.status_code}"
                    
        except Exception as e:
            return False, str(e)


# Global service instance
notification_service = NotificationService()
