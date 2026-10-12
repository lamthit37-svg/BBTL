// check.py dịch tệp này một mình, không kèm -msse4.1 mà CMake gắn vào game_math.
#if defined(__clang__)
#pragma clang attribute push(__attribute__((target("sse4.1"))), apply_to = function)
#elif defined(__GNUC__)
#pragma GCC target("sse4.1")
#endif
// Hiện thực CameraBase. Phần tử ma trận đối chiếu D3DX theo cột: _11 là col0.x.
#include "camera/lens.hpp"

#include "math/geometry.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <limits>

namespace game::camera {
namespace {

using Mat4 = math::Matrix4;
using Point = math::Point3;
using Vec3 = math::Vector3;
using Vec4 = math::Vector4;

constexpr float kAxisEpsilon = std::numeric_limits<float>::epsilon();

struct HalfExtent {
    float width = 0.0F;
    float height = 0.0F;
};

struct Extent {
    float x = -std::numeric_limits<float>::max();
    float y = -std::numeric_limits<float>::max();
};

struct FaceRow {
    math::CubeFace face = math::CubeFace::kPositiveZ;
    float target_x = 0.0F;
    float target_y = 0.0F;
    float target_z = 1.0F;
    float up_x = 0.0F;
    float up_y = 1.0F;
    float up_z = 0.0F;
};

constexpr std::array<FaceRow, 6> kFaces{{
    {.face = math::CubeFace::kPositiveX,
        .target_x = 1.0F,
        .target_y = 0.0F,
        .target_z = 0.0F,
        .up_x = 0.0F,
        .up_y = 1.0F,
        .up_z = 0.0F},
    {.face = math::CubeFace::kNegativeX,
        .target_x = -1.0F,
        .target_y = 0.0F,
        .target_z = 0.0F,
        .up_x = 0.0F,
        .up_y = 1.0F,
        .up_z = 0.0F},
    {.face = math::CubeFace::kPositiveY,
        .target_x = 0.0F,
        .target_y = 1.0F,
        .target_z = 0.0F,
        .up_x = 0.0F,
        .up_y = 0.0F,
        .up_z = -1.0F},
    {.face = math::CubeFace::kNegativeY,
        .target_x = 0.0F,
        .target_y = -1.0F,
        .target_z = 0.0F,
        .up_x = 0.0F,
        .up_y = 0.0F,
        .up_z = 1.0F},
    {.face = math::CubeFace::kPositiveZ,
        .target_x = 0.0F,
        .target_y = 0.0F,
        .target_z = 1.0F,
        .up_x = 0.0F,
        .up_y = 1.0F,
        .up_z = 0.0F},
    {.face = math::CubeFace::kNegativeZ,
        .target_x = 0.0F,
        .target_y = 0.0F,
        .target_z = -1.0F,
        .up_x = 0.0F,
        .up_y = 1.0F,
        .up_z = 0.0F},
}};

[[nodiscard]] bool has_area(Viewport viewport) noexcept {
    return viewport.width > 0.0F && viewport.height > 0.0F;
}

void store_view(Lens& lens, const Mat4& view) noexcept {
    lens.view = view;
    lens.inverse_view = math::inverse(view);
}

void store_projection(Lens& lens, const Mat4& projection) noexcept {
    lens.projection = projection;
    lens.inverse_projection = math::inverse(projection);
}

[[nodiscard]] float horizontal_fov(float fov_y, Viewport viewport) noexcept {
    const float aspect = viewport.width / viewport.height;
    const float half = std::tan(fov_y * 0.5F);
    return std::atan(half * aspect) * 2.0F;
}

[[nodiscard]] math::FovLens fov_of(float fov_y, Viewport viewport, DepthRange depth) noexcept {
    math::FovLens lens;
    lens.fov_x = horizontal_fov(fov_y, viewport);
    lens.aspect_inverse = viewport.height / viewport.width;
    lens.z_near = depth.z_near;
    lens.z_far = depth.z_far;
    return lens;
}

[[nodiscard]] math::ViewWindow window_of(Viewport viewport, DepthRange depth) noexcept {
    math::ViewWindow window;
    window.left = viewport.width * -0.5F;
    window.right = viewport.width * 0.5F;
    window.bottom = viewport.height * -0.5F;
    window.top = viewport.height * 0.5F;
    window.z_near = depth.z_near;
    window.z_far = depth.z_far;
    return window;
}

[[nodiscard]] Mat4 perspective_matrix(float fov_y, Viewport viewport, DepthRange depth) noexcept {
    return Mat4::perspective_lh(fov_of(fov_y, viewport, depth));
}

[[nodiscard]] Mat4 ortho_matrix(Viewport viewport, DepthRange depth) noexcept {
    return Mat4::orthographic_lh(window_of(viewport, depth));
}

[[nodiscard]] Vec3 upward_for(Point eye, Point target) noexcept {
    const Vec3 toward = target - eye;
    const float along_x = std::fabs(toward.x());
    const float along_z = std::fabs(toward.z());
    if (along_x < kAxisEpsilon && along_z < kAxisEpsilon && toward.y() < 0.0F) {
        return Vec3::z_axis();
    }
    const Vec3 right = cross(Vec3::y_axis(), toward);
    return cross(toward, right);
}

void take_face(Pose& pose, const FaceRow& row, math::CubeFace face) noexcept {
    if (row.face != face) return;
    pose.target = {row.target_x, row.target_y, row.target_z};
    pose.up = {row.up_x, row.up_y, row.up_z};
}

[[nodiscard]] Pose face_pose(math::CubeFace face) noexcept {
    Pose pose;
    pose.target = Point(Vec3::z_axis());
    pose.up = Vec3::y_axis();
    for (const FaceRow& row : kFaces) {
        take_face(pose, row, face);
    }
    return pose;
}

[[nodiscard]] Point corner_of(const math::Aabb& box, std::uint32_t index) noexcept {
    float along_x = box.min.x();
    float along_y = box.min.y();
    float along_z = box.min.z();
    if ((index & 1U) != 0U) along_x = box.max.x();
    if ((index & 2U) != 0U) along_y = box.max.y();
    if ((index & 4U) != 0U) along_z = box.max.z();
    return {along_x, along_y, along_z};
}

void widen(Extent& extent, float sample_x, float sample_y) noexcept {
    extent.x = std::max(extent.x, sample_x);
    extent.y = std::max(extent.y, sample_y);
}

void widen_perspective(Extent& extent, Vec3 view_point) noexcept {
    const float ratio_x = view_point.x() / view_point.z();
    const float ratio_y = view_point.y() / view_point.z();
    widen(extent, ratio_x, ratio_y);
}

void widen_ortho(Extent& extent, const Lens& lens, Vec3 view_point) noexcept {
    const float depth = lens.depth.z_near / (lens.depth.z_near - lens.depth.z_far);
    const float denominator = (depth * view_point.z()) + 1.0F;
    const float scale_x = (2.0F / lens.viewport.width) / denominator;
    const float scale_y = (2.0F / lens.viewport.height) / denominator;
    widen(extent, view_point.x() * scale_x, view_point.y() * scale_y);
}

struct BoxView {
    const Lens* lens = nullptr;
    const math::Aabb* box = nullptr;
};

void scan_one(Extent& extent, const BoxView& view, std::uint32_t index) noexcept {
    const Point corner = corner_of(*view.box, index);
    const Vec4 viewed = view.lens->view * corner;
    if (view.lens->fov_y > 0.0F) widen_perspective(extent, viewed.xyz());
    if (view.lens->fov_y <= 0.0F) widen_ortho(extent, *view.lens, viewed.xyz());
}

void scan_corners(Extent& extent, const Lens& lens, const math::Aabb& box) noexcept {
    BoxView view;
    view.lens = &lens;
    view.box = &box;
    for (std::uint32_t index = 0; index < 8U; ++index) {
        scan_one(extent, view, index);
    }
}

void write_scale(Lens& lens, float scale_x, float scale_y) noexcept {
    Vec4 column_x = lens.projection.col0();
    column_x.set_x(scale_x);
    lens.projection.set_col(0, column_x);
    Vec4 column_y = lens.projection.col1();
    column_y.set_y(scale_y);
    lens.projection.set_col(1, column_y);
    lens.inverse_projection = math::inverse(lens.projection);
}

[[nodiscard]] HalfExtent near_extent(const Lens& lens) noexcept {
    const float aspect = lens.viewport.width / lens.viewport.height;
    HalfExtent extent;
    extent.width = std::tan(lens.fov_y * 0.5F) * lens.depth.z_near * aspect;
    extent.height = extent.width / aspect;
    return extent;
}

void swap_ortho(Lens& lens, DepthRange depth) noexcept {
    Viewport swapped;
    swapped.width = lens.viewport.height;
    swapped.height = lens.viewport.width;
    set_ortho(lens, swapped, depth);
}

} // namespace

void set_look_at(Lens& lens, const Pose& pose) noexcept {
    const Vec3 toward = pose.target - pose.eye;
    if (length(toward) <= kAxisEpsilon) return;
    lens.eye = pose.eye;
    lens.look_at = pose.target;
    lens.up = pose.up;
    store_view(lens, Mat4::look_at_lh(pose.eye, pose.target, pose.up));
}

void set_look_at(Lens& lens, Aim aim) noexcept {
    Pose pose;
    pose.eye = aim.eye;
    pose.target = aim.target;
    pose.up = upward_for(aim.eye, aim.target);
    set_look_at(lens, pose);
}

void set_look_at(Lens& lens, Aim aim, math::CubeFace face) noexcept {
    set_look_at(lens, aim);
    const Pose cube = face_pose(face);
    const Point origin{};
    const Mat4 face_view = Mat4::look_at_lh(origin, cube.target, cube.up);
    store_view(lens, face_view * lens.view);
}

void set_perspective(Lens& lens, Viewport viewport, float fov_y, DepthRange depth) noexcept {
    if (!has_area(viewport)) return;
    lens.viewport = viewport;
    lens.depth = depth;
    lens.fov_y = fov_y;
    store_projection(lens, perspective_matrix(fov_y, viewport, depth));
}

void set_ortho(Lens& lens, Viewport viewport, DepthRange depth) noexcept {
    if (!has_area(viewport)) return;
    lens.viewport = viewport;
    lens.depth = depth;
    lens.fov_y = 0.0F;
    store_projection(lens, ortho_matrix(viewport, depth));
}

void set_z_far(Lens& lens, float z_far) noexcept {
    if (lens.fov_y > 0.0F) {
        DepthRange depth = lens.depth;
        depth.z_far = z_far;
        set_perspective(lens, lens.viewport, lens.fov_y, depth);
        return;
    }
    DepthRange depth;
    depth.z_near = lens.depth.z_near;
    depth.z_far = z_far;
    swap_ortho(lens, depth);
}

void set_z_near(Lens& lens, float z_near) noexcept {
    if (lens.fov_y > 0.0F) {
        DepthRange depth = lens.depth;
        depth.z_near = z_near;
        set_perspective(lens, lens.viewport, lens.fov_y, depth);
        return;
    }
    DepthRange depth;
    depth.z_near = z_near;
    depth.z_far = lens.depth.z_far;
    swap_ortho(lens, depth);
}

void adjust_adaptive(Lens& lens, const math::Aabb& box) noexcept {
    const Vec3 center = (box.min + box.max) * 0.5F;
    Pose pose;
    pose.eye = lens.eye;
    pose.target = Point(center);
    pose.up = lens.up;
    set_look_at(lens, pose);
    Extent extent;
    scan_corners(extent, lens, box);
    if (lens.fov_y > 0.0F) write_scale(lens, 1.0F / extent.x, 1.0F / extent.y);
    if (lens.fov_y <= 0.0F) {
        const float scale_x = (2.0F / lens.viewport.width) / extent.x;
        const float scale_y = (2.0F / lens.viewport.height) / extent.y;
        write_scale(lens, scale_x, scale_y);
    }
}

math::Matrix4 projection_for(const Lens& lens, DepthRange depth) noexcept {
    if (lens.fov_y > 0.0F) return perspective_matrix(lens.fov_y, lens.viewport, depth);
    return ortho_matrix(lens.viewport, depth);
}

math::Matrix4 projection_z_bias(const Lens& lens, float scale) noexcept {
    Mat4 biased = lens.projection;
    Vec4 column = biased.col2();
    const float scaled = column.z() * (1.0F + scale);
    column.set_z(scaled);
    biased.set_col(2, column);
    return biased;
}

math::Matrix4 projection_z_bias_at(const Lens& lens, BiasQuery bias) noexcept {
    const Vec3 ndc = world_to_ndc(lens, bias.reference);
    const float span = lens.depth.z_far + lens.depth.z_near;
    const float denominator = span * ndc.z() * (ndc.z() + bias.delta);
    const float numerator = 2.0F * lens.depth.z_far * lens.depth.z_near * bias.delta;
    return projection_z_bias(lens, numerator / denominator);
}

math::Vector3 world_to_ndc(const Lens& lens, math::Point3 world) noexcept {
    const Vec4 viewed = lens.view * world;
    const Vec4 clip = lens.projection * viewed;
    const float inverse_w = 1.0F / clip.w();
    Vec3 ndc;
    ndc.set_x(clip.x() * inverse_w);
    ndc.set_y(clip.y() * inverse_w);
    ndc.set_z(clip.z() * inverse_w);
    return ndc;
}

Pixel ndc_to_screen(const Lens& lens, math::Vector3 ndc) noexcept {
    const float along_x = (ndc.x() + 1.0F) * 0.5F * lens.viewport.width;
    const float along_y = (1.0F - ndc.y()) * 0.5F * lens.viewport.height;
    Pixel pixel;
    pixel.x = static_cast<std::int32_t>(along_x);
    pixel.y = static_cast<std::int32_t>(along_y);
    return pixel;
}

Pixel world_to_screen(const Lens& lens, math::Point3 world) noexcept {
    return ndc_to_screen(lens, world_to_ndc(lens, world));
}

math::Point3 screen_to_world(const Lens& lens, Pixel pixel) noexcept {
    const HalfExtent extent = near_extent(lens);
    const float half_width = lens.viewport.width * 0.5F;
    const float half_height = lens.viewport.height * 0.5F;
    const float norm_x = (static_cast<float>(pixel.x) / half_width) - 1.0F;
    const float norm_y = 1.0F - (static_cast<float>(pixel.y) / half_height);
    Vec3 view_point;
    view_point.set_x(norm_x * extent.width);
    view_point.set_y(norm_y * extent.height);
    view_point.set_z(lens.depth.z_near);
    const Vec4 world = lens.inverse_view * Point(view_point);
    return Point(world);
}

math::Ray mouse_ray(const Lens& lens, Pixel pixel) noexcept {
    const Point on_near = screen_to_world(lens, pixel);
    Vec3 toward = on_near - lens.eye;
    const float span = length(toward);
    if (span > kAxisEpsilon) toward = toward / span;
    math::Ray ray;
    const Point shifted = on_near + (toward * lens.depth.z_near);
    ray.origin = Vec3(shifted);
    ray.direction = toward;
    return ray;
}

math::Vector3 direction_of(const Lens& lens) noexcept {
    const Vec3 toward = lens.look_at - lens.eye;
    const float span = length(toward);
    if (span <= kAxisEpsilon) return {};
    return toward / span;
}

RenderMatrices render_matrices(const Lens& lens) noexcept {
    RenderMatrices matrices;
    matrices.view = Mat4::look_at_rh(lens.eye, lens.look_at, lens.up);
    if (!has_area(lens.viewport)) return matrices;
    if (lens.fov_y > 0.0F) {
        DepthRange swapped;
        swapped.z_near = lens.depth.z_far;
        swapped.z_far = lens.depth.z_near;
        const math::FovLens fov = fov_of(lens.fov_y, lens.viewport, swapped);
        matrices.projection = Mat4::perspective_rh(fov);
        return matrices;
    }
    DepthRange swapped;
    swapped.z_near = lens.depth.z_far;
    swapped.z_far = lens.depth.z_near;
    matrices.projection = Mat4::orthographic_rh(window_of(lens.viewport, swapped));
    return matrices;
}

} // namespace game::camera

#if defined(__clang__)
#pragma clang attribute pop
#endif
