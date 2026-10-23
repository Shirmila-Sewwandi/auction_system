"""One-off seed: fixed Role rows and the single platform_config row.

Run with: python -m app.db.seed
Safe to re-run — uses get-or-create, never duplicates.
"""
from app.db.session import SessionLocal
from app.models.platform_config import PlatformConfig
from app.models.user import Role

ROLE_NAMES = {
    "SELLER": "Can list items for auction",
    "BIDDER": "Can place bids on auctions",
    "MODERATOR": "Reviews listings, reports, and disputes",
    "ADMIN": "Full platform administration",
}


def run() -> None:
    db = SessionLocal()
    try:
        for name, description in ROLE_NAMES.items():
            if not db.query(Role).filter_by(role_name=name).first():
                db.add(Role(role_name=name, description=description))

        if not db.get(PlatformConfig, 1):
            db.add(PlatformConfig(config_id=1))

        db.commit()
        print("Seed complete: roles + platform_config ensured.")
    finally:
        db.close()


if __name__ == "__main__":
    run()
