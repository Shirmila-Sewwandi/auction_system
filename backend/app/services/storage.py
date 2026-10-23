import uuid
from pathlib import Path

from fastapi import UploadFile

from app.core.exceptions import ValidationError

UPLOAD_ROOT = Path(__file__).resolve().parent.parent.parent / "uploads" / "listings"
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_IMAGE_BYTES = 5 * 1024 * 1024


def save_listing_image(listing_id: int, file: UploadFile) -> str:
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise ValidationError(f"Unsupported image type: {file.content_type}")

    contents = file.file.read()
    if len(contents) > MAX_IMAGE_BYTES:
        raise ValidationError("Image exceeds maximum size of 5MB")

    ext = Path(file.filename or "").suffix.lower() or ".bin"
    dest_dir = UPLOAD_ROOT / str(listing_id)
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest_path = dest_dir / f"{uuid.uuid4().hex}{ext}"
    dest_path.write_bytes(contents)

    # as_posix(): stored as a URL path (served via StaticFiles / embedded in frontend <img> src),
    # so it must use forward slashes even when this runs on Windows.
    return dest_path.relative_to(UPLOAD_ROOT.parent.parent).as_posix()


def delete_listing_image(image_path: str) -> None:
    path = UPLOAD_ROOT.parent.parent / Path(image_path)
    path.unlink(missing_ok=True)
