"""Ghi và đọc bảng TSV theo hợp đồng đợt P1, và đọc bảng tên tệp.

    # schema 1
    # source: <cây>/<đường dẫn gốc>
    # tool: TOOLS/server/<công cụ>.py; sửa tay sẽ mất ở lượt xuất sau
    # types: <int, float hoặc text, cách nhau bằng tab>
    # layout: aligned                      (chỉ bảng căn cột)
    <tên cột>
    <bản ghi>

Định dạng lấy từ bộ đọc C++ game::table::parse_tsv: dòng bắt đầu bằng # và dòng rỗng bị bỏ,
ô không có cách thoát. write_table từ chối ô có tab hoặc xuống dòng, ô đầu bắt đầu bằng #,
và ô rỗng của bảng một cột, vì những dòng đó biến mất khi đọc. Ghi qua tệp tạm rồi đổi tên.
prepare_directory chỉ xoá tệp của đúng công cụ; gặp tệp lạ thì dừng, không xoá gì.

Bố cục "aligned" (chủ dự án giao 2026-10-15, cho bảng mở bằng trình soạn để đọc): mỗi ô trừ cột cuối
được đệm dấu cách tới độ rộng hiển thị lớn nhất của cột cộng ALIGN_GAP (chữ Hán và dạng toàn chiều
tính 2 ô), rồi mới tới tab; mọi dòng có cùng độ rộng trước mỗi tab nên cột thẳng với cỡ tab nào cũng
được. Dấu cách cuối ô khi đó là đệm; dấu cách cuối thật của dữ liệu ghi bằng SPACE_MARK (U+2423),
nên dữ liệu không được chứa SPACE_MARK. Dòng # types không căn (tiền tố của nó lệch cột). Bộ đọc C++
(table/tsv.hpp, content/table_text.hpp) và read_table bỏ đệm theo đúng luật này; cột ở đây tính độ
rộng như wcwidth, cột chỉ thẳng trên trình soạn vẽ chữ Hán đúng hai ô chữ Latin.
Mặc định write_table dùng layout "auto": căn cột khi bảng sau căn không quá ALIGN_LIMIT byte (1 MiB), không thì ghi
thường; "aligned" ép căn (lua_extract, bảng nhiệm vụ và hội thoại do chủ dự án đọc bằng mắt), "plain" ép thường.
Mọi bộ đọc của dự án hiểu cả hai bố cục: read_table, table::parse_tsv, item::tsv::Rows, content::RecordReader.
"""
from __future__ import annotations

import math
import os
import re
import struct
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path

SCHEMA = "1"
LAYOUTS = ("plain", "aligned", "auto")
LAYOUT_PREFIX = "# layout: "
SPACE_MARK = "␣"
ALIGN_GAP = 2
# Bảng căn cột nở ra vài lần (mỗi ô đệm tới độ rộng ô dài nhất của cột): bảng lớn ghi thường để tệp và thời gian nạp
# không phình. Đo 2026-10-15 trên dev/server/tables: căn hết mọi bảng thì 133 MB thành khoảng 660 MB.
ALIGN_LIMIT = 1 << 20
TOOL_SUFFIX = "; sửa tay sẽ mất ở lượt xuất sau"
COLUMN_NAME = re.compile(r"^[a-z][a-z0-9_]*$")
TOOL_FILE = re.compile(r"^[a-z][a-z0-9_]*\.py$")
KEY_VALUE = re.compile(r"^[a-z][a-z0-9_]*$")
TARGET_PATH = re.compile(
    r"^tables/(?:server|shared|variants/[a-z][a-z0-9_]*)/(?:[a-z][a-z0-9_]*/)?[a-z][a-z0-9_]*\.tsv$"
)
TYPE_KINDS = frozenset({"int", "float", "text"})
FATES = frozenset(
    {"table", "reference", "rules", "process_config", "scene_data", "client_only", "dropped", "deferred"}
)
TREES = frozenset({"server_config", "public_config", "public_data", "client_2026"})
KEY_FIELDS = frozenset({"", "box_key", "shop_key", "variant"})
NAME_COLUMNS = (
    "tree",
    "source",
    "fate",
    "target",
    "key_field",
    "key",
    "owner",
    "unresolved",
    "note",
)


