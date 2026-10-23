from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.core.deps import get_db, require_roles
from app.core.exceptions import NotFoundError
from app.models.audit_log import AuditLog
from app.models.auction_result import AuctionResult
from app.models.bid import Bid
from app.models.dispute import Dispute
from app.models.listing import Listing
from app.models.payment import Payment
from app.models.platform_config import PlatformConfig
from app.models.user import Role, User
from app.schemas.admin import PlatformConfigUpdate, UserRolesUpdate, UserStatusUpdate
from app.services.audit import log_action

router = APIRouter(prefix="/api/admin", tags=["admin"])
PAGE_SIZE = 20


def _paginate(query, page: int):
    total = query.count()
    items = query.offset((page - 1) * PAGE_SIZE).limit(PAGE_SIZE).all()
    return items, total


# ---------------------------------------------------------------- users (US-A01) ----------

@router.get("/users")
def list_users(
    search: str | None = Query(None),
    role: str | None = Query(None),
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("ADMIN")),
):
    query = db.query(User)
    if search:
        like = f"%{search}%"
        query = query.filter(or_(User.first_name.ilike(like), User.last_name.ilike(like), User.email.ilike(like)))
    if status:
        query = query.filter(User.status == status)
    if role:
        query = query.join(User.roles).filter(Role.role_name == role)

    users, total = _paginate(query, page)
    return {
        "users": [
            {
                "user_id": u.user_id,
                "name": f"{u.first_name} {u.last_name}",
                "email": u.email,
                "roles": [r.role_name for r in u.roles],
                "status": u.status,
            }
            for u in users
        ],
        "page": page,
        "total": total,
    }


@router.get("/users/{user_id}")
def get_user(user_id: int, db: Session = Depends(get_db), _: User = Depends(require_roles("ADMIN"))):
    user = db.get(User, user_id)
    if user is None:
        raise NotFoundError("User not found")
    return {
        "user_id": user.user_id,
        "name": f"{user.first_name} {user.last_name}",
        "email": user.email,
        "roles": [r.role_name for r in user.roles],
        "status": user.status,
        "created_at": user.created_at,
    }


@router.patch("/users/{user_id}")
def update_user_status(
    user_id: int,
    payload: UserStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_roles("ADMIN")),
):
    user = db.get(User, user_id)
    if user is None:
        raise NotFoundError("User not found")

    old = {"status": user.status, "is_verified": user.is_verified}
    if payload.status is not None:
        user.status = payload.status
    if payload.is_verified is not None:
        user.is_verified = payload.is_verified

    log_action(
        db,
        user_id=admin.user_id,
        action="USER_STATUS_UPDATED",
        entity_type="User",
        entity_id=user_id,
        old_value=old,
        new_value={"status": user.status, "is_verified": user.is_verified},
    )
    db.commit()
    return {"user_id": user_id, "status": user.status, "message": "User updated"}


@router.patch("/users/{user_id}/roles")
def update_user_roles(
    user_id: int,
    payload: UserRolesUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_roles("ADMIN")),
):
    user = db.get(User, user_id)
    if user is None:
        raise NotFoundError("User not found")

    old_roles = [r.role_name for r in user.roles]
    user.roles = db.query(Role).filter(Role.role_name.in_(payload.roles)).all()

    log_action(
        db,
        user_id=admin.user_id,
        action="USER_ROLES_UPDATED",
        entity_type="User",
        entity_id=user_id,
        old_value={"roles": old_roles},
        new_value={"roles": payload.roles},
    )
    db.commit()
    return {"user_id": user_id, "roles": payload.roles, "message": "Roles updated"}


# ---------------------------------------------------------- platform rules (US-A02) --------
# Not in the spec's §4.3 endpoint list (the ERD has no config entity either — see plan.md gap
# note) but required by US-A02; added as the obvious admin-config counterpart to categories.

@router.get("/config")
def get_config(db: Session = Depends(get_db), _: User = Depends(require_roles("ADMIN"))):
    config = db.get(PlatformConfig, 1)
    if config is None:
        raise NotFoundError("Platform configuration has not been seeded yet")
    return {
        "min_bid_increment": config.min_bid_increment,
        "anti_sniping_window_minutes": config.anti_sniping_window_minutes,
        "anti_sniping_extension_minutes": config.anti_sniping_extension_minutes,
        "max_anti_sniping_extensions": config.max_anti_sniping_extensions,
        "platform_fee_percent": config.platform_fee_percent,
        "updated_at": config.updated_at,
    }


@router.patch("/config")
def update_config(
    payload: PlatformConfigUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_roles("ADMIN")),
):
    config = db.get(PlatformConfig, 1)
    if config is None:
        raise NotFoundError("Platform configuration has not been seeded yet")
    updates = payload.model_dump(exclude_unset=True)
    old = {
        "min_bid_increment": config.min_bid_increment,
        "anti_sniping_window_minutes": config.anti_sniping_window_minutes,
        "anti_sniping_extension_minutes": config.anti_sniping_extension_minutes,
        "max_anti_sniping_extensions": config.max_anti_sniping_extensions,
        "platform_fee_percent": config.platform_fee_percent,
    }
    for field, value in updates.items():
        setattr(config, field, value)
    config.updated_by = admin.user_id

    # Deliberately NOT touching existing Listing rows: rules are snapshotted per-listing at
    # creation time (plan.md Phase 10 decision), so this change only affects auctions created
    # from now on.
    log_action(
        db, user_id=admin.user_id, action="PLATFORM_CONFIG_UPDATED", entity_type="PlatformConfig", entity_id=1,
        old_value=old, new_value=updates,
    )
    db.commit()
    return {"message": "Platform configuration updated"}


