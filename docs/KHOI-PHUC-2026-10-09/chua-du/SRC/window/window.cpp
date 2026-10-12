// Cửa sổ Win32: lớp cửa sổ đăng ký một lần, mỗi HWND trỏ về WindowState của nó qua GWLP_USERDATA.
// Phủ màn hình là cửa sổ không khung đặt đúng vùng màn hình (không đổi độ phân giải), như gốc.
// Cỡ và vị trí vùng vẽ lấy từ tham số của WM_SIZE, WM_MOVE như gốc dặn: hỏi lại hệ thống ngay trong
// lúc xử lý hai thông điệp đó có thể ra chữ nhật cũ.
// Khác gốc: kéo hoặc đổi cỡ thì Windows giữ vòng thông điệp riêng. WM_TIMER gọi nhịp vẽ đã đặt.
// WM_QUIT trong vòng này bị giữ và gửi lại khi vòng kết thúc, vì vòng đó nuốt WM_QUIT. Huỷ Window
// giữa một thông điệp thì HWND và trạng thái chỉ được xoá khi window_proc ngoài cùng đã trả về.
// Nguồn: Forge2 src/window/window.cpp@d7fcd76. Khác gốc ở đây là khác Forge2: enumerator mang tiền
// tố k; macro của windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32
// include trực tiếp; tên lớp cửa sổ theo dự án này; khởi tạo aggregate ghi tên thành viên; vòng
// lặp có ngoặc; lệnh return kèm lời gọi hàm void tách làm hai.
#include "window/window.hpp"

#include "core/check.hpp"
#include "core/error.hpp"
#include "core/log.hpp"
#include "core/text.hpp"
#include "core/thread_slot.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "window/cursor.hpp"
#include "window/monitor.hpp"
#include "window/system.hpp"
#include "window/types.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <exception>
#include <iterator>
#include <limits>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <basetsd.h>
#include <dwmapi.h>
#include <errhandlingapi.h>
#include <libloaderapi.h>
#include <shellapi.h>
#include <windef.h>
#include <windowsx.h>
#include <wingdi.h>
#include <winnt.h>
#include <winreg.h>
#include <winuser.h>

