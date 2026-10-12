# THIENLONG — client tự viết nạp tài nguyên Thiên Long Bát Bộ. Khung theo bộ quy cách C++23
# (refs/14 BD-01..BD-17): cờ theo target, cảnh báo từ config/warnings-*.txt, preset cho từng trình
# dịch và nền tảng, sanitizer, cứng hoá, tách symbol. Mã nguồn ở SRC/<module>/, test ở tests/, công
# cụ Python ở TOOLS/, bản chạy và dữ liệu ở CLIENT/.
cmake_minimum_required(VERSION 3.28)
project(thienlong VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
# Chưa dùng module C++20:
# tắt quét phụ thuộc (CMP0155).
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
# cl 19.51: cxx_std_23 sinh -std:c++latest (__cplusplus 202400). Ghim đúng C++23 (đo ở cpp-build).
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set(CMAKE_CXX23_STANDARD_COMPILE_OPTION "-std:c++23preview")
    set(CMAKE_CXX23_EXTENSION_COMPILE_OPTION "-std:c++23preview")
endif()

include(cmake/GameWarnings.cmake)
include(cmake/GameOptions.cmake)
include(cmake/GameSanitize.cmake)
include(cmake/GameHarden.cmake)
include(cmake/GameDebugInfo.cmake)
include(cmake/GameSplitDebug.cmake)

# GCC của MinGW: std::print ghi console Windows qua các hàm nằm trong libstdc++exp (đo với GCC 16.2:
# thiếu thì lỗi liên kết ở vprint_unicode).
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND WIN32)
    target_link_libraries(game_options INTERFACE stdc++exp)
    # Liên kết tĩnh runtime của GCC: exe không còn phụ thuộc libstdc++-6.dll tìm theo PATH (đo: Git
    # Bash đặt bản libstdc++ cũ của nó lên trước, exe dùng std::print không nạp được, mã thoát 127).
    target_link_options(game_options INTERFACE -static)
endif()

# Test của bản Android chạy trên thiết bị qua adb (cmake/GameAndroidRun.cmake).
if(ANDROID)
    set(CMAKE_CROSSCOMPILING_EMULATOR
        "${CMAKE_COMMAND};-P;${PROJECT_SOURCE_DIR}/cmake/GameAndroidRun.cmake")
endif()

# clangd của trình soạn thảo tìm compile_commands.json ở gốc dự án (tệp nằm trong .gitignore);
# thiếu thì nó báo lỗi giả vì không biết thư mục include. Chép sau mỗi lượt build trên máy dev.
if(NOT CMAKE_CROSSCOMPILING)
    add_custom_target(compile_db ALL
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${PROJECT_BINARY_DIR}/compile_commands.json ${PROJECT_SOURCE_DIR}/compile_commands.json
        COMMENT "Chép compile_commands.json ra gốc dự án cho clangd")
endif()

# Gom mọi module để header_check thấy header của chúng.
add_library(game_all_modules INTERFACE)

# Module: SRC/<m>/, x.hpp cạnh x.cpp; include "<m>/x.hpp" từ gốc SRC/. Module mới: một dòng
# game_module ở dưới và một dòng trong bảng tầng cmake/GameLayers.cmake.
function(game_module name)
    add_library(game_${name} STATIC ${ARGN})
    target_include_directories(game_${name} PUBLIC ${PROJECT_SOURCE_DIR}/SRC)
    target_compile_features(game_${name} PUBLIC cxx_std_23)
    target_link_libraries(game_${name} PUBLIC game::options PRIVATE game::warnings)
    target_link_libraries(game_all_modules INTERFACE game_${name})
endfunction()

# core: đồng hồ, lỗi, log, luồng. Cùng API C++ trên mọi nền tảng (Result, template park), không
# thêm biên C. Win32: WaitOnAddress và ntdll. POSIX: futex 4 byte (Android, nhân 4.9 không có
# futex_waitv) hoặc __ulock_wait (iOS). log của Android là liblog.
set(game_core_sources
    SRC/core/clock.cpp
    SRC/core/error.cpp
    SRC/core/log.cpp
    SRC/core/log_sink.cpp
    SRC/core/range.cpp
    SRC/core/system.cpp
    SRC/core/text.cpp
    SRC/core/uarch.cpp)
if(WIN32)
    list(APPEND game_core_sources SRC/core/handle.cpp SRC/core/thread.cpp)
else()
    list(APPEND game_core_sources
        SRC/core/handle_posix.cpp
        SRC/core/log_sink_posix.cpp
        SRC/core/system_posix.cpp
        SRC/core/thread_posix.cpp)
endif()
game_module(core ${game_core_sources})
if(WIN32)
    target_link_libraries(game_core PRIVATE synchronization ntdll)
endif()
if(ANDROID)
    target_link_libraries(game_core PRIVATE log)
endif()

# Phần phụ thuộc hệ điều hành của io nằm ở tệp riêng theo nền tảng.
if(WIN32)
    set(game_io_platform SRC/io/platform_win32.cpp)
elseif(APPLE)
    set(game_io_platform SRC/io/platform_apple.cpp)
else()
    set(game_io_platform SRC/io/platform_posix.cpp)
endif()
game_module(io SRC/io/file.cpp ${game_io_platform})
target_link_libraries(game_io PUBLIC game_core)

game_module(xml SRC/xml/document.cpp)
target_link_libraries(game_xml PUBLIC game_core)

# miniaudio chỉ giải mã và mở thiết bị. Cảnh báo của header đó không vào game::warnings.
add_library(game_audio_native STATIC SRC/audio/detail/native.cpp)
target_include_directories(game_audio_native PUBLIC ${PROJECT_SOURCE_DIR}/SRC
    ${PROJECT_SOURCE_DIR}/third_party/miniaudio)
target_compile_features(game_audio_native PUBLIC cxx_std_23)
target_link_libraries(game_audio_native PUBLIC game_core game::options)
if(MSVC)
    target_compile_options(game_audio_native PRIVATE /w /utf-8)
else()
    target_compile_options(game_audio_native PRIVATE -w)
endif()
if(ANDROID)
    target_link_libraries(game_audio_native PUBLIC aaudio log)
endif()
game_module(audio
    SRC/audio/catalog.cpp
    SRC/audio/cook.cpp
    SRC/audio/detail/codec.cpp
    SRC/audio/detail/music.cpp
    SRC/audio/engine.cpp
    SRC/audio/gain.cpp
    SRC/audio/limiter.cpp
    SRC/audio/pack.cpp
    SRC/audio/resample.cpp)
target_link_libraries(game_audio PUBLIC game_core game_io game_xml PRIVATE game_audio_native)
# Tệp âm thanh cook (.tla) mang Opus. Preset GCC không lấy được gói vcpkg của MSVC: ở đó module
# vẫn dựng, chỉ không đọc được tải Opus (tệp gốc WAV/MP3 và tải PCM vẫn chạy).
find_package(Opus CONFIG QUIET)
if(TARGET Opus::opus)
    # Preset có sanitizer build Debug nhưng chạy CRT release (ASan đòi). Bản Debug của opus.lib
    # kéo CRT debug (_CrtDbgReportW) nên không link được ở đó: dùng bản Release của nó.
    if(CMAKE_MSVC_RUNTIME_LIBRARY STREQUAL "MultiThreadedDLL")
        set_target_properties(Opus::opus PROPERTIES MAP_IMPORTED_CONFIG_DEBUG Release)
    endif()
    target_link_libraries(game_audio PRIVATE Opus::opus)
    target_compile_definitions(game_audio PRIVATE GAME_AUDIO_OPUS)