class TsvError(ValueError):
    """Lỗi hợp đồng bảng, kèm vị trí khi biết tệp và dòng."""


@dataclass(frozen=True)
class Table:
    source: str
    tool: str
    types: tuple[str, ...]
    columns: tuple[str, ...]
    rows: tuple[tuple[str, ...], ...]
    layout: str = "plain"


@dataclass(frozen=True)
class NameRow:
    tree: str
    source: str
    fate: str
    target: str
    key_field: str
    key: str
    owner: str
    unresolved: str
    note: str


def canonical_tool(tool: str) -> str:
    """Đưa tên công cụ về dạng TOOLS/server/<tên>.py."""
    if not isinstance(tool, str) or not tool or any(char in tool for char in "\\\n\r\t"):
        raise TsvError("tên công cụ không hợp lệ")
    name = tool.split("/")[-1]
    prefix = tool[: -len(name)].rstrip("/")
    if not TOOL_FILE.fullmatch(name) or prefix not in ("", "TOOLS/server"):
        raise TsvError(f"tên công cụ không hợp lệ: {tool}")
    return f"TOOLS/server/{name}"


def _fail(path: Path, line: int, message: str) -> TsvError:
    return TsvError(f"{path}:{line}: {message}")


def _check_source(source: str) -> None:
    if not isinstance(source, str) or not source:
        raise TsvError("source rỗng")
    if any(char in source for char in "\t\r\n\\"):
        raise TsvError("source chứa tab, xuống dòng hoặc dấu gạch ngược")


def _check_header(columns: tuple[str, ...] | list[str], types: tuple[str, ...] | list[str]) -> None:
    if not columns:
        raise TsvError("bảng không có cột")
    if len(columns) != len(types):
        raise TsvError("số kiểu khác số cột")
    seen: set[str] = set()
    for name in columns:
        if not isinstance(name, str) or not COLUMN_NAME.fullmatch(name):
            raise TsvError(f"tên cột không hợp lệ: {name}")
        if name in seen:
            raise TsvError(f"tên cột trùng: {name}")
        seen.add(name)
    for kind in types:
        if kind not in TYPE_KINDS:
            raise TsvError(f"kiểu cột không hợp lệ: {kind}")


def _check_cell(cell: object, line: int, width: int, first: bool) -> str:
    if type(cell) is not str:
        raise TsvError(f"dòng {line}: ô phải là chuỗi")
    if any(char in cell for char in "\t\r\n"):
        raise TsvError(f"dòng {line}: ô chứa tab hoặc xuống dòng")
    if first and cell.startswith("#"):
        raise TsvError(f"dòng {line}: ô đầu bắt đầu bằng #")
    if first and width == 1 and cell == "":
        raise TsvError(f"dòng {line}: bảng một cột có ô rỗng")
    return cell


def _check_rows(width: int, rows: list | tuple) -> tuple[tuple[str, ...], ...]:
    checked = []
    for index, row in enumerate(rows, start=1):
        if len(row) != width:
            raise TsvError(f"dòng {index}: {len(row)} ô, cần {width}")
        cells = tuple(_check_cell(cell, index, width, column == 0) for column, cell in enumerate(row))
        checked.append(cells)
    return tuple(checked)


def display_width(text: str) -> int:
    """Số ô hiển thị trong phông đơn cách: chữ Hán và dạng toàn chiều 2 ô, dấu kết hợp 0 ô."""
    return sum(
        0 if unicodedata.combining(char) else 2 if unicodedata.east_asian_width(char) in "WF" else 1
        for char in text
    )


def _mark_trailing(cell: str) -> str:
    """Dấu cách cuối thật thành SPACE_MARK để không lẫn với đệm."""
    body = cell.rstrip(" ")
    return body + SPACE_MARK * (len(cell) - len(body))


def _unmark_trailing(cell: str) -> str:
    """Ngược _mark_trailing trên một ô đã đọc của bảng căn cột: bỏ đệm, SPACE_MARK cuối thành dấu cách."""
    body = cell.rstrip(" ")
    text = body.rstrip(SPACE_MARK)
    return text + " " * (len(body) - len(text))


