"""
AgriSense Pro - Marketplace Routes
Farmer-to-buyer marketplace for agricultural products
"""

from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from datetime import datetime, date
import json

from models.schemas import (
    ListingCreate, ListingUpdate, ListingResponse, ListingFilters,
    ListingInquiryCreate, ListingInquiryResponse, BaseResponse, ListingStatus
)
from api.routes.auth import get_current_user, get_current_user_optional
from db.database import db, generate_uuid, now_iso

router = APIRouter(prefix="/marketplace", tags=["Marketplace"])


@router.get("/listings", response_model=List[ListingResponse])
async def get_listings(
    crop_name: Optional[str] = None,
    state: Optional[str] = None,
    district: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    is_organic: Optional[bool] = None,
    delivery_available: Optional[bool] = None,
    sort_by: str = "created_at",
    sort_order: str = "desc",
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: Optional[dict] = Depends(get_current_user_optional)
):
    """
    Get marketplace listings with filters.
    Public endpoint - no authentication required.
    """
    query = """
        SELECT l.*, u.full_name as seller_name, u.phone as seller_phone
        FROM listings l
        JOIN users u ON l.user_id = u.id
        WHERE l.status = 'active'
    """
    params = []
    
    if crop_name:
        query += " AND LOWER(l.crop_name) LIKE LOWER(?)"
        params.append(f"%{crop_name}%")
    
    if state:
        query += " AND LOWER(l.state) = LOWER(?)"
        params.append(state)
    
    if district:
        query += " AND LOWER(l.district) = LOWER(?)"
        params.append(district)
    
    if min_price is not None:
        query += " AND l.price_per_unit >= ?"
        params.append(min_price)
    
    if max_price is not None:
        query += " AND l.price_per_unit <= ?"
        params.append(max_price)
    
    if is_organic is not None:
        query += " AND l.is_organic = ?"
        params.append(1 if is_organic else 0)
    
    if delivery_available is not None:
        query += " AND l.delivery_available = ?"
        params.append(1 if delivery_available else 0)
    
    # Sorting
    valid_sort_fields = ["created_at", "price_per_unit", "quantity", "views_count"]
    if sort_by in valid_sort_fields:
        order = "DESC" if sort_order.lower() == "desc" else "ASC"
        query += f" ORDER BY l.{sort_by} {order}"
    else:
        query += " ORDER BY l.created_at DESC"
    
    # Pagination
    offset = (page - 1) * per_page
    query += " LIMIT ? OFFSET ?"
    params.extend([per_page, offset])
    
    listings = db.fetch_all(query, tuple(params))
    
    return [_format_listing_response(l) for l in listings]


@router.post("/listings", response_model=ListingResponse, status_code=status.HTTP_201_CREATED)
async def create_listing(
    listing_data: ListingCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Create a new marketplace listing.
    """
    listing_id = generate_uuid()
    
    # Verify crop ownership if provided
    if listing_data.crop_id:
        crop = db.fetch_one(
            "SELECT id FROM crops WHERE id = ? AND user_id = ?",
            (listing_data.crop_id, current_user["id"])
        )
        if crop is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid crop ID"
            )
    
    images_json = json.dumps(listing_data.images) if listing_data.images else None
    certs_json = json.dumps(listing_data.certifications) if listing_data.certifications else None
    
    db.execute("""
        INSERT INTO listings (
            id, user_id, crop_id, crop_master_id, title, description,
            crop_name, variety, grade, quantity, unit, price_per_unit,
            min_order_quantity, negotiable, available_from,
            pickup_address, city, district, state, latitude, longitude,
            delivery_available, delivery_radius_km, images,
            is_organic, certifications, status, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        listing_id,
        current_user["id"],
        listing_data.crop_id,
        listing_data.crop_master_id,
        listing_data.title,
        listing_data.description,
        listing_data.crop_name,
        listing_data.variety,
        listing_data.grade,
        listing_data.quantity,
        listing_data.unit,
        listing_data.price_per_unit,
        listing_data.min_order_quantity,
        1 if listing_data.negotiable else 0,
        listing_data.available_from.isoformat() if listing_data.available_from else None,
        listing_data.pickup_address,
        listing_data.city,
        listing_data.district,
        listing_data.state,
        listing_data.latitude,
        listing_data.longitude,
        1 if listing_data.delivery_available else 0,
        listing_data.delivery_radius_km,
        images_json,
        1 if listing_data.is_organic else 0,
        certs_json,
        "active",
        now_iso(),
        now_iso()
    ))
    
    # Fetch and return created listing
    listing = db.fetch_one("""
        SELECT l.*, u.full_name as seller_name, u.phone as seller_phone
        FROM listings l
        JOIN users u ON l.user_id = u.id
        WHERE l.id = ?
    """, (listing_id,))
    
    return _format_listing_response(listing)


