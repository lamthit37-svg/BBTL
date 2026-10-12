# Đọc và ghi cây tệp cho niêm. Một tệp trong bộ nhớ tại một thời điểm.
# Gói ghi ra đuôi .partial rồi đổi tên. Không ghi đè khoá, gói, hay bản dở.
# File khoá 32 byte là khoá thô. File TLBBKEY1 cần cụm mật khẩu, xem keyfile.py.
# Khác gốc: thư mục bị từ chối quyền thì dừng, không bỏ qua im lặng như C++.

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from errors import BakeError, Cancelled, Code, NeedPassphrase
from keyfile import MAGIC, open_envelope, wrap_key
from paths import covers, hits_client, partial_path, path_blocks, same_place
from tlpak import (
    HEADER_BYTES,
    KEY_BYTES,
    MANIFEST_NAME,
    MAX_PLAIN,
    OVERHEAD,
    Catalog,
    Entry,
    SubKeys,
    _encode_head,
    _encode_record,
    blake16,
    derive_subkeys,
    fold_ascii,
    legal_name,
    lock_secret,
    manifest_body,
    open_catalog,
    read_named,
    read_names,
    seal_box,
    seal_chunk,
    wipe,
)


@dataclass(frozen=True)
class Saved:
    files: int
    raw_bytes: int


class FileSource:
    def __init__(self, path: Path) -> None:
        try:
            self.handle = path.open("rb")
            self.size = path.stat().st_size
        except OSError as error:
            raise BakeError(Code.IO) from error

    def read_at(self, offset: int, size: int) -> bytes:
        if offset > self.size or size > self.size - offset:
            raise BakeError(Code.CORRUPT)
        try:
            self.handle.seek(offset)
            data = self.handle.read(size)
        except OSError as error:
            raise BakeError(Code.IO) from error
        if len(data) != size:
            raise BakeError(Code.CORRUPT)
        return data

    def close(self) -> None:
        self.handle.close()

    def __enter__(self) -> FileSource:
        return self

    def __exit__(self, *exc: object) -> None:
        self.close()


class _Writer:
    def __init__(self, destination: Path, sub: SubKeys) -> None:
        self.destination = destination
        self.partial = partial_path(destination)
        self.sub = sub
        self.cursor = HEADER_BYTES
        self.entries: list[Entry] = []
        self.raw_bytes = 0
        try:
            self.handle = self.partial.open("wb")
            self.handle.write(b"\x00" * HEADER_BYTES)
        except OSError as error:
            self.abort()
            raise BakeError(Code.IO) from error

    def append(self, name: str, payload: bytes) -> None:
        chunk = seal_chunk(self.sub, name, payload)
        chunk.entry.offset = self.cursor
        try:
            self.handle.write(chunk.sealed)
        except OSError as error:
            raise BakeError(Code.IO) from error
        self.cursor += len(chunk.sealed)
        self.entries.append(chunk.entry)

    def finish(self) -> None:
        self.entries.sort(key=lambda entry: entry.name_hash)
        for index in range(1, len(self.entries)):
            if self.entries[index].name_hash == self.entries[index - 1].name_hash:
                raise BakeError(Code.DUPLICATE)
        plain = b"".join(_encode_record(entry) for entry in self.entries)
        key_check = blake16(bytes(self.sub.check), b"")
        index_size = len(plain) + OVERHEAD
        head = _encode_head(len(self.entries), self.cursor, index_size, key_check)
        sealed_index = seal_box(bytes(self.sub.index), plain, head)
        try:
            self.handle.write(sealed_index)
            self.handle.seek(0)
            self.handle.write(head)
            self.handle.flush()
            os.fsync(self.handle.fileno())
        except OSError as error:
            raise BakeError(Code.IO) from error

    def commit(self) -> None:
        try:
            self.handle.close()
            os.rename(self.partial, self.destination)
        except OSError as error:
            self.abort()
            raise BakeError(Code.IO) from error

    def abort(self) -> None:
        handle = getattr(self, "handle", None)
        if handle is not None and not handle.closed:
            handle.close()
        partial = getattr(self, "partial", None)
        if partial is not None:
            try:
                partial.unlink()
            except OSError:
                return None
        return None


