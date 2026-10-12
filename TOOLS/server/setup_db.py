"""Dựng cụm PostgreSQL nằm trong dev/server/ cho máy chủ thử.

Nhị phân ở dev/server/pgsql (git bỏ qua), dữ liệu ở dev/server/data/pg, mật khẩu ở
dev/server/config/secrets.local.toml (git bỏ qua). Không cài dịch vụ Windows, không cần quyền
quản trị. Địa chỉ, cổng và đường dẫn của cụm đọc từ dev/server/config/cluster.toml; tên database và
role đọc từ auth.toml, billing.toml, store.toml: một nguồn sự thật với máy chủ.

  python TOOLS/server/setup_db.py fetch [--zip <tệp>]   tải gói nhị phân, kiểm SHA-256, giải nén
  python TOOLS/server/setup_db.py init                  initdb, sinh mật khẩu, tạo role và database
  python TOOLS/server/setup_db.py start | stop | status
"""
import argparse
import hashlib
import os
import secrets
import subprocess
import sys
import tomllib
import urllib.request
import zipfile
from pathlib import Path

from config_style import render

ROOT = Path(__file__).resolve().parents[2]
SERVER = ROOT / "dev" / "server"
CONFIG = SERVER / "config"
SECRETS = CONFIG / "secrets.local.toml"

# Gói nhị phân Windows x64 của EDB. Đổi phiên bản thì đổi cả ba hằng.
PG_VERSION = "18.6-5"
PG_URL = f"https://get.enterprisedb.com/postgresql/postgresql-{PG_VERSION}-windows-x64-binaries.zip"
PG_SHA256 = "e2246ba91d22345bc3d017586c09ede52d9df180b1eeb480f050445f1cad84e2"
# Chỉ giải nén phần máy chủ cần; bỏ pgAdmin 4 (814 MB), tài liệu, header, StackBuilder.
KEEP_PREFIXES = ("pgsql/bin/", "pgsql/lib/", "pgsql/share/")
KEEP_FILES = ("pgsql/server_license.txt", "pgsql/commandlinetools_3rd_party_licenses.txt")
SERVICE_FILES = ("auth.toml", "billing.toml", "store.toml")


class SetupError(Exception):
    pass


def read_toml(path: Path) -> dict:
    try:
        with path.open("rb") as stream:
            return tomllib.load(stream)
    except FileNotFoundError as error:
        raise SetupError(f"thiếu tệp {path}") from error
    except tomllib.TOMLDecodeError as error:
        raise SetupError(f"{path}: {error}") from error


class Cluster:
    """Địa chỉ và đường dẫn của cụm, đọc từ cluster.toml."""

    def __init__(self) -> None:
        section = read_toml(CONFIG / "cluster.toml").get("postgres")
        if not isinstance(section, dict):
            raise SetupError("cluster.toml thiếu bảng [postgres]")
        try:
            self.host = str(section["host"])
            self.port = int(section["port"])
            self.bin_dir = (CONFIG / section["bin_dir"]).resolve()
            self.data_dir = (CONFIG / section["data_dir"]).resolve()
            self.log_file = (CONFIG / section["log_file"]).resolve()
        except KeyError as error:
            raise SetupError(f"cluster.toml [postgres] thiếu khoá {error}") from error
        for path in (self.bin_dir, self.data_dir, self.log_file):
            if not path.is_relative_to(SERVER):
                raise SetupError(f"{path} nằm ngoài {SERVER}")

    def tool(self, name: str) -> str:
        path = self.bin_dir / f"{name}.exe"
        if not path.is_file():
            raise SetupError(f"chưa có {path}; chạy lệnh fetch trước")
        return str(path)


def run(command: list[str], env: dict | None = None, text: str | None = None) -> str:
    """Chạy một lệnh, trả stdout; lệnh lỗi thì báo kèm stderr."""
    merged = dict(os.environ)
    merged.update(env or {})
    done = subprocess.run(command, input=text, capture_output=True, text=True, encoding="utf-8",
                          errors="replace", env=merged, check=False)
    if done.returncode != 0:
        detail = (done.stderr or done.stdout).strip()
        raise SetupError(f"{Path(command[0]).name} thoát {done.returncode}: {detail}")
    return done.stdout


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def is_kept(name: str) -> bool:
    return name.startswith(KEEP_PREFIXES) or name in KEEP_FILES


def extract_entry(bundle: zipfile.ZipFile, info: zipfile.ZipInfo, target: Path) -> None:
    """Giải nén một mục vào target; tên mục thoát khỏi thư mục đích là lỗi."""
    relative = info.filename.removeprefix("pgsql/")
    output = (target / relative).resolve()
    if not output.is_relative_to(target.resolve()):
        raise SetupError(f"mục {info.filename} thoát khỏi thư mục đích")
    output.parent.mkdir(parents=True, exist_ok=True)
    with bundle.open(info) as source, output.open("wb") as sink:
        while block := source.read(1 << 20):
            sink.write(block)


