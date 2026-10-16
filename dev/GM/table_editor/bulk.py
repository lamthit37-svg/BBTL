"""Phần thuần của sửa hàng loạt và chú giải cột. Không import Qt.

Mọi thao tác nhận danh sách ô (dòng, cột) của mô hình nguồn và trả về danh sách thay đổi (dòng, cột, cũ, mới);
không sửa dữ liệu. Áp dụng và hoàn tác do lệnh hoàn tác của giao diện làm, một thao tác là một bước hoàn tác.
Số tính bằng Decimal để không sinh đuôi nhị phân (0.1 + 0.2 = 0.3), không dùng ký pháp khoa học trừ khi ô gốc có.
"""
from __future__ import annotations

import html
import re
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation

import core

Cell = tuple[int, int]
Change = tuple[int, int, str, str]

TYPE_RULES = {
    "int": "Số nguyên thập phân: tuỳ chọn dấu + hoặc -, rồi chữ số 0-9; không dấu chấm, không khoảng trắng.",
    "float": "Số thực: dạng 12, 1.5, .5 hoặc 1e3 (dấu chấm thập phân); không dấu phẩy, không NaN/vô cực.",
    "text": "Chuỗi bất kỳ trên một dòng: không tab, không CR/LF; dấu cách đầu/cuối được giữ nguyên.",
}
FORBIDDEN = "\t\r\n"


class BulkError(ValueError):
    """Thao tác không áp dụng được; lời báo nêu ô hoặc lý do."""


def col_label(columns, c: int) -> str:
    return columns[c] if 0 <= c < len(columns) else f"cột {c + 1}"


def check_changes(changes: list[Change], columns) -> None:
    """Chặn giá trị chứa tab/CR/LF, nêu ô đầu tiên vi phạm (dòng tính từ 1)."""
    for r, c, _old, new in changes:
        if any(ch in new for ch in FORBIDDEN):
            raise BulkError(f"dòng {r + 1}, cột {col_label(columns, c)}: giá trị chứa tab hoặc xuống dòng")


def _only_changed(changes):
    return [ch for ch in changes if ch[2] != ch[3]]


# ---------- số ----------

def parse_number(text: str, kind: str) -> Decimal | None:
    """Giá trị số của ô theo kiểu cột, hoặc None khi ô không đúng dạng."""
    if not core.type_ok(kind, text) or kind not in ("int", "float"):
        return None
    try:
        value = Decimal(text)
    except InvalidOperation:
        return None
    return value if value.is_finite() else None


def parse_input(text: str) -> Decimal:
    """Số người dùng gõ vào hộp thoại (dấu chấm thập phân)."""
    t = text.strip()
    if not core.FLOAT_RE.fullmatch(t):
        raise BulkError(f"không phải số: {text!r}")
    return Decimal(t)


def format_number(value: Decimal, kind: str, original: str = "") -> str:
    """int: chuỗi số nguyên. float: dạng thập phân ngắn gọn, giữ số chữ số lẻ Decimal sinh ra;
    chỉ dùng ký pháp khoa học khi ô gốc đã dùng."""
    if kind == "int":
        if value != value.to_integral_value():
            raise BulkError(f"kết quả {value} không phải số nguyên")
        return str(int(value))
    if "e" in original.lower():
        return f"{value.normalize():e}".replace("e+", "e")
    text = format(value, "f")
    if text in ("-0", "-0.0") or text.startswith("-0") and Decimal(text) == 0:
        text = text.lstrip("-")
    return text


def numeric_columns(types, cells) -> bool:
    return bool(cells) and all(types[c] in ("int", "float") for _, c in cells)


def op_assign(rows, cells, value: str, columns) -> list[Change]:
    changes = [(r, c, rows[r][c], value) for r, c in cells]
    check_changes(changes, columns)
    return _only_changed(changes)


def op_delta(rows, cells, types, delta_text: str, columns) -> tuple[list[Change], list[Cell]]:
    """Cộng delta vào mỗi ô số. Cột int cần delta nguyên. Trả (thay đổi, các ô bỏ qua vì không phải số)."""
    delta = parse_input(delta_text)
    changes, skipped = [], []
    for r, c in cells:
        kind = types[c]
        if kind not in ("int", "float"):
            raise BulkError(f"cột {col_label(columns, c)} kiểu {kind}, không cộng số được")
        if kind == "int" and delta != delta.to_integral_value():
            raise BulkError(f"cột {col_label(columns, c)} kiểu int: bước cộng phải là số nguyên")
        old = rows[r][c]
        value = parse_number(old, kind)
        if value is None:
            skipped.append((r, c))
            continue
        changes.append((r, c, old, format_number(value + delta, kind, old)))
    return _only_changed(changes), skipped


