# Gói .tlpak TLBBPAK1. Mật mã là libsodium qua PyNaCl: XChaCha20-Poly1305 IETF,
# BLAKE2b có khoá, và KDF đúng crypto_kdf_derive_from_key (ngữ cảnh "TLBBPAK_",
# salt = id khoá con little-endian, personal = "TLBBPAK_"). Không tự viết mật mã.
# Method trên đĩa luôn Stored (0). Byte mở ra trùng byte đưa vào.
# Khoá 32 byte không nằm trong client. Game không đọc gói này.
# Bọc file khoá bằng Argon2id nằm ở keyfile.py và không đổi byte của gói này.

from __future__ import annotations

import hmac
import struct
from dataclasses import dataclass

from errors import BakeError, Code

try:
    import nacl.bindings
    import nacl.encoding
    import nacl.hash
    from nacl._sodium import ffi, lib
    from nacl.exceptions import CryptoError
except ImportError as import_error:  # pragma: no cover - máy dựng đã cài PyNaCl
    nacl = None
    ffi = None
    lib = None
    CryptoError = Exception
    _IMPORT_ERROR: Exception | None = import_error
else:
    _IMPORT_ERROR = None

MANIFEST_NAME = "thienlong/manifest.txt"
KEY_BYTES = 32
HEADER_BYTES = 64
OVERHEAD = 40
RECORD_BYTES = 28
MAX_NAME = 240
MAX_PLAIN = 0xFFFFFFFF - OVERHEAD
_MAGIC = b"TLBBPAK1"
_CONTEXT = b"TLBBPAK_"
_ENTRY_ID = 1
_INDEX_ID = 2
_NAME_ID = 3
_CHECK_ID = 4


@dataclass
class Item:
    name: str
    payload: bytes


@dataclass
class Entry:
    name_hash: int
    offset: int
    sealed_size: int
    raw_size: int
    method: int


@dataclass
class Chunk:
    entry: Entry
    sealed: bytes


@dataclass
class SubKeys:
    entries: bytearray
    index: bytearray
    names: bytearray
    check: bytearray

    def wipe(self) -> None:
        wipe(self.entries)
        wipe(self.index)
        wipe(self.names)
        wipe(self.check)


@dataclass
class Catalog:
    sub: SubKeys
    entries: list[Entry]
    head: bytes

    def wipe(self) -> None:
        self.sub.wipe()


class BytesSource:
    def __init__(self, package: bytes) -> None:
        self.package = package
        self.size = len(package)

    def read_at(self, offset: int, size: int) -> bytes:
        if offset > self.size or size > self.size - offset:
            raise BakeError(Code.CORRUPT)
        return self.package[offset : offset + size]

    def close(self) -> None:
        return None


def ensure_crypto() -> None:
    if _IMPORT_ERROR is not None or lib is None:
        raise BakeError(Code.CRYPTO) from _IMPORT_ERROR
    if lib.sodium_init() < 0:
        raise BakeError(Code.CRYPTO)


def lock_secret(secret: bytearray) -> None:
    # Khoá trang để giảm khả năng bị đẩy ra file page. Thất bại thì vẫn chạy.
    if not secret or lib is None or ffi is None:
        return
    try:
        lib.sodium_mlock(ffi.from_buffer(secret), len(secret))
    except Exception:
        return


def wipe(secret: bytearray) -> None:
    # Bản bytes đưa vào PyNaCl là bất biến nên không xoá được. Bản tool giữ thì xoá.
    # sodium_munlock tự xoá rồi mở khoá trang. Trang chưa khoá thì nó vẫn xoá, trả -1.
    if not secret or lib is None or ffi is None:
        return
    try:
        locked = lib.sodium_munlock(ffi.from_buffer(secret), len(secret))
    except Exception:
        locked = -1
    if locked == 0:
        return
    try:
        lib.sodium_memzero(ffi.from_buffer(secret), len(secret))
    except Exception:
        secret[:] = bytes(len(secret))


def random_key() -> bytearray:
    ensure_crypto()
    key = bytearray(nacl.bindings.randombytes(KEY_BYTES))
    lock_secret(key)
    return key


