from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppError(Exception):
    """Base for all domain errors. Caught once in main.py and mapped to a consistent
    JSON error shape, instead of every route hand-rolling HTTPException.
    """

    status_code = 400

    def __init__(self, message: str):
        self.message = message
        super().__init__(message)


class NotFoundError(AppError):
    status_code = 404


class ForbiddenError(AppError):
    status_code = 403


class UnauthorizedError(AppError):
    status_code = 401


class ConflictError(AppError):
    status_code = 409


class ValidationError(AppError):
    status_code = 422


# Bidding/auction-specific domain errors (Phase 3+) — all map to 400 unless noted.
class BidTooLowError(AppError):
    pass


class AuctionNotActiveError(AppError):
    pass


class SelfBidError(AppError):
    pass


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppError)
    async def app_error_handler(request: Request, exc: AppError):
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})
