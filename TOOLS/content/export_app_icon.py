#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/export_app_icon.py
#  PHÂN HỆ   : Content / Export App Icon
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Xuất icon ứng dụng của Game.exe 2026 (RT_GROUP_ICON 107 và 108, cùng một bộ ảnh) ra
#    assets/icon1.ico, assets/icon2.ico (PC), android/res/mipmap-*/ic_launcher.png và
#    apple/icons/AppIcon*.png.
#  - Ảnh trong .ico là byte nguyên của RT_ICON; PNG cho điện thoại là cùng ảnh đó, 48 điểm lấy
#    nguyên bản, các cỡ khác thu từ ảnh 256 điểm. Ảnh iOS dán lên nền đen vì App Store cấm alpha.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

# Cách dùng, chạy ở gốc dự án:
#   py -B TOOLS/content/export_app_icon.py <Game.exe>            ghi rồi kiểm
#   py -B TOOLS/content/export_app_icon.py <Game.exe> --check    chỉ kiểm, không ghi
# Mã thoát: 0 khi khớp, 1 khi exe hỏng hay tệp lệch, 2 khi sai cách dùng. Thư viện: Pillow.

from __future__ import annotations

import argparse
import struct
import sys
from io import BytesIO
from pathlib import Path

from export_cursors import CursorError, Resources
from PIL import Image

RT_ICON = 3
RT_GROUP_ICON = 14
# Hai nhóm của exe; cả hai mang cùng bộ ảnh. app.rc đặt chúng làm icon 1 (cửa sổ, kích thước lớn)
# và icon 2 (thanh tiêu đề) như window.cpp nạp.
PC_ICONS = {"assets/icon1.ico": 107, "assets/icon2.ico": 108}
ANDROID_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
APPLE_SIZES = {
    "AppIcon60x60@2x.png": 120,
    "AppIcon60x60@3x.png": 180,
    "AppIcon76x76@2x.png": 152,
    "AppIcon83.5x83.5@2x.png": 167,
}
NATIVE_EDGE = 48
SOURCE_EDGE = 256


def group_entries(resources: Resources, group_id: int) -> list[tuple[bytes, bytes]]:
    """(8 byte đầu của mục thư mục: rộng, cao, màu, planes, bit; ảnh) của nhóm, theo thứ tự nhóm."""
    group = resources.items.get((RT_GROUP_ICON, group_id))
    if group is None:
        raise CursorError(f"exe không có RT_GROUP_ICON {group_id}")
    reserved, kind, count = struct.unpack_from("<HHH", group, 0)
    if kind != 1 or 6 + 14 * count > len(group):
        raise CursorError(f"RT_GROUP_ICON {group_id} sai dạng")
    found = []
    for index in range(count):
        row = 6 + 14 * index
        icon_id = struct.unpack_from("<H", group, row + 12)[0]
        image = resources.items.get((RT_ICON, icon_id))
        if image is None:
            raise CursorError(f"nhóm {group_id} trỏ tới RT_ICON {icon_id} mà exe không có")
        found.append((group[row:row + 8], image))
    return found


def ico_bytes(entries: list[tuple[bytes, bytes]]) -> bytes:
    offset = 6 + 16 * len(entries)
    head = struct.pack("<HHH", 0, 1, len(entries))
    directory = b""
    body = b""
    for fields, image in entries:
        directory += fields + struct.pack("<II", len(image), offset)
        body += image
        offset += len(image)
    return head + directory + body


def pictures_of(ico: bytes) -> dict[int, Image.Image]:
    opened = Image.open(BytesIO(ico))
    sizes = sorted(opened.info.get("sizes", []))
    return {edge: opened.ico.getimage((edge, edge)).convert("RGBA") for edge, _ in sizes}


def scaled(pictures: dict[int, Image.Image], edge: int) -> Image.Image:
    native = pictures.get(edge) if edge == NATIVE_EDGE else None
    if native is not None:
        return native
    return pictures[SOURCE_EDGE].resize((edge, edge), Image.LANCZOS)


def flat_on_black(picture: Image.Image) -> Image.Image:
    base = Image.new("RGBA", picture.size, (0, 0, 0, 255))
    base.alpha_composite(picture)
    return base.convert("RGB")


def png_bytes(picture: Image.Image) -> bytes:
    out = BytesIO()
    picture.save(out, format="PNG")
    return out.getvalue()


def wanted_files(exe: Path) -> dict[str, bytes]:
    resources = Resources(exe.read_bytes())
    files: dict[str, bytes] = {}
    for name, group_id in PC_ICONS.items():
        files[name] = ico_bytes(group_entries(resources, group_id))
    pictures = pictures_of(files["assets/icon1.ico"])
    if SOURCE_EDGE not in pictures or NATIVE_EDGE not in pictures:
        raise CursorError(f"nhóm icon thiếu ảnh {SOURCE_EDGE} hay {NATIVE_EDGE} điểm")
    for density, edge in ANDROID_SIZES.items():
        files[f"android/res/mipmap-{density}/ic_launcher.png"] = png_bytes(scaled(pictures, edge))
    for name, edge in APPLE_SIZES.items():
        files[f"apple/icons/{name}"] = png_bytes(flat_on_black(scaled(pictures, edge)))
    return files


def pixels_equal(left: bytes, right: bytes) -> bool:
    first = Image.open(BytesIO(left)).convert("RGBA")
    second = Image.open(BytesIO(right)).convert("RGBA")
    return first.size == second.size and first.tobytes() == second.tobytes()


def differs(name: str, current: bytes, wanted: bytes) -> bool:
    if name.endswith(".png"):
        return not pixels_equal(current, wanted)
    return current != wanted


def run(exe: Path, only_check: bool) -> int:
    files = wanted_files(exe)
    bad = 0
    for name, wanted in files.items():
        path = Path(name)
        current = path.read_bytes() if path.is_file() else None
        if current is not None and not differs(name, current, wanted):
            continue
        bad += 1
        print(f"{'lệch' if current is not None else 'thiếu'}: {name}")
        if only_check:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(wanted)
    print(f"icon ứng dụng: {len(files)} tệp, {bad} {'lệch' if only_check else 'đã ghi'}")
    return 1 if bad and only_check else 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Xuất icon ứng dụng của Game.exe 2026")
    parser.add_argument("exe", type=Path, help="Game.exe của client 2026")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm, không ghi")
    args = parser.parse_args(argv)
    try:
        return run(args.exe, args.check)
    except (CursorError, OSError) as failure:
        print(f"export_app_icon: {failure}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
