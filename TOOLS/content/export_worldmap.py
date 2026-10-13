# Ghép ảnh nền bản đồ thế giới (LargeMap) của client 2026 thành một ảnh PNG: <dữ liệu client>/Interface/LargeMap/
# WorldMap.png, để client tự viết nạp một texture thay vì 20 tệp DDS DXT1.
# Nguồn: FalagardWorldMap::createBackground (CEGUIFalagard.dll 0x18008b200): BackgroundName "WorldMap" và
# BackgroundSize w:5 h:4 (LargeMap.layout.xml) dựng lưới 5 cột 4 hàng các ô vuông 256 điểm ảnh (hằng 0x18013a820 =
# 256,0), ô thứ n (n chạy hàng này rồi hàng kế) đọc từ "LargeMap/jpg_WorldMap%02d.dds". Ảnh ghép rộng 1280, cao 1024,
# đúng toạ độ pixel mà cột 11..14 của Config/SceneDefineEx.txt dùng để đặt nút và nhãn thành phố.
# Chạy ở gốc dự án (cần Pillow):
#   python -B TOOLS/content/export_worldmap.py <dữ liệu client>            ghép rồi ghi
#   python -B TOOLS/content/export_worldmap.py <dữ liệu client> --check    chỉ kiểm tệp đã ghi còn khớp các ô
# Mã thoát: 0 khi xong hay khớp, 1 khi thiếu ô, ô sai cỡ hay tệp ghi lệch, 2 khi sai cách dùng.
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

COLUMNS = 5
ROWS = 4
TILE = 256
TARGET_DIR = ("Interface", "LargeMap")
OUTPUT = "WorldMap.png"


def tile_path(folder: Path, index: int) -> Path:
    return folder / f"jpg_WorldMap{index:02d}.dds"


def stitch(folder: Path) -> Image.Image:
    """Ghép 20 ô; thiếu ô hay ô khác cỡ 256 x 256 là lỗi (ValueError), không đoán."""
    whole = Image.new("RGB", (COLUMNS * TILE, ROWS * TILE))
    for index in range(COLUMNS * ROWS):
        path = tile_path(folder, index)
        if not path.is_file():
            raise ValueError(f"thiếu ô {path.name}")
        with Image.open(path) as tile:
            if tile.size != (TILE, TILE):
                raise ValueError(f"{path.name} cỡ {tile.size}, cần {TILE} x {TILE}")
            whole.paste(tile.convert("RGB"), ((index % COLUMNS) * TILE, (index // COLUMNS) * TILE))
    return whole


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Ghép ảnh nền bản đồ thế giới")
    parser.add_argument("data", help="thư mục dữ liệu client (chứa Interface/)")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm, không ghi")
    chosen = parser.parse_args(argv)
    folder = Path(chosen.data).joinpath(*TARGET_DIR)
    try:
        whole = stitch(folder)
    except (ValueError, OSError) as error:
        print(f"lỗi: {error}")
        return 1
    target = folder / OUTPUT
    if chosen.check:
        if not target.is_file():
            print(f"thiếu {target}")
            return 1
        with Image.open(target) as written:
            if written.convert("RGB").tobytes() != whole.tobytes():
                print(f"{target} lệch các ô DDS")
                return 1
        print(f"khớp: {target}")
        return 0
    # Ghi qua tệp tạm rồi đổi tên: ngắt giữa chừng không để lại ảnh dở.
    temporary = target.with_suffix(".tmp")
    whole.save(temporary, format="PNG")
    temporary.replace(target)
    with Image.open(target) as written:
        if written.convert("RGB").tobytes() != whole.tobytes():
            print(f"{target} đọc lại không khớp")
            return 1
    print(f"đã ghi {target} ({whole.width} x {whole.height})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
