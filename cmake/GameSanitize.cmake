# cmake/GameSanitize.cmake
set(GAME_SANITIZE "" CACHE STRING "Sanitizer: address,undefined | thread | rỗng")
if(GAME_SANITIZE STREQUAL "")
    return()
endif()
# Khác mẫu: sanitizer của dự án chạy bằng Clang hoặc GCC; cl của MSVC không dùng các cờ dưới.
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    message(FATAL_ERROR "GAME_SANITIZE cần Clang hoặc GCC (preset clang-asan)")
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
