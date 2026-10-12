#include "map/sheet.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::map {
namespace {

[[nodiscard]] std::size_t junction_index(int x_size, int x, int z) noexcept {
    return (static_cast<std::size_t>(z) * static_cast<std::size_t>(x_size + 1)) +
        static_cast<std::size_t>(x);
}

[[nodiscard]] float height_at(const HeightField& heights, int x_size, int x, int z) noexcept {
    return heights.samples[junction_index(x_size, x, z)];
}

[[nodiscard]] float slope_x(const HeightField& heights, int x_size, int x, int z) noexcept {
    const int left = x > 0 ? x - 1 : x;
    const int right = x < x_size ? x + 1 : x;
    const int span = right - left;
    if (span == 0) return 0.0F;
    const float rise = height_at(heights, x_size, right, z) - height_at(heights, x_size, left, z);
    return rise / static_cast<float>(span);
}

[[nodiscard]] float slope_z(const HeightField& heights, int z_size, int x_size, int x, int z) noexcept {
    const int back = z > 0 ? z - 1 : z;
    const int front = z < z_size ? z + 1 : z;
    const int span = front - back;
    if (span == 0) return 0.0F;
    const float rise = height_at(heights, x_size, x, front) - height_at(heights, x_size, x, back);
    return rise / static_cast<float>(span);
}

struct Normal {
    float x = 0.0F;
    float y = 1.0F;
    float z = 0.0F;
};

// n = cross(dP/dz, dP/dx). Trục j dương khi tỉ lệ dương, nên mặt hướng lên.
[[nodiscard]] Normal normal_of(const scene::Vector3& scale, float along_x, float along_z) noexcept {
    Normal normal;
    normal.x = -scale.y * scale.z * along_x;
    normal.y = scale.x * scale.z;
    normal.z = -scale.x * scale.y * along_z;
    const float length =
        std::sqrt((normal.x * normal.x) + (normal.y * normal.y) + (normal.z * normal.z));
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

void push_corner(Sheet& sheet, const TerrainFile& file, const HeightField& heights, const Span& span,
    int x, int z) {
    const float height = height_at(heights, file.x_size, x, z);
    const Normal normal =
        normal_of(file.scale, slope_x(heights, file.x_size, x, z),
            slope_z(heights, file.z_size, file.x_size, x, z));
    const Rgb color = shade_of(height, span.low, span.high);
    Corner corner;
    corner.x = file.origin.x + (file.scale.x * static_cast<float>(x));
    corner.y = file.origin.y + (file.scale.y * height);
    corner.z = file.origin.z + (file.scale.z * static_cast<float>(z));
    corner.normal_x = normal.x;
    corner.normal_y = normal.y;
    corner.normal_z = normal.z;
    corner.red = color.red;
    corner.green = color.green;
    corner.blue = color.blue;
    sheet.corners.push_back(corner);
}

// a góc (x,z), b (x+1,z), c (x,z+1), d (x+1,z+1). Thứ tự cho pháp tuyến +Y.
void push_cell(std::vector<std::uint32_t>& indices, std::uint32_t a, std::uint32_t b,
    std::uint32_t c, std::uint32_t d, bool is_flipped) {
    if (is_flipped) {
        indices.push_back(a);
        indices.push_back(c);
        indices.push_back(b);
        indices.push_back(b);
        indices.push_back(c);
        indices.push_back(d);
        return;
    }
    indices.push_back(a);
    indices.push_back(d);
    indices.push_back(b);
    indices.push_back(a);
    indices.push_back(c);
    indices.push_back(d);
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
    for (int z = 0; z < depth; ++z) {
        for (int x = 0; x < width; ++x) {
            push_corner(sheet, file, heights, span, x, z);
        }
    }
    const std::size_t cells =
        static_cast<std::size_t>(file.x_size) * static_cast<std::size_t>(file.z_size);
    sheet.indices.reserve(cells * 6);
    for (int z = 0; z < file.z_size; ++z) {
        for (int x = 0; x < file.x_size; ++x) {
            const std::size_t cell =
                (static_cast<std::size_t>(z) * static_cast<std::size_t>(file.x_size)) +
                static_cast<std::size_t>(x);
            if (grid.cells[cell].base.pixmap == 0) continue;
            const auto a = static_cast<std::uint32_t>(junction_index(file.x_size, x, z));
            const auto b = static_cast<std::uint32_t>(junction_index(file.x_size, x + 1, z));
            const auto c = static_cast<std::uint32_t>(junction_index(file.x_size, x, z + 1));
            const auto d = static_cast<std::uint32_t>(junction_index(file.x_size, x + 1, z + 1));
            const bool is_flipped = (grid.cells[cell].flags & kFlipDiagonal) != 0;
            push_cell(sheet.indices, a, b, c, d, is_flipped);
        }
    }
    return sheet;
}

} // namespace game::map