endif()
# Công cụ cook của máy dựng: cây sound gốc (WAV, MP3) thành tệp .tla 48 kHz. Không đóng vào thiết bị.
if(NOT ANDROID AND NOT IOS)
    add_executable(thienlong_audio SRC/audiotool/main.cpp)
    target_link_libraries(thienlong_audio PRIVATE game_audio game::warnings)
    # Cook cây sound của client ra build/cooked/sound, chung cho mọi preset. Chạy lại chỉ cook
    # tệp đổi. Gọi tay (cmake --build ... --target cook_sound) trước khi đóng APK.
    add_custom_target(cook_sound
        COMMAND thienlong_audio cook "${PROJECT_SOURCE_DIR}/CLIENT/data/sound"
            "${PROJECT_SOURCE_DIR}/build/cooked/sound"
        COMMENT "Cook âm thanh ra build/cooked/sound"
        VERBATIM)
endif()

# Niêm asset trên máy dựng. Client không liên kết game_seal: đường nạp và khung hình không đổi.
if(NOT CMAKE_CROSSCOMPILING)
    add_subdirectory(third_party/libsodium)
    game_module(seal
        SRC/seal/key.cpp
        SRC/seal/package.cpp
        SRC/seal/tree.cpp
        SRC/seal/detail/format.cpp)
    add_library(game_seal_native STATIC SRC/seal/detail/sodium.cpp)
    target_include_directories(game_seal_native PUBLIC ${PROJECT_SOURCE_DIR}/SRC)
    target_compile_features(game_seal_native PUBLIC cxx_std_23)
    target_link_libraries(game_seal_native PUBLIC game_sodium game::options)
    if(MSVC)
        target_compile_options(game_seal_native PRIVATE /w /utf-8)
    else()
        target_compile_options(game_seal_native PRIVATE -w)
    endif()
    target_link_libraries(game_seal PUBLIC game_io game_seal_native)
    add_executable(thienlong_seal SRC/sealtool/main.cpp)
    target_link_libraries(thienlong_seal PRIVATE game_seal game::warnings)
    if(WIN32)
        target_link_libraries(thienlong_seal PRIVATE shell32)
    endif()
    game_split_debug(thienlong_seal)
endif()

game_module(scene SRC/scene/placement.cpp SRC/scene/scene_file.cpp SRC/scene/transform.cpp)

# ogre: toán vô hướng đúng thứ tự phép tính của OGRE 1.2.5 (vec3, quaternion); anim: xương và
# animation theo OGRE, ra ma trận skin. Hai module thuần C++, port từ TLBB Dev, không cần math SIMD.
game_module(ogre SRC/ogre/quat.cpp)
game_module(fx
    SRC/fx/script.cpp
    SRC/fx/system.cpp
    SRC/fx/field.cpp
    SRC/fx/billboard.cpp
    SRC/fx/mesh.cpp
    SRC/fx/strip.cpp
    SRC/fx/cast.cpp
    SRC/fx/ttex.cpp)
target_link_libraries(game_fx PUBLIC game_ogre)
game_module(anim SRC/anim/pose.cpp SRC/anim/rig.cpp)
target_link_libraries(game_anim PUBLIC game_ogre)

# table: đọc bảng TSV của client; look: giải ngoại hình người chơi từ các bảng đó (port từ TLBB Dev).
game_module(table SRC/table/tsv.cpp)
target_link_libraries(game_table PUBLIC game_core)
# Máy chủ. content chỉ nhận chữ và trả kết quả; exe thienlong_lint là nơi đọc đĩa.
game_module(content
    SRC/content/coverage.cpp
    SRC/content/lint.cpp
    SRC/content/path_glob.cpp
    SRC/content/ref_rule.cpp
    SRC/content/table_text.cpp
    SRC/content/utf8.cpp)
target_link_libraries(game_content PUBLIC game_table game_core)
# Phần còn lại của máy chủ chỉ dựng cho máy tính: client di động không mang mã máy chủ.
# tomlplusplus chỉ cho thư mục include SYSTEM, không nối target của vcpkg: bản đã dịch của nó bật
# exception (AGENTS.md mục 11). Preset không chạy vcpkg (gcc-debug) lấy header từ thư mục cài chung.
if(NOT CMAKE_CROSSCOMPILING)
    find_path(GAME_TOML_INCLUDE toml++/toml.hpp
        HINTS "${PROJECT_SOURCE_DIR}/vcpkg_installed/x64-windows-static-md/include")
endif()
if(GAME_TOML_INCLUDE)
    add_library(game_toml INTERFACE)
    target_include_directories(game_toml SYSTEM INTERFACE "${GAME_TOML_INCLUDE}")
    # config: chữ TOML thành struct đã kiểm miền. Chỉ detail/parse.cpp thấy thư viện TOML.
    game_module(config
        SRC/config/admin.cpp
        SRC/config/auth.cpp
        SRC/config/billing.cpp
        SRC/config/cluster.cpp
        SRC/config/gate.cpp
        SRC/config/log.cpp
        SRC/config/loose.cpp
        SRC/config/secrets.cpp
        SRC/config/startup.cpp
        SRC/config/store.cpp
        SRC/config/supervisor.cpp
        SRC/config/types.cpp
        SRC/config/world.cpp
        SRC/config/zone.cpp
        SRC/config/detail/node.cpp
        SRC/config/detail/parse.cpp
        SRC/config/detail/read.cpp
        SRC/config/detail/read_list.cpp)
    target_link_libraries(game_config PUBLIC game_core PRIVATE game_toml)
    # process: chạy và dừng tiến trình con; supervise: máy trạng thái của trình giám sát, không
    # đụng hệ điều hành.
    if(WIN32)
        game_module(process
            SRC/process/process.cpp SRC/process/process_win32.cpp SRC/process/self_win32.cpp)
    else()
        game_module(process SRC/process/process.cpp SRC/process/process_posix.cpp)
    endif()
    target_link_libraries(game_process PUBLIC game_core)
    game_module(supervise SRC/supervise/supervise.cpp)
    target_link_libraries(game_supervise PUBLIC game_core)
    # service: khung chung của một tiến trình máy chủ; mỗi exe chỉ là một main.cpp ba dòng.
    game_module(service
        SRC/service/host.cpp
        SRC/service/load.cpp
        SRC/service/request.cpp
        SRC/service/service.cpp)
    target_link_libraries(game_service
        PUBLIC game_core game_config game_supervise PRIVATE game_io game_process)
    add_executable(thienlong_lint SRC/linttool/main.cpp SRC/linttool/config_lint.cpp)
    target_link_libraries(thienlong_lint PRIVATE game_content game_config game_io game::warnings)
    if(WIN32)
        target_link_libraries(thienlong_lint PRIVATE shell32)
    endif()
    game_split_debug(thienlong_lint)
    # Bản chạy của máy chủ cài riêng: cmake --install <build> --component server --prefix SERVER.
    # Lệnh cài mặc định của client không chép các exe này.
    install(TARGETS thienlong_lint RUNTIME DESTINATION bin COMPONENT server EXCLUDE_FROM_ALL)
    function(game_server_exe target folder)
        add_executable(${target} "SRC/${folder}/main.cpp")
        target_link_libraries(${target} PRIVATE game_service game::warnings)
        game_split_debug(${target})
        install(TARGETS ${target} RUNTIME DESTINATION bin COMPONENT server EXCLUDE_FROM_ALL)
    endfunction()
    game_server_exe(thienlong_server supervisor)
    game_server_exe(thienlong_store stored)
    game_server_exe(thienlong_auth authd)
    game_server_exe(thienlong_billing billingd)
    game_server_exe(thienlong_world worldd)
    game_server_exe(thienlong_zone zoned)
    game_server_exe(thienlong_gate gated)
    # Exe phụ của process_tests: đóng vai một tiến trình con ngoan hoặc hư. Không cài.
    add_executable(thienlong_test_child tests/support/server_child.cpp)
    target_link_libraries(thienlong_test_child PRIVATE game_process game::warnings)
