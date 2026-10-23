from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel

from app.schemas.common import Money


class BidCreate(BaseModel):
    amount: Money


class BidPlacedResponse(BaseModel):
    bid_id: int
    listing_id: int
    amount: Decimal
    current_price: Decimal
    end_time: datetime
    message: str


class BidHistoryEntry(BaseModel):
    bid_id: int
    bidder_id: int
    amount: Decimal
    placed_at: datetime


class MyBidEntry(BaseModel):
    bid_id: int
    listing_id: int
    title: str
    amount: Decimal
    status: str
    placed_at: datetime
