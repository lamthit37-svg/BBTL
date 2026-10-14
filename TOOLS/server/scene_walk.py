"""Chọn nguồn lưới đi cho từng cảnh của dev/server/scenes và ghi vào scene.toml.

    python TOOLS/server/scene_walk.py <gốc dev/server> <gốc tlbb của XJL7457> <thư mục Scene của client> [--check]

Thứ bậc (đề bài chung đợt gameplay: client 2026 thắng):
  1. `client_2026_path`: tệp .path của client 2026 (lưới tam giác của PathLib.dll, đọc bằng src/shared/nav),
     chép thành walk.path. Chỉ dùng khi cảnh ghép được vào đúng MỘT tệp .path của client (xem scene_xref.py) và
     tài nguyên đó là của riêng cảnh: tài nguyên dùng chung cho hàng nghìn id (擂台, leitai_1.path cỡ 64 x 64)
     không phải lưới của cảnh nào trong số đó, nên cảnh rơi xuống bậc 2.
     Còn một điều kiện nữa: quá MAX_OUTSIDE_PERCENT quái đặt trong cảnh mà đứng ngoài hộp bao đỉnh của .path (nới
     EXTENT_SLACK) thì lưới là của cảnh khác (đo 2026-10-14: gusufb, lưới 64 x 64, quái tới 465; 200/269 quái ngoài).
     Cảnh rơi xuống bậc 2 và scene.toml ghi lý do. Vài quái lạc ngoài hộp thì không bỏ lưới: client thắng, bộ đọc
     C++ (scenedata::audit_scene) đếm lại. Chỉ bác khi có bằng chứng: .path đọc không ra đầu tệp thì vẫn dùng.
  2. `legacy_nav_0859602` / `legacy_nav_xjl7457`: walk.nav, lưới ô 0,5 đơn vị của máy chủ 2008, chỉ khi cảnh
     không có .path của client.
  3. `none`: cảnh không có lưới nào.
walk.nav vẫn giữ cạnh walk.path làm dự phòng; scene.toml ghi `walk_nav` để bộ đọc biết.

Chạy sau export_scene.py và import_scene_xjl.py (hai công cụ đó ghi lại scene.toml và xoá walk.path).
"""
from __future__ import annotations

import math
import shutil
import struct
import sys
from dataclasses import dataclass
from pathlib import Path

import config_style
import scene_xref
import tsv_file

HELP = __doc__ or ""
BLOCK_TITLE = "Nguồn lưới đi"
SOURCE_CLIENT = "client_2026_path"
SOURCE_NAV_0859602 = "legacy_nav_0859602"
SOURCE_NAV_XJL = "legacy_nav_xjl7457"
SOURCE_NONE = "none"
EXTENT_SLACK = 1.0  # đơn vị thế giới: quái đứng sát mép lưới (toạ độ tròn 64.0) vẫn tính là nằm trong
MAX_OUTSIDE_PERCENT = 10  # quá tỉ lệ này quái nằm ngoài hộp bao thì .path không phải lưới của cảnh
# Số bản của tệp .path (src/shared/nav/mesh.cpp) và số byte của một chỉ số/số đếm ở mỗi bản.
PATH_INDEX_BYTES = {0x2000: 4, 0x1000: 2}
Bounds = tuple[float, float, float, float]  # x nhỏ, z nhỏ, x lớn, z lớn
Point = tuple[float, float]


@dataclass(frozen=True)
class Choice:
    source: str
    path: Path | None = None
    rejected: str = ""  # lý do bỏ .path của client (rỗng khi không có .path nào bị bỏ)


WALK_COMMENTS = {
    "walk_source": "nguồn lưới đi dùng khi chạy",
    "walk_path": "tệp .path của client 2026 đã chép vào",
    "walk_client_file": "tên tệp gốc trong thư mục Scene của client 2026",
    "walk_nav": "lưới ô của máy chủ 2008, dự phòng",
}


