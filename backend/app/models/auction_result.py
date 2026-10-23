from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AuctionResult(Base):
    __tablename__ = "auction_results"

    result_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    listing_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("listings.listing_id"), unique=True)
    winner_id: Mapped[int | None] = mapped_column(BigInteger, ForeignKey("users.user_id"), nullable=True)
    winning_bid_id: Mapped[int | None] = mapped_column(BigInteger, ForeignKey("bids.bid_id"), nullable=True)
    final_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    reserve_met: Mapped[bool] = mapped_column(Boolean, default=False)
    result_status: Mapped[str] = mapped_column(String(30))  # Sold/Reserve Not Met/No Bids
    closed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