elseif(NOT CMAKE_CROSSCOMPILING)
    message(STATUS "không thấy toml++/toml.hpp: bỏ các module, exe và test của máy chủ")
endif()
game_module(look SRC/look/appearance.cpp SRC/look/look.cpp SRC/look/head.cpp)
target_link_libraries(game_look PUBLIC game_table game_core)

# avatar: chọn clip theo trạng thái (gait) và làm mượt hướng mặt (turning), port từ TLBB Dev.
game_module(avatar SRC/avatar/gait.cpp SRC/avatar/turning.cpp)
target_link_libraries(game_avatar PUBLIC game_anim game_core)

# control: mặt đất của cảnh (độ cao, tia chạm đất, va chạm của mắt camera), tia từ màn hình, camera
# bám theo, lệnh đi bằng chuột, chọn thứ dưới chuột, cử chỉ chạm và cần gạt ảo; port từ TLBB Dev.
game_module(control
    SRC/control/cursor_rules.cpp
    SRC/control/follow_camera.cpp
    SRC/control/ground.cpp
    SRC/control/hover.cpp
    SRC/control/player_input.cpp
    SRC/control/stick.cpp
    SRC/control/touch.cpp
    SRC/control/view_ray.cpp)
target_link_libraries(game_control PUBLIC game_ogre game_core)

# motion: luật đi dọc đường (vị trí là hàm đóng của điểm xuất phát, đường, tốc độ, thời gian).
game_module(motion SRC/motion/motion.cpp)
target_link_libraries(game_motion PUBLIC game_core)

# gui: giao diện gốc của client (CEGUI và Falagard): nạp XML scheme, looknfeel, imageset và layout
# lúc chạy, dàn trang rồi ra lệnh vẽ ảnh và chữ; port từ TLBB Dev. Không vẽ thật: bộ vẽ 2D nằm ở
# module ui.
game_module(gui
    SRC/gui/value.cpp
    SRC/gui/strings.cpp
    SRC/gui/loader.cpp
    SRC/gui/loader_look.cpp
    SRC/gui/layout.cpp
    SRC/gui/paint.cpp
    SRC/gui/text.cpp
    SRC/gui/radar.cpp
    SRC/gui/hub.cpp)
target_link_libraries(game_gui PUBLIC game_core game_io game_xml game_table)
# hero: trạng thái của nhân vật người chơi mà giao diện hiển thị (tên, cấp, máu, khí, nộ, kinh
# nghiệm). Giá trị thuần: mạng ghi vào, ui/panel đọc.
game_module(hero SRC/hero/hero.cpp)
target_link_libraries(game_hero PUBLIC game_core)
# ui/panel: logic của từng cửa sổ HUD, thay script Lua của client gốc (hiện, giấu, điền chữ, đặt
# thanh). Thuần logic trên gui, không cần GPU; module ui (bộ vẽ) dùng nó.
game_module(ui_panel
    SRC/ui/panel/deck.cpp
    SRC/ui/panel/start.cpp
    SRC/ui/panel/player_frame.cpp
    SRC/ui/panel/minimap.cpp
    SRC/ui/panel/maps.cpp
    SRC/ui/panel/menubar.cpp
    SRC/ui/panel/portraits.cpp)
target_link_libraries(game_ui_panel PUBLIC game_gui game_hero game_table game_core)
game_module(client_map
    SRC/client/map/terrain.cpp
    SRC/client/map/samples.cpp
    SRC/client/map/picture.cpp
    SRC/client/map/surface.cpp
    SRC/client/map/liquid.cpp
    SRC/client/map/sheet.cpp
    SRC/client/map/ground.cpp
    SRC/client/map/book.cpp
    SRC/client/map/gates.cpp)
target_link_libraries(game_client_map PUBLIC game_core game_io game_xml game_scene)
target_link_libraries(game_scene PUBLIC game_core game_xml)

# window: cửa sổ, màn hình, con trỏ, vòng thông điệp; chép từ Forge2 và mới có bản Win32, nên chỉ
# dựng trên Windows (MSVC, Clang và GCC MinGW đều dựng được: đã đo bằng check.py trên từng tệp).
# Android và iOS chưa có: bản Android của Forge2 chưa được chép. Thư viện hệ thống: shcore cho DPI
# từng màn hình, dwmapi cho thanh tiêu đề tối, shell32 cho kéo thả tệp, advapi32 cho registry.
if(WIN32)
    game_module(window
        SRC/window/cursor.cpp
        SRC/window/monitor.cpp
        SRC/window/system.cpp
        SRC/window/window.cpp)
    target_link_libraries(game_window
        PUBLIC game_core PRIVATE user32 gdi32 shell32 shcore dwmapi advapi32)
endif()

# jobs: hệ thống job (hàng đợi chia việc, đếm việc, chờ có hạn); chép từ Forge2, dựa phần luồng và
# đồng hồ của core. Core có bản POSIX nên dựng được cả trên Android; capture đi kèm vì nén dải
# hình chạy qua jobs.
if(WIN32 OR ANDROID)
    game_module(jobs SRC/jobs/jobs.cpp SRC/jobs/queue.cpp)
    target_link_libraries(game_jobs PUBLIC game_core)

    game_module(capture
        SRC/capture/deflate.cpp
        SRC/capture/frame.cpp
        SRC/capture/png.cpp)
    target_link_libraries(game_capture PUBLIC game_core PRIVATE game_jobs)
endif()

# math: vectơ, ma trận, quaternion, hình học; chép từ Forge2. Mã dùng intrinsic SSE4.1; trên arm64
# math/sse.hpp ánh xạ sang NEON qua sse2neon (vcpkg, header nằm trong include/sse2neon).
set(GAME_HAS_MATH OFF)
if(CMAKE_SYSTEM_PROCESSOR MATCHES "AMD64|x86_64|arm64|aarch64")
    set(GAME_HAS_MATH ON)
