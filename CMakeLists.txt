# THIENLONG — client tự viết nạp tài nguyên Thiên Long Bát Bộ. Khung theo bộ quy cách C++23
# (refs/14 BD-01..BD-17): cờ theo target, cảnh báo từ config/warnings-*.txt, preset cho từng trình
# dịch và nền tảng, sanitizer, cứng hoá, tách symbol. Mã nguồn ở engine/ và src/, test ở Test/<domain>/, công
# cụ Python ở TOOLS/, nguyên liệu ở assets/. Bản thử ở dev/, bản chính thức ở release/.
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

# iOS: project() chỉ khai CXX, mà ios_main.mm và surface_ios.mm là Objective-C++, và bản iOS của
# miniaudio chứa cú pháp Objective-C (@interface, @autoreleasepool) nên native.cpp phải dịch thành
# Objective-C++ (xem game_audio_native). ARC bật cả cây: hai tệp .mm không retain/release tay.
# Chưa dựng được trên máy này (không có macOS): mọi nhánh IOS dưới đây chưa qua trình dịch.
if(IOS)
    enable_language(OBJCXX)
    set(CMAKE_OBJCXX_STANDARD 23)
    set(CMAKE_OBJCXX_STANDARD_REQUIRED ON)
    set(CMAKE_OBJCXX_EXTENSIONS OFF)
    set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES)
endif()

include(cmake/GameWarnings.cmake)
include(cmake/GameOptions.cmake)
include(cmake/GameSanitize.cmake)
include(cmake/GameHarden.cmake)
include(cmake/GameDebugInfo.cmake)
include(cmake/GameSplitDebug.cmake)
include(cmake/GameDeviceShaders.cmake)

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

# Module: engine/<m>/ hoặc src/<client|server|shared>/<m>/, x.hpp cạnh x.cpp. Client xếp module
# vào app, figure, place, face, book, pack. Include vẫn "<m>/x.hpp". Gốc include là engine/,
# các nhóm của src/client/, src/server/ và src/shared/. Module mới: một dòng game_module ở dưới
# và một dòng trong bảng tầng cmake/GameLayers.cmake.
# Cây include là ranh giới thật. Engine chỉ thấy engine/. Shared thấy thêm src/shared.
# Client thấy engine, shared và src/client. Server thấy engine, shared và src/server.
# Một tệp engine không thể include header game: đường đó không có trên dòng biên dịch.
function(game_module name)
    add_library(game_${name} STATIC ${ARGN})
    set(game_homes "${PROJECT_SOURCE_DIR}/engine")
    set(game_sees_client FALSE)
    set(game_sees_server FALSE)
    set(game_sees_shared FALSE)
    foreach(source IN LISTS ARGN)
        if(source MATCHES "^src/client/")
            set(game_sees_client TRUE)
        elseif(source MATCHES "^src/server/")
            set(game_sees_server TRUE)
        elseif(source MATCHES "^src/shared/")
            set(game_sees_shared TRUE)
        endif()
    endforeach()
    if(game_sees_client AND game_sees_server)
        message(FATAL_ERROR "game_${name} trộn nguồn client và server")
    endif()
    if(game_sees_client OR game_sees_server)
        set(game_sees_shared TRUE)
    endif()
    if(game_sees_shared)
        list(APPEND game_homes "${PROJECT_SOURCE_DIR}/src/shared")
    endif()
    if(game_sees_client)
        # Sáu nhóm chỉ để xếp thư mục. Include vẫn là "avatar/x.hpp", "client/boot.hpp".
        foreach(game_group IN ITEMS app figure place face book pack)
            list(APPEND game_homes "${PROJECT_SOURCE_DIR}/src/client/${game_group}")
        endforeach()
    endif()
    if(game_sees_server)
        list(APPEND game_homes "${PROJECT_SOURCE_DIR}/src/server")
    endif()
    target_include_directories(game_${name} PUBLIC ${game_homes})
    target_compile_features(game_${name} PUBLIC cxx_std_23)
    target_link_libraries(game_${name} PUBLIC game::options PRIVATE game::warnings)
    target_link_libraries(game_all_modules INTERFACE game_${name})
endfunction()

# Configure dừng nếu một cây include module của cây khác. Đây là ranh giới, không phải quy ước thư mục.
function(game_reject_foreign tree)
    file(GLOB_RECURSE sources "${tree}/*.hpp" "${tree}/*.cpp" "${tree}/*.mm")
    foreach(source IN LISTS sources)
        file(STRINGS "${source}" lines REGEX "^[ \t]*#[ \t]*include[ \t]*\"[a-z0-9_]+/")
        foreach(line IN LISTS lines)
            string(REGEX MATCH "\"([a-z0-9_]+)/" _hit "${line}")
            if(NOT CMAKE_MATCH_1 IN_LIST ARGN)
                file(RELATIVE_PATH where "${PROJECT_SOURCE_DIR}" "${source}")
                message(FATAL_ERROR "ranh giới: ${where} include \"${CMAKE_MATCH_1}/\" ngoài cây của nó")
            endif()
        endforeach()
    endforeach()
endfunction()
set(game_engine_names audio audiotool capture core fs gpu io jobs math net render resource shader
    shadertool window xml)
set(game_shared_names protocol secure table link nav collision ids)
set(game_client_names anim avatar classic client control fx gui hero look lua luanum motion ogre
    quest scene seal sealtool skill ui)
set(game_server_names account actor authd billing billingd bus combat config content dice forge gate gated guard handlers ipc
    ledger linttool metrics mission item loot ops process scenedata service shop social store stored supervise supervisor talk
    worldd zone zoned)
game_reject_foreign("${PROJECT_SOURCE_DIR}/engine" ${game_engine_names})
game_reject_foreign("${PROJECT_SOURCE_DIR}/src/shared" ${game_engine_names} ${game_shared_names})
game_reject_foreign("${PROJECT_SOURCE_DIR}/src/client" ${game_engine_names} ${game_shared_names}
    ${game_client_names})
game_reject_foreign("${PROJECT_SOURCE_DIR}/src/server" ${game_engine_names} ${game_shared_names}
    ${game_server_names})

# core: đồng hồ, lỗi, log, luồng. Cùng API C++ trên mọi nền tảng (Result, template park), không
# thêm biên C. Win32: WaitOnAddress và ntdll. POSIX: futex 4 byte (Android, nhân 4.9 không có
# futex_waitv) hoặc __ulock_wait (iOS). log của Android là liblog.
set(game_core_sources
    engine/core/clock.cpp
    engine/core/error.cpp
    engine/core/log.cpp
    engine/core/log_sink.cpp
    engine/core/range.cpp
    engine/core/system.cpp
    engine/core/text.cpp
    engine/core/uarch.cpp)
if(WIN32)
    list(APPEND game_core_sources engine/core/handle.cpp engine/core/thread.cpp)
else()
    list(APPEND game_core_sources
        engine/core/handle_posix.cpp
        engine/core/log_sink_posix.cpp
        engine/core/system_posix.cpp
        engine/core/thread_posix.cpp)
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
    set(game_io_platform engine/io/platform_win32.cpp)
elseif(APPLE)
    set(game_io_platform engine/io/platform_apple.cpp)
else()
    set(game_io_platform engine/io/platform_posix.cpp)
endif()
game_module(io engine/io/file.cpp ${game_io_platform})
target_link_libraries(game_io PUBLIC game_core)
if(WIN32)
    # ShellExecuteExW của io::open_in_browser.
    target_link_libraries(game_io PRIVATE shell32)
endif()

game_module(xml engine/xml/document.cpp)
target_link_libraries(game_xml PUBLIC game_core)

# miniaudio chỉ giải mã và mở thiết bị. Header ấy là SYSTEM: cảnh báo của thư viện
# không vào đơn vị dịch này, mã của mình vẫn đi qua game::warnings.
add_library(game_audio_native STATIC engine/audio/detail/native.cpp)
target_include_directories(game_audio_native PUBLIC ${PROJECT_SOURCE_DIR}/engine)
target_include_directories(game_audio_native SYSTEM PRIVATE
    ${PROJECT_SOURCE_DIR}/third_party/miniaudio)
target_compile_features(game_audio_native PUBLIC cxx_std_23)
target_link_libraries(game_audio_native PUBLIC game_core game::options PRIVATE game::warnings)
if(ANDROID)
    target_link_libraries(game_audio_native PUBLIC aaudio log)
endif()
if(IOS)
    # miniaudio trên iOS (MA_APPLE_MOBILE) viết Core Audio bằng Objective-C và không nạp khung lúc
    # chạy, nên tệp cài đặt dịch thành Objective-C++ và các khung link tĩnh.
    set_source_files_properties(engine/audio/detail/native.cpp PROPERTIES LANGUAGE OBJCXX)
    target_link_libraries(game_audio_native PUBLIC "-framework CoreFoundation"
        "-framework CoreAudio" "-framework AudioToolbox" "-framework AVFoundation")
endif()
game_module(audio
    engine/audio/catalog.cpp
    engine/audio/cook.cpp
    engine/audio/detail/codec.cpp
    engine/audio/detail/music.cpp
    engine/audio/engine.cpp
    engine/audio/gain.cpp
    engine/audio/limiter.cpp
    engine/audio/pack.cpp
    engine/audio/resample.cpp)
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
    add_executable(thienlong_audio engine/audiotool/main.cpp)
    target_link_libraries(thienlong_audio PRIVATE game_audio game::warnings)
    # Cook cây sound của client ra build/cooked/sound, chung cho mọi preset. Chạy lại chỉ cook
    # tệp đổi. Gọi tay (cmake --build ... --target cook_sound) trước khi đóng APK.
    add_custom_target(cook_sound
        COMMAND thienlong_audio cook "${PROJECT_SOURCE_DIR}/dev/client/assets/sound"
            "${PROJECT_SOURCE_DIR}/build/cooked/sound"
        COMMENT "Cook âm thanh ra build/cooked/sound"
        VERBATIM)
endif()

# luanum: số của script giao diện theo MSVCR110 (định dạng, strtod, rand, ép số nguyên), module lá không phụ thuộc gì.
# LuaPlus (C) gọi nó qua luanum.h; ui/panel và runtime tự viết cũ dùng number.hpp, cformat.hpp.
game_module(luanum
    src/client/face/luanum/cformat.cpp
    src/client/face/luanum/luanum.cpp
    src/client/face/luanum/number.cpp)

# LuaPlus (Lua 5.0.1) của client 2026: máy chạy script giao diện. Nguồn chép nguyên văn ở third_party/luaplus, mục "Khác gốc"
# ở NGUON.txt. game_luaplus (tĩnh) cho client; luaplus_oracle (DLL, chỉ Windows) cho ctest lua_oracle.
add_subdirectory(third_party/luaplus)

# lua: vỏ C++ của game_luaplus — State RAII với trần bộ nhớ, móc đếm lệnh cắt vòng lặp vô hạn, trần độ sâu, nạp và gọi trả
# std::expected, hàm native không để lại đối tượng có destructor khi LuaPlus nhảy (lua/native.hpp).
game_module(lua src/client/face/lua/state.cpp)
target_link_libraries(game_lua PUBLIC game_luaplus game_luanum game_core)

# Niêm asset trên máy dựng. Client không liên kết game_seal: đường nạp và khung hình không đổi.
if(NOT CMAKE_CROSSCOMPILING)
    add_subdirectory(third_party/libsodium)
    game_module(seal
        src/client/pack/seal/key.cpp
        src/client/pack/seal/package.cpp
        src/client/pack/seal/tree.cpp
        src/client/pack/seal/detail/format.cpp)
    add_library(game_seal_native STATIC src/client/pack/seal/detail/sodium.cpp)
    target_include_directories(game_seal_native PUBLIC ${PROJECT_SOURCE_DIR}/engine
        ${PROJECT_SOURCE_DIR}/src/client/pack)
    target_compile_features(game_seal_native PUBLIC cxx_std_23)
    target_link_libraries(game_seal_native PUBLIC game_sodium game::options PRIVATE game::warnings)
    target_link_libraries(game_seal PUBLIC game_io game_seal_native)
    add_executable(thienlong_seal src/client/pack/sealtool/main.cpp)
    target_link_libraries(thienlong_seal PRIVATE game_seal game::warnings)
    if(WIN32)
        target_link_libraries(thienlong_seal PRIVATE shell32)
    endif()
    game_split_debug(thienlong_seal)
