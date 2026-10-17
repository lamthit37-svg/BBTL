# Sinh bảng nhìn của hiệu ứng, đạn và tốc độ mẫu cho client.
# Nguồn là bảng máy chủ đã xuất từ client 2026. Client không đọc dev/server lúc chạy.
# Chạy lại export_creatures.py sẽ làm mất cột move_speed cho tới khi chạy lại công cụ này.

from __future__ import annotations

import argparse
import sys
from pathlib import Path

IMPACT_OUT = (
    "id",
    "trigger_effect",
    "trigger_sound",
    "trigger_anchor",
    "continuous_effect",
    "continuous_sound",
    "continuous_anchor",
    "kept_after_death",
    "is_linear",
    "linear_anchor",
)
IMPACT_FROM = {
    "id": "id",
    "trigger_effect": "trigger_effect_id",
    "trigger_sound": "trigger_sound_id",
    "trigger_anchor": "trigger_effect_anchor",
    "continuous_effect": "continuous_effect_id",
    "continuous_sound": "continuous_sound_id",
    "continuous_anchor": "continuous_effect_anchor",
    "kept_after_death": "kept_after_death",
    "is_linear": "is_linear_effect",
    "linear_anchor": "linear_effect_anchor",
}
BULLET_OUT = (
    "id",
    "trajectory",
    "speed",
    "flight_effect",
    "flight_sound",
    "explosion_effect",
    "explosion_sound",
    "hit_anchor",
)
BULLET_FROM = {
    "id": "id",
    "trajectory": "trajectory_type",
    "speed": "speed_m_per_s",
    "flight_effect": "flight_effect_id",
    "flight_sound": "flight_sound_id",
    "explosion_effect": "explosion_effect_id",
    "explosion_sound": "explosion_sound_id",
    "hit_anchor": "hit_effect_anchor",
}


def read_tsv(path: Path) -> tuple[list[str], list[list[str]]]:
    header: list[str] = []
    rows: list[list[str]] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        cells = [cell.rstrip() for cell in raw.rstrip().split("\t")]
        if not header:
            header = cells
            continue
        if len(cells) < len(header):
            cells.extend([""] * (len(header) - len(cells)))
        rows.append(cells[: len(header)])
    if not header:
        raise SystemExit(f"{path}: không có dòng tên cột")
    return header, rows


def index_of(header: list[str], name: str, path: Path) -> int:
    if name not in header:
        raise SystemExit(f"{path}: thiếu cột {name}")
    return header.index(name)


def flag_cell(text: str) -> str:
    return "1" if text == "1" else "0"


def write_tsv(path: Path, comment: str, header: tuple[str, ...], rows: list[list[str]]) -> None:
    lines = [comment, "\t".join(header)]
    lines.extend("\t".join(row) for row in rows)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def take_columns(
    path: Path,
    wanted: tuple[str, ...],
    source: dict[str, str],
    key: str,
) -> tuple[list[list[str]], int]:
    header, rows = read_tsv(path)
    columns = {name: index_of(header, source[name], path) for name in wanted}
    key_at = columns[key]
    seen: set[str] = set()
    taken: list[list[str]] = []
    skipped = 0
    for row in rows:
        identity = row[key_at]
        if identity in seen:
            skipped += 1
            continue
        seen.add(identity)
        cells = []
        for name in wanted:
            cell = row[columns[name]]
            if name in {"kept_after_death", "is_linear"}:
                cell = flag_cell(cell)
            cells.append(cell)
        taken.append(cells)
    return taken, skipped


def skill_bullets(path: Path) -> tuple[list[list[str]], int]:
    header, rows = read_tsv(path)
    skill_at = index_of(header, "skill_id", path)
    bullet_at = index_of(header, "bullet_id", path)
    spawn_at = index_of(header, "bullet_spawn_point", path)
    seen: set[str] = set()
    taken: list[list[str]] = []
    skipped = 0
    for row in rows:
        skill = row[skill_at]
        bullet = row[bullet_at].strip()
        if not bullet or bullet == "-1" or bullet == "0":
            continue
        if not bullet.isdigit():
            skipped += 1
            continue
        if skill in seen:
            skipped += 1
            continue
        seen.add(skill)
        taken.append([skill, bullet, row[spawn_at]])
    return taken, skipped


