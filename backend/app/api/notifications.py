from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_db
from app.core.exceptions import ForbiddenError, NotFoundError
from app.models.notification import Notification
from app.models.user import User

router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.get("")
def list_notifications(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    notifications = (
        db.query(Notification).filter_by(user_id=user.user_id).order_by(Notification.created_at.desc()).all()
    )
    return {
        "notifications": [
            {
                "notification_id": n.notification_id,
                "type": n.type,
                "title": n.title,
                "message": n.message,
                "is_read": n.is_read,
                "created_at": n.created_at,
            }
            for n in notifications
        ]
    }


@router.patch("/{notification_id}/read")
def mark_read(notification_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    notification = db.get(Notification, notification_id)
    if notification is None:
        raise NotFoundError("Notification not found")
    if notification.user_id != user.user_id:
        raise ForbiddenError("This notification does not belong to you")
    if not notification.is_read:
        notification.is_read = True
        notification.read_at = datetime.now(timezone.utc)
        db.commit()
    return {"notification_id": notification_id, "is_read": notification.is_read}


@router.patch("/read-all")
def mark_all_read(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    now = datetime.now(timezone.utc)
    db.query(Notification).filter_by(user_id=user.user_id, is_read=False).update(
        {"is_read": True, "read_at": now}
    )
    db.commit()
    return {"message": "All notifications marked as read"}
