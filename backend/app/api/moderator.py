from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_db, require_roles
from app.models.dispute import Dispute
from app.models.listing import Listing
from app.models.user import User
from app.schemas.dispute import DisputeResolve
from app.schemas.moderation import ModerationAction
from app.services.cache import invalidate_listing
from app.services.disputes import resolve_dispute
from app.services.moderation import moderate_listing

router = APIRouter(prefix="/api/moderator", tags=["moderator"])


@router.get("/listings")
def list_for_moderation(
    status: str | None = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("MODERATOR")),
):
    query = db.query(Listing)
    query = query.filter(Listing.moderation_status == status) if status else query.filter(
        Listing.moderation_status == "Pending Review"
    )
    listings = query.order_by(Listing.created_at.asc()).all()
    return {
        "listings": [
            {
                "listing_id": listing.listing_id,
                "seller_id": listing.seller_id,
                "title": listing.title,
                "moderation_status": listing.moderation_status,
            }
            for listing in listings
        ]
    }


@router.patch("/listings/{listing_id}")
def moderate_listing_route(
    listing_id: int,
    payload: ModerationAction,
    db: Session = Depends(get_db),
    moderator: User = Depends(require_roles("MODERATOR")),
):
    listing = moderate_listing(
        db, listing_id=listing_id, moderator=moderator, action=payload.action, reason=payload.reason
    )
    db.commit()
    invalidate_listing(listing_id)
    return {
        "listing_id": listing_id,
        "moderation_status": listing.moderation_status,
        "message": "Moderation action recorded",
    }


@router.get("/disputes")
def list_disputes_for_moderation(
    status: str | None = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("MODERATOR")),
):
    query = db.query(Dispute)
    if status:
        query = query.filter(Dispute.status == status)
    disputes = query.order_by(Dispute.created_at.asc()).all()
    return {
        "disputes": [
            {
                "dispute_id": d.dispute_id,
                "auction_result_id": d.auction_result_id,
                "raised_by": d.raised_by,
                "status": d.status,
            }
            for d in disputes
        ]
    }


@router.patch("/disputes/{dispute_id}")
def moderate_dispute(
    dispute_id: int,
    payload: DisputeResolve,
    db: Session = Depends(get_db),
    moderator: User = Depends(require_roles("MODERATOR")),
):
    dispute = resolve_dispute(
        db,
        dispute_id=dispute_id,
        moderator=moderator,
        status=payload.status,
        resolution=payload.resolution,
        release_funds=payload.release_funds,
        refund_funds=payload.refund_funds,
    )
    db.commit()
    return {
        "dispute_id": dispute.dispute_id,
        "status": dispute.status,
        "resolution": dispute.resolution,
        "message": "Dispute updated",
    }
