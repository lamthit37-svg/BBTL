# Cây này là bản khôi phục ngày 2026-10-09

Ngày 2026-10-09, khoảng 14:56–14:59, toàn bộ `F:\tl 2026` (dự án, `.git`, client gốc, `_raw`, `_glb`) bị
xoá nhầm. Ổ F là SSD đã TRIM nên không lấy lại được nội dung từ đĩa. Cây ở `D:\THIENLONG` được ghép lại từ
nhật ký của các công cụ đã làm việc trên dự án, rồi chép sang ổ D cùng ngày theo lời chủ dự án. Các kho nhật
ký đóng băng, công cụ ghép và bản quét MFT đã xoá theo lời chủ dự án, nên các danh sách dưới đây không sinh
lại được: đừng xoá thư mục này khi chưa rà xong.

## Trong thư mục này

- `DANH-SACH-KHOP-CO.tsv` — 4.828 tệp đúng số byte so với lúc bị xoá.
- `DANH-SACH-GAN-DUNG.tsv` — 120 tệp có nội dung nhưng lệch cỡ: bản cũ hơn bản cuối, hoặc bản ghép chưa
  chính xác. Mỗi dòng ghi số byte đang có và số byte lúc xoá. Rà những tệp này trước khi tin.
- `DANH-SACH-MAT.tsv` — 48.459 tệp chỉ còn tên và cỡ (44.367 dòng là dữ liệu dưới `CLIENT/`). Dùng để đối
  chiếu khi sinh lại dữ liệu.
- `BAO-CAO-GHEP.tsv` — từng tệp: mức tin cậy, thời điểm và nguồn của sự kiện cuối, ghi chú.
- `chua-du/` — 83 tệp mới biết một phần số dòng; dòng chưa biết đánh dấu `⟪thiếu dòng này⟫`.
- `ngoai-ban-ke/` — 78 tệp nhật ký có nhắc nhưng lúc bị xoá không còn trong dự án (đã đổi chỗ hoặc bỏ).
- `lich-su-git-2026-10-05.bundle` — lịch sử git 25 commit đầu, tới `28d4c74` (2026-10-05 19:37). Lấy ra:
  `git clone lich-su-git-2026-10-05.bundle <thư mục>`. Lịch sử sau đó không còn; lúc mất `main` = `server`
  = `d3629ed`.

## Con số

"Khớp cỡ" là đúng số byte theo bảng tệp NTFS của ổ F, không phải đã so từng byte nội dung.

| Vùng | Tổng | Khớp cỡ | Gần đúng | Mất |
|---|---|---|---|---|
| `SRC` | 603 | 546 | 56 | 1 |
| `tests` (mã) | 122 | 65 | 31 | 26 |
| `tests/golden` | 56 | 0 | 0 | 56 |
| `cmake` | 9 | 8 | 1 | 0 |
| tệp ở gốc | 16 | 11 | 2 | 3 |
| `refs`, `config` | 24 | 24 | 0 | 0 |
| `docs` (ngoài `giao-viec`) | 17 | 14 | 1 | 2 |
| `docs/giao-viec` | 981 | 400 | 7 | 574 |
| `TOOLS` (ngoài `server`) | 93 | 63 | 11 | 19 |
| `TOOLS/server` (mã và bảng cột `columns/`) | 783 | 429 | 6 | 348 |
| `WEB` | 57 | 52 | 0 | 5 |
| `SERVER/config` | 18 | 13 | 3 | 2 |

Biên dịch thử cú pháp bằng Clang 23 (`-std=c++23 -fsyntax-only -msse4.1 -I SRC`) 57 tệp `.cpp` của 20
module không cần thư viện ngoài: 54 qua, 3 lỗi (`core/log.cpp`, `core/log_sink.cpp`,
`control/char_camera.cpp`), cả ba thuộc danh sách gần đúng. Chưa dựng dự án bằng CMake và chưa chạy test
nào sau khôi phục.

## Còn thiếu

- Mã: `SRC/client/stage/props.cpp`; 11 tệp test mà `CMakeLists.txt` nêu (`collision_tests.cpp`,
  `collision_alloc_tests.cpp`, `collision_fuzz_tests.cpp`, `collision_model_tests.cpp`,
  `collision_hostile.hpp`, ba tệp `tests/bench`, `protocol_channel_tests.cpp`, `protocol_fuzz_tests.cpp`,
  `window_modal_tests.cpp`).
- `CMakeLists.txt` là bản gần đúng: chưa có target của gói P2-2 (`metrics`, `metrics/serve`,
  `thienlong_metrics_snap`). Gói đó đã qua cổng ngày 2026-10-09 nhưng chưa commit; `SRC/gate/table.*`,
  `SRC/service/service.cpp`, `tests/gate_tests.cpp` trong cây là bản trước một số bản vá của gói.
- `SRC/protocol/messages.cpp`, `messages.hpp` là tệp sinh: chạy lại `TOOLS/server/gen_protocol.py` sau khi
  rà bảng `SRC/protocol/catalog`.
- Phải cài lại hoặc sinh lại: client gốc, `_raw`, `_glb`; `CLIENT/data`, `SERVER/tables`, `SERVER/scenes`,
  `tests/golden`; ảnh `assets/i18n` (tấm `button_sheet.png` cần bản gốc của chủ dự án);
  `third_party/libsodium` 1.0.22 và `third_party/miniaudio`.
- Đường dẫn `F:\tl 2026` trong `AGENTS.md` và `docs/` tả chỗ cũ của dự án và của dữ liệu gốc.
- `AGENTS.md` có thêm gạch đầu dòng "Khôi phục" ở mục 0 so với bản lúc mất; ngoài dòng đó và thư mục này,
  không tệp nào trong cây được sửa sau khi ghép.

## Cây được ghép thế nào

Nguồn nội dung: transcript Claude Code (Read, Write, Edit, đầu ra của `cat` và `sed -n`, tệp tạo bằng
heredoc, kết quả của tác tử con), bản sao lưu trước khi sửa của Claude Code, luồng `updates.jsonl` của Grok
Build, artifact của ZCode, thư mục `agent-tools` của Grok Bot, 5 bản clone git ngày 05-10 của Grok, tệp
dưới ~700 byte còn thật trong bảng MFT, và bộ `~/.claude/cpp23` (cho `MAP.md`, `INDEX.md`, `refs/`). 655
script vá tệp mà các phiên Claude từng chạy được chạy lại trong hộp cát theo thứ tự thời gian. Cỡ tệp trong
bảng MFT làm trọng tài: khi bản ghép cuối lệch cỡ, lấy bản muộn nhất đúng số byte trong mọi bản từng thấy,
kể cả bản đã chạy lại `clang-format` cột 120 (ngày 08-10 cả cây C++ được định dạng lại như vậy).
`.clang-format` trong cây là bản hiện nay của cpp23, khác bản của dự án lúc mất 31 byte.
