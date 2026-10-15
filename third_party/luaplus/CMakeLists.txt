# LuaPlus (Lua 5.0.1): máy Lua của script giao diện. Nguồn, giấy phép và mục "Khác gốc" ở NGUON.txt.
# Chỉ dịch lõi C (máy ảo, bộ dịch, thư viện chuẩn, phần thêm của LuaPlus). Lớp bọc C++ cũ (LuaObject, LuaState...) và
# ltests.c, luiolib.c, lua.c, luac.c không dịch.
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

set(luaplus_root "${CMAKE_CURRENT_SOURCE_DIR}/LuaPlus")
set(luaplus_sources
    src/lapi.c src/lcode.c src/ldebug.c src/ldo.c src/ldump.c src/lfunc.c src/lgc.c src/llex.c src/lmem.c
    src/lobject.c src/lopcodes.c src/lparser.c src/lstate.c src/lstring.c src/ltable.c src/ltm.c src/lundump.c
    src/lvm.c src/lzio.c
    src/lib/lauxlib.c src/lib/lbaselib.c src/lib/ldblib.c src/lib/liolib.c src/lib/lmathlib.c src/lib/loadlib.c
    src/lib/lstrlib.c src/lib/ltablib.c
    LuaPlusAddons.c lwstrlib.c)
list(TRANSFORM luaplus_sources PREPEND "${luaplus_root}/")

# Cờ chung của hai bản dựng. Mã C của bên thứ ba: cảnh báo của nó không đi vào cổng -Werror của dự án; header ra ngoài
# qua SYSTEM.
function(luaplus_configure target)
    target_compile_features(${target} PRIVATE c_std_11)
    target_include_directories(${target} SYSTEM PUBLIC "${luaplus_root}/include" "${luaplus_root}")
    target_include_directories(${target} PRIVATE "${luaplus_root}/src")
    # Số của script đi qua module luanum (định dạng, strtod, rand, ép số nguyên theo MSVCR110): NGUON.txt, mục "Khác gốc".
    target_link_libraries(${target} PUBLIC game_luanum)
    if(MSVC)
        target_compile_options(${target} PRIVATE /W0)
        target_compile_definitions(${target} PRIVATE _CRT_SECURE_NO_WARNINGS)
    else()
        # Ngoài MSVC: header vá luaplus_compat.h (ký tự rộng, _snwprintf) buộc include vào mọi tệp C của LuaPlus.
        # -ffp-contract=off: trình dịch GCC/Clang không được gộp a * b + c thành FMA (ARM64 làm mặc định), kết quả lệch một ulp.
        target_compile_options(${target} PRIVATE -w -ffp-contract=off -include "${CMAKE_CURRENT_SOURCE_DIR}/luaplus_compat.h")
        # lua_WChar là wchar_t (4 byte ở Android, Linux, iOS) như các hàm w* của libc mà lwstrlib.c gọi; MSVC giữ unsigned short.
        target_compile_definitions(${target} PUBLIC LUAPLUS_HAS_WCHAR_T)
    endif()
endfunction()

# Bản tĩnh cho client: LUA_API rỗng (LuaLink.h với LUAPLUS_LIB).
add_library(game_luaplus STATIC ${luaplus_sources})
luaplus_configure(game_luaplus)
target_compile_definitions(game_luaplus PUBLIC LUAPLUS_LIB)

# Bản DLL cùng nguồn, cùng cờ, xuất API như LuaPlus.dll của client 2026: TOOLS/port/luagen/mass_oracle.py nạp nó bằng
# ctypes để ctest lua_mass so vết 2 060 đơn vị giao diện với bảng vàng của DLL gốc.
if(WIN32)
    add_library(luaplus_oracle SHARED ${luaplus_sources})
    luaplus_configure(luaplus_oracle)
    target_compile_definitions(luaplus_oracle PRIVATE LUAPLUS_BUILDDLL)
    # Phần luanum là C++: DLL liên kết bằng trình liên kết C++.
    set_target_properties(luaplus_oracle PROPERTIES OUTPUT_NAME LuaPlus PREFIX "" LINKER_LANGUAGE CXX
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/luaplus"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/luaplus"
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/luaplus")
    foreach(config IN ITEMS DEBUG RELEASE RELWITHDEBINFO MINSIZEREL)
        set_target_properties(luaplus_oracle PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${config} "${CMAKE_BINARY_DIR}/luaplus")
    endforeach()
endif()
