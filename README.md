# Online Auction Platform

Full-stack implementation of `design_specification.docx` (Part A) per `plan.md` (Part B build
plan). Everything runs locally — no external accounts, no cloud services.

## Stack

- **Backend:** Python, FastAPI, SQLAlchemy 2.0, Alembic, PostgreSQL, JWT auth, WebSockets, an
  in-process background worker (auction closer), optional Redis cache.
- **Frontend:** React (Vite), React Router, Pico.css.
- **Local infra:** Docker Compose (Postgres + Redis).

## One-time setup

```bash
cd backend
python -m venv .venv
.venv/Scripts/activate        # .venv/bin/activate on macOS/Linux
pip install -r requirements.txt

cp .env.example .env          # defaults already point at the docker-compose services
docker compose up -d          # Postgres on :5433, Redis on :6379

alembic upgrade head          # creates all 12 entity tables + platform_config
python -m app.db.seed         # roles (SELLER/BIDDER/MODERATOR/ADMIN) + default platform_config row
python -m app.db.demo_data    # optional: demo users + listings in every lifecycle state
```

```bash
cd frontend
npm install
```

## Running it

```bash
# backend (from backend/, with .venv activated)
uvicorn app.main:app --reload --port 8000

# frontend (from frontend/, separate terminal)
npm run dev
```

- API: http://localhost:8000 — interactive docs at **http://localhost:8000/docs**
- App: http://localhost:5173

If you ran `python -m app.db.demo_data`, log in with any of `admin@demo.com`,
`moderator@demo.com`, `seller@demo.com`, `seller2@demo.com`, `bidder@demo.com`,
`bidder2@demo.com` — password `password123` for all.

## Tests

```bash
cd backend
.venv/Scripts/activate
python -m pytest app/tests -v
```

56 tests, run against a dedicated `auction_test` Postgres database (created automatically; each
test runs in its own rolled-back transaction, so tests never touch `auction_db`). Covers every
phase in `plan.md`: auth/RBAC, listings/moderation, bidding concurrency (including a real
multi-connection row-lock test), anti-sniping, WebSocket broadcast, the background auto-closer,
notifications, escrow payments, disputes, admin, dashboards, pagination, and Redis cache
fail-soft behaviour. Redis must be running (`docker compose up -d`) for the cache tests to pass
meaningfully — if it's down, cache calls fail soft and those two tests will fail (nothing else
breaks).

## Project layout

```
backend/app/
  models/      SQLAlchemy ORM — one file per entity (12 entities + platform_config)
  schemas/     Pydantic request/response models
  api/         FastAPI routers, one per resource
  services/    Business logic (bidding, closing, payments, disputes, notify, audit, cache, realtime)
  workers/     Background auction-closer loop
  core/        config, security, deps (auth/RBAC), exceptions, rate limiting
  tests/       pytest suite
frontend/src/
  pages/       One hub page per role (tabs inside, not a route per feature) + public pages
  components/  NavBar, ProtectedRoute, Tabs, Pagination, Banner
  context/     AuthContext (JWT + current user)
  api/         fetch wrapper + WebSocket URL helper
```

## Known gaps / deliberate deviations from the literal spec

- **`platform_config` table** — not in the Part A 12-entity ERD, but required by US-A02
  (admin-configurable bid rules). Added as a single-row settings table; see `plan.md`.
- **`GET /api/categories`** — public read of active categories, not in §4.3's endpoint list.
  Needed so the seller listing-creation form has something to populate a category picker with
  (only `/api/admin/categories`, admin-only, is in the spec).
- **`GET/PATCH /api/admin/config`** — not in §4.3, added as the obvious admin-config endpoint
  for the `platform_config` table above.
- **Partial refunds** — not implemented; `Payment` has one `amount` + an escrow status enum
  (Held/Released/Refunded), not a refunded-amount ledger, so refunds are full-amount only. See
  the `# ponytail:` comment in `backend/app/services/payments.py`.
- **Rule-snapshot policy** — admin changes to `platform_config` (min increment, anti-sniping
  window/extension, fees) only affect auctions created from then on; every `Listing` snapshots
  the rules in effect at its own creation time, so an admin change never alters an auction
  already in flight.

## Verification notes

The full golden path (register all 4 roles → create category → create listing → upload image →
moderator approve → bid → price/escrow/notifications update) was verified end-to-end against a
live `uvicorn` process via direct HTTP calls, and the frontend was confirmed to build cleanly
(`npm run build`) with every page module transforming without error. No browser-automation tool
was available in the session that built this, so the UI itself was not clicked through visually
— do that once before treating the frontend as done, especially the WebSocket live-price-update
behaviour on the listing detail page.
