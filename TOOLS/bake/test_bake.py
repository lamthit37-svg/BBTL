# Kiểm gói TLBBPAK1 và cook TLA1. Byte mở ra phải trùng byte đưa vào.
# Nếu có thienlong_seal.exe thì hai chiều phải mở được gói của nhau.

from __future__ import annotations

import io
import os
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import audio_cook
import bake
import keyfile
import map_cook
import tlpak
import tree
from errors import MISMATCH_TEXT, BakeError, Code, KdfLevel, NeedPassphrase, PassphraseTooLong

def _seal_exe() -> Path:
    # THIENLONG_SEAL_EXE thắng; không đặt thì lấy bản dựng đầu tiên có sẵn. Không có bản nào thì trả đường
    # dẫn gcc-debug để lời nhắn bỏ qua nói rõ cần dựng gì.
    named = os.environ.get("THIENLONG_SEAL_EXE")
    if named:
        return Path(named)
    builds = ROOT.parents[1] / "build"
    found = [builds / name / "thienlong_seal.exe" for name in ("gcc-debug", "msvc-release", "msvc-debug")]
    existing = [path for path in found if path.is_file()]
    return existing[0] if existing else found[0]


SEAL_EXE = _seal_exe()
FIRST = "âm/một.bin"
SECOND = "CongRen_Login.mp3"


def _wav(path: Path, frames: int, rate: int, channels: int, level: int = 1000) -> None:
    count = frames * channels
    samples = struct.pack("<" + "h" * count, *([level] * count))
    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF",
        36 + len(samples),
        b"WAVE",
        b"fmt ",
        16,
        1,
        channels,
        rate,
        rate * channels * 2,
        channels * 2,
        16,
        b"data",
        len(samples),
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(header + samples)


def _pair(key: bytes | bytearray | None = None) -> tuple[bytearray, bytes]:
    if key is None:
        key = tlpak.random_key()
    items = [
        tlpak.Item(FIRST, bytes([0]) + bytes([0x11]) * 31),
        tlpak.Item(SECOND, bytes([0x22]) * 32),
    ]
    return key, tlpak.seal_items(key, items)


def _flip(package: bytes, offset: int) -> bytes:
    raw = bytearray(package)
    raw[offset] ^= 1
    return bytes(raw)


def _run_cli(args: list[str]) -> tuple[int, str, str]:
    stdout = io.StringIO()
    stderr = io.StringIO()
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = stdout
    sys.stderr = stderr
    try:
        code = bake.main(args)
    finally:
        sys.stdout = old_out
        sys.stderr = old_err
    return code, stdout.getvalue(), stderr.getvalue()


class _QuietEnv(unittest.TestCase):
    def setUp(self) -> None:
        self._saved_phrase = os.environ.pop("BAKE_PASSPHRASE", None)
        self._saved_kdf = os.environ.pop("BAKE_KDF", None)
        # Test không được dừng chờ gõ. Riêng test lời nhắc gắn lại _tty.
        self._saved_tty = bake._tty
        bake._tty = lambda: False

    def tearDown(self) -> None:
        bake._tty = self._saved_tty
        self._restore("BAKE_PASSPHRASE", self._saved_phrase)
        self._restore("BAKE_KDF", self._saved_kdf)

    @staticmethod
    def _restore(name: str, value: str | None) -> None:
        if value is None:
            os.environ.pop(name, None)
        else:
            os.environ[name] = value