def extract(archive: Path, target: Path) -> int:
    """Giải nén các mục cần vào target, trả số tệp đã ghi."""
    with zipfile.ZipFile(archive) as bundle:
        kept = [info for info in bundle.infolist() if not info.is_dir() and is_kept(info.filename)]
        for info in kept:
            extract_entry(bundle, info, target)
    return len(kept)


def fetch(cluster: Cluster, given: Path | None) -> None:
    target = cluster.bin_dir.parent
    if (cluster.bin_dir / "postgres.exe").is_file():
        print(f"đã có {cluster.bin_dir / 'postgres.exe'}; không tải lại")
        return
    archive = given
    downloaded = False
    if archive is None:
        archive = SERVER / "data" / "download" / f"postgresql-{PG_VERSION}.zip"
        archive.parent.mkdir(parents=True, exist_ok=True)
        print(f"tải {PG_URL}")
        urllib.request.urlretrieve(PG_URL, archive)
        downloaded = True
    actual = sha256_of(archive)
    if actual != PG_SHA256:
        raise SetupError(f"SHA-256 của {archive.name} là {actual}, cần {PG_SHA256}")
    count = extract(archive, target)
    if downloaded:
        archive.unlink()
    print(f"giải nén {count} tệp vào {target}")
    print(run([cluster.tool("postgres"), "--version"]).strip())


def service_databases() -> list[tuple[str, str]]:
    """(tên database, role sở hữu) của từng dịch vụ, theo [database] trong tệp cấu hình của nó."""
    pairs = []
    for name in SERVICE_FILES:
        section = read_toml(CONFIG / name).get("database")
        if not isinstance(section, dict) or "name" not in section or "user" not in section:
            raise SetupError(f"{name} thiếu [database] name, user")
        pairs.append((str(section["name"]), str(section["user"])))
    return pairs


def load_or_create_secrets(roles: list[str]) -> dict[str, str]:
    """Mật khẩu của từng role. Tệp đã có thì dùng lại, role thiếu thì thêm; không in mật khẩu."""
    passwords: dict[str, str] = {}
    if SECRETS.is_file():
        stored = read_toml(SECRETS).get("database", {})
        passwords = {role: str(entry["password"]) for role, entry in stored.items() if entry.get("password")}
    for role in roles:
        passwords.setdefault(role, secrets.token_urlsafe(24))
    owners = {role: Path(name).stem for name, (_, role) in zip(SERVICE_FILES, service_databases())}
    sections = [("Chung", None, [], [
        ("schema", "1", "Phiên bản bố cục của tệp; bộ đọc từ chối số nó không hiểu")])]
    for role in sorted(passwords):
        if role == "postgres":
            name, about = "Role quản trị postgres", "Role toàn quyền của cụm; chỉ dùng khi dựng và sao lưu."
        elif role in owners:
            name, about = f"Role của {owners[role]}", f"Role mà tiến trình {owners[role]} dùng."
        else:
            name, about = f"Role {role}", "Role không còn dịch vụ nào khai trong tệp cấu hình."
        sections.append((name, f"[database.{role}]", [about], [
            ("password", f'"{passwords[role]}"', f"Mật khẩu của role {role}")]))
    intro = ["Tệp: secrets.local.toml. Sinh bởi TOOLS/server/setup_db.py; mỗi tiến trình chỉ đọc mục của mình.",
             "Git bỏ qua tệp này. Không chép ra ngoài máy chủ, không dán vào log hay tin nhắn."]
    text = render("BÍ MẬT CỦA MÁY CHỦ", intro, sections)
    SECRETS.write_text(text, encoding="utf-8", newline="\n")
    return passwords


def is_running(cluster: Cluster) -> bool:
    done = subprocess.run([cluster.tool("pg_ctl"), "-D", str(cluster.data_dir), "status"],
                          capture_output=True, check=False)
    return done.returncode == 0