def mesh_bounds(data: bytes) -> Bounds | None:
    """Hộp bao các đỉnh của tệp .path; None khi đầu tệp không đọc ra được (cụt, số bản lạ, toạ độ hỏng)."""
    if len(data) < 2:
        return None
    width = PATH_INDEX_BYTES.get(int.from_bytes(data[:2], "little"))
    if width is None or len(data) < 2 + width:
        return None
    count = int.from_bytes(data[2 : 2 + width], "little")
    start = 2 + width
    if count == 0 or count > (len(data) - start) // 8:
        return None
    values = struct.unpack_from(f"<{2 * count}f", data, start)
    if not all(math.isfinite(value) for value in values):
        return None
    return min(values[0::2]), min(values[1::2]), max(values[0::2]), max(values[1::2])


def _placed_points(table: tsv_file.Table) -> list[Point]:
    if "position_x" not in table.columns or "position_z" not in table.columns:
        return []
    at_x, at_z = table.columns.index("position_x"), table.columns.index("position_z")
    points: list[Point] = []
    for row in table.rows:
        try:
            point = (float(row[at_x]), float(row[at_z]))
        except ValueError:
            continue  # ô trống: quái không khai toạ độ (đọc như 0 ở máy chủ 2008), không phải chỗ đặt
        if point != (0.0, 0.0):  # (0, 0) là mục chỉ chạy kịch bản (type 0, không tên), không phải chỗ quái đứng
            points.append(point)
    return points


def spawn_points(folder: Path) -> list[Point]:
    """Toạ độ quái đặt (x, z) trong mọi bảng spawns*.tsv của cảnh; bỏ quái không khai toạ độ."""
    points: list[Point] = []
    for table in sorted(folder.glob("spawns*.tsv")):
        points += _placed_points(tsv_file.read_table(table))
    return points


def _inside(mesh: Bounds, point: Point) -> bool:
    return mesh[0] - EXTENT_SLACK <= point[0] <= mesh[2] + EXTENT_SLACK and (
        mesh[1] - EXTENT_SLACK <= point[1] <= mesh[3] + EXTENT_SLACK
    )


def extent_conflict(mesh: Bounds, points: list[Point]) -> str:
    """Lý do .path không phải lưới của cảnh có các quái này; rỗng khi đủ quái nằm trong hộp bao."""
    outside = sum(1 for point in points if not _inside(mesh, point))
    if outside * 100 <= len(points) * MAX_OUTSIDE_PERCENT:
        return ""
    box = f"x {mesh[0]:g}..{mesh[2]:g} z {mesh[1]:g}..{mesh[3]:g}"
    return f"{outside}/{len(points)} quái đứng ngoài hộp bao .path {box}"


def client_path_file(group: scene_xref.Group, client: scene_xref.Client, files: dict[str, Path]) -> Path | None:
    """Tệp .path của client mà cảnh ghép tới, hoặc None khi không ghép được đúng một tệp riêng của cảnh."""
    own = [res for res in group.client_res_ids if len(client.ids_of_res.get(res, ())) <= scene_xref.GENERIC_RES_IDS]
    names = {client.path_of_res.get(res, "") for res in own}
    names.discard("")
    if len(names) != 1:
        return None
    return files.get(next(iter(names)).lower())


def check_extent(path: Path, folder: Path) -> str:
    """Lý do bỏ .path của client vì hộp bao nhỏ hơn chỗ đặt quái; rỗng khi dùng được."""
    mesh = mesh_bounds(path.read_bytes())
    points = spawn_points(folder)
    if mesh is None or not points:
        return ""
    return extent_conflict(mesh, points)


def choose(
    group: scene_xref.Group, client: scene_xref.Client, files: dict[str, Path], scenes: Path
) -> Choice:
    """Nguồn lưới đi của một cảnh, tệp .path của client nếu nguồn là nó, và lý do nếu .path bị bỏ."""
    folder = scenes / group.scene_dir
    path = client_path_file(group, client, files)
    reason = check_extent(path, folder) if path is not None else ""
    if path is not None and not reason:
        return Choice(SOURCE_CLIENT, path)
    reason = f"{path.name}: {reason}" if path is not None else ""
    if (folder / "walk.nav").is_file():
        from_xjl = group.dir_tool.endswith("import_scene_xjl.py")
        return Choice(SOURCE_NAV_XJL if from_xjl else SOURCE_NAV_0859602, None, reason)
    return Choice(SOURCE_NONE, None, reason)