def _aligned_lines(lines: list[tuple[str, ...]]) -> list[str]:
    """Các dòng (tên cột và bản ghi) căn cột; ô cuối không đệm. O(tổng độ dài ô)."""
    marked = [tuple(_mark_trailing(cell) for cell in line) for line in lines]
    widths = [0] * len(marked[0])
    for line in marked:
        for column, cell in enumerate(line[:-1]):
            widths[column] = max(widths[column], display_width(cell))
    out = []
    for line in marked:
        padded = [
            cell + " " * (widths[column] - display_width(cell) + ALIGN_GAP) for column, cell in enumerate(line[:-1])
        ]
        out.append("\t".join([*padded, line[-1]]))
    return out


def _plain_lines(columns: list[str] | tuple[str, ...], body: tuple[tuple[str, ...], ...]) -> list[str]:
    return ["\t".join(columns), *("\t".join(row) for row in body)]


def _aligned_text_lines(columns: list[str] | tuple[str, ...], body: tuple[tuple[str, ...], ...]) -> list[str]:
    return [f"{LAYOUT_PREFIX}aligned", *_aligned_lines([tuple(columns), *body])]


def _fits_aligned(columns: list[str] | tuple[str, ...], body: tuple[tuple[str, ...], ...]) -> list[str] | None:
    """Các dòng căn cột khi bảng đủ nhỏ để căn, hoặc None. Số ký tự chưa tính đệm đã vượt trần thì khỏi tính độ rộng:
    byte sau căn không bao giờ ít hơn số ký tự. O(tổng độ dài ô) và dừng sớm với bảng lớn."""
    chars = sum(len(cell) + 1 for cell in columns) + sum(len(cell) + 1 for row in body for cell in row)
    if chars > ALIGN_LIMIT or any(SPACE_MARK in cell for row in body for cell in row):
        return None
    lines = _aligned_text_lines(columns, body)
    if sum(len(line.encode("utf-8")) + 1 for line in lines) > ALIGN_LIMIT:
        return None
    return lines


def render_table(
    source: str,
    tool: str,
    types: list[str] | tuple[str, ...],
    columns: list[str] | tuple[str, ...],
    rows: list | tuple,
    layout: str = "auto",
) -> str:
    """Nội dung tệp đúng hợp đồng. Chưa ghi đĩa. layout: "plain", "aligned" (bảng chứa SPACE_MARK thì lỗi) hay "auto"
    (căn cột khi bảng sau căn không quá ALIGN_LIMIT byte, không thì ghi thường)."""
    tool_id = canonical_tool(tool)
    _check_source(source)
    _check_header(columns, types)
    if layout not in LAYOUTS:
        raise TsvError(f"bố cục lạ: {layout}")
    body = _check_rows(len(columns), rows)
    lines = [
        f"# schema {SCHEMA}",
        f"# source: {source}",
        f"# tool: {tool_id}{TOOL_SUFFIX}",
        "# types: " + "\t".join(types),
    ]
    if layout == "aligned":
        for index, row in enumerate(body, start=1):
            if any(SPACE_MARK in cell for cell in row):
                raise TsvError(f"dòng {index}: bảng căn cột không nhận ô chứa {SPACE_MARK}")
        lines.extend(_aligned_text_lines(columns, body))
    else:
        fitted = _fits_aligned(columns, body) if layout == "auto" else None
        lines.extend(fitted if fitted is not None else _plain_lines(columns, body))
    return "\n".join(lines) + "\n"


def _owned_tool(path: Path) -> str | None:
    """Tên công cụ ghi tệp này, hoặc None khi không phải bảng của công cụ."""
    if not path.is_file():
        return None
    try:
        text = path.read_bytes().decode("utf-8")
    except (UnicodeError, OSError):
        return None
    found = []
    prefix = "# tool: "
    for line in text.splitlines():
        if not line.startswith(prefix) or not line.endswith(TOOL_SUFFIX):
            continue
        tool = line[len(prefix) : -len(TOOL_SUFFIX)]
        if tool.startswith("TOOLS/server/") and TOOL_FILE.fullmatch(tool.split("/")[-1]):
            found.append(tool)
    if len(found) == 1:
        return found[0]
    return None


