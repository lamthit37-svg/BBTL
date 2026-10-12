#include "camera/follow.hpp"

#include "math/vector.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>

namespace game::camera {
namespace {

// TDU_PI của TDUtil.h là hằng double; mọi phép đổi độ sang radian của Camera_Scene.cpp tính bằng
// double rồi mới gán vào FLOAT, nên ở đây cũng vậy.
// NOLINTNEXTLINE(modernize-use-std-numbers): giữ đúng hằng TDU_PI của bản gốc (HP-07)
constexpr double kPi = 3.1415926535;

[[nodiscard]] constexpr float degrees_to_radians(double degrees) noexcept {
    return static_cast<float>(degrees * kPi / 180.0);
}

// MIN_ANGLE và STEP_ANGLE của CCamera_Scene.
constexpr float kMinAngle = degrees_to_radians(0.1);
constexpr float kStepAngle = degrees_to_radians(1.0);
// Bước zoom của Camera_SetZoom(BOOL, INT).
constexpr float kZoomSpeed = 0.05F;
// Mặt gần và xa của WXSystem::_adjustCamera, nhân base_scale.
constexpr float kNearScale = 0.25F;
constexpr float kFarScale = 150.0F;
// Hằng của GamePro_Main.cpp: phím xoay 0,04 radian, zoom hai nấc, kéo phải chia 300.
constexpr float kKeyTurn = 0.04F;
constexpr int kZoomMultiple = 2;
constexpr float kDragDivisor = 300.0F;

// Một ô lưới: cột theo X, hàng theo Z.
struct Cell {
    int column = 0;
    int row = 0;
};

// Bốn ô chung nhau một đỉnh lưới, tính theo độ lệch so với đỉnh đó, như getJunction.
constexpr std::array<Cell, 4> kAround{{
    {.column = -1, .row = -1},
    {.column = -1, .row = 0},
    {.column = 0, .row = -1},
    {.column = 0, .row = 0},
}};

[[nodiscard]] bool is_valid_cell(const Terrain& terrain, Cell cell) noexcept {
    const bool is_in_x = 0 <= cell.column && cell.column < terrain.columns;
    return is_in_x && 0 <= cell.row && cell.row < terrain.rows;
}

// Độ cao thế giới của đỉnh lưới; lưới thiếu mẫu thì coi như mặt phẳng ở origin.
[[nodiscard]] float corner_height(const Terrain& terrain, Cell corner) noexcept {
    const auto stride = static_cast<std::size_t>(terrain.columns) + 1;
    const auto index =
        (static_cast<std::size_t>(corner.row) * stride) + static_cast<std::size_t>(corner.column);
    if (index >= terrain.heights.size()) return terrain.origin.y();
    return terrain.origin.y() + (terrain.scale.y() * terrain.heights[index]);
}

// Góc cao nhất của một ô, như _GetInterPatch.
[[nodiscard]] float cell_top(const Terrain& terrain, Cell cell) noexcept {
    const float near_left = corner_height(terrain, cell);
    const float near_right =
        corner_height(terrain, Cell{.column = cell.column + 1, .row = cell.row});
    const float far_left = corner_height(terrain, Cell{.column = cell.column, .row = cell.row + 1});
    const float far_right =
        corner_height(terrain, Cell{.column = cell.column + 1, .row = cell.row + 1});
    return std::max({near_left, near_right, far_left, far_right});
}

// Quả cầu và hộp của một ô (đáy sâu vô hạn), như Math::intersects(sphere, box): chỉ loại khi quả
// cầu nằm hẳn ngoài một mặt của hộp.
struct Ball {
    math::Point3 center;
    float radius = 0.0F;
};

[[nodiscard]] bool ball_touches_cell(const Terrain& terrain, const Ball& ball, Cell cell) noexcept {
    if (!is_valid_cell(terrain, cell)) return false;
    const float low_x = terrain.origin.x() + (static_cast<float>(cell.column) * terrain.scale.x());
    const float low_z = terrain.origin.z() + (static_cast<float>(cell.row) * terrain.scale.z());
    const float high_x = low_x + terrain.scale.x();
    const float high_z = low_z + terrain.scale.z();
    const float center_x = ball.center.x();
    const float center_z = ball.center.z();
    const bool is_apart_x = low_x - center_x > ball.radius || center_x - high_x > ball.radius;
    const bool is_apart_y = ball.center.y() - cell_top(terrain, cell) > ball.radius;
    const bool is_apart_z = low_z - center_z > ball.radius || center_z - high_z > ball.radius;
    return !(is_apart_x || is_apart_y || is_apart_z);
}

[[nodiscard]] int floor_int(float value) noexcept {
    return static_cast<int>(std::floor(value));
}

// Mắt không chạm địa hình, như _IsValidEye.
[[nodiscard]] bool is_valid_eye(const Terrain& terrain, math::Point3 eye, float radius) noexcept {
    return !touches_sphere(terrain, eye, radius);
}

// Một lần thử pitch quanh điểm nhìn.
struct Probe {
    math::Point3 target;
    Orbit orbit;
    float near_plane = 0.0F;
};

[[nodiscard]] bool is_clear(const Terrain& terrain, Probe probe, float pitch) noexcept {
    probe.orbit.pitch = pitch;
    return is_valid_eye(terrain, eye_position(probe.target, probe.orbit), probe.near_plane);
}

// Mắt đang vướng: dốc pitch thêm từng bước tới khi thoát, hoặc tới gần thẳng đứng. Hết vòng mà vẫn
// vướng thì trả pitch cuối, như bản gốc.
[[nodiscard]] float lift_pitch(const Terrain& terrain, const Probe& probe) noexcept {
    const double lowest = -((kPi / 2.0) - static_cast<double>(kMinAngle));
    float pitch = probe.orbit.pitch - kStepAngle;
    while (static_cast<double>(pitch) > lowest && !is_clear(terrain, probe, pitch)) {
        pitch -= kStepAngle;
    }
    return pitch;
}

} // namespace

math::Point3 eye_position(math::Point3 target, Orbit orbit) noexcept {
    const float rise = orbit.distance * std::sin(-orbit.pitch);
    const float reach = orbit.distance * std::cos(-orbit.pitch);
    const float along_x = -reach * std::sin(orbit.direction);
    const float along_z = -reach * std::cos(orbit.direction);
    return {target.x() + along_x, target.y() + rise, target.z() + along_z};
}

float base_scale(const Terrain& terrain) noexcept {
    return std::sqrt(terrain.scale.x() * terrain.scale.z());
}

bool touches_sphere(const Terrain& terrain, math::Point3 center, float radius) noexcept {
    const float width = static_cast<float>(terrain.columns) * terrain.scale.x();
    const float depth = static_cast<float>(terrain.rows) * terrain.scale.z();
    const float left = center.x() - terrain.origin.x();
    const float front = center.z() - terrain.origin.z();
    const bool is_inside = 0.0F <= left && left <= width && 0.0F <= front && front <= depth;
    if (!is_inside) return false;
    // getJunction: đỉnh lưới gần nhất.
    const float inverse_x = 1.0F / terrain.scale.x();
    const float inverse_z = 1.0F / terrain.scale.z();
    const int column = floor_int((left * inverse_x) + 0.5F);
    const int row = floor_int((front * inverse_z) + 0.5F);
    const Ball ball{.center = center, .radius = radius};
    const auto cell_at = [column, row](Cell offset) noexcept {
        return Cell{.column = column + offset.column, .row = row + offset.row};
    };
    const auto is_valid = [&](Cell offset) noexcept {
        return is_valid_cell(terrain, cell_at(offset));
    };
    const auto touches = [&](Cell offset) noexcept {
        return ball_touches_cell(terrain, ball, cell_at(offset));
    };
    // Bản gốc chỉ xét khi đỉnh có đủ 2 ô (ở mép) hoặc 4 ô quanh nó.
    const auto count = std::ranges::count_if(kAround, is_valid);
    if (count != 2 && count != 4) return false;
    return std::ranges::any_of(kAround, touches);
}

FollowCamera::FollowCamera(FollowRules rules) noexcept
    : rules_(rules),
      static_pitch_(degrees_to_radians(-static_cast<double>(rules.pitch_degrees))),
      pitch_(static_pitch_),
      distance_(rules.max_distance),
      direction_(rules.direction) {}

void FollowCamera::set_zoom(float zoom) noexcept {
    if (zoom < 0.0F || zoom > 1.0F) return;
    distance_ = rules_.min_distance + ((rules_.max_distance - rules_.min_distance) * zoom);
}

void FollowCamera::zoom_steps(int steps_closer) noexcept {
    const float step = kZoomSpeed * static_cast<float>(steps_closer);
    set_zoom(std::clamp(zoom_level() - step, 0.0F, 1.0F));
}

void FollowCamera::turn(float radians) noexcept {
    direction_ = direction_ + radians;
}

void FollowCamera::home() noexcept {
    distance_ = rules_.max_distance;
    direction_ = rules_.direction;
    pitch_ = static_pitch_;
}

float FollowCamera::zoom_level() const noexcept {
    return (distance_ - rules_.min_distance) / (rules_.max_distance - rules_.min_distance);
}

// Update của CCamera_Scene cùng _GetValidPitch: mắt đang ổn thì tiến về pitch chuẩn một bước (tới
// ngay nếu đã đủ gần), bước đó làm mắt vướng thì đứng yên; mắt đang vướng thì dốc thêm.
FollowPose FollowCamera::update(const Terrain& terrain, math::Point3 foot) noexcept {
    const float vertical = terrain.scale.y();
    const float near_plane = kNearScale * base_scale(terrain);
    const math::Point3 target(foot.x(), foot.y() + (rules_.add_height * vertical), foot.z());
    Probe probe;
    probe.target = target;
    probe.orbit = Orbit{.distance = distance_ * vertical, .direction = direction_, .pitch = pitch_};
    probe.near_plane = near_plane;
    const bool is_current_clear = is_clear(terrain, probe, pitch_);
    const bool is_near_enough = std::fabs(static_pitch_ - pitch_) <= kMinAngle;
    const float stepped = std::min(pitch_ + kStepAngle, static_pitch_);
    const bool is_stepped_clear = is_clear(terrain, probe, stepped);
    if (!is_current_clear) {
        pitch_ = lift_pitch(terrain, probe);
    } else if (is_near_enough) {
        pitch_ = static_pitch_;
    } else if (is_stepped_clear) {
        pitch_ = stepped;
    }
    probe.orbit.pitch = pitch_;
    FollowPose pose;
    pose.eye = eye_position(target, probe.orbit);
    pose.target = target;
    pose.fov_degrees = rules_.fov_degrees;
    pose.near_plane = near_plane;
    pose.far_plane = kFarScale * base_scale(terrain);
    return pose;
}

void apply_key(FollowCamera& camera, CameraKey key) noexcept {
    switch (key) {
    case CameraKey::kLeft: camera.turn(kKeyTurn); break;
    case CameraKey::kRight: camera.turn(-kKeyTurn); break;
    case CameraKey::kUp: camera.zoom_steps(kZoomMultiple); break;
    case CameraKey::kDown: camera.zoom_steps(-kZoomMultiple); break;
    }
}

void apply_wheel(FollowCamera& camera, int notches) noexcept {
    camera.zoom_steps(notches * kZoomMultiple);
}

void apply_drag(FollowCamera& camera, float dx_pixels) noexcept {
    camera.turn(-dx_pixels / kDragDivisor);
}

} // namespace game::camera
