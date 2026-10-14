// Test của camera cảnh (control/follow_camera) và chuột của người chơi (control/player_input) theo
// client 2026. Số mong đợi tính tay từ công thức đọc trong Render.dll và Game.exe bản 3.71 (địa chỉ
// ở docs/CAMERA-2026.md), ghi cạnh phép kiểm. Map phẳng tỉ lệ 100 như mọi cảnh của client: một đơn
// vị game là 100 đơn vị thế giới.
#include "control/follow_camera.hpp"
#include "control/ground.hpp"
#include "control/player_input.hpp"
#include "core/check.hpp"
#include "core/ground_point.hpp"
#include "ogre/vec3.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <optional>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using control::CameraFit;
using control::CameraRules;
using control::FollowCamera;
using control::Ground;
using control::GroundShape;
using control::MouseEvent;
using control::MouseEvents;
using control::MouseSample;
using control::MouseTicker;
using control::Pilot;
using control::PilotFrame;
using control::PilotRules;
using control::PilotStep;
using control::ZoomWay;
using ogre::Vec3;

constexpr float kDegree = 0.0174532925F;
constexpr std::size_t kSide = 64;

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) <= 1e-4F;
}

[[nodiscard]] bool near_point(Vec3 left, Vec3 right) {
    const bool is_flat = std::fabs(left.x - right.x) <= 0.05F && std::fabs(left.z - right.z) <= 0.05F;
    return is_flat && std::fabs(left.y - right.y) <= 0.05F;
}

// Map 64 x 64 ô, tỉ lệ 100, gốc (-3200, 0, -3200). Hàng z từ wall trở đi cao height (đơn vị thô).
[[nodiscard]] std::optional<Ground> map_with_wall(std::size_t wall, float height) {
    GroundShape shape;
    shape.x_size = static_cast<int>(kSide);
    shape.z_size = static_cast<int>(kSide);
    shape.scale = Vec3{.x = 100.0F, .y = 100.0F, .z = 100.0F};
    shape.position = Vec3{.x = -3200.0F, .y = 0.0F, .z = -3200.0F};
    const std::size_t row = kSide + 1;
    shape.heights.assign(row * row, 0.0F);
    for (std::size_t index = wall * row; index < shape.heights.size(); ++index) {
        shape.heights[index] = height;
    }
    return Ground::create(std::move(shape));
}

[[nodiscard]] std::optional<Ground> flat_map() {
    return map_with_wall(kSide + 1, 0.0F);
}

[[nodiscard]] control::Clock::time_point after(int milliseconds) {
    return control::Clock::time_point{} + std::chrono::milliseconds{milliseconds};
}

// Một camera đã vào cảnh trên map phẳng, zoom xa nhất, chân nhân vật ở gốc.
struct Stage {
    Ground ground;
    FollowCamera camera{CameraRules{}};
};

[[nodiscard]] std::optional<Stage> entered(float zoom) {
    std::optional<Ground> ground = flat_map();
    if (!ground) return std::nullopt;
    Stage stage{.ground = std::move(*ground)};
    stage.camera.enter(stage.ground, Vec3{}, zoom);
    return stage;
}

// _GetEyePos: y = d sin(-p), r = d cos(-p), x = -r sin(hướng), z = -r cos(hướng).
void eye_formula(Context& context) {
    const float pitch = -30.0F * kDegree;
    const control::EyeArm ahead{.distance = 10.0F, .direction = 0.0F, .pitch = pitch};
    const Vec3 eye = control::eye_position(Vec3{}, ahead);
    context.expect(near_point(eye, Vec3{.x = 0.0F, .y = 5.0F, .z = -8.660254F}), "hướng 0");
    const Vec3 target{.x = 1.0F, .y = 2.0F, .z = 3.0F};
    const control::EyeArm aside{.distance = 10.0F, .direction = 90.0F * kDegree, .pitch = pitch};
    const Vec3 side = control::eye_position(target, aside);
    const Vec3 expected{.x = 1.0F - 8.660254F, .y = 7.0F, .z = 3.0F};
    context.expect(near_point(side, expected), "hướng 90 độ, điểm nhìn lệch gốc");
}

