from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.deps import get_db, require_roles
from app.core.exceptions import NotFoundError
from app.core.rate_limit import rate_limit_by_user_or_ip
from app.models.bid import Bid
from app.models.listing import Listing
from app.models.user import User
from app.schemas.bid import BidCreate, BidPlacedResponse
from app.services.bidding import place_bid
from app.services.cache import invalidate_listing
from app.services.realtime import broadcast_listing_update

router = APIRouter(tags=["bids"])
PAGE_SIZE = 20


@router.post(
    "/api/listings/{listing_id}/bids",
    response_model=BidPlacedResponse,
    dependencies=[Depends(rate_limit_by_user_or_ip(20, 10))],
)
def create_bid(
    listing_id: int,
    payload: BidCreate,
    db: Session = Depends(get_db),
    bidder: User = Depends(require_roles("BIDDER")),
):
    bid = place_bid(db, listing_id=listing_id, bidder=bidder, amount=payload.amount)
    db.commit()
    db.refresh(bid)
    listing = db.get(Listing, listing_id)
    invalidate_listing(listing_id)
    broadcast_listing_update(
        listing_id, event="bid_placed", current_price=listing.current_price, end_time=listing.end_time
    )
    return BidPlacedResponse(
        bid_id=bid.bid_id,
        listing_id=listing_id,
        amount=bid.amount,
        current_price=listing.current_price,
        end_time=listing.end_time,
        message="Bid accepted",
    )


@router.get("/api/listings/{listing_id}/bids")
def bid_history(listing_id: int, page: int = Query(1, ge=1), db: Session = Depends(get_db)):
    if db.get(Listing, listing_id) is None:
        raise NotFoundError("Listing not found")
    query = db.query(Bid).filter_by(listing_id=listing_id).order_by(Bid.placed_at.desc())
    total = query.count()
    bids = query.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE).all()
    return {
        "listing_id": listing_id,
        "bids": [{"bid_id": b.bid_id, "bidder": b.bidder_id, "amount": b.amount, "placed_at": b.placed_at} for b in bids],
        "page": page,
        "total": total,
    }


@router.get("/api/bids/me")
def my_bids(page: int = Query(1, ge=1), db: Session = Depends(get_db), bidder: User = Depends(require_roles("BIDDER"))):
    query = (
        db.query(Bid, Listing.title)
        .join(Listing, Listing.listing_id == Bid.listing_id)
        .filter(Bid.bidder_id == bidder.user_id)
        .order_by(Bid.placed_at.desc())
    )
    total = query.count()
    rows = query.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE).all()
    return {
        "bids": [
            {
                "bid_id": bid.bid_id,
                "listing_id": bid.listing_id,
                "title": title,
                "amount": bid.amount,
                "status": bid.status,
                "placed_at": bid.placed_at,
            }
            for bid, title in rows
        ],
        "page": page,
        "total": total,
    }
