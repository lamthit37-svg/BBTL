# BD · Build và toolchain

> **Phạm vi:** CMake (target, preset, chuẩn C++23), bộ cảnh báo, cấu hình Debug/Release và
> `GAME_DEBUG_CHECKS`, clang-tidy, MSVC, ccache, preset sanitizer, cờ cứng hoá, thông tin
> gỡ lỗi và tách symbol, ma trận CI, PCH, module C++20, đo thời gian build, linker, lỗi công cụ đã
> biết. **Đọc khi:** tạo hoặc sửa `CMakeLists.txt`, `CMakePresets.json`, tệp `cmake/*.cmake`; thêm
> target, cờ, macro cấu hình; dựng CI; build chậm; binary phát hành thiếu symbol; clang-tidy sập hay
> báo lạ; chuyển sang module.
> **Liên quan:** refs/07-generic-compile-time.md (GN-16, GN-19), refs/08-thu-vien-chuan-cpp23.md (STD-13,
> STD-22), refs/09-hieu-nang.md (HN — SỞ HỮU cờ hiệu năng: -O, -march, LTO, PGO),
> refs/13-ub-on-dinh.md (UB — SỞ HỮU chính sách sanitizer/hardening), refs/15-kiem-thu.md (KT),
> refs/17-kien-truc-module.md (KTR).

Đã kiểm trên máy: CMake 3.28.3, Ninja 1.11.1, GCC 14.2, Clang 20.1 + libc++ 20, lld. `CMakeLists.txt`,
mọi `cmake/*.cmake` và `CMakePresets.json` dưới đây được trích NGUYÊN VĂN từ tệp này, ghép thành một dự
án, rồi configure + build + ctest với cả năm preset; đoạn trích của BD-13, BD-14, BD-16 kiểm riêng.
Kiểm lại 2026-10-03 trên Windows 11: CMake 4.4.3, Ninja 1.13.2, GCC 16.2 (MinGW-w64 UCRT), Clang 23.1
(đích MSVC, STL MSVC 14.51): `gcc-debug`, `clang-asan`, `ci-gcc` configure + build + ctest qua;
`gcc-asan`, `clang-tsan` chỉ hiện trên máy không phải Windows (MinGW không có runtime sanitizer,
Windows không có TSan). CHƯA kiểm: MSVC `cl`, ccache.

## 0. Bố cục tệp build của dự án

```text
CMakeLists.txt            gốc: project, include(cmake/*.cmake), một target mỗi module
CMakePresets.json         mọi cấu hình dev + CI (BD-04)
.clang-format .clang-tidy chép NGUYÊN VĂN từ config/ của bộ quy cách (BD-05)
.gitignore .gitattributes bỏ build/IDE/rác; LF mọi nơi, CRLF cho .bat/.ps1/.sln; tài nguyên lớn qua LFS
config/warnings-*.txt     chép nguyên văn; CMake đọc (BD-02)
cmake/GameWarnings.cmake  cmake/GameOptions.cmake  cmake/GameSanitize.cmake
cmake/GameHarden.cmake    cmake/GameDebugInfo.cmake cmake/GameSplitDebug.cmake
cmake/GameLayers.cmake    bảng tầng, chạy bằng test `layers` (KTR-15)
src/<m>/x.hpp + x.cpp     header đặt cạnh .cpp cùng tên; include "<m>/x.hpp" từ gốc src/ (KTR-08)
src/<m>/detail/           header nội bộ của module <m>; module khác không include (KTR-15)
tests/                    test.hpp (KT-01), <m>_tests.cpp, fuzz/ (KT-11)
```

Khung đã build sẵn theo bố cục này: `templates/project/` của bộ quy cách.

## 1. Nền tảng [N]

### BD-01 [N] PHẢI — CMake ≥ 3.28; mọi thiết lập gắn vào target; `cxx_std_23` và `CMAKE_CXX_EXTENSIONS OFF`; không sửa `CMAKE_CXX_FLAGS` trong CMakeLists

`target_compile_features(t PUBLIC cxx_std_23)`, `target_compile_options`, `target_compile_definitions`,
`target_link_libraries` với PUBLIC/PRIVATE/INTERFACE đúng nghĩa. Thiết lập chung đi qua target INTERFACE
(BD-02, BD-03), không qua biến toàn cục. Chọn trình dịch/thư viện chuẩn là việc của preset.

- **Vì sao:** 3.28 là bản đầu có module C++20 không thử nghiệm (BD-14) và biết `cxx_std_23` với GCC 14,
  Clang 20. `CMAKE_CXX_EXTENSIONS OFF` cho `-std=c++23` thay `-std=gnu++23` (đo trong
  compile_commands.json): phần mở rộng GNU không lọt vào code. Cờ gắn theo target lan đúng theo phụ
  thuộc; `CMAKE_CXX_FLAGS` sửa trong CMakeLists áp cho cả thư viện bên thứ ba và không thấy được từ
  target.
- **Kiểm:** review `CMakeLists.txt`: grep `CMAKE_CXX_FLAGS`, `add_definitions`, `include_directories(`
  không có `target_`.
- **Ngoại lệ:** cờ phải giống nhau ở MỌI TU kể cả mã bên thứ ba (sanitizer, cứng hoá, kiểm biên thư
  viện, thông tin gỡ lỗi, linker) gắn một lần bằng `add_compile_options`/`add_link_options` trong
  `cmake/*.cmake` ở thư mục gốc (BD-08, BD-09, BD-10, BD-16), không qua `CMAKE_CXX_FLAGS`.

