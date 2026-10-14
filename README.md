# THIENLONG — client tự viết nạp tài nguyên Thiên Long Bát Bộ

Client tự viết nạp và vẽ lại tài nguyên của client Thiên Long Bát Bộ (XTLBB-JD 3.71)
đúng toạ độ gốc, chạy offline trước, trên PC và mobile. Mã nguồn C++23, công cụ
xử lý dữ liệu bằng Python ở `TOOLS/`.

Trạng thái chi tiết theo mã hiện tại: mục 0 của `AGENTS.md` (đối chiếu mã ngày
2026-10-14, `main` ở `1ff6703`). Nhật ký theo phiên: `docs/TIEN-DO.md`. Chỉ mục
toàn bộ tài liệu: `docs/README.md`. Phân tích mã máy client gốc: `TAILIEU/README.md`.

## Bố cục

- `engine/` — hạ tầng tái sử dụng (core, io, xml, audio, window, math, fs, jobs,
  capture, shader, gpu, resource, render, net). Target engine chỉ nhận `engine/`
  trên dòng include.
- `src/client/` — game phía client, xếp vào sáu nhóm `app figure place face book pack`.
  Include vẫn `"<m>/x.hpp"`. Client thấy `engine`, `src/shared` và `src/client`.
- `src/server/` — game phía máy chủ. Server thấy `engine`, `src/shared` và `src/server`.
- `src/shared/` — dùng chung: `protocol` (22 tin, version 2), `secure`, `table`, `link`.
- `Test/<Domain>/` — test theo domain, tên domain trùng module
  (`Test/Protocol/protocol_tests.cpp`). Header dùng chung ở gốc `Test/`.
- `TOOLS/` — công cụ Python: `content/` (gom map, avatar, giao diện, i18n),
  `server/` (sinh protocol, lint config, vận hành), `port/` (port từ client 2026),
  `run/` (đo nạp, chụp ảnh), `glb/`, `bake/`, `check/`.
- `assets/` — nguyên liệu dựng (chữ, ảnh nguồn, icon): `assets/i18n/<mã>.tsv`
  (`zh` mặc định, `vi`/`en` giữ làm nguồn).
- `dev/` — bản thử cho người chơi (exe ở `client/bin`, assets ở `client/assets`;
  máy chủ thử ở `server/` kèm PostgreSQL). `release/` — bản chính thức cùng hình.
- `WEB/` — trang giới thiệu tĩnh (Vite, React, three.js), không backend, không nằm
  trong CMake. `android/` — vỏ APK. `apple/` — vỏ iOS (chưa build, cần macOS).
- `third_party/` — nguồn chép (`libsodium`, `miniaudio`, mỗi thư mục có `NGUON.txt`);
  thư viện tải về nằm ở `C:\dev\third_party`, khai ở `vcpkg.json`.
- `cmake/` — `GameLayers.cmake` là bảng tầng (nguồn sự thật về ai include ai),
  `GameI18n.cmake` (ngôn ngữ dựng), `GameAndroidRun.cmake` (test trên thiết bị).
- `build/` — chỉ chứa thứ xoá đi dựng lại được (cây preset, log, ảnh chụp).
  Công cụ dùng lại vào `TOOLS/`, mã thử có giá trị vào `Test/<Domain>/`.

Ranh giới là thật: `game_reject_foreign` dừng configure nếu một cây include
module ngoài cây của nó.

## Dựng, kiểm, chạy

```powershell
cmake --preset msvc-debug
cmake --build --preset msvc-debug
ctest --preset msvc-debug
cmake --install build/msvc-release   # client vào release/client/bin, server theo component server
```

Preset hàng ngày: `msvc-debug` / `msvc-release` (trong `dev.bat`), kiểm chéo
`gcc-debug`, `clang-asan`; mobile `android-arm64`, `android-x86_64`;
iOS `ios-arm64`, `ios-sim-arm64` (chỉ hiện trên macOS). Mọi preset bật cảnh báo
thành lỗi. Chi tiết: `cmake --preset <tên>` xem `CMakePresets.json`.

```powershell
python ~/.claude/cpp23/tools/check.py <tệp…>   # GCC + Clang -Werror + clang-tidy
ctest --preset clang-asan                       # ASan + UBSan (shell thường, không dev.bat)
python -B TOOLS/server/lint_config.py           # kiểm TOML máy chủ (--fix để căn)
python -B TOOLS/server/gen_protocol.py --check  # kiểm tệp sinh protocol còn tươi
python -B TOOLS/run/bench_load.py               # đo nạp đầu, giữ ngân sách 450 ms
```

Bộ quy cách C++23 nằm ở `D:\CLAUDE\cpp23` (bản duy nhất, `~/.claude/cpp23` trỏ vào
đó), không nằm trong repo này. Mọi việc C/C++ gọi skill `cpp23` trước khi đọc
hay viết mã. Quy định làm việc của agent: `AGENTS.md`.
