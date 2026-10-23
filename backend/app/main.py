import asyncio
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.admin import router as admin_router
from app.api.auth import router as auth_router
from app.api.bidder import router as bidder_router
from app.api.bids import router as bids_router
from app.api.categories import admin_router as admin_categories_router, router as categories_router
from app.api.disputes import router as disputes_router
from app.api.listings import router as listings_router
from app.api.moderator import router as moderator_router
from app.api.notifications import router as notifications_router
from app.api.payments import router as payments_router
from app.api.results import router as results_router
from app.api.seller import router as seller_router
from app.api.ws import router as ws_router
from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.services.realtime import set_main_loop
from app.workers.closer import run_closer_loop


@asynccontextmanager
async def lifespan(app: FastAPI):
    set_main_loop(asyncio.get_running_loop())
    task = asyncio.create_task(run_closer_loop()) if settings.enable_background_worker else None
    yield
    if task is not None:
        task.cancel()


app = FastAPI(title="Online Auction Platform API", lifespan=lifespan)
register_exception_handlers(app)
# Local-only dev setup: frontend runs on a different port (Vite default 5173), no auth cookies
# involved (bearer tokens in headers), so a permissive local-dev CORS policy is fine here.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(admin_router)
app.include_router(auth_router)
app.include_router(bidder_router)
app.include_router(categories_router)
app.include_router(admin_categories_router)
app.include_router(disputes_router)
app.include_router(listings_router)
app.include_router(bids_router)
app.include_router(moderator_router)
app.include_router(notifications_router)
app.include_router(payments_router)
app.include_router(results_router)
app.include_router(seller_router)
app.include_router(ws_router)

# Serves what services/storage.py writes (image_path is stored relative to this same "uploads"
# directory), so GET /{image_path} from a ListingOut response actually resolves to the file.
UPLOADS_DIR = Path(__file__).resolve().parent.parent / "uploads"
UPLOADS_DIR.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")


@app.get("/health")
def health():
    return {"status": "ok"}
