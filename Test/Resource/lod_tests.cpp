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
 *    ra các mức giảm dần, mọi chỉ số nằm trong đỉnh, bỏ qua lưới skin và lưới
 *    nhỏ.
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

void lods_skip_skinned_and_small(Context& context) {
    resource::Model model;
    resource::Mesh mesh;
    resource::Primitive skinned = grid_primitive(32);
    skinned.vertices.front().weights = {.x = 1.0F, .y = 0.0F, .z = 0.0F, .w = 0.0F};
    mesh.primitives.push_back(std::move(skinned));
    mesh.primitives.push_back(grid_primitive(4));
    model.meshes.push_back(std::move(mesh));
    resource::build_lods(model);
    context.expect(model.meshes.front().primitives[0].lods.empty(), "lưới skin không giản lược");
    context.expect(model.meshes.front().primitives[1].lods.empty(), "lưới nhỏ không giản lược");
}

constexpr std::array kCases{
    Case{.name = "tiles_keep_every_triangle_once", .body = &tiles_keep_every_triangle_once},
    Case{.name = "tile_sphere_contains_its_vertices", .body = &tile_sphere_contains_its_vertices},
    Case{.name = "tiles_refuse_bad_input", .body = &tiles_refuse_bad_input},
    Case{.name = "lods_shrink_and_stay_in_range", .body = &lods_shrink_and_stay_in_range},
    Case{.name = "lods_skip_skinned_and_small", .body = &lods_skip_skinned_and_small},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "lod_tests: mọi ca phải qua");
    return 0;
}
