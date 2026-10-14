"""Sinh các bảng luật chiến đấu mà bản 2008 hoặc client 2026 không có sẵn.

  python TOOLS/server/import_combat.py <thư mục bảng>
  python TOOLS/server/import_combat.py <thư mục bảng> --check

Bốn bảng ghi vào <thư mục bảng>/server:
  sect_templates.tsv  — môn phái mới (10..15, chỉ có ở client 2026) mượn hệ số và điểm mỗi cấp của
                        phái nào trong 10 phái gốc. Số tự đặt (basis=made_up), chờ chủ dự án duyệt.
  sect_rage_rules.tsv — nộ khí tăng khi nào và bao nhiêu theo từng phái (MenPai/*.cpp của 2008).
                        Phái mới mượn luật của phái mẫu, cũng tự đặt.
  skill_logics.tsv    — logic kỹ năng (cột logic của skill_levels.tsv) -> mã xử lý, vai của từng ô tham số,
                        độ trung thực. Nội dung ở combat_logics.py.
  effect_logics.tsv   — logic hiệu ứng (cột logic của effects.tsv) -> mã xử lý, như trên.

--check so nội dung sẽ ghi với tệp đang có, không ghi gì. Thoát 0 khi khớp, 1 khi lệch hay có lỗi.
"""
from __future__ import annotations

import sys
from pathlib import Path

import combat_logics
import tsv_file

TOOL = "import_combat.py"
SOURCE_2008 = "source_2008"
MADE_UP = "made_up"
SOURCE_REF = "GameServer 2008 {name}.cpp"

# Phái mới -> phái mẫu. Chọn theo lối đánh gần nhất với tên và kỹ năng của phái (kiểm bằng
# docs/SERVER-COMBAT.md mục "Số tự đặt"): Mộ Dung đánh nội/đối kháng như Đại Lý, Đường Môn ám khí
# như Thiên Sơn, Quỷ Cốc mưu kế như Võ Đang, Đào Hoa Đảo như Nga Mi, Thông Nhân Tông diệt như
# Minh Giáo, Nga Nhân Cốc độc như Tinh Túc.
TEMPLATES = (
    (10, 6, "Mộ Dung mượn Đại Lý"),
    (11, 7, "Đường Môn mượn Thiên Sơn"),
    (12, 3, "Quỷ Cốc mượn Võ Đang"),
    (13, 4, "Đào Hoa Đảo mượn Nga Mi"),
    (14, 1, "Thông Nhân Tông mượn Minh Giáo"),
    (15, 5, "Nga Nhân Cốc mượn Tinh Túc"),
)

# Luật nộ khí theo sự kiện đặc thù của phái (mã 2008, MenPai/*.cpp): nộ khí cộng = giá trị * nhân / chia.
# Nộ khí khi nhận và khi gây sát thương KHÔNG nằm ở đây: dữ liệu hiện hành (BaseValueTable.ini cột 37, 38)
# cho tỉ lệ từng phái, còn mã 2008 chia cứng 20 hoặc 40; dữ liệu thắng mã (docs/SERVER-COMBAT.md).
# Cái Bang: tiêu điểm liên kích nhân 10. Nga Mi: hồi máu cho người chia 20. Tiêu Dao: bẫy phát nổ nhân 10.
SECT_FILES = {2: "GaiBang", 4: "EMei", 8: "XiaoYao"}
SECT_RULES = {
    2: {"strike_spent": (10, 1)},
    4: {"heal_done": (1, 20)},
    8: {"trap_triggered": (10, 1)},
}

TEMPLATE_HEADER = ("sect_id", "template_sect", "basis", "note")
TEMPLATE_TYPES = ("int", "int", "text", "text")
RAGE_HEADER = ("sect_id", "trigger", "multiplier", "divisor", "basis", "note")
RAGE_TYPES = ("int", "text", "int", "int", "text", "text")
LOGIC_HEADER = ("logic_id", "handler", "roles", "fidelity", "note")
LOGIC_TYPES = ("int", "text", "text", "text", "text")


def template_rows() -> list[tuple[str, ...]]:
    """Một dòng mỗi phái mới."""
    return [(str(sect), str(source), MADE_UP, note) for sect, source, note in TEMPLATES]


def rage_rows() -> list[tuple[str, ...]]:
    """Luật nộ khí đặc thù của các phái gốc, rồi của phái mới theo phái mẫu."""
    rows = []
    for sect, rules in SECT_RULES.items():
        note = SOURCE_REF.format(name=SECT_FILES[sect])
        for event, (mult, div) in rules.items():
            rows.append((str(sect), event, str(mult), str(div), SOURCE_2008, note))
    for sect, source, _ in TEMPLATES:
        for event, (mult, div) in SECT_RULES.get(source, {}).items():
            rows.append((str(sect), event, str(mult), str(div), MADE_UP, f"mượn luật của phái {source}"))
    return rows


def logic_rows(logics: dict[int, combat_logics.Logic]) -> list[tuple[str, ...]]:
    """Một dòng mỗi logic, sắp theo số logic."""
    return [(str(logic), item.handler, item.roles, item.fidelity, item.note) for logic, item in sorted(logics.items())]


def outputs(folder: Path) -> list[tuple[Path, str, tuple[str, ...], tuple[str, ...], list[tuple[str, ...]]]]:
    """(đường dẫn, nguồn, kiểu, tên cột, bản ghi) của từng bảng."""
    server = folder / "server"
    return [
        (server / "sect_templates.tsv", "tự soạn: phái mới mượn phái mẫu", TEMPLATE_TYPES, TEMPLATE_HEADER,
         template_rows()),
        (server / "sect_rage_rules.tsv", "GameServer 2008 MenPai/*.cpp", RAGE_TYPES, RAGE_HEADER, rage_rows()),
        (server / "skill_logics.tsv", "GameServer 2008 Skills/*.cpp, tham số theo skill_levels.tsv", LOGIC_TYPES,
         LOGIC_HEADER, logic_rows(combat_logics.SKILL_LOGICS)),
        (server / "effect_logics.tsv", "GameServer 2008 Impacts/*.cpp, tham số theo effects.tsv", LOGIC_TYPES,
         LOGIC_HEADER, logic_rows(combat_logics.EFFECT_LOGICS)),
    ]


def run(folder: Path, check: bool) -> int:
    """Ghi hoặc kiểm các bảng. Trả mã thoát."""
    status = 0
    for path, source, types, header, rows in outputs(folder):
        text = tsv_file.render_table(source, TOOL, types, header, rows)
        if check:
            same = path.is_file() and path.read_bytes().decode("utf-8") == text
            if not same:
                print(f"{path}:1: bảng lệch hoặc thiếu so với import_combat.py", file=sys.stderr)
                status = 1
            continue
        tsv_file.write_table(path, source, TOOL, types, header, rows)
        print(f"đã ghi {path} ({len(rows)} dòng)")
    return status


def main(argv: list[str]) -> int:
    """Điểm vào dòng lệnh."""
    args = [item for item in argv if item != "--check"]
    if len(args) != 1:
        print(__doc__, file=sys.stderr)
        return 1
    return run(Path(args[0]), "--check" in argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
