"""Phần thuần của trình sửa bảng: phân loại tệp, nối chú thích cột, kiểm kiểu, ghi và đọc lại.

Không import Qt. Bộ đọc và bộ ghi bảng schema 1 duy nhất là TOOLS/server/tsv_file.py; module này chỉ gọi nó.
Tệp loại 2 (không phải schema 1) chỉ xem, tách bằng tsv_file.split_rows.
"""
from __future__ import annotations

import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

HERE = Path(__file__).resolve().parent


def _find_repo(start: Path) -> Path:
    """Đi ngược lên tới thư mục có TOOLS/server/tsv_file.py."""
    for folder in (start, *start.parents):
        if (folder / "TOOLS" / "server" / "tsv_file.py").is_file():
            return folder
    raise SystemExit(f"Không tìm thấy TOOLS/server/tsv_file.py phía trên {start}")


REPO = _find_repo(HERE)
SERVER_TOOLS = REPO / "TOOLS" / "server"
if str(SERVER_TOOLS) not in sys.path:
    sys.path.insert(0, str(SERVER_TOOLS))

import tsv_file as tf  # noqa: E402

ROOTS = (
    "dev/server/tables",
    "TOOLS/server/columns",
    "dev/client/assets/Table",
    "assets/i18n",
    "src/shared/protocol/catalog",
)
SCAN_SUFFIXES = (".tsv", ".txt", ".tab")
NOTE_BRANCHES = ("server", "shared", "scenes")
KNOWN_KEYS = ("# schema ", "# source: ", "# tool: ", "# types: ", tf.LAYOUT_PREFIX)
NO_NOTE = "chưa có chú thích"
NO_ANNOTATION_FILE = "không có tệp chú thích cột cho bảng này"
SAMPLE_ROWS = 200
TRAILING_MARK = "·"  # dấu hiện cho dấu cách cuối trong ô; giá trị lưu vẫn là dấu cách

INT_RE = re.compile(r"^[+-]?[0-9]+$")
FLOAT_RE = re.compile(r"^[+-]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$")


def rel(path: Path) -> str:
    try:
        return Path(path).resolve().relative_to(REPO).as_posix()
    except ValueError:
        return Path(path).as_posix()


def scan(repo: Path = REPO) -> dict[str, list[str]]:
    """Gốc -> danh sách đường dẫn tương đối (so với gốc), sắp xếp."""
    out: dict[str, list[str]] = {}
    for root in ROOTS:
        base = repo / root
        files: list[str] = []
        if base.is_dir():
            for item in base.rglob("*"):
                if item.is_file() and item.suffix.lower() in SCAN_SUFFIXES and not item.name.endswith(".tmp"):
                    files.append(item.relative_to(base).as_posix())
        out[root] = sorted(files, key=str.lower)
    return out


def stray_comments(path: Path) -> list[str]:
    """Các dòng # trước dòng tên cột không thuộc năm khoá; read_table sẽ bỏ chúng, ghi lại sẽ mất."""
    try:
        text = Path(path).read_bytes().decode("utf-8")
    except (OSError, UnicodeError):
        return []
    found = []
    for line in text.split("\n"):
        line = line.rstrip("\r")
        if line == "":
            continue
        if not line.startswith("#"):
            break
        if line.startswith("# tool: ") and not line.endswith(tf.TOOL_SUFFIX):
            found.append(line)
        elif not line.startswith(KNOWN_KEYS):
            found.append(line)
    return found


def type_ok(kind: str, value: str) -> bool:
    if kind == "int":
        return bool(INT_RE.fullmatch(value))
    if kind == "float":
        if not FLOAT_RE.fullmatch(value):
            return False
        return math.isfinite(float(value))
    return True


def show_cell(value: str) -> str:
    """Chuỗi hiện trong ô: dấu cách cuối thành dấu nhìn thấy, không cắt gì."""
    body = value.rstrip(" ")
    return body + TRAILING_MARK * (len(value) - len(body))


@dataclass
class Loaded:
    path: Path
    relpath: str
    kind: int  # 1 = schema 1 đọc được, 2 = chỉ xem
    columns: list[str]
    rows: list[list[str]]
    types: list[str] = field(default_factory=list)
    source: str = ""
    tool: str = ""
    layout: str = "plain"
    stray: list[str] = field(default_factory=list)
    reason: str = ""  # vì sao không ghi đè
    tool_suffix: bool = False

    @property
    def can_overwrite(self) -> bool:
        return self.kind == 1 and not self.stray

    @property
    def can_export(self) -> bool:
        return self.kind == 1

    @property
    def write_layout(self) -> str:
        return "aligned" if self.layout == "aligned" else "auto"


