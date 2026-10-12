# Cook cây âm thanh thành .tla (TLA1) mà client đã đọc. Không nén lại byte trong gói niêm.
# PCM 16-bit nếu không quá 0,4 giây; dài hơn thì Opus 20 ms, độ phức tạp 10, phần dẫn 80 ms.
# Nhạc và ambience lấy đuôi bài làm phần dẫn để lặp. Thoại vẫn dùng application audio.
# Đổi tần số bằng kaiser.py, cùng công thức SRC/audio/resample.cpp. Chưa so từng bit với bản C++.
# Khác gốc: PyAV không đặt được OPUS_SET_SIGNAL. Gói flush của bộ mã không ghi vào tệp.
# Khác gốc: liên kết là lỗi; os.replace để lần sau ghi đè .tla cũ.
# Thư mục ra phải khác cây nguồn. engine.cpp ưu tiên .tla cạnh tệp gốc nếu thấy.

from __future__ import annotations

import os
import struct
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

import av
import miniaudio
import numpy as np

from errors import Cancelled
from kaiser import resample
from paths import covers, hits_client, same_place

SAMPLE_RATE = 48000
PCM_FRAMES = 19200
LEAD_FRAMES = 3840
PACKET_FRAMES = 960
SOURCE_SECONDS = 30 * 60
MAX_FRAMES = SAMPLE_RATE * SOURCE_SECONDS
_MEGA = 1024.0 * 1024.0

_RATES = {
    "effect": (64000, 96000),
    "voice": (48000, 72000),
    "ambience": (64000, 112000),
    "music": (96000, 144000),
}

_lookahead_lock = threading.Lock()
_lookahead: dict[int, int] = {}


class CookFailure(Exception):
    pass


class CookRefusal(Exception):
    pass


@dataclass
class CookReport:
    files: int = 0
    pcm: int = 0
    opus: int = 0
    copied: int = 0
    skipped: int = 0
    failed: int = 0
    bytes_in: int = 0
    bytes_out: int = 0
    seconds: float = 0.0

    def lines(self) -> list[str]:
        entered = self.bytes_in / _MEGA
        left = self.bytes_out / _MEGA
        summary = (
            f"Cook âm thanh: {self.files} tệp, {self.pcm} PCM, {self.opus} Opus, "
            f"{self.copied} chép nguyên, {self.skipped} bỏ qua, {self.failed} lỗi"
        )
        size = f"Cook âm thanh: {entered:.1f} MB vào, {left:.1f} MB ra, {self.seconds:.1f} giây"
        return [summary, size]


@dataclass
class _Job:
    source: Path | None
    target: Path | None
    relative: str
    sound: bool
    problem: str | None = None


class _Tally:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.pcm = 0
        self.opus = 0
        self.copied = 0
        self.skipped = 0
        self.failed = 0
        self.bytes_in = 0
        self.bytes_out = 0

    def add(self, field: str, amount: int = 1) -> None:
        with self.lock:
            current = getattr(self, field)
            setattr(self, field, current + amount)


def classify(relative: str) -> str:
    if relative.startswith("music/"):
        return "music"
    if relative.startswith("ambience/"):
        return "ambience"
    if relative.startswith("Dial_"):
        return "voice"
    return "effect"


def _lower_ascii(text: str) -> str:
    folded = []
    for unit in text:
        code = ord(unit)
        if 65 <= code <= 90:
            folded.append(chr(code - 65 + 97))
        else:
            folded.append(unit)
    return "".join(folded)


def _is_sound(path: Path) -> bool:
    return _lower_ascii(path.suffix) in (".wav", ".mp3")


def _bitrate(kind: str, channels: int) -> int:
    mono, stereo = _RATES[kind]
    if channels == 2:
        return stereo
    return mono


def to_pcm16(samples: np.ndarray) -> np.ndarray:
    # std::round làm tròn nửa ra xa 0. Không dùng làm tròn ngân hàng của NumPy.
    scaled = np.asarray(samples, dtype=np.float32) * np.float32(32768.0)
    rounded = np.where(
        scaled >= 0,
        np.floor(scaled + np.float32(0.5)),
        np.ceil(scaled - np.float32(0.5)),
    )
    clipped = np.clip(rounded, -32768, 32767)
    return clipped.astype("<i2")


