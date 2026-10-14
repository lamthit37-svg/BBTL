// Bản không có chuỗi đồ hoạ (cấu hình GCC MinGW): không tạo thiết bị, không luồng vẽ. Mọi hàm của
// Display trở thành no-op; vòng lặp cửa sổ tự xoay theo nhịp nghỉ một khung hình.
#include "client/display/display.hpp"
#include "client/world/world.hpp"

#include "control/cursor_rules.hpp"
#include "control/input.hpp"
#include "core/error.hpp"
#include "ui/panel/online.hpp"

#include <chrono>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace game::client {
namespace {

constexpr std::chrono::milliseconds kFramePause{16};

} // namespace

struct Display::State {
    std::shared_ptr<const world::ShownScene> scene;
    std::chrono::steady_clock::time_point started = std::chrono::steady_clock::now();
};

Display::Display(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Display::Display(Display&&) noexcept = default;
Display& Display::operator=(Display&&) noexcept = default;
Display::~Display() = default;

struct DisplayPreload::Work {};

DisplayPreload::DisplayPreload(const std::filesystem::path& /*data_root*/,
    const std::optional<std::string>& /*backend*/) {}
DisplayPreload::DisplayPreload(DisplayPreload&&) noexcept = default;
DisplayPreload& DisplayPreload::operator=(DisplayPreload&&) noexcept = default;
DisplayPreload::~DisplayPreload() = default;

core::Result<Display> Display::create(const DisplayDesc& /*desc*/) {
    return Display(std::make_unique<State>());
}

void Display::notify_resized(PixelSize /*size*/) noexcept {}

void Display::steer(const Steering& /*input*/) noexcept {}

void Display::input(std::span<const control::InputEvent> /*events*/) {}

void Display::show(const std::shared_ptr<const world::ShownScene>& scene) {
    state_->scene = scene;
}

void Display::play(const std::shared_ptr<const world::ShownScene>& scene, std::optional<EntryPoint> /*entry*/) {
    state_->scene = scene;
}

// Các hàm dưới không đọc GPU ở bản này. Chúng giữ dạng thành viên vì hợp đồng chung với bản có
// chuỗi đồ hoạ (display.hpp).
// NOLINTBEGIN(readability-convert-member-functions-to-static)
core::Status Display::finish() {
    std::this_thread::sleep_for(kFramePause);
    return core::ok();
}

std::uint64_t Display::validation_errors() const noexcept {
    return 0;
}

std::uint32_t Display::draw_count() const noexcept {
    return 0;
}

// Luồng vẽ vô hình luôn "còn quay": vòng cửa sổ chỉ dừng theo người dùng hoặc --frames.
bool Display::is_spinning() const noexcept {
    return true;
}

// Luồng vẽ vô hình coi như quay một lượt mỗi kFramePause, để --frames vẫn dừng được.
std::uint64_t Display::turns() const noexcept {
    const auto lived = std::chrono::steady_clock::now() - state_->started;
    return static_cast<std::uint64_t>(lived / kFramePause);
}

void Display::set_refresh(double /*rate_hz*/) noexcept {}

// NOLINTNEXTLINE(modernize-use-string-view)
std::string Display::description() const {
    return "không vẽ: bản dựng này không có chuỗi đồ hoạ";
}

std::optional<control::CursorKind> Display::cursor_choice() const noexcept {
    return control::CursorKind::kNormal;
}

// Bản này không có giao diện nên không nút nào nhờ việc gì.
std::vector<Request> Display::take_requests() {
    return {};
}

std::vector<ui::panel::OnlineAsk> Display::take_online_asks() {
    return {};
}

void Display::post_online(const ui::panel::OnlineReply& /*reply*/) {}

KeptRole Display::kept_role() const {
    return {};
}
// NOLINTEND(readability-convert-member-functions-to-static)

} // namespace game::client
