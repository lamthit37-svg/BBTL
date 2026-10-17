/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/resource/lod.cpp
 *  PHÂN HỆ   : Resource / Lod
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - LOD bằng meshoptimizer, mỗi mức giản lược từ mức trước, luôn trong trần
 *    sai số hình học; gom cụm sloppy chỉ là đường cuối. Biên không khoá: vật
 *    cảnh là mảnh rời. Bỏ lưới morph. Lưới skin chỉ chọn lại chỉ số đỉnh gốc,
 *    khớp và trọng số đi kèm như thuộc tính để không gộp hai đỉnh khác khớp:
 *    vật cảnh TLBB gần như đều mang xương dù đứng yên, bỏ skin là bỏ gần hết
 *    LOD.
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

using Indices = std::vector<std::uint32_t>;

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

constexpr std::array<Level, 3> kLevels{{
    {.keep = 0.35, .error = 0.05F, .allow_sloppy = false},
    {.keep = 0.12, .error = 0.12F, .allow_sloppy = true},
    {.keep = 0.04, .error = 0.3F, .allow_sloppy = true},
}};

// Normal 3, uv 2, màu rgb 3. Trọng số theo meshoptimizer: vị trí là 1.
constexpr std::size_t kBaseAttributes = 8;
// Lưới có skin thêm bốn trọng số skin rồi bốn chỉ số khớp (0 ở ô trọng số 0). Chỉ số khớp lệch
// một đơn vị đã cho sai số 0,25, lớn hơn mọi sai số cho phép của kLevels nên hai đỉnh khác khớp
// không bao giờ bị gộp.
constexpr std::size_t kSkinAttributes = kBaseAttributes + 8;
constexpr std::array<float, kSkinAttributes> kWeights{0.5F, 0.5F, 0.5F, 1.0F, 1.0F, 0.25F, 0.25F,
    0.25F, 2.0F, 2.0F, 2.0F, 2.0F, 0.25F, 0.25F, 0.25F, 0.25F};

// Lưới tam giác không morph. Có skin hay không do is_skinned nói.
[[nodiscard]] bool is_lodable(const Primitive& primitive) noexcept {
    return primitive.topology == Topology::kTriangles && primitive.targets.empty();
}

[[nodiscard]] bool is_skinned(const Primitive& primitive) noexcept {
    const auto weighted = [](const Vertex& vertex) {
        return vertex.weights.x + vertex.weights.y + vertex.weights.z + vertex.weights.w > 0.0F;
    };
    return std::ranges::any_of(primitive.vertices, weighted);
}

[[nodiscard]] std::array<float, 4> weights_of(const Vertex& vertex) noexcept {
    return {vertex.weights.x, vertex.weights.y, vertex.weights.z, vertex.weights.w};
}

// Chỉ số khớp của ô k nếu ô đó có trọng số, 0 nếu không (ô trống có thể mang số rác).
[[nodiscard]] float joint_of(const Vertex& vertex, std::size_t slot) noexcept {
    const std::array<float, 4> weight = weights_of(vertex);
    return weight.at(slot) > 0.0F ? static_cast<float>(vertex.joints.at(slot)) : 0.0F;
}

// Normal, uv, màu: đúng thứ tự tám trọng số đầu của kWeights.
void append_base(std::vector<float>& out, const Vertex& vertex) {
    out.insert(out.end(), {vertex.normal.x, vertex.normal.y, vertex.normal.z});
    out.insert(out.end(), {vertex.uv.x, vertex.uv.y});
    out.insert(out.end(), {vertex.color.x, vertex.color.y, vertex.color.z});
}

// Trọng số skin rồi chỉ số khớp: tám trọng số cuối của kWeights.
void append_skin(std::vector<float>& out, const Vertex& vertex) {
    const std::array<float, 4> weights = weights_of(vertex);
    out.insert(out.end(), weights.begin(), weights.end());
    for (std::size_t slot = 0; slot < 4; ++slot) {
        out.push_back(joint_of(vertex, slot));
    }
}

