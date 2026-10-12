#include "client/map/sheet.hpp"

#include "client/map/picture.hpp"
#include "client/map/samples.hpp"
#include "client/map/terrain.hpp"
#include "scene/placement.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::client::map {
namespace {

struct GridPoint {
    int column = 0;
    int row = 0;
};

[[nodiscard]] std::size_t junction_index(int columns, GridPoint point) noexcept {
    return (static_cast<std::size_t>(point.row) * static_cast<std::size_t>(columns + 1)) +
        static_cast<std::size_t>(point.column);
}

[[nodiscard]] float height_point(const HeightField& field, int columns, GridPoint point) noexcept {
    return field.samples[junction_index(columns, point)];
}

[[nodiscard]] float slope_x(const HeightField& field, int columns, GridPoint point) noexcept {
    const int left = point.column > 0 ? point.column - 1 : point.column;
    const int right = point.column < columns ? point.column + 1 : point.column;
    const int span = right - left;
    if (span == 0) return 0.0F;
    const GridPoint point_right{.column = right, .row = point.row};
    const GridPoint point_left{.column = left, .row = point.row};
    const float rise = height_point(field, columns, point_right) - height_point(field, columns, point_left);
    return rise / static_cast<float>(span);
}

[[nodiscard]] float slope_z(const HeightField& field, GridSpan grid, GridPoint point) noexcept {
    const int back = point.row > 0 ? point.row - 1 : point.row;
    const int front = point.row < grid.rows ? point.row + 1 : point.row;
    const int steps = front - back;
    if (steps == 0) return 0.0F;
    const GridPoint point_front{.column = point.column, .row = front};
    const GridPoint point_back{.column = point.column, .row = back};
    const float rise = height_point(field, grid.columns, point_front) - height_point(field, grid.columns, point_back);
    return rise / static_cast<float>(steps);
}

struct Normal {
    float x = 0.0F;
    float y = 1.0F;
    float z = 0.0F;
};

struct Slope {
    float along_x = 0.0F;
    float along_z = 0.0F;
};

// n = cross(dP/dz, dP/dx). Trục j dương khi tỉ lệ dương, nên mặt hướng lên.
[[nodiscard]] Normal normal_of(const scene::Vector3& scale, Slope slope) noexcept {
    Normal normal;
    normal.x = -scale.y * scale.z * slope.along_x;
    normal.y = scale.x * scale.z;
    normal.z = -scale.x * scale.y * slope.along_z;
    const float length = std::sqrt((normal.x * normal.x) + (normal.y * normal.y) + (normal.z * normal.z));
    if (length <= 0.0F) return Normal{};
    normal.x /= length;
    normal.y /= length;
    normal.z /= length;
    return normal;
}

struct Span {
    float low = 0.0F;
    float high = 0.0F;
};

[[nodiscard]] Span span_of(const HeightField& heights) noexcept {
    Span span;
    if (heights.samples.empty()) return span;
    span.low = heights.samples.front();
    span.high = heights.samples.front();
    for (const float height : heights.samples) {
        span.low = std::min(span.low, height);
        span.high = std::max(span.high, height);
    }
    return span;
}

struct CornerRequest {
    const TerrainFile* file = nullptr;
    const HeightField* field = nullptr;
    const Span* span = nullptr;
    GridPoint point{};
};

void push_corner(Sheet& sheet, const CornerRequest& request) {
    const TerrainFile& file = *request.file;
    const HeightField& field = *request.field;
    const GridPoint point = request.point;
    const float height = height_point(field, file.x_size, point);
    const GridSpan span{.columns = file.x_size, .rows = file.z_size};
    const Slope slope{.along_x = slope_x(field, file.x_size, point), .along_z = slope_z(field, span, point)};
    const Normal normal = normal_of(file.scale, slope);
    const Rgb color = shade_of(height, request.span->low, request.span->high);
    Corner corner;
    corner.x = file.origin.x + (file.scale.x * static_cast<float>(point.column));
    corner.y = file.origin.y + (file.scale.y * height);
    corner.z = file.origin.z + (file.scale.z * static_cast<float>(point.row));
    corner.normal_x = normal.x;
    corner.normal_y = normal.y;
    corner.normal_z = normal.z;
    corner.red = color.red;
    corner.green = color.green;
    corner.blue = color.blue;
    sheet.corners.push_back(corner);
}

// Bốn góc theo msConnerMap: 0 trái-trên, 1 phải-trên, 2 trái-dưới, 3 phải-dưới.
void push_plain(std::vector<std::uint32_t>& indices, const std::array<std::uint32_t, 4>& corner) {
    const std::uint32_t near_left = std::get<0>(corner);
    const std::uint32_t near_right = std::get<1>(corner);
    const std::uint32_t far_left = std::get<2>(corner);
    const std::uint32_t far_right = std::get<3>(corner);
    indices.push_back(near_right);
    indices.push_back(near_left);
    indices.push_back(far_left);
    indices.push_back(near_right);
    indices.push_back(far_left);
    indices.push_back(far_right);
}

// msConnerMap lật là trái-dưới, trái-trên, phải-dưới, phải-trên. Vẫn ghi [1],[0],[2] rồi
// [1],[2],[3].
void push_flipped(std::vector<std::uint32_t>& indices, const std::array<std::uint32_t, 4>& corner) {
    const std::uint32_t near_left = std::get<0>(corner);
    const std::uint32_t near_right = std::get<1>(corner);
    const std::uint32_t far_left = std::get<2>(corner);
    const std::uint32_t far_right = std::get<3>(corner);
    indices.push_back(near_left);
    indices.push_back(far_left);
    indices.push_back(far_right);
    indices.push_back(near_left);
    indices.push_back(far_right);
    indices.push_back(near_right);
}

void push_cell(std::vector<std::uint32_t>& indices, const std::array<std::uint32_t, 4>& corner, bool is_flipped) {
    if (is_flipped) {
        push_flipped(indices, corner);
        return;
    }
    push_plain(indices, corner);
}

void place_cell(Sheet& sheet, const TerrainFile& file, const GridField& grid, int index) {
    const GridPoint point{.column = index % file.x_size, .row = index / file.x_size};
    const auto cell = static_cast<std::size_t>(index);
    if (grid.cells[cell].base.pixmap == 0) return;
    const GridPoint east{.column = point.column + 1, .row = point.row};
    const GridPoint north{.column = point.column, .row = point.row + 1};
    const GridPoint far{.column = point.column + 1, .row = point.row + 1};
    const auto near_left = static_cast<std::uint32_t>(junction_index(file.x_size, point));
    const auto near_right = static_cast<std::uint32_t>(junction_index(file.x_size, east));
    const auto far_left = static_cast<std::uint32_t>(junction_index(file.x_size, north));
    const auto far_right = static_cast<std::uint32_t>(junction_index(file.x_size, far));
    const std::array<std::uint32_t, 4> corner{near_left, near_right, far_left, far_right};
    const bool is_flipped = (grid.cells[cell].flags & kFlipDiagonal) != 0;
    push_cell(sheet.indices, corner, is_flipped);
}

} // namespace

Sheet build_sheet(const TerrainFile& file, const HeightField& heights, const GridField& grid) {
    Sheet sheet;
    if (file.x_size <= 0 || file.z_size <= 0) return sheet;
    const int width = file.x_size + 1;
    const int depth = file.z_size + 1;
    const std::size_t points = static_cast<std::size_t>(width) * static_cast<std::size_t>(depth);
    sheet.corners.reserve(points);
    const Span span = span_of(heights);
    const int point_count = width * depth;
    for (int index = 0; index < point_count; ++index) {
        const GridPoint point{.column = index % width, .row = index / width};
        const CornerRequest request{.file = &file, .field = &heights, .span = &span, .point = point};
        push_corner(sheet, request);
    }
    const int cell_count = file.x_size * file.z_size;
    sheet.indices.reserve(static_cast<std::size_t>(cell_count) * 6);
    for (int index = 0; index < cell_count; ++index)
        place_cell(sheet, file, grid, index);
    return sheet;
}

} // namespace game::client::map
