#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/source_headers/source_headers.py
#  PHÂN HỆ   : Source Headers / Source Headers
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Kiểm và đưa comment đầu tệp của mọi tệp nguồn về một khung thống nhất theo
#    mẫu EngineHP (source_frame.py).
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Kiểm và đưa comment đầu tệp của mọi tệp nguồn về một khung thống nhất theo mẫu EngineHP (source_frame.py).

  python TOOLS/source_headers/source_headers.py                      kiểm mọi tệp trong phạm vi (chạy trong ctest: source_headers)
  python TOOLS/source_headers/source_headers.py <tệp...>             kiểm các tệp chỉ định
  python TOOLS/source_headers/source_headers.py --fix [tệp...]       ghi khung vào tệp chưa có (và dựng lại khung sai)
  python TOOLS/source_headers/source_headers.py --fix --describe m.json   m.json: {"đường/dẫn": ["ý 1", "ý 2"]}, ý cho tệp
                                                                     không có comment đầu tệp dùng được
  python TOOLS/source_headers/source_headers.py --survey [tệp...]    đếm tệp đã đúng, tự chuyển được, cần mô tả viết tay

Phạm vi: tệp git theo dõi mà profiles.profile_for nhận ra, trừ thư mục ngoại lệ ở EXCLUDED_PREFIXES; tệp .toml không thuộc phạm vi
KHÔNG nằm trong phạm vi: bố cục tiêu đề của chúng do lint_config.py giữ. --fix không sửa mã, chỉ thay phần comment đầu tệp; mọi từ của comment cũ còn lại.
Thoát 0 khi sạch, 1 khi có lỗi; mỗi lỗi một dòng "tệp: nội dung".
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

import legacy_box
import source_frame as frame
from extract import locate
from profiles import Profile, profile_for
from rewrite import Plan, rewrite

ROOT = Path(__file__).resolve().parents[2]
# Không đụng: mã bên thứ ba, dữ liệu, tài liệu, bản dựng, script Lua gốc của client 2026 (có MANIFEST băm), tệp sinh từ ngoài.
EXCLUDED_PREFIXES = (
    "third_party/", "build/", ".worktrees/", "docs/", "dev/client/assets/", "src/client/script/", "TAILIEU/", "assets/",
    "TOOLS/check/isystem/", "Test/golden/", "dev/server/scenes/", "dev/server/tables/", "dev/server/data/", "dev/server/sql/",
    "vcpkg_installed/", "release/",
)


def in_scope(path: str) -> bool:
    return not path.startswith(EXCLUDED_PREFIXES) and not path.endswith(".toml") and profile_for(path) is not None


def tracked_files(root: Path) -> list[str]:
    out = subprocess.run(["git", "ls-files", "-z"], cwd=root, check=True, capture_output=True).stdout
    return sorted(name for name in out.decode("utf-8").split("\0") if name and in_scope(name))


