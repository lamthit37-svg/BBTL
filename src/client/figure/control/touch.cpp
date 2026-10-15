// Máy trạng thái của cử chỉ chạm, luật ghi ở touch.hpp: Idle, Pointer (một ngón như chuột trái),
// Turn (một ngón kéo sớm: kéo phải), Camera (hai ngón: kéo phải và nấc lăn; giữ tới khi nhấc hết; đặt rồi nhấc
// nhanh là chạm hai ngón).
// Ngón của cần gạt đi riêng (stick_), không vào fingers_ nên không đổi chế độ của cử chỉ.
#include "control/touch.hpp"

#include "control/input.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

namespace game::control {
namespace {

[[nodiscard]] TouchPoint middle(TouchPoint first, TouchPoint second) noexcept {
    return TouchPoint{.x = (first.x + second.x) / 2.0F, .y = (first.y + second.y) / 2.0F};
}

[[nodiscard]] float distance(TouchPoint first, TouchPoint second) noexcept {
    return std::hypot(first.x - second.x, first.y - second.y);
}

[[nodiscard]] InputEvent wheel_event(float notches) noexcept {
    InputEvent event;
    event.kind = InputKind::kWheel;
    event.wheel = notches;
    return event;
}

} // namespace

void TouchGestures::resize(float width, float height, float points_per_dp) noexcept {
    width_ = std::max(width, 1.0F);
    height_ = std::max(height, 1.0F);
    radius_ = kStickRadius * std::max(points_per_dp, 0.01F);
}

// Cần gạt ảo
bool TouchGestures::is_stick_zone(TouchPoint where) const noexcept {
    const bool is_left = where.x < width_ * kStickZoneWidth;
    const bool is_low = where.y > height_ * kStickZoneTop;
    return is_left && is_low;
}

// Đế ở chỗ chạm, lùi vào cho cả đế nằm trong khung; khung hẹp hơn đế thì đế sát mép trái, trên.
void TouchGestures::begin_stick(std::uint64_t finger, TouchPoint where, std::vector<InputEvent>& out) {
    const float base_x = std::clamp(where.x, radius_, std::max(radius_, width_ - radius_));
    const float base_y = std::clamp(where.y, radius_, std::max(radius_, height_ - radius_));
    stick_ = Stick{.id = finger, .base = TouchPoint{.x = base_x, .y = base_y}};
    push_stick(where, out);
}

// Độ gạt là độ dời từ tâm đế chia bán kính; dài quá 1 thì kéo về 1, giữ hướng.
void TouchGestures::push_stick(TouchPoint where, std::vector<InputEvent>& out) const {
    if (!stick_) return;
    const TouchPoint base = stick_->base;
    const float along_x = (where.x - base.x) / radius_;
    const float along_y = (where.y - base.y) / radius_;
    const float length = std::hypot(along_x, along_y);
    const float shrink = length > 1.0F ? 1.0F / length : 1.0F;
    InputEvent event = at_event(InputKind::kStick, MouseButton::kLeft, base);
    event.dx = along_x * shrink;
    event.dy = along_y * shrink;
    out.push_back(event);
}

void TouchGestures::end_stick(std::vector<InputEvent>& out) {
    if (!stick_) return;
    emit(out, InputKind::kStickEnd, MouseButton::kLeft, stick_->base);
    stick_.reset();
}

bool TouchGestures::is_stick_finger(std::uint64_t finger) const noexcept {
    return stick_.has_value() && stick_->id == finger;
}

void TouchGestures::down(std::uint64_t finger, TouchPoint where, TouchTime now, std::vector<InputEvent>& out) {
    const bool is_stick = !stick_ && is_stick_zone(where);
    if (is_stick) {
        begin_stick(finger, where, out);
        return;
    }
    if (fingers_.size() >= 2) return;
    fingers_.push_back(Finger{.id = finger, .at = where});
    if (fingers_.size() == 2) {
        is_pair_open_ = true;
        has_pair_moved_ = false;
        pair_at_ = now;
        pair_first_ = fingers_.front().at;
        pair_second_ = fingers_.back().at;
        begin_camera(out);
        return;
    }
    mode_ = Mode::kPointer;
    start_ = where;
    pressed_at_ = now;
    emit(out, InputKind::kPress, MouseButton::kLeft, where);
}

void TouchGestures::move(std::uint64_t finger, TouchPoint where, TouchTime now, std::vector<InputEvent>& out) {
    if (is_stick_finger(finger)) {
        push_stick(where, out);
        return;
    }
    Finger* tracked = find(finger);
    if (tracked == nullptr) return;
    const TouchPoint from = tracked->at;
    tracked->at = where;
    const bool is_pair = mode_ == Mode::kCamera && fingers_.size() == 2;
    if (is_pair) {
        const bool is_far = distance(fingers_.front().at, pair_first_) > kDragSlop ||
                            distance(fingers_.back().at, pair_second_) > kDragSlop;
        if (is_far) has_pair_moved_ = true;
        follow_camera(out);
        return;
    }
    if (mode_ == Mode::kTurn) {
        push_drag(MouseButton::kRight, from, where, out);
        return;
    }
    if (mode_ != Mode::kPointer) return;
    const bool is_early = now - pressed_at_ < kHoldTime;
    const bool is_far = distance(start_, where) > kDragSlop;
    if (is_early && is_far) {
        begin_turn(where, out);
        return;
    }
    push_drag(MouseButton::kLeft, from, where, out);
}

void TouchGestures::up(std::uint64_t finger, TouchPoint where, TouchTime now, std::vector<InputEvent>& out) {
    if (is_stick_finger(finger)) {
        end_stick(out);
        return;
    }
    if (find(finger) == nullptr) return;
    // Ngón đầu nhấc khỏi cặp quyết định cú chạm hai ngón; ngón còn lại nhấc sau không tính lần nữa.
    if (is_pair_open_ && mode_ == Mode::kCamera && fingers_.size() == 2) {
        if (!has_pair_moved_ && now - pair_at_ <= kPairTapTime) ++pair_taps_;
        is_pair_open_ = false;
    }
    std::erase_if(fingers_, [finger](const Finger& tracked) { return tracked.id == finger; });
    if (mode_ == Mode::kPointer) emit(out, InputKind::kRelease, MouseButton::kLeft, where);
    if (mode_ == Mode::kTurn) end_turn(where, out);
    if (mode_ == Mode::kCamera && right_held_) end_camera(out);
    if (fingers_.empty()) mode_ = Mode::kIdle;
}

void TouchGestures::push_drag(MouseButton button, TouchPoint from, TouchPoint where,
    std::vector<InputEvent>& out) const {
    InputEvent event = at_event(InputKind::kMove, button, where);
    event.dx = where.x - from.x;
    event.dy = where.y - from.y;
    out.push_back(event);
}

// Một ngón kéo sớm: huỷ thao tác trái (không ra lệnh đi), nhấn phải ở chỗ chạm, rồi kéo phải từ đó
// tới ngón, để phần đã dời trước khi qua ngưỡng cũng xoay camera.
void TouchGestures::begin_turn(TouchPoint where, std::vector<InputEvent>& out) {
    mode_ = Mode::kTurn;
    emit(out, InputKind::kCancel, MouseButton::kLeft, start_);
    emit(out, InputKind::kPress, MouseButton::kRight, start_);
    right_held_ = true;
    push_drag(MouseButton::kRight, start_, where, out);
}

void TouchGestures::end_turn(TouchPoint where, std::vector<InputEvent>& out) {
    emit(out, InputKind::kRelease, MouseButton::kRight, where);
    right_held_ = false;
}

InputEvent TouchGestures::at_event(InputKind kind, MouseButton button, TouchPoint where) const {
    InputEvent event;
    event.kind = kind;
    event.button = button;
    event.x = where.x / width_;
    event.y = where.y / height_;
    return event;
}

// Thêm một sự kiện ở điểm where vào out.
void TouchGestures::emit(std::vector<InputEvent>& out, InputKind kind, MouseButton button, TouchPoint where) const {
    const InputEvent event = at_event(kind, button, where);
    out.push_back(event);
}

// Ngón thứ hai chạm xuống: huỷ thao tác trái đang dở (hay nhả kéo một ngón), nhấn phải ở tâm hai
// ngón.
void TouchGestures::begin_camera(std::vector<InputEvent>& out) {
    const TouchPoint first = fingers_.front().at;
    const TouchPoint second = fingers_.back().at;
    const InputKind ending = mode_ == Mode::kTurn ? InputKind::kRelease : InputKind::kCancel;
    const MouseButton held = mode_ == Mode::kTurn ? MouseButton::kRight : MouseButton::kLeft;
    const bool is_busy = mode_ == Mode::kPointer || mode_ == Mode::kTurn;
    if (is_busy) emit(out, ending, held, first);
    mode_ = Mode::kCamera;
    centre_ = middle(first, second);
    spread_ = distance(first, second);
    pinch_ = 0.0F;
    right_held_ = true;
    emit(out, InputKind::kPress, MouseButton::kRight, centre_);
}

// Tâm hai ngón dời thành kéo phải; khoảng cách đổi dồn lại, đủ kPinchStep thì thành một nấc lăn.
void TouchGestures::follow_camera(std::vector<InputEvent>& out) {
    const TouchPoint first = fingers_.front().at;
    const TouchPoint second = fingers_.back().at;
    const TouchPoint centre = middle(first, second);
    InputEvent drag = at_event(InputKind::kMove, MouseButton::kRight, centre);
    drag.dx = centre.x - centre_.x;
    drag.dy = centre.y - centre_.y;
    centre_ = centre;
    out.push_back(drag);
    const float spread = distance(first, second);
    pinch_ += spread - spread_;
    spread_ = spread;
    const float notches = std::trunc(pinch_ / kPinchStep);
    pinch_ -= notches * kPinchStep;
    const int count = static_cast<int>(std::fabs(notches));
    const float step = notches > 0.0F ? 1.0F : -1.0F;
    for (int index = 0; index < count; ++index) {
        out.push_back(wheel_event(step));
    }
}

void TouchGestures::end_camera(std::vector<InputEvent>& out) {
    emit(out, InputKind::kRelease, MouseButton::kRight, centre_);
    right_held_ = false;
}

TouchGestures::Finger* TouchGestures::find(std::uint64_t id) noexcept {
    const auto found = std::ranges::find(fingers_, id, &Finger::id);
    return found == fingers_.end() ? nullptr : &*found;
}

} // namespace game::control
