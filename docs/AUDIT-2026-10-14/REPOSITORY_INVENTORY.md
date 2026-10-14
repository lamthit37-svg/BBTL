# REPOSITORY_INVENTORY — số liệu đã đo 2026-10-14

Scope: repo `D:\THIENLONG`, commit `1ff6703`, nhánh `main`, working tree bẩn
(65 file đổi, toàn là code/docs đang dở — xem `git status`). Mọi số dưới đây là
MEASURED bằng lệnh trong `EVIDENCE_INDEX.md`, trừ chỗ ghi rõ.

## Metadata

- Repository: THIENLONG. Commit: `1ff6703`. Branch: `main`.
- Toàn cây (trừ `.git/build/vcpkg_installed/__pycache__`): 12229 thư mục,
  228174 file, ~43,6 GB — phần lớn là `dev/client/assets` (`.dds` 95628,
  `.mesh` 69308, `.tsv` 20448, `.glb` 3902) và `build/`.
- Phạm vi mã nguồn (`engine+src+Test+TOOLS+cmake+android+apple+WEB/src`):
  1794 file. Trong đó `.cpp` 417, `.hpp` 362, `.py` 124, `.tsx` 40, `.ts` 37,
  `.slang` 11, `.cmake` 11, `.glsl` 7, `.mm` 2.

## Source metrics (MEASURED, script đếm dòng)

| Phạm vi | File C++ | LOC | Comment `//` | Trắng | Bytes |
|---|---|---|---|---|---|
| `engine/` | 257 | 53513 | 6134 | 8092 | 2869423 |
| `src/` | 411 | 57355 | 6996 | 8870 | 3046664 |
| `Test/` | 110 | 31445 | 1651 | 3376 | 1800515 |
| Tổng | 778 | 142313 | 14781 | 20338 | ~7,7 MB |

Định nghĩa: LOC = dòng không trắng và không mở đầu bằng `//`. Không tách comment
cuối dòng. Không có module C++20 (`import`): 0 file `.ixx`, không dùng
`FILE_SET CXX_MODULES`.

## Target (MEASURED, regex trên `CMakeLists.txt`)

- 53 module `game_<m>` (danh sách đủ trong `EVIDENCE_INDEX.md`).
- 17 `add_executable`, gồm: `thienlong_client`, 7 exe server
  (`server/store/auth/billing/world/zone/gate`), `thienlong_lint`,
  `thienlong_audio`, `thienlong_seal`, `thienlong_shader`,
  `thienlong_metrics_snap`, `thienlong_gate_load`, `thienlong_test_child`,
  `server_boot`, `server_boot_source_clean`, bench (`collision/core/net/protocol`),
  `gate_attack`. Mẫu `${name}_tests` sinh một exe mỗi `Test/*/*_tests.cpp`.
- Preset (`CMakePresets.json`): `gcc-debug`, `gcc-asan`, `clang-asan`,
  `clang-tsan`, `ci-gcc`, `msvc-debug`, `msvc-asan`, `msvc-release`,
  `android-arm64`, `android-x86_64`, `ios-arm64`, `ios-sim-arm64` (chỉ Darwin).

## Dependency (SOURCE-CONFIRMED)

- `vcpkg.json`: `tomlplusplus`, `cgltf`, `lz4`, `meshoptimizer`, `opus`, `stb`,
  `xxhash`, `zstd`, `sse2neon`, `sdl3`, `libpq` (no-default-features),
  baseline `04a9d8e5`.
- Vendored: `third_party/libsodium` 1.0.22, `third_party/miniaudio` 0.11.22
  (mỗi thư mục có `NGUON.txt`).
- Hệ thống: Vulkan SDK (bắt buộc khi `GAME_HAS_GPU`), `d3d12/d3d11/dxgi`,
  `delayimp` + `vulkan-1.dll` trễ, Android `EGL/GLESv3/log/aaudio`, iOS frameworks
  `Metal/QuartzCore/UIKit` + MoltenVK tự cấp, `SDL3`, `PostgreSQL` (chỉ toolchain
  vcpkg), Python3 + Pillow (i18n/APK).
- Backend đồ hoạ thật: `kVulkan/kD3D12/kD3D11/kGles`
  (`engine/gpu/types.hpp:20-26`). Không có backend Metal gốc.

## Test domain (MEASURED, file tồn tại)

38 domain có `*_tests.cpp`: Anim, Audio (2), Avatar (2), Client (6), Config,
Content, Control (3), Core (4), Fs, Fx, Gate (3), Gui (7), Hero, Io, Look (2),
Math, Metrics (2), Motion (2), Nav, Net (2), Ogre, Process, Protocol (2), Quest,
Render (3), Resource (6), Scene (2), Secure, Service, Shared (2), Shader, Gpu,
Skill, Supervise, Ui (13), Window, Xml, Seal, Server (2). Cộng test đặc biệt:
`layers`, `server_boot`, `server_boot_source_clean`, `server_data_lint`,
`protocol_catalog_fresh`, `server_config_lint`, `i18n_tool_tests`.
`window_modal` bị DISABLED mặc định.

## Protocol (SOURCE-CONFIRMED)

- `src/shared/protocol`: `kVersion = 2` (`src/shared/protocol/messages.hpp:21`,
  `src/shared/protocol/catalog/messages.tsv:3`). 22 tin (11 client→server + 11 server→client) +
  1 record `CharacterSummary`; 4 nhóm `01 session, 02 character, 03 move, 05 auth`.
- `src/shared/secure`: `kSecureVersion = 1`, label `TLBBSEC1`,
  `ClientHello` 42B, `ServerHello` 96B (`secure.hpp:48-50`).
- Tệp sinh còn tươi: `gen_protocol.py --check` exit True ngày 2026-10-14.

## Phân loại mã nguồn / vendor / generated / test / asset

- Chính thức: `engine/`, `src/`. Test: `Test/`. Tool: `TOOLS/` (Python).
- Vendor: `third_party/libsodium`, `third_party/miniaudio`.
- Generated: `src/shared/protocol/messages.{hpp,cpp}`,
  `Test/Protocol/protocol_samples.hpp`, `docs/PROTOCOL-TIN.md` (đầu file ghi
  không sửa tay); `*.f2s` trong `build/`; `Test/golden/**`.
- Asset: `dev/client/assets`, `assets/i18n`. Build output: `build/`,
  `vcpkg_installed/`.
