from pydantic import BaseModel


class DisputeCreate(BaseModel):
    auction_result_id: int
    dispute_type: str
    reason: str
    description: str | None = None


class DisputePatch(BaseModel):
    reason: str | None = None
    description: str | None = None


class DisputeResolve(BaseModel):
    status: str  # "Resolved" (only valid terminal action here) or "Under Review"
    resolution: str
    release_funds: bool = False
    refund_funds: bool = False