// CGamePro_Enter: hướng 3,1415, zoom đã lưu, pitch = (pitch gốc + 26) x zoom - 26 độ.
void enter_scene(Context& context) {
    std::optional<Stage> far = entered(1.0F);
    std::optional<Stage> near = entered(0.0F);
    std::optional<Stage> half = entered(0.5F);
    context.expect(far && near && half, "dựng map phẳng");
    if (!far || !near || !half) return;
    context.expect(near_value(far->camera.direction(), 3.1415F), "hướng lúc vào cảnh");
    context.expect(near_value(far->camera.zoom(far->ground), 1.0F), "zoom xa nhất");
    context.expect(near_value(far->camera.pitch(), -40.0F * kDegree), "zoom 1: pitch gốc 40 độ");
    context.expect(near_value(near->camera.pitch(), -26.0F * kDegree), "zoom 0: 26 độ");
    context.expect(near_value(half->camera.pitch(), -33.0F * kDegree), "zoom 0,5: 33 độ");
    const control::CameraPose& pose = far->camera.pose();
    context.expect(near_point(pose.target, Vec3{.x = 0.0F, .y = 150.0F, .z = 0.0F}), "nhìn cao 1,5");
    const control::EyeArm arm{.distance = 2750.0F, .direction = 3.1415F, .pitch = -40.0F * kDegree};
    context.expect(near_point(pose.eye, control::eye_position(pose.target, arm)), "mắt cách 27,5");
    const bool is_lens = near_value(pose.near_plane, 10.0F) && near_value(pose.far_plane, 15000.0F);
    context.expect(is_lens && near_value(pose.fov_degrees, 35.0F), "mặt cắt 10 và 15000, FOV 35");
}

// Camera_SetZoom hai dạng; cảnh thường không tự nới khoảng cách sau khi zoom.
void zoom_api(Context& context) {
    std::optional<Stage> stage = entered(1.0F);
    context.expect(stage.has_value(), "dựng map phẳng");
    if (!stage) return;
    FollowCamera& camera = stage->camera;
    const Ground& ground = stage->ground;
    camera.zoom_step(ground, ZoomWay::kCloser, 2);
    context.expect(near_value(camera.zoom(ground), 0.9F), "lại gần hai bước 0,05");
    camera.zoom_step(ground, ZoomWay::kCloser, 100);
    context.expect(near_value(camera.zoom(ground), 0.0F), "kẹp ở gần nhất");
    camera.zoom_step(ground, ZoomWay::kFarther, 2);
    context.expect(near_value(camera.zoom(ground), 0.1F), "ra xa hai bước");
    camera.set_zoom(ground, 1.5F);
    context.expect(near_value(camera.zoom(ground), 0.1F), "zoom ngoài [0, 1] bị bỏ qua");
    camera.set_zoom(ground, 0.0F);
    for (int frame = 0; frame < 5; ++frame) {
        camera.set_look_at(ground, Vec3{.x = static_cast<float>(frame), .y = 0.0F, .z = 0.0F});
    }
    context.expect(near_value(camera.zoom(ground), 0.0F), "zoom gần nhất giữ nguyên qua 5 khung");
    const float gap = camera.pose().target.z - camera.pose().eye.z;
    context.expect(std::fabs(std::fabs(gap) - (600.0F * std::cos(40.0F * kDegree))) <= 0.5F, "cách 6");
}

