// Cửa sổ của ứng dụng — WindowDesc và nhóm hàm openWindow..captureCursor của IOperatingSystem.h,
// WindowsWindow.cpp trong _Ref. Header không kéo windows.h. Khác gốc:
// - Window là đối tượng RAII và có thể có nhiều cửa sổ; gốc nhận WindowDesc* nhưng mọi trạng thái
//   nằm ở biến toàn cục gWindow, chỉ một cửa sổ chạy đúng;
// - thay đổi của cửa sổ vào hàng sự kiện của chính nó (poll_events); gốc ghi thẳng vào
//   IApp::mSettings và gọi requestReload từ trong hàm xử lý thông điệp;
// - set_message_hook được gọi thật cho mọi thông điệp; setCustomMessageProcessor của gốc lưu con
//   trỏ rồi không nơi nào gọi;
// - nhận biết DPI từng màn hình (Per-Monitor-V2) và báo DpiChanged; gốc không khai nên Windows
//   phóng mờ cả cửa sổ trên màn hình tỉ lệ khác 100%;
// - tiêu đề và đường dẫn là UTF-8; con trỏ ẩn hiện theo từng cửa sổ, không qua bộ đếm ShowCursor
//   toàn cục.
// Lỗi của gốc đã sửa: docs/modules/window.md của Forge2.
// Nguồn: Forge2 src/window/window.hpp@d7fcd76. Khác gốc (so với Forge2): enumerator mang tiền tố k;
// tiêu đề mặc định là tên dự án này.
#pragma once

#include "core/error.hpp"
#include "core/function.hpp"
#include "window/cursor.hpp"
#include "window/types.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#if defined(__ANDROID__)
struct ANativeWindow;
#endif

namespace game::window {

struct Monitor;

namespace detail {

// Trạng thái của một cửa sổ, định nghĩa ở window.cpp để header không cần windows.h.
struct WindowState;

} // namespace detail

enum class Mode : std::uint8_t {
    // Có khung và thanh tiêu đề.
    kWindowed,
    // Không khung, giữ cỡ và vị trí của cửa sổ thường; vẫn kéo mép để đổi cỡ được.
    kBorderless,
    // Không khung, phủ trọn màn hình đang chứa cửa sổ. Không đổi độ phân giải của màn hình.
    kFullscreen,
};

struct WindowConfig {
    std::string title = "Thiên Long Bát Bộ";
    // Cỡ vùng vẽ; {0, 0} thì lấy recommended_size của màn hình.
    Size client_size{};
    // Góc trên trái của vùng vẽ tính từ góc trên trái màn hình; không có thì canh giữa màn hình.
    std::optional<Point> position;
    // Chỉ số trong monitors(); ngoài danh sách thì lấy màn hình chính.
    std::size_t monitor = 0;
    Mode mode = Mode::kWindowed;
    bool is_resizable = true;
    bool is_visible = true;
    // Chỉ có tác dụng khi is_visible.
    bool is_maximized = false;
    // Người dùng đóng cửa sổ thì kết thúc vòng thông điệp (pump_messages trả Flow::kQuit), như gốc.
    // Tắt đi khi ứng dụng có nhiều cửa sổ hoặc muốn hỏi lại trước khi thoát.
    bool quits_on_close = true;
    // Nhận tệp kéo thả từ Explorer (sự kiện FilesDropped).
    bool accepts_files = false;
    // Cửa sổ không bao giờ giành tiêu điểm của người đang dùng máy: tạo với WS_EX_NOACTIVATE, hiện
    // và khôi phục bằng SW_SHOWNOACTIVATE. Dành cho lần chạy tự động (client --script).
    bool is_inactive = false;
};

enum class EventKind : std::uint8_t {
    // Cỡ vùng vẽ đổi; Event::size là cỡ mới. Kéo mép cửa sổ sinh nhiều sự kiện, gộp còn một trong
    // mỗi lượt poll_events.
    kResized,
    // Vùng vẽ dời; Event::position là góc trên trái mới trong desktop.
    kMoved,
    kFocusGained,
    kFocusLost,
    kMinimized,
    // Trở lại từ thu nhỏ.
    kRestored,
    // Người dùng bấm đóng (nút X, Alt+F4). Cửa sổ chưa bị huỷ.
    kCloseRequested,
    // Cửa sổ sang màn hình có tỉ lệ khác, hoặc người dùng đổi tỉ lệ; Event::dpi là DPI mới.
    kDpiChanged,
    // Độ phân giải hay cách xếp màn hình đổi: danh sách monitors() cũ hết hạn.
    kDisplayChanged,
    // Có tệp được thả vào: lấy bằng take_dropped_files.
    kFilesDropped,
};

struct Event {
    EventKind kind = EventKind::kResized;
    Size size{};
    Point position{};
    Dpi dpi{};
};

// Thông điệp Win32 thô, cho module cần đọc phím, chuột, WM_INPUT.
struct NativeMessage {
    void* window = nullptr;
    std::uint32_t id = 0;
    std::uintptr_t wparam = 0;
    std::intptr_t lparam = 0;
};

// Trả giá trị thì đó là kết quả của thông điệp và xử lý mặc định bị bỏ qua; trả rỗng thì cửa sổ xử
// lý tiếp như thường. Móc chạy sau khi cửa sổ đã cập nhật trạng thái của chính nó, trên luồng tạo
// cửa sổ. Ngoại lệ ném ra bị chặn và ghi log.
using MessageHook = std::function<std::optional<std::intptr_t>(const NativeMessage&)>;

// Nhịp một khung hình trên luồng cửa sổ.
using ModalTick = core::MoveOnlyFunction<void()>;

class Window {
public:
    // Phải gọi trên luồng sẽ chạy pump_messages cho cửa sổ này.
    [[nodiscard]] static core::Result<Window> create(const WindowConfig& config);

#if defined(__ANDROID__)
    // Activity đã có bề mặt. acquire lúc nhận, release lúc huỷ. Không mở cửa sổ mới.
    [[nodiscard]] static core::Result<Window> adopt(::ANativeWindow* native);
#endif