def _ensure_parent(path: Path) -> None:
    parent = path.parent
    if str(parent) == "":
        return
    try:
        parent.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        raise BakeError(Code.IO) from error


def _ensure_directory(path: Path) -> None:
    try:
        path.mkdir(parents=True, exist_ok=True)
    except OSError as error:
        raise BakeError(Code.IO) from error
    if not path.is_dir():
        raise BakeError(Code.IO)


def load_key(path: Path, passphrase: str = "") -> bytearray:
    try:
        body = path.read_bytes()
    except OSError as error:
        raise BakeError(Code.IO) from error
    if len(body) == KEY_BYTES:
        key = bytearray(body)
        lock_secret(key)
        return key
    if not body.startswith(MAGIC):
        raise BakeError(Code.IO)
    if passphrase == "":
        raise NeedPassphrase()
    return open_envelope(body, passphrase)


def _write_synced(path: Path, payload: bytes) -> None:
    # FlushFileBuffers trên Windows cần quyền ghi. Mở rb rồi fsync thì bị từ chối.
    try:
        handle = path.open("wb")
    except OSError as error:
        raise BakeError(Code.IO) from error
    try:
        handle.write(payload)
        handle.flush()
        os.fsync(handle.fileno())
    except OSError as error:
        raise BakeError(Code.IO) from error
    finally:
        handle.close()


def store_key(
    key: bytes | bytearray,
    path: Path,
    passphrase: str = "",
    opslimit: int | None = None,
    memlimit: int | None = None,
) -> None:
    if len(key) != KEY_BYTES:
        raise BakeError(Code.CRYPTO)
    if hits_client(path) or hits_client(partial_path(path)):
        raise BakeError(Code.IO)
    pending = partial_path(path)
    if path_blocks(path) or path_blocks(pending):
        raise BakeError(Code.IO)
    if passphrase:
        payload = wrap_key(key, passphrase, opslimit, memlimit)
    else:
        if opslimit is not None or memlimit is not None:
            raise BakeError(Code.CRYPTO)
        payload = bytes(key)
    if path_blocks(path) or path_blocks(pending):
        raise BakeError(Code.IO)
    _ensure_parent(path)
    try:
        _write_synced(pending, payload)
        os.rename(pending, path)
    except BakeError:
        try:
            pending.unlink()
        except OSError:
            pass
        raise
    except OSError as error:
        try:
            pending.unlink()
        except OSError:
            pass
        raise BakeError(Code.IO) from error


def check_seal_paths(source: Path, destination: Path) -> None:
    try:
        linked = source.is_symlink()
        folder = source.is_dir()
    except OSError as error:
        raise BakeError(Code.IO) from error
    if linked or not folder:
        raise BakeError(Code.IO)
    pending = partial_path(destination)
    if hits_client(destination) or hits_client(pending):
        raise BakeError(Code.IO)
    if path_blocks(destination) or path_blocks(pending):
        raise BakeError(Code.IO)
    if covers(source, destination) or covers(source, pending):
        raise BakeError(Code.IO)
    _ensure_parent(destination)


def collect_names(root: Path) -> list[str]:
    names: list[str] = []
    folded: set[str] = set()
    walk_error: OSError | None = None

    def on_error(error: OSError) -> None:
        nonlocal walk_error
        walk_error = error

    for dirpath, dirnames, filenames in os.walk(root, onerror=on_error, followlinks=False):
        if walk_error is not None:
            raise BakeError(Code.IO) from walk_error
        current = Path(dirpath)
        for directory in list(dirnames):
            if (current / directory).is_symlink():
                raise BakeError(Code.IO)
        for filename in filenames:
            candidate = current / filename
            try:
                if candidate.is_symlink() or not candidate.is_file():
                    raise BakeError(Code.IO)
            except OSError as error:
                raise BakeError(Code.IO) from error
            relative = candidate.relative_to(root).as_posix()
            if not legal_name(relative):
                raise BakeError(Code.NAME)
            token = fold_ascii(relative)
            if token in folded:
                raise BakeError(Code.DUPLICATE)
            folded.add(token)
            names.append(relative)
    if walk_error is not None:
        raise BakeError(Code.IO) from walk_error
    names.sort(key=lambda name: name.encode("utf-8"))
    return names