// Camera_SetPitch chỉ nhận trong (-89, 89) độ; Camera_SetFOV ép góc khi lệch quá 0,01.
void pitch_and_fov(Context& context) {
    std::optional<Stage> stage = entered(1.0F);
    context.expect(stage.has_value(), "dựng map phẳng");
    if (!stage) return;
    FollowCamera& camera = stage->camera;
    const Ground& ground = stage->ground;
    camera.set_pitch(ground, -1.0F);
    context.expect(near_value(camera.pitch(), -1.0F), "đặt pitch");
    camera.set_pitch(ground, -1.56F);
    context.expect(near_value(camera.pitch(), -1.0F), "quá 89 độ thì bỏ qua");
    camera.set_pitch(ground, 1.56F);
    context.expect(near_value(camera.pitch(), -1.0F), "quá 89 độ phía trên cũng bỏ qua");
    camera.set_fov(35.005F);
    camera.set_direction(ground, 1.0F);
    context.expect(near_value(camera.pose().fov_degrees, 35.0F), "FOV ép lệch dưới 0,01 thì thôi");
    camera.set_fov(55.0F);
    camera.set_direction(ground, 2.0F);
    context.expect(near_value(camera.pose().fov_degrees, 55.0F), "FOV ép của cảnh");
    context.expect(near_value(camera.direction(), 2.0F), "hướng không gói lại");
}

// Cảnh thường: mắt chui vào vách thì pitch dốc thêm từng độ tới khi thoát; pitch người chơi đặt
// không đổi; hết vách thì mỗi lần Update trả một độ.
void fit_pitch(Context& context) {
    const auto walled = map_with_wall(40, 30.0F);
    const auto flat = flat_map();
    context.expect(walled.has_value() && flat.has_value(), "dựng map");
    if (!walled || !flat) return;
    FollowCamera camera{CameraRules{}};
    camera.enter(*walled, Vec3{}, 1.0F);
    const float wanted = -40.0F * kDegree;
    context.expect(near_value(camera.pitch(), wanted), "pitch muốn giữ nguyên");
    context.expect(camera.eye_pitch() < wanted - (kDegree / 2.0F), "mắt vướng vách thì dốc thêm");
    const bool is_clear = !walled->touches_sphere(camera.pose().eye, 10.0F);
    context.expect(is_clear, "mắt sau khi chỉnh không chạm địa hình");
    const float lifted = camera.eye_pitch();
    camera.set_look_at(*flat, Vec3{.x = 1.0F, .y = 0.0F, .z = 0.0F});
    context.expect(near_value(camera.eye_pitch(), lifted + kDegree), "đất phẳng: trả một độ");
    camera.set_look_at(*flat, Vec3{.x = 1.0F, .y = 0.0F, .z = 0.0F});
    const bool is_second = near_value(camera.eye_pitch(), lifted + (2.0F * kDegree));
    context.expect(is_second, "chân đứng yên mà pitch chưa về thì vẫn Update");
}

// Cảnh của SpecialSceneCamera: giữ pitch, rút khoảng cách; khoảng cách muốn là của người chơi chứ
// không phải 17,5.
void fit_distance(Context& context) {
    const auto walled = map_with_wall(40, 30.0F);
    const auto flat = flat_map();
    context.expect(walled.has_value() && flat.has_value(), "dựng map");
    if (!walled || !flat) return;
    CameraRules rules;
    rules.fit = CameraFit::kDistance;
    FollowCamera stuck{rules};
    stuck.enter(*walled, Vec3{}, 1.0F);
    context.expect(near_value(stuck.eye_pitch(), -40.0F * kDegree), "không đổi pitch");
    context.expect(stuck.zoom(*walled) < 1.0F, "mắt vướng thì khoảng cách giảm");
    const bool is_clear = !walled->touches_sphere(stuck.pose().eye, 10.0F);
    context.expect(is_clear, "mắt sau khi rút không chạm");
    FollowCamera free{rules};
    free.enter(*flat, Vec3{}, 0.5F);
    for (int frame = 0; frame < 300; ++frame) {
        free.set_look_at(*flat, Vec3{.x = static_cast<float>(frame), .y = 0.0F, .z = 0.0F});
    }
    context.expect(near_value(free.zoom(*flat), 0.5F), "mắt trống: nới tới đúng zoom đã đặt");
}