@router.get("/listings/my", response_model=List[ListingResponse])
async def get_my_listings(
    status_filter: Optional[ListingStatus] = Query(None, alias="status"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get current user's listings.
    """
    query = """
        SELECT l.*, u.full_name as seller_name, u.phone as seller_phone
        FROM listings l
        JOIN users u ON l.user_id = u.id
        WHERE l.user_id = ?
    """
    params = [current_user["id"]]
    
    if status_filter:
        query += " AND l.status = ?"
        params.append(status_filter.value)
    
    query += " ORDER BY l.created_at DESC"
    
    listings = db.fetch_all(query, tuple(params))
    
    return [_format_listing_response(l) for l in listings]


@router.get("/listings/{listing_id}", response_model=ListingResponse)
async def get_listing(
    listing_id: str,
    current_user: Optional[dict] = Depends(get_current_user_optional)
):
    """
    Get a specific listing by ID.
    """
    listing = db.fetch_one("""
        SELECT l.*, u.full_name as seller_name, u.phone as seller_phone
        FROM listings l
        JOIN users u ON l.user_id = u.id
        WHERE l.id = ?
    """, (listing_id,))
    
    if listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Listing not found"
        )
    
    # Increment view count (only for non-owners)
    if not current_user or current_user["id"] != listing["user_id"]:
        db.execute(
            "UPDATE listings SET views_count = views_count + 1 WHERE id = ?",
            (listing_id,)
        )
    
    return _format_listing_response(listing)


@router.put("/listings/{listing_id}", response_model=ListingResponse)
async def update_listing(
    listing_id: str,
    listing_data: ListingUpdate,
    current_user: dict = Depends(get_current_user)
):
    """
    Update a listing.
    """
    # Check ownership
    listing = db.fetch_one(
        "SELECT * FROM listings WHERE id = ? AND user_id = ?",
        (listing_id, current_user["id"])
    )
    
    if listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Listing not found"
        )
    
    # Build update query
    updates = []
    params = []
    
    update_fields = listing_data.model_dump(exclude_unset=True)
    
    for field, value in update_fields.items():
        if value is not None:
            if field == "status":
                value = value.value
            elif field == "images":
                value = json.dumps(value)
            elif isinstance(value, date):
                value = value.isoformat()
            elif isinstance(value, bool):
                value = 1 if value else 0
            updates.append(f"{field} = ?")
            params.append(value)
    
    if updates:
        updates.append("updated_at = ?")
        params.append(now_iso())
        params.append(listing_id)
        
        db.execute(
            f"UPDATE listings SET {', '.join(updates)} WHERE id = ?",
            tuple(params)
        )
    
    return await get_listing(listing_id, current_user)


@router.delete("/listings/{listing_id}", response_model=BaseResponse)
async def delete_listing(
    listing_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a listing.
    """
    listing = db.fetch_one(
        "SELECT * FROM listings WHERE id = ? AND user_id = ?",
        (listing_id, current_user["id"])
    )
    
    if listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Listing not found"
        )
    
    db.execute("DELETE FROM listings WHERE id = ?", (listing_id,))
    
    return BaseResponse(message="Listing deleted successfully")


# =========================================================================
# INQUIRIES
# =========================================================================

@router.post("/inquiries", response_model=ListingInquiryResponse, status_code=status.HTTP_201_CREATED)
async def create_inquiry(
    inquiry_data: ListingInquiryCreate,
    current_user: dict = Depends(get_current_user)
):
    """
    Create an inquiry/bid for a listing.
    """
    # Verify listing exists and is active
    listing = db.fetch_one(
        "SELECT * FROM listings WHERE id = ? AND status = 'active'",
        (inquiry_data.listing_id,)
    )
    
    if listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Listing not found or not active"
        )
    
    # Prevent self-inquiry
    if listing["user_id"] == current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot inquire on your own listing"
        )
    
    inquiry_id = generate_uuid()
    
    db.execute("""
        INSERT INTO listing_inquiries (
            id, listing_id, buyer_id, offered_price,
            requested_quantity, message, status, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        inquiry_id,
        inquiry_data.listing_id,
        current_user["id"],
        inquiry_data.offered_price,
        inquiry_data.requested_quantity,
        inquiry_data.message,
        "pending",
        now_iso()
    ))
    
    # Update listing inquiry count
    db.execute(
        "UPDATE listings SET inquiries_count = inquiries_count + 1 WHERE id = ?",
        (inquiry_data.listing_id,)
    )
    
    # Create alert for seller
    _create_inquiry_alert(listing["user_id"], listing["title"], current_user["full_name"])
    
    return ListingInquiryResponse(
        id=inquiry_id,
        listing_id=inquiry_data.listing_id,
        buyer_id=current_user["id"],
        buyer_name=current_user["full_name"],
        offered_price=inquiry_data.offered_price,
        requested_quantity=inquiry_data.requested_quantity,
        message=inquiry_data.message,
        status="pending",
        created_at=datetime.utcnow()
    )


@router.get("/inquiries/received", response_model=List[ListingInquiryResponse])
async def get_received_inquiries(
    listing_id: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Get inquiries received on user's listings.
    """
    query = """
        SELECT i.*, u.full_name as buyer_name
        FROM listing_inquiries i
        JOIN listings l ON i.listing_id = l.id
        JOIN users u ON i.buyer_id = u.id
        WHERE l.user_id = ?
    """
    params = [current_user["id"]]
    
    if listing_id:
        query += " AND i.listing_id = ?"
        params.append(listing_id)
    
    query += " ORDER BY i.created_at DESC"
    
    inquiries = db.fetch_all(query, tuple(params))
    
    return [_format_inquiry_response(i) for i in inquiries]


@router.get("/inquiries/sent", response_model=List[ListingInquiryResponse])
async def get_sent_inquiries(
    current_user: dict = Depends(get_current_user)
):
    """
    Get inquiries sent by the user.
    """
    inquiries = db.fetch_all("""
        SELECT i.*, u.full_name as buyer_name
        FROM listing_inquiries i
        JOIN users u ON i.buyer_id = u.id
        WHERE i.buyer_id = ?
        ORDER BY i.created_at DESC
    """, (current_user["id"],))
    
    return [_format_inquiry_response(i) for i in inquiries]


@router.put("/inquiries/{inquiry_id}/respond")
async def respond_to_inquiry(
    inquiry_id: str,
    action: str,  # accept, reject
    response_message: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    """
    Respond to an inquiry (accept/reject).
    """
    # Verify inquiry and ownership
    inquiry = db.fetch_one("""
        SELECT i.*, l.user_id as seller_id
        FROM listing_inquiries i
        JOIN listings l ON i.listing_id = l.id
        WHERE i.id = ?
    """, (inquiry_id,))
    
    if inquiry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inquiry not found"
        )
    
    if inquiry["seller_id"] != current_user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to respond to this inquiry"
        )
    
    if action not in ["accept", "reject"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid action. Use 'accept' or 'reject'"
        )
    
    status_value = "accepted" if action == "accept" else "rejected"
    
    db.execute("""
        UPDATE listing_inquiries 
        SET status = ?, seller_response = ?, responded_at = ?
        WHERE id = ?
    """, (status_value, response_message, now_iso(), inquiry_id))
    
    return {"success": True, "message": f"Inquiry {status_value}"}


