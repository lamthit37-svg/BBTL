# Bảng dọc toàn bộ ô giao diện gốc. Ba cột ảnh cùng cỡ: chữ Hán đã dán, Việt và Anh để trống.
#   python -B TOOLS/content/pack_ui_board.py "F:/tl 2026/_goc/Interface" assets/ui/sheet assets/ui/board.png
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from pack_ui_kinds import kind_of
from pack_ui_sheet import cells_of, crop, decode_dds

FONT = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 15)
FONT_SMALL = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 12)
FONT_TITLE = ImageFont.truetype(r"C:\Windows\Fonts\msyh.ttc", 22)

BG = (18, 18, 20, 255)
GOLD = (212, 184, 122, 255)
MUTED = (168, 160, 148, 255)
LINE = (70, 62, 48, 255)
EMPTY = (28, 28, 32, 255)

META_W = 210
PAD = 18
ROW_GAP = 10
SECTION_ORDER = ("ui", "button", "icon", "label")
SECTION_TITLE = {"ui": "KHUNG", "button": "NÚT", "icon": "ICON", "label": "NHÃN"}
LANG = ("中文", "VIỆT", "ANH")


def state_of(name: str) -> str:
    lowered = name.lower()
    marks = (
        ("disabled", "DISABLED"),
        ("disable", "DISABLED"),
        ("disbled", "DISABLED"),
        ("hover", "HOVER"),
        ("pushed", "PRESSED"),
        ("push", "PRESSED"),
        ("normal", "NORMAL"),
    )
    for mark, label in marks:
        if mark in lowered:
            return label
    return ""


def text_size(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=font)
    return box[2] - box[0], box[3] - box[1]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("interface", type=Path)
    parser.add_argument("sheets", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    rows: list[tuple[str, str, str, int, int, np.ndarray]] = []
    cache: dict[str, np.ndarray] = {}
    for rel, name, x, y, w, h in cells_of(args.sheets):
        if w <= 0 or h <= 0:
            continue
        atlas = Path(rel).stem
        if rel not in cache:
            cache[rel] = decode_dds(args.interface / rel)
        rows.append((kind_of(name, atlas, w, h), name, state_of(name), w, h, crop(cache[rel], x, y, w, h)))
    rows.sort(key=lambda item: (SECTION_ORDER.index(item[0]), item[1]))
    col_w = max(item[3] for item in rows)
    width = PAD + META_W + (col_w + PAD) * 3 + PAD
    # Chiều cao: đầu trang, mỗi nhóm một dòng tiêu đề, mỗi ô một hàng đúng cỡ ảnh.
    height = 78
    last_kind = ""
    for kind, _name, _state, _w, h, _piece in rows:
        if kind != last_kind:
            height += 36
            last_kind = kind
        height += max(h, 58) + ROW_GAP
    board = Image.new("RGBA", (width, height), BG)
    draw = ImageDraw.Draw(board)
    draw.text((width // 2, 16), "GIAO DIỆN GỐC  —  中文    VIỆT    ANH", font=FONT_TITLE, fill=GOLD, anchor="ma")
    headers = ("中文", "VIỆT", "ANH")
    y = 58
    for index, title in enumerate(headers):
        x = PAD + META_W + index * (col_w + PAD) + col_w // 2
        draw.text((x, y), title, font=FONT, fill=GOLD, anchor="ma")
    y = 78
    last_kind = ""
    number = 0
    for kind, name, state, w, h, piece in rows:
        if kind != last_kind:
            draw.line((PAD, y + 8, width - PAD, y + 8), fill=LINE, width=1)
            draw.text((PAD, y + 14), SECTION_TITLE[kind], font=FONT, fill=GOLD)
            y += 36
            last_kind = kind
        number += 1
        row_h = max(h, 58)
        draw.text((PAD + 8, y + 2), str(number), font=FONT, fill=GOLD)
        if state:
            draw.text((PAD + 36, y + 4), state, font=FONT_SMALL, fill=(230, 226, 216, 255))
        draw.text((PAD + 36, y + 22), f"({w}×{h})", font=FONT_SMALL, fill=MUTED)
        shown = name if len(name) <= 26 else name[:25] + "…"
        draw.text((PAD + 8, y + 40), shown, font=FONT_SMALL, fill=MUTED)
        origin_x = PAD + META_W
        board.paste(Image.fromarray(piece, "RGBA"), (origin_x, y), Image.fromarray(piece, "RGBA"))
        for slot in range(1, 3):
            left = origin_x + slot * (col_w + PAD)
            draw.rectangle((left, y, left + w - 1, y + h - 1), outline=LINE, fill=EMPTY)
        y += row_h + ROW_GAP
    args.out.parent.mkdir(parents=True, exist_ok=True)
    board.save(args.out)
    print(f"{number} hàng, {width}x{height} -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