def _kind2_reason(relpath: str, error: str) -> str:
    if relpath.startswith("dev/client/assets/Table/"):
        why = "bảng client theo đầu tệp export_config.py, không phải schema 1"
    elif relpath.startswith("assets/i18n/"):
        why = "tệp i18n (khoá, tab, giá trị, comment tự do), không phải schema 1"
    elif relpath.startswith("src/shared/protocol/catalog/"):
        why = "catalog giao thức có kiểu ngoài int/float/text; sửa xong phải chạy gen_protocol.py, app này không làm"
    else:
        why = "read_table không đọc được tệp này"
    return f"Chỉ xem, không ghi đè: {why}. ({error})"


def load(path: Path | str) -> Loaded:
    path = Path(path)
    relpath = rel(path)
    try:
        table = tf.read_table(path)
    except (tf.TsvError, OSError) as exc:
        return _load_view(path, relpath, str(exc))
    stray = stray_comments(path)
    reason = ""
    if stray:
        reason = (
            "Không ghi đè: tệp có dòng # ngoài năm khoá schema/source/tool/types/layout; "
            "chỉ được Xuất sang đường khác (các dòng đó sẽ mất)."
        )
    return Loaded(
        path, relpath, 1, list(table.columns), [list(r) for r in table.rows], list(table.types),
        table.source, table.tool, table.layout, stray, reason, True,
    )


def _load_view(path: Path, relpath: str, error: str) -> Loaded:
    data = path.read_bytes() if path.is_file() else b""
    if data.startswith(b"\xef\xbb\xbf"):
        data = data[3:]
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return Loaded(path, relpath, 2, ["(không phải UTF-8)"], [], reason=_kind2_reason(relpath, "không phải UTF-8, không hiện lưới"))
    try:
        rows = tf.split_rows(text)
    except tf.TsvError:
        rows = [line.split("\t") for line in text.replace("\r\n", "\n").split("\n") if line and not line.startswith("#")]
    tool_suffix = any(l.startswith("# tool: ") and l.endswith(tf.TOOL_SUFFIX) for l in text.split("\n")[:20])
    layout = "aligned" if f"{tf.LAYOUT_PREFIX}aligned" in text.split("\n")[:20] else "plain"
    header = rows[0] if rows else []
    body = rows[1:]
    width = max([len(header), *(len(r) for r in body)]) if rows else 0
    columns = [header[i] if i < len(header) else f"({i + 1})" for i in range(width)]
    body = [r + [""] * (width - len(r)) for r in body]
    return Loaded(path, relpath, 2, columns, body, layout=layout, reason=_kind2_reason(relpath, error), tool_suffix=tool_suffix)


# ---------- chú thích cột ----------

def annotation_path(relpath: str, repo: Path = REPO) -> Path | None:
    prefix = "dev/server/tables/"
    if not relpath.startswith(prefix):
        return None
    inner = relpath[len(prefix):]
    branch = inner.split("/", 1)[0]
    if branch not in NOTE_BRANCHES or "/" not in inner:
        return None
    candidate = repo / "TOOLS/server/columns" / inner
    return candidate if candidate.is_file() else None


def annotations(relpath: str, repo: Path = REPO) -> dict[str, dict[str, str]]:
    """name -> {original, type, note} lấy nguyên văn từ tệp chú thích; không có thì rỗng."""
    path = annotation_path(relpath, repo)
    if path is None:
        return {}
    table = tf.read_table(path)
    idx = {name: i for i, name in enumerate(table.columns)}
    out = {}
    for row in table.rows:
        get = lambda key: row[idx[key]] if key in idx else ""
        out[get("name")] = {"original": get("original"), "type": get("type"), "note": get("note")}
    return out


def note_text(note: str) -> str:
    """Note rỗng -> câu mặc định; còn lại nguyên văn (kể cả '?' và 'không có bản đối chiếu')."""
    return NO_NOTE if note == "" else note


def column_lines(name: str, kind: str, ann: dict[str, dict[str, str]] | None, has_file: bool = True) -> list[str]:
    entry = (ann or {}).get(name)
    if entry is None:
        original = "(không có)" if has_file else "(không có tệp chú thích)"
        note = NO_NOTE
    else:
        original = entry["original"] if entry["original"] else "(trống)"
        note = note_text(entry["note"])
    return [
        f"Tên cột: {name}",
        f"Tên gốc (original): {original}",
        f"Kiểu (# types): {kind or '(không có)'}",
        f"Chú thích (note): {note}",
    ]


_NAME_MAP: dict[str, str] | None = None


def table_note(relpath: str, repo: Path = REPO) -> str | None:
    """Note của table_names.tsv khi target trùng đường dẫn bảng (tính từ dev/server/)."""
    global _NAME_MAP
    if _NAME_MAP is None:
        _NAME_MAP = {}
        try:
            for row in tf.read_name_map(repo / "TOOLS/server/table_names.tsv"):
                if row.target:
                    _NAME_MAP.setdefault(row.target, row.note)
        except (tf.TsvError, OSError):
            pass
    prefix = "dev/server/"
    if not relpath.startswith(prefix):
        return None
    return _NAME_MAP.get(relpath[len(prefix):])