def _header(
    codec: int,
    channels: int,
    pre_skip: int,
    frames: int,
    packet_count: int,
    packet_frames: int,
) -> bytes:
    return struct.pack(
        "<4sBBHIIIHH",
        b"TLA1",
        codec,
        channels,
        pre_skip,
        SAMPLE_RATE,
        frames,
        packet_count,
        packet_frames,
        0,
    )


def _write_pcm(samples: np.ndarray) -> bytes:
    frames = samples.shape[0]
    channels = samples.shape[1]
    body = np.ascontiguousarray(to_pcm16(samples)).tobytes()
    expect = frames * channels * 2
    if len(body) != expect:
        raise CookFailure("không ghi được tệp ra")
    return _header(0, channels, 0, frames, 0, 0) + body


def _open_encoder(channels: int, bitrate: int) -> av.codec.context.CodecContext:
    layout = "mono" if channels == 1 else "stereo"
    context = av.CodecContext.create("libopus", "w")
    context.sample_rate = SAMPLE_RATE
    context.layout = layout
    context.format = "fltp"
    context.bit_rate = bitrate
    context.options = {
        "application": "audio",
        "frame_duration": "20",
        "compression_level": "10",
    }
    context.open()
    return context


def _encode_block(context: av.codec.context.CodecContext, block: np.ndarray, index: int) -> bytes:
    channels = block.shape[1]
    layout = "mono" if channels == 1 else "stereo"
    frame = av.AudioFrame(format="fltp", layout=layout, samples=PACKET_FRAMES)
    frame.sample_rate = SAMPLE_RATE
    frame.pts = index * PACKET_FRAMES
    for channel in range(channels):
        plane = np.ascontiguousarray(block[:, channel], dtype=np.float32)
        frame.planes[channel].update(plane)
    packets = context.encode(frame)
    if len(packets) != 1 or packets[0].duration != PACKET_FRAMES:
        raise CookFailure("bộ mã Opus từ chối một gói")
    data = bytes(packets[0])
    if not data or len(data) > 65535:
        raise CookFailure("cỡ gói Opus ngoài khoảng")
    return data


def _measure_lookahead(channels: int) -> int:
    context = _open_encoder(channels, 64000)
    silence = np.zeros((PACKET_FRAMES, channels), dtype=np.float32)
    _encode_block(context, silence, 0)
    # ctx.delay của PyAV ở 0. Gói flush có duration bằng OPUS_GET_LOOKAHEAD, và không được ghi.
    tail = context.encode(None)
    if len(tail) != 1 or tail[0].duration is None or int(tail[0].duration) <= 0:
        raise CookFailure("không đo được độ trễ Opus")
    return int(tail[0].duration)


def _lookahead_frames(channels: int) -> int:
    with _lookahead_lock:
        cached = _lookahead.get(channels)
        if cached is not None:
            return cached
        measured = _measure_lookahead(channels)
        _lookahead[channels] = measured
        return measured


def _encode_opus(samples: np.ndarray, kind: str) -> bytes:
    channels = samples.shape[1]
    frames = samples.shape[0]
    lookahead = _lookahead_frames(channels)
    pre_skip = lookahead + LEAD_FRAMES
    if pre_skip > 65535:
        raise CookFailure("pre_skip phải vừa 16 bit")
    packet_count = (pre_skip + frames + PACKET_FRAMES - 1) // PACKET_FRAMES
    staged = np.zeros((packet_count * PACKET_FRAMES, channels), dtype=np.float32)
    looping = kind in ("music", "ambience") and frames >= LEAD_FRAMES
    if looping:
        staged[:LEAD_FRAMES] = samples[-LEAD_FRAMES:]
    staged[LEAD_FRAMES : LEAD_FRAMES + frames] = samples
    context = _open_encoder(channels, _bitrate(kind, channels))
    packets: list[bytes] = []
    for index in range(packet_count):
        start = index * PACKET_FRAMES
        block = staged[start : start + PACKET_FRAMES]
        packets.append(_encode_block(context, block, index))
    sizes = b"".join(struct.pack("<H", len(packet)) for packet in packets)
    payload = b"".join(packets)
    header = _header(1, channels, pre_skip, frames, packet_count, PACKET_FRAMES)
    return header + sizes + payload