// MouseTick: bấm, kéo, giữ lặp, lăn.
void ticker_events(Context& context) {
    MouseTicker ticker;
    MouseSample mouse{.x = 100, .y = 100};
    mouse.is_left_down = true;
    const MouseEvents down = ticker.tick(mouse, after(1000), false);
    const bool is_down_only = down.has(MouseEvent::kLeftDown) && !down.has(MouseEvent::kLeftDrag);
    context.expect(is_down_only, "nhịp nhấn: chỉ có nhấn");
    mouse.x = 104;
    mouse.dx = 4;
    const MouseEvents drag = ticker.tick(mouse, after(1100), false);
    const bool is_drag = drag.has(MouseEvent::kLeftDrag) && drag.has(MouseEvent::kMove);
    context.expect(is_drag && !drag.has(MouseEvent::kLeftRepeat), "giữ qua hai nhịp và dời: kéo");
    mouse.dx = 0;
    mouse.is_left_down = false;
    const MouseEvents up = ticker.tick(mouse, after(1499), false);
    const bool is_click = up.has(MouseEvent::kLeftClick) && up.has(MouseEvent::kLeftUp);
    context.expect(is_click, "nhả trước 500 ms, lệch 4 điểm ảnh: bấm rồi nhả");
    mouse.is_left_down = true;
    static_cast<void>(ticker.tick(mouse, after(2000), false));
    mouse.x = 109;
    mouse.is_left_down = false;
    const MouseEvents far = ticker.tick(mouse, after(2100), false);
    const bool is_far = !far.has(MouseEvent::kLeftClick) && far.has(MouseEvent::kLeftUp);
    context.expect(is_far, "lệch 5 điểm ảnh: chỉ nhả");
    mouse.is_left_down = true;
    static_cast<void>(ticker.tick(mouse, after(3000), false));
    const MouseEvents early = ticker.tick(mouse, after(4000), false);
    context.expect(!early.has(MouseEvent::kLeftRepeat), "giữ đúng 1000 ms: chưa lặp");
    const MouseEvents late = ticker.tick(mouse, after(4001), false);
    context.expect(late.has(MouseEvent::kLeftRepeat), "giữ quá 1000 ms: lặp");
    mouse.is_left_down = false;
    const MouseEvents slow = ticker.tick(mouse, after(4100), false);
    context.expect(!slow.has(MouseEvent::kLeftClick), "nhả sau 500 ms không phải bấm");
}

void ticker_other_buttons(Context& context) {
    MouseTicker ticker;
    MouseSample mouse{.x = 50, .y = 50};
    mouse.is_right_down = true;
    mouse.is_middle_down = true;
    const MouseEvents down = ticker.tick(mouse, after(1000), false);
    const bool is_both = down.has(MouseEvent::kRightDown) && down.has(MouseEvent::kMiddleDown);
    context.expect(is_both, "nhấn phải và giữa");
    mouse.dy = 30;
    mouse.y = 80;
    mouse.is_wheel_up = true;
    const MouseEvents drag = ticker.tick(mouse, after(1050), false);
    const bool is_dragged = drag.has(MouseEvent::kRightDrag) && drag.has(MouseEvent::kMiddleDrag);
    context.expect(is_dragged && drag.has(MouseEvent::kWheelUp), "kéo phải, kéo giữa, lăn lên");
    mouse.dy = 0;
    mouse.is_wheel_up = false;
    mouse.is_right_down = false;
    mouse.is_middle_down = false;
    const MouseEvents up = ticker.tick(mouse, after(1100), false);
    context.expect(up.has(MouseEvent::kMiddleClick), "nút giữa bấm không cần đứng yên");
    const bool is_right_up = up.has(MouseEvent::kRightUp) && !up.has(MouseEvent::kRightClick);
    context.expect(is_right_up, "nút phải lệch 30 điểm ảnh: không bấm");
    mouse.is_right_down = true;
    static_cast<void>(ticker.tick(mouse, after(2000), false));
    mouse.is_right_down = false;
    const MouseEvents held = ticker.tick(mouse, after(2100), true);
    context.expect(!held.has(MouseEvent::kRightClick), "camera đang kéo: nhả phải không là bấm");
    mouse.is_left_down = true;
    static_cast<void>(ticker.tick(mouse, after(3000), false));
    ticker.drop_left();
    mouse.is_left_down = false;
    const MouseEvents dropped = ticker.tick(mouse, after(3100), false);
    context.expect(!dropped.has(MouseEvent::kLeftUp), "nút trái bị bỏ thì không có nhả");
}

