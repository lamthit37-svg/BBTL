# Đổi ảnh chùm sáng hướng nhìn của minimap (Material/MapSearchLight.tga của client 2026) thành PNG: <dữ liệu client>/
# Interface/Common/MapSearchLight.png, để client tự viết nạp thẳng một texture.
# Nguồn: UI_CEGUI.dll UISystem 0x18006a530 nạp "MapSearchLight.tga" (nhóm General) thành imageset "MapLight_RenderTexture"
# ảnh "View"; FalagardSceneMap::CreateSceneMap (CEGUIFalagard.dll 0x1800c58d0) dựng cửa sổ "<tên>_Auto_MapLight" mang ảnh đó,
# UpdateFlag (UI_CEGUI 0x18003de10) xoay nó theo hướng camera. Ảnh 128 x 128, chóp ở tâm và mở xuống (nam, +z).
# TGA gốc dưới-trái (mô tả 0x08): Pillow đọc đúng chiều, không lật tay.
# Chạy ở gốc dự án (cần Pillow):
#   python -B TOOLS/content/export_map_light.py <_raw> <dữ liệu client>            đổi rồi ghi
#   python -B TOOLS/content/export_map_light.py <_raw> <dữ liệu client> --check    chỉ kiểm tệp đã ghi còn khớp nguồn
# Mã thoát: 0 khi xong hay khớp, 1 khi thiếu nguồn, ảnh sai cỡ hay tệp ghi lệch, 2 khi sai cách dùng.
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

SOURCE = ("Material", "MapSearchLight.tga")
TARGET = ("Interface", "Common", "MapSearchLight.png")
SIZE = (128, 128)


def load(raw: Path) -> Image.Image:
    """Đọc ảnh nguồn thành RGBA; thiếu tệp hay khác cỡ 128 x 128 là lỗi (ValueError), không đoán."""
    path = raw.joinpath(*SOURCE)
    if not path.is_file():
        raise ValueError(f"thiếu {path}")
    with Image.open(path) as source:
        if source.size != SIZE:
            raise ValueError(f"{path.name} cỡ {source.size}, cần {SIZE[0]} x {SIZE[1]}")
        return source.convert("RGBA")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Đổi ảnh chùm sáng hướng nhìn của minimap sang PNG")
    parser.add_argument("raw", help="thư mục dữ liệu gốc (chứa Material/)")
    parser.add_argument("data", help="thư mục dữ liệu client (chứa Interface/)")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm, không ghi")
    chosen = parser.parse_args(argv)
    try:
        light = load(Path(chosen.raw))
    except (ValueError, OSError) as error:
        print(f"lỗi: {error}")
        return 1
    target = Path(chosen.data).joinpath(*TARGET)
    if chosen.check:
        if not target.is_file():
            print(f"thiếu {target}")
            return 1
        with Image.open(target) as written:
            same = written.convert("RGBA").tobytes() == light.tobytes()
        print("khớp" if same else f"{target} lệch nguồn")
        return 0 if same else 1
    target.parent.mkdir(parents=True, exist_ok=True)
    light.save(target, optimize=True)
    print(f"đã ghi {target} ({SIZE[0]} x {SIZE[1]})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