def monster_speeds(path: Path) -> dict[str, str]:
    header, rows = read_tsv(path)
    id_at = index_of(header, "monster_id", path)
    speed_at = index_of(header, "move_speed", path)
    speeds: dict[str, str] = {}
    for row in rows:
        speed = row[speed_at].strip()
        if not speed.isdigit():
            speed = "0"
        speeds[row[id_at]] = speed
    return speeds


def join_speed(path: Path, speeds: dict[str, str]) -> tuple[int, int]:
    raw_lines = path.read_text(encoding="utf-8").splitlines()
    header_at = next(index for index, line in enumerate(raw_lines) if line.strip() and not line.startswith("#"))
    header = [cell.rstrip() for cell in raw_lines[header_at].rstrip().split("\t")]
    added = "move_speed" not in header
    if added:
        header.append("move_speed")
    speed_at = header.index("move_speed")
    id_at = header.index("template")
    matched = 0
    written: list[str] = []
    for index, raw in enumerate(raw_lines):
        if index == header_at:
            written.append("\t".join(header))
            continue
        if not raw.strip() or raw.startswith("#"):
            written.append(raw)
            continue
        cells = [cell.rstrip() for cell in raw.rstrip().split("\t")]
        while len(cells) <= speed_at:
            cells.append("")
        speed = speeds.get(cells[id_at], "0")
        if cells[id_at] in speeds:
            matched += 1
        cells[speed_at] = speed
        written.append("\t".join(cells))
    path.write_text("\n".join(written) + "\n", encoding="utf-8", newline="\n")
    data_rows = sum(1 for line in raw_lines[header_at + 1 :] if line.strip() and not line.startswith("#"))
    return matched, data_rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Xuất impacts, bullets, skill_bullets và move_speed")
    parser.add_argument("--server", type=Path, default=Path("dev/server/tables/shared"))
    parser.add_argument("--client", type=Path, default=Path("dev/client/assets"))
    args = parser.parse_args()
    table = args.client / "Table"
    table.mkdir(parents=True, exist_ok=True)
    impacts, impact_skips = take_columns(
        args.server / "effect_visuals.tsv", IMPACT_OUT, IMPACT_FROM, "id"
    )
    bullets, bullet_skips = take_columns(args.server / "bullets.tsv", BULLET_OUT, BULLET_FROM, "id")
    # 2008 chỉ có -1, 0, 1, 2. Quỹ đạo 3 có trên bảng 2026 nhưng chưa đọc mã máy, không bịa đường bay.
    known = {"-1", "0", "1", "2"}
    odd = [row for row in bullets if row[1] not in known]
    bullets = [row for row in bullets if row[1] in known]
    skills, skill_skips = skill_bullets(args.server / "skills.tsv")
    write_tsv(
        table / "impacts.tsv",
        "# Sinh từ effect_visuals.tsv. Ô rỗng là không có hạt hay tiếng.",
        IMPACT_OUT,
        impacts,
    )
    write_tsv(
        table / "bullets.tsv",
        "# Sinh từ bullets.tsv. trajectory -1 và 2 là nổ tại đích. Không có cột độ cao cung.",
        BULLET_OUT,
        bullets,
    )
    write_tsv(
        table / "skill_bullets.tsv",
        "# skill có bullet_id lớn hơn 0. 0 và -1 là không bắn.",
        ("skill", "bullet_id", "spawn_point"),
        skills,
    )
    matched, total = join_speed(table / "creature_templates.tsv", monster_speeds(args.server / "monsters.tsv"))
    print(f"impacts {len(impacts)} bỏ trùng {impact_skips}")
    print(f"bullets {len(bullets)} bỏ trùng {bullet_skips} bỏ quỹ đạo lạ {len(odd)}")
    print(f"skill_bullets {len(skills)} bỏ {skill_skips}")
    print(f"move_speed khớp {matched}/{total}")


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
