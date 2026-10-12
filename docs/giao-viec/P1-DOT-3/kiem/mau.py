"""Mẫu hạt 20261008. Không chấm đúng sai. Không gọi diff_tables hay thienlong_lint."""
from __future__ import annotations

import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TOOLS = ROOT / "TOOLS" / "server"
TERMS = TOOLS / "column_terms.tsv"
SERVER_TERMS = TOOLS / "column_terms_server.tsv"
REFS = TOOLS / "refs"
CODE = Path(r"C:\Users\myhea\Desktop\New folder\tlbb_server")
OUT = Path(__file__).resolve().parent / "mau-ra.txt"
SEED = 20261008


def rows(path: Path) -> list[tuple[int, list[str]]]:
    found: list[tuple[int, list[str]]] = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] in ("original", "child"):
            continue
        found.append((number, cells))
    return found


def ref_rows() -> list[tuple[str, int, list[str]]]:
    found: list[tuple[str, int, list[str]]] = []
    for path in sorted(REFS.glob("*.tsv")):
        for number, cells in rows(path):
            found.append((path.name, number, cells))
    return found


def read_code(relative: str, line_number: int) -> str:
    path = CODE / Path(relative)
    if not path.is_file():
        matches = [item for item in CODE.rglob(path.name) if item.is_file()]
        if len(matches) != 1:
            return f"KHÔNG THẤY TỆP {relative} ({len(matches)} ứng viên)"
        path = matches[0]
    text = path.read_bytes().decode("gb18030", errors="replace")
    lines = text.splitlines()
    if line_number < 1 or line_number > len(lines):
        return f"{path.name}: không có dòng {line_number}, tệp {len(lines)} dòng"
    start = max(1, line_number - 1)
    end = min(len(lines), line_number + 1)
    shown = []
    for number in range(start, end + 1):
        mark = ">" if number == line_number else " "
        shown.append(f"{mark}{number}: {lines[number - 1].strip()}")
    return "\n".join(shown)


def glossary_hit(original: str) -> str:
    hits = []
    for number, cells in rows(TOOLS / "glossary.tsv"):
        if original in cells[0] or original in cells[1] or original.casefold() == cells[0].casefold():
            hits.append(f"glossary.tsv:{number}: {cells[0]} / {cells[1]} -> {cells[2]} banned={cells[3]}")
    if not hits:
        return "không thấy dòng glossary"
    return "\n".join(hits)


def one_term(kind: str, number: int, cells: list[str]) -> str:
    original, scope, name, basis, note = cells[:5]
    head = f"{kind}:{number}: [{scope}] {original!r} -> {name} | {basis} | {note}"
    if basis == "glossary":
        proof = glossary_hit(original)
    elif basis.startswith("code:"):
        body = basis[len("code:") :]
        relative, _, line_text = body.rpartition(":")
        proof = read_code(relative, int(line_text))
    elif basis == "direct":
        proof = "direct: chỉ có nhãn và câu note"
    else:
        proof = f"basis lạ: {basis}"
    return head + "\n" + proof


def one_ref(name: str, number: int, cells: list[str]) -> str:
    child, child_column, parent, parent_column, absent, missing, basis, note = cells
    head = (
        f"refs/{name}:{number}: {child} {child_column} -> {parent} {parent_column}"
        f" absent={absent!r} known_missing={missing} | {basis} | {note}"
    )
    if basis.startswith("code:"):
        body = basis[len("code:") :]
        relative, _, line_text = body.rpartition(":")
        proof = read_code(relative, int(line_text))
    elif basis == "label":
        proof = "label: nhãn cột phải tự nói bảng đích"
    elif basis == "data":
        proof = "data: note phải có tỉ lệ đã đo"
    else:
        proof = f"basis lạ: {basis}"
    return head + "\n" + proof


def main() -> None:
    terms = rows(TERMS)
    server_terms = rows(SERVER_TERMS)
    refs = ref_rows()
    picker = random.Random(SEED)
    term_pick = picker.sample(terms, 40)
    server_pick = picker.sample(server_terms, 40)
    ref_pick = picker.sample(refs, 15)
    blocks = [
        f"hạt {SEED}",
        f"column_terms dòng dữ liệu {len(terms)}, lấy 40",
        f"column_terms_server dòng dữ liệu {len(server_terms)}, lấy 40",
        f"refs dòng dữ liệu {len(refs)}, lấy 15",
        "",
        "===== column_terms =====",
    ]
    blocks.extend(one_term("column_terms.tsv", number, cells) for number, cells in term_pick)
    blocks.append("")
    blocks.append("===== column_terms_server =====")
    blocks.extend(one_term("column_terms_server.tsv", number, cells) for number, cells in server_pick)
    blocks.append("")
    blocks.append("===== refs =====")
    blocks.extend(one_ref(name, number, cells) for name, number, cells in ref_pick)
    OUT.write_text("\n\n".join(blocks) + "\n", encoding="utf-8")
    print(f"ghi {OUT}")
    print(f"terms {len(terms)} server {len(server_terms)} refs {len(refs)}")


if __name__ == "__main__":
    main()