```cmake
# CMakeLists.txt (gốc)
cmake_minimum_required(VERSION 3.28)
project(game VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# Chưa dùng module C++20:
# tắt quét phụ thuộc (CMP0155).
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

include(cmake/GameWarnings.cmake)
include(cmake/GameOptions.cmake)
include(cmake/GameSanitize.cmake)
include(cmake/GameHarden.cmake)
include(cmake/GameDebugInfo.cmake)
include(cmake/GameSplitDebug.cmake)

# Module: src/<m>/, x.hpp cạnh x.cpp;
# include "<m>/x.hpp" từ gốc src/.
add_library(game_core STATIC src/core/clock.cpp)
target_include_directories(game_core PUBLIC src)
target_compile_features(game_core PUBLIC cxx_std_23)
target_link_libraries(game_core PUBLIC game::options PRIVATE game::warnings)

add_executable(game_server src/app/main.cpp)
target_link_libraries(game_server PRIVATE game_core game::warnings)
game_split_debug(game_server)

enable_testing()
add_executable(core_tests tests/core_tests.cpp)
target_include_directories(core_tests PRIVATE tests)
target_link_libraries(core_tests PRIVATE game_core game::warnings)
add_test(NAME core_tests COMMAND core_tests)
# Include ngược tầng: bảng ở cmake/GameLayers.cmake (KTR-15).
add_test(NAME layers COMMAND ${CMAKE_COMMAND} -DGAME_SOURCE_DIR=${PROJECT_SOURCE_DIR}
         -P ${PROJECT_SOURCE_DIR}/cmake/GameLayers.cmake)
# Khung đầy đủ (thêm game_all_modules và header_check của KTR-03): templates/project/.
```

```cpp
// ✓ core/platform.hpp: giả định nền tảng thành lỗi biên dịch, không thành lỗi lúc chạy.
#include <bit>
#include <climits>
#include <cstddef>

namespace game::core {

// NOLINTBEGIN(misc-redundant-expression): so macro với hằng là chủ đích của tệp (BD-01).
// MSVC chỉ báo đúng __cplusplus khi có /Zc:__cplusplus; giá trị dưới /std:c++latest: BD-06.
static_assert(__cplusplus >= 202302L, "cần -std=c++23");
static_assert(CHAR_BIT == 8 && sizeof(void*) == 8, "chỉ hỗ trợ đích 64 bit, byte 8 bit");
// NOLINTEND(misc-redundant-expression)
static_assert(std::endian::native == std::endian::little, "giao thức giả định little-endian");
static_assert(sizeof(std::size_t) == 8);

} // namespace game::core
```

### BD-02 [N] PHẢI — Cảnh báo lấy từ `config/warnings-*.txt` qua target INTERFACE `game::warnings`; `-Werror` bật bằng `COMPILE_WARNING_AS_ERROR` trong CI

Mọi target của dự án `target_link_libraries(... PRIVATE game::warnings)`. Không chép danh sách cờ vào
CMakeLists: tệp `.txt` là nguồn duy nhất cho CMake, tools/verify.py và CI. Thư viện bên thứ ba
không link `game::warnings`. `-Werror` không cứng trong CMakeLists: preset CI đặt
`CMAKE_COMPILE_WARNING_AS_ERROR=ON` (CMake ≥ 3.24; ra `-Werror`, MSVC ra `-WX`); dev tạm tắt bằng
`cmake --preset ci-gcc --compile-no-warning-as-error` khi cần — tuỳ chọn của bước cấu hình;
`cmake --build` không nhận nó (đo: "Unknown argument").

- **Vì sao:** cảnh báo trong bộ là lỗi thật đã gặp (`-Wconversion`, `-Wsign-conversion`, `-Wshadow`,
  `-Wuseless-cast`, `-Wmissing-declarations`…), mẫu ✓ của bộ quy cách đều qua `-Werror` với đúng các tệp
  này. `-Werror` cứng trong CMakeLists làm gãy build khi người dùng đổi sang trình dịch mới có cảnh báo
  mới; CI giữ kỷ luật mà không khoá dev. `CMAKE_CONFIGURE_DEPENDS` làm CMake tự cấu hình lại khi sửa tệp
  `.txt`.
- **Kiểm:** CI preset `ci-*`; review target thiếu `game::warnings`.

```text
config/warnings-common.txt: -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow
  -Wnon-virtual-dtor -Wold-style-cast -Wcast-align -Wcast-qual -Woverloaded-virtual
  -Wnull-dereference -Wdouble-promotion -Wformat=2 -Wimplicit-fallthrough -Wundef -Wsuggest-override
config/warnings-gcc.txt:    -Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wuseless-cast
  -Wmissing-declarations -Wredundant-decls
config/warnings-clang.txt:  -Wmissing-prototypes -Wextra-semi -Wcomma -Wshadow-all
  -Wimplicit-int-float-conversion -Winvalid-constexpr
(mỗi cờ một dòng trong tệp thật)
```

```cmake
# cmake/GameWarnings.cmake — một nguồn sự thật cho cảnh báo.
foreach(kind IN ITEMS common gcc clang)
    set(file "${PROJECT_SOURCE_DIR}/config/warnings-${kind}.txt")
    file(STRINGS "${file}" GAME_WARNINGS_${kind})
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${file}")
endforeach()

add_library(game_warnings INTERFACE)
add_library(game::warnings ALIAS game_warnings)
# Biểu thức sinh có danh sách bên trong PHẢI nằm trong ngoặc kép, nếu không ';' cắt đôi nó.
target_compile_options(game_warnings INTERFACE
    "$<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:${GAME_WARNINGS_common}>"
    "$<$<CXX_COMPILER_ID:GNU>:${GAME_WARNINGS_gcc}>"
    "$<$<CXX_COMPILER_ID:Clang,AppleClang>:${GAME_WARNINGS_clang}>"
    "$<$<CXX_COMPILER_ID:MSVC>:/W4;/permissive-;/Zc:__cplusplus;/Zc:preprocessor;/utf-8>")
```

### BD-03 [N] PHẢI — Ba cấu hình Debug / RelWithDebInfo / Release; `GAME_DEBUG_CHECKS` gắn qua target INTERFACE `game::options` cho cả chương trình

| Cấu hình | Dùng cho | Tối ưu | `GAME_DEBUG_CHECKS` | Sanitizer / cứng hoá |
|---|---|---|---|---|
| Debug | dev, test | `-O0 -g` | bật | preset asan/tsan (BD-08) |
| RelWithDebInfo | CI chính, staging, profiler | `-O2 -g` | tắt | cứng hoá (BD-09) |
| Release | bản phát hành máy chủ/client | cờ của HN, vẫn `-g` (BD-10) | tắt | cứng hoá + tách symbol (BD-17) |

- **Vì sao:** `core::debug_check` đổi thân theo `GAME_DEBUG_CHECKS` (tools/include/core/check.hpp): TU
  này có macro, TU kia không là vi phạm ODR — linker giữ một bản tuỳ ý (GN-19). Gắn macro vào target
  INTERFACE mà thư viện gốc link PUBLIC thì mọi TU nhận cùng giá trị; `#define` trong .cpp là cấm.
  `NDEBUG` (CMake tự thêm ở Release/RelWithDebInfo) chỉ tắt `assert` C — dự án dùng `core::check`, luôn bật.
