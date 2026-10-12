# Tệp âm thanh đã cook (.tla), bản 1

Công cụ `thienlong_audio cook <cây sound gốc> <cây ra>` ghi; `SRC/audio/pack.cpp` đọc và kiểm.
Mọi số là little-endian. Mọi tệp ở 48 kHz, một hoặc hai kênh.

## Đầu tệp, 24 byte

| Vị trí | Cỡ | Trường | Ghi chú |
|---|---|---|---|
| 0 | 4 | dấu | `TLA1` |
| 4 | 1 | codec | 0 = PCM16, 1 = Opus |
| 5 | 1 | số kênh | 1 hoặc 2 |
| 6 | 2 | pre_skip | Opus: số khung đầu ra của bộ giải mã phải bỏ trước khung đầu tiên. PCM: 0 |
| 8 | 4 | tần số | luôn 48000 |
| 12 | 4 | số khung | khung PCM của âm thanh, không tính phần dẫn và phần đệm; 1 tới 86 400 000 (30 phút) |
| 16 | 4 | số gói | Opus: số gói. PCM: 0 |
| 20 | 2 | khung mỗi gói | Opus: 960 (20 ms). PCM: 0 |
| 22 | 2 | dành riêng | 0 |

## Thân tệp

- **PCM16:** `số khung × số kênh` mẫu int16 xen kẽ theo kênh. Độ dài thân phải khít.
- **Opus:** bảng `số gói` số uint16 (cỡ từng gói, tính bằng byte), rồi các gói nối liền nhau theo thứ
  tự phát. Tổng các cỡ phải khít phần còn lại của tệp, và `số gói × 960` phải không nhỏ hơn
  `pre_skip + số khung`.

## Giải mã Opus

Mỗi gói cho đúng 960 khung. Bỏ `pre_skip` khung đầu, giao `số khung` khung kế tiếp, phần còn lại
của gói cuối là đệm. `pre_skip` bằng độ trễ của bộ mã (libopus báo qua `OPUS_GET_LOOKAHEAD`) cộng
3840 khung dẫn (80 ms). Với nhạc và ambience, phần dẫn là 80 ms cuối của chính bài; với tiếng một
lần, phần dẫn là im lặng. Quay vòng: đặt lại trạng thái bộ giải mã rồi đọc lại từ gói 0.

## Lớp và bitrate lúc cook

Lớp lấy theo thư mục đầu trong cây `sound/`. Tệp không quá 0,4 giây (19 200 khung) luôn là PCM16.

| Lớp | Thư mục | Một kênh | Hai kênh | Phần dẫn |
|---|---|---|---|---|
| nhạc | `music/` | 96 kbit/s | 144 kbit/s | đuôi bài |
| ambience | `ambience/` | 64 kbit/s | 112 kbit/s | đuôi bài |
| lời thoại | `Dial_*` | 48 kbit/s | 72 kbit/s | im lặng |
| hiệu ứng | còn lại | 64 kbit/s | 96 kbit/s | im lặng |

Số đo ngày 2026-10-06 trên cây sound của client (2259 tệp): 1204,6 MB vào, 470,4 MB ra, 28,8 giây
trên máy dựng; 122 tệp PCM, 2135 tệp Opus.