endif()

game_module(scene src/client/place/scene/placement.cpp src/client/place/scene/scene_file.cpp src/client/place/scene/transform.cpp)

# ogre: toán vô hướng đúng thứ tự phép tính của OGRE 1.2.5 (vec3, quaternion); anim: xương và
# animation theo OGRE, ra ma trận skin. Hai module thuần C++, port từ TLBB Dev, không cần math SIMD.
game_module(ogre src/client/place/ogre/quat.cpp)
game_module(fx
    src/client/place/fx/script.cpp
    src/client/place/fx/system.cpp
    src/client/place/fx/field.cpp
    src/client/place/fx/billboard.cpp
    src/client/place/fx/mesh.cpp
    src/client/place/fx/strip.cpp
    src/client/place/fx/cast.cpp)
target_link_libraries(game_fx PUBLIC game_ogre)
game_module(anim src/client/figure/anim/pose.cpp src/client/figure/anim/rig.cpp)
target_link_libraries(game_anim PUBLIC game_ogre)

# table: đọc bảng TSV của client; look: giải ngoại hình người chơi từ các bảng đó (port từ TLBB Dev).
game_module(table src/shared/table/tsv.cpp src/shared/table/localize.cpp)
target_link_libraries(game_table PUBLIC game_core)
# Máy chủ. content chỉ nhận chữ và trả kết quả; exe thienlong_lint là nơi đọc đĩa.
game_module(content
    src/server/content/coverage.cpp
    src/server/content/lint.cpp
    src/server/content/path_glob.cpp
    src/server/content/ref_rule.cpp
    src/server/content/table_text.cpp
    src/server/content/utf8.cpp)
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
        src/server/config/admin.cpp
        src/server/config/auth.cpp
        src/server/config/billing.cpp
        src/server/config/client.cpp
        src/server/config/cluster.cpp
        src/server/config/gate.cpp
        src/server/config/log.cpp
        src/server/config/loose.cpp
        src/server/config/secrets.cpp
        src/server/config/startup.cpp
        src/server/config/store.cpp
        src/server/config/supervisor.cpp
        src/server/config/types.cpp
        src/server/config/world.cpp
        src/server/config/zone.cpp
        src/server/config/detail/node.cpp
        src/server/config/detail/parse.cpp
        src/server/config/detail/read.cpp
        src/server/config/detail/read_list.cpp)
    target_link_libraries(game_config PUBLIC game_core PRIVATE game_toml)
    # process: chạy và dừng tiến trình con; supervise: máy trạng thái của trình giám sát, không
    # đụng hệ điều hành.
    if(WIN32)
        game_module(process
            src/server/process/process.cpp src/server/process/process_win32.cpp src/server/process/self_win32.cpp)
    else()
        game_module(process src/server/process/process.cpp src/server/process/process_posix.cpp)
    endif()
    target_link_libraries(game_process PUBLIC game_core)
    game_module(supervise src/server/supervise/supervise.cpp)
    target_link_libraries(game_supervise PUBLIC game_core)
    # service: khung chung của một tiến trình máy chủ; mỗi exe chỉ là một main.cpp ba dòng.
    game_module(service
        src/server/service/host.cpp
        src/server/service/load.cpp
        src/server/service/request.cpp
        src/server/service/service.cpp)
    target_link_libraries(game_service
        PUBLIC game_core game_config game_supervise PRIVATE game_io game_process)
    add_executable(thienlong_lint src/server/linttool/main.cpp src/server/linttool/config_lint.cpp)
    target_link_libraries(thienlong_lint PRIVATE game_content game_config game_io game::warnings)
    if(WIN32)
        target_link_libraries(thienlong_lint PRIVATE shell32)
    endif()
    game_split_debug(thienlong_lint)
    # Exe máy chủ vào <prefix>/server/bin. prefix dev là bản thử, prefix release là bản chính thức.
    # Lệnh cài mặc định của client không chép các exe này.
    install(TARGETS thienlong_lint RUNTIME DESTINATION server/bin COMPONENT server EXCLUDE_FROM_ALL)
    function(game_server_exe target folder)
        add_executable(${target} "src/server/${folder}/main.cpp")
        target_link_libraries(${target} PRIVATE game_service game::warnings)
        game_split_debug(${target})
        install(TARGETS ${target} RUNTIME DESTINATION server/bin COMPONENT server EXCLUDE_FROM_ALL)
    endfunction()
    game_server_exe(thienlong_server supervisor)
    game_server_exe(thienlong_store stored)
    game_server_exe(thienlong_auth authd)
    game_server_exe(thienlong_billing billingd)
    game_server_exe(thienlong_world worldd)
    game_server_exe(thienlong_zone zoned)
    game_server_exe(thienlong_gate gated)
    # Exe phụ của process_tests: đóng vai một tiến trình con ngoan hoặc hư. Không cài.
    add_executable(thienlong_test_child Test/support/server_child.cpp)
    target_link_libraries(thienlong_test_child PRIVATE game_process game::warnings)
elseif(NOT CMAKE_CROSSCOMPILING)
    message(STATUS "không thấy toml++/toml.hpp: bỏ các module, exe và test của máy chủ")
