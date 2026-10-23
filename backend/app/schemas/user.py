from pydantic import BaseModel, EmailStr, field_validator

# Only these can be self-selected at sign-up. MODERATOR/ADMIN are granted by an admin
# (PATCH /api/admin/users/{id}/roles) — otherwise anyone could register as ADMIN.
VALID_ROLES = {"SELLER", "BIDDER"}


class RegisterRequest(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    password: str
    phone: str | None = None
    roles: list[str]

    @field_validator("roles")
    @classmethod
    def roles_must_be_known(cls, roles: list[str]) -> list[str]:
        if not roles:
            raise ValueError("At least one role is required")
        unknown = set(roles) - VALID_ROLES
        if unknown:
            raise ValueError(f"Role(s) not allowed at registration: {sorted(unknown)}")
        return roles

    @field_validator("password")
    @classmethod
    def password_min_length(cls, value: str) -> str:
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters")
        return value


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserSummary(BaseModel):
    user_id: int
    email: str
    roles: list[str]


class RegisterResponse(BaseModel):
    user_id: int
    email: str
    roles: list[str]
    message: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserSummary


class MeResponse(BaseModel):
    user_id: int
    first_name: str
    last_name: str
    email: str
    phone: str | None
    roles: list[str]
    status: str
