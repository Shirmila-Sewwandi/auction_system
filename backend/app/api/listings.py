from fastapi import APIRouter, Depends, File, Query, UploadFile
from sqlalchemy import or_
from sqlalchemy.orm import Session, selectinload

from app.core.deps import get_current_user_optional, get_db, require_roles
from app.core.exceptions import ConflictError, ForbiddenError, NotFoundError
from app.core.rate_limit import rate_limit_by_user_or_ip
from app.models.bid import Bid
from app.models.category import Category
from app.models.listing import Listing, ListingImage
from app.models.platform_config import PlatformConfig
from app.models.user import User
from app.schemas.listing import (
    ImageOut,
    ListingCreate,
    ListingOut,
    ListingPage,
    ListingPatch,
    ListingSummary,
    ListingUpdate,
)
from app.services.audit import log_action
from app.services.cache import get_cached_listing, invalidate_listing, set_cached_listing
from app.services.storage import delete_listing_image, save_listing_image

router = APIRouter(prefix="/api/listings", tags=["listings"])

PAGE_SIZE = 20

# Fields that may still be edited via PATCH once the listing already has bids —
# everything price/time/category related is locked at that point (US-S02).
PATCHABLE_AFTER_BIDDING = {"title", "description", "condition", "provenance"}


def _has_bids(db: Session, listing_id: int) -> bool:
    return db.query(Bid.bid_id).filter_by(listing_id=listing_id).first() is not None


def _visible_to(listing: Listing, user: User | None) -> bool:
    if listing.moderation_status == "Approved":
        return True
    if user is not None and (user.user_id == listing.seller_id or _is_staff(user)):
        return True
    return False


def _is_staff(user: User) -> bool:
    return bool({r.role_name for r in user.roles} & {"MODERATOR", "ADMIN"})


@router.get("", response_model=ListingPage, dependencies=[Depends(rate_limit_by_user_or_ip(60, 10))])
def browse_listings(
    db: Session = Depends(get_db),
    search: str | None = Query(None),
    category: int | None = Query(None),
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
):
    query = db.query(Listing).filter(Listing.moderation_status == "Approved")

    if status:
        query = query.filter(Listing.status == status)
    else:
        # Default browse view: don't surface closed/cancelled auctions (US-G01 edge case).
        query = query.filter(Listing.status.in_(["Pending", "Active"]))

    if category is not None:
        query = query.filter(Listing.category_id == category)
    if search:
        like = f"%{search}%"
        query = query.filter(or_(Listing.title.ilike(like), Listing.description.ilike(like)))

    total = query.count()
    items = (
        query.options(selectinload(Listing.images))
        .order_by(Listing.end_time.asc())
        .offset((page - 1) * PAGE_SIZE)
        .limit(PAGE_SIZE)
        .all()
    )
    summaries = [
        ListingSummary(
            listing_id=listing.listing_id,
            title=listing.title,
            current_price=listing.current_price,
            end_time=listing.end_time,
            status=listing.status,
            thumbnail=listing.images[0].image_path if listing.images else None,
        )
        for listing in items
    ]
    return ListingPage(items=summaries, page=page, total=total)


@router.get("/{listing_id}", response_model=ListingOut)
def get_listing(
    listing_id: int,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_current_user_optional),
):
    # Cache only the common hot path (anonymous/guest viewing an already-approved listing) —
    # owners/staff always see live data so a preview or moderation decision is never stale.
    anonymous = user is None
    if anonymous:
        cached = get_cached_listing(listing_id)
        if cached is not None:
            return cached

    listing = db.get(Listing, listing_id)
    if listing is None or not _visible_to(listing, user):
        raise NotFoundError("Listing not found")

    if anonymous and listing.moderation_status == "Approved":
        set_cached_listing(listing_id, ListingOut.model_validate(listing).model_dump(mode="json"))

    return listing


@router.post("", response_model=dict)
def create_listing(
    payload: ListingCreate,
    db: Session = Depends(get_db),
    seller: User = Depends(require_roles("SELLER")),
):
    category = db.get(Category, payload.category_id)
    if category is None or not category.is_active:
        raise NotFoundError("Category not found or inactive")

    config = db.get(PlatformConfig, 1)

    listing = Listing(
        seller_id=seller.user_id,
        category_id=payload.category_id,
        title=payload.title,
        description=payload.description,
        condition=payload.condition,
        provenance=payload.provenance,
        starting_price=payload.starting_price,
        reserve_price=payload.reserve_price,
        current_price=payload.starting_price,
        min_bid_increment=config.min_bid_increment if config else 1.00,
        anti_sniping_window_minutes=config.anti_sniping_window_minutes if config else 5,
        anti_sniping_extension_minutes=config.anti_sniping_extension_minutes if config else 10,
        max_anti_sniping_extensions=config.max_anti_sniping_extensions if config else None,
        start_time=payload.start_time,
        end_time=payload.end_time,
        original_end_time=payload.end_time,
        status="Pending",
        moderation_status="Pending Review",
    )
    db.add(listing)
    db.flush()
    log_action(
        db,
        user_id=seller.user_id,
        action="LISTING_CREATED",
        entity_type="Listing",
        entity_id=listing.listing_id,
        new_value={"title": listing.title, "starting_price": str(listing.starting_price)},
    )
    db.commit()
    db.refresh(listing)
    return {"listing_id": listing.listing_id, "status": listing.status, "message": "Listing submitted for approval"}


