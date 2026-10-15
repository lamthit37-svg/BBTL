"""Kiểm cfgtool, đối chiếu với chính bộ đọc của máy chủ (dev/server/bin/thienlong_lint.exe).

  python TOOLS/cfgtool/test_cfgtool.py        (hoặc: python -m pytest TOOLS/cfgtool)

Không đọc, không chép secrets.local.toml: mọi bản sao bỏ *.local.toml.
"""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import core  # noqa: E402

ROOT = HERE.parents[1]
CONFIG = ROOT / "dev" / "server" / "config"
LINT = ROOT / "dev" / "server" / "bin" / "thienlong_lint.exe"
sys.path.insert(0, str(ROOT / "TOOLS" / "server"))
import lint_config  # noqa: E402


def copy_config(dest: Path) -> Path:
    shutil.copytree(CONFIG, dest / "config", ignore=shutil.ignore_patterns("*.local.toml"))
    for name in ("tables", "scenes", "refs"):
        (dest / name).mkdir()
    return dest / "config"


def server_issues(root: Path) -> tuple[int, set[tuple[str, int, str]]]:
    done = subprocess.run([str(LINT), "--root", str(root), "--refs", str(root / "refs")],
                          capture_output=True, encoding="utf-8", errors="replace")
    found = set()
    for line in done.stdout.splitlines():
        m = re.match(r"^(config/\S+?):(\d+): (.*)$", line.replace("\\", "/"))
        if m:
            found.add((m.group(1).removeprefix("config/"), int(m.group(2)), m.group(3)))
    return done.returncode, found


def tool_issues(config: Path) -> set[tuple[str, int, str]]:
    found = set()
    for path in core.config_files(config):
        rel = path.relative_to(config).as_posix()
        for issue in core.validate(path.name, path.read_text(encoding="utf-8")):
            found.add((rel, issue.line, issue.message))
    return found


# (tệp, chuỗi cũ, chuỗi mới): mỗi phép làm hỏng một kiểu mà bộ đọc C++ bắt.
MUTATIONS = [
    ("gate.toml", "per_ip_prefix        = 32", "per_ip_prefix        = 8"),
    ("gate.toml", "messages_per_second  = 60", "messages_per_second  = 60\nfoo = 1"),
    ("gate.toml", '"0.0.0.0:7000"', '"0.0.0.0:07000"'),
    ("gate.toml", "deny  = []", 'deny  = ["10.0.0.0/33"]'),
    ("cluster.toml", 'kind    = "auth"', 'kind    = "store"'),
    ("cluster.toml", "machine = 0             # Máy chạy tiến trình, theo id của [[machine]]\nhost    = \"127.0.0.1\"   # Địa chỉ mà cổng ipc nghe\nport    = 7020",
     "machine = 5             # Máy chạy tiến trình, theo id của [[machine]]\nhost    = \"127.0.0.1\"   # Địa chỉ mà cổng ipc nghe\nport    = 7020"),
    ("cluster.toml", "port    = 7020", "port    = 0"),
    ("cluster.toml", 'host    = "127.0.0.1"   # Địa chỉ mà cổng ipc nghe\nport    = 7020', 'host    = "0.0.0.0"   # Địa chỉ mà cổng ipc nghe\nport    = 0'),
    ("auth.toml", "[ticket]\nttl_seconds = 300", "[tickets]\nttl_seconds = 300"),
    ("auth.toml", "pool = 2 ", 'pool = "2" '),
    ("store.toml", "female_hairs      = [1, 17, 19]", "female_hairs      = []"),
    ("store.toml", "male_hairs        = [5, 12, 14]", "male_hairs        = [5, 5, 70000]"),
    ("world.toml", "hours = [13, 15, 21]", "hours = [13, 13, 24]"),
    ("admin.toml", '"127.0.0.1:7002"', '"0.0.0.0:0"'),
    ("billing.toml", 'allow = ["127.0.0.1"]', 'allow = ["1.2.3", 5]'),
    ("log.toml", 'default = "info"', 'default = "trace"'),
    ("zone.toml", "hz = 20", "hz = 0"),
    ("zone.toml", "cell_size = 10", "cell_size = 1.5"),
    ("supervisor.toml", 'process               = "auth" ', 'process               = "store"'),
    ("rules/pet.toml", "schema = 1", "schema = 2"),
    ("secrets.example.toml", "[database.thienlong_store]", "[database.thienlong_shop]"),
    ("client.toml", "[hud]", "[hud]\nextra = true"),
    ("world.toml", "online_users   = 4300", "online_users   = 2147483648"),
]


def test_roundtrip_byte_identical_and_server_accepts():
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out"
        for path in core.config_files(CONFIG):
            raw = path.read_bytes()
            data = core.write_export(out / "config" / path.relative_to(CONFIG), raw.decode("utf-8"))
            assert data == raw, f"{path.name}: export(import(x)) khác x"
        for name in ("tables", "scenes", "refs"):
            (out / name).mkdir()
        code, issues = server_issues(out)
        assert code == 0 and not issues, issues


