# Đổi tần số bằng sinc cửa sổ Kaiser, cùng công thức với SRC/audio/resample.cpp.
# 48 lần cắt không mỗi bên khi nâng tần, beta 10,5, điểm -6 dB ở 0,955 Nyquist.
# Mỗi hàng chuẩn hoá tổng 1. Tỉ số không quá 1024 pha thì mỗi pha một hàng; lệch hơn thì trộn hai hàng.
# Chưa so từng bit với bản C++ đã dịch.

from __future__ import annotations

import math
import threading

import numpy as np

ZERO_CROSSINGS = 48
BANDWIDTH = 0.955
KAISER_BETA = 10.5
MAX_PHASES = 1024
BESSEL_TERMS = 48

_cache_lock = threading.Lock()
_cache: dict[tuple[int, int], tuple[np.ndarray, int, int, int, bool]] = {}


def _bessel(value: float) -> float:
    quarter = value * value * 0.25
    term = 1.0
    total = 1.0
    for step in range(1, BESSEL_TERMS):
        count = float(step)
        term *= quarter / (count * count)
        total += term
    return total


def _bessel_array(values: np.ndarray) -> np.ndarray:
    quarter = values * values * 0.25
    term = np.ones_like(quarter)
    total = np.ones_like(quarter)
    for step in range(1, BESSEL_TERMS):
        count = float(step)
        term = term * quarter / (count * count)
        total = total + term
    return total


def _half_width(source_rate: int, target_rate: int) -> int:
    ratio = target_rate / source_rate
    narrow = min(1.0, ratio)
    whole = int(math.ceil(ZERO_CROSSINGS / narrow))
    return whole + (whole % 2)


def _fill_row(row: np.ndarray, fraction: float, cutoff: float, half: float, peak: float) -> None:
    taps = row.shape[0]
    index = np.arange(taps, dtype=np.float64)
    offset = (index + 1.0) - half - fraction
    place = offset / half
    inside = 1.0 - (place * place)
    values = np.zeros(taps, dtype=np.float64)
    live = inside > 0.0
    if np.any(live):
        window = _bessel_array(KAISER_BETA * np.sqrt(inside[live])) / peak
        chosen = offset[live]
        sinc = np.ones_like(chosen)
        wide = np.abs(chosen) >= 1.0e-9
        turn = np.pi * chosen[wide]
        sinc[wide] = np.sin(turn) / turn
        values[live] = cutoff * sinc * window
    scale = np.float32(1.0 / float(values.sum()))
    stored = values.astype(np.float32)
    row[:] = stored * scale


def _table_for(source_rate: int, target_rate: int) -> tuple[np.ndarray, int, int, int, bool]:
    key = (source_rate, target_rate)
    with _cache_lock:
        cached = _cache.get(key)
        if cached is not None:
            return cached
        half = _half_width(source_rate, target_rate)
        taps = half * 2
        exact = target_rate // math.gcd(source_rate, target_rate)
        is_exact = exact <= MAX_PHASES
        phases = exact if is_exact else MAX_PHASES
        ratio = target_rate / source_rate
        cutoff = min(1.0, ratio) * BANDWIDTH
        peak = _bessel(KAISER_BETA)
        rows = phases + 1
        table = np.zeros(rows * taps, dtype=np.float32)
        for phase in range(rows):
            fraction = phase / phases
            start = phase * taps
            _fill_row(table[start : start + taps], fraction, cutoff, float(half), peak)
        cached = (table, taps, phases, half, is_exact)
        _cache[key] = cached
        return cached


