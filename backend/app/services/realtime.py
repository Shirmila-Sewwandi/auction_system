import asyncio
import json
from collections import defaultdict
from datetime import datetime
from decimal import Decimal

from fastapi import WebSocket

_MAIN_LOOP: asyncio.AbstractEventLoop | None = None
_subscribers: dict[int, set[WebSocket]] = defaultdict(set)


def set_main_loop(loop: asyncio.AbstractEventLoop) -> None:
    """Captured once at app startup so sync request handlers (FastAPI runs sync `def` routes
    in a worker thread) can hand a broadcast back to the event loop that owns the sockets."""
    global _MAIN_LOOP
    _MAIN_LOOP = loop


async def subscribe(listing_id: int, websocket: WebSocket) -> None:
    await websocket.accept()
    _subscribers[listing_id].add(websocket)


def unsubscribe(listing_id: int, websocket: WebSocket) -> None:
    _subscribers[listing_id].discard(websocket)


def _default(value):
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, datetime):
        return value.isoformat()
    raise TypeError(f"Not serializable: {value!r}")


async def _broadcast(listing_id: int, payload: dict) -> None:
    dead = []
    for ws in _subscribers.get(listing_id, set()):
        try:
            await ws.send_text(json.dumps(payload, default=_default))
        except Exception:
            dead.append(ws)
    for ws in dead:
        unsubscribe(listing_id, ws)


def broadcast_listing_update(listing_id: int, *, event: str, current_price, end_time) -> None:
    """Called from sync code (bid placement, anti-sniping extension, auto-close) after a
    commit. Schedules the actual send onto the main asyncio loop; a no-op with no subscribers
    or outside a running app (e.g. in tests) since there's nothing to deliver to."""
    if _MAIN_LOOP is None:
        return
    payload = {"event": event, "listing_id": listing_id, "current_price": current_price, "end_time": end_time}
    asyncio.run_coroutine_threadsafe(_broadcast(listing_id, payload), _MAIN_LOOP)
