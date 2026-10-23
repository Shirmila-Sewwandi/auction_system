from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Dispute(Base):
    __tablename__ = "disputes"
    __table_args__ = (Index("ix_disputes_status_moderator", "status", "assigned_moderator_id"),)

    dispute_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    auction_result_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("auction_results.result_id"))
    raised_by: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.user_id"))
    assigned_moderator_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("users.user_id"), nullable=True
    )

    dispute_type: Mapped[str] = mapped_column(String(50))
    reason: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[str] = mapped_column(String(30), default="Open")  # Open/Under Review/Resolved
    resolution: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
