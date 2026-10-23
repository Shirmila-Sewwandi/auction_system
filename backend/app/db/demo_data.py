"""Demo dataset for UI/UX verification against realistic data volume.

Covers every role (including one account that is both SELLER and BIDDER), 10 categories, and
~25 listings spanning every lifecycle state (pending review, rejected, suspended, active with
and without bids, closing soon, closed with no bids / reserve not met / sold, paid, and
disputed at every stage: open, under review, resolved-refund, resolved-release). Every table
ends up with 10+ rows except two that are structurally fixed by design: `roles` (exactly 4 —
SELLER/BIDDER/MODERATOR/ADMIN, per the RBAC model) and `platform_config` (a single settings
row, see plan.md's Phase 10 note).

Run with: python -m app.db.demo_data
Not idempotent — intended for a one-time demo/marking setup on a fresh database (run
`python -m app.db.seed` first for roles + platform_config).
"""
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path

from app.core.security import hash_password
from app.db.placeholder_images import ensure_placeholders
from app.db.session import SessionLocal
from app.models.auction_result import AuctionResult
from app.models.category import Category
from app.models.listing import Listing, ListingImage
from app.models.user import Role, User
from app.services.bidding import place_bid
from app.services.closing import close_expired_auction
from app.services.disputes import raise_dispute, resolve_dispute
from app.services.moderation import moderate_listing
from app.services.payments import create_payment

PASSWORD = "password123"

CATEGORY_NAMES = [
    "Furniture", "Jewelry", "Art", "Coins & Currency", "Books & Manuscripts",
    "Ceramics & Glass", "Textiles & Rugs", "Clocks & Watches", "Militaria", "Musical Instruments",
]


def make_user(db, email, first, last, roles):
    existing = db.query(User).filter_by(email=email).first()
    if existing:
        return existing
    role_rows = db.query(Role).filter(Role.role_name.in_(roles)).all()
    user = User(
        first_name=first, last_name=last, email=email,
        password_hash=hash_password(PASSWORD), is_verified=True, status="Active", roles=role_rows,
    )
    db.add(user)
    db.flush()
    return user


def make_category(db, name):
    existing = db.query(Category).filter_by(name=name).first()
    if existing:
        return existing
    category = Category(name=name, description=f"{name} items")
    db.add(category)
    db.flush()
    return category


def make_listing(db, seller, category, title, *, starting_price, reserve_price, start_offset, end_offset):
    now = datetime.now(timezone.utc)
    listing = Listing(
        seller_id=seller.user_id, category_id=category.category_id, title=title,
        description=f"A fine {title.lower()}, carefully preserved and offered from a private collection.",
        condition="Good", provenance="Private collection",
        starting_price=starting_price, reserve_price=reserve_price, current_price=starting_price,
        min_bid_increment=Decimal("1.00"), anti_sniping_window_minutes=5, anti_sniping_extension_minutes=10,
        start_time=now + timedelta(minutes=start_offset), end_time=now + timedelta(minutes=end_offset),
        original_end_time=now + timedelta(minutes=end_offset), status="Pending", moderation_status="Pending Review",
    )
    db.add(listing)
    db.flush()
    return listing


def build(db, moderator, image_paths, image_index, *, seller, category, title, starting_price,
          reserve_price=None, moderation=None, reason=None, bids=None, force_close=False,
          pay_by=None, dispute=None, start_offset=-120, end_offset=60):
    """One listing, carried through as much of its lifecycle as the arguments ask for."""
    listing = make_listing(
        db, seller, category, title, starting_price=starting_price, reserve_price=reserve_price,
        start_offset=start_offset, end_offset=end_offset,
    )
    db.add(ListingImage(listing_id=listing.listing_id, image_path=image_paths[image_index % len(image_paths)]))
    db.commit()

    if moderation is None:
        return listing  # stays Pending Review

    moderate_listing(db, listing_id=listing.listing_id, moderator=moderator, action=moderation, reason=reason)
    db.commit()
    if moderation != "approve":
        return listing

    for bidder, amount in bids or []:
        place_bid(db, listing_id=listing.listing_id, bidder=bidder, amount=amount)
        db.commit()

    if not force_close:
        return listing

    listing.end_time = datetime.now(timezone.utc) - timedelta(seconds=1)
    db.commit()
    result = close_expired_auction(db, listing.listing_id)
    db.commit()
    result = result or db.query(AuctionResult).filter_by(listing_id=listing.listing_id).one()

    if pay_by is not None:
        payment = create_payment(db, auction_result_id=result.result_id, payer=pay_by)
        db.commit()
        if dispute is not None:
            d = raise_dispute(
                db, auction_result_id=result.result_id, raiser=dispute["raiser"],
                dispute_type=dispute["type"], reason=dispute["reason"], description=dispute.get("description"),
            )
            db.commit()
            resolution = dispute.get("resolve")
            if resolution:
                resolve_dispute(
                    db, dispute_id=d.dispute_id, moderator=moderator, status=resolution["status"],
                    resolution=resolution["resolution"], release_funds=resolution.get("release", False),
                    refund_funds=resolution.get("refund", False),
                )
                db.commit()

    return listing


