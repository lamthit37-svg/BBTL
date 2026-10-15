/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/win32.hpp
 *  PHÂN HỆ   : Core / Win32
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - <windows.h> cho mọi tệp Win32 của dự án, kèm các macro phải khai trước nó.
 *    Gom về một chỗ vì check.py dịch từng tệp đứng riêng, không có cờ của
 *    CMake, nên macro không thể chỉ nằm ở CMake.
 *  - UNICODE: tên không hậu tố (IDC_ARROW, MAKEINTRESOURCE) là bản chuỗi rộng.
 *  - NOMINMAX: không có macro min, max đè lên std::min, std::max.
 *  - WIN32_LEAN_AND_MEAN: bỏ phần ít dùng; tệp cần shellapi.h, dwmapi.h thì tự
 *    include.
 *  - _WIN32_WINNT 0x0A00: MinGW mặc định 0x0601 (Windows 7) và khi đó không
 *    khai các API của Windows 10 mà mã chép từ Forge2 dùng
 *    (GetSystemCpuSetInformation, SetThreadDescription,
 *    AdjustWindowRectExForDpi, SetProcessDpiAwarenessContext).
 *  - Tệp .cpp include header này trong nhóm header dự án, rồi include trực tiếp
 *    các header con nó dùng (winuser.h, winerror.h...) ở nhóm nền tảng. Nền
 *    tảng khác: header rỗng.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#if defined(_WIN32)

// Tên macro do Windows SDK quy định (lệch DD-02).
// NOLINTBEGIN(bugprone-reserved-identifier,cert-dcl37-c,cert-dcl51-cpp)
// NOLINTBEGIN(cppcoreguidelines-macro-usage,readability-identifier-naming)
#if !defined(_WIN32_WINNT) || _WIN32_WINNT < 0x0A00
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0A00
#endif
// NOLINTEND(cppcoreguidelines-macro-usage,readability-identifier-naming)
// NOLINTEND(bugprone-reserved-identifier,cert-dcl37-c,cert-dcl51-cpp)
#if !defined(UNICODE)
#define UNICODE
#endif
#if !defined(NOMINMAX)
#define NOMINMAX
#endif
#if !defined(WIN32_LEAN_AND_MEAN)
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h> // IWYU pragma: export

#endif
