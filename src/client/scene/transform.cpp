#include "scene/transform.hpp"

#include "scene/placement.hpp"

#include <algorithm>
#include <array>
#include <cstddef>

namespace game::scene {
namespace {

using Row = std::array<double, 4>;
using Rotation = std::array<std::array<double, 3>, 3>;

// Quaternion::ToRotationMatrix của OGRE 1.2.5, giữ thứ tự phép tính của gốc. Khác gốc: double thay
// Real (float); tên fTx, fTwx, fTxy... của gốc viết thành two_x, two_wx, two_xy...
[[nodiscard]] Rotation rotation_of(const Quaternion& turn) noexcept {
    const auto quat_x = static_cast<double>(turn.x);
    const auto quat_y = static_cast<double>(turn.y);
    const auto quat_z = static_cast<double>(turn.z);
    const auto quat_w = static_cast<double>(turn.w);
    const double two_x = 2.0 * quat_x;
    const double two_y = 2.0 * quat_y;
    const double two_z = 2.0 * quat_z;
    const double two_wx = two_x * quat_w;
    const double two_wy = two_y * quat_w;
    const double two_wz = two_z * quat_w;
    const double two_xx = two_x * quat_x;
    const double two_xy = two_y * quat_x;
    const double two_xz = two_z * quat_x;
    const double two_yy = two_y * quat_y;
    const double two_yz = two_z * quat_y;
    const double two_zz = two_z * quat_z;
    Rotation rows{};
    rows[0] = {1.0 - (two_yy + two_zz), two_xy - two_wz, two_xz + two_wy};
    rows[1] = {two_xy + two_wz, 1.0 - (two_xx + two_zz), two_yz - two_wx};
    rows[2] = {two_xz - two_wy, two_yz + two_wx, 1.0 - (two_xx + two_yy)};
    return rows;
}

// Một hàng của Matrix4::makeTransform: m[i][j] = rot[i][j] * tỉ lệ của cột j, cột cuối là phép dời.
[[nodiscard]] Row row_of(const std::array<double, 3>& turn, const Vector3& scale, double offset) {
    const auto scale_x = static_cast<double>(scale.x);
    const auto scale_y = static_cast<double>(scale.y);
    const auto scale_z = static_cast<double>(scale.z);
    return {turn[0] * scale_x, turn[1] * scale_y, turn[2] * scale_z, offset};
}

[[nodiscard]] double dot(const Row& row, const Point& point) noexcept {
    return (row[0] * point.x) + (row[1] * point.y) + (row[2] * point.z) + row[3];
}

// Góc thứ index của hộp: bit 0 chọn x, bit 1 chọn y, bit 2 chọn z; bit bật thì lấy high.
[[nodiscard]] Point corner(const Box& box, std::size_t index) noexcept {
    const bool is_high_x = (index & 1U) != 0;
    const bool is_high_y = (index & 2U) != 0;
    const bool is_high_z = (index & 4U) != 0;
    return {.x = is_high_x ? box.high.x : box.low.x,
        .y = is_high_y ? box.high.y : box.low.y,
        .z = is_high_z ? box.high.z : box.low.z};
}

void extend(Box& box, const Point& point) noexcept {
    box.low.x = std::min(box.low.x, point.x);
    box.low.y = std::min(box.low.y, point.y);
    box.low.z = std::min(box.low.z, point.z);
    box.high.x = std::max(box.high.x, point.x);
    box.high.y = std::max(box.high.y, point.y);
    box.high.z = std::max(box.high.z, point.z);
}

constexpr std::size_t kCorners = 8;

} // namespace

Transform world_transform(const Placement& placement) noexcept {
    const Rotation turn = rotation_of(placement.orientation);
    const Vector3& scale = placement.scale;
    const Vector3& position = placement.position;
    Transform transform;
    transform.rows[0] = row_of(turn[0], scale, static_cast<double>(position.x));
    transform.rows[1] = row_of(turn[1], scale, static_cast<double>(position.y));
    transform.rows[2] = row_of(turn[2], scale, static_cast<double>(position.z));
    return transform;
}

Point apply(const Transform& transform, const Point& point) noexcept {
    return {.x = dot(transform.rows[0], point), .y = dot(transform.rows[1], point), .z = dot(transform.rows[2], point)};
}

Box world_box(const Transform& transform, const Box& local) noexcept {
    const Point first = apply(transform, corner(local, 0));
    Box world{.low = first, .high = first};
    for (std::size_t index = 1; index < kCorners; ++index) {
        const Point moved = apply(transform, corner(local, index));
        extend(world, moved);
    }
    return world;
}

} // namespace game::scene
