// Kiểu hình học số nguyên của tầng cửa sổ: điểm, cỡ, chữ nhật theo điểm ảnh màn hình — RectDesc và
// Resolution của IOperatingSystem.h trong _Ref. Gốc toạ độ ở góc trên trái, y hướng xuống; right và
// bottom nằm NGOÀI chữ nhật (như RECT của Win32). Tách khỏi module math vì tầng này chỉ dựa core.
// Nguồn: Forge2 src/window/types.hpp@d7fcd76. Khác gốc: khởi tạo aggregate ghi tên thành viên.
#pragma once

#include <cstdint>

namespace game::window {

struct Point {
    std::int32_t x = 0;
    std::int32_t y = 0;

    friend constexpr bool operator==(const Point&, const Point&) = default;
};

struct Size {
    std::uint32_t width = 0;
    std::uint32_t height = 0;

    [[nodiscard]] constexpr bool empty() const noexcept { return width == 0 || height == 0; }

    friend constexpr bool operator==(const Size&, const Size&) = default;
};

struct Rect {
    std::int32_t left = 0;
    std::int32_t top = 0;
    std::int32_t right = 0;
    std::int32_t bottom = 0;

    [[nodiscard]] static constexpr Rect from(Point origin, Size size) noexcept {
        const auto width = static_cast<std::int32_t>(size.width);
        const auto height = static_cast<std::int32_t>(size.height);
        const std::int32_t end_x = origin.x + width;
        const std::int32_t end_y = origin.y + height;
        return {.left = origin.x, .top = origin.y, .right = end_x, .bottom = end_y};
    }

    // Chiều rộng, cao; chữ nhật lộn ngược (right < left) cho 0, không cho số âm.
    [[nodiscard]] constexpr std::uint32_t width() const noexcept {
        return right > left ? static_cast<std::uint32_t>(right - left) : 0U;
    }
    [[nodiscard]] constexpr std::uint32_t height() const noexcept {
        return bottom > top ? static_cast<std::uint32_t>(bottom - top) : 0U;
    }
    [[nodiscard]] constexpr Size size() const noexcept { return {.width = width(), .height = height()}; }
    [[nodiscard]] constexpr Point origin() const noexcept { return {.x = left, .y = top}; }
    [[nodiscard]] constexpr bool contains(Point point) const noexcept {
        return point.x >= left && point.x < right && point.y >= top && point.y < bottom;
    }

    friend constexpr bool operator==(const Rect&, const Rect&) = default;
};

// Số điểm trên inch theo hai trục; 96 là tỉ lệ 100%.
struct Dpi {
    std::uint32_t x = 96;
    std::uint32_t y = 96;

    [[nodiscard]] constexpr float scale_x() const noexcept { return static_cast<float>(x) / 96.0F; }
    [[nodiscard]] constexpr float scale_y() const noexcept { return static_cast<float>(y) / 96.0F; }

    friend constexpr bool operator==(const Dpi&, const Dpi&) = default;
};

} // namespace game::window