def _derive_subkey(master: bytes, subkey_id: int) -> bytearray:
    # libsodium bọc salt 8 byte id và personal 8 byte ngữ cảnh bằng số 0 cho đủ 16.
    digest = bytearray(
        nacl.bindings.crypto_generichash_blake2b_salt_personal(
            b"",
            digest_size=32,
            key=master,
            salt=subkey_id.to_bytes(8, "little"),
            person=_CONTEXT,
        )
    )
    lock_secret(digest)
    return digest


def derive_subkeys(master: bytes | bytearray) -> SubKeys:
    ensure_crypto()
    if len(master) != KEY_BYTES:
        raise BakeError(Code.CRYPTO)
    raw = bytes(master)
    return SubKeys(
        entries=_derive_subkey(raw, _ENTRY_ID),
        index=_derive_subkey(raw, _INDEX_ID),
        names=_derive_subkey(raw, _NAME_ID),
        check=_derive_subkey(raw, _CHECK_ID),
    )


def blake16(key: bytes, message: bytes) -> bytes:
    ensure_crypto()
    return nacl.hash.blake2b(
        message,
        digest_size=16,
        key=key,
        encoder=nacl.encoding.RawEncoder,
    )


def hash_name(name_key: bytes, name: str) -> int:
    digest = blake16(name_key, name.encode("utf-8"))
    return struct.unpack_from("<Q", digest)[0]


def _segment_ok(segment: str) -> bool:
    if segment == "" or segment == "." or segment == "..":
        return False
    for unit in segment:
        code = ord(unit)
        if code < 0x20 or code == 0x7F:
            return False
        if unit in "\\:*?\"<>|":
            return False
    return True


def legal_name(name: str) -> bool:
    raw = name.encode("utf-8")
    if not raw or len(raw) > MAX_NAME:
        return False
    if name == MANIFEST_NAME:
        return False
    if name.startswith("/") or name.endswith("/"):
        return False
    return all(_segment_ok(segment) for segment in name.split("/"))


def fold_ascii(name: str) -> str:
    from paths import fold_ascii as fold_path

    return fold_path(name)


def _same16(left: bytes, right: bytes) -> bool:
    if len(left) != 16 or len(right) != 16:
        return False
    return hmac.compare_digest(left, right)


def seal_box(key: bytes, plain: bytes, extra: bytes) -> bytes:
    ensure_crypto()
    if len(plain) > MAX_PLAIN:
        raise BakeError(Code.TOO_LARGE)
    nonce = nacl.bindings.randombytes(24)
    associated = extra if extra else None
    try:
        cipher = nacl.bindings.crypto_aead_xchacha20poly1305_ietf_encrypt(
            plain, associated, nonce, key
        )
    except (CryptoError, ValueError) as error:
        raise BakeError(Code.CRYPTO) from error
    if len(cipher) != len(plain) + 16:
        raise BakeError(Code.CRYPTO)
    return nonce + cipher


def open_box(key: bytes, sealed: bytes, extra: bytes) -> bytes:
    ensure_crypto()
    if len(sealed) < OVERHEAD:
        raise BakeError(Code.CORRUPT)
    nonce = sealed[:24]
    cipher = sealed[24:]
    associated = extra if extra else None
    try:
        return nacl.bindings.crypto_aead_xchacha20poly1305_ietf_decrypt(
            cipher, associated, nonce, key
        )
    except (CryptoError, ValueError) as error:
        raise BakeError(Code.CORRUPT) from error


def seal_chunk(sub: SubKeys, name: str, payload: bytes) -> Chunk:
    if len(payload) > MAX_PLAIN:
        raise BakeError(Code.TOO_LARGE)
    name_hash = hash_name(bytes(sub.names), name)
    extra = struct.pack("<QI", name_hash, len(payload))
    sealed = seal_box(bytes(sub.entries), payload, extra)
    entry = Entry(name_hash, 0, len(sealed), len(payload), 0)
    return Chunk(entry, sealed)


def manifest_body(names: list[str]) -> bytes:
    lines = [name.encode("utf-8") + b"\n" for name in names]
    return b"".join(lines)


