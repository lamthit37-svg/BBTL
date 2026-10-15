#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/server/gen_protocol.py
#  PHÂN HỆ   : Server / Gen Protocol
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Sinh mã giao thức từ bốn bảng src/shared/protocol/catalog/*.tsv (DE-BAI
#    P2-DOT-2 §3.5): messages.hpp và messages.cpp, mẫu cho test, tài liệu tin.
#    Bảng sai một luật G1–G11 thì in mọi lỗi và không ghi gì.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Cách chạy: python -B TOOLS/server/gen_protocol.py [--catalog DIR] [--out DIR] [--check]

--catalog  thư mục bốn bảng, mặc định src/shared/protocol/catalog
--out      gốc nơi ghi bốn tệp sinh (giữ đường dẫn tương đối), mặc định gốc repo
--check    không ghi; tệp nào khác nội dung sẽ sinh thì in tên và trả 1

Mã thoát: 0 xong, 1 bảng lỗi hoặc tệp sinh đã cũ, 2 sai cách gọi.
"""

from __future__ import annotations

import argparse
import sys
from collections.abc import Callable
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "source_headers"))

import source_frame  # noqa: E402  (TOOLS/source_headers, đường dẫn thêm ngay trên)
from protocol_cpp_hpp import render_header
from protocol_cpp_src import render_source
from protocol_doc import render_doc
from protocol_model import Catalog
from protocol_rules import build_catalog
from protocol_samples import render_samples
from protocol_tsv import Problems, read_catalog_tables

ROOT = Path(__file__).resolve().parents[2]
RENDERERS: tuple[tuple[str, Callable[[Catalog], str]], ...] = (
    ("src/shared/protocol/messages.hpp", render_header),
    ("src/shared/protocol/messages.cpp", render_source),
    ("Test/Protocol/protocol_samples.hpp", render_samples),
    ("docs/PROTOCOL-TIN.md", render_doc),
)


class CatalogError(Exception):
    """Bảng vi phạm luật; lines là các dòng lỗi đã xếp theo tệp rồi dòng."""

    def __init__(self, lines: list[str]) -> None:
        super().__init__("\n".join(lines))
        self.lines = lines


def load_catalog(directory: Path) -> Catalog:
    """Đọc và kiểm bốn bảng; lỗi thì ném CatalogError."""
    problems = Problems()
    tables = read_catalog_tables(directory, ROOT, problems)
    catalog = None if problems else build_catalog(tables, problems)
    if catalog is None or problems:
        raise CatalogError(problems.lines())
    return catalog


FRAMED = ("src/shared/protocol/messages.hpp", "src/shared/protocol/messages.cpp", "Test/Protocol/protocol_samples.hpp")


def with_frame(name: str, text: str) -> str:
    """Thay khối comment `//` đầu tệp sinh bằng khung đầu tệp của dự án (TOOLS/source_headers).

    Các dòng NOTICE của protocol_cxx thành ý đầu, phần mô tả vai trò của tệp thành ý sau; kiểm của
    source_headers và protocol_catalog_fresh thấy cùng một khung vì khung đến từ chính bộ sinh.
    """
    lines = text.split(chr(10))
    count = 0
    while count < len(lines) and lines[count].startswith("// "):
        count += 1
    notice, role = lines[:2], lines[2:count]
    items = [
        "Tệp sinh bởi gen_protocol.py từ các bảng .tsv trong catalog/; không sửa tay.",
        "Sửa bảng rồi chạy: python -B TOOLS/server/gen_protocol.py",
        " ".join(line.removeprefix("// ") for line in role),
    ]
    if len(notice) != 2 or not role:
        raise ValueError(f"{name}: đầu tệp sinh không có hai dòng NOTICE và dòng mô tả")
    frame = source_frame.render_frame("//", name, items)
    return chr(10).join([*frame, "", *lines[count:]])


def render_all(catalog: Catalog) -> dict[str, str]:
    files = {name: render(catalog) for name, render in RENDERERS}
    return {name: with_frame(name, text) if name in FRAMED else text for name, text in files.items()}


def stale_files(out: Path, files: dict[str, str]) -> list[str]:
    """Tệp thiếu hoặc khác từng byte so với nội dung sẽ sinh."""
    stale: list[str] = []
    for name, text in files.items():
        path = out / name
        if not path.is_file() or path.read_bytes() != text.encode("utf-8"):
            stale.append(name)
    return stale


def write_files(out: Path, files: dict[str, str]) -> None:
    """Ghi LF, UTF-8 không BOM; tệp đã đúng thì không chạm để giữ mtime cho hệ build."""
    for name in stale_files(out, files):
        path = out / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(files[name].encode("utf-8"))


def parse_arguments(argv: list[str]) -> argparse.Namespace | int:
    """Tham số đã đọc, hoặc mã thoát khi argparse dừng (0 cho --help, 2 cho sai cách gọi)."""
    parser = argparse.ArgumentParser(prog="gen_protocol.py", description="Sinh mã giao thức từ catalog/*.tsv.")
    parser.add_argument("--catalog", type=Path, default=ROOT / "src" / "shared" / "protocol" / "catalog")
    parser.add_argument("--out", type=Path, default=ROOT)
    parser.add_argument("--check", action="store_true")
    try:
        return parser.parse_args(argv)
    except SystemExit as stop:
        return 0 if stop.code == 0 else 2


def main(argv: list[str] | None = None) -> int:
    arguments = parse_arguments(sys.argv[1:] if argv is None else argv)
    if isinstance(arguments, int):
        return arguments
    try:
        catalog = load_catalog(arguments.catalog)
    except CatalogError as error:
        for line in error.lines:
            print(line, file=sys.stderr)
        print(f"{len(error.lines)} lỗi; không ghi tệp nào.", file=sys.stderr)
        return 1
    files = render_all(catalog)
    if arguments.check:
        stale = stale_files(arguments.out, files)
        for name in stale:
            print(f"cũ: {name}", file=sys.stderr)
        if stale:
            print(f"Chạy lại: python -B TOOLS/server/gen_protocol.py ({len(stale)} tệp cũ).", file=sys.stderr)
        return 1 if stale else 0
    write_files(arguments.out, files)
    return 0


if __name__ == "__main__":
    sys.exit(main())