endif()
if(GAME_HAS_MATH)
    game_module(math SRC/math/geometry.cpp)
    target_link_libraries(game_math PUBLIC game_core)
    if(NOT CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        # GCC và Clang chỉ nhận intrinsic SSE4.1 khi có cờ này (đã đo: thiếu thì _mm_blend_ps báo
        # "target specific option mismatch"); cl của MSVC không cần. PUBLIC vì header chứa mã.
        target_compile_options(game_math PUBLIC "$<$<CXX_COMPILER_ID:GNU,Clang>:-msse4.1>")
    else()
        target_include_directories(game_math SYSTEM PUBLIC
            "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include/sse2neon")
    endif()
    game_module(camera
        SRC/camera/basis.cpp
        SRC/camera/lens.cpp
        SRC/camera/motion.cpp
        SRC/camera/rig.cpp)
    target_link_libraries(game_camera PUBLIC game_math)
endif()

# Chuỗi đồ hoạ chép từ Forge2: fs (mã hoá, luồng byte), shader (gói và phản chiếu), gpu (thiết bị,
# backend Vulkan). Chỉ dựng trên Windows với MSVC hoặc Clang đích MSVC:
# - GCC MinGW: gói vcpkg của dự án chỉ cài cho triplet x64-windows-static-md (thư viện của MSVC), và
#   backend Vulkan của Forge2 nạp trễ vulkan-1.dll bằng cờ /DELAYLOAD của trình liên kết MSVC. Đã
#   đo: check.py dịch được từng tệp của ba module bằng GCC, nên trở ngại nằm ở khâu gói và liên
#   kết, không ở mã.
# - Android, iOS: gpu/retire.hpp từng phụ thuộc std::move_only_function mà libc++ của NDK 30
#   không có — nay có bản thay MoveOnlyCall; Android đã có bề mặt ANativeWindow
#   (gpu/vulkan/surface_android.cpp), iOS chờ Metal (chưa build, không có macOS).
set(GAME_HAS_GPU OFF)
if((WIN32 AND NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU") OR ANDROID OR IOS)
    set(GAME_HAS_GPU ON)
endif()
if(GAME_HAS_GPU)
    # lz4 và zstd cho fs/codec.cpp, xxhash cho tổng kiểm của gói shader; qua vcpkg manifest.
    find_package(lz4 CONFIG REQUIRED)
    find_package(xxHash CONFIG REQUIRED)
    find_package(zstd CONFIG REQUIRED)
    if(ANDROID OR IOS)
        # fs của thiết bị chỉ cần mã hoá (giải gói shader) và luồng byte; disk/file/watcher của
        # Forge2 là Win32 (shader/package.cpp đọc tệp qua io đã có bản POSIX).
        game_module(fs
            SRC/fs/buny.cpp
            SRC/fs/codec.cpp
            SRC/fs/path.cpp
            SRC/fs/stream.cpp)
    else()
        game_module(fs
            SRC/fs/buny.cpp
            SRC/fs/codec.cpp
            SRC/fs/disk.cpp
            SRC/fs/file.cpp
            SRC/fs/path.cpp
            SRC/fs/stream.cpp
            SRC/fs/watcher.cpp)
    endif()
    target_link_libraries(game_fs PUBLIC game_core PRIVATE lz4::lz4 xxHash::xxhash zstd::libzstd)
    if(ANDROID OR IOS)
        # Chạy trên thiết bị chỉ đọc gói .f2s; builder/compiler/dxil/dxbc là công cụ Windows.
        game_module(shader
            SRC/shader/package.cpp
            SRC/shader/reflection.cpp
            SRC/shader/spirv.cpp
            SRC/shader/types.cpp)
        target_link_libraries(game_shader PUBLIC game_core game_fs PRIVATE game_io game_jobs)
    else()
        # builder dịch HLSL; compiler và dxil include <windows.h> trực tiếp (bản chép) rồi gọi
        # std::max. NOMINMAX phải có trước header ấy. check.py không thấy cờ của target này.
        game_module(shader
            SRC/shader/builder.cpp
            SRC/shader/compiler.cpp
            SRC/shader/dxbc.cpp
            SRC/shader/dxil.cpp
            SRC/shader/manifest.cpp
            SRC/shader/package.cpp
            SRC/shader/reflection.cpp
            SRC/shader/spirv.cpp
            SRC/shader/types.cpp)
        target_link_libraries(
            game_shader PUBLIC game_core game_fs PRIVATE game_io game_jobs d3dcompiler)
        target_compile_definitions(game_shader PRIVATE NOMINMAX)
        # compiler.cpp gọi __uuidof và IID_PPV_ARGS. Đó là extension của COM, không có dạng chuẩn.
        # Clang -Wlanguage-extension-token biến nó thành lỗi. Chỉ tắt đúng cảnh báo ấy, với Clang.
        set_source_files_properties(SRC/shader/compiler.cpp PROPERTIES COMPILE_OPTIONS
            "$<$<CXX_COMPILER_ID:Clang>:-Wno-language-extension-token>")
    endif()

    # gpu: phần chung và backend Vulkan mọi nền; D3D12/D3D11 chỉ Windows. Vulkan trên Windows lấy
    # từ Vulkan SDK (VULKAN_SDK), trên Android từ NDK (header trong sysroot, libvulkan.so hệ thống).
    find_package(Vulkan REQUIRED)
    if(ANDROID)
        game_module(gpu
            SRC/gpu/check.cpp
            SRC/gpu/device.cpp
            SRC/gpu/format.cpp
            SRC/gpu/layout.cpp
            SRC/gpu/vulkan/api.cpp
            SRC/gpu/vulkan/commands.cpp
            SRC/gpu/vulkan/convert.cpp
            SRC/gpu/vulkan/device.cpp
            SRC/gpu/vulkan/instance.cpp
            SRC/gpu/vulkan/programs.cpp
            SRC/gpu/vulkan/resources.cpp
            SRC/gpu/vulkan/surface_android.cpp
            SRC/gpu/vulkan/swapchain.cpp
            SRC/gpu/gles/bind_map.cpp
            SRC/gpu/gles/context_egl.cpp
            SRC/gpu/gles/device.cpp
            SRC/gpu/gles/load.cpp
            SRC/gpu/gles/pick.cpp
            SRC/gpu/gles/probe.cpp
            SRC/gpu/gles/programs.cpp
            SRC/gpu/gles/resources.cpp
            SRC/gpu/gles/commands.cpp
            SRC/gpu/gles/swapchain.cpp)
        target_compile_definitions(game_gpu PRIVATE GAME_GPU_GLES)
        target_link_libraries(game_gpu PUBLIC game_core game_shader PRIVATE Vulkan::Vulkan EGL GLESv3)
    elseif(IOS)
        # iOS chạy Vulkan trên MoltenVK nhúng: bề mặt là CAMetalLayer (surface_ios.mm). MoltenVK
        # và framework của Apple tĩnh trong ứng dụng; đủ mã, chờ macOS để build.
        game_module(gpu
            SRC/gpu/check.cpp
            SRC/gpu/device.cpp
            SRC/gpu/format.cpp
            SRC/gpu/layout.cpp
            SRC/gpu/vulkan/api.cpp
            SRC/gpu/vulkan/commands.cpp
            SRC/gpu/vulkan/convert.cpp
            SRC/gpu/vulkan/device.cpp
            SRC/gpu/vulkan/instance.cpp
            SRC/gpu/vulkan/programs.cpp
            SRC/gpu/vulkan/resources.cpp
            SRC/gpu/vulkan/surface_ios.mm
            SRC/gpu/vulkan/swapchain.cpp)
        target_link_libraries(game_gpu PUBLIC game_core game_shader
            PRIVATE Vulkan::Vulkan "-framework Metal" "-framework QuartzCore" "-framework UIKit")
    else()
        # Macro GAME_GPU_D3D12 và GAME_GPU_D3D11 bật nhánh trong gpu/device.cpp; thiếu macro thì
        # nhánh ấy trả kUnsupported. dxcapi.h nằm trong include của Vulkan SDK, không trong Windows
        # SDK. Không link vulkan-1.
        target_include_directories(game_shader PRIVATE
            "$<TARGET_PROPERTY:Vulkan::Vulkan,INTERFACE_INCLUDE_DIRECTORIES>")
        game_module(gpu
            SRC/gpu/check.cpp
            SRC/gpu/device.cpp
            SRC/gpu/format.cpp
            SRC/gpu/layout.cpp
            SRC/gpu/vulkan/api.cpp
            SRC/gpu/vulkan/commands.cpp
            SRC/gpu/vulkan/convert.cpp
            SRC/gpu/vulkan/device.cpp
            SRC/gpu/vulkan/instance.cpp
            SRC/gpu/vulkan/programs.cpp
            SRC/gpu/vulkan/resources.cpp
            SRC/gpu/vulkan/surface_win32.cpp
            SRC/gpu/vulkan/swapchain.cpp
            SRC/gpu/d3d12/commands.cpp
            SRC/gpu/d3d12/convert.cpp
            SRC/gpu/d3d12/device.cpp
            SRC/gpu/d3d12/programs.cpp
            SRC/gpu/d3d12/resources.cpp
            SRC/gpu/d3d12/swapchain.cpp
            SRC/gpu/d3d11/commands.cpp
            SRC/gpu/d3d11/convert.cpp
            SRC/gpu/d3d11/device.cpp
            SRC/gpu/d3d11/hresult.cpp
            SRC/gpu/d3d11/programs.cpp
            SRC/gpu/d3d11/resources.cpp
            SRC/gpu/d3d11/swapchain.cpp
            SRC/gpu/gles/bind_map.cpp
            SRC/gpu/gles/context_wgl.cpp
            SRC/gpu/gles/device.cpp
            SRC/gpu/gles/load.cpp
            SRC/gpu/gles/pick.cpp
            SRC/gpu/gles/probe.cpp
            SRC/gpu/gles/programs.cpp
            SRC/gpu/gles/resources.cpp
            SRC/gpu/gles/commands.cpp
            SRC/gpu/gles/swapchain.cpp)
        target_compile_definitions(game_gpu PRIVATE GAME_GPU_D3D12 GAME_GPU_D3D11 GAME_GPU_GLES)
        target_link_libraries(game_gpu PUBLIC game_core game_shader
            PRIVATE Vulkan::Vulkan user32 gdi32 opengl32 d3d12 d3d11 dxgi dxguid)
        # vulkan-1.dll nạp trễ: exe chạy được trên máy không có trình điều khiển Vulkan, backend khi
        # ấy báo kUnsupported (gpu/vulkan/api.hpp, has_loader). Cờ thuộc bước liên kết exe nên đi
        # theo INTERFACE; LINKER: để trình điều khiển clang++ chuyển nguyên cờ xuống trình liên kết.
        target_link_libraries(game_gpu INTERFACE delayimp)
        target_link_options(game_gpu INTERFACE "LINKER:/DELAYLOAD:vulkan-1.dll")
    endif()

    # render: màn hình vẽ lên cửa sổ (swapchain kèm ảnh độ sâu, vòng acquire, vẽ, present).
    # camera và forward cần math và resource; thêm ở khối resource bên dưới khi cả hai có.
    game_module(render SRC/render/screen.cpp)
    target_link_libraries(game_render PUBLIC game_core game_gpu)

    # resource: nạp GLB (cgltf, stb) và tải lên GPU (meshoptimizer giải EXT_meshopt_compression).
    # Cần math. Trên Windows x64 cả GAME_HAS_GPU và GAME_HAS_MATH cùng bật; arm64 chưa có math.
    if(GAME_HAS_MATH)
        find_path(CGLTF_INCLUDE_DIR NAMES cgltf.h REQUIRED)
        find_package(Stb REQUIRED)
        find_package(meshoptimizer CONFIG REQUIRED)
        game_module(resource
            SRC/resource/classic.cpp
            SRC/resource/image.cpp
            SRC/resource/model.cpp
            SRC/resource/rig.cpp
            SRC/resource/upload.cpp)
        target_include_directories(game_resource PRIVATE ${CGLTF_INCLUDE_DIR} ${Stb_INCLUDE_DIR})
        target_link_libraries(game_resource
            PUBLIC game_core game_math game_fs game_gpu game_anim game_ogre
            PRIVATE meshoptimizer::meshoptimizer)
        # Forward đọc gói .f2s và vẽ model đã tải lên. Header của nó kéo math và resource.
        target_sources(game_render PRIVATE SRC/render/camera.cpp SRC/render/forward.cpp
            SRC/render/shade.cpp SRC/render/ui.cpp SRC/render/canvas.cpp)
        target_link_libraries(game_render PUBLIC game_math game_resource PRIVATE game_shader)
        # Nạp người chơi từ GLB và ra ma trận skin mỗi khung (cần resource, look, io).
        target_sources(game_avatar PRIVATE SRC/avatar/avatar.cpp)
        target_link_libraries(game_avatar PUBLIC game_look game_math game_io game_resource)
        # ui: HUD của game: bộ vẽ quad của giao diện gốc lên lượt vẽ 2D (render/ui), gom bộ nạp, dàn trang
        # và bảng chuỗi (cần gui, render, resource).
        game_module(ui SRC/ui/painter.cpp SRC/ui/hud.cpp SRC/ui/pace.cpp SRC/ui/text.cpp
            SRC/ui/radar.cpp)
        target_link_libraries(game_ui PUBLIC game_gui game_ui_panel game_render game_resource
            game_gpu game_io game_table game_core)
    endif()
endif()

# Công cụ dịch shader, chạy trên máy dựng (Windows). Gói .f2s cho thiết bị đóng sẵn vào APK;
# Android không dựng công cụ này vì builder/compiler là Win32.
if(GAME_HAS_GPU AND WIN32)
    add_executable(thienlong_shader SRC/shadertool/main.cpp)
    target_link_libraries(thienlong_shader PRIVATE game_shader game_jobs game_io game::warnings)
    game_split_debug(thienlong_shader)
    set(game_shader_dir "${CMAKE_BINARY_DIR}/shaders")
    set(game_shader_src "${PROJECT_SOURCE_DIR}/SRC/render/shaders")
    set(game_shader_packages
        "${game_shader_dir}/model.vs.f2s"
        "${game_shader_dir}/model.ps.f2s"
        "${game_shader_dir}/ui.vs.f2s"
        "${game_shader_dir}/ui.ps.f2s")
    # Mỗi gói ở trên phải có dòng "shader <tên> ..." trong shaders.list. Thiếu dòng thì công cụ không
    # sinh gói, lượt vẽ nạp gói đó lặng lẽ tắt lúc chạy (HUD mất) và lệnh dịch chạy lại mỗi lần build.
    file(STRINGS "${game_shader_src}/shaders.list" game_shader_lines REGEX "^shader ")
    foreach(game_shader_package IN LISTS game_shader_packages)
        get_filename_component(game_shader_name "${game_shader_package}" NAME)
        string(REGEX REPLACE "\\.f2s$" "" game_shader_name "${game_shader_name}")
        if(NOT game_shader_lines MATCHES "shader ${game_shader_name} ")
            message(FATAL_ERROR "SRC/render/shaders/shaders.list thiếu dòng của ${game_shader_name}")
        endif()
    endforeach()
    add_custom_command(
        OUTPUT ${game_shader_packages}
        COMMAND thienlong_shader build "${game_shader_src}/shaders.list"
            --out "${game_shader_dir}" --target spirv,dxil,dxbc,glsl
        DEPENDS thienlong_shader
            "${game_shader_src}/shaders.list"
            "${game_shader_src}/model.hlsli"
            "${game_shader_src}/model.vs.hlsl"
            "${game_shader_src}/model.ps.hlsl"
            "${game_shader_src}/model.vs.glsl"
            "${game_shader_src}/model.ps.glsl"
            "${game_shader_src}/ui.hlsli"
            "${game_shader_src}/ui.vs.hlsl"
            "${game_shader_src}/ui.ps.hlsl"
            "${game_shader_src}/ui.vs.glsl"
            "${game_shader_src}/ui.ps.glsl"
        COMMENT "Dịch shader của render thành gói .f2s"
        VERBATIM)
    add_custom_target(game_render_shaders DEPENDS ${game_shader_packages})
    add_dependencies(game_render game_render_shaders)
    install(FILES ${game_shader_packages} DESTINATION bin/shaders)
endif()

# client: phần của exe kiểm được bằng test (tuỳ chọn dòng lệnh) và vòng lặp cửa sổ. Vòng lặp cửa sổ
# cần module window, mới có trên Windows; nền tảng khác dựng bản không cửa sổ. Phần hiển thị của
# cửa sổ (client/display.hpp) có bản dùng chuỗi đồ hoạ và bản không vẽ cho cấu hình thiếu nó.
# client tách submodule cho ranh giới rõ: stage (nội dung cảnh cần vẽ), map (địa hình .Terrain),
# display (phần đồ hoạ, bản có chuỗi đồ hoạ hoặc bản không vẽ), viewer (vòng lặp cửa sổ). Gốc
# client giữ tuỳ chọn dòng lệnh và các điểm vào (main, android_main, ios_main).
if(GAME_HAS_GPU)
    set(game_client_screen SRC/client/display/display_gpu.cpp SRC/client/display/player.cpp
        SRC/client/display/portrait.cpp SRC/client/display/fx_view.cpp
        SRC/client/display/lighting.cpp)
else()
    set(game_client_screen SRC/client/display/display_none.cpp)
endif()
if(WIN32)
    set(game_client_loop SRC/client/viewer/viewer_win32.cpp SRC/client/viewer/cursors.cpp)
else()
    set(game_client_loop SRC/client/viewer/viewer_none.cpp)
endif()
game_module(client_stage
    SRC/client/stage/stage.cpp
    SRC/client/stage/sky.cpp
    SRC/client/stage/props.cpp)
target_link_libraries(game_client_stage PUBLIC game_core game_xml game_scene)
game_module(client_world SRC/client/world/world.cpp)
target_link_libraries(game_client_world PUBLIC game_client_stage game_client_map game_io)
game_module(client_display ${game_client_screen})
target_link_libraries(game_client_display PUBLIC game_core game_client_stage game_client_map
    game_client_world game_control)
if(GAME_HAS_GPU)
    target_link_libraries(game_client_display PRIVATE game_gpu game_render game_capture
        game_avatar game_look game_motion game_ui game_fx game_camera)
endif()
game_module(client_viewer ${game_client_loop})
target_link_libraries(game_client_viewer PUBLIC game_core game_client_stage
    PRIVATE game_client_display)
if(WIN32)
    target_link_libraries(game_client_viewer PRIVATE game_window)
    target_link_libraries(game_client_viewer PUBLIC game_audio)
endif()
game_module(client SRC/client/options.cpp SRC/client/assets.cpp)
target_link_libraries(game_client PUBLIC game_core game_io game_client_map game_client_world)

# iOS: điểm vào UIKit. Chưa build trên máy này (không có macOS). Android giữ main.cpp cho exe adb;
# APK là thư viện riêng bên dưới.
if(IOS)
    add_executable(thienlong_client SRC/client/ios_main.mm SRC/client/mobile_probe.cpp)
else()
    add_executable(thienlong_client SRC/client/main.cpp)
endif()
if(WIN32)
    # Icon của exe, dịch trong một target riêng không có thư mục include nào. windres của MinGW đưa
    # -I cho bộ tiền xử lý mà không bọc nháy, nên thư mục có dấu cách (chính đường dẫn dự án) làm
    # nó dừng. app.rc không include gì; đường dẫn icon trong đó tính từ chỗ tệp .rc.
    add_library(thienlong_client_icon OBJECT SRC/client/app.rc)
    target_sources(thienlong_client PRIVATE $<TARGET_OBJECTS:thienlong_client_icon>)
endif()
target_link_libraries(thienlong_client PRIVATE game_client game_client_viewer game_client_stage
    game_io game_scene game::warnings)
if(IOS)
    target_link_libraries(thienlong_client PRIVATE "-framework UIKit" "-framework Foundation"
        game_audio)
endif()
game_split_debug(thienlong_client)
# Bản chạy: cmake --install build/<preset> chép exe vào CLIENT/bin (CMAKE_INSTALL_PREFIX ở preset).
install(TARGETS thienlong_client RUNTIME DESTINATION bin BUNDLE DESTINATION bin)
# iOS chỉ chạy được exe nằm trong gói ứng dụng. Chưa build trên macOS (máy phát triển là Windows).
if(IOS)
    set_target_properties(thienlong_client PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER vn.thienlong.client
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION})
    # Cùng dữ liệu và gói .f2s với preset PC clang-asan. resourcePath/data là chỗ ios_main đọc.
    set(GAME_IOS_SHADERS "${PROJECT_SOURCE_DIR}/build/clang-asan/shaders" CACHE PATH
        "Gói .f2s đóng vào bundle iOS. Mặc định là build/clang-asan/shaders của bản PC.")
    if(NOT EXISTS "${GAME_IOS_SHADERS}/model.vs.f2s" OR NOT EXISTS "${GAME_IOS_SHADERS}/model.ps.f2s")
        message(FATAL_ERROR
            "Thiếu gói shader PC tại ${GAME_IOS_SHADERS}. Dựng preset clang-asan trước.")
    endif()
    add_custom_command(TARGET thienlong_client POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E env PYTHONUTF8=1
            python "${PROJECT_SOURCE_DIR}/TOOLS/android/package_apk.py"
            --stage "$<TARGET_BUNDLE_CONTENT_DIR:thienlong_client>/data"
            --data "${PROJECT_SOURCE_DIR}/CLIENT/data"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${GAME_IOS_SHADERS}"
            "$<TARGET_BUNDLE_CONTENT_DIR:thienlong_client>/data/shaders"
        COMMENT "Chép cảnh startup.id và shader PC vào bundle iOS")
endif()

# APK NativeActivity: cùng Display với bản PC (Vulkan 1.3, rồi GLES). Glue của NDK là C,
# không qua cổng cảnh báo của dự án. Exe thienlong_client vẫn để ctest đẩy qua adb.
# Gói shader lấy từ preset PC (cache GAME_ANDROID_SHADERS, mặc định clang-asan).
# --data trỏ cả CLIENT/data; package_apk.py chỉ đóng cảnh của Config/startup.id.
if(ANDROID)
    enable_language(C)
    set(game_glue "${ANDROID_NDK}/sources/android/native_app_glue")
    add_library(android_native_app_glue STATIC "${game_glue}/android_native_app_glue.c")
    target_include_directories(android_native_app_glue PUBLIC "${game_glue}")
    set_property(TARGET android_native_app_glue PROPERTY COMPILE_WARNING_AS_ERROR OFF)
    add_library(thienlong_activity SHARED
        SRC/client/android_main.cpp
        SRC/client/mobile_probe.cpp)
    target_include_directories(thienlong_activity PRIVATE "${game_glue}")
    target_compile_features(thienlong_activity PRIVATE cxx_std_23)
    target_link_libraries(thienlong_activity PRIVATE
        game_client game_client_display game_client_stage game_client_world game_client_map game_io
        game_audio android_native_app_glue android log game::warnings)
    set_target_properties(thienlong_activity PROPERTIES OUTPUT_NAME thienlong)
    target_link_options(thienlong_activity PRIVATE "-u" "ANativeActivity_onCreate")
    set(game_apk "${CMAKE_BINARY_DIR}/thienlong.apk")
    # Mặc định là shader của preset PC đang dùng (clang-asan). Đặt GAME_ANDROID_SHADERS khi
    # muốn đóng gói của preset khác. Thiếu model.vs.f2s thì package_apk.py từ chối đóng.
    set(GAME_ANDROID_SHADERS "${PROJECT_SOURCE_DIR}/build/clang-asan/shaders" CACHE PATH
        "Thư mục gói .f2s đóng vào APK. Mặc định là build/clang-asan/shaders của bản PC.")
    if(NOT EXISTS "${GAME_ANDROID_SHADERS}/model.vs.f2s")
        set(GAME_ANDROID_SHADERS "${PROJECT_SOURCE_DIR}/build/clang-asan/shaders" CACHE PATH
            "Thư mục gói .f2s đóng vào APK. Mặc định là build/clang-asan/shaders của bản PC."
            FORCE)
    endif()
    set(game_apk_assets
        --data "${PROJECT_SOURCE_DIR}/CLIENT/data"
        --shaders "${GAME_ANDROID_SHADERS}")
    # Có cây sound đã cook thì APK mang bản .tla (48 kHz, Opus) thay cho WAV và MP3 gốc: nhẹ hơn
    # một nửa và thiết bị không phải đổi tần số. Chưa cook thì đóng tệp gốc như cũ.
    set(GAME_ANDROID_SOUND "${PROJECT_SOURCE_DIR}/build/cooked/sound" CACHE PATH
        "Cây sound đã cook bằng thienlong_audio (target cook_sound của preset PC).")
    if(EXISTS "${GAME_ANDROID_SOUND}/sound_table.xml")
        list(APPEND game_apk_assets --sound "${GAME_ANDROID_SOUND}")
    endif()
    add_custom_command(
        OUTPUT "${game_apk}"
        COMMAND ${CMAKE_COMMAND} -E env PYTHONUTF8=1
            python "${PROJECT_SOURCE_DIR}/TOOLS/android/package_apk.py"
            --library "$<TARGET_FILE:thienlong_activity>"
            --abi "${ANDROID_ABI}"
            --manifest "${PROJECT_SOURCE_DIR}/TOOLS/android/AndroidManifest.xml"
            --out "${game_apk}"
            --depfile "${game_apk}.d"
            ${game_apk_assets}
        DEPENDS thienlong_activity
            "${PROJECT_SOURCE_DIR}/TOOLS/android/package_apk.py"
            "${PROJECT_SOURCE_DIR}/TOOLS/android/AndroidManifest.xml"
            "${GAME_ANDROID_SHADERS}/model.vs.f2s"
            "${GAME_ANDROID_SHADERS}/model.ps.f2s"
        # Dữ liệu đóng vào APK (danh sách cảnh, từng tệp, thư mục đã quét) do package_apk.py tự kê:
        # tệp nào đổi thì APK đóng lại.
        DEPFILE "${game_apk}.d"
        COMMENT "Đóng thienlong.apk"
        VERBATIM)
    add_custom_target(thienlong_apk ALL DEPENDS "${game_apk}")
endif()

# Mỗi header thành một .cpp include nó hai lần (tự đủ + #pragma once, KTR-03).
file(GLOB_RECURSE game_headers CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/SRC/*.hpp)
# Header của module không dựng trong cấu hình này không vào header_check: chúng cần gói vcpkg và
# Vulkan SDK mà cấu hình ấy không có (xem GAME_HAS_GPU ở trên).
if(NOT GAME_HAS_GPU)
    list(FILTER game_headers EXCLUDE REGEX "/SRC/(fs|shader|gpu|render|resource)/")
endif()
# Backend D3D chỉ có trên Windows: header của nó đòi d3d11.h/d3d12.h của Windows SDK.
if(NOT WIN32)
    list(FILTER game_headers EXCLUDE REGEX "/SRC/gpu/d3d1[12]/")
endif()
if(NOT GAME_HAS_MATH)
    list(FILTER game_headers EXCLUDE REGEX "/SRC/(math|camera)/")
endif()
# capture chỉ có target trên Windows (xem khối jobs); ngoài Windows header của nó không vào
# header_check. render/target.hpp chưa có target (target kéo capture). library.hpp là nạp lại lúc
# chạy, công cụ shader không dựng nó. shadertool không có header.
if(NOT WIN32)
    list(FILTER game_headers EXCLUDE REGEX "/SRC/capture/")
endif()
# Mã máy chủ không dựng cho client di động, hoặc khi thiếu header của tomlplusplus.
if(NOT TARGET game_service)
    list(FILTER game_headers EXCLUDE REGEX "/SRC/(config|process|supervise|service|linttool)/")
endif()
list(FILTER game_headers EXCLUDE REGEX "/SRC/render/target\\.hpp$")
list(FILTER game_headers EXCLUDE REGEX "/SRC/shader/library\\.hpp$")
foreach(header IN LISTS game_headers)
  file(RELATIVE_PATH relative "${PROJECT_SOURCE_DIR}" "${header}")
  string(MAKE_C_IDENTIFIER "${relative}" stem)
  set(unit "${PROJECT_BINARY_DIR}/header_check/${stem}.cpp")
  file(CONFIGURE OUTPUT "${unit}" CONTENT "#include \"${header}\"\n#include \"${header}\"\n")
  list(APPEND header_units "${unit}")
endforeach()
add_library(header_check OBJECT ${header_units})
target_link_libraries(header_check PRIVATE game_all_modules game::warnings)
# Header của backend Vulkan include <vulkan/vulkan.h>; game_gpu chỉ nối Vulkan ở phần PRIVATE.
if(GAME_HAS_GPU)
    target_link_libraries(header_check PRIVATE Vulkan::Vulkan)
endif()

# Preset iOS tắt test: exe test không chạy được ngoài gói ứng dụng.
option(BUILD_TESTING "Dựng và đăng ký test" ON)
if(NOT BUILD_TESTING)
    return()
endif()
enable_testing()
# Mỗi tệp tests/<tên>_tests.cpp là một exe test; đối số sau tên là các module nó cần.
function(game_test name)
    add_executable(${name}_tests tests/${name}_tests.cpp)
    target_include_directories(${name}_tests PRIVATE tests)
    target_link_libraries(${name}_tests PRIVATE ${ARGN} game::warnings)
    add_test(NAME ${name}_tests COMMAND ${name}_tests)
endfunction()
game_test(fx game_fx)
game_test(io game_io)
game_test(xml game_xml)
game_test(audio game_audio)
game_test(audio_dsp game_audio)
if(TARGET game_seal)
    game_test(seal game_seal)
endif()
# Đường dẫn dữ liệu là của máy dựng: test chạy trên thiết bị Android không thấy nó, và bản checkout
# mới chưa có CLIENT/data (thư mục không vào git). Ở cả hai nơi các ca đọc tệp thật tự bỏ qua
# (audio, map) hoặc test không được đăng ký (giao diện, phông).
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/CLIENT/data/sound/sound_table.xml")
    target_compile_definitions(audio_tests PRIVATE
        "GAME_CLIENT_DATA=\"${PROJECT_SOURCE_DIR}/CLIENT/data\"")
endif()
game_test(scene game_scene)
game_test(map game_client_map)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/CLIENT/data/Config/ScenePosDefineEx.txt")
    target_compile_definitions(map_tests PRIVATE
        "GAME_CLIENT_DATA=\"${PROJECT_SOURCE_DIR}/CLIENT/data\"")
endif()
game_test(world game_client_world)
game_test(transform game_scene)
game_test(client game_client)
game_test(props game_client_stage)
game_test(stage game_client_stage)
# core có bản POSIX nên test chạy trên Windows và trên thiết bị Android. Cửa sổ vẫn chỉ Windows.
if(WIN32 OR ANDROID)
    game_test(core game_core)
    game_test(log game_core)
    game_test(function_fallback game_core)
endif()
if(WIN32)
    game_test(window game_window)
endif()
# Test trên GPU thật qua backend Vulkan, lớp kiểm tra bật. Trên Android, gpu/resource_tests còn
# cần fs::write_file (fs/file của Forge2 là Win32) để ghi tệp tạm — chờ bản fs POSIX.
if(GAME_HAS_GPU AND NOT ANDROID)
    game_test(gpu game_gpu)
    if(TARGET game_resource)
        game_test(resource game_resource)
        game_test(classic game_resource)
        game_test(shade game_render)
        game_test(rig game_resource)
        target_compile_definitions(rig_tests PRIVATE
            GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/CLIENT/data")
        # Kiểm trên dữ liệu thật của người chơi: chỉ đăng ký khi đã gom bằng TOOLS/content.
        if(EXISTS "${PROJECT_SOURCE_DIR}/CLIENT/data/Table/player_bodies.tsv")
            game_test(avatar_data game_avatar game_look game_io)
            target_compile_definitions(avatar_data_tests PRIVATE
                GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/CLIENT/data")
        endif()
    endif()
endif()
game_test(ogre game_ogre)
game_test(anim game_anim)
game_test(motion game_motion)
game_test(look game_look)
game_test(head game_look)
game_test(avatar game_avatar)
game_test(control game_control)
game_test(touch game_control)
game_test(hero game_hero)
game_test(gui_value game_gui)
game_test(gui_loader game_gui)
game_test(gui_sheet game_gui)
# Kiểm trên dữ liệu giao diện thật: chỉ đăng ký khi đã gom bằng TOOLS/content/collect_ui.py.
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/CLIENT/data/Interface/Schema/WoWLookSkin.scheme.xml")
    game_test(gui_real game_gui)
    game_test(ui_panel game_ui_panel game_io)
    target_compile_definitions(ui_panel_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/CLIENT/data")
    target_compile_definitions(gui_real_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/CLIENT/data"
        GAME_UI_GOLDEN="${PROJECT_SOURCE_DIR}/tests/golden")
endif()
# Camera dựng ma trận bằng math và render/camera.cpp; chỉ cần module render, không cần GPU thật.
if(TARGET game_render)
    game_test(camera game_render)
endif()
if(TARGET game_camera)
    game_test(loong_camera game_camera)
endif()
if(TARGET game_ui AND NOT ANDROID
        AND EXISTS "${PROJECT_SOURCE_DIR}/CLIENT/data/Interface/Schema/VTNAM14.bin")
    game_test(ui_text game_ui)
    target_compile_definitions(ui_text_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/CLIENT/data")
    game_test(pace game_ui)
    target_compile_definitions(pace_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/CLIENT/data")
endif()
# Include ngược tầng: bảng ở cmake/GameLayers.cmake (KTR-15).
add_test(NAME layers COMMAND ${CMAKE_COMMAND} -DGAME_SOURCE_DIR=${PROJECT_SOURCE_DIR}
         -P ${PROJECT_SOURCE_DIR}/cmake/GameLayers.cmake)
game_test(content game_content)
if(TARGET game_service)
    game_test(config game_config game_io)
    target_compile_definitions(config_tests PRIVATE
        "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/SERVER/config\"")
    game_test(process game_process game_io)
    add_dependencies(process_tests thienlong_test_child)
    game_test(supervise game_supervise)
    # Hai test dưới chạy exe thật nằm cạnh chúng và đọc cấu hình thật, không PostgreSQL.
    set(game_server_programs thienlong_server thienlong_store thienlong_auth thienlong_billing
        thienlong_world thienlong_zone thienlong_gate)
    game_test(service game_service game_io)
    target_compile_definitions(service_tests PRIVATE
        "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/SERVER/config\"")
    add_dependencies(service_tests ${game_server_programs})
    add_executable(server_boot tests/server_boot_tests.cpp)
    target_include_directories(server_boot PRIVATE tests)
    target_link_libraries(server_boot PRIVATE game_process game_io game::warnings)
    target_compile_definitions(server_boot PRIVATE
        "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/SERVER/config\"")
    add_dependencies(server_boot ${game_server_programs})
    add_test(NAME server_boot COMMAND server_boot)
endif()
# Lint cả cây dữ liệu thật. tables/shared là bảng xuất từ client: git bỏ qua, build_data.py sinh ra.
# Bản checkout chưa sinh dữ liệu thì dòng refs không có bảng để đối chiếu, nên test chưa đăng ký.
if(TARGET thienlong_lint AND EXISTS "${PROJECT_SOURCE_DIR}/SERVER/tables/shared")
    add_test(NAME server_data_lint COMMAND thienlong_lint
        --root "${PROJECT_SOURCE_DIR}/SERVER"
        --refs "${PROJECT_SOURCE_DIR}/TOOLS/server/refs")
elseif(TARGET thienlong_lint)
    message(STATUS "chưa có SERVER/tables/shared: bỏ test server_data_lint, sinh bằng build_data.py")
endif()
