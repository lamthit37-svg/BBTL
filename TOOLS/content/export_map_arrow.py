# Đổi tấm mũi tên người chơi của minimap (Interface/Common/tga_MiniMap_Arrow.dds, imageset MiniMap_Arrow: 30 khung 32 x 32
# xếp 8 cột) thành PNG RGBA cạnh nó: <dữ liệu client>/Interface/Common/MiniMap_Arrow.png. Client ghép tấm này cùng ảnh
# chùm sáng vào một texture lớp phủ (ui/radar.hpp build_overlay) để nền, chùm sáng, mũi tên chỉ tốn hai lệnh vẽ; DDS nén
# khối (và ASTC, ETC2 trên điện thoại) không ghép được ở CPU nên cần bản PNG. Giữ nguyên cỡ 256 x 128 và toạ độ khung của
# imageset.
# Chạy ở gốc dự án (cần Pillow):
#   python -B TOOLS/content/export_map_arrow.py <dữ liệu client>            đổi rồi ghi
#   python -B TOOLS/content/export_map_arrow.py <dữ liệu client> --check    chỉ kiểm tệp đã ghi còn khớp nguồn
# Mã thoát: 0 khi xong hay khớp, 1 khi thiếu nguồn, ảnh sai cỡ hay tệp ghi lệch, 2 khi sai cách dùng.
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

SOURCE = ("Interface", "Common", "tga_MiniMap_Arrow.dds")
TARGET = ("Interface", "Common", "MiniMap_Arrow.png")
SIZE = (256, 128)


def load(data: Path) -> Image.Image:
    """Đọc tấm mũi tên thành RGBA; thiếu tệp hay khác cỡ 256 x 128 là lỗi (ValueError), không đoán."""
    path = data.joinpath(*SOURCE)
    if not path.is_file():
        raise ValueError(f"thiếu {path}")
    with Image.open(path) as source:
        if source.size != SIZE:
            raise ValueError(f"{path.name} cỡ {source.size}, cần {SIZE[0]} x {SIZE[1]}")
        return source.convert("RGBA")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Đổi tấm mũi tên người chơi của minimap sang PNG")
    parser.add_argument("data", help="thư mục dữ liệu client (chứa Interface/)")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm, không ghi")
    chosen = parser.parse_args(argv)
    try:
        sheet = load(Path(chosen.data))
    except (ValueError, OSError) as error:
        print(f"lỗi: {error}")
        return 1
    target = Path(chosen.data).joinpath(*TARGET)
    if chosen.check:
        if not target.is_file():
            print(f"thiếu {target}")
            return 1
        with Image.open(target) as written:
            same = written.convert("RGBA").tobytes() == sheet.tobytes()
        print("khớp" if same else f"{target} lệch nguồn")
        return 0 if same else 1
    target.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(target, optimize=True)
    print(f"đã ghi {target} ({SIZE[0]} x {SIZE[1]})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
