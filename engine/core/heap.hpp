/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/heap.hpp
 *  PHÂN HỆ   : Core / Heap
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - trim_heap: trả cho hệ điều hành các trang heap đã free mà allocator còn
 *    giữ. Android (jemalloc, scudo) giữ chúng để cấp lại nên RssAnon không
 *    giảm sau đợt nạp lớn, và lmkd giết tiến trình dựa trên con số đó chứ
 *    không phải số byte đang dùng thật. Gọi sau mỗi đợt nạp xong. Nền khác
 *    không làm gì.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#if defined(__ANDROID__)
#include <malloc.h>
#endif

namespace game::core {

inline void trim_heap() noexcept {
#if defined(__ANDROID__) && defined(M_PURGE)
    // Giá trị trả về chỉ cho biết allocator có hỗ trợ không; không hỗ trợ thì bỏ qua là đúng.
    static_cast<void>(mallopt(M_PURGE, 0));
#endif
}

} // namespace game::core
