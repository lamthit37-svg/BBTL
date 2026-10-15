// +---------------------------------------------------------------+
// | THIENLONG                                                     |
// | Tệp: Test/Window/window_tests.cpp                             |
// | - Test của window: hình học số nguyên, cỡ cửa sổ nên dùng     |
// |   theo danh sách chế độ của màn hình, và một cửa sổ ẩn thật:  |
// |   tạo đúng cỡ vùng vẽ, đổi cỡ sinh sự kiện, tiêu đề UTF-8,    |
// |   yêu cầu đóng không tự huỷ cửa sổ, huỷ Window thì HWND mất,  |
// |   yêu cầu thoát kết thúc vòng thông điệp. Cần phiên làm việc  |
// |   có desktop; cửa sổ ẩn nên không hiện gì lên màn hình. Các   |
// |   ca vào vòng kéo thật của Windows nằm riêng ở                |
// |   window_modal_tests.cpp vì chúng đụng tới con trỏ chuột của  |
// |   người đang dùng máy. Chỉ dựng trên Windows.                 |
// | Dev : HiepHoon   Tele : @Hoon9xx                              |
// +---------------------------------------------------------------+

#include "core/check.hpp"
#include "core/error.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "test.hpp"
#include "window/monitor.hpp"
#include "window/system.hpp"
#include "window/types.hpp"
#include "window/window.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <vector>

#include <windef.h>
#include <winnt.h>
#include <winuser.h>

