/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Resource/lod_tests.cpp
 *  PHÂN HỆ   : Resource / Lod Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - LOD và chia khối: build_tiles chỉ sắp lại tam giác (không mất, không thêm,
 *    khối liền nhau phủ kín), từ chối đầu vào xấu mà không đổi gì; build_lods
 *    ra các mức giảm dần, mọi chỉ số nằm trong đỉnh; lưới có skin vẫn có mức
 *    thô còn lưới morph và lưới nhỏ thì bị bỏ qua.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "resource/lod.hpp"
#include "resource/model.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <map>
#include <utility>
#include <vector>

namespace game::test {
namespace {

// Lưới phẳng side x side ô trên mặt xz, mỗi ô hai tam giác, cao độ gợn nhẹ để meshopt không coi là phẳng hoàn toàn.
resource::Primitive grid_primitive(std::uint32_t side) {
    resource::Primitive primitive;
    for (std::uint32_t z = 0; z <= side; ++z) {
        for (std::uint32_t x = 0; x <= side; ++x) {
            resource::Vertex vertex;
            const auto fx = static_cast<float>(x);
            const auto fz = static_cast<float>(z);
            vertex.position = {.x = fx, .y = 0.3F * std::sin(fx * 0.7F) * std::cos(fz * 0.5F), .z = fz};
            vertex.normal = {.x = 0.0F, .y = 1.0F, .z = 0.0F};
            vertex.uv = {.x = fx / static_cast<float>(side), .y = fz / static_cast<float>(side)};
            primitive.vertices.push_back(vertex);
        }
    }
    const std::uint32_t row = side + 1;
    for (std::uint32_t z = 0; z < side; ++z) {
        for (std::uint32_t x = 0; x < side; ++x) {
            const std::uint32_t a = (z * row) + x;
            primitive.indices.insert(primitive.indices.end(), {a, a + row, a + 1, a + 1, a + row, a + row + 1});
        }
    }
    return primitive;
}

// Tam giác không phụ thuộc thứ tự bắt đầu quay vòng: xoay để chỉ số nhỏ nhất đứng đầu.
using Triangle = std::array<std::uint32_t, 3>;

std::map<Triangle, int> triangle_counts(const std::vector<std::uint32_t>& indices) {
    std::map<Triangle, int> counts;
    for (std::size_t corner = 0; corner + 2 < indices.size(); corner += 3) {
        Triangle triangle{indices[corner], indices[corner + 1], indices[corner + 2]};
        std::ranges::rotate(triangle, std::ranges::min_element(triangle));
        ++counts[triangle];
    }
    return counts;
}

void tiles_keep_every_triangle_once(Context& context) {
    resource::Primitive primitive = grid_primitive(8);
    const std::map<Triangle, int> before = triangle_counts(primitive.indices);
    resource::build_tiles(primitive, 2.0F);
    context.expect(primitive.tiles.size() == 16, "lưới 8x8 ô chia khối 2 ô thành 16 khối");
    context.expect(triangle_counts(primitive.indices) == before, "tập tam giác không đổi");
    std::uint32_t expected_first = 0;
    for (const resource::Tile& tile : primitive.tiles) {
        context.expect(tile.first_index == expected_first, "khối liền nhau, không hở");
        context.expect(tile.index_count % 3 == 0 && tile.index_count > 0, "khối gồm trọn tam giác");
        expected_first += tile.index_count;
    }
    context.expect(expected_first == primitive.indices.size(), "các khối phủ kín chỉ số");
}

void tile_sphere_contains_its_vertices(Context& context) {
    resource::Primitive primitive = grid_primitive(8);
    resource::build_tiles(primitive, 2.0F);
    for (const resource::Tile& tile : primitive.tiles) {
        for (std::uint32_t at = tile.first_index; at < tile.first_index + tile.index_count; ++at) {
            const math::Float3& point = primitive.vertices[primitive.indices[at]].position;
            const float dx = point.x - tile.centre.x;
            const float dy = point.y - tile.centre.y;
            const float dz = point.z - tile.centre.z;
            const float distance = std::sqrt((dx * dx) + (dy * dy) + (dz * dz));
            context.expect(distance <= tile.radius + 1.0e-4F, "đỉnh nằm trong hình cầu bao của khối");
        }
    }
}

void tiles_refuse_bad_input(Context& context) {
    resource::Primitive outside = grid_primitive(4);
    outside.indices.back() = 9999;
    const std::vector<std::uint32_t> kept = outside.indices;
    resource::build_tiles(outside, 2.0F);
    context.expect(outside.tiles.empty() && outside.indices == kept, "chỉ số ngoài đỉnh: không đổi");

    resource::Primitive flat = grid_primitive(4);
    const std::vector<std::uint32_t> original = flat.indices;
    resource::build_tiles(flat, 0.0F);
    context.expect(flat.tiles.empty() && flat.indices == original, "span 0: không đổi");
    resource::build_tiles(flat, std::numeric_limits<float>::quiet_NaN());
    context.expect(flat.tiles.empty() && flat.indices == original, "span NaN: không đổi");
    resource::build_tiles(flat, 1.0e-9F);
    context.expect(flat.tiles.empty() && flat.indices == original, "quá nhiều khối: không đổi");

    resource::Primitive broken = grid_primitive(4);
    broken.vertices.front().position.x = std::numeric_limits<float>::quiet_NaN();
    resource::build_tiles(broken, 2.0F);
    context.expect(broken.indices.size() == original.size(), "toạ độ NaN không làm mất tam giác");
}

void lods_shrink_and_stay_in_range(Context& context) {
    resource::Model model;
    resource::Mesh mesh;
    mesh.primitives.push_back(grid_primitive(32));
    model.meshes.push_back(std::move(mesh));
    resource::build_lods(model);
    const resource::Primitive& primitive = model.meshes.front().primitives.front();
    context.expect(!primitive.lods.empty(), "lưới 2048 tam giác có mức thô");
    std::size_t previous = primitive.indices.size();
    for (const std::vector<std::uint32_t>& level : primitive.lods) {
        context.expect(level.size() % 3 == 0 && level.size() >= 3, "mức gồm trọn tam giác");
        context.expect(level.size() < previous, "mỗi mức ít chỉ số hơn mức trước");
        const auto outside = [&](std::uint32_t index) { return index >= primitive.vertices.size(); };
        context.expect(std::ranges::none_of(level, outside), "chỉ số nằm trong đỉnh");
        previous = level.size();
    }
}

// Lưới skin hai khớp, nửa trái khớp 0 và nửa phải khớp 1: mức thô vẫn có và chỉ chọn lại chỉ số của đỉnh gốc.
void lods_cover_skinned(Context& context) {
    resource::Model model;
    resource::Mesh mesh;
    resource::Primitive skinned = grid_primitive(32);
    const float middle = skinned.vertices[skinned.vertices.size() / 2].position.x;
    for (resource::Vertex& vertex : skinned.vertices) {
        const bool is_left = vertex.position.x < middle;
        vertex.joints = {static_cast<std::uint16_t>(is_left ? 0 : 1), 0, 0, 0};
        vertex.weights = {.x = 1.0F, .y = 0.0F, .z = 0.0F, .w = 0.0F};
    }
    mesh.primitives.push_back(std::move(skinned));
    model.meshes.push_back(std::move(mesh));
    resource::build_lods(model);
    const resource::Primitive& primitive = model.meshes.front().primitives.front();
    context.expect(!primitive.lods.empty(), "lưới skin có mức thô");
    for (const std::vector<std::uint32_t>& level : primitive.lods) {
        const auto outside = [&](std::uint32_t index) { return index >= primitive.vertices.size(); };
        context.expect(level.size() % 3 == 0 && std::ranges::none_of(level, outside), "mức skin gồm chỉ số của đỉnh gốc");
        context.expect(level.size() < primitive.indices.size(), "mức skin ít chỉ số hơn mức 0");
    }
}

// Pháp tuyến của mặt tam giác; tam giác suy biến lấy hướng lên.
[[nodiscard]] math::Float3 face_normal(const std::array<math::Float3, 3>& points) {
    const math::Float3 along{.x = points[1].x - points[0].x, .y = points[1].y - points[0].y, .z = points[1].z - points[0].z};
    const math::Float3 across{.x = points[2].x - points[0].x, .y = points[2].y - points[0].y, .z = points[2].z - points[0].z};
    const math::Float3 cross{.x = (along.y * across.z) - (along.z * across.y),
        .y = (along.z * across.x) - (along.x * across.z), .z = (along.x * across.y) - (along.y * across.x)};
    const float length = std::sqrt((cross.x * cross.x) + (cross.y * cross.y) + (cross.z * cross.z));
    if (!(length > 0.0F)) return {.x = 0.0F, .y = 1.0F, .z = 0.0F};
    return {.x = cross.x / length, .y = cross.y / length, .z = cross.z / length};
}

// Chép tam giác ở corner của smooth thành ba đỉnh riêng, cao độ nhân height, pháp tuyến theo mặt.
void add_face(resource::Primitive& faceted, const resource::Primitive& smooth, std::size_t corner, float height) {
    std::array<resource::Vertex, 3> corners{};
    std::array<math::Float3, 3> points{};
    for (std::size_t k = 0; k < 3; ++k) {
        corners.at(k) = smooth.vertices[smooth.indices[corner + k]];
        corners.at(k).position.y *= height;
        points.at(k) = corners.at(k).position;
    }
    const math::Float3 normal = face_normal(points);
    const auto first = static_cast<std::uint32_t>(faceted.vertices.size());
    for (resource::Vertex& vertex : corners) {
        vertex.normal = normal;
        faceted.vertices.push_back(vertex);
    }
    faceted.indices.insert(faceted.indices.end(), {first, first + 1, first + 2});
}

// Lưới rời đỉnh như đá flat shading của cảnh: lưới gợn sóng side x side ô, mỗi tam giác giữ ba đỉnh riêng. Cách giữ
// tô-pô không gộp nổi đỉnh rời nên mức thô rơi vào sloppy, và sloppy hay giảm quá đích, xuống dưới cả đích của mức sau
// (đo 2026-10-16 ở cảnh đăng nhập: N=714 chỉ số, 660 đỉnh, mức 1 còn 24 chỉ số trong khi đích của mức 2 là 27).
resource::Primitive faceted_primitive(std::uint32_t side, float height) {
    const resource::Primitive smooth = grid_primitive(side);
    resource::Primitive faceted;
    for (std::size_t corner = 0; corner + 2 < smooth.indices.size(); corner += 3) {
        add_face(faceted, smooth, corner, height);
    }
    return faceted;
}

[[nodiscard]] bool levels_shrink(const resource::Primitive& primitive) {
    std::size_t previous = primitive.indices.size();
    for (const std::vector<std::uint32_t>& level : primitive.lods) {
        if (level.size() % 3 != 0 || level.size() < 3 || level.size() >= previous) return false;
        previous = level.size();
    }
    return true;
}

// Đích của một mức không bao giờ vượt số chỉ số của mức trước nó: meshopt đòi target <= index_count, bản dựng có assert
// thì dừng hẳn chương trình (gặp khi nạp cảnh đăng nhập với --quality mobile ngày 2026-10-16).
void lods_survive_faceted(Context& context) {
    constexpr std::array kHeights{0.3F, 1.0F, 3.0F, 8.0F};
    for (std::uint32_t round = 0; round < 48; ++round) {
        resource::Model model;
        resource::Mesh mesh;
        mesh.primitives.push_back(faceted_primitive(8 + (round % 12), kHeights.at(round / 12)));
        model.meshes.push_back(std::move(mesh));
        resource::build_lods(model);
        context.expect(levels_shrink(model.meshes.front().primitives.front()), "mức của lưới rời đỉnh vẫn giảm dần");
    }
}

// Diện tích phủ của các tam giác chiếu xuống mặt xz. Lưới cao độ giản lược đúng thì giữ diện tích; gom cụm sloppy làm
// thủng hoặc chồng mặt nên diện tích lệch.
[[nodiscard]] float covered_area(const resource::Primitive& primitive, const std::vector<std::uint32_t>& indices) {
    float area = 0.0F;
    for (std::size_t corner = 0; corner + 2 < indices.size(); corner += 3) {
        const math::Float3& first = primitive.vertices[indices[corner]].position;
        const math::Float3& second = primitive.vertices[indices[corner + 1]].position;
        const math::Float3& third = primitive.vertices[indices[corner + 2]].position;
        const float cross = ((second.x - first.x) * (third.z - first.z)) - ((second.z - first.z) * (third.x - first.x));
        area += 0.5F * std::fabs(cross);
    }
    return area;
}

// Đá flat shading (mọi đỉnh nằm trên ranh giới thuộc tính) vẫn có mức 35% mà không cần gom cụm, và mức thô nhất vẫn phủ
// đúng mặt gốc. Trước đây cả hai mức thô của loại lưới này rơi vào sloppy: 121 và 131 lưới ở cảnh đăng nhập (đo
// 2026-10-16), đá gần camera thành mảng tam giác nhọn trên tablet.
void lods_keep_faceted_shape(Context& context) {
    resource::Model model;
    resource::Mesh mesh;
    mesh.primitives.push_back(faceted_primitive(16, 1.0F));
    model.meshes.push_back(std::move(mesh));
    resource::build_lods(model);
    const resource::Primitive& primitive = model.meshes.front().primitives.front();
    context.expect(primitive.lods.size() == 3, "lưới rời đỉnh có đủ ba mức");
    if (primitive.lods.empty()) return;
    const float whole = covered_area(primitive, primitive.indices);
    const float coarse = covered_area(primitive, primitive.lods.back());
    context.expect(std::fabs(coarse - whole) <= whole * 0.1F, "mức thô nhất vẫn phủ đúng mặt gốc");
}

void lods_skip_morph_and_small(Context& context) {
    resource::Model model;
    resource::Mesh mesh;
    resource::Primitive morphed = grid_primitive(32);
    morphed.targets.emplace_back();
    mesh.primitives.push_back(std::move(morphed));
    mesh.primitives.push_back(grid_primitive(4));
    model.meshes.push_back(std::move(mesh));
    resource::build_lods(model);
    context.expect(model.meshes.front().primitives[0].lods.empty(), "lưới morph không giản lược");
    context.expect(model.meshes.front().primitives[1].lods.empty(), "lưới nhỏ không giản lược");
}

constexpr std::array kCases{
    Case{.name = "tiles_keep_every_triangle_once", .body = &tiles_keep_every_triangle_once},
    Case{.name = "tile_sphere_contains_its_vertices", .body = &tile_sphere_contains_its_vertices},
    Case{.name = "tiles_refuse_bad_input", .body = &tiles_refuse_bad_input},
    Case{.name = "lods_shrink_and_stay_in_range", .body = &lods_shrink_and_stay_in_range},
    Case{.name = "lods_cover_skinned", .body = &lods_cover_skinned},
    Case{.name = "lods_survive_faceted", .body = &lods_survive_faceted},
    Case{.name = "lods_keep_faceted_shape", .body = &lods_keep_faceted_shape},
    Case{.name = "lods_skip_morph_and_small", .body = &lods_skip_morph_and_small},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "lod_tests: mọi ca phải qua");
    return 0;
}
