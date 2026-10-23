from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_db
from app.core.exceptions import ConflictError, ForbiddenError, NotFoundError
from app.models.auction_result import AuctionResult
from app.models.dispute import Dispute
from app.models.listing import Listing
from app.models.user import User
from app.schemas.dispute import DisputeCreate, DisputePatch
from app.services.disputes import raise_dispute

router = APIRouter(prefix="/api/disputes", tags=["disputes"])


def _is_staff(user: User) -> bool:
    return bool({r.role_name for r in user.roles} & {"MODERATOR", "ADMIN"})


@router.post("")
def create_dispute(payload: DisputeCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    dispute = raise_dispute(
        db,
        auction_result_id=payload.auction_result_id,
        raiser=user,
        dispute_type=payload.dispute_type,
        reason=payload.reason,
        description=payload.description,
    )
    db.commit()
    db.refresh(dispute)
    return {"dispute_id": dispute.dispute_id, "status": dispute.status, "message": "Dispute filed"}


@router.get("/me")
def my_disputes(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    disputes = db.query(Dispute).filter_by(raised_by=user.user_id).order_by(Dispute.created_at.desc()).all()
    return {
        "disputes": [
            {
                "dispute_id": d.dispute_id,
                "auction_result_id": d.auction_result_id,
                "dispute_type": d.dispute_type,
                "status": d.status,
                "created_at": d.created_at,
            }
            for d in disputes
        ]
    }


def _get_visible_dispute(db: Session, dispute_id: int, user: User) -> Dispute:
    dispute = db.get(Dispute, dispute_id)
    if dispute is None:
        raise NotFoundError("Dispute not found")
    if dispute.raised_by == user.user_id or _is_staff(user):
        return dispute
    result = db.get(AuctionResult, dispute.auction_result_id)
    listing = db.get(Listing, result.listing_id) if result else None
    if result and user.user_id in (result.winner_id, listing.seller_id if listing else None):
        return dispute
    raise ForbiddenError("You do not have access to this dispute")


@router.get("/{dispute_id}")
def get_dispute(dispute_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    dispute = _get_visible_dispute(db, dispute_id, user)
    return {
        "dispute_id": dispute.dispute_id,
        "auction_result_id": dispute.auction_result_id,
        "raised_by": dispute.raised_by,
        "dispute_type": dispute.dispute_type,
        "reason": dispute.reason,
        "description": dispute.description,
        "status": dispute.status,
        "resolution": dispute.resolution,
    }


@router.patch("/{dispute_id}")
def patch_dispute(
    dispute_id: int,
    payload: DisputePatch,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    dispute = db.get(Dispute, dispute_id)
    if dispute is None:
        raise NotFoundError("Dispute not found")
    if dispute.raised_by != user.user_id:
        raise ForbiddenError("Only the person who raised this dispute can amend it")
    if dispute.status != "Open":
        raise ConflictError("This dispute can no longer be amended")

    if payload.reason is not None:
        dispute.reason = payload.reason
    if payload.description is not None:
        dispute.description = payload.description
    db.commit()
    return {"dispute_id": dispute.dispute_id, "status": dispute.status, "message": "Dispute updated"}
