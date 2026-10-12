"""Kiểm đầu cuối trình giám sát của P2 đợt 1 (Claude, 2026-10-07). Không dùng mã test của dự án.

    python -B docs/giao-viec/P2-DOT-1/kiem-claude/boot_check.py <thư mục exe> <thư mục cấu hình> [phần...]

Phần không đụng PostgreSQL (mặc định chạy cả): nul, pipe, restart, ceiling, kill, break, ctrlc.
Phần chạy PostgreSQL thật, phải gọi tên: postgres, using, survive.
Mọi phần chạy trên một bản chép của thư mục cấu hình đặt ở build/p2-claude-boot: gate nghe
127.0.0.1:0 và mọi [[process]] khai cổng 0 (hệ điều hành cấp cổng, gate báo cổng thật ở dòng ready),
khoá danh tính sinh tại đó. Không phần nào nghe địa chỉ ngoài loopback, nên không tranh cổng với cụm
đang chạy và Windows không thêm rule tường lửa cho exe đang thử.
Ba phần PostgreSQL dựng một cụm PostgreSQL tạm bằng initdb ở build/p2-claude-boot/pg-data, chỉ nghe
127.0.0.1 ở một cổng trống do hệ điều hành chọn, dừng và xoá nó khi xong. Chúng chỉ mượn nhị phân
PostgreSQL ở thư mục bin_dir của cấu hình đã cho (tải bằng `python TOOLS/server/setup_db.py fetch`),
không đụng SERVER/data/pg hay cấu hình PostgreSQL của máy.
Mỗi phép kiểm in một dòng "đạt" hoặc "HỎNG". Mã thoát 0 khi không dòng nào hỏng.
"""
import ctypes
import os
import queue
import re
import secrets
import shutil
import socket
import subprocess
import sys
import threading
import time
from ctypes import wintypes
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
HERE = Path(__file__).resolve()
ROOT = HERE.parents[4]
SCRATCH = ROOT / "build" / "p2-claude-boot"
K32 = ctypes.WinDLL("kernel32", use_last_error=True)
START = ["started store 0", "started auth 0", "started billing 0", "started world 0", "started zone 0",
         "started gate", "ready"]
STOP = ["stopped gate", "stopped zone 0", "stopped world 0", "stopped billing 0", "stopped auth 0",
        "stopped store 0"]
# Dòng sẵn sàng của cụm: `ready` kèm hai cổng thật của gate (mục 3.1 của docs/KE-HOACH-SERVER.md).
READY = re.compile(r"ready gate\.game=([1-9][0-9]{0,4}) gate\.auth=([1-9][0-9]{0,4})")
FAILED = []


def is_cluster_ready(text: str) -> bool:
    found = READY.fullmatch(text)
    if not found:
        return False
    game, auth = int(found[1]), int(found[2])
    return game != auth and game <= 65535 and auth <= 65535


def shape(text: str) -> str:
    """Dòng ready của cụm rút về "ready" để so thứ tự với START; `ready` trần (thiếu cổng của gate)
    thì đổi thành chữ khác để phép so hỏng."""
    if is_cluster_ready(text):
        return "ready"
    return "ready thiếu cổng của gate" if text == "ready" else text


def verdict(ok: bool, what: str, detail: str = "") -> None:
    print(f"    {'đạt' if ok else 'HỎNG'}: {what}{' — ' + detail if detail and not ok else ''}")
    if not ok:
        FAILED.append(what)


class Entry(ctypes.Structure):
    _fields_ = [("dwSize", wintypes.DWORD), ("cntUsage", wintypes.DWORD), ("th32ProcessID", wintypes.DWORD),
                ("th32DefaultHeapID", ctypes.c_size_t), ("th32ModuleID", wintypes.DWORD),
                ("cntThreads", wintypes.DWORD), ("th32ParentProcessID", wintypes.DWORD),
                ("pcPriClassBase", wintypes.LONG), ("dwFlags", wintypes.DWORD), ("szExeFile", wintypes.WCHAR * 260)]