def _read_file(path: Path) -> bytes:
    try:
        size = path.stat().st_size
    except OSError as error:
        raise BakeError(Code.IO) from error
    if size > MAX_PLAIN:
        raise BakeError(Code.TOO_LARGE)
    try:
        return path.read_bytes()
    except OSError as error:
        raise BakeError(Code.IO) from error


def seal_folder(
    key: bytes | bytearray,
    source: Path,
    destination: Path,
    stop: object | None = None,
    on_progress: object | None = None,
) -> Saved:
    check_seal_paths(source, destination)
    names = collect_names(source)
    sub = derive_subkeys(key)
    writer: _Writer | None = None
    committed = False
    try:
        writer = _Writer(destination, sub)
        total = len(names)
        for done, name in enumerate(names, start=1):
            if stop is not None and stop():
                raise Cancelled()
            payload = _read_file(source / name)
            writer.raw_bytes += len(payload)
            writer.append(name, payload)
            if on_progress is not None:
                on_progress(done, total)
        writer.append(MANIFEST_NAME, manifest_body(names))
        writer.finish()
        writer.commit()
        committed = True
        return Saved(len(names), writer.raw_bytes)
    finally:
        sub.wipe()
        if writer is not None and not committed:
            writer.abort()


def check_open_paths(package: Path, destination: Path) -> None:
    try:
        is_file = package.is_file()
    except OSError as error:
        raise BakeError(Code.IO) from error
    if not is_file:
        raise BakeError(Code.IO)
    if hits_client(destination):
        raise BakeError(Code.IO)
    if same_place(package, destination):
        raise BakeError(Code.IO)
    if path_blocks(destination) and not destination.is_dir():
        raise BakeError(Code.IO)
    _ensure_directory(destination)


def _place_of(root: Path, name: str) -> Path:
    if not legal_name(name):
        raise BakeError(Code.NAME)
    relative = Path(name)
    if relative.is_absolute():
        raise BakeError(Code.NAME)
    full = root.joinpath(*relative.parts)
    if not covers(root, full) or same_place(root, full):
        raise BakeError(Code.NAME)
    return full


def _write_fresh(path: Path, payload: bytes) -> None:
    if path_blocks(path):
        raise BakeError(Code.IO)
    _ensure_parent(path)
    pending = partial_path(path)
    try:
        _write_synced(pending, payload)
        os.rename(pending, path)
    except OSError as error:
        try:
            pending.unlink()
        except OSError:
            pass
        raise BakeError(Code.IO) from error


def _walk_saved(catalog: Catalog, view: FileSource, destination: Path | None) -> Saved:
    names = read_names(catalog, view)
    total = 0
    for name in names:
        payload = read_named(catalog, view, name)
        if destination is not None:
            _write_fresh(_place_of(destination, name), payload)
        total += len(payload)
    return Saved(len(names), total)


def open_folder(key: bytes | bytearray, package: Path, destination: Path) -> Saved:
    check_open_paths(package, destination)
    with FileSource(package) as view:
        catalog = open_catalog(key, view)
        try:
            return _walk_saved(catalog, view, destination)
        finally:
            catalog.wipe()


def verify_folder(key: bytes | bytearray, package: Path) -> Saved:
    try:
        if not package.is_file():
            raise BakeError(Code.IO)
    except OSError as error:
        raise BakeError(Code.IO) from error
    with FileSource(package) as view:
        catalog = open_catalog(key, view)
        try:
            return _walk_saved(catalog, view, None)
        finally:
            catalog.wipe()


def wipe_key(key: bytearray) -> None:
    wipe(key)