- **Kiểm:** grep `#define GAME_` trong mã nguồn; so `-D` trong compile_commands.json giữa các TU.

```cmake
# cmake/GameOptions.cmake — macro cấu hình chung cho MỌI đơn vị dịch.
add_library(game_options INTERFACE)
add_library(game::options ALIAS game_options)
option(GAME_DEBUG_CHECKS_IN_RELEASE "Bật core::debug_check cả ở bản tối ưu" OFF)
target_compile_definitions(game_options INTERFACE
    "$<$<OR:$<CONFIG:Debug>,$<BOOL:${GAME_DEBUG_CHECKS_IN_RELEASE}>>:GAME_DEBUG_CHECKS>")
```

### BD-04 [N] PHẢI — `CMakePresets.json` mô tả mọi cấu hình dev và CI; CI chỉ gọi preset

Preset `version` 6 (CMake ≥ 3.25: có workflow preset), `cmakeMinimumRequired` 3.28. Preset ẩn cho phần
chung (generator, thư mục build, trình dịch), preset con cho từng tổ hợp. Máy cá nhân thêm
`CMakeUserPresets.json` (không commit).

- **Vì sao:** một lệnh `cmake --workflow --preset ci-gcc` tái hiện đúng build của CI trên máy dev; hết
  "CI dùng cờ khác". `testPresets` mang biến môi trường sanitizer nên `ctest --preset` chạy đúng chế độ.
- **Kiểm:** `cmake --list-presets` trong CI; review: workflow CI không có `-D` rời.

```json
{
  "version": 6,
  "cmakeMinimumRequired": { "major": 3, "minor": 28, "patch": 0 },
  "configurePresets": [
    {
      "name": "base", "hidden": true, "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/${presetName}",
      "cacheVariables": { "CMAKE_EXPORT_COMPILE_COMMANDS": "ON" }
    },
    {
      "name": "not-windows", "hidden": true,
      "condition": { "type": "notEquals", "lhs": "${hostSystemName}", "rhs": "Windows" }
    },
    { "name": "gcc", "hidden": true, "cacheVariables": { "CMAKE_CXX_COMPILER": "g++" } },
    { "name": "clang", "hidden": true, "cacheVariables": { "CMAKE_CXX_COMPILER": "clang++" } },
    { "name": "gcc-debug", "inherits": ["base", "gcc"], "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug" } },
    {
      "name": "gcc-asan", "inherits": ["base", "gcc", "not-windows"],
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug", "GAME_SANITIZE": "address,undefined" }
    },
    {
      "name": "clang-asan", "inherits": ["base", "clang"],
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug", "GAME_SANITIZE": "address,undefined" }
    },
    {
      "name": "clang-tsan", "inherits": ["base", "clang", "not-windows"],
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug", "GAME_SANITIZE": "thread" }
    },
    {
      "name": "ci-gcc", "inherits": ["base", "gcc"],
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "RelWithDebInfo", "GAME_HARDEN": "ON", "CMAKE_COMPILE_WARNING_AS_ERROR": "ON"
      }
    }
  ],
  "buildPresets": [
    { "name": "gcc-debug", "configurePreset": "gcc-debug" },
    { "name": "gcc-asan", "configurePreset": "gcc-asan" },
    { "name": "clang-asan", "configurePreset": "clang-asan" },
    { "name": "clang-tsan", "configurePreset": "clang-tsan" },
    { "name": "ci-gcc", "configurePreset": "ci-gcc" }
  ],
  "testPresets": [
    {
      "name": "asan-env", "hidden": true, "output": { "outputOnFailure": true },
      "environment": {
        "ASAN_OPTIONS": "abort_on_error=1:detect_stack_use_after_return=1:strict_string_checks=1",
        "UBSAN_OPTIONS": "print_stacktrace=1:halt_on_error=1"
      }
    },
    { "name": "gcc-debug", "configurePreset": "gcc-debug", "output": { "outputOnFailure": true } },
    { "name": "gcc-asan", "inherits": "asan-env", "configurePreset": "gcc-asan" },
    { "name": "clang-asan", "inherits": "asan-env", "configurePreset": "clang-asan" },
    {
      "name": "clang-tsan", "configurePreset": "clang-tsan", "output": { "outputOnFailure": true },
      "environment": { "TSAN_OPTIONS": "halt_on_error=1:second_deadlock_stack=1" }
    },
    { "name": "ci-gcc", "configurePreset": "ci-gcc", "output": { "outputOnFailure": true } }
  ],
  "workflowPresets": [
    {
      "name": "ci-gcc",
      "steps": [
        { "type": "configure", "name": "ci-gcc" }, { "type": "build", "name": "ci-gcc" },
        { "type": "test", "name": "ci-gcc" }
      ]
    }
  ]
}
```

### BD-05 [N] PHẢI — clang-tidy dùng đúng `.clang-tidy` của bộ quy cách; `compile_commands.json` luôn bật

Chép nguyên văn `config/.clang-tidy` vào gốc repo (clangd, IDE, clang-tidy tự tìm theo thư mục cha).
`config/.clang-format` chép kèm chỉ để trình soạn định dạng khi lưu; không cổng nào kiểm định dạng.
Sửa luật thì sửa ở bộ quy cách rồi chép lại, không sửa riêng một repo.
`CMAKE_EXPORT_COMPILE_COMMANDS ON` (chỉ Ninja/Makefile sinh tệp này).

- **Vì sao:** `.clang-tidy` bật bugprone/cert/clang-analyzer/concurrency/cppcoreguidelines/misc/
  modernize/performance/portability cùng các check readability bắt lỗi thật, với `WarningsAsErrors: '*'`;
  mỗi check bị tắt có lý do ngay trong tệp. clang-tidy cần compile DB để thấy đúng cờ, macro, thư viện.
- **Kiểm:** lệnh dưới trong CI.