def _sound_info(data: bytes) -> miniaudio.SoundFileInfo:
    last: Exception | None = None
    for reader in (miniaudio.wav_get_info, miniaudio.mp3_get_info):
        try:
            return reader(data)
        except Exception as error:
            last = error
    raise CookFailure("không giải mã được âm thanh") from last


def _decode(data: bytes) -> tuple[np.ndarray, int]:
    info = _sound_info(data)
    channels = int(info.nchannels)
    rate = int(info.sample_rate)
    if channels not in (1, 2) or rate <= 0:
        raise CookFailure("chỉ nhận âm thanh một hoặc hai kênh")
    most = SOURCE_SECONDS * rate
    parts: list[np.ndarray] = []
    held = 0
    stream = miniaudio.stream_memory(
        data,
        output_format=miniaudio.SampleFormat.FLOAT32,
        nchannels=channels,
        sample_rate=rate,
        frames_to_read=4096,
    )
    try:
        for chunk in stream:
            if held >= most:
                break
            block = np.asarray(chunk, dtype=np.float32)
            if block.size == 0:
                break
            if block.size % channels != 0:
                raise CookFailure("không giải mã được âm thanh")
            frames = block.reshape(-1, channels)
            room = most - held
            if frames.shape[0] > room:
                frames = frames[:room]
            parts.append(np.ascontiguousarray(frames))
            held += frames.shape[0]
    finally:
        stream.close()
    if not parts:
        raise CookFailure("tệp âm thanh gốc không có mẫu")
    return np.concatenate(parts, axis=0), rate


def _resample(samples: np.ndarray, rate: int) -> np.ndarray:
    if rate == SAMPLE_RATE:
        return samples
    try:
        return resample(samples, rate, SAMPLE_RATE)
    except (ValueError, FloatingPointError) as error:
        raise CookFailure("không đổi được tần số") from error


def cook_bytes(data: bytes, kind: str) -> bytes:
    samples, rate = _decode(data)
    samples = _resample(samples, rate)
    if samples.shape[0] > MAX_FRAMES:
        samples = samples[:MAX_FRAMES]
    if samples.shape[0] == 0 or samples.shape[1] not in (1, 2):
        raise CookFailure("tệp âm thanh gốc không có mẫu")
    if samples.shape[0] <= PCM_FRAMES:
        return _write_pcm(samples)
    return _encode_opus(samples, kind)


