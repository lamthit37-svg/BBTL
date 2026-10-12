// Khung hình cho việc ghi hình: vùng điểm ảnh trên CPU kèm kích thước và định dạng. Module capture
// không biết GPU: tầng đồ hoạ đọc ngược render target vào bộ nhớ rồi trao một FrameView (mượn) hay
// một Frame (sở hữu) cho bộ mã hoá ảnh và video. _Ref gộp hai việc ấy trong Screenshot.cpp —
// đọc ngược bằng compute shader, chờ fence rồi nén PNG bằng stb ngay trên luồng vẽ — nên một lần
// chụp chặn khung hình cho tới khi tệp ghi xong. Hàng 0 là hàng trên cùng.
// Nguồn: Forge2 src/capture/frame.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; bỏ {} thừa của
// FrameView::pixels và Frame::pixels_.
#pragma once

#include "core/error.hpp"

#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

namespace game::capture {

using core::ErrorCode;
using core::fail;
using core::ok;
using core::Result;
using core::Status;

enum class PixelFormat : std::uint8_t {
    // 8 bit mỗi kênh, không dấu.
    kRgba8,
    kBgra8,
    // 16 bit mỗi kênh, không dấu, thứ tự byte của máy.
    kRgba16,
    // float 32 bit mỗi kênh, tuyến tính: cho ảnh HDR.
    kRgba32F,
};

// Số byte của một điểm ảnh.
[[nodiscard]] constexpr std::size_t pixel_size(PixelFormat format) noexcept {
    switch (format) {
    case PixelFormat::kRgba8:
    case PixelFormat::kBgra8: return 4;
    case PixelFormat::kRgba16: return 8;
    case PixelFormat::kRgba32F: return 16;
    }
    return 0;
}

// Khung hình mượn: pixels phải sống lâu hơn mọi lời gọi nhận view này.
struct FrameView {
    std::span<const std::byte> pixels;
    std::uint32_t width = 0;
    std::uint32_t height = 0;
    // Số byte từ đầu hàng này tới đầu hàng sau; ít nhất width * pixel_size(format).
    std::size_t stride = 0;
    PixelFormat format = PixelFormat::kRgba8;

    // Số byte điểm ảnh của một hàng, không tính phần đệm của stride.
    [[nodiscard]] constexpr std::size_t row_size() const noexcept { return width * pixel_size(format); }

    // Kích thước khác 0, stride đủ một hàng và pixels đủ mọi hàng.
    [[nodiscard]] constexpr bool valid() const noexcept {
        if (width == 0 || height == 0 || stride < row_size()) return false;
        const std::size_t needed = (stride * (height - std::size_t{1})) + row_size();
        return pixels.size() >= needed;
    }

    // Điểm ảnh của hàng line, không kèm phần đệm. Chỉ gọi trên view đã valid() với line < height.
    [[nodiscard]] constexpr std::span<const std::byte> row(std::uint32_t line) const noexcept {
        return pixels.subspan(stride * line, row_size());
    }
};

// Khung hình sở hữu, hàng xếp sát nhau (stride bằng đúng một hàng).
class Frame {
public:
    Frame() = default;
    // Vùng điểm ảnh cấp sẵn, giá trị 0.
    Frame(std::uint32_t width, std::uint32_t height, PixelFormat format)
        : pixels_(std::size_t{width} * height * pixel_size(format)), width_(width), height_(height), format_(format) {}

    // Chép view, bỏ phần đệm của stride. view phải valid().
    [[nodiscard]] static Frame copy(const FrameView& view);

    [[nodiscard]] std::span<std::byte> pixels() noexcept { return pixels_; }
    [[nodiscard]] std::uint32_t width() const noexcept { return width_; }
    [[nodiscard]] std::uint32_t height() const noexcept { return height_; }
    [[nodiscard]] PixelFormat format() const noexcept { return format_; }

    // Mượn: hết hiệu lực khi Frame bị huỷ hay gán đè.
    [[nodiscard]] FrameView view() const noexcept {
        return {.pixels = pixels_,
            .width = width_,
            .height = height_,
            .stride = width_ * pixel_size(format_),
            .format = format_};
    }

private:
    std::vector<std::byte> pixels_;
    std::uint32_t width_ = 0;
    std::uint32_t height_ = 0;
    PixelFormat format_ = PixelFormat::kRgba8;
};

} // namespace game::capture
