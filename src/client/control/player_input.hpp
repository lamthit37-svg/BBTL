#pragma once
// Chuột của người chơi thành lệnh đi và chỉnh camera, theo Game.exe bản 3.71 của client 2026:
// - MouseTicker là CInputSystem::MouseTick (0x140212ad0): mỗi nhịp so trạng thái ba nút và vị trí
//   con trỏ với nhịp trước rồi sinh sự kiện. Bấm là nhả trong 500 ms và cách chỗ nhấn không quá 4
//   điểm ảnh mỗi trục; giữ trái quá 1000 ms thì mỗi nhịp có một sự kiện giữ lặp; bấm phải không
//   sinh ra khi camera đang được kéo.
// - Pilot là phần chuột và camera của CGamePro_Main: ProcessInput_Mouse (0x14064c960), đoạn camera
//   của Tick (0x14064b39f), Lua ResetCamera (0x140239dc8), cùng hai chốt nhịp ra lệnh đi: 100 ms
//   của CCursorMng::MouseCommand_Active (0x14007c6cb) và 500 ms khi đang tự chạy của
//   CAI_MySelf::Enter_Move (0x140616a00).
//   Kéo phải quá 4 điểm ảnh ngang kể từ chỗ nhấn thì bắt đầu xoay: hướng -dx / 300 radian, pitch
//   -dy / 300 radian kẹp giữa Camera_Pitch_Max và Camera_Pitch_Min; kéo nút giữa đổi pitch 0,25 độ
//   mỗi điểm ảnh. Lăn chuột dời đích zoom 0,1; mỗi nhịp zoom tiến 0,01 về đích. Nhả trái thì đi
//   tới điểm đất dưới con trỏ; giữ trái quá 1000 ms thì chạy theo con trỏ tới lần nhấn trái kế.
// Bảng địa chỉ, hằng và chỗ khác bản 2008 ở docs/CAMERA-2026.md.
// Khác gốc: bản gốc tiến zoom 0,01 mỗi khung ở trần System_MaxFPS_Front = 45 khung mỗi giây; ở
// đây bước nhân theo thời gian của khung để cùng tốc độ ở mọi tần số vẽ. Thời gian là Clock của
// core thay cho mili giây 32 bit. Chưa có vật thể dưới chuột, kỹ năng và lệnh của giao diện nên
// lệnh trái luôn là đi; các nhánh camera bị khoá hướng của cảnh đặc biệt (Game.exe 0x14103dfc0)
// và phim cắt cảnh không có. Không biết cửa sổ: chỗ gọi lấy mẫu chuột mỗi khung.

#include "control/follow_camera.hpp"
#include "control/ground.hpp"
#include "core/clock.hpp"
#include "core/ground_point.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>

namespace game::control {

using core::Clock;
using core::GroundPoint;

// Chuột của một nhịp: vị trí trong vùng vẽ và độ dời từ nhịp trước (điểm ảnh), ba nút, và có lăn
// lên hay xuống kể từ nhịp trước không.
struct MouseSample {
    int x = 0;
    int y = 0;
    int dx = 0;
    int dy = 0;
    bool is_left_down = false;
    bool is_middle_down = false;
    bool is_right_down = false;
    bool is_wheel_up = false;
    bool is_wheel_down = false;
};

// Sự kiện chuột, xếp theo thứ tự MouseTick đẩy vào hàng trong một nhịp; màn chơi xử lý đúng thứ
// tự đó. Mỗi loại có nhiều nhất một lần mỗi nhịp. kMiddleDrag chỉ có ở bản 2026.
enum class MouseEvent : std::uint8_t {
    kMove,
    kLeftDown,
    kMiddleDown,
    kRightDown,
    kLeftClick,
    kLeftUp,
    kMiddleClick,
    kMiddleUp,
    kRightClick,
    kRightUp,
    kLeftDrag,
    kLeftRepeat,
    kMiddleDrag,
    kRightDrag,
    kWheelUp,
    kWheelDown,
};

inline constexpr std::size_t kMouseEventKinds = 16;

// Sự kiện của một nhịp: mỗi loại một bit.
struct MouseEvents {
    std::uint32_t bits = 0;

