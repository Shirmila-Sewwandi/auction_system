from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_db
from app.core.exceptions import NotFoundError
from app.models.auction_result import AuctionResult
from app.models.listing import Listing
from app.models.user import User

router = APIRouter(tags=["auction-results"])


@router.get("/api/listings/{listing_id}/result")
def get_result(listing_id: int, db: Session = Depends(get_db)):
    result = db.query(AuctionResult).filter_by(listing_id=listing_id).first()
    if result is None:
        raise NotFoundError("This auction has not closed yet")
    return {
        "result_id": result.result_id,
        "listing_id": result.listing_id,
        "winner_id": result.winner_id,
        "final_price": result.final_price,
        "reserve_met": result.reserve_met,
        "result_status": result.result_status,
        "closed_at": result.closed_at,
    }


@router.get("/api/auction-results/me")
def my_results(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    rows = (
        db.query(AuctionResult, Listing.title)
        .join(Listing, Listing.listing_id == AuctionResult.listing_id)
        .filter((AuctionResult.winner_id == user.user_id) | (Listing.seller_id == user.user_id))
        .order_by(AuctionResult.closed_at.desc())
        .all()
    )
    return {
        "results": [
            {
                "result_id": result.result_id,
                "listing_id": result.listing_id,
                "title": title,
                "final_price": result.final_price,
                "result_status": result.result_status,
            }
            for result, title in rows
        ]
    }
