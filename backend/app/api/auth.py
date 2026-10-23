from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_db
from app.core.exceptions import ConflictError, UnauthorizedError
from app.core.rate_limit import rate_limit_by_ip
from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import Role, User
from app.schemas.user import (
    LoginRequest,
    LoginResponse,
    MeResponse,
    RegisterRequest,
    RegisterResponse,
    UserSummary,
)
from app.services.audit import log_action

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/register", response_model=RegisterResponse, dependencies=[Depends(rate_limit_by_ip(10, 60))])
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter_by(email=payload.email).first():
        raise ConflictError("An account with this email already exists")

    roles = db.query(Role).filter(Role.role_name.in_(payload.roles)).all()

    user = User(
        first_name=payload.first_name,
        last_name=payload.last_name,
        email=payload.email,
        password_hash=hash_password(payload.password),
        phone=payload.phone,
        roles=roles,
    )
    db.add(user)
    db.flush()  # populate user.user_id before using it below
    log_action(
        db,
        user_id=user.user_id,
        action="USER_REGISTERED",
        entity_type="User",
        entity_id=user.user_id,
        new_value={"email": user.email, "roles": payload.roles},
    )
    db.commit()
    db.refresh(user)

    return RegisterResponse(
        user_id=user.user_id,
        email=user.email,
        roles=[r.role_name for r in user.roles],
        message="Registration successful",
    )


@router.post("/login", response_model=LoginResponse, dependencies=[Depends(rate_limit_by_ip(10, 60))])
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter_by(email=payload.email).first()
    if user is None or not verify_password(payload.password, user.password_hash):
        raise UnauthorizedError("Invalid email or password")
    if user.status != "Active":
        raise UnauthorizedError(f"Account is {user.status}")

    role_names = [r.role_name for r in user.roles]
    token = create_access_token(user.user_id, role_names)
    return LoginResponse(
        access_token=token,
        user=UserSummary(user_id=user.user_id, email=user.email, roles=role_names),
    )


@router.post("/logout")
def logout(user: User = Depends(get_current_user)):
    # Stateless JWT: nothing to invalidate server-side; client discards the token.
    return {"message": "Logged out"}


@router.get("/me", response_model=MeResponse)
def me(user: User = Depends(get_current_user)):
    return MeResponse(
        user_id=user.user_id,
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email,
        phone=user.phone,
        roles=[r.role_name for r in user.roles],
        status=user.status,
    )
