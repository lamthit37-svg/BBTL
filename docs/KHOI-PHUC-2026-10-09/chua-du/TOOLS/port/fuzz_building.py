"""Fuzz bộ đọc .WCollision (DH đợt 1): dựng harness libFuzzer tests/fuzz/fuzz_building.cpp bằng lệnh trần rồi chạy.

cách dùng (ở gốc dự án):
  python -B TOOLS/port/fuzz_building.py --runs 1000000 --seed 20261008 [--max-len 4096]
      [--scene <_raw>/Scene] [--max-total-time 300] [--hostile-call EXPR] [--no-hostile-hpp]
      [--only-hostile] [--keep-corpus] [--dry-run]
Harness dựng vào build/dh-fuzz/ bằng clang++ -fsanitize=fuzzer,address,undefined -fno-sanitize-recover=all, kèm
SRC/collision/building_file.cpp (core chỉ dùng header), không qua CMake. Corpus mồi xoá và dựng lại mỗi lượt cho
tất định, từ ba nguồn:
- make_building_file.py (cùng thư mục): tệp tự vẽ mã 1 và mã 2 với bốn hạt giống, hai dạng rỗng, và mọi tệp hỏng
  của corruptions() trên từng tệp đó;
- byte của game::collision::test::hostile_cases() trong tests/collision_hostile.hpp (69 ca HostileCase, trường
  bytes là std::span<const std::byte>): dịch build/dh-fuzz/dump_hostile.exe (không sanitizer) gọi biểu thức
  --hostile-call rồi ghi từng ca ra corpus thành hostile_hpp_<số>_<name>.WCollision, kể cả ca rỗng (g3-01; libFuzzer
  bỏ qua tệp rỗng khi nạp corpus nhưng luôn tự chạy đầu vào rỗng); --no-hostile-hpp bỏ nguồn này (chỉ cho lượt thử);
- --scene: mọi .WCollision thật dưới thư mục đó, chép vào corpus (thư mục gốc chỉ đọc).
--only-hostile: corpus mồi CHỈ là byte của hostile_cases() (bỏ tệp tự vẽ, không nhận --scene); mặc định giữ cả ba
nguồn như cũ. --keep-corpus: không xoá, không mồi lại; chạy tiếp trên build/dh-fuzz/corpus của lượt trước (đoạn nối
của một lượt bị ngắt), số mồi trong log/tsv là 0 và cột seed_corpus_files là số tệp có sẵn.
UBSan dừng ngay ở lỗi đầu: cờ dựng -fno-sanitize-recover=all, môi trường chạy UBSAN_OPTIONS=halt_on_error=1:
print_stacktrace=1, và -error_exitcode=77 cho libFuzzer; crash-*/leak-*/timeout-* ghi vào build/dh-fuzz/.
libFuzzer cắt mọi đầu vào về --max-len; muốn chạy trọn tệp thật thì đặt bằng cỡ tệp lớn nhất (9523328) và giới
hạn bằng --max-total-time. Log libFuzzer là docs/giao-viec/DH-DOT-1/so-do/fuzz-building-<giờ>.log, bảng một dòng
là fuzz-building-<giờ>.tsv, <giờ> là lúc bắt đầu lượt (YYYYmmdd-HHMMSS); tệp đã có thì dừng, không ghi đè. Đích
thoát khác 0 thì thoát 1 và giữ crash-* trong build/dh-fuzz/. Dựng hỏng thì thoát 2, thiếu nguồn mồi thì thoát 3.
Lệnh nặng: giữ build/NANG.lock khi chạy.
"""
from __future__ import annotations

import argparse
import dataclasses
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_building_file  # noqa: E402

