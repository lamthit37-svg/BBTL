"""Đòn phá trên công cụ, đầu vào dựng trong build/p1-r/pha. Không sửa mã A, B, C, L."""
from __future__ import annotations

import subprocess
import sys
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
TOOLS = ROOT / "TOOLS" / "server"
BUILD = ROOT / "build" / "p1-r" / "pha"
sys.path.insert(0, str(TOOLS))

import align_columns  # noqa: E402
import scene_refs  # noqa: E402


def run_tool(args: list[str]) -> tuple[int, str]:
    completed = subprocess.run(
        [sys.executable, "-W", "error", *args],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    text = (completed.stdout + completed.stderr).strip()
    return completed.returncode, text


def show(title: str, code: int, text: str) -> None:
    print(f"## {title}")
    print(f"exit {code}")
    print(text if text else "(im)")
    print()


def cell(kind: str, value: int | str) -> align_columns.Cell:
    return (kind, value)


def column(values: list[int]) -> list[align_columns.Cell]:
    return [cell("int", value) for value in values]


def rows_of(columns: list[list[align_columns.Cell]]) -> align_columns.Rows:
    height = len(columns[0])
    built = []
    for index in range(height):
        built.append(tuple(column[index] for column in columns))
    return tuple(built)


def break_align() -> None:
    ids = column([1, 2, 3, 4])
    left = column([10, 20, 30, 40])
    right = column([100, 200, 300, 400])
    pair = align_columns.TablePair(
        ("int", "int", "int"),
        rows_of([ids, left, ids]),
        ("int", "int", "int"),
        ("ID", "Khác", "ID2"),
        rows_of([ids, right, ids]),
    )
    links = align_columns.align(pair)
    kinds = [link.kind for link in links]
    note = align_columns.link_note(links[1])
    print("## căn cột: giữa hai neo, cột nhiều giá trị khớp 0%")
    print(f"loại {kinds}")
    print(f"cột giữa {note} tên gốc {links[1].legacy_name!r}")
    print()


def break_block_comment() -> None:
    root = BUILD / "tlbb" / "Public" / "Data" / "Script"
    root.mkdir(parents=True, exist_ok=True)
    script = root / "block.lua"
    script.write_text(
        textwrap.dedent(
            """\
            --[[
            LuaFnSetSceneLoad_Map(1, "hidden.nav")
            ]]
            local name = "shown.nav"
            LuaFnSetSceneLoad_Monster(1, name)
            print("LuaFnSetSceneLoad_Area(1, \\"in_string.nav\\")")
            """
        ),
        encoding="utf-8",
    )
    calls, commented = scene_refs.collect_calls(root)
    print("## scene_refs: chú thích khối, chuỗi, hằng")
    print(f"chú thích đếm {commented}")
    for call in calls:
        print(
            f"  dòng {call.line} kind={call.kind} how={call.how}"
            f" commented={call.commented} resolved={call.resolved!r} argument={call.argument!r}"
        )
    print()


def break_rules_float() -> None:
    legacy = BUILD / "rules-legacy"
    config = legacy / "Server" / "Config"
    config.mkdir(parents=True, exist_ok=True)
    (config / "CopyScene.ini").write_text("[CopyScene]\nMaxGroup=1.5\n", encoding="utf-8")
    for name in (
        "ConfigInfo.ini",
        "DefaultChar.ini",
        "PetConfigTable.ini",
        "DarkConfigTable.ini",
        "SystemInfo.ini",
        "MergeConfig.txt",
    ):
        (config / name).write_text("", encoding="utf-8")
    public = legacy / "Public" / "Config"
    public.mkdir(parents=True, exist_ok=True)
    (public / "CombatLimits.ini").write_text("", encoding="utf-8")
    code, text = run_tool(
        [
            "TOOLS/server/import_rules.py",
            str(legacy),
            str(BUILD / "rules-out"),
            "--check",
        ]
    )
    show("import_rules trên cây giả thiếu khoá", code, text.splitlines()[0] if text else "")


def break_lint() -> None:
    path = BUILD / "dai.py"
    body = "\n".join(f"    value = {index}" for index in range(51))
    path.write_text(f"def dai(value: int) -> int:\n{body}\n    return value\n", encoding="utf-8")
    code, text = run_tool(["TOOLS/server/lint_py.py", str(path)])
    show("lint_py hàm 53 dòng", code, text)


def break_scene_orphan() -> None:
    legacy = BUILD / "scene-legacy" / "Public" / "Scene"
    legacy.mkdir(parents=True, exist_ok=True)
    (legacy / "khong_co_cha.nav").write_bytes(b"")
    code, text = run_tool(
        [
            "TOOLS/server/export_scene.py",
            str(BUILD / "scene-legacy"),
            str(BUILD / "scene-out"),
            "--check",
        ]
    )
    first = "\n".join(text.splitlines()[:4])
    show("export_scene tệp không gắn", code, first)
    print(f"thư mục đích tồn tại: {(BUILD / 'scene-out').exists()}")
    print()


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    BUILD.mkdir(parents=True, exist_ok=True)
    break_align()
    break_block_comment()
    break_lint()
    break_scene_orphan()
    break_rules_float()


if __name__ == "__main__":
    main()
