#!/usr/bin/env python3
"""Số vàng độc lập cho Test/Combat/combat_tests.cpp: chỉ số theo phái và cấp, xúc xắc, và kết quả một đòn.

Mọi số ở đây tính lại từ các bảng trong dev/server/tables và từ công thức của bản 2008 (Obj_Human_Attributes.cpp,
Combat_Core.cpp, Float2Int), không đọc đầu ra của mã C++. Bộ xúc xắc là bản Python của src/server/dice/dice.cpp
(splitmix64 gieo xoshiro256**). Test C++ ghim các số này; đổi bảng luật thì chạy lại để lấy số mới.

Cách dùng:
    python TOOLS/server/golden_combat.py stats <phái> <cấp>      chỉ số và điểm cộng của một người
    python TOOLS/server/golden_combat.py scan <số hạt> [thật]    kết quả một đòn theo từng hạt giống
    python TOOLS/server/golden_combat.py dice <hạt> [số lần]     chuỗi Rand100 của một hạt giống
"""

from __future__ import annotations

import dataclasses
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "dev" / "server" / "tables"
MASK = (1 << 64) - 1
TEMPLATE_OF = {10: 6, 11: 7, 12: 3, 13: 4, 14: 1, 15: 5}
SPLIT_GAMMA = 0x9E3779B97F4A7C15
SPLIT_A = 0xBF58476D1CE4E5B9
SPLIT_B = 0x94D049BB133111EB
PRIMARY = 5
BASE_COLUMNS = 42
FLUCTUATION_COLUMN = 36  # BaseInfo::kAttackFluctuation (dữ liệu hiện hành, mã 2008 đọc cột 33)
FREE_POINT_LEVEL = 60  # từ cấp này điểm mỗi cấp vào điểm tự do (Body::apply_growth)


def rotl(value: int, shift: int) -> int:
    """Xoay trái 64 bit."""
    return ((value << shift) | (value >> (64 - shift))) & MASK


class Dice:
    """src/server/dice/dice.cpp: splitmix64 gieo bốn từ cho xoshiro256**."""

    def __init__(self, seed: int) -> None:
        self.state = [0, 0, 0, 0]
        for i in range(4):
            seed = (seed + SPLIT_GAMMA) & MASK
            mixed = seed
            mixed = ((mixed ^ (mixed >> 30)) * SPLIT_A) & MASK
            mixed = ((mixed ^ (mixed >> 27)) * SPLIT_B) & MASK
            self.state[i] = mixed ^ (mixed >> 31)

    def next_u64(self) -> int:
        s = self.state
        result = (rotl((s[1] * 5) & MASK, 7) * 9) & MASK
        shifted = (s[1] << 17) & MASK
        s[2] ^= s[0]
        s[3] ^= s[1]
        s[1] ^= s[2]
        s[0] ^= s[3]
        s[2] ^= shifted
        s[3] = rotl(s[3], 45)
        return result

    def below(self, bound: int) -> int:
        """Đều trong [0, bound), loại mẫu thừa như bản C++."""
        if bound == 0:
            return 0
        reject_below = ((MASK + 1 - bound) % (MASK + 1)) % bound
        draw = self.next_u64()
        while draw < reject_below:
            draw = self.next_u64()
        return draw % bound


