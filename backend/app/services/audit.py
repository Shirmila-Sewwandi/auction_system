import json
from typing import Any

from sqlalchemy.orm import Session

from app.models.audit_log import AuditLog


def log_action(
    db: Session,
    *,
    user_id: int | None,
    action: str,
    entity_type: str,
    entity_id: int,
    old_value: dict[str, Any] | None = None,
    new_value: dict[str, Any] | None = None,
    description: str | None = None,
    ip_address: str | None = None,
) -> AuditLog:
    """Stages an immutable audit entry on the given session without committing.

    Callers add this to the SAME transaction as the action it records (e.g. a moderation
    decision, a payment release) so the action and its audit trail succeed or fail together
    (US-M04 edge case) — call db.commit() once, after this, at the end of the request.
    """
    entry = AuditLog(
        user_id=user_id,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        old_value=json.dumps(old_value, default=str) if old_value is not None else None,
        new_value=json.dumps(new_value, default=str) if new_value is not None else None,
        description=description,
        ip_address=ip_address,
    )
    db.add(entry)
    return entry
