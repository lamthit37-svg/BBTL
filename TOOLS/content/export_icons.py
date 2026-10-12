# Xuất bảng tra icon của client 2026 thành <dữ liệu client>/Table/icons.tsv: tên icon (ô icon của
# bảng kỹ năng, tâm pháp, kỹ năng sống...) sang bộ ảnh chứa nó, để client tự viết dựng tên đầy đủ
# "set:<bộ ảnh> image:<tên icon>" như CUIIconsManager của UI_CEGUI.dll (đọc từ mã máy,
# docs/NHIEM-VU-VO-CONG-2026.md): bảng dựng từ mọi bộ ảnh có Imagefile mở đầu bằng "Icons" (so đúng
# hoa thường), duyệt theo thứ tự map của CEGUI (tên bộ ngắn hơn đứng trước, cùng độ dài thì so byte
# của chuỗi UTF-32), và tên ảnh nằm ở nhiều bộ thuộc về bộ gặp trước.
# Nguồn: mọi *.imageset.xml của <_raw>/Interface, đọc bằng bộ nạp của collect_ui.py. Bộ icon chỉ được
# nằm trong Schema/all.imageset.xml: gặp ở tệp khác là lỗi (luật thứ tự nạp của tệp lẻ chưa đọc từ
# mã máy).
# Sau khi ghi, công cụ đọc lại tệp và so từng dòng với kho gốc. Chạy ở gốc dự án:
#   python -B TOOLS/content/export_icons.py <_raw> <dữ liệu client>            ghi rồi kiểm
#   python -B TOOLS/content/export_icons.py <_raw> <dữ liệu client> --check    chỉ kiểm, không ghi
# Mã thoát: 0 khi bảng khớp, 1 khi kho gốc hỏng hay bảng lệch, 2 khi sai cách dùng. Kho gốc không có
# icon nào cũng là hỏng (bảng 0 dòng không bao giờ được ghi, --check cũng từ chối nó); lỗi đĩa là một
# dòng LỖI mã 1.
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

import collect_ui
import export_config

TARGET = "icons.tsv"
ICON_PREFIX = "Icons"
NOTE = "Sinh bằng TOOLS/content/export_icons.py từ imageset của client 2026; sửa tay sẽ mất ở lượt sau"


class IconError(Exception):
    """Kho gốc không đọc được hay không có icon nào, tên không viết được thành TSV, tệp đích không
    ghi hay đọc lại được, hay tệp đã ghi lệch kho gốc."""


# Một bộ ảnh của kho gốc: tên, tệp ảnh, tệp imageset khai nó và tên các ảnh.
@dataclass(frozen=True)
class IconSet:
    name: str
    imagefile: str
    origin: str
    images: tuple[str, ...]


def cegui_order(name: str) -> tuple[int, bytes]:
    """Khoá sắp của map bộ ảnh trong CEGUI (FastLessCompare): độ dài rồi byte của chuỗi UTF-32."""
    return len(name), name.encode("utf-32-le")


def icon_owners(sets: list[IconSet]) -> dict[str, str]:
    """Tên icon sang tên bộ ảnh chứa nó; tên nằm ở nhiều bộ thuộc về bộ đứng trước theo cegui_order."""
    owners: dict[str, str] = {}
    for item in sorted(sets, key=lambda one: cegui_order(one.name)):
        if not item.imagefile.startswith(ICON_PREFIX):
            continue
        if item.origin != collect_ui.ALL_IMAGESET:
            raise IconError(f"bộ icon {item.name} nằm ở {item.origin}, ngoài {collect_ui.ALL_IMAGESET}")
        for image in item.images:
            owners.setdefault(image, item.name)
    return owners