def _format_listing_response(listing: dict) -> ListingResponse:
    """Format listing database row to response model."""
    images = []
    if listing.get("images"):
        try:
            images = json.loads(listing["images"]) if isinstance(listing["images"], str) else listing["images"]
        except:
            images = []
    
    certifications = []
    if listing.get("certifications"):
        try:
            certifications = json.loads(listing["certifications"]) if isinstance(listing["certifications"], str) else listing["certifications"]
        except:
            certifications = []
    
    available_from = None
    if listing.get("available_from"):
        available_from = date.fromisoformat(listing["available_from"]) if isinstance(listing["available_from"], str) else listing["available_from"]
    
    return ListingResponse(
        id=listing["id"],
        user_id=listing["user_id"],
        crop_id=listing.get("crop_id"),
        crop_master_id=listing.get("crop_master_id"),
        title=listing["title"],
        description=listing.get("description"),
        crop_name=listing["crop_name"],
        variety=listing.get("variety"),
        grade=listing.get("grade"),
        quantity=listing["quantity"],
        unit=listing.get("unit", "kg"),
        price_per_unit=listing["price_per_unit"],
        min_order_quantity=listing.get("min_order_quantity"),
        negotiable=bool(listing.get("negotiable", 1)),
        available_from=available_from,
        pickup_address=listing.get("pickup_address"),
        city=listing.get("city"),
        district=listing.get("district"),
        state=listing.get("state"),
        latitude=listing.get("latitude"),
        longitude=listing.get("longitude"),
        delivery_available=bool(listing.get("delivery_available", 0)),
        delivery_radius_km=listing.get("delivery_radius_km"),
        images=images,
        is_organic=bool(listing.get("is_organic", 0)),
        certifications=certifications,
        status=listing.get("status", "active"),
        views_count=listing.get("views_count", 0),
        inquiries_count=listing.get("inquiries_count", 0),
        created_at=datetime.fromisoformat(listing["created_at"]),
        updated_at=datetime.fromisoformat(listing["updated_at"]),
        seller_name=listing.get("seller_name"),
        seller_phone=listing.get("seller_phone")
    )