def op_scale(rows, cells, types, factor_text: str, columns) -> tuple[list[Change], list[Cell]]:
    """Nhân mỗi ô số với hệ số. Cột int chỉ nhận hệ số nguyên (không làm tròn ngầm)."""
    factor = parse_input(factor_text)
    changes, skipped = [], []
    for r, c in cells:
        kind = types[c]
        if kind not in ("int", "float"):
            raise BulkError(f"cột {col_label(columns, c)} kiểu {kind}, không nhân được")
        if kind == "int" and factor != factor.to_integral_value():
            raise BulkError(
                f"cột {col_label(columns, c)} kiểu int: hệ số phải là số nguyên; app không tự làm tròn")
        old = rows[r][c]
        value = parse_number(old, kind)
        if value is None:
            skipped.append((r, c))
            continue
        changes.append((r, c, old, format_number(value * factor, kind, old)))
    return _only_changed(changes), skipped


def op_replace(rows, cells, find: str, repl: str, match_case: bool, columns) -> list[Change]:
    """Thay chuỗi nguyên văn (không regex)."""
    if find == "":
        raise BulkError("chuỗi cần tìm rỗng")
    pattern = re.compile(re.escape(find), re.IGNORECASE)
    changes = []
    for r, c in cells:
        old = rows[r][c]
        new = old.replace(find, repl) if match_case else pattern.sub(lambda _m: repl, old)
        changes.append((r, c, old, new))
    check_changes(changes, columns)
    return _only_changed(changes)


def op_affix(rows, cells, prefix: str, suffix: str, columns) -> list[Change]:
    changes = [(r, c, rows[r][c], prefix + rows[r][c] + suffix) for r, c in cells]
    check_changes(changes, columns)
    return _only_changed(changes)


def ordered(cells) -> list[Cell]:
    """Thứ tự điền: theo cột, trong cột theo dòng (đi xuống)."""
    return sorted(cells, key=lambda rc: (rc[1], rc[0]))


def op_series(rows, cells, types, start_text: str, step_text: str, columns) -> list[Change]:
    """Điền start, start+step, ... xuống từng cột đã chọn (mỗi cột bắt đầu lại từ start)."""
    start, step = parse_input(start_text), parse_input(step_text)
    changes, counter = [], {}
    for r, c in ordered(cells):
        kind = types[c]
        if kind == "int" and (start != start.to_integral_value() or step != step.to_integral_value()):
            raise BulkError(f"cột {col_label(columns, c)} kiểu int: giá trị đầu và bước phải là số nguyên")
        n = counter.get(c, 0)
        counter[c] = n + 1
        value = start + step * n
        if kind == "text":
            new = format_number(value, "float", start_text.strip())
        else:
            new = format_number(value, kind, start_text.strip())
        changes.append((r, c, rows[r][c], new))
    return _only_changed(changes)


def op_filldown(rows, cells, columns) -> list[Change]:
    """Mỗi cột: giá trị ô trên cùng của vùng chọn chép xuống các ô còn lại của cột đó."""
    first: dict[int, str] = {}
    changes = []
    for r, c in ordered(cells):
        if c not in first:
            first[c] = rows[r][c]
            continue
        changes.append((r, c, rows[r][c], first[c]))
    return _only_changed(changes)


def op_clear(rows, cells, columns) -> list[Change]:
    if len(columns) == 1:
        raise BulkError("bảng một cột không được có ô rỗng (hợp đồng schema 1)")
    return _only_changed([(r, c, rows[r][c], "") for r, c in cells])


# ---------- clipboard ----------

def copy_text(rows, cells) -> str:
    """TSV của hình chữ nhật bao vùng chọn; ô không chọn trong hình chữ nhật để rỗng."""
    if not cells:
        return ""
    chosen = set(cells)
    rs = sorted({r for r, _ in cells})
    cs = sorted({c for _, c in cells})
    lines = ["\t".join(rows[r][c] if (r, c) in chosen else "" for c in cs) for r in rs]
    return "\n".join(lines) + "\n"