// Khung của màn chơi trên map phẳng: giữ camera, người lái và đồng hồ giả.
struct Play {
    Ground ground;
    FollowCamera camera{CameraRules{}};
    Pilot pilot{PilotRules{}};
    PilotFrame frame;
    int now_ms = 1000;

    PilotStep step(int advance_ms) {
        now_ms += advance_ms;
        frame.now = after(now_ms);
        frame.seconds = static_cast<float>(advance_ms) / 1000.0F;
        const PilotStep done = pilot.frame(camera, ground, frame);
        frame.mouse.dx = 0;
        frame.mouse.dy = 0;
        frame.mouse.is_wheel_up = false;
        frame.mouse.is_wheel_down = false;
        return done;
    }

    void drag(int dx, int dy) {
        frame.mouse.x += dx;
        frame.mouse.y += dy;
        frame.mouse.dx = dx;
        frame.mouse.dy = dy;
    }
};

[[nodiscard]] std::optional<Play> playing(PilotRules rules) {
    std::optional<Ground> ground = flat_map();
    if (!ground) return std::nullopt;
    Play play{.ground = std::move(*ground),
        .camera = FollowCamera{CameraRules{}},
        .pilot = Pilot{rules},
        .frame = PilotFrame{},
        .now_ms = 1000};
    play.camera.enter(play.ground, Vec3{}, 1.0F);
    play.pilot.enter(1.0F);
    play.frame.mouse.x = 400;
    play.frame.mouse.y = 300;
    return play;
}

// Kéo phải: ngang không quá 4 điểm ảnh từ chỗ nhấn thì chưa xoay; quá thì hướng -dx / 300 và
// pitch -dy / 300.
void right_drag(Context& context) {
    std::optional<Play> play = playing(PilotRules{});
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    const float direction = play->camera.direction();
    const float pitch = play->camera.pitch();
    play->frame.mouse.is_right_down = true;
    static_cast<void>(play->step(20));
    play->drag(4, 30);
    static_cast<void>(play->step(20));
    context.expect(near_value(play->camera.direction(), direction), "lệch ngang 4: chưa xoay");
    context.expect(!play->pilot.holds_cursor(), "chưa giữ con trỏ");
    play->drag(30, 15);
    static_cast<void>(play->step(20));
    context.expect(play->pilot.holds_cursor(), "lệch ngang 34: giữ con trỏ");
    context.expect(near_value(play->camera.direction(), direction - 0.1F), "hướng -30 / 300");
    context.expect(near_value(play->camera.pitch(), pitch - 0.05F), "pitch -15 / 300");
    play->drag(0, 600);
    static_cast<void>(play->step(20));
    context.expect(near_value(play->camera.pitch(), -60.0F * kDegree), "kẹp ở Camera_Pitch_Max");
    play->drag(0, -900);
    static_cast<void>(play->step(20));
    context.expect(near_value(play->camera.pitch(), 40.0F * kDegree), "kẹp ở Camera_Pitch_Min");
    play->frame.mouse.is_right_down = false;
    static_cast<void>(play->step(20));
    context.expect(!play->pilot.holds_cursor(), "nhả phải thì thả con trỏ");
}

