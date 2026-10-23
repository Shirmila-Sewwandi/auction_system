from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, model_validator

from app.schemas.common import Money


class ListingCreate(BaseModel):
    category_id: int
    title: str
    description: str
    condition: str | None = None
    provenance: str | None = None
    starting_price: Money
    reserve_price: Money | None = None
    start_time: datetime
    end_time: datetime

    @model_validator(mode="after")
    def check_consistency(self):
        if self.reserve_price is not None and self.reserve_price < self.starting_price:
            raise ValueError("reserve_price cannot be lower than starting_price")
        if self.start_time >= self.end_time:
            raise ValueError("start_time must be before end_time")
        return self


class ListingUpdate(ListingCreate):
    """Full replace (PUT) — same shape and validation as create."""


class ListingPatch(BaseModel):
    """Partial edit (PATCH). Only a safe subset of these may apply once bidding has
    started — enforced in the route, not here (depends on DB state, not just payload shape)."""

    title: str | None = None
    description: str | None = None
    condition: str | None = None
    provenance: str | None = None
    category_id: int | None = None
    starting_price: Money | None = None
    reserve_price: Money | None = None
    start_time: datetime | None = None
    end_time: datetime | None = None


class ImageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    image_id: int
    image_path: str
    display_order: int


class ListingSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    listing_id: int
    title: str
    current_price: Decimal
    end_time: datetime
    status: str
    thumbnail: str | None = None


class ListingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    listing_id: int
    seller_id: int
    category_id: int
    title: str
    description: str
    condition: str | None
    provenance: str | None
    starting_price: Decimal
    reserve_price: Decimal | None
    current_price: Decimal
    start_time: datetime
    end_time: datetime
    status: str
    moderation_status: str
    images: list[ImageOut]


class ListingPage(BaseModel):
    items: list[ListingSummary]
    page: int
    total: int
