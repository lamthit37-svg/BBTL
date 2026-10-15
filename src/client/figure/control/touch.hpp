#pragma once
// Cử chỉ chạm (Android) thành các thao tác chuột mà client đã hiểu, để máy cảm ứng chơi được như
// PC:
// - một ngón là chuột trái: chạm là nhấn, nhấc là nhả (chạm để đi); giữ yên quá kHoldTime là tự
//   chạy của Pilot, và kéo sau đó là di con trỏ (lái);
// - kéo một ngón xa chỗ chạm quá kDragSlop trước kHoldTime: huỷ thao tác trái (Cancel) và thành
//   kéo phải (xoay camera) từ chỗ chạm, nhấc là nhả phải;
// - ngón thứ hai huỷ thao tác trái đang dở và chuyển sang chế độ camera tới khi nhấc hết ngón:
//   mở ra hay chụm lại mỗi kPinchStep điểm là một nấc lăn (mở ra là lại gần), tâm hai ngón dời
//   là kéo phải (xoay); ngón thứ ba trở đi bị bỏ;
// - cần gạt ảo: ngón chạm vùng cần khi chưa có cần thì thành cần, đế nổi ở chỗ chạm (lùi khỏi
//   mép), mỗi lần dời là một Stick, nhấc là StickEnd. Ngón của cần không tính vào cử chỉ, nên tay
//   kia vẫn chạm để đi hay kéo xoay;
// - chạm hai ngón (hai ngón cùng đặt rồi nhấc ngón đầu trong kPairTapTime, không ngón nào dời quá
//   kDragSlop) là một cú nhảy: vỏ đọc take_pair_taps rồi gọi Display::act(PlayAct::kJump).
// Toạ độ vào tính bằng điểm (point) của cửa sổ; InputEvent ra theo quy ước của input.hpp. Logic
// thuần, không biết hệ cửa sổ, để test được trên PC.
// Nguồn: TLBB Dev src/render/touch.hpp và touch.cpp@e0d89a6. Khác gốc: namespace game::control;
// enumerator theo kCamelCase; các hàm phát nhiều sự kiện dùng emit thay cho push_back lồng
// at_event; chạm hai ngón để nhảy (bản gốc không có nút nhảy cho cảm ứng) nên up nhận thêm now.

#include "control/input.hpp"

#include <chrono>
#include <cstdint>
#include <optional>
#include <utility>
#include <vector>

namespace game::control {

// Độ đổi khoảng cách hai ngón cho một nấc lăn, tính bằng điểm.
inline constexpr float kPinchStep = 48.0F;

// Thời điểm của một sự kiện chạm, từ một mốc bất kỳ; chỉ hiệu số có nghĩa.
using TouchTime = std::chrono::nanoseconds;
// Giữ yên lâu hơn chừng này là tự chạy (MOUSE_REPEAT_DOWN của client gốc, như MouseTicker).
inline constexpr TouchTime kHoldTime = std::chrono::milliseconds{1000};
// Dời xa chỗ chạm hơn chừng này điểm trước kHoldTime là kéo xoay camera, không phải rung tay.
inline constexpr float kDragSlop = 16.0F;
// Hai ngón đặt rồi nhấc trong chừng này là chạm hai ngón (nhảy); lâu hơn là giữ camera.
inline constexpr TouchTime kPairTapTime = std::chrono::milliseconds{300};

// Vùng cần gạt: góc trái dưới, x dưới kStickZoneWidth và y trên kStickZoneTop, theo tỉ lệ khung.
inline constexpr float kStickZoneWidth = 0.4F;
inline constexpr float kStickZoneTop = 0.4F;
// Bán kính đế cần, dp: ngón cách tâm đế chừng này là gạt hết cỡ.
inline constexpr float kStickRadius = 60.0F;

struct TouchPoint {
    float x = 0.0F;
    float y = 0.0F;
};

class TouchGestures {
public:
    // Cỡ cửa sổ tính bằng điểm, để chuẩn hoá vị trí con trỏ về [0, 1]; points_per_dp đổi bán kính
    // cần từ dp sang điểm.
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): chữ ký của TLBB Dev (HP-07)
    void resize(float width, float height, float points_per_dp) noexcept;

    // Mỗi hàm thêm các InputEvent sinh ra vào out (không xoá out).
    void down(std::uint64_t finger, TouchPoint where, TouchTime now, std::vector<InputEvent>& out);
    void move(std::uint64_t finger, TouchPoint where, TouchTime now, std::vector<InputEvent>& out);
    void up(std::uint64_t finger, TouchPoint where, TouchTime now, std::vector<InputEvent>& out);
    // Số lần chạm hai ngón từ lần gọi trước; lấy rồi thì về 0.
    [[nodiscard]] std::uint32_t take_pair_taps() noexcept { return std::exchange(pair_taps_, 0U); }

private:
    // Pointer: một ngón như chuột trái; Turn: một ngón kéo xoay như chuột phải; Camera: hai ngón.
    enum class Mode : std::uint8_t { kIdle, kPointer, kTurn, kCamera };

    struct Finger {
        std::uint64_t id = 0;
        TouchPoint at;
    };

    // Ngón đang giữ cần và tâm đế, điểm.
    struct Stick {
        std::uint64_t id = 0;
        TouchPoint base;
    };

    [[nodiscard]] bool is_stick_zone(TouchPoint where) const noexcept;
    [[nodiscard]] bool is_stick_finger(std::uint64_t finger) const noexcept;
    void begin_stick(std::uint64_t finger, TouchPoint where, std::vector<InputEvent>& out);
    void push_stick(TouchPoint where, std::vector<InputEvent>& out) const;
    void end_stick(std::vector<InputEvent>& out);
    [[nodiscard]] InputEvent at_event(InputKind kind, MouseButton button, TouchPoint where) const;
    void emit(std::vector<InputEvent>& out, InputKind kind, MouseButton button, TouchPoint where) const;
    void push_drag(MouseButton button, TouchPoint from, TouchPoint where, std::vector<InputEvent>& out) const;
    void begin_turn(TouchPoint where, std::vector<InputEvent>& out);
    void end_turn(TouchPoint where, std::vector<InputEvent>& out);
    void begin_camera(std::vector<InputEvent>& out);
    void follow_camera(std::vector<InputEvent>& out);
    void end_camera(std::vector<InputEvent>& out);
    [[nodiscard]] Finger* find(std::uint64_t id) noexcept;

    Mode mode_ = Mode::kIdle;
    // Tối đa hai, theo thứ tự chạm.
    std::vector<Finger> fingers_;
    std::optional<Stick> stick_;
    float width_ = 1.0F;
    float height_ = 1.0F;
    // Bán kính đế cần, điểm.
    float radius_ = kStickRadius;
    bool right_held_ = false;
    // Chỗ chạm và lúc chạm của ngón đầu.
    TouchPoint start_;
    TouchTime pressed_at_{};
    // Tâm hai ngón ở lần phát sự kiện trước.
    TouchPoint centre_;
    // Độ đổi khoảng cách hai ngón chưa thành nấc, và khoảng cách hai ngón ở lần trước.
    float pinch_ = 0.0F;
    float spread_ = 0.0F;
    // Cặp ngón đang mở có thể còn là một cú chạm hai ngón: lúc ngón thứ hai chạm, chỗ hai ngón lúc ấy, đã dời quá
    // kDragSlop chưa.
    bool is_pair_open_ = false;
    bool has_pair_moved_ = false;
    TouchTime pair_at_{};
    TouchPoint pair_first_;
    TouchPoint pair_second_;
    std::uint32_t pair_taps_ = 0;
};

} // namespace game::control