// Kéo nút giữa: 0,25 độ mỗi điểm ảnh, kéo xuống là nhìn xuống thêm.
void middle_drag(Context& context) {
    std::optional<Play> play = playing(PilotRules{});
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    const float pitch = play->camera.pitch();
    play->frame.mouse.is_middle_down = true;
    static_cast<void>(play->step(20));
    context.expect(play->pilot.holds_cursor(), "nhấn nút giữa là giữ con trỏ ngay");
    play->drag(0, 20);
    static_cast<void>(play->step(20));
    context.expect(near_value(play->camera.pitch(), pitch - (5.0F * kDegree)), "20 điểm ảnh: 5 độ");
    play->frame.mouse.is_middle_down = false;
    static_cast<void>(play->step(20));
    context.expect(!play->pilot.holds_cursor(), "nhả nút giữa");
}

// Lăn chuột khi Camera_Smooth bật: đích dời 0,1, zoom tiến 0,01 mỗi nhịp 1/45 giây rồi dừng đúng
// đích; pitch người chơi đặt không đổi.
void wheel_smooth(Context& context) {
    std::optional<Play> play = playing(PilotRules{});
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    const float pitch = play->camera.pitch();
    play->frame.mouse.is_wheel_up = true;
    PilotFrame& frame = play->frame;
    frame.now = after(2000);
    frame.seconds = 1.0F / 45.0F;
    static_cast<void>(play->pilot.frame(play->camera, play->ground, frame));
    frame.mouse.is_wheel_up = false;
    context.expect(near_value(play->pilot.zoom_target(), 0.9F), "đích 0,9");
    context.expect(near_value(play->camera.zoom(play->ground), 0.99F), "nhịp đầu tiến 0,01");
    for (int tick = 0; tick < 5; ++tick) {
        static_cast<void>(play->pilot.frame(play->camera, play->ground, frame));
    }
    context.expect(near_value(play->camera.zoom(play->ground), 0.94F), "sáu nhịp: 0,94");
    for (int tick = 0; tick < 10; ++tick) {
        static_cast<void>(play->pilot.frame(play->camera, play->ground, frame));
    }
    context.expect(near_value(play->camera.zoom(play->ground), 0.9F), "dừng đúng đích");
    context.expect(near_value(play->camera.pitch(), pitch), "pitch giữ nguyên");
    frame.mouse.is_wheel_down = true;
    static_cast<void>(play->pilot.frame(play->camera, play->ground, frame));
    frame.mouse.is_wheel_down = false;
    context.expect(near_value(play->pilot.zoom_target(), 1.0F), "lăn xuống: đích về 1");
}

// Camera_Smooth tắt: mỗi nấc là Camera_SetZoom(BOOL, 2).
void wheel_plain(Context& context) {
    PilotRules rules;
    rules.is_smooth = false;
    std::optional<Play> play = playing(rules);
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    play->frame.mouse.is_wheel_up = true;
    static_cast<void>(play->step(20));
    context.expect(near_value(play->camera.zoom(play->ground), 0.9F), "một nấc: hai bước 0,05");
    key_zoom(play->camera, play->ground, ZoomWay::kFarther);
    context.expect(near_value(play->camera.zoom(play->ground), 1.0F), "phím zoom: hai bước");
    key_turn(play->camera, play->ground, -1);
    context.expect(near_value(play->camera.direction(), 3.1415F - 0.04F), "phím xoay 0,04");
}

const core::GroundPoint kHere{.x = 10.0F, .z = 20.0F};
const core::GroundPoint kThere{.x = 30.0F, .z = 20.0F};

[[nodiscard]] bool is_point(const std::optional<core::GroundPoint>& order, core::GroundPoint want) {
    return order && near_value(order->x, want.x) && near_value(order->z, want.z);
}

