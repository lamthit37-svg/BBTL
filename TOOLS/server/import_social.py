"""Nhập dữ liệu xã hội của máy chủ 14 môn phái (XJL7457) mà client 2026 không có.

  python TOOLS/server/import_social.py <gốc dev/server> <gốc tlbb của XJL7457>
  python TOOLS/server/import_social.py <gốc dev/server> <gốc tlbb của XJL7457> --check

Bảng ghi vào <gốc>/tables/server:
  chat_blocked_words.tsv  từ cấm của máy chủ gốc (Server/Config/Filt.txt và FiltV2.txt) mà text_filter.tsv của
                          client 2026 (dòng type 1) chưa có. Cột index, word, origin (filt, filt_v2 hoặc
                          filt+filt_v2). Thứ bậc nguồn: client 2026 là chuẩn, nên từ đã có ở client không nhập lại.
  rank_boards.tsv         các bảng xếp hạng mà ScriptGlobal.lua của máy chủ gốc đọc/ghi (SetPaimingold,
                          GetPaimingold: khoá bảng sang tệp Server/Config/Paiming/<tên>.txt, mười dòng đầu).
                          Cột board_id, name, capacity. Chỉ nhập KHUNG bảng: dòng người chơi trong tệp Paiming là
                          dữ liệu vận hành của một máy chủ đã chạy, không phải cấu hình, nên không nhập.

Đầu vào hỏng thì dừng với thông báo tệp:dòng, không ghi gì. Cần text_filter.tsv ở <gốc>/tables/shared (bảng client
đã xuất).
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

import scene_xref
import tsv_file

TOOL = "import_social.py"
SERVER_CONFIG = "Server/Config"
SCRIPT_GLOBAL = "Public/Data/Script/ScriptGlobal.lua"
PAIMING = "Paiming"
INTEGER = re.compile(r"^[0-9]+$")
KEY_FILE = re.compile(r'key\s*==\s*([0-9]+)\s*then\s*mystring\s*=\s*"([A-Za-z0-9_]+)"')
DEFAULT_FILE = re.compile(r'local\s+mystring\s*=\s*"([A-Za-z0-9_]+)"')
LOOP_COUNT = re.compile(r"for\s+i\s*=\s*1\s*,\s*([0-9]+)\s+do")
MAX_WORD_CODEPOINTS = 256  # trần của WordFilter (src/server/social/wordfilter.cpp): từ dài hơn bị bỏ
CLIENT_TEXT_COLUMNS = 3  # text_filter.tsv: id, text, type (đọc theo vị trí, tên cột trong bảng client là chung chung)
CLIENT_BLOCKED_TYPE = "1"


class SocialImportError(ValueError):
    """Đầu vào hỏng; thông báo đã có tệp:dòng."""


@dataclass(frozen=True)
class Output:
    name: str
    source: str
    types: tuple[str, ...]
    columns: tuple[str, ...]
    rows: tuple[tuple[str, ...], ...]
    note: str


def _lines(path: Path) -> list[str]:
    """Tệp chữ của bản private: GBK, kết thúc dòng CRLF hoặc LF."""
    text = scene_xref.decode_text(path.read_bytes())
    return text.replace("\r\n", "\n").replace("\r", "\n").split("\n")


def _check_word(path: Path, number: int, word: str) -> None:
    for char in word:
        if ord(char) < 0x20 or ord(char) == 0x7F:
            raise SocialImportError(f"{path.name}:{number}: từ có ký tự điều khiển {ord(char):#04x}")


def read_plain_words(path: Path) -> list[tuple[int, str]]:
    """Filt.txt: mỗi dòng một từ. Dòng trống bỏ; khoảng trắng đầu cuối bỏ (soạn tay, gần như chắc là nhầm)."""
    words = []
    for number, line in enumerate(_lines(path), start=1):
        word = line.strip()
        if word:
            _check_word(path, number, word)
            words.append((number, word))
    return words


def read_typed_words(path: Path) -> list[tuple[int, str]]:
    """FiltV2.txt: dòng kiểu "INT<tab>STRING", dòng tên cột, rồi "số<tab>từ"."""
    lines = _lines(path)
    if len(lines) < 2 or lines[0].strip().split("\t") != ["INT", "STRING"]:
        raise SocialImportError(f"{path.name}:1: dòng đầu phải là 'INT<tab>STRING'")
    words = []
    for number, line in enumerate(lines[2:], start=3):
        if not line.strip():
            continue
        cells = line.split("\t")
        if len(cells) != 2 or not INTEGER.fullmatch(cells[0].strip()):
            raise SocialImportError(f"{path.name}:{number}: cần 'số<tab>từ', gặp {line!r}")
        word = cells[1].strip()
        if word:
            _check_word(path, number, word)
            words.append((number, word))
    return words


def client_blocked_words(tables: Path) -> set[str]:
    """Từ cấm type 1 của client 2026 (cột theo vị trí: id, text, type)."""
    path = tables / "shared" / "text_filter.tsv"
    if not path.is_file():
        raise SocialImportError(f"{path}:1: thiếu bảng client text_filter.tsv, chạy bộ xuất client trước")
    table = tsv_file.read_table(path)
    if len(table.columns) < CLIENT_TEXT_COLUMNS:
        raise SocialImportError(f"{path}:1: cần {CLIENT_TEXT_COLUMNS} cột (id, text, type), có {len(table.columns)}")
    return {row[1] for row in table.rows if row[2] == CLIENT_BLOCKED_TYPE}


def blocked_words(server_config: Path, tables: Path) -> Output:
    known = client_blocked_words(tables)
    sources = (("filt", read_plain_words(server_config / "Filt.txt")),
               ("filt_v2", read_typed_words(server_config / "FiltV2.txt")))
    origins: dict[str, list[str]] = {}
    already = too_long = 0
    for origin, words in sources:
        for _number, word in words:
            if word in known:
                already += 1
            elif len(word) > MAX_WORD_CODEPOINTS:
                too_long += 1
            elif origin not in origins.setdefault(word, []):
                origins[word].append(origin)
    rows = tuple((str(index), word, "+".join(found)) for index, (word, found) in enumerate(origins.items(), start=1))
    total = sum(len(words) for _origin, words in sources)
    note = (f"{total} từ ở hai tệp gốc, {already} lượt đã có ở client, {too_long} từ quá {MAX_WORD_CODEPOINTS} "
            f"ký tự bị bỏ, {len(rows)} từ nhập")
    return Output("chat_blocked_words.tsv", f"XJL7457/{SERVER_CONFIG}/Filt.txt+FiltV2.txt", ("int", "text", "text"),
                  ("index", "word", "origin"), rows, note)


def _function_text(script: str, name: str, path: Path) -> str:
    """Thân hàm Lua cấp cao nhất: từ dòng 'function <tên>(' tới 'function' kế tiếp ở đầu dòng."""
    start = re.search(rf"^function\s+{re.escape(name)}\s*\(", script, re.MULTILINE)
    if start is None:
        raise SocialImportError(f"{path.name}:1: không thấy hàm {name}")
    end = re.search(r"^function\s", script[start.end():], re.MULTILINE)
    return script[start.start(): start.end() + end.start()] if end else script[start.start():]


def read_rank_script(path: Path) -> tuple[dict[int, str], int]:
    """Khoá bảng sang tên tệp, và số dòng đọc (GetPaimingold). Hai hàm ghi/đọc phải khớp nhau."""
    script = scene_xref.decode_text(path.read_bytes())
    writer = _function_text(script, "SetPaimingold", path)
    reader = _function_text(script, "GetPaimingold", path)
    mapping = {int(key): name for key, name in KEY_FILE.findall(reader)}
    if not mapping:
        raise SocialImportError(f"{path.name}:1: GetPaimingold không có khoá bảng nào")
    if {int(key): name for key, name in KEY_FILE.findall(writer)} != mapping:
        raise SocialImportError(f"{path.name}:1: SetPaimingold và GetPaimingold ánh xạ khoá bảng khác nhau")
    default = DEFAULT_FILE.search(reader)
    if default is None or default.group(1) not in mapping.values():
        raise SocialImportError(f"{path.name}:1: tệp mặc định của GetPaimingold không nằm trong ánh xạ")
    loop = LOOP_COUNT.search(reader)
    if loop is None or int(loop.group(1)) < 1:
        raise SocialImportError(f"{path.name}:1: GetPaimingold không có vòng 'for i=1, N do'")
    return mapping, int(loop.group(1))


def rank_boards(xjl: Path) -> Output:
    mapping, capacity = read_rank_script(xjl / SCRIPT_GLOBAL)
    folder = xjl / SERVER_CONFIG / PAIMING
    players = 0
    for name in sorted(set(mapping.values())):
        path = folder / f"{name}.txt"
        if not path.is_file():
            raise SocialImportError(f"{path.name}:1: ScriptGlobal.lua trỏ tới tệp xếp hạng không có ở {folder.name}")
        players += len([line for line in _lines(path) if line.strip()]) // 5
    rows = tuple((str(key), mapping[key], str(capacity)) for key in sorted(mapping))
    note = f"{len(rows)} bảng, mỗi bảng {capacity} dòng; bỏ {players} dòng người chơi (dữ liệu vận hành, không nhập)"
    return Output("rank_boards.tsv", f"XJL7457/{SCRIPT_GLOBAL}", ("int", "text", "int"),
                  ("board_id", "name", "capacity"), rows, note)


def build(server_root: Path, xjl: Path) -> list[Output]:
    return [blocked_words(xjl / SERVER_CONFIG, server_root / "tables"), rank_boards(xjl)]


def run(server_root: Path, xjl: Path, check: bool) -> int:
    outputs = build(server_root, xjl)
    status = 0
    for out in outputs:
        path = server_root / "tables" / "server" / out.name
        text = tsv_file.render_table(out.source, TOOL, out.types, out.columns, out.rows)
        if check:
            if not (path.is_file() and path.read_bytes().decode("utf-8") == text):
                print(f"{path}:1: bảng lệch hoặc thiếu so với {TOOL}", file=sys.stderr)
                status = 1
            continue
        tsv_file.write_table(path, out.source, TOOL, out.types, out.columns, out.rows)
        print(f"đã ghi {out.name} ({len(out.rows)} dòng): {out.note}")
    return status


def main(argv: list[str]) -> int:
    args = [item for item in argv if not item.startswith("--")]
    if len(args) != 2 or "--help" in argv:
        print(__doc__)
        return 0 if "--help" in argv else 1
    try:
        return run(Path(args[0]), Path(args[1]), "--check" in argv)
    except (SocialImportError, tsv_file.TsvError) as error:
        print(f"{TOOL}:1: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv[1:]))
