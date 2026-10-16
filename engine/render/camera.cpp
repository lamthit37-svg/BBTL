/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/render/camera.cpp
 *  PHÂN HỆ   : Render / Camera
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Ma trận nhìn và chiếu của camera (look, posed, orbit, frame), góc dọc
 *    giữ khung tham chiếu trong tầm nhìn (fitted_fov_y), cắt khuất hộp và
 *    hình cầu, ma trận nút ở tư thế nghỉ và hộp bao của model.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
// Chỉ cho x86-64: đích ARM không có tính năng này, clang in cảnh báo rồi bỏ qua.
#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__) && defined(__x86_64__)
#pragma GCC target("sse4.1")
#endif
// Cây nút duyệt bằng ngăn xếp tường minh: cây sâu hàng nghìn nút không làm tràn stack, và nút bị
// trỏ hai lần hay nằm trên một vòng chỉ được tính một lần.
// Nguồn: Forge2 src/render/camera.cpp@d7fcd76 (rest_nodes, bounds_of) và TLBB Dev
// src/render/camera.cpp@e0d89a6 (frame_camera, orbit_camera, look_camera, box_in_view, frustum_of,
// sphere_in_view). Khác gốc: thân vòng lặp của rest_nodes và bounds_of tách thành place_next và
// add_node; không có bgfx; phép chiếu là độ sâu đảo; mặt xa của cắt khuất là z >= 0 thay cho w - z.
#include "render/camera.hpp"

#include "core/bits.hpp"
#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/quat.hpp"
#include "math/vector.hpp"
#include "render/view_size.hpp"
#include "resource/model.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <numbers>
#include <span>
#include <utility>
#include <vector>

