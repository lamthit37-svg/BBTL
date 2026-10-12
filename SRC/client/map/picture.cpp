#include "client/map/picture.hpp"

#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::client::map {
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

struct GridPoint {
    int column = 0;
    int row = 0;
};

[[nodiscard]] float sample_point(const HeightField& heights, int columns, GridPoint point) noexcept {
    const std::size_t index = (static_cast<std::size_t>(point.row) * static_cast<std::size_t>(columns + 1)) +
        static_cast<std::size_t>(point.column);
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

[[nodiscard]] float cell_height(const HeightField& heights, int columns, GridPoint point) noexcept {
    const GridPoint east{.column = point.column + 1, .row = point.row};
    const GridPoint north{.column = point.column, .row = point.row + 1};
    const GridPoint far{.column = point.column + 1, .row = point.row + 1};
    const float south_west = sample_point(heights, columns, point);
    const float south_east = sample_point(heights, columns, east);
    const float north_west = sample_point(heights, columns, north);
    const float north_east = sample_point(heights, columns, far);
    return (south_west + south_east + north_west + north_east) / 4.0F;
}

void write_pixel(Picture& picture, std::size_t pixel, Rgb color, bool is_hole) noexcept {
    const std::size_t offset = pixel * 4;
    const float scale = 255.0F;
    picture.rgba[offset] = static_cast<std::uint8_t>(color.red * scale);
    picture.rgba[offset + 1] = static_cast<std::uint8_t>(color.green * scale);
    picture.rgba[offset + 2] = static_cast<std::uint8_t>(color.blue * scale);
    picture.rgba[offset + 3] = is_hole ? 0 : 255;
}

struct PaintInput {
    const TerrainFile* file = nullptr;
    const HeightField* heights = nullptr;
    const GridField* grid = nullptr;
    const Range* range = nullptr;
};

void paint_cell(Picture& picture, const PaintInput& input, int index) noexcept {
    const int columns = input.file->x_size;
    const GridPoint point{.column = index % columns, .row = index / columns};
    const auto cell = static_cast<std::size_t>(index);
    const bool is_hole = input.grid->cells[cell].base.pixmap == 0;
    const float height = cell_height(*input.heights, columns, point);
    const Rgb color = shade_of(height, input.range->low, input.range->high);
    const int image_row = (input.file->z_size - 1) - point.row;
    const auto pixel = (static_cast<std::size_t>(image_row) * static_cast<std::size_t>(columns)) +
        static_cast<std::size_t>(point.column);
    write_pixel(picture, pixel, color, is_hole);
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
    const std::size_t pixels = static_cast<std::size_t>(picture.width) * static_cast<std::size_t>(picture.height);
    picture.rgba.assign(pixels * 4, 0);
    const Range range = range_of(heights);
    const PaintInput input{.file = &file, .heights = &heights, .grid = &grid, .range = &range};
    const int count = file.x_size * file.z_size;
    for (int index = 0; index < count; ++index)
        paint_cell(picture, input, index);
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

} // namespace game::client::map
