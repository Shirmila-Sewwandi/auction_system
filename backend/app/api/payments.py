from fastapi import APIRouter, Depends
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_db, require_roles
from app.core.exceptions import ForbiddenError, NotFoundError
from app.models.auction_result import AuctionResult
from app.models.listing import Listing
from app.models.payment import Payment
from app.models.user import User
from app.schemas.payment import ConfirmReceiptRequest, PaymentCreate
from app.services.payments import confirm_receipt, create_payment

router = APIRouter(prefix="/api/payments", tags=["payments"])


def _is_staff(user: User) -> bool:
    return bool({r.role_name for r in user.roles} & {"MODERATOR", "ADMIN"})


@router.post("")
def pay(
    payload: PaymentCreate,
    db: Session = Depends(get_db),
    payer: User = Depends(require_roles("BIDDER")),
):
    payment = create_payment(db, auction_result_id=payload.auction_result_id, payer=payer)
    db.commit()
    db.refresh(payment)
    return {
        "payment_id": payment.payment_id,
        "amount": payment.amount,
        "payment_status": payment.payment_status,
        "escrow_status": payment.escrow_status,
        "message": "Payment held in escrow",
    }


def _get_visible_payment(db: Session, payment_id: int, user: User) -> Payment:
    payment = db.get(Payment, payment_id)
    if payment is None:
        raise NotFoundError("Payment not found")
    if user.user_id not in (payment.payer_id, payment.payee_id) and not _is_staff(user):
        raise ForbiddenError("You do not have access to this payment")
    return payment


@router.get("/me")
def my_payments(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    rows = (
        db.query(Payment, Listing.title)
        .join(AuctionResult, AuctionResult.result_id == Payment.auction_result_id)
        .join(Listing, Listing.listing_id == AuctionResult.listing_id)
        .filter(or_(Payment.payer_id == user.user_id, Payment.payee_id == user.user_id))
        .order_by(Payment.created_at.desc())
        .all()
    )
    return {
        "payments": [
            {
                "payment_id": payment.payment_id,
                "listing": title,
                "amount": payment.amount,
                "payment_status": payment.payment_status,
                "escrow_status": payment.escrow_status,
            }
            for payment, title in rows
        ]
    }


@router.get("/{payment_id}")
def get_payment(payment_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    payment = _get_visible_payment(db, payment_id, user)
    return {
        "payment_id": payment.payment_id,
        "auction_result_id": payment.auction_result_id,
        "amount": payment.amount,
        "payment_status": payment.payment_status,
        "escrow_status": payment.escrow_status,
        "paid_at": payment.paid_at,
    }


@router.get("/{payment_id}/receipt")
def get_receipt(payment_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    payment = _get_visible_payment(db, payment_id, user)
    result = db.get(AuctionResult, payment.auction_result_id)
    listing = db.get(Listing, result.listing_id)
    return {
        "payment_id": payment.payment_id,
        "listing": listing.title,
        "payer": payment.payer_id,
        "payee": payment.payee_id,
        "amount": payment.amount,
        "paid_at": payment.paid_at,
        "payment_status": payment.payment_status,
    }


@router.post("/{payment_id}/confirm-receipt")
def confirm(
    payment_id: int,
    payload: ConfirmReceiptRequest,
    db: Session = Depends(get_db),
    payer: User = Depends(get_current_user),
):
    payment = confirm_receipt(db, payment_id=payment_id, payer=payer, received=payload.received)
    db.commit()
    message = "Funds released to seller" if payload.received else "Please file a dispute if the item was not received"
    return {"payment_id": payment.payment_id, "escrow_status": payment.escrow_status, "message": message}
