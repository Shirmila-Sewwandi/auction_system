from decimal import Decimal

from pydantic import BaseModel, field_validator

from app.schemas.user import VALID_ROLES


class UserStatusUpdate(BaseModel):
    status: str | None = None  # Active/Suspended/Deactivated
    is_verified: bool | None = None


class UserRolesUpdate(BaseModel):
    roles: list[str]

    @field_validator("roles")
    @classmethod
    def roles_must_be_known(cls, roles: list[str]) -> list[str]:
        unknown = set(roles) - VALID_ROLES
        if unknown:
            raise ValueError(f"Unknown role(s): {sorted(unknown)}")
        return roles


class PlatformConfigUpdate(BaseModel):
    min_bid_increment: Decimal | None = None
    anti_sniping_window_minutes: int | None = None
    anti_sniping_extension_minutes: int | None = None
    max_anti_sniping_extensions: int | None = None
    platform_fee_percent: Decimal | None = None

    @field_validator(
        "min_bid_increment",
        "anti_sniping_window_minutes",
        "anti_sniping_extension_minutes",
        "max_anti_sniping_extensions",
        "platform_fee_percent",
    )
    @classmethod
    def non_negative(cls, value):
        if value is not None and value < 0:
            raise ValueError("Value must not be negative")
        return value
