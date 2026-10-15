# Nhật ký chuẩn hoá (nhánh `chuan-hoa`)

Ghi mọi nghi ngờ bug hoặc chỗ yếu phát hiện khi chuẩn hoá. Không sửa ngữ nghĩa ở lượt chuẩn hoá;
mỗi mục ghi tệp, dòng (tính sau khi gắn header mẫu) và mô tả.

## Quyết định của CTO (2026-10-15)

- Ngoại lệ cho CLAUDE.md 0.3: giữ header mẫu ENGINEHP (từ 16 dòng trở lên, có TÁC GIẢ/TELEGRAM)
  cho mọi tệp, dù 0.3 giới hạn comment đầu tệp 15 dòng và cấm ghi tác giả. Không sửa check_style.js.
- check_style.js hiện là bản đã gỡ (người dùng gỡ ngày 2026-10-08): nó in "cổng hình thức đã gỡ"
  và luôn trả 0, không kiểm gì. Vì vậy nó không báo lỗi 0.3, và cũng không chứng minh được gì.
  Kiểm định dạng thay bằng `clang-format --dry-run -Werror` trên các tệp đã sửa.
- Bỏ qua mọi tệp có thay đổi chưa commit sẵn có của người dùng (danh sách cuối tệp).
- Ngoại lệ cho CLAUDE.md 0.1 (cấm căn thẳng cột): riêng header mẫu ENGINEHP giữ nguyên khoảng
  đệm sau nhãn (ví dụ `TỆP       :`) theo đúng mẫu CTO giao. Ngoài header không căn cột ở đâu.

## Lô 1 - engine/audio

- `engine/audio/ring.hpp`, dòng 39-40, 44, 59, 74 - Các phép `acquire`/`release` trên `write_` và
  `read_` không có comment ghi cặp happens-before mà chúng dựa vào (CLAUDE.md III.4). Thứ tự nhớ
  có vẻ đúng cho mô hình một ghi một đọc, nhưng chưa có ghi chú; chưa kiểm bằng công cụ (máy không
  có TSan, II.2).
- `engine/audio/gain.cpp`, hàm `distance_gain` - `distance` là NaN thì mọi phép so sánh sai và hàm
  trả NaN, có thể lan vào hệ số âm lượng của bộ trộn. Chỉ là giả thuyết từ đọc mã; chưa rõ nơi gọi
  có chặn NaN hay không.

## Lô 2 - engine/audiotool, engine/io

- `engine/io/platform.hpp`, dòng 32 (dòng 17 ở HEAD) - comment dài quá ColumnLimit 100;
  clang-format --dry-run báo lỗi. Có sẵn từ HEAD, không do lô này.
- `engine/io/platform_win32.cpp`, dòng 76 (dòng 61 ở HEAD) - vòng `for` một dòng không khớp
  .clang-format; clang-format --dry-run báo lỗi. Có sẵn từ HEAD.
- `engine/io/platform_apple.cpp` - tự ghi "CHƯA BIÊN DỊCH" (máy không có macOS); không kiểm được
  trên máy này.
- `engine/io/platform_posix.cpp`, `engine/io/platform_apple.cpp` - `open_in_browser` luôn trả
  false (chưa làm, đã có trong docs/NGHI-NGO.md).

## Lô 3 - engine/capture, engine/jobs (chỉ tệp sạch)

- `engine/capture/png.hpp`, dòng 15 - comment trỏ tới `tests/capture_tests.cpp`, nhưng repo không có
  tệp đó (cả `Test/` lẫn `tests/`). Comment có thể lỗi thời từ Forge2; capture không có test nào
  đăng ký trong ctest.
- `engine/jobs/jobs.hpp`, dòng 18 - comment trỏ tới `docs/modules/jobs.md`, nhưng tệp không tồn
  tại. Comment có thể lỗi thời từ Forge2.
- `engine/jobs` - không có test riêng trong ctest (không có jobs_tests hay queue_tests), dù đây là
  mã đồng thời không khoá. Chỉ kiểm được bằng build.

## Lô 4 - engine/math (chỉ tệp sạch, bỏ simd.hpp, types.hpp)

- `engine/math/vector.hpp`, dòng 13 và `engine/math/vector_int.hpp`, dòng 12 - comment trỏ tới
  `docs/modules/math.md`, nhưng repo không có thư mục `docs/modules/`. Comment có thể lỗi thời từ
  Forge2.
- `engine/math/cofactor.hpp`, dòng 10 - comment nói nghịch đảo dùng cho `Matrix4d`
  (`math/double.hpp`), nhưng `engine/math/double.hpp` không có trong repo. Có thể Matrix4d chưa
  được chép từ Forge2; cần xác nhận cofactor còn nơi dùng nào ngoài SoaMatrix4.

## Lô 5 - engine/fs (chỉ tệp sạch, bỏ codec.cpp; file.cpp đã có header mẫu)

