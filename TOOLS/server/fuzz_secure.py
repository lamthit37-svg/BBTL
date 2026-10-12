"""Fuzz bắt tay và bộ mở bản ghi đã mã hoá bằng libFuzzer, ASan và UBSan.

cách dùng:
    python -B TOOLS/server/fuzz_secure.py --runs 1000000
    python -B TOOLS/server/fuzz_secure.py --teeth

Mỗi đích in một dòng. --teeth dựng lại đích record với SECURE_DROP_LENGTH_CHECK rồi
đưa đúng đầu vào vượt biên: bản thường phải sống, bản bỏ kiểm phải chết dưới ASan.
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
BUILD = PROJECT / "build" / "fuzz-secure"
SODIUM_LIB = PROJECT / "build" / "clang-asan" / "third_party" / "libsodium" / "game_sodium.lib"
SODIUM_INCLUDE = PROJECT / "build" / "clang-asan" / "third_party" / "libsodium" / "include"
SECURE = PROJECT / "SRC" / "secure"
HARNESSES = PROJECT / "tests" / "fuzz"
FLAGS = (
    "-std=c++23",
    "-g",
    "-O1",
    "-fsanitize=fuzzer,address,undefined",
    "-fno-sanitize-recover=undefined",
    "-fuse-ld=lld",
    "-DSODIUM_STATIC",
)
C_FLAGS = (
    "-std=c11",
    "-g",
    "-O1",
    "-w",
    "-fsanitize=address,undefined",
    "-fno-sanitize-recover=undefined",
    "-DSODIUM_STATIC",
    "-DCONFIGURED=1",
    "-DNATIVE_LITTLE_ENDIAN=1",
    "-DHAVE_ATOMIC_OPS=1",
    "-DHAVE_C11_MEMORY_FENCES=1",
    "-DHAVE_GCC_MEMORY_FENCES=1",
    "-DHAVE_INLINE_ASM=1",
    "-DHAVE_INTTYPES_H=1",
    "-DHAVE_STDINT_H=1",
    "-DHAVE_TI_MODE=1",
    "-DHAVE_CPUID=1",
    "-DHAVE_MMINTRIN_H=1",
    "-DHAVE_EMMINTRIN_H=1",
    "-DHAVE_PMMINTRIN_H=1",
    "-DHAVE_TMMINTRIN_H=1",
    "-DHAVE_SMMINTRIN_H=1",
    "-DHAVE_AVXINTRIN_H=1",
    "-DHAVE_AVX2INTRIN_H=1",
    "-DHAVE_AVX512FINTRIN_H=1",
    "-DHAVE_WMMINTRIN_H=1",
    "-DHAVE_RDRAND=1",
)
WINDOWS_DEFINES = ("-D_DISABLE_STRING_ANNOTATION", "-D_DISABLE_VECTOR_ANNOTATION")
SOURCES = (
    SECURE / "identity.cpp",
    SECURE / "handshake.cpp",
    SECURE / "record.cpp",
    SECURE / "detail" / "sodium.cpp",
)
SODIUM_SRC = PROJECT / "third_party" / "libsodium" / "upstream" / "src" / "libsodium"
# u16 LE = 20000 rồi 20000 byte thân: vượt mảng bản ghi khi bỏ kiểm độ dài.
PROOF = bytes((0x20, 0x4E)) + bytes(20_000)


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fuzz bắt tay và bản ghi mã hoá.")
    parser.add_argument("--runs", type=int, default=1_000_000)
    parser.add_argument("--seed", type=int, default=20261008)
    parser.add_argument("--only", choices=("handshake", "record"))
    parser.add_argument("--teeth", action="store_true", help="chứng minh ASan bắt được bản bỏ kiểm biên")
    return parser.parse_args(argv)


def _compiler() -> str:
    found = os.environ.get("FUZZ_CXX") or shutil.which("clang++")
    if not found:
        raise SystemExit("không thấy clang++")
    return found


def _cc(cxx: str) -> str:
    return str(Path(cxx).with_name("clang.exe" if cxx.endswith("clang++.exe") else "clang"))


def _runtime_env(cxx: str) -> dict[str, str]:
    env = dict(os.environ)
    found = subprocess.run([cxx, "-print-resource-dir"], capture_output=True, text=True, check=False)
    runtime = Path(found.stdout.strip()) / "lib" / "windows"
    env["PATH"] = f"{runtime}{os.pathsep}{env.get('PATH', '')}"
    return env


def _exe(name: str) -> Path:
    return BUILD / name / f"fuzz_{name}.exe"


def _sodium_objects(cc: str, env: dict[str, str]) -> list[Path]:
    folder = BUILD / "sodium"
    folder.mkdir(parents=True, exist_ok=True)
    includes = ["-I", str(SODIUM_INCLUDE), "-I", str(SODIUM_INCLUDE / "sodium")]
    sources = sorted(SODIUM_SRC.rglob("*.c"))
    objects: list[Path] = []

    def compile_one(source: Path) -> Path:
        output = folder / (source.relative_to(SODIUM_SRC).as_posix().replace("/", "_") + ".o")
        objects_ready = output.is_file() and output.stat().st_mtime >= source.stat().st_mtime
        if objects_ready:
            return output
        command = [cc, *C_FLAGS, *includes, "-c", str(source), "-o", str(output)]
        done = subprocess.run(command, cwd=PROJECT, env=env, capture_output=True, text=True, check=False)
        if done.returncode != 0:
            raise RuntimeError(done.stdout + done.stderr)
        return output

    with ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
        objects = list(pool.map(compile_one, sources))
    return objects


def _command(cxx: str, name: str, sodium: list[Path], extra: tuple[str, ...]) -> list[str]:
    harness = HARNESSES / f"fuzz_{name}.cpp"
    sources = [str(harness), *(str(path) for path in SOURCES)]
    includes = ["-I", str(PROJECT / "SRC"), "-isystem", str(SODIUM_INCLUDE)]
    folder = name if not extra else f"{name}-teeth"
    output = _exe(folder)
    output.parent.mkdir(parents=True, exist_ok=True)
    listing = output.parent / "sodium.rsp"
    lines = [f'"{path.as_posix()}"' for path in sodium]
    listing.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return [cxx, *FLAGS, *extra, *WINDOWS_DEFINES, *includes, *sources, f"@{listing}", "-ladvapi32", "-o", str(output)]


def _build(cxx: str, name: str, env: dict[str, str], extra: tuple[str, ...] = ()) -> Path:
    if not SODIUM_INCLUDE.is_dir():
        raise SystemExit(f"chưa có {SODIUM_INCLUDE}: dựng preset clang-asan trước")
    try:
        sodium = _sodium_objects(_cc(cxx), env)
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit("libsodium: dựng hỏng") from None
    command = _command(cxx, name, sodium, extra)
    done = subprocess.run(command, cwd=PROJECT, env=env, capture_output=True, text=True, check=False)
    if done.returncode != 0:
        print(done.stdout + done.stderr, file=sys.stderr)
        raise SystemExit(f"{name}: dựng hỏng, mã {done.returncode}")
    return Path(command[-1])


def _run(exe: Path, runs: int, seed: int, max_len: int, corpus: Path, env: dict[str, str]) -> tuple[int, str]:
    corpus.mkdir(parents=True, exist_ok=True)
    args = [str(exe), f"-runs={runs}", f"-seed={seed}", f"-max_len={max_len}", str(corpus)]
    done = subprocess.run(
        args, cwd=exe.parent, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, encoding="utf-8", errors="replace", check=False,
    )
    return done.returncode, done.stdout


def _runs_of(log: str) -> int:
    done = [line for line in log.splitlines() if line.startswith("Done ")]
    if not done:
        return 0
    return int(done[-1].split()[1])


def fuzz(name: str, runs: int, seed: int, max_len: int, cxx: str, env: dict[str, str]) -> int:
    exe = _build(cxx, name, env)
    corpus = exe.parent / "corpus"
    if corpus.exists():
        shutil.rmtree(corpus)
    start = time.perf_counter()
    code, log = _run(exe, runs, seed, max_len, corpus, env)
    seconds = time.perf_counter() - start
    finished = _runs_of(log)
    print(f"{name}\t{finished}\t{seconds:.2f}\t{code}", flush=True)
    if code != 0:
        print(log[-4000:], file=sys.stderr)
    return code


def _proof_corpus(name: str) -> Path:
    folder = BUILD / name
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    (folder / "proof").write_bytes(PROOF)
    return folder


def teeth(cxx: str, env: dict[str, str]) -> int:
    normal = _build(cxx, "record", env)
    broken = _build(cxx, "record", env, ("-DSECURE_DROP_LENGTH_CHECK",))
    limit = len(PROOF) + 64
    safe_code, _safe_log = _run(normal, 1, 1, limit, _proof_corpus("teeth-safe"), env)
    bad_code, bad_log = _run(broken, 1, 1, limit, _proof_corpus("teeth-broken"), env)
    caught = safe_code == 0 and bad_code != 0 and "ERROR: AddressSanitizer" in bad_log
    print(f"teeth\tsafe={safe_code}\tbroken={bad_code}\tcaught={int(caught)}", flush=True)
    if not caught:
        print(bad_log[-4000:], file=sys.stderr)
        return 1
    return 0


def main(argv: list[str]) -> int:
    args = _parse_args(argv)
    cxx = _compiler()
    env = _runtime_env(cxx)
    if args.teeth:
        return teeth(cxx, env)
    names = ("handshake", "record") if args.only is None else (args.only,)
    limits = {"handshake": 512, "record": 8308}
    codes = [fuzz(name, args.runs, args.seed, limits[name], cxx, env) for name in names]
    return 0 if all(code == 0 for code in codes) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