    void add(MouseEvent event) noexcept { bits |= 1U << static_cast<unsigned>(event); }
    [[nodiscard]] bool has(MouseEvent event) const noexcept {
        return (bits & (1U << static_cast<unsigned>(event))) != 0U;
    }
};

// Một nút qua các nhịp: nhịp trước có giữ không, chỗ và lúc nhấn gần nhất.
struct ButtonTrack {
    bool was_down = false;
    int x = 0;
    int y = 0;
    Clock::time_point at;
};

class MouseTicker {
public:
    // Một nhịp. is_camera_dragging là m_bCameraDraging của màn chơi: đang kéo thì nhả phải không
    // thành bấm phải.
    [[nodiscard]] MouseEvents tick(const MouseSample& sample, Clock::time_point now, bool is_camera_dragging) noexcept;
    // Nút trái bị bỏ giữa chừng (ngón thứ hai chạm xuống, mất focus): coi như chưa từng nhấn, nhịp
    // sau không sinh sự kiện nhả.
    void drop_left() noexcept { left_.was_down = false; }

private:
    ButtonTrack left_;
    ButtonTrack middle_;
    ButtonTrack right_;
};

// Số của Bin/System.cfg và dòng 1 của SpecialSceneCamera mà màn chơi đọc.
struct PilotRules {
    // Camera_Smooth: lăn chuột dời đích rồi zoom tiến dần; tắt thì mỗi nấc nhảy hai bước 0,05.
    bool is_smooth = true;
    // Camera_RestoreView: đang đi thì pitch tự về Camera_Pitch_Moving.
    bool restores_view = false;
    // Camera_Pitch_Min, Camera_Pitch_Max: góc nhìn xuống nhỏ nhất và lớn nhất, độ.
    float pitch_min_degrees = -40.0F;
    float pitch_max_degrees = 60.0F;
    float moving_pitch_degrees = 40.0F;
    // Camera_MoveSpeed_Auto, độ mỗi giây.
    float auto_speed = 30.0F;
    // Cột 6 và 7 của SpecialSceneCamera: bước đích mỗi nấc lăn, bước zoom mỗi nhịp.
    float wheel_step = 0.1F;
    float ease_step = 0.01F;
    // System_MaxFPS_Front: số nhịp mỗi giây của bản gốc.
    float tick_rate = 45.0F;
};

// Một khung của màn chơi.
struct PilotFrame {
    MouseSample mouse;
    Clock::time_point now;
    // Thời gian của khung, giây.
    float seconds = 0.0F;
    // Con trỏ trên cửa sổ giao diện: nhấn, bấm và giữ lặp thuộc về giao diện.
    bool is_over_ui = false;
    bool is_player_moving = false;
    // Điểm đất dưới con trỏ (fvMouseHitPlan); không có khi tia không chạm địa hình.
    std::optional<GroundPoint> under_cursor;
};

struct PilotStep {
    // Lệnh đi được nhận ở khung này.
    std::optional<GroundPoint> move_to;
};

class Pilot {
public:
    explicit Pilot(PilotRules rules) noexcept;

    // Vào cảnh (CGamePro_Main::Init): đích zoom là zoom đã lưu, không còn tự chạy.
    void enter(float zoom) noexcept;
    // Rời cảnh (CGamePro_Main::Release): thôi kéo camera và thôi tự chạy.
    void leave() noexcept;
    // Một khung: sự kiện chuột, rồi phần camera tự động của Tick.
    [[nodiscard]] PilotStep frame(FollowCamera& camera, const Ground& ground, const PilotFrame& frame) noexcept;
    // Lua ResetCamera: gói hướng về [0, 2 pi) rồi quay 1 radian mỗi giây về 3,1415.
    void reset_camera(FollowCamera& camera, const Ground& ground) noexcept;
    // Thao tác trái bị bỏ: không lệnh đi, dừng tự chạy.
    void cancel_left() noexcept;

