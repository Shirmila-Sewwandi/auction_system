from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_db, require_roles
from app.models.auction_result import AuctionResult
from app.models.listing import Listing
from app.models.payment import Payment
from app.models.user import User

router = APIRouter(prefix="/api/seller", tags=["seller"])


@router.get("/listings")
def my_listings(db: Session = Depends(get_db), seller: User = Depends(require_roles("SELLER"))):
    listings = db.query(Listing).filter_by(seller_id=seller.user_id).order_by(Listing.created_at.desc()).all()
    return {
        "listings": [
            {
                "listing_id": listing.listing_id,
                "title": listing.title,
                "current_price": listing.current_price,
                "status": listing.status,
                "end_time": listing.end_time,
            }
            for listing in listings
        ]
    }


@router.get("/sales")
def my_sales(db: Session = Depends(get_db), seller: User = Depends(require_roles("SELLER"))):
    rows = (
        db.query(AuctionResult, Listing, Payment)
        .join(Listing, Listing.listing_id == AuctionResult.listing_id)
        .outerjoin(Payment, Payment.auction_result_id == AuctionResult.result_id)
        .filter(Listing.seller_id == seller.user_id, AuctionResult.result_status == "Sold")
        .order_by(AuctionResult.closed_at.desc())
        .all()
    )
    return {
        "sales": [
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
def seller_dashboard(db: Session = Depends(get_db), seller: User = Depends(require_roles("SELLER"))):
    active_listings = db.query(Listing).filter_by(seller_id=seller.user_id, status="Active").count()
    completed_sales = (
        db.query(AuctionResult)
        .join(Listing, Listing.listing_id == AuctionResult.listing_id)
        .filter(Listing.seller_id == seller.user_id, AuctionResult.result_status == "Sold")
        .count()
    )
    pending_payments = (
        db.query(AuctionResult)
        .join(Listing, Listing.listing_id == AuctionResult.listing_id)
        .outerjoin(Payment, Payment.auction_result_id == AuctionResult.result_id)
        .filter(Listing.seller_id == seller.user_id, AuctionResult.result_status == "Sold", Payment.payment_id.is_(None))
        .count()
    )
    return {
        "active_listings": active_listings,
        "completed_sales": completed_sales,
        "pending_payments": pending_payments,
    }