- `engine/fs/stream.hpp`, dòng 13 - comment liệt kê ba bản cài đặt File, MemoryStream
  (`fs/memory_stream.hpp`), ArchiveStream (`fs/archive.hpp`), nhưng hai tệp sau không có trong
  repo. Có thể chưa được chép từ Forge2; comment mô tả quá phạm vi thật.
- `engine/fs/buny.cpp`, dòng 15 - comment nói số đo ở `docs/modules/fs.md`; tệp không tồn tại.
- `engine/fs/path.cpp`, dòng 13 - comment nói bài đo `bench/fs` đối chiếu bản mới với bản gốc;
  `Test/bench/` không có bài đo fs nào. Lời khẳng định "trùng gốc" hiện không có bằng chứng
  trong repo.
- `engine/fs/disk.cpp`, `engine/fs/watcher.cpp` - chỉ Win32; bản POSIX
  (`posix.cpp`) chỉ có năm hàm. Lô này chỉ build trên Windows x64, không kiểm được posix.cpp.

## Lô 6a - engine/core, nửa đầu (aligned..hash, 19 tệp sạch)

- `engine/core/clock.cpp`, dòng 14 và 205 - comment trỏ tới `docs/modules/core.md` (số đo p99);
  thư mục `docs/modules/` không có trong repo.
- `engine/core/effects.hpp`, dòng 12 - comment nói "cổng check.py bật cờ -Wfunction-effects cho
  Clang", nhưng repo không có `check.py` nào (ngoài build/, third_party). Cổng có thể chưa được
  chép; khi đó GAME_NONALLOCATING/GAME_NONBLOCKING không có bằng chứng ở bản dựng nào.
- `engine/core/hash.hpp`, dòng 10 - comment chỉ việc chữ ký, mật khẩu sang `sha256.hpp` và
  `siphash.hpp`, nhưng không tìm thấy hai tệp đó trong engine/ hay src/.
- `engine/core/governor.cpp`, dòng 101 và `engine/core/governor.hpp`, dòng 32-33 - comment dài
  quá ColumnLimit, clang-format --dry-run báo lỗi. Có sẵn từ HEAD (governor.hpp ở HEAD còn lỗi cả
  ở comment đầu tệp, nay đã gộp vào header mẫu). Không định dạng lại thân tệp.
- `engine/core/governor.cpp` - không có comment đầu tệp nào; CHỨC NĂNG viết mới từ việc đọc mã
  (fill_tiers, note_frame, judge, step_down). Người soát nên đối chiếu.