def run() -> None:
    db = SessionLocal()
    try:
        admin = make_user(db, "admin@demo.com", "Ada", "Admin", ["ADMIN"])
        mod1 = make_user(db, "moderator@demo.com", "Mo", "Deratorz", ["MODERATOR"])
        mod2 = make_user(db, "moderator2@demo.com", "Rae", "Reviewer", ["MODERATOR"])
        s1 = make_user(db, "seller@demo.com", "Sam", "Seller", ["SELLER"])
        s2 = make_user(db, "seller2@demo.com", "Sally", "Smith", ["SELLER"])
        s3 = make_user(db, "seller3@demo.com", "Steve", "Stone", ["SELLER"])
        b1 = make_user(db, "bidder@demo.com", "Bea", "Bidder", ["BIDDER"])
        b2 = make_user(db, "bidder2@demo.com", "Ben", "Bidderson", ["BIDDER"])
        b3 = make_user(db, "bidder3@demo.com", "Bill", "Byers", ["BIDDER"])
        sb = make_user(db, "sellerbidder@demo.com", "Robin", "Rivera", ["SELLER", "BIDDER"])
        db.commit()

        cats = {name: make_category(db, name) for name in CATEGORY_NAMES}
        db.commit()

        uploads_dir = Path(__file__).resolve().parent.parent.parent / "uploads"
        image_paths = ensure_placeholders(uploads_dir)
        idx = 0

        def next_idx():
            nonlocal idx
            idx += 1
            return idx

        # --- Pending review (2) ---------------------------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=s1, category=cats["Furniture"],
              title="Georgian Mahogany Card Table", starting_price=Decimal("150.00"))
        build(db, mod1, image_paths, next_idx(), seller=s2, category=cats["Jewelry"],
              title="Edwardian Diamond Ring", starting_price=Decimal("900.00"))

        # --- Rejected / suspended (1 each) -----------------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=s3, category=cats["Art"],
              title="Unverified Oil Painting", starting_price=Decimal("300.00"),
              moderation="reject", reason="Unable to verify authenticity")
        build(db, mod2, image_paths, next_idx(), seller=s1, category=cats["Militaria"],
              title="Antique Firearm Collection", starting_price=Decimal("500.00"),
              moderation="suspend", reason="Requires additional compliance review")

        # --- Active, no bids yet (2) -------------------------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=s2, category=cats["Ceramics & Glass"],
              title="Victorian Silver Tea Set", starting_price=Decimal("220.00"), moderation="approve")
        build(db, mod1, image_paths, next_idx(), seller=s3, category=cats["Books & Manuscripts"],
              title="First Edition Dickens Novel", starting_price=Decimal("400.00"), moderation="approve")

        # --- Active, with bids (3) ----------------------------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=s1, category=cats["Jewelry"],
              title="Art Deco Sapphire Brooch", starting_price=Decimal("80.00"), moderation="approve",
              bids=[(b1, Decimal("80.00")), (b2, Decimal("85.00"))])
        build(db, mod2, image_paths, next_idx(), seller=sb, category=cats["Ceramics & Glass"],
              title="Qing Dynasty Porcelain Vase", starting_price=Decimal("600.00"), moderation="approve",
              bids=[(b1, Decimal("600.00")), (b3, Decimal("625.00"))])
        build(db, mod1, image_paths, next_idx(), seller=s2, category=cats["Musical Instruments"],
              title="Stradivarius-style Violin", starting_price=Decimal("1200.00"), moderation="approve",
              bids=[(b2, Decimal("1200.00")), (sb, Decimal("1250.00"))])

        # --- Closing soon — inside the default anti-sniping window (1) --------------------
        build(db, mod1, image_paths, next_idx(), seller=s3, category=cats["Art"],
              title="Limited Edition Lithograph", starting_price=Decimal("200.00"), moderation="approve",
              bids=[(b1, Decimal("200.00"))], end_offset=4)

        # --- Closed: no bids (1) -------------------------------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=s1, category=cats["Clocks & Watches"],
              title="Unsold Victorian Clock", starting_price=Decimal("90.00"), moderation="approve",
              force_close=True, end_offset=2)

        # --- Closed: reserve not met (2) ------------------------------------------------------
        build(db, mod2, image_paths, next_idx(), seller=s2, category=cats["Coins & Currency"],
              title="Rare Gold Coin Collection", starting_price=Decimal("50.00"), reserve_price=Decimal("5000.00"),
              moderation="approve", bids=[(b2, Decimal("50.00"))], force_close=True, end_offset=2)
        build(db, mod1, image_paths, next_idx(), seller=s3, category=cats["Textiles & Rugs"],
              title="Persian Silk Rug", starting_price=Decimal("300.00"), reserve_price=Decimal("3000.00"),
              moderation="approve", bids=[(b3, Decimal("300.00"))], force_close=True, end_offset=2)

        # --- Closed, sold, paid, no dispute (2) -----------------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=sb, category=cats["Furniture"],
              title="Regency Dining Chairs", starting_price=Decimal("350.00"), reserve_price=Decimal("350.00"),
              moderation="approve", bids=[(b1, Decimal("350.00"))], force_close=True, end_offset=2, pay_by=b1)
        build(db, mod2, image_paths, next_idx(), seller=s1, category=cats["Jewelry"],
              title="Art Nouveau Hair Comb", starting_price=Decimal("150.00"), reserve_price=Decimal("150.00"),
              moderation="approve", bids=[(b2, Decimal("150.00"))], force_close=True, end_offset=2, pay_by=b2)

        # --- Closed, sold, paid, dispute OPEN (3) ----------------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=s2, category=cats["Art"],
              title="Impressionist Landscape Study", starting_price=Decimal("700.00"), reserve_price=Decimal("700.00"),
              moderation="approve", bids=[(b3, Decimal("700.00"))], force_close=True, end_offset=2, pay_by=b3,
              dispute={"raiser": b3, "type": "item_not_as_described", "reason": "Canvas has undisclosed restoration"})
        build(db, mod1, image_paths, next_idx(), seller=s3, category=cats["Clocks & Watches"],
              title="18th Century Pocket Watch", starting_price=Decimal("800.00"), reserve_price=Decimal("800.00"),
              moderation="approve", bids=[(sb, Decimal("800.00"))], force_close=True, end_offset=2, pay_by=sb,
              dispute={"raiser": sb, "type": "item_not_received", "reason": "Item has not arrived"})
        build(db, mod2, image_paths, next_idx(), seller=sb, category=cats["Ceramics & Glass"],
              title="Delft Blue Porcelain Plate", starting_price=Decimal("120.00"), reserve_price=Decimal("120.00"),
              moderation="approve", bids=[(b1, Decimal("120.00"))], force_close=True, end_offset=2, pay_by=b1,
              dispute={"raiser": b1, "type": "other", "reason": "Plate arrived with a hairline crack"})

        # --- Closed, sold, paid, dispute UNDER REVIEW (3) ---------------------------------------
        build(db, mod1, image_paths, next_idx(), seller=s1, category=cats["Coins & Currency"],
              title="Roman Silver Denarius", starting_price=Decimal("250.00"), reserve_price=Decimal("250.00"),
              moderation="approve", bids=[(b2, Decimal("250.00"))], force_close=True, end_offset=2, pay_by=b2,
              dispute={
                  "raiser": b2, "type": "item_not_as_described", "reason": "Coin weight does not match listing",
                  "resolve": {"status": "Under Review", "resolution": "Requesting seller provide a certificate of authenticity"},
              })
        build(db, mod2, image_paths, next_idx(), seller=s2, category=cats["Textiles & Rugs"],
              title="Hand-Knotted Kilim Rug", starting_price=Decimal("450.00"), reserve_price=Decimal("450.00"),
              moderation="approve", bids=[(b3, Decimal("450.00"))], force_close=True, end_offset=2, pay_by=b3,
              dispute={
                  "raiser": b3, "type": "item_not_as_described", "reason": "Colors differ noticeably from photos",
                  "resolve": {"status": "Under Review", "resolution": "Awaiting additional photos from buyer"},
              })
        build(db, mod1, image_paths, next_idx(), seller=s3, category=cats["Musical Instruments"],
              title="Vintage Brass Trumpet", starting_price=Decimal("300.00"), reserve_price=Decimal("300.00"),
              moderation="approve", bids=[(sb, Decimal("300.00"))], force_close=True, end_offset=2, pay_by=sb,
              dispute={
                  "raiser": sb, "type": "item_not_received", "reason": "Tracking shows no movement in 10 days",
                  "resolve": {"status": "Under Review", "resolution": "Contacting shipping carrier for an update"},
              })

        # --- Closed, sold, paid, dispute RESOLVED — refund (2) -----------------------------------
        build(db, mod1, image_paths, next_idx(), seller=sb, category=cats["Books & Manuscripts"],
              title="First Folio Facsimile", starting_price=Decimal("600.00"), reserve_price=Decimal("600.00"),
              moderation="approve", bids=[(b1, Decimal("600.00"))], force_close=True, end_offset=2, pay_by=b1,
              dispute={
                  "raiser": b1, "type": "item_not_as_described", "reason": "Facsimile, not an original as implied",
                  "resolve": {"status": "Resolved", "resolution": "Listing was misleading — buyer refunded in full", "refund": True},
              })
        build(db, mod2, image_paths, next_idx(), seller=s1, category=cats["Militaria"],
              title="WWII Medal Set", starting_price=Decimal("350.00"), reserve_price=Decimal("350.00"),
              moderation="approve", bids=[(b2, Decimal("350.00"))], force_close=True, end_offset=2, pay_by=b2,
              dispute={
                  "raiser": b2, "type": "item_not_received", "reason": "Item never arrived after 3 weeks",
                  "resolve": {"status": "Resolved", "resolution": "Seller could not provide proof of postage — buyer refunded", "refund": True},
              })

        # --- Closed, sold, paid, dispute RESOLVED — released despite dispute (2) -------------------
        build(db, mod1, image_paths, next_idx(), seller=s2, category=cats["Furniture"],
              title="Tiffany Style Lamp", starting_price=Decimal("400.00"), reserve_price=Decimal("400.00"),
              moderation="approve", bids=[(b3, Decimal("400.00"))], force_close=True, end_offset=2, pay_by=b3,
              dispute={
                  "raiser": b3, "type": "other", "reason": "Buyer changed their mind after purchase",
                  "resolve": {"status": "Resolved", "resolution": "Item matched listing exactly — funds released to seller", "release": True},
              })
        build(db, mod2, image_paths, next_idx(), seller=s3, category=cats["Jewelry"],
              title="Emerald Cut Sapphire Pendant", starting_price=Decimal("950.00"), reserve_price=Decimal("950.00"),
              moderation="approve", bids=[(sb, Decimal("950.00"))], force_close=True, end_offset=2, pay_by=sb,
              dispute={
                  "raiser": sb, "type": "item_not_as_described", "reason": "Stone size seemed smaller than described",
                  "resolve": {"status": "Resolved", "resolution": "Measurements independently verified as accurate — funds released", "release": True},
              })

        print("Demo data loaded: 10 users, 10 categories, 25 listings across every lifecycle state.")
        print("Accounts (password for all: password123):")
        print("  admin@demo.com (ADMIN)")
        print("  moderator@demo.com, moderator2@demo.com (MODERATOR)")
        print("  seller@demo.com, seller2@demo.com, seller3@demo.com (SELLER)")
        print("  bidder@demo.com, bidder2@demo.com, bidder3@demo.com (BIDDER)")
        print("  sellerbidder@demo.com (SELLER + BIDDER)")
    finally:
        db.close()


if __name__ == "__main__":
    run()
