#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/server/e2e_g0.py
#  PHÂN HỆ   : Server / E2E
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Chạy sáu kịch bản của thienlong_bot (đôi, đứng xem, đi vòng, đi thẳng, nói
#    chuyện, đánh quái) trên cụm đang chạy ở 7100/7101, rồi đối chiếu dòng
#    `zone: kiểm` mới của cluster_err.txt với việc mỗi kịch bản phải để lại.
#  - Việc mà không kịch bản nào sinh ra (nhận, trả, nhặt...) in ở "chưa kiểm",
#    không tính là đạt.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""E2E G0-M: sáu kịch bản bot trên cụm thật, đối chiếu log kiểm của zone.

cách dùng: py -X utf8 TOOLS/server/e2e_g0.py [--tag 7] [--bot build/lane-server/thienlong_bot.exe]
Cụm phải đang chạy (local_cluster.py start) với play_trace = true. Tài khoản bot là
e2em<tag><kịch bản><số>: mỗi lượt chạy cần một --tag mới vì tài khoản đã có nhân vật thì giữ vị
trí cũ. Kết quả vào build/e2e/G0/m/ (build/e2e/G0/ là của client K): <kịch bản>-out.txt, <kịch bản>-err.txt, report.txt.
Mã thoát 0 khi mọi kịch bản đạt, 1 khi có kịch bản hỏng.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
KEY = PROJECT / "dev" / "server" / "data" / "gate" / "identity.key"
WALK = PROJECT / "dev" / "server" / "scenes" / "dali" / "walk.path"
ZONE_LOG = PROJECT / "dev" / "server" / "log" / "cluster_err.txt"
OUT = PROJECT / "build" / "e2e" / "G0" / "m"
BOT = PROJECT / "build" / "lane-server" / "thienlong_bot.exe"
# Mọi việc zone có thể ghi (zone/trace.cpp); việc nào không kịch bản nào sinh thì in ở "chưa kiểm".
ALL_ACTS = ("vào", "rời", "đi", "kéo", "nói", "chọn", "nhận", "trả", "bỏ", "chiêu", "đánh", "trúng",
            "hạ", "chết", "hồi", "nhặt")
PEERS_HEAD_START = 4.0
PATIENCE_SECONDS = 300.0
KIEM = re.compile(r'zone: kiểm .*việc=(\S+) .*ten="([^"]*)"')


@dataclass
class Scenario:
    name: str
    digit: int
    args: list[str]
    acts: tuple[str, ...]
    # Mã thoát chấp nhận được: talk thoát 1 khi chưa nhận được nhiệm vụ nào (chưa có NPC giao việc).
    exits: tuple[int, ...] = (0,)
    note: str = ""
    code: int | None = None
    seen: set[str] = field(default_factory=set)


def scenarios() -> list[Scenario]:
    walk = ["--walk", str(WALK)]
    return [
        Scenario("pair", 1, ["--count", "2", "--seconds", "8"], ("vào", "đi", "rời")),
        Scenario("peers", 2, ["--count", "1", "--seconds", "25", "--peers", "1"], ("vào",)),
        Scenario("walker", 3, ["--count", "1", "--seconds", "8"], ("vào", "rời")),
        Scenario("straight", 4, ["--count", "1", "--seconds", "10", "--straight", "1"], ("kéo",)),
        Scenario("talk", 5, ["--count", "1", "--seconds", "15", "--talk", "163,171", *walk],
                 ("nói", "chọn"), exits=(0, 1), note="mã 1 là chưa nhận được nhiệm vụ nào"),
        Scenario("fight", 6, ["--count", "1", "--seconds", "120", "--fight", "258,124", *walk],
                 ("chiêu", "đánh", "hạ")),
    ]


def start(bot: Path, tag: str, one: Scenario) -> subprocess.Popen:
    prefix = f"e2em{tag}{one.digit}"
    command = [str(bot), "--identity", str(KEY), *one.args, "--prefix", prefix]
    out = open(OUT / f"{one.name}-out.txt", "wb")
    err = open(OUT / f"{one.name}-err.txt", "wb")
    return subprocess.Popen(command, cwd=PROJECT, stdout=out, stderr=err)


def finish(one: Scenario, process: subprocess.Popen) -> None:
    try:
        one.code = process.wait(timeout=PATIENCE_SECONDS)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        one.code = None


def run_all(bot: Path, tag: str, plan: list[Scenario]) -> None:
    by_name = {one.name: one for one in plan}
    peers = start(bot, tag, by_name["peers"])
    time.sleep(PEERS_HEAD_START)
    finish(by_name["walker"], start(bot, tag, by_name["walker"]))
    finish(by_name["peers"], peers)
    for name in ("pair", "straight", "talk", "fight"):
        finish(by_name[name], start(bot, tag, by_name[name]))


def acts_by_account(since: int) -> dict[str, set[str]]:
    """Việc đã ghi cho từng tên nhân vật, từ dòng mới của log zone (sau byte `since`)."""
    with open(ZONE_LOG, "rb") as source:
        source.seek(since)
        text = source.read().decode("utf-8", errors="replace")
    found: dict[str, set[str]] = {}
    for line in text.splitlines():
        match = KIEM.search(line)
        if match:
            found.setdefault(match.group(2), set()).add(match.group(1))
    return found


def attach_acts(plan: list[Scenario], tag: str, found: dict[str, set[str]]) -> None:
    for one in plan:
        prefix = f"e2em{tag}{one.digit}"
        for name, acts in found.items():
            if name.startswith(prefix):
                one.seen |= acts


def verdict(one: Scenario) -> tuple[bool, str]:
    missing = [act for act in one.acts if act not in one.seen]
    exit_ok = one.code in one.exits
    text = f"thoát {one.code}" + (f" ({one.note})" if one.note and one.code != 0 else "")
    text += f"; việc có {','.join(sorted(one.seen)) or '-'}"
    if missing:
        text += f"; THIẾU {','.join(missing)}"
    return exit_ok and not missing, text


def report(plan: list[Scenario], tag: str) -> tuple[str, bool]:
    lines = [f"E2E G0-M, tag {tag}, bot {BOT.name}", ""]
    every_ok = True
    for one in plan:
        ok, text = verdict(one)
        every_ok = every_ok and ok
        lines.append(f"{'ĐẠT' if ok else 'HỎNG'}\t{one.name}\t{text}")
    seen_all = set().union(*(one.seen for one in plan))
    untested = [act for act in ALL_ACTS if act not in seen_all]
    lines += ["", f"chưa kiểm (không kịch bản nào sinh ra): {', '.join(untested) or 'không có'}"]
    lines += ["", f"KẾT LUẬN: {'ĐẠT' if every_ok else 'HỎNG'}"]
    return "\n".join(lines) + "\n", every_ok


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="E2E G0-M: sáu kịch bản bot trên cụm thật.")
    parser.add_argument("--tag", default="7", help="chuỗi chen vào tên tài khoản; mỗi lượt một giá trị mới")
    parser.add_argument("--bot", default=str(BOT), help="đường dẫn thienlong_bot.exe")
    args = parser.parse_args()
    if not ZONE_LOG.is_file():
        print(f"không thấy {ZONE_LOG}: cụm chưa chạy (local_cluster.py start)", file=sys.stderr)
        return 2
    OUT.mkdir(parents=True, exist_ok=True)
    since = ZONE_LOG.stat().st_size
    plan = scenarios()
    run_all(Path(args.bot), args.tag, plan)
    time.sleep(2.0)
    attach_acts(plan, args.tag, acts_by_account(since))
    text, ok = report(plan, args.tag)
    (OUT / "report.txt").write_text(text, encoding="utf-8")
    sys.stdout.write(text)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