class SealTests(_QuietEnv):
    def test_roundtrip_keeps_bytes(self) -> None:
        key, package = _pair()
        try:
            opened = tlpak.open_all(key, package)
        finally:
            tlpak.wipe(key)
        self.assertEqual([item.name for item in opened], [FIRST, SECOND])
        self.assertEqual(opened[0].payload[0], 0)
        self.assertEqual(opened[0].payload[1], 0x11)
        self.assertEqual(opened[1].payload, bytes([0x22]) * 32)

    def test_manifest_lists_user_names(self) -> None:
        key, package = _pair()
        try:
            body = tlpak.open_named(key, package, tlpak.MANIFEST_NAME)
        finally:
            tlpak.wipe(key)
        text = FIRST.encode("utf-8") + b"\n" + SECOND.encode("utf-8") + b"\n"
        self.assertEqual(body, text)

    def test_wrong_key_and_messages(self) -> None:
        key, package = _pair()
        other = tlpak.random_key()
        try:
            with self.assertRaises(BakeError) as caught:
                tlpak.open_all(other, package)
            self.assertEqual(caught.exception.code, Code.WRONG_KEY)
            self.assertEqual(str(caught.exception), "sai khoá")
            self.assertEqual(str(BakeError(Code.BAD_MAGIC)), "không phải gói TLBBPAK1")
        finally:
            tlpak.wipe(key)
            tlpak.wipe(other)

    def test_flipped_ciphertext_stops_that_item(self) -> None:
        key, package = _pair()
        broken = _flip(package, 100)
        try:
            with self.assertRaises(BakeError) as first:
                tlpak.open_named(key, broken, FIRST)
            self.assertEqual(first.exception.code, Code.CORRUPT)
            with self.assertRaises(BakeError) as verified:
                tlpak.verify_count(key, broken)
            self.assertEqual(verified.exception.code, Code.CORRUPT)
            second = tlpak.open_named(key, broken, SECOND)
            self.assertEqual(second, bytes([0x22]) * 32)
        finally:
            tlpak.wipe(key)

    def test_header_damage(self) -> None:
        key, package = _pair()
        try:
            with self.assertRaises(BakeError) as wrong:
                tlpak.open_all(key, _flip(package, 32))
            self.assertEqual(wrong.exception.code, Code.WRONG_KEY)
            with self.assertRaises(BakeError) as magic:
                tlpak.open_all(key, _flip(package, 0))
            self.assertEqual(magic.exception.code, Code.BAD_MAGIC)
            with self.assertRaises(BakeError) as version:
                tlpak.open_all(key, _flip(package, 8))
            self.assertEqual(version.exception.code, Code.BAD_VERSION)
            with self.assertRaises(BakeError) as flags:
                tlpak.open_all(key, _flip(package, 10))
            self.assertEqual(flags.exception.code, Code.BAD_VERSION)
            with self.assertRaises(BakeError) as reserved:
                tlpak.open_all(key, _flip(package, 48))
            self.assertEqual(reserved.exception.code, Code.CORRUPT)
            with self.assertRaises(BakeError) as short_head:
                tlpak.open_all(key, package[:60])
            self.assertEqual(short_head.exception.code, Code.CORRUPT)
            with self.assertRaises(BakeError) as short_tail:
                tlpak.open_all(key, package[:-1])
            self.assertEqual(short_tail.exception.code, Code.CORRUPT)
            with self.assertRaises(BakeError) as missing:
                tlpak.open_named(key, package, "không-có.bin")
            self.assertEqual(missing.exception.code, Code.MISSING)
        finally:
            tlpak.wipe(key)

    def test_rejected_names_and_duplicate_fold(self) -> None:
        key = tlpak.random_key()
        try:
            for name in ("..", tlpak.MANIFEST_NAME, "a/../b", "", "/a", "a\\b"):
                with self.assertRaises(BakeError) as caught:
                    tlpak.seal_items(key, [tlpak.Item(name, b"x")])
                self.assertEqual(caught.exception.code, Code.NAME, name)
            with self.assertRaises(BakeError) as duplicate:
                tlpak.seal_items(key, [tlpak.Item("A.wav", b"a"), tlpak.Item("a.wav", b"b")])
            self.assertEqual(duplicate.exception.code, Code.DUPLICATE)
        finally:
            tlpak.wipe(key)

    def test_empty_package(self) -> None:
        key = tlpak.random_key()
        try:
            package = tlpak.seal_items(key, [])
            self.assertTrue(package.startswith(b"TLBBPAK1"))
            self.assertEqual(tlpak.open_all(key, package), [])
            self.assertEqual(tlpak.verify_count(key, package), 0)
            self.assertEqual(tlpak.open_named(key, package, tlpak.MANIFEST_NAME), b"")
        finally:
            tlpak.wipe(key)

    def test_nonzero_method_and_crafted_manifest(self) -> None:
        key = tlpak.random_key()
        sub = tlpak.derive_subkeys(key)
        try:
            chunk = tlpak.seal_chunk(sub, "a.bin", b"abc")
            chunk.entry.method = 1
            package = tlpak.finish_package(sub, [chunk])
            with self.assertRaises(BakeError) as method:
                tlpak.open_all(key, package)
            self.assertEqual(method.exception.code, Code.CORRUPT)
            manifest = tlpak.seal_chunk(sub, tlpak.MANIFEST_NAME, "../thoat.bin\n".encode("utf-8"))
            crafted = tlpak.finish_package(sub, [manifest])
            with self.assertRaises(BakeError) as lines:
                tlpak.open_all(key, crafted)
            self.assertEqual(lines.exception.code, Code.CORRUPT)
        finally:
            sub.wipe()
            tlpak.wipe(key)

    def test_directory_roundtrip_and_refusal(self) -> None:
        with tempfile.TemporaryDirectory(prefix="thienlong-bake-") as folder:
            root = Path(folder)
            source = root / "nguồn"
            nested = source / "thử-âm"
            nested.mkdir(parents=True)
            (nested / "dữ.liệu").write_bytes(bytes([0, 0xFF, 0x10]))
            (source / "CongRen_Login.mp3").write_bytes(bytes([0x7F]))
            (source / "trống.bin").write_bytes(b"")
            key_path = root / "khoa.bin"
            code = bake.main(["new-key", "--out", str(key_path)])
            self.assertEqual(code, 0)
            self.assertEqual(key_path.stat().st_size, 32)
            self.assertEqual(bake.main(["new-key", "--out", str(key_path)]), 1)
            key_path.write_bytes(b"short")
            self.assertEqual(bake.main(["verify", "--key", str(key_path), "--from", str(root / "no.tlpak")]), 1)
            key_path.unlink()
            key = tlpak.random_key()
            try:
                tree.store_key(key, key_path)
                package = root / "gói.tlpak"
                saved = tree.seal_folder(key, source, package)
                self.assertEqual(saved.files, 3)
                self.assertEqual(saved.raw_bytes, 4)
                opened = root / "ra"
                extracted = tree.open_folder(key, package, opened)
                self.assertEqual(extracted.files, 3)
                self.assertEqual((opened / "thử-âm" / "dữ.liệu").read_bytes(), bytes([0, 0xFF, 0x10]))
                self.assertEqual((opened / "CongRen_Login.mp3").read_bytes(), bytes([0x7F]))
                self.assertEqual((opened / "trống.bin").read_bytes(), b"")
                verified = tree.verify_folder(key, package)
                self.assertEqual((verified.files, verified.raw_bytes), (3, 4))
                with self.assertRaises(BakeError) as again:
                    tree.open_folder(key, package, opened)
                self.assertEqual(again.exception.code, Code.IO)
            finally:
                tlpak.wipe(key)
            inside = source / "out.tlpak"
            fresh = tlpak.random_key()
            try:
                with self.assertRaises(BakeError) as nested_out:
                    tree.seal_folder(fresh, source, inside)
                self.assertEqual(nested_out.exception.code, Code.IO)
                self.assertFalse((source / "out.tlpak.partial").exists())
                client = root / "thienlong" / "client" / "out.tlpak"
                with self.assertRaises(BakeError) as blocked:
                    tree.seal_folder(fresh, source, client)
                self.assertEqual(blocked.exception.code, Code.IO)
                self.assertFalse(client.exists())
                marked = root / "thienlong" / "client" / "data"
                marked.mkdir(parents=True)
                (marked / "a.bin").write_bytes(b"\x02")
                safe = root / "safe.tlpak"
                sealed = tree.seal_folder(fresh, marked, safe)
                self.assertEqual(sealed.files, 1)
            finally:
                tlpak.wipe(fresh)

    def test_directory_symlink_is_refused(self) -> None:
        with tempfile.TemporaryDirectory(prefix="thienlong-link-") as folder:
            root = Path(folder)
            source = root / "src"
            source.mkdir()
            (source / "a.bin").write_bytes(b"\x01")
            try:
                os.symlink(source / "a.bin", source / "alias.bin")
            except OSError as error:
                self.skipTest(str(error))
            key = tlpak.random_key()
            try:
                with self.assertRaises(BakeError) as caught:
                    tree.seal_folder(key, source, root / "out.tlpak")
                self.assertEqual(caught.exception.code, Code.IO)
                self.assertFalse((root / "out.tlpak").exists())
                self.assertFalse((root / "out.tlpak.partial").exists())
            finally:
                tlpak.wipe(key)

    def test_cli_usage(self) -> None:
        code, _out, err = _run_cli(["--headless"])
        self.assertEqual(code, 2)
        self.assertIn("Argon2id", err)
        self.assertIn("Ảnh chụp GPU", err)
        self.assertIn("Không đưa cụm mật khẩu lên dòng lệnh", err)
        self.assertEqual(bake.main(["không-có"]), 2)
        self.assertEqual(bake.main(["seal", "--out", "a.tlpak"]), 2)
        self.assertEqual(bake.main(["new-key", "--out", "a.bin", "--passphrase", "khong"]), 2)


