"""Phép kiểm T1, T2, T3, T4, T10, T13, T15, T16, T18 và Đ5, Đ6 của L (P2 đợt 2), ở gốc worktree.

Mỗi phép ghi một log mới l-t<N>.log (hay l-d5.log, l-d6.log) trong so-do/; tệp đã có thì dừng,
không ghi đè. T3, T4 dùng t3(), t4() của c-do.py với thư mục làm việc build/p2-l/do. Cả script giữ
NANG.lock (T13 chạy ctest lặp 20 lần). Không mở hai tệp cấm: T18 chỉ tìm tên và mẫu bí mật.
"""
from __future__ import annotations

import importlib.util
import re
import subprocess
import sys
from collections.abc import Callable
from datetime import datetime
from pathlib import Path
from types import ModuleType

ROOT = Path.cwd()
SO_DO = ROOT / "docs/giao-viec/P2-DOT-2/so-do"
MOC = ROOT / "docs/giao-viec/P2-DOT-2/moc"
LOCK = ROOT / "build/NANG.lock"
TSV = ROOT / "build/lich-nang.tsv"
GIT = ["git", "-c", "safe.directory=*"]
DEV_BAT = r"call %USERPROFILE%\.claude\skills\cpp-build\dev.bat >nul && "
GENERATED = {"SRC/protocol/messages.hpp", "SRC/protocol/messages.cpp", "tests/protocol_samples.hpp",
             "docs/PROTOCOL-TIN.md"}
NET_HEADERS = re.compile(r"winsock2\.h|ws2tcpip\.h|sys/socket\.h|poll\.h|netinet/|arpa/")
SECRET = re.compile(r"(?i)(password|passwd|secret|token|api[_-]?key)\s*[=:]\s*\S{6,}|secrets\.local|Account\.txt")
PRESETS = ("clang-asan", "msvc-release", "gcc-debug")


def stamp() -> str:
    """Giờ máy, đến giây."""
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def save(name: str, lines: list[str]) -> None:
    """Ghi log mới, dòng đầu là giờ bắt đầu; tệp đã có thì dừng."""
    path = SO_DO / name
    if path.exists():
        raise SystemExit(f"đã có {name}, không ghi đè")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"đã ghi so-do/{name}", flush=True)


def shell(command: str) -> tuple[int, str]:
    """Chạy một lệnh qua cmd ở gốc worktree; trả mã thoát và stdout cùng stderr."""
    done = subprocess.run(command, shell=True, capture_output=True, text=True, encoding="utf-8",
                          errors="replace", cwd=ROOT, check=False)
    return done.returncode, (done.stdout + done.stderr).rstrip()


def block(title: str, command: str, shown: str | None = None) -> tuple[list[str], int, str]:
    """Chạy lệnh, trả các dòng log (giờ, lệnh, output, mã thoát)."""
    start = stamp()
    code, text = shell(command)
    return [f"# {start} -> {stamp()}  {title}", f"$ {shown or command}", text, f"mã thoát: {code}", ""], code, text


def t1() -> None:
    """T1: unittest của TOOLS/server."""
    lines, _code, text = block("T1", 'python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"')
    ran = re.findall(r"Ran (\d+) tests?", text)
    skipped = re.findall(r"skipped=(\d+)", text)
    lines += [f"số test chạy: {ran}", f"số bỏ qua: {skipped or ['0']}"]
    new, _c, new_text = block("T1 phần test mới",
                              r"cd TOOLS\server && python -B -W error -m unittest -v test_gen_protocol")
    lines += new + [f"ca bỏ qua của test_gen_protocol.py: {len(re.findall(r'skipped', new_text))}", ""]
    save("l-t1.log", lines)


def t2() -> None:
    """T2: lint_py."""
    lines, _code, _text = block("T2", "python -B -W error TOOLS/server/lint_py.py")
    save("l-t2.log", lines)


