# Chạy thienlong_client với một kịch bản E2E (--script), thu kết quả vào một thư mục và phán đạt hay
# hỏng theo các chỉ thị "#!" ghi ngay trong tệp kịch bản (client coi dòng #! là chú thích).
# Chạy ở gốc dự án (chỉ Windows):
#   py -X utf8 TOOLS/run/e2e_client.py TOOLS/run/e2e/g0.script
#   py -X utf8 TOOLS/run/desk_watch.py py -X utf8 TOOLS/run/e2e_client.py TOOLS/run/e2e/g0.script
# desk_watch bỏ stdout của lệnh con, nên công cụ này tự ghi mọi thứ ra thư mục kết quả: stdout.txt
# (đầu ra của client, có các dòng SCRIPT), net.log (vết mạng), shots/*.png, sidecar-N.txt, report.txt.
# Mã thoát: 0 khi mọi chỉ thị đạt, 1 khi có chỉ thị hỏng, 2 khi kịch bản hay đối số sai.
# Tài khoản đã có nhân vật thì đăng nhập tự động không gửi CreateCharacter nữa: chạy lại kịch bản
# cần tạo nhân vật thì đổi tên bằng --account.
#
# Chỉ thị (mỗi dòng "#! tên đối số..."):
#   account <tên>                tài khoản đăng nhập tự động (THIENLONG_ACCOUNT); --account thắng
#   out <thư mục>                thư mục kết quả; mặc định build/e2e/<tên tệp kịch bản>
#   timeout <giây>               hạn cho cả lượt chạy; mặc định 240
#   expect-exit <mã>             mã thoát của client; mặc định 0 (kéo theo: có dòng SCRIPT end, 0 hỏng)
#   expect-shots <tên>...        mỗi tên có tệp <thư mục kết quả>/shots/<tên>.png hợp lệ
#   expect-net <tin>...          net.log có tin đó; "gửi:Tên" hay "nhận:Tên" để chỉ rõ chiều
#   expect-file <tệp> <regex>    dòng MỚI của tệp (từ lúc bắt đầu chạy) có chỗ khớp regex; {account}
#                                trong regex là tên tài khoản của lượt chạy này
#   sidecar <lệnh>               chạy kèm một tiến trình (bot) từ lúc mở client; phải thoát mã 0
import argparse
import os
import re
import shlex
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CLIENT = ROOT / "dev" / "client" / "bin" / "thienlong_client.exe"
DEFAULT_TIMEOUT = 240.0
# Tiến trình kèm còn chạy sau khi client thoát thì chờ thêm chừng này giây rồi dừng.
SIDECAR_GRACE = 60.0
# Dòng log của máy chủ ghi trễ một nhịp: chỉ thị expect-file được thử lại tới chừng này giây.
FILE_RETRY = 10.0
SW_SHOWNOACTIVATE = 4
CREATE_NO_WINDOW = 0x08000000
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


@dataclass
class Plan:
    """Những gì kịch bản đòi: đọc từ các dòng #!."""
    account: str = ""
    out: str = ""
    timeout: float = DEFAULT_TIMEOUT
    exit_code: int = 0
    shots: list[str] = field(default_factory=list)
    net: list[tuple[str, str]] = field(default_factory=list)
    files: list[tuple[Path, str]] = field(default_factory=list)
    sidecars: list[list[str]] = field(default_factory=list)


@dataclass
class Check:
    name: str
    ok: bool
    detail: str


class PlanError(Exception):
    """Chỉ thị sai: báo kèm số dòng và thoát mã 2."""


def resolve(text: str) -> Path:
    path = Path(text)
    return path if path.is_absolute() else ROOT / path


def parse_net(tokens: list[str]) -> list[tuple[str, str]]:
    pairs = []
    for token in tokens:
        way, _, name = token.rpartition(":")
        pairs.append((way, name))
    return pairs


def apply_directive(plan: Plan, key: str, rest: str, number: int) -> None:
    words = rest.split()
    if key == "account":
        plan.account = rest.strip()
    elif key == "out":
        plan.out = rest.strip()
    elif key == "timeout":
        plan.timeout = float(rest)
    elif key == "expect-exit":
        plan.exit_code = int(rest)
    elif key == "expect-shots":
        plan.shots.extend(words)
    elif key == "expect-net":
        plan.net.extend(parse_net(words))
    elif key == "expect-file":
        path, _, pattern = rest.strip().partition(" ")
        if not pattern.strip():
            raise PlanError(f"dòng {number}: expect-file cần <tệp> <regex>")
        re.compile(pattern.strip())
        plan.files.append((resolve(path), pattern.strip()))
    elif key == "sidecar":
        plan.sidecars.append(shlex.split(rest, posix=False))
    else:
        raise PlanError(f"dòng {number}: chỉ thị lạ '{key}'")


