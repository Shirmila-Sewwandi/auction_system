from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.auction_result import AuctionResult
from app.models.bid import Bid
from app.models.listing import Listing
from app.services.audit import log_action
from app.services.notify import notify


def activate_due_listing(db: Session, listing_id: int) -> bool:
    """Flips an approved-but-not-yet-started listing to Active once its start_time arrives.
    Idempotent: a listing already Active/Closed/Cancelled is simply skipped."""
    listing = db.execute(
        select(Listing).where(Listing.listing_id == listing_id).with_for_update()
    ).scalar_one_or_none()
    if listing is None or listing.status != "Pending" or listing.moderation_status != "Approved":
        return False
    if listing.start_time > datetime.now(timezone.utc):
        return False
    listing.status = "Active"
    return True


def close_expired_auction(db: Session, listing_id: int) -> AuctionResult | None:
    """Closes one listing past its end_time: determines the winner (if any), checks the
    reserve, and writes exactly one AuctionResult. Must run with a row lock inside its own
    transaction — this is US-SYS03's idempotency requirement: re-running this on a listing
    that's already Closed is a safe no-op (status guard below), and `AuctionResult.listing_id`
    is additionally unique at the DB level as a second line of defense.
    """
    listing = db.execute(
        select(Listing).where(Listing.listing_id == listing_id).with_for_update()
    ).scalar_one_or_none()
    if listing is None or listing.status != "Active":
        return None

    now = datetime.now(timezone.utc)
    if now < listing.end_time:
        # An anti-sniping extension landed after this job was queued — don't close early.
        return None

    highest_bid = db.execute(
        select(Bid)
        .where(Bid.listing_id == listing_id, Bid.status == "Accepted")
        .order_by(Bid.amount.desc(), Bid.placed_at.asc())
    ).scalars().first()

    if highest_bid is None:
        result_status, winner_id, winning_bid_id, final_price, reserve_met = "No Bids", None, None, None, False
    else:
        reserve_met = listing.reserve_price is None or highest_bid.amount >= listing.reserve_price
        if reserve_met:
            result_status = "Sold"
            winner_id, winning_bid_id, final_price = highest_bid.bidder_id, highest_bid.bid_id, highest_bid.amount
        else:
            result_status, winner_id, winning_bid_id, final_price = "Reserve Not Met", None, None, None

    result = AuctionResult(
        listing_id=listing_id,
        winner_id=winner_id,
        winning_bid_id=winning_bid_id,
        final_price=final_price,
        reserve_met=reserve_met,
        result_status=result_status,
    )
    db.add(result)
    listing.status = "Closed"
    db.flush()

    log_action(
        db,
        user_id=None,
        action="AUCTION_CLOSED",
        entity_type="Listing",
        entity_id=listing_id,
        new_value={"result_status": result_status, "final_price": str(final_price) if final_price else None},
        description="Closed automatically by the background auction-closer job",
    )
    _notify_outcome(db, listing, result, highest_bid)

    return result


def _notify_outcome(db: Session, listing: Listing, result: AuctionResult, highest_bid: Bid | None) -> None:
    if result.result_status == "Sold":
        notify(
            db,
            user_id=result.winner_id,
            type_="AUCTION_WON",
            title="You won!",
            message=f"You won '{listing.title}' for {result.final_price}. Payment instructions to follow.",
        )
        notify(
            db,
            user_id=listing.seller_id,
            type_="AUCTION_SOLD",
            title="Your item sold",
            message=f"'{listing.title}' sold for {result.final_price}.",
        )
    elif result.result_status == "Reserve Not Met":
        notify(
            db,
            user_id=listing.seller_id,
            type_="AUCTION_RESERVE_NOT_MET",
            title="Reserve not met",
            message=f"'{listing.title}' closed without meeting the reserve price.",
        )
    else:
        notify(
            db,
            user_id=listing.seller_id,
            type_="AUCTION_NO_BIDS",
            title="No bids received",
            message=f"'{listing.title}' closed with no bids.",
        )

    losing_bidder_ids = db.execute(
        select(Bid.bidder_id)
        .where(Bid.listing_id == listing.listing_id, Bid.status == "Accepted")
        .distinct()
    ).scalars().all()
    for bidder_id in losing_bidder_ids:
        if bidder_id == result.winner_id:
            continue
        notify(
            db,
            user_id=bidder_id,
            type_="AUCTION_LOST",
            title="Auction ended",
            message=f"'{listing.title}' has closed. You did not win this item.",
        )
