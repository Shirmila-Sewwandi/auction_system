from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import ConflictError, NotFoundError
from app.models.listing import Listing
from app.models.user import User
from app.services.audit import log_action
from app.services.notify import notify

ACTION_TO_STATUS = {
    "approve": "Approved",
    "reject": "Rejected",
    "suspend": "Suspended",
}

# A listing already in one of these states cannot be re-moderated by a stale/duplicate
# request (US-M01 edge case: "an already rejected/closed listing cannot be accidentally
# approved by stale requests").
TERMINAL_MODERATION_STATES = {"Rejected", "Suspended"}


def moderate_listing(db: Session, *, listing_id: int, moderator: User, action: str, reason: str | None) -> Listing:
    # Row lock: a concurrent moderator action on the same listing blocks until this commits.
    listing = db.execute(
        select(Listing).where(Listing.listing_id == listing_id).with_for_update()
    ).scalar_one_or_none()
    if listing is None:
        raise NotFoundError("Listing not found")
    if listing.status == "Closed" or listing.moderation_status in TERMINAL_MODERATION_STATES:
        raise ConflictError("This listing has already been moderated or closed")

    new_status = ACTION_TO_STATUS.get(action)
    if new_status is None:
        raise ConflictError(f"Unknown moderation action: {action}")
    if new_status in ("Rejected", "Suspended") and not reason:
        raise ConflictError("A reason is required to reject or suspend a listing")

    old_status = listing.moderation_status
    listing.moderation_status = new_status
    if new_status == "Approved":
        now = datetime.now(timezone.utc)
        listing.status = "Active" if listing.start_time <= now else "Pending"
    elif new_status in ("Rejected", "Suspended"):
        listing.status = "Cancelled"

    log_action(
        db,
        user_id=moderator.user_id,
        action=f"LISTING_{new_status.upper()}",
        entity_type="Listing",
        entity_id=listing_id,
        old_value={"moderation_status": old_status},
        new_value={"moderation_status": new_status, "reason": reason},
        description=reason,
    )
    notify(
        db,
        user_id=listing.seller_id,
        type_="LISTING_MODERATED",
        title=f"Listing {new_status.lower()}",
        message=f"Your listing '{listing.title}' was {new_status.lower()}."
        + (f" Reason: {reason}" if reason else ""),
    )
    return listing