[[nodiscard]] std::vector<float> attributes_of(const Primitive& primitive, std::size_t count) {
    std::vector<float> out;
    out.reserve(primitive.vertices.size() * count);
    for (const Vertex& vertex : primitive.vertices) {
        append_base(out, vertex);
        if (count != kBaseAttributes) append_skin(out, vertex);
    }
    return out;
}

struct Source {
    const Primitive* primitive = nullptr;
    const std::vector<float>* attributes = nullptr;
    // Số thuộc tính mỗi đỉnh trong attributes: kBaseAttributes hoặc kSkinAttributes.
    std::size_t count = kBaseAttributes;
};

// Thứ tự thử một mức, đẹp trước: giữ normal, uv, màu; rồi cho gộp qua ranh giới thuộc tính
// (Permissive), vì đá flat shading của cảnh có ranh giới ở mọi đỉnh nên cách đầu không gộp nổi gì;
// rồi chỉ vị trí. Cả ba bỏ dần mảnh rời nhỏ (Prune, lá và cỏ) và giữ trần sai số hình học. Gom cụm
// sloppy không giữ tô-pô là đường cuối, chỉ cho hai mức thô, và cũng chỉ trong trần sai số của mức:
// trước đây nó được nhân bốn (tới 120% cỡ lưới) và là thứ biến đá gần camera trên tablet thành
// mảng tam giác nhọn (đo 2026-10-16, cảnh đăng nhập: 121 và 131 lưới ở hai mức thô đi đường này).
enum class Method : std::uint8_t { kWithAttributes, kAcrossSeams, kPositionOnly, kSloppy };

constexpr std::array<Method, 4> kMethods{
    Method::kWithAttributes, Method::kAcrossSeams, Method::kPositionOnly, Method::kSloppy};

constexpr unsigned int kPrune = meshopt_SimplifyPrune;
constexpr unsigned int kAcross = meshopt_SimplifyPrune | meshopt_SimplifyPermissive;

struct Attempt {
    const Source* source = nullptr;
    const Indices* from = nullptr;
    std::size_t target = 0;
    float error = 0.0F;
};

// Đầu vào chung của mọi cách giản lược: chỉ số của mức trước và vị trí đỉnh gốc.
struct Input {
    const std::uint32_t* indices = nullptr;
    std::size_t index_count = 0;
    const float* positions = nullptr;
    std::size_t vertex_count = 0;
};

[[nodiscard]] Input input_of(const Attempt& attempt) noexcept {
    const std::vector<Vertex>& vertices = attempt.source->primitive->vertices;
    const Indices& from = *attempt.from;
    return {.indices = from.data(),
        .index_count = from.size(),
        .positions = &vertices.front().position.x,
        .vertex_count = vertices.size()};
}

// Giữ normal, uv, màu (và skin) theo kWeights; kAcrossSeams cho gộp qua ranh giới thuộc tính.
[[nodiscard]] std::size_t simplify_attributes(Method method, const Attempt& attempt, Indices& out) {
    const Input input = input_of(attempt);
    const Source& source = *attempt.source;
    const std::size_t stride = source.count * sizeof(float);
    const unsigned int options = method == Method::kAcrossSeams ? kAcross : kPrune;
    float error = 0.0F;
    return meshopt_simplifyWithAttributes(out.data(), input.indices, input.index_count,
        input.positions, input.vertex_count, sizeof(Vertex), source.attributes->data(), stride,
        kWeights.data(), source.count, nullptr, attempt.target, attempt.error, options, &error);
}

// Chỉ vị trí: bỏ ràng buộc thuộc tính mà hai cách trên không gỡ được.
[[nodiscard]] std::size_t simplify_positions(const Attempt& attempt, Indices& out) {
    const Input input = input_of(attempt);
    float error = 0.0F;
    return meshopt_simplify(out.data(), input.indices, input.index_count, input.positions,
        input.vertex_count, sizeof(Vertex), attempt.target, attempt.error, kAcross, &error);
}

