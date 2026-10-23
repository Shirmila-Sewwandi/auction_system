"""Generates a handful of solid-color placeholder JPEGs for demo listing images — stdlib only
(no Pillow dependency) via a minimal hand-rolled PNG encoder. Good enough for UI verification;
not a general-purpose image tool.
"""
import struct
import zlib
from pathlib import Path

COLORS = {
    "amber.png": (196, 149, 86),
    "sage.png": (122, 142, 110),
    "slate.png": (90, 104, 122),
    "terracotta.png": (178, 104, 80),
    "plum.png": (120, 90, 120),
}


def _write_solid_png(path: Path, rgb: tuple[int, int, int], width=640, height=480) -> None:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)  # 8-bit depth, RGB
    row = b"\x00" + bytes(rgb) * width  # filter byte 0 (none) + one pixel repeated
    raw = row * height
    idat = zlib.compress(raw, level=6)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    path.write_bytes(png)


def ensure_placeholders(uploads_dir: Path) -> list[str]:
    """Writes the placeholder files if missing; returns their paths relative to uploads_dir's
    parent (i.e. the form ListingImage.image_path / the static URL expects)."""
    demo_dir = uploads_dir / "demo"
    demo_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for filename, rgb in COLORS.items():
        file_path = demo_dir / filename
        if not file_path.exists():
            _write_solid_png(file_path, rgb)
        paths.append(f"uploads/demo/{filename}")
    return paths
