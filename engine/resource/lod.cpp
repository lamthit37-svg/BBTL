/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/lod.cpp
 *  PHÂN HỆ   : Resource / Lod
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Sinh LOD bằng meshopt_simplifyWithAttributes. Mỗi mức đơn giản hoá từ mức
 *    trước để rẻ; cạnh biên không khoá vì vật thể trong cảnh là mảnh rời, vết
 *    nứt giữa các mảnh không xảy ra ở đây. Lưới có skin hoặc morph bị bỏ: giản
 *    lược theo vị trí làm méo hoạt cảnh.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "resource/lod.hpp"

#include "resource/model.hpp"

#include <meshoptimizer.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>
#include <vector>

namespace game::resource {

namespace {

// Primitive dưới ngưỡng này vẽ rẻ hơn công sức giản lược.
constexpr std::size_t kMinIndices = std::size_t{100} * 3;
// Mức thô nhất vẫn giữ tối thiểu chừng này chỉ số, dưới đó hình không còn nhận ra.
constexpr std::size_t kFloorIndices = std::size_t{8} * 3;
// Mức mới phải giảm ít nhất 20% so với mức trước, không thì bỏ.
constexpr double kMinShrink = 0.8;

struct Level {
    // Tỉ lệ số chỉ số so với mức 0.
    double keep;
    // Sai số tương đối tối đa (so với cỡ lưới) mà meshopt được phép chấp nhận.
    float error;
    // Cho phép gom cụm không giữ tô-pô khi các cách giữ tô-pô không giảm đủ.
    bool allow_sloppy;
};

constexpr std::array<Level, 3> kLevels{{{.keep = 0.35, .error = 0.05F, .allow_sloppy = false},
    {.keep = 0.12, .error = 0.12F, .allow_sloppy = true}, {.keep = 0.04, .error = 0.3F, .allow_sloppy = true}}};

// Normal 3, uv 2, màu rgb 3. Trọng số theo meshoptimizer: vị trí là 1.
constexpr std::size_t kAttributes = 8;
constexpr std::array<float, kAttributes> kWeights{0.5F, 0.5F, 0.5F, 1.0F, 1.0F, 0.25F, 0.25F, 0.25F};

[[nodiscard]] bool is_static(const Primitive& primitive) noexcept {
    if (primitive.topology != Topology::kTriangles || !primitive.targets.empty()) return false;
    const auto skinned = [](const Vertex& vertex) {
        return vertex.weights.x + vertex.weights.y + vertex.weights.z + vertex.weights.w > 0.0F;
    };
    return std::ranges::none_of(primitive.vertices, skinned);
}

[[nodiscard]] std::vector<float> attributes_of(const std::vector<Vertex>& vertices) {
    std::vector<float> out;
    out.reserve(vertices.size() * kAttributes);
    for (const Vertex& vertex : vertices) {
        const std::array<float, kAttributes> one{vertex.normal.x, vertex.normal.y, vertex.normal.z, vertex.uv.x,
            vertex.uv.y, vertex.color.x, vertex.color.y, vertex.color.z};
        out.insert(out.end(), one.begin(), one.end());
    }
    return out;
}

struct Source {
    const Primitive* primitive = nullptr;
    const std::vector<float>* attributes = nullptr;
};

// Thứ tự thử một mức: giữ normal, uv, màu (đẹp nhất); chỉ vị trí (gỡ ràng buộc seam mà meshopt không chịu bỏ); rồi gom
// cụm không giữ tô-pô, chỉ cho hai mức thô vì ở đó vật chỉ còn vài chục điểm ảnh.
enum class Method : std::uint8_t { kWithAttributes, kPositionOnly, kSloppy };

struct Attempt {
    const Source* source = nullptr;
    const std::vector<std::uint32_t>* from = nullptr;
    std::size_t target = 0;
    float error = 0.0F;
};

[[nodiscard]] std::size_t run_method(Method method, const Attempt& attempt, std::vector<std::uint32_t>& out) {
    const std::vector<Vertex>& vertices = attempt.source->primitive->vertices;
    const float* positions = &vertices.front().position.x;
    const std::vector<std::uint32_t>& from = *attempt.from;
    float error = 0.0F;
    switch (method) {
    case Method::kWithAttributes:
        return meshopt_simplifyWithAttributes(out.data(), from.data(), from.size(), positions, vertices.size(),
            sizeof(Vertex), attempt.source->attributes->data(), kAttributes * sizeof(float), kWeights.data(),
            kAttributes, nullptr, attempt.target, attempt.error, 0, &error);
    case Method::kPositionOnly:
        return meshopt_simplify(out.data(), from.data(), from.size(), positions, vertices.size(), sizeof(Vertex),
            attempt.target, attempt.error * 2.0F, 0, &error);
    case Method::kSloppy:
        return meshopt_simplifySloppy(out.data(), from.data(), from.size(), positions, vertices.size(), sizeof(Vertex),
            nullptr, attempt.target, attempt.error * 4.0F, &error);
    }
    return 0;
}

// Một mức từ `from`; rỗng khi không cách nào giảm đủ.
[[nodiscard]] std::vector<std::uint32_t> simplified(const Source& source, const std::vector<std::uint32_t>& from,
    const Level& level) {
    const std::vector<Vertex>& vertices = source.primitive->vertices;
    const auto wanted = static_cast<std::size_t>(static_cast<double>(source.primitive->indices.size()) * level.keep);
    const Attempt attempt{.source = &source, .from = &from, .target = std::max(wanted, kFloorIndices) / 3 * 3,
        .error = level.error};
    const std::size_t limit = static_cast<std::size_t>(static_cast<double>(from.size()) * kMinShrink);
    std::vector<std::uint32_t> out(from.size());
    for (const Method method : {Method::kWithAttributes, Method::kPositionOnly, Method::kSloppy}) {
        if (method == Method::kSloppy && !level.allow_sloppy) break;
        const std::size_t kept = run_method(method, attempt, out);
        if (kept < 3 || kept > limit) continue;
        out.resize(kept);
        // Thứ tự tam giác theo vertex cache: mức thô vẫn chạy nhanh trên GPU có cache đỉnh.
        std::vector<std::uint32_t> ordered(kept);
        meshopt_optimizeVertexCache(ordered.data(), out.data(), kept, vertices.size());
        return ordered;
    }
    return {};
}

void build_primitive_lods(Primitive& primitive) {
    if (!is_static(primitive) || primitive.indices.size() < kMinIndices || primitive.vertices.empty()) return;
    const std::vector<float> attributes = attributes_of(primitive.vertices);
    const Source source{.primitive = &primitive, .attributes = &attributes};
    const std::vector<std::uint32_t>* from = &primitive.indices;
    for (const Level& level : kLevels) {
        std::vector<std::uint32_t> next = simplified(source, *from, level);
        if (next.empty()) continue;
        primitive.lods.push_back(std::move(next));
        from = &primitive.lods.back();
    }
}

struct TileGrid {
    float low_x = 0.0F;
    float low_z = 0.0F;
    float span = 1.0F;
    std::size_t across = 1;
    std::size_t down = 1;
};

// Số khối tối đa của một primitive: quá nhiều khối thì lệnh vẽ mỗi khung nhiều hơn lợi từ việc bỏ khối.
constexpr std::size_t kMaxTiles = std::size_t{1} << 16;

[[nodiscard]] bool indices_fit(const Primitive& primitive) noexcept {
    const auto outside = [&](std::uint32_t index) { return index >= primitive.vertices.size(); };
    return primitive.indices.size() % 3 == 0 && std::ranges::none_of(primitive.indices, outside);
}

// Lưới khối phủ hộp bao xz của đỉnh; rỗng khi toạ độ không hữu hạn hoặc số khối vượt trần.
[[nodiscard]] std::optional<TileGrid> grid_of(const Primitive& primitive, float span) {
    float low_x = std::numeric_limits<float>::max();
    float low_z = low_x;
    float high_x = std::numeric_limits<float>::lowest();
    float high_z = high_x;
    for (const Vertex& vertex : primitive.vertices) {
        low_x = std::min(low_x, vertex.position.x);
        high_x = std::max(high_x, vertex.position.x);
        low_z = std::min(low_z, vertex.position.z);
        high_z = std::max(high_z, vertex.position.z);
    }
    const double across = std::floor(static_cast<double>(high_x - low_x) / static_cast<double>(span)) + 1.0;
    const double down = std::floor(static_cast<double>(high_z - low_z) / static_cast<double>(span)) + 1.0;
    const bool is_sane = std::isfinite(across) && std::isfinite(down) && across * down <= static_cast<double>(kMaxTiles);
    if (!is_sane) return std::nullopt;
    return TileGrid{.low_x = low_x, .low_z = low_z, .span = span, .across = static_cast<std::size_t>(across),
        .down = static_cast<std::size_t>(down)};
}

[[nodiscard]] std::size_t axis_cell(float value, float low, const TileGrid& grid, std::size_t count) noexcept {
    const float along = (value - low) / grid.span;
    if (!(along > 0.0F)) return 0;
    return std::min(static_cast<std::size_t>(along), count - 1);
}

struct KeyedTriangle {
    std::size_t key = 0;
    std::uint32_t triangle = 0;
};

[[nodiscard]] KeyedTriangle key_of(const Primitive& primitive, const TileGrid& grid, std::uint32_t triangle) noexcept {
    const std::size_t corner = std::size_t{triangle} * 3;
    float sum_x = 0.0F;
    float sum_z = 0.0F;
    for (std::size_t k = 0; k < 3; ++k) {
        const Vertex& vertex = primitive.vertices[primitive.indices[corner + k]];
        sum_x += vertex.position.x;
        sum_z += vertex.position.z;
    }
    const std::size_t cell_x = axis_cell(sum_x / 3.0F, grid.low_x, grid, grid.across);
    const std::size_t cell_z = axis_cell(sum_z / 3.0F, grid.low_z, grid, grid.down);
    return {.key = cell_z * grid.across + cell_x, .triangle = triangle};
}

// Hình cầu bao của các đỉnh mà đoạn chỉ số [first, first + count) dùng: tâm hộp bao, bán kính tới đỉnh xa nhất.
[[nodiscard]] Tile tile_of(const Primitive& sorted, std::size_t first, std::size_t count) {
    math::Float3 low{.x = std::numeric_limits<float>::max(), .y = std::numeric_limits<float>::max(),
        .z = std::numeric_limits<float>::max()};
    math::Float3 high{.x = std::numeric_limits<float>::lowest(), .y = std::numeric_limits<float>::lowest(),
        .z = std::numeric_limits<float>::lowest()};
    for (std::size_t at = first; at < first + count; ++at) {
        const math::Float3& point = sorted.vertices[sorted.indices[at]].position;
        low = {.x = std::min(low.x, point.x), .y = std::min(low.y, point.y), .z = std::min(low.z, point.z)};
        high = {.x = std::max(high.x, point.x), .y = std::max(high.y, point.y), .z = std::max(high.z, point.z)};
    }
    Tile tile;
    tile.first_index = static_cast<std::uint32_t>(first);
    tile.index_count = static_cast<std::uint32_t>(count);
    tile.centre = {.x = (low.x + high.x) * 0.5F, .y = (low.y + high.y) * 0.5F, .z = (low.z + high.z) * 0.5F};
    float farthest = 0.0F;
    for (std::size_t at = first; at < first + count; ++at) {
        const math::Float3& point = sorted.vertices[sorted.indices[at]].position;
        const float dx = point.x - tile.centre.x;
        const float dy = point.y - tile.centre.y;
        const float dz = point.z - tile.centre.z;
        farthest = std::max(farthest, std::sqrt((dx * dx) + (dy * dy) + (dz * dz)));
    }
    tile.radius = farthest;
    return tile;
}

} // namespace

void build_tiles(Primitive& primitive, float span) {
    primitive.tiles.clear();
    const bool is_usable = span > 0.0F && std::isfinite(span) && !primitive.indices.empty() &&
        primitive.topology == Topology::kTriangles && indices_fit(primitive);
    if (!is_usable) return;
    const std::optional<TileGrid> grid = grid_of(primitive, span);
    if (!grid) return;
    const std::size_t triangles = primitive.indices.size() / 3;
    std::vector<KeyedTriangle> keyed;
    keyed.reserve(triangles);
    for (std::uint32_t triangle = 0; triangle < triangles; ++triangle) {
        keyed.push_back(key_of(primitive, *grid, triangle));
    }
    std::ranges::stable_sort(keyed, {}, &KeyedTriangle::key);
    std::vector<std::uint32_t> sorted;
    sorted.reserve(primitive.indices.size());
    for (const KeyedTriangle& entry : keyed) {
        const auto first = primitive.indices.begin() + static_cast<std::ptrdiff_t>(std::size_t{entry.triangle} * 3);
        sorted.insert(sorted.end(), first, first + 3);
    }
    primitive.indices = std::move(sorted);
    std::size_t begin = 0;
    while (begin < keyed.size()) {
        std::size_t end = begin;
        while (end < keyed.size() && keyed[end].key == keyed[begin].key) ++end;
        primitive.tiles.push_back(tile_of(primitive, begin * 3, (end - begin) * 3));
        begin = end;
    }
}

void build_lods(Model& model) {
    for (Mesh& mesh : model.meshes) {
        for (Primitive& primitive : mesh.primitives) {
            primitive.lods.clear();
            build_primitive_lods(primitive);
        }
    }
}

} // namespace game::resource