endif()
# protocol: tầng byte, khung, kênh và danh mục tin sinh từ bảng; net: socket TCP không chặn và tập
# chờ, nơi duy nhất include header mạng của hệ điều hành. Hai module không include nhau và không cần
# tomlplusplus. messages.cpp (và messages.hpp) sinh bởi TOOLS/server/gen_protocol.py từ
# src/shared/protocol/catalog/*.tsv; socket_win32.cpp và socket_posix.cpp là hai nền của net.
if(NOT CMAKE_CROSSCOMPILING)
    game_module(protocol src/shared/protocol/wire.cpp src/shared/protocol/channel.cpp src/shared/protocol/messages.cpp)
    target_link_libraries(game_protocol PUBLIC game_core)
    if(WIN32)
        game_module(net engine/net/net.cpp engine/net/socket_win32.cpp engine/net/reactor_win32.cpp)
    else()
        game_module(net engine/net/net.cpp engine/net/socket_posix.cpp engine/net/reactor_posix.cpp)
    endif()
    target_link_libraries(game_net PUBLIC game_core)
    if(WIN32)
        target_link_libraries(game_net PRIVATE ws2_32 mswsock)
    endif()
    # metrics: bộ đếm, mức đo, biểu đồ thời gian từng pha và ảnh chụp văn bản có trần; chỉ cần core,
    # nên đứng ngoài khối cần tomlplusplus. Cổng đọc qua loopback là module con metrics/serve.
    game_module(guard src/server/guard/pace.cpp)
    target_link_libraries(game_guard PUBLIC game_core)
    game_module(metrics src/server/metrics/metrics.cpp)
    target_link_libraries(game_metrics PUBLIC game_core)
    game_module(metrics_serve src/server/metrics/serve/serve.cpp)
    target_link_libraries(game_metrics_serve PUBLIC game_core game_metrics game_net)
    # Chụp ảnh số đo của một tiến trình qua cổng metrics của nó (kịch bản kiểm gọi exe này).
    if(TARGET game_process)
        add_executable(thienlong_metrics_snap TOOLS/server/metrics_snap.cpp)
        target_link_libraries(thienlong_metrics_snap PRIVATE game_metrics game_net game_process game_io game::warnings)
    endif()
    # secure: bắt tay và bản ghi. Header C của libsodium đi qua include SYSTEM của
    # game_sodium, nên cảnh báo của thư viện không vào sodium.cpp.
    game_module(secure src/shared/secure/identity.cpp src/shared/secure/handshake.cpp src/shared/secure/record.cpp
        src/shared/secure/password.cpp)
    add_library(game_secure_sodium STATIC src/shared/secure/detail/sodium.cpp)
    target_include_directories(game_secure_sodium PUBLIC ${PROJECT_SOURCE_DIR}/engine
        ${PROJECT_SOURCE_DIR}/src/shared)
    target_compile_features(game_secure_sodium PUBLIC cxx_std_23)
    target_link_libraries(game_secure_sodium PUBLIC game_sodium PRIVATE game::options game::warnings)
    target_link_libraries(game_secure PUBLIC game_core PRIVATE game_secure_sodium)
    game_module(link src/shared/link/link.cpp)
    target_link_libraries(game_link PUBLIC game_core game_net game_protocol game_secure)
    # client/session: phiên mạng của client (luồng nền giữ link::Link, máy trạng thái, bảng cổng máy chủ). Chỉ máy tính,
    # như net và link: Android và iOS vào thẳng cảnh, không có thủ tục đăng nhập trực tuyến.
    game_module(client_session
        src/client/app/client/session/gates.cpp
        src/client/app/client/session/machine.cpp
        src/client/app/client/session/session.cpp)
    target_link_libraries(game_client_session PUBLIC game_core game_net game_protocol game_secure game_link game_table)
    # client/online: cầu nối giữa chuỗi đăng nhập (ui/panel) và phiên mạng; viewer của Windows gọi nó.
    game_module(client_online src/client/app/client/online/bridge.cpp)
    target_link_libraries(game_client_online PUBLIC game_client_session game_ui_panel game_protocol game_core
        PRIVATE game_secure)
    if(TARGET game_config)
        game_module(gate src/server/gate/table.cpp src/server/gate/front.cpp src/server/gate/motion.cpp)
        target_link_libraries(game_gate PUBLIC game_core game_net game_protocol game_secure game_config game_guard
            game_metrics PRIVATE game_io game_process)
        target_link_libraries(game_service PUBLIC game_gate)
        game_module(account
            src/server/account/rules.cpp
            src/server/account/book.cpp
            src/server/account/cap.cpp
            src/server/account/ipc_key.cpp
            src/server/account/rpc.cpp
            src/server/account/realm.cpp)
        target_link_libraries(game_account PUBLIC game_core game_net game_protocol game_secure game_config
            game_io game_process)
        target_link_libraries(game_gate PUBLIC game_account game_ipc)
        # ipc_key.cpp: kiểm và đặt quyền riêng (DACL) cho ipc.key.
        if(WIN32)
            target_link_libraries(game_account PRIVATE advapi32)
        endif()
        if(CMAKE_TOOLCHAIN_FILE MATCHES "[Vv]cpkg")
            find_package(PostgreSQL REQUIRED)
            game_module(store src/server/store/pg.cpp)
            target_link_libraries(game_store PUBLIC game_core PostgreSQL::PostgreSQL)
            if(WIN32)
                target_link_libraries(game_store PUBLIC ws2_32)
            endif()
            target_sources(game_account PRIVATE src/server/account/sql.cpp src/server/account/serve.cpp)
            target_link_libraries(game_account PUBLIC game_store)
            target_compile_definitions(game_service PRIVATE GAME_HAS_LIBPQ)
            target_link_libraries(game_service PUBLIC game_account)
        endif()
    endif()
    # Module gameplay của máy chủ: mỗi module một tệp cmake/server/<tên>.modules.cmake (game_module, link)
    # và, nếu có test, cmake/server/<tên>.tests.cmake (game_test, nạp sau khi game_test được định nghĩa).
    # Tách tệp để nhiều người cùng thêm module mà không sửa chung một vùng của tệp này.
    file(GLOB game_server_module_files CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/cmake/server/*.modules.cmake")
    foreach(game_server_module_file IN LISTS game_server_module_files)
        include("${game_server_module_file}")
    endforeach()
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/bench/collision_bench.cpp")
        add_executable(collision_bench Test/bench/collision_bench.cpp)
        target_include_directories(collision_bench PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Test" "${CMAKE_CURRENT_SOURCE_DIR}/Test/Collision")
        target_link_libraries(collision_bench PRIVATE game_collision game::warnings)
    else()
        message(STATUS "Thiếu Test/bench/collision_bench.cpp, bỏ collision_bench")
    endif()
endif()
game_module(classic src/client/place/classic/classic.cpp)
target_link_libraries(game_classic PUBLIC game_core game_math)
game_module(look src/client/figure/look/appearance.cpp src/client/figure/look/look.cpp src/client/figure/look/head.cpp src/client/figure/look/sect.cpp
    src/client/figure/look/weapon.cpp src/client/figure/look/skill.cpp)
target_link_libraries(game_look PUBLIC game_table game_core)

# avatar: chọn clip theo trạng thái (gait) và làm mượt hướng mặt (turning), port từ TLBB Dev.
game_module(avatar src/client/figure/avatar/gait.cpp src/client/figure/avatar/turning.cpp src/client/figure/avatar/locator.cpp)
target_link_libraries(game_avatar PUBLIC game_anim game_core game_look)

# control: mặt đất của cảnh (độ cao, tia chạm đất, va chạm của mắt camera), tia từ màn hình, camera
# bám theo, lệnh đi bằng chuột, chọn thứ dưới chuột, cử chỉ chạm và cần gạt ảo; port từ TLBB Dev.
game_module(control
    src/client/figure/control/char_camera.cpp
    src/client/figure/control/cursor_rules.cpp
    src/client/figure/control/follow_camera.cpp
    src/client/figure/control/ground.cpp
    src/client/figure/control/hover.cpp
    src/client/figure/control/player_input.cpp
    src/client/figure/control/stick.cpp
    src/client/figure/control/touch.cpp
    src/client/figure/control/view_ray.cpp)
target_link_libraries(game_control PUBLIC game_ogre game_core)

# motion: luật đi dọc đường (vị trí là hàm đóng của điểm xuất phát, đường, tốc độ, thời gian).
game_module(motion src/client/figure/motion/motion.cpp src/client/figure/motion/jump.cpp)
target_link_libraries(game_motion PUBLIC game_core)

# nav: lưới đi của cảnh (tệp .path) và luật đi của người chơi, port PathLib.dll và CPath của client
# 2026. Kết quả phải trùng từng bit với bản gốc, nên GCC và Clang không được gộp nhân với cộng
# thành FMA (arm64 có sẵn FMA; MSVC x64 mặc định không gộp).
game_module(nav src/shared/nav/mesh.cpp src/shared/nav/finder.cpp src/shared/nav/route.cpp)
target_link_libraries(game_nav PUBLIC game_core)
target_compile_options(game_nav PRIVATE "$<$<CXX_COMPILER_ID:GNU,Clang>:-ffp-contract=off>")
# collision: va chạm công trình (.WCollision), port BuildingCollision của PathLib.dll. A: bộ đọc; C thêm Model.
game_module(collision src/shared/collision/building_file.cpp src/shared/collision/mesh.cpp
    src/shared/collision/opcode_tree.cpp src/shared/collision/model.cpp)
target_link_libraries(game_collision PUBLIC game_core)
target_compile_options(game_collision PRIVATE "$<$<CXX_COMPILER_ID:GNU,Clang>:-ffp-contract=off>" "$<$<CXX_COMPILER_ID:MSVC>:/fp:precise>")

# gui: giao diện gốc của client (CEGUI và Falagard): nạp XML scheme, looknfeel, imageset và layout
# lúc chạy, dàn trang rồi ra lệnh vẽ ảnh và chữ; port từ TLBB Dev. Không vẽ thật: bộ vẽ 2D nằm ở
# module ui.
game_module(gui
    src/client/face/gui/value.cpp
    src/client/face/gui/strings.cpp
    src/client/face/gui/loader.cpp
    src/client/face/gui/loader_look.cpp
    src/client/face/gui/layout.cpp
    src/client/face/gui/paint.cpp
    src/client/face/gui/text.cpp
    src/client/face/gui/softkey.cpp
    src/client/face/gui/widgets.cpp
    src/client/face/gui/radar.cpp
    src/client/face/gui/hub.cpp)
target_link_libraries(game_gui PUBLIC game_core game_io game_xml game_table)
# hero: trạng thái của nhân vật người chơi mà giao diện hiển thị (tên, cấp, máu, khí, nộ, kinh
# nghiệm). Giá trị thuần: mạng ghi vào, ui/panel đọc.
game_module(hero src/client/figure/hero/hero.cpp)
target_link_libraries(game_hero PUBLIC game_core)
# quest: sổ nhiệm vụ của người chơi và bảng nhiệm vụ nhận được, bộ lọc port từ mã máy client 2026.
game_module(quest src/client/book/quest/outline.cpp)
target_link_libraries(game_quest PUBLIC game_table game_core)
# skill: bảng của sách võ công, sách kỹ năng của người chơi và hệ action, port từ mã máy client 2026.
game_module(skill src/client/book/skill/tables.cpp src/client/book/skill/book.cpp src/client/book/skill/actions.cpp)
target_link_libraries(game_skill PUBLIC game_table game_core)

# ui/panel: logic của từng cửa sổ HUD, thay script Lua của client gốc (hiện, giấu, điền chữ, đặt
# thanh). Thuần logic trên gui, không cần GPU; module ui (bộ vẽ) dùng nó.
game_module(ui_panel
    src/client/face/ui/panel/online.cpp
    src/client/face/ui/panel/deck.cpp
    src/client/face/ui/panel/desk.cpp
    src/client/face/ui/panel/logon.cpp
    src/client/face/ui/panel/softkey.cpp
    src/client/face/ui/panel/scene_trans.cpp
    src/client/face/ui/panel/start.cpp
    src/client/face/ui/panel/player_frame.cpp
    src/client/face/ui/panel/minimap.cpp
    src/client/face/ui/panel/maps.cpp
    src/client/face/ui/panel/menubar.cpp
    src/client/face/ui/panel/self_equip.cpp
    src/client/face/ui/panel/quest_book.cpp
    src/client/face/ui/panel/quest_log.cpp
    src/client/face/ui/panel/wording.cpp
    src/client/face/ui/panel/widgets.cpp
    src/client/face/ui/panel/portraits.cpp
    src/client/face/ui/panel/role_cast.cpp
    src/client/face/ui/panel/roles.cpp
    src/client/face/ui/panel/select_role.cpp
    src/client/face/ui/panel/create_role.cpp
    src/client/face/ui/panel/packet.cpp
    src/client/face/ui/panel/scene_board.cpp
    src/client/face/ui/panel/world_map.cpp
    src/client/face/ui/panel/scene_table.cpp
    src/client/face/ui/panel/system_info.cpp
    src/client/face/ui/panel/servers.cpp
    src/client/face/ui/panel/select_server.cpp
    src/client/face/ui/panel/login_flow.cpp
    src/client/face/ui/panel/events.cpp
    src/client/face/ui/panel/main_menu_bar_3.cpp
    src/client/face/ui/panel/action_bar.cpp
    src/client/face/ui/panel/main_menu_bar_4.cpp
    src/client/face/ui/panel/main_menu_bar_2.cpp
    src/client/face/ui/panel/function_bar_right.cpp
    src/client/face/ui/panel/function_bar_right_2.cpp
    src/client/face/ui/panel/call_events.cpp
    src/client/face/ui/panel/action_bars.cpp
    src/client/face/ui/panel/progress_bar.cpp
    src/client/face/ui/panel/data_pool.cpp
    src/client/face/ui/panel/debug_list_box.cpp)
target_link_libraries(game_ui_panel PUBLIC game_gui game_hero game_luanum game_quest game_table game_core)
# ui/script: máy chủ cửa sổ chạy script giao diện gốc trên LuaPlus (docs/giao-viec/LUA-GEN/TANG-C.md). windows.cpp đọc sổ cửa
# sổ (Script/windows.tsv), host.cpp là phần chủ (môi trường <Tên>_Env, `this`, gửi sự kiện, nhường chỗ, hẹn giờ), widget.cpp là
# các lớp Lua của widget (SetText, Show, AddItem...), ghi vào ui/panel::Widgets và hàng Call; không đụng GPU, dựng ở mọi nền tảng.
game_module(ui_script
    src/client/face/ui/script/gui_screen.cpp
    src/client/face/ui/script/windows.cpp
    src/client/face/ui/script/host.cpp
    src/client/face/ui/script/native_support.cpp
    src/client/face/ui/script/native_xscript.cpp
    src/client/face/ui/script/natives.cpp
    src/client/face/ui/script/widget.cpp
    src/client/face/ui/script/xscript.cpp)
target_link_libraries(game_ui_script PUBLIC game_ui_panel game_gui game_table game_io game_lua game_luaplus game_luanum game_core)
# Cấu hình dựng client nằm ở src/client/client.build.toml (chủ dự án chốt 2026-10-14: gắn thẳng vào
# exe lúc dựng, không đọc tệp lúc chạy, không qua server hay protocol). CMake đọc khoá avatar_frame
# bằng regex (chỉ nhận dạng `khoá = "giá trị"` trên một dòng) rồi đặt macro cho riêng player_frame.cpp,
# nên đổi giá trị chỉ dựng lại tệp đó. Sửa tệp thì CMake tự cấu hình lại (CMAKE_CONFIGURE_DEPENDS).
set(game_client_build "${PROJECT_SOURCE_DIR}/src/client/client.build.toml")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${game_client_build}")
file(STRINGS "${game_client_build}" game_schema_line REGEX "^schema[ \t]*=")
if(NOT game_schema_line MATCHES "^schema[ \t]*=[ \t]*1([ \t]|$)")
    message(FATAL_ERROR "${game_client_build}: schema phải là 1")
endif()
file(STRINGS "${game_client_build}" game_avatar_line REGEX "^[ \t]*avatar_frame[ \t]*=")
if(NOT game_avatar_line MATCHES "^[ \t]*avatar_frame[ \t]*=[ \t]*\"([a-z]*)\"")
    message(FATAL_ERROR "${game_client_build}: thiếu dòng avatar_frame = \"round\" hoặc \"square\"")
endif()
set(game_avatar_frame "${CMAKE_MATCH_1}")
if(NOT game_avatar_frame STREQUAL "round" AND NOT game_avatar_frame STREQUAL "square")
    message(FATAL_ERROR "${game_client_build}: avatar_frame = \"${game_avatar_frame}\", chỉ nhận round hoặc square")
endif()
set(game_avatar_square 0)
if(game_avatar_frame STREQUAL "square")
    set(game_avatar_square 1)
endif()
set_source_files_properties(src/client/face/ui/panel/player_frame.cpp
    PROPERTIES COMPILE_DEFINITIONS "GAME_AVATAR_FRAME_SQUARE=${game_avatar_square}")
game_module(client_map
    src/client/app/client/map/terrain.cpp
    src/client/app/client/map/samples.cpp
    src/client/app/client/map/picture.cpp
    src/client/app/client/map/splat.cpp
    src/client/app/client/map/liquid.cpp
    src/client/app/client/map/sheet.cpp
    src/client/app/client/map/ground.cpp
    src/client/app/client/map/book.cpp
    src/client/app/client/map/gates.cpp)
target_link_libraries(game_client_map PUBLIC game_core game_io game_xml game_scene)
target_link_libraries(game_scene PUBLIC game_core game_xml)

# window: cửa sổ, màn hình, con trỏ, vòng thông điệp; chép từ Forge2 và mới có bản Win32, nên chỉ
# dựng trên Windows (MSVC, Clang và GCC MinGW đều dựng được: đã đo bằng check.py trên từng tệp).
# Android và iOS chưa có: bản Android của Forge2 chưa được chép. Thư viện hệ thống: shcore cho DPI
# từng màn hình, dwmapi cho thanh tiêu đề tối, shell32 cho kéo thả tệp, advapi32 cho registry.
if(WIN32)
    game_module(window
        engine/window/cursor.cpp
        engine/window/monitor.cpp
        engine/window/system.cpp
        engine/window/window.cpp)
    target_link_libraries(game_window
        PUBLIC game_core PRIVATE user32 gdi32 shell32 shcore dwmapi advapi32)
endif()

# jobs: hệ thống job (hàng đợi chia việc, đếm việc, chờ có hạn); chép từ Forge2, dựa phần luồng và
# đồng hồ của core. Core có bản POSIX nên dựng được cả trên Android; capture đi kèm vì nén dải
# hình chạy qua jobs. iOS dùng chung vì client_display (đường vẽ) và game_shader link cả hai.
if(WIN32 OR ANDROID OR IOS)
    game_module(jobs engine/jobs/jobs.cpp engine/jobs/queue.cpp)
    target_link_libraries(game_jobs PUBLIC game_core)

    game_module(capture
        engine/capture/deflate.cpp
        engine/capture/frame.cpp
        engine/capture/png.cpp)
    target_link_libraries(game_capture PUBLIC game_core PRIVATE game_jobs)
endif()

# math: vectơ, ma trận, quaternion, hình học; chép từ Forge2. Mã dùng intrinsic SSE4.1; trên arm64
# math/sse.hpp ánh xạ sang NEON qua sse2neon (vcpkg, header nằm trong include/sse2neon).
set(GAME_HAS_MATH OFF)
if(CMAKE_SYSTEM_PROCESSOR MATCHES "AMD64|x86_64|arm64|aarch64")
    set(GAME_HAS_MATH ON)
endif()
if(GAME_HAS_MATH)
    game_module(math engine/math/geometry.cpp)
    target_link_libraries(game_math PUBLIC game_core)
    if(NOT CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        # GCC và Clang chỉ nhận intrinsic SSE4.1 khi có cờ này (đã đo: thiếu thì _mm_blend_ps báo
        # "target specific option mismatch"); cl của MSVC không cần. PUBLIC vì header chứa mã.
        target_compile_options(game_math PUBLIC "$<$<CXX_COMPILER_ID:GNU,Clang>:-msse4.1>")
    else()
        target_include_directories(game_math SYSTEM PUBLIC
            "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include/sse2neon")
    endif()
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
        # fs của thiết bị: mã hoá (giải gói shader), luồng byte và posix.cpp (đọc cả tệp, ghi nguyên
        # tử, hỏi tệp, tạo thư mục); disk/file/watcher của Forge2 là Win32.
        game_module(fs
            engine/fs/buny.cpp
            engine/fs/codec.cpp
            engine/fs/path.cpp
            engine/fs/posix.cpp
            engine/fs/stream.cpp)
    else()
        game_module(fs
            engine/fs/buny.cpp
            engine/fs/codec.cpp
            engine/fs/disk.cpp
            engine/fs/file.cpp
            engine/fs/path.cpp
            engine/fs/stream.cpp
            engine/fs/watcher.cpp)
    endif()
    target_link_libraries(game_fs PUBLIC game_core PRIVATE lz4::lz4 xxHash::xxhash zstd::libzstd)
    if(ANDROID OR IOS)
        # Chạy trên thiết bị chỉ đọc gói .f2s; builder/compiler/dxil/dxbc là công cụ Windows.
        game_module(shader
            engine/shader/package.cpp
            engine/shader/reflection.cpp
            engine/shader/spirv.cpp
            engine/shader/types.cpp)
        target_link_libraries(game_shader PUBLIC game_core game_fs PRIVATE game_io game_jobs)
    else()
        # builder dịch nguồn Slang (detail/slang.cpp, slang.dll nạp lúc chạy); compiler và dxil
        # include <windows.h> trực tiếp (bản chép) rồi gọi std::max. NOMINMAX phải có trước header
        # ấy. check.py không thấy cờ của target này.
        game_module(shader
            engine/shader/builder.cpp
            engine/shader/compiler.cpp
            engine/shader/detail/reconcile.cpp
            engine/shader/detail/slang.cpp
            engine/shader/dxil.cpp
            engine/shader/manifest.cpp
            engine/shader/package.cpp
            engine/shader/reflection.cpp
            engine/shader/spirv.cpp
            engine/shader/types.cpp)
        target_link_libraries(
            game_shader PUBLIC game_core game_fs PRIVATE game_io game_jobs)
        target_compile_definitions(game_shader PRIVATE NOMINMAX)
    endif()

    # gpu: phần chung và backend Vulkan mọi nền; D3D12/D3D11 chỉ Windows. Vulkan trên Windows lấy
    # từ Vulkan SDK (VULKAN_SDK), trên Android từ NDK (header trong sysroot, libvulkan.so hệ thống).
    find_package(Vulkan REQUIRED)
    if(ANDROID)
        game_module(gpu
            engine/gpu/check.cpp
            engine/gpu/device.cpp
            engine/gpu/format.cpp
            engine/gpu/layout.cpp
            engine/gpu/vulkan/api.cpp
            engine/gpu/vulkan/commands.cpp
            engine/gpu/vulkan/convert.cpp
            engine/gpu/vulkan/device.cpp
            engine/gpu/vulkan/instance.cpp
            engine/gpu/vulkan/programs.cpp
            engine/gpu/vulkan/resources.cpp
            engine/gpu/vulkan/surface_android.cpp
            engine/gpu/vulkan/swapchain.cpp
            engine/gpu/gles/bind_map.cpp
            engine/gpu/gles/context_egl.cpp
            engine/gpu/gles/device.cpp
            engine/gpu/gles/load.cpp
            engine/gpu/gles/pick.cpp
            engine/gpu/gles/probe.cpp
            engine/gpu/gles/programs.cpp
            engine/gpu/gles/resources.cpp
            engine/gpu/gles/commands.cpp
            engine/gpu/gles/swapchain.cpp)
        target_compile_definitions(game_gpu PRIVATE GAME_GPU_GLES)
        target_link_libraries(game_gpu PUBLIC game_core game_shader PRIVATE Vulkan::Vulkan EGL GLESv3)
    elseif(IOS)
        # iOS chạy Vulkan trên MoltenVK nhúng: bề mặt là CAMetalLayer (surface_ios.mm). MoltenVK
        # và framework của Apple tĩnh trong ứng dụng; đủ mã, chờ macOS để build.
        game_module(gpu
            engine/gpu/check.cpp
            engine/gpu/device.cpp
            engine/gpu/format.cpp
            engine/gpu/layout.cpp
            engine/gpu/vulkan/api.cpp
            engine/gpu/vulkan/commands.cpp
            engine/gpu/vulkan/convert.cpp
            engine/gpu/vulkan/device.cpp
            engine/gpu/vulkan/instance.cpp
            engine/gpu/vulkan/programs.cpp
            engine/gpu/vulkan/resources.cpp
            engine/gpu/vulkan/surface_ios.mm
            engine/gpu/vulkan/swapchain.cpp)
        # iOS không có loader Vulkan: Vulkan::Vulkan phải là MoltenVK. find_package(Vulkan) tìm tên
        # "vulkan" nên cần đặt Vulkan_LIBRARY và Vulkan_INCLUDE_DIR tới MoltenVK (apple/HUONG-DAN.txt).
        # Các khung dưới là phần phụ thuộc của MoltenVK tĩnh.
        target_link_libraries(game_gpu PUBLIC game_core game_shader
            PRIVATE Vulkan::Vulkan "-framework Metal" "-framework QuartzCore" "-framework UIKit"
            "-framework Foundation" "-framework IOSurface" "-framework CoreGraphics")
    else()
        # Macro GAME_GPU_D3D12 và GAME_GPU_D3D11 bật nhánh trong gpu/device.cpp; thiếu macro thì
        # nhánh ấy trả kUnsupported. dxcapi.h nằm trong include của Vulkan SDK, không trong Windows
        # SDK. Không link vulkan-1.
        target_include_directories(game_shader PRIVATE
            "$<TARGET_PROPERTY:Vulkan::Vulkan,INTERFACE_INCLUDE_DIRECTORIES>")
        # slang.h cũng nằm trong SDK (Include/slang). SYSTEM: cảnh báo của header ấy không thuộc dự án.
        target_include_directories(game_shader SYSTEM PRIVATE "${Vulkan_INCLUDE_DIR}/slang")
        game_module(gpu
            engine/gpu/check.cpp
            engine/gpu/device.cpp
            engine/gpu/format.cpp
            engine/gpu/layout.cpp
            engine/gpu/vulkan/api.cpp
            engine/gpu/vulkan/commands.cpp
            engine/gpu/vulkan/convert.cpp
            engine/gpu/vulkan/device.cpp
            engine/gpu/vulkan/instance.cpp
            engine/gpu/vulkan/programs.cpp
            engine/gpu/vulkan/resources.cpp
            engine/gpu/vulkan/surface_win32.cpp
            engine/gpu/vulkan/swapchain.cpp
            engine/gpu/d3d12/commands.cpp
            engine/gpu/d3d12/convert.cpp
            engine/gpu/d3d12/device.cpp
            engine/gpu/d3d12/programs.cpp
            engine/gpu/d3d12/resources.cpp
            engine/gpu/d3d12/swapchain.cpp
            engine/gpu/d3d11/commands.cpp
            engine/gpu/d3d11/convert.cpp
            engine/gpu/d3d11/device.cpp
            engine/gpu/d3d11/hresult.cpp
            engine/gpu/d3d11/programs.cpp
            engine/gpu/d3d11/resources.cpp
            engine/gpu/d3d11/swapchain.cpp
            engine/gpu/gles/bind_map.cpp
            engine/gpu/gles/context_wgl.cpp
            engine/gpu/gles/device.cpp
            engine/gpu/gles/load.cpp
            engine/gpu/gles/pick.cpp
            engine/gpu/gles/probe.cpp
            engine/gpu/gles/programs.cpp
            engine/gpu/gles/resources.cpp
            engine/gpu/gles/commands.cpp
            engine/gpu/gles/swapchain.cpp)
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
    game_module(render engine/render/screen.cpp)
    target_link_libraries(game_render PUBLIC game_core game_gpu)

    # resource: nạp GLB (cgltf, stb) và tải lên GPU (meshoptimizer giải EXT_meshopt_compression).
    # Cần math. Trên Windows x64 cả GAME_HAS_GPU và GAME_HAS_MATH cùng bật; arm64 chưa có math.
    if(GAME_HAS_MATH)
        find_path(CGLTF_INCLUDE_DIR NAMES cgltf.h REQUIRED)
        find_package(Stb REQUIRED)
        find_package(meshoptimizer CONFIG REQUIRED)
        game_module(resource
            engine/resource/dds.cpp
            engine/resource/tier.cpp
            engine/resource/ogre_mesh.cpp
            engine/resource/image.cpp
            engine/resource/model.cpp
            engine/resource/upload.cpp)
        target_include_directories(game_resource PRIVATE ${CGLTF_INCLUDE_DIR} ${Stb_INCLUDE_DIR})
        target_link_libraries(game_resource
            PUBLIC game_core game_math game_fs game_gpu
            PRIVATE meshoptimizer::meshoptimizer)
        # Forward đọc gói .f2s và vẽ model đã tải lên. Header của nó kéo math và resource.
        target_sources(game_render PRIVATE engine/render/camera.cpp engine/render/catalog.cpp
            engine/render/forward.cpp engine/render/shade.cpp engine/render/ui.cpp engine/render/canvas.cpp)
        target_link_libraries(game_render PUBLIC game_math game_resource PRIVATE game_shader)
        # Nạp người chơi từ GLB và ra ma trận skin mỗi khung (cần resource, look, io).
        target_sources(game_avatar PRIVATE src/client/figure/avatar/avatar.cpp src/client/figure/avatar/rig.cpp)
        target_link_libraries(game_avatar PUBLIC game_look game_math game_io game_resource game_anim game_ogre
            game_classic)
        # ui: HUD của game: bộ vẽ quad của giao diện gốc lên lượt vẽ 2D (render/ui), gom bộ nạp, dàn trang
        # và bảng chuỗi (cần gui, render, resource).
        game_module(ui src/client/face/ui/painter.cpp src/client/face/ui/hud.cpp src/client/face/ui/pace.cpp src/client/face/ui/text.cpp
            src/client/face/ui/radar.cpp)
        target_link_libraries(game_ui PUBLIC game_gui game_ui_panel game_ui_script game_render game_resource
            game_gpu game_io game_table game_core)
    endif()
endif()

# Công cụ dịch shader, chạy trên máy dựng (Windows). Gói .f2s cho thiết bị đóng sẵn vào APK;
# Android không dựng công cụ này vì builder/compiler là Win32.
if(GAME_HAS_GPU AND WIN32)
    add_executable(thienlong_shader engine/shadertool/main.cpp)
    target_link_libraries(thienlong_shader PRIVATE game_shader game_jobs game_io game::warnings)
    game_split_debug(thienlong_shader)
    set(game_shader_dir "${CMAKE_BINARY_DIR}/shaders")
    set(game_shader_src "${PROJECT_SOURCE_DIR}/src/client/render/shaders")
    # Danh sách gói lấy thẳng từ shaders.list (mỗi dòng "shader <tên> <tệp>" là một gói <tên>.f2s):
    # công cụ dịch mọi dòng của danh sách, nên gói nào nó sinh ra cũng được theo dõi và được cài.
    # Chép tên gói ra đây lần nữa thì thêm một dòng vào danh sách mà quên ở đây là gói đó không
    # vào bản cài, lượt vẽ nạp nó lặng lẽ tắt lúc chạy (đã xảy ra với fx: bản cài không vẽ hạt nào).
    file(STRINGS "${game_shader_src}/shaders.list" game_shader_lines REGEX "^shader ")
    set(game_shader_packages "")
    foreach(game_shader_line IN LISTS game_shader_lines)
        string(REGEX REPLACE "^shader +([^ ]+) .*$" "\\1" game_shader_name "${game_shader_line}")
        list(APPEND game_shader_packages "${game_shader_dir}/${game_shader_name}.f2s")
    endforeach()
    if(NOT game_shader_packages)
        message(FATAL_ERROR "src/client/render/shaders/shaders.list không có dòng shader nào")
    endif()
    # Mọi tệp nguồn shader của thư mục: sửa tệp nào thì dịch lại.
    file(GLOB game_shader_sources CONFIGURE_DEPENDS
        "${game_shader_src}/*.slang" "${game_shader_src}/*.glsl")
    add_custom_command(
        OUTPUT ${game_shader_packages}
        COMMAND thienlong_shader build "${game_shader_src}/shaders.list"
            --out "${game_shader_dir}" --target spirv,dxil,dxbc,glsl
        DEPENDS thienlong_shader "${game_shader_src}/shaders.list" ${game_shader_sources}
        COMMENT "Dịch shader của render thành gói .f2s"
        VERBATIM)
    add_custom_target(game_client_shaders DEPENDS ${game_shader_packages})
    install(FILES ${game_shader_packages} DESTINATION client/bin/shaders)
endif()

# client: phần của exe kiểm được bằng test (tuỳ chọn dòng lệnh) và vòng lặp cửa sổ. Vòng lặp cửa sổ
# cần module window, mới có trên Windows; nền tảng khác dựng bản không cửa sổ. Phần hiển thị của
# cửa sổ (client/display.hpp) có bản dùng chuỗi đồ hoạ và bản không vẽ cho cấu hình thiếu nó.
# client tách submodule cho ranh giới rõ: stage (nội dung cảnh cần vẽ), map (địa hình .Terrain),
# display (phần đồ hoạ, bản có chuỗi đồ hoạ hoặc bản không vẽ), viewer (vòng lặp cửa sổ). Gốc
# client giữ tuỳ chọn dòng lệnh và các điểm vào (main, android_main, ios_main).
if(GAME_HAS_GPU)
    set(game_client_screen
        src/client/app/client/display/graphic/frame.cpp
        src/client/app/client/display/graphic/stream.cpp
        src/client/app/client/display/graphic/scene.cpp
        src/client/app/client/display/graphic/play.cpp
        src/client/app/client/display/graphic/face.cpp
        src/client/app/client/display/graphic/effect.cpp
        src/client/app/client/display/player.cpp
        src/client/app/client/display/portrait.cpp src/client/app/client/display/role_preview.cpp src/client/app/client/display/fx_view.cpp
        src/client/app/client/display/role_stage.cpp
        src/client/app/client/display/lighting.cpp src/client/app/client/display/login_data.cpp)
else()
    set(game_client_screen src/client/app/client/display/display_none.cpp)
endif()
if(WIN32)
    set(game_client_loop src/client/app/client/viewer/viewer_win32.cpp src/client/app/client/viewer/cursors.cpp
        src/client/app/client/viewer/sdl_input.cpp)
else()
    set(game_client_loop src/client/app/client/viewer/viewer_none.cpp)
endif()
game_module(client_stage
    src/client/app/client/stage/stage.cpp
    src/client/app/client/stage/sky.cpp
    src/client/app/client/stage/props.cpp)
target_link_libraries(game_client_stage PUBLIC game_core game_xml game_scene)
game_module(client_world src/client/app/client/world/world.cpp)
target_link_libraries(game_client_world PUBLIC game_client_stage game_client_map game_io game_nav game_fs
    game_collision)
game_module(client_display ${game_client_screen})
target_link_libraries(game_client_display PUBLIC game_core game_client_stage game_client_map
    game_client_world game_control)
if(GAME_HAS_GPU)
    target_link_libraries(game_client_display PRIVATE game_gpu game_render game_capture
        game_avatar game_look game_motion game_ui game_fx game_classic)
endif()
game_module(client_viewer ${game_client_loop})
target_link_libraries(game_client_viewer PUBLIC game_core game_client_stage
    PRIVATE game_client_display)
if(WIN32)
    find_package(SDL3 CONFIG REQUIRED)
    target_link_libraries(game_client_viewer PRIVATE game_window SDL3::SDL3 game_client_online game_client_session)
    # Thư mục include chung của vcpkg tới đây dưới dạng -I, nên Clang -Werror bắt cả SDL_bits.h
    # (ép kiểu kiểu C). Khai lại là SYSTEM: Clang giữ bản system khi một thư mục có cả hai.
    get_target_property(game_sdl_include SDL3::Headers INTERFACE_INCLUDE_DIRECTORIES)
    if(game_sdl_include)
        target_include_directories(game_client_viewer SYSTEM PRIVATE ${game_sdl_include})
    endif()
    target_link_libraries(game_client_viewer PUBLIC game_audio)
endif()
game_module(client src/client/app/client/options.cpp src/client/app/client/assets.cpp src/client/app/client/boot.cpp)
target_link_libraries(game_client PUBLIC game_core game_io game_client_map game_client_world)

# iOS: điểm vào UIKit. Chưa build trên máy này (không có macOS). Android giữ main.cpp cho exe adb;
# APK là thư viện riêng bên dưới.
if(IOS)
    add_executable(thienlong_client src/client/app/client/ios_main.mm src/client/app/client/mobile_probe.cpp)
else()
    add_executable(thienlong_client src/client/app/client/main.cpp)
endif()
if(WIN32)
    # Icon của exe, dịch trong một target riêng không có thư mục include nào. windres của MinGW đưa
    # -I cho bộ tiền xử lý mà không bọc nháy, nên thư mục có dấu cách (chính đường dẫn dự án) làm
    # nó dừng. app.rc không include gì; đường dẫn icon trong đó tính từ chỗ tệp .rc.
    add_library(thienlong_client_icon OBJECT src/client/app/client/app.rc)
    target_sources(thienlong_client PRIVATE $<TARGET_OBJECTS:thienlong_client_icon>)
endif()
target_link_libraries(thienlong_client PRIVATE game_client game_client_viewer game_client_stage
    game_io game_scene game::warnings)
if(TARGET game_client_shaders)
    add_dependencies(thienlong_client game_client_shaders)
endif()
if(IOS)
    target_link_libraries(thienlong_client PRIVATE "-framework UIKit" "-framework Foundation"
        "-framework WebKit" game_audio)
    target_sources(thienlong_client PRIVATE
        "${PROJECT_SOURCE_DIR}/apple/LaunchScreen.storyboard"
        "${PROJECT_SOURCE_DIR}/apple/PrivacyInfo.xcprivacy")
    set_source_files_properties(
        "${PROJECT_SOURCE_DIR}/apple/LaunchScreen.storyboard"
        "${PROJECT_SOURCE_DIR}/apple/PrivacyInfo.xcprivacy"
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
endif()
game_split_debug(thienlong_client)
# PC vào <prefix>/client/bin. Bundle iOS vào <prefix>/client/IOS. APK vào <prefix>/client/APK.
install(TARGETS thienlong_client RUNTIME DESTINATION client/bin BUNDLE DESTINATION client/IOS)
# Bản địa hoá (chữ, tên cảnh, ảnh thay) dựng cùng client từ assets/i18n.
include(cmake/GameI18n.cmake)
# Script giao diện gốc và sổ cửa sổ (src/client/script) vào dev/client/assets/Script, nơi ui/script đọc lúc chạy, ở mỗi
# lượt dựng client (công cụ bỏ qua tệp không đổi). GAME_SCRIPTS_STAMP chỉ ghi lại khi bản trong dữ liệu đổi: bước đóng APK
# khai nó làm đầu vào như GAME_I18N_STAMP.
if(Python3_Interpreter_FOUND)
    set(GAME_SCRIPTS_STAMP "${PROJECT_SOURCE_DIR}/build/scripts/staged.stamp")
    add_custom_target(thienlong_scripts ALL
        COMMAND ${CMAKE_COMMAND} -E env PYTHONUTF8=1 "${Python3_EXECUTABLE}" -B
            TOOLS/content/stage_scripts.py src/client/script dev/client/assets --stamp "${GAME_SCRIPTS_STAMP}"
        BYPRODUCTS "${GAME_SCRIPTS_STAMP}"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
        COMMENT "script: đưa script giao diện vào dev/client/assets/Script"
        VERBATIM)
    add_dependencies(thienlong_client thienlong_scripts)
endif()
# iOS chỉ chạy được exe nằm trong gói ứng dụng. Chưa build trên macOS (máy phát triển là Windows).
if(IOS)
    set_target_properties(thienlong_client PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER vn.thienlong.client
        MACOSX_BUNDLE_BUNDLE_NAME "Thiên Long Bát Bộ"
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
        MACOSX_BUNDLE_INFO_PLIST "${PROJECT_SOURCE_DIR}/apple/Info.plist.in")
    # Cùng dữ liệu và gói .f2s với bản PC. resourcePath/data là chỗ ios_main đọc. Gói do Windows dựng:
    # trên máy Apple chép thư mục shaders của cây PC sang và đặt GAME_IOS_SHADERS.
    game_device_shaders(GAME_IOS_SHADERS
        "Gói .f2s đóng vào bundle iOS. Mặc định là shaders của cây dựng PC đang dùng.")
    if(NOT EXISTS "${GAME_IOS_SHADERS}/model.vs.f2s" OR NOT EXISTS "${GAME_IOS_SHADERS}/model.ps.f2s")
        message(FATAL_ERROR
            "Thiếu gói shader tại ${GAME_IOS_SHADERS}. Dựng bản PC (thienlong_client) trên Windows rồi "
            "chép thư mục build/<preset>/shaders sang và đặt -DGAME_IOS_SHADERS=<thư mục đó>.")
    endif()
    add_custom_command(TARGET thienlong_client POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E env PYTHONUTF8=1
            python "${PROJECT_SOURCE_DIR}/android/package_apk.py"
            --stage "$<TARGET_BUNDLE_CONTENT_DIR:thienlong_client>/data"
            --data "${PROJECT_SOURCE_DIR}/dev/client/assets"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${GAME_IOS_SHADERS}"
            "$<TARGET_BUNDLE_CONTENT_DIR:thienlong_client>/data/shaders"
        COMMENT "Chép cảnh startup.id và shader PC vào bundle iOS")
endif()

# APK NativeActivity: cùng Display với bản PC (Vulkan 1.3, rồi GLES). Glue của NDK là C,
# không qua cổng cảnh báo của dự án. Exe thienlong_client vẫn để ctest đẩy qua adb.
# Gói shader lấy từ cây dựng PC (cache GAME_ANDROID_SHADERS, tự chọn cây có đủ gói).
# --data trỏ cả assets/client; package_apk.py chỉ đóng cảnh của Config/startup.id.
if(ANDROID)
    enable_language(C)
    set(game_glue "${ANDROID_NDK}/sources/android/native_app_glue")
    add_library(android_native_app_glue STATIC "${game_glue}/android_native_app_glue.c")
    target_include_directories(android_native_app_glue PUBLIC "${game_glue}")
    set_property(TARGET android_native_app_glue PROPERTY COMPILE_WARNING_AS_ERROR OFF)
    add_library(thienlong_activity SHARED
        src/client/app/client/android_main.cpp
        src/client/app/client/mobile_probe.cpp)
    target_include_directories(thienlong_activity PRIVATE "${game_glue}")
    target_compile_features(thienlong_activity PRIVATE cxx_std_23)
    target_link_libraries(thienlong_activity PRIVATE
        game_client game_client_display game_client_stage game_client_world game_client_map game_io
        game_audio android_native_app_glue android log game::warnings)
    set_target_properties(thienlong_activity PROPERTIES OUTPUT_NAME thienlong)
    target_link_options(thienlong_activity PRIVATE "-u" "ANativeActivity_onCreate")
    set(game_apk "${CMAKE_BINARY_DIR}/thienlong.apk")
    # Mặc định là shader của cây dựng PC đang dùng (cmake/GameDeviceShaders.cmake). Đặt
    # GAME_ANDROID_SHADERS khi muốn đóng gói của cây khác. Thiếu model.vs.f2s thì package_apk.py từ
    # chối đóng.
    game_device_shaders(GAME_ANDROID_SHADERS
        "Thư mục gói .f2s đóng vào APK. Mặc định là shaders của cây dựng PC đang dùng.")
    set(game_apk_assets
        --data "${PROJECT_SOURCE_DIR}/dev/client/assets"
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
            python "${PROJECT_SOURCE_DIR}/android/package_apk.py"
            --library "$<TARGET_FILE:thienlong_activity>"
            --abi "${ANDROID_ABI}"
            --manifest "${PROJECT_SOURCE_DIR}/android/AndroidManifest.xml"
            --out "${game_apk}"
            --depfile "${game_apk}.d"
            ${game_apk_assets}
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_INSTALL_PREFIX}/client/APK"
        COMMAND ${CMAKE_COMMAND} -E copy "${game_apk}" "${CMAKE_INSTALL_PREFIX}/client/APK/thienlong.apk"
        DEPENDS thienlong_activity
            "${PROJECT_SOURCE_DIR}/android/package_apk.py"
            "${PROJECT_SOURCE_DIR}/android/AndroidManifest.xml"
            "${GAME_ANDROID_SHADERS}/model.vs.f2s"
            "${GAME_ANDROID_SHADERS}/model.ps.f2s"
            # Mốc của bước i18n (cmake/GameI18n.cmake; rỗng khi không có Python): APK đóng sau khi
            # chữ và ảnh của ngôn ngữ đã chọn nằm trong assets/client, và đóng lại khi chúng đổi.
            ${GAME_I18N_STAMP}
            # Mốc của bước đưa script giao diện (thienlong_scripts; rỗng khi không có Python).
            ${GAME_SCRIPTS_STAMP}
        # Dữ liệu đóng vào APK (danh sách cảnh, từng tệp, thư mục đã quét) do package_apk.py tự kê:
        # tệp nào đổi thì APK đóng lại.
        DEPFILE "${game_apk}.d"
        COMMENT "Đóng thienlong.apk"
        VERBATIM)
    add_custom_target(thienlong_apk ALL DEPENDS "${game_apk}")
endif()

# Mỗi header thành một .cpp include nó hai lần (tự đủ + #pragma once, KTR-03).
file(GLOB_RECURSE game_headers CONFIGURE_DEPENDS
    ${PROJECT_SOURCE_DIR}/engine/*.hpp
    ${PROJECT_SOURCE_DIR}/src/client/*.hpp
    ${PROJECT_SOURCE_DIR}/src/server/*.hpp
    ${PROJECT_SOURCE_DIR}/src/shared/*.hpp)
# Header của module không dựng trong cấu hình này không vào header_check: chúng cần gói vcpkg và
# Vulkan SDK mà cấu hình ấy không có (xem GAME_HAS_GPU ở trên).
if(NOT GAME_HAS_GPU)
    list(FILTER game_headers EXCLUDE REGEX "/engine/(fs|shader|gpu|render|resource)/")
endif()
# Backend D3D chỉ có trên Windows: header của nó đòi d3d11.h/d3d12.h và wrl/client.h của Windows SDK.
if(NOT WIN32)
    list(FILTER game_headers EXCLUDE REGEX "/engine/gpu/d3d1[12]/")
    list(FILTER game_headers EXCLUDE REGEX "/engine/gpu/com\\.hpp$")
endif()
if(NOT GAME_HAS_MATH)
    list(FILTER game_headers EXCLUDE REGEX "/engine/math/")
endif()
# capture chỉ có target trên Windows (xem khối jobs); ngoài Windows header của nó không vào
# header_check. render/target.hpp chưa có target (target kéo capture). library.hpp là nạp lại lúc
# chạy, công cụ shader không dựng nó. shadertool không có header.
if(NOT WIN32)
    list(FILTER game_headers EXCLUDE REGEX "/engine/capture/")
endif()
# Mã máy chủ không dựng cho client di động, hoặc khi thiếu header của tomlplusplus.
if(NOT TARGET game_service)
    list(FILTER game_headers EXCLUDE REGEX "/src/server/(config|process|supervise|service|linttool)/")
endif()
# protocol và net chỉ dựng cho máy tính (khối NOT CMAKE_CROSSCOMPILING của hai module).
if(NOT TARGET game_net)
    list(FILTER game_headers EXCLUDE REGEX "/(src/shared/protocol|engine/net)/")
endif()
list(FILTER game_headers EXCLUDE REGEX "/engine/render/target\\.hpp$")
list(FILTER game_headers EXCLUDE REGEX "/engine/shader/library\\.hpp$")
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
# Mỗi tệp Test/<domain>/<tên>_tests.cpp là một exe test; đối số sau tên là các module nó cần.
function(game_test name)
    file(GLOB game_test_source "${CMAKE_CURRENT_SOURCE_DIR}/Test/*/${name}_tests.cpp")
    if(NOT game_test_source)
        message(STATUS "Thiếu test ${name}, bỏ ${name}_tests")
        return()
    endif()
    list(LENGTH game_test_source game_test_count)
    if(NOT game_test_count EQUAL 1)
        message(FATAL_ERROR "test ${name} có nhiều tệp: ${game_test_source}")
    endif()
    cmake_path(GET game_test_source PARENT_PATH game_test_dir)
    add_executable(${name}_tests ${game_test_source})
    target_include_directories(${name}_tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Test" "${game_test_dir}")
    target_link_libraries(${name}_tests PRIVATE ${ARGN} game::warnings)
    add_test(NAME ${name}_tests COMMAND ${name}_tests)
endfunction()
game_test(fx game_fx)
# Thư viện chuẩn và máy ảo của game_luaplus so với LuaPlus.dll của client 2026 (số vàng do TOOLS/port/lua_rt_golden.py sinh).
# Thiết bị Android không thấy cây nguồn nên ca số vàng ở đó tự bỏ qua.
game_test(lua_golden game_luaplus game_io)
# Vỏ lua::State: trần bộ nhớ, trần lệnh, trần độ sâu, traceback, native an toàn, và script ProgressBar thật của client 2026.
game_test(lua_shell game_lua game_io)
if(TARGET lua_shell_tests)
    # State đóng mà bộ đếm còn byte là rò bộ nhớ của LuaPlus: vỏ chỉ ghi log lỗi, test thì coi là đỏ.
    set_tests_properties(lua_shell_tests PROPERTIES FAIL_REGULAR_EXPRESSION "chưa trả về bộ cấp phát")
    if(NOT ANDROID)
        target_compile_definitions(lua_shell_tests PRIVATE GAME_SCRIPT_ROOT="${PROJECT_SOURCE_DIR}/src/client/script")
    endif()
endif()
if(NOT ANDROID AND TARGET lua_golden_tests)
    target_compile_definitions(lua_golden_tests PRIVATE GAME_LUA_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden/lua")
endif()
game_test(io game_io)
game_test(xml game_xml)
game_test(audio game_audio)
game_test(audio_dsp game_audio)
if(TARGET game_seal)
    game_test(seal game_seal)
endif()
# Đường dẫn dữ liệu là của máy dựng: test chạy trên thiết bị Android không thấy nó, và bản checkout
# mới chưa có assets/client (thư mục không vào git). Ở cả hai nơi các ca đọc tệp thật tự bỏ qua
# (audio, map) hoặc test không được đăng ký (giao diện, phông).
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/sound/sound_table.xml")
    target_compile_definitions(audio_tests PRIVATE
        "GAME_CLIENT_DATA=\"${PROJECT_SOURCE_DIR}/dev/client/assets\"")
endif()
game_test(scene game_scene)
game_test(map game_client_map)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Config/ScenePosDefineEx.txt")
    target_compile_definitions(map_tests PRIVATE
        "GAME_CLIENT_DATA=\"${PROJECT_SOURCE_DIR}/dev/client/assets\"")
endif()
game_test(world game_client_world)
game_test(transform game_scene)
game_test(client game_client)
game_test(boot game_client)
game_test(props game_client_stage)
game_test(stage game_client_stage)
# core có bản POSIX nên test chạy trên Windows và trên thiết bị Android. Cửa sổ vẫn chỉ Windows.
if(WIN32 OR ANDROID)
    game_test(core game_core)
    game_test(log game_core)
    game_test(thread_slot game_core)
    game_test(function_fallback game_core)
endif()
# Test chép kèm mã từ Forge2 ở các bước B2, B3. Chỉ Windows: fs_tests dùng disk, file, watcher (bản
# Win32), shader_tests đi cùng chuỗi đồ hoạ; math_tests thuần nhưng chưa dựng thử cho Android.
if(WIN32 AND TARGET game_math)
    game_test(math game_math)
endif()
if(WIN32 AND TARGET game_fs)
    game_test(fs game_fs)
endif()
if(WIN32 AND TARGET game_shader)
    game_test(shader game_shader game_fs)
endif()
if(WIN32)
    game_test(window game_window)
    # Các ca vào vòng kéo thật của Windows. Luôn dựng, nhưng ctest chỉ chạy khi bật
    # GAME_DESKTOP_TESTS: vòng kéo đổi hình và vùng giam con trỏ chuột của cả phiên đăng nhập, người
    # đang dùng máy thấy con trỏ nháy (Test/window_modal_tests.cpp).
    option(GAME_DESKTOP_TESTS "ctest chạy cả test đụng tới con trỏ chuột của phiên Windows" OFF)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/Window/window_modal_tests.cpp")
        game_test(window_modal game_window)
    endif()
    if(TARGET window_modal_tests AND NOT GAME_DESKTOP_TESTS)
        set_tests_properties(window_modal_tests PROPERTIES DISABLED TRUE)
    endif()
endif()
# Test trên GPU thật qua backend Vulkan, lớp kiểm tra bật. Trên Android, gpu/resource_tests còn
# cần fs::write_file (fs/file của Forge2 là Win32) để ghi tệp tạm — chờ bản fs POSIX.
if(GAME_HAS_GPU AND NOT ANDROID)
    if(WIN32)
        game_test(gpu game_gpu user32)
    else()
        game_test(gpu game_gpu)
    endif()
    if(TARGET game_resource)
        game_test(resource game_resource)
        game_test(dds game_resource)
        game_test(ogre_mesh game_resource)
        if(EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Model")
            target_compile_definitions(ogre_mesh_tests PRIVATE
                GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
        endif()
        game_test(resource_upload game_resource)
        game_test(classic game_classic)
        game_test(shade game_render game_classic)
        game_test(rig game_avatar)
        target_compile_definitions(rig_tests PRIVATE
            GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
        # Kiểm trên dữ liệu thật của người chơi: chỉ đăng ký khi đã gom bằng TOOLS/content.
        if(EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Table/player_bodies.tsv")
            game_test(avatar_data game_avatar game_look game_io game_ui_panel)
            target_compile_definitions(avatar_data_tests PRIVATE
                GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
        endif()
    endif()
endif()
game_test(ogre game_ogre)
game_test(anim game_anim)
game_test(motion game_motion)
game_test(jump game_motion)
# Số vàng của nav do PathLib.dll gốc trả lời (TOOLS/port/pathlib_oracle.py). Đường dẫn là của máy
# dựng: test chạy trên thiết bị Android không thấy nó nên tự bỏ qua phần so số vàng.
game_test(nav game_nav game_io)
if(NOT ANDROID)
    target_compile_definitions(nav_tests PRIVATE GAME_NAV_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden")
    if(EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Scene/huoyangu.path")
        target_compile_definitions(nav_tests PRIVATE GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
    endif()
endif()
# collision (DE-BAI DH đợt 1, mục 4 và 5): collision_tests là bộ đọc trên byte tự dựng, số vàng của PathLib.dll gốc
# (so-do/b-dinh-dang-tsv.md) và 435 tệp thật; collision_alloc_tests là G3 (Test/collision_hostile.hpp), H1, H2.
# Thứ tự dò byte nguồn số vàng: dòng file, rồi GAME_CLIENT_DATA/Scene/<cảnh>.WCollision, rồi
# GAME_RAW_SCENE/<cảnh>.WCollision (lingxingfeng, xihu_Valentine đọc GAME_CLIENT_DATA rồi GAME_RAW_SCENE trước);
# không có gì thì trả 77. Chưa có Model của C cũng trả 77 (CTest báo Skipped); ca hỏng vẫn trả 1. Đường dẫn là của
# máy dựng nên Android tự bỏ qua.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/Collision/collision_tests.cpp")
    game_test(collision game_collision)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/Collision/collision_alloc_tests.cpp")
    game_test(collision_alloc game_collision)
endif()
# Tệp .WCollision thật nằm ngoài dự án, nên không có mặc định nào trỏ ra ngoài cây nguồn: lấy thư mục _raw
# từ biến môi trường THIENLONG_RAW_ROOT (cùng quy ước với các test dữ liệu thật của máy chủ), hoặc cấu hình
# với -DGAME_RAW_SCENE=<_raw>/Scene. Không có thì các ca cần tệp thật trả 77.
set(game_raw_scene_default "")
if(DEFINED ENV{THIENLONG_RAW_ROOT})
    file(TO_CMAKE_PATH "$ENV{THIENLONG_RAW_ROOT}/Scene" game_raw_scene_default)
endif()
set(GAME_RAW_SCENE "${game_raw_scene_default}" CACHE PATH "Thư mục .WCollision thật cho collision_tests")
if(TARGET collision_tests AND NOT ANDROID)
    target_compile_definitions(collision_tests PRIVATE GAME_COLLISION_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden")
    if(EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Scene/huoyangu.path")
        target_compile_definitions(collision_tests PRIVATE GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
    endif()
endif()
if(TARGET collision_tests AND NOT ANDROID AND IS_DIRECTORY "${GAME_RAW_SCENE}")
    target_compile_definitions(collision_tests PRIVATE GAME_COLLISION_SCENE="${GAME_RAW_SCENE}"
        GAME_COLLISION_COUNTS="${PROJECT_SOURCE_DIR}/docs/giao-viec/DH-DOT-1/so-do/b-t1-tep-2.tsv")
endif()
if(TARGET collision_tests AND TARGET collision_alloc_tests)
    set_tests_properties(collision_tests collision_alloc_tests PROPERTIES SKIP_RETURN_CODE 77)
endif()
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/Collision/collision_fuzz_tests.cpp")
    game_test(collision_fuzz game_collision)
endif()
# collision_model_tests (C, B3): lưới sau nạp và cây OPCODE của Model; chốt cây với Test/golden/collision_cay_*.tsv
# (bianjing theo #sha256_day_du, bản đầy đủ ở build/vang nếu có). Thiếu .WCollision thật thì trả 77.
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/Collision/collision_model_tests.cpp")
    game_test(collision_model game_collision)
endif()
if(TARGET collision_model_tests AND NOT ANDROID)
    target_compile_definitions(collision_model_tests PRIVATE GAME_COLLISION_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden")
    if(IS_DIRECTORY "${GAME_RAW_SCENE}")
        target_compile_definitions(collision_model_tests PRIVATE GAME_COLLISION_SCENE="${GAME_RAW_SCENE}")
    endif()
    if(IS_DIRECTORY "${PROJECT_SOURCE_DIR}/build/vang")
        target_compile_definitions(collision_model_tests PRIVATE GAME_COLLISION_VANG="${PROJECT_SOURCE_DIR}/build/vang")
    endif()
endif()
if(TARGET collision_model_tests)
    set_tests_properties(collision_model_tests PROPERTIES SKIP_RETURN_CODE 77)
endif()
game_test(building_height game_collision)
game_test(table_localize game_table)
game_test(table_tsv game_table)
game_test(look game_look)
game_test(head game_look)
game_test(avatar game_avatar)
game_test(control game_control)
game_test(pilot game_control)
game_test(touch game_control)
game_test(hero game_hero)
# Bộ lọc nhiệm vụ nhận được; ca trên bảng thật chỉ dịch khi đã xuất bảng bằng export_config.py.
game_test(quest game_quest game_io)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Table/mission_outline.tsv")
    target_compile_definitions(quest_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
# Bảng, sách kỹ năng và hệ action của sách võ công; ca trên bảng thật chỉ dịch khi đã xuất đủ tám
# bảng bằng export_config.py (bảy bảng, formation_levels.tsv là bảng mới nhất) và export_icons.py.
game_test(skill game_skill game_io)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Table/life_skill_levels.tsv"
        AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Table/formation_levels.tsv"
        AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Table/icons.tsv")
    target_compile_definitions(skill_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
game_test(gui_value game_gui)
game_test(gui_loader game_gui)
game_test(gui_sheet game_gui)
game_test(gui_scroll game_gui)
game_test(gui_softkey game_gui)
# Nội dung các bảng của ui/panel: logic thuần chạy ở mọi nơi; ca đối chiếu tên cửa sổ với layout
# thật chỉ dịch khi đã gom dữ liệu giao diện.
game_test(ui_board game_ui_panel)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/Schema/WoWLookSkin.scheme.xml")
    target_compile_definitions(ui_board_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
# Trạng thái giữ lại của cửa sổ một bảng (bảng port từ script lái bằng sự kiện).
game_test(ui_widgets game_ui_panel)
# Bảng nhiệm vụ: so với trạng thái mà script gốc để lại trên LuaPlus.dll của client 2026 (số vàng do
# TOOLS/port/lua_oracle.py sinh). Thiết bị Android không thấy cây nguồn nên ở đó ca số vàng tự bỏ qua.
game_test(ui_quest game_ui_panel game_io)
game_test(ui_quest_book game_ui_panel game_io)
if(NOT ANDROID)
    target_compile_definitions(ui_quest_tests PRIVATE
        GAME_PANEL_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden/panel")
endif()
# Bảng nhập tài khoản của thủ tục đăng nhập; ca đối chiếu layout thật chỉ dịch khi đã gom layout đó.
game_test(ui_logon game_ui_panel)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/Logon/LogOn.layout.xml")
    target_compile_definitions(ui_logon_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
game_test(ui_role game_ui_panel)
game_test(ui_select game_ui_panel)
# Bảng tạo nhân vật: so với trạng thái mà CreateRole.lua gốc để lại trên LuaPlus.dll của client 2026
# với bảng thật của assets/client/Table (số vàng do TOOLS/port/lua_oracle.py sinh); ca đó chỉ chạy khi
# bản dựng thấy cả thư mục số vàng lẫn dữ liệu client.
game_test(ui_create game_ui_panel game_io)
if(NOT ANDROID)
    target_compile_definitions(ui_create_tests PRIVATE
        GAME_PANEL_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden/panel")
endif()
# Widget của script giao diện trên LuaPlus thật; ca cuối chạy ProgressBar.lua gốc và so với số vàng (suy src/client/script
# từ thư mục số vàng). Thiết bị Android không thấy cây nguồn nên ca đó tự bỏ qua.
game_test(ui_script_widget game_ui_script game_io)
if(NOT ANDROID AND TARGET ui_script_widget_tests)
    target_compile_definitions(ui_script_widget_tests PRIVATE
        GAME_PANEL_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden/panel")
endif()
# Phần chủ: luật gửi, nhường chỗ, hẹn giờ trên script thử viết trong test; ca cuối chạy ProgressBar.lua gốc qua host (cần layout
# đã gom và cây nguồn, nên chỉ có trên máy dựng).
game_test(ui_script_host game_ui_script game_gui game_io)
if(NOT ANDROID AND TARGET ui_script_host_tests
        AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/ProgressBar/ProgressBar.layout.xml")
    target_compile_definitions(ui_script_host_tests PRIVATE
        GAME_PANEL_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden/panel"
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets"
        GAME_SCRIPT_SOURCE="${PROJECT_SOURCE_DIR}/src/client/script")
endif()
# Script gốc của các cửa sổ HUD đã có bản port tay, chạy qua host và widget thật bằng kịch bản của trọng tài (TOOLS/port/oracle) và so
# với số vàng của bản port tay (Test/golden/panel). Cần layout đã gom và cây nguồn, nên chỉ có trên máy dựng.
game_test(ui_script_golden game_ui_script game_gui game_io)
if(NOT ANDROID AND TARGET ui_script_golden_tests
        AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/ProgressBar/ProgressBar.layout.xml")
    target_compile_definitions(ui_script_golden_tests PRIVATE
        GAME_PANEL_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden/panel"
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets"
        GAME_SCRIPT_SOURCE="${PROJECT_SOURCE_DIR}/src/client/script")
endif()
# Hàm game của script giao diện (tầng B): chạy đoạn Lua thật trên máy LuaPlus trần có open_natives.
game_test(ui_script_natives game_ui_script)
# XSCRIPT và XParam (tầng B): bản ghi gửi máy chủ và bản ghi tham số của sự kiện, qua hàm Lua thật.
game_test(ui_script_xscript game_ui_script)
# Lượt chạy hàng loạt (không phải test): mở cả sổ cửa sổ, hiện/giấu từng cửa sổ và kê hàm game, phương thức widget mà script
# đòi mà client chưa có, để xếp việc cho tầng B và widget (Test/bench/ui_script_survey.cpp).
if(NOT ANDROID AND NOT IOS AND TARGET game_ui_script)
    add_executable(ui_script_survey Test/bench/ui_script_survey.cpp)
    target_link_libraries(ui_script_survey PRIVATE game_ui_script game_gui game_io game::warnings)
endif()
# Bảng port từ script Lua của client 2026 (đợt UI-PORT): test so trạng thái cửa sổ với số vàng của
# TOOLS/port/lua_oracle.py. Thiết bị Android không thấy cây nguồn nên ca số vàng ở đó tự bỏ qua.
function(game_panel_golden_test name)
    game_test(${name} game_ui_panel game_io)
    if(NOT ANDROID)
        target_compile_definitions(${name}_tests PRIVATE
            GAME_PANEL_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden/panel")
    endif()
endfunction()
game_panel_golden_test(ui_main_menu_bar_3)
game_panel_golden_test(ui_main_menu_bar_4)
game_panel_golden_test(ui_main_menu_bar_2)
game_panel_golden_test(ui_function_bar_right)
game_panel_golden_test(ui_function_bar_right_2)
game_test(ui_call_events game_ui_panel)
game_panel_golden_test(ui_lua_value)
game_panel_golden_test(ui_progress_bar)
game_panel_golden_test(ui_debug_list_box)
game_test(ui_flow game_ui_panel)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/SelectRole/SelectRole.layout.xml")
    target_compile_definitions(ui_select_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/CreateRole/CreateRole.layout.xml")
    target_compile_definitions(ui_create_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
# Bàn phím ảo của thủ tục đăng nhập; ca đối chiếu layout thật chỉ dịch khi đã gom layout đó.
game_test(ui_softkey game_ui_panel)
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/SoftKeyBoard/SoftKeyBoard.layout.xml")
    target_compile_definitions(ui_softkey_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
# Kiểm trên dữ liệu giao diện thật: chỉ đăng ký khi đã gom bằng TOOLS/content/collect_ui.py.
if(NOT ANDROID AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/Schema/WoWLookSkin.scheme.xml")
    game_test(gui_real game_gui)
    # Danh sách, thanh cuộn, cửa sổ phức hợp trên layout thật của bảng nhiệm vụ.
    game_test(gui_widgets game_gui)
    target_compile_definitions(gui_widgets_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
    game_test(ui_panel game_ui_panel game_io)
    target_compile_definitions(ui_panel_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
    target_compile_definitions(gui_real_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets"
        GAME_UI_GOLDEN="${PROJECT_SOURCE_DIR}/Test/golden")
endif()
# Camera dựng ma trận bằng math và render/camera.cpp; chỉ cần module render, không cần GPU thật.
if(TARGET game_render)
    game_test(camera game_render)
    game_test(catalog game_render)
endif()
if(TARGET game_ui AND NOT ANDROID
        AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface/Schema/VTNAM14.bin")
    game_test(ui_text game_ui)
    target_compile_definitions(ui_text_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
    game_test(pace game_ui)
    target_compile_definitions(pace_tests PRIVATE
        GAME_CLIENT_DATA="${PROJECT_SOURCE_DIR}/dev/client/assets")
endif()
# lua_oracle: LuaPlus dựng từ third_party/luaplus (DLL cùng nguồn cùng cờ với game_luaplus) chạy 2 060 đơn vị giao diện cùng
# thế giới giả world.lua; vết phải trùng sha256 với bảng vàng của LuaPlus.dll trong client 2026. Chứng minh bản dựng của dự
# án (trình dịch, cờ, CRT) không làm lệch hành vi của máy gốc. Cần layout giao diện đã gom ở dev/client/assets/Interface.
if(TARGET luaplus_oracle AND NOT CMAKE_CROSSCOMPILING AND EXISTS "${PROJECT_SOURCE_DIR}/dev/client/assets/Interface")
    find_package(Python3 COMPONENTS Interpreter)
    if(Python3_Interpreter_FOUND)
        # Số của LuaPlus (định dạng, strtod, rand, ép số nguyên) đi qua module luanum nên chuỗi NaN ("-1.#IND") khớp MSVCR110 của
        # DLL gốc, không còn đơn vị nào được phép lệch.
        add_test(NAME lua_oracle
            COMMAND ${Python3_EXECUTABLE} -B TOOLS/port/luagen/mass_oracle.py $<TARGET_FILE_DIR:luaplus_oracle>
                --traces ${CMAKE_BINARY_DIR}/luagen/oracle --check Test/golden/lua_mass/oracle.tsv
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
        set_tests_properties(lua_oracle PROPERTIES ENVIRONMENT "PYTHONUTF8=1")
    endif()
endif()
# Include ngược tầng: bảng ở cmake/GameLayers.cmake (KTR-15).
add_test(NAME layers COMMAND ${CMAKE_COMMAND} -DGAME_SOURCE_DIR=${PROJECT_SOURCE_DIR}
         -P ${PROJECT_SOURCE_DIR}/cmake/GameLayers.cmake)
game_test(content game_content)
if(TARGET game_service)
    game_test(config game_config game_io)
    target_compile_definitions(config_tests PRIVATE
        "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/dev/server/config\"")
    game_test(process game_process game_io)
    add_dependencies(process_tests thienlong_test_child)
    game_test(supervise game_supervise)
    # Hai test dưới chạy exe thật nằm cạnh chúng, không PostgreSQL. Chúng chép cấu hình thật vào
    # cây dựng và cho mọi cổng nghe là 127.0.0.1:0 (Test/support/loopback_config.hpp): hệ điều hành
    # cấp cổng, tiến trình báo cổng thật ở dòng ready, nên hai lượt ctest chạy cùng lúc không tranh cổng.
    set(game_server_programs thienlong_server thienlong_store thienlong_auth thienlong_billing
        thienlong_world thienlong_zone thienlong_gate)
    game_test(service game_service game_io game_process)
    target_compile_definitions(service_tests PRIVATE
        "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/dev/server/config\"")
    add_dependencies(service_tests ${game_server_programs})
    add_executable(server_boot Test/Service/server_boot_tests.cpp)
    target_include_directories(server_boot PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Test" "${CMAKE_CURRENT_SOURCE_DIR}/Test/Service")
    target_link_libraries(server_boot PRIVATE game_process game_io game::warnings)
    target_compile_definitions(server_boot PRIVATE
        "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/dev/server/config\"")
    add_dependencies(server_boot ${game_server_programs})
    add_test(NAME server_boot COMMAND server_boot)
    # Ca B của nợ (a): chạy lại trọn server_boot rồi so dev/server/data/gate của cây nguồn trước và sau.
    add_executable(server_boot_source_clean Test/Service/server_boot_source_tests.cpp)
    target_include_directories(server_boot_source_clean PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Test" "${CMAKE_CURRENT_SOURCE_DIR}/Test/Service")
    target_link_libraries(server_boot_source_clean PRIVATE game_process game_io game::warnings)
    target_compile_definitions(server_boot_source_clean PRIVATE
        "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/dev/server/config\"")
    add_dependencies(server_boot_source_clean server_boot)
    add_test(NAME server_boot_source_clean COMMAND server_boot_source_clean)
    # Hai test cùng chạy server_boot trên một thư mục tạm cạnh exe: trong một lượt ctest không chạy
    # cùng lúc.
    set_tests_properties(server_boot server_boot_source_clean PROPERTIES RESOURCE_LOCK server_boot_stage)
endif()
# Lint cả cây dữ liệu thật. tables/shared là bảng xuất từ client: git bỏ qua, build_data.py sinh ra.
# Bản checkout chưa sinh dữ liệu thì dòng refs không có bảng để đối chiếu, nên test chưa đăng ký.
if(TARGET thienlong_lint AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/shared")
    add_test(NAME server_data_lint COMMAND thienlong_lint
        --root "${PROJECT_SOURCE_DIR}/dev/server"
        --refs "${PROJECT_SOURCE_DIR}/TOOLS/server/refs")
elseif(TARGET thienlong_lint)
    message(STATUS "chưa có dev/server/tables/shared: bỏ test server_data_lint, sinh bằng build_data.py")
endif()
# P2 đợt 2: test của protocol và net, chỉ ở máy tính như hai module. wire_loop ghép hai module qua
# loopback thật; protocol_catalog_fresh báo khi tệp sinh cũ hơn bảng danh mục.
if(TARGET game_net)
    game_test(protocol game_protocol)
    game_test(link game_link)
    # Phiên mạng của client và cầu nối với giao diện; chạy với máy chủ giả loopback (Test/support/fake_gate.hpp).
    if(TARGET game_client_session)
        game_test(session_logic game_client_session)
        game_test(session game_client_session)
        game_test(online game_client_online)
    endif()
    game_test(guard game_guard)
    if(TARGET game_account)
        game_test(account game_account)
    endif()
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/Protocol/protocol_channel_tests.cpp")
        game_test(protocol_channel game_protocol)
    endif()
    game_test(protocol_catalog game_protocol)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/Protocol/protocol_fuzz_tests.cpp")
        game_test(protocol_fuzz game_protocol)
    endif()
    game_test(net game_net)
    game_test(metrics game_metrics)
    game_test(metrics_serve game_metrics_serve)
    game_test(wire_loop game_protocol game_net)
    # Exe đo của mục 7 (Đ1 tới Đ3): dựng cùng mọi target, không đăng ký vào ctest.
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/bench/protocol_bench.cpp")
        add_executable(protocol_bench Test/bench/protocol_bench.cpp)
        target_include_directories(protocol_bench PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Test" "${CMAKE_CURRENT_SOURCE_DIR}/Test/Protocol")
        target_link_libraries(protocol_bench PRIVATE game_protocol game::warnings)
    else()
        message(STATUS "Thiếu Test/bench/protocol_bench.cpp, bỏ protocol_bench")
    endif()
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/bench/net_bench.cpp")
        add_executable(net_bench Test/bench/net_bench.cpp)
        target_include_directories(net_bench PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Test" "${CMAKE_CURRENT_SOURCE_DIR}/Test/Net")
        target_link_libraries(net_bench PRIVATE game_protocol game_net game::warnings)
    else()
        message(STATUS "Thiếu Test/bench/net_bench.cpp, bỏ net_bench")
    endif()
    # Tấn công thật vào gate + auth + store đang chạy; chỉ Windows, không vào ctest.
    if(WIN32 AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/bench/gate_attack.cpp")
        add_executable(gate_attack Test/bench/gate_attack.cpp)
        target_link_libraries(gate_attack PRIVATE game_secure game_protocol ws2_32 psapi)
    endif()
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Test/bench/core_bench.cpp")
        add_executable(core_bench Test/bench/core_bench.cpp)
        target_include_directories(core_bench PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/Test")
        target_link_libraries(core_bench PRIVATE game_net game::warnings)
    endif()
    game_test(secure game_secure)
    file(GLOB game_server_test_files CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/cmake/server/*.tests.cmake")
    foreach(game_server_test_file IN LISTS game_server_test_files)
        include("${game_server_test_file}")
    endforeach()
    if(TARGET game_gate)
        game_test(gate game_gate)
        game_test(gate_motion game_gate)
        game_test(gate_loop game_gate game_supervise game_process game_io)
        target_compile_definitions(gate_loop_tests PRIVATE
            "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/dev/server/config\"")
        add_dependencies(gate_loop_tests thienlong_gate)
        if(WIN32 AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/TOOLS/server/gate_load.cpp")
            add_executable(thienlong_gate_load TOOLS/server/gate_load.cpp)
            target_link_libraries(thienlong_gate_load PRIVATE game_gate game_supervise game_process game_io
                psapi game::warnings)
            add_dependencies(thienlong_gate_load thienlong_gate)
        endif()
    endif()
    find_package(Python3 COMPONENTS Interpreter)
    if(Python3_Interpreter_FOUND)
        add_test(NAME protocol_catalog_fresh
            COMMAND ${Python3_EXECUTABLE} -B TOOLS/server/gen_protocol.py --check
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
        # Bố cục và chú thích của dev/server/config. Trước ngày 2026-10-08 không test nào chạy bộ kiểm
        # này: gate.toml lệch cột từ commit f74a41a mà ctest vẫn xanh.
        add_test(NAME server_config_lint
            COMMAND ${Python3_EXECUTABLE} -B TOOLS/server/lint_config.py
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
        # Bộ kiểm in tiếng Việt; stdout của ctest là ống nên Python phải ghi UTF-8.
        set_tests_properties(server_config_lint PROPERTIES ENVIRONMENT "PYTHONUTF8=1")
    endif()
endif()