def _format_inquiry_response(inquiry: dict) -> ListingInquiryResponse:
    """Format inquiry database row to response model."""
    responded_at = None
    if inquiry.get("responded_at"):
        responded_at = datetime.fromisoformat(inquiry["responded_at"])
    
    return ListingInquiryResponse(
        id=inquiry["id"],
        listing_id=inquiry["listing_id"],
        buyer_id=inquiry["buyer_id"],
        buyer_name=inquiry.get("buyer_name"),
        offered_price=inquiry.get("offered_price"),
        requested_quantity=inquiry.get("requested_quantity"),
        message=inquiry.get("message"),
        status=inquiry.get("status", "pending"),
        seller_response=inquiry.get("seller_response"),
        responded_at=responded_at,
        created_at=datetime.fromisoformat(inquiry["created_at"])
    )


def _create_inquiry_alert(seller_id: str, listing_title: str, buyer_name: str):
    """Create alert for new inquiry."""
    alert_id = generate_uuid()
    db.execute("""
        INSERT INTO alerts (
            id, user_id, alert_type, severity, title, message, action_required, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        alert_id,
        seller_id,
        "market",
        "info",
        "New Inquiry Received",
        f"{buyer_name} is interested in your listing: {listing_title}",
        1,
        now_iso()
    ))
