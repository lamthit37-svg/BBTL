# FINDINGS — phát hiện kỹ thuật có evidence

Quy ước: mỗi mục có `id`, severity (Critical/High/Medium/Low), confidence
(VERIFIED = đã đối chiếu dòng mã; SOURCE-CONFIRMED = xác nhận source, chưa chạy
runtime), status `open` trừ chỗ ghi rõ. Không có Critical nào đủ evidence trong
đợt này. Khuyến nghị sửa là PROPOSED, chưa thực hiện (phạm vi audit không sửa code).

## AUD-BUILD-0001 — Test được CMakeLists gọi nhưng file không tồn tại, bỏ qua im lặng

- severity: Medium. confidence: VERIFIED. status: open. component: build/test.
- source_locations: `CMakeLists.txt:1247,1250,1274,1279` (collision,
  collision_alloc, collision_fuzz, collision_model), `:1191` (window_modal),
  `:1456,1460,1468,1475` (protocol_channel, protocol_fuzz, protocol/net_bench).
- evidence: `Test/Collision` chỉ còn `building_height_tests.cpp`; `Test/Window`
  chỉ `window_tests.cpp`; `Test/bench` chỉ `Test/bench/gate_attack.cpp` + `Test/bench/core_bench.cpp`.
- description: `game_test` in một dòng và bỏ target khi thiếu file; configure
  không đỏ nên thiếu test trông như bình thường.
- impact: coverage thực thấp hơn vẻ ngoài; hồi quy module collision/protocol
  chỉ còn một phần.
- recommended_fix (PROPOSED): hoặc khôi phục file test, hoặc đổi `game_test`
  thành `message(FATAL_ERROR)` cho danh sách test bắt buộc; liệt kê test tùy
  chọn riêng.
- verification_plan: `cmake --preset gcc-debug` phải liệt kê đúng test còn thiếu.

## AUD-BUILD-0002 — `gcc-debug` mất cả cụm server + GPU mà vẫn xanh

- severity: Medium. confidence: VERIFIED. status: open. component: build.
- source_locations: `CMakeLists.txt:295-298` (find tomlplusplus chỉ hint
  `x64-windows-static-md`), `:368-369` (bỏ module/test server),
  `:643` (`GAME_HAS_GPU=OFF` với GNU-Windows).
- evidence: preset GCC không chạy vcpkg nên mất `config/process/service/gate/
  account/protocol/net/secure/link` và toàn bộ `fs/shader/gpu/render/resource/ui`.
- impact: CI chạy `gcc-debug` tưởng xanh nhưng thực ra bỏ qua phần lớn hệ thống.
- recommended_fix (PROPOSED): in `WARNING` to khi bỏ module, hoặc cấp preset GCC
  có vcpkg; tài liệu hoá ma trận preset × module.
- verification_plan: so `ctest -N` giữa `gcc-debug` và `msvc-debug`.

## AUD-BUILD-0003 — Mọi preset dùng chung `dev/client/assets` + một `GAME_LANGUAGE`

- severity: Medium. confidence: VERIFIED. status: open. component: i18n/build.
- source_locations: `cmake/GameI18n.cmake:7-8,13`.
- impact: preset dựng ngôn ngữ khác ghi đè nhau; không dựng song song `zh/vi/en`.
- recommended_fix (PROPOSED): state/build-i18n theo từng preset hoặc assets
  theo từng preset.

## AUD-BUILD-0004 — Mobile ăn theo cây PC; iOS chưa từng build

- severity: Medium. confidence: VERIFIED. status: open. component: platform.
- source_locations: `cmake/GameDeviceShaders.cmake:13-19`,
  `CMakeLists.txt:1006,1028,984-991`, `apple/HUONG-DAN.txt:1-4`.
- evidence: APK lấy `.f2s` của PC; iOS FATAL nếu thiếu `model.vs/ps.f2s`;
  chưa có lượt dựng iOS nào (không có macOS).
- impact: Mọi tuyên bố "hỗ trợ iOS" hiện chỉ là mã nguồn, chưa phải bản dựng.
- verification_plan: dựng trên macOS theo `apple/HUONG-DAN.txt` rồi ghi kết quả.

## AUD-RENDER-0001 — Không có backend Metal gốc; iOS cược vào MoltenVK

