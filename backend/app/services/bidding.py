from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.exceptions import AuctionNotActiveError, BidTooLowError, NotFoundError, SelfBidError
from app.models.bid import Bid
from app.models.listing import Listing
from app.models.user import User
from app.services.audit import log_action
from app.services.notify import notify

DUPLICATE_SUBMIT_WINDOW = timedelta(seconds=5)


def place_bid(db: Session, *, listing_id: int, bidder: User, amount: Decimal) -> Bid:
    """Validates and records one bid. Must run inside a single DB transaction — the row lock
    below plus the current_price update happen together, so two simultaneous bids on the same
    listing are serialized rather than racing (US-B03/US-SYS01 — the one correctness-critical
    path in this system)."""

    listing = db.execute(
        select(Listing).where(Listing.listing_id == listing_id).with_for_update()
    ).scalar_one_or_none()
    if listing is None:
        raise NotFoundError("Listing not found")
    if listing.seller_id == bidder.user_id:
        raise SelfBidError("You cannot bid on your own listing")

    now = datetime.now(timezone.utc)
    if listing.status != "Active" or now >= listing.end_time:
        raise AuctionNotActiveError("This auction is not open for bidding")

    # Idempotent replay: the exact same (bidder, listing, amount) within a few seconds is
    # treated as a retried request (double-click / network retry), not a new bid.
    duplicate = db.execute(
        select(Bid)
        .where(
            Bid.listing_id == listing_id,
            Bid.bidder_id == bidder.user_id,
            Bid.amount == amount,
            Bid.placed_at >= now - DUPLICATE_SUBMIT_WINDOW,
        )
        .order_by(Bid.placed_at.desc())
    ).scalars().first()
    if duplicate is not None:
        return duplicate

    bid_count = db.execute(select(func.count()).select_from(Bid).where(Bid.listing_id == listing_id)).scalar_one()
    min_required = listing.current_price if bid_count == 0 else listing.current_price + listing.min_bid_increment
    if amount < min_required:
        raise BidTooLowError(f"Bid must be at least {min_required}")

    previous_highest = db.execute(
        select(Bid).where(Bid.listing_id == listing_id).order_by(Bid.amount.desc(), Bid.placed_at.desc())
    ).scalars().first()

    bid = Bid(listing_id=listing_id, bidder_id=bidder.user_id, amount=amount, status="Accepted")
    db.add(bid)
    listing.current_price = amount

    extended = _maybe_extend_for_anti_sniping(db, listing, now)

    db.flush()

    log_action(
        db,
        user_id=bidder.user_id,
        action="BID_PLACED",
        entity_type="Bid",
        entity_id=bid.bid_id,
        new_value={"listing_id": listing_id, "amount": str(amount)},
    )
    notify(
        db,
        user_id=bidder.user_id,
        type_="BID_CONFIRMED",
        title="Bid placed",
        message=f"Your bid of {amount} on '{listing.title}' was accepted.",
    )
    if previous_highest is not None and previous_highest.bidder_id != bidder.user_id:
        notify(
            db,
            user_id=previous_highest.bidder_id,
            type_="OUTBID",
            title="You've been outbid",
            message=f"Someone placed a higher bid on '{listing.title}'. The new price is {amount}.",
        )
    if extended:
        notify(
            db,
            user_id=listing.seller_id,
            type_="AUCTION_EXTENDED",
            title="Auction extended",
            message=f"A late bid on '{listing.title}' extended the closing time to {listing.end_time.isoformat()}.",
        )

    return bid


def _maybe_extend_for_anti_sniping(db: Session, listing: Listing, now: datetime) -> bool:
    """Anti-sniping (US-B05/US-SYS02). Runs inside place_bid's row lock, so there is no
    concurrent-extension race to guard against here — each qualifying bid is serialized and
    always extends forward from whatever end_time the previous one left (never shortens it)."""
    window = timedelta(minutes=listing.anti_sniping_window_minutes)
    if now < listing.end_time - window:
        return False

    limit = listing.max_anti_sniping_extensions
    if limit is not None and listing.anti_sniping_extensions >= limit:
        return False

    listing.end_time = listing.end_time + timedelta(minutes=listing.anti_sniping_extension_minutes)
    listing.anti_sniping_extensions += 1
    return True
