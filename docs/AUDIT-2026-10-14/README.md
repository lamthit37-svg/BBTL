# Audit kỹ thuật THIENLONG 2026-10-14 — README

Purpose: điểm vào duy nhất của đợt audit này. Scope: toàn repo ở commit
`1ff6703` (nhánh `main`), chỉ đọc code + đo an toàn, không sửa production source.
Implementation status: `PARTIALLY COMPLETE` — inventory, architecture AS-IS,
findings có evidence và metrics đo được đã xong; build/test/runtime chưa chạy
(xem Hạn chế).

## Kết luận một đoạn

Repo là client + server game C++23 tự viết (778 file C++ trong `engine/src/Test`,
~142k LOC đã đo), hạ tầng đồ hoạ chép từ Forge2, logic game port từ TLBB Dev và
mã máy client 2026. Kiến trúc tầng một chiều có kiểm máy (`game_reject_foreign`,
`GameLayers.cmake`). Điểm mạnh đã xác minh: protocol version 2 fail-closed,
gate rate-limit + outbox trần, supervise thuần trạng thái dễ test, shader có
reconcile SPIR-V/DXIL, TOML lint sạch (26 tệp/437 cài đặt), không hardcoded
secret (review tay 130 dòng). Rủi ro lớn nhất: iOS cược hết vào MoltenVK chưa từng build;
`gcc-debug` mất cả cụm server + GPU mà configure vẫn xanh; nhiều test được
CMakeLists gọi nhưng file không tồn tại nên bị bỏ qua im lặng; GPU timestamp có
API nhưng client chưa gọi nên số GPU-ms trong bảng pace chưa có thật.

## Coverage manifest

- Đã kiểm nội dung: `CMakeLists.txt`, `CMakePresets.json`, `cmake/*.cmake` (11),
  `vcpkg.json`, `src/shared/protocol/catalog/*`, `src/shared/secure/*`,
  `engine/net/*`, `src/server/gate/*`, `src/server/account/*`,
  `src/server/supervise/*`, `src/server/process/*`, `engine/core|io|jobs|fs|xml`,
  `engine/gpu|render|shader|resource|window|capture|audio` (đọc API + lifetime theo
  header mã nguồn), `src/client` toàn nhóm (đọc header + comment đầu file),
  `dev/server/config/*.toml` (tên + khoá, KHÔNG đọc `secrets.local.toml`),
  `TOOLS/*` (tên script + vai trò), `Test/*` (tên file test tồn tại).
- Chỉ lập chỉ mục: `dev/client/assets` (~43 GB gồm `.dds/.mesh/.glb/.tsv`),
  `build/` (cây `msvc-release` + log), `WEB/` (package.json + services stub).
- Bỏ qua có chủ đích: `.git/`, `vcpkg_installed/`, `__pycache__/`,
  `dev/server/config/secrets.local.toml` (chứa mật khẩu thật), `dev/server/data/`,
  `dev/server/pgsql/`, file nhị phân `.dll/.exe/.lib/.obj/.pdb`.
- Không thể đọc: không có (mọi file text trong phạm vi đều đọc được).
- Lưu ý phiên tiếp (2026-10-14, sau khi đo, chỉ đọc-không chạm): cây xuất hiện thêm
  file chưa track của một phiên làm việc khác — `src/client/figure/avatar/locator.*`
  (locator theo xương, port TLBB Dev `locator.hpp`), `src/client/figure/look/weapon.*`
  + `skill.*` + `look/detail/` (bảng vũ khí 7 khe `Hold`, bảng skill-moves/actions/
  scripts/events/clips), `TOOLS/content/export_weapons.py` + `export_skills.py` +
  `test_export_weapons.py`. Nội dung đã đọc lướt header/comment: đúng hướng lấp gap
  "chưa bảng vũ khí" của audit này, nhưng CHƯA audit sâu, chưa đo, chưa build/test —
  vẫn giữ nhãn gap Stub cho tới khi file vào git và qua kiểm.
- Mức bao phủ: 5/5 cụm module đã audit qua subagent chỉ-đọc; mỗi finding dưới đây
  ghi confidence `VERIFIED` (đã đối chiếu dòng mã) hoặc `SOURCE-CONFIRMED`.

## Phương pháp đo

Mọi số LOC đếm bằng script Python đọc file (`utf-8, errors=replace`), phân loại
dòng trắng / comment `//` / còn lại; không dùng công cụ đếm ngoài. Module/target
đếm bằng regex trên `CMakeLists.txt`. Protocol freshness chạy
`python -B TOOLS/server/gen_protocol.py --check` (exit True = tệp sinh còn tươi).
Không chạy build, ctest, benchmark, sanitizer (lý do ở Hạn chế).

## Hạn chế và độ tin cậy

- BLOCKED: full/clean build, incremental build time, compiler warnings, ctest,
  ASan/UBSan/TSan, FPS/frame-time/VRAM/draw-call, server tick/concurrency —
  máy audit đang có working tree bẩn (65 file đổi) và AGENTS.md cấm build nặng
  song song (OOM đã đo); không chạy để tránh kết quả nhiễm.
- NOT MEASURED: coverage %, complexity score, duplication % (không cài công cụ mới
  theo lệnh audit §I.14).
- Source trong `build/`, `dev/client/assets` không phân biệt generated vs thủ công
  ở cấp file trong đợt này.

## Danh mục tài liệu audit này

- `REPOSITORY_INVENTORY.md` — metadata đã đo (§II).
- `ARCHITECTURE_AS_IS.md` — kiến trúc tái dựng từ implementation (§VIII).
- `FINDINGS.md` — phát hiện kỹ thuật có mã `AUD-*` (§XI, §VII).
- `GAPS_AND_GATES.md` — gap analysis (§XIII), quality gates (§XII), rủi ro.
- `METRICS.md` — số liệu + phân loại MEASURED/DERIVED/NOT MEASURED (§V).
- `EVIDENCE_INDEX.md` — traceability và log lệnh (§XIV–XV).