```yaml
# Trích config/.clang-tidy (bản đầy đủ, kèm lý do từng check tắt và CheckOptions, ở tệp gốc).
Checks: >
  -*, bugprone-*, cert-*, clang-analyzer-*, concurrency-*, cppcoreguidelines-*, misc-*,
  modernize-*, performance-*, portability-*,
  readability-<13 check bắt lỗi thật, liệt kê từng tên trong tệp gốc>,
  -modernize-use-trailing-return-type, -cppcoreguidelines-avoid-magic-numbers,
  -misc-non-private-member-variables-in-classes, -portability-simd-intrinsics,
  -portability-avoid-pragma-once, -cppcoreguidelines-pro-bounds-avoid-unchecked-container-access,
  -bugprone-signed-bitwise, -portability-no-assembler, -clang-analyzer-optin.core.EnumCastOutOfRange
WarningsAsErrors: '*'
```

```bash
# Toàn bộ clang-tidy (đêm/tuần); hằng ngày chỉ phần diff (BD-11).
run-clang-tidy -p build/clang-asan -quiet -j 2
```

### BD-06 [N] PHẢI — MSVC: `/W4 /permissive- /Zc:__cplusplus /Zc:preprocessor /utf-8`, `/WX` trong CI (chưa kiểm trên MSVC)

Đã nằm trong `game::warnings` (BD-02). CMake 3.28 ánh xạ `cxx_std_23` thành `-std:c++latest` trên MSVC
và `COMPILE_WARNING_AS_ERROR` thành `-WX` (đọc từ Modules/Compiler/MSVC-CXX.cmake và MSVC.cmake của
CMake 3.28 — không phải chạy MSVC).

- **Vì sao:** `/permissive-` bật hành vi chuẩn (tra tên hai pha, cấm ràng buộc tạm thời vào tham chiếu
  không const); thiếu `/Zc:__cplusplus` thì MSVC báo `__cplusplus` là 199711L và mọi kiểm phiên bản sai
  (BD-01); `/Zc:preprocessor` cho bộ tiền xử lý chuẩn (`__VA_OPT__`); `/utf-8` đọc mã nguồn và chuỗi
  tiếng Việt là UTF-8 thay vì code page hệ thống. Mức hỗ trợ C++23 của MSVC: CHƯA kiểm trên MSVC — mọi
  tính năng dùng ở code Windows phải qua feature-test macro (STD-16) và CI Windows. Với
  `/std:c++latest`, `__cplusplus` tuỳ phiên bản (tài liệu Microsoft: lớn hơn giá trị của chuẩn cao
  nhất mà bản đó hỗ trợ đủ), có thể nhỏ hơn 202302L: `static_assert` của core/platform.hpp (BD-01)
  chưa kiểm trên MSVC.
- **Kiểm:** CI Windows (nếu ship client Windows) với preset `msvc-*`.

```cmake
# Trích cmake/GameWarnings.cmake: nhánh MSVC (CMake thêm /EHsc mặc định cho MSVC).
target_compile_options(game_warnings INTERFACE
    "$<$<CXX_COMPILER_ID:MSVC>:/W4;/permissive-;/Zc:__cplusplus;/Zc:preprocessor;/utf-8>")
```

### BD-07 [N] NÊN — Ninja + ccache; quét module tắt khi chưa dùng module

`"CMAKE_CXX_COMPILER_LAUNCHER": "ccache"` trong preset base; generator `Ninja`. Dùng PCH (BD-13) thì đặt
`CCACHE_SLOPPINESS=pch_defines,time_macros`.

- **Vì sao:** Ninja song song đúng theo đồ thị phụ thuộc và ghi `.ninja_log` (BD-15); ccache bỏ qua TU
  không đổi khi đổi nhánh git. CMake 3.28 quét module mọi tệp khi chuẩn ≥ 20 (CMP0155): thêm một bước
  cho mỗi TU vô ích nếu không có module.
- **Kiểm:** `ccache -s` sau build CI thứ hai (tỉ lệ trúng). `CMAKE_CXX_COMPILER_LAUNCHER` là biến chuẩn của
  CMake; tổ hợp với ccache chưa chạy trên máy kiểm.

```json
{ "name": "base", "hidden": true, "generator": "Ninja",
  "cacheVariables": { "CMAKE_CXX_COMPILER_LAUNCHER": "ccache" } }
```

## 2. Nâng cao [C]

### BD-08 [C] PHẢI — Preset sanitizer: `address,undefined` chung một build, `thread` build riêng; cờ biên dịch và liên kết khớp nhau

Cờ: `-fsanitize=<danh sách> -fno-sanitize-recover=all -fno-omit-frame-pointer`, cùng `-fsanitize` khi
liên kết; GCC thêm `-fsanitize=float-cast-overflow`. Biến môi trường trong `testPresets` (BD-04).
Windows: chỉ Clang (đích MSVC) có ASan + UBSan, buộc CRT phát hành `/MD` (CRT debug làm ASan báo nhầm
"free on address which was not malloc()-ed", đo), runtime `clang_rt.asan_dynamic` phải nằm trên PATH;
`detect_leaks` không có trên Windows (trên Linux LSan bật sẵn cùng ASan); không có TSan; GCC MinGW
không có runtime sanitizer. Chính sách (test nào chạy dưới sanitizer nào,
MSan, chế độ trap cho production): refs/13-ub-on-dinh.md.

- **Vì sao:** ASan và TSan dùng cách ánh xạ bộ nhớ bóng xung khắc, không chung một binary. Thiếu
  `-fno-sanitize-recover=all` thì UBSan chỉ in rồi chạy tiếp → test vẫn "qua". Thiếu `-fsanitize` khi
  liên kết là lỗi `undefined reference to __asan_…`. Frame pointer cho stack trace của sanitizer nhanh và
  đủ.
- **Kiểm:** `ctest --preset clang-asan`, `ctest --preset clang-tsan` trong CI (BD-12).

```cmake
# cmake/GameSanitize.cmake
set(GAME_SANITIZE "" CACHE STRING "Sanitizer: address,undefined | thread | rỗng")
if(GAME_SANITIZE STREQUAL "")
    return()
endif()
if(GAME_SANITIZE MATCHES "thread" AND GAME_SANITIZE MATCHES "address")
    message(FATAL_ERROR "TSan và ASan không dùng chung một bản build")
endif()
add_compile_options(
    "-fsanitize=${GAME_SANITIZE}"
    -fno-sanitize-recover=all
    -fno-omit-frame-pointer)
add_link_options("-fsanitize=${GAME_SANITIZE}")
# Clang nhắm MSVC: ASan chỉ chạy với CRT phát hành (/MD); CRT debug (ucrtbased) giải phóng bằng
# heap riêng và ASan báo "free on address which was not malloc()-ed".
if(CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
    set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
endif()
# GCC: float-cast-overflow không nằm trong nhóm undefined (UB-07).
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND GAME_SANITIZE MATCHES "undefined")
    add_compile_options(-fsanitize=float-cast-overflow)
endif()
```