PROJECT = Path(__file__).resolve().parents[2]
BUILD = PROJECT / "build" / "dh-fuzz"
SO_DO = PROJECT / "docs" / "giao-viec" / "DH-DOT-1" / "so-do"
HARNESS = PROJECT / "tests" / "fuzz" / "fuzz_building.cpp"
SOURCES = (PROJECT / "SRC" / "collision" / "building_file.cpp",)
HOSTILE_HPP = PROJECT / "tests" / "collision_hostile.hpp"
HOSTILE_CALL = "game::collision::test::hostile_cases()"
HOSTILE_EXPECTED = 69
DRAWN_SEEDS = (20261008, 1, 2, 3)
TIMEOUT_SECONDS = 3600
ERROR_EXITCODE = 77
FLAGS = ("-std=c++23", "-g", "-O1", "-fsanitize=fuzzer,address,undefined", "-fno-sanitize-recover=all")
UBSAN_OPTIONS = "halt_on_error=1:print_stacktrace=1"
# Như TOOLS/server/fuzz_protocol.py: libFuzzer dựng sẵn trên Windows tắt chú thích ASan của STL MSVC.
WINDOWS_DEFINES = ("-D_DISABLE_STRING_ANNOTATION", "-D_DISABLE_VECTOR_ANNOTATION")
COLUMNS = ("target", "runs", "seconds", "runs_per_s", "cov", "ft", "drawn_files", "hostile_hpp_files",
           "scene_files", "max_len", "corpus_files", "exit_code", "hostile_empty_files", "seed_corpus_files",
           "only_hostile", "keep_corpus", "seed")
