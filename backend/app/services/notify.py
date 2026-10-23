from sqlalchemy.orm import Session

from app.models.notification import Notification


def notify(db: Session, *, user_id: int, type_: str, title: str, message: str) -> Notification:
    """Stages an in-app notification on the given session without committing — same pattern
    as log_action, so the triggering action and its notification commit together.

    Introduced here (Phase 2) as shared infra: every later phase (bidding, anti-sniping,
    closing, payments, disputes) calls this directly instead of waiting for a dedicated
    "notifications phase". Phase 7 only adds the read/list API and the read/unread flags.
    """
    entry = Notification(user_id=user_id, type=type_, title=title, message=message)
    db.add(entry)
    return entry
