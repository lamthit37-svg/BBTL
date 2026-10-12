// Độ cao mặt công trình trên byte tự dựng. Không cần tệp .WCollision thật.
#include "collision/model.hpp"
#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <bit>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

void put_u32(std::vector<std::byte>& out, std::uint32_t value) {
    out.push_back(static_cast<std::byte>(value & 0xFFU));
    out.push_back(static_cast<std::byte>((value >> 8U) & 0xFFU));
    out.push_back(static_cast<std::byte>((value >> 16U) & 0xFFU));
    out.push_back(static_cast<std::byte>((value >> 24U) & 0xFFU));
}

void put_i32(std::vector<std::byte>& out, std::int32_t value) {
    put_u32(out, static_cast<std::uint32_t>(value));
}

void put_f32(std::vector<std::byte>& out, float value) {
    put_u32(out, std::bit_cast<std::uint32_t>(value));
}

void put_triangle(std::vector<std::byte>& out, float y, float x, float z) {
    put_f32(out, x - 1.0F);
    put_f32(out, y);
    put_f32(out, z - 1.0F);
    put_f32(out, x + 2.0F);
    put_f32(out, y);
    put_f32(out, z - 1.0F);
    put_f32(out, x);
    put_f32(out, y);
    put_f32(out, z + 2.0F);
}

// Một ô, các tam giác nằm ngang. Mã 1.
[[nodiscard]] std::vector<std::byte> cells_file(std::span<const float> heights, std::span<const float> xs,
    std::span<const float> zs) {
    std::vector<std::byte> bytes;
    put_u32(bytes, 0xFF000001U);
    put_i32(bytes, 1);
    put_i32(bytes, 0);
    put_i32(bytes, 0);
    put_i32(bytes, static_cast<std::int32_t>(heights.size()));
    for (std::size_t index = 0; index < heights.size(); ++index)
        put_triangle(bytes, heights[index], xs[index], zs[index]);
    return bytes;
}

[[nodiscard]] bool near(float actual, float expected) noexcept {
    return std::abs(actual - expected) < 1.0e-3F;
}

void empty_file_loads_and_misses(Context& context) {
    std::vector<std::byte> bytes;
    put_u32(bytes, 0xFF000001U);
    put_i32(bytes, 0);
    const std::expected<collision::Model, collision::LoadError> model = collision::load(bytes);
    context.expect(model.has_value(), "tệp rỗng nạp được");
    if (!model) return;
    context.expect(!model->height(0.0F, 0.0F), "không có mặt thì không có độ cao");
}

void one_triangle_reports_its_height(Context& context) {
    const std::array<float, 1> height{5.0F};
    const std::array<float, 1> at{0.0F};
    const std::vector<std::byte> bytes = cells_file(height, at, at);
    const std::expected<collision::Model, collision::LoadError> model = collision::load(bytes);
    context.expect(model.has_value(), "một tam giác nạp được");
    if (!model) return;
    const std::optional<float> hit = model->height(0.0F, 0.0F);
    context.expect(hit.has_value() && near(*hit, 5.0F), "tia từ y = 10000 trúng mặt y = 5");
    context.expect(!model->height(50.0F, 0.0F), "ngoài tam giác thì trượt");
}

void two_triangles_use_the_tree(Context& context) {
    const std::array<float, 2> height{5.0F, 8.0F};
    const std::array<float, 2> xs{0.0F, 10.0F};
    const std::array<float, 2> zs{0.0F, 0.0F};
    const std::vector<std::byte> bytes = cells_file(height, xs, zs);
    const std::expected<collision::Model, collision::LoadError> model = collision::load(bytes);
    context.expect(model.has_value(), "hai tam giác nạp được");
    if (!model) return;
    const std::optional<float> low = model->height(0.0F, 0.0F);
    const std::optional<float> high = model->height(10.0F, 0.0F);
    context.expect(low.has_value() && near(*low, 5.0F), "mặt thứ nhất");
    context.expect(high.has_value() && near(*high, 8.0F), "mặt thứ hai qua cây");
    const std::array<float, 3> origin{0.0F, 10000.0F, 0.0F};
    const std::array<float, 3> direction{0.0F, -1.0F, 0.0F};
    const std::optional<collision::Hit> point = model->raycast(origin, direction);
    context.expect(point.has_value() && near(point->y, 5.0F), "điểm trúng lấy cao độ mặt");
}

constexpr std::array kCases{
    Case{.name = "empty_file_loads_and_misses", .body = &empty_file_loads_and_misses},
    Case{.name = "one_triangle_reports_its_height", .body = &one_triangle_reports_its_height},
    Case{.name = "two_triangles_use_the_tree", .body = &two_triangles_use_the_tree},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "building_height_tests");
    return 0;
}
