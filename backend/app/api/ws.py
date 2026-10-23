from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.services.realtime import subscribe, unsubscribe

router = APIRouter(tags=["websocket"])


@router.websocket("/api/ws/listings/{listing_id}")
async def listing_updates(websocket: WebSocket, listing_id: int):
    await subscribe(listing_id, websocket)
    try:
        while True:
            # Clients don't need to send anything; just keep the connection open and
            # detect disconnects promptly.
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        unsubscribe(listing_id, websocket)
