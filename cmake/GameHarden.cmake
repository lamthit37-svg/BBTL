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
# Khác mẫu: nhánh riêng cho cl của MSVC (Control Flow Guard, kiểm SDL, ASLR 64 bit, DEP).
if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    add_compile_options(/guard:cf /sdl)
    add_link_options(/guard:cf /DYNAMICBASE /HIGHENTROPYVA /NXCOMPAT)
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
# Khác mẫu: Mach-O của Apple không nhận các cờ -z của ELF.
if(APPLE)
    return()
endif()
# ELF: stack clash chỉ có ý nghĩa với stack tăng theo trang của Linux; RELRO, BIND_NOW, NX.
add_compile_options(-fstack-clash-protection)
add_link_options(LINKER:-z,relro LINKER:-z,now LINKER:-z,noexecstack)
