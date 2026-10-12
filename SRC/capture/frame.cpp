// Sao chép khung hình thành bản sở hữu, các hàng xếp sát nhau.
// Mỗi hàng chỉ chép đúng row_size, nên phần đệm stride của view không lọt vào bản sao.
// Nguồn: Forge2 src/capture/frame.cpp@d7fcd76. Khác gốc: không (chỉ thêm include đủ).
#include "capture/frame.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <span>

namespace game::capture {

Frame Frame::copy(const FrameView& view) {
    Frame frame(view.width, view.height, view.format);
    const std::size_t row = view.row_size();
    const std::span<std::byte> target = frame.pixels_;
    for (std::uint32_t line = 0; line < view.height; ++line) {
        std::ranges::copy(view.row(line), target.subspan(row * line, row).begin());
    }
    return frame;
}

} // namespace game::capture