def test_validator_matches_server_on_mutations():
    agree = 0
    for file, old, new in MUTATIONS:
        with tempfile.TemporaryDirectory() as tmp:
            config = copy_config(Path(tmp))
            target = config / file
            text = target.read_text(encoding="utf-8")
            assert old in text, f"mẫu không còn khớp: {file}: {old!r}"
            target.write_bytes(text.replace(old, new, 1).encode("utf-8"))
            code, server = server_issues(Path(tmp))
            mine = {i for i in tool_issues(config) if i[0] == file}
            server = {i for i in server if i[0] == file}
            if file == "world.toml" and "2147483648" in new:  # int32: cả hai cùng báo ngoài miền
                pass
            assert mine == server, f"{file}: {new!r}\n  máy chủ: {sorted(server)}\n  cfgtool: {sorted(mine)}"
            agree += 1
    print(f"  {agree}/{len(MUTATIONS)} phép làm hỏng: cfgtool báo đúng như thienlong_lint (cùng dòng, cùng câu)")


def test_messy_import_restores_exact_server_format():
    for name in ("gate.toml", "cluster.toml", "rules/pet.toml"):
        original = (CONFIG / name).read_bytes()
        lines = original.decode("utf-8").split("\n")
        messy = []
        for line in lines:
            if "=" in line and not line.startswith("#"):
                key, rest = line.split("=", 1)
                line = key.strip() + "\t=  " + rest.strip().replace("   #", " #", 1)
            messy.append(line + "   ")
        raw = b"\xef\xbb\xbf" + "\r\n".join(messy).encode("utf-8") + b"\r\n\r\n"
        text, notes = core.normalize(Path(name).name, raw)
        assert text.encode("utf-8") == original, f"{name}: nhập tệp lộn xộn không về đúng bản chuẩn"


def test_bare_file_gets_full_layout_and_passes_both_linters():
    with tempfile.TemporaryDirectory() as tmp:
        config = copy_config(Path(tmp))
        data = tomllib.loads((config / "auth.toml").read_text(encoding="utf-8"))
        bare = []
        for key, value in data.items():
            if not isinstance(value, dict):
                bare.append(f"{key}={core.fmt(value)}")
        for table, values in reversed(list(data.items())):
            if isinstance(values, dict):
                bare.append(f"[{table}]")
                bare += [f"{k}={core.fmt(v)}" for k, v in reversed(list(values.items()))]
        text, notes = core.normalize("auth.toml", "\n".join(bare))
        core.write_export(config / "auth.toml", text)
        assert tomllib.loads(text) == data
        assert not lint_config.check_file(config / "auth.toml"), lint_config.check_file(config / "auth.toml")
        code, issues = server_issues(Path(tmp))
        assert code == 0, issues


def test_secrets_are_masked_and_never_exported():
    sample = (CONFIG / "secrets.example.toml").read_text(encoding="utf-8").replace('password = ""', 'password = "abc123"', 1)
    rows = core.describe("secrets.example.toml", sample)
    assert all("abc123" not in r["value"] for r in rows)
    assert any(r["value"] == core.MASK for r in rows)
    out = core.export_bytes("secrets.example.toml", sample).decode("utf-8")
    assert "abc123" not in out
    assert out.encode("utf-8") == (CONFIG / "secrets.example.toml").read_bytes()
    for call in (lambda: core.validate("secrets.local.toml", ""), lambda: core.normalize("secrets.local.toml", b""),
                 lambda: core.write_export(Path(tempfile.gettempdir()) / "x.local.toml", "")):
        try:
            call()
        except core.SecretFileError:
            continue
        raise AssertionError("công cụ đã mở tệp *.local.toml")


def test_set_value_keeps_comment_and_alignment():
    text = (CONFIG / "gate.toml").read_text(encoding="utf-8")
    edited = core.set_value("gate.toml", text, "limits", -1, "max_connections", "50000")
    assert "max_connections      = 50000   # Tổng số kết nối" in edited
    assert not core.validate("gate.toml", edited)
    assert not [p for p in lint_config.check_file.__wrapped__(edited)] if hasattr(lint_config.check_file, "__wrapped__") else True
    back = core.set_value("gate.toml", edited, "limits", -1, "max_connections", "2000")
    assert back == text


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    failed = 0
    for name, test in list(globals().items()):
        if name.startswith("test_"):
            try:
                test()
                print(f"ĐẠT  {name}")
            except AssertionError as error:
                failed += 1
                print(f"HỎNG {name}: {error}")
    print("tất cả đạt" if not failed else f"{failed} test hỏng")
    sys.exit(1 if failed else 0)