def write_table(
    path: Path | str,
    source: str,
    tool: str,
    types: list[str] | tuple[str, ...],
    columns: list[str] | tuple[str, ...],
    rows: list | tuple,
    layout: str = "auto",
) -> None:
    """Ghi một bảng. Tệp đã có mà không phải của công cụ này thì không ghi đè."""
    destination = Path(path)
    text = render_table(source, tool, types, columns, rows, layout)
    tool_id = canonical_tool(tool)
    if destination.exists() and _owned_tool(destination) != tool_id:
        raise _fail(destination, 1, f"tệp không phải của {tool_id}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    handle_fd, temporary = tempfile.mkstemp(prefix=f"{destination.name}.", suffix=".tmp", dir=destination.parent)
    try:
        with os.fdopen(handle_fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
        os.replace(temporary, destination)
    except Exception:
        if os.path.exists(temporary):
            os.unlink(temporary)
        raise


def _read_text(path: Path) -> str:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        raise _fail(path, 1, "có BOM")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise _fail(path, exc.start + 1, "byte UTF-8 hỏng") from exc
    if "\r" in text:
        raise _fail(path, 1, "xuống dòng CRLF")
    if not text.endswith("\n"):
        raise _fail(path, 1, "tệp cụt, thiếu xuống dòng cuối")
    return text


def _take_comment(path: Path, number: int, line: str, found: dict) -> None:
    if line.startswith("# schema "):
        found["schema"] = line[len("# schema ") :]
        return
    if line.startswith("# source: "):
        found["source"] = line[len("# source: ") :]
        return
    if line.startswith("# tool: ") and line.endswith(TOOL_SUFFIX):
        found["tool"] = line[len("# tool: ") : -len(TOOL_SUFFIX)]
        return
    if line.startswith("# types: "):
        found["types"] = tuple(line[len("# types: ") :].split("\t"))
        return
    if line.startswith(LAYOUT_PREFIX):
        layout = line[len(LAYOUT_PREFIX) :]
        if layout != "aligned":
            raise _fail(path, number, f"bố cục lạ: {layout}")
        found["layout"] = layout
        return
    if line.startswith("# "):
        return
    raise _fail(path, number, "dòng chú thích không thuộc hợp đồng")


def split_rows(text: str) -> list[list[str]]:
    """Ô của mọi dòng không phải # và không rỗng, kể cả dòng tên cột, cho công cụ tự đọc bảng mà không cần đủ hợp đồng
    của read_table (CRLF được chấp nhận). Bảng căn cột (dòng # layout: aligned trước tên cột) được bỏ đệm như
    read_table; bố cục lạ là lỗi. O(độ dài văn bản)."""
    aligned = False
    rows: list[list[str]] = []
    for number, line in enumerate(text.replace("\r\n", "\n").split("\n"), start=1):
        if not rows and line.startswith(LAYOUT_PREFIX):
            if line != f"{LAYOUT_PREFIX}aligned":
                raise TsvError(f"dòng {number}: bố cục lạ: {line[len(LAYOUT_PREFIX):]}")
            aligned = True
        if line == "" or line.startswith("#"):
            continue
        cells = line.split("\t")
        rows.append([_unmark_trailing(cell) for cell in cells] if aligned else cells)
    return rows


def read_table(path: Path | str) -> Table:
    """Đọc bảng do write_table ghi. Sai hợp đồng thì lỗi, không sửa ô."""
    source_path = Path(path)
    lines = _read_text(source_path).split("\n")[:-1]
    found: dict = {}
    header: tuple[str, ...] | None = None
    rows: list[tuple[str, ...]] = []
    for number, line in enumerate(lines, start=1):
        if line == "":
            continue
        if header is None and line.startswith("#"):
            _take_comment(source_path, number, line, found)
            continue
        cells = tuple(line.split("\t"))
        if found.get("layout") == "aligned":
            cells = tuple(_unmark_trailing(cell) for cell in cells)
        if header is None:
            header = cells
            continue
        if len(cells) != len(header):
            raise _fail(source_path, number, f"{len(cells)} ô, dòng tên cột có {len(header)}")
        rows.append(cells)
    if found.get("schema") != SCHEMA:
        raise _fail(source_path, 1, "sai schema")
    if "source" not in found or "tool" not in found or "types" not in found or header is None:
        raise _fail(source_path, 1, "thiếu dòng hợp đồng")
    _check_header(header, found["types"])
    checked = []
    for index, row in enumerate(rows, start=1):
        checked.append(tuple(_check_cell(cell, index, len(header), column == 0) for column, cell in enumerate(row)))
    return Table(found["source"], found["tool"], found["types"], header, tuple(checked), found.get("layout", "plain"))


def _relative_name(name: str) -> str:
    if not name or "\\" in name or name.startswith("/") or ".." in Path(name).parts:
        raise TsvError(f"tên tệp nhị phân không hợp lệ: {name}")
    return name


def prepare_directory(
    directory: Path | str,
    tool: str,
    own_binaries: list[str] | tuple[str, ...] = (),
    keep_tools: list[str] | tuple[str, ...] = (),
) -> None:
    """Xoá tệp của công cụ trong thư mục. Tệp lạ làm dừng trước khi xoá."""
    folder = Path(directory)
    tool_id = canonical_tool(tool)
    claimed = {_relative_name(name) for name in own_binaries}
    kept = {canonical_tool(name) for name in keep_tools}
    folder.mkdir(parents=True, exist_ok=True)
    foreign: list[Path] = []
    owned: list[Path] = []
    for path in sorted(item for item in folder.rglob("*") if item.is_file()):
        relative = path.relative_to(folder).as_posix()
        owner = _owned_tool(path)
        if relative in claimed or owner == tool_id:
            owned.append(path)
            continue
        if owner in kept:
            continue
        foreign.append(path)
    if foreign:
        raise _fail(foreign[0], 1, "tệp lạ, không xoá")
    for path in owned:
        path.unlink()
    folders = [item for item in folder.rglob("*") if item.is_dir()]
    subdirs = sorted(folders, key=lambda item: len(item.parts), reverse=True)
    for subdir in subdirs:
        if not any(subdir.iterdir()):
            subdir.rmdir()


def _packed_f32(text: str) -> int | None:
    """Bit float32 của chuỗi, hoặc None khi chuỗi không đóng gói được."""
    try:
        value = float(text)
    except ValueError:
        return None
    if not math.isfinite(value):
        return None
    try:
        return struct.unpack("<I", struct.pack("<f", value))[0]
    except OverflowError:
        return None


def format_float32(bits: int) -> str:
    """Chuỗi ngắn nhất mà đóng gói lại ra đúng 32 bit. Không nhận NaN và vô cực."""
    if type(bits) is not int or bits < 0 or bits > 0xFFFFFFFF:
        raise TsvError("mẫu bit float32 không hợp lệ")
    value = struct.unpack("<f", struct.pack("<I", bits))[0]
    if math.isnan(value) or math.isinf(value):
        raise TsvError("số thực đặc biệt không ghi thành chuỗi thập phân")
    for digits in range(1, 10):
        text = format(value, f".{digits}g")
        if _packed_f32(text) == bits:
            return text
    raise TsvError("không tìm được chuỗi ngắn nhất cho float32")


def owned_tool(path: Path | str) -> str | None:
    """Công cụ trong dòng # tool: của tệp, hoặc None khi tệp không phải của công cụ."""
    return _owned_tool(Path(path))


def _default_name_map() -> Path:
    return Path(__file__).resolve().with_name("table_names.tsv")


def _check_relative(path: Path, line: int, value: str, label: str) -> None:
    if "\\" in value or value.startswith("/") or ".." in Path(value).parts:
        raise _fail(path, line, f"{label} không phải đường dẫn tương đối")
    if len(value) > 1 and value[1] == ":":
        raise _fail(path, line, f"{label} là đường dẫn tuyệt đối")


def _check_name_row(path: Path, line: int, row: NameRow) -> None:
    if row.tree not in TREES:
        raise _fail(path, line, f"tree lạ: {row.tree}")
    if row.fate not in FATES:
        raise _fail(path, line, f"fate lạ: {row.fate}")
    if row.owner not in {"", "A", "B", "C"}:
        raise _fail(path, line, f"owner lạ: {row.owner}")
    if row.key_field not in KEY_FIELDS:
        raise _fail(path, line, f"key_field lạ: {row.key_field}")
    if row.unresolved not in {"0", "1"}:
        raise _fail(path, line, "unresolved phải là 0 hoặc 1")
    marked = "1" if "?" in row.note else "0"
    if row.unresolved != marked:
        raise _fail(path, line, "unresolved không khớp dấu ? trong note")
    _check_relative(path, line, row.source, "source")
    if not row.source:
        raise _fail(path, line, "source rỗng")
    if row.fate == "table":
        if not TARGET_PATH.fullmatch(row.target):
            raise _fail(path, line, f"target không hợp lệ: {row.target}")
        if row.owner not in {"A", "B", "C"}:
            raise _fail(path, line, "bảng thiếu owner")
    elif row.target or row.owner:
        raise _fail(path, line, "fate không phải table thì target và owner phải rỗng")
    if row.owner == "A" and (row.tree != "client_2026" or row.fate != "table"):
        raise _fail(path, line, "owner A chỉ ghi bảng client")
    if row.owner == "B" and (row.tree == "client_2026" or row.fate != "table"):
        raise _fail(path, line, "owner B chỉ ghi bảng máy chủ")
    if row.owner == "C" and not _owner_c(row):
        raise _fail(path, line, "owner C chỉ ghi scene_load_refs từ Script")
    if (row.key_field == "") != (row.key == ""):
        raise _fail(path, line, "key và key_field phải cùng rỗng hoặc cùng có")
    if row.key and not KEY_VALUE.fullmatch(row.key):
        raise _fail(path, line, f"key không hợp lệ: {row.key}")
    if row.key_field == "box_key" and not row.target.endswith("/loot_box_entries.tsv"):
        raise _fail(path, line, "box_key không trỏ loot_box_entries.tsv")
    if row.key_field == "shop_key" and not row.target.endswith("/random_shop_goods.tsv"):
        raise _fail(path, line, "shop_key không trỏ random_shop_goods.tsv")
    if row.key_field == "variant" and not row.target.startswith(f"tables/variants/{row.key}/"):
        raise _fail(path, line, "variant không nằm trong thư mục khoá")


def _owner_c(row: NameRow) -> bool:
    if row.tree != "public_data" or row.source != "Script":
        return False
    targets = {
        "tables/server/scene_load_refs.tsv",
        "tables/server/scene_level_files.tsv",
    }
    return row.target in targets


def read_name_map(path: Path | str | None = None) -> tuple[NameRow, ...]:
    """Đọc table_names.tsv. Sai cột, sai fate hoặc đường dẫn lạ là lỗi."""
    source_path = Path(path) if path is not None else _default_name_map()
    lines = _read_text(source_path).split("\n")[:-1]
    header: tuple[str, ...] | None = None
    rows: list[NameRow] = []
    seen: set[tuple[str, str, str, str, str]] = set()
    for number, line in enumerate(lines, start=1):
        if line == "" or line.startswith("#"):
            continue
        cells = line.split("\t")
        if header is None:
            header = tuple(cells)
            if header != NAME_COLUMNS:
                raise _fail(source_path, number, "thiếu cột của bảng tên")
            continue
        if len(cells) != len(header):
            raise _fail(source_path, number, f"{len(cells)} ô, cần {len(header)}")
        row = NameRow(*cells)
        _check_name_row(source_path, number, row)
        identity = (row.tree, row.source, row.fate, row.target, row.key)
        if identity in seen:
            raise _fail(source_path, number, "dòng tên trùng")
        seen.add(identity)
        rows.append(row)
    if header is None:
        raise _fail(source_path, 1, "bảng tên không có dòng tên cột")
    return tuple(rows)
