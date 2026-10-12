"""Bổ sung Đ6 (số ca test đếm theo Case{.name, số tin, trường, mẫu) và nội dung dòng khớp của T18."""
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path.cwd()
SO_DO = ROOT / "docs/giao-viec/P2-DOT-2/so-do"
HITS = {"SRC/protocol/messages.cpp": (209, 221),
        "tests/protocol_samples.hpp": (155, 161, 167, 271, 278, 290, 297, 327, 333, 339, 458, 464, 470),
        "docs/giao-viec/P2-DOT-2/so-do/l-t.py": (28,)}


def save(name: str, lines: list[str]) -> None:
    path = SO_DO / name
    if path.exists():
        raise SystemExit(f"đã có {name}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"đã ghi so-do/{name}")


def rows(name: str) -> int:
    text = (ROOT / "SRC/protocol/catalog" / name).read_text(encoding="utf-8")
    return sum(1 for line in text.splitlines()[1:] if line.strip() and not line.startswith("#"))


def main() -> int:
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [f"# {now}  Đ6 bổ sung: l-d6.log đếm game::test::Case{{ nên ra 0 ở bốn tệp; ở đây đếm Case{{.name", "",
             "### ca test (đếm chuỗi 'Case{.name')"]
    for path in sorted((ROOT / "tests").glob("*_tests.cpp")):
        rel = path.relative_to(ROOT).as_posix()
        if rel in {"tests/net_tests.cpp", "tests/protocol_catalog_tests.cpp", "tests/protocol_fuzz_tests.cpp",
                   "tests/protocol_tests.cpp", "tests/wire_loop_tests.cpp"}:
            lines.append(f"{rel}: {path.read_text(encoding='utf-8').count('Case{.name')} ca")
    samples = (ROOT / "tests/protocol_samples.hpp").read_text(encoding="utf-8")
    lines += ["", "### bảng tin (dòng dữ liệu, bỏ dòng tiêu đề và dòng chú thích #)"]
    lines += [f"SRC/protocol/catalog/{name}: {rows(name)} dòng" for name in
              ("groups.tsv", "messages.tsv", "fields.tsv", "enums.tsv")]
    lines += ["", f"tests/protocol_samples.hpp: {len(re.findall(r'Frame\{', samples))} mẫu (đếm 'Frame{{')", ""]
    save("l-d6-bo-sung.log", lines)
    hit_lines = [f"# {now}  T18: nội dung các dòng khớp mẫu bí mật trong l-t18.log", ""]
    for name, numbers in HITS.items():
        text = (ROOT / name).read_text(encoding="utf-8").splitlines()
        hit_lines += [f"{name}:{number}: {text[number - 1].strip()}" for number in numbers]
    save("l-t18-bi-mat.log", hit_lines + [""])
    return 0


if __name__ == "__main__":
    sys.exit(main())