    ~Window();
    Window(const Window&) = delete;
    Window& operator=(const Window&) = delete;
    Window(Window&& other) noexcept;
    Window& operator=(Window&& other) noexcept;

    // HWND, cho swapchain và module input.
    [[nodiscard]] void* native_handle() const noexcept;

    // Vùng vẽ trong toạ độ desktop.
    [[nodiscard]] Rect client_rect() const noexcept;
    [[nodiscard]] Size client_size() const noexcept;
    // Cả cửa sổ gồm khung và thanh tiêu đề, ở lần gần nhất không phủ màn hình.
    [[nodiscard]] Rect frame_rect() const noexcept;
    // Vùng của màn hình đang chứa cửa sổ.
    [[nodiscard]] Rect monitor_rect() const noexcept;
    [[nodiscard]] Dpi dpi() const noexcept;

    // Bốn hàm đặt cỡ và vị trí không làm gì khi đang Fullscreen.
    void set_frame_rect(const Rect& rect);
    void set_frame_size(Size size);
    void set_client_rect(const Rect& rect);
    void set_client_size(Size size);
    // Đưa vùng vẽ vào giữa màn hình đang chứa cửa sổ.
    void center();

    [[nodiscard]] Mode mode() const noexcept;
    void set_mode(Mode mode);
    // Fullscreen về chế độ trước đó (Windowed hoặc Borderless), và ngược lại.
    void toggle_fullscreen();

    void show();
    void hide();
    void maximize();
    void minimize();
    // Về cỡ thường từ phóng to hoặc thu nhỏ.
    void restore();

    [[nodiscard]] bool is_visible() const noexcept;
    [[nodiscard]] bool is_maximized() const noexcept;
    [[nodiscard]] bool is_minimized() const noexcept;
    [[nodiscard]] bool is_focused() const noexcept;
    // Người dùng đang kéo hoặc đổi cỡ cửa sổ: nên hoãn việc dựng lại swapchain tới khi xong.
    [[nodiscard]] bool is_resizing() const noexcept;
    // Nhịp vẽ trong vòng kéo hoặc đổi cỡ. Chu kỳ phải dương.
    void set_modal_tick(ModalTick tick, std::chrono::milliseconds period);
    // Kết thúc vòng kéo đang chạy. Không làm gì nếu cửa sổ không đang kéo.
    void cancel_size_move() noexcept;
    [[nodiscard]] bool is_close_requested() const noexcept;

    [[nodiscard]] const std::string& title() const noexcept;
    void set_title(std::string_view title);

    // Hình con trỏ khi chuột ở trong vùng vẽ.
    void set_cursor(const Cursor& cursor);
    void set_cursor_visible(bool is_visible);
    [[nodiscard]] bool is_cursor_visible() const noexcept;
    // Giam chuột trong vùng vẽ và ẩn con trỏ; nhả ra thì con trỏ về chỗ cũ. Mất focus thì tạm nhả,
    // có focus lại thì giam tiếp.
    void capture_cursor(bool is_captured);
    [[nodiscard]] bool is_cursor_captured() const noexcept;
    [[nodiscard]] bool is_cursor_inside() const noexcept;
    // Đặt con trỏ theo toạ độ trong vùng vẽ.
    void move_cursor(Point client_position);

    // Sự kiện tích từ lần gọi trước. Vùng nhớ trả về còn hiệu lực tới lần gọi kế.
    [[nodiscard]] std::span<const Event> poll_events();
    // Đường dẫn UTF-8 của các tệp được thả từ lần gọi trước.
    [[nodiscard]] std::vector<std::string> take_dropped_files();
    void set_message_hook(MessageHook hook);

private:
    explicit Window(std::unique_ptr<detail::WindowState> state) noexcept;

    // Địa chỉ của trạng thái không đổi khi Window bị dời: hàm xử lý thông điệp giữ con trỏ tới nó.
    std::unique_ptr<detail::WindowState> state_;
};

// Chỉ số trong list của màn hình đang chứa cửa sổ; 0 khi không khớp mục nào.
[[nodiscard]] std::size_t monitor_index(const Window& window, std::span<const Monitor> list);

#if defined(__ANDROID__)
// Cỡ bề mặt đã adopt gần nhất; {0, 0} khi chưa có. monitor đọc được mà không cần header NDK.
[[nodiscard]] Size adopted_size() noexcept;
#endif

} // namespace game::window
