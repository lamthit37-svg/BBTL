// Hình con trỏ chuột — createCursor và setCursor của _Ref. Cursor là giá trị chép rẻ: các bản chép
// dùng chung một handle, handle nạp từ tệp được huỷ khi bản cuối cùng mất. Khác gốc:
// - đường dẫn UTF-8 qua LoadCursorFromFileW; gốc gọi bản A theo code page;
// - con trỏ nạp từ tệp được giải phóng; gốc trả void* trần và không bao giờ huỷ;
// - có sẵn các con trỏ của hệ thống, và lỗi nạp tệp trả qua Result thay vì con trỏ null.
// Nguồn: Forge2 src/window/cursor.hpp@d7fcd76. Khác gốc (so với Forge2): enumerator mang tiền tố k.
#pragma once

#include "core/error.hpp"

#include <cstdint>
#include <memory>
#include <span>
#include <string_view>
#include <utility>

namespace game::window {

enum class SystemCursor : std::uint8_t {
    kArrow,
    kText,
    kWait,
    kCross,
    kHand,
    kMove,
    kResizeVertical,
    kResizeHorizontal,
    kResizeDiagonalDown,
    kResizeDiagonalUp,
    kForbidden,
};

class Cursor {
public:
    // Mũi tên của hệ thống.
    Cursor() noexcept : Cursor(system(SystemCursor::kArrow)) {}

    [[nodiscard]] static Cursor system(SystemCursor shape) noexcept;
    // Tệp .cur hoặc .ani.
    [[nodiscard]] static core::Result<Cursor> from_file(std::string_view path);

    // Ảnh RGBA8 hàng trên trước, alpha thẳng. Windows chép thành BGRA đã nhân alpha lúc tạo.
    struct RgbaCursor {
        std::uint32_t width = 0;
        std::uint32_t height = 0;
        std::uint16_t hot_x = 0;
        std::uint16_t hot_y = 0;
        std::span<const std::uint8_t> rgba;
    };
    [[nodiscard]] static core::Result<Cursor> from_rgba(RgbaCursor picture);

    // HCURSOR; null chỉ khi hệ thống không nạp nổi con trỏ chuẩn.
    [[nodiscard]] void* native_handle() const noexcept { return handle_; }

private:
    Cursor(void* handle, std::shared_ptr<void> owner) noexcept : handle_(handle), owner_(std::move(owner)) {}

    void* handle_ = nullptr;
    // Chỉ có ở con trỏ nạp từ tệp: giữ handle sống tới bản chép cuối cùng (cửa sổ giữ một bản chép
    // của con trỏ đang dùng). Con trỏ hệ thống là tài nguyên chung của Windows, không ai huỷ.
    std::shared_ptr<void> owner_;
};

} // namespace game::window