// Nhả trái thì đi tới điểm đất của nhịp gần nhất không có bấm; hai lệnh cách nhau hơn 100 ms.
void click_to_move(Context& context) {
    std::optional<Play> play = playing(PilotRules{});
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    play->frame.under_cursor = kHere;
    play->frame.mouse.is_left_down = true;
    context.expect(!play->step(20).move_to, "nhấn trái chưa ra lệnh");
    play->frame.under_cursor = kThere;
    play->frame.mouse.is_left_down = false;
    const PilotStep released = play->step(20);
    context.expect(is_point(released.move_to, kHere), "bấm: đích là điểm của nhịp trước");
    play->frame.mouse.is_left_down = true;
    static_cast<void>(play->step(20));
    play->frame.mouse.is_left_down = false;
    context.expect(!play->step(20).move_to, "chưa quá 100 ms từ lệnh trước: bỏ");
    play->frame.mouse.is_left_down = true;
    static_cast<void>(play->step(100));
    play->frame.mouse.is_left_down = false;
    context.expect(is_point(play->step(20).move_to, kThere), "quá 100 ms: nhận");
    play->frame.under_cursor.reset();
    static_cast<void>(play->step(200));
    play->frame.mouse.is_left_down = true;
    static_cast<void>(play->step(20));
    play->frame.mouse.is_left_down = false;
    context.expect(!play->step(600).move_to, "không có đất dưới con trỏ thì không đi");
}

// Giữ trái quá 1000 ms: tự chạy, mỗi 500 ms một lệnh tới điểm dưới con trỏ, cả sau khi nhả; nhấn
// trái lần nữa thì dừng.
void hold_to_run(Context& context) {
    std::optional<Play> play = playing(PilotRules{});
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    play->frame.under_cursor = kHere;
    play->frame.mouse.is_left_down = true;
    static_cast<void>(play->step(20));
    context.expect(!play->step(1000).move_to && !play->pilot.auto_run(), "đúng 1000 ms: chưa chạy");
    const PilotStep first = play->step(20);
    context.expect(play->pilot.auto_run() && is_point(first.move_to, kHere), "quá 1000 ms: chạy");
    play->frame.under_cursor = kThere;
    context.expect(!play->step(480).move_to, "chưa đủ 500 ms từ lệnh trước: chờ");
    context.expect(is_point(play->step(20).move_to, kThere), "đủ 500 ms: lệnh mới nhất");
    play->frame.mouse.is_left_down = false;
    static_cast<void>(play->step(20));
    context.expect(play->pilot.auto_run(), "nhả rồi vẫn tự chạy");
    context.expect(is_point(play->step(600).move_to, kThere), "vẫn ra lệnh theo con trỏ");
    play->frame.mouse.is_left_down = true;
    static_cast<void>(play->step(20));
    context.expect(!play->pilot.auto_run(), "nhấn trái lần nữa thì dừng");
    play->pilot.cancel_left();
    play->frame.mouse.is_left_down = false;
    context.expect(!play->step(600).move_to, "thao tác trái bị bỏ: không lệnh đi");
}

// Con trỏ trên giao diện: bấm trái không đi, nhấn phải không mở khoá kéo camera.
void over_ui(Context& context) {
    std::optional<Play> play = playing(PilotRules{});
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    const float direction = play->camera.direction();
    play->frame.is_over_ui = true;
    play->frame.under_cursor = kHere;
    play->frame.mouse.is_left_down = true;
    static_cast<void>(play->step(20));
    play->frame.mouse.is_left_down = false;
    context.expect(!play->step(20).move_to, "bấm trên giao diện không đi");
    play->frame.mouse.is_right_down = true;
    static_cast<void>(play->step(20));
    play->drag(40, 0);
    static_cast<void>(play->step(20));
    context.expect(near_value(play->camera.direction(), direction), "nhấn phải trên giao diện");
}

