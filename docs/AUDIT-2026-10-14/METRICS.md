# METRICS — số liệu và phân loại

Định nghĩa metric: tên + đơn vị + phương pháp + lệnh ở `EVIDENCE_INDEX.md`.
Ngày đo: 2026-10-14. Commit: `1ff6703`. Môi trường: Windows 11, repo ở
`D:\THIENLONG`, working tree bẩn (65 file). Không có benchmark/runtime nào được
chạy đợt này — mọi ô runtime là NOT MEASURED, không suy từ kiến trúc.

## Source (MEASURED)

| Metric | Giá trị | Cách đo |
|---|---|---|
| File C++ (`engine+src+Test`) | 785 (lúc đo đợt trước 778; +7 file mới chưa track ở `figure/avatar` + `figure/look`, xem README audit) | đếm file `.cpp/.hpp/.h/.c/.mm` |
| LOC engine | 53513 (+6134 comment, +8092 trắng) | script đọc file |
| LOC src | 57355 (+6996 comment, +8870 trắng) | script đọc file |
| LOC Test | 31445 (+1651 comment, +3376 trắng) | script đọc file |
| Tổng LOC | 142313 | DERIVED (cộng 3 dòng trên) |
| Module `game_*` | 53 | regex `game_module\(` trên CMakeLists |
| Executable target | 17 (+ mẫu `${name}_tests`) | regex `add_executable` |
| Preset configure | 12 (8 dev/test + 2 iOS Darwin-only) | đọc CMakePresets.json |
| Test domain có file | 38 + 7 test đặc biệt | liệt kê `Test/*/*_tests.cpp` |
| Tin protocol | 22 + 1 record, 4 nhóm, version 2 | đọc catalog + messages.hpp |
| Backend GPU thật | 4 (Vulkan/D3D12/D3D11/GLES), 0 Metal gốc | đọc types.hpp + cây gpu/ |
| TU dịch (`.cpp/.c/.mm`) | 419 | đếm file `engine+src+Test` |
| Header (`.hpp/.h`) | 366 | đếm file, tổng 785 |
| TU lớn nhất | `engine/resource/model.cpp` 1715 LOC (top10 trong evidence) | script đếm dòng |
| Sâu include (client `main.cpp`) | 10 | BFS include ngoặc kép, resolver gần đúng |
| Sâu include (`engine/gpu/device.cpp`) | 9 | như trên |
| Khối trùng ≥20 dòng chuẩn hoá | 206 nhóm, gom ở 15 file (bộ ba `gpu/*/device.hpp`) | hash khối dòng, DERIVED gần đúng |
| Định nghĩa `class/struct` | 2228 | regex đầu dòng, proxy type-surface |
| Định nghĩa `enum class` | 277 | regex đầu dòng |
| Điểm rẽ (`if/for/while/switch/catch/?:`) | 13501 (~9,5/100 LOC; top `engine/resource/model.cpp` 278) | regex sau khi lột comment/string, PROXY thô — không phải cyclomatic của công cụ |

## Build / test / runtime (NOT MEASURED hoặc BLOCKED)

Full/clean/incremental build time, warning count, binary size, ctest pass rate,
ASan/UBSan/TSan, FPS P50/P95/P99, CPU/GPU frame time, RAM/VRAM, draw call,
triangle, shader compile time, asset load, startup, server tick/RPS/RTT/DB latency
— toàn bộ NOT MEASURED đợt này (BLOCKED: working tree bẩn + chính sách không
build nặng song song). Số duy nhất còn hiệu lực gần nhất: nạp đầu Đại Lý trung vị
387 ms / 15 lượt / 2026-10-13 (nguồn `TAILIEU/TOC-DO-NAP-SO-VOI-TLBB.md`) — KHÔNG
đo lại đợt này, ghi nhận như dữ liệu cũ, không nhận là đạt gate.

## Validation đã chạy (MEASURED)

- `gen_protocol.py --check`: True (tệp sinh còn tươi).
- `lint_config.py` (check-only): `26 tệp sạch, 437 cài đặt đều có chú thích và
  thẳng cột` (chạy 2026-10-14, MEASURED).
- Quét secret: 130 dòng chứa từ khoá trong `src/**/*.cpp/.hpp` đã review tay toàn
  bộ (VERIFIED sạch — toàn hằng cỡ khoá, tham số khoá, `wipe_*` sau dùng, bộ đọc
  `secrets.*`, đường dẫn `secret_file`; pattern hẹp `api_key|passwd|token=<giá
  trị>` cho 0 kết quả; không đọc `secrets.local.toml`, không đưa giá trị vào báo cáo).
- `src/client/client.build.toml`: `schema = 1`, `[hud] avatar_frame = "square"`
  (đọc trực tiếp 2026-10-14, khớp tài liệu).
