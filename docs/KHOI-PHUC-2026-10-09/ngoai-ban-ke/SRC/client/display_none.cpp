// Bản không có chuỗi đồ hoạ (cấu hình GCC MinGW): không tạo thiết bị, không luồng vẽ. Mọi hàm của
// Display trở thành no-op; vòng lặp cửa sổ tự xoay theo nhịp nghỉ một khung hình.
#include "client/display.hpp"

#include "core/error.hpp"

#include <chrono>
#include <memory>
#include <string>
#include <thread>
#include <utility>

namespace game::client {
namespace {

constexpr std::chrono::milliseconds kFramePause{16};

} // namespace

struct Display::State {};

Display::Display(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
Display::Display(Display&&) noexcept = default;
Display& Display::operator=(Display&&) noexcept = default;
Display::~Display() = default;

core::Result<Display> Display::create(const DisplayDesc& /*desc*/) {
    return Display(std::make_unique<State>());
}

void Display::notify_resized(PixelSize /*size*/) noexcept {}

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

// Các hàm dưới không đọc state_ ở bản này và description trả một chuỗi cố định; chúng giữ dạng
// thành viên và kiểu trả std::string vì hợp đồng chung với bản có GPU (display.hpp).
// NOLINTBEGIN(readability-convert-member-functions-to-static)
std::string Display::description() const {
    return "không vẽ: bản dựng này không có chuỗi đồ hoạ";
}
// NOLINTEND(readability-convert-member-functions-to-static)

} // namespace game::client
