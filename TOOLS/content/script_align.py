# Căn cột thẳng script Lua của client 2026 để đọc cho dễ: dấu `=` của các dòng gán liền nhau và chú thích
# cuối dòng (`-- ...`) của các dòng mã liền nhau. Chỉ đổi khoảng trắng nằm NGOÀI chuỗi và chú thích dài,
# nên chương trình không đổi: với `--luaplus` công cụ biên dịch (không chạy) bản gốc và bản đã căn bằng
# LuaPlus.dll của client rồi so từng byte mã trung gian (hằng số, chuỗi, số dòng đều nằm trong đó).
# Tác giả script căn bằng tab, độ rộng tab tuỳ trình soạn nên cột lệch; công cụ này căn bằng dấu cách, tính
# độ rộng theo ô hiển thị (chữ Hán chiếm 2 ô). Thụt đầu dòng giữ nguyên, nhóm chỉ gồm các dòng liền nhau
# cùng thụt lề, nên cột đúng với mọi cỡ tab.
# Luật:
#   - Dòng gán: `lhs = rhs`, `=` đầu tiên ở ngoài ngoặc và ngoài chuỗi (không phải `==`, `~=`, `<=`, `>=`);
#     lhs chỉ gồm tên, dấu chấm, phẩy, `[...]` và `local` ở đầu; không phải từ khoá.
#   - Nhóm = dòng gán liền nhau cùng thụt lề. `=` thẳng cột theo lhs dài nhất (bỏ lhs dài quá 40 ô khỏi phép tính),
#     một dấu cách hai bên.
#   - Khối = dòng mã liền nhau cùng thụt lề. Khối có từ hai dòng có chú thích cuối dòng thì chú thích thẳng cột
#     (mã dài quá 64 ô khỏi phép tính, dòng ấy cách đúng 2 dấu cách).
#   - Dòng nằm trong hay chạm chuỗi dài `[[...]]`, chú thích dài `--[[...]]` hay chuỗi nối dòng bằng `\` giữ
#     nguyên byte, vì khoảng trắng trong đó là dữ liệu. Lexer theo Lua 5.0 (LuaPlus): chuỗi dài lồng được.
#   - Dòng có tab trong phần mã (ngoài khoảng quanh `=`) không vào phép tính độ rộng, giữ nguyên.
# Không có chế độ sửa tại chỗ: đọc từ một cây, ghi sang thư mục khác.
#   python TOOLS/content/script_align.py <cây UTF-8> <thư mục đích> [--luaplus <Bin64>] [--overwrite]
import argparse
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

KEYWORDS = frozenset(
    "and break do else elseif end false for function if in local nil not or repeat return then true until while".split())
EQ_LHS_CAP = 40
COMMENT_CODE_CAP = 64
COMMENT_GAP = 2
LHS_CHARS = re.compile(r"[A-Za-z0-9_.,\s]*")
WORD = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
BRACKETS = re.compile(r"\[[^\]]*\]")
CODE = ("code", 0)
State = tuple[str, int]


@dataclass
class Scan:
    eq: int | None
    comment: int | None
    protected: bool


def display_width(text: str) -> int:
    """Số ô hiển thị trong phông đơn cách: chữ Hán và dạng toàn chiều 2 ô, dấu kết hợp 0 ô."""
    return sum(
        0 if unicodedata.combining(ch) else 2 if unicodedata.east_asian_width(ch) in "WF" else 1 for ch in text)


def scan_line(line: str, state: State) -> tuple[Scan, State]:
    """Quét một dòng (không có CR) theo lexer Lua 5.0. Trả vị trí `=` gán đầu tiên ở độ sâu ngoặc 0, vị trí
    chú thích ngắn `--`, cờ "dòng phải giữ nguyên" và trạng thái dòng sau."""
    mode, arg = state
    protected = mode != "code"
    length = len(line)
    i = 0
    depth = 0
    eq = comment = None
    continued = False
    while i < length:
        ch = line[i]
        if mode == "long":
            i += 1
            if ch == "[":
                if i < length and line[i] == "[":
                    arg += 1
                    i += 1
            elif ch == "]" and i < length and line[i] == "]":
                i += 1
                if arg == 0:
                    mode = "code"
                else:
                    arg -= 1
        elif mode == "str":
            if ch == "\\":
                if i + 1 >= length:
                    continued = True
                i += 2
            else:
                if ord(ch) == arg:
                    mode = "code"
                i += 1
        elif ch in "\"'":
            mode, arg = "str", ord(ch)
            continued = False
            i += 1
        elif line.startswith("--", i):
            if line.startswith("--[[", i):
                protected = True
                mode, arg = "long", 0
                i += 4
            else:
                comment = i
                break
        elif line.startswith("[[", i):
            protected = True
            mode, arg = "long", 0
            i += 2
        else:
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
            elif ch == "=" and eq is None and depth == 0 and (i == 0 or line[i - 1] not in "=~<>") \
                    and not line.startswith("==", i):
                eq = i
            i += 1
    if mode == "str" and not continued:
        protected = True
        mode = "code"
    if mode != "code":
        protected = True
    return Scan(eq, comment, protected), (mode, arg)


