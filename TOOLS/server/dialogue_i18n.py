#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/server/dialogue_i18n.py
#  PHÂN HỆ   : Server / Dialogue I18n
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Kiểm bản dịch của chữ thoại máy chủ: tables/server/dialogue.<ngôn ngữ>.txt
#    so với bản gốc dialogue.zh.txt.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Kiểm và dựng bản dịch của chữ thoại máy chủ: tables/server/dialogue.<ngôn ngữ>.txt so với bản gốc dialogue.zh.txt.

Chữ thoại là thứ máy chủ gửi thẳng cho người chơi, trong đó có thẻ màu (#Y, #cFF0000), tham chiếu từ điển của client
(#{...}) và chỗ điền (%s, %d, {0}) mà máy chủ điền theo thứ tự. Bản dịch làm mất hay đảo một trong số đó thì hỏng
thầm: game vẫn chạy, chữ hiện sai. Công cụ này là cổng của bản dịch, không dịch gì.

Dùng, ở gốc dự án:
    python -X utf8 TOOLS/server/dialogue_i18n.py check <gốc> <bản dịch>    lỗi thì mã thoát 1
    python -X utf8 TOOLS/server/dialogue_i18n.py terms <gốc> <bản dịch> [--glossary tệp.tsv]   chỉ cảnh báo thuật ngữ
    python -X utf8 TOOLS/server/dialogue_i18n.py build <ngôn ngữ> <tệp phần>...    gộp phần dịch thành dialogue.<ngôn ngữ>.txt
    python -X utf8 TOOLS/server/dialogue_i18n.py tables <ngôn ngữ> <tệp phần>...   ghi <bảng>.<ngôn ngữ>.tsv của sáu bảng chuỗi hệ thống

<gốc> và <bản dịch> là tệp dialogue (có dòng "# schema", đọc bằng dialogue_text.parse) hoặc tệp phần
(dòng "## chủ  nhãn" tuỳ chọn rồi "khoá<tab>chữ", dấu cách cuối ghi bằng ␣) dùng khi dịch song song.
build và tables kiểm toàn bộ trước khi ghi: thiếu khoá, thừa khoá hay một câu lỗi thì không ghi tệp nào.
"""
from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import dialogue_text
import tsv_file

PROJECT = Path(__file__).resolve().parents[2]
GLOSSARY = PROJECT / "assets/i18n/glossary.tsv"
SPACE_MARK = dialogue_text.MARK
TOOL = "TOOLS/server/dialogue_i18n.py"
# Bảng chuỗi hệ thống: (tên bảng, cột khoá, cột chữ). Khoá của câu là "<tên bảng>.<giá trị cột khoá>".
TABLES = (
    ("server_strings", "id", "text"),
    ("notices_on_login", "index", "info"),
    ("notices_by_weekday", "index", "info"),
    ("notices_by_date", "index", "info"),
    ("rolling_announcements", "announcement_id", "contex"),
    ("npc_chat_lines", "id", "chat"),
)

# Thứ tự của các token này phải giữ nguyên: máy chủ điền chỗ điền lần lượt, client tra từ điển theo chuỗi.
FIXED = re.compile(
    r"#\{\{[^{}]*\}\}|#\{[^{}]*\}|@\*;[A-Za-z]+;[A-Za-z]+:|https?://[A-Za-z0-9./_?=&%-]+|#-\d+|\{ID=[A-Za-z0-9_]+\}|\{\d+\}|\$[A-Za-z]|%%|%[-+0#]*\d*(?:\.\d+)?[A-Za-z]"
)
# Thẻ màu và định dạng: đủ số lượng, thứ tự tuỳ ngữ pháp.
STYLE = re.compile(r"#[cg][0-9A-Fa-f]{6}|#[A-Za-z]")
# Chữ Hán, dấu câu CJK, dạng toàn góc: không được còn trong bản dịch.
HAN = re.compile("[⺀-⿟　-〿぀-ヿ㐀-䶿一-鿿豈-﫿＀-￯]")
IDEOGRAPH = re.compile("[㐀-䶿一-鿿豈-﫿]")
LETTER = re.compile(r"[A-Za-zÀ-ɏḀ-ỿ]")
DOUBLE_SPACE = re.compile(r"(?<=\S)  +(?=\S)")


@dataclass(frozen=True)
class Line:
    key: str
    owner: str
    text: str


def _is_allowed(char: str, source: str) -> bool:
    code = ord(char)
    if 0x20 <= code < 0x7F or 0x00A0 <= code <= 0x024F or 0x1E00 <= code <= 0x1EFF:
        return True
    if 0x2010 <= code <= 0x205E:  # dấu câu chung: “ ” ‘ ’ … – —
        return True
    return char in source


def load(path: Path) -> list[Line]:
    """Đọc tệp dialogue hay tệp phần thành danh sách theo thứ tự tệp."""
    text = path.read_text(encoding="utf-8")
    if text.lstrip("﻿").startswith("# schema"):
        return [Line(entry.key, entry.owner, entry.text) for entry in dialogue_text.parse(text)]
    lines: list[Line] = []
    owner = ""
    for number, raw in enumerate(text.replace("\r\n", "\n").split("\n"), start=1):
        if not raw or raw.startswith("#") and not raw.startswith("##"):
            continue
        if raw.startswith("##"):
            owner = raw[2:].split()[0] if raw[2:].split() else ""
            continue
        key, tab, cell = raw.partition("\t")
        if not tab:
            raise ValueError(f"{path}:{number}: thiếu tab giữa khoá và chữ")
        lines.append(Line(key, owner, dialogue_text._unmark(cell)))
    return lines


def check_text(source: str, target: str) -> list[str]:
    """Lỗi của một câu dịch so với câu gốc; rỗng là đạt."""
    problems: list[str] = []
    if any(char in target for char in "\t\r\n"):
        problems.append("chữ chứa tab hoặc xuống dòng")
    if SPACE_MARK in target:
        problems.append(f"còn ký hiệu {SPACE_MARK} (phải đổi thành dấu cách cuối thật)")
    if unicodedata.normalize("NFC", target) != target:
        problems.append("không ở dạng Unicode NFC (dấu rời)")
    if source.strip() and not target.strip():
        problems.append("rỗng")
        return problems
    if target == source and HAN.search(source):
        problems.append("chưa dịch (giống hệt bản gốc)")
    # Chữ Hán nằm trong thẻ #{...} (tên NPC của #{_INFOAIM...}) là tham số của client, giữ nguyên như vi.tsv.
    leftover = HAN.search(FIXED.sub("", target))
    if leftover:
        problems.append(f"còn chữ Hán hoặc dấu toàn góc: {leftover.group()!r}")
    if IDEOGRAPH.search(FIXED.sub("", source)) and not LETTER.search(FIXED.sub("", STYLE.sub("", target))):
        problems.append("không có chữ nào ngoài thẻ và chỗ điền")
    fixed_source, fixed_target = FIXED.findall(source), FIXED.findall(target)
    if fixed_source != fixed_target:
        problems.append(f"chỗ điền/tham chiếu lệch: gốc {fixed_source} dịch {fixed_target}")
    style_source, style_target = Counter(STYLE.findall(source)), Counter(STYLE.findall(target))
    if style_source != style_target:
        missing = dict(style_source - style_target)
        extra = dict(style_target - style_source)
        problems.append(f"thẻ màu/định dạng lệch: thiếu {missing} thừa {extra}")
    for bracket in "<>":
        if source.count(bracket) != target.count(bracket):
            problems.append(f"số dấu {bracket} lệch: gốc {source.count(bracket)} dịch {target.count(bracket)}")
    lead = len(source) - len(source.lstrip(" "))
    if len(target) - len(target.lstrip(" ")) != lead:
        problems.append(f"dấu cách đầu câu phải là {lead}")
    tail = len(source) - len(source.rstrip(" "))
    if len(target) - len(target.rstrip(" ")) != tail:
        problems.append(f"dấu cách cuối câu phải là {tail}")
    if DOUBLE_SPACE.search(target) and not DOUBLE_SPACE.search(source):
        problems.append("hai dấu cách liền nhau giữa câu")
    odd = sorted({char for char in target if not _is_allowed(char, source)})
    if odd:
        problems.append(f"ký tự ngoài bảng chữ Việt và dấu câu thường: {''.join(odd)!r}")
    return problems


def check(source: list[Line], target: list[Line]) -> list[str]:
    """Lỗi của cả bản dịch: cùng khoá, cùng thứ tự, cùng nhóm, từng câu đạt check_text."""
    errors: list[str] = []
    if [line.key for line in source] != [line.key for line in target]:
        have = {line.key for line in target}
        want = {line.key for line in source}
        errors.append(f"khoá lệch: thiếu {sorted(want - have)[:8]} thừa {sorted(have - want)[:8]}")
        if len(source) == len(target) and have == want:
            errors.append("cùng tập khoá nhưng khác thứ tự")
        return errors
    for original, translated in zip(source, target, strict=True):
        if original.owner != translated.owner:
            errors.append(f"{original.key}: khác nhóm ({original.owner} và {translated.owner})")
        for problem in check_text(original.text, translated.text):
            errors.append(f"{original.key}: {problem}")
    return errors


def _terms(path: Path) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for raw in path.read_text(encoding="utf-8").split("\n"):
        if not raw or raw.startswith("#"):
            continue
        cells = raw.split("\t")
        if len(cells) >= 3 and cells[0] != "zh" and len(cells[0]) >= 2 and cells[2]:
            rows.append((cells[0], cells[2]))
    return rows


def term_warnings(source: list[Line], target: list[Line], glossary: Path) -> list[str]:
    """Câu gốc có thuật ngữ của bảng mà câu dịch không có dạng tiếng Việt của nó (không phân biệt hoa thường)."""
    terms = _terms(glossary)
    warnings: list[str] = []
    for original, translated in zip(source, target, strict=True):
        lowered = translated.text.lower()
        for zh, vi in terms:
            if zh in original.text and vi.lower() not in lowered:
                warnings.append(f"{original.key}: {zh} nên là {vi!r}")
    return warnings


def merge(parts: list[Path]) -> dict[str, Line]:
    """Gộp các tệp phần thành khoá → câu; một khoá ở hai phần là lỗi."""
    merged: dict[str, Line] = {}
    for part in parts:
        for line in load(part):
            if line.key in merged:
                raise ValueError(f"{part}: khoá {line.key} đã có ở phần khác")
            merged[line.key] = line
    return merged


def _coverage(wanted: list[str], merged: dict[str, Line]) -> list[str]:
    have, want = set(merged), set(wanted)
    errors = [f"thiếu câu dịch cho {key}" for key in wanted if key not in have]
    errors += [f"câu dịch thừa, không có trong bản gốc: {key}" for key in sorted(have - want)]
    return errors


def build_dialogue(language: str, parts: list[Path], destination: Path) -> int:
    """Gộp các phần đã dịch thành tables/server/dialogue.<ngôn ngữ>.txt (cùng khoá, nhóm, thứ tự với bản gốc)."""
    entries = dialogue_text.parse(dialogue_text.TABLE_FILE.read_text(encoding="utf-8"))
    source = [Line(entry.key, entry.owner, entry.text) for entry in entries]
    merged = merge(parts)
    errors = _coverage([line.key for line in source], merged)
    if not errors:
        target = [merged[line.key] for line in source]
        errors = check(source, target)
    if errors:
        print("\n".join(errors))
        print(f"{len(errors)} lỗi, không ghi tệp")
        return 1
    translated = [dialogue_text.Entry(line.key, line.text, line.owner) for line in target]
    labels = dialogue_text.labels_of(entries, dialogue_text.TABLE_FILE.parent)
    dialogue_text.write(destination, translated, labels, language, TOOL)
    print(f"{destination}: {len(translated)} câu")
    return 0


def build_tables(language: str, parts: list[Path], table_dir: Path) -> int:
    """Với từng bảng chuỗi hệ thống, ghi bảng anh em <tên>.<ngôn ngữ>.tsv cùng cột, chỉ cột chữ đổi sang bản dịch."""
    merged = merge(parts)
    errors: list[str] = []
    pending: list[tuple[str, tsv_file.Table, list[tuple[str, ...]]]] = []
    wanted: list[str] = []
    for name, key_column, text_column in TABLES:
        table = tsv_file.read_table(table_dir / f"{name}.tsv")
        key_at, text_at = table.columns.index(key_column), table.columns.index(text_column)
        rows: list[tuple[str, ...]] = []
        for row in table.rows:
            key = f"{name}.{row[key_at]}"
            if row[text_at].strip():
                wanted.append(key)
                line = merged.get(key)
                if line is None:
                    rows.append(row)
                    continue
                errors += [f"{key}: {problem}" for problem in check_text(row[text_at], line.text)]
                row = (*row[:text_at], line.text, *row[text_at + 1 :])
            rows.append(row)
        pending.append((name, table, rows))
    errors += _coverage(wanted, merged)
    if errors:
        print("\n".join(errors))
        print(f"{len(errors)} lỗi, không ghi tệp")
        return 1
    for name, table, rows in pending:
        destination = table_dir / f"{name}.{language}.tsv"
        tsv_file.write_table(destination, table.source, TOOL, table.types, table.columns, rows)
        print(f"{destination}: {len(rows)} dòng")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=("check", "terms", "build", "tables"))
    parser.add_argument("source", type=Path, help="check, terms: tệp gốc; build, tables: mã ngôn ngữ (vd. vi)")
    parser.add_argument("target", type=Path, nargs="+", help="check, terms: tệp dịch; build, tables: các tệp phần")
    parser.add_argument("--glossary", type=Path, default=GLOSSARY)
    args = parser.parse_args(argv)
    if args.command in ("build", "tables"):
        language = str(args.source)
        table_dir = dialogue_text.TABLE_FILE.parent
        try:
            if args.command == "tables":
                return build_tables(language, args.target, table_dir)
            return build_dialogue(language, args.target, table_dir / f"dialogue.{language}.txt")
        except (ValueError, dialogue_text.DialogueError, tsv_file.TsvError, OSError) as error:
            print(f"lỗi: {error}", file=sys.stderr)
            return 2
    if len(args.target) != 1:
        parser.error("check và terms nhận đúng một tệp dịch")
    try:
        source, target = load(args.source), load(args.target[0])
    except (ValueError, dialogue_text.DialogueError, OSError) as error:
        print(f"lỗi đọc tệp: {error}", file=sys.stderr)
        return 2
    if args.command == "terms":
        if len(source) != len(target):
            print("hai tệp khác số câu: chạy check trước", file=sys.stderr)
            return 2
        warnings = term_warnings(source, target, args.glossary)
        print("\n".join(warnings))
        print(f"{len(warnings)} cảnh báo thuật ngữ trên {len(source)} câu")
        return 0
    errors = check(source, target)
    print("\n".join(errors))
    print(f"{len(errors)} lỗi trên {len(source)} câu gốc, {len(target)} câu dịch")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