def processes():
    """Mọi tiến trình đang chạy: (pid, pid cha, tên exe)."""
    K32.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
    snapshot = K32.CreateToolhelp32Snapshot(0x2, 0)
    entry = Entry()
    entry.dwSize = ctypes.sizeof(Entry)
    found = []
    more = K32.Process32FirstW(wintypes.HANDLE(snapshot), ctypes.byref(entry))
    while more:
        found.append((entry.th32ProcessID, entry.th32ParentProcessID, entry.szExeFile))
        more = K32.Process32NextW(wintypes.HANDLE(snapshot), ctypes.byref(entry))
    K32.CloseHandle(wintypes.HANDLE(snapshot))
    return found


def ours():
    return [(pid, name) for pid, _, name in processes() if name.lower().startswith("thienlong_")
            and name.lower() != "thienlong_client.exe"]


def child_of(parent: int, name: str):
    return [pid for pid, owner, exe in processes() if owner == parent and exe.lower() == name]


def kill(pid: int) -> None:
    K32.OpenProcess.restype = wintypes.HANDLE
    handle = K32.OpenProcess(0x1, False, pid)
    K32.TerminateProcess(wintypes.HANDLE(handle), 9)
    K32.CloseHandle(wintypes.HANDLE(handle))


def wait_until(test, seconds: float) -> bool:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if test():
            return True
        time.sleep(0.05)
    return test()


class Run:
    """Một lần chạy exe: stdout và stderr đọc trên luồng riêng để không bao giờ chặn."""

    def __init__(self, exe: Path, args, stdin):
        self.started = time.monotonic()
        self.proc = subprocess.Popen([str(exe), *args], stdin=stdin, stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE)
        self.out = queue.Queue()
        self.err = []
        threading.Thread(target=self._pump_out, daemon=True).start()
        threading.Thread(target=self._pump_err, daemon=True).start()

    def _pump_out(self):
        for raw in self.proc.stdout:
            self.out.put((raw.decode("utf-8", "replace").rstrip("\r\n"), time.monotonic() - self.started))
        self.out.put((None, 0.0))

    def _pump_err(self):
        for raw in self.proc.stderr:
            self.err.append(raw.decode("utf-8", "replace").rstrip("\r\n"))

    def line(self, seconds: float = 20.0):
        try:
            return self.out.get(timeout=seconds)
        except queue.Empty:
            return ("<quá hạn>", 0.0)

    def take(self, count: int, seconds: float = 20.0):
        got = []
        while len(got) < count:
            text, moment = self.line(seconds)
            if text is None:
                break
            got.append((text, moment))
        return got

    def rest(self, seconds: float = 40.0):
        got = []
        while True:
            text, moment = self.line(seconds)
            if text is None or text == "<quá hạn>":
                return got
            got.append((text, moment))

    def exit_code(self, seconds: float = 40.0):
        try:
            return self.proc.wait(timeout=seconds)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            return "treo"

    def has_err(self, piece: str, seconds: float = 10.0) -> bool:
        return wait_until(lambda: any(piece in line for line in self.err), seconds)


def texts(pairs):
    return [shape(text) for text, _ in pairs]


def copy_config(source: Path, name: str, edits) -> Path:
    target = SCRATCH / name
    shutil.rmtree(target, ignore_errors=True)
    target.mkdir(parents=True)
    for path in source.glob("*.toml"):
        if path.name.endswith(".local.toml"):
            continue
        text = path.read_text(encoding="utf-8")
        for old, new in edits.get(path.name, []):
            assert old in text, (path.name, old)
            text = text.replace(old, new)
        (target / path.name).write_text(text, encoding="utf-8", newline="\n")
    return target


