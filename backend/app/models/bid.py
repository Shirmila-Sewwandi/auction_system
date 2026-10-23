from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Bid(Base):
    __tablename__ = "bids"
    __table_args__ = (
        Index("ix_bids_listing_amount", "listing_id", "amount"),
        Index("ix_bids_listing_placed_at", "listing_id", "placed_at"),
        Index("ix_bids_bidder_id", "bidder_id"),
    )

    bid_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    listing_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("listings.listing_id"))
    bidder_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.user_id"))
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    status: Mapped[str] = mapped_column(String(20), default="Accepted")  # Accepted/Rejected
    placed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