def read_plan(script: Path) -> Plan:
    plan = Plan()
    lines = script.read_text(encoding="utf-8").splitlines()
    for number, raw in enumerate(lines, start=1):
        line = raw.strip()
        if not line.startswith("#!"):
            continue
        key, _, rest = line[2:].strip().partition(" ")
        try:
            apply_directive(plan, key, rest, number)
        except ValueError as error:
            raise PlanError(f"dòng {number}: đối số của '{key}' sai ({error})") from error
    return plan


def clear_output(out: Path) -> None:
    """Xoá đúng những tệp công cụ này ghi ở lượt trước, không đụng thứ khác."""
    out.mkdir(parents=True, exist_ok=True)
    (out / "shots").mkdir(exist_ok=True)
    for name in ("stdout.txt", "net.log", "report.txt"):
        (out / name).unlink(missing_ok=True)
    for old in list(out.glob("sidecar-*.txt")) + list((out / "shots").glob("*.png")):
        old.unlink()


def sizes_of(paths: list[Path]) -> dict[Path, int]:
    return {path: path.stat().st_size if path.exists() else 0 for path in paths}


def start_sidecar(command: list[str], log: Path) -> subprocess.Popen:
    sink = open(log, "wb")
    return subprocess.Popen(command, cwd=ROOT, stdout=sink, stderr=subprocess.STDOUT,
                            creationflags=CREATE_NO_WINDOW)


def start_client(client: Path, script: Path, out: Path, env: dict[str, str]) -> subprocess.Popen:
    """Mở client không giành tiêu điểm: SW_SHOWNOACTIVATE cho lần hiện cửa sổ đầu."""
    info = subprocess.STARTUPINFO()
    info.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    info.wShowWindow = SW_SHOWNOACTIVATE
    sink = open(out / "stdout.txt", "wb")
    command = [str(client), "--script", str(script), "--shot-dir", str(out / "shots")]
    return subprocess.Popen(command, cwd=client.parent, env=env, stdout=sink,
                            stderr=subprocess.STDOUT, startupinfo=info)


def wait_exit(process: subprocess.Popen, seconds: float) -> int | None:
    """Mã thoát, hoặc None khi quá hạn (tiến trình bị dừng)."""
    try:
        return process.wait(timeout=max(seconds, 0.0))
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        return None


def read_steps(stdout: Path) -> tuple[list[list[str]], list[str] | None]:
    steps: list[list[str]] = []
    end: list[str] | None = None
    for line in stdout.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = line.rstrip("\r").split("\t")
        if parts[0] != "SCRIPT" or len(parts) < 3:
            continue
        if parts[1] == "end":
            end = parts
        else:
            steps.append(parts)
    return steps, end


def check_script(plan: Plan, out: Path) -> Check:
    steps, end = read_steps(out / "stdout.txt")
    bad = [step for step in steps if len(step) > 4 and step[4] != "ok"]
    if plan.exit_code != 0:
        return Check("script", True, f"{len(steps)} bước (mã thoát mong đợi {plan.exit_code})")
    if end is None:
        return Check("script", False, "không có dòng SCRIPT end: client không chạy hết kịch bản")
    failed = len(bad)
    names = ", ".join(f"{step[1]}:{step[2]}" for step in bad)
    detail = f"{len(steps)} bước, {failed} hỏng" + (f" ({names})" if bad else "")
    return Check("script", failed == 0, detail)


def check_shots(plan: Plan, out: Path) -> list[Check]:
    checks = []
    for name in plan.shots:
        path = out / "shots" / f"{name}.png"
        head = path.read_bytes()[:8] if path.exists() else b""
        ok = head == PNG_SIGNATURE and path.stat().st_size > 1000
        size = path.stat().st_size if path.exists() else 0
        checks.append(Check(f"shot {name}", ok, f"{size} byte" if path.exists() else "không có tệp"))
    return checks