- `engine/core/detail/gbk_table.hpp` - tệp sinh bởi TOOLS/content/gen_gbk_table.py ("không sửa
  tay"); thân bảng không khớp .clang-format (22060 dòng báo, bằng đúng HEAD). Lô này chỉ thay
  comment đầu tệp bằng header mẫu; lần sinh lại kế tiếp sẽ xoá header nếu bộ sinh không được sửa
  để in header mẫu.
- Khi dựng lô này CMake tự chạy lại cấu hình vì CMakeLists.txt đã đổi (người dùng/agent khác,
  thêm collision_bench); không ảnh hưởng kết quả.

## Lô 6b - engine/core, nửa sau (log..win32, 17 tệp sạch)

- `engine/core/win32.hpp`, dòng 10 - comment nói gom macro về header vì "check.py dịch từng tệp
  đứng riêng"; repo không có `check.py` (cùng nghi vấn như effects.hpp ở lô 6a). Lý do thiết kế
  vẫn đúng với header_check của CMake, nhưng tên công cụ trong comment có thể lỗi thời.
- clang-format --dry-run sạch trên cả 17 tệp; không có lỗi định dạng có sẵn nào trong lô này.
- `engine/core/log_sink_posix.cpp`, `engine/core/thread_posix.cpp` - chỉ build Windows x64, hai
  tệp POSIX không được biên dịch ở lô này.

## Bộ sinh gbk_table (CTO duyệt)

- `TOOLS/content/gen_gbk_table.py` - không có thay đổi chưa commit của người dùng trước khi sửa.
  Chỉ thay ba dòng comment đầu trong `render()` bằng đúng 16 dòng header mẫu ENGINEHP và một dòng
  trống, lấy nguyên văn từ `engine/core/detail/gbk_table.hpp` hiện tại. Không đổi logic bảng.
- Chạy lại bộ sinh ra tệp tạm: trùng từng byte với gbk_table.hpp hiện tại (202235 byte);
  `--check` báo "khớp". Không ghi đè tệp trong repo (không cần).
- Thân bảng vẫn không khớp .clang-format (22060 dòng báo, có sẵn từ HEAD) - chỉ ghi nhận.

## Tệp bị bỏ qua vì người dùng đang có thay đổi chưa commit (phạm vi A-M)
- `engine/capture/frame.hpp`
- `engine/capture/png.cpp`
- `engine/core/number.hpp`
- `engine/core/range.cpp`
- `engine/core/system_posix.cpp`
- `engine/fs/codec.cpp`
- `engine/jobs/queue.cpp`
- `engine/math/simd.hpp`
- `engine/math/types.hpp`
- `src/client/app/client/cast/cast.cpp`
- `src/client/app/client/cast/cast.hpp`
- `src/client/app/client/cast/note.hpp`
- `src/client/app/client/display/display.hpp`
- `src/client/app/client/display/display_none.cpp`
- `src/client/app/client/display/graphic/creature.cpp`
- `src/client/app/client/display/graphic/face.cpp`
- `src/client/app/client/display/graphic/frame.cpp`
- `src/client/app/client/display/graphic/play.cpp`
- `src/client/app/client/display/graphic/prelude.hpp`
- `src/client/app/client/display/graphic/state.hpp`
- `src/client/app/client/display/player.cpp`
- `src/client/app/client/display/player.hpp`
- `src/client/app/client/host/host.cpp`
- `src/client/app/client/main.cpp`
- `src/client/app/client/online/bridge.cpp`
- `src/client/app/client/online/bridge.hpp`
- `src/client/app/client/options.cpp`
- `src/client/app/client/options.hpp`
- `src/client/app/client/session/machine.cpp`
- `src/client/app/client/session/machine.hpp`
- `src/client/app/client/session/session.cpp`
- `src/client/app/client/session/session.hpp`
- `src/client/app/client/viewer/viewer.hpp`
- `src/client/app/client/viewer/viewer_win32.cpp`
- `src/client/face/gui/content.hpp`
- `src/client/face/gui/detail/draw.hpp`
- `src/client/face/gui/hub.cpp`
- `src/client/face/gui/sheet.hpp`
- `src/client/face/gui/widgets.cpp`
- `src/client/face/ui/hud.cpp`
- `src/client/face/ui/hud.hpp`
- `src/client/face/ui/script/context.hpp`
- `src/client/face/ui/script/native_groups.hpp`
- `src/client/face/ui/script/native_pool.cpp`
- `src/client/figure/control/view_ray.cpp`
- `src/client/figure/control/view_ray.hpp`
- `src/client/app/client/display/graphic/fight.cpp`
- `src/client/app/client/display/graphic/fight_demo.cpp`
- `src/client/app/client/display/graphic/talk.cpp`
- `src/client/app/client/display/graphic/talk_demo.cpp`
- `src/client/app/client/fight/`
- `src/client/face/ui/panel/npc_talk.cpp`
- `src/client/face/ui/panel/npc_talk.hpp`
- `src/client/face/ui/panel/talk.hpp`


## Dev Sửa 2 (N-Z) — lô 1: engine/net (2026-10-15)

- [Ngoại lệ] Khung đầu tệp mẫu chung (12-18 dòng, đệm khoảng trắng theo mẫu) vượt giới hạn comment đầu tệp ở CLAUDE.md mục 0.3; theo chỉ đạo CTO, mẫu chung thắng. Không sửa check_style.js (hiện là stub, "cổng hình thức đã gỡ 2026-10-08").
- [Ghi nhận] TOOLS/source_headers/source_headers.py --fix dồn comment cũ vào CHỨC NĂNG thành văn xuôi và cắt ngang ý (vd shard.hpp), có khi đặt comment trên `#pragma once`; lô này viết CHỨC NĂNG tay, gộp nghĩa comment cũ vào khung (vai trò, vì sao, nguồn/khác gốc), bỏ comment cũ; khung đặt trước `#pragma once`.
- [Nghi bug, có sẵn trong HEAD, không do lô này] ctest `layers` đỏ: "tầng: play → bus (src/server/play/gameplay.cpp)". Đã kiểm bằng git: gameplay.cpp sạch (git status rỗng), dòng 19 `#include "bus/bus.hpp"` có từ commit 0805b5c0 (git blame); ghi trước đây cho rằng do thay đổi chưa commit là sai, đã sửa.
- [Yếu] engine/net/reactor_posix.cpp và socket_posix.cpp tự ghi "chưa chạy trên Linux thật" / "khôi phục 2026-10-15 viết lại"; nhánh POSIX chưa có bằng chứng chạy, nên có test trên Linux/Android.
## Soát vòng 1 (TL Soát Vòng 1, 15/10/2026)

- `src/server/play/gameplay.cpp`, dòng 19 - `#include "bus/bus.hpp"` vi phạm tầng play → bus; ctest
  `layers` đỏ (cmake/GameLayers.cmake:200). Dòng này đã nằm trong HEAD 0805b5c0 (commit 15/10 18:31),
  không phải thay đổi chưa commit và không do lô engine/net. Cần chủ commit đó xem lại tầng hoặc
  luật tầng.