### BD-09 [C] PHẢI — Bản RelWithDebInfo/Release của máy chủ bật cờ cứng hoá OpenSSF và kiểm biên thư viện; kiểm kết quả trên binary

Cờ (OpenSSF Compiler Options Hardening Guide): `-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3`,
`-fstack-protector-strong`, `-fstack-clash-protection`, `-fcf-protection=full` (x86-64), PIE,
`-Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack`; thêm `-ftrivial-auto-var-init=zero` (UB-06). Hướng dẫn
OpenSSF còn liệt kê `-fno-strict-overflow`, `-fno-strict-aliasing`, `-fno-delete-null-pointer-checks`:
dự án KHÔNG dùng (UB-12). Kiểm biên thư viện: `_GLIBCXX_ASSERTIONS` / `_LIBCPP_HARDENING_MODE` (mức
`DEBUG` cho Debug, `FAST` cho bản tối ưu) — bật ở cấu hình nào, mức nào là chính sách của UB (UB-08);
tệp này chỉ quy định cách gắn: ở mức thư mục gốc, cho mọi TU. STL MSVC: `_MSVC_STL_HARDENING=1`.
PE (Windows) không có RELRO/BIND_NOW: liên kết `/DYNAMICBASE /HIGHENTROPYVA /NXCOMPAT` (MinGW:
`--dynamicbase --high-entropy-va --nxcompat`); `-fstack-clash-protection` chỉ cho ELF.

- **Vì sao:** chặn khai thác lỗi bộ nhớ còn sót (tràn ngăn xếp, ghi đè GOT, ROP) với chi phí nhỏ. `-U`
  trước `-D_FORTIFY_SOURCE=3` vì nhiều bản phân phối định nghĩa sẵn mức khác → cảnh báo định nghĩa lại;
  FORTIFY chỉ có tác dụng khi tối ưu (≥ `-O1`). `CheckPIESupported` + `POSITION_INDEPENDENT_CODE` cho
  `-fPIE` khi biên dịch và `-pie` khi liên kết (đo trong lệnh link). Macro thư viện phải giống nhau ở mọi
  TU (ODR, GN-19): định nghĩa cả hai, thư viện nào không dùng macro của mình thì bỏ qua.
- **Kiểm:** `readelf` trên binary (đo trên bản build mẫu: `DYN (Position-Independent Executable)`,
  `BIND_NOW`, `GNU_RELRO`, `x86 feature: IBT, SHSTK`).

```cmake
# cmake/GameHarden.cmake
option(GAME_HARDEN "Cờ cứng hoá cho bản phát hành" OFF)
option(GAME_LIB_HARDENING "Kiểm biên của libstdc++/libc++/STL MSVC (chính sách: refs/13)" ON)
if(GAME_LIB_HARDENING)
    # libc++: DEBUG (có thông điệp) cho Debug, FAST (trap, rẻ) cho bản tối ưu — UB-08.
    set(libcxx_mode "$<IF:$<CONFIG:Debug>,_LIBCPP_HARDENING_MODE_DEBUG,_LIBCPP_HARDENING_MODE_FAST>")
    add_compile_definitions(_GLIBCXX_ASSERTIONS "_LIBCPP_HARDENING_MODE=${libcxx_mode}"
                            _MSVC_STL_HARDENING=1)
endif()
if(NOT GAME_HARDEN)
    return()
endif()
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
include(CheckPIESupported)
check_pie_supported()
add_compile_options(
    -U_FORTIFY_SOURCE
    -D_FORTIFY_SOURCE=3
    -fstack-protector-strong
    -ftrivial-auto-var-init=zero
    "$<$<STREQUAL:${CMAKE_SYSTEM_PROCESSOR},x86_64>:-fcf-protection=full>")
if(WIN32)
    # PE: ASLR 64 bit + DEP. MinGW ld nhận dạng --, lld-link/link.exe nhận dạng /.
    if(CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
        add_link_options(LINKER:/DYNAMICBASE LINKER:/HIGHENTROPYVA LINKER:/NXCOMPAT)
    else()
        add_link_options(LINKER:--dynamicbase LINKER:--high-entropy-va LINKER:--nxcompat)
    endif()
    return()
endif()
# ELF: stack clash chỉ có ý nghĩa với stack tăng theo trang của Linux; RELRO, BIND_NOW, NX.
add_compile_options(-fstack-clash-protection)
add_link_options(LINKER:-z,relro LINKER:-z,now LINKER:-z,noexecstack)
```

```bash
# Kiểm cứng hoá trên binary phát hành (CI chạy sau build ci-*).
readelf -h build/ci-gcc/game_server | grep 'Type:.*DYN'
readelf -d build/ci-gcc/game_server | grep -E 'BIND_NOW|FLAGS_1.*NOW'
readelf -lW build/ci-gcc/game_server | grep GNU_RELRO
readelf -n build/ci-gcc/game_server | grep -E 'IBT, SHSTK'
```

### BD-10 [C] PHẢI — Mọi cấu hình máy chủ giữ frame pointer, thông tin gỡ lỗi và build-id; đường dẫn nguồn trong binary là tương đối

`-fno-omit-frame-pointer` và `-g` ở cả Release; `-Wl,--build-id=sha1`;
`-ffile-prefix-map=<gốc nguồn>=.` (Clang đích MSVC: PDB thay build-id). Dự án lớn: `-gsplit-dwarf` cho build dev (giảm thời gian liên kết;
đo: GCC 14 và Clang 20 sinh `.dwo` cạnh `.o`).

- **Vì sao:** frame pointer tốn một thanh ghi (thường dưới vài phần trăm, đo theo HN) nhưng cho stack
  trace tin được trong perf, sanitizer, crash handler; `-g` không đổi mã máy sinh ra, chỉ thêm section
  (tách ra ở BD-17). build-id nối binary đang chạy với tệp symbol đúng. `-ffile-prefix-map` bỏ đường dẫn
  tuyệt đối của máy build khỏi binary và `__FILE__`/`source_location` (dữ liệu `core::check` in ra):
  build tái lập được, không lộ cấu trúc máy build.