def check_net(plan: Plan, out: Path) -> list[Check]:
    log = out / "net.log"
    text = log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""
    rows = [line.split("\t") for line in text.splitlines()]
    seen = {(row[1], row[2]) for row in rows if len(row) >= 3}
    checks = []
    for way, name in plan.net:
        found = [pair for pair in seen if pair[1] == name and way in ("", pair[0])]
        label = f"net {way + ':' if way else ''}{name}"
        count = sum(1 for row in rows if len(row) >= 3 and row[2] == name)
        checks.append(Check(label, bool(found), f"{count} dòng"))
    return checks


def fresh_text(path: Path, start: int) -> str:
    if not path.exists():
        return ""
    with open(path, "rb") as source:
        source.seek(start)
        return source.read().decode("utf-8", errors="replace")


def check_files(plan: Plan, starts: dict[Path, int]) -> list[Check]:
    account = re.escape(plan.account)
    pending = [(path, pattern.replace("{account}", account)) for path, pattern in plan.files]
    deadline = time.monotonic() + FILE_RETRY
    results: dict[tuple[Path, str], bool] = {}
    while pending:
        for path, pattern in list(pending):
            if re.search(pattern, fresh_text(path, starts[path])):
                results[(path, pattern)] = True
                pending.remove((path, pattern))
        if pending and time.monotonic() >= deadline:
            break
        if pending:
            time.sleep(0.5)
    checks = [Check(f"file {path.name}", True, pattern) for (path, pattern) in results]
    checks += [Check(f"file {path.name}", False, f"không dòng mới nào khớp: {pattern}")
               for path, pattern in pending]
    return checks


def write_report(out: Path, script: Path, plan: Plan, code: int | None, seconds: float,
                 checks: list[Check]) -> str:
    steps, _ = read_steps(out / "stdout.txt")
    lines = [f"E2E {script.name}: client thoát {code if code is not None else 'QUÁ HẠN'}"
             f" sau {seconds:.1f} giây, tài khoản {plan.account or '(không)'}", ""]
    lines += ["\t".join(step[1:]) for step in steps]
    lines.append("")
    lines += [f"{'ĐẠT' if one.ok else 'HỎNG'}\t{one.name}\t{one.detail}" for one in checks]
    verdict = "ĐẠT" if all(one.ok for one in checks) else "HỎNG"
    lines += ["", f"KẾT LUẬN: {verdict}"]
    text = "\n".join(lines) + "\n"
    (out / "report.txt").write_text(text, encoding="utf-8")
    return text


def run(script: Path, args: argparse.Namespace) -> int:
    plan = read_plan(script)
    if args.account:
        plan.account = args.account
    out = resolve(args.out or plan.out or f"build/e2e/{script.stem}")
    clear_output(out)
    starts = sizes_of([path for path, _ in plan.files])
    env = dict(os.environ, THIENLONG_NET_TRACE=str(out / "net.log"))
    if plan.account:
        env["THIENLONG_ACCOUNT"] = plan.account
    began = time.monotonic()
    helpers = [start_sidecar(cmd, out / f"sidecar-{index}.txt")
               for index, cmd in enumerate(plan.sidecars, start=1)]
    client = start_client(Path(args.client), script.resolve(), out, env)
    code = wait_exit(client, plan.timeout)
    client_seconds = time.monotonic() - began
    checks = [Check("exit", code == plan.exit_code, f"nhận {code}, mong {plan.exit_code}")]
    for index, helper in enumerate(helpers, start=1):
        helper_code = wait_exit(helper, SIDECAR_GRACE)
        checks.append(Check(f"sidecar {index}", helper_code == 0, f"mã thoát {helper_code}"))
    checks.append(check_script(plan, out))
    checks += check_shots(plan, out) + check_net(plan, out) + check_files(plan, starts)
    text = write_report(out, script, plan, code, client_seconds, checks)
    sys.stdout.write(text)
    return 0 if all(one.ok for one in checks) else 1


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Chạy một kịch bản E2E của thienlong_client.")
    parser.add_argument("script", help="tệp kịch bản (--script của client)")
    parser.add_argument("--client", default=str(DEFAULT_CLIENT), help="đường dẫn thienlong_client.exe")
    parser.add_argument("--account", default="", help="ghi đè chỉ thị #! account")
    parser.add_argument("--out", default="", help="ghi đè chỉ thị #! out")
    args = parser.parse_args()
    script = resolve(args.script)
    if not script.is_file():
        print(f"không thấy kịch bản: {script}", file=sys.stderr)
        return 2
    try:
        return run(script, args)
    except PlanError as error:
        print(f"kịch bản sai: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
