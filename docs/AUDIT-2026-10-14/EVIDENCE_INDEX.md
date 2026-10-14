# EVIDENCE_INDEX — traceability và log lệnh

Nhãn tin cậy: VERIFIED (source +/hoặc thực thi phù hợp), SOURCE-CONFIRMED
(source, chưa runtime), INFERRED (suy luận), PROPOSED (đề xuất), UNKNOWN,
BLOCKED. Traceability: `Yêu cầu → Component → Source → Test → Metric →
Finding → Doc`. Ô nào thiếu ghi `UNVERIFIED`/`MISSING`.

## Lệnh đã chạy (MEASURED, Windows PowerShell 5.1, gốc `D:\THIENLONG`)

1. `git rev-parse HEAD` → `1ff6703`. `git branch --show-current` → `main`.
   `git status --short` → 65 file đổi (danh sách đủ ở log tool, gồm code đang dở
   ở `src/*`, `TOOLS/*`, `Test/*` + docs).
2. Inventory toàn cây (Python `os.walk`, trừ `.git/build/vcpkg_installed/
   __pycache__`): 12229 dir, 228174 file, 43579339929 byte + bảng đuôi file.
3. Inventory mã nguồn (`engine+src+Test+TOOLS+cmake+android+apple+WEB/src`):
   1794 file (`.cpp` 417, `.hpp` 362, `.py` 124, `.tsx` 40, `.ts` 37,
   `.slang` 11, `.cmake` 11, `.glsl` 7, `.mm` 2).
4. Đếm LOC Python (`utf-8/errors=replace`): engine 257 file / 53513 LOC,
   src 411 / 57355, Test 110 / 31445.
5. Đếm target: regex `game_module\(` → 53 module; `add_executable` → 17 exe
   (danh sách: `${name}_tests ${target} collision_bench core_bench gate_attack
   net_bench protocol_bench server_boot server_boot_source_clean thienlong_audio
   thienlong_client thienlong_gate_load thienlong_lint thienlong_metrics_snap
   thienlong_seal thienlong_shader thienlong_test_child`).
6. `python -B TOOLS/server/gen_protocol.py --check` → True (exit True).
7. `python -B TOOLS/server/lint_config.py` (check-only, 2026-10-14) → `26 tệp
   sạch, 437 cài đặt đều có chú thích và thẳng cột` (exit True).
8. Quét secret (2026-10-14): regex khoá rộng trên `src/**.cpp/.hpp` → 130 dòng /
   17 file; review tay toàn bộ (VERIFIED sạch); regex hẹp
   `api_key|apikey|passwd|pwd=|token=<giá trị>` → 0 kết quả toàn `src/`;
   `secrets.local.toml` không đọc, không giá trị nào vào báo cáo.
9. Đếm TU/header (script tạm ngoài repo, đã xoá sau khi đo; phương pháp: duyệt
   `engine+src+Test`, đếm dòng không trắng/không `//`): 419 TU + 366 header = 785 file;
   top10 theo LOC (`engine/resource/model.cpp` 1715 … `Test/Gui/gui_sheet_tests.cpp` 1196).
10. Sâu include (script tạm, resolver gần đúng: module `m/x` thử `engine/`,
    `src/shared`, các nhóm `src/client/*`, `src/server` rồi kề file): client
    `src/client/app/client/main.cpp` = 10, `src/server/gated/main.cpp` = 1, `engine/gpu/device.cpp` = 9 (62 file trong chuỗi).
11. Trùng lặp (script tạm, hash khối 20 dòng chuẩn hoá whitespace, bỏ dòng chỉ
    ngoặc): 206 nhóm ở 15 file, top là bộ ba `engine/gpu/{d3d12,gles,vulkan}/device.hpp`.
12. Đọc `src/client/client.build.toml`: `schema = 1`,
    `[hud] avatar_frame = "square"` (khớp tài liệu).
13. Consistency evidence (script tạm): 120 ref backtick trong 7 file audit, 78
    ref đường dẫn đầy đủ — toàn bộ resolve được sau khi gắn tiền tố repo còn
    thiếu (16 chỗ đã sửa); 4 chuỗi đuôi file (`.cpp/.hpp…`) là false-positive,
    không phải ref. Nội dung 2 evidence điểm (`display.hpp:81-85` mượn Stage,
    `table.cpp:169` restart mất phiên) đã đọc lại đúng chữ.
14. Type-surface + decision-proxy (script tạm, regex đa dòng sau khi lột
    comment/string): 2228 `class/struct`, 277 `enum class`, 13501 điểm rẽ trên
    ~141,7k LOC ( khớp chéo tổng LOC 142313 ). Đây là PROXY thô, không thay công
    cụ complexity.

## Không chạy (BLOCKED / NOT MEASURED)

`cmake --preset`, `cmake --build`, `ctest`, `check.py`, clang-tidy, sanitizer,
benchmark, `lint_config` (kể cả không `--fix`), đo FPS/VRAM/server — lý do:
working tree bẩn + AGENTS.md cấm việc nặng song song (OOM đã đo). Không cài công
cụ, không tải gói, không đọc secret.

## Traceability mẫu

- Protocol v2 → `src/shared/protocol` → catalog + `messages.hpp:21` →
  `protocol_tests` + `protocol_catalog_fresh` (chưa chạy) → 22 tin (MEASURED) →
  FINDINGS (không finding về version) → `REPOSITORY_INVENTORY.md`,
  `docs/PROTOCOL-TIN.md`. Test-result: UNVERIFIED.
- Gate session → `src/server/gate/table.cpp` → `gate_loop_tests`
  (chưa chạy) → NOT MEASURED → AUD-NET-0002 → `ARCHITECTURE_AS_IS.md`.
- GPU slot → `engine/render/forward.hpp:16-18` → chưa có test →
  MISSING → AUD-RENDER-0002.
- iOS → `surface_ios.mm`, preset `ios-arm64` → chưa từng build →
  BLOCKED → AUD-RENDER-0001, gate G-BUILD Unknown.

## Module audit (subagent chỉ-đọc, 5 cụm)

Foundation (core/io/jobs/net/fs/xml/process/supervise), rendering
(gpu/render/shader/resource/window/capture/audio/shaders), game-world
(src/client toàn nhóm), server/shared (protocol/secure/table/link/config/
content/gate/account/store/service/metrics/guard + toml), build/test/asset
(CMake/preset/vcpkg/Test/TOOLS/i18n/APK/WEB). Báo cáo gốc nằm trong log phiên;
kết luận đã hợp nhất vào `FINDINGS.md` với file:dòng cụ thể.
