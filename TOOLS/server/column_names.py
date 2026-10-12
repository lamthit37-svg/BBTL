"""Đặt tên cột cho bảng client và bảng máy chủ.

Thứ tự: thuật ngữ đúng scope, mẫu {n}, M1, M2, rồi column_<n>.
Mission và Task không đổi thành quest: phụ lục nói bảng 2026 chưa đổi cột thì giữ mission.
KFS còn dấu hỏi vì phụ lục ghi martial_soul (?).
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

import align_columns

_IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
_CAMEL = re.compile(r"[A-Z]+(?![a-z])|[A-Z]?[a-z]+|\d+")
_FALLBACK = re.compile(r"column_\d+")
_STEM = re.compile(r"(.*)\$\d+\$$")
_COLUMN = re.compile(r"^[a-z][a-z0-9_]*$")
_M2 = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)[(（].*[)）]$")
_KEEP_TOKEN = frozenset({"mission", "task"})
_UNCERTAIN = frozenset({"kfs"})
_TERM_FILES = ("column_terms.tsv", "column_terms_server.tsv")
PRIORITY = frozenset(
    {
        "SkillTemplate_V1.txt",
        "SkillData_V1.txt",
        "XinFa_V1.txt",
        "MonsterAttrExTable.txt",
        "CommonItem.txt",
        "PlayerExpLevel.txt",
        "ImpactSEData_V1.txt",
        "SpecialObjData.txt",
        "Bullet.txt",
        "AttackTraits.txt",
        "SceneAttr.txt",
    }
)
_TERM_CACHE: list[tuple[TermRow, ...]] = []


@dataclass(frozen=True)
class TermRow:
    original: str
    scope: str
    name: str
    basis: str
    note: str


def _glossary_rows(text: str) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    for line in text.splitlines():
        if not line or line.startswith("#") or line.startswith("original\t"):
            continue
        original, chinese, name, _banned = line.split("\t")
        rows.append((original, chinese, name))
    return rows


def _glossary_from(rows: list[tuple[str, str, str]]) -> dict[str, tuple[str, bool]]:
    found: dict[str, tuple[str, bool]] = {}
    for original, chinese, english in rows:
        key = original.replace("_", "").casefold()
        if key in _KEEP_TOKEN:
            continue
        value = (english, key in _UNCERTAIN)
        found[key] = value
        if chinese and chinese not in found:
            found[chinese] = value
    return found


def _load_glossary() -> dict[str, tuple[str, bool]]:
    path = Path(__file__).with_name("glossary.tsv")
    return _glossary_from(_glossary_rows(path.read_text(encoding="utf-8")))


GLOSSARY = _load_glossary()


def allow_terms(source: str) -> bool:
    """Chỉ mười một bảng ưu tiên từng được lấy tên từ column_terms."""
    return Path(source).name in PRIORITY


def english_name(original: str) -> tuple[str | None, bool]:
    """Tên cột tiếng Anh, hoặc None khi không dịch được. Bool là thuật ngữ còn dấu hỏi."""
    body = original
    stem = _STEM.fullmatch(original)
    if stem:
        body = stem.group(1)
    folded = body.replace("_", "").casefold()
    if folded in GLOSSARY:
        return GLOSSARY[folded]
    if not _IDENT.fullmatch(body):
        return None, False
    return _from_identifier(body)


def _from_identifier(body: str) -> tuple[str | None, bool]:
    parts: list[str] = []
    uncertain = False
    for chunk in body.split("_"):
        if not chunk:
            continue
        for piece in _CAMEL.findall(chunk):
            token = piece.lower()
            if token in GLOSSARY:
                name, flag = GLOSSARY[token]
                parts.append(name)
                uncertain = uncertain or flag
            else:
                parts.append(token)
    name = "_".join(parts)
    if not _COLUMN.fullmatch(name) or _FALLBACK.fullmatch(name):
        return None, False
    return name, uncertain


def snake(name: str) -> str:
    """CamelCase thành snake_case, không tra thuật ngữ."""
    text = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name)
    text = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", text)
    return text.lower()


def free_name(used: set[str], index: int) -> str:
    """Tên column_<n> còn trống khi đánh số bị đụng."""
    fallback = f"column_{index}"
    if fallback not in used:
        return fallback
    suffix = 2
    while f"{fallback}_{suffix}" in used:
        suffix += 1
    return f"{fallback}_{suffix}"


def number_repeated(names: list[str]) -> tuple[list[str], set[int]]:
    """Tên lặp thành name_1, name_2. Trả các chỉ số phải đổ về column_<n>."""
    totals: dict[str, int] = {}
    for name in names:
        totals[name] = totals.get(name, 0) + 1
    numbered = _with_indexes(names, totals)
    return _resolve_clashes(numbered)


def _with_indexes(names: list[str], totals: dict[str, int]) -> list[str]:
    seen_count: dict[str, int] = {}
    numbered: list[str] = []
    for name in names:
        if totals[name] == 1:
            numbered.append(name)
            continue
        seen_count[name] = seen_count.get(name, 0) + 1
        numbered.append(f"{name}_{seen_count[name]}")
    return numbered


def _resolve_clashes(numbered: list[str]) -> tuple[list[str], set[int]]:
    used: set[str] = set()
    clashes: set[int] = set()
    fixed: list[str] = []
    for index, name in enumerate(numbered):
        if name not in used:
            used.add(name)
            fixed.append(name)
            continue
        fallback = free_name(used, index)
        used.add(fallback)
        fixed.append(fallback)
        clashes.add(index)
    return fixed, clashes


def m2_identifier(original: str) -> str | None:
    """Phần định danh ASCII đứng trước ngoặc giải thích, nếu nhãn đúng mẫu M2."""
    match = _M2.fullmatch(original.strip())
    if match is None:
        return None
    return match.group(1)


def _rows_of(path: Path) -> list[TermRow]:
    rows: list[TermRow] = []
    for term in align_columns.read_terms(path):
        rows.append(TermRow(term.original, term.scope, term.name, term.basis, term.note))
    return rows


def _reject_conflicts(rows: list[TermRow]) -> None:
    seen: dict[tuple[str, str], str] = {}
    for row in rows:
        key = (row.original, row.scope)
        previous = seen.get(key)
        if previous is None:
            seen[key] = row.name
            continue
        if previous != row.name:
            raise ValueError(f"thuật ngữ {row.original} / {row.scope} có hai tên")


def _read_all_terms() -> tuple[TermRow, ...]:
    folder = Path(__file__).resolve().parent
    found: list[TermRow] = []
    for name in _TERM_FILES:
        path = folder / name
        if path.is_file():
            found.extend(_rows_of(path))
    _reject_conflicts(found)
    return tuple(found)


def load_terms() -> tuple[TermRow, ...]:
    """Đọc gộp hai bảng thuật ngữ. Cùng khoá mà khác tên thì lỗi."""
    if _TERM_CACHE:
        return _TERM_CACHE[0]
    loaded = _read_all_terms()
    _TERM_CACHE.append(loaded)
    return loaded


def _exact_name(original: str, scope: str, terms: tuple[TermRow, ...]) -> str | None:
    general: str | None = None
    for term in terms:
        if term.original != original or "{n}" in term.original:
            continue
        if term.scope == scope:
            return term.name
        if term.scope == "" and general is None:
            general = term.name
    return general


def _fill_pattern(term: TermRow, original: str) -> str | None:
    parts = term.original.split("{n}")
    pattern = r"(\d+)".join(re.escape(part) for part in parts)
    matched = re.fullmatch(pattern, original)
    if matched is None:
        return None
    name = term.name
    for group in matched.groups():
        name = name.replace("{n}", group, 1)
    if not _COLUMN.fullmatch(name):
        return None
    return name


def _candidate(term: TermRow, original: str, scope: str) -> str | None:
    if "{n}" not in term.original or term.scope not in ("", scope):
        return None
    return _fill_pattern(term, original)


def _rank(term: TermRow, index: int) -> tuple[int, int, int]:
    literal = len(term.original) - 3 * term.original.count("{n}")
    return (1 if term.scope else 0, literal, -index)


def _pattern_name(original: str, scope: str, terms: tuple[TermRow, ...]) -> str | None:
    best_rank: tuple[int, int, int] | None = None
    best_name = ""
    for index, term in enumerate(terms):
        found = _candidate(term, original, scope)
        if found is None:
            continue
        rank = _rank(term, index)
        if best_rank is None or rank > best_rank:
            best_rank = rank
            best_name = found
    if best_rank is None:
        return None
    return best_name


def _stem(original: str) -> str:
    matched = _STEM.fullmatch(original)
    if matched is None:
        return original
    return matched.group(1)


def _accepted(named: tuple[str | None, bool], index: int, rule: str) -> tuple[str, str]:
    name, uncertain = named
    if name is None:
        return f"column_{index}", "failed"
    if uncertain:
        return name, "uncertain"
    return name, rule


def _machine(original: str, index: int) -> tuple[str, str]:
    body = _stem(original)
    ident = m2_identifier(body)
    if ident is not None:
        return _accepted(english_name(ident), index, "m2")
    return _accepted(english_name(body), index, "m1")


def classify(original: str, scope: str, terms: tuple[TermRow, ...], index: int) -> tuple[str, str]:
    """Tên và luật: exact, pattern, m1, m2, uncertain, failed."""
    exact = _exact_name(original, scope, terms)
    if exact is not None:
        return exact, "exact"
    patterned = _pattern_name(original, scope, terms)
    if patterned is not None:
        return patterned, "pattern"
    return _machine(original, index)


def flag_note(flag: str) -> str:
    """Câu ghi luật đã đặt tên. Cột không đặt được giữ dấu ?."""
    if flag == "failed":
        return "?"
    if flag == "uncertain":
        return "? thuật ngữ chưa chốt; luật: M1"
    if flag == "collision":
        return "? trùng tên sau khi dịch"
    if flag == "exact":
        return "luật: nguyên văn"
    if flag == "pattern":
        return "luật: mẫu {n}"
    if flag == "m1":
        return "luật: M1"
    if flag == "m2":
        return "luật: M2"
    return ""


def _chosen(
    originals: list[str], scope: str, terms: tuple[TermRow, ...]
) -> list[tuple[str, str]]:
    chosen: list[tuple[str, str]] = []
    for index, original in enumerate(originals):
        if original.strip() == "":
            chosen.append((f"column_{index}", "failed"))
            continue
        chosen.append(classify(original, scope, terms, index))
    return chosen


def _final_note(index: int, clashes: set[int], chosen: list[tuple[str, str]]) -> str:
    if index in clashes:
        return flag_note("collision")
    return flag_note(chosen[index][1])


def named_columns(
    originals: list[str],
    scope: str = "",
    terms: tuple[TermRow, ...] | None = None,
) -> tuple[list[str], list[str]]:
    """Tên cột và câu luật. terms=None thì đọc hai bảng thuật ngữ trên đĩa."""
    chosen_terms = load_terms() if terms is None else terms
    chosen = _chosen(originals, scope, chosen_terms)
    numbered, clashes = number_repeated([item[0] for item in chosen])
    notes = [_final_note(index, clashes, chosen) for index in range(len(chosen))]
    return numbered, notes