def any_port_processes(text: str) -> str:
    """cluster.toml với dòng port của mọi khối [[process]] đổi thành 0; bảng khác giữ nguyên."""
    out, inside, blocks, hosts, ports = [], False, 0, 0, 0
    for line in text.splitlines():
        if line.startswith("["):
            inside = line.startswith("[[process]]")
            blocks += inside
        if inside and re.match(r'host\s*=\s*"127\.0\.0\.1"', line):
            hosts += 1
        if inside and re.match(r"port\s*=\s*[0-9]+", line):
            line = re.sub(r"^(port\s*=\s*)[0-9]+", r"\g<1>0", line)
            ports += 1
        out.append(line)
    assert blocks > 0 and hosts == blocks and ports == blocks, ("cluster.toml lệch bố cục", blocks, hosts, ports)
    return "\n".join(out) + "\n"


def loopback_config(bin_dir: Path, source: Path) -> Path:
    """Bản chép cấu hình cho mọi phần: gate nghe 127.0.0.1:0, mọi [[process]] khai cổng 0, khoá danh
    tính sinh cạnh bản chép (gate.toml trỏ ../data/gate/identity.key)."""
    target = copy_config(source, "config-loopback", {})
    gate = target / "gate.toml"
    line = re.compile(r'^(game|auth)(\s*=\s*)"[^"]*"', re.MULTILINE)
    text, count = line.subn(lambda m: f'{m[1]}{m[2]}"127.0.0.1:0"', gate.read_text(encoding="utf-8"))
    assert count == 2, ("gate.toml phải có đúng hai dòng game và auth", count)
    gate.write_text(text, encoding="utf-8", newline="\n")
    cluster = target / "cluster.toml"
    cluster.write_text(any_port_processes(cluster.read_text(encoding="utf-8")), encoding="utf-8", newline="\n")
    key = SCRATCH / "data" / "gate" / "identity.key"
    if not key.exists():
        key.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run([str(bin_dir / "thienlong_gate.exe"), "--gen-key", str(key)], check=True,
                       stdout=subprocess.DEVNULL)
    return target


def part_nul(server: Path, config: Path):
    print("nul: stdin là thiết bị rỗng, không PostgreSQL")
    run = Run(server, ["--config", str(config), "--no-postgres"], subprocess.DEVNULL)
    lines = run.rest()
    code = run.exit_code()
    verdict(texts(lines) == START + STOP, "đúng 13 dòng theo thứ tự", repr(texts(lines)))
    verdict(code == 0, "thoát 0", repr(code))
    verdict(run.err == [], "stderr trống khi chạy êm", repr(run.err[:3]))
    ready = [moment for text, moment in lines if is_cluster_ready(text)]
    print(f"    từ lúc chạy tới dòng ready: {ready[0] * 1000:.0f} ms" if ready else "    không có dòng ready")
    verdict(wait_until(lambda: not ours(), 5), "không còn tiến trình thienlong_*", repr(ours()))


def part_pipe(server: Path, config: Path):
    print("pipe: ống stdin còn mở thì cụm đứng yên, đóng ống thì dừng ngược thứ tự")
    run = Run(server, ["--config", str(config), "--no-postgres"], subprocess.PIPE)
    verdict(texts(run.take(7)) == START, "khởi động đủ rồi ready")
    time.sleep(1.0)
    verdict(run.proc.poll() is None and len(ours()) == 7, "sau 1 giây vẫn đủ 7 tiến trình", repr(ours()))
    run.proc.stdin.close()
    verdict(texts(run.rest()) == STOP, "đóng ống thì dừng ngược thứ tự")
    verdict(run.exit_code() == 0, "thoát 0")


