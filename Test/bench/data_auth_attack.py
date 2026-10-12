"""Tấn công DATA/AUTH/ITEM qua IPC loopback + đọc DB (không in bí mật)."""
from __future__ import annotations

import hashlib
import os
import hmac
import socket
import struct
import sys
import time
from pathlib import Path

import nacl.bindings

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "TOOLS" / "server"))
import setup_db  # noqa: E402

IPC_KEY = ROOT / "dev" / "server" / "data" / "ipc.key"
STORE = ("127.0.0.1", 7010)
CAP_TTL = 8 * 60 * 60
findings: list[str] = []
blocked: list[str] = []


def note(ok: bool, name: str, detail: str) -> None:
    line = f"{'LO' if ok else 'CHAN'} {name}: {detail}"
    print(line, flush=True)
    (findings if ok else blocked).append(line)


def crypto_auth(message: bytes, key: bytes) -> bytes:
    return hmac.new(key, message, hashlib.sha512).digest()[:32]


def u16(n: int) -> bytes:
    return struct.pack("<H", n)


def u32(n: int) -> bytes:
    return struct.pack("<I", n)


def u64(n: int) -> bytes:
    return struct.pack("<Q", n)


def text(s: str) -> bytes:
    b = s.encode("utf-8")
    return u16(len(b)) + b


def cap_key_id(key: bytes) -> int:
    kid = struct.unpack("<I", crypto_auth(b"thienlong/cap-key-id/v1", key)[:4])[0]
    return kid or 1


def seal_cap(key: bytes, account: int, expiry: int) -> bytes:
    # Định dạng cap: id, hết hạn, key id, HMAC bằng khoá con tách miền. Ai có ipc.key vẫn dựng được:
    # chặn nằm ở quyền đọc tệp khoá, không ở định dạng.
    msg = u64(account) + u64(expiry) + u32(cap_key_id(key))
    return msg + crypto_auth(msg, crypto_auth(b"thienlong/cap-mac/v1", key))


def ipc_seal(key: bytes, plain: bytes) -> bytes:
    nonce = nacl.bindings.randombytes(24)
    cipher = nacl.bindings.crypto_aead_xchacha20poly1305_ietf_encrypt(plain, None, nonce, key)
    return nonce + cipher


def ipc_open(key: bytes, boxed: bytes) -> bytes | None:
    if len(boxed) < 40:
        return None
    nonce, cipher = boxed[:24], boxed[24:]
    try:
        return nacl.bindings.crypto_aead_xchacha20poly1305_ietf_decrypt(cipher, None, nonce, key)
    except Exception:
        return None


