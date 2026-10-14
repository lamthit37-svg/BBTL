#pragma once
// Giữ một giá trị dựng một lần tới hết tiến trình test (bảng thật đọc từ đĩa, dùng chung mọi ca). Cố ý không huỷ lúc
// thoát: biến tĩnh có destructor không tầm thường bị Clang -Wexit-time-destructors cấm, mà việc huỷ vài MB bảng ngay
// trước khi tiến trình chết không đem lại gì.

#include <optional>
#include <utility>

namespace game::test {

// Chuyển `value` lên heap và không bao giờ giải phóng; nullptr khi `value` rỗng (nạp lỗi).
template <typename T>
[[nodiscard]] const T* keep_forever(std::optional<T> value) {
    if (!value) return nullptr;
    // NOLINTNEXTLINE(cppcoreguidelines-owning-memory,bugprone-unhandled-exception-at-new): sống tới hết tiến trình (HP-07)
    return new T(std::move(*value));
}

} // namespace game::test
