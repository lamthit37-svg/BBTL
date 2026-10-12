// Test của scene/transform: ma trận đặt vật thể của cảnh theo đúng OGRE 1.2.5 của client gốc
// (Matrix4::makeTransform, Quaternion::ToRotationMatrix): tỉ lệ trước, quay sau, dời cuối; quay
// tính thẳng từ quaternion đọc trong tệp, KHÔNG chuẩn hoá; hệ tay phải, Y hướng lên. Số kỳ vọng
// tính tay từ công thức của mã gốc.
#include "core/check.hpp"
#include "scene/placement.hpp"
#include "scene/transform.hpp"
#include "test.hpp"

#include <array>
#include <cmath>

namespace game::test {
namespace {

using scene::Box;
using scene::Placement;
using scene::Point;
using scene::Transform;

// sin và cos của 45 độ đã làm tròn về float, như số đọc từ tệp cảnh.
constexpr float kHalf = 0.70710678F;
// Sai số do kHalf * kHalf * 2 không đúng bằng 1 ở float.
constexpr double kLoose = 1e-5;

[[nodiscard]] bool is_near(const Point& left, const Point& right, double tolerance) noexcept {
    const bool is_x = std::abs(left.x - right.x) <= tolerance;
    const bool is_y = std::abs(left.y - right.y) <= tolerance;
    return is_x && is_y && std::abs(left.z - right.z) <= tolerance;
}

void default_placement_leaves_points_alone(Context& context) noexcept {
    const Transform transform = scene::world_transform(Placement{});
    const Point moved = scene::apply(transform, {.x = 1.5, .y = -2.0, .z = 3.25});
    context.expect(is_near(moved, {.x = 1.5, .y = -2.0, .z = 3.25}, 0.0), "phép đặt mặc định");
}

void rows_hold_scale_and_translation(Context& context) noexcept {
    Placement placement;
    placement.position = {.x = 5.0F, .y = 6.0F, .z = 7.0F};
    placement.scale = {.x = 2.0F, .y = 3.0F, .z = 4.0F};
    const Transform transform = scene::world_transform(placement);
    using Row = std::array<double, 4>;
    context.expect(transform.rows[0] == Row{2.0, 0.0, 0.0, 5.0}, "hàng 0: tỉ lệ x, dời x");
    context.expect(transform.rows[1] == Row{0.0, 3.0, 0.0, 6.0}, "hàng 1: tỉ lệ y, dời y");
    context.expect(transform.rows[2] == Row{0.0, 0.0, 4.0, 7.0}, "hàng 2: tỉ lệ z, dời z");
}

void scale_then_rotation_then_translation(Context& context) noexcept {
    Placement placement;
    placement.position = {.x = 10.0F, .y = 20.0F, .z = 30.0F};
    // Quay 90 độ quanh Z (x y z w).
    placement.orientation = {.x = 0.0F, .y = 0.0F, .z = kHalf, .w = kHalf};
    placement.scale = {.x = 2.0F, .y = 3.0F, .z = 4.0F};
    const Transform transform = scene::world_transform(placement);
    // (1,1,1) nhân tỉ lệ thành (2,3,4); quay quanh Z thành (-3,2,4); dời thành (7,22,34).
    const Point moved = scene::apply(transform, {.x = 1.0, .y = 1.0, .z = 1.0});
    context.expect(is_near(moved, {.x = 7.0, .y = 22.0, .z = 34.0}, kLoose), "thứ tự T * R * S");
}

void rotation_about_y_is_right_handed(Context& context) noexcept {
    Placement placement;
    placement.orientation = {.x = 0.0F, .y = kHalf, .z = 0.0F, .w = kHalf};
    const Transform transform = scene::world_transform(placement);
    const Point from_x = scene::apply(transform, {.x = 1.0, .y = 0.0, .z = 0.0});
    const Point from_z = scene::apply(transform, {.x = 0.0, .y = 0.0, .z = 1.0});
    context.expect(is_near(from_x, {.x = 0.0, .y = 0.0, .z = -1.0}, kLoose), "trục X về -Z");
    context.expect(is_near(from_z, {.x = 1.0, .y = 0.0, .z = 0.0}, kLoose), "trục Z về +X");
}

void quaternion_is_used_without_normalising(Context& context) noexcept {
    Placement placement;
    // Quaternion dài căn 2: OGRE của client gốc không chuẩn hoá ở Node::setOrientation.
    placement.orientation = {.x = 0.0F, .y = 1.0F, .z = 0.0F, .w = 1.0F};
    const Transform transform = scene::world_transform(placement);
    const Point from_x = scene::apply(transform, {.x = 1.0, .y = 0.0, .z = 0.0});
    context.expect(is_near(from_x, {.x = -1.0, .y = 0.0, .z = -2.0}, 0.0), "cột 0 là (-1, 0, -2)");
}

void world_box_covers_all_eight_corners(Context& context) noexcept {
    Placement placement;
    placement.position = {.x = 10.0F, .y = 0.0F, .z = 0.0F};
    placement.orientation = {.x = 0.0F, .y = 0.0F, .z = kHalf, .w = kHalf};
    const Box local{.low = {.x = -1.0, .y = -2.0, .z = -3.0}, .high = {.x = 1.0, .y = 2.0, .z = 3.0}};
    const Box world = scene::world_box(scene::world_transform(placement), local);
    context.expect(is_near(world.low, {.x = 8.0, .y = -1.0, .z = -3.0}, kLoose), "góc thấp");
    context.expect(is_near(world.high, {.x = 12.0, .y = 1.0, .z = 3.0}, kLoose), "góc cao");
}

void world_box_stays_ordered_under_mirror_scale(Context& context) noexcept {
    Placement placement;
    placement.scale = {.x = -2.0F, .y = 1.0F, .z = 1.0F};
    const Box local{.low = {.x = 1.0, .y = 0.0, .z = 0.0}, .high = {.x = 3.0, .y = 1.0, .z = 1.0}};
    const Box world = scene::world_box(scene::world_transform(placement), local);
    context.expect(is_near(world.low, {.x = -6.0, .y = 0.0, .z = 0.0}, 0.0), "thấp sau khi lật");
    context.expect(is_near(world.high, {.x = -2.0, .y = 1.0, .z = 1.0}, 0.0), "cao sau khi lật");
}

constexpr std::array kCases{
    Case{.name = "default_placement_leaves_points_alone", .body = &default_placement_leaves_points_alone},
    Case{.name = "rows_hold_scale_and_translation", .body = &rows_hold_scale_and_translation},
    Case{.name = "scale_then_rotation_then_translation", .body = &scale_then_rotation_then_translation},
    Case{.name = "rotation_about_y_is_right_handed", .body = &rotation_about_y_is_right_handed},
    Case{.name = "quaternion_is_used_without_normalising", .body = &quaternion_is_used_without_normalising},
    Case{.name = "world_box_covers_all_eight_corners", .body = &world_box_covers_all_eight_corners},
    Case{.name = "world_box_stays_ordered_under_mirror_scale", .body = &world_box_stays_ordered_under_mirror_scale},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "transform_tests: mọi ca phải qua");
    return 0;
}