def part_restart(server: Path, config: Path):
    print("restart: giết một con sau ready thì nó được chạy lại, cụm chạy tiếp")
    run = Run(server, ["--config", str(config), "--no-postgres"], subprocess.PIPE)
    verdict(texts(run.take(7)) == START, "khởi động đủ rồi ready")
    before = child_of(run.proc.pid, "thienlong_zone.exe")
    verdict(len(before) == 1, "giám sát có đúng một con zone", repr(before))
    for pid in before:
        kill(pid)
    verdict(run.has_err("zone 0 thoát, chạy lại"), "stderr báo chạy lại zone 0", repr(run.err))
    fresh = lambda: [pid for pid in child_of(run.proc.pid, "thienlong_zone.exe") if pid not in before]
    verdict(wait_until(lambda: len(fresh()) == 1, 10), "có tiến trình zone mới", repr(fresh()))
    time.sleep(0.5)
    verdict(run.proc.poll() is None and len(ours()) == 7, "cụm vẫn đủ 7 tiến trình", repr(ours()))
    run.proc.stdin.close()
    verdict(texts(run.rest()) == STOP, "rồi vẫn dừng êm ngược thứ tự")
    verdict(run.exit_code() == 0, "thoát 0", repr(run.err))


def part_ceiling(server: Path, config: Path):
    print("ceiling: max_per_hour = 1, con chết lần hai thì dừng cả cụm, thoát 1")
    limited = copy_config(config, "config-ceiling", {"supervisor.toml": [("max_per_hour = 3", "max_per_hour = 1")]})
    run = Run(server, ["--config", str(limited), "--no-postgres"], subprocess.PIPE)
    verdict(texts(run.take(7)) == START, "khởi động đủ rồi ready")
    first = child_of(run.proc.pid, "thienlong_zone.exe")
    for pid in first:
        kill(pid)
    verdict(run.has_err("zone 0 thoát, chạy lại"), "lần chết đầu được chạy lại")
    second = lambda: [pid for pid in child_of(run.proc.pid, "thienlong_zone.exe") if pid not in first]
    wait_until(lambda: len(second()) == 1, 10)
    time.sleep(0.5)
    for pid in second():
        kill(pid)
    verdict(run.has_err("zone 0 vượt trần chạy lại mỗi giờ"), "lần chết hai báo vượt trần", repr(run.err))
    verdict(texts(run.rest()) == STOP, "các con còn lại dừng ngược thứ tự")
    verdict(run.exit_code() == 1, "thoát 1")


def part_kill(server: Path, config: Path):
    print("kill: giết giám sát giữa chừng, sau 5 giây không còn tiến trình thienlong_*")
    run = Run(server, ["--config", str(config), "--no-postgres"], subprocess.PIPE)
    verdict(texts(run.take(7)) == START, "khởi động đủ rồi ready")
    kill(run.proc.pid)
    gone = wait_until(lambda: not ours(), 5)
    verdict(gone, "không còn tiến trình mồ côi", repr(ours()))


def run_helper(server: Path, config: Path, event: str):
    """Tiến trình phụ có console riêng: chạy giám sát với stdin là console rồi gửi tín hiệu phím."""
    K32.SetConsoleCtrlHandler(None, True)
    out_path = SCRATCH / f"{event}-out.txt"
    with open(out_path, "wb") as out:
        proc = subprocess.Popen([str(server), "--config", str(config), "--no-postgres"], stdout=out,
                                stderr=subprocess.DEVNULL, creationflags=subprocess.CREATE_NEW_PROCESS_GROUP)
        ready = wait_until(lambda: b"ready" in out_path.read_bytes(), 30)
        time.sleep(0.5)
        if event == "break":
            sent = K32.GenerateConsoleCtrlEvent(1, proc.pid)
        else:
            sent = K32.GenerateConsoleCtrlEvent(0, 0)
        try:
            code = proc.wait(timeout=40)
        except subprocess.TimeoutExpired:
            proc.kill()
            code = "treo"
    (SCRATCH / f"{event}-exit.txt").write_text(f"{ready} {bool(sent)} {code}", encoding="utf-8")