namespace game::render {

namespace {

constexpr std::uint32_t kNoParent = std::numeric_limits<std::uint32_t>::max();
// Camera quay của Dev: góc nhìn dọc, khoảng lùi, mặt gần và xa theo bán kính.
constexpr float kFieldOfView = 60.0F;
constexpr float kEyeDistance = 3.2F;
constexpr float kNearRatio = 0.05F;
constexpr float kFarRatio = 8.0F;
// Hướng chếch ban đầu của camera quay, trước khi xoay quanh trục y.
constexpr float kOrbitX = 0.55F;
constexpr float kOrbitY = 0.45F;
constexpr float kOrbitZ = -1.0F;

// Một nút chờ tính, kèm cha của nó.
using Visit = std::pair<std::uint32_t, std::uint32_t>;
using math::Aabb;
using math::Matrix4;
using resource::Primitive;

// Vùng làm việc của rest_nodes: ma trận đã tính, nút đã gặp, ngăn xếp nút chờ.
struct Walk {
    std::vector<math::Matrix4> out;
    std::vector<std::uint8_t> seen;
    std::vector<Visit> stack;
};

void push_children(const resource::Node& node, std::uint32_t index, std::vector<Visit>& stack) {
    for (const std::uint32_t child : node.children) {
        stack.emplace_back(child, index);
    }
}

// Khác gốc: thân vòng lặp của rest_nodes tách ra đây. Lấy nút trên đỉnh ngăn xếp ra rồi tính nó.
void place_next(const resource::Model& model, Walk& walk) {
    const auto [index, parent] = walk.stack.back();
    walk.stack.pop_back();
    if (index >= model.nodes.size() || walk.seen.at(index) != 0) return;
    walk.seen.at(index) = 1;
    const resource::Node& node = model.nodes.at(index);
    walk.out.at(index) = parent == kNoParent ? node.local : walk.out.at(parent) * node.local;
    push_children(node, index, walk.stack);
}

void grow(math::Aabb& box, const math::Vector3& point) noexcept {
    box.min = math::min(box.min, point);
    box.max = math::max(box.max, point);
}

void add_primitive(Aabb& box, const Primitive& primitive, const Matrix4& placed) noexcept {
    for (const resource::Vertex& vertex : primitive.vertices) {
        const math::Point3 point(vertex.position.x, vertex.position.y, vertex.position.z);
        grow(box, (placed * point).xyz());
    }
}

void add_mesh(math::Aabb& box, const resource::Mesh& mesh, const math::Matrix4& placed) noexcept {
    for (const resource::Primitive& primitive : mesh.primitives) {
        add_primitive(box, primitive, placed);
    }
}

// Khác gốc: thân vòng lặp của bounds_of tách ra đây. Nút không mang lưới hợp lệ thì bỏ qua.
void add_node(math::Aabb& box, const resource::Model& model, std::span<const math::Matrix4> nodes, std::size_t index) {
    const resource::Node& node = model.nodes.at(index);
    if (!node.mesh || *node.mesh >= model.meshes.size()) return;
    const bool is_placed = !node.skin && index < nodes.size();
    const math::Matrix4 placed = is_placed ? core::at(nodes, index) : math::Matrix4::identity();
    add_mesh(box, model.meshes.at(*node.mesh), placed);
}

// Tỉ lệ rộng trên cao của khung vẽ; chiều cao 0 thì coi như khung vuông.
[[nodiscard]] float aspect_of(ViewSize size) noexcept {
    if (size.height == 0) return 1.0F;
    return static_cast<float>(size.width) / static_cast<float>(size.height);
}

// Phép chiếu tay phải, độ sâu đảo, theo góc nhìn DỌC của Lens (Ogre::Camera::setFOVy) đã chỉnh theo khung tham chiếu
// (fitted_fov_y); perspective_rh của math nhận góc ngang nên đổi qua tỉ lệ khung.
[[nodiscard]] math::Matrix4 perspective_of(const Lens& lens, float aspect) noexcept {
    const float lens_fov = lens.fov_degrees * (std::numbers::pi_v<float> / 180.0F);
    const float fov_y = fitted_fov_y(lens_fov, aspect, lens.reference_aspect);
    math::FovLens reversed;
    reversed.fov_x = 2.0F * std::atan(std::tan(fov_y * 0.5F) * aspect);
    reversed.aspect_inverse = 1.0F / aspect;
    // Độ sâu đảo: gần và xa đổi chỗ có chủ ý.
    reversed.z_near = lens.far_plane;
    reversed.z_far = lens.near_plane;
    return Matrix4::perspective_rh(reversed);
}

} // namespace

// Nửa bề ngang của khung tham chiếu trên mặt cách mắt một đơn vị là tan(fov_y / 2) * reference_aspect; khung hẹp hơn
// giữ đúng nửa bề ngang ấy, nên tan của nửa góc dọc mới là nó chia aspect.
float fitted_fov_y(float fov_y, float aspect, float reference_aspect) noexcept {
    const bool is_narrow = reference_aspect > 0.0F && aspect > 0.0F && aspect < reference_aspect;
    if (!is_narrow) return fov_y;
    const float half_width = std::tan(fov_y * 0.5F) * reference_aspect;
    return 2.0F * std::atan(half_width / aspect);
}

std::vector<math::Matrix4> rest_nodes(const resource::Model& model) {
    const std::size_t count = model.nodes.size();
    Walk walk;
    walk.out.assign(count, math::Matrix4::identity());
    walk.seen.assign(count, 0);
    walk.stack.reserve(count);
    for (const std::uint32_t root : model.roots) {
        walk.stack.emplace_back(root, kNoParent);
    }
    while (!walk.stack.empty()) {
        place_next(model, walk);
    }
    return std::move(walk.out);
}

math::Aabb bounds_of(const resource::Model& model, std::span<const math::Matrix4> nodes) {
    math::Aabb box;
    for (std::size_t index = 0; index < model.nodes.size(); ++index) {
        add_node(box, model, nodes, index);
    }
    return box;
}

// Hướng chếch kOrbit xoay quanh trục y một góc angle; khoảng lùi, góc nhìn và tỉ lệ mặt gần xa
// theo bán kính.
Camera orbit_camera(Orbit orbit, ViewSize size) noexcept {
    const math::Vector3 base = math::normalize(math::Vector3(kOrbitX, kOrbitY, kOrbitZ));
    const float cosine = std::cos(orbit.angle);
    const float sine = std::sin(orbit.angle);
    const float turned_x = (base.x() * cosine) - (base.z() * sine);
    const float turned_z = (base.x() * sine) + (base.z() * cosine);
    const math::Vector3 direction(turned_x, base.y(), turned_z);
    const float distance = orbit.radius * kEyeDistance;
    const math::Point3 eye(orbit.centre + (direction * distance));
    Lens lens;
    lens.fov_degrees = kFieldOfView;
    lens.near_plane = orbit.radius * kNearRatio;
    lens.far_plane = orbit.radius * kFarRatio;
    Camera camera;
    camera.view = math::Matrix4::look_at_rh(eye, math::Point3(orbit.centre), math::Vector3::y_axis());
    camera.projection = perspective_of(lens, aspect_of(size));
    return camera;
}

Camera look_camera(math::Point3 eye, math::Point3 target, Lens lens, ViewSize size) noexcept {
    Camera camera;
    camera.view = math::Matrix4::look_at_rh(eye, target, math::Vector3::y_axis());
    camera.projection = perspective_of(lens, aspect_of(size));
    return camera;
}

// Ba cột của ma trận quay là trục phải, lên và lùi của camera trong thế giới, đúng bộ ba mà
// look_at_rh tự dựng từ điểm nhìn; ma trận nhìn là nghịch đảo của phép đặt đó.
Camera posed_camera(math::Point3 eye, const math::Quat& turn, Lens lens, ViewSize size) noexcept {
    const math::Matrix3 axes(turn);
    const math::Vector3 origin(eye);
    const math::Matrix4 placed(axes, origin);
    Camera camera;
    camera.view = math::ortho_inverse(placed);
    camera.projection = perspective_of(lens, aspect_of(size));
    return camera;
}

namespace {

[[nodiscard]] math::Vector3 bounds_centre(SceneBounds bounds) noexcept {
    return (bounds.min + bounds.max) * 0.5F;
}

// Bán kính để đặt camera: ưu tiên bán kính khai trong asset, thiếu thì nửa đường chéo hộp.
[[nodiscard]] float bounds_radius(SceneBounds bounds) noexcept {
    if (bounds.radius > 0.0F) return bounds.radius;
    const float half_x = (bounds.max.x() - bounds.min.x()) * 0.5F;
    const float half_y = (bounds.max.y() - bounds.min.y()) * 0.5F;
    const float half_z = (bounds.max.z() - bounds.min.z()) * 0.5F;
    const float extent = std::sqrt((half_x * half_x) + (half_y * half_y) + (half_z * half_z));
    return extent > 0.0F ? extent : 1.0F;
}

// Ngoài một mặt khi giá trị âm. Mặt gần thay bằng w < 0 (sau mắt), rộng hơn mặt gần thật.
// Khác gốc: mặt xa là z (độ sâu đảo, z >= 0) thay cho w - z của depth [0, 1] và [-1, 1].
using ClipPlane = float (*)(math::Vector4);

constexpr std::array<ClipPlane, 6> kClipPlanes = {
    [](math::Vector4 point) { return point.x() + point.w(); },
    [](math::Vector4 point) { return point.w() - point.x(); },
    [](math::Vector4 point) { return point.y() + point.w(); },
    [](math::Vector4 point) { return point.w() - point.y(); },
    [](math::Vector4 point) { return point.z(); },
    [](math::Vector4 point) { return point.w(); },
};

[[nodiscard]] std::array<math::Vector4, 8> clip_corners(const math::Matrix4& clip, const SceneBounds& box) noexcept {
    std::array<math::Vector4, 8> corners{};
    for (std::size_t index = 0; index < corners.size(); ++index) {
        const float corner_x = (index & 1U) != 0U ? box.max.x() : box.min.x();
        const float corner_y = (index & 2U) != 0U ? box.max.y() : box.min.y();
        const float corner_z = (index & 4U) != 0U ? box.max.z() : box.min.z();
        const math::Point3 corner(corner_x, corner_y, corner_z);
        corners.at(index) = clip * corner;
    }
    return corners;
}

[[nodiscard]] bool all_outside(const std::array<math::Vector4, 8>& corners, ClipPlane plane) noexcept {
    const auto is_out = [plane](math::Vector4 point) { return plane(point) < 0.0F; };
    return std::ranges::all_of(corners, is_out);
}

// Hàng index của ma trận lưu theo cột: toạ độ clip thứ index là tích của hàng này với (x, y, z, 1).
[[nodiscard]] math::Vector4 row_of(const math::Matrix4& matrix, std::size_t index) noexcept {
    return {matrix[0][index], matrix[1][index], matrix[2][index], matrix[3][index]};
}

// Chia cho độ dài pháp tuyến để giá trị của mặt là khoảng cách; mặt suy biến giữ nguyên.
[[nodiscard]] math::Vector4 normalized_plane(math::Vector4 plane) noexcept {
    const float span = math::length(plane.xyz());
    if (!(span > 0.0F)) return plane;
    return plane / span;
}

} // namespace

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): min rồi max, chữ ký của TLBB Dev (HP-07)
SceneBounds bounds_with_radius(math::Vector3 low, math::Vector3 high) noexcept {
    const math::Vector3 half = (high - low) * 0.5F;
    const float extent = math::length(half);
    SceneBounds bounds;
    bounds.min = low;
    bounds.max = high;
    bounds.radius = extent > 0.0F ? extent : 1.0F;
    return bounds;
}

