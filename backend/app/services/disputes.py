from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import ConflictError, ForbiddenError, NotFoundError
from app.models.auction_result import AuctionResult
from app.models.dispute import Dispute
from app.models.listing import Listing
from app.models.payment import Payment
from app.models.user import User
from app.services.audit import log_action
from app.services.notify import notify
from app.services.payments import refund_payment, release_payment

OPEN_STATUSES = {"Open", "Under Review"}


def raise_dispute(db: Session, *, auction_result_id: int, raiser: User, dispute_type: str, reason: str,
                   description: str | None) -> Dispute:
    result = db.get(AuctionResult, auction_result_id)
    if result is None:
        raise NotFoundError("Auction result not found")
    listing = db.get(Listing, result.listing_id)

    if raiser.user_id not in (result.winner_id, listing.seller_id):
        raise ForbiddenError("Only the buyer or seller of this transaction can raise a dispute")

    dispute = Dispute(
        auction_result_id=auction_result_id,
        raised_by=raiser.user_id,
        dispute_type=dispute_type,
        reason=reason,
        description=description,
        status="Open",
    )
    db.add(dispute)
    db.flush()
    log_action(
        db,
        user_id=raiser.user_id,
        action="DISPUTE_RAISED",
        entity_type="Dispute",
        entity_id=dispute.dispute_id,
        new_value={"dispute_type": dispute_type, "reason": reason},
    )
    counterparty_id = listing.seller_id if raiser.user_id == result.winner_id else result.winner_id
    if counterparty_id is not None:
        notify(
            db,
            user_id=counterparty_id,
            type_="DISPUTE_RAISED",
            title="A dispute has been raised",
            message=f"A dispute was raised regarding '{listing.title}'.",
        )
    return dispute


def resolve_dispute(
    db: Session,
    *,
    dispute_id: int,
    moderator: User,
    status: str,
    resolution: str,
    release_funds: bool,
    refund_funds: bool,
) -> Dispute:
    if release_funds and refund_funds:
        raise ConflictError("Cannot both release and refund the same funds")

    dispute = db.execute(
        select(Dispute).where(Dispute.dispute_id == dispute_id).with_for_update()
    ).scalar_one_or_none()
    if dispute is None:
        raise NotFoundError("Dispute not found")
    if dispute.status == "Resolved":
        raise ConflictError("This dispute has already been resolved")
    if status not in ("Under Review", "Resolved"):
        raise ConflictError(f"Unknown dispute status: {status}")

    dispute.assigned_moderator_id = moderator.user_id
    dispute.status = status
    dispute.resolution = resolution

    if status == "Resolved":
        dispute.resolved_at = datetime.now(timezone.utc)
        if release_funds or refund_funds:
            payment = db.query(Payment).filter_by(auction_result_id=dispute.auction_result_id).first()
            if payment is None:
                raise ConflictError("No payment exists yet for this transaction")
            if release_funds:
                release_payment(db, payment, released_by_id=moderator.user_id)
            else:
                refund_payment(db, payment=payment, refunded_by_id=moderator.user_id)

    log_action(
        db,
        user_id=moderator.user_id,
        action=f"DISPUTE_{status.upper().replace(' ', '_')}",
        entity_type="Dispute",
        entity_id=dispute.dispute_id,
        new_value={"status": status, "resolution": resolution},
        description=resolution,
    )

    result = db.get(AuctionResult, dispute.auction_result_id)
    listing = db.get(Listing, result.listing_id)
    for party_id in {dispute.raised_by, result.winner_id, listing.seller_id} - {None}:
        notify(
            db,
            user_id=party_id,
            type_="DISPUTE_UPDATED",
            title=f"Dispute {status.lower()}",
            message=f"The dispute regarding '{listing.title}' is now {status.lower()}.",
        )

    return dispute
