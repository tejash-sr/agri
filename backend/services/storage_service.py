"""
AgriSense Pro - Storage Service
Handles file uploads, image storage, and asset management
"""

import os
import uuid
import hashlib
import mimetypes
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List, Tuple
import base64
import httpx

from core.config import settings


class StorageService:
    """Storage service for file and image management"""
    
    def __init__(self):
        self.upload_dir = Path(settings.UPLOAD_DIR)
        self.max_size_mb = settings.MAX_UPLOAD_SIZE_MB
        self.allowed_types = settings.ALLOWED_IMAGE_TYPES
        self.cloudinary_cloud = settings.CLOUDINARY_CLOUD_NAME
        self.cloudinary_key = settings.CLOUDINARY_API_KEY
        self.cloudinary_secret = settings.CLOUDINARY_API_SECRET
        
        # Ensure upload directory exists
        self.upload_dir.mkdir(parents=True, exist_ok=True)
    
    # =========================================================================
    # LOCAL FILE STORAGE
    # =========================================================================
    
    def save_file(
        self,
        file_data: bytes,
        filename: str,
        user_id: str,
        category: str = "general"
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Save a file to local storage.
        
        Returns:
            Tuple of (success: bool, result: Dict with file info or error)
        """
        # Validate file size
        file_size = len(file_data)
        if file_size > self.max_size_mb * 1024 * 1024:
            return False, {"error": f"File exceeds maximum size of {self.max_size_mb}MB"}
        
        # Get file extension and mime type
        ext = Path(filename).suffix.lower()
        mime_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
        
        # Generate unique filename
        file_id = str(uuid.uuid4())
        new_filename = f"{file_id}{ext}"
        
        # Create category directory
        category_dir = self.upload_dir / user_id / category
        category_dir.mkdir(parents=True, exist_ok=True)
        
        file_path = category_dir / new_filename
        
        try:
            # Save file
            with open(file_path, "wb") as f:
                f.write(file_data)
            
            # Calculate file hash for deduplication
            file_hash = hashlib.md5(file_data).hexdigest()
            
            return True, {
                "file_id": file_id,
                "filename": new_filename,
                "original_name": filename,
                "path": str(file_path),
                "url": f"/uploads/{user_id}/{category}/{new_filename}",
                "size": file_size,
                "mime_type": mime_type,
                "hash": file_hash,
                "uploaded_at": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            return False, {"error": str(e)}
    
    def save_image(
        self,
        image_data: bytes,
        filename: str,
        user_id: str,
        category: str = "images"
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Save an image file with validation.
        
        Returns:
            Tuple of (success: bool, result: Dict with image info or error)
        """
        # Get mime type
        mime_type = mimetypes.guess_type(filename)[0]
        
        # Validate image type
        if mime_type not in self.allowed_types:
            return False, {
                "error": f"Invalid image type. Allowed: {', '.join(self.allowed_types)}"
            }
        
        return self.save_file(image_data, filename, user_id, category)
    
    def get_file(self, file_path: str) -> Optional[bytes]:
        """Get file contents from storage."""
        path = Path(file_path)
        if path.exists() and path.is_file():
            with open(path, "rb") as f:
                return f.read()
        return None
    
    def delete_file(self, file_path: str) -> bool:
        """Delete a file from storage."""
        try:
            path = Path(file_path)
            if path.exists():
                path.unlink()
                return True
            return False
        except Exception:
            return False
    
    def list_user_files(
        self,
        user_id: str,
        category: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """List all files for a user."""
        user_dir = self.upload_dir / user_id
        
        if not user_dir.exists():
            return []
        
        files = []
        search_path = user_dir / category if category else user_dir
        
        for file_path in search_path.rglob("*"):
            if file_path.is_file():
                stat = file_path.stat()
                files.append({
                    "path": str(file_path),
                    "filename": file_path.name,
                    "size": stat.st_size,
                    "created_at": datetime.fromtimestamp(stat.st_ctime).isoformat(),
                    "modified_at": datetime.fromtimestamp(stat.st_mtime).isoformat()
                })
        
        return files
    
    # =========================================================================
    # CLOUDINARY STORAGE (CLOUD)
    # =========================================================================
    
    async def upload_to_cloudinary(
        self,
        file_data: bytes,
        filename: str,
        folder: str = "agrisense"
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Upload file to Cloudinary for cloud storage.
        
        Returns:
            Tuple of (success: bool, result: Dict with cloud URL or error)
        """
        if self.cloudinary_cloud == "YOUR_CLOUDINARY_CLOUD_NAME":
            # Development mode - save locally instead
            return self.save_file(file_data, filename, "cloud", folder)
        
        try:
            # Generate upload signature
            timestamp = str(int(datetime.utcnow().timestamp()))
            public_id = f"{folder}/{uuid.uuid4()}"
            
            to_sign = f"public_id={public_id}&timestamp={timestamp}{self.cloudinary_secret}"
            signature = hashlib.sha1(to_sign.encode()).hexdigest()
            
            # Prepare file for upload
            base64_data = base64.b64encode(file_data).decode()
            mime_type = mimetypes.guess_type(filename)[0] or "image/jpeg"
            file_string = f"data:{mime_type};base64,{base64_data}"
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"https://api.cloudinary.com/v1_1/{self.cloudinary_cloud}/image/upload",
                    data={
                        "file": file_string,
                        "public_id": public_id,
                        "timestamp": timestamp,
                        "api_key": self.cloudinary_key,
                        "signature": signature
                    },
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return True, {
                        "url": data.get("secure_url"),
                        "public_id": data.get("public_id"),
                        "format": data.get("format"),
                        "width": data.get("width"),
                        "height": data.get("height"),
                        "size": data.get("bytes")
                    }
                else:
                    return False, {"error": f"Cloudinary error: {response.text}"}
                    
        except Exception as e:
            return False, {"error": str(e)}
    
    async def delete_from_cloudinary(self, public_id: str) -> bool:
        """Delete a file from Cloudinary."""
        if self.cloudinary_cloud == "YOUR_CLOUDINARY_CLOUD_NAME":
            return True
        
        try:
            timestamp = str(int(datetime.utcnow().timestamp()))
            to_sign = f"public_id={public_id}&timestamp={timestamp}{self.cloudinary_secret}"
            signature = hashlib.sha1(to_sign.encode()).hexdigest()
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"https://api.cloudinary.com/v1_1/{self.cloudinary_cloud}/image/destroy",
                    data={
                        "public_id": public_id,
                        "timestamp": timestamp,
                        "api_key": self.cloudinary_key,
                        "signature": signature
                    },
                    timeout=10.0
                )
                
                return response.status_code == 200
                
        except Exception:
            return False
    
    # =========================================================================
    # BASE64 HANDLING
    # =========================================================================
    
    def decode_base64_image(self, base64_string: str) -> Tuple[bytes, str]:
        """
        Decode a base64 image string.
        
        Returns:
            Tuple of (image_bytes, mime_type)
        """
        # Handle data URL format
        if "," in base64_string:
            header, data = base64_string.split(",", 1)
            # Extract mime type from header (e.g., "data:image/jpeg;base64")
            mime_type = header.split(":")[1].split(";")[0]
        else:
            data = base64_string
            mime_type = "image/jpeg"
        
        image_bytes = base64.b64decode(data)
        return image_bytes, mime_type
    
    def encode_to_base64(self, file_data: bytes, mime_type: str) -> str:
        """Encode file data to base64 data URL."""
        encoded = base64.b64encode(file_data).decode()
        return f"data:{mime_type};base64,{encoded}"
    
    # =========================================================================
    # CROP IMAGE STORAGE
    # =========================================================================
    
    def save_disease_scan_image(
        self,
        image_data: bytes,
        user_id: str,
        crop_id: Optional[str] = None
    ) -> Tuple[bool, Dict[str, Any]]:
        """Save a disease scan image."""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"scan_{timestamp}.jpg"
        
        return self.save_image(
            image_data,
            filename,
            user_id,
            category="disease_scans"
        )
    
    def save_listing_image(
        self,
        image_data: bytes,
        user_id: str,
        listing_id: str
    ) -> Tuple[bool, Dict[str, Any]]:
        """Save a marketplace listing image."""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"listing_{listing_id}_{timestamp}.jpg"
        
        return self.save_image(
            image_data,
            filename,
            user_id,
            category="listings"
        )
    
    def save_profile_image(
        self,
        image_data: bytes,
        user_id: str
    ) -> Tuple[bool, Dict[str, Any]]:
        """Save a user profile image."""
        filename = f"avatar_{user_id}.jpg"
        
        return self.save_image(
            image_data,
            filename,
            user_id,
            category="profiles"
        )
    
    # =========================================================================
    # STORAGE STATISTICS
    # =========================================================================
    
    def get_user_storage_stats(self, user_id: str) -> Dict[str, Any]:
        """Get storage usage statistics for a user."""
        user_dir = self.upload_dir / user_id
        
        if not user_dir.exists():
            return {
                "total_files": 0,
                "total_size": 0,
                "by_category": {}
            }
        
        total_files = 0
        total_size = 0
        by_category = {}
        
        for category_dir in user_dir.iterdir():
            if category_dir.is_dir():
                category_files = 0
                category_size = 0
                
                for file_path in category_dir.rglob("*"):
                    if file_path.is_file():
                        category_files += 1
                        category_size += file_path.stat().st_size
                
                by_category[category_dir.name] = {
                    "files": category_files,
                    "size": category_size
                }
                
                total_files += category_files
                total_size += category_size
        
        return {
            "total_files": total_files,
            "total_size": total_size,
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "by_category": by_category
        }
    
    def cleanup_old_files(
        self,
        max_age_days: int = 30,
        category: Optional[str] = None
    ) -> int:
        """
        Clean up old temporary files.
        
        Returns:
            Number of files deleted
        """
        cutoff = datetime.utcnow().timestamp() - (max_age_days * 24 * 60 * 60)
        deleted_count = 0
        
        search_path = self.upload_dir
        if category:
            search_path = self.upload_dir / "*" / category
        
        for file_path in search_path.rglob("*"):
            if file_path.is_file():
                if file_path.stat().st_mtime < cutoff:
                    try:
                        file_path.unlink()
                        deleted_count += 1
                    except Exception:
                        pass
        
        return deleted_count


# Global service instance
storage_service = StorageService()