def _encode_head(count: int, index_offset: int, index_size: int, key_check: bytes) -> bytes:
    raw = bytearray(HEADER_BYTES)
    raw[:8] = _MAGIC
    struct.pack_into("<H", raw, 8, 1)
    struct.pack_into("<I", raw, 12, count)
    struct.pack_into("<Q", raw, 16, index_offset)
    struct.pack_into("<Q", raw, 24, index_size)
    raw[32:48] = key_check
    return bytes(raw)


def _encode_record(entry: Entry) -> bytes:
    return struct.pack(
        "<QQIIHH",
        entry.name_hash,
        entry.offset,
        entry.sealed_size,
        entry.raw_size,
        entry.method,
        0,
    )


def finish_package(sub: SubKeys, chunks: list[Chunk]) -> bytes:
    cursor = HEADER_BYTES
    body = bytearray()
    entries: list[Entry] = []
    for chunk in chunks:
        chunk.entry.offset = cursor
        cursor += len(chunk.sealed)
        body.extend(chunk.sealed)
        entries.append(chunk.entry)
    entries.sort(key=lambda entry: entry.name_hash)
    for index in range(1, len(entries)):
        if entries[index].name_hash == entries[index - 1].name_hash:
            raise BakeError(Code.DUPLICATE)
    plain = b"".join(_encode_record(entry) for entry in entries)
    key_check = blake16(bytes(sub.check), b"")
    head = _encode_head(len(entries), cursor, len(plain) + OVERHEAD, key_check)
    sealed_index = seal_box(bytes(sub.index), plain, head)
    return head + bytes(body) + sealed_index


def _check_items(items: list[Item]) -> None:
    seen: set[str] = set()
    for item in items:
        if not legal_name(item.name):
            raise BakeError(Code.NAME)
        folded = fold_ascii(item.name)
        if folded in seen:
            raise BakeError(Code.DUPLICATE)
        seen.add(folded)


def seal_items(key: bytes | bytearray, items: list[Item]) -> bytes:
    _check_items(items)
    sub = derive_subkeys(key)
    try:
        chunks = [seal_chunk(sub, item.name, item.payload) for item in items]
        names = [item.name for item in items]
        chunks.append(seal_chunk(sub, MANIFEST_NAME, manifest_body(names)))
        return finish_package(sub, chunks)
    finally:
        sub.wipe()


def _entry_inside(entry: Entry, index_offset: int) -> bool:
    if entry.method != 0 or entry.sealed_size < OVERHEAD:
        return False
    if entry.sealed_size - OVERHEAD != entry.raw_size:
        return False
    if entry.offset < HEADER_BYTES or entry.offset > index_offset:
        return False
    return entry.sealed_size <= index_offset - entry.offset


def _parse_index(plain: bytes, index_offset: int) -> list[Entry]:
    if len(plain) % RECORD_BYTES != 0:
        raise BakeError(Code.CORRUPT)
    entries: list[Entry] = []
    slots = len(plain) // RECORD_BYTES
    for slot in range(slots):
        start = slot * RECORD_BYTES
        unpacked = struct.unpack_from("<QQIIHH", plain, start)
        entry = Entry(unpacked[0], unpacked[1], unpacked[2], unpacked[3], unpacked[4])
        reserved = unpacked[5]
        if reserved != 0:
            raise BakeError(Code.CORRUPT)
        if entries and not entries[-1].name_hash < entry.name_hash:
            raise BakeError(Code.CORRUPT)
        if not _entry_inside(entry, index_offset):
            raise BakeError(Code.CORRUPT)
        entries.append(entry)
    return entries


def _load_head(view: BytesSource) -> tuple[bytes, int, int, int, bytes]:
    if view.size < HEADER_BYTES:
        raise BakeError(Code.CORRUPT)
    raw = view.read_at(0, HEADER_BYTES)
    if raw[:8] != _MAGIC:
        raise BakeError(Code.BAD_MAGIC)
    version, flags = struct.unpack_from("<HH", raw, 8)
    if version != 1 or flags != 0:
        raise BakeError(Code.BAD_VERSION)
    if raw[48:64] != b"\x00" * 16:
        raise BakeError(Code.CORRUPT)
    count, index_offset, index_size = struct.unpack_from("<IQQ", raw, 12)
    return raw, count, index_offset, index_size, raw[32:48]


