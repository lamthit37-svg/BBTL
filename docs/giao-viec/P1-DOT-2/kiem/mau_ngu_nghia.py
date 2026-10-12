"""Lấy mẫu hạt 20261007: 30 dòng column_terms và 40 dòng fate=rule.

In căn cứ đúng chỗ basis ghi. Không tự chấm đúng sai.
"""
from __future__ import annotations

import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TERMS = ROOT / "TOOLS" / "server" / "column_terms.tsv"
RULES = ROOT / "TOOLS" / "server" / "legacy_rules.tsv"
LEGACY = Path(r"C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb")
SERVER = Path(r"C:\Users\myhea\Desktop\New folder\tlbb_server")
GLOSSARY = ROOT / "docs" / "SERVER-TEP-CAU-HINH.md"
OUT = Path(__file__).resolve().parent / "mau-ra.txt"
CODE = re.compile(r"code:([^:]+):(\d+)")
SEED = 20261007


def body(path: Path) -> list[list[str]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] in ("original", "source"):
            continue
        rows.append(cells)
    return rows


def read_code(relative: str, line_number: int) -> str:
    path = SERVER / relative
    if not path.is_file():
        matches = [item for item in SERVER.rglob(Path(relative).name) if item.is_file()]
        if len(matches) != 1:
            return f"KHÔNG THẤY TỆP {relative} ({len(matches)} ứng viên)"
        path = matches[0]
    raw = path.read_bytes()
    text = raw.decode("gb18030", errors="replace")
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


def glossary_line(original: str) -> str:
    for line in GLOSSARY.read_text(encoding="utf-8").splitlines():
        if original in line and line.startswith("|"):
            return line
    return "không thấy dòng thuật ngữ chứa nguyên văn"


def ini_line(source: str, section: str, key: str) -> str:
    path = LEGACY / source
    if not path.is_file():
        return f"không thấy {source}"
    text = path.read_bytes().decode("utf-8")
    current = ""
    for number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("[") and "]" in stripped:
            current = stripped[1 : stripped.index("]")]
            continue
        if "=" not in line:
            continue
        left = line.split("=", 1)[0].strip()
        if left == key and (section == "" or current == section):
            return f"{source}:{number} [{current}] {line.strip()}"
    return f"không thấy [{section}] {key} trong {source}"


def main() -> None:
    terms = body(TERMS)
    rules = [row for row in body(RULES) if row[3] == "rule"]
    picker = random.Random(SEED)
    term_sample = picker.sample(terms, 30)
    rule_sample = picker.sample(rules, 40)
    lines = [
        f"column_terms dòng dữ liệu {len(terms)}, mẫu {len(term_sample)}",
        f"legacy_rules fate=rule {len(rules)}, mẫu {len(rule_sample)}",
        f"hạt random.Random({SEED}).sample theo thứ tự tệp",
        "",
    ]
    for index, row in enumerate(term_sample, start=1):
        original, name, basis, note = row[0], row[1], row[2], row[3]
        lines.append(f"T{index:02} original={original} name={name} basis={basis}")
        lines.append(f"    note: {note}")
        if basis == "glossary":
            lines.append(f"    phụ lục: {glossary_line(original)}")
        elif basis == "direct":
            lines.append("    căn cứ là chính nhãn original")
        else:
            for match in CODE.finditer(basis):
                lines.append("    " + read_code(match.group(1), int(match.group(2))).replace("\n", "\n    "))
        lines.append("")
    for index, row in enumerate(rule_sample, start=1):
        source, section, key = row[0], row[1], row[2]
        target = f"{row[4]} [{row[5]}] {row[6]}"
        convert, note, basis = row[8], row[9], row[10]
        lines.append(
            f"R{index:02} [{section}] {key} -> {target} convert={convert} basis={basis}"
        )
        lines.append(f"    note: {note}")
        lines.append(f"    ini: {ini_line(source, section, key)}")
        for match in CODE.finditer(basis):
            lines.append("    " + read_code(match.group(1), int(match.group(2))).replace("\n", "\n    "))
        lines.append("")
    text = "\n".join(lines)
    OUT.write_text(text, encoding="utf-8")
    print(f"ghi {OUT} {len(text)} ký tự, thuật ngữ {len(term_sample)}, luật {len(rule_sample)}")


if __name__ == "__main__":
    main()
