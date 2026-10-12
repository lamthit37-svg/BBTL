# Dựng lại mọi atlas giao diện từ board.png theo đúng ô trong assets/ui/sheet.
# Toạ độ XPos/YPos là của tệp gốc, không xếp lại.
#   python -B TOOLS/content/restore_ui_atlases.py
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pack_ui_kinds import kind_of
from pack_ui_sheet import cells_of

SECTION_ORDER = ("ui", "button", "icon", "label")
META_W = 210
PAD = 18
ROW_GAP = 10
ROOT = Path(__file__).resolve().parents[2]
SHEETS = ROOT / "assets" / "ui" / "sheet"
BOARD = ROOT / "assets" / "ui" / "board.png"
INTERFACE = ROOT / "assets" / "client" / "Interface"
OUT = INTERFACE / "Schema" / "all.imageset.xml"


def board_rows() -> list[tuple[int, str, int, int, str, int, int]]:
    rows = []
    for rel, name, x, y, width, height in cells_of(SHEETS):
        if width <= 0 or height <= 0:
            continue
        atlas = Path(rel).stem
        rows.append((kind_of(name, atlas, width, height), name, width, height, rel, x, y))
    rows.sort(key=lambda item: (SECTION_ORDER.index(item[0]), item[1]))
    cursor = 78
    last = ""
    placed = []
    for kind, name, width, height, rel, x, y in rows:
        if kind != last:
            cursor += 36
            last = kind
        placed.append((cursor, name, width, height, rel.replace("\\", "/"), x, y))
        cursor += max(height, 58) + ROW_GAP
    return placed


def ensure_png(rel: str, pieces: list[tuple[int, str, int, int, int, int]], board: Image.Image) -> None:
    target = INTERFACE / rel
    png = Path(str(target) + ".png")
    if png.exists():
        return
    if target.exists():
        Image.open(target).convert("RGBA").save(png)
        return
    max_x = max(item[4] + item[2] for item in pieces)
    max_y = max(item[5] + item[3] for item in pieces)
    atlas = Image.new("RGBA", (max_x, max_y), (0, 0, 0, 0))
    for top, _name, width, height, x, y in pieces:
        piece = board.crop((PAD + META_W, top, PAD + META_W + width, top + height))
        atlas.paste(piece, (x, y))
    png.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(png)


def xml_text(groups: dict[str, list[tuple[str, int, int, int, int]]], files: dict[str, str]) -> str:
    lines = ['<?xml version="1.0" ?>', "<allImageset>"]
    for name in sorted(groups):
        lines.append(f'  <Imageset Name="{name}" Imagefile="{files[name]}">')
        seen: set[str] = set()
        for image, x, y, width, height in groups[name]:
            if image in seen:
                continue
            seen.add(image)
            lines.append(
                f'    <Image Name="{image}" XPos="{x}" YPos="{y}" Width="{width}" Height="{height}" />'
            )
        lines.append("  </Imageset>")
    lines.append("</allImageset>")
    return "\n".join(lines) + "\n"


def main() -> int:
    placed = board_rows()
    by_file: dict[str, list[tuple[int, str, int, int, int, int]]] = {}
    groups: dict[str, list[tuple[str, int, int, int, int]]] = {}
    files: dict[str, str] = {}
    for top, name, width, height, rel, x, y in placed:
        by_file.setdefault(rel, []).append((top, name, width, height, x, y))
        set_name = Path(rel).stem
        if set_name.startswith("tga_") or set_name.startswith("png_"):
            set_name = set_name.split("_", 1)[1]
        sheet = SHEETS / f"{Path(rel).stem}.tsv"
        if not sheet.exists():
            sheet = SHEETS / f"{set_name}.tsv"
        set_name = sheet.stem if sheet.exists() else set_name
        groups.setdefault(set_name, []).append((name, x, y, width, height))
        files[set_name] = rel
    board = Image.open(BOARD).convert("RGBA")
    for rel, pieces in by_file.items():
        ensure_png(rel, pieces, board)
    # Ảnh khai trong imageset lẻ mà sheet không có, giữ nguyên ô của tệp đó.
    for extra in sorted(INTERFACE.rglob("*.imageset.xml")):
        if extra.name.lower() == "all.imageset.xml":
            continue
        # Bộ đọc XML của client nhận thuộc tính hoa thường; ở đây chỉ cần tên và ô.
        raw = extra.read_text(encoding="utf-8")
        set_name = ""
        imagefile = ""
        for line in raw.splitlines():
            if "Imageset Name=" in line or "<Imageset " in line:
                name_at = line.find('Name="')
                file_at = line.find('Imagefile="')
                if name_at >= 0:
                    set_name = line[name_at + 6 :].split('"', 1)[0]
                if file_at >= 0:
                    imagefile = line[file_at + 11 :].split('"', 1)[0]
            if "<Image " not in line or not set_name:
                continue
            def attr(key: str) -> str:
                token = f'{key}="'
                at = line.find(token)
                if at < 0:
                    return "0"
                return line[at + len(token) :].split('"', 1)[0]
            image = attr("Name")
            if image == "0":
                continue
            known = {item[0] for item in groups.get(set_name, [])}
            if image in known:
                continue
            groups.setdefault(set_name, []).append(
                (image, int(attr("XPos")), int(attr("YPos")), int(attr("Width")), int(attr("Height")))
            )
            files.setdefault(set_name, imagefile.replace("\\", "/"))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(xml_text(groups, files), encoding="utf-8")
    print(f"{len(groups)} bộ ảnh, {sum(len(items) for items in groups.values())} ô -> {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
