"""Lõi của cfgtool: đọc, kiểm theo lược đồ của bộ đọc C++, căn chỉnh và xuất đúng định dạng máy chủ.

Định dạng máy chủ cần (rút từ detail/parse.cpp, detail/read*.cpp và TOOLS/server/config_style.py):
- TOML (toml++), UTF-8 không BOM, xuống dòng LF, kết thúc bằng một dấu xuống dòng, tối đa 1048576 byte.
- Khoá gốc schema = 1. Khoá lạ, nhóm lạ, thiếu khoá bắt buộc, sai kiểu hay ngoài miền đều là lỗi.
- Bố cục của dự án: khung tiêu đề, chú thích tiếng Việt cho mọi khoá, dấu = và # thẳng cột, dòng <= 110 cột.
Công cụ không bao giờ mở *.local.toml (giống máy chủ) và không in giá trị khoá bí mật.
"""
from __future__ import annotations

import re
import sys
import tomllib
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "server"))
from config_style import GAP, KEY, LINE_LIMIT, RULE, TABLE, align_lines, banner, comment, comment_start  # noqa: E402

import schema as S  # noqa: E402

MAX_DOCUMENT = 1048576
MAX_TEXT = 4096
MAX_ARRAY = 256
MASK = "••••••"

HEADER = re.compile(r"^\s*(\[\[?)\s*([A-Za-z0-9_.-]+)\s*\]\]?")
KEYNAME = re.compile(r"^\s*([A-Za-z0-9_-]+)\s*=")
IDENT = re.compile(r"^[A-Za-z][A-Za-z0-9_-]{0,62}$")


class SecretFileError(Exception):
    """Ai đó đưa tệp *.local.toml cho công cụ."""


@dataclass
class Issue:
    line: int
    message: str       # đúng câu của bộ đọc C++
    hint: str = ""     # giải thích thêm cho người sửa

    def text(self) -> str:
        return f"dòng {self.line}: {self.message}" + (f" — {self.hint}" if self.hint else "")


def guard(name: str) -> None:
    if S.is_secret_file(name):
        raise SecretFileError(f"{name} là tệp bí mật: công cụ không mở, không đọc, không xuất tệp *.local.toml")


# ---------------------------------------------------------------- chỉ mục dòng
class LineIndex:
    """Dòng của từng nhóm và khoá trong văn bản, để báo lỗi theo dòng và sửa giá trị tại chỗ."""

    def __init__(self, text: str):
        self.lines = text.split("\n")
        self.headers: dict[tuple[str, int], int] = {}
        self.keys: dict[tuple[str, int, str], int] = {}
        counter: dict[str, int] = {}
        group, row = "", -1
        for number, line in enumerate(self.lines, start=1):
            if line.lstrip().startswith("#"):
                continue
            head = HEADER.match(line)
            if head:
                group = head.group(2)
                if head.group(1) == "[[":
                    counter[group] = counter.get(group, -1) + 1
                    row = counter[group]
                else:
                    row = -1
                self.headers[(group, row)] = number
                continue
            key = KEYNAME.match(line)
            if key:
                self.keys.setdefault((group, row, key.group(1)), number)

    def key_line(self, group: str, row: int, key: str, fallback: int = 1) -> int:
        return self.keys.get((group, row, key), fallback)

    def group_line(self, group: str, row: int = -1) -> int:
        if (group, row) in self.headers:
            return self.headers[(group, row)]
        # Bảng ngầm (chỉ có [cha.con]): toml++ ghi dòng của bảng con đầu tiên.
        nested = [n for (g, _), n in self.headers.items() if group and g.startswith(group + ".")]
        return min(nested) if nested else 1

    def note_at(self, number: int) -> str:
        """Chú thích ngang hàng hoặc ngay dòng trên của khoá ở dòng number."""
        if not 1 <= number <= len(self.lines):
            return ""
        line = self.lines[number - 1]
        at = comment_start(line.split("=", 1)[1]) if "=" in line else None
        if at is not None:
            return line.split("=", 1)[1][at + 1:].strip()
        above = self.lines[number - 2] if number >= 2 else ""
        return above[1:].strip() if above.startswith("#") and above != RULE else ""


