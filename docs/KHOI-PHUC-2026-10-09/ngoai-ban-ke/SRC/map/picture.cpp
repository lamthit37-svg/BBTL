#include "map/picture.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::map {
namespace {

// Cách mép phải và mép trên, đo từ layout desktop (xem picture.hpp).
constexpr float kFromRight = 156.5F;
constexpr float kFromTop = 42.0F;
constexpr float kAreaWidth = 119.0F;
constexpr float kAreaHeight = 121.0F;

constexpr float kLowRed = 0.36F;
constexpr float kLowGreen = 0.16F;
constexpr float kLowBlue = 0.05F;
constexpr float kHighRed = 0.78F;
constexpr float kHighGreen = 0.48F;
constexpr float kHighBlue = 0.22F;

struct Range {
    float low = 0.0F;
    float high = 0.0F;
};

[[nodiscard]] float sample_at(const HeightField& heights, int x_size, int x, int z) noexcept {
    const std::size_t index =
        (static_cast<std::size_t>(z) * static_cast<std::size_t>(x_size + 1)) +
        static_cast<std::size_t>(x);
    return heights.samples[index];
}

[[nodiscard]] Range range_of(const HeightField& heights) noexcept {
    Range range;
    if (heights.samples.empty()) return range;
    range.low = heights.samples.front();
    range.high = heights.samples.front();
    for (const float height : heights.samples) {
        range.low = std::min(range.low, height);
        range.high = std::max(range.high, height);
    }
    return range;
}

[[nodiscard]] float cell_height(
    const HeightField& heights, int x_size, int x, int z) noexcept {
    const float a = sample_at(heights, x_size, x, z);
    const float b = sample_at(heights, x_size, x + 1, z);
    const float c = sample_at(heights, x_size, x, z + 1);
    const float d = sample_at(heights, x_size, x + 1, z + 1);
    return (a + b + c + d) / 4.0F;
}

void write_pixel(Picture& picture, std::size_t pixel, Rgb color, bool is_hole) noexcept {
    const std::size_t offset = pixel * 4;
    const float scale = 255.0F;
    picture.rgba[offset] = static_cast<std::uint8_t>(color.red * scale);
    picture.rgba[offset + 1] = static_cast<std::uint8_t>(color.green * scale);
    picture.rgba[offset + 2] = static_cast<std::uint8_t>(color.blue * scale);
    picture.rgba[offset + 3] = is_hole ? 0 : 255;
}

} // namespace

Rgb shade_of(float height, float low, float high) noexcept {
    const float span = high - low;
    const float blend = span > 0.0F ? (height - low) / span : 0.0F;
    Rgb color;
    color.red = kLowRed + ((kHighRed - kLowRed) * blend);
    color.green = kLowGreen + ((kHighGreen - kLowGreen) * blend);
    color.blue = kLowBlue + ((kHighBlue - kLowBlue) * blend);
    return color;
}

Picture paint_overview(const TerrainFile& file, const HeightField& heights, const GridField& grid) {
    Picture picture;
    if (file.x_size <= 0 || file.z_size <= 0) return picture;
    picture.width = static_cast<std::uint32_t>(file.x_size);
    picture.height = static_cast<std::uint32_t>(file.z_size);
    const std::size_t pixels =
        static_cast<std::size_t>(picture.width) * static_cast<std::size_t>(picture.height);
    picture.rgba.assign(pixels * 4, 0);
    const Range range = range_of(heights);
    for (int z = 0; z < file.z_size; ++z) {
        const int row = (file.z_size - 1) - z;
        for (int x = 0; x < file.x_size; ++x) {
            const std::size_t cell =
                (static_cast<std::size_t>(z) * static_cast<std::size_t>(file.x_size)) +
                static_cast<std::size_t>(x);
            const bool is_hole = grid.cells[cell].base.pixmap == 0;
            const float height = cell_height(heights, file.x_size, x, z);
            const Rgb color = shade_of(height, range.low, range.high);
            const std::size_t pixel =
                (static_cast<std::size_t>(row) * static_cast<std::size_t>(file.x_size)) +
                static_cast<std::size_t>(x);
            write_pixel(picture, pixel, color, is_hole);
        }
    }
    return picture;
}

Frame minimap_area(float root_width) noexcept {
    Frame frame;
    frame.x = root_width - kFromRight;
    frame.y = kFromTop;
    frame.width = kAreaWidth;
    frame.height = kAreaHeight;
    return frame;
}

} // namespace game::map