# ---------------------------------------------------------- oversight (US-A04) -------------

@router.get("/listings")
def admin_listings(
    status: str | None = Query(None),
    seller_id: int | None = Query(None),
    page: int = Query(1, ge=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("ADMIN")),
):
    query = db.query(Listing)
    if status:
        query = query.filter(Listing.status == status)
    if seller_id:
        query = query.filter(Listing.seller_id == seller_id)
    items, total = _paginate(query.order_by(Listing.created_at.desc()), page)
    return {
        "listings": [
            {"listing_id": l.listing_id, "title": l.title, "status": l.status, "moderation_status": l.moderation_status}
            for l in items
        ],
        "page": page,
        "total": total,
    }


@router.get("/bids")
def admin_bids(
    listing_id: int | None = Query(None),
    bidder_id: int | None = Query(None),
    page: int = Query(1, ge=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("ADMIN")),
):
    query = db.query(Bid)
    if listing_id:
        query = query.filter(Bid.listing_id == listing_id)
    if bidder_id:
        query = query.filter(Bid.bidder_id == bidder_id)
    items, total = _paginate(query.order_by(Bid.placed_at.desc()), page)
    return {
        "bids": [{"bid_id": b.bid_id, "listing_id": b.listing_id, "bidder_id": b.bidder_id, "amount": b.amount} for b in items],
        "page": page,
        "total": total,
    }


@router.get("/auction-results")
def admin_results(
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("ADMIN")),
):
    query = db.query(AuctionResult)
    if status:
        query = query.filter(AuctionResult.result_status == status)
    items, total = _paginate(query.order_by(AuctionResult.closed_at.desc()), page)
    return {
        "results": [
            {"result_id": r.result_id, "listing_id": r.listing_id, "result_status": r.result_status, "final_price": r.final_price}
            for r in items
        ],
        "page": page,
        "total": total,
    }


@router.get("/payments")
def admin_payments(
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("ADMIN")),
):
    query = db.query(Payment)
    if status:
        query = query.filter(Payment.payment_status == status)
    items, total = _paginate(query.order_by(Payment.created_at.desc()), page)
    return {
        "payments": [
            {"payment_id": p.payment_id, "amount": p.amount, "payment_status": p.payment_status, "escrow_status": p.escrow_status}
            for p in items
        ],
        "page": page,
        "total": total,
    }


@router.get("/disputes")
def admin_disputes(
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("ADMIN")),
):
    query = db.query(Dispute)
    if status:
        query = query.filter(Dispute.status == status)
    items, total = _paginate(query.order_by(Dispute.created_at.desc()), page)
    return {
        "disputes": [{"dispute_id": d.dispute_id, "status": d.status, "dispute_type": d.dispute_type} for d in items],
        "page": page,
        "total": total,
    }


# ---------------------------------------------------------- audit logs (US-A05) ------------

@router.get("/audit-logs")
def admin_audit_logs(
    action: str | None = Query(None),
    entity_type: str | None = Query(None),
    entity_id: int | None = Query(None),
    page: int = Query(1, ge=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles("ADMIN")),
):
    query = db.query(AuditLog)
    if action:
        query = query.filter(AuditLog.action == action)
    if entity_type:
        query = query.filter(AuditLog.entity_type == entity_type)
    if entity_id is not None:
        query = query.filter(AuditLog.entity_id == entity_id)
    items, total = _paginate(query.order_by(AuditLog.created_at.desc()), page)
    return {
        "logs": [
            {
                "log_id": log.log_id,
                "user_id": log.user_id,
                "action": log.action,
                "entity_type": log.entity_type,
                "entity_id": log.entity_id,
                "created_at": log.created_at,
            }
            for log in items
        ],
        "page": page,
        "total": total,
    }


@router.get("/audit-logs/{log_id}")
def admin_audit_log_detail(log_id: int, db: Session = Depends(get_db), _: User = Depends(require_roles("ADMIN"))):
    log = db.get(AuditLog, log_id)
    if log is None:
        raise NotFoundError("Audit log entry not found")
    return {
        "log_id": log.log_id,
        "user_id": log.user_id,
        "action": log.action,
        "entity_type": log.entity_type,
        "entity_id": log.entity_id,
        "old_value": log.old_value,
        "new_value": log.new_value,
        "description": log.description,
        "created_at": log.created_at,
    }


# ---------------------------------------------------------- dashboard (US-A04/A05) ---------

@router.get("/dashboard")
def admin_dashboard(db: Session = Depends(get_db), _: User = Depends(require_roles("ADMIN"))):
    return {
        "total_users": db.query(User).count(),
        "active_auctions": db.query(Listing).filter_by(status="Active").count(),
        "total_bids": db.query(Bid).count(),
        "completed_auctions": db.query(Listing).filter_by(status="Closed").count(),
        "open_disputes": db.query(Dispute).filter(Dispute.status.in_(["Open", "Under Review"])).count(),
    }
