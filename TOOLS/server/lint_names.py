"""Cổng tên cột và tên tệp luật theo glossary.tsv.

cách dùng: python TOOLS/server/lint_names.py [--stats]
Thoát 0 khi sạch, 1 khi có lỗi. Mỗi lỗi một dòng tệp:dòng: nội dung.
N1, N2 trên mọi tên. N3, N4 trên hai bảng thuật ngữ cột.
--stats in sáu số của từng nhóm shared, server, scenes.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

_NAME = re.compile(r"^[a-z][a-z0-9_]*$")
_COLUMN_N = re.compile(r"^column_\d+(?:_\d+)?$")
_KEY = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=")
_GROUP = re.compile(r"^\[([A-Za-z_][A-Za-z0-9_]*)\]\s*(?:#.*)?$")
_HAN = re.compile(r"[\u3400-\u9fff\uf900-\ufaff]")
_LETTER = re.compile(r"[A-Za-z]")
HELP = """\
cách dùng: python TOOLS/server/lint_names.py [--stats]

Kiểm tên trong tệp luật, tệp cột, bảng thuật ngữ và tên bảng đích.
N3, N4 đọc term_morphemes.tsv. Ngoại lệ ở name_exceptions.tsv.
--stats in sáu số cột của nhóm shared, server và scenes. Thoát 0 khi sạch.
"""
PROJECT = Path(__file__).resolve().parents[2]
TOOLS = Path(__file__).resolve().parent
COLUMNS = TOOLS / "columns"
GROUPS = ("shared", "server", "scenes")


def _display(path: Path) -> str:
    try:
        return path.resolve().relative_to(PROJECT).as_posix()
    except ValueError:
        return path.as_posix()


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _glossary_banned() -> tuple[set[str], set[str]]:
    path = TOOLS / "glossary.tsv"
    banned: set[str] = set()
    official: set[str] = set()
    for line in _read(path).splitlines():
        if not line or line.startswith("#") or line.startswith("original\t"):
            continue
        original, _chinese, name, flag = line.split("\t")
        if flag != "1":
            continue
        banned.add(original.casefold())
        official.add(name.replace("_", ""))
    return banned, official


def _exception_sets() -> tuple[set[str], set[str], set[str]]:
    """Tên miễn N1, tên miễn N3, nhãn gốc miễn N4."""
    path = TOOLS / "name_exceptions.tsv"
    plain: set[str] = set()
    morpheme: set[str] = set()
    clash: set[str] = set()
    if not path.is_file():
        return plain, morpheme, clash
    for line in _read(path).splitlines():
        if not line or line.startswith("#") or line.startswith("name\t"):
            continue
        cells = line.split("\t")
        rule = cells[1] if len(cells) > 1 else "N1"
        if rule == "N3":
            morpheme.add(cells[0])
            continue
        if rule == "N4":
            clash.add(cells[0])
            continue
        plain.add(cells[0])
    return plain, morpheme, clash


Word = tuple[str, ...]
Morpheme = tuple[Word, str, Word]


def _morphemes() -> list[Morpheme]:
    path = TOOLS / "term_morphemes.tsv"
    rows: list[Morpheme] = []
    for line in _read(path).splitlines():
        if not line or line.startswith("#") or line.startswith("chinese\t"):
            continue
        chinese, name, banned, _basis = line.split("\t")
        words = tuple(part.strip() for part in chinese.split(",") if part.strip())
        bans = tuple(part.strip() for part in banned.split(",") if part.strip())
        rows.append((words, name, bans))
    return rows


def _term_tokens(name: str) -> list[str]:
    return [token for token in name.split("_") if token and token != "{n}"]


def _n3(original: str, name: str, morphemes: list[Morpheme], exempt: set[str]) -> list[str]:
    if name in exempt:
        return []
    tokens = _term_tokens(name)
    joined = {tokens[index] + tokens[index + 1] for index in range(len(tokens) - 1)}
    found: list[str] = []
    seen: set[str] = set()
    for words, need, banned in morphemes:
        if not any(word in original for word in words):
            continue
        if need not in seen:
            seen.add(need)
            if need not in tokens:
                found.append(f"thiếu từ {need}")
        for ban in banned:
            if ban in tokens or ban in joined:
                found.append(f"chứa từ cấm {ban}")
    return found


def _hits(name: str, banned: set[str], official: set[str]) -> list[str]:
    tokens = [token for token in name.split("_") if token]
    found = [token for token in tokens if token in banned]
    for index in range(len(tokens) - 1):
        joined = tokens[index] + tokens[index + 1]
        if joined in banned and joined not in official:
            found.append(joined)
    return found


def _n2(name: str) -> str:
    if not _NAME.fullmatch(name) or "__" in name or name.endswith("_"):
        return "sai dạng tên"
    return ""


def _problems(name: str, banned: set[str], official: set[str], exempt: set[str]) -> list[str]:
    if name in exempt:
        return []
    found = []
    shape = _n2(name)
    if shape:
        found.append(shape)
    for token in _hits(name, banned, official):
        found.append(f"chứa từ cấm {token}")
    return found


def _emit(path: Path, line: int, name: str, banned: set[str], official: set[str], exempt: set[str]) -> list[str]:
    display = _display(path)
    problems = _problems(name, banned, official, exempt)
    return [f"{display}:{line}: tên {name} {problem}" for problem in problems]


def _toml_names(path: Path, banned: set[str], official: set[str], exempt: set[str]) -> list[str]:
    errors: list[str] = []
    for number, line in enumerate(_read(path).splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        group = _GROUP.fullmatch(stripped)
        if group:
            errors.extend(_emit(path, number, group.group(1), banned, official, exempt))
            continue
        key = _KEY.match(stripped)
        if key:
            errors.extend(_emit(path, number, key.group(1), banned, official, exempt))
    return errors


def _filled_term(name: str) -> str | None:
    """Mẫu {n} kiểm sau khi điền số. Tên cột đã sinh không đi qua đây."""
    if "{n}" not in name:
        return name
    if name.count("{") != name.count("{n}") or name.count("}") != name.count("{n}"):
        return None
    return name.replace("{n}", "1")


def _term_names(
    path: Path,
    banned: set[str],
    official: set[str],
    exempt: set[str],
    morphemes: list[Morpheme],
    morpheme_exempt: set[str],
    entries: list[tuple[Path, int, str, str]],
) -> list[str]:
    if not path.is_file():
        return []
    errors: list[str] = []
    name_at = 2
    for number, line in enumerate(_read(path).splitlines(), start=1):
        if not line or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] == "original":
            name_at = cells.index("name")
            continue
        entries.append((path, number, cells[0], cells[name_at]))
        filled = _filled_term(cells[name_at])
        if filled is None:
            errors.append(f"{_display(path)}:{number}: tên {cells[name_at]} sai dạng tên")
            continue
        errors.extend(_emit(path, number, filled, banned, official, exempt))
        display = _display(path)
        for problem in _n3(cells[0], cells[name_at], morphemes, morpheme_exempt):
            errors.append(f"{display}:{number}: tên {cells[name_at]} {problem}")
    return errors


def _n4(entries: list[tuple[Path, int, str, str]], exempt: set[str]) -> list[str]:
    grouped: dict[str, list[tuple[Path, int]]] = {}
    names: dict[str, set[str]] = {}
    for path, line, original, name in entries:
        grouped.setdefault(original, []).append((path, line))
        names.setdefault(original, set()).add(name)
    errors: list[str] = []
    for original, spots in grouped.items():
        found = names[original]
        if len(found) < 2 or original in exempt:
            continue
        shown = ", ".join(sorted(found))
        for path, line in spots:
            errors.append(f"{_display(path)}:{line}: nhãn {original} có nhiều tên {shown}")
    return errors


def _column_names(banned: set[str], official: set[str], exempt: set[str]) -> list[str]:
    errors: list[str] = []
    for path in sorted(COLUMNS.rglob("*.tsv")):
        name_at = 2
        for number, line in enumerate(_read(path).splitlines(), start=1):
            if not line or line.startswith("#"):
                continue
            cells = line.split("\t")
            if cells[0] == "index":
                name_at = cells.index("name")
                continue
            errors.extend(_emit(path, number, cells[name_at], banned, official, exempt))
    return errors


def _target_names(banned: set[str], official: set[str], exempt: set[str]) -> list[str]:
    path = TOOLS / "table_names.tsv"
    errors: list[str] = []
    target_at = 3
    for number, line in enumerate(_read(path).splitlines(), start=1):
        if not line or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] == "tree":
            target_at = cells.index("target")
            continue
        target = cells[target_at]
        if not target.endswith(".tsv"):
            continue
        errors.extend(_emit(path, number, Path(target).stem, banned, official, exempt))
    return errors


def check_names() -> list[str]:
    """Mọi tên vi phạm N1–N4. Danh sách rỗng là sạch."""
    banned, official = _glossary_banned()
    exempt, morpheme_exempt, clash_exempt = _exception_sets()
    morphemes = _morphemes()
    errors: list[str] = []
    rules = PROJECT / "SERVER" / "config" / "rules"
    for path in sorted(rules.glob("*.toml")):
        errors.extend(_toml_names(path, banned, official, exempt))
    errors.extend(_column_names(banned, official, exempt))
    entries: list[tuple[Path, int, str, str]] = []
    errors.extend(
        _term_names(TOOLS / "column_terms.tsv", banned, official, exempt, morphemes, morpheme_exempt, entries)
    )
    errors.extend(
        _term_names(
            TOOLS / "column_terms_server.tsv", banned, official, exempt, morphemes, morpheme_exempt, entries
        )
    )
    errors.extend(_n4(entries, clash_exempt))
    errors.extend(_target_names(banned, official, exempt))
    return errors


def _kind(original: str) -> str:
    if original.strip() == "":
        return "empty"
    han = _HAN.search(original) is not None
    letter = _LETTER.search(original) is not None
    if han and letter:
        return "mixed"
    if letter:
        return "ascii"
    return "han"


def _unnamed(name: str, note: str) -> bool:
    return "?" in note or _COLUMN_N.fullmatch(name) is not None


def _group_stats(group: str) -> tuple[int, int, int, int, int, int]:
    total = unnamed = empty = han = mixed = ascii_only = 0
    root = COLUMNS / group
    for path in sorted(root.rglob("*.tsv")):
        name_at, original_at, note_at = 2, 1, 4
        for line in _read(path).splitlines():
            if not line or line.startswith("#"):
                continue
            cells = line.split("\t")
            if cells[0] == "index":
                name_at = cells.index("name")
                original_at = cells.index("original")
                note_at = cells.index("note")
                continue
            total += 1
            if not _unnamed(cells[name_at], cells[note_at]):
                continue
            unnamed += 1
            kind = _kind(cells[original_at])
            if kind == "empty":
                empty += 1
            elif kind == "han":
                han += 1
            elif kind == "mixed":
                mixed += 1
            elif kind == "ascii":
                ascii_only += 1
    return total, unnamed, empty, han, mixed, ascii_only


def stats_lines() -> list[str]:
    """Sáu số cột của từng nhóm, đúng thứ tự bảng ở mục 3."""
    lines = []
    for group in GROUPS:
        total, unnamed, empty, han, mixed, ascii_only = _group_stats(group)
        lines.append(
            f"{group}: cột {total}, chưa tên {unnamed}, nhãn rỗng {empty}, "
            f"chỉ chữ Hán {han}, ASCII và chữ Hán {mixed}, chỉ ASCII {ascii_only}"
        )
    return lines


def _arguments(arguments: list[str]) -> bool:
    stats = False
    for arg in arguments:
        if arg == "--stats":
            stats = True
            continue
        if arg in ("--help", "-h"):
            continue
        raise ValueError(f"không rõ đối số: {arg}")
    return stats


def main(argv: list[str] | None = None) -> int:
    """Kiểm tên. --stats in số cột. Thoát 1 khi còn lỗi."""
    arguments = list(sys.argv[1:] if argv is None else argv)
    if "--help" in arguments or "-h" in arguments:
        print(HELP)
        return 0
    try:
        stats = _arguments(arguments)
    except ValueError as exc:
        print(f"lint_names.py:1: {exc}")
        return 1
    errors = check_names()
    for error in errors:
        print(error)
    if stats:
        for line in stats_lines():
            print(line)
    if errors:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
