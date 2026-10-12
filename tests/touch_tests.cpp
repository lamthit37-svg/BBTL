// Kiểm TouchGestures: một ngón như chuột trái; kéo quá ngưỡng trước khi giữ đủ lâu thì thành xoay
// camera, giữ đủ lâu rồi kéo thì vẫn là lái tự chạy; ngón thứ hai huỷ thao tác trái rồi chuyển sang
// camera (chụm mở thành nấc lăn, tâm hai ngón dời thành kéo phải), không ra lệnh đi tới khi nhấc
// hết ngón, và ngón thứ ba bị bỏ. Cần gạt ảo: ngón chạm góc trái dưới thành cần, đế nổi ở chỗ chạm
// (lùi khỏi mép), độ gạt theo bán kính dp, và cần chơi cùng lúc với cử chỉ của ngón khác.
// Nguồn: TLBB Dev tests/render/touch_test.cpp@e0d89a6. Khác gốc: khung test của dự án; mốc thời
// gian đi qua after; điểm và độ gạt mong đợi gom vào struct để hàm kiểm không nhận bốn số rời.
#include "control/input.hpp"
#include "control/touch.hpp"
#include "core/check.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cmath>
#include <vector>

namespace game::test {
namespace {

using control::InputEvent;
using control::InputKind;
using control::MouseButton;
using control::TouchGestures;
using control::TouchPoint;
using control::TouchTime;

constexpr float kTolerance = 1e-4F;
constexpr TouchTime kStart{std::chrono::seconds{5}};

[[nodiscard]] bool near_value(float left, float right) {
    return std::fabs(left - right) < kTolerance;
}

// Mốc thời gian sau milliseconds kể từ lúc chạm đầu của bài.
[[nodiscard]] TouchTime after(int milliseconds) {
    return kStart + std::chrono::milliseconds{milliseconds};
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): hai trục x và y của một điểm (HP-07)
[[nodiscard]] TouchPoint at(float along_x, float along_y) {
    return TouchPoint{.x = along_x, .y = along_y};
}

// Sự kiện nhấn, nhả hay di con trỏ ở điểm đã chuẩn hoá where.
[[nodiscard]] bool is_at(const InputEvent& event, InputKind kind, MouseButton button, TouchPoint where) {
    const bool is_kind = event.kind == kind && event.button == button;
    return is_kind && near_value(event.x, where.x) && near_value(event.y, where.y);
}

// Cửa sổ 1000 x 500 điểm, một điểm cho một dp: điểm (100, 50) là (0,1; 0,1) sau khi chuẩn hoá.
[[nodiscard]] TouchGestures screen() {
    TouchGestures gestures;
    gestures.resize(1000.0F, 500.0F, 1.0F);
    return gestures;
}

void one_finger(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(100.0F, 50.0F), after(0), out);
    const bool is_pressed = out.size() == 1 && is_at(out[0], InputKind::kPress, MouseButton::kLeft, at(0.1F, 0.1F));
    context.expect(is_pressed, "chạm là nhấn trái");
    out.clear();
    gestures.move(1, at(110.0F, 50.0F), after(100), out);
    const bool is_moved = out.size() == 1 && out[0].kind == InputKind::kMove;
    context.expect(is_moved && near_value(out[0].x, 0.11F), "rung dưới ngưỡng là di con trỏ");
    context.expect(is_moved && near_value(out[0].dx, 10.0F), "độ dời tính bằng điểm");
    out.clear();
    gestures.up(1, at(110.0F, 50.0F), out);
    const bool is_released = out.size() == 1 && is_at(out[0], InputKind::kRelease, MouseButton::kLeft, at(0.11F, 0.1F));
    context.expect(is_released, "nhấc là nhả trái: chạm để đi");
}

// Kéo một ngón quá kDragSlop trước kHoldTime: huỷ thao tác trái rồi xoay camera như kéo phải, độ
// dời tính từ chỗ chạm; nhấc là nhả phải.
void one_finger_turns(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(100.0F, 50.0F), after(0), out);
    out.clear();
    gestures.move(1, at(200.0F, 60.0F), after(200), out);
    context.expect(out.size() == 3, "huỷ, nhấn phải, kéo");
    if (out.size() != 3) return;
    const bool is_cancelled = out[0].kind == InputKind::kCancel && out[0].button == MouseButton::kLeft;
    context.expect(is_cancelled, "huỷ trái");
    const bool is_pressed = is_at(out[1], InputKind::kPress, MouseButton::kRight, at(0.1F, 0.1F));
    context.expect(is_pressed, "nhấn phải ở chỗ chạm");
    const bool is_dragged = out[2].kind == InputKind::kMove && out[2].button == MouseButton::kRight;
    context.expect(is_dragged && near_value(out[2].dx, 100.0F), "kéo phải từ chỗ chạm, dx");
    context.expect(is_dragged && near_value(out[2].dy, 10.0F), "kéo phải từ chỗ chạm, dy");
    out.clear();
    gestures.move(1, at(150.0F, 60.0F), after(300), out);
    context.expect(out.size() == 1 && near_value(out[0].dx, -50.0F), "kéo tiếp là kéo phải");
    out.clear();
    gestures.up(1, at(150.0F, 60.0F), out);
    const bool is_released =
        out.size() == 1 && is_at(out[0], InputKind::kRelease, MouseButton::kRight, at(0.15F, 0.12F));
    context.expect(is_released, "nhấc là nhả phải, không ra lệnh đi");
}