namespace game::window {

namespace detail {

struct WindowState {
    HWND handle = nullptr;
    std::string title;
    Mode mode = Mode::kWindowed;
    // Chế độ không phủ màn hình gần nhất: nơi toggle_fullscreen quay về.
    Mode windowed_mode = Mode::kWindowed;
    bool is_resizable = true;
    bool is_visible = true;
    bool is_maximized = false;
    bool is_minimized = false;
    bool is_focused = false;
    bool is_resizing = false;
    bool is_modal_timer_armed = false;
    ModalTick modal_tick;
    std::chrono::milliseconds modal_period{};
    bool is_close_requested = false;
    bool quits_on_close = true;
    bool quits_after_modal = false;
    bool is_in_tick = false;
    // Chuỗi cửa sổ chờ huỷ.
    std::unique_ptr<WindowState> destroy_next;
    bool is_cursor_visible = true;
    bool is_cursor_captured = false;
    // Danh sách cửa sổ đang giam chuột. ClipCursor là trạng thái của cả phiên: nhả một cửa sổ
    // không được xoá vùng giam của cửa sổ còn lại.
    WindowState* clip_next = nullptr;
    // Cửa sổ đang phóng to lúc chuyển sang Fullscreen: rời Fullscreen thì phóng to lại.
    bool restores_maximized = false;
    Rect client{};
    // Vùng vẽ ở cỡ thường (không phủ màn hình, không phóng to, không thu nhỏ), và khung ứng với nó.
    Rect restore_client{};
    Rect frame{};
    Rect monitor{};
    Dpi dpi{};
    Cursor cursor;
    POINT cursor_before_capture{};
    // Hai bộ đệm sự kiện đổi vai ở mỗi lần poll_events: không cấp phát lại mỗi khung hình.
    std::vector<Event> pending;
    std::vector<Event> delivered;
    std::vector<std::string> dropped;
    MessageHook hook;
};

} // namespace detail

namespace {

using detail::WindowState;

constexpr const wchar_t* kClassName = L"ThienLongWindow";
// Cỡ nhỏ nhất người dùng kéo được, để cửa sổ không sụp thành một vạch.
constexpr LONG kMinTrackSize = 128;
// Id riêng, tránh đụng timer của module khác trên cùng HWND.
constexpr UINT_PTR kModalTimerId = 0x544C01;
// DWMWA_USE_IMMERSIVE_DARK_MODE: SDK cũ hơn 10.0.22000 chưa khai tên này.
constexpr DWORD kDarkModeAttribute = 20;

[[nodiscard]] Rect to_rect(const RECT& rect) noexcept {
    return {.left = rect.left, .top = rect.top, .right = rect.right, .bottom = rect.bottom};
}

[[nodiscard]] RECT to_native(const Rect& rect) noexcept {
    return {.left = rect.left, .top = rect.top, .right = rect.right, .bottom = rect.bottom};
}

[[nodiscard]] HCURSOR native(const Cursor& cursor) noexcept {
    return static_cast<HCURSOR>(cursor.native_handle());
}

[[nodiscard]] DWORD style_of(const WindowState& state) noexcept {
    DWORD style = WS_OVERLAPPEDWINDOW;
    if (state.mode == Mode::kBorderless) style = WS_POPUP;
    // DefWindowProc chỉ mở vòng đổi cỡ khi có WS_THICKFRAME. on_hit_test trả HTLEFT không đủ.
    // on_calc_size trả 0 nên khung dày không vẽ ra và không cộng vào vùng vẽ.
    if (state.mode == Mode::kBorderless && state.is_resizable) style |= WS_THICKFRAME;
    if (state.mode == Mode::kFullscreen) style = WS_POPUP | WS_SYSMENU | WS_CLIPCHILDREN;
    // Gốc dùng XOR ở đây: với cửa sổ không khung phép đó BẬT khung dày thay vì tắt.
    const bool is_fixed = state.mode == Mode::kWindowed && !state.is_resizable;
    if (is_fixed) style &= ~static_cast<DWORD>(WS_THICKFRAME | WS_MAXIMIZEBOX);
    if (state.is_visible) style |= WS_VISIBLE;
    return style;
}

// Chữ nhật cả cửa sổ (khung, thanh tiêu đề) ứng với vùng vẽ client ở DPI đang dùng.
[[nodiscard]] Rect frame_for(const Rect& client, DWORD style, Dpi dpi) noexcept {
    // Không khung có WS_THICKFRAME: vùng vẽ bằng khung. Cộng viền ở đây làm set_mode(Borderless)
    // phình client so với lúc còn cửa sổ thường.
    const bool is_client_window = (style & WS_POPUP) != 0 && (style & WS_CAPTION) == 0 && (style & WS_THICKFRAME) != 0;
    if (is_client_window) return client;
    RECT rect = to_native(client);
    AdjustWindowRectExForDpi(&rect, style, FALSE, 0, dpi.x);
    return to_rect(rect);
}

[[nodiscard]] Rect monitor_rect_of(HWND handle) noexcept {
    MONITORINFO info{};
    info.cbSize = sizeof(info);
    auto* const monitor = MonitorFromWindow(handle, MONITOR_DEFAULTTONEAREST);
    if (GetMonitorInfoW(monitor, &info) == FALSE) return {};
    return to_rect(info.rcMonitor);
}

// Vùng vẽ trong toạ độ desktop.
[[nodiscard]] Rect client_rect_of(HWND handle) noexcept {
    RECT rect{};
    POINT origin{};
    GetClientRect(handle, &rect);
    ClientToScreen(handle, &origin);
    const LONG right = origin.x + rect.right;
    const LONG bottom = origin.y + rect.bottom;
    return {.left = origin.x, .top = origin.y, .right = right, .bottom = bottom};
}

[[nodiscard]] Rect centered(const Rect& area, Size size) noexcept {
    const auto slack_x = static_cast<std::int32_t>(area.width()) - static_cast<std::int32_t>(size.width);
    const auto slack_y = static_cast<std::int32_t>(area.height()) - static_cast<std::int32_t>(size.height);
    const Point origin{.x = area.left + (slack_x / 2), .y = area.top + (slack_y / 2)};
    return Rect::from(origin, size);
}

// Kéo mép cửa sổ sinh hàng loạt Resized, Moved: chỉ giữ cái cuối của mỗi chuỗi liền nhau.
void push(WindowState& state, const Event& event) {
    const bool is_stream = event.kind == EventKind::kResized || event.kind == EventKind::kMoved;
    const bool is_repeat = !state.pending.empty() && state.pending.back().kind == event.kind;
    if (is_stream && is_repeat) state.pending.pop_back();
    state.pending.push_back(event);
}

void apply_cursor(const WindowState& state) noexcept {
    const bool is_shown = state.is_cursor_visible && !state.is_cursor_captured;
    SetCursor(is_shown ? native(state.cursor) : nullptr);
}

⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
}

// Đặt lại vùng giam sau khi cửa sổ dời, đổi cỡ, được hay mất focus. Vùng giam là vùng vẽ trong
// toạ độ desktop. Gốc cộng vị trí cửa sổ hai lần nên vùng giam lệch đúng bằng toạ độ cửa sổ.
void update_clip(const WindowState&) noexcept {
    apply_clip_owner();
}

void begin_capture(WindowState& state) noexcept {
    state.is_cursor_captured = true;
    GetCursorPos(&state.cursor_before_capture);
    link_clip(state);
    update_clip(state);
    apply_cursor(state);
}

// Nhả chuột. Cửa sổ khác còn giam thì nhường capture cho nó và không kéo con trỏ ra khỏi vùng ấy.
void end_capture(WindowState& state) noexcept {
    state.is_cursor_captured = false;
    const POINT restore = state.cursor_before_capture;
    unlink_clip(state);
    if (clip_owner() == nullptr) SetCursorPos(restore.x, restore.y);
    apply_cursor(state);
}

// Ghi nhớ vùng vẽ và khung khi cửa sổ đang ở cỡ thường.
void remember_normal(WindowState& state) noexcept {
    const bool is_normal = !state.is_maximized && !state.is_minimized;
    if (state.mode == Mode::kFullscreen || !is_normal) return;
    state.restore_client = state.client;
    state.frame = frame_for(state.client, style_of(state), state.dpi);
}

void place(const WindowState& state, const Rect& area) noexcept {
    const UINT flags = SWP_FRAMECHANGED | SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOOWNERZORDER;
    const auto width = static_cast<int>(area.width());
    const auto height = static_cast<int>(area.height());
    SetWindowPos(state.handle, nullptr, area.left, area.top, width, height, flags);
}

// Đặt kiểu khung và chữ nhật theo state.mode: phủ vùng màn hình, hoặc trả về vùng vẽ cỡ thường.
void apply_mode(WindowState& state) noexcept {
    const DWORD style = style_of(state);
    const bool is_fullscreen = state.mode == Mode::kFullscreen;
    SetWindowLongPtrW(state.handle, GWL_STYLE, static_cast<LONG_PTR>(style));
    const Rect normal = frame_for(state.restore_client, style, state.dpi);
    place(state, is_fullscreen ? monitor_rect_of(state.handle) : normal);
    const bool is_remaximized = !is_fullscreen && state.restores_maximized && state.is_visible;
    if (is_remaximized) ShowWindow(state.handle, SW_MAXIMIZE);
    state.restores_maximized = state.restores_maximized && is_fullscreen;
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    icons.client = static_cast<HICON>(LoadImageW(instance, MAKEINTRESOURCEW(kClientIcon), IMAGE_ICON, client_px,
        client_px, LR_SHARED));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast)
    icons.title = static_cast<HICON>(LoadImageW(instance, MAKEINTRESOURCEW(kTitleIcon), IMAGE_ICON, title_px, title_px,
        LR_SHARED));
    return icons;
}