Camera frame_camera(SceneBounds bounds, ViewSize size) noexcept {
    const math::Vector3 centre = bounds_centre(bounds);
    const float radius = bounds_radius(bounds);
    const math::Vector3 direction = math::normalize(math::Vector3(kOrbitX, kOrbitY, kOrbitZ));
    const float distance = radius * kEyeDistance;
    const math::Vector3 offset = direction * distance;
    const math::Point3 eye = math::Point3(centre) + offset;
    Lens lens;
    lens.fov_degrees = kFieldOfView;
    lens.near_plane = radius * kNearRatio;
    lens.far_plane = radius * kFarRatio;
    Camera camera;
    camera.view = math::Matrix4::look_at_rh(eye, math::Point3(centre), math::Vector3::y_axis());
    camera.projection = perspective_of(lens, aspect_of(size));
    return camera;
}

bool box_in_view(const math::Matrix4& clip, const SceneBounds& box) noexcept {
    const std::array<math::Vector4, 8> corners = clip_corners(clip, box);
    const auto outside = [&corners](ClipPlane plane) { return all_outside(corners, plane); };
    return std::ranges::none_of(kClipPlanes, outside);
}

// Mặt trong không gian clip là hàng tổ hợp của ma trận clip (Gribb và Hartmann), cùng thứ tự với
// kClipPlanes. Khác gốc: mặt thứ năm là hàng z, vì độ sâu đảo có mặt xa tại z = 0.
Frustum frustum_of(const math::Matrix4& clip) noexcept {
    const math::Vector4 row_x = row_of(clip, 0);
    const math::Vector4 row_y = row_of(clip, 1);
    const math::Vector4 row_z = row_of(clip, 2);
    const math::Vector4 row_w = row_of(clip, 3);
    const std::array<math::Vector4, 6> raw{row_w + row_x, row_w - row_x, row_w + row_y, row_w - row_y, row_z, row_w};
    Frustum frustum;
    std::ranges::transform(raw, frustum.planes.begin(), normalized_plane);
    return frustum;
}

bool sphere_in_view(const Frustum& frustum, math::Vector3 centre, float radius) noexcept {
    const auto outside = [centre, radius](math::Vector4 plane) {
        const float distance = (plane.x() * centre.x()) + (plane.y() * centre.y()) + (plane.z() * centre.z());
        return distance + plane.w() < -radius;
    };
    return std::ranges::none_of(frustum.planes, outside);
}

} // namespace game::render

#if defined(__clang__) && defined(__x86_64__)
#pragma clang attribute pop
#endif