def part_signal(server: Path, config: Path, event: str):
    name = "Ctrl+Break" if event == "break" else "Ctrl+C"
    print(f"{event}: stdin là console, gửi {name} thì dừng êm ngược thứ tự")
    for leftover in SCRATCH.glob(f"{event}-*.txt"):
        leftover.unlink()
    hidden = subprocess.STARTUPINFO()
    hidden.dwFlags = subprocess.STARTF_USESHOWWINDOW
    hidden.wShowWindow = 0
    helper = subprocess.Popen([sys.executable, "-B", str(HERE), str(server.parent), str(config), f"--helper={event}"],
                              creationflags=subprocess.CREATE_NEW_CONSOLE, startupinfo=hidden)
    try:
        helper.wait(timeout=90)
    except subprocess.TimeoutExpired:
        helper.kill()
    result = (SCRATCH / f"{event}-exit.txt")
    summary = result.read_text(encoding="utf-8") if result.exists() else "không có kết quả"
    out = SCRATCH / f"{event}-out.txt"
    lines = out.read_text(encoding="utf-8").splitlines() if out.exists() else []
    verdict(summary.startswith("True True"), "cụm lên tới ready và tín hiệu gửi được", summary)
    verdict([shape(line) for line in lines] == START + STOP, "đủ 13 dòng, dừng ngược thứ tự", repr(lines))
    verdict(summary.endswith(" 0"), "thoát 0", summary)
    verdict(wait_until(lambda: not ours(), 5), "không còn tiến trình thienlong_*", repr(ours()))


class TempPostgres:
    """Cụm PostgreSQL tạm của ba phần postgres, using, survive: dữ liệu và log nằm dưới SCRATCH, chỉ
    nghe 127.0.0.1 ở một cổng trống do hệ điều hành chọn. PostgreSQL không nhận cổng 0, nên cổng được
    xin trước rồi trả lại; tiến trình khác lấy mất nó thì `pg_ctl start` hỏng và phần đó báo HỎNG."""

    def __init__(self, source: Path, staged: Path):
        cluster = staged / "cluster.toml"
        text = cluster.read_text(encoding="utf-8")
        found = re.search(r'^bin_dir\s*=\s*"([^"]*)"', text, re.MULTILINE)
        assert found, "cluster.toml thiếu bin_dir"
        self.bin = (source / found[1]).resolve()
        self.data = SCRATCH / "pg-data"
        self.log = SCRATCH / "pg-log" / "postgres.log"
        self.missing = not (self.bin / "pg_ctl.exe").exists()
        if self.missing:
            return
        shutil.rmtree(self.data, ignore_errors=True)
        shutil.rmtree(self.log.parent, ignore_errors=True)
        self.log.parent.mkdir(parents=True)
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            self.port = probe.getsockname()[1]
        # Mật khẩu của tài khoản quản trị cụm tạm: sinh lúc chạy, chỉ initdb đọc, xoá ngay sau đó.
        password = SCRATCH / "pg-password.txt"
        password.write_text(secrets.token_hex(16), encoding="ascii")
        try:
            subprocess.run([str(self.bin / "initdb.exe"), "-D", str(self.data), "-U", "thienlong_test",
                            "--auth=scram-sha-256", f"--pwfile={password}", "-E", "UTF8", "--no-locale"],
                           check=True, stdout=subprocess.DEVNULL)
        finally:
            password.unlink()
        with open(self.data / "postgresql.conf", "a", encoding="utf-8", newline="\n") as settings:
            settings.write(f"\nlisten_addresses = '127.0.0.1'\nport = {self.port}\n")
        edits = {"port": str(self.port), "bin_dir": self.relative(self.bin, staged),
                 "data_dir": self.relative(self.data, staged), "log_file": self.relative(self.log, staged)}
        cluster.write_text(self.point_postgres(text, edits), encoding="utf-8", newline="\n")

    @staticmethod
    def relative(path: Path, base: Path) -> str:
        return os.path.relpath(path, base).replace("\\", "/")

    @staticmethod
    def point_postgres(text: str, edits) -> str:
        """Bảng [postgres] của cluster.toml trỏ sang cụm tạm; bảng khác giữ nguyên."""
        out, inside, done = [], False, set()
        for line in text.splitlines():
            if line.startswith("["):
                inside = line.startswith("[postgres]")
            key = line.split("=", 1)[0].strip()
            if inside and key in edits:
                value = edits[key] if key == "port" else f'"{edits[key]}"'
                line = f"{key} = {value}"
                done.add(key)
            out.append(line)
        assert done == set(edits), ("cluster.toml thiếu khoá của [postgres]", sorted(set(edits) - done))
        return "\n".join(out) + "\n"

    def ctl(self, *words) -> int:
        """Chạy pg_ctl trên cụm tạm. Không nối ống: PostgreSQL do `start` sinh ra giữ đầu ghi của ống."""
        return subprocess.run([str(self.bin / "pg_ctl.exe"), *words, "-D", str(self.data)],
                              stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL).returncode

    def running(self) -> bool:
        return self.ctl("status") == 0

    def start(self) -> bool:
        return self.ctl("start", "-w", "-l", str(self.log)) == 0

    def stop(self) -> None:
        if self.running():
            self.ctl("stop", "-w", "-m", "fast")

    def drop(self) -> None:
        """Dừng cụm tạm nếu còn chạy rồi xoá dữ liệu của nó."""
        if self.missing:
            return
        self.stop()
        shutil.rmtree(self.data, ignore_errors=True)

    def log_lines(self):
        if not self.log.exists():
            return []
        return self.log.read_text(encoding="utf-8", errors="replace").splitlines()

    def show_new_log(self, mark: int):
        """Các dòng PostgreSQL ghi thêm từ mốc mark; in ra để người đọc thấy nguyên văn."""
        fresh = self.log_lines()[mark:]
        print(f"    PostgreSQL ghi thêm {len(fresh)} dòng log:")
        for line in fresh:
            print("      " + line[:150])
        return fresh