    [[nodiscard]] bool auto_run() const noexcept { return is_auto_run_; }
    // Đang kéo camera bằng nút phải hay nút giữa: con trỏ ẩn, chuột bị giữ và kéo về chỗ cũ.
    [[nodiscard]] bool holds_cursor() const noexcept { return is_dragging_ || is_tilting_; }
    [[nodiscard]] float zoom_target() const noexcept { return zoom_target_; }

private:
    // m_nCameraRestore (+0x15c): kUser là người chơi vừa tự kéo, chờ dừng bước mới tự chỉnh lại.
    enum class Restore : std::uint8_t { kIdle, kRunning, kUser };

    // Camera, mặt đất và khung đang xử lý: ba thứ mọi bước của một khung đều cần.
    struct Turn {
        FollowCamera* camera = nullptr;
        const Ground* ground = nullptr;
        const PilotFrame* frame = nullptr;
    };

    void offer(const Turn& turn, MouseEvents events, MouseEvent event) noexcept;
    void handle(const Turn& turn, MouseEvent event) noexcept;
    void press_right(const Turn& turn) noexcept;
    void drag_right(const Turn& turn) noexcept;
    void drag_middle(const Turn& turn) noexcept;
    void release_camera(bool& is_held) noexcept;
    void wheel(const Turn& turn, ZoomWay way) noexcept;
    void click_move(Clock::time_point now) noexcept;
    void move_to(GroundPoint target, Clock::time_point now) noexcept;
    void automate(const Turn& turn) noexcept;
    void spin_back(const Turn& turn) noexcept;
    void ease_zoom(const Turn& turn) noexcept;
    void restore_view(const Turn& turn) noexcept;
    void note_walk(bool is_moving) noexcept;
    [[nodiscard]] float clamp_pitch(float pitch) const noexcept;

    PilotRules rules_;
    MouseTicker ticker_;
    // Pitch cao nhất và thấp nhất kéo được, radian (Game.exe 0x140fb2df4 và 0x140fb2df8).
    float pitch_high_ = 0.0F;
    float pitch_low_ = 0.0F;
    float moving_pitch_ = 0.0F;
    float zoom_target_ = 1.0F;
    // Hoành độ chỗ nhấn phải, chờ kéo ngang quá ngưỡng.
    int right_down_x_ = 0;
    bool is_right_pending_ = false;
    bool is_dragging_ = false;
    bool is_tilting_ = false;
    bool is_auto_run_ = false;
    bool is_easing_ = false;
    Restore restore_ = Restore::kIdle;
    // m_nResetCamera: dấu của chiều đang quay về, 0 là không quay.
    int reset_sign_ = 0;
    // Lệnh trái của nhịp gần nhất không có bấm (MouseCommand_Set).
    std::optional<GroundPoint> left_target_;
    // Lệnh đi đang chờ chốt 500 ms của tự chạy, và lệnh nhận ở khung này.
    std::optional<GroundPoint> waiting_;
    std::optional<GroundPoint> accepted_;
    Clock::time_point clicked_at_;
    Clock::time_point moved_at_;
};

// Phím zoom của bản gốc (lệnh phím 0x2d và 0x2e, Game.exe 0x14021b490): hai bước 0,05, không qua
// đích zoom mượt.
void key_zoom(FollowCamera& camera, const Ground& ground, ZoomWay way) noexcept;
// Phím xoay của bản 2008 (0,04 radian mỗi lần nhấn); bản 2026 không còn lời gọi nào.
void key_turn(FollowCamera& camera, const Ground& ground, int presses) noexcept;

} // namespace game::control
