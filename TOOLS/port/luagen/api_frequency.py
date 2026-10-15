"""Bảng tần suất cho lớp B của LUA-GEN (docs/giao-viec/LUA-GEN/THIET-KE.md): mỗi hàm của game và mỗi phương thức
widget mà script giao diện gọi, xếp theo số cửa sổ (đơn vị) gọi nó, rồi số lần gọi trong vết đối soát, rồi số chỗ gọi trong mã, kèm địa chỉ hàm C
của Game.exe 2026 (docs/TAILIEU/GAME-EXE-2026/lua_api.tsv). Thứ tự port lớp B là thứ tự của bảng này.

cách dùng (ở gốc dự án, sau mass_oracle.py):
    python -B TOOLS/port/luagen/api_frequency.py [--layouts <thư mục Interface của layout>]
        [--traces build/luagen/oracle] [--out docs/giao-viec/LUA-GEN/API-TAN-SUAT.tsv]

Loại:
    game    Đối_tượng:Hàm trên một bảng toàn cục mà Game.exe đăng ký (DataPool, Player...)
    global  hàm C toàn cục của Game.exe (PushEvent, OpenWindow...)
    widget  phương thức gọi trên `this` hay trên tên một cửa sổ của layout (lớp nối Lua của UI_CEGUI.dll)
    other   phương thức gọi trên giá trị khác (cửa sổ cất trong bảng, đối tượng action...): bên nhận chỉ biết lúc chạy
Chỗ gọi đếm bằng biểu thức chính quy trên mã đã bỏ chú thích và chuỗi; số lần gọi đếm trên vết của thế giới giả.
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import re
import sys
import xml.etree.ElementTree as ElementTree

import mass_units

API = mass_units.PROJECT / "docs/TAILIEU/GAME-EXE-2026/lua_api.tsv"
LONG_COMMENT = re.compile(r"--\[\[.*?\]\]", re.S)
LINE_COMMENT = re.compile(r"--[^\n]*")
STRING = re.compile(r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|\[\[.*?\]\]', re.S)
METHOD = re.compile(r"\b([A-Za-z_]\w*)\s*:\s*([A-Za-z_]\w*)\s*\(")
GLOBAL_CALL = re.compile(r"(?<![\w.:])([A-Za-z_]\w*)\s*\(")
COLUMNS = ("rank", "kind", "name", "trace_calls", "sites", "units", "impl", "source_file")


class Api:
    """lua_api.tsv: tên toàn cục của bảng → hàm có trong bảng đó; hàm C toàn cục."""

    def __init__(self, path: pathlib.Path) -> None:
        self.methods: dict[str, dict[str, tuple[str, str]]] = collections.defaultdict(dict)
        self.globals: dict[str, tuple[str, str]] = {}
        lines = path.read_text(encoding="utf-8").splitlines()
        header = lines[0].split("\t")
        for line in lines[1:]:
            row = dict(zip(header, line.split("\t")))
            where = (row.get("impl", ""), row.get("source_file", ""))
            if row["table"] == "(globals)":
                self.globals[row["name"]] = where
                continue
            for owner in filter(None, row.get("lua_globals", "").split(",")):
                self.methods[owner][row["name"]] = where


def plain(source: str) -> str:
    return LINE_COMMENT.sub("", STRING.sub('""', LONG_COMMENT.sub("", source)))


def window_names(layout_root: pathlib.Path) -> set[str]:
    names = {"this"}
    for layout in layout_root.glob("*/*.layout.xml"):
        try:
            names.update(item.get("Name", "") for item in ElementTree.parse(layout).getroot().iter("Window"))
        except ElementTree.ParseError as error:
            print(f"{layout}: bỏ, không đọc được: {error}", file=sys.stderr)
    names.discard("")
    return names


class Tally:
    def __init__(self, api: Api, windows: set[str]) -> None:
        self.api = api
        self.windows = windows
        self.sites: collections.Counter[tuple[str, str]] = collections.Counter()
        self.units: dict[tuple[str, str], set[str]] = collections.defaultdict(set)
        self.calls: collections.Counter[tuple[str, str]] = collections.Counter()

    def classify(self, owner: str, method: str) -> tuple[str, str]:
        if owner in self.api.methods and method in self.api.methods[owner]:
            return "game", f"{owner}:{method}"
        if owner in self.windows:
            return "widget", method
        return "other", method

    def scan(self, unit: str, source: str) -> None:
        text = plain(source)
        for owner, method in METHOD.findall(text):
            key = self.classify(owner, method)
            self.sites[key] += 1
            self.units[key].add(unit)
        for name in GLOBAL_CALL.findall(text):
            if name in self.api.globals:
                key = ("global", name)
                self.sites[key] += 1
                self.units[key].add(unit)

    def trace(self, path: pathlib.Path) -> None:
        for line in path.read_bytes().split(b"\n"):
            if not line.startswith(b"call\t"):
                continue
            name = line.split(b"\t", 2)[1].decode("utf-8", "replace")
            owner, dot, method = name.partition(".")
            if dot:
                self.calls[self.classify(owner, method)] += 1
            elif name in self.api.globals:
                self.calls[("global", name)] += 1

    def where(self, key: tuple[str, str]) -> tuple[str, str]:
        kind, name = key
        if kind == "global":
            return self.api.globals[name]
        if kind == "game":
            owner, _, method = name.partition(":")
            return self.api.methods[owner][method]
        return "", ""


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--layouts", type=pathlib.Path, default=mass_units.LAYOUT_ROOT)
    parser.add_argument("--traces", type=pathlib.Path, default=mass_units.PROJECT / "build/luagen/oracle")
    parser.add_argument("--out", type=pathlib.Path,
                        default=mass_units.PROJECT / "docs/giao-viec/LUA-GEN/API-TAN-SUAT.tsv")
    args = parser.parse_args(argv)
    if not args.traces.is_dir():
        print(f"không thấy {args.traces}: chạy mass_oracle.py trước", file=sys.stderr)
        return 2
    tally = Tally(Api(API), window_names(args.layouts))
    for unit in mass_units.units(layout_root=args.layouts):
        for chunk in unit.chunks:
            tally.scan(unit.name, chunk.source)
    for path in sorted(args.traces.glob("*.trace")):
        tally.trace(path)
    # Số cửa sổ dùng trước: port một hàm thì bấy nhiêu cửa sổ bớt một chỗ thiếu; số lần gọi trong vết lệch theo vòng
    # lặp của dữ liệu giả nên chỉ xếp sau.
    keys = sorted(set(tally.sites) | set(tally.calls),
                  key=lambda key: (-len(tally.units[key]), -tally.calls[key], -tally.sites[key], key))
    lines = ["# Sinh bằng TOOLS/port/luagen/api_frequency.py; không sửa tay", "\t".join(COLUMNS)]
    for rank, key in enumerate(keys, start=1):
        impl, source = tally.where(key)
        lines.append("\t".join(str(cell) for cell in (rank, key[0], key[1], tally.calls[key], tally.sites[key],
                                                       len(tally.units[key]), impl, source)))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    by_kind = collections.Counter(key[0] for key in keys)
    print(f"ghi {args.out}: {len(keys)} tên; theo loại: {dict(by_kind)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
