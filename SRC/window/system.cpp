// Vòng thông điệp và các dịch vụ cấp tiến trình của tầng cửa sổ; xem system.hpp.
// Nguồn: Forge2 src/window/system.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; macro của
// windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32 include trực tiếp; câu
// if trong vòng của pump_messages thành phép chọn; lệnh return kèm lời gọi hàm void tách làm hai.
#include "window/system.hpp"

#include "core/log.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "window/types.hpp"
#include "window/window.hpp"

#include <atomic>
#include <string>
#include <string_view>

#include <windef.h>
#include <winuser.h>

namespace game::window {

namespace {

// Công tắc của cả tiến trình: bộ chạy tự động tắt một lần ở đầu main.
[[nodiscard]] std::atomic<bool>& popups_enabled() noexcept {
    static std::atomic<bool> flag{true};
    return flag;
}

} // namespace

Flow pump_messages() {
    Flow flow = Flow::kRunning;
    MSG message{};
    while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE) != FALSE) {
        // Khác gốc: gốc viết if (message.message == WM_QUIT) flow = Flow::Quit.
        flow = message.message == WM_QUIT ? Flow::kQuit : flow;
        TranslateMessage(&message);
        DispatchMessageW(&message);
    }
    if (finish_modal_if_idle()) flow = Flow::kQuit;
    return flow;
}

void request_quit() noexcept {
    if (defer_quit_if_modal()) return;
    PostQuitMessage(0);
}

void enable_dpi_awareness() noexcept {
    // Thất bại khi manifest của exe đã khai sẵn hoặc đã gọi trước đó: cả hai đều là trạng thái mong
    // muốn, nên bỏ qua kết quả.
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
}

Point cursor_position() noexcept {
    POINT position{};
    GetCursorPos(&position);
    return {.x = position.x, .y = position.y};
}

void move_cursor_to(Point desktop_position) noexcept {
    SetCursorPos(desktop_position.x, desktop_position.y);
}

void error_popup(std::string_view title, std::string_view message, const Window* parent) {
    if (!popups_enabled().load()) {
        core::error("{}: {}", title, message);
        return;
    }
    const std::wstring wide_title = core::widen(title);
    const std::wstring wide_message = core::widen(message);
    auto* const owner = static_cast<HWND>(parent != nullptr ? parent->native_handle() : nullptr);
    MessageBoxW(owner, wide_message.c_str(), wide_title.c_str(), MB_OK | MB_ICONERROR);
}

void set_popups_enabled(bool is_enabled) noexcept {
    popups_enabled().store(is_enabled);
}

ThermalStatus thermal_status() noexcept {
    return ThermalStatus::kNotSupported;
}

// Không default: thêm trạng thái mà quên ở đây là C4062.
std::string_view name(ThermalStatus status) noexcept {
    switch (status) {
    case ThermalStatus::kNotSupported: return "NotSupported";
    case ThermalStatus::kError: return "Error";
    case ThermalStatus::kNone: return "None";
    case ThermalStatus::kLight: return "Light";
    case ThermalStatus::kModerate: return "Moderate";
    case ThermalStatus::kSevere: return "Severe";
    case ThermalStatus::kCritical: return "Critical";
    case ThermalStatus::kEmergency: return "Emergency";
    case ThermalStatus::kShutdown: return "Shutdown";
    }
    return "Invalid";
}

} // namespace game::window
