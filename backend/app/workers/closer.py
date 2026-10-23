import asyncio
import logging
from datetime import datetime, timezone

from sqlalchemy import select

from app.db.session import SessionLocal
from app.models.listing import Listing
from app.services.cache import invalidate_listing
from app.services.closing import activate_due_listing, close_expired_auction
from app.services.realtime import broadcast_listing_update

logger = logging.getLogger("auction.closer")

# ponytail: fixed polling interval, not a priority queue of next-close times — fine at this
# scale (poll cost is one indexed query per tick); switch to scheduling exact wakeups per
# listing if auction volume ever makes 1 query / POLL_INTERVAL_SECONDS too chatty.
POLL_INTERVAL_SECONDS = 5


def _due_listing_ids() -> tuple[list[int], list[int]]:
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        pending_due = db.execute(
            select(Listing.listing_id).where(
                Listing.status == "Pending",
                Listing.moderation_status == "Approved",
                Listing.start_time <= now,
            )
        ).scalars().all()
        active_due = db.execute(
            select(Listing.listing_id).where(Listing.status == "Active", Listing.end_time <= now)
        ).scalars().all()
        return list(pending_due), list(active_due)
    finally:
        db.close()


def _activate_one(listing_id: int) -> None:
    db = SessionLocal()
    try:
        if activate_due_listing(db, listing_id):
            db.commit()
            invalidate_listing(listing_id)
    except Exception:
        db.rollback()
        logger.exception("Failed to activate listing %s", listing_id)
    finally:
        db.close()


def _close_one(listing_id: int) -> None:
    db = SessionLocal()
    try:
        result = close_expired_auction(db, listing_id)
        if result is not None:
            db.commit()
            invalidate_listing(listing_id)
            broadcast_listing_update(
                listing_id,
                event="auction_closed",
                current_price=result.final_price,
                end_time=None,
            )
    except Exception:
        db.rollback()
        logger.exception("Failed to close listing %s", listing_id)
    finally:
        db.close()


def run_due_listings_once() -> None:
    """One isolated transaction per listing — a failure on one listing never blocks the rest
    of the batch, and re-running this is always safe (both operations are idempotent)."""
    pending_ids, active_ids = _due_listing_ids()
    for listing_id in pending_ids:
        _activate_one(listing_id)
    for listing_id in active_ids:
        _close_one(listing_id)


async def run_closer_loop() -> None:
    while True:
        await asyncio.to_thread(run_due_listings_once)
        await asyncio.sleep(POLL_INTERVAL_SECONDS)