def _get_owned_listing(db: Session, listing_id: int, seller: User) -> Listing:
    listing = db.get(Listing, listing_id)
    if listing is None:
        raise NotFoundError("Listing not found")
    if listing.seller_id != seller.user_id:
        raise ForbiddenError("You do not own this listing")
    return listing


@router.put("/{listing_id}", response_model=dict)
def replace_listing(
    listing_id: int,
    payload: ListingUpdate,
    db: Session = Depends(get_db),
    seller: User = Depends(require_roles("SELLER")),
):
    listing = _get_owned_listing(db, listing_id, seller)
    if _has_bids(db, listing_id):
        raise ConflictError("Cannot fully replace a listing after bidding has started")

    for field in ("category_id", "title", "description", "condition", "provenance", "start_time", "end_time"):
        setattr(listing, field, getattr(payload, field))
    listing.starting_price = payload.starting_price
    listing.reserve_price = payload.reserve_price
    listing.current_price = payload.starting_price
    listing.original_end_time = payload.end_time

    log_action(db, user_id=seller.user_id, action="LISTING_UPDATED", entity_type="Listing", entity_id=listing_id)
    db.commit()
    invalidate_listing(listing_id)
    return {"listing_id": listing_id, "message": "Listing updated"}


@router.patch("/{listing_id}", response_model=dict)
def patch_listing(
    listing_id: int,
    payload: ListingPatch,
    db: Session = Depends(get_db),
    seller: User = Depends(require_roles("SELLER")),
):
    listing = _get_owned_listing(db, listing_id, seller)
    has_bids = _has_bids(db, listing_id)
    updates = payload.model_dump(exclude_unset=True)

    if has_bids:
        disallowed = set(updates) - PATCHABLE_AFTER_BIDDING
        if disallowed:
            raise ConflictError(f"Cannot edit {sorted(disallowed)} after bidding has started")

    for field, value in updates.items():
        setattr(listing, field, value)

    log_action(db, user_id=seller.user_id, action="LISTING_PATCHED", entity_type="Listing", entity_id=listing_id)
    db.commit()
    invalidate_listing(listing_id)
    return {"listing_id": listing_id, "message": "Listing updated"}


@router.delete("/{listing_id}", response_model=dict)
def delete_listing(
    listing_id: int,
    db: Session = Depends(get_db),
    seller: User = Depends(require_roles("SELLER")),
):
    listing = _get_owned_listing(db, listing_id, seller)
    if _has_bids(db, listing_id):
        raise ConflictError("Cannot delete a listing that already has bids")

    log_action(db, user_id=seller.user_id, action="LISTING_DELETED", entity_type="Listing", entity_id=listing_id)
    db.delete(listing)
    db.commit()
    invalidate_listing(listing_id)
    return {"listing_id": listing_id, "message": "Listing deleted"}


@router.post("/{listing_id}/images", response_model=ImageOut)
def upload_image(
    listing_id: int,
    db: Session = Depends(get_db),
    seller: User = Depends(require_roles("SELLER")),
    image: UploadFile = File(...),
):
    listing = _get_owned_listing(db, listing_id, seller)
    path = save_listing_image(listing_id, image)
    next_order = len(listing.images)
    record = ListingImage(listing_id=listing_id, image_path=path, display_order=next_order)
    db.add(record)
    db.commit()
    db.refresh(record)
    invalidate_listing(listing_id)
    return record


@router.delete("/{listing_id}/images/{image_id}", response_model=dict)
def remove_image(
    listing_id: int,
    image_id: int,
    db: Session = Depends(get_db),
    seller: User = Depends(require_roles("SELLER")),
):
    _get_owned_listing(db, listing_id, seller)
    image = db.get(ListingImage, image_id)
    if image is None or image.listing_id != listing_id:
        raise NotFoundError("Image not found")
    delete_listing_image(image.image_path)
    db.delete(image)
    db.commit()
    invalidate_listing(listing_id)
    return {"message": "Image deleted"}