namespace game::test {
namespace {

using window::Rect;
using window::Size;

constexpr Rect kBox = Rect::from({.x = 10, .y = 20}, {.width = 30, .height = 40});
static_assert(kBox == Rect{.left = 10, .top = 20, .right = 40, .bottom = 60});
static_assert(kBox.size() == Size{.width = 30, .height = 40});
static_assert(kBox.contains({.x = 10, .y = 20}), "góc trên trái thuộc chữ nhật");
static_assert(!kBox.contains({.x = 40, .y = 20}), "right nằm ngoài chữ nhật");
static_assert(Rect{.left = 5, .top = 5, .right = 1, .bottom = 9}.width() == 0, "lộn ngược cho 0");
static_assert(Size{.width = 0, .height = 7}.empty());

// Màn hình dựng tay với danh sách chế độ đã sắp theo cao rồi rộng; chế độ đang dùng là mục cuối.
[[nodiscard]] window::Monitor monitor_with(std::span<const Size> modes) {
    window::Monitor monitor;
    monitor.modes.assign(modes.begin(), modes.end());
    monitor.current_mode = modes.size() - 1;
    return monitor;
}

void recommended_size_prefers_three_quarters_of_screen(Context& context) {
    constexpr std::array kModes{Size{.width = 640, .height = 480}, Size{.width = 800, .height = 600},
        Size{.width = 1280, .height = 720}, Size{.width = 1024, .height = 768}, Size{.width = 1920, .height = 1080}};
    const window::Monitor wide = monitor_with(kModes);
    const Size chosen = window::recommended_size(wide);
    context.expect(chosen == Size{.width = 1280, .height = 720}, "chế độ lớn nhất dưới 3/4 màn hình");
    context.expect(window::supports(wide, chosen), "chế độ được chọn nằm trong danh sách");
    context.expect(!window::supports(wide, {.width = 1, .height = 1}), "chế độ lạ không hỗ trợ");
}

void recommended_size_relaxes_when_nothing_fits(Context& context) {
    constexpr std::array kTwo{Size{.width = 800, .height = 600}, Size{.width = 1920, .height = 1080}};
    const Size relaxed = window::recommended_size(monitor_with(kTwo));
    context.expect(relaxed == Size{.width = 800, .height = 600}, "bỏ sàn khi không chế độ nào vừa");
    constexpr std::array kOne{Size{.width = 1920, .height = 1080}};
    const Size only = window::recommended_size(monitor_with(kOne));
    context.expect(only == Size{.width = 1920, .height = 1080}, "một chế độ thì lấy chính nó");
}

constexpr std::array<std::uint32_t, 6> kOffered{60, 0, 1, 200, 120, 200};

constexpr bool ranks_highest_first() {
    std::array<std::uint32_t, 4> out{};
    const std::size_t count = window::rank_refresh({.current = 60, .ceiling = 0}, kOffered, out);
    return count == 2 && out[0] == 200 && out[1] == 120;
}

constexpr bool never_lowers() {
    constexpr std::array<std::uint32_t, 4> offered{50, 60, 144, 60};
    std::array<std::uint32_t, 4> out{};
    return window::rank_refresh({.current = 144, .ceiling = 0}, offered, out) == 0;
}

constexpr bool keeps_highest_when_the_list_is_short() {
    constexpr std::array<std::uint32_t, 3> offered{100, 200, 150};
    std::array<std::uint32_t, 1> out{};
    const std::size_t count = window::rank_refresh({.current = 60, .ceiling = 0}, offered, out);
    return count == 1 && out[0] == 200;
}

constexpr bool treats_driver_default_as_absent() {
    constexpr std::array<std::uint32_t, 3> offered{0, 1, 165};
    std::array<std::uint32_t, 2> out{};
    const std::size_t count = window::rank_refresh({.current = 0, .ceiling = 0}, offered, out);
    return count == 1 && out[0] == 165;
}

// Máy yếu vẽ tới 60: không kéo lên 200. Máy vẽ tới 120: lấy 120, bỏ 144 và 200.
constexpr bool respects_machine_ceiling() {
    constexpr std::array<std::uint32_t, 5> offered{60, 75, 120, 144, 200};
    std::array<std::uint32_t, 4> low{};
    if (window::rank_refresh({.current = 60, .ceiling = 60}, offered, low) != 0) return false;
    std::array<std::uint32_t, 4> mid{};
    const std::size_t count = window::rank_refresh({.current = 60, .ceiling = 120}, offered, mid);
    if (count != 2 || mid[0] != 120 || mid[1] != 75) return false;
    constexpr std::array<std::uint32_t, 2> only_fast{144, 200};
    std::array<std::uint32_t, 2> skipped{};
    return window::rank_refresh({.current = 60, .ceiling = 120}, only_fast, skipped) == 0;
}

static_assert(ranks_highest_first());
static_assert(never_lowers());
static_assert(keeps_highest_when_the_list_is_short());
static_assert(treats_driver_default_as_absent());
static_assert(respects_machine_ceiling());

void rank_refresh_orders_higher_rates_only(Context& context) {
    std::array<std::uint32_t, 4> out{};
    const std::size_t count = window::rank_refresh({.current = 60, .ceiling = 0}, kOffered, out);
    context.expect(count == 2 && out[0] == 200 && out[1] == 120, "không trần thì 200 rồi 120");
    context.expect(window::rank_refresh({.current = 200, .ceiling = 0}, kOffered, out) == 0, "không hạ xuống dưới mức đang dùng");
    constexpr std::array<std::uint32_t, 5> offered{60, 75, 120, 144, 200};
    context.expect(window::rank_refresh({.current = 60, .ceiling = 60}, offered, out) == 0, "trần 60 không nâng máy yếu");
    const std::size_t capped = window::rank_refresh({.current = 60, .ceiling = 120}, offered, out);
    context.expect(capped == 2 && out[0] == 120 && out[1] == 75, "trần 120 bỏ 144 và 200");
}

void raise_refresh_rejects_null_window(Context& context) {
    const core::Result<window::RefreshLift> lifted = window::raise_refresh(nullptr, 60);
    context.expect(!lifted.has_value(), "không có cửa sổ thì không đổi màn");
    if (lifted.has_value()) return;
    context.expect(lifted.error().code() == core::ErrorCode::kInvalidArgument, "thiếu cửa sổ là đối số sai");
}

void monitors_list_starts_with_primary(Context& context) {
    const std::vector<window::Monitor> list = window::monitors();
    context.expect(!list.empty(), "phiên có desktop thì có ít nhất một màn hình");
    if (list.empty()) return;
    context.expect(list.front().is_primary, "màn hình chính đứng đầu");
    context.expect(!list.front().rect.size().empty(), "vùng màn hình không rỗng");
    context.expect(!list.front().modes.empty(), "có ít nhất chế độ đang dùng");
}

constexpr Size kSmall{.width = 640, .height = 360};
constexpr Size kLarge{.width = 800, .height = 450};

// Cửa sổ ẩn, không kết thúc vòng thông điệp khi bị đóng: mỗi ca tự kiểm việc đóng.
[[nodiscard]] core::Result<window::Window> hidden_window() {
    window::WindowConfig config;
    config.title = "thử cửa sổ — 測試";
    config.client_size = kSmall;
    config.is_visible = false;
    config.quits_on_close = false;
    return window::Window::create(config);
}

[[nodiscard]] bool has_kind(std::span<const window::Event> events, window::EventKind kind) {
    const auto matches = [kind](const window::Event& event) { return event.kind == kind; };
    return std::ranges::any_of(events, matches);
}

void window_opens_with_requested_client_size(Context& context) {
    const core::Result<window::Window> opened = hidden_window();
    context.expect(opened.has_value(), "tạo được cửa sổ ẩn");
    if (!opened) return;
    context.expect(opened->native_handle() != nullptr, "có HWND");
    context.expect(opened->client_size() == kSmall, "vùng vẽ đúng cỡ yêu cầu");
    context.expect(opened->title() == "thử cửa sổ — 測試", "tiêu đề UTF-8 giữ nguyên");
    context.expect(!opened->is_visible(), "cửa sổ tạo ẩn thì không hiện");
    context.expect(opened->mode() == window::Mode::kWindowed, "chế độ mặc định có khung");
}

void window_reports_resize_as_event(Context& context) {
    core::Result<window::Window> opened = hidden_window();
    context.expect(opened.has_value(), "tạo được cửa sổ ẩn");
    if (!opened) return;
    // Bỏ các sự kiện phát sinh lúc tạo.
    static_cast<void>(opened->poll_events());
    opened->set_client_size(kLarge);
    static_cast<void>(window::pump_messages());
    const std::span<const window::Event> events = opened->poll_events();
    context.expect(has_kind(events, window::EventKind::kResized), "đổi cỡ sinh sự kiện Resized");
    context.expect(opened->client_size() == kLarge, "vùng vẽ theo cỡ mới");
    context.expect(opened->poll_events().empty(), "sự kiện chỉ được giao một lần");
}

void window_close_request_does_not_destroy(Context& context) {
    core::Result<window::Window> opened = hidden_window();
    context.expect(opened.has_value(), "tạo được cửa sổ ẩn");
    if (!opened) return;
    auto* const handle = static_cast<HWND>(opened->native_handle());
    static_cast<void>(opened->poll_events());
    context.expect(PostMessageW(handle, WM_CLOSE, 0, 0) != FALSE, "gửi được WM_CLOSE");
    const window::Flow flow = window::pump_messages();
    context.expect(flow == window::Flow::kRunning, "quits_on_close tắt thì vòng lặp chạy tiếp");
    context.expect(opened->is_close_requested(), "cửa sổ ghi nhận yêu cầu đóng");
    const std::span<const window::Event> events = opened->poll_events();
    context.expect(has_kind(events, window::EventKind::kCloseRequested), "có sự kiện đóng");
    context.expect(IsWindow(handle) != FALSE, "cửa sổ chưa bị huỷ khi mới được yêu cầu đóng");
}

// HWND của một cửa sổ đã bị huỷ cùng đối tượng Window của nó.
[[nodiscard]] HWND handle_of_destroyed_window() {
    const core::Result<window::Window> opened = hidden_window();
    if (!opened) return nullptr;
    return static_cast<HWND>(opened->native_handle());
}

void window_destructor_destroys_native_window(Context& context) {
    auto* const handle = handle_of_destroyed_window();
    context.expect(handle != nullptr, "tạo được cửa sổ ẩn");
    context.expect(IsWindow(handle) == FALSE, "huỷ Window thì HWND cũng bị huỷ");
}

// Không đòi vị trí thì CẢ KHUNG nằm giữa vùng làm việc của màn hình chính, như Game.exe 0x140631940
// (căn giữa trong SPI_GETWORKAREA). Sai số một điểm ảnh do chia nguyên.
void window_opens_centered_in_primary_work_area(Context& context) {
    const core::Result<window::Window> opened = hidden_window();
    context.expect(opened.has_value(), "tạo được cửa sổ ẩn");
    if (!opened) return;
    const std::vector<window::Monitor> list = window::monitors();
    context.expect(!list.empty(), "có màn hình");
    if (list.empty()) return;
    const Rect work = list.front().work_rect;
    RECT frame{};
    context.expect(GetWindowRect(static_cast<HWND>(opened->native_handle()), &frame) != FALSE, "đọc được khung");
    const LONG slack_x = static_cast<LONG>(work.width()) - (frame.right - frame.left);
    const LONG slack_y = static_cast<LONG>(work.height()) - (frame.bottom - frame.top);
    context.expect(slack_x >= 0 && slack_y >= 0, "khung 640x360 vừa vùng làm việc");
    context.expect(frame.left == work.left + slack_x / 2, "khung căn giữa theo chiều ngang");
    context.expect(frame.top == work.top + slack_y / 2, "khung căn giữa theo chiều dọc");
}

constexpr std::array kCases{
    Case{.name = "recommended_size_prefers_three_quarters_of_screen",
        .body = &recommended_size_prefers_three_quarters_of_screen},
    Case{.name = "recommended_size_relaxes_when_nothing_fits", .body = &recommended_size_relaxes_when_nothing_fits},
    Case{.name = "rank_refresh_orders_higher_rates_only", .body = &rank_refresh_orders_higher_rates_only},
    Case{.name = "raise_refresh_rejects_null_window", .body = &raise_refresh_rejects_null_window},
    Case{.name = "monitors_list_starts_with_primary", .body = &monitors_list_starts_with_primary},
    Case{.name = "window_opens_with_requested_client_size", .body = &window_opens_with_requested_client_size},
    Case{.name = "window_reports_resize_as_event", .body = &window_reports_resize_as_event},
    Case{.name = "window_close_request_does_not_destroy", .body = &window_close_request_does_not_destroy},
    Case{.name = "window_destructor_destroys_native_window", .body = &window_destructor_destroys_native_window},
    Case{.name = "window_opens_centered_in_primary_work_area",
        .body = &window_opens_centered_in_primary_work_area},
};

} // namespace
} // namespace game::test

int main() {
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
    game::core::check(game::test::run_all(game::test::kCases) == 0, "window_tests: mọi ca phải qua");
    return 0;
}
