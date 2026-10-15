"""Bảng đăng ký hàm game của lớp B (src/client/face/gameapi, docs/giao-viec/LUA-GEN/TANG-B.md): mỗi hàm Lua mà Game.exe 2026
đăng ký (TAILIEU/GAME-EXE-2026/lua_api.tsv) thành một dòng {khoá, độ dài chủ, địa chỉ impl, trạng thái}, sinh vào
src/client/face/gameapi/api_rows.inc. Trạng thái:

    kPort     đã có bản C++: tên nằm trong một bảng `{"Chủ:Tên", &hàm}` ở src/client/face/gameapi/natives_*.cpp
    kEmpty    hàm "rỗng thật" của Game.exe (`xor eax,eax; ret`): chạy được, không làm gì, không trả giá trị
    kPending  chưa port: lúc chạy là hàm thay thế ghi log một lần rồi trả không giá trị

Nguồn sự thật về "đã port" là các bảng ở natives_*.cpp (bộ sinh đọc chúng); lua_api.tsv và classes.tsv là nguồn của mọi thứ
còn lại. Khoá: `Tên` cho hàm toàn cục, `Chủ:Tên` cho hàm của bảng toàn cục `Chủ` (cùng cách gọi tên của API-TAN-SUAT.tsv).
Hàm của bảng meta không có tên toàn cục (ActionButtonMetaTable...) thuộc tầng action, chưa vào bảng.

cách dùng (ở gốc dự án):
    python -B TOOLS/port/luagen/api_table.py            ghi api_rows.inc
    python -B TOOLS/port/luagen/api_table.py --check    thoát 1 khi api_rows.inc cũ hơn nguồn (ctest gameapi_table_fresh)
"""

from __future__ import annotations

import argparse
import csv
import dataclasses
import pathlib
import re
import sys

PROJECT = pathlib.Path(__file__).resolve().parents[3]
DUMP = PROJECT / "TAILIEU/GAME-EXE-2026"
MODULE = PROJECT / "src/client/face/gameapi"
OUTPUT = MODULE / "api_rows.inc"
# Hàm chuyển tiếp "ô ảo N" của ba bảng này nhảy tới ô ảo N của lớp SCRIPT_SANDBOX tương ứng; địa chỉ có nghĩa là của ô đó.
SCRIPT_CLASS = {
    "Player": "SCRIPT_SANDBOX::PlayerMySelf",
    "Target": "SCRIPT_SANDBOX::Character",
    "CachedTarget": "SCRIPT_SANDBOX::CachedCharacter",
}
FORWARD = re.compile(r"ô ảo (\d+)")
NATIVE_LINE = re.compile(r'^\s*\{"([A-Za-z0-9_:]+)",\s*&', re.M)
STATUS_NAME = {"port": "kPort", "empty": "kEmpty", "pending": "kPending"}


@dataclasses.dataclass(frozen=True)
class Row:
    key: str
    owner_length: int
    impl: int
    status: str


def read_tsv(path: pathlib.Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream, delimiter="\t"))


def native_keys() -> list[str]:
    """Khoá của mọi hàm đã port, theo thứ tự xuất hiện trong các natives_*.cpp."""
    keys: list[str] = []
    for path in sorted(MODULE.glob("natives_*.cpp")):
        keys.extend(NATIVE_LINE.findall(path.read_text(encoding="utf-8")))
    return keys


def build_rows() -> tuple[list[Row], int]:
    """Các dòng của bảng (đã xếp theo khoá) và số hàm của bảng meta không có tên toàn cục (bị bỏ)."""
    classes = {row["class"]: row["slots"].split(",") for row in read_tsv(DUMP / "classes.tsv")}
    listed = native_keys()
    ported = set(listed)
    duplicated = sorted(key for key in ported if listed.count(key) > 1)
    if duplicated:
        raise SystemExit(f"natives_*.cpp khai hai lần: {', '.join(duplicated)}")
    rows: dict[str, Row] = {}
    hidden = 0
    for source in read_tsv(DUMP / "lua_api.tsv"):
        if source["table"] == "(globals)":
            owners = [""]
        else:
            owners = [owner for owner in source["lua_globals"].split(",") if owner]
            if not owners:
                hidden += 1
                continue
        impl = int(source["impl"], 16)
        for owner in owners:
            slot = FORWARD.search(source["impl_kind"])
            if slot and owner in SCRIPT_CLASS:
                impl = int(classes[SCRIPT_CLASS[owner]][int(slot.group(1))], 16)
            key = f"{owner}:{source['name']}" if owner else source["name"]
            if not key.isascii():
                raise SystemExit(f"khoá không phải ASCII: {key}")
            if key in rows:
                raise SystemExit(f"lua_api.tsv đăng ký hai lần: {key}")
            if key in ported:
                status = "port"
            elif source["impl_kind"].startswith("rỗng: xor eax,eax"):
                status = "empty"
            else:
                status = "pending"
            rows[key] = Row(key, len(owner), impl, status)
    unknown = sorted(set(ported) - set(rows))
    if unknown:
        raise SystemExit(f"natives_*.cpp có khoá không có trong lua_api.tsv: {', '.join(unknown)}")
    owners_table = {row.key[:row.owner_length] for row in rows.values() if row.owner_length}
    clash = sorted(owners_table & {row.key for row in rows.values() if not row.owner_length})
    if clash:
        raise SystemExit(f"tên vừa là hàm toàn cục vừa là bảng toàn cục: {', '.join(clash)}")
    return [rows[key] for key in sorted(rows)], hidden


def render(rows: list[Row], hidden: int) -> str:
    counts = {name: sum(1 for row in rows if row.status == name) for name in STATUS_NAME}
    lines = [
        "// Sinh bằng TOOLS/port/luagen/api_table.py từ TAILIEU/GAME-EXE-2026/lua_api.tsv, classes.tsv và các bảng ở natives_*.cpp;",
        "// không sửa tay. Mỗi dòng: khoá (`Tên` hay `Chủ:Tên`), độ dài của `Chủ`, địa chỉ impl trong Game.exe 2026, trạng thái.",
        f"// {len(rows)} dòng: {counts['port']} đã port, {counts['empty']} rỗng thật, {counts['pending']} chưa port;"
        f" {hidden} hàm của bảng meta không có tên toàn cục chưa vào bảng.",
    ]
    for row in rows:
        lines.append(f'{{"{row.key}", {row.owner_length}, {row.impl:#x}, Status::{STATUS_NAME[row.status]}}},')
    return "\n".join(lines) + "\n"


def ported_names() -> set[str]:
    """Khoá chạy được không cần hàm thay thế: đã port hoặc rỗng thật (độ phủ của api_survey.py)."""
    rows, _ = build_rows()
    return {row.key for row in rows if row.status != "pending"}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="chỉ kiểm api_rows.inc có khớp nguồn không")
    args = parser.parse_args(argv)
    rows, hidden = build_rows()
    text = render(rows, hidden)
    if args.check:
        current = OUTPUT.read_bytes().decode("utf-8") if OUTPUT.is_file() else ""
        if current != text:
            print(f"{OUTPUT.relative_to(PROJECT)} cũ hơn nguồn: chạy python -B TOOLS/port/luagen/api_table.py", file=sys.stderr)
            return 1
        return 0
    OUTPUT.write_bytes(text.encode("utf-8"))
    print(text.splitlines()[2][3:])
    return 0


if __name__ == "__main__":
    sys.exit(main())