// ResetCamera: gói hướng về [0, 6,283) rồi quay 1 radian mỗi giây về 3,1415.
void reset_camera(Context& context) {
    std::optional<Play> play = playing(PilotRules{});
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    play->camera.set_direction(play->ground, -1.0F);
    play->pilot.reset_camera(play->camera, play->ground);
    context.expect(near_value(play->camera.direction(), 5.283F), "hướng âm gói lên");
    static_cast<void>(play->step(1000));
    context.expect(near_value(play->camera.direction(), 4.283F), "một giây quay 1 radian");
    static_cast<void>(play->step(2000));
    context.expect(near_value(play->camera.direction(), 3.1415F), "qua đích thì dừng ở 3,1415");
    static_cast<void>(play->step(1000));
    context.expect(near_value(play->camera.direction(), 3.1415F), "đã dừng");
    play->camera.set_direction(play->ground, 7.283F);
    play->pilot.reset_camera(play->camera, play->ground);
    context.expect(near_value(play->camera.direction(), 1.0F), "hướng quá một vòng gói xuống");
    static_cast<void>(play->step(500));
    context.expect(near_value(play->camera.direction(), 1.5F), "dưới đích thì quay tăng");
}

// Camera_RestoreView: nhân vật đi thì pitch tiến 30 độ mỗi giây về Camera_Pitch_Moving; người chơi
// vừa tự kéo thì chờ tới lần dừng bước kế tiếp.
void restore_view(Context& context) {
    PilotRules rules;
    rules.restores_view = true;
    std::optional<Play> play = playing(rules);
    context.expect(play.has_value(), "dựng map phẳng");
    if (!play) return;
    play->camera.set_pitch(play->ground, -10.0F * kDegree);
    static_cast<void>(play->step(100));
    context.expect(near_value(play->camera.pitch(), -10.0F * kDegree), "đứng yên: không chỉnh");
    play->frame.is_player_moving = true;
    static_cast<void>(play->step(500));
    context.expect(near_value(play->camera.pitch(), -25.0F * kDegree), "nửa giây: 15 độ");
    static_cast<void>(play->step(1000));
    context.expect(near_value(play->camera.pitch(), -40.0F * kDegree), "tới Camera_Pitch_Moving");
    play->frame.mouse.is_right_down = true;
    static_cast<void>(play->step(20));
    play->drag(10, -30);
    static_cast<void>(play->step(20));
    const float pulled = play->camera.pitch();
    play->frame.mouse.is_right_down = false;
    static_cast<void>(play->step(500));
    context.expect(near_value(play->camera.pitch(), pulled), "vừa tự kéo: không chỉnh lại");
}

constexpr std::array kCases{
    Case{.name = "eye_formula", .body = &eye_formula},
    Case{.name = "enter_scene", .body = &enter_scene},
    Case{.name = "zoom_api", .body = &zoom_api},
    Case{.name = "pitch_and_fov", .body = &pitch_and_fov},
    Case{.name = "fit_pitch", .body = &fit_pitch},
    Case{.name = "fit_distance", .body = &fit_distance},
    Case{.name = "ticker_events", .body = &ticker_events},
    Case{.name = "ticker_other_buttons", .body = &ticker_other_buttons},
    Case{.name = "right_drag", .body = &right_drag},
    Case{.name = "middle_drag", .body = &middle_drag},
    Case{.name = "wheel_smooth", .body = &wheel_smooth},
    Case{.name = "wheel_plain", .body = &wheel_plain},
    Case{.name = "click_to_move", .body = &click_to_move},
    Case{.name = "hold_to_run", .body = &hold_to_run},
    Case{.name = "over_ui", .body = &over_ui},
    Case{.name = "reset_camera", .body = &reset_camera},
    Case{.name = "restore_view", .body = &restore_view},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "pilot_tests: mọi ca phải qua");
    return 0;
}
