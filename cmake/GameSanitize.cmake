# cmake/GameSanitize.cmake
set(GAME_SANITIZE "" CACHE STRING "Sanitizer: address,undefined | thread | rỗng")
if(GAME_SANITIZE STREQUAL "")
    return()
endif()
# Khác mẫu: sanitizer của dự án chạy bằng Clang hoặc GCC; cl của MSVC không dùng các cờ dưới.
# cl of MSVC supports AddressSanitizer only (/fsanitize=address); UBSan/TSan need Clang or GCC.
# /Zi gives ASan symbolized stacks; /RTC* and incremental linking are incompatible with ASan.
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    if(NOT GAME_SANITIZE STREQUAL "address")
        message(FATAL_ERROR "cl only supports GAME_SANITIZE=address; use preset clang-asan for UBSan/TSan")
    endif()
    string(REGEX REPLACE "/RTC[1csu]+" "" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
    string(REGEX REPLACE "/RTC[1csu]+" "" CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
    add_compile_options(/fsanitize=address /Zi)
    add_link_options(/INCREMENTAL:NO /DEBUG)
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