void apply_brand(HWND handle, const BrandIcons& icons) noexcept {
    if (icons.client != nullptr) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast, performance-no-int-to-ptr)
        SendMessageW(handle, WM_SETICON, ICON_BIG, reinterpret_cast<LPARAM>(icons.client));
    }
    if (icons.title != nullptr) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast, performance-no-int-to-ptr)
        SendMessageW(handle, WM_SETICON, ICON_SMALL, reinterpret_cast<LPARAM>(icons.title));
    }
}

// Đăng ký lớp cửa sổ ở lần gọi đầu; 0 khi hệ thống từ chối. Nền đen để vùng chưa vẽ không loé trắng
// khi đổi cỡ (gốc tô tay trong WM_ERASEBKGND bằng một chổi tạo mới mỗi lần và không bao giờ xoá).
[[nodiscard]] ATOM window_class() noexcept {
    static const ATOM kAtom = [] {
        const BrandIcons icons = brand_icons();
        WNDCLASSEXW description{};
        description.cbSize = sizeof(description);
        description.lpfnWndProc = window_proc;
        description.hInstance = GetModuleHandleW(nullptr);
        description.hIcon = icons.client != nullptr ? icons.client : LoadIconW(nullptr, IDI_APPLICATION);
        description.hIconSm = icons.title;
        description.hbrBackground = static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH));
        description.lpszClassName = kClassName;
        return RegisterClassExW(&description);
    }();
    return kAtom;
}

