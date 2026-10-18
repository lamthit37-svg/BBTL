#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/content/check_i18n.py
#  PHÂN HỆ   : Content / I18n Gate
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Cổng kiểm i18n ba thứ tiếng (zh, en, vi) của client và thoại máy chủ; đỏ
#    thì ctest i18n_gate dừng. Luật chữ của chủ dự án, HO-SO.md mục 0.1.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Cổng kiểm i18n. Sáu phép kiểm, mỗi phép một chữ cái trong thông báo:

  a  ba bộ khoá của assets/i18n/{zh,en,vi}.tsv phải bằng nhau.
  b  giá trị en và vi không còn chữ Hán. Phần nằm trong thẻ #{...} là dữ liệu dẫn đường (ví dụ
     #{_INFOAIM99,200,1007,戴春生}), không phải chữ hiển thị, nên bị bỏ trước khi tìm; trong zh, en, vi
     không có thẻ lồng hay dấu } lẻ nào, thẻ kết thúc ở dấu } đầu tiên như bộ tra của client.
  c  khoá #{KHOÁ} mà client dùng và có trong StrDictionary gốc phải có ở cả ba tệp. Layout và script gốc:
     khoá còn thiếu nằm trong danh sách nền (thiếu thư mục layout, vốn do công cụ sinh và git bỏ qua, thì
     chỉ so khoá script). Thoại máy chủ dialogue.zh.txt: không có danh sách nền, mọi khoá gốc nó dùng phải
     đủ ba tệp. Mã C++ của ta: không có danh sách nền, mọi khoá mã dùng phải đủ ba tệp (khoá gốc không có
     thì là khoá ta tự đặt, cũng phải có đủ ba tệp).
  d  ba bản thoại máy chủ dialogue.{zh,en,vi}.txt phải cùng bộ khoá. Bản chưa dịch nằm trong danh sách nền.
  e  chuỗi chữ Hán hiển thị viết cứng trong src/client. Tệp cũ nằm trong danh sách nền. Hằng dùng để so
     dữ liệu gốc thì để lại, ghi "i18n-giữ: <lý do>" trong comment cùng dòng.
  f  cùng một chữ zh mà en hoặc vi dịch khác nhau (kể cả chỉ khác chữ hoa). Mỗi nhóm nằm trong danh sách nền
     cho tới khi tra được bản Việt Nam hoặc chủ dự án dịch tay (docs/DICH-TAY.txt).

Danh sách nền (TOOLS/content/i18n.baseline) chỉ được co lại: mục mới hay mục lớn thêm là đỏ; mục đã
sạch mà còn nằm trong danh sách cũng đỏ, để người chạm tệp gỡ nó. Mỗi dòng, các cột cách nhau một tab:
    khoá  <khoá>  <layout|script>  <tệp đầu tiên dùng nó>
    cứng  <đường dẫn tệp>  <số chuỗi>
    thoại <ngôn ngữ>
    lệch  <ngôn ngữ>  <số bản dịch khác nhau>  <chữ zh>

Dùng, ở gốc dự án (mã thoát 1 khi đỏ, 2 khi gọi sai):
    python -X utf8 TOOLS/content/check_i18n.py
    python -X utf8 TOOLS/content/check_i18n.py --ghi-nen     sinh danh sách nền từ hiện trạng, chỉ khi chưa có tệp
    python -X utf8 TOOLS/content/check_i18n.py --co-lai      ghi lại danh sách nền theo hiện trạng, chỉ khi không thêm mục
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
I18N = PROJECT / "assets/i18n"
STRDICT = PROJECT / "dev/server/tables/client/StrDictionary.tsv"
BASELINE = PROJECT / "TOOLS/content/i18n.baseline"
LAYOUTS = PROJECT / "dev/client/assets/Interface"
SCRIPTS = PROJECT / "src/client/script/Interface"
CLIENT_SRC = PROJECT / "src/client"
DIALOGUE = PROJECT / "dev/server/tables/server"
LANGS = ("zh", "en", "vi")
SHOWN = 12

HAN = re.compile("[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]")
TAG = re.compile(r"#\{[^}]*\}")
REF = re.compile(r"#\{([A-Za-z0-9_()]+)\}")
SPOKEN = re.compile(r"#\{\{?([A-Za-z0-9_()]+)\}?\}")
STRING = re.compile(r'"(?:[^"\\\n]|\\.)*"')
CHAR_LITERAL = re.compile(r"'(?:[^'\\\n]|\\[^\n][^'\n]*)'")
KEEP_MARK = "i18n-giữ:"
FILE_KINDS = ("image/", "file/")
SOURCE_SUFFIXES = (".cpp", ".hpp", ".h", ".c")

