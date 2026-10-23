from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.core.exceptions import ConflictError, ForbiddenError, NotFoundError
from app.models.auction_result import AuctionResult
from app.models.dispute import Dispute
from app.models.listing import Listing
from app.models.payment import Payment
from app.models.user import User
from app.services.audit import log_action
from app.services.notify import notify

BLOCKING_DISPUTE_STATUSES = {"Open", "Under Review"}


def create_payment(db: Session, *, auction_result_id: int, payer: User) -> Payment:
    result = db.get(AuctionResult, auction_result_id)
    if result is None:
        raise NotFoundError("Auction result not found")
    if result.result_status != "Sold" or result.winner_id is None:
        raise ConflictError("This auction has no winner to pay for")
    if result.winner_id != payer.user_id:
        raise ForbiddenError("Only the winning bidder can pay for this auction")

    existing = db.query(Payment).filter_by(auction_result_id=auction_result_id).first()
    if existing is not None:
        raise ConflictError("This auction has already been paid for")

    listing = db.get(Listing, result.listing_id)
    seller_id = listing.seller_id

    now = datetime.now(timezone.utc)
    payment = Payment(
        auction_result_id=auction_result_id,
        payer_id=payer.user_id,
        payee_id=seller_id,
        amount=result.final_price,
        payment_status="Paid",
        escrow_status="Held",
        paid_at=now,
    )
    db.add(payment)
    db.flush()
    log_action(
        db,
        user_id=payer.user_id,
        action="PAYMENT_MADE",
        entity_type="Payment",
        entity_id=payment.payment_id,
        new_value={"amount": str(payment.amount)},
    )
    notify(
        db,
        user_id=seller_id,
        type_="PAYMENT_RECEIVED",
        title="Payment received",
        message=f"Payment of {payment.amount} has been placed in escrow for your sale.",
    )
    return payment


def confirm_receipt(db: Session, *, payment_id: int, payer: User, received: bool) -> Payment:
    payment = db.get(Payment, payment_id)
    if payment is None:
        raise NotFoundError("Payment not found")
    if payment.payer_id != payer.user_id:
        raise ForbiddenError("Only the paying bidder can confirm receipt")
    if payment.payment_status != "Paid":
        raise ConflictError("This payment is not eligible for release")
    if payment.escrow_status != "Held":
        raise ConflictError(f"Escrow funds are already {payment.escrow_status.lower()}")

    if not received:
        return payment  # no state change — buyer should file a dispute instead

    blocking = (
        db.query(Dispute)
        .filter(
            Dispute.auction_result_id == payment.auction_result_id,
            Dispute.status.in_(BLOCKING_DISPUTE_STATUSES),
        )
        .first()
    )
    if blocking is not None:
        raise ConflictError("Funds cannot be released while a dispute is open")

    release_payment(db, payment, released_by_id=payer.user_id)
    return payment


def refund_payment(db: Session, *, payment: Payment, refunded_by_id: int) -> Payment:
    """Full refund only — the Payment entity has a single `amount` + escrow_status state
    machine (Held/Released/Refunded), not a refunded-amount ledger, so partial refunds aren't
    structurally supported without adding a column outside the Part A ERD.
    # ponytail: full-refund only; add a `refunded_amount` column if partial refunds are needed.
    """
    if payment.payment_status != "Paid":
        raise ConflictError("This payment is not eligible for refund")
    if payment.escrow_status != "Held":
        raise ConflictError(f"Escrow funds are already {payment.escrow_status.lower()} — cannot refund")

    payment.escrow_status = "Refunded"
    payment.refunded_at = datetime.now(timezone.utc)
    log_action(
        db,
        user_id=refunded_by_id,
        action="ESCROW_REFUNDED",
        entity_type="Payment",
        entity_id=payment.payment_id,
    )
    notify(
        db,
        user_id=payment.payer_id,
        type_="ESCROW_REFUNDED",
        title="Payment refunded",
        message=f"Your payment of {payment.amount} has been refunded.",
    )
    return payment


def release_payment(db: Session, payment: Payment, *, released_by_id: int) -> None:
    """Shared by the buyer's self-service confirm_receipt (blocking-dispute guard lives there)
    and moderator dispute resolution (explicitly authorized to release despite the dispute it's
    resolving)."""
    if payment.payment_status != "Paid":
        raise ConflictError("This payment is not eligible for release")
    if payment.escrow_status != "Held":
        raise ConflictError(f"Escrow funds are already {payment.escrow_status.lower()}")

    payment.escrow_status = "Released"
    payment.released_at = datetime.now(timezone.utc)
    log_action(
        db,
        user_id=released_by_id,
        action="ESCROW_RELEASED",
        entity_type="Payment",
        entity_id=payment.payment_id,
    )
    notify(
        db,
        user_id=payment.payee_id,
        type_="ESCROW_RELEASED",
        title="Funds released",
        message=f"The escrowed payment of {payment.amount} has been released to you.",
    )