# ---------- kiểm và ghi ----------

def check_cells(columns: list[str], rows: list[list[str]]) -> list[tuple[int, int, str]]:
    """Lỗi chặn ghi: (dòng 0-based, cột, lời). Tab/CR/LF, ô đầu bắt đầu bằng #, bảng một cột có ô rỗng."""
    errors = []
    width = len(columns)
    for r, row in enumerate(rows):
        for c, cell in enumerate(row):
            if any(ch in cell for ch in "\t\r\n"):
                errors.append((r, c, "ô chứa tab hoặc xuống dòng"))
        if row and row[0].startswith("#"):
            errors.append((r, 0, "ô đầu bắt đầu bằng #"))
        if width == 1 and row and row[0] == "":
            errors.append((r, 0, "bảng một cột không được có ô rỗng"))
    return errors


def size_estimate(lt: Loaded, rows: list[list[str]]) -> tuple[int, bool]:
    """(byte sau khi căn, có phải ước lượng). Bảng nhỏ render thật; bảng lớn ngoại suy từ mẫu."""
    chars = sum(len(c) + 1 for c in lt.columns) + sum(len(c) + 1 for r in rows for c in r) if len(rows) < 50000 else None
    if chars is not None and chars <= tf.ALIGN_LIMIT and lt.kind == 1:
        try:
            text = tf.render_table(lt.source, lt.tool, lt.types, lt.columns, rows, "aligned")
            return len(text.encode("utf-8")), False
        except tf.TsvError:
            pass
    sample = rows[:2000]
    if not sample:
        return 0, True
    widths = [tf.display_width(c) for c in lt.columns]
    for r in sample:
        for i, c in enumerate(r[: len(widths)]):
            widths[i] = max(widths[i], tf.display_width(c))
    per = 0
    for r in sample:
        line = 0
        for i, c in enumerate(r):
            b = len(c.encode("utf-8"))
            line += b + (widths[i] - tf.display_width(c) + tf.ALIGN_GAP + 1 if i < len(r) - 1 else 1)
        per += line
    return int(per / len(sample) * len(rows)), True


def predicted_layout(lt: Loaded, est: int) -> str:
    if lt.layout == "aligned":
        return "aligned"
    return "aligned" if est <= tf.ALIGN_LIMIT else "plain"


def render(lt: Loaded, rows: list[list[str]]) -> str:
    errors = check_cells(lt.columns, rows)
    if errors:
        r, c, msg = errors[0]
        raise tf.TsvError(f"dòng {r + 1}, cột {lt.columns[c]}: {msg}")
    return tf.render_table(lt.source, lt.tool, lt.types, lt.columns, rows, lt.write_layout)


def verify(path: Path, lt: Loaded, rows: list[list[str]]) -> list[str]:
    """Đọc lại bằng read_table và so từng ô; trả danh sách lệch (rỗng là khớp)."""
    back = tf.read_table(path)
    issues = []
    if list(back.columns) != lt.columns or list(back.types) != lt.types:
        issues.append("tên cột hoặc kiểu khác")
    if back.source != lt.source or tf.canonical_tool(back.tool) != tf.canonical_tool(lt.tool):
        issues.append("source hoặc tool khác")
    if len(back.rows) != len(rows):
        issues.append(f"số dòng {len(back.rows)} khác {len(rows)}")
    for r, (a, b) in enumerate(zip(back.rows, rows)):
        if list(a) != list(b):
            c = next(i for i in range(len(b)) if i >= len(a) or a[i] != b[i])
            issues.append(f"dòng {r + 1}, cột {lt.columns[c]}: {a[c] if c < len(a) else ''!r} khác {b[c]!r}")
            if len(issues) > 20:
                break
    return issues


def write(path: Path | str, lt: Loaded, rows: list[list[str]]) -> list[str]:
    """Ghi qua write_table với source/tool gốc rồi đọc lại so. Trả danh sách lệch."""
    if not lt.can_export:
        raise tf.TsvError("tệp loại 2 không ghi được")
    errors = check_cells(lt.columns, rows)
    if errors:
        r, c, msg = errors[0]
        raise tf.TsvError(f"dòng {r + 1}, cột {lt.columns[c]}: {msg}")
    tf.write_table(path, lt.source, lt.tool, lt.types, lt.columns, rows, lt.write_layout)
    return verify(Path(path), lt, rows)


def write_inplace(lt: Loaded, rows: list[list[str]]) -> list[str]:
    if not lt.can_overwrite:
        raise tf.TsvError(lt.reason or "tệp không ghi đè được")
    return write(lt.path, lt, rows)
