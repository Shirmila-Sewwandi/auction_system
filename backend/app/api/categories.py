from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.deps import get_db, require_roles
from app.core.exceptions import ConflictError, NotFoundError
from app.models.category import Category
from app.models.user import User
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from app.services.audit import log_action

router = APIRouter(tags=["categories"])
admin_router = APIRouter(prefix="/api/admin/categories", tags=["admin:categories"])


@router.get("/api/categories", response_model=list[CategoryOut])
def list_active_categories(db: Session = Depends(get_db)):
    """Public read-only list of active categories — not in the spec's §4.3 endpoint list (only
    /api/admin/categories is), but sellers need something to populate a category picker with
    when creating a listing, and they can't call the admin-only management endpoint."""
    return db.query(Category).filter_by(is_active=True).order_by(Category.name).all()


@admin_router.get("", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db), _: User = Depends(require_roles("ADMIN"))):
    return db.query(Category).order_by(Category.name).all()


@admin_router.post("", response_model=CategoryOut)
def create_category(
    payload: CategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_roles("ADMIN")),
):
    if db.query(Category).filter_by(name=payload.name).first():
        raise ConflictError("A category with this name already exists")

    category = Category(name=payload.name, description=payload.description)
    db.add(category)
    db.flush()
    log_action(
        db,
        user_id=admin.user_id,
        action="CATEGORY_CREATED",
        entity_type="Category",
        entity_id=category.category_id,
        new_value={"name": category.name},
    )
    db.commit()
    db.refresh(category)
    return category


@admin_router.patch("/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: int,
    payload: CategoryUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_roles("ADMIN")),
):
    category = db.get(Category, category_id)
    if category is None:
        raise NotFoundError("Category not found")

    if payload.name is not None and payload.name != category.name:
        if db.query(Category).filter_by(name=payload.name).first():
            raise ConflictError("A category with this name already exists")
        category.name = payload.name
    if payload.description is not None:
        category.description = payload.description
    if payload.is_active is not None:
        category.is_active = payload.is_active

    log_action(
        db,
        user_id=admin.user_id,
        action="CATEGORY_UPDATED",
        entity_type="Category",
        entity_id=category.category_id,
        new_value={"name": category.name, "is_active": category.is_active},
    )
    db.commit()
    db.refresh(category)
    return category