def _index_fits(count: int, index_offset: int, index_size: int, file_size: int) -> bool:
    plain = count * RECORD_BYTES
    if index_size != plain + OVERHEAD:
        return False
    if index_offset < HEADER_BYTES or index_offset > file_size:
        return False
    return index_size == file_size - index_offset


def open_catalog(key: bytes | bytearray, view: BytesSource) -> Catalog:
    head, count, index_offset, index_size, key_check = _load_head(view)
    sub = derive_subkeys(key)
    try:
        expect = blake16(bytes(sub.check), b"")
        if not _same16(expect, key_check):
            raise BakeError(Code.WRONG_KEY)
        if not _index_fits(count, index_offset, index_size, view.size):
            raise BakeError(Code.CORRUPT)
        sealed = view.read_at(index_offset, index_size)
        plain = open_box(bytes(sub.index), sealed, head)
        if len(plain) != count * RECORD_BYTES:
            raise BakeError(Code.CORRUPT)
        entries = _parse_index(plain, index_offset)
        return Catalog(sub, entries, head)
    except Exception:
        sub.wipe()
        raise


def _find_entry(entries: list[Entry], name_hash: int) -> Entry | None:
    lo = 0
    hi = len(entries)
    while lo < hi:
        mid = (lo + hi) // 2
        if entries[mid].name_hash < name_hash:
            lo = mid + 1
        else:
            hi = mid
    if lo == len(entries) or entries[lo].name_hash != name_hash:
        return None
    return entries[lo]


def read_named(catalog: Catalog, view: BytesSource, name: str) -> bytes:
    name_hash = hash_name(bytes(catalog.sub.names), name)
    entry = _find_entry(catalog.entries, name_hash)
    if entry is None:
        raise BakeError(Code.MISSING)
    if entry.method != 0:
        raise BakeError(Code.CORRUPT)
    sealed = view.read_at(entry.offset, entry.sealed_size)
    if len(sealed) < OVERHEAD or len(sealed) - OVERHEAD != entry.raw_size:
        raise BakeError(Code.CORRUPT)
    extra = struct.pack("<QI", entry.name_hash, entry.raw_size)
    plain = open_box(bytes(catalog.sub.entries), sealed, extra)
    if len(plain) != entry.raw_size:
        raise BakeError(Code.CORRUPT)
    return plain


def split_lines(body: bytes) -> list[str]:
    names: list[str] = []
    seen: set[str] = set()
    cursor = 0
    size = len(body)
    while cursor < size:
        newline = body.find(b"\n", cursor)
        if newline < 0:
            raw = body[cursor:]
            cursor = size
        else:
            raw = body[cursor:newline]
            cursor = newline + 1
        try:
            line = raw.decode("utf-8")
        except UnicodeError as error:
            raise BakeError(Code.CORRUPT) from error
        if not legal_name(line):
            raise BakeError(Code.CORRUPT)
        folded = fold_ascii(line)
        if folded in seen:
            raise BakeError(Code.CORRUPT)
        seen.add(folded)
        names.append(line)
    return names


def read_names(catalog: Catalog, view: BytesSource) -> list[str]:
    body = read_named(catalog, view, MANIFEST_NAME)
    return split_lines(body)


def open_named(key: bytes | bytearray, package: bytes, name: str) -> bytes:
    view = BytesSource(package)
    catalog = open_catalog(key, view)
    try:
        return read_named(catalog, view, name)
    finally:
        catalog.wipe()


def open_all(key: bytes | bytearray, package: bytes) -> list[Item]:
    view = BytesSource(package)
    catalog = open_catalog(key, view)
    try:
        names = read_names(catalog, view)
        return [Item(name, read_named(catalog, view, name)) for name in names]
    finally:
        catalog.wipe()


def verify_count(key: bytes | bytearray, package: bytes) -> int:
    return len(open_all(key, package))