def is_assignment_lhs(lhs: str) -> bool:
    if not lhs or "\t" in lhs:
        return False
    cleaned = BRACKETS.sub("", lhs)
    if not LHS_CHARS.fullmatch(cleaned) or not (lhs[0].isalpha() or lhs[0] in "_["):
        return False
    words = WORD.findall(cleaned)
    return all(word not in KEYWORDS or (word == "local" and index == 0) for index, word in enumerate(words))


@dataclass
class Row:
    line: str
    kind: str = "keep"        # keep: giữ nguyên | code | assign
    indent: str = ""
    lhs: str = ""
    code: str = ""
    gap: str = ""             # khoảng trắng nguyên văn giữa mã và chú thích
    comment: str = ""
    cr: str = ""
    changed: bool = False


def classify(line: str, state: State) -> tuple[Row, State]:
    body = line.removesuffix("\r")
    info, after = scan_line(body, state)
    row = Row(line)
    if info.protected or not body.strip():
        return row, after
    row.indent = body[: len(body) - len(body.lstrip(" \t"))]
    row.cr = line[len(body):]
    end = info.comment if info.comment is not None else len(body)
    row.code = body[len(row.indent):end].rstrip()
    row.gap = body[len(row.indent) + len(row.code):end]
    row.comment = body[end:] if info.comment is not None else ""
    if not row.code:
        return row, after
    row.kind = "code"
    if info.eq is not None:
        eq = info.eq - len(row.indent)
        lhs, rhs = row.code[:eq].rstrip(), row.code[eq + 1:].lstrip()
        if rhs and is_assignment_lhs(lhs):
            row.kind, row.lhs, row.code = "assign", lhs, rhs
    return row, after


def runs(rows: list[Row], kinds: tuple[str, ...]):
    """Các đoạn dòng liền nhau thuộc `kinds` và cùng thụt lề."""
    start = 0
    while start < len(rows):
        if rows[start].kind not in kinds:
            start += 1
            continue
        end = start + 1
        while end < len(rows) and rows[end].kind in kinds and rows[end].indent == rows[start].indent:
            end += 1
        yield rows[start:end]
        start = end


def align_text(text: str) -> str:
    rows: list[Row] = []
    state = CODE
    for line in text.split("\n"):
        row, state = classify(line, state)
        rows.append(row)
    for group in runs(rows, ("assign",)):
        fitting = [display_width(r.lhs) for r in group if display_width(r.lhs) <= EQ_LHS_CAP]
        width = max(fitting, default=0)
        for r in group:
            r.code = f"{r.lhs}{' ' * max(width - display_width(r.lhs), 0)} = {r.code}"
            r.kind, r.changed = "code", True
            if "\t" in r.gap:
                r.gap = " " * COMMENT_GAP
    for block in runs(rows, ("code",)):
        members = [r for r in block if r.comment and "\t" not in r.code]
        if len(members) < 2:
            continue
        fitting = [display_width(r.code) for r in members if display_width(r.code) <= COMMENT_CODE_CAP]
        column = max(fitting, default=0)
        for r in members:
            width = display_width(r.code)
            gap = column - width + COMMENT_GAP if width <= COMMENT_CODE_CAP else COMMENT_GAP
            r.gap, r.changed = " " * gap, True
    return "\n".join(f"{r.indent}{r.code}{r.gap}{r.comment}{r.cr}" if r.changed else r.line for r in rows)


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Căn cột script Lua (ghi sang thư mục khác, kiểm bằng LuaPlus)")
    parser.add_argument("src", type=Path)
    parser.add_argument("dst", type=Path)
    parser.add_argument("--luaplus", type=Path, help="thư mục Bin64 có LuaPlus.dll: so mã trung gian gốc và đã căn")
    parser.add_argument("--overwrite", action="store_true", help="cho ghi vào thư mục đích đã có tệp")
    chosen = parser.parse_args()
    src, dst = chosen.src.resolve(), chosen.dst.resolve()
    if dst == src or src in dst.parents or dst in src.parents:
        print("thư mục đích không được trùng, nằm trong hay chứa nguồn", file=sys.stderr)
        return 2
    if dst.exists() and any(dst.iterdir()) and not chosen.overwrite:
        print(f"{dst} đã có tệp; thêm --overwrite nếu muốn ghi vào", file=sys.stderr)
        return 2
    compiler = None
    if chosen.luaplus:
        from unpack_scripts import Compiler
        compiler = Compiler(chosen.luaplus)
    files = changed = lines_changed = bad = 0
    for source in sorted(src.rglob("*.lua")):
        relative = source.relative_to(src)
        original = source.read_bytes().decode("utf-8")
        aligned = align_text(original)
        if compiler is not None:
            name = relative.as_posix()
            before, after = compiler.dump(name, original.encode("utf-8")), compiler.dump(name, aligned.encode("utf-8"))
            if before != after:
                print(f"LỆCH mã trung gian: {name}", file=sys.stderr)
                bad += 1
                continue
        target = dst / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(aligned.encode("utf-8"))
        files += 1
        if aligned != original:
            changed += 1
            lines_changed += sum(a != b for a, b in zip(original.split("\n"), aligned.split("\n")))
    print(f"đã ghi {files} tệp vào {dst}: {changed} tệp đổi, {lines_changed} dòng đổi"
          + (f"; mã trung gian khớp từng byte ở {files}/{files + bad} tệp" if compiler else "; CHƯA kiểm bằng LuaPlus"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