- severity: High (nếu mục tiêu iOS). confidence: SOURCE-CONFIRMED. status: open.
- source_locations: `engine/gpu/types.hpp:20-26`,
  `engine/gpu/vulkan/surface_ios.mm:43`, `CMakeLists.txt:730-751`.
- impact: hỏng MoltenVK (version 1.3 + timeline + bufferDeviceAddress) = không
  chạy iOS. Mọi số iOS hiện tại là UNKNOWN.
- recommended_fix (PROPOSED): pin phiên bản MoltenVK + test khởi tạo tối thiểu
  trên macOS trước khi nhận iOS là supported.

## AUD-RENDER-0002 — Slot-aliasing GPU không guard runtime

- severity: Medium. confidence: SOURCE-CONFIRMED. status: open.
- source_locations: `engine/render/forward.hpp:16-18`, `engine/render/ui.hpp:3-4`.
- description: slot = index ảnh swapchain vừa acquire; sai slot ghi đè buffer
  Upload GPU đang đọc.
- recommended_fix (PROPOSED): `check` slot == ảnh vừa acquire ở bản debug.

## AUD-RENDER-0003 — GPU timestamp có API nhưng client chưa gọi

- severity: Medium (tài liệu pace). confidence: VERIFIED. status: open.
- source_locations: `engine/gpu/command.hpp:196-202`,
  `src/client/app/client/display/graphic/frame.cpp:412` (chỉ `end_frame`).
- impact: cột GPU-ms trong bảng pace chưa có thật; "Xin ảnh cao là GPU chưa kịp"
  mới là INFERRED.

## AUD-NET-0001 — Giữ handle thô trong PollSet/Reactor, OS tái cấp gây nhầm tag

- severity: High. confidence: SOURCE-CONFIRMED. status: open.
- source_locations: `engine/net/net.hpp:220-223,125-127`.
- description: đóng/abort mà chưa `remove` thì handle tái cấp trùng gây nhầm tag.
- recommended_fix (PROPOSED): generation trên tag hoặc `check` remove-trước-close
  ở bản debug; test hồi quy đóng-mở nhanh.

## AUD-NET-0002 — Move không hỏi lại standing/cap mỗi tick

- severity: Medium. confidence: SOURCE-CONFIRMED. status: open.
- source_locations: `src/server/account/serve.cpp:182-196`,
  `src/server/gate/table.cpp:604+`, `src/server/gate/motion.hpp:1-4`,
  `src/server/account/cap.hpp:19` (cap 8h).
- impact: ban/cap hết giữa phiên chỉ đá ở lần Resume/Enter kế.

## AUD-SEC-0001 — `SECURE_DROP_LENGTH_CHECK` bỏ kiểm dài, chỉ dành cho test

- severity: High-nếu-bật (hiện OFF). confidence: VERIFIED. status: open.
- source_locations: `src/shared/secure/record.cpp:2-3,88-92,110-112`.
- description: macro test bỏ kiểm độ dài bản ghi; lỡ define ở build thường là mất
  kiểm.
- recommended_fix (PROPOSED): `static_assert` cấm macro này khi `NDEBUG`/release,
  hoặc tách file test riêng.

## AUD-SEC-0002 — Dev `auto_register=true` + trần brute-force

- severity: Medium. confidence: SOURCE-CONFIRMED. status: open.
- source_locations: `dev/server/config/auth.toml:25`,
  `src/server/account/rules.cpp:74-75`, `src/server/account/rules.hpp:24-26`
  (`kFailLimit` 8, `kIpFailLimit` 30/15m).
- impact: mang nguyên config dev lên prod là mở đăng ký + bề mặt brute-force.
- recommended_fix (PROPOSED): `auto_register=false` mặc định prod + quality gate
  kiểm config prod.

## AUD-SEC-0003 — Quét hardcoded secret: sạch (đã review tay)

- severity: Informational. confidence: VERIFIED. status: closed.
- evidence: 130 dòng chứa `secret` trong 17 file `src/**` đã đọc toàn bộ ngày
  2026-10-14: hằng cỡ khoá (`sodium.hpp:12,16`, `secure.hpp:42`), tham số khoá +
  `wipe_*` sau dùng (`sodium.cpp`, `handshake.cpp`, `identity.cpp`,
  `src/server/gate/table.cpp:520-522,556`), bộ đọc `config/secrets.*` (hình dạng + đường
  dẫn, không giá trị), `secret_file` của billing, 2 dòng comment trong
  `src/server/linttool/config_lint.cpp`. Pattern hẹp `api_key|apikey|passwd|pwd=|token=<giá
  trị>` cho 0 kết quả toàn `src/` và `src/server/`.
