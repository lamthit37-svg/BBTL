"""Cấm một tài khoản do gate_attack tạo, để đo thu hồi ban sau khi đăng nhập.

Chỉ nhận tên do bộ tấn công sinh (atk + chữ thường/số). Tên đi vào psql bằng -v và :'name', không
ghép vào chuỗi SQL. Mật khẩu role postgres đọc từ secrets.local.toml trong bộ nhớ, không in ra.
Dùng: python -B Test/bench/ban_account.py <tên>
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "TOOLS" / "server"))
import setup_db  # noqa: E402


def main() -> int:
    if len(sys.argv) != 2 or not re.fullmatch(r"atk[a-z0-9]{1,40}", sys.argv[1]):
        print("tên không phải của gate_attack", file=sys.stderr)
        return 2
    cluster = setup_db.Cluster()
    stored = setup_db.read_toml(setup_db.SECRETS).get("database", {})
    password = str(stored.get("postgres", {}).get("password", ""))
    if not password:
        print("thiếu mật khẩu role postgres", file=sys.stderr)
        return 1
    database = setup_db.service_databases()[0][0]
    command = [cluster.tool("psql"), "-X", "-q", "-A", "-t", "-v", "ON_ERROR_STOP=1", "-v", f"name={sys.argv[1]}",
               "-h", cluster.host, "-p", str(cluster.port), "-U", "postgres", "-d", database, "-f", "-"]
    script = ("INSERT INTO ban (account_id, reason) SELECT id, 'gate_attack' FROM account WHERE name = :'name' "
              "RETURNING id;\n")
    out = setup_db.run(command, env={"PGPASSWORD": password, "PGCLIENTENCODING": "UTF8"}, text=script)
    rows = [line for line in out.splitlines() if line.strip()]
    print(f"ban rows={len(rows)}")
    return 0 if len(rows) == 1 else 1


if __name__ == "__main__":
    sys.exit(main())