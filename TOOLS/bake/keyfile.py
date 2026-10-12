# File khoá TLBBKEY1. Gói TLBBPAK1 không đổi.
# Không có cụm mật khẩu thì file vẫn là 32 byte thô, thienlong_seal đọc được.
# Có cụm mật khẩu thì Argon2id (crypto_pwhash) rồi XChaCha20-Poly1305 bọc 32 byte đó.
# Tham số Argon2id nằm trong file và được gắn vào dữ liệu xác thực, nên sửa ops hay
# mem làm hỏng thẻ. Mặc định là mức nhạy của libsodium (1 GiB). Thiếu bộ nhớ thì dừng,
# không tự hạ mức. Bản bytes đưa vào PyNaCl không xoá được.

from __future__ import annotations

import struct
import unicodedata
from pathlib import Path

import nacl.bindings
from nacl._sodium import ffi, lib

from errors import BakeError, Code, KdfLevel, KdfMemory, NeedPassphrase, PassphraseTooLong
from tlpak import KEY_BYTES, ensure_crypto, lock_secret, open_box, seal_box, wipe

MAGIC = b"TLBBKEY1"
VERSION = 1
SALT_BYTES = nacl.bindings.crypto_pwhash_SALTBYTES
ALG = nacl.bindings.crypto_pwhash_ALG_ARGON2ID13
OPS_MIN = nacl.bindings.crypto_pwhash_argon2id_OPSLIMIT_MIN
OPS_MODERATE = nacl.bindings.crypto_pwhash_argon2id_OPSLIMIT_MODERATE
OPS_SENSITIVE = nacl.bindings.crypto_pwhash_argon2id_OPSLIMIT_SENSITIVE
MEM_MIN = nacl.bindings.crypto_pwhash_argon2id_MEMLIMIT_MIN
MEM_MODERATE = nacl.bindings.crypto_pwhash_argon2id_MEMLIMIT_MODERATE
MEM_SENSITIVE = nacl.bindings.crypto_pwhash_argon2id_MEMLIMIT_SENSITIVE
PREFIX_BYTES = 44
NONCE_BYTES = 24
TAG_BYTES = 16
FILE_BYTES = PREFIX_BYTES + NONCE_BYTES + KEY_BYTES + TAG_BYTES
MAX_PASSPHRASE_BYTES = 4096
_SALT_AT = 28

if SALT_BYTES != 16 or not isinstance(ALG, int) or ALG > 0xFFFF:
    raise RuntimeError("libsodium Argon2id không khớp bố cục TLBBKEY1")


def limits_for_choice(choice: str | None) -> tuple[int, int]:
    if choice is None or choice == "" or choice == "sensitive":
        return OPS_SENSITIVE, MEM_SENSITIVE
    if choice == "moderate":
        return OPS_MODERATE, MEM_MODERATE
    raise KdfLevel()


def key_is_wrapped(path: Path) -> bool:
    try:
        size = path.stat().st_size
    except OSError as error:
        raise BakeError(Code.IO) from error
    if size == KEY_BYTES:
        return False
    try:
        handle = path.open("rb")
    except OSError as error:
        raise BakeError(Code.IO) from error
    try:
        magic = handle.read(len(MAGIC))
    except OSError as error:
        raise BakeError(Code.IO) from error
    finally:
        handle.close()
    return magic == MAGIC


def _limits_ok(opslimit: int, memlimit: int) -> bool:
    if opslimit < OPS_MIN or opslimit > OPS_SENSITIVE:
        return False
    if memlimit < MEM_MIN or memlimit > MEM_SENSITIVE:
        return False
    return True


def _resolve_create(opslimit: int | None, memlimit: int | None) -> tuple[int, int]:
    if opslimit is None and memlimit is None:
        opslimit = OPS_SENSITIVE
        memlimit = MEM_SENSITIVE
    elif opslimit is None or memlimit is None:
        raise BakeError(Code.CRYPTO)
    if not _limits_ok(opslimit, memlimit):
        raise BakeError(Code.CRYPTO)
    return opslimit, memlimit