def load_c() -> ModuleType:
    """Nạp so-do/c-do.py; thư mục làm việc đổi sang build/p2-l/do."""
    spec = importlib.util.spec_from_file_location("c_do", SO_DO / "c-do.py")
    if spec is None or spec.loader is None:
        raise SystemExit("không nạp được c-do.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.WORK = ROOT / "build/p2-l/do"
    module.WORK.mkdir(parents=True, exist_ok=True)
    return module


def via_c(step: str, name: str) -> None:
    """Chạy một hàm của c-do.py, ghi log của nó dưới tên của L."""
    module = load_c()
    start = stamp()
    module.write = lambda _name, lines: save(name, [f"# {start}  {step} chạy bằng c-do.py {step.lower()}()"
                                                    f" (thư mục làm việc build/p2-l/do)", "", *lines])
    getattr(module, step.lower())()


def t10() -> None:
    """T10: số vòng (hằng kRuns) và số giây của protocol_fuzz_tests ở ba preset, lấy từ log ctest 1b."""
    source = (ROOT / "tests/protocol_fuzz_tests.cpp").read_text(encoding="utf-8")
    runs = re.search(r"constexpr std::size_t kRuns = ([\d']+);", source)
    lines = [f"# {stamp()}  T10: đọc tests/protocol_fuzz_tests.cpp và log ctest 1b-*", "",
             f"tests/protocol_fuzz_tests.cpp: kRuns = {runs.group(1) if runs else 'không thấy'} (mọi preset, mỗi đích)", ""]
    logs = {"clang-asan": "1b-clang-asan-ctest-lan2.txt", "msvc-release": "1b-msvc-release-ctest.txt",
            "gcc-debug": "1b-gcc-debug-ctest.txt"}
    for preset, log in logs.items():
        text = (SO_DO / log).read_text(encoding="utf-8")
        found = re.findall(r".*protocol_fuzz_tests \.+.*", text)
        lines.append(f"{preset} ({log}): {found}")
    save("l-t10.log", lines + [""])


def t13() -> None:
    """T13: net_tests và wire_loop_tests lặp 20 lần trên msvc-release."""
    lines: list[str] = []
    for test in ("net_tests", "wire_loop_tests"):
        command = f'ctest --test-dir build/msvc-release -R "^{test}$" --repeat until-fail:20'
        part, _code, text = block(f"T13 {test} (trong dev.bat)", DEV_BAT + command, command)
        lines += part + [f"số dòng Passed: {len(re.findall(r'Passed', text))}", ""]
    save("l-t13.log", lines)


def tracked_new() -> list[str]:
    """Tệp mới và tệp đã sửa theo git status."""
    _code, text = shell(" ".join(GIT) + " status --short --untracked-files=all")
    return [line[3:].strip() for line in text.splitlines() if line.strip()]


def t15() -> None:
    """T15: header mạng của hệ điều hành trong SRC/ và tests/."""
    lines = [f"# {stamp()}  T15: tìm {NET_HEADERS.pattern} trong SRC/ và tests/ (*.cpp, *.hpp, *.h)", ""]
    for base in ("SRC", "tests"):
        for path in sorted((ROOT / base).rglob("*")):
            if path.suffix not in {".cpp", ".hpp", ".h"}:
                continue
            for number, row in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
                if "#include" in row and NET_HEADERS.search(row):
                    lines.append(f"{path.relative_to(ROOT).as_posix()}:{number}: {row.strip()}")
    save("l-t15.log", lines + [""])


def hand_written() -> list[str]:
    """Tệp .cpp, .hpp, .py viết tay mới của đợt (không tính tệp sinh và so-do/)."""
    names = [name for name in tracked_new() if Path(name).suffix in {".cpp", ".hpp", ".py"}]
    return [name for name in names if name not in GENERATED and "/so-do/" not in name]


def line_count(name: str) -> int:
    """Số dòng như wc -l (đếm ký tự xuống dòng)."""
    return (ROOT / name).read_bytes().count(b"\n")


def t16() -> None:
    """T16: số dòng từng tệp viết tay."""
    names = hand_written()
    lines = [f"# {stamp()}  T16: số dòng (đếm byte xuống dòng, như wc -l) của tệp .cpp/.hpp/.py viết tay mới",
             "", *(f"{line_count(name)}\t{name}" for name in names), ""]
    over = [name for name in names if Path(name).suffix in {".cpp", ".py"} and line_count(name) > 500]
    save("l-t16.log", lines + [f"tệp .cpp hay .py quá 500 dòng: {over or 'không có'}", ""])


def t18() -> None:
    """T18: git status so với moc, diff hai tệp CMake, tìm bí mật."""
    lines, _code, _text = block("T18 git status", " ".join(GIT) + " status --short --untracked-files=all")
    lines += [f"moc/git-status.txt: {(MOC / 'git-status.txt').read_text(encoding='utf-8').strip()}", ""]
    for current, moc in (("CMakeLists.txt", "CMakeLists.txt"), ("cmake/GameLayers.cmake", "GameLayers.cmake")):
        command = " ".join(GIT) + f" diff --no-index --numstat docs/giao-viec/P2-DOT-2/moc/{moc} {current}"
        part, _c, _t = block(f"T18 diff {current} (cột: thêm, bớt)", command)
        lines += part
    lines += ["tìm bí mật: không mở hai tệp cấm; tìm tên của chúng và mẫu " + SECRET.pattern, ""]
    hits = []
    for name in tracked_new():
        path = ROOT / name
        if path.is_file():
            hits += [f"{name}:{number}" for number, row in
                     enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1) if SECRET.search(row)]
    save("l-t18.log", lines + [f"dòng khớp: {hits or 'không có'}", ""])