// Gom cụm không giữ tô-pô: đường cuối, chỉ cho hai mức thô.
[[nodiscard]] std::size_t simplify_sloppy(const Attempt& attempt, Indices& out) {
    const Input input = input_of(attempt);
    float error = 0.0F;
    return meshopt_simplifySloppy(out.data(), input.indices, input.index_count, input.positions,
        input.vertex_count, sizeof(Vertex), nullptr, attempt.target, attempt.error, &error);
}

[[nodiscard]] std::size_t run_method(Method method, const Attempt& attempt, Indices& out) {
    switch (method) {
    case Method::kWithAttributes:
    case Method::kAcrossSeams: return simplify_attributes(method, attempt, out);
    case Method::kPositionOnly: return simplify_positions(attempt, out);
    case Method::kSloppy: return simplify_sloppy(attempt, out);
    }
    return 0;
}

// Một mức từ `from`; rỗng khi không cách nào giảm đủ.
[[nodiscard]] Indices simplified(const Source& source, const Indices& from, const Level& level) {
    const std::vector<Vertex>& vertices = source.primitive->vertices;
    const auto base_count = static_cast<double>(source.primitive->indices.size());
    const auto wanted = static_cast<std::size_t>(base_count * level.keep);
    const std::size_t target = std::max(wanted, kFloorIndices) / 3 * 3;
    const Attempt attempt{.source = &source, .from = &from, .target = target, .error = level.error};
    const auto from_count = static_cast<double>(from.size());
    const auto limit = static_cast<std::size_t>(from_count * kMinShrink);
    // Đích tính theo mức 0 nhưng đầu vào là mức trước: sloppy hay giảm quá đích (nhất là lưới rời
    // đỉnh, đo 2026-10-16: N=714, mức 1 còn 24 chỉ số, đích mức 2 là 27). Mức trước đã thô tới đây
    // thì mức này thừa; meshopt cũng đòi target <= index_count, bản dựng có assert thì dừng hẳn
    // chương trình.
    if (attempt.target >= limit) return {};
    Indices out(from.size());
    for (const Method method : kMethods) {
        if (method == Method::kSloppy && !level.allow_sloppy) break;
        const std::size_t kept = run_method(method, attempt, out);
        if (kept < 3 || kept > limit) continue;
        out.resize(kept);
        // Thứ tự tam giác theo vertex cache: mức thô vẫn chạy nhanh trên GPU có cache đỉnh.
        Indices ordered(kept);
        meshopt_optimizeVertexCache(ordered.data(), out.data(), kept, vertices.size());
        return ordered;
    }
    return {};
}

void build_primitive_lods(Primitive& primitive) {
    const bool is_small = primitive.indices.size() < kMinIndices || primitive.vertices.empty();
    if (!is_lodable(primitive) || is_small) return;
    const std::size_t count = is_skinned(primitive) ? kSkinAttributes : kBaseAttributes;
    const std::vector<float> attributes = attributes_of(primitive, count);
    const Source source{.primitive = &primitive, .attributes = &attributes, .count = count};
    const Indices* from = &primitive.indices;
    for (const Level& level : kLevels) {
        Indices next = simplified(source, *from, level);
        if (next.empty()) continue;
        primitive.lods.push_back(std::move(next));
        from = &primitive.lods.back();
    }
}

void drop_mesh_lods(Mesh& mesh) noexcept {
    for (Primitive& primitive : mesh.primitives)
        primitive.lods.clear();
}

void build_mesh_lods(Mesh& mesh) {
    for (Primitive& primitive : mesh.primitives) {
        primitive.lods.clear();
        build_primitive_lods(primitive);
    }
}

struct TileGrid {
    float low_x = 0.0F;
    float low_z = 0.0F;
    float span = 1.0F;
    std::size_t across = 1;
    std::size_t down = 1;
};

// Trần số khối của một primitive: nhiều khối quá thì lệnh vẽ mỗi khung tốn hơn lợi từ việc bỏ khối.
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
    const auto step = static_cast<double>(span);
    const double across = std::floor(static_cast<double>(high_x - low_x) / step) + 1.0;
    const double down = std::floor(static_cast<double>(high_z - low_z) / step) + 1.0;
    const bool is_finite = std::isfinite(across) && std::isfinite(down);
    const bool is_sane = is_finite && across * down <= static_cast<double>(kMaxTiles);
    if (!is_sane) return std::nullopt;
    const auto columns = static_cast<std::size_t>(across);
    const auto rows = static_cast<std::size_t>(down);
    return TileGrid{.low_x = low_x, .low_z = low_z, .span = span, .across = columns, .down = rows};
}

