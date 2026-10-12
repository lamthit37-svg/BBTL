# cmake/GameDebugInfo.cmake
# Khác mẫu: cl của MSVC không nhận cờ kiểu GNU; bản Debug của nó đã ghi PDB nên không thêm gì.
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    return()
endif()
add_compile_options(
    -fno-omit-frame-pointer
    "$<$<CONFIG:Release>:-g>"
    "-ffile-prefix-map=${PROJECT_SOURCE_DIR}=.")
# build-id: ld của ELF và PE (MinGW). Clang nhắm MSVC liên kết bằng lld-link/link.exe, ghi PDB.
# Khác mẫu: ld của Apple không có --build-id (Mach-O luôn mang LC_UUID).
if(NOT CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC" AND NOT APPLE)
    add_link_options(LINKER:--build-id=sha1)
endif()
