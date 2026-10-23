import threading
import time
from collections import defaultdict, deque

from fastapi import Depends, Request

from app.core.deps import get_current_user_optional
from app.core.exceptions import AppError
from app.models.user import User

# ponytail: single-process in-memory sliding window — fine for one FastAPI process on one
# box (this project's whole deployment model). Swap for a Redis-backed limiter (INCR + EXPIRE)
# if this ever runs as more than one worker/process.
_lock = threading.Lock()
_hits: dict[str, deque] = defaultdict(deque)


class RateLimitedError(AppError):
    status_code = 429


def reset_rate_limits() -> None:
    """Test-only hook — TestClient reuses one fake client IP for every request, so without a
    reset between tests the global in-memory store would make unrelated tests throttle each
    other."""
    with _lock:
        _hits.clear()


def _route_key(request: Request) -> str:
    """Route *template* (e.g. /api/listings/{listing_id}/bids), so each endpoint has its own
    bucket — without it two endpoints with the same limits (register + login) shared one — while
    per-user limits still span every listing id."""
    route = request.scope.get("route")
    return getattr(route, "path", request.url.path)


def _check(key: str, max_requests: int, window_seconds: int) -> None:
    now = time.monotonic()
    with _lock:
        bucket = _hits[key]
        while bucket and now - bucket[0] > window_seconds:
            bucket.popleft()
        if len(bucket) >= max_requests:
            raise RateLimitedError("Too many requests — please slow down and try again shortly")
        bucket.append(now)


def rate_limit_by_ip(max_requests: int, window_seconds: int):
    """For endpoints callable without auth (login, register, public search)."""

    def _dep(request: Request) -> None:
        client_ip = request.client.host if request.client else "unknown"
        _check(f"{_route_key(request)}:ip:{client_ip}:{max_requests}:{window_seconds}", max_requests, window_seconds)

    return _dep


def rate_limit_by_user_or_ip(max_requests: int, window_seconds: int):
    """For endpoints usually called by an authenticated user (bidding) but that may also see
    anonymous callers — falls back to IP when there's no user."""

    def _dep(request: Request, user: User | None = Depends(get_current_user_optional)) -> None:
        identity = f"user:{user.user_id}" if user else f"ip:{request.client.host if request.client else 'unknown'}"
        _check(f"{_route_key(request)}:{identity}:{max_requests}:{window_seconds}", max_requests, window_seconds)

    return _dep