def table_text(owners: dict[str, str]) -> str:
    """Nội dung icons.tsv: mỗi icon một dòng, xếp theo byte của tên."""
    lines = [f"# {NOTE}", f"# {len(owners)} icon của {len(set(owners.values()))} bộ ảnh", "icon\timageset"]
    for icon in sorted(owners, key=lambda name: name.encode("utf-8")):
        cells = (icon, owners[icon])
        if any(not cell or cell.startswith("#") or any(mark in cell for mark in "\t\n\r") for cell in cells):
            raise IconError(f"tên \"{icon}\" hay \"{owners[icon]}\" không viết được thành một ô TSV")
        lines.append("\t".join(cells))
    return "\n".join(lines) + "\n"


def verify(owners: dict[str, str], text: str) -> int:
    """So tệp đã ghi với owners; trả số dòng đã so. Lệch thì ném IconError nêu dòng đầu tiên."""
    rows = export_config.data_rows(text)
    if len(rows) != len(owners):
        raise IconError(f"{TARGET}: {len(rows)} dòng, kho gốc có {len(owners)} icon")
    for number, cells in enumerate(rows):
        if len(cells) != 2 or owners.get(cells[0]) != cells[1]:
            raise IconError(f"{TARGET}: dòng dữ liệu {number} lệch kho gốc: {cells}")
    if len({cells[0] for cells in rows}) != len(rows):
        raise IconError(f"{TARGET}: có tên icon lặp")
    return len(rows)


def read_sets(raw_root: Path) -> list[IconSet]:
    """Mọi bộ ảnh của kho gốc; tên bộ lặp thì giữ bộ gặp trước như collect_ui. Tệp hỏng hay không
    đọc được là IconError."""
    try:
        source = collect_ui.Source(str(raw_root))
        seen: dict[str, IconSet] = {}
        files = source.matching(".imageset.xml")
        files.sort(key=lambda relative: relative != collect_ui.ALL_IMAGESET)
        for relative in files:
            _, root = source.read_xml(relative)
            for element in ([root] if root.tag == "Imageset" else root.findall("Imageset")):
                one = collect_ui.read_imageset(element)
                seen.setdefault(one.name, IconSet(one.name, one.imagefile, relative, tuple(one.rects.items)))
    except collect_ui.UiError as error:
        raise IconError(str(error)) from error
    except OSError as error:
        raise IconError(f"không đọc được kho gốc: {error}") from error
    return list(seen.values())


def run(raw_root: Path, data_root: Path, is_check: bool) -> int:
    path = data_root / "Table" / TARGET
    try:
        owners = icon_owners(read_sets(raw_root))
        if not owners:
            raise IconError(f"{TARGET}: kho gốc không có icon nào; bảng 0 dòng không phải là bảng đúng")
        wanted = table_text(owners).encode("utf-8")
        is_written = False
        try:
            if is_check:
                if not path.is_file():
                    raise IconError(f"{TARGET}: chưa có trong {path.parent}")
                if path.read_bytes() != wanted:
                    raise IconError(f"{TARGET}: khác tệp sẽ sinh từ kho gốc; chạy lại không có --check")
            else:
                is_written = export_config.write_changed(path, wanted)
            written = path.read_bytes().decode("utf-8")
        except (OSError, UnicodeDecodeError) as error:
            raise IconError(f"{TARGET}: không ghi hay đọc lại được {path}: {error}") from error
        rows = verify(owners, written)
    except IconError as error:
        print(f"LỖI {error}", file=sys.stderr)
        return 1
    print(f"{TARGET}: {rows} icon khớp kho gốc ({'ghi mới' if is_written else 'giữ nguyên'})")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Xuất bảng tra icon của client 2026 thành Table/icons.tsv.")
    parser.add_argument("raw", type=Path, help="kho gốc đã giải gói (_raw)")
    parser.add_argument("data", type=Path, help="thư mục dữ liệu client (CLIENT/data)")
    parser.add_argument("--check", action="store_true", help="chỉ kiểm tệp đang có, không ghi")
    args = parser.parse_args(argv)
    if not (args.raw / collect_ui.INTERFACE).is_dir():
        print(f"không thấy {args.raw / collect_ui.INTERFACE}", file=sys.stderr)
        return 2
    return run(args.raw, args.data, args.check)


if __name__ == "__main__":
    sys.exit(main())
