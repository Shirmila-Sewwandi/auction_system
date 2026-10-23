from pydantic import BaseModel


class ModerationAction(BaseModel):
    action: str  # "approve" | "reject" | "suspend"
    reason: str | None = None