- Không đưa giá trị nào vào báo cáo; `secrets.local.toml` không đọc.
- verification_plan: DONE đợt này. Đề xuất (PROPOSED): thêm gate quét secret vào CI.

## AUD-DUP-0001 — Nhân ba implementation giữa backend GPU (by-design)

- severity: Informational. confidence: VERIFIED. status: open.
- evidence: 206 nhóm ≥20 dòng chuẩn hoá trùng nhau, gom ở 15 file, top là bộ ba
  `engine/gpu/{d3d12,gles,vulkan}/device.hpp` (script hash khối dòng, 2026-10-14).
- description: mỗi backend lặp lại khung `Device` — là tách biệt có chủ đích theo
  backend, không phải copy-paste vô ý. Rủi ro duy nhất: sửa khung một nơi quên
  hai nơi còn lại.
- recommended_fix (PROPOSED): không gộp code (khác API gốc); nếu chạm khung
  Device thì grep cả ba backend trong cùng thay đổi.

## AUD-CPP-0001 — `jobs` dùng exception_ptr + rethrow, lệch quy tắc no-throw của core

- severity: Medium. confidence: SOURCE-CONFIRMED. status: open.
- source_locations: `engine/jobs/jobs.hpp:72-76`, `engine/jobs/jobs.cpp:493-506`.
- impact: đường lỗi job đi bằng ngoại lệ trong khi core cấm `throw` ở game/net.
- recommended_fix (PROPOSED): ADR ghi nhận ngoại lệ có chủ đích ở ranh giới job,
  hoặc đổi sang `expected` + test.

## AUD-CPP-0002 — `~Child` chờ INFINITE, huỷ có thể chặn vô hạn

- severity: Medium. confidence: VERIFIED. status: open.
- source_locations: `src/server/process/process_win32.cpp:397-402,418-423`.
- recommended_fix (PROPOSED): hạn chờ + `terminate` có log, test hồi quy con lì.

## AUD-CPP-0003 — Lỗi ghi lúc đóng file mất nếu không gọi `close()`

- severity: Medium. confidence: VERIFIED. status: open.
- source_locations: `engine/fs/file.cpp:253-262`, `engine/fs/file.hpp:96`.
- description: `~File` chỉ `flush_quietly` + log.

## AUD-CPP-0004 — XML surrogate `0xD800-0xDFFF` được nhận rồi mã hoá sai

- severity: Low. confidence: VERIFIED. status: open.
- source_locations: `engine/xml/document.cpp:130-138,40-60`.
- description: thực thể số chỉ loại `0` và `>0x10FFFF`, lọt surrogate.

## AUD-GAME-0001 — Che asset lỗi bằng giá trị câm (scene/fx/anim/gui)

- severity: Medium (tổng hợp). confidence: SOURCE-CONFIRMED. status: open.
- source_locations: `src/client/place/scene/placement.hpp:8-9` (token sai → 0/vị đơn vị),
  `src/client/place/fx/system.hpp:154-156` (SequenceFrame đọc chưa hết),
  `src/client/figure/anim/rig.hpp:7-9` (handle lạ → ma trận đơn vị, 660 bản ghi ở 7 mesh),
  `src/client/face/gui/loader.hpp:6-7` (ref hỏng bỏ + ghi notes).
- impact: asset hỏng vẫn chạy nhưng thiếu/sai hình thầm; khó phát hiện.
- recommended_fix (PROPOSED): chế độ strict khi cook (`collect_* --strict`) +
  giữ fail-open lúc chạy.

## AUD-DATA-0001 — `third_party/NGUON.txt` thiếu 2 thư viện vendored

- severity: Low. confidence: VERIFIED. status: open.
- source_locations: `third_party/NGUON.txt:1-4` vs
  `third_party/libsodium/NGUON.txt`, `third_party/miniaudio/NGUON.txt`,
  `cmake/VcpkgToolchain.cmake:9-14`.
