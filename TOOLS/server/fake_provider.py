"""Nhà cung cấp thanh toán giả để thử webhook của billing (docs/SERVER-BILLING.md mục 6).

cách dùng:
  python TOOLS/server/fake_provider.py keygen <tệp khoá>
  python TOOLS/server/fake_provider.py send --port <cổng> --path /pay/alpha --key-file <tệp> --trade T1 \\
      --account 7 --points 500 --amount 50000 [--status paid] [--repeat 1] [--tamper none|body|signature|path|stale]
  python TOOLS/server/fake_provider.py storm --port <cổng> --path /pay/alpha --key-file <tệp> --orders 1000 --seed 1

Giao ước chữ ký (src/server/billing/webhook.hpp): message = "TLBBPAY1\\n" + đường dẫn + "\\n" + X-Timestamp + "\\n" +
thân; chữ ký = hex của HMAC-SHA512 rút còn 32 byte đầu, khoá 32 byte ghi bằng 64 ký tự hex trong tệp khoá.
`points` trong thân form tính theo phần mười điểm (10 = 1,0 điểm, như client 2026 hiển thị).

`storm` sinh một đợt đơn nạp tất định theo hạt giống: nạp gọi lại, báo chờ rồi báo trả, báo trả muộn bị bỏ qua,
mâu thuẫn nội dung, chữ ký sai, mốc thời gian cũ, đường dẫn lạ và kết nối đứt giữa yêu cầu. In ra JSON gồm số điểm
billing phải cộng, để so với sổ thật. Thoát 0 khi mọi phản hồi đúng như kỳ vọng.
"""
from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import random
import secrets
import socket
import sys
import time
from dataclasses import dataclass, replace
from pathlib import Path
from urllib.parse import urlencode

PREFIX = "TLBBPAY1"
KEY_BYTES = 32
SIGNATURE_BYTES = 32
TIMEOUT_SECONDS = 10.0
STALE_SECONDS = 4000
FIELD_ORDER = ("trade_no", "account", "points", "amount", "currency", "status")


@dataclass(frozen=True)
class Order:
    """Một đơn nạp như nhà cung cấp báo."""

    trade_no: str
    account: int
    points: int
    amount: int
    currency: str = "VND"
    status: str = "paid"

    def body(self) -> str:
        values = {
            "trade_no": self.trade_no,
            "account": self.account,
            "points": self.points,
            "amount": self.amount,
            "currency": self.currency,
            "status": self.status,
        }
        return urlencode([(name, values[name]) for name in FIELD_ORDER])


def sign(key: bytes, path: str, timestamp: int, body: str) -> str:
    message = f"{PREFIX}\n{path}\n{timestamp}\n{body}".encode()
    return hmac.new(key, message, hashlib.sha512).digest()[:SIGNATURE_BYTES].hex()


def load_key_text(text: str) -> bytes:
    key = bytes.fromhex(text.strip())
    if len(key) != KEY_BYTES:
        raise ValueError(f"khoá phải {KEY_BYTES} byte (64 ký tự hex)")
    return key


def load_key(path: Path) -> bytes:
    return load_key_text(path.read_text(encoding="ascii"))


def build_request(path: str, timestamp: int, signature: str, body: str) -> bytes:
    head = (
        f"POST {path} HTTP/1.1\r\nHost: billing\r\nX-Timestamp: {timestamp}\r\nX-Signature: {signature}\r\n"
        f"Content-Type: application/x-www-form-urlencoded\r\nContent-Length: {len(body.encode())}\r\n\r\n"
    )
    return head.encode() + body.encode()


def status_of(response: bytes) -> int | None:
    """Mã trạng thái trong dòng đầu của trả lời HTTP; None nếu không đọc được."""
    first = response.split(b"\r\n", 1)[0].split(b" ")
    if len(first) < 2 or not first[1].isdigit():
        return None
    return int(first[1])


def read_until_close(connection: socket.socket) -> bytes:
    chunks = []
    chunk = connection.recv(4096)
    while chunk:
        chunks.append(chunk)
        chunk = connection.recv(4096)
    return b"".join(chunks)


def exchange(host: str, port: int, raw: bytes, cut: int | None = None) -> int | None:
    """Gửi một yêu cầu (cắt giữa chừng sau `cut` byte nếu có) và trả mã HTTP; None khi không có trả lời."""
    try:
        with socket.create_connection((host, port), timeout=TIMEOUT_SECONDS) as connection:
            connection.sendall(raw if cut is None else raw[:cut])
            if cut is not None:
                return None
            return status_of(read_until_close(connection))
    except OSError:
        return None


@dataclass
class Target:
    host: str
    port: int
    path: str
    key: bytes