// Vùng vẽ ban đầu theo cấu hình: cỡ yêu cầu hoặc cỡ nên dùng, ở vị trí yêu cầu hoặc giữa màn hình.
[[nodiscard]] Rect initial_client(const WindowConfig& config, const Monitor& monitor) noexcept {
    const Size size = config.client_size.empty() ? recommended_size(monitor) : config.client_size;
    if (!config.position) return centered(monitor.rect, size);
    const Point origin{.x = monitor.rect.left + config.position->x, .y = monitor.rect.top + config.position->y};
    return Rect::from(origin, size);
}

// Khung của cửa sổ lúc tạo, đẩy vào trong vùng làm việc khi thanh tiêu đề hay mép trái lọt ra ngoài
// màn hình (vùng vẽ đặt sát góc màn hình thì khung nằm ngoài, không kéo được).
[[nodiscard]] Rect initial_frame(const WindowState& state, const Monitor& monitor) noexcept {
    const Rect frame = frame_for(state.client, style_of(state), state.dpi);
    const std::int32_t shift_x = std::max(monitor.work_rect.left - frame.left, 0);
    const std::int32_t shift_y = std::max(monitor.work_rect.top - frame.top, 0);
    const Rect shifted{.left = frame.left + shift_x,
        .top = frame.top + shift_y,
        .right = frame.right + shift_x,
        .bottom = frame.bottom + shift_y};
    return shifted;
}

[[nodiscard]] std::unique_ptr<WindowState> make_state(const WindowConfig& config, const Monitor& monitor) {
    auto state = std::make_unique<WindowState>();
    state->title = config.title;
    state->is_resizable = config.is_resizable;
    state->quits_on_close = config.quits_on_close;
    // Tạo ở dạng ẩn, cỡ thường; hiện và đổi chế độ sau khi đã có HWND.
    state->is_visible = false;
    state->dpi = monitor.dpi;
    state->monitor = monitor.rect;
    state->client = initial_client(config, monitor);
    state->restore_client = state->client;
    return state;
}

} // namespace

bool defer_quit_if_modal() noexcept {
    detail::WindowState* const modal = modal_window();
    if (modal == nullptr || modal->handle == nullptr) return false;
    modal->quits_after_modal = true;
    PostMessageW(modal->handle, WM_CANCELMODE, 0, 0);
    return true;
}

bool finish_modal_if_idle() noexcept {
    if (proc_depth() != 0) return false;
    detail::WindowState* const modal = modal_window();
    if (modal == nullptr) return false;
    const bool quits = end_size_move(*modal);
    if (!quits) return false;
    MSG waiting{};
    PeekMessageW(&waiting, nullptr, WM_QUIT, WM_QUIT, PM_REMOVE);
    return true;
}

Window::Window(std::unique_ptr<detail::WindowState> state) noexcept : state_(std::move(state)) {}

Window::Window(Window&&) noexcept = default;