// Giữ yên quá kHoldTime là tự chạy của Pilot; kéo sau đó là lái, không xoay camera.
void hold_then_steer(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(100.0F, 50.0F), after(0), out);
    out.clear();
    gestures.move(1, at(300.0F, 50.0F), after(1200), out);
    const bool is_steered = out.size() == 1 && out[0].kind == InputKind::kMove;
    context.expect(is_steered && out[0].button == MouseButton::kLeft, "giữ lâu rồi kéo là lái");
    out.clear();
    gestures.up(1, at(300.0F, 50.0F), out);
    context.expect(out.size() == 1 && out[0].kind == InputKind::kRelease, "nhấc là nhả trái");
}

void second_finger(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(100.0F, 100.0F), after(0), out);
    out.clear();
    gestures.down(2, at(300.0F, 100.0F), after(0), out);
    const bool is_cancelled = out.size() == 2 && out[0].kind == InputKind::kCancel;
    context.expect(is_cancelled, "ngón thứ hai huỷ thao tác trái");
    const bool is_pressed = out.size() == 2 && is_at(out[1], InputKind::kPress, MouseButton::kRight, at(0.2F, 0.2F));
    context.expect(is_pressed, "rồi nhấn phải ở tâm hai ngón");
    out.clear();
    gestures.move(2, at(400.0F, 100.0F), after(0), out);
    context.expect(out.size() == 3, "tâm dời và hai nấc lăn");
    if (out.size() != 3) return;
    const bool is_drag = out[0].kind == InputKind::kMove && near_value(out[0].dx, 50.0F);
    context.expect(is_drag, "tâm dời 50 điểm là kéo");
    const bool is_first = out[1].kind == InputKind::kWheel && near_value(out[1].wheel, 1.0F);
    context.expect(is_first, "mở ra 100 điểm: nấc một");
    const bool is_second = out[2].kind == InputKind::kWheel && near_value(out[2].wheel, 1.0F);
    context.expect(is_second, "nấc hai, dư 4 điểm");
    out.clear();
    gestures.up(2, at(400.0F, 100.0F), out);
    context.expect(out.size() == 1 && out[0].kind == InputKind::kRelease, "còn một ngón thì nhả");
    context.expect(out.size() == 1 && out[0].button == MouseButton::kRight, "đúng nút phải");
    out.clear();
    gestures.move(1, at(150.0F, 100.0F), after(0), out);
    gestures.up(1, at(150.0F, 100.0F), out);
    context.expect(out.empty(), "sau camera không ra lệnh đi tới khi nhấc hết");
    gestures.down(3, at(100.0F, 50.0F), after(0), out);
    const bool is_again = out.size() == 1 && out[0].kind == InputKind::kPress;
    context.expect(is_again, "nhấc hết rồi thì chạm lại là nhấn");
}

[[nodiscard]] int notches_in(const std::vector<InputEvent>& events) {
    int total = 0;
    for (const InputEvent& event : events) {
        total += event.kind == InputKind::kWheel ? static_cast<int>(event.wheel) : 0;
    }
    return total;
}

void pinch_in(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(100.0F, 100.0F), after(0), out);
    gestures.down(2, at(400.0F, 100.0F), after(0), out);
    out.clear();
    gestures.move(2, at(300.0F, 100.0F), after(0), out);
    gestures.move(1, at(200.0F, 100.0F), after(0), out);
    context.expect(notches_in(out) == -4, "chụm 200 điểm là bốn nấc lùi xa");
}

void third_finger(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(100.0F, 100.0F), after(0), out);
    gestures.down(2, at(300.0F, 100.0F), after(0), out);
    out.clear();
    gestures.down(3, at(500.0F, 400.0F), after(0), out);
    gestures.move(3, at(600.0F, 400.0F), after(0), out);
    gestures.up(3, at(600.0F, 400.0F), out);
    context.expect(out.empty(), "ngón thứ ba bị bỏ");
}

// Cần gạt ảo: tâm đế và độ gạt mong đợi của một sự kiện Stick.
struct StickAt {
    TouchPoint base;
    TouchPoint tilt;
};

[[nodiscard]] bool is_stick(const InputEvent& event, StickAt expected) {
    const bool is_base =
        event.kind == InputKind::kStick && near_value(event.x, expected.base.x) && near_value(event.y, expected.base.y);
    return is_base && near_value(event.dx, expected.tilt.x) && near_value(event.dy, expected.tilt.y);
}