- **Kiểm:** `readelf -n` thấy `Build ID`; `strings binary | grep /home/` rỗng.

```cmake
# cmake/GameDebugInfo.cmake
add_compile_options(
    -fno-omit-frame-pointer
    "$<$<CONFIG:Release>:-g>"
    "-ffile-prefix-map=${PROJECT_SOURCE_DIR}=.")
# build-id: ld của ELF và PE (MinGW). Clang nhắm MSVC liên kết bằng lld-link/link.exe, ghi PDB.
if(NOT CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
    add_link_options(LINKER:--build-id=sha1)
endif()
```

### BD-11 [C] PHẢI — clang-tidy trong CI chạy trên phần diff, bằng compile DB của build Clang + libc++, 0 cảnh báo

`git diff -U0 <gốc> | clang-tidy-diff.py -p1 -path <thư mục build> -config-file .clang-tidy -quiet`.
Mã thoát khác 0 khi có cảnh báo (đo, nhờ `WarningsAsErrors: '*'`). Toàn bộ repo chạy định kỳ (BD-05).

- **Vì sao:** chạy toàn repo mỗi PR tốn hàng chục phút; diff chỉ kiểm dòng mới. Bẫy: ở
  `clang-tidy-diff.py`, `-p` là SỐ thành phần tiền tố bỏ khỏi đường dẫn diff (như `patch -p1`), thư mục
  build là `-path` — ngược với `clang-tidy -p`. clang-tidy dựng lại lệnh từ compile DB: DB của build GCC
  thiếu `-stdlib=libc++`, còn trình dịch trong DB là script bọc thì clang-tidy không tìm thấy header chuẩn
  (đo: `'cstdio' file not found`) — dùng DB của preset Clang với đường dẫn trình dịch thật.
- **Kiểm:** job CI `tidy-diff`; mã thoát.

```bash
# Job tidy-diff: chỉ dòng thay đổi so với nhánh chính. LLVM_ROOT: gốc bản cài LLVM 20
# (apt.llvm.org: /usr/lib/llvm-20); script nằm ở share/clang/.
cmake --preset clang-asan
git diff -U0 origin/main...HEAD -- '*.cpp' '*.hpp' |
    python3 "$LLVM_ROOT/share/clang/clang-tidy-diff.py" -p1 -path build/clang-asan \
        -clang-tidy-binary "$LLVM_ROOT/bin/clang-tidy" -config-file .clang-tidy -quiet -j 2
```

### BD-12 [C] PHẢI — Ma trận CI: hai thư viện chuẩn × hai mục đích, cộng TSan; mọi PR qua hết

| Job | Preset | Kiểm |
|---|---|---|
| gcc-release | `ci-gcc` (GCC 14, libstdc++, RelWithDebInfo, cứng hoá, `-Werror`) | build, ctest, readelf (BD-09) |
| gcc-asan | `gcc-asan` (GCC 14, libstdc++, Debug, ASan+UBSan+`float-cast-overflow`) | build, ctest |
| clang-asan | `clang-asan` (Clang 20, libc++, Debug, ASan+UBSan) | build, ctest |
| clang-tsan | `clang-tsan` | ctest test đồng thời (DT, KT) |
| fuzz | — (Clang 20, `-fsanitize=fuzzer,address,undefined`) | mỗi harness 5 phút trên corpus (KT-11) |
| tidy-diff | `clang-asan` | BD-11 |
| msvc (khi ship client Windows) | `msvc-*` | build, ctest — CHƯA kiểm trên MSVC |

- **Vì sao:** libstdc++ và libc++ khác nhau thật ở thư viện C++23 (STD §0), ở `std::hash`, phân phối
  `<random>` (STD-14, STD-15) — chỉ build một bên thì code gãy ở bên kia hoặc lệch tất định. GCC và Clang
  bắt các cảnh báo khác nhau. ASan và TSan không chung build (BD-08).
- **Kiểm:** quy tắc nhánh bảo vệ: mọi job phải xanh.

```bash
# Tái hiện CI trên máy dev.
cmake --workflow --preset ci-gcc
cmake --preset gcc-asan && cmake --build --preset gcc-asan && ctest --preset gcc-asan
cmake --preset clang-asan && cmake --build --preset clang-asan && ctest --preset clang-asan
cmake --preset clang-tsan && cmake --build --preset clang-tsan && ctest --preset clang-tsan
```

### BD-13 [C] NÊN — PCH cho header chuẩn nặng và ổn định; CI có một build tắt PCH

`target_precompile_headers(t PRIVATE <format> <string> <vector>)` — chỉ header chuẩn/ổn định, không header
dự án hay đổi. Một job CI cấu hình `-DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON`.

- **Vì sao:** `<format>`, `<ranges>`, `<chrono>` mỗi cái tốn đáng kể thời gian phân tích ở MỌI TU (đo bằng
  BD-15 trước khi thêm). PCH được ép vào đầu mọi TU của target: header thiếu `#include` vẫn biên dịch
  được nhờ PCH, rồi gãy ở nơi khác — build không PCH giữ header tự đủ (KTR). Đo: CMake 3.28 sinh
  `cmake_pch.hxx.gch` với GCC 14; `CMAKE_DISABLE_PRECOMPILE_HEADERS=ON` bỏ hẳn bước này.
- **Kiểm:** job CI không PCH; clang-tidy `misc-include-cleaner`.

```cmake
# CMakeLists.txt: header chuẩn nặng, ổn định — tiền biên dịch một lần cho target.
target_precompile_headers(game_core PRIVATE <format> <string> <vector>)
```

## 3. Thần thoại [T]

### BD-14 [T] CÓ THỂ — Module C++20 của dự án qua `FILE_SET CXX_MODULES` (CMake 3.28 + Ninja ≥ 1.11); `import std;` chưa

Module nội bộ: `target_sources(t PUBLIC FILE_SET CXX_MODULES FILES x.cppm)`, bỏ
`CMAKE_CXX_SCAN_FOR_MODULES OFF`. Thiết kế module và partition: KTR. `import std;` cần CMake ≥ 3.30
(`CXX_MODULE_STD`, sau cổng thử nghiệm `CMAKE_EXPERIMENTAL_CXX_IMPORT_STD` có giá trị UUID đổi theo
phiên bản — lấy từ tài liệu của đúng bản CMake) — chưa dùng (STD-22).

