def test_login_rate_limited_after_threshold(client):
    client.post(
        "/api/auth/register",
        json={
            "first_name": "R",
            "last_name": "L",
            "email": "ratelimited@example.com",
            "password": "password123",
            "roles": ["BIDDER"],
        },
    )
    for _ in range(10):
        resp = client.post("/api/auth/login", json={"email": "ratelimited@example.com", "password": "password123"})
        assert resp.status_code == 200

    eleventh = client.post("/api/auth/login", json={"email": "ratelimited@example.com", "password": "password123"})
    assert eleventh.status_code == 429


def test_register_and_login_limits_are_independent_buckets(client):
    """Regression: the limiter key once ignored the endpoint, so exhausting register also blocked login."""
    for i in range(10):
        r = client.post(
            "/api/auth/register",
            json={"first_name": "A", "last_name": "B", "email": f"bucket{i}@example.com", "password": "password123", "roles": ["BIDDER"]},
        )
        assert r.status_code == 200
    ok = client.post("/api/auth/login", json={"email": "bucket0@example.com", "password": "password123"})
    assert ok.status_code == 200
