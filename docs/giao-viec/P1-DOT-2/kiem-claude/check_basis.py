"""Mở từng dòng mã mà cột basis dẫn tới (Claude, 2026-10-07).

    python docs/giao-viec/P1-DOT-2/kiem-claude/check_basis.py <tlbb_server> [--show]

column_terms.tsv: basis code:<tệp>:<dòng> phải trỏ tới dòng có định danh mà note nêu (m_...).
legacy_rules.tsv: dòng mã được dẫn phải chứa tên khoá ini. Lệch trong khoảng 2 dòng vẫn tính là
trúng, xa hơn thì in ra.
"""
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve()
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / "docs/giao-viec/P1-DOT-1/kiem-claude"))
from verify_p1 import parse_like_cpp  # noqa: E402

sys.stdout.reconfigure(encoding="utf-8")
SOURCE = Path(sys.argv[1])
SHOW = "--show" in sys.argv
CODE = re.compile(r"code:([^:;]+):(\d+)")


def index_sources():
    found = {}
    for path in SOURCE.rglob("*"):
        if path.suffix.lower() in (".cpp", ".h", ".inl"):
            found.setdefault(path.name.casefold(), []).append(path)
    return found


def lines_of(path: Path):
    data = path.read_bytes()
    for encoding in ("utf-8", "gb18030"):
        try:
            return data.decode(encoding).split("\n")
        except UnicodeDecodeError:
            continue
    return data.decode("latin-1").split("\n")


def near(lines, number: int, words) -> bool:
    window = "\n".join(lines[max(0, number - 3) : number + 2])
    return any(word and word in window for word in words)


def check(name: str, rows, words_of):
    sources = index_sources()
    cited = hit = missing = 0
    for row in rows:
        for match in CODE.finditer(row["basis"]):
            cited += 1
            paths = sources.get(Path(match.group(1)).name.casefold(), [])
            number = int(match.group(2))
            words = words_of(row)
            ok = False
            for path in paths:
                lines = lines_of(path)
                if number <= len(lines) and near(lines, number, words):
                    ok = True
                    if SHOW:
                        print(f"    {row['basis']}: {lines[number - 1].strip()[:110]}")
                    break
            if not paths:
                missing += 1
                print(f"    không có tệp mã: {row['basis']}")
            elif ok:
                hit += 1
            else:
                line = lines_of(paths[0])[number - 1].strip()[:100] if number <= len(lines_of(paths[0])) else "<ngoài tệp>"
                print(f"    không thấy {words} quanh {match.group(0)}: {line}")
    print(f"{name}: {cited} chỗ dẫn mã, trúng {hit}, không có tệp {missing}, trật {cited - hit - missing}")


def rows_of(path: Path):
    header, _, rows, problems, _ = parse_like_cpp(path)
    assert not problems, problems
    return [dict(zip(header, row)) for row in rows]


if __name__ == "__main__":
    terms = rows_of(ROOT / "TOOLS/server/column_terms.tsv")
    check("column_terms.tsv", terms, lambda row: re.findall(r"m_\w+|Skip[\w ]+", row["note"]))
    rules = rows_of(ROOT / "TOOLS/server/legacy_rules.tsv")
    check("legacy_rules.tsv", rules, lambda row: [row["key"].rstrip("0123456789")])
