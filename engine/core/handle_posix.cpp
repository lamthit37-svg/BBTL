/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/handle_posix.cpp
 *  PHÂN HỆ   : Core / Handle
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt core/handle.hpp cho nền không phải Windows.
 *  - fd của POSIX sở hữu độc quyền. fd 0 là stdin hợp lệ, còn nullptr là "không
 *    giữ gì", nên lưu (fd + 1). Mọi bit 1 đóng vai INVALID_HANDLE_VALUE. close
 *    trên Linux giải phóng fd kể cả khi trả EINTR; gọi lại sẽ đóng nhầm fd vừa
 *    được tái sử dụng.
 *  - Nguồn: Forge2 src/core/handle_android.cpp@d7fcd76. Khác gốc: không. Không
 *    thêm biên C: UniqueHandle đã là kiểu C++ sở hữu, cùng chữ ký với bản
 *    Win32.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#if !defined(_WIN32)

#include "core/handle.hpp"

#include <unistd.h>

#include <cstdint>

namespace game::core {

namespace {

[[nodiscard]] void* invalid_handle() noexcept {
    return reinterpret_cast<void*>(~std::uintptr_t{0});
}

// Khớp encode trong log_sink_posix.cpp.
[[nodiscard]] int decode_fd(void* handle) noexcept {
    const auto encoded = reinterpret_cast<std::uintptr_t>(handle);
    return static_cast<int>(encoded - 1U);
}

} // namespace

bool UniqueHandle::valid() const noexcept {
    return handle_ != nullptr && handle_ != invalid_handle();
}

void UniqueHandle::reset(void* handle) noexcept {
    if (valid()) static_cast<void>(::close(decode_fd(handle_)));
    handle_ = handle;
}

} // namespace game::core

#endif
