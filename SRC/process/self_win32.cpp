// Phía của chính tiến trình này trên Windows: câu hỏi "đã có yêu cầu dừng chưa" và đối số UTF-8.
// Tách khỏi process_win32.cpp (điều khiển tiến trình con) để mỗi tệp một việc.
// Nguồn: TLBB Dev src/platform/console.cpp @e0d89a6.
// Khác gốc: phân biệt stdin là ống, console hay thiết bị rỗng; con được giám sát bỏ qua Ctrl+C;
// giữ luồng xử lý khi cửa sổ đóng để luồng chính kịp dừng êm.
#include "process/process.hpp"

#include "core/handle.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "process/detail/child_state.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cstdint>
#include <string>
#include <vector>

#include <consoleapi.h>
#include <fileapi.h>
#include <handleapi.h>
#include <minwindef.h>
#include <namedpipeapi.h>
#include <processenv.h>
#include <processthreadsapi.h>
#include <synchapi.h>
#include <winbase.h>
#include <wincon.h>
#include <winerror.h>
#include <winnt.h>

namespace game::process {
namespace {

struct StopState {
    std::atomic<bool> is_requested{false};
    // stdin là ống: tiến trình do cha điều khiển, cha đóng ống để bảo dừng.
    std::atomic<bool> is_piped{false};
};

[[nodiscard]] StopState& stop_state() noexcept {
    static StopState state;
    return state;
}

enum class InputKind : std::uint8_t { kPipe, kConsole, kEnded };

// Thiết bị rỗng, tệp đĩa và handle hỏng đều là "đã hết dòng": không ai đóng chúng về sau được.
[[nodiscard]] InputKind input_kind(HANDLE input) noexcept {
    if (input == nullptr || input == INVALID_HANDLE_VALUE) return InputKind::kEnded;
    const DWORD type = GetFileType(input);
    if (type == FILE_TYPE_PIPE) return InputKind::kPipe;
    DWORD mode = 0;
    const bool is_console = type == FILE_TYPE_CHAR && GetConsoleMode(input, &mode) != FALSE;
    return is_console ? InputKind::kConsole : InputKind::kEnded;
}

// Ống còn mở khi PeekNamedPipe còn trả lời. Byte ai đó gửi vào thì đọc bỏ: stdin chỉ là dây báo
// dừng, để byte nằm lại thì không bao giờ thấy được đầu kia đóng.
[[nodiscard]] bool pipe_ended(HANDLE input) noexcept {
    DWORD available = 0;
    if (PeekNamedPipe(input, nullptr, 0, nullptr, &available, nullptr) == FALSE) return true;
    if (available == 0) return false;
    std::array<char, detail::kReadChunk> sink{};
    const DWORD want = std::min(available, static_cast<DWORD>(sink.size()));
    DWORD got = 0;
    return ReadFile(input, sink.data(), want, &got, nullptr) == FALSE;
}

[[nodiscard]] bool input_ended() noexcept {
    auto* const input = GetStdHandle(STD_INPUT_HANDLE);
    const InputKind kind = input_kind(input);
    if (kind == InputKind::kPipe) return pipe_ended(input);
    return kind == InputKind::kEnded;
}

// Chạy trên luồng riêng do Windows tạo. Con được giám sát không tự dừng theo phím: cha sẽ đóng
// ống của từng con theo thứ tự ngược lúc chạy.
BOOL WINAPI on_console_event(DWORD event) noexcept {
    StopState& state = stop_state();
    if (!state.is_piped.load(std::memory_order_relaxed)) {
        state.is_requested.store(true, std::memory_order_relaxed);
    }
    // Đóng cửa sổ, đăng xuất, tắt máy: Windows kết thúc tiến trình ngay khi hàm này trả về. Giữ
    // luồng này lại để luồng chính kịp dừng êm trong hạn hệ điều hành cho.
    const bool is_key = event == CTRL_C_EVENT || event == CTRL_BREAK_EVENT;
    if (!is_key) Sleep(INFINITE);
    return TRUE;
}

[[nodiscard]] bool install_stop_handler() noexcept {
    const bool is_piped = input_kind(GetStdHandle(STD_INPUT_HANDLE)) == InputKind::kPipe;
    stop_state().is_piped.store(is_piped, std::memory_order_relaxed);
    // Tiến trình sinh ra trong nhóm riêng thừa hưởng trạng thái "bỏ qua Ctrl+C". Tiến trình chạy
    // tay trong console phải nghe lại phím đó; con được giám sát thì giữ nguyên.
    if (!is_piped) static_cast<void>(SetConsoleCtrlHandler(nullptr, FALSE));
    return SetConsoleCtrlHandler(&on_console_event, TRUE) != FALSE;
}

} // namespace

void watch_stop_signals() noexcept {
    static const bool kInstalled = install_stop_handler();
    static_cast<void>(kInstalled);
}

bool stop_requested() noexcept {
    watch_stop_signals();
    if (stop_state().is_requested.load(std::memory_order_relaxed)) return true;
    return input_ended();
}

bool process_alive(std::uint32_t id) noexcept {
    if (id == 0) return false;
    const DWORD access = SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION;
    const core::UniqueHandle opened{OpenProcess(access, FALSE, id)};
    if (!opened) return false;
    return WaitForSingleObject(opened.get(), 0) == WAIT_TIMEOUT;
}

std::vector<std::string> utf8_arguments(int /*argc*/, const char* const* /*argv*/) {
    std::vector<std::string> arguments = split_command_line(core::narrow(GetCommandLineW()));
    if (!arguments.empty()) arguments.erase(arguments.begin());
    return arguments;
}

} // namespace game::process