# Danh sách nền đọc ra: loại -> {tên: giá trị}. Khoá: (loại cửa sổ, tệp); cứng: số chuỗi; thoại: 1.
Baseline = dict[str, dict[str, object]]


@dataclass
class Report:
    problems: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    def red(self, check: str, text: str) -> None:
        self.problems.append(f"[{check}] {text}")


def read_table(path: Path) -> dict[str, str]:
    """Bảng "khoá<tab>chữ": bỏ dòng trống và dòng bắt đầu bằng #."""
    rows: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#") or "\t" not in raw:
            continue
        key, value = raw.split("\t", 1)
        rows[key] = value
    return rows


def sample(items) -> str:
    items = sorted(items)
    head = ", ".join(items[:SHOWN])
    return head + (f" ... (+{len(items) - SHOWN})" if len(items) > SHOWN else "")


def strip_comments(text: str) -> str:
    """Thay comment // và /* */ bằng dấu cách, giữ nguyên xuống dòng và mọi thứ trong chuỗi.
    Ruột ký tự ('"', '\\n') cũng thành dấu cách để dấu " trong đó không mở chuỗi giả. Chưa biết chuỗi thô
    R"(...)": chuỗi thô chứa dấu " lẻ có thể làm lệch (giới hạn đã biết)."""
    out: list[str] = []
    index, size = 0, len(text)
    while index < size:
        pair = text[index:index + 2]
        char = text[index]
        literal = CHAR_LITERAL.match(text, index) if char == "'" else None
        if literal:
            out.append("'" + " " * (literal.end() - index - 2) + "'")
            index = literal.end()
        elif char == '"':
            end = index + 1
            while end < size and text[end] not in '"\n':
                end += 2 if text[end] == "\\" else 1
            out.append(text[index:end + 1])
            index = end + 1
        elif pair == "//":
            end = text.find("\n", index)
            end = size if end < 0 else end
            out.append(" " * (end - index))
            index = end
        elif pair == "/*":
            end = text.find("*/", index + 2)
            end = size if end < 0 else end + 2
            out.append("".join("\n" if c == "\n" else " " for c in text[index:end]))
            index = end
        else:
            out.append(char)
            index += 1
    return "".join(out)


def read_baseline() -> Baseline:
    entries: Baseline = {"khoá": {}, "cứng": {}, "thoại": {}, "lệch": {}}
    if not BASELINE.exists():
        return entries
    for raw in BASELINE.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#"):
            continue
        cells = raw.split("\t")
        if cells[0] == "khoá":
            entries["khoá"][cells[1]] = (cells[2], cells[3])
        elif cells[0] == "cứng":
            entries["cứng"][cells[1]] = int(cells[2])
        elif cells[0] == "thoại":
            entries["thoại"][cells[1]] = 1
        elif cells[0] == "lệch":
            entries["lệch"][f"{cells[1]}:{cells[3]}"] = int(cells[2])
    return entries


def judge(report: Report, check: str, found: dict[str, object], base: dict[str, object], what: str) -> None:
    """So hiện trạng với danh sách nền: mới hay lớn thêm là đỏ; còn trong danh sách mà đã sạch cũng đỏ."""
    fresh = [name for name in found if name not in base]
    grown = [name for name, value in found.items() if name in base and isinstance(value, int) and value > base[name]]
    clean = [name for name in base if name not in found]
    if fresh:
        report.red(check, f"{len(fresh)} {what} chưa có trong danh sách nền: {sample(fresh)}")
    if grown:
        report.red(check, f"{len(grown)} {what} nhiều hơn danh sách nền: {sample(grown)}")
    if clean:
        report.red(check, f"{len(clean)} {what} đã sạch, gỡ khỏi TOOLS/content/i18n.baseline: {sample(clean)}")


def is_complete(key: str, tables: dict[str, dict[str, str]]) -> bool:
    return all(key in tables[lang] for lang in LANGS)


def scan_window_keys(tables, original: dict[str, str]) -> dict[str, tuple[str, str]]:
    """Khoá layout và script gốc có trong StrDictionary mà thiếu ở ít nhất một tệp: khoá -> (loại, tệp đầu)."""
    groups = [("script", sorted(SCRIPTS.glob("*/*.lua")))]
    if LAYOUTS.is_dir():
        groups.append(("layout", sorted(LAYOUTS.glob("*/*.layout.xml"))))
    found: dict[str, tuple[str, str]] = {}
    for kind, files in groups:
        for path in files:
            for key in REF.findall(path.read_text(encoding="utf-8", errors="replace")):
                if key in original and not is_complete(key, tables):
                    found.setdefault(key, (kind, path.name))
    return found


