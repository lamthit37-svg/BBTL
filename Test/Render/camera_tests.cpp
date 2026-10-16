/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Render/camera_tests.cpp
 *  PHÂN HỆ   : Render / Camera Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Test của camera dựng ma trận (render/camera): camera nhìn từ mắt tới điểm
 *    nhìn (look_camera, của camera bám theo), camera đặt bằng vị trí và hướng
 *    (posed_camera, của màn đăng nhập) và camera quay quanh một điểm
 *    (orbit_camera, của chế độ xem cảnh). Nguồn: TLBB Dev
 *    tests/render/render_test.cpp@e0d89a6 (orbit, look_camera_centre,
 *    view_culling).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Khác gốc: khung test của dự án; độ sâu đảo của gpu nên phép kiểm độ sâu chỉ đòi nằm giữa 0 và 1; thêm ca góc nhìn
// dọc, khung cao 0, frame_camera và posed_camera; cắt khuất chỉ kiểm một phép chiếu độ sâu đảo.

#include "core/check.hpp"
#include "math/matrix.hpp"
#include "math/quat.hpp"
#include "math/vector.hpp"
#include "render/camera.hpp"
#include "render/view_size.hpp"
#include "test.hpp"

#include <array>
#include <cmath>
#include <numbers>

namespace game::test {
namespace {

using math::Point3;
using math::Vector3;
using math::Vector4;
using render::Camera;
using render::Lens;
using render::Orbit;
using render::ViewSize;

// Sai số của phép so sánh, theo từng ca.
struct Tolerance {
    float value = 1e-4F;
};

[[nodiscard]] bool near_value(float left, float right, Tolerance tolerance) {
    return std::fabs(left - right) <= tolerance.value;
}

constexpr ViewSize kWindow{.width = 800, .height = 600};

// Điểm thế giới sau khi qua ma trận nhìn rồi ma trận chiếu: toạ độ clip.
[[nodiscard]] Vector4 clip_of(const Camera& camera, Point3 world) {
    const Vector4 seen = camera.view * world;
    return camera.projection * seen;
}

// Điểm thế giới trên khung vẽ: toạ độ clip đã chia w.
struct ScreenSpot {
    float x = 0.0F;
    float y = 0.0F;
    float depth = 0.0F;
};

[[nodiscard]] ScreenSpot spot_of(const Camera& camera, Point3 world) {
    const Vector4 clip = clip_of(camera, world);
    return {.x = clip.x() / clip.w(), .y = clip.y() / clip.w(), .depth = clip.z() / clip.w()};
}

[[nodiscard]] bool same_spot(ScreenSpot left, ScreenSpot right) {
    const Tolerance loose{.value = 1e-3F};
    const bool is_same_place = near_value(left.x, right.x, loose) && near_value(left.y, right.y, loose);
    return is_same_place && near_value(left.depth, right.depth, loose);
}

[[nodiscard]] bool is_centred(ScreenSpot spot) {
    return near_value(spot.x, 0.0F, Tolerance{}) && near_value(spot.y, 0.0F, Tolerance{});
}

// Camera quay quanh một điểm: mắt luôn cách tâm radius nhân 3,2, và tâm luôn nằm trên trục nhìn. Hệ
// tay phải: tâm trước mắt có z nhìn âm.
void orbit(Context& context) {
    Orbit around;
    around.centre = Vector3(100.0F, 20.0F, -50.0F);
    around.radius = 10.0F;
    around.angle = 1.3F;
    const Camera camera = render::orbit_camera(around, kWindow);
    const Vector4 centre = camera.view * Point3(100.0F, 20.0F, -50.0F);
    const Tolerance loose{.value = 1e-3F};
    const bool is_on_axis = near_value(centre.x(), 0.0F, loose) && near_value(centre.y(), 0.0F, loose);
    context.expect(is_on_axis, "tâm nằm trên trục nhìn");
    context.expect(near_value(centre.z(), -32.0F, loose), "mắt cách tâm radius nhân 3,2");
    Orbit start;
    start.radius = 10.0F;
    Orbit turned = start;
    turned.angle = 0.5F;
    const Camera first = render::orbit_camera(start, kWindow);
    const Camera second = render::orbit_camera(turned, kWindow);
    const bool is_moved = !near_value(first.view.col0().x(), second.view.col0().x(), Tolerance{});
    context.expect(is_moved, "góc khác thì mắt ở chỗ khác");
}

// Camera nhìn từ mắt tới điểm nhìn: điểm nhìn chiếu vào giữa khung và nằm giữa hai mặt cắt.
void look_camera_centre(Context& context) {
    Lens lens;
    lens.fov_degrees = 35.0F;
    lens.near_plane = 0.25F;
    lens.far_plane = 150.0F;
    const Point3 eye(3.0F, 10.0F, -7.0F);
    const Point3 target(1.0F, 0.0F, 2.0F);
    const Camera camera = render::look_camera(eye, target, lens, kWindow);
    const Vector4 clip = clip_of(camera, target);
    const ScreenSpot seen = spot_of(camera, target);
    context.expect(clip.w() != 0.0F && is_centred(seen), "điểm nhìn ở giữa khung");
    context.expect(seen.depth > 0.0F && seen.depth < 1.0F, "điểm nhìn nằm giữa hai mặt cắt");
    const ViewSize wide_size{.width = 1600, .height = 600};
    const Camera wide = render::look_camera(eye, target, lens, wide_size);
    // Khung rộng gấp đôi cùng chiều cao thì hệ số x của phép chiếu còn một nửa.
    const float half = wide.projection.col0().x() * 2.0F;
    context.expect(near_value(half, camera.projection.col0().x(), Tolerance{1e-5F}), "tỉ lệ theo size");
}

// FOV của Lens là góc DỌC: mép trên của khung ở đúng nửa góc nhìn, mép phải ở nửa góc nhìn dọc nhân
// tỉ lệ khung.
void look_camera_vertical_fov(Context& context) {
    Lens lens;
    lens.fov_degrees = 35.0F;
    const Point3 eye(0.0F, 0.0F, 0.0F);
    const Point3 target(0.0F, 0.0F, -10.0F);
    const Camera camera = render::look_camera(eye, target, lens, kWindow);
    const float half_tan = std::tan(35.0F * 0.5F * std::numbers::pi_v<float> / 180.0F);
    const Vector4 top = clip_of(camera, Point3(0.0F, 10.0F * half_tan, -10.0F));
    context.expect(near_value(top.y() / top.w(), 1.0F, Tolerance{}), "mép trên ở nửa góc dọc");
    const float aspect = 800.0F / 600.0F;
    const Vector4 right = clip_of(camera, Point3(10.0F * half_tan * aspect, 0.0F, -10.0F));
    context.expect(near_value(right.x() / right.w(), 1.0F, Tolerance{}), "mép phải theo tỉ lệ");
}

// Lens có khung tham chiếu 16:9: khung hẹp hơn (máy tính bảng 16:10, iPad 4:3) vẫn thấy đúng bề ngang của khung tham
// chiếu và thấy thêm trên dưới; khung rộng hơn (điện thoại 20:9) giữ góc dọc. Không đặt tham chiếu thì luôn giữ góc dọc.
void look_camera_keeps_reference_frame(Context& context) {
    constexpr float kReference = 16.0F / 9.0F;
    Lens lens;
    lens.fov_degrees = 35.0F;
    lens.reference_aspect = kReference;
    const Point3 eye(0.0F, 0.0F, 0.0F);
    const Point3 target(0.0F, 0.0F, -10.0F);
    const float half_tan = std::tan(35.0F * 0.5F * std::numbers::pi_v<float> / 180.0F);
    const Point3 reference_right(10.0F * half_tan * kReference, 0.0F, -10.0F);
    const Point3 reference_top(0.0F, 10.0F * half_tan, -10.0F);

    const ViewSize tablet{.width = 1280, .height = 800};
    const Camera narrow = render::look_camera(eye, target, lens, tablet);
    const Vector4 right = clip_of(narrow, reference_right);
    context.expect(near_value(right.x() / right.w(), 1.0F, Tolerance{}), "16:10 giữ mép phải của khung 16:9");
    const Vector4 top = clip_of(narrow, reference_top);
    const float tablet_aspect = 1280.0F / 800.0F;
    context.expect(near_value(top.y() / top.w(), tablet_aspect / kReference, Tolerance{}), "16:10 thấy thêm trên dưới");

    const ViewSize phone{.width = 2400, .height = 1080};
    const Camera wide = render::look_camera(eye, target, lens, phone);
    const Vector4 wide_top = clip_of(wide, reference_top);
    context.expect(near_value(wide_top.y() / wide_top.w(), 1.0F, Tolerance{}), "20:9 giữ góc dọc");

    const float fov_y = 35.0F * std::numbers::pi_v<float> / 180.0F;
    context.expect(render::fitted_fov_y(fov_y, 1.0F, 0.0F) == fov_y, "không có tham chiếu thì giữ góc dọc");
    context.expect(render::fitted_fov_y(fov_y, kReference, kReference) == fov_y, "đúng tỉ lệ tham chiếu thì giữ nguyên");
    const float ipad = render::fitted_fov_y(fov_y, 4.0F / 3.0F, kReference);
    const float ipad_half_x = std::tan(ipad * 0.5F) * (4.0F / 3.0F);
    context.expect(near_value(ipad_half_x, half_tan * kReference, Tolerance{}), "4:3 giữ bề ngang của khung 16:9");
}

// Khung cao 0 (cửa sổ đang thu nhỏ) coi như khung vuông: không ra NaN.
void look_camera_flat_window(Context& context) {
    const Lens lens;
    const ViewSize flat{.width = 800, .height = 0};
    const Camera camera = render::look_camera(Point3(0.0F, 5.0F, 5.0F), Point3(0.0F, 0.0F, 0.0F), lens, flat);
    const float scale = camera.projection.col0().x();
    context.expect(std::isfinite(scale) && scale > 0.0F, "phép chiếu hữu hạn");
}

// Hướng chỉ xoay quanh y: camera đặt bằng vị trí và hướng trùng với look_camera nhìn theo -z đã
// xoay. -z xoay quanh y một góc a (tay phải) là (-sin a, 0, -cos a).
void posed_camera_yaw(Context& context) {
    const Lens lens;
    const Point3 eye(3.0F, 10.0F, -7.0F);
    const float half_angle = 0.6F;
    const math::Quat turn(0.0F, std::sin(half_angle), 0.0F, std::cos(half_angle));
    const float angle = 2.0F * half_angle;
    const Vector3 forward(-std::sin(angle), 0.0F, -std::cos(angle));
    const Point3 target(Vector3(eye) + forward);
    const Camera posed = render::posed_camera(eye, turn, lens, kWindow);
    const Camera looked = render::look_camera(eye, target, lens, kWindow);
    const Point3 probe(-40.0F, 16.0F, -20.0F);
    const ScreenSpot by_pose = spot_of(posed, probe);
    const ScreenSpot by_look = spot_of(looked, probe);
    context.expect(same_spot(by_pose, by_look), "trùng look_camera cùng hướng");
    const ScreenSpot centre = spot_of(posed, target);
    context.expect(is_centred(centre), "điểm trên trục nhìn ở giữa khung");
}

// Hướng nghiêng một phần tư vòng quanh trục nhìn: trục lên của camera là -x của thế giới, nên điểm
// nằm phía +y của thế giới hiện bên phải khung chứ không ở trên. look_camera luôn dựng trục lên +y,
// không biểu diễn được tư thế này.
void posed_camera_roll(Context& context) {
    const Lens lens;
    const Point3 eye(0.0F, 0.0F, 0.0F);
    const float quarter = std::numbers::pi_v<float> * 0.25F;
    const math::Quat rolled(0.0F, 0.0F, std::sin(quarter), std::cos(quarter));
    const Camera camera = render::posed_camera(eye, rolled, lens, kWindow);
    const ScreenSpot above = spot_of(camera, Point3(0.0F, 1.0F, -10.0F));
    context.expect(above.x > 0.01F, "điểm phía +y thế giới hiện bên phải");
    context.expect(near_value(above.y, 0.0F, Tolerance{}), "và không lệch lên xuống");
    const math::Quat level(0.0F, 0.0F, 0.0F, 1.0F);
    const Camera upright = render::posed_camera(eye, level, lens, kWindow);
    const ScreenSpot top = spot_of(upright, Point3(0.0F, 1.0F, -10.0F));
    context.expect(top.y > 0.01F && near_value(top.x, 0.0F, Tolerance{}), "hướng đơn vị: nhìn theo -z, +y ở trên");
}

render::SceneBounds cube_at(Vector3 centre) {
    const Vector3 half(1.0F, 1.0F, 1.0F);
    return render::bounds_with_radius(centre - half, centre + half);
}

// Hướng chếch không xoay, tâm khung bao nằm trên trục nhìn, bán kính là nửa đường chéo.
void frame_camera_box(Context& context) {
    const Vector3 low(-2.0F, 0.0F, -2.0F);
    const Vector3 high(2.0F, 4.0F, 2.0F);
    const render::SceneBounds bounds = render::bounds_with_radius(low, high);
    const float half = math::length((high - low) * 0.5F);
    context.expect(near_value(bounds.radius, half, Tolerance{}), "bán kính là nửa đường chéo");
    const Camera camera = render::frame_camera(bounds, kWindow);
    const Vector3 centre = (low + high) * 0.5F;
    const Vector4 seen = camera.view * Point3(centre);
    const Tolerance loose{.value = 1e-3F};
    const bool is_on_axis = near_value(seen.x(), 0.0F, loose) && near_value(seen.y(), 0.0F, loose);
    context.expect(is_on_axis, "tâm khung bao nằm trên trục nhìn");
    context.expect(seen.z() < 0.0F, "tâm ở trước mắt");
    const float distance = bounds.radius * 3.2F;
    context.expect(near_value(seen.z(), -distance, loose), "mắt cách tâm bán kính nhân 3,2");
}

// Mắt ở gốc nhìn về -z, FOV 60, mặt gần 1, mặt xa 100. Độ sâu đảo: mặt xa là z >= 0.
void view_culling(Context& context) {
    Lens lens;
    lens.fov_degrees = 60.0F;
    lens.near_plane = 1.0F;
    lens.far_plane = 100.0F;
    const Point3 eye(0.0F, 0.0F, 0.0F);
    const Point3 ahead(0.0F, 0.0F, -10.0F);
    const ViewSize square{.width = 100, .height = 100};
    const Camera camera = render::look_camera(eye, ahead, lens, square);
    const math::Matrix4 clip = camera.projection * camera.view;
    const render::SceneBounds front_box = cube_at(Vector3(0.0F, 0.0F, -10.0F));
    context.expect(render::box_in_view(clip, front_box), "hộp trước mắt");
    const render::SceneBounds straddling = cube_at(Vector3(0.0F, 0.0F, -100.5F));
    context.expect(render::box_in_view(clip, straddling), "hộp cắt mặt xa");
    const render::SceneBounds around_eye = cube_at(Vector3(0.0F, 0.0F, 0.0F));
    context.expect(render::box_in_view(clip, around_eye), "hộp bao quanh mắt");
    const render::SceneBounds behind = cube_at(Vector3(0.0F, 0.0F, 10.0F));
    context.expect(!render::box_in_view(clip, behind), "hộp sau lưng");
    const render::SceneBounds left = cube_at(Vector3(-50.0F, 0.0F, -10.0F));
    context.expect(!render::box_in_view(clip, left), "hộp lệch hẳn sang trái");
    const render::SceneBounds too_far = cube_at(Vector3(0.0F, 0.0F, -200.0F));
    context.expect(!render::box_in_view(clip, too_far), "hộp xa quá mặt xa");
    const render::Frustum frustum = render::frustum_of(clip);
    const Vector3 front(0.0F, 0.0F, -10.0F);
    const bool is_front = render::sphere_in_view(frustum, front, 1.0F);
    context.expect(is_front, "cầu trước mắt");
    const Vector3 rear(0.0F, 0.0F, 10.0F);
    const bool is_rear = render::sphere_in_view(frustum, rear, 1.0F);
    context.expect(!is_rear, "cầu sau lưng");
    const Vector3 past(0.0F, 0.0F, -150.0F);
    const bool is_past = render::sphere_in_view(frustum, past, 1.0F);
    context.expect(!is_past, "cầu quá mặt xa");
    const bool is_crossing = render::sphere_in_view(frustum, past, 60.0F);
    context.expect(is_crossing, "cầu cắt mặt xa");
    const Vector3 aside(-50.0F, 0.0F, -10.0F);
    const bool is_aside = render::sphere_in_view(frustum, aside, 1.0F);
    context.expect(!is_aside, "cầu lệch trái");
    const Vector3 edge(-6.5F, 0.0F, -10.0F);
    const bool is_edge = render::sphere_in_view(frustum, edge, 1.0F);
    context.expect(is_edge, "cầu cắt mặt trái");
}

constexpr std::array kCases{
    Case{.name = "orbit", .body = &orbit},
    Case{.name = "look_camera_centre", .body = &look_camera_centre},
    Case{.name = "look_camera_vertical_fov", .body = &look_camera_vertical_fov},
    Case{.name = "look_camera_keeps_reference_frame", .body = &look_camera_keeps_reference_frame},
    Case{.name = "look_camera_flat_window", .body = &look_camera_flat_window},
    Case{.name = "posed_camera_yaw", .body = &posed_camera_yaw},
    Case{.name = "posed_camera_roll", .body = &posed_camera_roll},
    Case{.name = "frame_camera_box", .body = &frame_camera_box},
    Case{.name = "view_culling", .body = &view_culling},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "camera_tests: mọi ca phải qua");
    return 0;
}
