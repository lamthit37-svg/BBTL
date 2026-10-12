// Ghim công thức kính Cool3D và ClientCamera của Loong. Số lấy từ CameraBase, CameraEuler và
// ClientCamera.cpp (SetDefault, lăn, occult, rung), không từ camera của TLBB Dev.
#include "camera/lens.hpp"
#include "camera/rig.hpp"
#include "core/check.hpp"
#include "math/geometry.hpp"
#include "math/scalar.hpp"
#include "math/vector.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <optional>

namespace game::test {
namespace {

using camera::FrameInput;
using camera::Pixel;
using camera::PointerInput;
using camera::Rig;
using camera::Viewport;

constexpr float kSlack = 1.0e-3F;

[[nodiscard]] bool near_value(float left, float right) noexcept {
    return std::fabs(left - right) <= kSlack;
}

[[nodiscard]] Viewport window_of() noexcept {
    Viewport viewport;
    viewport.width = 800.0F;
    viewport.height = 600.0F;
    return viewport;
}

[[nodiscard]] Rig opened() noexcept {
    Rig rig = camera::make_rig(0);
    camera::set_default(rig, window_of(), 20000.0F);
    return rig;
}

// Chữ ký Probe nhận void*, không phải const void*.
// NOLINTNEXTLINE(misc-const-correctness)
float low_ground(void* user, camera::Planar place) noexcept {
    static_cast<void>(place);
    const auto* height = static_cast<const float*>(user);
    return *height;
}

void basis_default_eye(Context& context) {
    const Rig rig = opened();
    context.expect(near_value(rig.euler.distance, 660.0F), "khoảng cách mặc định 660");
    context.expect(near_value(rig.expect_distance, 660.0F), "expect bằng khoảng cách");
    context.expect(near_value(rig.euler.yaw, 0.39793599F), "yaw mặc định");
    context.expect(near_value(rig.euler.pitch, -0.18762225F), "pitch mặc định");
    context.expect(near_value(rig.lens.eye.x(), -251.272F), "mắt x");
    context.expect(near_value(rig.lens.eye.y(), 623.105F), "mắt y");
    context.expect(near_value(rig.lens.eye.z(), -597.752F), "mắt z");
    context.expect(near_value(rig.lens.depth.z_near, 20.0F), "mặt gần 20");
    context.expect(near_value(rig.lens.depth.z_far, 20000.0F), "mặt xa của WorldFrame");
}

void projection_matches_d3d(Context& context) {
    const Rig rig = opened();
    const float aspect = 800.0F / 600.0F;
    const float y_scale = 1.0F / std::tan(math::radians(45.0F) * 0.5F);
    const float x_scale = y_scale / aspect;
    const float depth = 20000.0F - 20.0F;
    const float z_scale = 20000.0F / depth;
    const float z_bias = (-20.0F * 20000.0F) / depth;
    context.expect(near_value(rig.lens.projection.col0().x(), x_scale), "D3DX _11");
    context.expect(near_value(rig.lens.projection.col1().y(), y_scale), "D3DX _22");
    context.expect(near_value(rig.lens.projection.col2().z(), z_scale), "D3DX _33");
    context.expect(near_value(rig.lens.projection.col2().w(), 1.0F), "D3DX _34 đã chuyển vị");
    context.expect(near_value(rig.lens.projection.col3().z(), z_bias), "D3DX _43 đã chuyển vị");
}

void wheel_and_clamp(Context& context) {
    Rig rig = opened();
    PointerInput pointer;
    pointer.over_desktop = true;
    pointer.wheel = 120;
    const camera::FlyKeys keys;
    static_cast<void>(camera::steer(rig, pointer, keys));
    context.expect(near_value(rig.expect_distance, 600.0F), "lZ 120 lại gần 60 cm");
    pointer.wheel = -100000;
    static_cast<void>(camera::steer(rig, pointer, keys));
    context.expect(near_value(rig.expect_distance, 1800.0F), "trần 1800");
    pointer.wheel = 100000;
    static_cast<void>(camera::steer(rig, pointer, keys));
    context.expect(near_value(rig.expect_distance, 220.0F), "sàn expect 220");
    pointer.over_desktop = false;
    pointer.wheel = -120;
    static_cast<void>(camera::steer(rig, pointer, keys));
    context.expect(near_value(rig.expect_distance, 220.0F), "không ở desktop thì bỏ lăn");
}

void yaw_and_pitch_gate(Context& context) {
    Rig rig = opened();
    rig.euler.distance = 200.0F;
    rig.euler.pitch = 0.0F;
    PointerInput pointer;
    pointer.right_held = true;
    pointer.moved = true;
    pointer.relative_x = 100;
    pointer.relative_y = -10;
    const camera::FlyKeys keys;
    static_cast<void>(camera::steer(rig, pointer, keys));
    const float yaw_step = 100.0F * 0.6F * 0.006545F;
    context.expect(near_value(rig.euler.yaw, 0.39793599F + yaw_step), "kéo phải tăng yaw");
    context.expect(near_value(rig.euler.pitch, 0.0F), "sát thì không ngẩng");
    pointer.relative_x = 0;
    pointer.relative_y = 10;
    static_cast<void>(camera::steer(rig, pointer, keys));
    context.expect(near_value(rig.euler.pitch, -10.0F * 0.006545F), "sát vẫn cúi được");
}

void spring_and_block(Context& context) {
    Rig rig = opened();
    rig.euler.distance = 200.0F;
    rig.expect_distance = 660.0F;
    camera::place(rig, rig.euler);
    float floor = -100000.0F;
    FrameInput frame;
    frame.clock.delta_seconds = 0.1F;
    frame.subject.present = true;
    frame.subject.position = {0.0F, 370.0F, 0.0F};
    frame.probe.user = &floor;
    frame.probe.ground = &low_ground;
    camera::settle(rig, frame);
    context.expect(near_value(rig.euler.distance, 300.0F), "lò xo 1000 cm/s trong 0,1 s");
    context.expect(near_value(rig.euler.look_at.y(), 510.0F), "nâng điểm nhìn (300 - 200) / 10");
    floor = 100000.0F;
    rig.euler.distance = 660.0F;
    rig.expect_distance = 660.0F;
    camera::place(rig, rig.euler);
    camera::settle(rig, frame);
    context.expect(near_value(rig.euler.distance, 200.0F), "mặt đất chặn thì sàn 200");
    context.expect(rig.is_fading, "sát hơn 200 thì nhân vật mờ");
    context.expect(rig.lens.eye.y() >= 100010.0F - kSlack, "mắt không chui xuống đất");
}

void quake_frames(Context& context) {
    Rig rig = opened();
    camera::play_quake(rig, 0);
    float floor = 100000.0F;
    FrameInput frame;
    frame.subject.present = true;
    frame.subject.position = {10.0F, 0.0F, 20.0F};
    frame.probe.user = &floor;
    frame.probe.ground = &low_ground;
    frame.clock.accum_ms = 0;
    camera::settle(rig, frame);
    context.expect(near_value(rig.euler.look_at.y(), 135.0F), "khung rung đầu cộng 5");
    frame.clock.accum_ms = 301;
    camera::settle(rig, frame);
    context.expect(!rig.is_quaking, "hết 300 ms thì dừng rung");
    context.expect(near_value(rig.euler.look_at.y(), 130.0F), "hết rung thì hết lệch");
}

void play_fov_is_world_frame(Context& context) {
    Rig rig = opened();
    camera::set_fov(rig, window_of(), 55.0F);
    context.expect(near_value(rig.expect_distance, 660.0F), "SetFov giữ expect");
    context.expect(near_value(rig.euler.distance, 660.0F), "SetFov không đổi khoảng cách");
    context.expect(near_value(rig.lens.fov_y, math::radians(55.0F)), "WorldFrame đặt 55 độ");
    const float aspect = 800.0F / 600.0F;
    const float y_scale = 1.0F / std::tan(math::radians(55.0F) * 0.5F);
    const float x_scale = y_scale / aspect;
    context.expect(near_value(rig.lens.projection.col0().x(), x_scale), "D3DX _11 ở 55 độ");
    context.expect(near_value(rig.lens.projection.col1().y(), y_scale), "D3DX _22 ở 55 độ");
}

void view_matches_look_at(Context& context) {
    const Rig rig = opened();
    const math::Vector4 left_eye = rig.lens.view * rig.lens.eye;
    context.expect(near_value(left_eye.x(), 0.0F), "LookAtLH mắt x");
    context.expect(near_value(left_eye.y(), 0.0F), "LookAtLH mắt y");
    context.expect(near_value(left_eye.z(), 0.0F), "LookAtLH mắt z");
    context.expect(near_value(left_eye.w(), 1.0F), "LookAtLH mắt w");
    const math::Vector4 left_look = rig.lens.view * rig.lens.look_at;
    context.expect(near_value(left_look.x(), 0.0F), "LookAtLH đích x");
    context.expect(near_value(left_look.y(), 0.0F), "LookAtLH đích y");
    context.expect(near_value(left_look.z(), 660.0F), "LookAtLH đích ở +Z");
    const camera::RenderMatrices drawn = camera::render_matrices(rig.lens);
    const math::Vector4 right_eye = drawn.view * rig.lens.eye;
    context.expect(near_value(right_eye.x(), 0.0F), "LookAtRH mắt x");
    context.expect(near_value(right_eye.y(), 0.0F), "LookAtRH mắt y");
    context.expect(near_value(right_eye.z(), 0.0F), "LookAtRH mắt z");
    const math::Vector4 right_look = drawn.view * rig.lens.look_at;
    context.expect(near_value(right_look.x(), 0.0F), "LookAtRH đích x");
    context.expect(near_value(right_look.y(), 0.0F), "LookAtRH đích y");
    context.expect(near_value(right_look.z(), -660.0F), "LookAtRH đích ở -Z");
}

// Điểm chạm của RayCollideWater, trước khi occult cộng 30 cm.
// NOLINTNEXTLINE(misc-const-correctness)
std::optional<math::Point3> flat_water(void* user, const camera::WaterQuery& query) noexcept {
    static_cast<void>(user);
    static_cast<void>(query);
    return math::Point3{0.0F, 0.0F, 250.0F};
}

void water_lifts_the_hit(Context& context) {
    Rig rig = opened();
    camera::Euler aim;
    aim.look_at = {0.0F, 0.0F, 0.0F};
    aim.distance = 300.0F;
    camera::place(rig, aim);
    rig.expect_distance = 300.0F;
    FrameInput frame;
    frame.subject.present = true;
    frame.subject.position = {0.0F, -130.0F, 0.0F};
    frame.probe.water_ray = &flat_water;
    camera::settle(rig, frame);
    const float lifted = std::hypot(250.0F, 30.0F);
    context.expect(near_value(rig.euler.distance, lifted), "nước cộng 30 rồi lấy độ dài");
}

void mouse_ray_hits_near(Context& context) {
    const Rig rig = opened();
    Pixel pixel;
    pixel.x = 400;
    pixel.y = 300;
    const math::Ray ray = camera::mouse_ray(rig.lens, pixel);
    const math::Vector3 toward = rig.lens.look_at - rig.lens.eye;
    const math::Vector3 forward = math::normalize(toward);
    const float align = math::dot(ray.direction, forward);
    context.expect(align > 0.99F, "tia giữa màn hình đi về điểm nhìn");
}

constexpr std::array kCases{
    Case{.name = "basis_default_eye", .body = &basis_default_eye},
    Case{.name = "projection_matches_d3d", .body = &projection_matches_d3d},
    Case{.name = "wheel_and_clamp", .body = &wheel_and_clamp},
    Case{.name = "yaw_and_pitch_gate", .body = &yaw_and_pitch_gate},
    Case{.name = "spring_and_block", .body = &spring_and_block},
    Case{.name = "quake_frames", .body = &quake_frames},
    Case{.name = "play_fov_is_world_frame", .body = &play_fov_is_world_frame},
    Case{.name = "view_matches_look_at", .body = &view_matches_look_at},
    Case{.name = "water_lifts_the_hit", .body = &water_lifts_the_hit},
    Case{.name = "mouse_ray_hits_near", .body = &mouse_ray_hits_near},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(
        game::test::run_all(game::test::kCases) == 0, "loong_camera_tests: mọi ca phải qua");
    return 0;
}
