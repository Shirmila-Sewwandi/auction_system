from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, Integer, Numeric, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PlatformConfig(Base):
    """Single-row admin-configurable rules table (US-A02).

    Not part of the Part A 12-entity ERD — added because the spec requires admin-configurable
    bid rules/fees but the ERD has no config entity (see plan.md gap note). Listings snapshot
    these values at creation time (`Listing.min_bid_increment`), so changes here never affect
    auctions already in flight.
    """

    __tablename__ = "platform_config"

    config_id: Mapped[int] = mapped_column(Integer, primary_key=True, default=1)
    min_bid_increment: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=1.00)
    anti_sniping_window_minutes: Mapped[int] = mapped_column(Integer, default=5)
    anti_sniping_extension_minutes: Mapped[int] = mapped_column(Integer, default=10)
    max_anti_sniping_extensions: Mapped[int | None] = mapped_column(Integer, nullable=True)  # None = unlimited
    platform_fee_percent: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=0.00)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