// Đế ở chỗ chạm, độ gạt là độ dời chia bán kính (60 điểm ở mật độ 1), kẹp ở độ dài 1; ra khỏi vùng
// sau khi đã chạm vẫn là cần; nhấc là nhả cần, không có thao tác chuột nào.
void stick_hold(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(200.0F, 300.0F), after(0), out);
    const StickAt centred{.base = at(0.2F, 0.6F), .tilt = at(0.0F, 0.0F)};
    context.expect(out.size() == 1 && is_stick(out[0], centred), "chạm góc trái dưới là cần");
    out.clear();
    gestures.move(1, at(230.0F, 300.0F), after(50), out);
    const StickAt half{.base = at(0.2F, 0.6F), .tilt = at(0.5F, 0.0F)};
    context.expect(out.size() == 1 && is_stick(out[0], half), "gạt nửa bán kính");
    out.clear();
    gestures.move(1, at(200.0F, 100.0F), after(2000), out);
    const StickAt full{.base = at(0.2F, 0.6F), .tilt = at(0.0F, -1.0F)};
    context.expect(out.size() == 1 && is_stick(out[0], full), "quá bán kính là hết cỡ");
    out.clear();
    gestures.up(1, at(200.0F, 100.0F), out);
    const bool is_ended = out.size() == 1 && out[0].kind == InputKind::kStickEnd;
    context.expect(is_ended, "nhấc là nhả cần");
}

// Chạm sát mép: đế lùi vào để cả đế nằm trong khung, độ gạt tính từ tâm đế đã lùi.
void stick_edge(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(10.0F, 490.0F), after(0), out);
    const float half = std::sqrt(0.5F);
    const StickAt pushed{.base = at(0.06F, 0.88F), .tilt = at(-half, half)};
    context.expect(out.size() == 1 && is_stick(out[0], pushed), "đế lùi khỏi mép");
}

// Mật độ 2 điểm cho một dp: bán kính 120 điểm.
void stick_density(Context& context) {
    TouchGestures gestures;
    gestures.resize(1000.0F, 500.0F, 2.0F);
    std::vector<InputEvent> out;
    gestures.down(1, at(200.0F, 300.0F), after(0), out);
    out.clear();
    gestures.move(1, at(260.0F, 300.0F), after(0), out);
    const StickAt half{.base = at(0.2F, 0.6F), .tilt = at(0.5F, 0.0F)};
    context.expect(out.size() == 1 && is_stick(out[0], half), "bán kính theo dp");
}

// Cần và cử chỉ cùng lúc: ngón ngoài vùng vẫn là chuột trái chứ không phải chế độ hai ngón; ngón
// thứ hai chạm vào vùng khi đã có cần là cử chỉ; cần chạm sau ngón chuột không huỷ ngón đó.
void stick_with_gestures(Context& context) {
    TouchGestures gestures = screen();
    std::vector<InputEvent> out;
    gestures.down(1, at(200.0F, 300.0F), after(0), out);
    out.clear();
    gestures.down(2, at(700.0F, 100.0F), after(0), out);
    const bool is_mouse = out.size() == 1 && is_at(out[0], InputKind::kPress, MouseButton::kLeft, at(0.7F, 0.2F));
    context.expect(is_mouse, "ngón ngoài vùng là chuột trái");
    out.clear();
    gestures.up(2, at(700.0F, 100.0F), out);
    context.expect(out.size() == 1 && out[0].kind == InputKind::kRelease, "chạm để đi khi giữ cần");
    out.clear();
    gestures.down(3, at(100.0F, 400.0F), after(0), out);
    context.expect(out.size() == 1 && out[0].kind == InputKind::kPress, "đã có cần thì là cử chỉ");
    TouchGestures later = screen();
    out.clear();
    later.down(1, at(700.0F, 100.0F), after(0), out);
    later.down(2, at(200.0F, 300.0F), after(0), out);
    context.expect(out.size() == 2 && out[1].kind == InputKind::kStick, "cần chạm sau không huỷ");
    out.clear();
    later.up(1, at(700.0F, 100.0F), out);
    context.expect(out.size() == 1 && out[0].kind == InputKind::kRelease, "ngón chuột vẫn nhả");
}

constexpr std::array kCases{
    Case{.name = "one_finger", .body = &one_finger},
    Case{.name = "one_finger_turns", .body = &one_finger_turns},
    Case{.name = "hold_then_steer", .body = &hold_then_steer},
    Case{.name = "second_finger", .body = &second_finger},
    Case{.name = "pinch_in", .body = &pinch_in},
    Case{.name = "third_finger", .body = &third_finger},
    Case{.name = "stick_hold", .body = &stick_hold},
    Case{.name = "stick_edge", .body = &stick_edge},
    Case{.name = "stick_density", .body = &stick_density},
    Case{.name = "stick_with_gestures", .body = &stick_with_gestures},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "touch_tests: mọi ca phải qua");
    return 0;
}