Window& Window::operator=(Window&& other) noexcept {
    std::swap(state_, other.state_);
    return *this;
}

Window::~Window() {
    destroy_state(std::move(state_));
}

core::Result<Window> Window::create(const WindowConfig& config) {
    enable_dpi_awareness();
    if (window_class() == 0) {
        return core::fail(core::ErrorCode::kInternal, "không đăng ký được lớp cửa sổ");
    }
    const std::vector<Monitor> list = monitors();
    if (list.empty()) return core::fail(core::ErrorCode::kNotFound, "không có màn hình nào");
    const Monitor& monitor = list.at(config.monitor < list.size() ? config.monitor : 0);
    std::unique_ptr<detail::WindowState> state = make_state(config, monitor);
    const Rect frame = initial_frame(*state, monitor);
    const std::wstring title = core::widen(config.title);
    const auto width = static_cast<int>(frame.width());
    const auto height = static_cast<int>(frame.height());
    // Tách style và instance: gộp vào lời gọi thì phép gán xuống dòng rồi lời gọi xuống tiếp,
    // thành ba bậc thụt.
    const DWORD style = style_of(*state);
    auto* const instance = GetModuleHandleW(nullptr);
    auto* const handle = CreateWindowExW(WS_EX_APPWINDOW, kClassName, title.c_str(), style, frame.left, frame.top,
        width, height, nullptr, nullptr, instance, state.get());
    if (handle == nullptr) {
        return core::fail_system(GetLastError(), "không tạo được cửa sổ", config.title);
    }
    Window window(std::move(state));
    window.state_->dpi = {.x = GetDpiForWindow(handle), .y = GetDpiForWindow(handle)};
    window.state_->client = client_rect_of(handle);
    remember_normal(*window.state_);
    apply_theme(handle);
    apply_brand(handle, brand_icons());
    DragAcceptFiles(handle, config.accepts_files ? TRUE : FALSE);
    if (config.is_visible) window.show();
    if (config.is_visible && config.is_maximized) window.maximize();
    window.set_mode(config.mode);
    return window;
}

void* Window::native_handle() const noexcept {
    return state_->handle;
}

Rect Window::client_rect() const noexcept {
    return state_->client;
}

Size Window::client_size() const noexcept {
    return state_->client.size();
}

Rect Window::frame_rect() const noexcept {
    return state_->frame;
}

Rect Window::monitor_rect() const noexcept {
    return state_->monitor;
}

Dpi Window::dpi() const noexcept {
    return state_->dpi;
}

void Window::set_frame_rect(const Rect& rect) {
    if (state_->mode == Mode::kFullscreen) return;
    place(*state_, rect);
}

void Window::set_frame_size(Size size) {
    RECT current{};
    GetWindowRect(state_->handle, &current);
    const Point origin{.x = current.left, .y = current.top};
    set_frame_rect(Rect::from(origin, size));
}

void Window::set_client_rect(const Rect& rect) {
    set_frame_rect(frame_for(rect, style_of(*state_), state_->dpi));
}

void Window::set_client_size(Size size) {
    set_client_rect(Rect::from(state_->client.origin(), size));
}

void Window::center() {
    set_client_rect(centered(state_->monitor, state_->client.size()));
}

Mode Window::mode() const noexcept {
    return state_->mode;
}

void Window::set_mode(Mode mode) {
    detail::WindowState& state = *state_;
    if (state.mode == mode) return;
    const bool is_entering = mode == Mode::kFullscreen;
    if (is_entering) state.restores_maximized = state.is_maximized;
    if (!is_entering) state.windowed_mode = mode;
    state.mode = mode;
    apply_mode(state);
}

void Window::toggle_fullscreen() {
    const bool is_fullscreen = state_->mode == Mode::kFullscreen;
    set_mode(is_fullscreen ? state_->windowed_mode : Mode::kFullscreen);
}

void Window::show() {
    state_->is_visible = true;
    ShowWindow(state_->handle, SW_SHOW);
}

void Window::hide() {
    state_->is_visible = false;
    ShowWindow(state_->handle, SW_HIDE);
}

void Window::maximize() {
    ShowWindow(state_->handle, SW_MAXIMIZE);
}

