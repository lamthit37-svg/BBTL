"""Thử fake_provider.py: chữ ký khớp số vàng của Test/Billing/billing_tests.cpp (webhook_signature), khung HTTP,
kiểu làm hỏng yêu cầu, và việc đợt `storm` tất định theo hạt giống."""
from __future__ import annotations

import random
import socket
import threading
import unittest
from collections.abc import Callable

import fake_provider as provider

# Cùng dữ liệu với webhook_signature: khoá 00 01 ... 1f, mốc 1.700.000.000, thân kBody.
GOLDEN_KEY = bytes(range(32))
GOLDEN_BODY = "trade_no=T1&account=7&points=500&amount=50000&currency=VND&status=paid"
GOLDEN_SIGNATURE = "22a8dbcccfdf586d9642ba24e3e12343540bfa58a3898b8bff91c7cac0e6f49b"


class OneShotServer:
    """Máy chủ giả: nhận đúng một kết nối, ghi lại byte nhận được, trả một dòng trạng thái cố định."""

    def __init__(self, answer: bytes) -> None:
        self.received = b""
        self._answer = answer
        self._listener = socket.socket()
        self._listener.bind(("127.0.0.1", 0))
        self._listener.listen(1)
        self.port: int = self._listener.getsockname()[1]
        self._thread = threading.Thread(target=self._serve)
        self._thread.start()

    def _serve(self) -> None:
        connection, _ = self._listener.accept()
        with connection:
            connection.settimeout(2.0)
            self.received = self._read(connection)
            connection.sendall(self._answer)

    @staticmethod
    def _read(connection: socket.socket) -> bytes:
        data = b""
        try:
            while b"\r\n\r\n" not in data or not data.endswith(b"paid"):
                chunk = connection.recv(4096)
                if not chunk:
                    break
                data += chunk
        except TimeoutError:
            return data
        return data

    def close(self) -> None:
        self._thread.join(timeout=5.0)
        self._listener.close()


def with_server(answer: bytes, action: Callable[[int], int | None]) -> tuple[int | None, bytes]:
    server = OneShotServer(answer)
    try:
        result = action(server.port)
    finally:
        server.close()
    return result, server.received


class SignatureTests(unittest.TestCase):
    def test_golden_signature(self) -> None:
        got = provider.sign(GOLDEN_KEY, "/hooks/alpha", 1_700_000_000, GOLDEN_BODY)
        self.assertEqual(got, GOLDEN_SIGNATURE)

    def test_each_part_is_signed(self) -> None:
        base = provider.sign(GOLDEN_KEY, "/hooks/alpha", 1_700_000_000, GOLDEN_BODY)
        self.assertNotEqual(base, provider.sign(GOLDEN_KEY, "/hooks/beta", 1_700_000_000, GOLDEN_BODY))
        self.assertNotEqual(base, provider.sign(GOLDEN_KEY, "/hooks/alpha", 1_700_000_001, GOLDEN_BODY))
        self.assertNotEqual(base, provider.sign(GOLDEN_KEY, "/hooks/alpha", 1_700_000_000, GOLDEN_BODY + "x"))
        self.assertNotEqual(base, provider.sign(bytes(32), "/hooks/alpha", 1_700_000_000, GOLDEN_BODY))

    def test_order_body_matches_golden(self) -> None:
        order = provider.Order("T1", 7, 500, 50000)
        self.assertEqual(order.body(), GOLDEN_BODY)

    def test_key_file(self) -> None:
        with self.assertRaises(ValueError):
            provider.load_key_text("00ff")
        self.assertEqual(provider.load_key_text("00" * 32 + "\n"), bytes(32))


class RequestTests(unittest.TestCase):
    def test_framing(self) -> None:
        raw = provider.build_request("/hooks/alpha", 1_700_000_000, GOLDEN_SIGNATURE, GOLDEN_BODY)
        head, _, body = raw.partition(b"\r\n\r\n")
        lines = head.split(b"\r\n")
        self.assertEqual(lines[0], b"POST /hooks/alpha HTTP/1.1")
        self.assertIn(b"X-Timestamp: 1700000000", lines)
        self.assertIn(f"X-Signature: {GOLDEN_SIGNATURE}".encode(), lines)
        self.assertIn(f"Content-Length: {len(GOLDEN_BODY)}".encode(), lines)
        self.assertEqual(body, GOLDEN_BODY.encode())

    def test_status_parse(self) -> None:
        self.assertEqual(provider.status_of(b"HTTP/1.1 409 Conflict\r\n\r\nx"), 409)
        self.assertIsNone(provider.status_of(b""))
        self.assertIsNone(provider.status_of(b"garbage"))

    def test_deliver_over_socket(self) -> None:
        def action(port: int) -> int | None:
            target = provider.Target("127.0.0.1", port, "/hooks/alpha", GOLDEN_KEY)
            return provider.deliver(target, provider.Order("T1", 7, 500, 50000), now=1_700_000_000)

        status, received = with_server(b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok", action)
        self.assertEqual(status, 200)
        self.assertIn(f"X-Signature: {GOLDEN_SIGNATURE}".encode(), received)

    def test_tamper_kinds(self) -> None:
        def run(kind: str) -> bytes:
            def action(port: int) -> int | None:
                target = provider.Target("127.0.0.1", port, "/hooks/alpha", GOLDEN_KEY)
                return provider.deliver(target, provider.Order("T1", 7, 500, 50000), kind, now=1_700_000_000)

            return with_server(b"HTTP/1.1 401 Unauthorized\r\n\r\n", action)[1]

        self.assertNotIn(GOLDEN_SIGNATURE.encode(), run("signature"))
        self.assertIn(b"POST /hooks/alpha/unknown ", run("path"))
        self.assertIn(b"X-Timestamp: 1699996000", run("stale"))
        self.assertIn(b"points=9500", run("body"))


class StormTests(unittest.TestCase):
    def test_plan_is_deterministic_and_balanced(self) -> None:
        def plan(seed: int) -> list[tuple[str, str, str, int | None]]:
            rng = random.Random(seed)
            out = []
            for index in range(1, 200):
                steps, _ = provider.plan_order(rng, index, 50)
                steps.extend(provider.plan_faults(rng, index))
                out.extend((s.order.trade_no, s.order.status, s.tamper, s.expect) for s in steps)
            return out

        self.assertEqual(plan(1), plan(1))
        self.assertNotEqual(plan(1), plan(2))
        kinds = {step[2] for step in plan(1)}
        self.assertTrue({"none", "signature", "stale", "path", "cut", "body"} <= kinds)
        expects = {step[3] for step in plan(1)}
        self.assertTrue({200, 401, 404, 409, None} <= expects)

    def test_every_paid_order_is_counted_once(self) -> None:
        rng = random.Random(5)
        paid = 0
        points = 0
        for index in range(1, 300):
            steps, owed = provider.plan_order(rng, index, 50)
            self.assertTrue(steps and steps[0].order.trade_no == f"S{index}")
            if owed is not None:
                paid += 1
                points += owed.points
                self.assertEqual(owed.status, "paid")
        self.assertTrue(0 < paid < 299)
        self.assertGreater(points, 0)


if __name__ == "__main__":
    unittest.main()
