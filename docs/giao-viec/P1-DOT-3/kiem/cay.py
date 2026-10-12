"""Cấy năm lỗi vào bản chép và chạy thienlong_lint. Không sửa SERVER."""
from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
EXE = ROOT / "build" / "gcc-debug" / "thienlong_lint.exe"
SRC = ROOT / "SERVER"
DEST = ROOT / "build" / "p1-dot3-r" / "cay"


def write(path: Path, text: str) -> None:
    path.write_bytes(text.encode("utf-8"))


def plant() -> None:
    if DEST.exists():
        shutil.rmtree(DEST)
    server = DEST / "tables" / "server"
    shutil.copytree(SRC / "tables" / "server", server)
    scenes = [path for path in (SRC / "scenes").iterdir() if path.is_dir()]
    scenes.sort(key=lambda path: sum(item.stat().st_size for item in path.rglob("*") if item.is_file()))
    for scene in scenes[:2]:
        shutil.copytree(scene, DEST / "scenes" / scene.name)
        print(f"cảnh {scene.name}")
    bom = server / "pet_death_happiness_loss.tsv"
    write(bom, "\ufeff" + bom.read_text(encoding="utf-8"))
    print(f"BOM {bom.relative_to(DEST).as_posix()}")
    carriage = server / "pet_mutant_quality_odds.tsv"
    write(carriage, carriage.read_text(encoding="utf-8").replace("\n", "\r\n"))
    print(f"CR {carriage.relative_to(DEST).as_posix()}")
    zero = server / "pet_skill_index.tsv"
    lines = zero.read_text(encoding="utf-8").split("\n")
    header = next(line for line in lines if line and not line.startswith("#"))
    skill_id = header.split("\t").index("skill_id")
    for number, line in enumerate(lines, start=1):
        if not line or line.startswith("#") or line == header:
            continue
        cells = line.split("\t")
        cells[skill_id] = "0" + cells[skill_id]
        lines[number - 1] = "\t".join(cells)
        write(zero, "\n".join(lines))
        print(f"số 0 đứng đầu {zero.relative_to(DEST).as_posix()}:{number}: {cells[skill_id]}")
        break
    scenes_table = server / "scenes.tsv"
    scene_lines = scenes_table.read_text(encoding="utf-8").split("\n")
    header = next(line for line in scene_lines if line and not line.startswith("#"))
    column = header.split("\t").index("scene_id")
    data_rows = [index for index, line in enumerate(scene_lines) if line and not line.startswith("#") and line != header]
    first = scene_lines[data_rows[0]]
    scene_lines.insert(data_rows[0] + 1, first)
    write(scenes_table, "\n".join(scene_lines))
    print(f"khoá lặp scenes.tsv:{data_rows[0] + 2}: scene_id {first.split(chr(9))[column]}")
    hosting = server / "scene_hosting.tsv"
    host_lines = hosting.read_text(encoding="utf-8").split("\n")
    host_header = next(line for line in host_lines if line and not line.startswith("#"))
    host_column = host_header.split("\t").index("scene_id")
    for index, line in enumerate(host_lines):
        if line and not line.startswith("#") and line != host_header:
            cells = line.split("\t")
            cells[host_column] = "999999"
            host_lines[index] = "\t".join(cells)
            write(hosting, "\n".join(host_lines))
            print(f"trỏ hụt scene_hosting.tsv:{index + 1}: 999999")
            break
    refs = DEST / "refs"
    refs.mkdir()
    write(
        refs / "probe.tsv",
        "# schema 1\n"
        "# types: text\ttext\ttext\ttext\ttext\tint\ttext\ttext\n"
        "child\tchild_column\tparent\tparent_column\tabsent\tknown_missing\tbasis\tnote\n"
        "tables/server/scene_hosting.tsv\tscene_id\ttables/server/scenes.tsv\tscene_id\t\t0\tdata\tcấy một id\n",
    )


def main() -> None:
    plant()
    result = subprocess.run(
        [str(EXE), "--root", str(DEST), "--refs", str(DEST / "refs")],
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=False,
    )
    print(f"EXIT:{result.returncode}")
    print(result.stdout)
    print(result.stderr)


if __name__ == "__main__":
    main()
