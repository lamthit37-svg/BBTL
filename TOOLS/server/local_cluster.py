#===============================================================================
#  THIENLONG  |  TOOLS
#-------------------------------------------------------------------------------
#  TỆP       : TOOLS/server/local_cluster.py
#  PHÂN HỆ   : Server / Local Cluster
#  CHUẨN     : Python 3.13
#-------------------------------------------------------------------------------
#  CHỨC NĂNG
#  - Chạy cụm máy chủ thử ở dev/server chỉ trên loopback, nền, dừng êm được
#    (start, stop, status).
#  - Không động tới config/ của git: dựng config.loopback (gate nghe 127.0.0.1,
#    bí mật khoá quyền) để khỏi tạo rule tường lửa.
#-------------------------------------------------------------------------------
#  TÁC GIẢ   : HiepHoon
#  TELEGRAM  : @Hoon9xx
#===============================================================================

"""Chạy cụm máy chủ thử ở dev/server chỉ trên loopback, nền, dừng êm được.

cách dùng: python -B TOOLS/server/local_cluster.py start|stop|status|prepare

Cụm thật nghe 0.0.0.0 theo dev/server/config/gate.toml (cho LAN); lần đầu một exe ở đường dẫn mới nghe như vậy,
Windows thêm rule tường lửa và có thể hiện hộp thoại. Lệnh này không động tới config/ của git: nó dựng
dev/server/config.loopback (bản chép, chỉ đổi hai dòng [listen] gate sang 127.0.0.1, khoá bí mật lại quyền như
setup_db.py) cạnh config/ để đường dẫn tương đối (../data, ../scenes, ../tables) vẫn đúng, rồi chạy trình giám sát với
cấu hình đó. Thư mục config.loopback sinh lại mỗi lần start và nằm trong .git/info/exclude, không vào git.

Trình giám sát dừng khi stdin của nó là ống bị đóng (process::stop_requested), nên một tiến trình giữ riêng (`hold`)
giữ ống và đóng nó khi thấy tệp dev/server/log/cluster.stop. Dòng stdout của trình giám sát ghi ở
dev/server/log/cluster_out.txt, stderr ở cluster_err.txt.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

import setup_db

PROJECT = Path(__file__).resolve().parents[2]
SERVER = PROJECT / "dev" / "server"
CONFIG = SERVER / "config"
LOOPBACK = SERVER / "config.loopback"
LOG = SERVER / "log"
STOP_FILE = LOG / "cluster.stop"
HOLDER_PID = LOG / "cluster.holder.pid"
OUT = LOG / "cluster_out.txt"
ERR = LOG / "cluster_err.txt"
EXE = SERVER / "bin" / "thienlong_server.exe"
READY_WAIT_SECONDS = 180
STOP_WAIT_SECONDS = 60
LISTEN = re.compile(r'^(game|auth)(\s*=\s*)"[0-9.]+:(\d+)"', re.MULTILINE)


class ClusterError(Exception):
    """Lỗi người dùng cần sửa; in một dòng rồi thoát 1."""


def prepare() -> None:
    """Dựng config.loopback từ config: bản chép mới, gate nghe 127.0.0.1, bí mật khoá quyền."""
    if LOOPBACK.exists():
        shutil.rmtree(LOOPBACK)
    shutil.copytree(CONFIG, LOOPBACK)
    gate = LOOPBACK / "gate.toml"
    text = gate.read_text(encoding="utf-8")
    changed, count = LISTEN.subn(lambda found: f'{found.group(1)}{found.group(2)}"127.0.0.1:{found.group(3)}"', text)
    if count != 2:
        raise ClusterError(f"gate.toml [listen]: tìm thấy {count} khoá game/auth, cần đúng 2")
    gate.write_text(changed, encoding="utf-8", newline="")
    secrets = LOOPBACK / "secrets.local.toml"
    if secrets.is_file():
        setup_db.restrict(secrets)
    exclude = PROJECT / ".git" / "info" / "exclude"
    entry = "dev/server/config.loopback/"
    if exclude.is_file() and entry not in exclude.read_text(encoding="utf-8").splitlines():
        with exclude.open("a", encoding="utf-8", newline="") as handle:
            handle.write(entry + "\n")


def is_running() -> bool:
    """Tiến trình giữ còn sống (đọc pid trong tệp, hỏi tasklist)."""
    if not HOLDER_PID.is_file():
        return False
    pid = HOLDER_PID.read_text(encoding="ascii").strip()
    done = subprocess.run(["tasklist", "/FI", f"PID eq {pid}", "/FO", "CSV", "/NH"], capture_output=True, text=True,
                          errors="replace", check=False)
    return f'"{pid}"' in done.stdout


def ready_line() -> str | None:
    """Dòng `ready` cuối của trình giám sát, nếu đã có."""
    if not OUT.is_file():
        return None
    lines = [line for line in OUT.read_text(encoding="utf-8", errors="replace").splitlines() if line.startswith("ready")]
    return lines[-1] if lines else None


def hold() -> int:
    """Chạy trình giám sát và giữ ống stdin của nó tới khi có tệp dừng hoặc nó thoát."""
    LOG.mkdir(parents=True, exist_ok=True)
    HOLDER_PID.write_text(str(os.getpid()), encoding="ascii")
    with OUT.open("wb") as out, ERR.open("wb") as err:
        child = subprocess.Popen([str(EXE), "--config", str(LOOPBACK)], stdin=subprocess.PIPE, stdout=out, stderr=err,
                                 cwd=PROJECT)
        while child.poll() is None and not STOP_FILE.exists():
            time.sleep(0.5)
        if child.poll() is None and child.stdin is not None:
            child.stdin.close()
        try:
            child.wait(timeout=STOP_WAIT_SECONDS)
        except subprocess.TimeoutExpired:
            child.kill()
            child.wait()
    HOLDER_PID.unlink(missing_ok=True)
    return 0


def start() -> int:
    if is_running():
        raise ClusterError(f"cụm đang chạy ({ready_line() or 'chưa ready'}); dừng bằng: local_cluster.py stop")
    if not EXE.is_file():
        raise ClusterError(f"chưa có {EXE.relative_to(PROJECT)}: cmake --install build/msvc-release --component server --prefix dev")
    prepare()
    LOG.mkdir(parents=True, exist_ok=True)
    STOP_FILE.unlink(missing_ok=True)
    OUT.unlink(missing_ok=True)
    flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW
    subprocess.Popen([sys.executable, "-B", str(Path(__file__).resolve()), "hold"], creationflags=flags, cwd=PROJECT,
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, close_fds=True)
    deadline = time.monotonic() + READY_WAIT_SECONDS
    while time.monotonic() < deadline:
        line = ready_line()
        if line:
            print(line)
            return 0
        if not is_running() and time.monotonic() > deadline - READY_WAIT_SECONDS + 5:
            break
        time.sleep(1)
    tail = OUT.read_text(encoding="utf-8", errors="replace")[-600:] if OUT.is_file() else ""
    raise ClusterError(f"cụm không báo ready trong {READY_WAIT_SECONDS} s; xem {OUT.name}/{ERR.name}\n{tail}")


def stop() -> int:
    if not is_running():
        print("cụm không chạy")
        return 0
    STOP_FILE.write_text("stop", encoding="ascii")
    deadline = time.monotonic() + STOP_WAIT_SECONDS + 15
    while time.monotonic() < deadline:
        if not is_running():
            STOP_FILE.unlink(missing_ok=True)
            print("đã dừng")
            return 0
        time.sleep(1)
    raise ClusterError("cụm chưa dừng sau thời hạn; xem tiến trình thienlong_* bằng tasklist")


def status() -> int:
    print(f"chạy: {'có' if is_running() else 'không'}; {ready_line() or 'chưa có dòng ready'}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Cụm máy chủ thử chỉ loopback.")
    parser.add_argument("action", choices=("start", "stop", "status", "prepare", "hold"))
    action = parser.parse_args(argv).action
    try:
        if action == "prepare":
            prepare()
            return 0
        return {"start": start, "stop": stop, "status": status, "hold": hold}[action]()
    except (ClusterError, setup_db.SetupError) as error:
        print(error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