def d5() -> None:
    """Đ5: vòng mỗi giây của từng đích, chép nguyên từ so-do/fuzz.tsv (T11)."""
    text = (SO_DO / "fuzz.tsv").read_text(encoding="utf-8").rstrip()
    save("l-d5.log", [f"# {stamp()}  Đ5: nội dung so-do/fuzz.tsv (fuzz tầng hai 02:29 tới 02:30)", "", text, ""])


def d6() -> None:
    """Đ6: số dòng từng tệp viết tay và tệp sinh; số ca test của từng tệp test mới."""
    lines = [f"# {stamp()}  Đ6: số dòng (đếm byte xuống dòng) và số ca test", "", "### viết tay"]
    lines += [f"{line_count(name)}\t{name}" for name in hand_written()]
    lines += ["", "### sinh", *(f"{line_count(name)}\t{name}" for name in sorted(GENERATED)), "", "### ca test"]
    for name in sorted(n for n in tracked_new() if n.startswith("tests/") and n.endswith("_tests.cpp")):
        text = (ROOT / name).read_text(encoding="utf-8")
        lines.append(f"{name}: {len(re.findall(r'game::test::Case\{', text))} ca (đếm game::test::Case{{)")
    save("l-d6.log", lines + [""])


def main() -> int:
    """Mọi phép kiểm dưới một khoá."""
    while LOCK.exists():
        raise SystemExit("NANG.lock đang có, chờ")
    start = stamp()
    LOCK.write_text(f"L chạy T1 tới T18 (l-t.py) {start}", encoding="utf-8")
    steps: list[Callable[[], None]] = [t1, t2, lambda: via_c("T3", "l-t3.log"), lambda: via_c("T4", "l-t4.log"),
                                       t10, t13, t15, t16, t18, d5, d6]
    try:
        for step in steps:
            step()
    finally:
        with TSV.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(f"{start}\t{stamp()}\tL\tT1 tới T18 trừ T12, T17, kèm ctest lặp 20 lần (so-do/l-t.py)\n")
        LOCK.unlink()
    return 0


if __name__ == "__main__":
    sys.exit(main())