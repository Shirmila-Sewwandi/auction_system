import pytest

from app.core.deps import require_roles
from app.core.exceptions import ForbiddenError
from app.models.user import Role, User


def test_register_and_login(client):
    reg = client.post(
        "/api/auth/register",
        json={
            "first_name": "Ada",
            "last_name": "Lovelace",
            "email": "ada@example.com",
            "password": "password123",
            "roles": ["BIDDER"],
        },
    )
    assert reg.status_code == 200
    assert reg.json()["roles"] == ["BIDDER"]

    login = client.post("/api/auth/login", json={"email": "ada@example.com", "password": "password123"})
    assert login.status_code == 200
    assert login.json()["user"]["email"] == "ada@example.com"


def test_duplicate_email_rejected(client):
    body = {
        "first_name": "A",
        "last_name": "B",
        "email": "dup@example.com",
        "password": "password123",
        "roles": ["BIDDER"],
    }
    assert client.post("/api/auth/register", json=body).status_code == 200
    second = client.post("/api/auth/register", json=body)
    assert second.status_code == 409


def test_invalid_role_rejected(client):
    body = {
        "first_name": "A",
        "last_name": "B",
        "email": "badrole@example.com",
        "password": "password123",
        "roles": ["SUPERUSER"],
    }
    resp = client.post("/api/auth/register", json=body)
    assert resp.status_code == 422


def test_login_wrong_password_rejected(client, make_user):
    make_user(["BIDDER"], email="wrongpw@example.com")
    resp = client.post("/api/auth/login", json={"email": "wrongpw@example.com", "password": "nope12345"})
    assert resp.status_code == 401


def test_me_requires_token(client):
    resp = client.get("/api/auth/me")
    assert resp.status_code == 401


def test_me_returns_profile(client, make_user):
    headers, user_id = make_user(["SELLER", "BIDDER"])
    resp = client.get("/api/auth/me", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["user_id"] == user_id
    assert set(resp.json()["roles"]) == {"SELLER", "BIDDER"}


def test_require_roles_rejects_wrong_role():
    bidder_only = User(status="Active", roles=[Role(role_name="BIDDER")])
    checker = require_roles("ADMIN")
    with pytest.raises(ForbiddenError):
        checker(user=bidder_only)


@pytest.mark.parametrize("role", ["ADMIN", "MODERATOR"])
def test_privileged_roles_cannot_be_self_registered(client, role):
    resp = client.post(
        "/api/auth/register",
        json={"first_name": "E", "last_name": "V", "email": f"{role.lower()}@evil.com", "password": "password123", "roles": [role]},
    )
    assert resp.status_code == 422


def test_register_is_rate_limited(client):
    codes = [
        client.post(
            "/api/auth/register",
            json={"first_name": "A", "last_name": "B", "email": f"flood{i}@example.com", "password": "password123", "roles": ["BIDDER"]},
        ).status_code
        for i in range(12)
    ]
    assert codes[-1] == 429