def exchange(port_pair: tuple[str, int], key: bytes, op: int, body: bytes, timeout: float = 3.0):
    plain = u16(op) + body
    boxed = ipc_seal(key, plain)
    wire = u32(len(boxed)) + boxed
    with socket.create_connection(port_pair, timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(wire)
        head = b""
        while len(head) < 4:
            chunk = sock.recv(4 - len(head))
            if not chunk:
                return None
            head += chunk
        size = struct.unpack("<I", head)[0]
        payload = b""
        while len(payload) < size:
            chunk = sock.recv(size - len(payload))
            if not chunk:
                return None
            payload += chunk
    opened = ipc_open(key, payload)
    if opened is None or len(opened) < 2:
        return None
    code = opened[0] | (opened[1] << 8)
    return code, opened[2:]


def pg_password() -> str:
    stored = setup_db.read_toml(setup_db.SECRETS).get("database", {})
    return str(stored.get("postgres", {}).get("password", ""))


def psql(database: str, sql: str) -> str:
    cluster = setup_db.Cluster()
    password = pg_password()
    command = [
        cluster.tool("psql"), "-X", "-q", "-A", "-t", "-v", "ON_ERROR_STOP=1",
        "-h", cluster.host, "-p", str(cluster.port), "-U", "postgres", "-d", database, "-c", sql,
    ]
    return setup_db.run(command, env={"PGPASSWORD": password, "PGCLIENTENCODING": "UTF8"})


def victim_account():
    out = psql(
        "thienlong_auth",
        "SELECT id::text || '|' || name FROM account WHERE name LIKE 'atk%' ORDER BY id DESC LIMIT 1;",
    ).strip()
    if not out or "|" not in out:
        return None
    aid, name = out.split("|", 1)
    return int(aid), name


def check_acl() -> None:
    import subprocess
    out = subprocess.check_output(["icacls", str(IPC_KEY)], text=True, errors="replace")
    # Mọi dòng quyền ngoài chủ, SYSTEM, Administrators đều là lỗ (Users, Authenticated Users, Everyone...).
    owner = os.environ.get("USERNAME", "").lower()
    loose = []
    for line in out.splitlines():
        entry = line.replace(str(IPC_KEY), "").strip()
        if ":" not in entry or entry.startswith("Successfully"):
            continue
        who = entry.split(":", 1)[0].strip()
        if who.lower().endswith("\\" + owner) or who in ("NT AUTHORITY\\SYSTEM", "BUILTIN\\Administrators"):
            continue
        loose.append(who)
    note(bool(loose), "ipc_key_acl", f"tài khoản khác có quyền trên ipc.key: {loose}" if loose else "chỉ chủ/SYSTEM/Administrators")


def main() -> int:
    key = IPC_KEY.read_bytes()
    if len(key) != 32:
        print("ipc.key sai kích thước", file=sys.stderr)
        return 1
    print("== data_auth_attack", flush=True)
    check_acl()
    victim = victim_account()
    if victim is None:
        print("WARN chưa có account atk*", flush=True)
        return 1
    aid, name = victim
    print(f"victim account_id={aid} name={name}", flush=True)

    expiry = int(time.time()) + CAP_TTL
    cap = seal_cap(key, aid, expiry)
    reply = exchange(STORE, key, 4, cap)
    if reply is None:
        note(False, "forge_list", "không reply")
    else:
        note(reply[0] == 0, "forge_list", f"List bằng cap giả account={aid} code={reply[0]} body_len={len(reply[1])}")

    flipped = bytearray(cap)
    flipped[0] ^= 1
    reply = exchange(STORE, key, 4, bytes(flipped))
    if reply is None:
        note(False, "cap_bitflip", "không reply / đóng kết nối")
    else:
        note(reply[0] == 0, "cap_bitflip", f"cap sửa bit List code={reply[0]} (LO nếu 0)")

    expired = seal_cap(key, aid, int(time.time()) - 10)
    reply = exchange(STORE, key, 4, expired)
    if reply is None:
        note(False, "cap_expired", "không reply")
    else:
        note(reply[0] == 0, "cap_expired", f"cap hết hạn code={reply[0]} (kỳ vọng 5)")

    row = psql(
        "thienlong_game_1",
        "SELECT id::text || '|' || account_id::text FROM player WHERE deleted_at IS NULL ORDER BY id DESC LIMIT 1;",
    ).strip()
    if row and "|" in row:
        cid_s, owner_s = row.split("|", 1)
        cid, owner = int(cid_s), int(owner_s)
        attacker = aid if owner != aid else aid + 99991
        body = seal_cap(key, attacker, expiry) + u64(cid)
        reply = exchange(STORE, key, 7, body)
        if reply is None:
            note(False, "enter_foreign_ipc", "không reply")
        else:
            note(reply[0] == 0, "enter_foreign_ipc", f"attacker={attacker} char={cid} owner={owner} code={reply[0]}")

    cname = f"Z{int(time.time()) % 100000}"
    body = seal_cap(key, aid, expiry) + text(cname) + bytes([1]) + u16(1) + u16(1)
    reply = exchange(STORE, key, 5, body)
    if reply is None:
        note(False, "create_on_forged_cap", "không reply")
    else:
        note(reply[0] == 0, "create_on_forged_cap", f"tạo NV name={cname} trên account={aid} code={reply[0]}")

    # Standing: hỏi auth Op 8 bằng cap giả
    reply = exchange(("127.0.0.1", 7011), key, 8, seal_cap(key, aid, expiry))
    if reply is None:
        note(False, "standing_forged", "không reply")
    else:
        note(reply[0] == 0, "standing_forged", f"Standing auth bằng cap giả code={reply[0]}")

    print(f"kq forge_lo={len(findings)} chan={len(blocked)}", flush=True)
    for line in findings:
        print("FINDING", line, flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
