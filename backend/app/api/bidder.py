from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.deps import get_db, require_roles
from app.models.auction_result import AuctionResult
from app.models.bid import Bid
from app.models.listing import Listing
from app.models.payment import Payment
from app.models.user import User

router = APIRouter(prefix="/api/bidder", tags=["bidder"])


@router.get("/auctions")
def my_auctions(db: Session = Depends(get_db), bidder: User = Depends(require_roles("BIDDER"))):
    rows = (
        db.query(Listing, func.max(Bid.amount))
        .join(Bid, Bid.listing_id == Listing.listing_id)
        .filter(Bid.bidder_id == bidder.user_id)
        .group_by(Listing.listing_id)
        .order_by(Listing.end_time.asc())
        .all()
    )
    return {
        "auctions": [
            {
                "listing_id": listing.listing_id,
                "title": listing.title,
                "my_highest_bid": my_highest,
                "current_price": listing.current_price,
                "status": listing.status,
            }
            for listing, my_highest in rows
        ]
    }


@router.get("/wins")
def my_wins(db: Session = Depends(get_db), bidder: User = Depends(require_roles("BIDDER"))):
    rows = (
        db.query(AuctionResult, Listing, Payment)
        .join(Listing, Listing.listing_id == AuctionResult.listing_id)
        .outerjoin(Payment, Payment.auction_result_id == AuctionResult.result_id)
        .filter(AuctionResult.winner_id == bidder.user_id)
        .order_by(AuctionResult.closed_at.desc())
        .all()
    )
    return {
        "wins": [
            {
                "listing_id": listing.listing_id,
                "title": listing.title,
                "final_price": result.final_price,
                "payment_status": payment.payment_status if payment else "Pending",
            }
            for result, listing, payment in rows
        ]
    }


@router.get("/dashboard")
def bidder_dashboard(db: Session = Depends(get_db), bidder: User = Depends(require_roles("BIDDER"))):
    active_bids = (
        db.query(Bid.listing_id)
        .join(Listing, Listing.listing_id == Bid.listing_id)
        .filter(Bid.bidder_id == bidder.user_id, Listing.status == "Active")
        .distinct()
        .count()
    )
    auctions_won = db.query(AuctionResult).filter_by(winner_id=bidder.user_id).count()
    pending_payments = (
        db.query(AuctionResult)
        .outerjoin(Payment, Payment.auction_result_id == AuctionResult.result_id)
        .filter(AuctionResult.winner_id == bidder.user_id, Payment.payment_id.is_(None))
        .count()
    )
    return {"active_bids": active_bids, "auctions_won": auctions_won, "pending_payments": pending_payments}
