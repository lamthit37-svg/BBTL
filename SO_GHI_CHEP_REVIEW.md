# SỔ GHI CHÉP REVIEW — AUDIT ĐA TÁC TỬ THIENLONG

- Ngày: 2026-10-17. Hình thức: audit tĩnh read-only, 9 đợt phân tích song song (Auditor/Red Team/
  Performance/Architect theo subsystem) + 1 vòng phản biện đối chất (Adversarial Reviewer/Arbiter)
  tự đọc lại mã cho mọi phát hiện HIGH và phần lớn MEDIUM.
- Phạm vi: 1.067 tệp C/C++ first-party (~205.486 dòng) trong `engine/`, `src/`; build system
  (CMakeLists, CMakePresets, cmake/*), `vcpkg.json`, `third_party/*` (NGUON/CMake glue),
  `dev/server/config`, `android/package_apk.py`, `Test/` (mẫu ~15/180 tệp), `TOOLS/` (greps +
  2 lệnh read-only).
- Mức tin cậy: **CONFIRMED** = arbiter/agent đã đọc trọn đường đi lỗi (gồm nhánh lỗi) trong mã;
  **PROBABLE** = bằng chứng mạnh nhưng thiếu một mắt xích hoặc cần runtime; **UNVERIFIED** = suy
  luận từ vắng mặt bằng chứng, chưa tái kiểm được trên máy này.
- Không có phát hiện CRITICAL nào được xác nhận trong phạm vi đã kiểm (xem mục "Phạm vi chưa kiểm" — chưa
  chạy build/test/sanitizer trong phiên này, nên không tuyên bố "sạch lỗi").
- Lệnh read-only đã chạy thật trong phiên: `python -B TOOLS/server/gen_protocol.py --check` (exit 0),
  `python -B TOOLS/server/lint_config.py` (26 tệp sạch, exit 0), test `layers` (exit 0).

---

## CRITICAL

Không có. Trong phạm vi đọc được, tầng decode mạng (wire/record/handshake/channel/link) đều fail-closed
với trần trước cấp phát; không tìm thấy đường RCE, double-spend hay dupe item nào từ dữ liệu mạng
đã đọc tới. Đây là kết luận trong phạm vi, không phải tuyên bố toàn dự án sạch (xem "Phạm vi chưa kiểm").

---

## HIGH

- **[HIGH][CONFIRMED] Speed-hack ~4–7×: bù jitter `kJitterTicks` được cấp lại MỖI tin Move, không
  có ngân sách theo thời gian | `src/server/guard/pace.cpp:15,75-77` | Bằng chứng:**
  `allowed = server_elapsed + kJitterTicks` (pace.cpp:75-76) với `kJitterTicks = 3` (dòng 15); mỗi `observe()` cộng đủ 3 tick mới bất kể bao nhiêu tin đã nhận trong cùng một motion tick
  (`server_tick_` chỉ bằng `server_tick` hiện tại nên tin thứ 2+ trong tick có `server_elapsed = 0`
  nhưng vẫn được +3). `measure` (dòng 29-41) chỉ so từng bước với `465 cm/s × elapsed/30 × 1.05 + 5`,
  bước nằm trong hạn thì `speed_debt_` không tăng (dòng 79-86) nên không bao giờ phạt. Rate limit
  cho phép đúng 60 tin/giây (`src/server/gate/table.cpp:1375-1386`, nạp 60×1000/giây, mỗi tin tốn
  1000; `dev/server/config/gate.toml:35 messages_per_second = 60`; vượt thì ngắt `Drop::kRate`
  table.cpp:1452-1456 — nên 60/s là mức ổn định, không bị đá). Phép tính, arbiter tự suy lại: 30 motion
  tick/giây (`gate/motion.hpp kMotionTickNs = 1e9/30`), ở 60 tin/giây mỗi tick nhận 2 tin → tin 1
  `allowed = 1+3 = 4`, tin 2 `allowed = 0+3 = 3` → 210 client-tick/giây so với 30 thật ≈ **7,3×**
  trần chạy; kể cả 30 tin/giây (1 tin/tick, `allowed = 4` mỗi tick) vẫn **4×**. Bước đơn tối đa
  `465×(4/30)×1.05+5 ≈ 70 cm`. Đường đi hoàn chỉnh đã đọc: `table.cpp:1248-1255` (`on_move` →
  `motion.judge`) → `kAccept` → `relay_move` `table.cpp:757-764` (gửi nguyên vị trí anchor cho zone,
  không throttle) → `src/server/zone/scene.cpp:276-292` (`blocked` chỉ tra `walkable` **điểm đến**).
  **Điều kiện tái hiện:** client đã đăng nhập, gửi 60 `Move`/giây, mỗi tin nâng `tick` 4 (hoặc 3) đơn
  vị và dịch chuyển ≤ ~70 cm (≤ ~54 cm), luôn trong hạn nên không bị `kRejected`/`kSpeed`/`kTeleport`.
  **Tác động:** người chơi di chuyển 4–7× nhanh hơn trần thật một cách bền vững, không bị kick;
  đồng thời phá giả định "bước ≤ 15,5 cm" mà luật đi zone dựa vào để chỉ kiểm điểm đến
  (`docs/SERVER-DI-CHUYEN.md:39,41`) → xuyên được chướng ngại mỏng tới ~0,7 m ở nơi lưới `.path`
  biểu diễn mảnh. **Root cause:** `kJitterTicks` là hằng cộng mỗi thông điệp thay vì token bucket
  được nạp lại theo `server_elapsed` và trừ khi dùng. **Hướng khắc phục:** biến bù jitter thành
  credit theo tick (nạp `server_elapsed`, trần 3–6, trừ theo bước đã dùng); thêm bước quét đoạn
  đường (raycast ô lưới) hoặc khoá cứng trần bước độc lập với tick; thêm test gửi nhiều
  `observe` trong cùng `server_tick`. **Kết quả phản biện:** (1) đã đọc toàn bộ
  `Test/Server/guard_tests.cpp` — helper `walk()` (dòng 26) nối client tick và server tick thành một,
  mọi ca mỗi lần gọi là một server tick mới; **không có ca nào** nhiều tin trong cùng tick → lỗ trống
  test đúng như bị cáo buộc. (2) `docs/NGHI-NGO.md` mục 39(g) và 54(b) đã ghi nhận "test Pace có điểm
  mù" và "chưa đo trần tốc độ gate có đủ chặn tường mỏng" — tức vấn đề được biết ở mức câu hỏi mở,
  nhưng con số 4–7×, nguyên nhân gốc (cấp lại mỗi tin) và cách sửa là phát hiện mới; nghiêm trọng
  hơn mức đã ghi. (3) Không chạy động để tái hiện (audit read-only) — mức CONFIRMED theo chứng cứ
  tĩnh đọc hết đường đi; số nhân 7,3× là suy diễn từ hằng số, chưa đo thực nghiệm.

- **[HIGH][CONFIRMED] Sandbox Lua bị phá từ đầu: `luaopen_io` trao toàn bảng `os` (gồm
  `os.execute` → `system()`) cho script giao diện | `src/client/face/ui/script/host.cpp:829-835`,
  `third_party/luaplus/LuaPlus/src/lib/liolib.c:818-831,837-847` | Bằng chứng:**
  `open_libraries` gọi `luaopen_io(lua)` (host.cpp:833) — hàm này `luaL_openlib(L, LUA_OSLIBNAME,
  syslib, 0)` với `syslib[]` chứa `execute` (`io_execute` → `system(luaL_checkstring(...))`,
  liolib.c:637,822), `exit`, `remove`, `rename`, `getenv`, `tmpname`, cộng bảng `io` đầy đủ
  (open/read/write). Comment host.cpp:829-831 nêu chủ ý chỉ cần `io.open`, `os.time`, `os.date` và
  kể các thứ **đã** gỡ (loadlib, debug, wstring, LOG) — nhưng không gỡ các thành phần nguy hiểm
  của `syslib`. **Điều kiện tái hiện:** mọi script trong `Script/Interface/` tải qua `windows.tsv`
  (host.cpp:919-925 `preload`), mọi chuỗi `SetTimer`/sự kiện chạy qua `run_code_in` →
  `load_and_call`; chỉ cần một lệnh `os.execute(...)` trong script. **Tác động:** thực thi lệnh
  OS tuỳ ý, đọc/ghi/xoá tệp tuỳ ý, đọc biến môi trường, thoát tiến trình từ ngữ cảnh script — thoát
  hoàn toàn khỏi "sandbox" mà host đang tự dựng (đã cố ý cấm loadlib/debug). **Root cause:** port
  `LuaState::Init(true)` mang theo `syslib` nguyên vẹn vì ba hàm cần thiết kéo theo cả bảng 2005.
  **Hướng khắc phục:** sau `luaopen_io`, xoá `execute/exit/remove/rename/tmpname/getenv` khỏi `os`;
  bọc `io.open` bằng hàm C gò đường dẫn về `Script/`/`Interface/`; giữ `os.time`/`os.date`.
  **Kết quả phản biện:** (1) Red team tìm **không có** đường từ dữ liệu mạng vào
  `DoString`/`loadbuffer` (nguồn code đều là tệp local hoặc chuỗi sự kiện do script đăng ký) — nên
  đây không phải RCE từ xa; (2) ngưỡng khai thác = quyền ghi thư mục asset, cùng ngưỡng như thay
  exe — nhưng script là thứ mod/chia sẻ dễ thay hơn exe nhiều, và asset nằm trong APK giải nén được;
  (3) bản gốc 2026 nhiều khả năng cũng mở đủ (port trung thành) — đây là quyết định hardening cần
  chốt chủ động, không phải lệch so với gốc; giữ HIGH vì là escape có chủ đích của lớp sandbox
  đang tự nhận là có containment.

- **[HIGH][CONFIRMED] Hai nguồn sự thật về nơi đặt gói vcpkg: tệp ngoài repo dùng FORCE đè giá trị preset,
  các cây build trên cùng máy đang lệch nhau | `cmake/VcpkgToolchain.cmake:9-14` +
  `C:\dev\third_party\vcpkg.cmake:8-13` (ngoài repo, không vào git) | Bằng chứng:**
  `VcpkgToolchain.cmake:11-12` — nếu tồn tại `<VCPKG_ROOT>/../third_party/vcpkg.cmake` thì nạp nó
  thay toolchain gốc; tệp đó `set(VCPKG_INSTALLED_DIR "C:/dev/third_party/installed" CACHE PATH
  ... FORCE)`, tương tự `FETCHCONTENT_BASE_DIR`, `VCPKG_DOWNLOADS`, `VCPKG_DEFAULT_BINARY_CACHE`.
  Đo thực tế trên máy: 9/10 cây build có `VCPKG_INSTALLED_DIR=C:/dev/third_party/installed`
  (android-arm64, android-x86_64, android-zc, i18n-vi, msvc-release-dev1/2/r1...), riêng
  `build/msvc-release` = `D:/THIENLONG/vcpkg_installed` (UNINITIALIZED — không đi qua nhánh FORCE);
  `C:/dev/third_party/installed` hiện chỉ có `arm64-android`, `x64-android`, `x64-windows`, `vcpkg`
  — **không có** `x64-windows-static-md` (Test-Path = False). **Điều kiện tái hiện:** configure bất
  kỳ preset nào khi tệp chung tồn tại/không tồn tại — kết quả phụ thuộc trạng thái máy, không phụ
  thuộc commit. **Tác động:** cùng một commit dựng vào hai cây package khác nhau trên cùng một
  máy; một tệp ngoài kho (không hash, không git) quyết định ABI của mọi phụ thuộc; gói của dự án khác
  trong cây chung có thể lọt vào; tái lập build/CI trên máy thứ hai là không được. **Root cause:**
  `CMakePresets.json` khai `VCPKG_INSTALLED_DIR` trong khi toolchain coi sự tồn tại của tệp chung
  là công tắc và tệp chung dùng FORCE — không chủ sở hữu duy nhất. **Hướng khắc phục:** chọn một
  trong: (a) bỏ `VCPKG_INSTALLED_DIR` trong preset, ghi chính sách cây chung vào tài liệu; hoặc
  (b) `if(NOT DEFINED VCPKG_INSTALLED_DIR)` trong toolchain + bỏ FORCE trong tệp chung. Không giữ
  cả hai. **Kết quả phản biện:** (1) đã đọc nội dung tệp chung và 10 CMakeCache bằng lệnh thật —
  không suy diễn; (2) agent build ban đầu cáo buộc thêm "toml++ sẽ trỏ sai → server biến mất", arbiter
  phát hiện cache `GAME_TOML_INCLUDE` vẫn trỏ đường C:/dev đã không còn trên đĩa (xem MEDIUM M3) —
  tách bạch thành hai finding, không cộng dồn; (3) không phải bug runtime nhưng là rủi ro chuỗi cung
  ứng/build, giữ HIGH theo tiêu chí "giao diện tích hợp third-party".

---

## MEDIUM

- **[MEDIUM][CONFIRMED] `SwapchainVk::take()` không đặt `is_stale_` khi `adopt_images` thất bại
  (trong khi `settle()` có đặt) → chuỗi swapchain "sống dở" chặn draw cho tới lần rebuild khác |
  `engine/gpu/vulkan/swapchain.cpp:335,339-347,386-393` | Bằng chứng:** `plan()` luôn
  `is_stale_ = false` (335); `take()` huỷ chain cũ, gắn chain mới rồi `return is_hidden() ? ok() :
  adopt_images(usage_)` (347) mà không kiểm kết quả — `settle()` thì có `if (!adopted) is_stale_ =
  true` (392). `is_current()`/`ready()` chỉ bị chặn bởi `is_stale_`. **Điều kiện tái hiện:**
  `vkCreateSwapchainKHR` thành công nhưng `adopt_images` lỗi (bộ nhớ table hết, `vkGetSwapchainImagesKHR`
  lỗi) trong lần resize. **Tác động:** black/frozen surface cho tới khi một path khác đặt stale
  (`OUT_OF_DATE` ở 504/559/618 hoặc 606) — không mất an toàn bộ nhớ (drop_images duyệt từng vector
  riêng). **Root cause:** nhánh lỗi của `adopt_images` không nối vào cờ stale. **Hướng khắc phục:**
  mirror `settle()`: sau `adopt_images` thất bại đặt `is_stale_ = true` (hoặc null `swapchain_`).
  **Kết quả phản biện:** agent GPU tự soát các nhánh `acquire/present` đặt stale đủ (504,559,606,618)
  — đúng, nhưng chúng chỉ chạy khi có acquire/present; chuỗi hỏng ngay ở khâu adopt thì không ai
  gọi tới; impact là chức năng, không phải UAF.

- **[MEDIUM][CONFIRMED] `~D3d12Device()` bỏ qua timeout 5 giây của fence rồi giải phóng tài nguyên
  GPU có thể còn in-flight | `engine/gpu/d3d12/device.cpp:256-266,762-776` | Bằng chứng:**
  `wait_queue()` gọi `WaitForSingleObject(event, 5'000)` và không đọc kết quả (264); destructor
  (762-776) gọi `wait_queues()` rồi `contexts_.reset()`, `drain(...)` mọi bảng, `retired_.flush()`
  không kiểm lại fence đã đạt. **Điều kiện tái hiện:** thoát tiến trình khi GPU đang treo/khung
  rất dài, quá 5 giây. **Tác động:** giải phóng bộ nhớ CommandList/Resources còn được GPU tham chiếu
  → UAF phía driver/TDR lúc thoát (không phải đường attacker-controlled). **Root cause:** timeout
  được chọn để không treo vô hạn nhưng nhánh fail coi như thành công. **Hướng khắc phục:** đọc mã
  trả về; nếu timeout → log + bỏ giải phóng (process đang thoát) hoặc bắt buộc coi như device-lost.
  **Kết quả phản biện:** đường `loss() != kNone` vốn đã bỏ qua wait — cùng rủi ro nhưng sau khi
  device-removed; bản vá cho nhánh "khoẻ nhưng treo" là đủ. Không chạy runtime để thấy TDR (thừa
  nhận: tĩnh).

- **[MEDIUM][CONFIRMED] `find_path(toml++)` HINTS trỏ cây vcpkg đang tranh chấp, và khi miss thì
  **im lặng** xoá toàn bộ module máy chủ khỏi build bằng một dòng STATUS | `CMakeLists.txt:345-347,418`
  | Bằng chứng:** `find_path(GAME_TOML_INCLUDE toml++/toml.hpp HINTS "${PROJECT_SOURCE_DIR}/
  vcpkg_installed/x64-windows-static-md/include")`; nhánh else: `message(STATUS "không thấy
  toml++/toml.hpp: bỏ các module, exe và test của máy chủ")`. Trên máy này cache đã resolve ra
  `C:/dev/third_party/installed/x64-windows-static-md/include` — thư mục **không còn tồn tại**
  (Test-Path False): cache cũ đang che đậy; configure lại từ đầu (xóa cache/clone mới) mà cây chung
  không có triplet static-md thì server biến mất khỏi ctest mà exit code vẫn 0. **Điều kiện tái
  hiện:** `git clone` mới hoặc `rm CMakeCache.txt` trên máy dùng toolchain chung. **Tác động:**
  CI/ctest "xanh" mà không dựng dòng server nào; nợ code tích tụ không bị phát hiện. **Root cause:**
  hard-code HINTS vào một bên đang thua trong tranh chấp cache + "không thấy" không phải lỗi.
  **Hướng khắc phục:** bỏ HINTS, để `CMAKE_PREFIX_PATH` của vcpkg dẫn đường; đổi fallback thành
  `FATAL_ERROR` sau một option `GAME_BUILD_SERVER`. **Kết quả phản biện:** arbiter kiểm tra trực tiếp
  và **hạ mức độ** so với bản cáo ban đầu (agent nói "server chắc chắn biến mất"): trên 5 cache
  hiện có thì `GAME_TOML_INCLUDE` vẫn có giá trị — rủi ro là tái cấu hình, không phải hiện tại;
  giữ MEDIUM.

- **[MEDIUM][CONFIRMED] Header `android_native_app_glue` không phải SYSTEM: một lần nâng NDK thêm
  warning là hỏng cả APK dưới `-Werror` | `CMakeLists.txt:1234-1236,1241` | Bằng chứng:**
  `target_include_directories(android_native_app_glue PUBLIC "${game_glue}")` (1235) và
  `target_include_directories(thienlong_activity PRIVATE "${game_glue}")` (1241) — đều `-I` thường;
  `android_main.cpp:41` `#include <android_native_app_glue.h>` (góc vuông nên qua luôn
  `game_reject_foreign`); 7 chỗ third-party khác đều SYSTEM (toml, sodium, luaplus, miniaudio, slang,
  SDL3, sse2neon). **Điều kiện tái hiện:** NDK upgrade thêm warning vào header glue. **Tác động:**
  nâng toolchain không đổi một dòng code nguồn cũng làm `thienlong_activity` (toàn bộ APK) đỏ.
  **Root cause:** third-party include quên gắn SYSTEM. **Hướng khắc phục:** thêm `SYSTEM` ở 1235
  và 1241. **Kết quả phản biện:** đã thấy bất đối xứng `-isystem` (SDL3) vs `-I` (glue) trong cùng
  compile_commands — không phải suy diễn; guard `COMPILE_WARNING_AS_ERROR OFF` (1236) chỉ áp cho
  TU của glue, không cho TU include nó.

- **[MEDIUM][CONFIRMED] `game_reject_foreign` dùng glob không `CONFIGURE_DEPENDS` + regex chỉ bắt
  include nhúng có dạng `"thành_phần_đầu_tiên/"` — né được bằng `#include <...>` hoặc `../` |
  `CMakeLists.txt:128-140` | Bằng chứng:** dòng 129 `file(GLOB_RECURSE ...)` không có
  `CONFIGURE_DEPENDS` (trong khi 1276/1310 có — bất đối xứng trong cùng tệp); regex 131 chỉ khớp
  `#include "lớp/chuỗi"` (chữ thường, dấu nháy kép) → `#include <server/x.hpp>` và
  `#include "../../server/zone/x.hpp"` lọt (chấm không thuộc lớp `[a-z0-9_]`). **Điều kiện tái
  hiện:** thêm tệp .cpp mới có include vi phạm khi chưa có gì chạm CMakeLists; hoặc include tương
  đối. **Tác động:** cổng kiểm kiến trúc lúc configure có thể xanh dù luật bị phá; thực chất ranh
  giới đang nằm ở include-path + test `layers`. **Root cause:** regex rẻ + glob cũ. **Hướng khắc
  phục:** thêm `CONFIGURE_DEPENDS`; chặn cả include nhúng có đường dẫn thoát cây module; giữ
  `layers` làm lưới. **Kết quả phản biện:** agent đã thử phản ví dụ (thêm include `../../server/...`
  không báo lỗi) — arbiter đọc regex xác nhận cú pháp; mức độ giảm vì `layers` test và ràng buộc
  link-module vẫn chặn thực tế (không target client nào link module server).

- **[MEDIUM][CONFIRMED] APK đóng gói fail-open: thiếu bảng quái/NPC hay bảng avatar vẫn ký APK
  thành công | `android/package_apk.py:59-66` (`creature_paths` trả `[]` khi thiếu tệp) và nhánh
  avatar/mobile tương ứng | Bằng chứng:** `creature_paths` trả `[]` khi
  `Table/creature.files.tsv` vắng mặt; comment trong tệp ghi rõ "không có danh sách thì APK không
  có quái, NPC... không phải lỗi chặn gói" — tức **quyết định có chủ ý**; chỉ `mobile.files.tsv`
  là bắt buộc. **Điều kiện tái hiện:** bỏ chạy `collect_creatures.py`/`collect_avatar.py` rồi đóng
  gói. **Tác động:** ship bản không có quái/avatar, lỗi chỉ lộ ở hiện trường. **Root cause:** mặc
  định "thiếu thì bỏ qua" thay vì "thiếu thì dừng". **Hướng khắc phục:** đổi mặc định sang fail,
  thêm cờ `--allow-missing-creatures` cho gói minimal có chủ đích. **Kết quả phản biện:** phản
  biện cho rằng đây là thiết kế (comment giải thích) — đúng một phần, nên ghi nhận là quyết định
  nhưng vẫn là rủi ro vận hành; giữ MEDIUM vì chi phí sửa 1 dòng.

- **[MEDIUM][CONFIRMED] Bản dựng Android đi hàng không (GAME_HARDEN tắt) và `android-x86_64` là
  Debug; AGENTS.md mô tả sai triplet của nó | `CMakePresets.json` (GAME_HARDEN ON chỉ ở dòng 137
  `ci-gcc` và 173 `msvc-release`; `android` preset CMAKE_BUILD_TYPE=Debug; `android-x86_64` không
  override) | Bằng chứng:** đọc trực tiếp JSON preset: chỉ `msvc-release`, `ci-gcc` có
  `GAME_HARDEN=ON`; `GameHarden.cmake:10-12` return khi OFF → Android không có
  `-D_FORTIFY_SOURCE=3`; `android-x86_64` kế thừa Debug và đặt triplet `x64-android` (không phải
  `arm64-android` như AGENTS.md nói). **Điều kiện tái hiện:** dựng preset android-arm64 (bản
  RelWithDebInfo `CMAKE_INSTALL_PREFIX=release/` — bản ship) và so flags. **Tác động:** xếp hạng
  hardening bị đảo (bản dev desktop harden, bản ship mobile không); build mô phỏng (Debug,
  triplet khác) không test cấu hình ship; AGENTS.md sai lệch thực tế. **Root cause:** GAME_HARDEN
  không bao giờ bật cho các preset android; preset android-x86_64 thiếu cờ; tài liệu không cập nhật.
  **Hướng khắc phục:** bật `GAME_HARDEN` cho 2 preset android (kiểm NDK 30 hỗ trợ
  `_FORTIFY_SOURCE=3` trước), set `CMAKE_BUILD_TYPE=RelWithDebInfo` cho x86_64, sửa dòng
  AGENTS.md. **Kết quả phản biện:** delta thật của hardening Android nhỏ hơn desktop (NDK mặc định
  đã `_FORTIFY_SOURCE=2` + `stack-protector-strong`, PIE mặc định) — nên MEDIUM không phải HIGH;
  điểm nhấn là sai lệch cấu hình ship/mô phỏng và sai lệch tài liệu.

- **[MEDIUM][CONFIRMED] `thienlong_i18n` không thuộc `all` và không có dependency nào từ
  `thienlong_client` — mâu thuẫn trực tiếp với AGENTS.md "chạy ở mỗi lượt dựng client" |
  `cmake/GameI18n.cmake:29`, `CMakeLists.txt:1161-1162` | Bằng chứng:** `add_custom_target(
  thienlong_i18n ...)` không có ALL; grep toàn `CMakeLists.txt` không có
  `add_dependencies(thienlong_client thienlong_i18n)` (có `thienlong_scripts` ở 1175,
  `thienlong_mobile_textures` ở 1224); `build/msvc-release/build.ninja`: dòng `build all: phony`
  không chứa `thienlong_i18n` (4 dòng ninja duy nhất của target này không ai phụ thuộc).
  **Điều kiện tái hiện:** xoá output i18n trong `dev/client/assets` rồi `cmake --build --preset
  msvc-release` (không `--target`) → vắng mặt, client vẫn dựng. **Tác động:** sửa `assets/i18n`
  không có tác dụng tới client, devs hiểu nhầm vì tài liệu nói có. **Root cause:** target bị chủ
  đích bỏ khỏi ALL nhưng quên thêm dependency + không sửa tài liệu. **Hướng khắc phục:**
  `add_dependencies(thienlong_client thienlong_i18n)` + sửa câu AGENTS.md. **Kết quả phản biện:**
  đã kiểm bằng chính build.ninja (không suy diễn); có thể có chủ đích giữ ALL sạch (i18n chạy ở
  preset i18n-vi riêng) — nếu đúng thì bên sai là tài liệu; một trong hai phải sửa.

- **[MEDIUM][CONFIRMED] 39/41 bộ test Python của TOOLS không nằm trong ctest — chuỗi cung ứng dữ
  liệu regress mà kiểm chuẩn vẫn xanh | `cmake/GameI18n.cmake:38,42` (chỉ 2 add_test Python),
  inventory `add_test` toàn repo = 10 dòng (C++ đi qua wrapper `CMakeLists.txt:1383`) |
  Bằng chứng:** đếm `test_*.py` trong TOOLS = 41; chỉ `test_build_i18n.py`,
  `test_bake_mobile_textures.py` có `add_test`; không có lệnh `unittest discover` nào trong
  cmake/. **Điều kiện tái hiện:** regress trong `tsv_file.py`, `gen_protocol.py` (ngoài ca --check),
  `dialogue_i18n.py`... → `ctest` vẫn xanh. **Tác động:** dữ liệu xuất sai (TSV lệch cột, sai chữ)
  tới tay client/server mà không có cổng chặn; project có test nhưng không chạy. **Root cause:** test
  Python viết theo lệnh tay, không nối vào graph ctest như C++. **Hướng khắc phục:** một
  `add_test(NAME py_tool_tests COMMAND ${Python3_EXECUTABLE} -B -m unittest discover -s TOOLS
  -p "test_*.py")` (hoặc theo từng thư mục, loại test cần dữ liệu nguồn lớn). **Kết quả phản biện:**
  đã đếm lại `add_test` thật (10 dòng, đúng 2 dòng Python) — không phải ước lượng; lý do có thể là
  thời gian chạy/điều kiện data, nhưng hiện tại không có cơ chế skip/label nào ghi nhận điều đó.

- **[MEDIUM][CONFIRMED] Đăng ký ctest `protocol_fuzz` là mã chết: tệp test không tồn tại, decoder
  thù địch chỉ được phủ bằng sample tĩnh | `CMakeLists.txt:1847-1849`,
  `Test/Protocol/` (chỉ `protocol_catalog_tests.cpp`, `protocol_tests.cpp`, `protocol_samples.hpp`) |
  Bằng chứng:** `game_test(protocol_fuzz game_protocol)` bọc trong `if(EXISTS ...protocol_fuzz_
  tests.cpp)` — Test-Path = False; harness libFuzzer ở `Test/fuzz/` chỉ chạy ngoài CMake qua
  `TOOLS/server/fuzz_protocol.py`. **Điều kiện tái hiện:** thêm regression vào wire decoder → ctest
  không có test generative nào bắt. **Tác động:** lớp quan trọng nhất (gói tin mạng) chỉ có
  round-trip sample cố định; project tự xếp dữ liệu mạng là thù địch. **Root cause:** tầng fuzz theo
  kế hoạch (điểm P2) chưa được viết, đăng ký có điều kiện che mất việc thiếu. **Hướng khắc phục:** viết
  `protocol_fuzz_tests.cpp` quét mẫu đối nghịch (truncated, bit-flip, length 0xFFFFFFFF) trên
  corpus cố định, hoặc đăng ký `fuzz_protocol.py` với ngân sách `--runs` thấp vào ctest.
  **Kết quả phản biện:** `protocol_catalog_fresh` (content-hash) + ca truncation/bad-enum trong
  `protocol_catalog_tests` (agent đọc: truncation từng độ dài, bad enum, millis64 range) vẫn là lưới
  thật — nên là MEDIUM phủ nhuận, không phải "không có test"; đã kiểm `--check` exit 0 trong phiên.

- **[MEDIUM][CONFIRMED] `pack_message` ghi chiều dài 1 byte → tràn wraps với args > 255 byte làm
  lệch khung tin chat/debug | `src/client/face/ui/script/message_format.cpp:33,39,44,49` |
  Bằng chứng:** kiểm tra trần duy nhất là tổng ≤ 1024 (dòng 33); chiều dài từng arg ghi
  `static_cast<char>(static_cast<std::uint8_t>(arg.size()))` (44) và byte tổng (49) đều wraps ở
  256; `kPadAt` chỉ xử lý đúng một giá trị wraps (0x38). Người gọi
  (`native_format.cpp:37-56 ScriptGlobal_Format`) nhận chuỗi script bất kỳ. **Điều kiện tái hiện:**
  script gọi `ScriptGlobal_Format(mẫu, arg)` với arg 256–~1000 byte. **Tác động:** hiện tại người
  tiêu thụ là script Lua (đọc bằng chuỗi Lua — không OOB C++) → hiển thị sai/nội dung lệch khung;
  `FUN_14007af80(3)` (người tiêu thụ C++ gốc) **chưa port** (host.cpp:774) — khi port mà tin cậy
  byte độ dài sẽ là đọc quá biên. **Root cause:** port trung thành trường 1 byte mà không ép ràng
  buộc ≤255 ở đầu vào mới. **Hướng khắc phục:** `pack_message` trả `nullopt` (hoặc cắt theo chính
  sách ghi rõ) khi `arg.size() > 255` hoặc tổng > 255. **Kết quả phản biện:** đã đọc toàn hàm —
  không có phép chặn (clamp) nào giữa `text_arg` và bước ghi; `find('\0')` giới hạn view trả về nên chưa có ghi
  quá biên C++; giữ MEDIUM vì là vi phạm hợp đồng khung đã sinh và tạo bẫy cho lần port sau.

- **[MEDIUM][CONFIRMED] Cảnh server đẩy chuyển cảnh (`Arrive`) chạy `world::enter` (đọc/parse đĩa
  đồng bộ) ngay trên luồng cửa sổ | `src/client/app/client/host/host.cpp:130-141` (`Online::follow`),
  `src/client/app/client/viewer/viewer_win32.cpp:618-636` (`follow_scene`) | Bằng chứng:**
  `Online::on_frame` (143) chạy trên vòng lặp nền tảng; `follow()` gọi thẳng
  `world::enter(playing, arrive.scene, scenes)` (134) inline trước pump kế tiếp; không tách luồng,
  không progress. Đường đổi cảnh do người chơi tự khởi xướng thì đã đi streamer bất đồng bộ
  (`begin_load`/`post_load`). **Điều kiện tái hiện:** mọi lần dịch chuyển do server đẩy (teleport,
  vào bản đồ mới). **Tác động:** treo input/paint hàng trăm ms (cảnh lớn), >5s thì Windows hiện
  "not responding" — chất lượng, không phải đúng-sai; trái với mục tiêu ngân sách nạp đầu của
  project. **Root cause:** đường nạp đồng bộ thiết kế cho boot được dùng lại nguyên cho đường đẩy
  từ server. **Hướng khắc phục:** hoãn sang streamer sẵn có (đã bất đồng bộ cho đường local) rồi
  post kết quả về. **Kết quả phản biện:** đã đối chiếu hai đường đi (local async vs server sync) —
  đúng bất đối xứng; không đo thời gian stall thực tế (thừa nhận: ước lượng theo ngân sách nạp
  450 ms đã công bố, chưa chạy đo trong phiên).

- **[MEDIUM][CONFIRMED] `gate_attack` là target C++ duy nhất trong cây không link
  `game::warnings` — thiếu `/W4 /permissive- /utf-8 /Zc:__cplusplus` | `CMakeLists.txt:1875-1877`,
  `build/msvc-release/build.ninja:20196` | Bằng chứng:**
  `target_link_libraries(gate_attack PRIVATE game_secure game_protocol ws2_32 psapi)` — không
  `game::warnings`; dòng ninja `FLAGS = ... -std:c++23preview -MD -Zi /guard:cf /sdl -WX` — quét
  1.236 dòng `std:c++23` trong build.ninja có đúng **1** dòng thiếu `/W4` là dòng này. **Điều
  kiện tái hiện:** dựng target. **Tác động:** TU này compile ở mức `/W1` — project có quy tắc
  "0 warning, mọi target qua game::warnings"; comment tiếng Việt UTF-8 không có `/utf-8` đọc theo
  ACP (lỗi hiển thị/lỗi lạ tiềm tàng); `__cplusplus` đọc 199711 ở TU này. Tác động giới hạn vì
  đây là bench tool, không vào ctest. **Root cause:** thêm target không kèm warnings.
  **Hướng khắc phục:** thêm `game::warnings`. **Kết quả phản biện:** **sửa một phần cáo buộc của
  agent build**: agent nói "thiếu -WX" — arbiter thấy `-WX` có mặt (đến từ `CMAKE_COMPILE_WARNING_
  AS_ERROR` toàn cục) nhưng vô nghĩa khi không có `/W4`; phần lõi (thiếu W4/permissive/utf-8/
  Zc:__cplusplus) CONFIRMED bằng chính build.ninja.

---

## LOW

- **[LOW][CONFIRMED] Hàng đợi sự kiện đầy khi đang `kResuming`: `emit` đặt `kLost` nhưng không
  xoá `want_resume_`/token → client tự nối lại một vòng sau khi game đã báo mất phiên |
  `src/client/app/client/session/session.cpp:400-405` (nhánh lỗi `emit`) so với `give_up()` 423-426 |
  Bằng chứng:** nhánh push thất bại chỉ `line_.reset(); roster_.clear(); set_phase(kLost)` —
  `give_up()` thì có `want_resume_ = false; wipe_token()`. **Điều kiện tái hiện:** hàng đợi 256
  phần tử đầy đúng lúc một lượt Resume đang bay (consumer chậm, Android pause). **Tác động:** một
  lần kết nối+`Resume` thừa; gate trả `kNoSession` cho token đã dùng → dừng; trạng thái nửa vời
  trong lúc đó, không mất an toàn bộ nhớ. **Root cause:** nhánh đầy hàng đợi dùng lại `emit` thay
  vì đường tháo `give_up`. **Hướng khắc phục:** trong nhánh push thất bại thêm
  `want_resume_ = false; tries_ = 0; wipe_token()` (không emit `Lost` lần hai vì `note_full` đã ghi).
  **Kết quả phản biện:** các đường mất khác (`lose`/`give_up`) đều dọn sạch; `resume_again`
  (machine.cpp) chặn gửi token lần hai trên dây; agent đã kiểm — arbiter đọc xác nhận hai nhánh
  khác nhau.

- **[LOW][CONFIRMED] Phông AXFT: tràn `uint32_t` trong `layout_of` → `index_at` underflow →
  `string_view::substr` ném `std::out_of_range` không ai bắt → terminate lúc nạp phông |
  `src/client/face/ui/pace.cpp:94-97` (phép nhân `8U*range_count` 32-bit), `:622`
  (`glyphs_at - 4*kIndexEntries`), `:110` (`bytes.substr(origin,...)`) | Bằng chứng:**
  arbiter tự dựng phản-ví-dụ số học: chọn `range_count` để `ranges = kHeaderBytes + 8*range_count`
  wrap về giá trị nhỏ; header khai `ranges_at/index_at/glyphs_at` khớp giá trị đã wrap thì
  `is_placed`/`is_tail` đều qua; `open()` tính `index_at = glyphs_at - 4*kIndexEntries` underflow
  về số khổng lồ → `substr` ném. **Điều kiện tái hiện:** tệp phông (asset local) bị tạo/cắt sai.
  **Tác động:** crash tiến trình khi nạp phông (preload thread hoặc render thread, không ai
  try/catch) — không có OOB đọc (ném trước khi đọc). **Root cause:** kiểm layout bằng số học 32-bit
  trên dữ liệu do tệp khai rồi dùng làm `size_t` origin. **Hướng khắc phục:** dựng phép kiểm ở
  `size_t`, thêm điều kiện `glyphs_at >= 4*kIndexEntries` và mọi offset ≤ `bytes.size()`; hoặc
  `index_of` trả `expected`. **Kết quả phản biện:** phông thật có `range_count` vài trăm, xa biên
  wrap — kiểm thêm vẫn qua; yêu cầu ghi asset nên là LOW.

- **[LOW][CONFIRMED] Phím PageUp/PageDown đổi cảnh local không bị chặn khi đang online → desync
  client/server | `src/client/app/client/viewer/viewer_win32.cpp:160-162,375-381` | Bằng chứng:**
  `direction_of(key)` trả ±1; `can_change = has_world && step != 0 && !is_repeat` (377) — không
  kiểm phiên mạng; `controls.maps->pending.fetch_add(step)` (379) dẫn tới `world::enter` (201).
  **Điều kiện tái hiện:** bấm PageUp/Down khi đã vào game online. **Tác động:** toạ độ scene mới
  gửi vào AOI scene cũ; server kéo về bằng `Position`; không mất an toàn bộ nhớ. **Root cause:** phím
  debug cho trình xem map chưa gạt theo trạng thái phiên. **Hướng khắc phục:** bỏ qua phím khi
  bridge báo phiên đang mở. **Kết quả phản biện:** đã đọc đủ điều kiện `can_change` — không có nhánh
  online nào trong đó.

- **[LOW][CONFIRMED] Carrier (UDP) thiếu trần byte ở phía nhận tái lắp ráp tin tin cậy — tới ~100 MB/
  kết nối nếu exposed | `engine/net/detail/pipe.hpp` (kRecvWindow 256, kChunk 1024,
  kMaxReliableFrags 96, kCarrierLanes 4), `engine/net/inlet.cpp:96-101` (`pieces.resize(count)`
  không tổng trần byte) | Bằng chứng:** phép nhân hằng số 256×96×1024×4 ≈ 100 MB; send-side có
  `kReliableBudget`, receive-side chỉ có `kRecvWindow`/`kMaxPartial` (unreliable). **Điều kiện tái
  hiện:** chỉ khi Carrier nhận lưu lượng thật — **red team xác nhận Carrier hiện chỉ nằm trong
  test/bench** (grep: không có trong đường client/gate thật; lưu lượng thật đi TCP +
  `Channel` + `RecordPipe` + `Link`). **Tác động:** latent DoS bộ nhớ trước khi bật UDP. **Root
  cause:** trần ngân sách chỉ có ở chiều gửi. **Hướng khắc phục:** thêm `kRecvReliableBudget`
  (1–2 MiB/lane), quá thì drop fragment. **Kết quả phản biện:** đã xác nhận không nằm trên đường
  sống → giữ LOW (latent), nhưng phải sửa trước mọi bước expose UDP.

- **[LOW][CONFIRMED, module chưa nối] `Arena::deal`: clamp `max(damage, 0)` nằm trong
  `if (attacker != nullptr)` trong khi hook chạy cả khi attacker null → damage âm thành heal |
  `src/server/combat/arena_damage.cpp:121-138` (clamp ở 133), `src/server/combat/arena_buff.cpp:481-495`
  | Bằng chứng:** `run_on_damage` duyệt buff của nạn nhân và gọi `logic->on_damage(ctx, attacker,
  damage, skill)` bất kể `attacker` null (attacker chỉ là tham số); DoT/buff sống lâu hơn người
  thả (ra khỏi arena) vẫn sửa `damage`; clamp bị bỏ qua khi null → `change_hp(..., -(-x))` là heal.
  **Điều kiện tái hiện:** bảng hiệu ứng cấu sai (absorb >100% với khiên lớn, amp < −100 —
  `effects.tsv` không bị range-clamp lúc nạp catalog theo agent); với bảng chuẩn thì
  `AbsorbPercent` đã gò về damage nên không xuống âm. **Tác động:** heal thay vì sát thương; module
  `combat` **chưa nối zone/world/gate** (AGENTS.md) → latent. **Root cause:** clamp gắn với sự có
  mặt của attacker thay vì với việc hook có thể làm âm. **Hướng khắc phục:** chuyển
  `damage = std::max(damage, 0);` ra ngoài nhánh `attacker != nullptr` (dời 1 dòng). **Kết quả phản
  biện:** agent tự kiểm ngược "bảng chuẩn không xuống âm" — đồng ý; giữ LOW vì chưa nối và cần
  dữ liệu sai để nổ.

- **[LOW][CONFIRMED, module chưa nối] Retag quan hệ (ly hôn/ở thầy/đuổi học trò) gò vào nhóm cuối
  khi danh sách đầy → sheet vượt trần nhóm, lần nạp sau `decode_relation` từ chối → mất cả sổ quan
  hệ | `src/server/social/relation.cpp:610,615,635,642,662,669,770` (7 chỗ
  `min(first_free_group(...), kFriendGroups-1)`), kiểm tại `:827` (`decode_relation` gọi
  `sheet_problem`), `:155` ("quá tràn một nhóm bạn") | Bằng chứng:**
  `check_request` (301-302) chặn thêm bạn khi `first_free_group == kFriendGroups` — các đường retag
  **không** kiểm tương tự; `encode_relation` (780) không validate. **Điều kiện tái hiện:** người
  chơi đủ số nhóm bạn ở mức trần rồi ly hôn/đuổi học trò. **Tác động:** mất sổ quan hệ ở lần đăng
  nhập kế (data loss cho người chơi); không lợi kinh tế; module `social` chưa nối zone → latent.
  **Root cause:** bất biến được kiểm ở boundary (load/decode) nhưng không kiểm ở từng đường mutate.
  **Hướng khắc phục:** khi `first_free_group == kFriendGroups` thì xoá entry (hoặc đẩy bạn cũ ra)
  thay vì gò vào nhóm cuối; thêm ca test "đầy nhóm + retag". **Kết quả phản biện:** đã đọc 7 vị
  trí thật (agent nêu 3 — arbiter bổ sung 401-402, 615, 642, 669, 770 là cùng mẫu; 401-402 thuộc
  `answer` hợp lệ vì có kiểm ở `check_request` trước — chỉ retag mới lách); đã xác nhận module
  chưa nối nên giữ LOW.

- **[LOW][PROBABLE] `JobSystem::share` deref `job.counter` trong `catch (...)` khi counter có thể
  nullptr theo hợp đồng | `engine/jobs/jobs.cpp:1207-1212`, `jobs.hpp:445,520` |
  Bằng chứng:** `run_batch_detached` truyền `counter = nullptr`; `share_owned` gán vào
  `job.counter`; catch bắt `*job.counter` không kiểm. **Điều kiện tái hiện:** API mới gọi `share()`
  với counter null — **hiện tại mọi call site (`jobs.hpp:541` parallel_for) đều counter khác null**
  (agent đã grep toàn bộ). **Tác động:** null deref → crash. **Root cause:** hợp đồng "counter không
  null" không được enforce bằng kiểu (nên nhận `JobCounter&`). **Hướng khắc phục:** kiểm
  `job.counter` trong catch, hoặc đổi chữ ký. **Kết quả phản biện:** latent — không reach được từ
  mã hiện có; PROBABLE cho lần dùng sau.

- **[LOW][PROBABLE] `Frame(w,h,fmt)` nhân `size_t` không kiểm tràn | `engine/capture/frame.hpp:86-87` |
  Bằng chứng:** `pixels_(std::size_t{width} * height * pixel_size(format))` — (2³²−1)² vượt
  `size_t`. **Điều kiện tái hiện:** chỉ khi gọi với cỡ thù địch; caller thật (`png.cpp`, capture)
  dùng cỡ màn hình. **Tác động:** OOB ghi ảnh nếu nổ. **Root cause:** thiếu guard tràn. **Hướng
  khắc phục:** kiểm `width && height && width <= SIZE_MAX/height/...` trước. **Kết quả phản biện:**
  grep mọi `Frame(` — chỉ caller cỡ thật; latent.

- **[LOW][CONFIRMED] `File::close` nhả sở hữu trước khi `CloseHandle` — nếu close fail thì handle
  rò vĩnh viễn | `engine/fs/file.cpp:475-476` | Bằng chứng:** `raw = handle_.release()` rồi
  `closed = raw == nullptr || CloseHandle(raw) != 0` — sau `release()` không ai close lại khi
  `CloseHandle` trả 0. **Điều kiện tái hiện:** CloseHandle fail (hiếm). **Tác động:** rò handle OS.
  **Root cause:** thứ tự release/close sai. **Hướng khắc phục:** close qua `handle_.get()` trước,
  chỉ release khi thành công. **Kết quả phản biện:** mọi chỗ khác trong engine dùng RAII tự close
  — đây là ngoại lệ một dòng.

- **[LOW][CONFIRMED] Phép nhân kích thước trong phản chiếu SPIR-V/DXIL tràn `uint32_t` trên blob
  thù địch | `engine/shader/spirv.cpp` (đếm mảng, `member_size`), `engine/shader/dxil.cpp`
  (`element_size`) | Bằng chứng:** stream word/bounds-checked chắc (agent đọc
  `word()/record_next/slice/definition`), điểm mềm chỉ ở số phái sinh. **Điều kiện tái hiện:** gói
  shader không từ pipeline nấu của dự án. **Tác động:** layout bind sai → GPU-side OOB khả năng;
  heap host vẫn in-bounds. **Root cause:** nhân không kiểm tràn trên metadata do đối phương khai.
  **Hướng khắc phục:** `std::ckd_mul`/reject khi tràn. **Kết quả phản biện:**
  `package.cpp` checksum/bounds đã kiểm — chỉ phần phái sinh; chưa có mẫu SPIR-V xấu để demo hết
  (thừa nhận).

- **[LOW][PROBABLE] `DescriptorArena` của D3D12 không hợp nhất vùng trống → phân mảnh, cấp phát
  thất bại `kExhausted` dù tổng còn | `engine/gpu/d3d12/resources.cpp` (tách ô khi allocate, không
  merge khi free) | Bằng chứng:** agent đọc logic tách/ghi — toán đúng, thiếu coalesce. **Điều
  kiện tái hiện:** phiên dài tạo/hủy view biến thiên. **Tác động:** resource creation fail, tái
  tạo được — không mất an toàn. **Hướng khắc phục:** merge ô kề khi free. **Kết quả phản biện:**
  chỉ fragmentation, không phải lỗi tính toán — PROBABLE cho mức độ xảy ra thực tế.

- **[LOW][PROBABLE] Vulkan: list mở (`open()` tăng mark `recording_`) mà không submit rồi bị hủy
  → mark mất cặp, deferred-destroy bị chặn tới khi destructor flush | `engine/gpu/vulkan/device.cpp`
  (`recording_`/`submitted`), `engine/gpu/vulkan/retire.hpp` | Bằng chứng:** ngưỡng thu hồi dùng
  `submitted + recording_`; đường `reject()` rồi hủy list không bù. **Điều kiện tái hiện:** path
  lỗi giữa open và submit. **Tác động:** leak có chặn (flush ở destructor dọn). **Hướng khắc
  phục:** khi hủy list chưa submit, trừ `recording_`. **Kết quả phản biện:** không phải UAF
  (deferred lại giữ), chỉ giữ đồ quá hạn — LOW.

- **[LOW][PROBABLE→hạ tin cậy] `wait_idle` đọc `queue.submitted` không qua `queue.mutex` trong
  khi đường ghi có mutex | `engine/gpu/d3d12/device.cpp:256+`, `device.hpp:181` | Bằng chứng:**
  agent báo "mọi mutex"; arbiter kiểm: `queue.submitted.load()` là **atomic** (dòng 257:
  `queue.submitted.load()`) → **không có data race**; vấn đề còn lại là thứ tự "submit khác luồng
  vừa signal sau khi wait đọc" — xảy ra với mọi thiết kế kể cả có mutex. **Kết quả phản biện:**
  hạ từ cáo buộc ban đầu thành nuance thiết kế; khuyến nghị ghi hợp đồng (wait_idle không bảo vệ
  khỏi submit đồng thời) thay vì thêm khoá.

- **[LOW][CONFIRMED] `answer_reject` gắn nhãn Reject bằng `pending_` đã cũ (vd lỗi đăng nhập thay
  "không có nhân vật đó") | `src/client/app/client/session/session.cpp:858-869` |
  Bằng chứng:** `pending_` chỉ ghi ở `send_request`/`open_game`, không xoá khi kết thúc chờ
  (roster về, resume bắt đầu). **Điều kiện tái hiện:** gate gửi `Reject` ngoài cửa sổ request
  (gồm đường `kResuming` → `kNoSession` bình thường). **Tác động:** câu báo người chơi sai —
  không hỏng trạng thái. **Hướng khắc phục:** reset `pending_` về giá trị "không có" khi mọi trả
  lời phi-Reject kết thúc chờ và trong `try_resume`. **Kết quả phản biện:** các Reject thật sự
  trả lời request đã có nhãn đúng — chỉ các ca trễ sai; agent đọc đủ, arbiter xác nhận pattern.

- **[LOW][CONFIRMED] `pack`/host nạp script **không** qua lệnh cấm chunk nhị phân mà `State::load`
  có | `src/client/face/ui/script/host.cpp:268-269` so với `src/client/face/lua/state.cpp:365-368` |
  Bằng chứng:** `State::load` từ chối source bắt đầu `\x1B` ("chunk nhị phân không được nạp");
  `load_and_call` gọi thẳng `luaL_loadbuffer` cho script `windows.tsv`, chuỗi `SetTimer`, `DoString`.
  **Điều kiện tái hiện:** tệp script (asset local) có byte đầu 0x1B → `lundump.c` 2005 (lịch sử
  dễ hỏng về bộ nhớ; allocator cap+hook hạn chế nhưng không phủ undump). **Tác động:** chính sách
  an toàn của project bị lách ở đường nạp chính; chưa có mẫu nhị phân để chứng minh UB cụ thể
  (thừa nhận). **Root cause:** hai đường nạp, đường "được harden" không phải đường host dùng.
  **Hướng khắc phục:** route host qua `State::load`, hoặc nhân đôi kiểm `\x1B` ở `load_and_call`
  và các nguồn chuỗi sự kiện. **Kết quả phản biện:** xếp LOW (tệp local, chưa demo được undump
   hỏng) — lệch với agent (MEDIUM); arbiter giữ LOW vì chưa chứng minh được lan truyền thành
  corruption, chỉ chứng minh được chính sách bị bỏ qua. **Bất đồng ghi lại:** agent xếp MEDIUM,
  arbiter xếp LOW — chốt LOW do thiếu bằng chứng hiệu ứng; nếu port test undump thấy UB thì nâng.

- **[LOW][CONFIRMED] 39 bộ test Python + không có CI → các cổng tự động hiện có chỉ chạy khi
  người nhớ chạy | repo (không có `.github/`, `.gitlab-ci.yml`, `Jenkinsfile` — agent quét) |
  Bằng chứng:** quét tên tệp CI = 0; kết hợp finding "39/41 test Python không vào ctest".
  **Tác động:** `protocol_catalog_fresh`, `server_config_lint`, `layers` (đều xanh hôm nay) không
  có protection liên tục. **Hướng khắc phục:** pipeline tối thiểu chạy `ctest -E "audio_tests|
  window_modal_tests"` + `unittest discover TOOLS`. **Kết quả phản biện:** thiếu CI là trạng thái
  vận hành, không phải bug mã — giữ LOW, ghi rõ là khoảng trống quy trình.

- **[LOW][CONFIRMED] Test dữ liệu thật "soft-pass": thiếu data thì `expect(true)` → xanh giả che
  mất lỗ trống cover | `Test/Client/map_tests.cpp:818-820`, `Test/Audio/audio_tests.cpp:524`,
  `Test/Loot/loot_roll_tests.cpp:236` | Bằng chứng:** pattern `expect(true, "không có thư mục
  data...")`; CMake gate biến biên dịch nhưng test vẫn chạy và báo "đạt". **Tác động:** hợp đồng
  1957 gate/sound/loot trên dữ liệu thật không được kiểm ở máy chưa chạy collect/export, mà ctest
  vẫn xanh. **Hướng khắc phục:** return 77 + `SKIP_RETURN_CODE` (mẫu `collision_tests` đã dùng).
  **Kết quả phản biện:** pattern có chủ đích và có comment; framework `test.hpp` không có khái niệm
  skip → đây là gap framework, không phải lỗi lẻ.

- **[LOW][CONFIRMED] APK/preset/đường dẫn vặt tích tụ của build: (a) `compile_db` chép
  `compile_commands.json` vào gốc repo lúc build (không lúc configure) → clangd dùng bản cũ
  (đã đo: bản gốc 12:32 vs bản tree 13:55); (b) preset iOS không kế thừa `base`/`vcpkg`;
  (c) `ANDROID_NDK_HOME` không được validate trong khi `VCPKG_ROOT` có
  (`cmake/VcpkgToolchain.cmake:5-7`);   (d) MSVC thiếu `/Brepro` (build không tái lập từng byte) và
  genex `$<$<CONFIG:Release>:-g>` ở `cmake/GameDebugInfo.cmake:8` là mã chết (không preset nào
  dùng `Release`); (e) không có `INSTALL_RPATH` nào trong repo → bản cài Linux (mục tiêu đã nêu)
  chưa từng dựng sẽ chết "error while loading shared libraries" (UNVERIFIED — không có cây Linux
  trên máy để kiểm); (f) `third_party/miniaudio/NGUON.txt` thiếu SHA-256 (libsodium, luaplus có);
  (g) `TOOLS/server/fuzz_protocol.py:115` dùng `"SRC"` hoa (hiện vô hại vì `CORE_SOURCES` rỗng,
  sẽ vỡ trên Linux case-sensitive). **Tác động:** từng cái nhỏ (devex, tái lập, port).
  **Hướng khắc phục:** từng dòng một như mô tả. **Kết quả phản biện:** (a)-(d),(f),(g) đọc/tính
  trực tiếp CONFIRMED; (e) là suy luận từ vắng mặt → để UNVERIFIED trong nhóm này.

- **[LOW][CONFIRMED] Mã debug tạm còn trong bản dựng: `TMPGOV` (tắt frame governor qua
  `debug.thienlong.nogov`, `src/client/app/client/display/graphic/face.cpp:32-50,544`) và `TMPEXP`
  (đọc `debug.thienlong.texp` đổi flag terrain, `engine/render/forward.cpp:65-97,1067`) |
  Bằng chứng:** code `#ifdef __ANDROID__` + `__system_property_get` + `std::atoi`, có comment
  `TMP*`. **Điều kiện tái hiện:** Android có property được đặt (adb/root). **Tác động:** hành vi
  render/governor đổi âm thầm trong bản ship; không phải lỗ an ninh mạng. **Hướng khắc phục:** gỡ
  hoặc khoá theo cờ build. **Kết quả phản biện:** red team xác nhận không đường mạng tới — chỉ
  nợ kỹ thuật; giữ LOW.

- **[LOW][CONFIRMED] `CEArg` userdata cấp `sizeof(void*)` nhưng không khởi tạo payload |
  `src/client/face/ui/script/host.cpp:890-893` | Bằng chứng:** `lua_newuserdata(lua, sizeof(void*))`
  rồi metatable + global, không ghi gì vào; các hộp khác đều `= nullptr`/`construct_at`.
  **Điều kiện tái hiện:** chưa có người đọc payload (`event_get_value` chỉ đọc field `Core`).
  **Tác động:** latent-uninit nếu thêm reader. **Hướng khắc phục:** ghi `nullptr` hoặc bỏ payload.
  **Kết quả phản biện:** grep mọi reader metatable — chưa ai deref; latent.

- **[LOW][CONFIRMED] Token Resume đánh cắp (32 byte, kênh mã hoá) có thể đá người đang chơi —
  hành vi thiết kế đã ghi trong code | `src/server/gate/table.cpp:1138-1158` | Bằng chứng:**
  token khớp + phiên owned → goodbye `kLoginElsewhere` cho kết nối cũ (single-use); IP khác +
  `resume_bind_ip` thì huỷ cả phiên (đúng như comment "coi như lộ"). **Điều kiện tái hiện:** rò RAM
  / log hoặc cùng IP khi tắt `resume_bind_ip`. **Tác động:** DoS một tài khoản. **Kết quả phản
  biện:** so sánh digest constant-work (`same_digest` ~1010-1017), token `fill_random` 32 byte —
  không lộ timing; đánh đổi đã được chủ đích, ghi nhận thay vì sửa.

- **[LOW][CONFIRMED] Ghé thêm các quan sát/INFO:**
  (i) Handshake giữ partial hello tới timeout — không chặn sớm theo IP ở tầng `shared/`
  (`secure/handshake.cpp:ServerHandshake::absorb`, chờ đủ 42 byte): trách nhiệm chặn kết nối nằm ở
  gate (gate có trần kết nối/IP/hạn bắt tay theo agent đọc `gate/table.cpp`) — ghi nhận là nghĩa vụ
  vận hành gate, không phải lỗi `shared/`;
  (ii) `keep_one` của bridge chỉ cap `Moved`/`Hurt` (4096) các kind khác không cap — thực tế bị
  gói bởi hàng đợi 256 của session nên không phình thật; khuyến nghị cap đồng nhất
  (`src/client/app/client/online/bridge.cpp`, `session.hpp:135`);
  (iii) `Limiter::process_frame` cứng stereo (`frame[0]/[1]`, `engine/audio/limiter.cpp:46-67`) —
  hợp đồng kín vì mọi caller subspan 2 phần tử (`engine.cpp:991`); thêm `check(size>=2)` nếu muốn;
  (iv) `thread_slot` rò có chủ đích trên GCC MinGW (bug TLS giả lập, đã đo 0xC0000374,
  `engine/core/thread_slot.hpp:58-61`) — đúng chủ đích, không sửa;
  (v) `SharedQueue` spill gấp đôi không trần (`engine/jobs/queue.cpp:284-295`) — hàng đợi nội bộ,
  không phải bề mặt thù địch.

---

## Phản biện — các cáo buộc bị bác bỏ, hạ cấp hoặc sửa trong vòng đối chất

1. "gate_attack thiếu -WX" → **sửa**: `-WX` có (WAE toàn cục); thiếu thật là `/W4`,
   `/permissive-`, `/utf-8`, `/Zc:__cplusplus` (build.ninja:20196).
2. "toml++ miss chắc chắn xoá server hiện tại" → **hạ**: 5 cache hiện có vẫn trỏ giá trị (đường
   đã chết trên đĩa) — rủi ro là tái cấu hình/clone mới, không phải trạng thái đang chạy.
3. "wait_submitted đọc ngoài mutex = data race" → **hạ**: `submitted` là `std::atomic`; còn lại là
   nuance thiết kế, không race.
4. Agent GPU tự rút cáo buộc "`sys/system_properties.h` trong swapchain.cpp" (không tồn tại) —
   được ghi nhận là tự phản biện đúng.
5. "APK fail-open" → **ghi nhận là quyết định có chủ ý** (comment trong tệp) nhưng giữ MEDIUM vì
   giá trị sửa 1 dòng và rủi ro ship.
6. "Carrier ~100 MB/kết nối" → giữ LOW vì red team xác nhận Carrier **không** nằm trên đường
   client/gate thật hiện nay.
7. Bất đồng chưa chốt (ghi lại): mức độ `lundump` bypass — agent MEDIUM, arbiter LOW (chưa có
   bằng chứng hiệu ứng runtime); hệ số speed-hack — server-agent nêu "~7×/69 cm", arbiter tính
   4× ở 30 tin/s và ~7,3×/~70 cm ở 60 tin/s (cùng chiều, khác điểm đặt); hai con số đều là suy
   diễn từ hằng số, chưa đo động.

## Phạm vi chưa kiểm (giới hạn rõ ràng)

- **Không chạy build/test/sanitizer trong phiên này**: chưa `ctest`, chưa ASan/UBSan/TSan (Windows
  không có TSan), chưa fuzz, chưa tái hiện động exploit speed-hack (đường đi chỉ được đọc). Mọi
  CONFIRMED là chứng cứ tĩnh đã đọc tới nhánh lỗi.
- **Chưa đọc line-by-line:** `engine/gpu/gles/*` (pattern-match với D3D11), `engine/resource` ngoài
  loader index/position/sparse, `engine/render/forward.cpp` ngoài TMPEXP, `src/client/face/ui/panel/*`
  (30+ tệp, chỉ grep `.at(`/`[]`), `gui/` nội bộ paint/text/9-slice, VM/GC Lua 5.0 (`lvm/lgc/ltable`)
  và `lundump` (third-party), `src/server/store` ngoài tham số hoá SQL (mức isolation, pool),
  `TOOLS/bake`, `cfgtool`, `port/luagen` (ngoài greps subprocess/shell), `Test/` (~15/180 tệp),
  `WEB/`, `apple/`, `third_party` trừ glue CMake/NGUON.
- **Chưa kiểm runtime/đa nền:** không có cây Linux/iOS/Android runtime nào được dựng hoặc chạy;
  claim nạp đầu 450 ms (`bench_load.py`) chưa đo; RPATH Linux suy luận từ vắng mặt
  (UNVERIFIED); không có đo hiệu năng (mọi nhận định performance là tĩnh).
- **Không có CI nên các kết luận "ctest xanh"** dựa trên agent đã chạy 3 lệnh read-only
  (`gen_protocol.py --check`, `lint_config.py`, `layers`) trong phiên — không phải toàn bộ suite.

## Tổng kết

| Severity | Số | CONFIRMED | PROBABLE | UNVERIFIED |
|---|---|---|---|---|
| CRITICAL | 0 | — | — | — |
| HIGH | 3 | 3 | 0 | 0 |
| MEDIUM | 13 | 13 | 0 | 0 |
| LOW | 19 | 15 | 4 | 0 |
| Tổng | 35 | 31 | 4 | 0 |

Trong đó một mục LOW dạng gộp (`APK/preset/đường dẫn vặt tích tụ`) chứa 7 ghi chú con, trong đó
RPATH Linux (e) là UNVERIFIED; một mục LOW khác gộp 5 quan sát INFO. Các con số trên đếm theo thẻ
`[SEVERITY][CONFIDENCE]` in đậm trong văn bản.

- Trọng tâm rủi ro sống (đang trên đường client/gate thật): **tầng anti-cheat di chuyển (HIGH #1)**,
  **sandbox Lua (HIGH #2)**, và **sở hữu công cụ build (HIGH #3)** — ba việc nên làm trước.
- Tầng mã hoá/giới hạn/protocol thể hiện kỷ luật cao: record layer fail-closed, transcript chống
  downgrade, trần inbox/outbox, SQL tham số hoá, webhook HMAC constant-time, argon2id, billing
  có advisory-lock + đối soát — các agent độc lập cùng kết luận; arbiter soát các hợp đồng trọng
  yếu và đồng ý với kết luận này.
- Phần gameplay thuần (combat/item/loot/shop/mission/social) phát hiện 2 lỗi LOW nhưng **chưa nối
  vào zone/world/gate** — phải sửa trước khi nối (theo AGENTS.md).
- Không tuyên bố cây mã sạch: còn ~35% bề mặt code (panel/gui/store/bake/GLES/third-party VM) chỉ
  được quét greps hoặc chưa đọc, và toàn bộ kết luận là tĩnh.