- **Vì sao:** đo trên máy kiểm: dự án mẫu một module + một chương trình build và chạy với GCC 14.2 và
  Clang 20.1 (CMake 3.28.3, Ninja 1.11.1). Clang cần `clang-scan-deps`: CMake tìm cạnh trình dịch; khi
  trình dịch là script bọc thì đặt `CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS` (đo: thiếu thì lỗi
  `CMAKE_CXX_COMPILER_CLANG_SCAN_DEPS-NOTFOUND`). BMI không dùng chung giữa trình dịch hay cờ khác nhau;
  clangd/clang-tidy hỗ trợ module còn hạn chế — cân nhắc trước khi chuyển cả dự án.
- **Kiểm:** job CI build cả GCC và Clang với module.

```cmake
# Module game.math dùng ở game_server.
add_library(game_math)
target_sources(game_math
    PUBLIC
        FILE_SET CXX_MODULES
        FILES src/math/math.cppm)
target_compile_features(game_math PUBLIC cxx_std_23)
target_link_libraries(game_server PRIVATE game_math)
```

### BD-15 [T] NÊN — Đo thời gian build trước khi tối ưu nó: `.ninja_log`, Clang `-ftime-trace`, GCC `-ftime-report`

Mọi thay đổi nhằm tăng tốc build (PCH, `extern template`, tách header, module) kèm số đo trước/sau trên
cùng preset, build sạch, cùng số luồng.

- **Vì sao:** cảm giác "header này chậm" thường sai; số đo chỉ ra TU và template tốn nhất (GN-16).
  `.ninja_log` (v5: bắt đầu, kết thúc ms, mtime, đích) có sẵn sau mỗi build. Clang `-ftime-trace` ghi
  JSON cạnh mỗi `.o` (đo: `CMakeFiles/<target>.dir/<tệp>.cpp.json`), mở bằng Perfetto hoặc
  `chrome://tracing`, thấy từng bước phân tích, khởi tạo, sinh mã. GCC 14 không có `-ftime-trace` (đo:
  "unrecognized command-line option"); `-ftime-report` in bảng theo pha.
- **Kiểm:** ghi số đo trước/sau vào mô tả PR.

```bash
# 10 đích build lâu nhất của lần build gần nhất (ms).
awk -F'\t' 'NR > 1 { print $2 - $1, $4 }' build/clang-asan/.ninja_log | sort -rn | head -10
# Trace thời gian biên dịch từng TU (Clang). -DCMAKE_CXX_FLAGS THAY giá trị preset: giữ -stdlib=libc++.
cmake --preset clang-asan "-DCMAKE_CXX_FLAGS=-stdlib=libc++ -ftime-trace" && cmake --build --preset clang-asan
```

### BD-16 [T] NÊN — Liên kết bằng lld (hoặc mold); bỏ section thừa bằng `--gc-sections`; gộp hàm trùng bằng `--icf=safe`

`-fuse-ld=lld` (GCC và Clang); `-ffunction-sections -fdata-sections` + `-Wl,--gc-sections`;
`-Wl,--icf=safe` hoặc `--icf=all` (lld, gold, mold có; GNU ld KHÔNG có). LTO, PGO, BOLT: HN.

- **Vì sao:** liên kết là bước tuần tự cuối của mọi build tăng dần: lld/mold nhanh hơn GNU ld rõ rệt
  trên binary lớn (đo trên dự án thật trước khi kết luận). `--gc-sections` bỏ hàm/biến không ai tham
  chiếu; `--icf=all` gộp các khởi tạo template có mã máy giống hệt (vd. `Pool<A>::clear` và
  `Pool<B>::clear`). Bẫy: `--icf=all` làm hai hàm khác nhau có CÙNG địa chỉ — code so sánh con trỏ hàm
  sẽ sai; `--icf=safe` chỉ gộp hàm không bị lấy địa chỉ, biết nhờ bảng `.llvm_addrsig` mà chỉ Clang
  sinh: object của GCC không có bảng nên lld coi mọi hàm là bị lấy địa chỉ (đo: hai `clear<T>` giống
  hệt được gộp với Clang 20, không với GCC 14). Build GCC muốn gộp thì `--icf=all` và chấp nhận bẫy
  trên. Đo: tệp dưới build, liên kết bằng lld và test chạy với GCC 14 và Clang 20.
- **Kiểm:** `readelf -n` (build-id còn), test hồi quy so con trỏ hàm.

```cmake
# Trích cmake/GameLink.cmake: chỉ đích ELF, linker lld.
add_compile_options(-ffunction-sections -fdata-sections)
add_link_options(-fuse-ld=lld LINKER:--gc-sections LINKER:--icf=safe)
```

### BD-17 [T] PHẢI — Mọi bản phát hành tách symbol theo build-id và lưu lại; binary chạy trên máy chủ không có `.debug_*`

Sau liên kết: `objcopy --only-keep-debug` ra `<binary>.debug`, `objcopy --strip-debug --strip-unneeded`
binary, `objcopy --add-gnu-debuglink`. Lưu `.debug` theo build-id vào kho symbol; crash dump (core) +
symbol → stack trace đầy đủ.

- **Vì sao:** binary gọn, không lộ thông tin gỡ lỗi; symbol vẫn khớp chính xác bản đang chạy nhờ
  build-id (đo: build-id của binary đã strip và tệp `.debug` trùng nhau). Không lưu symbol thì crash
  production chỉ còn địa chỉ trần. `std::stacktrace` (STD-13) chỉ có ở libstdc++ và cần
  `-lstdc++exp` (đo GCC 14, 15): `target_link_libraries(t PRIVATE
  "$<$<CXX_COMPILER_ID:GNU>:stdc++exp>")`; core dump + symbol hoạt động với mọi trình dịch.
- **Kiểm:** CI kiểm `readelf -S binary` có `.gnu_debuglink`, không có `.debug_info`.