def _write_atomic(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pending = Path(str(path) + ".part")
    try:
        handle = pending.open("wb")
        try:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        finally:
            handle.close()
        os.replace(pending, path)
    except OSError as error:
        try:
            pending.unlink()
        except OSError:
            pass
        raise CookFailure("không ghi được tệp ra") from error


def _fresh(source: Path, target: Path) -> bool:
    try:
        made = target.stat().st_mtime_ns
        origin = source.stat().st_mtime_ns
    except OSError:
        return False
    return made >= origin


def _plan(source: Path, destination: Path) -> list[_Job]:
    jobs: list[_Job] = []
    walk_error: OSError | None = None

    def on_error(error: OSError) -> None:
        nonlocal walk_error
        walk_error = error

    for dirpath, dirnames, filenames in os.walk(source, onerror=on_error, followlinks=False):
        current = Path(dirpath)
        for directory in list(dirnames):
            candidate = current / directory
            if candidate.is_symlink():
                relative = candidate.relative_to(source).as_posix()
                jobs.append(_Job(None, None, relative, False, "không theo liên kết"))
                dirnames.remove(directory)
        for filename in filenames:
            candidate = current / filename
            relative = candidate.relative_to(source).as_posix()
            try:
                linked = candidate.is_symlink()
            except OSError:
                jobs.append(_Job(None, None, relative, False, "không đọc được tệp gốc"))
                continue
            if linked:
                jobs.append(_Job(None, None, relative, False, "không theo liên kết"))
                continue
            sound = _is_sound(candidate)
            target = destination / relative
            if sound:
                target = target.with_suffix(".tla")
            problem = None
            if hits_client(target):
                problem = "không ghi vào thư mục client"
            jobs.append(_Job(candidate, target, relative, sound, problem))
    if walk_error is not None and not jobs:
        raise CookRefusal(f"Lỗi: không đọc được thư mục {source.as_posix()}") from walk_error
    if walk_error is not None:
        jobs.append(_Job(None, None, source.as_posix(), False, "không đọc được thư mục"))
    return jobs


def _run_job(job: _Job, tally: _Tally, stop) -> None:
    if stop is not None and stop():
        raise Cancelled()
    if job.problem is not None or job.source is None or job.target is None:
        tally.add("failed")
        why = job.problem or "không đọc được tệp gốc"
        raise CookFailure(f"{job.relative}: {why}")
    if _fresh(job.source, job.target):
        tally.add("skipped")
        return
    try:
        payload = job.source.read_bytes()
    except OSError as error:
        tally.add("failed")
        raise CookFailure(f"{job.relative}: không đọc được tệp gốc") from error
    if not payload:
        tally.add("failed")
        raise CookFailure(f"{job.relative}: không đọc được tệp gốc")
    tally.add("bytes_in", len(payload))
    try:
        if job.sound:
            cooked = cook_bytes(payload, classify(job.relative))
            _write_atomic(job.target, cooked)
        else:
            cooked = payload
            _write_atomic(job.target, cooked)
    except CookFailure as error:
        tally.add("failed")
        raise CookFailure(f"{job.relative}: {error}") from error
    tally.add("bytes_out", len(cooked))
    if not job.sound:
        tally.add("copied")
        return
    if cooked[4:5] == b"\x01":
        tally.add("opus")
    else:
        tally.add("pcm")


def _refuse(source: Path, destination: Path) -> None:
    try:
        if source.is_symlink() or not source.is_dir():
            raise CookRefusal(f"Lỗi: không thấy tệp nào trong {source.as_posix()}")
    except OSError as error:
        raise CookRefusal(f"Lỗi: không thấy tệp nào trong {source.as_posix()}") from error
    if hits_client(destination):
        raise CookRefusal("Lỗi: không ghi vào thư mục client")
    if same_place(source, destination) or covers(source, destination):
        raise CookRefusal("Lỗi: không cook đè lên cây nguồn")
    try:
        if destination.exists() and not destination.is_dir():
            raise CookRefusal("Lỗi: thư mục ra không phải thư mục")
    except OSError as error:
        raise CookRefusal("Lỗi: thư mục ra không phải thư mục") from error


def cook_tree(
    source: Path,
    destination: Path,
    stop=None,
    on_progress=None,
    on_error=None,
    workers: int | None = None,
) -> CookReport:
    started = time.perf_counter()
    _refuse(source, destination)
    jobs = _plan(source, destination)
    if not jobs:
        raise CookRefusal(f"Lỗi: không thấy tệp nào trong {source.as_posix()}")
    tally = _Tally()
    done = 0
    done_lock = threading.Lock()

    def one(job: _Job) -> None:
        nonlocal done
        try:
            _run_job(job, tally, stop)
        except Cancelled:
            raise
        except CookFailure as error:
            line = f"Lỗi: {error}"
            if on_error is not None:
                on_error(line)
            else:
                print(line, file=sys.stderr, flush=True)
        finally:
            with done_lock:
                done += 1
                current = done
            if on_progress is not None:
                on_progress(current, len(jobs))

    pool = max(1, workers if workers is not None else (os.cpu_count() or 1))
    with ThreadPoolExecutor(max_workers=pool) as executor:
        list(executor.map(one, jobs))
    report = CookReport(
        files=len(jobs),
        pcm=tally.pcm,
        opus=tally.opus,
        copied=tally.copied,
        skipped=tally.skipped,
        failed=tally.failed,
        bytes_in=tally.bytes_in,
        bytes_out=tally.bytes_out,
        seconds=time.perf_counter() - started,
    )
    return report