def float_to_int(numerator: int, denominator: int) -> int:
    """Float2Int(n / d), d > 0: từ 0,5 lên, số âm cắt về 0 (actor::round_ratio)."""
    if numerator < 0:
        return -((-numerator) // denominator)
    quotient, rest = divmod(numerator, denominator)
    return quotient + 1 if 2 * rest >= denominator else quotient


def truncate_div(numerator: int, denominator: int) -> int:
    """Chia nguyên cắt về 0 như C++."""
    quotient = abs(numerator) // abs(denominator)
    return quotient if (numerator < 0) == (denominator < 0) else -quotient


def read_rows(relative: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in (TABLES / relative).read_text(encoding="utf-8").splitlines():
        if line and not line.startswith("#"):
            rows.append(line.split("\t"))
    return rows


@dataclasses.dataclass(frozen=True)
class Stats:
    sect: int
    level: int
    points: tuple[int, ...]
    remain: int
    max_hp: int
    max_mp: int
    attack_phy: int
    attack_magic: int
    defence_phy: int
    defence_magic: int
    hit: int
    miss: int
    critical: int
    fluctuation: int


def derive(base: list[int], first: int, attribute: int, level: int) -> int:
    """BaseInfo: (hằng + hệ số thuộc tính * thuộc tính + hệ số cấp * cấp) / 100, làm tròn Float2Int, không âm."""
    return max(0, float_to_int(base[first] + attribute * base[first + 1] + level * base[first + 2], 100))


def accumulate_points(sect: int, level: int) -> tuple[tuple[int, ...], int]:
    """Điểm cấp một và điểm tự do cộng dồn từ hàng 0 tới hàng `level` của bảng điểm mỗi cấp."""
    template = TEMPLATE_OF.get(sect, sect)
    growth = [[int(x) for x in row[1:]] for row in read_rows("server/sect_attribute_growth.tsv")[1:]]
    points = [0] * PRIMARY
    remain = 0
    for row_level in range(level + 1):
        for k in range(PRIMARY):
            gained = growth[row_level][template * PRIMARY + k]
            if row_level < FREE_POINT_LEVEL:
                points[k] += gained
            else:
                remain += gained
    return tuple(points), remain


def human_stats(sect: int, level: int) -> Stats:
    """Chỉ số của người phái `sect` cấp `level` với điểm theo bảng, chưa trang bị, chưa buff."""
    table = read_rows("server/sect_base_values.tsv")[1:]
    base_rows = {int(r[0]): [int(x) for x in r[1:BASE_COLUMNS + 1]] for r in table}
    base = base_rows[TEMPLATE_OF.get(sect, sect)]
    points, remain = accumulate_points(sect, level)
    strength, spirit, constitution, intelligence, dexterity = points
    return Stats(
        sect, level, points, remain,
        derive(base, 0, constitution, level), derive(base, 6, intelligence, level),
        derive(base, 12, strength, level), derive(base, 15, spirit, level),
        derive(base, 18, constitution, level), derive(base, 21, intelligence, level),
        derive(base, 24, dexterity, level), derive(base, 27, dexterity, level), derive(base, 30, dexterity, level),
        base[FLUCTUATION_COLUMN])


def hit_rate(hit: int, miss: int) -> int:
    """Tỉ lệ trúng phần trăm (Combat_Core CalculateHitRate): điểm kẹp 1..1000."""
    hit_c = min(max(hit, 1), 1000)
    miss_c = min(max(miss, 1), 1000)
    return hit_c * 100 // (hit_c + miss_c)


def ratio_damage(attack: int, defence: int) -> int:
    """atk^2 / (atk + def) với atk, def tối thiểu 1."""
    a = max(attack, 1)
    d = max(defence, 1)
    return a * a // (a + d)


@dataclasses.dataclass(frozen=True)
class Strike:
    hit: bool
    critical: bool
    damage: int
    rolls: tuple[int, ...]


def channels(attacker: Stats, defender: Stats, additions: list[int]) -> list[int]:
    """Sát thương sáu kênh trước dao động; người chơi không có công hệ và không có kháng hệ nên bốn hệ là phần cộng."""
    phy = ratio_damage(attacker.attack_phy + additions[0], defender.defence_phy)
    magic = ratio_damage(attacker.attack_magic + additions[1], defender.defence_magic)
    return [phy, magic, *[max(0, extra) for extra in additions[2:6]]]


def strike(seed: int, attacker: Stats, defender: Stats, additions: list[int], fixed: int) -> Strike:
    """Một đòn tức thời của kỹ năng sát thương công thức, đối địch, trúng/né tính từ chỉ số.

    Thứ tự xúc xắc: trúng/né, rồi (nếu trúng) hội tâm, rồi dao động của hiệu ứng.
    """
    dice = Dice(seed)
    hit_roll = dice.below(100)
    if hit_roll >= min(max(hit_rate(attacker.hit, defender.miss), 0), 100):
        return Strike(False, False, 0, (hit_roll,))
    crit_roll = dice.below(100)
    critical = crit_roll < min(max(attacker.critical, 0), 100)
    swing_roll = dice.below(100)
    swing = float_to_int(2 * attacker.fluctuation * (50 - swing_roll), 100)
    parts = [v + truncate_div(v * swing, 100) for v in channels(attacker, defender, additions)]
    slots = [*parts, fixed]
    if critical:
        slots = [2 * v for v in slots]
    total = sum(slots)
    return Strike(True, critical, max(total, 1), (hit_roll, crit_roll, swing_roll))


def real_additions() -> list[int]:
    """Hiệu ứng 201 (伏虎拳) trong effects.tsv, đọc theo tên cột: sáu cộng thêm và sát thương thẳng."""
    rows = read_rows("server/effects.tsv")
    header, body = rows[0], rows[1:]
    first = header.index("parameter_value_1")
    row = next(r for r in body if r[0] == "201")
    values = [int(row[first + 3 * k]) for k in range(7)]
    return values


def print_stats(sect: int, level: int) -> None:
    s = human_stats(sect, level)
    print(s)


def print_scan(count: int, real: bool) -> None:
    attacker = human_stats(0 if real else 3, 60)
    defender = human_stats(3 if real else 0, 60)
    additions = real_additions()[:6] if real else [0] * 6
    fixed = real_additions()[6] if real else 0
    print(f"trúng {hit_rate(attacker.hit, defender.miss)}% hội tâm {attacker.critical}% "
          f"dao động {attacker.fluctuation}")
    for seed in range(1, count + 1):
        result = strike(seed, attacker, defender, additions, fixed)
        kind = "trượt" if not result.hit else ("hội tâm" if result.critical else "trúng")
        print(f"hạt {seed:3d}: {kind:8s} sát thương {result.damage:6d} xúc xắc {result.rolls}")


def main(argv: list[str]) -> int:
    if len(argv) >= 3 and argv[0] == "stats":
        print_stats(int(argv[1]), int(argv[2]))
        return 0
    if len(argv) >= 2 and argv[0] == "scan":
        print_scan(int(argv[1]), len(argv) > 2)
        return 0
    if len(argv) >= 2 and argv[0] == "dice":
        dice = Dice(int(argv[1]))
        print([dice.below(100) for _ in range(int(argv[2]) if len(argv) > 2 else 8)])
        return 0
    print(__doc__, file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
