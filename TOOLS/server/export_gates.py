"""Ghi Table/gates.tsv của client: cổng game, cổng xác thực và khoá công khai của gate để client ghim.

cách dùng: python TOOLS/server/export_gates.py [--config dev/server/config/gate.toml]
           [--assets dev/client/assets] [--host 127.0.0.1] [--area TÊN_VÙNG] [--server TÊN_MÁY_CHỦ]

Client (src/client/app/client/session/gates.hpp) chỉ nối máy chủ trong danh sách chọn máy chủ mà bảng này có dòng; máy
chủ khác dùng sổ nhân vật cục bộ. Khoá công khai là 32 byte cuối của tệp khoá danh tính (64 byte bí mật của libsodium
Ed25519: hạt giống 32 byte rồi khoá công khai 32 byte). Hai cổng đọc từ gate.toml. Vùng và tên máy chủ phải có trong
Table/login_servers.tsv; không nêu thì lấy máy chủ đầu tiên của bảng đó.
Bảng chứa khoá của máy chủ này nên không vào git: dev/client/assets đã ignore.
"""
from __future__ import annotations

import argparse
import sys
import tomllib
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
SECRET_BYTES = 64
PUBLIC_BYTES = 32
GATES_COLUMNS = ("area", "server", "host", "game_port", "auth_port", "key")
SERVER_COLUMNS = ("area", "tip", "area_recommend", "server")


class ExportError(Exception):
    """Lỗi người dùng cần sửa; in một dòng rồi thoát 1."""


def port_of(listen: dict[str, object], name: str) -> int:
    """Cổng của khoá `name` trong [listen], dạng "địa_chỉ:cổng"."""
    text = listen.get(name)
    if not isinstance(text, str) or ":" not in text:
        raise ExportError(f"gate.toml [listen] thiếu khoá {name} dạng địa_chỉ:cổng")
    port = int(text.rsplit(":", 1)[1])
    if not 1 <= port <= 65535:
        raise ExportError(f"gate.toml [listen] {name}: cổng {port} ngoài 1..65535 (cổng 0 không ghim được)")
    return port


def public_key_hex(config: Path, data: dict[str, object]) -> str:
    """Khoá công khai (hex thường) từ tệp khoá danh tính nằm cạnh cấu hình."""
    relative = data.get("identity_key_file")
    if not isinstance(relative, str):
        raise ExportError("gate.toml thiếu identity_key_file")
    key_file = (config.parent / relative).resolve()
    if not key_file.is_file():
        raise ExportError(f"chưa có khoá danh tính {key_file.name}: chạy gate một lần để nó tự sinh")
    secret = key_file.read_bytes()
    if len(secret) != SECRET_BYTES:
        raise ExportError(f"{key_file.name} có {len(secret)} byte, phải đúng {SECRET_BYTES}")
    return secret[SECRET_BYTES - PUBLIC_BYTES:].hex()


def first_server(assets: Path) -> tuple[str, str]:
    """Vùng và máy chủ đầu tiên của Table/login_servers.tsv."""
    table = assets / "Table" / "login_servers.tsv"
    if not table.is_file():
        raise ExportError(f"không thấy {table.name} trong {assets.name}/Table")
    rows = [line for line in table.read_text(encoding="utf-8").splitlines() if line and not line.startswith("#")]
    if len(rows) < 2:
        raise ExportError(f"{table.name} chưa có máy chủ nào")
    head = rows[0].split("\t")
    if tuple(head[:len(SERVER_COLUMNS)]) != SERVER_COLUMNS:
        raise ExportError(f"{table.name}: dòng tên cột không đúng {SERVER_COLUMNS}")
    cells = rows[1].split("\t")
    return cells[0], cells[3]


def write_gates(assets: Path, row: tuple[str, ...]) -> Path:
    """Ghi bảng một dòng; thư mục Table phải có sẵn."""
    folder = assets / "Table"
    if not folder.is_dir():
        raise ExportError(f"không thấy thư mục {folder}")
    target = folder / "gates.tsv"
    lines = ["\t".join(GATES_COLUMNS), "\t".join(row)]
    target.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    return target


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ghi Table/gates.tsv cho client từ cấu hình gate")
    parser.add_argument("--config", type=Path, default=PROJECT / "dev/server/config/gate.toml")
    parser.add_argument("--assets", type=Path, default=PROJECT / "dev/client/assets")
    parser.add_argument("--host", default="127.0.0.1", help="địa chỉ IPv4 client dùng để nối gate")
    parser.add_argument("--area", help="tên vùng trong login_servers.tsv")
    parser.add_argument("--server", help="tên máy chủ trong login_servers.tsv")
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> Path:
    config = args.config.resolve()
    with config.open("rb") as handle:
        data = tomllib.load(handle)
    listen = data.get("listen")
    if not isinstance(listen, dict):
        raise ExportError("gate.toml thiếu nhóm [listen]")
    area, server = first_server(args.assets)
    area = args.area or area
    server = args.server or server
    row = (area, server, args.host, str(port_of(listen, "game")), str(port_of(listen, "auth")),
           public_key_hex(config, data))
    return write_gates(args.assets, row)


def main(argv: list[str]) -> int:
    try:
        target = run(parse_args(argv))
    except ExportError as error:
        print(f"export_gates: {error}", file=sys.stderr)
        return 1
    print(f"đã ghi {target.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
