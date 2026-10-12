"""Phá hợp đồng trên cây giả trong build. Không sửa SERVER."""
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
EXE = ROOT / "build" / "gcc-debug" / "thienlong_lint.exe"
BASE = ROOT / "build" / "p1-dot3-r" / "pha"
LEGACY = Path(r"C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb")
NAMES = """# schema 1
# source: pha
# types: text	text	text	text	text	text	text	text	text
tree	source	fate	target	key_field	key	owner	unresolved	note
"""
REF_HEAD = (
    "# schema 1\n"
    "# types: text\ttext\ttext\ttext\ttext\tint\ttext\ttext\n"
    "child\tchild_column\tparent\tparent_column\tabsent\tknown_missing\tbasis\tnote\n"
)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


def table(path: Path, types: str, header: str, rows: list[str]) -> None:
    body = "\n".join(rows)
    text = "# schema 1\n# source: pha\n# tool: pha.py; sửa tay sẽ mất ở lượt xuất sau\n"
    text += f"# types: {types}\n{header}\n{body}\n"
    write(path, text)


def run_exe(root: Path, refs: Path) -> tuple[int, str]:
    result = subprocess.run(
        [str(EXE), "--root", str(root), "--refs", str(refs), "--report", str(root / "cpp.tsv")],
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=False,
    )
    return result.returncode, result.stdout + result.stderr


def run_py(root: Path, refs: Path) -> tuple[int, str]:
    result = subprocess.run(
        [
            "python",
            "-B",
            "-W",
            "error",
            "TOOLS/server/diff_tables.py",
            str(LEGACY),
            str(root),
            "--refs",
            str(refs),
            "--names",
            str(BASE / "names.tsv"),
            "--check",
        ],
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=False,
    )
    return result.returncode, result.stdout + result.stderr


def case_bad_known() -> None:
    root = BASE / "known"
    table(root / "tables" / "a.tsv", "int", "id", ["1"])
    refs = root / "refs"
    write(refs / "a.tsv", REF_HEAD + "tables/a.tsv\tid\ttables/a.tsv\tid\t\t\tdata\ttrống\n")
    code, text = run_exe(root, refs)
    print(f"known_missing trống exe {code}")
    print(text)


def case_clash() -> None:
    root = BASE / "clash"
    table(root / "tables" / "parent_int.tsv", "int", "id", ["1"])
    table(root / "tables" / "parent_text.tsv", "text", "id", ["a"])
    table(root / "tables" / "child_int.tsv", "int", "id", ["1"])
    table(root / "tables" / "child_text.tsv", "text", "label", ["a"])
    refs = root / "refs"
    write(
        refs / "a.tsv",
        REF_HEAD
        + "tables/child_int.tsv\tid\ttables/parent_int.tsv\tid\t\t0\tdata\tint\n"
        + "tables/child_text.tsv\tlabel\ttables/parent_text.tsv\tid\t\t0\tdata\ttext\n",
    )
    code, text = run_exe(root, refs)
    print(f"khác kiểu giả exe {code}")
    print(text)


def case_parent_absent() -> None:
    root = BASE / "absent"
    table(root / "tables" / "child.tsv", "int", "id", ["7"])
    refs = root / "refs"
    write(
        refs / "a.tsv",
        REF_HEAD + "tables/child.tsv\tid\ttables/missing.tsv\tid\t\t1\tdata\tcha không có\n",
    )
    exe_code, exe_text = run_exe(root, refs)
    py_code, py_text = run_py(root, refs)
    print(f"cha không có exe {exe_code}")
    print(exe_text)
    print(f"cha không có py {py_code}")
    print(py_text)


def case_short_and_empty() -> None:
    root = BASE / "cut"
    write(root / "tables" / "empty.tsv", "")
    write(root / "tables" / "cut.tsv", "abc")
    utf_path = root / "tables" / "utf.tsv"
    utf_path.parent.mkdir(parents=True, exist_ok=True)
    utf_path.write_bytes(b"# schema 1\n# types: int\nid\n\xff\n")
    write(
        root / "tables" / "short.tsv",
        "# schema 1\n# types: int\tint\nid\tvalue\n1\n",
    )
    refs = root / "refs"
    write(refs / "a.tsv", REF_HEAD + "tables/short.tsv\tid\ttables/short.tsv\tid\t\t0\tdata\tngắn\n")
    code, text = run_exe(root, refs)
    print(f"tệp hỏng exe {code}")
    print(text)


def main() -> None:
    write(BASE / "names.tsv", NAMES)
    case_bad_known()
    case_clash()
    case_parent_absent()
    case_short_and_empty()


if __name__ == "__main__":
    main()
