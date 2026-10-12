"""Kiểm tệp TOML của SERVER/config: đúng cú pháp, đúng bố cục, không cài đặt nào thiếu chú thích.

  python TOOLS/server/lint_config.py                  kiểm mọi tệp .toml dưới SERVER/config
  python TOOLS/server/lint_config.py <tệp...>         kiểm các tệp chỉ định
  python TOOLS/server/lint_config.py --fix [tệp...]   căn thẳng cột lại rồi mới kiểm

Luật (config_style.py): khung tiêu đề in hoa ở đầu tệp; mỗi nhóm cài đặt mở đầu bằng một khung
tiêu đề và cách nhóm trước một dòng trống; mỗi cài đặt có chú thích tiếng Việt ngang hàng hoặc ngay
dòng trên; dấu = và dấu # thẳng cột trong nhóm; dòng không quá 110 cột; có khoá schema.
--fix chỉ đổi dấu cách quanh dấu = và trước chú thích ngang hàng, không đổi chữ nào.
Thoát 0 khi sạch, 1 khi có lỗi; mỗi lỗi một dòng "tệp:dòng: nội dung".
"""
import re
import sys
import tomllib
from pathlib import Path

from config_style import KEY, LINE_LIMIT, RULE, TABLE, align_lines, split_setting

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "SERVER" / "config"
# Chữ chỉ tiếng Việt mới có: đủ để phân biệt chú thích tiếng Việt với chú thích trống hay tiếng Anh.
VIETNAMESE = re.compile(r"[àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ]", re.IGNORECASE)

Problems = list[tuple[int, str]]


def is_plain_comment(line: str) -> bool:
    """Dòng chú thích thường, không phải dòng kẻ của khung."""
    return line.startswith("#") and line != RULE


def banner_title(lines: list[str], start: int) -> str | None:
    """Tiêu đề của khung bắt đầu ở dòng start, hoặc None khi ba dòng đó không phải một khung."""
    if start < 0 or start + 2 >= len(lines):
        return None
    if lines[start] != RULE or lines[start + 2] != RULE or not lines[start + 1].startswith("# "):
        return None
    return lines[start + 1][2:].strip()


def check_title(lines: list[str]) -> Problems:
    title = banner_title(lines, 0)
    if title is None:
        return [(1, "thiếu khung tiêu đề ba dòng ở đầu tệp")]
    if not title or title != title.upper():
        return [(2, "tiêu đề tệp phải viết chữ in hoa")]
    return []


def check_group(lines: list[str], index: int, what: str) -> Problems:
    """Nhóm chứa dòng index phải mở đầu bằng một khung, chỉ cách khung bởi các dòng mô tả."""
    cursor = index - 1
    while cursor >= 0 and is_plain_comment(lines[cursor]):
        cursor -= 1
    # cursor đang ở dòng kẻ dưới của khung; start là dòng kẻ trên. start == 0 là khung tiêu đề tệp.
    start = cursor - 2
    title = banner_title(lines, start)
    if title is None or start == 0:
        return [(index + 1, f"{what} thiếu khung tiêu đề ngay phía trên")]
    problems = []
    if not title:
        problems.append((start + 2, "khung tiêu đề để trống"))
    if lines[start - 1]:
        problems.append((start + 1, "trước khung tiêu đề phải có một dòng trống"))
    return problems


def comment_above(lines: list[str], index: int) -> str | None:
    """Chú thích ngay trên một cài đặt. Các dòng mô tả nhóm nằm sát dưới khung thì không tính."""
    cursor = index - 1
    while cursor >= 0 and is_plain_comment(lines[cursor]):
        cursor -= 1
    if cursor == index - 1 or cursor < 0 or lines[cursor] == RULE:
        return None
    return lines[index - 1][1:].strip()


def check_key(lines: list[str], index: int) -> Problems:
    name, _, beside = split_setting(lines[index])
    note = beside if beside else comment_above(lines, index)
    if not note:
        return [(index + 1, f"cài đặt {name} thiếu chú thích ngang hàng hoặc ngay dòng trên")]
    if not VIETNAMESE.search(note):
        return [(index + 1, f"chú thích của cài đặt {name} không phải tiếng Việt có dấu")]
    return []


def check_file(path: Path) -> Problems:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        return [(1, f"không đọc được: {error}")]
    try:
        data = tomllib.loads(text)
    except tomllib.TOMLDecodeError as error:
        return [(1, f"sai cú pháp TOML: {error}")]
    lines = text.splitlines()
    problems = check_title(lines)
    if not isinstance(data.get("schema"), int):
        problems.append((1, "thiếu khoá gốc schema kiểu số nguyên"))
    aligned = align_lines(lines)
    in_root = True
    for index, line in enumerate(lines):
        if "\t" in line or line != line.rstrip():
            problems.append((index + 1, "có tab hoặc dấu cách thừa cuối dòng"))
        if len(line) > LINE_LIMIT:
            problems.append((index + 1, f"dòng dài {len(line)} cột, quá {LINE_LIMIT}: rút gọn chú thích"))
        if line != aligned[index]:
            problems.append((index + 1, "chưa căn thẳng cột: chạy lint_config.py --fix"))
        if TABLE.match(line):
            problems += check_group(lines, index, f"bảng {line.split('#')[0].strip()}")
            in_root = False
        elif KEY.match(line):
            if in_root:
                problems += check_group(lines, index, "nhóm khoá gốc")
                in_root = False
            problems += check_key(lines, index)
    return problems


def fix_file(path: Path) -> bool:
    """Căn thẳng cột lại một tệp. Trả True khi tệp đổi. Tệp sai cú pháp thì để nguyên cho bước kiểm."""
    try:
        text = path.read_text(encoding="utf-8")
        tomllib.loads(text)
    except (OSError, UnicodeDecodeError, tomllib.TOMLDecodeError):
        return False
    fixed = "\n".join(align_lines(text.splitlines())) + "\n"
    if fixed == text:
        return False
    path.write_text(fixed, encoding="utf-8", newline="\n")
    return True


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    arguments = sys.argv[1:]
    fix = "--fix" in arguments
    paths = [Path(argument) for argument in arguments if argument != "--fix"] or sorted(CONFIG.rglob("*.toml"))
    if not paths:
        print(f"không có tệp .toml nào dưới {CONFIG}")
        return 1
    if fix:
        changed = [path.name for path in paths if fix_file(path)]
        print(f"căn lại {len(changed)} tệp" + (": " + ", ".join(changed) if changed else ""))
    failures = 0
    keys = 0
    for path in paths:
        problems = check_file(path)
        if not problems:
            keys += sum(1 for line in path.read_text(encoding="utf-8").splitlines() if KEY.match(line))
        for line, message in sorted(problems):
            print(f"{path}:{line}: {message}")
        failures += len(problems)
    if failures:
        print(f"{failures} lỗi trong {len(paths)} tệp")
        return 1
    print(f"{len(paths)} tệp sạch, {keys} cài đặt đều có chú thích và thẳng cột")
    return 0


if __name__ == "__main__":
    sys.exit(main())