def parse_paste(text: str) -> list[list[str]]:
    """Lưới từ clipboard: tab tách ô, CRLF/LF/CR tách dòng; bỏ đúng một xuống dòng cuối.
    Tab và xuống dòng chỉ là dấu tách nên giá trị kết quả không chứa chúng."""
    if text == "":
        return []
    t = text.replace("\r\n", "\n").replace("\r", "\n")
    if t.endswith("\n"):
        t = t[:-1]
    return [line.split("\t") for line in t.split("\n")]


def op_paste(rows, grid, top: int, left: int, ncols: int, visible_rows: list[int] | None = None,
             columns=()) -> tuple[list[Change], int]:
    """Dán lưới từ ô (top, left) theo dòng đang hiện (visible_rows: chỉ số nguồn theo thứ tự hiện).
    Phần vượt bảng bị cắt; trả (thay đổi, số ô bị cắt)."""
    order = visible_rows if visible_rows is not None else list(range(len(rows)))
    try:
        start = order.index(top)
    except ValueError:
        raise BulkError("ô bắt đầu không nằm trong dòng đang hiện")
    changes, clipped = [], 0
    for i, line in enumerate(grid):
        if start + i >= len(order):
            clipped += len(line)
            continue
        r = order[start + i]
        for j, value in enumerate(line):
            c = left + j
            if c >= ncols:
                clipped += 1
                continue
            changes.append((r, c, rows[r][c], value))
    check_changes(changes, columns)
    return _only_changed(changes), clipped


def apply(rows, changes, new: bool = True) -> None:
    """Ghi thay đổi vào dữ liệu (new=False để hoàn tác)."""
    if new:
        for r, c, _o, v in changes:
            rows[r][c] = v
    else:
        for r, c, v, _n in reversed(changes):
            rows[r][c] = v


# ---------- chú giải cột ----------

@dataclass
class Stats:
    empty: int
    distinct: int
    bad: int
    minimum: str | None
    maximum: str | None


def column_stats(rows, c: int, kind: str) -> Stats:
    empty = bad = 0
    seen = set()
    lo = hi = None
    lo_s = hi_s = None
    numeric = kind in ("int", "float")
    for row in rows:
        v = row[c]
        seen.add(v)
        if v == "":
            empty += 1
        if not core.type_ok(kind, v):
            bad += 1
            continue
        if numeric:
            try:
                d = Decimal(v)
            except InvalidOperation:
                continue
            if lo is None or d < lo:
                lo, lo_s = d, v
            if hi is None or d > hi:
                hi, hi_s = d, v
    return Stats(empty, len(seen), bad, lo_s, hi_s)


def tooltip_html(name: str, position: int, kind: str, entry: dict | None, has_file: bool,
                 stats: Stats | None, annotation_index: str | None = None) -> str:
    """Chú giải cột dạng bảng HTML. Chỉ dữ liệu thật; note theo đúng quy tắc nguyên văn của core.note_text."""
    esc = html.escape
    if entry is None:
        original = "(không có)" if has_file else "(không có tệp chú thích)"
        note = core.NO_NOTE
    else:
        original = entry.get("original") or "(trống)"
        note = core.note_text(entry.get("note", ""))
    idx = annotation_index if annotation_index not in (None, "") else "(không có)"
    rows = [
        ("Tên cột", name),
        ("Tên gốc (original)", original),
        ("Kiểu (# types)", kind or "(không có)"),
        ("Chú thích (note)", note),
        ("Vị trí cột", f"index chú thích: {idx}; vị trí thật trong tệp: {position}"),
    ]
    if stats is not None:
        rows += [("Số ô rỗng", str(stats.empty)), ("Số giá trị khác nhau", str(stats.distinct))]
        if kind in ("int", "float"):
            rows.append(("Nhỏ nhất / lớn nhất",
                         "(không có số hợp lệ)" if stats.minimum is None else f"{stats.minimum} / {stats.maximum}"))
        rows.append(("Số ô sai kiểu", str(stats.bad)))
    if kind in TYPE_RULES:
        rows.append(("Cách cấu hình kiểu", TYPE_RULES[kind]))
    body = "".join(
        f"<tr><td valign='top'><b>{esc(k)}</b></td><td width='300'>{esc(v)}</td></tr>" for k, v in rows)
    return f"<table width='420' cellspacing='0' cellpadding='2'>{body}</table>"