def relative(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


class Source:
    """Một tệp đã đọc: dòng (không xuống dòng), kiểu xuống dòng, BOM."""

    def __init__(self, data: bytes) -> None:
        text = data.decode("utf-8")
        self.bom = text.startswith("﻿")
        text = text.removeprefix("﻿")
        self.crlf = "\r\n" in text
        self.lines = text.replace("\r\n", "\n").split("\n")

    def encode(self, lines: list[str]) -> bytes:
        text = ("\r\n" if self.crlf else "\n").join(lines)
        return (("﻿" if self.bom else "") + text).encode("utf-8")


def check_source(source: Source, profile: Profile, path: str) -> list[str]:
    layout = locate(source.lines, profile, frame.border(profile.prefix), legacy_box.border(profile.prefix))
    if layout.legacy_at is not None:
        return ["khung hộp cũ (// +---): chạy --fix để đổi sang khung theo mẫu EngineHP"]
    if layout.frame_at is None:
        return ["thiếu khung ở đầu tệp (sau shebang và dòng khai bảng mã)"]
    problems: list[str] = []
    if layout.lead is not None:
        problems.append("dòng \"#pragma once\" (hay @echo off) đứng trước khung")
    parsed = frame.parse_frame(source.lines, layout.frame_at, profile.prefix, path)
    if parsed is None:
        return [*problems, "viền trên của khung sai"]
    return [*problems, *parsed.problems]


def check_file(root: Path, path: str) -> list[str]:
    profile = profile_for(path)
    full = root / path
    if profile is None or not full.is_file():
        return []
    try:
        source = Source(full.read_bytes())
    except UnicodeDecodeError as error:
        return [f"không phải UTF-8: {error}"]
    return check_source(source, profile, path)


def fix_file(root: Path, path: str, description: list[str] | None) -> tuple[str, Plan]:
    """(trạng thái, kế hoạch): "đổi", "giữ" hay "cần mô tả"; ghi tệp khi đổi."""
    profile = profile_for(path)
    full = root / path
    if profile is None or not full.is_file():
        return "giữ", Plan()
    source = Source(full.read_bytes())
    lines, plan = rewrite(source.lines, profile, path, description)
    if plan.needs_description:
        return "cần mô tả", plan
    if lines is None or lines == source.lines:
        return "giữ", plan
    full.write_bytes(source.encode(lines))
    return "đổi", plan


def survey(root: Path, paths: list[str], describe: dict[str, list[str]]) -> int:
    counts = {"đúng": 0, "tự chuyển": 0, "tự chuyển, còn comment dưới khung": 0, "cần mô tả": 0}
    needs: list[str] = []
    for path in paths:
        profile = profile_for(path)
        full = root / path
        if profile is None or not full.is_file():
            continue
        source = Source(full.read_bytes())
        lines, plan = rewrite(source.lines, profile, path, describe.get(path))
        if plan.needs_description:
            counts["cần mô tả"] += 1
            needs.append(f"{path}\t{plan.reason}")
        elif lines is None or lines == source.lines:
            counts["đúng"] += 1
        else:
            counts["tự chuyển, còn comment dưới khung" if plan.remainder else "tự chuyển"] += 1
    print(json.dumps(counts, ensure_ascii=False))
    print("\n".join(needs))
    return 0


def read_descriptions(argument: str | None) -> dict[str, list[str]]:
    if not argument:
        return {}
    data = json.loads(Path(argument).read_text(encoding="utf-8"))
    return {name: [str(item) for item in items] for name, items in data.items()}


def parse_arguments(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Kiểm và ghi khung hộp ở đầu tệp nguồn.")
    parser.add_argument("paths", nargs="*", help="tệp (đường dẫn từ gốc repo hoặc tuyệt đối); bỏ trống là cả phạm vi")
    parser.add_argument("--fix", action="store_true", help="ghi khung")
    parser.add_argument("--survey", action="store_true", help="chỉ đếm, không ghi")
    parser.add_argument("--describe", help="tệp JSON {đường dẫn: [các ý]} cho tệp không có comment đầu tệp")
    return parser.parse_args(argv)


def selected(root: Path, paths: list[str]) -> list[str]:
    """Tệp cần xử lý: cả phạm vi khi không chỉ định, còn không thì các tệp chỉ định nằm trong phạm vi (tệp ngoài phạm vi bị bỏ, có báo)."""
    if not paths:
        return tracked_files(root)
    names = sorted(relative(Path(name).absolute() if Path(name).is_absolute() else root / name, root) for name in paths)
    for name in names:
        if not in_scope(name):
            print(f"{name}: ngoài phạm vi, bỏ qua")
    return [name for name in names if in_scope(name)]


def main(argv: list[str]) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = parse_arguments(argv)
    paths = selected(ROOT, args.paths)
    describe = read_descriptions(args.describe)
    if args.survey:
        return survey(ROOT, paths, describe)
    failures = 0
    if args.fix:
        for path in paths:
            status, plan = fix_file(ROOT, path, describe.get(path))
            if status == "cần mô tả":
                print(f"{path}: cần mô tả viết tay: {plan.reason}")
                failures += 1
    for path in paths:
        for problem in check_file(ROOT, path):
            print(f"{path}: {problem}")
            failures += 1
    if failures:
        print(f"{failures} lỗi trong {len(paths)} tệp")
        return 1
    print(f"{len(paths)} tệp có khung đúng ({frame.COLUMNS} cột, tối đa {frame.MAX_LINES} dòng)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
