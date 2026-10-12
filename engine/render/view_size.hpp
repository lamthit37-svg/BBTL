#pragma once
// Kích thước vùng vẽ, gói lại để chữ ký hàm dựng camera nằm gọn trên một dòng.
// Nguồn: TLBB Dev src/render/view_size.hpp@e0d89a6. Khác gốc: namespace game::render; bỏ
// view_extent (đổi sang uint16_t của bgfx; thiết bị của dự án nhận cỡ uint32).

#include <cstdint>

namespace game::render {

struct ViewSize {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

} // namespace game::render