def scan_dialogue_keys(tables, original: dict[str, str]) -> set[str]:
    """Khoá từ điển gốc mà thoại máy chủ dùng (#{KHOÁ}, hay #{{KHOÁ}} trong chuỗi định dạng) thiếu ở ít nhất một tệp.
    Client tra khoá lúc vẽ; thiếu ở en hay vi thì chữ Trung của bảng gốc lộ ra giữa câu đã dịch."""
    path = DIALOGUE / "dialogue.zh.txt"
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8")
    return {key for key in SPOKEN.findall(text) if key in original and not is_complete(key, tables)}


def scan_cpp_keys(tables) -> dict[str, str]:
    """Khoá mã C++ dùng mà thiếu ở ít nhất một tệp: khoá -> tệp đầu."""
    found: dict[str, str] = {}
    for path in sorted(CLIENT_SRC.rglob("*")):
        if path.suffix not in SOURCE_SUFFIXES:
            continue
        code = strip_comments(path.read_text(encoding="utf-8", errors="replace"))
        for key in REF.findall(code):
            if not is_complete(key, tables):
                found.setdefault(key, path.relative_to(PROJECT).as_posix())
    return found


def han_literals(path: Path) -> int:
    text = path.read_text(encoding="utf-8", errors="replace")
    count = 0
    for raw, code in zip(text.splitlines(), strip_comments(text).splitlines()):
        if KEEP_MARK in raw:
            continue
        count += sum(1 for literal in STRING.findall(code) if HAN.search(literal))
    return count


def scan_hardcoded() -> dict[str, int]:
    found: dict[str, int] = {}
    for path in sorted(CLIENT_SRC.rglob("*")):
        if path.suffix in SOURCE_SUFFIXES and (count := han_literals(path)):
            found[path.relative_to(PROJECT).as_posix()] = count
    return found


def dialogue_keys(path: Path) -> set[str]:
    keys: set[str] = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#") or "\t" not in raw:
            continue
        key = raw.split("\t", 1)[0].strip()
        if key != "key":
            keys.add(key)
    return keys


def scan_dialogue(report: Report | None) -> dict[str, int]:
    """Bản thoại chưa có tệp: ngôn ngữ -> 1. Tệp có mà lệch khoá với zh thì báo đỏ (nếu có report)."""
    zh_path = DIALOGUE / "dialogue.zh.txt"
    if not zh_path.exists():
        if report:
            report.red("d", f"thiếu {zh_path.relative_to(PROJECT)}")
        return {}
    base = dialogue_keys(zh_path)
    absent: dict[str, int] = {}
    for lang in ("en", "vi"):
        path = DIALOGUE / f"dialogue.{lang}.txt"
        if not path.exists():
            absent[lang] = 1
            continue
        keys = dialogue_keys(path)
        if keys != base and report:
            report.red("d", f"dialogue.{lang}: thiếu {len(base - keys)} khoá, thừa {len(keys - base)} khoá "
                            f"(thiếu: {sample(base - keys)}; thừa: {sample(keys - base)})")
    return absent


def check_keys(report: Report, tables) -> None:
    for lang in ("en", "vi"):
        only_zh = set(tables["zh"]) - set(tables[lang])
        only_lang = set(tables[lang]) - set(tables["zh"])
        if only_zh:
            report.red("a", f"{len(only_zh)} khoá có ở zh mà thiếu ở {lang}: {sample(only_zh)}")
        if only_lang:
            report.red("a", f"{len(only_lang)} khoá có ở {lang} mà thiếu ở zh: {sample(only_lang)}")


def check_han(report: Report, tables) -> None:
    for lang in ("en", "vi"):
        bad = [key for key, value in tables[lang].items()
               if not key.startswith(FILE_KINDS) and HAN.search(TAG.sub("", value))]
        if bad:
            report.red("b", f"{len(bad)} giá trị {lang} còn chữ Hán ngoài thẻ #{{...}}: {sample(bad)}")