class AudioTests(unittest.TestCase):
    def test_kaiser_keeps_level(self) -> None:
        import kaiser
        import numpy as np

        frames = 1000
        source = np.full((frames, 1), np.float32(1000 / 32768), dtype=np.float32)
        converted = kaiser.resample(source, 22050, 48000)
        self.assertGreater(converted.shape[0], 1500)
        self.assertLess(converted.shape[0], 3000)
        self.assertAlmostEqual(float(converted.mean()), 1000 / 32768, places=3)

    def test_classify(self) -> None:
        self.assertEqual(audio_cook.classify("music/a.wav"), "music")
        self.assertEqual(audio_cook.classify("ambience/a.wav"), "ambience")
        self.assertEqual(audio_cook.classify("Dial_01.wav"), "voice")
        self.assertEqual(audio_cook.classify("ui/click.wav"), "effect")

    def test_pcm_opus_copy_and_skip(self) -> None:
        with tempfile.TemporaryDirectory(prefix="thienlong-audio-") as folder:
            root = Path(folder)
            source = root / "sound"
            _wav(source / "click.wav", 1000, 48000, 1)
            _wav(source / "music" / "loop.wav", 19201, 48000, 1)
            _wav(source / "low.wav", 1000, 22050, 1)
            note = "giữ nguyên\n".encode("utf-8")
            (source / "notes.txt").write_bytes(note)
            destination = root / "cooked"
            notes: list[str] = []
            report = audio_cook.cook_tree(source, destination, on_error=notes.append, workers=2)
            self.assertEqual(notes, [])
            self.assertEqual(report.failed, 0)
            self.assertEqual(report.copied, 1)
            self.assertEqual(report.pcm, 2)
            self.assertEqual(report.opus, 1)
            self.assertEqual((destination / "notes.txt").read_bytes(), note)
            pcm = (destination / "click.tla").read_bytes()
            self.assertTrue(pcm.startswith(b"TLA1"))
            header = struct.unpack_from("<4sBBHIIIHH", pcm, 0)
            self.assertEqual(header[1], 0)
            self.assertEqual(header[2], 1)
            self.assertEqual(header[4], 48000)
            self.assertEqual(header[5], 1000)
            self.assertEqual(header[6], 0)
            self.assertEqual(pcm[24:], struct.pack("<1000h", *([1000] * 1000)))
            opus = (destination / "music" / "loop.tla").read_bytes()
            opus_head = struct.unpack_from("<4sBBHIIIHH", opus, 0)
            self.assertEqual(opus_head[1], 1)
            self.assertEqual(opus_head[4], 48000)
            self.assertEqual(opus_head[5], 19201)
            self.assertGreaterEqual(opus_head[3], 3840)
            self.assertEqual(opus_head[7], 960)
            self.assertEqual(opus_head[8], 0)
            count = opus_head[6]
            sizes = struct.unpack_from("<" + "H" * count, opus, 24)
            self.assertTrue(all(size > 0 for size in sizes))
            self.assertEqual(sum(sizes), len(opus) - 24 - count * 2)
            self._decode_opus(opus, count, sizes)
            low = (destination / "low.tla").read_bytes()
            low_head = struct.unpack_from("<4sBBHIIIHH", low, 0)
            self.assertEqual(low_head[1], 0)
            self.assertEqual(low_head[4], 48000)
            self.assertGreater(low_head[5], 1500)
            self.assertLess(low_head[5], 3000)
            low_samples = struct.unpack_from("<" + "h" * low_head[5], low, 24)
            low_mean = sum(low_samples) / len(low_samples)
            self.assertGreater(low_mean, 900)
            self.assertLess(low_mean, 1100)
            key = tlpak.random_key()
            try:
                sealed = tlpak.seal_items(key, [tlpak.Item("click.tla", pcm)])
                opened = tlpak.open_all(key, sealed)
                self.assertEqual(opened[0].payload, pcm)
            finally:
                tlpak.wipe(key)
            again = audio_cook.cook_tree(source, destination, on_error=notes.append, workers=1)
            self.assertEqual(again.skipped, 4)
            self.assertEqual(again.pcm, 0)
            self.assertEqual(again.failed, 0)

    def _decode_opus(self, blob: bytes, count: int, sizes: tuple[int, ...]) -> None:
        context = av_decoder()
        offset = 24 + count * 2
        for size in sizes:
            packet = blob[offset : offset + size]
            offset += size
            frames = context.decode(av_packet(packet))
            self.assertTrue(frames)
            self.assertEqual(frames[0].samples, 960)

    def test_refuse_inplace_and_client(self) -> None:
        with tempfile.TemporaryDirectory(prefix="thienlong-audio-") as folder:
            root = Path(folder)
            source = root / "sound"
            _wav(source / "click.wav", 200, 48000, 1)
            with self.assertRaises(audio_cook.CookRefusal):
                audio_cook.cook_tree(source, source)
            self.assertFalse((source / "click.tla").exists())
            client = root / "thienlong" / "client" / "out"
            with self.assertRaises(audio_cook.CookRefusal) as blocked:
                audio_cook.cook_tree(source, client)
            self.assertIn("client", str(blocked.exception))
            self.assertFalse(client.exists())
            empty = root / "trống"
            empty.mkdir()
            with self.assertRaises(audio_cook.CookRefusal) as missing:
                audio_cook.cook_tree(empty, root / "ra")
            self.assertIn("không thấy tệp nào", str(missing.exception))

    def test_symlink_is_an_error(self) -> None:
        with tempfile.TemporaryDirectory(prefix="thienlong-link-") as folder:
            root = Path(folder)
            source = root / "sound"
            _wav(source / "click.wav", 100, 48000, 1)
            link = source / "alias.wav"
            try:
                os.symlink(source / "click.wav", link)
            except OSError as error:
                self.skipTest(str(error))
            notes: list[str] = []
            report = audio_cook.cook_tree(source, root / "ra", on_error=notes.append, workers=1)
            self.assertEqual(report.failed, 1)
            self.assertEqual(report.pcm, 1)
            self.assertTrue(any("liên kết" in line for line in notes))
            self.assertFalse((root / "ra" / "alias.tla").exists())