def _dot(row: np.ndarray, samples: np.ndarray) -> np.float32:
    sums = [np.float32(0), np.float32(0), np.float32(0), np.float32(0)]
    taps = row.shape[0]
    for tap in range(0, taps, 4):
        sums[0] = np.float32(sums[0] + np.float32(row[tap] * samples[tap]))
        sums[1] = np.float32(sums[1] + np.float32(row[tap + 1] * samples[tap + 1]))
        sums[2] = np.float32(sums[2] + np.float32(row[tap + 2] * samples[tap + 2]))
        sums[3] = np.float32(sums[3] + np.float32(row[tap + 3] * samples[tap + 3]))
    left = np.float32(sums[0] + sums[1])
    right = np.float32(sums[2] + sums[3])
    return np.float32(left + right)


class Resampler:
    def __init__(self, source_rate: int, target_rate: int, channels: int) -> None:
        if source_rate <= 0 or target_rate <= 0 or channels not in (1, 2):
            raise ValueError("tần số hoặc số kênh không hợp lệ")
        table, taps, phases, half, is_exact = _table_for(source_rate, target_rate)
        self.table = table
        self.taps = taps
        self.phases = phases
        self.half = half
        self.is_exact = is_exact
        self.source = source_rate
        self.target = target_rate
        self.channels = channels
        self.blended = np.zeros(taps, dtype=np.float32)
        self.held = [np.zeros(0, dtype=np.float32), np.zeros(0, dtype=np.float32)]
        self.base = 0
        self.remainder = 0
        self.reset()

    def reset(self) -> None:
        quiet = np.zeros(self.half - 1, dtype=np.float32)
        self.held = [quiet.copy(), quiet.copy()]
        self.base = 0
        self.remainder = 0

    def push(self, samples: np.ndarray) -> None:
        for channel in range(self.channels):
            column = np.ascontiguousarray(samples[:, channel], dtype=np.float32)
            self.held[channel] = np.concatenate((self.held[channel], column))

    def finish(self) -> None:
        quiet = np.zeros(self.half, dtype=np.float32)
        for channel in range(self.channels):
            self.held[channel] = np.concatenate((self.held[channel], quiet))

    def _ready(self) -> bool:
        return self.base + self.taps <= int(self.held[0].shape[0])

    def _row(self) -> np.ndarray:
        scaled = self.remainder * self.phases
        phase = scaled // self.target
        start = phase * self.taps
        row = self.table[start : start + self.taps]
        if self.is_exact:
            return row
        part = np.float32(scaled % self.target) / np.float32(self.target)
        nxt = self.table[start + self.taps : start + (self.taps * 2)]
        for tap in range(self.taps):
            delta = np.float32(nxt[tap] - row[tap])
            self.blended[tap] = np.float32(row[tap] + np.float32(delta * part))
        return self.blended

    def _write(self, frame: np.ndarray) -> None:
        row = self._row()
        for channel in range(self.channels):
            samples = self.held[channel][self.base : self.base + self.taps]
            frame[channel] = _dot(row, samples)

    def _step(self) -> None:
        moved = self.remainder + self.source
        self.base += moved // self.target
        self.remainder = moved % self.target

    def _compact(self) -> None:
        held_frames = int(self.held[0].shape[0])
        dropped = min(self.base, held_frames)
        if dropped == 0:
            return
        for channel in range(self.channels):
            self.held[channel] = self.held[channel][dropped:]
        self.base -= dropped

    def pull(self, made: np.ndarray) -> int:
        wanted = int(made.shape[0])
        written = 0
        while written < wanted and self._ready():
            self._write(made[written])
            self._step()
            written += 1
        self._compact()
        return written


def resample(samples: np.ndarray, source_rate: int, target_rate: int) -> np.ndarray:
    if source_rate == target_rate:
        return samples
    frames = int(samples.shape[0])
    channels = int(samples.shape[1])
    engine = Resampler(source_rate, target_rate, channels)
    scaled = (frames * target_rate) + source_rate - 1
    total = scaled // source_rate
    engine.push(samples)
    engine.finish()
    made = np.zeros((total, channels), dtype=np.float32)
    written = engine.pull(made)
    return np.ascontiguousarray(made[:written])
