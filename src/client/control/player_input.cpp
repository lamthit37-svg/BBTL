// Chuột thành lệnh đi và chỉnh camera; luật và nguồn ở player_input.hpp. Địa chỉ là của Game.exe
// bản 3.71 (gốc 0x140000000).
#include "control/player_input.hpp"

#include "control/follow_camera.hpp"
#include "control/ground.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <numbers>
#include <optional>

namespace game::control {
namespace {

// MouseTick: bấm phải nhả trước 500 ms và lệch chỗ nhấn không quá 4 điểm ảnh mỗi trục; giữ trái
// quá 1000 ms (0x140f0c850) thì sinh sự kiện giữ lặp.
constexpr auto kClickTime = std::chrono::milliseconds(500);
constexpr int kClickSlop = 4;
constexpr auto kRepeatDown = std::chrono::milliseconds(1000);
// ProcessInput_Mouse: kéo phải ngang quá 4 điểm ảnh mới xoay (0x14064d0f2); mỗi điểm ảnh là 1/300
// radian (0x140c2a848); nút giữa 0,25 độ mỗi điểm ảnh (0x140a70b28); lăn hai bước khi không mượt.
constexpr int kDragStart = 4;
constexpr float kDragDivisor = 300.0F;
constexpr float kTiltDegrees = 0.25F;
constexpr int kZoomMultiple = 2;
// PI float của Game.exe (0x140baea28) và độ sang radian kiểu double của Tick (0x140c2e5b0).
constexpr float kFloatPi = std::numbers::pi_v<float>;
constexpr double kDegree = 0.017453292519444445;
// __PI của GameUtil.h (0x140b0dde8) và hai lần của nó (0x140b0ddec): đích và chu kỳ của
// ResetCamera.
// NOLINTNEXTLINE(modernize-use-std-numbers): giữ đúng hằng __PI của bản gốc (HP-07)
constexpr float kHome = 3.1415F;
constexpr float kFullTurn = 6.283F;
// MouseCommand_Active nhận lệnh đi cách lệnh trước hơn 100 ms; Enter_Move khi đang tự chạy nhận
// lệnh cách lệnh trước từ 500 ms.
constexpr auto kClickGap = std::chrono::milliseconds(100);
constexpr auto kRunGap = std::chrono::milliseconds(500);
// Phím xoay của bản 2008.
constexpr float kKeyTurn = 0.04F;
// Giới hạn pitch của dòng 1 SpecialSceneCamera (-40 và 60 độ), đổi bằng TDU_PI double như
// CScene::EnterScene (0x1406c0cc0): dùng khi số của System.cfg không hợp lệ.
// NOLINTNEXTLINE(modernize-use-std-numbers): giữ đúng hằng TDU_PI của bản gốc (HP-07)
constexpr double kPi = 3.1415926535;
constexpr float kRowPitchHigh = static_cast<float>(40.0 * kPi / 180.0);
constexpr float kRowPitchLow = static_cast<float>(-60.0 * kPi / 180.0);
// Pitch khi đang đi mặc định của Game.exe (0x140fb2d74): -40 độ.
constexpr float kRowMovingPitch = -0.69813174F;
constexpr float kPitchSpan = 90.0F;

[[nodiscard]] constexpr std::uint32_t bit_of(MouseEvent event) noexcept {
    return 1U << static_cast<unsigned>(event);
}

// Sự kiện mà cửa sổ giao diện dưới con trỏ nhận lấy; nhả nút phải, nút giữa, kéo và lăn vẫn tới
// màn chơi.
constexpr std::uint32_t kUiEvents = bit_of(MouseEvent::kLeftDown) | bit_of(MouseEvent::kLeftUp) |
    bit_of(MouseEvent::kLeftClick) | bit_of(MouseEvent::kLeftRepeat) | bit_of(MouseEvent::kRightDown) |
    bit_of(MouseEvent::kRightClick) | bit_of(MouseEvent::kMiddleDown) | bit_of(MouseEvent::kMiddleClick);

[[nodiscard]] bool is_near(int left, int right) noexcept {
    return std::abs(left - right) <= kClickSlop;
}

// Bốn sự kiện của một nút.
struct ButtonNames {
    MouseEvent down = MouseEvent::kLeftDown;
    MouseEvent click = MouseEvent::kLeftClick;
    MouseEvent up = MouseEvent::kLeftUp;
    MouseEvent drag = MouseEvent::kLeftDrag;
};

constexpr ButtonNames kMiddleNames{.down = MouseEvent::kMiddleDown,
    .click = MouseEvent::kMiddleClick,
    .up = MouseEvent::kMiddleUp,
    .drag = MouseEvent::kMiddleDrag};
constexpr ButtonNames kRightNames{.down = MouseEvent::kRightDown,
    .click = MouseEvent::kRightClick,
    .up = MouseEvent::kRightUp,
    .drag = MouseEvent::kRightDrag};

// Một nút ở nhịp này. Nút giữa bấm không cần đứng yên; nút phải không bấm khi camera đang kéo.
struct ButtonTick {
    const MouseSample* sample = nullptr;
    ButtonNames names;
    Clock::time_point now;
    bool is_down = false;
    bool is_moved = false;
    bool can_click = true;
    bool needs_still = true;
};

// Độ sang radian bằng float như Game.exe làm với số của System.cfg, đổi dấu: pitch âm là nhìn
// xuống.
[[nodiscard]] float flipped_radians(float degrees) noexcept {
    return -(degrees * kFloatPi / 180.0F);
}

[[nodiscard]] bool is_angle(float degrees) noexcept {
    return degrees >= -kPitchSpan && kPitchSpan >= degrees;
}

// Cạnh nhấn: ghi chỗ và lúc nhấn.
void press(MouseEvents& out, ButtonTrack& button, const ButtonTick& tick) noexcept {
    button.x = tick.sample->x;
    button.y = tick.sample->y;
    button.at = tick.now;
    out.add(tick.names.down);
}

// Cạnh nhả: bấm (nếu đủ nhanh và đủ gần chỗ nhấn) rồi nhả.
void release(MouseEvents& out, const ButtonTrack& button, const ButtonTick& tick) noexcept {
    const bool is_still = is_near(button.x, tick.sample->x) && is_near(button.y, tick.sample->y);
    const bool is_placed = is_still || !tick.needs_still;
    const bool is_quick = tick.now - button.at < kClickTime;
    if (is_quick && is_placed && tick.can_click) out.add(tick.names.click);
    out.add(tick.names.up);
}

// Một nút qua một nhịp; giữ qua hai nhịp mà con trỏ dời thì sinh kéo.
void step_button(MouseEvents& out, ButtonTrack& button, const ButtonTick& tick) noexcept {
    const bool was_down = button.was_down;
    button.was_down = tick.is_down;
    if (tick.is_down && !was_down) press(out, button, tick);
    if (!tick.is_down && was_down) release(out, button, tick);
    if (tick.is_down && was_down && tick.is_moved) out.add(tick.names.drag);
}

} // namespace

MouseEvents MouseTicker::tick(const MouseSample& sample, Clock::time_point now, bool is_camera_dragging) noexcept {
    MouseEvents out;
    ButtonTick left;
    left.sample = &sample;
    left.now = now;
    left.is_moved = sample.dx != 0 || sample.dy != 0;
    ButtonTick middle = left;
    ButtonTick right = left;
    left.is_down = sample.is_left_down;
    middle.names = kMiddleNames;
    middle.is_down = sample.is_middle_down;
    middle.needs_still = false;
    right.names = kRightNames;
    right.is_down = sample.is_right_down;
    right.can_click = !is_camera_dragging;
    const bool is_repeat = sample.is_left_down && left_.was_down && now - left_.at > kRepeatDown;
    if (left.is_moved) out.add(MouseEvent::kMove);
    if (is_repeat) out.add(MouseEvent::kLeftRepeat);
    step_button(out, left_, left);
    step_button(out, middle_, middle);
    step_button(out, right_, right);
    if (sample.is_wheel_up) out.add(MouseEvent::kWheelUp);
    if (sample.is_wheel_down) out.add(MouseEvent::kWheelDown);
    return out;
}

// CScene::EnterScene (0x1406c0d7b) và CGamePro_Main::Init (0x14064812e): số của System.cfg chỉ
// được nhận khi nằm trong [-90, 90] và đúng thứ tự; không thì giữ số của dòng 1.
Pilot::Pilot(PilotRules rules) noexcept
    : rules_(rules), pitch_high_(kRowPitchHigh), pitch_low_(kRowPitchLow), moving_pitch_(kRowMovingPitch) {
    const float low = rules.pitch_min_degrees;
    const float high = rules.pitch_max_degrees;
    const float moving = rules.moving_pitch_degrees;
    const bool is_span_valid = is_angle(low) && is_angle(high) && high >= low;
    if (!is_span_valid) return;
    pitch_high_ = flipped_radians(low);
    pitch_low_ = flipped_radians(high);
    const bool is_moving_valid = moving >= low && high >= moving;
    if (is_moving_valid) moving_pitch_ = flipped_radians(moving);
}

void Pilot::enter(float zoom) noexcept {
    zoom_target_ = zoom;
    is_auto_run_ = false;
}

void Pilot::leave() noexcept {
    is_right_pending_ = false;
    is_dragging_ = false;
    is_tilting_ = false;
    is_auto_run_ = false;
    left_target_.reset();
    waiting_.reset();
}

void Pilot::cancel_left() noexcept {
    ticker_.drop_left();
    is_auto_run_ = false;
    waiting_.reset();
}

// ProcessInput_Mouse (0x14064c960) rồi đoạn camera của Tick.
PilotStep Pilot::frame(FollowCamera& camera, const Ground& ground, const PilotFrame& frame) noexcept {
    const Turn turn{.camera = &camera, .ground = &ground, .frame = &frame};
    accepted_.reset();
    const MouseEvents events = ticker_.tick(frame.mouse, frame.now, is_dragging_);
    const bool has_click = events.has(MouseEvent::kLeftClick) || events.has(MouseEvent::kRightClick);
    // MouseCommand_Set: nhịp có bấm thì giữ lệnh của nhịp trước.
    if (!has_click && frame.is_over_ui) left_target_.reset();
    if (!has_click && !frame.is_over_ui) left_target_ = frame.under_cursor;
    for (std::size_t index = 0; index < kMouseEventKinds; ++index) {
        offer(turn, events, static_cast<MouseEvent>(index));
    }
    if (!frame.mouse.is_right_down) is_dragging_ = false;
    if (is_auto_run_ && frame.under_cursor) move_to(*frame.under_cursor, frame.now);
    const std::optional<GroundPoint> held_back = waiting_;
    if (held_back) move_to(*held_back, frame.now);
    automate(turn);
    return PilotStep{.move_to = accepted_};
}

// Sự kiện giao diện đã nhận thì màn chơi bỏ qua; đang giữ chuột cho camera thì giao diện không
// thấy sự kiện nào (ICS_GAME).
void Pilot::offer(const Turn& turn, MouseEvents events, MouseEvent event) noexcept {
    if (!events.has(event)) return;
    const bool is_ui_kind = (kUiEvents & bit_of(event)) != 0U;
    const bool is_taken = turn.frame->is_over_ui && !holds_cursor() && is_ui_kind;
    if (is_taken) return;
    handle(turn, event);
}

void Pilot::handle(const Turn& turn, MouseEvent event) noexcept {
    switch (event) {
    case MouseEvent::kRightDown: press_right(turn); break;
    case MouseEvent::kMiddleDown: is_tilting_ = true; break;
    case MouseEvent::kRightDrag: drag_right(turn); break;
    case MouseEvent::kMiddleDrag: drag_middle(turn); break;
    case MouseEvent::kLeftRepeat: is_auto_run_ = true; break;
    case MouseEvent::kLeftDown: is_auto_run_ = false; break;
    case MouseEvent::kLeftUp: click_move(turn.frame->now); break;
    case MouseEvent::kMiddleUp: release_camera(is_tilting_); break;
    case MouseEvent::kRightUp: release_camera(is_dragging_); break;
    case MouseEvent::kWheelUp: wheel(turn, ZoomWay::kCloser); break;
    case MouseEvent::kWheelDown: wheel(turn, ZoomWay::kFarther); break;
    case MouseEvent::kMove:
    case MouseEvent::kLeftDrag:
    case MouseEvent::kLeftClick:
    case MouseEvent::kMiddleClick:
    case MouseEvent::kRightClick: break;
    }
}

// EVENT_MOUSE_RBDOWN (0x14064d06a): ghi chỗ nhấn, chưa xoay.
void Pilot::press_right(const Turn& turn) noexcept {
    is_right_pending_ = true;
    is_dragging_ = false;
    right_down_x_ = turn.frame->mouse.x;
}

// EVENT_MOUSE_RDRAG_MOVE (0x14064d0d9). Chỉ độ lệch ngang mở khoá việc kéo; người chơi tự kéo thì
// lệnh ResetCamera đang chạy dừng lại.
void Pilot::drag_right(const Turn& turn) noexcept {
    const MouseSample& mouse = turn.frame->mouse;
    const bool is_past = std::abs(mouse.x - right_down_x_) > kDragStart;
    if (is_right_pending_ && is_past) is_dragging_ = true;
    if (is_right_pending_ && is_past) is_right_pending_ = false;
    if (!is_dragging_) return;
    restore_ = Restore::kUser;
    const float turned = static_cast<float>(-mouse.dx) / kDragDivisor;
    turn.camera->add_direction(*turn.ground, turned);
    const float tilted = turn.camera->pitch() - (static_cast<float>(mouse.dy) / kDragDivisor);
    const float pitch = clamp_pitch(tilted);
    turn.camera->set_pitch(*turn.ground, pitch);
    reset_sign_ = 0;
}

// Sự kiện kéo nút giữa (0x14064d2a5), chỉ có ở bản 2026.
void Pilot::drag_middle(const Turn& turn) noexcept {
    if (!is_tilting_) return;
    const auto rows = static_cast<float>(-turn.frame->mouse.dy);
    const float tilted = turn.camera->pitch() + (rows * kTiltDegrees * kFloatPi / 180.0F);
    const float pitch = clamp_pitch(tilted);
    turn.camera->set_pitch(*turn.ground, pitch);
}

// EVENT_MOUSE_RBUP (0x14064d48f) và nhả nút giữa (0x14064d442): thôi giữ chuột, và zoom tiến lại
// về đích ở các nhịp sau.
void Pilot::release_camera(bool& is_held) noexcept {
    is_held = false;
    is_easing_ = true;
}

// Lăn chuột (0x14064d50e, 0x14064d6bb): mượt thì chỉ dời đích; không thì hai bước 0,05.
void Pilot::wheel(const Turn& turn, ZoomWay way) noexcept {
    if (!rules_.is_smooth) {
        turn.camera->zoom_step(*turn.ground, way, kZoomMultiple);
        return;
    }
    const float nearer = std::max(zoom_target_ - rules_.wheel_step, 0.0F);
    const float farther = std::min(zoom_target_ + rules_.wheel_step, 1.0F);
    zoom_target_ = way == ZoomWay::kCloser ? nearer : farther;
    is_easing_ = true;
}

// MouseCommand_Active với lệnh đi (0x14007c6cb).
void Pilot::click_move(Clock::time_point now) noexcept {
    if (!left_target_) return;
    if (!(now > clicked_at_ + kClickGap)) return;
    clicked_at_ = now;
    move_to(*left_target_, now);
}

// Player_MoveTo tới Enter_Move (0x140616a00): đang tự chạy mà lệnh trước chưa quá 500 ms thì lệnh
// chờ, mỗi nhịp thử lại; lệnh mới thay lệnh đang chờ.
void Pilot::move_to(GroundPoint target, Clock::time_point now) noexcept {
    const bool is_held_back = is_auto_run_ && moved_at_ + kRunGap > now;
    if (is_held_back) {
        waiting_ = target;
        return;
    }
    waiting_.reset();
    accepted_ = target;
    moved_at_ = now;
}

// Đoạn camera của CGamePro_Main::Tick (0x14064b39f): đang quay về thì chỉ quay về.
void Pilot::automate(const Turn& turn) noexcept {
    if (reset_sign_ != 0) {
        spin_back(turn);
        return;
    }
    if (!rules_.is_smooth) return;
    if (is_easing_) ease_zoom(turn);
    if (rules_.restores_view) restore_view(turn);
}

void Pilot::spin_back(const Turn& turn) noexcept {
    const float turned = turn.frame->seconds * static_cast<float>(reset_sign_);
    turn.camera->add_direction(*turn.ground, turned);
    const float direction = turn.camera->direction();
    const bool is_past = reset_sign_ < 0 ? kHome > direction : direction > kHome;
    if (!is_past) return;
    turn.camera->set_direction(*turn.ground, kHome);
    reset_sign_ = 0;
}

// Zoom tiến một bước về đích rồi đặt lại pitch (0x14064b46e). Khác gốc: bước 0,01 của một nhịp
// nhân với số nhịp của bản gốc trong thời gian khung này.
void Pilot::ease_zoom(const Turn& turn) noexcept {
    const float level = turn.camera->zoom(*turn.ground);
    const float pitch = turn.camera->pitch();
    const float step = rules_.ease_step * (turn.frame->seconds * rules_.tick_rate);
    const bool is_above = level > zoom_target_ + step;
    const bool is_below = !is_above && zoom_target_ - step > level;
    float next = zoom_target_;
    if (is_above) next = std::max(level - step, 0.0F);
    if (is_below) next = std::min(level + step, 1.0F);
    if (!is_above && !is_below) is_easing_ = false;
    turn.camera->set_zoom(*turn.ground, next);
    turn.camera->set_pitch(*turn.ground, pitch);
}

// Camera_RestoreView (0x14064b53b): nhân vật bắt đầu đi thì pitch tiến về Camera_Pitch_Moving theo
// Camera_MoveSpeed_Auto độ mỗi giây; người chơi tự kéo thì chờ tới lần dừng bước kế tiếp.
void Pilot::restore_view(const Turn& turn) noexcept {
    note_walk(turn.frame->is_player_moving);
    if (restore_ != Restore::kRunning) return;
    const float pitch = turn.camera->pitch();
    const float degrees = rules_.auto_speed * turn.frame->seconds;
    const auto step = static_cast<float>(static_cast<double>(degrees) * kDegree);
    const bool is_falling = pitch > moving_pitch_;
    const bool is_rising = moving_pitch_ > pitch;
    const float moved = is_falling ? pitch - step : pitch + step;
    const bool is_past = is_falling ? moving_pitch_ > moved : moved > moving_pitch_;
    const bool is_arrived = is_past || (!is_falling && !is_rising);
    if (is_arrived) restore_ = Restore::kIdle;
    const float next = is_arrived ? moving_pitch_ : moved;
    turn.camera->set_pitch(*turn.ground, next);
}

void Pilot::note_walk(bool is_moving) noexcept {
    if (is_moving && restore_ == Restore::kIdle) restore_ = Restore::kRunning;
    if (!is_moving && restore_ == Restore::kUser) restore_ = Restore::kIdle;
}

float Pilot::clamp_pitch(float pitch) const noexcept {
    if (pitch > pitch_high_) return pitch_high_;
    if (pitch_low_ > pitch) return pitch_low_;
    return pitch;
}

// Lua_ResetCamera (0x140239dc8).
void Pilot::reset_camera(FollowCamera& camera, const Ground& ground) noexcept {
    const float direction = camera.direction();
    const float turns = std::trunc(direction / kFullTurn);
    float wrapped = direction - (turns * kFullTurn);
    if (0.0F > direction) wrapped += kFullTurn;
    camera.set_direction(ground, wrapped);
    reset_sign_ = kHome > wrapped ? 1 : -1;
}

void key_zoom(FollowCamera& camera, const Ground& ground, ZoomWay way) noexcept {
    camera.zoom_step(ground, way, kZoomMultiple);
}

void key_turn(FollowCamera& camera, const Ground& ground, int presses) noexcept {
    camera.add_direction(ground, static_cast<float>(presses) * kKeyTurn);
}

} // namespace game::control