def deliver(target: Target, order: Order, tamper: str = "none", now: int | None = None) -> int | None:
    """Ký và gửi một đơn. tamper: none, body (đổi thân sau khi ký), signature (lật một ký tự), path (đường dẫn
    lạ), stale (mốc thời gian quá cũ), cut (đứt kết nối giữa yêu cầu)."""
    stamp = int(time.time()) if now is None else now
    if tamper == "stale":
        stamp -= STALE_SECONDS
    body = order.body()
    signature = sign(target.key, target.path, stamp, body)
    path = target.path + "/unknown" if tamper == "path" else target.path
    if tamper == "signature":
        signature = ("0" if signature[0] != "0" else "1") + signature[1:]
    if tamper == "body":
        body = body.replace("points=", "points=9")
    raw = build_request(path, stamp, signature, body)
    return exchange(target.host, target.port, raw, cut=len(raw) // 2 if tamper == "cut" else None)


@dataclass
class Plan:
    """Một bước của đợt thử: gửi `order` với cách `tamper`, kỳ vọng nhận `expect` (None: không có trả lời)."""

    order: Order
    tamper: str
    expect: int | None


@dataclass
class Expected:
    paid_orders: int = 0
    points: int = 0


def plan_order(rng: random.Random, index: int, accounts: int) -> tuple[list[Plan], Order | None]:
    """Các bước của một đơn nạp và đơn (nếu cuối cùng đã trả) mà billing phải cộng điểm."""
    order = Order(
        trade_no=f"S{index}",
        account=1 + rng.randrange(accounts),
        points=10 + rng.randrange(5000),
        amount=1000 * (10 + rng.randrange(5000)),
    )
    final = "failed" if rng.randrange(10) == 0 else "paid"
    steps: list[Plan] = []
    if rng.randrange(5) == 0:
        steps.append(Plan(replace(order, status="pending"), "none", 200))
    steps.append(Plan(replace(order, status=final), "none", 200))
    if rng.randrange(10) < 3:
        steps.append(Plan(replace(order, status=final), "none", 200))
    if rng.randrange(20) == 0:
        steps.append(Plan(replace(order, points=order.points + 1, status=final), "none", 409))
    if final == "paid" and rng.randrange(10) < 2:
        steps.append(Plan(replace(order, status="pending"), "none", 200))
    return steps, (replace(order, status="paid") if final == "paid" else None)


def plan_faults(rng: random.Random, index: int) -> list[Plan]:
    """Yêu cầu hỏng chen vào: billing phải từ chối (hoặc không trả lời) và không đổi sổ."""
    order = Order(trade_no=f"F{index}", account=1, points=777, amount=777000)
    faults: list[Plan] = []
    pick = rng.randrange(40)
    if pick == 0:
        faults.append(Plan(order, "signature", 401))
    elif pick == 1:
        faults.append(Plan(order, "stale", 401))
    elif pick == 2:
        faults.append(Plan(order, "path", 404))
    elif pick == 3:
        faults.append(Plan(order, "cut", None))
    elif pick == 4:
        faults.append(Plan(order, "body", 401))
    return faults


def run_storm(target: Target, orders: int, seed: int, accounts: int) -> dict[str, object]:
    rng = random.Random(seed)
    expected = Expected()
    answers: dict[str, int] = {}
    wrong: list[str] = []
    for index in range(1, orders + 1):
        steps, paid_order = plan_order(rng, index, accounts)
        steps.extend(plan_faults(rng, index))
        for step in steps:
            got = deliver(target, step.order, step.tamper)
            answers[str(got)] = answers.get(str(got), 0) + 1
            if got != step.expect:
                wrong.append(f"{step.order.trade_no} {step.tamper}: cần {step.expect}, được {got}")
        if paid_order is not None:
            expected.paid_orders += 1
            expected.points += paid_order.points
    return {"orders": orders, "paid_orders": expected.paid_orders, "expected_points": expected.points,
            "answers": answers, "wrong": wrong[:20], "wrong_count": len(wrong)}


def command_keygen(arguments: argparse.Namespace) -> int:
    path = Path(arguments.file)
    if path.exists():
        print(f"{path} đã có, không ghi đè", file=sys.stderr)
        return 2
    path.write_text(secrets.token_hex(KEY_BYTES) + "\n", encoding="ascii")
    path.chmod(0o600)
    print(f"đã ghi khoá {KEY_BYTES * 8} bit vào {path}")
    return 0


def target_of(arguments: argparse.Namespace) -> Target:
    return Target(arguments.host, arguments.port, arguments.path, load_key(Path(arguments.key_file)))


def command_send(arguments: argparse.Namespace) -> int:
    order = Order(arguments.trade, arguments.account, arguments.points, arguments.amount, arguments.currency,
                  arguments.status)
    target = target_of(arguments)
    last: int | None = None
    for _ in range(arguments.repeat):
        last = deliver(target, order, arguments.tamper)
        print(f"{order.trade_no} {order.status} -> {last}")
    return 0 if last is not None else 1


def command_storm(arguments: argparse.Namespace) -> int:
    report = run_storm(target_of(arguments), arguments.orders, arguments.seed, arguments.accounts)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["wrong_count"] == 0 else 1


def add_target(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--path", required=True)
    parser.add_argument("--key-file", required=True)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Nhà cung cấp thanh toán giả cho billing")
    commands = parser.add_subparsers(dest="command", required=True)
    keygen = commands.add_parser("keygen", help="sinh tệp khoá 64 ký tự hex")
    keygen.add_argument("file")
    keygen.set_defaults(run=command_keygen)
    send = commands.add_parser("send", help="gửi một đơn")
    add_target(send)
    send.add_argument("--trade", required=True)
    send.add_argument("--account", type=int, required=True)
    send.add_argument("--points", type=int, required=True)
    send.add_argument("--amount", type=int, required=True)
    send.add_argument("--currency", default="VND")
    send.add_argument("--status", default="paid", choices=["pending", "paid", "failed", "refunded"])
    send.add_argument("--repeat", type=int, default=1)
    send.add_argument("--tamper", default="none", choices=["none", "body", "signature", "path", "stale", "cut"])
    send.set_defaults(run=command_send)
    storm = commands.add_parser("storm", help="gửi một đợt đơn tất định có chèn lỗi")
    add_target(storm)
    storm.add_argument("--orders", type=int, default=1000)
    storm.add_argument("--seed", type=int, default=1)
    storm.add_argument("--accounts", type=int, default=50)
    storm.set_defaults(run=command_storm)
    return parser


def main(argv: list[str]) -> int:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[union-attr]
    arguments = build_parser().parse_args(argv)
    result: int = arguments.run(arguments)
    return result


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