# Cụm tạm của lần chạy này; main dựng khi có phần PostgreSQL được gọi tên.
PG: TempPostgres | None = None


def is_crash_line(line: str) -> bool:
    return "was interrupted" in line or "not properly shut down" in line


def part_postgres(server: Path, config: Path):
    print("postgres: T15, giám sát tự chạy và dừng cụm PostgreSQL (cụm tạm trong cây dựng)")
    verdict(not PG.running(), "trước: cụm tạm không chạy")
    mark = len(PG.log_lines())
    run = Run(server, ["--config", str(config)], subprocess.DEVNULL)
    lines = run.rest(90)
    code = run.exit_code(90)
    verdict(texts(lines) == ["started postgres"] + START + STOP + ["stopped postgres"], "đúng 15 dòng", repr(texts(lines)))
    verdict(code == 0, "thoát 0", repr(code) + " " + repr(run.err))
    ready = [moment for text, moment in lines if is_cluster_ready(text)]
    print(f"    từ lúc chạy tới dòng ready: {ready[0] * 1000:.0f} ms" if ready else "    không có dòng ready")
    verdict(not PG.running(), "sau: cụm tạm không chạy")
    verdict(not ours(), "không còn tiến trình thienlong_*", repr(ours()))
    fresh = PG.show_new_log(mark)
    verdict(any("received fast shutdown request" in line for line in fresh), "log: dừng kiểu fast")
    verdict(any("database system is shut down" in line for line in fresh), "log: cụm đã dừng sạch")
    verdict(any(f"127.0.0.1\", port {PG.port}" in line for line in fresh), "log: chỉ nghe 127.0.0.1 ở cổng đã cấp")
    verdict(not any("listening on IPv" in line and "127.0.0.1" not in line for line in fresh),
            "log: không nghe địa chỉ nào khác")