def block_lines(source: str, client_file: str, has_nav: bool, rejected: str = "") -> list[str]:
    lines = config_style.banner(BLOCK_TITLE)
    lines += config_style.comment("Lưới đi chạy thật: .path của client 2026 nếu cảnh có, không thì walk.nav.")
    if rejected:
        lines += config_style.comment(f"Đã bỏ {rejected}")
    lines.append(f'walk_source = "{source}"   # {WALK_COMMENTS["walk_source"]}')
    if source == SOURCE_CLIENT:
        lines.append(f'walk_path = "walk.path"   # {WALK_COMMENTS["walk_path"]}')
        lines.append(f'walk_client_file = "{client_file}"   # {WALK_COMMENTS["walk_client_file"]}')
    if has_nav:
        lines.append(f'walk_nav = "walk.nav"   # {WALK_COMMENTS["walk_nav"]}')
    return lines


def strip_block(lines: list[str]) -> list[str]:
    """Bỏ khối `Nguồn lưới đi` của lượt trước (khối luôn nằm cuối tệp, sau một dòng trống)."""
    banner_at = [index for index, line in enumerate(lines) if line == f"# {BLOCK_TITLE}"]
    if not banner_at:
        return lines
    start = banner_at[0] - 1
    while start > 0 and lines[start - 1] == "":
        start -= 1
    return lines[:start]


def rewrite_toml(toml: Path, choice: Choice, has_nav: bool) -> None:
    lines = strip_block(toml.read_text(encoding="utf-8").splitlines())
    client_file = choice.path.name if choice.path else ""
    lines = [*lines, "", *block_lines(choice.source, client_file, has_nav, choice.rejected)]
    toml.write_text("\n".join(config_style.align_lines(lines)) + "\n", encoding="utf-8", newline="\n")


def place_walk(folder: Path, path: Path | None) -> None:
    """walk.path có đúng khi nguồn là client; ngược lại xoá bản cũ."""
    target = folder / "walk.path"
    if path is None:
        target.unlink(missing_ok=True)
        return
    if not target.is_file() or target.read_bytes() != path.read_bytes():
        shutil.copyfile(path, target)


def client_files(client_scene: Path) -> dict[str, Path]:
    return {entry.name.lower(): entry for entry in client_scene.iterdir() if entry.name.lower().endswith(".path")}


def plan(
    server_root: Path, groups: list[scene_xref.Group], client: scene_xref.Client, client_scene: Path
) -> list[tuple[scene_xref.Group, Choice]]:
    """Nguồn lưới đi của từng cảnh có thư mục, theo thứ tự của `groups`; không ghi gì."""
    scenes = server_root / "scenes"
    files = client_files(client_scene)
    return [(group, choose(group, client, files, scenes)) for group in groups if group.has_dir]


def apply(server_root: Path, chosen: list[tuple[scene_xref.Group, Choice]]) -> None:
    """Ghi walk.path và khối `Nguồn lưới đi` của scene.toml theo kết quả của `plan`."""
    for group, choice in chosen:
        folder = server_root / "scenes" / group.scene_dir
        place_walk(folder, choice.path)
        rewrite_toml(folder / "scene.toml", choice, (folder / "walk.nav").is_file())


def report(chosen: list[tuple[scene_xref.Group, Choice]]) -> list[str]:
    """Số cảnh theo nguồn, rồi từng cảnh bị bỏ .path của client kèm lý do."""
    counts: dict[str, int] = {}
    for _, choice in chosen:
        counts[choice.source] = counts.get(choice.source, 0) + 1
    lines = [f"{key} {value}" for key, value in sorted(counts.items())]
    lines += [f"bỏ {group.scene_dir}: {choice.rejected}" for group, choice in chosen if choice.rejected]
    return lines


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    args = list(sys.argv[1:] if argv is None else argv)
    if "--help" in args or "-h" in args:
        print(HELP)
        return 0
    positional = [arg for arg in args if not arg.startswith("--")]
    if len(positional) != 3:
        print("scene_walk.py:1: cần ba tham số: gốc dev/server, gốc XJL7457, thư mục Scene của client")
        return 1
    server_root = Path(positional[0])
    groups, client = scene_xref.build(server_root, Path(positional[1]), Path(positional[2]))
    chosen = plan(server_root, groups, client, Path(positional[2]))
    if "--check" not in args:
        apply(server_root, chosen)
    for line in report(chosen):
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
