// Việc của cả luồng hay cả tiến trình ở tầng cửa sổ: vòng thông điệp, yêu cầu thoát, hộp báo lỗi,
// vị trí con trỏ trên desktop, trạng thái nhiệt — handleMessages, requestShutdown,
// errorMessagePopup, setMousePositionAbsolute, getThermalStatus của _Ref. Khác gốc:
// - pump_messages trả Flow có tên thay bool; gốc coi cả WM_CLOSE trong hàng đợi là thoát;
// - hộp báo lỗi nhận UTF-8 và tắt được cho chạy tự động (gốc phải dịch lại với AUTOMATED_TESTING);
//   gốc còn truy cập handle->window dù đã đánh dấu tham số là không dùng: handle null là crash.
// Nguồn: Forge2 src/window/system.hpp@d7fcd76. Khác gốc (so với Forge2): enumerator mang tiền tố k.
#pragma once

#include "window/types.hpp"

#include <cstdint>
#include <string_view>

namespace game::window {

class Window;

enum class Flow : std::uint8_t {
    kRunning,
    // Đã nhận yêu cầu thoát (request_quit, hoặc cửa sổ có quits_on_close bị đóng).
    kQuit,
};

// Xử lý hết thông điệp đang chờ của luồng gọi, không chờ thêm. Gọi mỗi khung hình, trên luồng đã
// tạo các cửa sổ.
[[nodiscard]] Flow pump_messages();

// Đặt yêu cầu thoát vào hàng thông điệp của luồng gọi.
void request_quit() noexcept;

// Ghi thoát và dừng vòng kéo.
[[nodiscard]] bool defer_quit_if_modal() noexcept;

// Tắt nhịp kéo sót. true nếu có thoát.
[[nodiscard]] bool finish_modal_if_idle() noexcept;

// Khai với Windows rằng tiến trình tự lo DPI từng màn hình. Window::create tự gọi; gọi tay khi cần
// số đo màn hình đúng trước khi có cửa sổ. Gọi nhiều lần vô hại.
void enable_dpi_awareness() noexcept;

// Con trỏ chuột trong toạ độ desktop.
[[nodiscard]] Point cursor_position() noexcept;
void move_cursor_to(Point desktop_position) noexcept;

// Hộp thoại báo lỗi, chặn tới khi người dùng bấm OK. Khi đã tắt bằng set_popups_enabled(false) thì
// ghi log mức error và trả về ngay.
void error_popup(std::string_view title, std::string_view message, const Window* parent = nullptr);
void set_popups_enabled(bool is_enabled) noexcept;

enum class ThermalStatus : std::int8_t {
    // Nền này không cho hỏi trạng thái nhiệt (Windows).
    kNotSupported = -2,
    kError = -1,
    kNone = 0,
    kLight = 1,
    kModerate = 2,
    kSevere = 3,
    kCritical = 4,
    kEmergency = 5,
    kShutdown = 6,
};

[[nodiscard]] ThermalStatus thermal_status() noexcept;
[[nodiscard]] std::string_view name(ThermalStatus status) noexcept;

} // namespace game::window
