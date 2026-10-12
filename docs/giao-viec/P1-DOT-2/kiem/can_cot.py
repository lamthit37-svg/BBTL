"""Đối chiếu căn cột, không import align_columns hay export_tables.

Ba bảng đọc hết: CommonItem, XinFa_V1, ImpactSEData_V1.
Thêm mọi cột ghi nội suy mà dòng note nói khớp dưới 95%, trên mọi bảng shared.
"""
from __future__ import annotations

import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "TOOLS" / "content"))
import dbc  # noqa: E402

LEGACY = Path(r"C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb") / "Public" / "Config"
RAW = Path(r"F:\tl 2026\_raw") / "Config"
COLUMNS = ROOT / "TOOLS" / "server" / "columns" / "shared"
OUT = Path(__file__).resolve().parent / "can-cot-ra.txt"
NOTE = re.compile(
    r"^(neo|chéo|nội suy|đổi kiểu): cột gốc (\d+), khớp (\d+\.\d+)% \((\d+)/(\d+) id\)"
)
FOCUS = ("CommonItem.txt", "XinFa_V1.txt", "ImpactSEData_V1.txt")


def atoi(text: str) -> int | None:
    if re.fullmatch(r"[+-]?\d+", text):
        return int(text)
    return None


def float_bits(text: str) -> int | None:
    try:
        value = float(text)
    except ValueError:
        return None
    if value != value or value in (float("inf"), float("-inf")):
        return None
    try:
        packed = struct.pack("<f", value)
    except OverflowError:
        return None
    return struct.unpack("<I", packed)[0]


def read_text(path: Path) -> tuple[list[str], list[str], list[list[str]]]:
    data = path.read_bytes().replace(b"\r\n", b"\n")
    if data.startswith(b"\xef\xbb\xbf") or b"\r" in data:
        raise ValueError(f"{path.name}: BOM hoặc CR lẻ")
    lines = data.decode("utf-8").split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    body = [(number, line) for number, line in enumerate(lines, start=1) if line]
    kinds = body[0][1].split("\t")
    names = body[1][1].split("\t")
    while kinds and kinds[-1] == "":
        kinds.pop()
    while names and names[-1] == "":
        names.pop()
    rows = []
    for _number, line in body[2:]:
        if line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] == "":
            continue
        rows.append(cells)
    return kinds, names, rows


def new_id(table: dbc.Dbc, row: int) -> object:
    if table.types[0] == dbc.INT:
        return table.integer(row, 0)
    if table.types[0] == dbc.FLOAT:
        return table.raw(row, 0)
    return table.text(row, 0)


def old_id(kind: str, text: str) -> object:
    if kind == "INT":
        number = atoi(text)
        return text if number is None else number
    if kind == "FLOAT":
        bits = float_bits(text)
        return text if bits is None else bits
    number = atoi(text)
    if number is not None:
        return number
    return text


def new_value(table: dbc.Dbc, row: int, column: int) -> tuple[str, object]:
    kind = table.types[column]
    if kind == dbc.INT:
        return "int", table.integer(row, column)
    if kind == dbc.FLOAT:
        return "float", table.raw(row, column)
    return "text", table.text(row, column)


def old_value(kind: str, text: str) -> tuple[str, object]:
    if kind == "INT":
        number = atoi(text)
        if number is None:
            return "invalid", text
        return "int", number
    if kind == "FLOAT":
        bits = float_bits(text)
        if bits is None:
            return "invalid", text
        return "float", bits
    return "text", text


def same(left: tuple[str, object], right: tuple[str, object]) -> bool:
    if left[0] == "invalid" or right[0] == "invalid":
        return False
    if left[0] == right[0]:
        return left[1] == right[1]
    if left[0] == "int" and right[0] == "text":
        return atoi(str(right[1])) == left[1]
    if right[0] == "int" and left[0] == "text":
        return atoi(str(left[1])) == right[1]
    if {left[0], right[0]} == {"int", "float"}:
        number = left[1] if left[0] == "int" else right[1]
        bits = left[1] if left[0] == "float" else right[1]
        return float_bits(str(number)) == bits
    if left[0] == "float" and right[0] == "text":
        return isinstance(right[1], str) and float_bits(right[1]) == left[1]
    if right[0] == "float" and left[0] == "text":
        return isinstance(left[1], str) and float_bits(left[1]) == right[1]
    return False


class PairData:
    def __init__(self, source: str) -> None:
        self.source = source
        legacy_path = LEGACY / source
        raw_path = RAW / source
        self.kinds, self.names, old_rows = read_text(legacy_path)
        self.table = dbc.read(str(raw_path), source)
        self.old_by_id: dict[object, list[str]] = {}
        self.duplicate_old = 0
        for cells in old_rows:
            key = old_id(self.kinds[0], cells[0] if cells else "")
            if key in self.old_by_id:
                self.duplicate_old += 1
                continue
            self.old_by_id[key] = cells
        self.rows: list[tuple[int, list[str]]] = []
        seen: set[object] = set()
        self.duplicate_new = 0
        for index in range(self.table.rows):
            key = new_id(self.table, index)
            if key in seen:
                self.duplicate_new += 1
            seen.add(key)
            old = self.old_by_id.get(key)
            if old is not None:
                self.rows.append((index, old))
        self._cache: dict[tuple[int, int], tuple[int, int, int]] = {}

    def stats(self, left: int, right: int) -> tuple[int, int, int]:
        cached = self._cache.get((left, right))
        if cached is not None:
            return cached
        matched = 0
        distinct_new: set[object] = set()
        distinct_old: set[object] = set()
        for index, old in self.rows:
            got = new_value(self.table, index, left)
            other = old_value(self.kinds[right], old[right] if right < len(old) else "")
            if got[0] != "invalid":
                distinct_new.add((got[0], got[1]))
            if other[0] != "invalid":
                distinct_old.add((other[0], other[1]))
            if same(got, other):
                matched += 1
        found = (matched, len(distinct_new), len(distinct_old))
        self._cache[(left, right)] = found
        return found

    def samples(self, left: int, right: int, limit: int) -> list[str]:
        found = []
        for index, old in self.rows:
            got = new_value(self.table, index, left)
            other = old_value(self.kinds[right], old[right] if right < len(old) else "")
            if same(got, other):
                continue
            ident = new_id(self.table, index)
            found.append(f"id {ident}: 2026 {got[1]!r} | gốc {other[1]!r}")
            if len(found) == limit:
                break
        return found