```cmake
# cmake/GameSplitDebug.cmake
function(game_split_debug target)
    # Clang nhắm MSVC: debug info đã nằm riêng trong .pdb, không có objcopy.
    if(CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
        return()
    endif()
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} --only-keep-debug $<TARGET_FILE:${target}>
                $<TARGET_FILE:${target}>.debug
        COMMAND ${CMAKE_OBJCOPY} --strip-debug --strip-unneeded $<TARGET_FILE:${target}>
        COMMAND ${CMAKE_OBJCOPY} --add-gnu-debuglink=$<TARGET_FILE:${target}>.debug
                $<TARGET_FILE:${target}>
        VERBATIM)
endfunction()
```

### BD-18 [T] CÓ THỂ — `-fhardened` (GCC ≥ 14) thay danh sách cờ của BD-09 trên build GCC; kiểm macro thật nó sinh ra

Chỉ cho preset GCC; build Clang giữ danh sách cờ của BD-09. Không trộn `-fhardened` với `-D_FORTIFY_SOURCE`.

- **Vì sao:** một cờ gom đủ bộ OpenSSF; danh sách in bằng `g++ --help=hardened` (đo GCC 14.2):
  `-D_FORTIFY_SOURCE=3 (or =2 for glibc < 2.35)`, `-D_GLIBCXX_ASSERTIONS`, `-ftrivial-auto-var-init=zero`,
  `-fPIE -pie`, `-Wl,-z,now`, `-Wl,-z,relro`, `-fstack-protector-strong`, `-fstack-clash-protection`,
  `-fcf-protection=full`. Nhưng: GCC tự bỏ FORTIFY khi `-O0` hay khi đã có `-D/-U_FORTIFY_SOURCE` (cảnh báo
  `-Whardened`, đo); mức FORTIFY do glibc lúc CẤU HÌNH GCC quyết định — GCC 14 xpack trên máy kiểm ra
  `_FORTIFY_SOURCE=2` dù glibc hệ thống là 2.39 (đo bằng `-dM -E`); và nó kéo `_GLIBCXX_ASSERTIONS` vào —
  quyết định chính sách của UB. Clang 20 KHÔNG có `-fhardened` (đo: "unknown argument").
- **Kiểm:** lệnh dưới trong CI build GCC.

```bash
g++ --help=hardened
# Macro thật mà một TU nhận được với cờ phát hành:
g++ -std=c++23 -O2 -fhardened -dM -E -x c++ /dev/null |
    grep -E '_FORTIFY_SOURCE|_GLIBCXX_ASSERTIONS|__PIE__|__SSP_STRONG__|__CET__'
```

### BD-19 [T] PHẢI — Công cụ lỗi thì tắt ĐÚNG check/cờ gây lỗi, ghi phiên bản và lý do cạnh chỗ tắt, giữ ca tái hiện

Không tắt cả nhóm (`-bugprone-*`), không hạ `WarningsAsErrors`. Mỗi lần tắt: dòng comment trong
`.clang-tidy`/CMake nêu công cụ, phiên bản, triệu chứng, quy tắc thay thế; kiểm lại khi nâng phiên bản.

- **Vì sao:** lỗi đã gặp thật trên bộ này: (1) clang-tidy 20 SẬP ở `modernize-use-std-print` khi chuỗi
  định dạng printf chứa UTF-8 (tiếng Việt) → check từng bị tắt; clang-tidy 23 hết lỗi (đo) → bật lại;
  `core/check.hpp` vẫn giữ chuỗi printf ASCII cho công cụ cũ. (2) clang-tidy 20
  `cppcoreguidelines-missing-std-forward` báo nhầm khi tham số `this Self&&` chỉ được chuyển tiếp qua
  `std::forward_like` → NOLINT có lý do (GN-15). (3) GCC 14/15 cảnh báo `#pragma once in main file` cả
  khi phân tích header đứng riêng bằng `-x c++-header -fsyntax-only` (GCC 14 không có cờ tắt riêng;
  GCC 15 có `-Wno-pragma-once-outside-header`) → kiểm header tự đủ bằng một .cpp chỉ `#include` nó
  (KTR-03). (4) clang-tidy 23: `clang-analyzer-optin.core.EnumCastOutOfRange` báo bên trong
  `<filesystem>` của STL MSVC 14.51 với mọi mã dùng nó → tắt; `readability-redundant-parentheses` báo
  nhầm ngoặc bắt buộc quanh lời gọi hàm trong mệnh đề `requires` → tắt.
- **Kiểm:** review mọi dòng `-check` trong `.clang-tidy` và mọi NOLINT có lý do + phiên bản.

```yaml
# .clang-tidy: tắt đúng một check, kèm lý do và phiên bản.
Checks: >
  ...,
  -clang-analyzer-optin.core.EnumCastOutOfRange
#   EnumCastOutOfRange: clang-tidy 23.1 báo nhầm trong xfilesystem_abi.h của STL MSVC 14.51 với
#   mọi mã dùng <filesystem>. Kiểm lại khi nâng LLVM hoặc STL MSVC.
```

## Kiểm nhanh

- [ ] `cmake_minimum_required(VERSION 3.28)`, `cxx_std_23` theo target, `CMAKE_CXX_EXTENSIONS OFF`, không sửa `CMAKE_CXX_FLAGS`? (BD-01)
- [ ] Mọi target dự án link `game::warnings`; danh sách cờ chỉ ở `config/warnings-*.txt`? (BD-02)
- [ ] `GAME_DEBUG_CHECKS` và macro thư viện gắn ở mức target/thư mục, giống nhau mọi TU? (BD-03, BD-09)
- [ ] Mọi cấu hình CI là một preset; dev tái hiện bằng `cmake --workflow --preset`? (BD-04, BD-12)
- [ ] `.clang-tidy` là bản chép nguyên văn của bộ quy cách; `compile_commands.json` bật? (BD-05)
- [ ] ASan+UBSan và TSan là hai build riêng, `-fno-sanitize-recover=all`? (BD-08)
- [ ] Binary phát hành: PIE, BIND_NOW, RELRO, FORTIFY, frame pointer, build-id, symbol đã tách và lưu? (BD-09, BD-10, BD-17)
- [ ] clang-tidy-diff dùng `-path` cho thư mục build và DB của build Clang? (BD-11)
- [ ] CI có build cả libstdc++ và libc++? (BD-12)
- [ ] Có job build không PCH? (BD-13)
- [ ] Mỗi check/cờ tắt có phiên bản công cụ + lý do? (BD-19)