void Window::minimize() {
    ShowWindow(state_->handle, SW_MINIMIZE);
}

void Window::restore() {
    ShowWindow(state_->handle, SW_RESTORE);
}

bool Window::is_visible() const noexcept {
    return state_->is_visible;
}

bool Window::is_maximized() const noexcept {
    return state_->is_maximized;
}

bool Window::is_minimized() const noexcept {
    return state_->is_minimized;
}

bool Window::is_focused() const noexcept {
    return state_->is_focused;
}

bool Window::is_resizing() const noexcept {
    return state_->is_resizing;
}

bool Window::is_close_requested() const noexcept {
    return state_->is_close_requested;
}

const std::string& Window::title() const noexcept {
    return state_->title;
}

void Window::set_title(std::string_view title) {
    const std::wstring wide = core::widen(title);
    state_->title = title;
    SetWindowTextW(state_->handle, wide.c_str());
}

void Window::set_cursor(const Cursor& cursor) {
    state_->cursor = cursor;
    if (is_cursor_inside()) apply_cursor(*state_);
}

void Window::set_cursor_visible(bool is_visible) {
    state_->is_cursor_visible = is_visible;
    if (is_cursor_inside()) apply_cursor(*state_);
}

bool Window::is_cursor_visible() const noexcept {
    return state_->is_cursor_visible;
}

void Window::capture_cursor(bool is_captured) {
    detail::WindowState& state = *state_;
    if (state.is_cursor_captured == is_captured) return;
    if (is_captured) {
        begin_capture(state);
        return;
    }
    end_capture(state);
}

bool Window::is_cursor_captured() const noexcept {
    return state_->is_cursor_captured;
}

bool Window::is_cursor_inside() const noexcept {
    POINT position{};
    if (GetCursorPos(&position) == FALSE) return false;
    const bool is_over = WindowFromPoint(position) == state_->handle;
    const Point point{.x = position.x, .y = position.y};
    return is_over && state_->client.contains(point);
}

void Window::move_cursor(Point client_position) {
    POINT position{.x = client_position.x, .y = client_position.y};
    ClientToScreen(state_->handle, &position);
    SetCursorPos(position.x, position.y);
}

void Window::set_modal_tick(ModalTick tick, std::chrono::milliseconds period) {
    using Rep = std::chrono::milliseconds::rep;
    const Rep period_ms = period.count();
    constexpr Rep kLimit = static_cast<Rep>(std::numeric_limits<UINT>::max());
    core::check(period_ms > 0 && period_ms <= kLimit, "chu kỳ nhịp kéo không hợp lệ");
    core::check(!state_->is_in_tick, "không đổi nhịp đang chạy");
    state_->modal_period = period;
    state_->modal_tick = std::move(tick);
    if (!state_->is_resizing) return;
    disarm_modal_timer(*state_);
    arm_modal_timer(*state_);
}

void Window::cancel_size_move() noexcept {
    if (!state_->is_resizing || state_->handle == nullptr) return;
    PostMessageW(state_->handle, WM_CANCELMODE, 0, 0);
}

std::span<const Event> Window::poll_events() {
    state_->delivered.clear();
    std::swap(state_->pending, state_->delivered);
    return state_->delivered;
}

std::vector<std::string> Window::take_dropped_files() {
    return std::exchange(state_->dropped, {});
}

void Window::set_message_hook(MessageHook hook) {
    state_->hook = std::move(hook);
}

std::size_t monitor_index(const Window& window, std::span<const Monitor> list) {
    MONITORINFOEXW info{};
    info.cbSize = sizeof(info);
    auto* const handle = static_cast<HWND>(window.native_handle());
    auto* const monitor = MonitorFromWindow(handle, MONITOR_DEFAULTTOPRIMARY);
    if (GetMonitorInfoW(monitor, &info) == FALSE) return 0;
    const std::string device = core::narrow(std::data(info.szDevice));
    const auto found = std::ranges::find(list, device, &Monitor::device);
    if (found == list.end()) return 0;
    return static_cast<std::size_t>(std::distance(list.begin(), found));
}

} // namespace game::window