_DONE = re.compile(r"^Done (\d+) runs in", re.MULTILINE)
_STAT = re.compile(r"cov: (\d+) ft: (\d+)")
# Exe nhỏ ghi từng ca của hostile_cases() thành một tệp (giao diện L chốt 14:52: span<const HostileCase>, mỗi ca có
# name là string_view và bytes là span<const std::byte>). In số ca đã ghi.
DUMPER = """// Sinh bởi TOOLS/port/fuzz_building.py, chỉ để mồi corpus; không thuộc mã dự án.
#include "collision_hostile.hpp"

#include <cstddef>
#include <cstdio>
#include <fstream>
#include <string>

int main(int argc, char** argv) {{
    if (argc != 2) {{
        return 2;
    }}
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
    files: dict[str, bytes] = {}
    for version in (1, 2):
        files[f"drawn_v{version}_rong"] = make_building_file.build_file(version, 0, True)
        for seed in DRAWN_SEEDS:
            files[f"drawn_v{version}_s{seed}"] = make_building_file.build_file(version, seed, False)
    for name, data in list(files.items()):
        for index, broken in enumerate(make_building_file.corruptions(data).values()):
            files[f"{name}_hong{index}"] = broken
    for name, data in files.items():
        (folder / f"{name}.WCollision").write_bytes(data)
    return len(files)


def hostile_hpp_seeds(folder: Path, cxx: str, call: str, env: dict[str, str]) -> tuple[int, list[str]]:
    """Trả số ca dump_hostile báo và tên các tệp rỗng trong số đó."""
    if not HOSTILE_HPP.is_file():
        print(f"{HOSTILE_HPP.relative_to(PROJECT).as_posix()}: chưa có; dùng --no-hostile-hpp cho lượt thử",
              file=sys.stderr)
        raise SystemExit(3)
    source = BUILD / "dump_hostile.cpp"
    source.write_text(DUMPER.format(call=call), encoding="utf-8", newline="\n")
    command = [cxx, "-std=c++23", "-O1", *(WINDOWS_DEFINES if os.name == "nt" else ()), "-I", str(PROJECT / "SRC"),
               "-I", str(PROJECT / "tests"), str(source), "-o", str(exe("dump_hostile"))]
    built = subprocess.run(command, cwd=PROJECT, env=env, capture_output=True, text=True, check=False)
    if built.returncode != 0:
        print(f"dựng dump_hostile hỏng, mã {built.returncode}\n{built.stdout}{built.stderr}", file=sys.stderr)
        raise SystemExit(2)
    done = subprocess.run([str(exe("dump_hostile")), str(folder)], capture_output=True, text=True, check=False)
    if done.returncode != 0 or not done.stdout.strip().isdigit():
        print(f"dump_hostile thoát {done.returncode}\n{done.stdout}{done.stderr}", file=sys.stderr)
        raise SystemExit(3)
    count = int(done.stdout.strip())
    written = sorted(folder.glob("hostile_hpp_*.WCollision"))
    if len(written) != count:
        print(f"dump_hostile báo {count} ca nhưng có {len(written)} tệp hostile_hpp_*", file=sys.stderr)
        raise SystemExit(3)
    return count, [path.name for path in written if path.stat().st_size == 0]


def scene_seeds(folder: Path, scene: Path) -> int:
    real = sorted(path for path in scene.rglob("*") if path.is_file() and path.suffix.lower() == ".wcollision")
    if not real:
        print(f"{scene}: không có tệp .WCollision", file=sys.stderr)
        raise SystemExit(3)
    for path in real:
        shutil.copyfile(path, folder / ("scene__" + path.relative_to(scene).as_posix().replace("/", "__")))
    return len(real)


def write_new(path: Path, text: str) -> None:
    try:
        with path.open("x", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
    except FileExistsError:
        raise SystemExit(f"{path.name}: đã có, không ghi đè log của lượt trước") from None


def count_files(folder: Path) -> int:
    return sum(1 for path in folder.iterdir() if path.is_file())


@dataclasses.dataclass
class Seeds:
    """Số tệp mồi theo từng nguồn, tên các ca rỗng, và số tệp trong corpus trước khi chạy."""
    drawn: int = 0
    hostile: int = 0
    scene: int = 0
    empty: list[str] = dataclasses.field(default_factory=list)
    files: int = 0


@dataclasses.dataclass
class Outcome:
    """Một lượt chạy đích fuzz: mã thoát (-1 khi quá giờ), output và số giây."""
    code: int
    output: str
    seconds: float


def seed_corpus(args: argparse.Namespace, corpus: Path, cxx: str, env: dict[str, str]) -> Seeds | None:
    """Mồi lại corpus, hay giữ corpus của lượt trước (--keep-corpus); None khi phải giữ mà không có gì."""
    seeds = Seeds()
    if args.keep_corpus:
        if not corpus.is_dir() or count_files(corpus) == 0:
            print(f"{corpus}: không có corpus để chạy tiếp", file=sys.stderr)
            return None
        seeds.files = count_files(corpus)
        return seeds
    if corpus.exists():
        shutil.rmtree(corpus)
    corpus.mkdir(parents=True)
    seeds.drawn = 0 if args.only_hostile else drawn_seeds(corpus)
    if not args.no_hostile_hpp:
        seeds.hostile, seeds.empty = hostile_hpp_seeds(corpus, cxx, args.hostile_call, env)
    seeds.scene = scene_seeds(corpus, args.scene) if args.scene else 0
    seeds.files = count_files(corpus)
    return seeds


def run_command(args: argparse.Namespace, corpus: Path) -> list[str]:
    run = [str(exe("fuzz_building")), f"-runs={args.runs}", f"-seed={args.seed}", f"-max_len={args.max_len}",
           f"-error_exitcode={ERROR_EXITCODE}", f"-artifact_prefix={BUILD}{os.sep}", "-print_final_stats=1"]
    if args.max_total_time > 0:
        run.append(f"-max_total_time={args.max_total_time}")
    run.append(str(corpus))
    return run


def run_target(run: list[str], env: dict[str, str]) -> Outcome:
    start = time.perf_counter()
    try:
        done = subprocess.run(run, cwd=BUILD, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                              encoding="utf-8", errors="replace", timeout=TIMEOUT_SECONDS, check=False)
        code, output = done.returncode, done.stdout
    except subprocess.TimeoutExpired as exc:
        code, output = -1, (exc.output if isinstance(exc.output, str) else "") + f"\nquá {TIMEOUT_SECONDS} giây\n"
    return Outcome(code, output, time.perf_counter() - start)


def seed_note(args: argparse.Namespace, seeds: Seeds) -> str:
    """Dòng "# mồi ..." của log: chế độ mồi và số tệp của từng nguồn."""
    mode = ("chạy tiếp corpus có sẵn (--keep-corpus)" if args.keep_corpus
            else "chỉ hostile_cases() (--only-hostile)" if args.only_hostile else "ba nguồn (mặc định)")
    hostile_note = f"hostile_cases {seeds.hostile}"
    if not args.keep_corpus and not args.no_hostile_hpp:
        gap = seeds.hostile - HOSTILE_EXPECTED
        empty = seeds.empty
        hostile_note += (f" (mong {HOSTILE_EXPECTED}" + (", ĐỦ" if gap == 0 else f", LỆCH {gap:+d}")
                         + f"; tệp rỗng {len(empty)}" + (": " + ", ".join(empty) if empty else "") + ")")
    return (f"# mồi ({mode}): tự vẽ {seeds.drawn}, {hostile_note}, tệp thật {seeds.scene}; "
            f"tệp trong corpus trước khi chạy {seeds.files}")


def tsv_row(args: argparse.Namespace, seeds: Seeds, outcome: Outcome, files: int) -> tuple[str, ...]:
    """Dòng số liệu của lượt, cùng thứ tự với COLUMNS; files là số tệp trong corpus sau khi chạy."""
    runs = int(_DONE.findall(outcome.output)[-1]) if _DONE.findall(outcome.output) else 0
    stats = _STAT.findall(outcome.output)
    cov, ft = (stats[-1][0], stats[-1][1]) if stats else ("0", "0")
    rate = runs / outcome.seconds if outcome.seconds > 0 else 0.0
    return ("building", str(runs), f"{outcome.seconds:.2f}", f"{rate:.0f}", cov, ft, str(seeds.drawn),
            str(seeds.hostile), str(seeds.scene), str(args.max_len), str(files), str(outcome.code),
            str(len(seeds.empty)), str(seeds.files), str(int(args.only_hostile)), str(int(args.keep_corpus)),
            str(args.seed))


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    cxx = compiler()
    command = build_command(cxx)
    if args.dry_run:
        print(subprocess.list2cmdline(command))
        return 0
    stamp = time.strftime("%Y%m%d-%H%M%S")
    log, tsv = SO_DO / f"fuzz-building-{stamp}.log", SO_DO / f"fuzz-building-{stamp}.tsv"
    if log.exists() or tsv.exists():
        raise SystemExit(f"đã có {log.name} hay {tsv.name}, không ghi đè")
    env = runtime_env(cxx)
    BUILD.mkdir(parents=True, exist_ok=True)
    built = subprocess.run(command, cwd=PROJECT, env=env, capture_output=True, text=True, check=False)
    if built.returncode != 0:
        print(f"dựng hỏng, mã {built.returncode}\n{built.stdout}{built.stderr}", file=sys.stderr)
        return 2
    corpus = BUILD / "corpus"
    seeds = seed_corpus(args, corpus, cxx, env)
    if seeds is None:
        return 3
    run = run_command(args, corpus)
    outcome = run_target(run, env)
    SO_DO.mkdir(parents=True, exist_ok=True)
    head = (f"> {subprocess.list2cmdline(run)}\n# môi trường: UBSAN_OPTIONS={env['UBSAN_OPTIONS']}; dựng: "
            f"{subprocess.list2cmdline(command)}\n")
    write_new(log, head + seed_note(args, seeds) + "\n\n" + outcome.output)
    row = tsv_row(args, seeds, outcome, count_files(corpus))
    write_new(tsv, "\t".join(COLUMNS) + "\n" + "\t".join(row) + "\n")
    print(f"log: {log.relative_to(PROJECT).as_posix()}")
    print(f"tsv: {tsv.relative_to(PROJECT).as_posix()}")
    print("\t".join(COLUMNS))
    print("\t".join(row))
    return 0 if outcome.code == 0 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
⟪thiếu dòng này⟫
