from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, ForeignKey, Index, Integer, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Listing(Base):
    __tablename__ = "listings"
    __table_args__ = (
        Index("ix_listings_status_end_time", "status", "end_time"),
        Index("ix_listings_category_id", "category_id"),
        Index("ix_listings_seller_id", "seller_id"),
    )

    listing_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    seller_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.user_id"))
    category_id: Mapped[int] = mapped_column(Integer, ForeignKey("categories.category_id"))

    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str] = mapped_column(Text)
    condition: Mapped[str | None] = mapped_column(String(100), nullable=True)
    provenance: Mapped[str | None] = mapped_column(Text, nullable=True)

    starting_price: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    reserve_price: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    current_price: Mapped[Decimal] = mapped_column(Numeric(12, 2))  # cached MAX(Bid.amount), synced in same txn
    # Rule snapshots taken at creation time (Phase 10 policy: admin rule changes never affect
    # auctions already in flight).
    min_bid_increment: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    anti_sniping_window_minutes: Mapped[int] = mapped_column(Integer)
    anti_sniping_extension_minutes: Mapped[int] = mapped_column(Integer)
    max_anti_sniping_extensions: Mapped[int | None] = mapped_column(Integer, nullable=True)

    start_time: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    end_time: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    original_end_time: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    anti_sniping_extensions: Mapped[int] = mapped_column(Integer, default=0)  # count, capped by platform_config

    status: Mapped[str] = mapped_column(String(30), default="Pending")  # Pending/Active/Closed/Cancelled
    moderation_status: Mapped[str] = mapped_column(String(30), default="Pending Review")
    # Pending Review/Approved/Rejected/Suspended

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    images: Mapped[list["ListingImage"]] = relationship(
        back_populates="listing", order_by="ListingImage.display_order", cascade="all, delete-orphan"
    )


class ListingImage(Base):
    __tablename__ = "listing_images"

    image_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    listing_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("listings.listing_id"))
    image_path: Mapped[str] = mapped_column(String(500))
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    listing: Mapped["Listing"] = relationship(back_populates="images")