[[nodiscard]] std::size_t axis_cell(float value, float low, const TileGrid& grid,
    std::size_t count) noexcept {
    const float along = (value - low) / grid.span;
    if (!(along > 0.0F)) return 0;
    return std::min(static_cast<std::size_t>(along), count - 1);
}

struct KeyedTriangle {
    std::size_t key = 0;
    std::uint32_t triangle = 0;
};

[[nodiscard]] KeyedTriangle key_of(const Primitive& primitive, const TileGrid& grid,
    std::uint32_t triangle) noexcept {
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

[[nodiscard]] math::Float3 corner_min(const math::Float3& lhs, const math::Float3& rhs) noexcept {
    return {.x = std::min(lhs.x, rhs.x), .y = std::min(lhs.y, rhs.y), .z = std::min(lhs.z, rhs.z)};
}

[[nodiscard]] math::Float3 corner_max(const math::Float3& lhs, const math::Float3& rhs) noexcept {
    return {.x = std::max(lhs.x, rhs.x), .y = std::max(lhs.y, rhs.y), .z = std::max(lhs.z, rhs.z)};
}

[[nodiscard]] math::Float3 centre_of(const math::Float3& lhs, const math::Float3& rhs) noexcept {
    return {.x = (lhs.x + rhs.x) * 0.5F, .y = (lhs.y + rhs.y) * 0.5F, .z = (lhs.z + rhs.z) * 0.5F};
}

// Hình cầu bao của các đỉnh mà đoạn chỉ số [first, first + count) dùng: tâm hộp bao, bán kính tới
// đỉnh xa nhất.
[[nodiscard]] Tile tile_of(const Primitive& sorted, std::size_t first, std::size_t count) {
    constexpr float kMax = std::numeric_limits<float>::max();
    constexpr float kLowest = std::numeric_limits<float>::lowest();
    math::Float3 low{.x = kMax, .y = kMax, .z = kMax};
    math::Float3 high{.x = kLowest, .y = kLowest, .z = kLowest};
    for (std::size_t at = first; at < first + count; ++at) {
        const math::Float3& point = sorted.vertices[sorted.indices[at]].position;
        low = corner_min(low, point);
        high = corner_max(high, point);
    }
    Tile tile;
    tile.first_index = static_cast<std::uint32_t>(first);
    tile.index_count = static_cast<std::uint32_t>(count);
    tile.centre = centre_of(low, high);
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

// Cuối dãy tam giác cùng khối bắt đầu ở begin; keyed đã sắp theo khoá.
[[nodiscard]] std::size_t run_end(const std::vector<KeyedTriangle>& keyed, std::size_t begin) {
    std::size_t end = begin;
    while (end < keyed.size() && keyed[end].key == keyed[begin].key)
        ++end;
    return end;
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
    Indices sorted;
    sorted.reserve(primitive.indices.size());
    for (const KeyedTriangle& entry : keyed) {
        const std::size_t corner = std::size_t{entry.triangle} * 3;
        const auto first = primitive.indices.begin() + static_cast<std::ptrdiff_t>(corner);
        sorted.insert(sorted.end(), first, first + 3);
    }
    primitive.indices = std::move(sorted);
    std::size_t begin = 0;
    while (begin < keyed.size()) {
        const std::size_t end = run_end(keyed, begin);
        primitive.tiles.push_back(tile_of(primitive, begin * 3, (end - begin) * 3));
        begin = end;
    }
}

void build_lods(Model& model) {
    for (Mesh& mesh : model.meshes) {
        build_mesh_lods(mesh);
    }
    model.has_lods = true;
}

void drop_lods(Model& model) noexcept {
    for (Mesh& mesh : model.meshes)
        drop_mesh_lods(mesh);
    model.has_lods = false;
}

} // namespace game::resource
