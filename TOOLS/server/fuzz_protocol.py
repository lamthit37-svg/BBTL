"""Fuzz tầng hai của protocol: dựng năm harness libFuzzer ở Test/fuzz/ bằng lệnh trần rồi chạy.

cách dùng: python -B TOOLS/server/fuzz_protocol.py --runs 1000000 --seed 20261008 [--only <đích>]
Đề bài P2 đợt 2, mục 3.8. Mỗi harness dựng vào build/p2-fuzz/<đích>/ bằng clang++ với
-fsanitize=fuzzer,address,undefined, kèm các tệp .cpp của protocol nó cần, không qua CMake. Corpus
mồi bằng byte mẫu của Test/Protocol/protocol_samples.hpp, xoá và mồi lại mỗi lượt cho tất định. Chạy lần
lượt từng đích với -max_len bằng trần thân của đích cộng 64. In một dòng mỗi đích. Log của từng đích
là so-do/fuzz-<đích>-<giờ>.log; chạy đủ năm đích thì ghi so-do/fuzz-<giờ>.tsv, <giờ> là lúc bắt đầu
lượt (YYYYmmdd-HHMMSS). Tệp đã có thì dừng, không ghi đè log của lượt trước (V3 của R; lượt 02:30 của
T11 mang tên cũ fuzz-<đích>.log và fuzz.tsv). Có đích thoát khác 0 thì thoát 1 và giữ crash-*.
Dựng hỏng thì thoát 2.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
BUILD = PROJECT / "build" / "p2-fuzz"
SO_DO = PROJECT / "docs" / "giao-viec" / "P2-DOT-2" / "so-do"
SAMPLES = PROJECT / "Test" / "Protocol" / "protocol_samples.hpp"
PROTOCOL = PROJECT / "SRC" / "protocol"
HARNESSES = PROJECT / "tests" / "fuzz"
MAX_BODY = 65536
CLIENT_BODY = 4096
SLACK = 64
TIMEOUT_SECONDS = 3600
FLAGS = (
    "-std=c++23",
    "-g",
    "-O1",
    "-fsanitize=fuzzer,address,undefined",
    "-fno-sanitize-recover=undefined",
)
# Thư viện libFuzzer dựng sẵn trên Windows tắt chú thích ASan của string và vector trong STL MSVC;
# mã của ta phải tắt theo, nếu không lld-link báo /failifmismatch 'annotate_string'.
WINDOWS_DEFINES = ("-D_DISABLE_STRING_ANNOTATION", "-D_DISABLE_VECTOR_ANNOTATION")
# Tệp .cpp của core mà protocol cần khi link: rỗng vì protocol chỉ dùng core/check.hpp, chỉ có header.
CORE_SOURCES: tuple[str, ...] = ()
COLUMNS = ("target", "runs", "seconds", "runs_per_s", "cov", "ft", "corpus_files", "exit_code")
# Mảng byte khung của mẫu: inline constexpr std::array<std::uint8_t, N> k<Tin><Loại>Frame{0x.., ...};
_LIST = re.compile(r"\bk\w+Frame\s*\{([^}]*)\}")
_HEX = re.compile(r"0x([0-9A-Fa-f]{2})")
_DONE = re.compile(r"^Done (\d+) runs in", re.MULTILINE)
_STAT = re.compile(r"cov: (\d+) ft: (\d+)")


@dataclass(frozen=True)
class Target:
    name: str
    max_body: int
    decoders: bool


@dataclass(frozen=True)
class Outcome:
    target: str
    runs: int
    seconds: float
    cov: int
    ft: int
    corpus_files: int
    exit_code: int

    def row(self) -> tuple[str, ...]:
        rate = self.runs / self.seconds if self.seconds > 0 else 0.0
        return (
            self.target,
            str(self.runs),
            f"{self.seconds:.2f}",
            f"{rate:.0f}",
            str(self.cov),
            str(self.ft),
            str(self.corpus_files),
            str(self.exit_code),
        )


TARGETS = (
    Target("frame", MAX_BODY, False),
    Target("game_client", CLIENT_BODY, True),
    Target("game_server", MAX_BODY, True),
    Target("auth_client", CLIENT_BODY, True),
    Target("auth_server", MAX_BODY, True),
)


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fuzz tầng hai của protocol bằng libFuzzer.")
    parser.add_argument("--runs", type=int, default=1_000_000, help="số vòng mỗi đích")
    parser.add_argument("--seed", type=int, default=20261008, help="hạt giống của libFuzzer")
    parser.add_argument("--only", choices=[target.name for target in TARGETS], help="chỉ một đích")
    parser.add_argument("--dry-run", action="store_true", help="in lệnh dựng, không dựng, không chạy")
    return parser.parse_args(argv)


def _compiler() -> str:
    found = os.environ.get("FUZZ_CXX") or shutil.which("clang++")
    if not found:
        raise SystemExit("không thấy clang++: đặt biến FUZZ_CXX hoặc thêm clang++ vào PATH")
    return found


def _sources(target: Target) -> list[Path]:
    sources = sorted(PROTOCOL.glob("*.cpp"))
    if not target.decoders:
        sources = [path for path in sources if path.name != "messages.cpp"]
    return [*sources, *(PROJECT / "SRC" / name for name in CORE_SOURCES)]


def _exe(target: Target) -> Path:
    suffix = ".exe" if os.name == "nt" else ""
    return BUILD / target.name / f"fuzz_{target.name}{suffix}"


def build_command(cxx: str, target: Target) -> list[str]:
    harness = HARNESSES / f"fuzz_{target.name}.cpp"
    includes = ["-I", str(PROJECT / "SRC"), "-I", str(PROJECT / "tests")]
    sources = [str(path) for path in (harness, *_sources(target))]
    defines = WINDOWS_DEFINES if os.name == "nt" else ()
    return [cxx, *FLAGS, *defines, *includes, *sources, "-o", str(_exe(target))]


def _runtime_env(cxx: str) -> dict[str, str]:
    env = dict(os.environ)
    if os.name != "nt":
        return env
    found = subprocess.run([cxx, "-print-resource-dir"], capture_output=True, text=True, check=False)
    runtime = Path(found.stdout.strip()) / "lib" / "windows"
    env["PATH"] = f"{runtime}{os.pathsep}{env.get('PATH', '')}"
    return env


def sample_frames(text: str) -> list[bytes]:
    """Byte khung của mọi mẫu trong Test/Protocol/protocol_samples.hpp, theo thứ tự khai."""
    frames = []
    for match in _LIST.finditer(text):
        frames.append(bytes(int(value, 16) for value in _HEX.findall(match.group(1))))
    return frames


def _seed_corpus(folder: Path) -> int:
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    frames = sample_frames(SAMPLES.read_text(encoding="utf-8"))
    if not frames:
        raise SystemExit(f"{SAMPLES.relative_to(PROJECT).as_posix()}: không thấy byte mẫu để mồi corpus")
    for index, frame in enumerate(frames):
        (folder / f"seed-{index:04d}").write_bytes(frame)
    return len(frames)


def _build(cxx: str, target: Target, env: dict[str, str]) -> bool:
    _exe(target).parent.mkdir(parents=True, exist_ok=True)
    done = subprocess.run(
        build_command(cxx, target), cwd=PROJECT, env=env, capture_output=True, text=True, check=False
    )
    if done.returncode != 0:
        print(f"{target.name}: dựng hỏng, mã {done.returncode}", file=sys.stderr)
        print(done.stdout + done.stderr, file=sys.stderr)
    return done.returncode == 0


def _execute(args: list[str], folder: Path, env: dict[str, str]) -> tuple[int, str]:
    try:
        done = subprocess.run(
            args,
            cwd=folder,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=TIMEOUT_SECONDS,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        output = exc.output if isinstance(exc.output, str) else ""
        return -1, output + f"\nquá {TIMEOUT_SECONDS} giây, đã dừng tiến trình\n"
    return done.returncode, done.stdout


def parse_outcome(name: str, log: str, seconds: float, code: int, corpus_files: int) -> Outcome:
    done = _DONE.findall(log)
    stats = _STAT.findall(log)
    cov, ft = (int(stats[-1][0]), int(stats[-1][1])) if stats else (0, 0)
    runs = int(done[-1]) if done else 0
    return Outcome(name, runs, seconds, cov, ft, corpus_files, code)


def write_new(path: Path, text: str) -> None:
    """Ghi một tệp mới; tệp đã có thì dừng, không ghi đè."""
    try:
        with path.open("x", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
    except FileExistsError:
        raise SystemExit(f"{path.name}: đã có, không ghi đè log của lượt trước") from None


def log_path(target: str, stamp: str) -> Path:
    """Log libFuzzer của một đích trong lượt bắt đầu lúc stamp."""
    return SO_DO / f"fuzz-{target}-{stamp}.log"


def tsv_path(stamp: str) -> Path:
    """Bảng năm đích của lượt bắt đầu lúc stamp."""
    return SO_DO / f"fuzz-{stamp}.tsv"


def _run(target: Target, runs: int, seed: int, env: dict[str, str], stamp: str) -> Outcome:
    folder = BUILD / target.name
    corpus = folder / "corpus"
    _seed_corpus(corpus)
    max_len = target.max_body + SLACK
    args = [str(_exe(target)), f"-runs={runs}", f"-seed={seed}", f"-max_len={max_len}", str(corpus)]
    start = time.perf_counter()
    code, log = _execute(args, folder, env)
    seconds = time.perf_counter() - start
    SO_DO.mkdir(parents=True, exist_ok=True)
    write_new(log_path(target.name, stamp), log)
    files = sum(1 for path in corpus.iterdir() if path.is_file())
    return parse_outcome(target.name, log, seconds, code, files)


def write_tsv(path: Path, outcomes: list[Outcome]) -> None:
    lines = ["\t".join(COLUMNS), *("\t".join(outcome.row()) for outcome in outcomes)]
    write_new(path, "\n".join(lines) + "\n")


def main(argv: list[str]) -> int:
    args = _parse_args(argv)
    targets = [target for target in TARGETS if args.only in (None, target.name)]
    cxx = _compiler()
    if args.dry_run:
        for target in targets:
            print(subprocess.list2cmdline(build_command(cxx, target)))
        return 0
    stamp = time.strftime("%Y%m%d-%H%M%S")
    taken = [path.name for path in (tsv_path(stamp), *(log_path(t.name, stamp) for t in targets)) if path.exists()]
    if taken:
        raise SystemExit(f"đã có {', '.join(taken)}, không ghi đè log của lượt trước")
    env = _runtime_env(cxx)
    if not all(_build(cxx, target, env) for target in targets):
        return 2
    print("\t".join(COLUMNS))
    outcomes = []
    for target in targets:
        outcome = _run(target, args.runs, args.seed, env, stamp)
        outcomes.append(outcome)
        print("\t".join(outcome.row()), flush=True)
    if len(outcomes) == len(TARGETS):
        write_tsv(tsv_path(stamp), outcomes)
    return 0 if all(outcome.exit_code == 0 for outcome in outcomes) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