def part_using(server: Path, config: Path):
    print("using: cụm đang chạy sẵn thì giám sát dùng và không dừng nó")
    verdict(not PG.running(), "trước: cụm tạm không chạy")
    verdict(PG.start(), "chạy sẵn cụm tạm bằng pg_ctl")
    run = Run(server, ["--config", str(config)], subprocess.DEVNULL)
    lines = run.rest(90)
    verdict(texts(lines) == ["using postgres"] + START + STOP, "using postgres rồi 13 dòng", repr(texts(lines)))
    verdict(run.exit_code(90) == 0, "thoát 0")
    verdict(PG.running(), "sau khi giám sát thoát cụm vẫn chạy")
    PG.stop()
    verdict(not PG.running(), "trả cụm tạm về trạng thái tắt")


def part_survive(server: Path, config: Path):
    print("survive: giám sát bị giết giữa chừng thì PostgreSQL nó đã chạy không bị giết theo")
    verdict(not PG.running(), "trước: cụm tạm không chạy")
    mark = len(PG.log_lines())
    run = Run(server, ["--config", str(config)], subprocess.PIPE)
    verdict(texts(run.take(8, 90)) == ["started postgres"] + START, "cụm lên tới ready")
    kill(run.proc.pid)
    verdict(wait_until(lambda: not ours(), 5), "các con thienlong_* chết theo giám sát", repr(ours()))
    time.sleep(1.0)
    verdict(PG.running(), "postgres vẫn sống")
    again = Run(server, ["--config", str(config)], subprocess.DEVNULL)
    lines = again.rest(90)
    verdict(texts(lines)[:1] == ["using postgres"], "lần chạy sau dùng cụm đang chạy", repr(texts(lines)[:2]))
    verdict(again.exit_code(90) == 0, "lần chạy sau thoát 0")
    PG.stop()
    verdict(not PG.running(), "trả cụm tạm về trạng thái tắt")
    fresh = PG.show_new_log(mark)
    verdict(not any(is_crash_line(line) for line in fresh), "log không có dấu cụm bị ngắt giữa chừng")
    verdict(sum("database system is shut down" in line for line in fresh) == 1, "log: cụm dừng sạch đúng một lần")


PARTS = {"nul": part_nul, "pipe": part_pipe, "restart": part_restart, "ceiling": part_ceiling, "kill": part_kill,
         "break": lambda server, config: part_signal(server, config, "break"),
         "ctrlc": lambda server, config: part_signal(server, config, "ctrlc"),
         "postgres": part_postgres, "using": part_using, "survive": part_survive}
DEFAULT = ["nul", "pipe", "restart", "ceiling", "kill", "break", "ctrlc"]


def main() -> int:
    bin_dir, config = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    server = bin_dir / "thienlong_server.exe"
    SCRATCH.mkdir(parents=True, exist_ok=True)
    helper = [word for word in sys.argv[3:] if word.startswith("--helper=")]
    if helper:
        run_helper(server, config, helper[0].split("=", 1)[1])
        return 0
    stray = ours()
    if stray:
        print("đang có tiến trình thienlong_* từ trước, không chạy:", stray)
        return 2
    global PG
    names = sys.argv[3:] or DEFAULT
    quiet = loopback_config(bin_dir, config)
    if any(name not in DEFAULT for name in names):
        PG = TempPostgres(config, quiet)
        if PG.missing:
            print(f"thiếu nhị phân PostgreSQL ở {PG.bin}: chạy `python TOOLS/server/setup_db.py fetch` trước")
            return 2
    try:
        for name in names:
            PARTS[name](server, quiet)
    finally:
        if PG is not None:
            PG.drop()
    print(f"kết quả: {len(FAILED)} phép kiểm hỏng" + (": " + "; ".join(FAILED) if FAILED else ""))
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