# ---------------------------------------------------------------- kiểm giá trị
def is_int(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def ipv4_ok(text: str) -> bool:
    parts = text.split(".")
    if len(parts) != 4:
        return False
    for part in parts:
        if not part.isdigit() or not part.isascii() or len(part) > 3 or (len(part) > 1 and part[0] == "0"):
            return False
        if int(part) > 255:
            return False
    return True


def port_text_ok(text: str) -> bool:
    if not text or not text.isdigit() or not text.isascii() or (len(text) > 1 and text[0] == "0"):
        return False
    return 1 <= int(text) <= 65535


def endpoint_ok(text: str) -> bool:
    colon = text.rfind(":")
    if colon <= 0 or colon + 1 >= len(text):
        return False
    host, port = text[:colon], text[colon + 1:]
    if not ipv4_ok(host):
        return False
    return (port == "0" and host == "127.0.0.1") or port_text_ok(port)


def cidr_ok(text: str) -> bool:
    slash = text.rfind("/")
    if slash <= 0 or slash + 1 >= len(text):
        return False
    prefix = text[slash + 1:]
    if not prefix.isdigit() or not prefix.isascii() or (len(prefix) > 1 and prefix[0] == "0"):
        return False
    return ipv4_ok(text[:slash]) and int(prefix) <= 32


def text_fits(value: str, lo: int, hi: int) -> bool:
    size = len(value.encode("utf-8"))
    return lo <= size <= hi and not any(ord(c) < 0x20 or ord(c) == 0x7F for c in value)


def range_text(f: S.Field) -> str:
    if f.kind == "choice":
        return " | ".join(f.choices)
    if f.kind in ("int", "schema"):
        hi = "2147483647" if f.hi == S.INT_MOST else str(f.hi)
        return f"{f.lo} – {hi}"
    if f.kind == "text":
        return f"{f.lo} – {f.hi} byte, không ký tự điều khiển"
    if f.kind == "int_list":
        return f"phần tử {f.lo} – {f.hi}; 1 – {f.most} phần tử"
    if f.kind == "hours":
        return "0 – 23; tối đa 24 phần tử"
    if f.kind in ("port",):
        return "1 – 65535"
    if f.kind == "listen_port":
        return "1 – 65535 (0 khi host = 127.0.0.1)"
    return ""


def check_value(f: S.Field, value, line: int, host=None) -> list[Issue]:
    k = f.kind
    need = f"cần {S.KIND_TEXT.get(k, k)}" + (f", miền {range_text(f)}" if range_text(f) else "")
    wrong = [Issue(line, f"khoá {f.key} sai kiểu", need)]
    out_ = [Issue(line, f"khoá {f.key} ngoài miền", need)]
    if k in ("int", "schema", "port"):
        if not is_int(value):
            return wrong
        return [] if f.lo <= value <= f.hi else out_
    if k == "listen_port":
        if not is_int(value):
            return wrong
        if 1 <= value <= 65535 or (value == 0 and isinstance(host, str) and host == "127.0.0.1"):
            return []
        return out_
    if k == "flag":
        return [] if isinstance(value, bool) else wrong
    if k in ("text", "ident", "ipv4", "endpoint", "choice"):
        if not isinstance(value, str):
            return wrong
        if len(value.encode("utf-8")) > MAX_TEXT:
            return out_
        ok = {
            "text": lambda v: text_fits(v, f.lo, f.hi),
            "ident": lambda v: bool(IDENT.match(v)),
            "ipv4": ipv4_ok,
            "endpoint": endpoint_ok,
            "choice": lambda v: v in f.choices,
        }[k](value)
        return [] if ok else out_
    if k in ("ipv4_list", "cidr_list", "hours", "int_list"):
        if not isinstance(value, list):
            return wrong
        if len(value) > MAX_ARRAY:
            return [Issue(line, f"mảng {f.key} vượt trần", need)]
        issues: list[Issue] = []
        if k in ("ipv4_list", "cidr_list"):
            test = ipv4_ok if k == "ipv4_list" else cidr_ok
            for item in value:
                if not isinstance(item, str):
                    issues.append(Issue(line, f"phần tử của {f.key} sai kiểu", need))
                elif not test(item):
                    issues.append(Issue(line, f"khoá {f.key} ngoài miền", f"{item!r} không hợp lệ; {need}"))
            return issues
        if k == "hours":
            if len(value) > 24:
                return [Issue(line, f"mảng {f.key} vượt trần", need)]
            good = []
            for item in value:
                if not is_int(item):
                    issues.append(Issue(line, f"phần tử của {f.key} sai kiểu", need))
                elif not 0 <= item <= 23:
                    issues.append(Issue(line, f"khoá {f.key} ngoài miền", need))
                else:
                    good.append(item)
            if len(set(good)) != len(good):
                issues.append(Issue(line, f"khoá {f.key} có giờ lặp", "mỗi giờ chỉ ghi một lần"))
            return issues
        if not value or len(value) > f.most:
            return [Issue(line, f"mảng {f.key} rỗng hoặc vượt trần", need)]
        good = []
        for item in value:
            if not is_int(item):
                issues.append(Issue(line, f"phần tử của {f.key} sai kiểu", need))
            elif not f.lo <= item <= f.hi:
                issues.append(Issue(line, f"phần tử của {f.key} ngoài miền", need))
            else:
                good.append(item)
        if not issues and len(set(good)) != len(good):
            issues.append(Issue(line, f"khoá {f.key} có giá trị lặp", "mỗi id chỉ ghi một lần"))
        return issues
    return wrong


# ---------------------------------------------------------------- đọc tệp
def parse(text: str) -> tuple[dict | None, list[Issue]]:
    if len(text.encode("utf-8")) > MAX_DOCUMENT:
        return None, [Issue(1, "tệp vượt trần 1048576 byte")]
    try:
        return tomllib.loads(text), []
    except tomllib.TOMLDecodeError as error:
        found = re.search(r"line (\d+)", str(error))
        return None, [Issue(int(found.group(1)) if found else 1, f"lỗi cú pháp: {error}", "sửa cú pháp TOML trước")]


def children_of(spec: S.FileSpec, path: str) -> list[str]:
    depth = 0 if not path else path.count(".") + 1
    prefix = path + "." if path else ""
    names = []
    for g in spec.groups:
        if g.path and g.path.startswith(prefix) and g.path.count(".") == depth:
            names.append(g.path.split(".")[-1])
    return names


def check_table(spec: S.FileSpec, group: S.Group, table: dict, index: LineIndex, row: int, issues: list[Issue]) -> dict:
    """Kiểm một bảng; trả các giá trị hợp lệ (để kiểm chéo)."""
    allowed = {f.key for f in group.fields} | set(children_of(spec, group.path))
    for key, value in table.items():
        if key not in allowed:
            what = "nhóm lạ" if isinstance(value, dict) or (isinstance(value, list) and value and isinstance(value[0], dict)) else "khoá lạ"
            line = index.key_line(group.path, row, key, index.group_line(f"{group.path}.{key}" if group.path else key))
            issues.append(Issue(line, f"{what} {key}", f"bộ đọc chỉ nhận: {', '.join(sorted(allowed))}"))
    head_line = 1 if not group.path else index.group_line(group.path, row)
    good: dict = {}
    for f in group.fields:
        if f.key not in table:
            if f.required:
                issues.append(Issue(head_line, f"thiếu khoá {f.key}", f"khoá bắt buộc; gợi ý production: {f.key} = {f.prod}"))
            continue
        line = index.key_line(group.path, row, f.key, head_line)
        found = check_value(f, table[f.key], line, host=table.get("host"))
        issues.extend(found)
        if not found:
            good[f.key] = table[f.key]
    return good


def validate(name: str, text: str) -> list[Issue]:
    guard(name)
    data, issues = parse(text)
    if data is None:
        return issues
    index = LineIndex(text)
    spec = S.spec_for(name)
    if spec is None:  # rules/*.toml, scene.toml: config::read_loose
        if "schema" not in data:
            return [Issue(1, "thiếu khoá schema", "tệp luật phải có schema = 1")]
        found = check_value(S.SCHEMA, data["schema"], index.key_line("", -1, "schema"))
        return found
    rows_good: dict[str, list] = {}
    for group in spec.groups:
        if not group.path:
            check_table(spec, group, data, index, -1, issues)
            continue
        parent_path, _, last = group.path.rpartition(".")
        parent = data
        for part in parent_path.split(".") if parent_path else []:
            parent = parent.get(part) if isinstance(parent, dict) else None
        if not isinstance(parent, dict):
            continue  # nhóm cha đã báo lỗi
        parent_line = 1 if not parent_path else index.group_line(parent_path)
        if last not in parent:
            if group.required:
                hint = "nhóm bắt buộc" + (f": thêm [[{group.path}]]" if group.rows else f": thêm [{group.path}]")
                issues.append(Issue(parent_line, f"thiếu khoá {last}", hint))
            continue
        node = parent[last]
        if group.rows:
            if not isinstance(node, list):
                issues.append(Issue(index.group_line(group.path), f"khoá {last} sai kiểu", f"cần các khối [[{group.path}]]"))
                continue
            if len(node) > group.most:
                issues.append(Issue(index.group_line(group.path, 0), f"mảng {last} vượt trần", f"tối đa {group.most} khối"))
                continue
            rows_good[group.path] = []
            for row, item in enumerate(node):
                if not isinstance(item, dict):
                    issues.append(Issue(parent_line, f"phần tử của {last} sai kiểu", f"mỗi phần tử phải là khối [[{group.path}]]"))
                    continue
                good = check_table(spec, group, item, index, row, issues)
                whole = all(f.key in good for f in group.fields if f.required)
                rows_good[group.path].append((row, good if whole else None))
        else:
            if not isinstance(node, dict):
                issues.append(Issue(parent_line, f"khoá {last} sai kiểu", f"cần nhóm [{group.path}]"))
                continue
            check_table(spec, group, node, index, -1, issues)
    issues.extend(cross_check(name, rows_good, index))
    issues.sort(key=lambda i: (i.line, i.message))
    return issues


def cross_check(name: str, rows: dict, index: LineIndex) -> list[Issue]:
    issues: list[Issue] = []
    if name == "cluster.toml":
        machines = [(r, g) for r, g in rows.get("machine", []) if g]
        seen: list[int] = []
        for r, g in machines:
            if g["id"] in seen:
                issues.append(Issue(index.group_line("machine", r), "id máy lặp", "mỗi [[machine]] một id riêng"))
            seen.append(g["id"])
        pairs: list[tuple] = []
        for r, g in rows.get("process", []):
            if not g:
                continue
            line = index.group_line("process", r)
            if (g["kind"], g["id"]) in pairs:
                issues.append(Issue(line, "cặp kind và id lặp", "tăng id của khối trùng"))
            pairs.append((g["kind"], g["id"]))
            if g["machine"] not in seen:
                issues.append(Issue(line, "máy không có trong danh sách", "thêm [[machine]] có id này hoặc sửa machine"))
    if name == "supervisor.toml":
        seen_p: list[str] = []
        for r, g in rows.get("start", []):
            if not g:
                continue
            if g["process"] in seen_p:
                issues.append(Issue(index.group_line("start", r), "process của start lặp", "mỗi loại tiến trình một bước"))
            seen_p.append(g["process"])
    return issues


def check_startup(folder: Path) -> list[Issue]:
    """config::check_startup: mỗi bước [[start]] trừ gate cần ít nhất một [[process]] cùng loại trong cluster."""
    try:
        cluster = tomllib.loads((folder / "cluster.toml").read_text(encoding="utf-8"))
        supervisor_text = (folder / "supervisor.toml").read_text(encoding="utf-8")
        supervisor = tomllib.loads(supervisor_text)
    except (OSError, tomllib.TOMLDecodeError):
        return []
    kinds = {p.get("kind") for p in cluster.get("process", []) if isinstance(p, dict)}
    index = LineIndex(supervisor_text)
    issues = []
    for row, step in enumerate(supervisor.get("start", [])):
        process = step.get("process") if isinstance(step, dict) else None
        if process and process != "gate" and process not in kinds:
            issues.append(Issue(index.group_line("start", row), f"thiếu process {process} trong cluster",
                                f"thêm khối [[process]] kind = \"{process}\" vào cluster.toml"))
    return issues


# ---------------------------------------------------------------- căn chỉnh và xuất
def decode(raw: bytes) -> tuple[str, list[str]]:
    notes = []
    if raw.startswith(b"\xef\xbb\xbf"):
        raw = raw[3:]
        notes.append("bỏ BOM UTF-8")
    elif raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        notes.append("đổi UTF-16 sang UTF-8")
        return decode(raw.decode("utf-16").encode("utf-8"))[0], notes
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as error:
        raise ValueError(f"tệp không phải UTF-8 (byte {error.start}); lưu lại bằng UTF-8 rồi nhập lại") from error
    if "\r" in text:
        text = text.replace("\r\n", "\n").replace("\r", "\n")
        notes.append("đổi xuống dòng CRLF/CR sang LF")
    return text, notes


def short_note(f: S.Field) -> str:
    note = f.desc.split("; ")[0].split(" (")[0].rstrip(".")
    return note + (f", {f.unit}" if f.unit and f.unit not in note else "")


def fit_lines(lines: list[str]) -> list[str]:
    """Căn cột; dòng nào quá 110 cột thì đưa chú thích lên dòng trên rồi căn lại."""
    for _ in range(50):
        aligned = align_lines(lines)
        long_at = next((i for i, l in enumerate(aligned) if len(l) > LINE_LIMIT and KEY.match(l)), None)
        if long_at is None:
            return aligned
        line = lines[long_at]
        key, rest = line.split("=", 1)
        at = comment_start(rest)
        if at is None:
            return aligned
        note = rest[at + 1:].strip()
        lines = lines[:long_at] + comment(note) + [f"{key.strip()} = {rest[:at].strip()}"] + lines[long_at + 1:]
    return align_lines(lines)


def fmt(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        out = value.replace("\\", "\\\\").replace('"', '\\"')
        out = "".join(c if ord(c) >= 0x20 and c != "\x7f" else f"\\u{ord(c):04X}" for c in out)
        return f'"{out}"'
    if isinstance(value, list):
        return "[" + ", ".join(fmt(v) for v in value) + "]"
    raise ValueError("kiểu không ghi được ra cấu hình")


def render_canonical(name: str, data: dict) -> str:
    """Dựng lại cả tệp theo đúng bố cục dự án và thứ tự khoá của bộ đọc (khi tệp nhập không có bố cục)."""
    spec = S.spec_for(name)
    if spec is None:
        title = name.removesuffix(".toml").upper()
        out = banner(f"LUẬT {title}")
        groups = [("Chung", None, {k: v for k, v in data.items() if not isinstance(v, dict)})]
        groups += [(k, f"[{k}]", v) for k, v in data.items() if isinstance(v, dict)]
        for title_, header, values in groups:
            out += [""] + banner(title_)
            if header:
                out.append(header)
            for key, value in values.items():
                out.append(f"{key} = {fmt(value)}" + ("   # Phiên bản bố cục của tệp" if key == "schema" else ""))
        return "\n".join(fit_lines(out)) + "\n"
    out = banner(spec.title)
    for paragraph in spec.intro:
        out += comment(paragraph)
    for group in spec.groups:
        if not group.fields:
            continue
        node = data
        for part in group.path.split(".") if group.path else []:
            node = node.get(part, {}) if isinstance(node, dict) else {}
        blocks = node if group.rows else [node]
        if group.rows and not isinstance(blocks, list):
            blocks = []
        if not group.required and not blocks or (not group.rows and group.path and not group.required and not node):
            continue
        for block in blocks:
            out += [""] + banner(group.title)
            if group.about:
                out += comment(group.about)
            if group.path:
                out.append(f"[[{group.path}]]" if group.rows else f"[{group.path}]")
            known = set()
            for f in group.fields:
                known.add(f.key)
                if f.key not in block:
                    continue
                value = "\"\"" if f.secret else fmt(block[f.key])
                out.append(f"{f.key} = {value}   # {short_note(f)}")
            for key, value in block.items():  # khoá lạ: giữ lại để người dùng thấy lỗi
                if key not in known and not isinstance(value, (dict, list)) or (key not in known and isinstance(value, list) and not (value and isinstance(value[0], dict))):
                    out.append(f"{key} = {fmt(value)}   # khoá lạ: bộ đọc sẽ từ chối")
    return "\n".join(fit_lines(out)) + "\n"


def has_layout(text: str) -> bool:
    lines = text.split("\n")
    return len(lines) >= 3 and lines[0] == RULE and lines[2] == RULE and lines[1].startswith("# ")


def add_missing_notes(name: str, text: str) -> str:
    spec = S.spec_for(name)
    if spec is None:
        return text
    lines = text.split("\n")
    index = LineIndex(text)
    fields = {(g.path, f.key): f for g in spec.groups for f in g.fields}
    for (group, row, key), number in index.keys.items():
        f = fields.get((group, key))
        if f is None or index.note_at(number):
            continue
        lines[number - 1] = lines[number - 1].rstrip() + f"   # {short_note(f)}"
    return "\n".join(lines)


def clean_lines(text: str) -> str:
    lines = []
    for line in text.split("\n"):
        line = line.rstrip()
        if "\t" in line and '"' not in line and "'" not in line:
            line = line.replace("\t", " ")
        if line == "" and lines and lines[-1] == "":
            continue
        lines.append(line)
    while lines and lines[-1] == "":
        lines.pop()
    while lines and lines[0] == "":
        lines.pop(0)
    return "\n".join(lines) + "\n"


def normalize(name: str, raw: bytes | str) -> tuple[str, list[str]]:
    """Nhập một tệp: giải mã, căn chỉnh, thêm chú thích còn thiếu. Không đổi giá trị nào (trừ mật khẩu mẫu)."""
    guard(name)
    text, notes = decode(raw) if isinstance(raw, bytes) else (raw, [])
    before = text
    text = clean_lines(text)
    data, problems = parse(text)
    if data is None:
        return text, notes + ["tệp sai cú pháp: chỉ dọn khoảng trắng, chưa căn được"]
    if not has_layout(text):
        text = render_canonical(name, data)
        notes.append("tệp chưa có bố cục dự án: dựng lại theo thứ tự khoá của bộ đọc")
    else:
        text = add_missing_notes(name, text)
        lines = text[:-1].split("\n") if text.endswith("\n") else text.split("\n")
        text = "\n".join(fit_lines(lines)) + "\n"
    if name == "secrets.example.toml":
        text = blank_secrets(text)
    if tomllib.loads(text) != tomllib.loads(clean_lines(before)) and name != "secrets.example.toml":
        raise AssertionError("căn chỉnh làm đổi giá trị: dừng để không hỏng tệp")
    if text != before:
        notes.append("căn thẳng cột dấu = và #, dọn khoảng trắng")
    return text, notes


def blank_secrets(text: str) -> str:
    """Tệp mẫu không bao giờ mang mật khẩu: mọi khoá secret ghi thành chuỗi rỗng."""
    spec = S.spec_for("secrets.example.toml")
    secret = {(g.path, f.key) for g in spec.groups for f in g.fields if f.secret}
    index = LineIndex(text)
    lines = text.split("\n")
    for (group, row, key), number in index.keys.items():
        if (group, key) in secret:
            line = lines[number - 1]
            head, rest = line.split("=", 1)
            at = comment_start(rest)
            note = rest[at:] if at is not None else ""
            value = rest[:at] if at is not None else rest
            pad = len(value) - len(value.lstrip())
            new_value = " " * pad + '""'
            lines[number - 1] = head + "=" + (new_value.ljust(len(value)) if note else new_value) + note
    out = "\n".join(lines)
    return "\n".join(align_lines(out.split("\n")))


def export_bytes(name: str, text: str) -> bytes:
    guard(name)
    out, _ = normalize(name, text)
    return out.encode("utf-8")


def write_export(path: Path, text: str) -> bytes:
    guard(path.name)
    data = export_bytes(path.name, text)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return data


def set_value(name: str, text: str, group: str, row: int, key: str, value_toml: str) -> str:
    """Đổi giá trị một khoá tại chỗ (giữ chú thích), rồi căn lại. value_toml là giá trị viết dạng TOML."""
    guard(name)
    try:
        tomllib.loads(f"v = {value_toml}")
    except tomllib.TOMLDecodeError as error:
        raise ValueError(f"giá trị không phải TOML hợp lệ: {error}") from error
    index = LineIndex(text)
    lines = text.split("\n")
    number = index.keys.get((group, row, key))
    if number is None:
        spec = S.spec_for(name)
        f = next((f for g in (spec.groups if spec else ()) if g.path == group for f in g.fields if f.key == key), None)
        note = f"   # {short_note(f)}" if f else ""
        after = max([n for (g, r, _), n in index.keys.items() if g == group and r == row] or [index.group_line(group, row)])
        lines.insert(after, f"{key} = {value_toml}{note}")
    else:
        line = lines[number - 1]
        head, rest = line.split("=", 1)
        at = comment_start(rest)
        lines[number - 1] = f"{head.rstrip()} = {value_toml}" + (f"   {rest[at:]}" if at is not None else "")
    out = "\n".join(lines)
    return normalize(name, out)[0]


# ---------------------------------------------------------------- bảng trường để hiển thị
def describe(name: str, text: str) -> list[dict]:
    guard(name)
    data, _ = parse(text)
    data = data or {}
    index = LineIndex(text)
    spec = S.spec_for(name)
    rows: list[dict] = []
    if spec is None:
        def walk(node: dict, group: str):
            for key, value in node.items():
                if isinstance(value, dict):
                    walk(value, f"{group}.{key}" if group else key)
                    continue
                line = index.key_line(group, -1, key)
                kind = "true/false" if isinstance(value, bool) else "số nguyên" if is_int(value) else \
                    "số thực" if isinstance(value, float) else "chuỗi" if isinstance(value, str) else "mảng"
                rows.append(dict(group=group or "(gốc)", row=-1, key=key, value=fmt(value), kind=kind,
                                 range="1 – 1" if key == "schema" else "", required="bắt buộc" if key == "schema" else "—",
                                 default="", desc=index.note_at(line), guide="Tệp luật: máy chủ (thienlong_lint) chỉ kiểm "
                                 "schema = 1; giá trị do mã zone/world đọc. Giữ đúng kiểu đang có.", prod="", unit="",
                                 line=line, secret=False, path=group))
        walk(data, "")
        return rows
    for group in spec.groups:
        if not group.fields:
            continue
        node = data
        for part in group.path.split(".") if group.path else []:
            node = node.get(part, {}) if isinstance(node, dict) else {}
        blocks = (node if isinstance(node, list) else []) if group.rows else [node if isinstance(node, dict) else {}]
        if group.rows and not blocks:
            blocks = [{}]
        for row, block in enumerate(blocks):
            r = row if group.rows else -1
            for f in group.fields:
                present = isinstance(block, dict) and f.key in block
                value = fmt(block[f.key]) if present else ""
                if f.secret and present and block[f.key] != "":
                    value = MASK
                label = (group.path or "(gốc)") + (f"[{row}]" if group.rows else "")
                rows.append(dict(group=label, row=r, key=f.key, value=value, kind=S.KIND_TEXT.get(f.kind, f.kind),
                                 range=range_text(f), required="bắt buộc" if f.required and group.required else "tuỳ chọn",
                                 default=f.default or ("không có (thiếu là lỗi)" if f.required else ""),
                                 desc=f.desc, guide=f.guide, prod=f.prod, unit=f.unit,
                                 line=index.key_line(group.path, r, f.key, 0) if present else 0,
                                 secret=f.secret, path=group.path))
    return rows


def config_files(folder: Path) -> list[Path]:
    files = [p for p in sorted(folder.glob("*.toml")) if not S.is_secret_file(p.name)]
    rules = folder / "rules"
    if rules.is_dir():
        files += [p for p in sorted(rules.glob("*.toml")) if not S.is_secret_file(p.name)]
    return files
