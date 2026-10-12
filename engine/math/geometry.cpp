// Phép giao và phân rã ma trận. Công thức giữ như common.hpp của _Ref, trừ các chỗ đã ghi ở
// geometry.hpp. Slab của tia với hộp theo Real-Time Collision Detection (Ericson); phân rã ma trận
// theo GLM và TransformationMatrix của WebCore.
// Nguồn: Forge2 src/math/geometry.cpp@d7fcd76. Khác gốc (so với Forge2): enumerator của
// FrustumTest mang tiền tố k; header dùng trực tiếp được include đủ; hai vòng for có câu if trong
// thân (intersect của tia với Aabb, aabb_touches_frustum) đưa điều kiện dừng lên điều kiện lặp,
// thứ tự xét trục giữ nguyên; Vector2 khởi tạo bằng tên thành viên; NOLINT kèm lý do cho
// clip_axis và corners_beyond.
#include "math/geometry.hpp"

#include "math/matrix.hpp"
#include "math/quat.hpp"
#include "math/types.hpp"
#include "math/vector.hpp"

#include <algorithm>
#include <array>
#include <cfloat>
#include <cmath>
#include <cstddef>
#include <limits>
#include <optional>
#include <span>

// NOLINTBEGIN(readability-identifier-length): tên theo ký hiệu toán (a, b, v, m, q, t, x, y...),
// đúng với hiến pháp IV.1 cho phạm vi vài dòng.
namespace game::math {

namespace {

// Tám đỉnh của hộp theo trục.
[[nodiscard]] std::array<Vector3, 8> corners_of(const Aabb& box) noexcept {
    const Float3 lo = store(box.min);
    const Float3 hi = store(box.max);
    return {
        Vector3(lo.x, hi.y, hi.z),
        Vector3(lo.x, lo.y, hi.z),
        Vector3(hi.x, lo.y, hi.z),
        Vector3(hi.x, hi.y, hi.z),
        Vector3(hi.x, hi.y, lo.z),
        Vector3(hi.x, lo.y, lo.z),
        Vector3(lo.x, lo.y, lo.z),
        Vector3(lo.x, hi.y, lo.z),
    };
}

void grow(Aabb& box, const Vector3& point) noexcept {
    box.min = min(box.min, point);
    box.max = max(box.max, point);
}

// Khoảng tham số [enter, leave] của tia còn nằm trong các slab đã xét.
struct Span {
    float enter = 0.0F;
    float leave = std::numeric_limits<float>::max();
};

// Thu hẹp span theo slab [low, high] của một trục; sai khi tia trượt khỏi slab.
// Gốc rồi hướng của tia, rồi hai mặt slab như clamp(v, low, high) (ngoại lệ của API-03).
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
[[nodiscard]] bool clip_axis(Span& span, float origin, float direction, float low, float high) {
    const bool parallel = std::abs(direction) < FLT_EPSILON;
    if (parallel) return origin >= low && origin <= high;
    const float inverse = 1.0F / direction;
    const float first = (low - origin) * inverse;
    const float second = (high - origin) * inverse;
    span.enter = std::max(span.enter, std::min(first, second));
    span.leave = std::min(span.leave, std::max(first, second));
    return span.enter <= span.leave;
}

// Ma trận suy biến khi thể tích của ba cột đã chuẩn hoá (1 khi vuông góc, 0 khi phụ thuộc nhau) gần
// 0. So theo thang tương đối để tỉ lệ nhỏ đều như 0,001 không bị nhận nhầm là suy biến: gốc so
// |det| với FLT_EPSILON tuyệt đối, và det của ma trận tỉ lệ s là s^3. Cột có độ dài 0, vô cùng hay
// NaN cũng là suy biến (phép so viết phủ định để bắt NaN).
[[nodiscard]] bool is_singular(const Matrix3& linear) noexcept {
    const Vector3 a = linear.col0();
    const Vector3 b = linear.col1();
    const Vector3 c = linear.col2();
    const float length_a = length(a);
    const float length_b = length(b);
    const float length_c = length(c);
    const bool is_usable = length_a > 0.0F && length_b > 0.0F && length_c > 0.0F;
    if (!is_usable) return true;
    const float volume = dot(c / length_c, cross(a / length_a, b / length_b));
    return !(std::abs(volume) > FLT_EPSILON);
}

// Điểm NDC đưa ngược về thế giới, w = 1.
[[nodiscard]] Vector4 unproject(const Matrix4& inverse_vp, float x, float y, float z) noexcept {
    const Vector4 point = inverse_vp * Vector4(x, y, z, 1.0F);
    return {point.xyz() / point.w(), 1.0F};
}

// Cả tám đỉnh hộp nằm phía ngoài một mặt của khối nhìn.
[[nodiscard]] bool box_outside(const Vector4& plane, const std::array<Vector3, 8>& corners) {
    const auto outside = [&plane](const Vector3& corner) { return dot(plane, Vector4(corner, 1.0F)) < 0.0F; };
    return std::ranges::all_of(corners, outside);
}

// Cả tám đỉnh khối nhìn nằm về một phía của hộp trên một trục.
// low rồi high, như clamp
// (ngoại lệ của API-03).
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
[[nodiscard]] bool corners_beyond(const std::array<Vector4, 8>& points, std::size_t axis, float low, float high) {
    const auto above = [axis, high](const Vector4& point) { return point[axis] > high; };
    const auto below = [axis, low](const Vector4& point) { return point[axis] < low; };
    return std::ranges::all_of(points, above) || std::ranges::all_of(points, below);
}
// NOLINTEND(bugprone-easily-swappable-parameters)

} // namespace

Ray transform(const Ray& ray, const Matrix4& m) noexcept {
    const Vector4 origin = m * Vector4(ray.origin, 1.0F);
    const Vector4 direction = m * Vector4(ray.direction, 0.0F);
    return {.origin = origin.xyz() / origin.w(), .direction = normalize(direction.xyz())};
}

Aabb bounds(std::span<const Vector3> points) noexcept {
    Aabb box;
    for (const Vector3& point : points) {
        grow(box, point);
    }
    return box;
}

Aabb transform(const Aabb& box, const Matrix4& m) noexcept {
    Aabb moved;
    for (const Vector3& corner : corners_of(box)) {
        grow(moved, (m * Vector4(corner, 1.0F)).xyz());
    }
    return moved;
}

Obb transform(const Obb& box, const Matrix4& m) noexcept {
    const Vector3 x = (m * Vector4(box.x * box.half_extents.x(), 0.0F)).xyz();
    const Vector3 y = (m * Vector4(box.y * box.half_extents.y(), 0.0F)).xyz();
    const Vector3 z = (m * Vector4(box.z * box.half_extents.z(), 0.0F)).xyz();
    const Vector3 lengths(length(x), length(y), length(z));
    return {
        .center = (m * Vector4(box.center, 1.0F)).xyz(),
        .half_extents = lengths,
        .x = x / lengths.x(),
        .y = y / lengths.y(),
        .z = z / lengths.z(),
    };
}

std::optional<float> ray_plane_distance(const Ray& ray, const Plane& plane) noexcept {
    constexpr float kSteep = 1e-4F;
    constexpr float kFarthest = 1e4F;
    constexpr float kOnPlane = 1e-3F;
    const float slope = dot(plane.normal, ray.direction);
    const float offset = dot(plane.normal, ray.origin) + plane.d;
    if (std::abs(slope) > kSteep) return -offset / slope;
    // Gần song song: nhận khi giao điểm chưa chạy ra quá xa.
    const bool reachable = slope != 0.0F && std::abs(offset / slope) < kFarthest;
    if (reachable) return -offset / slope;
    if (std::abs(offset) < kOnPlane) return 0.0F;
    return std::nullopt;
}

std::optional<Vector3> intersect(const Ray& ray, const Plane& plane) noexcept {
    const std::optional<float> t = ray_plane_distance(ray, plane);
    if (!t || *t < 0.0F) return std::nullopt;
    return at(ray, *t);
}

std::optional<float> intersect(const Ray& ray, const Aabb& box) noexcept {
    const bool empty = box.min[0] > box.max[0] || box.min[1] > box.max[1] || box.min[2] > box.max[2];
    if (empty) return std::nullopt;
    Span span;
    bool has_overlap = true;
    // Khác gốc: gốc viết if (...) return trong thân vòng lặp;
    // ở đây kết quả nằm ở điều kiện lặp, thứ tự dừng như cũ.
    for (std::size_t axis = 0; has_overlap && axis < 3; ++axis) {
        const float low = box.min[axis];
        const float high = box.max[axis];
        has_overlap = clip_axis(span, ray.origin[axis], ray.direction[axis], low, high);
    }
    if (!has_overlap) return std::nullopt;
    return span.enter;
}

// Đưa tia về hệ toạ độ của hộp, gốc ở góc nhỏ nhất, rồi giao với hộp theo trục [0, 2 * nửa cỡ].
std::optional<float> intersect(const Ray& ray, const Obb& box) noexcept {
    const Vector3 corner =
        box.center - (box.x * box.half_extents.x()) - (box.y * box.half_extents.y()) - (box.z * box.half_extents.z());
    const Matrix4 local_to_world(Matrix3(box.x, box.y, box.z), corner);
    const Ray local = transform(ray, ortho_inverse(local_to_world));
    return intersect(local, Aabb{.min = Vector3::zero(), .max = box.half_extents * 2.0F});
}

std::optional<Vector2> intersect_lines(Vector2 a, Vector2 b, Vector2 c, Vector2 d) noexcept {
    const float a1 = b.y - a.y;
    const float b1 = a.x - b.x;
    const float c1 = (a1 * a.x) + (b1 * a.y);
    const float a2 = d.y - c.y;
    const float b2 = c.x - d.x;
    const float c2 = (a2 * c.x) + (b2 * c.y);
    const float determinant = (a1 * b2) - (a2 * b1);
    if (determinant == 0.0F) return std::nullopt;
    const float inverse = 1.0F / determinant;
    return Vector2{
        .x = ((b2 * c1) - (b1 * c2)) * inverse,
        .y = ((a1 * c2) - (a2 * c1)) * inverse,
    };
}

void set_corners(Frustum& frustum, const Matrix4& view_projection) noexcept {
    const Matrix4 inverse_vp = inverse(view_projection);
    frustum.near_top_left = unproject(inverse_vp, -1.0F, 1.0F, 0.0F);
    frustum.near_top_right = unproject(inverse_vp, 1.0F, 1.0F, 0.0F);
    frustum.near_bottom_left = unproject(inverse_vp, -1.0F, -1.0F, 0.0F);
    frustum.near_bottom_right = unproject(inverse_vp, 1.0F, -1.0F, 0.0F);
    frustum.far_top_left = unproject(inverse_vp, -1.0F, 1.0F, 1.0F);
    frustum.far_top_right = unproject(inverse_vp, 1.0F, 1.0F, 1.0F);
    frustum.far_bottom_left = unproject(inverse_vp, -1.0F, -1.0F, 1.0F);
    frustum.far_bottom_right = unproject(inverse_vp, 1.0F, -1.0F, 1.0F);
}

Frustum make_frustum(const Matrix4& view_projection) noexcept {
    const ClipPlanes planes = clip_planes(view_projection, true);
    Frustum frustum{
        .near_plane = planes.z_near,
        .far_plane = planes.z_far,
        .top_plane = planes.top,
        .bottom_plane = planes.bottom,
        .left_plane = planes.left,
        .right_plane = planes.right,
    };
    set_corners(frustum, view_projection);
    return frustum;
}

Vector4 frustum_plane(const Matrix4& inverse_view_projection, const Vector3& normal, const Vector3& tangent,
    float distance) noexcept {
    const Vector3 bitangent = normalize(cross(tangent, normal));
    const Vector3 base = normal * distance;
    Vector4 point_a = inverse_view_projection * Vector4(base + tangent, 1.0F);
    Vector4 point_b = inverse_view_projection * Vector4(base, 1.0F);
    Vector4 point_c = inverse_view_projection * Vector4(base + bitangent, 1.0F);
    point_a /= point_a.w();
    point_b /= point_b.w();
    point_c /= point_c.w();
    const Vector3 edge_a = point_b.xyz() - point_a.xyz();
    const Vector3 edge_c = point_b.xyz() - point_c.xyz();
    const Vector3 direction = normalize(cross(edge_a, edge_c));
    return {direction, -dot(direction, point_b.xyz())};
}

Frustum frustum_from_rect(const Matrix4& view_projection, const ScreenRect& rect, Float2 screen) noexcept {
    const Matrix4 inverse_vp = inverse(view_projection);
    const float x_min = ((rect.x_min / screen.x) * 2.0F) - 1.0F;
    const float x_max = ((rect.x_max / screen.x) * 2.0F) - 1.0F;
    const float y_min = (((screen.y - rect.y_max) / screen.y) * 2.0F) - 1.0F;
    const float y_max = (((screen.y - rect.y_min) / screen.y) * 2.0F) - 1.0F;
    const Vector3 forward = Vector3::z_axis();
    Frustum frustum;
    frustum.right_plane = frustum_plane(inverse_vp, Vector3::x_axis(), forward, x_max);
    frustum.left_plane = frustum_plane(inverse_vp, -Vector3::x_axis(), forward, -x_min);
    frustum.top_plane = frustum_plane(inverse_vp, Vector3::y_axis(), -forward, y_max);
    frustum.bottom_plane = frustum_plane(inverse_vp, -Vector3::y_axis(), -forward, -y_min);
    return frustum;
}

bool aabb_touches_frustum(const Aabb& box, const Frustum& frustum, FrustumTest test) noexcept {
    const std::array<Vector4, 6> planes{frustum.bottom_plane, frustum.top_plane, frustum.left_plane,
        frustum.right_plane, frustum.near_plane, frustum.far_plane};
    const std::array<Vector3, 8> corners = corners_of(box);
    const auto outside = [&corners](const Vector4& plane) { return box_outside(plane, corners); };
    if (std::ranges::any_of(planes, outside)) return false;
    if (test == FrustumTest::kPlanesOnly) return true;
    const std::array<Vector4, 8> points{
        frustum.near_bottom_left,
        frustum.near_bottom_right,
        frustum.near_top_left,
        frustum.near_top_right,
        frustum.far_bottom_left,
        frustum.far_bottom_right,
        frustum.far_top_left,
        frustum.far_top_right,
    };
    bool is_separated = false;
    // Khác gốc: gốc viết if (...) return trong thân vòng lặp;
    // ở đây kết quả nằm ở điều kiện lặp, thứ tự dừng như cũ.
    for (std::size_t axis = 0; !is_separated && axis < 3; ++axis) {
        is_separated = corners_beyond(points, axis, box.min[axis], box.max[axis]);
    }
    return !is_separated;
}

std::optional<AffineTransform> decompose(const Matrix4& m) noexcept {
    const float w = m.at(3, 3);
    if (std::abs(w) < FLT_EPSILON) return std::nullopt;
    const Matrix3 linear = m.upper3x3() * (1.0F / w);
    if (is_singular(linear)) return std::nullopt;
    // Gram-Schmidt trên ba cột: lấy tỉ lệ từng trục, bỏ phần xiên.
    Vector3 x = linear.col0();
    Vector3 y = linear.col1();
    Vector3 z = linear.col2();
    Vector3 scale(length(x), 0.0F, 0.0F);
    x /= scale.x();
    y = y + (x * -dot(x, y));
    scale.set_y(length(y));
    y /= scale.y();
    z = z + (x * -dot(x, z));
    z = z + (y * -dot(y, z));
    scale.set_z(length(z));
    z /= scale.z();
    // Định thức âm: hệ toạ độ bị lật. Đổi dấu cả ba trục và cả ba tỉ lệ để phần quay còn là quay.
    const bool flipped = dot(x, cross(y, z)) < 0.0F;
    const float sign = flipped ? -1.0F : 1.0F;
    return AffineTransform{
        .translation = m.translation() / w,
        .rotation = Quat(Matrix3(x * sign, y * sign, z * sign)),
        .scale = scale * sign,
    };
}

Vector3 euler_angles(const Matrix3& rotation) noexcept {
    const float r11 = rotation.col0().x();
    const float r12 = rotation.col0().y();
    const float r13 = rotation.col0().z();
    const float r23 = rotation.col1().z();
    const float r33 = rotation.col2().z();
    const float angle_x = std::atan2(r23, r33);
    const float angle_y = std::atan2(-r13, std::sqrt((r23 * r23) + (r33 * r33)));
    const float angle_z = std::atan2(r12, r11);
    return {angle_x, angle_y, angle_z};
}

// Cột c = e_c * (plane . light) - light * plane[c].
Matrix4 shadow_matrix(const Vector4& plane, const Vector4& light) noexcept {
    const float d =
        (plane.x() * light.x()) + (plane.y() * light.y()) + (plane.z() * light.z()) + (plane.w() * light.w());
    const Vector4 col0 = (Vector4::x_axis() * d) - (light * plane.x());
    const Vector4 col1 = (Vector4::y_axis() * d) - (light * plane.y());
    const Vector4 col2 = (Vector4::z_axis() * d) - (light * plane.z());
    const Vector4 col3 = (Vector4::w_axis() * d) - (light * plane.w());
    return {col0, col1, col2, col3};
}

} // namespace game::math
// NOLINTEND(readability-identifier-length)