def start(cluster: Cluster) -> None:
    if not (cluster.data_dir / "PG_VERSION").is_file():
        raise SetupError(f"chưa có cụm ở {cluster.data_dir}; chạy lệnh init trước")
    if is_running(cluster):
        print("cụm đang chạy")
        return
    cluster.log_file.parent.mkdir(parents=True, exist_ok=True)
    # pg_ctl giữ handle của stdout khi máy chủ chạy nền: không bắt output, kẻo lệnh này treo.
    done = subprocess.run([cluster.tool("pg_ctl"), "-D", str(cluster.data_dir), "-l", str(cluster.log_file),
                           "-w", "start"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
    if done.returncode != 0:
        raise SetupError(f"pg_ctl start thoát {done.returncode}; xem {cluster.log_file}")
    print(f"cụm chạy ở {cluster.host}:{cluster.port}")


def stop(cluster: Cluster) -> None:
    if not is_running(cluster):
        print("cụm không chạy")
        return
    run([cluster.tool("pg_ctl"), "-D", str(cluster.data_dir), "-m", "fast", "-w", "stop"])
    print("cụm đã dừng")


def psql(cluster: Cluster, password: str, script: str, database: str = "postgres") -> str:
    """Chạy một đoạn SQL bằng role postgres; SQL đi qua stdin nên mật khẩu không nằm trên dòng lệnh."""
    command = [cluster.tool("psql"), "-X", "-q", "-A", "-t", "-v", "ON_ERROR_STOP=1", "-h", cluster.host,
               "-p", str(cluster.port), "-U", "postgres", "-d", database, "-f", "-"]
    return run(command, env={"PGPASSWORD": password, "PGCLIENTENCODING": "UTF8"}, text=script)


def init(cluster: Cluster) -> None:
    databases = service_databases()
    roles = ["postgres"] + [role for _, role in databases]
    for name in [name for name, _ in databases] + roles:
        if not name.replace("_", "").isalnum() or not name.isascii():
            raise SetupError(f"tên {name!r} không phải định danh ASCII đơn giản")
    passwords = load_or_create_secrets(roles)
    if (cluster.data_dir / "PG_VERSION").is_file():
        print(f"đã có cụm ở {cluster.data_dir}; giữ nguyên dữ liệu")
    else:
        cluster.data_dir.parent.mkdir(parents=True, exist_ok=True)
        password_file = cluster.data_dir.parent / "pg.pwfile"
        password_file.write_text(passwords["postgres"], encoding="ascii")
        try:
            run([cluster.tool("initdb"), "-D", str(cluster.data_dir), "-U", "postgres",
                 f"--pwfile={password_file}", "-E", "UTF8", "--locale-provider=builtin",
                 "--builtin-locale=C.UTF-8", "--auth=scram-sha-256"])
        finally:
            password_file.unlink(missing_ok=True)
        settings = ["", "# Thêm bởi TOOLS/server/setup_db.py.", f"listen_addresses = '{cluster.host}'",
                    f"port = {cluster.port}", "password_encryption = 'scram-sha-256'", ""]
        with (cluster.data_dir / "postgresql.conf").open("a", encoding="utf-8", newline="\n") as stream:
            stream.write("\n".join(settings))
        print(f"khởi tạo cụm ở {cluster.data_dir}")
    start(cluster)
    existing_roles = set(psql(cluster, passwords["postgres"], "select rolname from pg_roles;").split())
    existing_databases = set(psql(cluster, passwords["postgres"], "select datname from pg_database;").split())
    for database, role in databases:
        # Mật khẩu là token_urlsafe: chỉ chữ, số, '-' và '_', không cần thoát trong chuỗi SQL.
        verb = "alter" if role in existing_roles else "create"
        psql(cluster, passwords["postgres"], f"{verb} role {role} login password '{passwords[role]}';")
        if database not in existing_databases:
            psql(cluster, passwords["postgres"],
                 f"create database {database} owner {role} template template0 encoding 'UTF8';")
        psql(cluster, passwords["postgres"], f"revoke connect on database {database} from public;")
        print(f"database {database}, role {role}: sẵn sàng")
    print(f"mật khẩu nằm ở {SECRETS.relative_to(ROOT)}")


def status(cluster: Cluster) -> None:
    if not is_running(cluster):
        print("cụm không chạy")
        return
    passwords = load_or_create_secrets([])
    if "postgres" not in passwords:
        raise SetupError(f"{SECRETS} thiếu mật khẩu của postgres")
    version = psql(cluster, passwords["postgres"], "select current_setting('server_version');").strip()
    rows = psql(cluster, passwords["postgres"],
                "select datname || ' (' || pg_get_userbyid(datdba) || ')' from pg_database "
                "where datname like 'thienlong%' order by 1;").split("\n")
    print(f"PostgreSQL {version} ở {cluster.host}:{cluster.port}")
    for row in filter(None, rows):
        print(f"  {row}")


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Dựng cụm PostgreSQL của máy chủ thử trong dev/server/.")
    commands = parser.add_subparsers(dest="command", required=True)
    fetch_parser = commands.add_parser("fetch", help="tải và giải nén gói nhị phân")
    fetch_parser.add_argument("--zip", type=Path, help="dùng tệp zip đã tải thay vì tải lại")
    for name in ("init", "start", "stop", "status"):
        commands.add_parser(name)
    arguments = parser.parse_args()
    try:
        cluster = Cluster()
        if arguments.command == "fetch":
            fetch(cluster, arguments.zip)
        elif arguments.command == "init":
            init(cluster)
        elif arguments.command == "start":
            start(cluster)
        elif arguments.command == "stop":
            stop(cluster)
        else:
            status(cluster)
    except SetupError as error:
        print(f"lỗi: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
