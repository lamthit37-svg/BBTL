// Bản Windows của cửa sổ xem cảnh: một cửa sổ của module window, phần hiển thị của nó
// (client/display.hpp) và vòng thông điệp. Luồng vẽ nằm trong Display, tự vẽ lấy; luồng này chỉ
// đọc sự kiện rồi chuyển cỡ vùng vẽ cho nó, nên kéo hay đổi cỡ cửa sổ không bao giờ đứng chờ GPU.
// Người dùng đóng cửa sổ thì pump_messages trả Quit; phần hiển thị bị huỷ trước cửa sổ: luồng vẽ
// dừng hẳn và GPU rỗi trước khi HWND biến mất.
#include "client/viewer.hpp"

#include "client/display.hpp"
#include "core/error.hpp"
#include "window/system.hpp"
#include "window/types.hpp"
#include "window/window.hpp"

#include <chrono>
#include <cstdint>
#include <optional>
#include <print>
#include <thread>
#include <utility>

namespace game::client {
namespace {

constexpr window::Size kDefaultSize{.width = 1280, .height = 720};
// Nhịp vòng thông điệp khi Windows giữ vòng kéo hoặc đổi cỡ, cỡ một khung hình.
constexpr std::chrono::milliseconds kFramePause{16};
struct LoopStats {
    std::uint32_t frames = 0;
    std::uint32_t resizes = 0;
};

[[nodiscard]] PixelSize pixels(window::Size size) noexcept {
    return {.width = size.width, .height = size.height};
}

// Cỡ vùng vẽ mà phần hiển thị phải theo sau sự kiện này; không có khi sự kiện không đổi cỡ. Thu
// nhỏ và khôi phục không sinh Resized (vùng vẽ ghi nhớ không đổi) nhưng bề mặt thì về cỡ 0 rồi trở
// lại: thiếu hai nhánh ấy phần hiển thị dựng swapchain cỡ 0 và báo lỗi (đã gặp khi thu nhỏ).
[[nodiscard]] std::optional<PixelSize> size_after(
    const window::Window& opened, const window::Event& event) noexcept {
    if (event.kind == window::EventKind::kResized) return pixels(event.size);
    if (event.kind == window::EventKind::kMinimized) return PixelSize{};
    if (event.kind == window::EventKind::kRestored) return pixels(opened.client_size());
    return std::nullopt;
}

// Gom tham số của một lượt đọc sự kiện.
struct Frame {
    window::Window* opened = nullptr;
    Display* display = nullptr;
    LoopStats* stats = nullptr;
};

void note_event(const Frame& frame, const window::Event& event) noexcept {
    if (event.kind == window::EventKind::kResized) ++frame.stats->resizes;
    const std::optional<PixelSize> size = size_after(*frame.opened, event);
    if (size) frame.display->notify_resized(*size);
}

// Một lượt vòng: đọc hết sự kiện rồi chuyển cỡ vùng vẽ cho luồng vẽ; không chạm GPU ở đây.
void step(window::Window& opened, Display& display, LoopStats& stats) {
    const Frame frame{.opened = &opened, .display = &display, .stats = &stats};
    for (const window::Event& event : opened.poll_events()) {
        note_event(frame, event);
    }
    ++stats.frames;
}

[[nodiscard]] bool is_done(const ViewerDesc& desc, const Display& display, const LoopStats& stats) {
    if (!display.is_spinning()) return true;
    return desc.frames.has_value() && stats.frames >= *desc.frames;
}

void finish_if_done(window::Window& opened, const ViewerDesc& desc, const Display& display,
    const LoopStats& stats) {
    if (!is_done(desc, display, stats)) return;
    window::request_quit();
    opened.cancel_size_move();
}

// Mọi thứ của một lần chạy vòng lặp; các hàm dưới cùng nhận một tham chiếu tới nó.
struct Session {
    window::Window* opened = nullptr;
    Display* display = nullptr;
    const ViewerDesc* desc = nullptr;
    LoopStats stats;
};

void one_frame(Session& session) {
    step(*session.opened, *session.display, session.stats);
    finish_if_done(*session.opened, *session.desc, *session.display, session.stats);
}

void pump_until_done(Session& session) {
    window::Window& opened = *session.opened;
    opened.set_modal_tick([&session] { one_frame(session); }, kFramePause);
    while (!is_done(*session.desc, *session.display, session.stats) &&
        window::pump_messages() == window::Flow::kRunning) {
        one_frame(session);
        // Luồng vẽ tự vẽ lấy; luồng này không còn bị present chặn, nên tự nhịp nghỉ một khung
        // hình (trước đây 67 triệu vòng bão hoà một lõi — đã đo bằng drive_window.py).
        std::this_thread::sleep_for(kFramePause);
    }
    // Nhịp modal giữ tham chiếu tới session và phần hiển thị, cả hai chết trước cửa sổ: gỡ nó ra.
    opened.set_modal_tick({}, kFramePause);
}

// Dừng luồng vẽ, in tóm tắt, và đổi kết quả của lần chạy thành mã thoát.
[[nodiscard]] int report(const Session& session) {
    const core::Status finished = session.display->finish();
    const LoopStats& stats = session.stats;
    const window::Size size = session.opened->client_size();
    const std::uint64_t faults = session.display->validation_errors();
    std::println("Cửa sổ đóng sau {} vòng lặp, {} lần đổi cỡ, vùng vẽ cuối {}x{}", stats.frames,
        stats.resizes, size.width, size.height);
    std::println("{} lệnh vẽ của khung cuối, lớp kiểm tra của GPU báo {} lỗi",
        session.display->draw_count(), faults);
    if (!finished) std::println(stderr, "Lỗi khi vẽ: {}", finished.error());
    const bool is_clean = finished.has_value() && faults == 0;
    return is_clean ? 0 : 1;
}

} // namespace

int run_viewer(const ViewerDesc& desc) {
    window::WindowConfig config;
    config.title = desc.title;
    config.client_size = kDefaultSize;
    core::Result<window::Window> opened = window::Window::create(config);
    if (!opened) {
        std::println(stderr, "Lỗi: không mở được cửa sổ: {}", opened.error());
        return 1;
    }
    const window::Size initial = opened->client_size();
    DisplayDesc shown;
    shown.window = opened->native_handle();
    shown.size = {.width = initial.width, .height = initial.height};
    shown.stage = desc.stage;
    shown.ground = desc.ground;
    shown.data_root = desc.data_folder;
    shown.shot_path = desc.shot;
    shown.is_validated = desc.is_validated;
    core::Result<Display> display = Display::create(shown);
    if (!display) {
        std::println(stderr, "Lỗi: không khởi tạo được phần hiển thị: {}", display.error());
        return 1;
    }
    std::println("Hiển thị: {}", display->description());
    Session session;
    session.opened = &*opened;
    session.display = &*display;
    session.desc = &desc;
    pump_until_done(session);
    return report(session);
}

} // namespace game::client
