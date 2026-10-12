# libsodium 1.0.22, tập nguồn để dịch. Cây autotools không chép theo. Giấy phép và mã băm ở NGUON.txt.
# Cờ theo G:\TLBB\Dev\third_party\libsodium\CMakeLists.txt (build.zig của upstream). Không sửa file .c.
cmake_minimum_required(VERSION 3.28)

if(NOT CMAKE_C_COMPILER_LOADED)
    set(paired "${CMAKE_CXX_COMPILER}")
    if(paired MATCHES "clang\\+\\+")
        string(REPLACE "clang++" "clang" paired "${paired}")
    elseif(paired MATCHES "g\\+\\+")
        string(REPLACE "g++" "gcc" paired "${paired}")
    endif()
    set(CMAKE_C_COMPILER "${paired}" CACHE FILEPATH "C cùng bộ với CXX" FORCE)
endif()
enable_language(C)

set(sodium_root "${CMAKE_CURRENT_SOURCE_DIR}/upstream")
file(GLOB_RECURSE sodium_sources CONFIGURE_DEPENDS "${sodium_root}/src/libsodium/*.c")
add_library(game_sodium STATIC ${sodium_sources})
target_compile_features(game_sodium PRIVATE c_std_11)

if(MSVC)
    target_compile_options(game_sodium PRIVATE /W0)
else()
    target_compile_options(game_sodium PRIVATE -w)
endif()

set(sodium_include "${CMAKE_CURRENT_BINARY_DIR}/include")
file(GLOB_RECURSE sodium_headers CONFIGURE_DEPENDS RELATIVE "${sodium_root}/src/libsodium/include"
    "${sodium_root}/src/libsodium/include/*.h")
foreach(header IN LISTS sodium_headers)
    configure_file("${sodium_root}/src/libsodium/include/${header}" "${sodium_include}/${header}"
        COPYONLY)
endforeach()
configure_file("${sodium_root}/builds/msvc/version.h" "${sodium_include}/sodium/version.h" COPYONLY)
target_include_directories(game_sodium SYSTEM PUBLIC "${sodium_include}")
target_include_directories(game_sodium PRIVATE "${sodium_include}/sodium")
target_compile_definitions(game_sodium PUBLIC SODIUM_STATIC
    PRIVATE CONFIGURED=1 NATIVE_LITTLE_ENDIAN=1)
if(NOT CMAKE_C_BYTE_ORDER STREQUAL "LITTLE_ENDIAN")
    message(FATAL_ERROR "libsodium: đích không phải little-endian")
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(game_sodium PRIVATE /UndefIntOverflow-)
    target_compile_definitions(game_sodium PRIVATE _CRT_SECURE_NO_WARNINGS)
elseif(MSVC)
    target_compile_options(game_sodium PRIVATE -fwrapv)
    target_compile_definitions(game_sodium PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
    target_compile_options(game_sodium PRIVATE -fvisibility=hidden -fno-strict-aliasing
        -fno-strict-overflow -fwrapv -flax-vector-conversions -Werror=vla)
    target_compile_definitions(game_sodium PRIVATE _GNU_SOURCE=1 HAVE_ATOMIC_OPS=1
        HAVE_C11_MEMORY_FENCES=1 HAVE_GCC_MEMORY_FENCES=1 HAVE_INLINE_ASM=1 HAVE_INTTYPES_H=1
        HAVE_STDINT_H=1 HAVE_TI_MODE=1)
endif()

if(ANDROID OR CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_compile_definitions(game_sodium PRIVATE HAVE_CLOCK_GETTIME=1 HAVE_GETPID=1
        HAVE_MADVISE=1 HAVE_MLOCK=1 HAVE_MMAP=1 HAVE_MPROTECT=1 HAVE_NANOSLEEP=1
        HAVE_POSIX_MEMALIGN=1 HAVE_PTHREAD=1 HAVE_PTHREAD_PRIO_INHERIT=1 HAVE_RAISE=1
        HAVE_SYSCONF=1 HAVE_SYS_AUXV_H=1 HAVE_SYS_MMAN_H=1
        HAVE_SYS_PARAM_H=1 HAVE_SYS_RANDOM_H=1 HAVE_WEAK_SYMBOLS=1 HAVE_CATCHABLE_ABRT=1
        HAVE_CATCHABLE_SEGV=1 TLS=_Thread_local ASM_HIDE_SYMBOL=.hidden)
endif()

if(NOT MSVC AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64|amd64")
    target_compile_definitions(game_sodium PRIVATE HAVE_CPUID=1 HAVE_MMINTRIN_H=1 HAVE_EMMINTRIN_H=1
        HAVE_PMMINTRIN_H=1 HAVE_TMMINTRIN_H=1 HAVE_SMMINTRIN_H=1 HAVE_AVXINTRIN_H=1
        HAVE_AVX2INTRIN_H=1 HAVE_AVX512FINTRIN_H=1 HAVE_WMMINTRIN_H=1 HAVE_RDRAND=1)
elseif(NOT MSVC AND CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64|ARM64")
    target_compile_definitions(game_sodium PRIVATE HAVE_ARMCRYPTO=1)
endif()

if(WIN32)
    target_link_libraries(game_sodium PUBLIC advapi32)
endif()
