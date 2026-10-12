// Một số API trả NULL khi lỗi (CreateEvent, OpenProcess), số khác trả INVALID_HANDLE_VALUE
// (CreateFile); valid() loại cả hai để nơi gọi khỏi phải nhớ API nào trả gì.
// Nguồn: Forge2 src/core/handle.cpp@d7fcd76. Khác gốc: macro của windows.h lấy từ core/win32.hpp
// (gốc khai ở CMake); header con của Win32 include trực tiếp.
#include "core/handle.hpp"

#include "core/win32.hpp" // IWYU pragma: keep

#include <handleapi.h>

namespace game::core {

bool UniqueHandle::valid() const noexcept {
    return handle_ != nullptr && handle_ != INVALID_HANDLE_VALUE;
}

void UniqueHandle::reset(void* handle) noexcept {
    if (valid()) CloseHandle(handle_);
    handle_ = handle;
}

} // namespace game::core
