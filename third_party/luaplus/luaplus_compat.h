/* Chỗ vá cho mọi trình dịch không phải MSVC/clang-cl (Android, iOS, Linux, MinGW, clang giao diện GNU): nguồn LuaPlus gốc chỉ dịch được bằng MSVC vì gọi hàm ký tự rộng
   mà không include <wchar.h> và <wctype.h> (MSVC kéo chúng vào qua header khác) và dùng tên `_snwprintf` riêng của Microsoft.
   Dựng bằng `-include` từ CMakeLists.txt, không sửa tệp nào của LuaPlus/. Xem mục "Khác gốc" ở NGUON.txt. */
#ifndef LUAPLUS_COMPAT_H
#define LUAPLUS_COMPAT_H

#include <wchar.h>
#include <wctype.h>

#if !defined(_WIN32)
/* Cùng chữ ký với swprintf của C99: (đệm, số ký tự tối đa, định dạng, ...). Windows có sẵn _snwprintf. */
#define _snwprintf swprintf
#endif

/* lwstrlib.c tự định nghĩa wmemchr và wmemcmp với kiểu lua_WChar; header hệ thống đã khai hai tên này với kiểu trả về khác
   (C: wchar_t*), nên đổi tên bản của LuaPlus. Phải đặt SAU các include ở trên để khai báo hệ thống giữ nguyên tên. */
#define wmemchr luaplus_wmemchr
#define wmemcmp luaplus_wmemcmp

#endif
