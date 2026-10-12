# Tách ô giao diện đang dùng thành 4 ảnh: ui, button, icon, label.
#   python -B TOOLS/content/pack_ui_kinds.py "F:/tl 2026/_goc/Interface" assets/ui/sheet assets/ui
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from pack_ui_sheet import cells_of, crop, decode_dds, pack

FONT = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 12)

BUTTON_MARKS = (
    "btn",
    "button",
    "anniu",
    "_normal",
    "_hover",
    "_pushed",
    "_push",
    "_disable",
    "_disabled",
    "_disbled",
)
UI_MARKS = ("frame", "bk", "bkg", "back", "beijing", "background", "title")


def kind_of(name: str, atlas: str, width: int, height: int) -> str:
    lowered = name.lower()
    atlas_name = atlas.lower()
    is_button = lowered.startswith("cs_") or atlas_name.startswith("button") or atlas_name == "imagebuttons"
    if not is_button:
        is_button = any(mark in lowered for mark in BUTTON_MARKS)
    if is_button:
        return "button"
    if "icon" in lowered or atlas == "UIIcons" or (width <= 48 and height <= 48):
        return "icon"
    if width >= 96 or height >= 96 or any(mark in lowered for mark in UI_MARKS):
        return "ui"
    return "label"


def with_size(piece: np.ndarray, width: int, height: int) -> np.ndarray:
    label = f"{width}x{height}"
    measure = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    box = measure.textbbox((0, 0), label, font=FONT)
    text_w = box[2] - box[0]
    text_h = box[3] - box[1]
    tile_w = max(int(piece.shape[1]), text_w + 2)
    tile_h = int(piece.shape[0]) + text_h + 4
    tile = Image.new("RGBA", (tile_w, tile_h), (0, 0, 0, 0))
    tile.paste(Image.fromarray(piece, "RGBA"), (0, 0))
    draw = ImageDraw.Draw(tile)
    x = 1
    y = int(piece.shape[0]) + 1
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        draw.text((x + dx, y + dy), label, font=FONT, fill=(0, 0, 0, 255))
    draw.text((x, y), label, font=FONT, fill=(255, 220, 0, 255))
    return np.asarray(tile)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("interface", type=Path)
    parser.add_argument("sheets", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    groups: dict[str, list[tuple[str, str, np.ndarray]]] = {
        "ui": [],
        "button": [],
        "icon": [],
        "label": [],
    }
    cache: dict[str, np.ndarray] = {}
    index: list[str] = ["# loại\tatlas\tảnh\tw\th"]
    for rel, name, x, y, w, h in cells_of(args.sheets):
        if w <= 0 or h <= 0:
            continue
        atlas = Path(rel).stem
        kind = kind_of(name, atlas, w, h)
        if rel not in cache:
            cache[rel] = decode_dds(args.interface / rel)
        groups[kind].append((atlas, name, with_size(crop(cache[rel], x, y, w, h), w, h)))
        index.append(f"{kind}\t{atlas}\t{name}\t{w}\t{h}")
    args.out.mkdir(parents=True, exist_ok=True)
    notes = ["# kích thước từng tấm"]
    for kind, items in groups.items():
        if not items:
            print(kind, 0)
            continue
        sheet = pack([piece for _atlas, _name, piece in items])
        path = args.out / f"{kind}.png"
        Image.fromarray(sheet, "RGBA").save(path)
        notes.append(f"# {kind}.png\t{sheet.shape[1]}x{sheet.shape[0]}\t{len(items)} ô")
        print(f"{kind} {len(items)} ô, {sheet.shape[1]}x{sheet.shape[0]} -> {path}")
    (args.out / "parts.tsv").write_text("\n".join(notes + index) + "\n", encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