def column_specs(path: Path) -> tuple[str, list[tuple[int, str, str, str]]]:
    source = ""
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("# source: client_2026/"):
            source = line.split("client_2026/", 1)[1]
            continue
        if not line or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] == "index":
            continue
        rows.append((int(cells[0]), cells[1], cells[2], cells[4]))
    return source, rows


def percent(matched: int, total: int) -> float:
    if total == 0:
        return 0.0
    return matched * 100 / total


def audit_focus(data: PairData, specs: list[tuple[int, str, str, str]], out: list[str]) -> None:
    out.append(
        f"## {data.source}: id chung {len(data.rows)}, id gốc trùng {data.duplicate_old},"
        f" id 2026 lặp {data.duplicate_new}, cột gốc {len(data.kinds)}"
    )
    for index, original, name, note in specs:
        matched_note = NOTE.match(note)
        if matched_note is None:
            continue
        kind, right_text, claimed, _num, _den = matched_note.groups()
        right = int(right_text)
        matched, distinct_new, distinct_old = data.stats(index, right)
        total = len(data.rows)
        actual = percent(matched, total)
        claimed_value = float(claimed)
        drift = abs(actual - claimed_value) > 0.15
        mark = ""
        if drift:
            mark = " LỆCH SỐ"
        out.append(
            f"  [{index}] {name} {kind} gốc {right} {data.names[right] if right < len(data.names) else '?'!r}"
            f" đo {actual:.1f}% ({matched}/{total}) ghi {claimed}%"
            f" khác nhau {distinct_new}/{distinct_old}{mark}"
        )
        if kind == "nội suy" and distinct_new >= 3 and distinct_old >= 3 and actual < 95:
            best_right = right
            best_matched = matched
            for candidate in range(len(data.kinds)):
                if candidate == right:
                    continue
                other, _dn, other_old = data.stats(index, candidate)
                if other_old < 3:
                    continue
                if other > best_matched:
                    best_matched = other
                    best_right = candidate
            best_pct = percent(best_matched, total)
            if best_right != right and best_pct >= 95 and best_pct > actual + 5:
                label = data.names[best_right] if best_right < len(data.names) else "?"
                out.append(f"    GHÉP SAI: cột gốc {best_right} {label} khớp {best_pct:.1f}%")
            else:
                out.append("    NGOÀI LUẬT: nhiều giá trị, khớp dưới 95%, vẫn nội suy")
            for line in data.samples(index, right, 3):
                out.append(f"    {line}")


def scan_weak(loaded: dict[str, PairData], out: list[str]) -> None:
    out.append("## Nội suy ghi dưới 95%, đo lại")
    weak = 0
    outside = 0
    for path in sorted(COLUMNS.glob("*.tsv")):
        source, specs = column_specs(path)
        pending = []
        for index, original, name, note in specs:
            matched_note = NOTE.match(note)
            if matched_note is None or matched_note.group(1) != "nội suy":
                continue
            if float(matched_note.group(3)) >= 95:
                continue
            pending.append((index, name, note, matched_note))
        if not pending:
            continue
        data = loaded.get(source)
        if data is None:
            data = PairData(source)
            loaded[source] = data
        for index, name, _note, matched_note in pending:
            weak += 1
            right = int(matched_note.group(2))
            matched, distinct_new, distinct_old = data.stats(index, right)
            total = len(data.rows)
            actual = percent(matched, total)
            if distinct_new >= 3 and distinct_old >= 3 and actual < 95:
                outside += 1
                out.append(
                    f"  {source} [{index}] {name} gốc {right}"
                    f" đo {actual:.1f}% ({matched}/{total}) khác nhau {distinct_new}/{distinct_old}"
                )
    out.append(f"nội suy ghi dưới 95%: {weak}; trong đó cả hai bên từ 3 giá trị và đo dưới 95%: {outside}")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    lines: list[str] = []
    loaded: dict[str, PairData] = {}
    for source in FOCUS:
        path = COLUMNS / {
            "CommonItem.txt": "items_common.tsv",
            "XinFa_V1.txt": "inner_arts.tsv",
            "ImpactSEData_V1.txt": "effect_visuals.tsv",
        }[source]
        got, specs = column_specs(path)
        if got != source:
            raise SystemExit(f"{path.name}: source {got}")
        data = PairData(source)
        loaded[source] = data
        audit_focus(data, specs, lines)
    scan_weak(loaded, lines)
    text = "\n".join(lines) + "\n"
    OUT.write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
