/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/effects.hpp
 *  PHÂN HỆ   : Core / Effects
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hiệu ứng hàm mà Clang chứng minh lúc biên dịch (cpp23 CL-09): hàm khai
 *    GAME_NONALLOCATING chỉ được gọi hàm cũng không cấp phát, GAME_NONBLOCKING
 *    thêm điều kiện không khoá, không chờ. Vi phạm là cảnh báo -Wfunction-
 *    effects ở đúng dòng gọi; cổng check.py bật cờ đó cho Clang. Macro đứng SAU
 *    noexcept trong khai báo (thuộc tính của kiểu hàm): `void f() noexcept
 *    GAME_NONBLOCKING;` đặt ở đầu khai báo thì Clang không coi là hiệu ứng của
 *    hàm. GCC và MSVC không biết hai thuộc tính này nên ở đó macro rỗng: bằng
 *    chứng chỉ có ở bản dựng Clang.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#if __has_cpp_attribute(clang::nonblocking)
#define GAME_NONALLOCATING [[clang::nonallocating]]
#define GAME_NONBLOCKING [[clang::nonblocking]]
#else
#define GAME_NONALLOCATING
#define GAME_NONBLOCKING
#endif