def _password_buffer(passphrase: str) -> bytearray:
    if not isinstance(passphrase, str) or passphrase == "":
        raise BakeError(Code.WRONG_KEY)
    try:
        raw = unicodedata.normalize("NFC", passphrase).encode("utf-8")
    except UnicodeEncodeError as error:
        raise BakeError(Code.WRONG_KEY) from error
    if len(raw) > MAX_PASSPHRASE_BYTES:
        raise PassphraseTooLong()
    return bytearray(raw)


def _derive(password: bytearray, salt: bytes, opslimit: int, memlimit: int) -> bytearray:
    # Gọi libsodium trên bộ đệm xoá được. Chuỗi Python của cụm mật khẩu thì không xoá được.
    ensure_crypto()
    out = ffi.new("unsigned char[]", KEY_BYTES)
    result = lib.crypto_pwhash(
        out,
        KEY_BYTES,
        ffi.from_buffer(password),
        len(password),
        salt,
        opslimit,
        memlimit,
        ALG,
    )
    if result != 0:
        lib.sodium_memzero(out, KEY_BYTES)
        raise KdfMemory()
    derived = bytearray(ffi.buffer(out, KEY_BYTES))
    lib.sodium_memzero(out, KEY_BYTES)
    lock_secret(derived)
    return derived


def _prefix(opslimit: int, memlimit: int, salt: bytes) -> bytes:
    return struct.pack("<8sHHQQ16s", MAGIC, VERSION, ALG, opslimit, memlimit, salt)


def wrap_key(
    package_key: bytes | bytearray,
    passphrase: str,
    opslimit: int | None = None,
    memlimit: int | None = None,
) -> bytes:
    ensure_crypto()
    if len(package_key) != KEY_BYTES:
        raise BakeError(Code.CRYPTO)
    ops, mem = _resolve_create(opslimit, memlimit)
    password = _password_buffer(passphrase)
    salt = bytearray(nacl.bindings.randombytes(SALT_BYTES))
    lock_secret(password)
    lock_secret(salt)
    derived = bytearray()
    try:
        try:
            prefix = _prefix(ops, mem, bytes(salt))
            derived = _derive(password, bytes(salt), ops, mem)
            sealed = seal_box(bytes(derived), bytes(package_key), prefix)
        except RuntimeError as error:
            raise KdfMemory() from error
        except ValueError as error:
            raise BakeError(Code.CRYPTO) from error
    finally:
        wipe(password)
        wipe(salt)
        wipe(derived)
    if len(prefix) != PREFIX_BYTES or len(sealed) != NONCE_BYTES + KEY_BYTES + TAG_BYTES:
        raise BakeError(Code.CRYPTO)
    return prefix + sealed


def open_envelope(body: bytes, passphrase: str) -> bytearray:
    ensure_crypto()
    if len(body) != FILE_BYTES or not body.startswith(MAGIC):
        raise BakeError(Code.CORRUPT)
    version, alg, opslimit, memlimit = struct.unpack_from("<HHQQ", body, 8)
    if version != VERSION or alg != ALG:
        raise BakeError(Code.BAD_VERSION)
    if not _limits_ok(opslimit, memlimit):
        raise BakeError(Code.CORRUPT)
    if passphrase == "":
        raise NeedPassphrase()
    prefix = body[:PREFIX_BYTES]
    sealed = body[PREFIX_BYTES:]
    salt = body[_SALT_AT : _SALT_AT + SALT_BYTES]
    password = _password_buffer(passphrase)
    lock_secret(password)
    derived = bytearray()
    try:
        try:
            derived = _derive(password, salt, opslimit, memlimit)
        except RuntimeError as error:
            raise KdfMemory() from error
        except ValueError as error:
            raise BakeError(Code.CORRUPT) from error
        try:
            plain = open_box(bytes(derived), sealed, prefix)
        except BakeError as error:
            if error.code != Code.CORRUPT:
                raise
            raise BakeError(Code.WRONG_KEY) from error
    finally:
        wipe(password)
        wipe(derived)
    if len(plain) != KEY_BYTES:
        raise BakeError(Code.CORRUPT)
    key = bytearray(plain)
    lock_secret(key)
    return key
