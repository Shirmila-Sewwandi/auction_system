import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.core.deps import get_db
from app.core.rate_limit import reset_rate_limits
from app.db.base import Base
from app.main import app
from app.models.platform_config import PlatformConfig
from app.models.user import Role, User

TEST_DATABASE_URL = settings.database_url.rsplit("/", 1)[0] + "/auction_test"

engine = create_engine(TEST_DATABASE_URL, future=True)
TestSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


@pytest.fixture(scope="session", autouse=True)
def _create_schema():
    import app.models  # noqa: F401 — register all tables on Base.metadata

    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session():
    """One test = one transaction, rolled back at the end — tests never see each other's data
    and never touch the real dev database."""
    connection = engine.connect()
    transaction = connection.begin()
    session = TestSessionLocal(bind=connection)

    # Every Role row must exist for register() to attach roles — recreated per test since
    # the whole transaction (including this insert) is rolled back after.
    for name in ("SELLER", "BIDDER", "MODERATOR", "ADMIN"):
        session.add(Role(role_name=name))
    session.add(PlatformConfig(config_id=1))
    session.flush()

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session):
    reset_rate_limits()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def make_user(client, db_session):
    """Registers + logs in a user with the given roles, returns (auth_headers, user_id)."""

    counter = {"n": 0}

    def _make(roles: list[str], email: str | None = None) -> tuple[dict, int]:
        counter["n"] += 1
        email = email or f"user{counter['n']}@example.com"
        reset_rate_limits()  # helper registers many users from one fake IP; limiter is tested separately
        public = [r for r in roles if r in ("SELLER", "BIDDER")]
        reg = client.post(
            "/api/auth/register",
            json={
                "first_name": "Test",
                "last_name": "User",
                "email": email,
                "password": "password123",
                "roles": public or ["BIDDER"],
            },
        )
        assert reg.status_code == 200, reg.text
        if set(roles) != set(public or ["BIDDER"]):
            # MODERATOR/ADMIN cannot be self-registered; grant them the way an admin would.
            user = db_session.get(User, reg.json()["user_id"])
            user.roles = db_session.query(Role).filter(Role.role_name.in_(roles)).all()
            db_session.flush()
        login = client.post("/api/auth/login", json={"email": email, "password": "password123"})
        assert login.status_code == 200, login.text
        token = login.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}, reg.json()["user_id"]

    return _make