def av_decoder():
    import av

    context = av.CodecContext.create("libopus", "r")
    context.sample_rate = 48000
    context.layout = "mono"
    context.format = "fltp"
    context.open()
    return context


def av_packet(payload: bytes):
    import av

    return av.Packet(payload)


class InteropTests(_QuietEnv):
    def test_cpp_and_python_open_each_other(self) -> None:
        if not SEAL_EXE.is_file():
            self.skipTest(f"không có {SEAL_EXE}")
        with tempfile.TemporaryDirectory(prefix="thienlong-interop-") as folder:
            root = Path(folder)
            source = root / "src"
            (source / "thử-âm").mkdir(parents=True)
            (source / "thử-âm" / "dữ.liệu").write_bytes(bytes([0, 0x11]))
            (source / "CongRen_Login.mp3").write_bytes(b"\x22")
            key = root / "khoa.bin"
            package = root / "py.tlpak"
            opened = root / "ra"
            self.assertEqual(bake.main(["new-key", "--out", str(key)]), 0)
            self.assertEqual(
                bake.main(["seal", "--key", str(key), "--from", str(source), "--out", str(package)]),
                0,
            )
            opened_by_cpp = root / "cpp-ra"
            result = subprocess.run(
                [str(SEAL_EXE), "open", "--key", str(key), "--from", str(package), "--out", str(opened_by_cpp)],
                capture_output=True,
                text=True,
                encoding="utf-8",
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((opened_by_cpp / "thử-âm" / "dữ.liệu").read_bytes(), bytes([0, 0x11]))
            self.assertEqual((opened_by_cpp / "CongRen_Login.mp3").read_bytes(), b"\x22")
            cpp_key = root / "cpp.key"
            cpp_pack = root / "cpp.tlpak"
            made = subprocess.run(
                [str(SEAL_EXE), "new-key", "--out", str(cpp_key)],
                capture_output=True,
                text=True,
                encoding="utf-8",
            )
            self.assertEqual(made.returncode, 0, made.stderr)
            sealed = subprocess.run(
                [str(SEAL_EXE), "seal", "--key", str(cpp_key), "--from", str(source), "--out", str(cpp_pack)],
                capture_output=True,
                text=True,
                encoding="utf-8",
            )
            self.assertEqual(sealed.returncode, 0, sealed.stderr)
            self.assertEqual(
                bake.main(["open", "--key", str(cpp_key), "--from", str(cpp_pack), "--out", str(opened)]),
                0,
            )
            self.assertEqual((opened / "thử-âm" / "dữ.liệu").read_bytes(), bytes([0, 0x11]))
            self.assertEqual((opened / "CongRen_Login.mp3").read_bytes(), b"\x22")


class EnvelopeTests(_QuietEnv):
    def test_min_envelope_roundtrip_and_refusal(self) -> None:
        phrase = "đúng-cụm"
        key = tlpak.random_key()
        try:
            with tempfile.TemporaryDirectory(prefix="thienlong-key-") as folder:
                root = Path(folder)
                path = root / "khoa.bin"
                tree.store_key(key, path, phrase, keyfile.OPS_MIN, keyfile.MEM_MIN)
                body = path.read_bytes()
                self.assertEqual(len(body), keyfile.FILE_BYTES)
                self.assertEqual(keyfile.FILE_BYTES, 116)
                self.assertTrue(body.startswith(keyfile.MAGIC))
                self.assertNotIn(bytes(key), body)
                again = keyfile.wrap_key(key, phrase, keyfile.OPS_MIN, keyfile.MEM_MIN)
                self.assertNotEqual(again, body)
                self.assertEqual(bytes(keyfile.open_envelope(again, phrase)), bytes(key))
                with self.assertRaises(NeedPassphrase):
                    tree.load_key(path)
                with self.assertRaises(BakeError) as wrong:
                    tree.load_key(path, "sai-cụm")
                self.assertEqual(wrong.exception.code, Code.WRONG_KEY)
                opened = tree.load_key(path, phrase)
                try:
                    self.assertEqual(bytes(opened), bytes(key))
                finally:
                    tlpak.wipe(opened)
                with self.assertRaises(PassphraseTooLong):
                    keyfile.wrap_key(key, "a" * 4097, keyfile.OPS_MIN, keyfile.MEM_MIN)
                nfc_path = root / "nfc.bin"
                tree.store_key(key, nfc_path, "e\u0301", keyfile.OPS_MIN, keyfile.MEM_MIN)
                nfc = tree.load_key(nfc_path, "\u00e9")
                try:
                    self.assertEqual(bytes(nfc), bytes(key))
                finally:
                    tlpak.wipe(nfc)
                broken = bytearray(body)
                broken[8] ^= 1
                with self.assertRaises(BakeError) as version:
                    keyfile.open_envelope(bytes(broken), phrase)
                self.assertEqual(version.exception.code, Code.BAD_VERSION)
                broken = bytearray(body)
                broken[10] ^= 1
                with self.assertRaises(BakeError) as alg:
                    keyfile.open_envelope(bytes(broken), phrase)
                self.assertEqual(alg.exception.code, Code.BAD_VERSION)
                broken = bytearray(body)
                broken[12:20] = bytes(8)
                with self.assertRaises(BakeError) as ops:
                    keyfile.open_envelope(bytes(broken), phrase)
                self.assertEqual(ops.exception.code, Code.CORRUPT)
                broken = bytearray(body)
                broken[20:28] = b"\xff" * 8
                with self.assertRaises(BakeError) as mem:
                    keyfile.open_envelope(bytes(broken), phrase)
                self.assertEqual(mem.exception.code, Code.CORRUPT)
                with self.assertRaises(BakeError) as tag:
                    keyfile.open_envelope(_flip(body, len(body) - 1), phrase)
                self.assertEqual(tag.exception.code, Code.WRONG_KEY)
                (root / "ngan.bin").write_bytes(b"short")
                with self.assertRaises(BakeError) as short:
                    tree.load_key(root / "ngan.bin", phrase)
                self.assertEqual(short.exception.code, Code.IO)
                (root / "cut.bin").write_bytes(keyfile.MAGIC + b"\x00" * 20)
                with self.assertRaises(BakeError) as cut:
                    tree.load_key(root / "cut.bin", phrase)
                self.assertEqual(cut.exception.code, Code.CORRUPT)
                raw_path = root / "tho.bin"
                tree.store_key(key, raw_path)
                self.assertEqual(raw_path.stat().st_size, 32)
                raw = tree.load_key(raw_path, "bỏ qua")
                try:
                    self.assertEqual(bytes(raw), bytes(key))
                finally:
                    tlpak.wipe(raw)
                source = root / "src"
                source.mkdir()
                (source / "a.bin").write_bytes(b"\x01\x00")
                package = root / "goi.tlpak"
                saved = tree.seal_folder(key, source, package)
                self.assertEqual((saved.files, saved.raw_bytes), (1, 2))
                self.assertTrue(package.read_bytes().startswith(b"TLBBPAK1"))
                os.environ["BAKE_PASSPHRASE"] = phrase
                code, out, err = _run_cli(["verify", "--key", str(path), "--from", str(package)])
                self.assertEqual(code, 0, err)
                self.assertIn("gói nguyên, 1 tệp, 2 byte", out)
                os.environ.pop("BAKE_PASSPHRASE")
                code, _out, err = _run_cli(["verify", "--key", str(path), "--from", str(package)])
                self.assertEqual(code, 1)
                self.assertIn("Cần cụm mật khẩu", err)
                os.environ["BAKE_PASSPHRASE"] = "sai"
                code, _out, err = _run_cli(["open", "--key", str(path), "--from", str(package), "--out", str(root / "ra")])
                self.assertEqual(code, 1)
                self.assertIn("sai khoá", err)
                self.assertFalse((root / "ra").exists())
        finally:
            tlpak.wipe(key)

    def test_default_sensitive_and_moderate(self) -> None:
        key = tlpak.random_key()
        try:
            with tempfile.TemporaryDirectory(prefix="thienlong-kdf-") as folder:
                root = Path(folder)
                high = root / "cao.bin"
                tree.store_key(key, high, "mức-cao")
                body = high.read_bytes()
                ops, mem = struct.unpack_from("<QQ", body, 12)
                self.assertEqual((ops, mem), (keyfile.OPS_SENSITIVE, keyfile.MEM_SENSITIVE))
                opened = tree.load_key(high, "mức-cao")
                try:
                    self.assertEqual(bytes(opened), bytes(key))
                finally:
                    tlpak.wipe(opened)
                os.environ["BAKE_KDF"] = "moderate"
                os.environ["BAKE_PASSPHRASE"] = "mức-vừa"
                mid = root / "vua.bin"
                code, out, err = _run_cli(["new-key", "--out", str(mid)])
                self.assertEqual(code, 0, err)
                self.assertIn("Chép file không đủ để mở.", out)
                stored = mid.read_bytes()
                ops, mem = struct.unpack_from("<QQ", stored, 12)
                self.assertEqual((ops, mem), (keyfile.OPS_MODERATE, keyfile.MEM_MODERATE))
                self.assertEqual(len(stored), keyfile.FILE_BYTES)
                mid_key = tree.load_key(mid, "mức-vừa")
                try:
                    self.assertEqual(len(mid_key), 32)
                finally:
                    tlpak.wipe(mid_key)
        finally:
            tlpak.wipe(key)

    def test_raw_key_sentence_and_bad_level(self) -> None:
        with tempfile.TemporaryDirectory(prefix="thienlong-rawkey-") as folder:
            path = Path(folder) / "khoa.bin"
            code, out, err = _run_cli(["new-key", "--out", str(path)])
            self.assertEqual(code, 0, err)
            self.assertEqual(path.stat().st_size, 32)
            self.assertIn("Chính file khoá là bí mật.", out)
            os.environ["BAKE_KDF"] = "min"
            refused = Path(folder) / "khac.bin"
            code, _out, err = _run_cli(["new-key", "--out", str(refused)])
            self.assertEqual(code, 1)
            self.assertIn("không được hỗ trợ", err)
            self.assertFalse(refused.exists())
            with self.assertRaises(KdfLevel):
                keyfile.limits_for_choice("min")

    def test_prompt_empty_is_raw_and_mismatch_writes_nothing(self) -> None:
        with tempfile.TemporaryDirectory(prefix="thienlong-prompt-") as folder:
            root = Path(folder)
            answers = iter(["",])
            original_tty = bake._tty
            original_getpass = bake.getpass.getpass

            def fake_tty() -> bool:
                return True

            def fake_getpass(prompt: str) -> str:
                self.assertIn("bí mật", prompt)
                return next(answers)

            bake._tty = fake_tty
            bake.getpass.getpass = fake_getpass
            try:
                path = root / "trong.bin"
                code, out, err = _run_cli(["new-key", "--out", str(path)])
                self.assertEqual(code, 0, err)
                self.assertEqual(path.stat().st_size, 32)
                self.assertIn("Chính file khoá là bí mật.", out)
            finally:
                bake._tty = original_tty
                bake.getpass.getpass = original_getpass
            answers = iter(["một", "hai"])
            bake._tty = fake_tty
            bake.getpass.getpass = lambda prompt: next(answers)
            try:
                path = root / "lech.bin"
                code, _out, err = _run_cli(["new-key", "--out", str(path)])
                self.assertEqual(code, 1)
                self.assertIn(MISMATCH_TEXT, err)
                self.assertFalse(path.exists())
            finally:
                bake._tty = original_tty
                bake.getpass.getpass = original_getpass

    def test_cpp_rejects_wrapped_key(self) -> None:
        if not SEAL_EXE.is_file():
            self.skipTest(f"không có {SEAL_EXE}")
        key = tlpak.random_key()
        try:
            with tempfile.TemporaryDirectory(prefix="thienlong-cppkey-") as folder:
                root = Path(folder)
                source = root / "src"
                source.mkdir()
                (source / "a.bin").write_bytes(b"\x7f")
                wrapped = root / "boc.bin"
                raw = root / "tho.bin"
                package = root / "goi.tlpak"
                tree.store_key(key, wrapped, "bọc", keyfile.OPS_MIN, keyfile.MEM_MIN)
                tree.store_key(key, raw)
                tree.seal_folder(key, source, package)
                result = subprocess.run(
                    [str(SEAL_EXE), "verify", "--key", str(wrapped), "--from", str(package)],
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                )
                self.assertEqual(result.returncode, 1)
                self.assertIn("không đọc hoặc ghi được tệp", result.stderr)
                opened = subprocess.run(
                    [str(SEAL_EXE), "verify", "--key", str(raw), "--from", str(package)],
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                )
                self.assertEqual(opened.returncode, 0, opened.stderr)
        finally:
            tlpak.wipe(key)


class GuiTests(unittest.TestCase):
    def test_window_builds(self) -> None:
        try:
            import gui
        except Exception as error:
            self.skipTest(str(error))
        try:
            app = gui.build_app(visible=False)
        except Exception as error:
            self.skipTest(str(error))
        try:
            app.root.update()
            self.assertEqual(app.root.title(), "Thiên Long — niêm asset")
            self.assertEqual(app.passphrase_entry.cget("show"), "*")
            self.assertEqual(app.kdf_level.get(), "cao (1 GiB)")
            self.assertIn("vừa (256 MiB)", app.kdf_level_box.cget("values"))
        finally:
            app.root.destroy()

    def test_window_seals_and_cooks(self) -> None:
        import time

        import gui

        noticed: list[str] = []

        def showerror(_title: str, text: str) -> None:
            noticed.append(text)

        original_error = gui.messagebox.showerror
        original_save = gui.filedialog.asksaveasfilename
        gui.messagebox.showerror = showerror
        app = gui.build_app(visible=False)
        try:
            app.passphrase.set("một")
            app.passphrase_again.set("hai")
            app._create_key()
            self.assertEqual(noticed, [MISMATCH_TEXT])
            app.passphrase.set("")
            app.passphrase_again.set("")
            with tempfile.TemporaryDirectory(prefix="thienlong-gui-") as folder:
                root = Path(folder)
                key_path = root / "khoa.bin"
                source = root / "src"
                source.mkdir()
                (source / "a.bin").write_bytes(b"\x03\x04")
                package = root / "goi.tlpak"
                opened = root / "ra"
                sound = root / "sound"
                cooked = root / "cooked"
                _wav(sound / "click.wav", 200, 48000, 1)
                gui.filedialog.asksaveasfilename = lambda **_kwargs: str(key_path)

                def drain() -> None:
                    deadline = time.monotonic() + 8
                    while time.monotonic() < deadline:
                        app.root.update()
                        alive = app.worker is not None and app.worker.is_alive()
                        if not alive and app.status.get() != "Đang chạy…":
                            app.root.update()
                            return
                    self.fail(app.status.get())

                app._create_key()
                drain()
                self.assertEqual(key_path.stat().st_size, 32)
                self.assertIn("bí mật", app.status.get())
                self.assertEqual(app.passphrase.get(), "")
                app.key.set(str(key_path))
                app.seal_from.set(str(source))
                app.seal_out.set(str(package))
                app._seal()
                drain()
                self.assertIn("đã niêm 1 tệp, 2 byte", app.status.get())
                app.seal_from.set(str(package))
                app.seal_out.set(str(opened))
                app._open()
                drain()
                self.assertEqual((opened / "a.bin").read_bytes(), b"\x03\x04")
                app.seal_from.set(str(package))
                app._verify()
                drain()
                self.assertIn("gói nguyên, 1 tệp, 2 byte", app.status.get())
                app.cook_from.set(str(sound))
                app.cook_out.set(str(cooked))
                app._cook()
                drain()
                self.assertTrue((cooked / "click.tla").is_file())
                self.assertEqual(noticed, [MISMATCH_TEXT])
        finally:
            app.stop.set()
            if app.worker is not None:
                app.worker.join(2)
            gui.messagebox.showerror = original_error
            gui.filedialog.asksaveasfilename = original_save
            app.root.destroy()


if __name__ == "__main__":
    unittest.main(verbosity=2)