def check_used(report: Report, tables, base: Baseline) -> None:
    if not STRDICT.exists():
        report.red("c", f"thiếu {STRDICT.relative_to(PROJECT)}")
        return
    window_base = base["khoá"]
    if not LAYOUTS.is_dir():
        report.notes.append(f"[c] thiếu {LAYOUTS.relative_to(PROJECT)} (thư mục sinh, git bỏ qua): chỉ so khoá script")
        window_base = {key: value for key, value in window_base.items() if value[0] == "script"}
    original = read_table(STRDICT)
    judge(report, "c", scan_window_keys(tables, original), window_base, "khoá cửa sổ")
    spoken = scan_dialogue_keys(tables, original)
    if spoken:
        report.red("c", f"{len(spoken)} khoá từ điển mà thoại máy chủ dùng thiếu ở zh, en hoặc vi: {sample(spoken)}")
    cpp = scan_cpp_keys(tables)
    if cpp:
        report.red("c", f"{len(cpp)} khoá mã C++ thiếu ở zh, en hoặc vi: {sample(f'{k} ({v})' for k, v in cpp.items())}")


def scan_inconsistent(tables) -> dict[str, int]:
    """Nhóm khoá cùng chữ zh mà en hoặc vi dịch khác nhau: "<ngôn ngữ>:<zh>" -> số bản dịch khác nhau."""
    shared: dict[str, list[str]] = {}
    for key, value in tables["zh"].items():
        if not key.startswith(FILE_KINDS) and HAN.search(value):
            shared.setdefault(value, []).append(key)
    found: dict[str, int] = {}
    for lang in ("en", "vi"):
        table = tables[lang]
        for value, keys in shared.items():
            variants = len({table.get(key, "") for key in keys})
            if len(keys) > 1 and variants > 1:
                found[f"{lang}:{value}"] = variants
    return found


def render_baseline(tables) -> str:
    lines = ["# Danh sách nền của cổng i18n (check_i18n.py): chỉ được co lại. Chạm cửa sổ hay tệp nào thì lấp i18n",
             "# cho nó rồi gỡ dòng của nó. Sinh bằng check_i18n.py --ghi-nen, thu nhỏ bằng --co-lai."]
    for key, (kind, name) in sorted(scan_window_keys(tables, read_table(STRDICT)).items()):
        lines.append(f"khoá\t{key}\t{kind}\t{name}")
    for path, count in scan_hardcoded().items():
        lines.append(f"cứng\t{path}\t{count}")
    for lang in scan_dialogue(None):
        lines.append(f"thoại\t{lang}")
    for name, variants in sorted(scan_inconsistent(tables).items()):
        lang, _, zh = name.partition(":")
        lines.append(f"lệch\t{lang}\t{variants}\t{zh}")
    return "\n".join(lines) + "\n"


def write_baseline(tables, shrink: bool) -> int:
    if BASELINE.exists() != shrink:
        print("--ghi-nen chỉ khi chưa có danh sách nền; --co-lai chỉ khi đã có", file=sys.stderr)
        return 2
    text = render_baseline(tables)
    old = read_baseline()
    if shrink:
        probe = Report()
        judge(probe, "c", scan_window_keys(tables, read_table(STRDICT)), old["khoá"], "khoá")
        judge(probe, "e", scan_hardcoded(), old["cứng"], "tệp")
        judge(probe, "f", scan_inconsistent(tables), old["lệch"], "nhóm")
        fresh = [p for p in probe.problems if "chưa có trong danh sách nền" in p or "nhiều hơn" in p]
        if fresh:
            print("không co lại được, có mục mới hay lớn thêm:\n" + "\n".join(fresh), file=sys.stderr)
            return 2
    BASELINE.write_text(text, encoding="utf-8", newline="\n")
    print(f"đã ghi {len(text.splitlines()) - 2} mục vào {BASELINE.relative_to(PROJECT)}")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Cổng kiểm i18n ba thứ tiếng.")
    parser.add_argument("--ghi-nen", action="store_true")
    parser.add_argument("--co-lai", action="store_true")
    args = parser.parse_args(argv)
    tables = {lang: read_table(I18N / f"{lang}.tsv") for lang in LANGS}
    if args.ghi_nen or args.co_lai:
        return write_baseline(tables, shrink=args.co_lai)
    base = read_baseline()
    report = Report()
    check_keys(report, tables)
    check_han(report, tables)
    check_used(report, tables, base)
    judge(report, "d", scan_dialogue(report), base["thoại"], "bản thoại")
    judge(report, "e", scan_hardcoded(), base["cứng"], "tệp có chuỗi Hán viết cứng")
    judge(report, "f", scan_inconsistent(tables), base["lệch"], "nhóm cùng zh khác bản dịch")
    for note in report.notes:
        print(note)
    for problem in report.problems:
        print(problem)
    print(f"i18n_gate: {'ĐỎ' if report.problems else 'XANH'} ({len(report.problems)} lỗi)")
    return 1 if report.problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
