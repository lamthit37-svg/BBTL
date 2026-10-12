// Tiến trình con trên Windows.
// - Con kiểu kService nằm trong một job KILL_ON_JOB_CLOSE: giám sát chết đột ngột thì hệ điều hành
//   dừng các con. Con kiểu kCommand đứng ngoài job, để tiến trình nền nó khởi động (PostgreSQL)
//   không bị giết cứng theo giám sát.
// - Con chỉ thừa hưởng ba handle chuẩn (PROC_THREAD_ATTRIBUTE_HANDLE_LIST): ống của con này không
//   lọt sang con khác, handle của cha không lọt sang tiến trình nền.
// - Nhóm tiến trình riêng: Ctrl+C ở console của cha không tới thẳng con.
// Nguồn: TLBB Dev src/platform/process_win32.cpp và console.cpp @e0d89a6.
// Khác gốc: lỗi core::Result; tạo ở trạng thái treo rồi mới đưa vào job; danh sách handle thừa
// hưởng; stdin rỗng và stderr gộp cho kCommand; câu hỏi dừng phân biệt ống, console, thiết bị rỗng.
#include "process/process.hpp"

#include "core/error.hpp"
#include "core/handle.hpp"
#include "core/text.hpp"
#include "core/win32.hpp" // IWYU pragma: keep
#include "process/detail/child_state.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <basetsd.h>
#include <errhandlingapi.h>
#include <fileapi.h>
#include <handleapi.h>
// MinGW khai các hàm job trong winbase.h và không có tệp này.
#if !defined(__MINGW32__)
#include <jobapi2.h>
#endif
#include <minwinbase.h>
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

using Arguments = std::span<const std::string_view>;
using Milliseconds = std::chrono::milliseconds;
using WideResult = core::Result<std::wstring>;

// CreateProcessW nhận dòng lệnh tối đa 32767 ký tự UTF-16; một đối số cũng không dài hơn thế.
constexpr std::size_t kCommandCeiling = 32767;
// Ống vô danh không chờ được bằng WaitForSingleObject: vòng đọc hỏi lại sau mỗi khoảng này.
constexpr DWORD kPauseSlice = 15;

[[nodiscard]] DWORD wait_span(Milliseconds limit) noexcept {
    constexpr Milliseconds::rep kMost = 0xFFFFFFFE;
    return static_cast<DWORD>(std::clamp<Milliseconds::rep>(limit.count(), 0, kMost));
}

// Dòng lệnh.
// Một ký tự vào đối số đang đặt trong nháy: dãy `\` đứng trước `"` phải nhân đôi, `"` phải có `\`.
void push_quoted(std::wstring& out, wchar_t unit, std::size_t& slashes) {
    if (unit == L'\\') {
        ++slashes;
        return;
    }
    const std::size_t extra = unit == L'"' ? slashes + 1 : 0;
    out.append(slashes + extra, L'\\');
    out.push_back(unit);
    slashes = 0;
}

void append_quoted(std::wstring& out, std::wstring_view text) {
    out.push_back(L'"');
    std::size_t slashes = 0;
    for (const wchar_t unit : text) {
        push_quoted(out, unit, slashes);
    }
    out.append(slashes * 2, L'\\');
    out.push_back(L'"');
}

// Byte 0 cắt cụt dòng lệnh, UTF-8 hỏng thành ký tự thay thế: cả hai là đối số sai, không chạy.
[[nodiscard]] bool is_usable(std::string_view text) noexcept {
    if (text.size() > kCommandCeiling || text.contains('\0')) return false;
    return core::is_valid_utf8(text);
}

struct CommandLine {
    std::wstring text;
    bool is_valid = true;
};

void append_argument(CommandLine& line, std::string_view argument) {
    line.is_valid = line.is_valid && is_usable(argument);
    if (!line.is_valid) return;
    line.text.push_back(L' ');
    append_quoted(line.text, core::widen(argument));
}

[[nodiscard]] WideResult command_line(std::wstring_view executable, Arguments list) {
    CommandLine line;
    append_quoted(line.text, executable);
    for (const std::string_view argument : list) {
        append_argument(line, argument);
    }
    if (!line.is_valid) return core::fail(core::ErrorCode::kInvalidArgument, "đối số không hợp lệ");
    const bool is_short = line.text.size() <= kCommandCeiling;
    if (!is_short) return core::fail(core::ErrorCode::kOverflow, "dòng lệnh dài quá trần");
    return std::move(line.text);
}

// Handle chuẩn của con.
// Handle con thừa hưởng và đầu ống cha giữ. parent_input rỗng với kCommand; child_error rỗng khi
// stderr gộp vào stdout hoặc cha không có stderr.
struct Wiring {
    core::UniqueHandle child_input;
    core::UniqueHandle child_output;
    core::UniqueHandle child_error;
    core::UniqueHandle parent_input;
    core::UniqueHandle parent_output;
};

struct PipeEnds {
    core::UniqueHandle read;
    core::UniqueHandle write;
};

[[nodiscard]] SECURITY_ATTRIBUTES inheritable() noexcept {
    SECURITY_ATTRIBUTES security{};
    security.nLength = static_cast<DWORD>(sizeof(security));
    security.bInheritHandle = TRUE;
    return security;
}

// Cả hai đầu thừa hưởng được; bên gọi tắt cờ ở đầu của cha bằng keep_private.
[[nodiscard]] core::Result<PipeEnds> open_pipe() {
    SECURITY_ATTRIBUTES security = inheritable();
    HANDLE read = nullptr;
    HANDLE write = nullptr;
    const bool is_open = CreatePipe(&read, &write, &security, 0) != FALSE;
    if (!is_open) return core::fail_system(GetLastError(), "không tạo được ống");
    return PipeEnds{.read = core::UniqueHandle{read}, .write = core::UniqueHandle{write}};
}

[[nodiscard]] core::Status keep_private(const core::UniqueHandle& handle) {
    const bool is_private = SetHandleInformation(handle.get(), HANDLE_FLAG_INHERIT, 0) != FALSE;
    if (is_private) return core::ok();
    return core::fail_system(GetLastError(), "không khoá được đầu ống của cha");
}

// Thiết bị rỗng làm stdin: con đọc là hết dòng ngay.
[[nodiscard]] core::Status wire_null_input(Wiring& wiring) {
    SECURITY_ATTRIBUTES security = inheritable();
    const DWORD share = FILE_SHARE_READ | FILE_SHARE_WRITE;
    auto* const opened = CreateFileW(L"NUL", GENERIC_READ, share, &security, OPEN_EXISTING, 0, nullptr);
    const bool is_open = opened != INVALID_HANDLE_VALUE;
    if (!is_open) return core::fail_system(GetLastError(), "không mở được thiết bị rỗng");
    wiring.child_input = core::UniqueHandle{opened};
    return core::ok();
}

[[nodiscard]] core::Status wire_pipe_input(Wiring& wiring) {
    core::Result<PipeEnds> pipe = open_pipe();
    if (!pipe) return std::unexpected(pipe.error());
    wiring.child_input = std::move(pipe->read);
    wiring.parent_input = std::move(pipe->write);
    return keep_private(wiring.parent_input);
}

// Bản thừa hưởng được của stderr của cha; rỗng khi cha không có stderr.
[[nodiscard]] core::UniqueHandle share_stderr() noexcept {
    auto* const own = GetStdHandle(STD_ERROR_HANDLE);
    if (own == nullptr || own == INVALID_HANDLE_VALUE) return {};
    auto* const self = GetCurrentProcess();
    HANDLE copy = nullptr;
    const BOOL copied = DuplicateHandle(self, own, self, &copy, 0, TRUE, DUPLICATE_SAME_ACCESS);
    if (copied == FALSE) return {};
    return core::UniqueHandle{copy};
}

[[nodiscard]] core::Status wire_output(Wiring& wiring, Mode mode) {
    core::Result<PipeEnds> pipe = open_pipe();
    if (!pipe) return std::unexpected(pipe.error());
    wiring.child_output = std::move(pipe->write);
    wiring.parent_output = std::move(pipe->read);
    if (mode == Mode::kService) wiring.child_error = share_stderr();
    return keep_private(wiring.parent_output);
}

[[nodiscard]] core::Status wire(Wiring& wiring, Mode mode) {
    const bool is_command = mode == Mode::kCommand;
    const core::Status input = is_command ? wire_null_input(wiring) : wire_pipe_input(wiring);
    if (!input) return input;
    return wire_output(wiring, mode);
}

// Tạo tiến trình.
// Mọi thứ CreateProcessW cần; spawn dựng một lần rồi các bước dưới cùng đọc.
struct Plan {
    std::wstring executable;
    std::wstring command;
    Wiring wiring;
    Mode mode = Mode::kService;
};

struct Launch {
    core::UniqueHandle process;
    core::UniqueHandle thread;
    std::uint32_t pid = 0;
};

// Danh sách thuộc tính của CreateProcessW chỉ mang một mục: các handle con được thừa hưởng. Bộ
// nhớ của danh sách và mảng handle phải sống tới sau CreateProcessW, nên cả hai nằm trong lớp.
class InheritList {
public:
    InheritList() = default;
    ~InheritList() {
        if (is_ready_) DeleteProcThreadAttributeList(get());
    }
    InheritList(const InheritList&) = delete;
    InheritList& operator=(const InheritList&) = delete;
    InheritList(InheritList&&) = delete;
    InheritList& operator=(InheritList&&) = delete;

    [[nodiscard]] core::Status set(std::vector<HANDLE> handles);
    // Windows chỉ cho biết cỡ của danh sách, không cho kiểu: vùng byte tự cấp là chỗ chứa nó.
    [[nodiscard]] LPPROC_THREAD_ATTRIBUTE_LIST get() noexcept {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): kiểu mờ của Win32 (UB-03)
        return reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(storage_.data());
    }

private:
    std::vector<std::byte> storage_;
    std::vector<HANDLE> handles_;
    bool is_ready_ = false;
};

core::Status InheritList::set(std::vector<HANDLE> handles) {
    handles_ = std::move(handles);
    SIZE_T size = 0;
    // Lần gọi đầu chỉ để hỏi cỡ: nó báo thất bại và ghi số byte cần vào size.
    static_cast<void>(InitializeProcThreadAttributeList(nullptr, 1, 0, &size));
    storage_.resize(size);
    is_ready_ = InitializeProcThreadAttributeList(get(), 1, 0, &size) != FALSE;
    if (!is_ready_) return core::fail_system(GetLastError(), "không dựng được danh sách handle");
    const SIZE_T bytes = handles_.size() * sizeof(HANDLE);
    void* const value = static_cast<void*>(handles_.data());
    const BOOL updated =
        UpdateProcThreadAttribute(get(), 0, PROC_THREAD_ATTRIBUTE_HANDLE_LIST, value, bytes, nullptr, nullptr);
    if (updated != FALSE) return core::ok();
    return core::fail_system(GetLastError(), "không ghi được danh sách handle thừa hưởng");
}

[[nodiscard]] STARTUPINFOEXW startup_of(const Plan& plan) noexcept {
    STARTUPINFOEXW start{};
    start.StartupInfo.cb = static_cast<DWORD>(sizeof(start));
    start.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
    const Wiring& wiring = plan.wiring;
    start.StartupInfo.hStdInput = wiring.child_input.get();
    start.StartupInfo.hStdOutput = wiring.child_output.get();
    const bool is_merged = plan.mode == Mode::kCommand;
    const core::UniqueHandle& error = is_merged ? wiring.child_output : wiring.child_error;
    start.StartupInfo.hStdError = error.get();
    return start;
}

// Danh sách không được lặp handle và không được chứa handle rỗng. Mảng ba ô rồi cắt, không
// push_back vào vector hai phần tử: GCC 16 -O2 báo nhầm -Warray-bounds ở dạng đó.
[[nodiscard]] std::vector<HANDLE> inherited(const STARTUPINFOW& start) {
    const std::array<HANDLE, 3> all{start.hStdInput, start.hStdOutput, start.hStdError};
    const bool is_own = start.hStdError != nullptr && start.hStdError != start.hStdOutput;
    const std::span<const HANDLE> used = std::span{all}.first(is_own ? 3 : 2);
    return std::vector<HANDLE>{used.begin(), used.end()};
}

[[nodiscard]] core::Result<Launch> create_suspended(Plan& plan) {
    STARTUPINFOEXW start = startup_of(plan);
    InheritList list;
    const core::Status listed = list.set(inherited(start.StartupInfo));
    if (!listed) return std::unexpected(listed.error());
    start.lpAttributeList = list.get();
    PROCESS_INFORMATION info{};
    const DWORD flags = CREATE_SUSPENDED | CREATE_NEW_PROCESS_GROUP | EXTENDED_STARTUPINFO_PRESENT;
    const BOOL created = CreateProcessW(plan.executable.c_str(), plan.command.data(), nullptr, nullptr, TRUE, flags,
        nullptr, nullptr, &start.StartupInfo, &info);
    if (created == FALSE) return core::fail_system(GetLastError(), "không tạo được tiến trình");
    Launch launch;
    launch.process = core::UniqueHandle{info.hProcess};
    launch.thread = core::UniqueHandle{info.hThread};
    launch.pid = info.dwProcessId;
    return launch;
}

[[nodiscard]] core::UniqueHandle make_job() noexcept {
    core::UniqueHandle job{CreateJobObjectW(nullptr, nullptr)};
    if (!job) return {};
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits{};
    limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    const auto size = static_cast<DWORD>(sizeof(limits));
    const BOOL applied = SetInformationJobObject(job.get(), JobObjectExtendedLimitInformation, &limits, size);
    if (applied == FALSE) return {};
    return job;
}

// Một job cho mọi con kiểu kService; handle đóng khi tiến trình cha kết thúc, kể cả bị giết.
[[nodiscard]] HANDLE shared_job() noexcept {
    static const core::UniqueHandle kJob = make_job();
    return kJob.get();
}

// Job là lớp bảo vệ thứ hai. Không gán được (cha đang ở trong một job cấm lồng) thì con vẫn tự
// thoát khi ống stdin của nó đóng theo cha.
[[nodiscard]] core::Status start_running(const Launch& launch, Mode mode) {
    auto* const job = shared_job();
    const bool is_tied = mode == Mode::kService && job != nullptr;
    if (is_tied) static_cast<void>(AssignProcessToJobObject(job, launch.process.get()));
    const bool is_resumed = ResumeThread(launch.thread.get()) != static_cast<DWORD>(-1);
    if (is_resumed) return core::ok();
    const DWORD error = GetLastError();
    static_cast<void>(TerminateProcess(launch.process.get(), 1));
    static_cast<void>(WaitForSingleObject(launch.process.get(), INFINITE));
    return core::fail_system(error, "không chạy tiếp được tiến trình");
}

[[nodiscard]] detail::Chunk closed_or_failed(DWORD error) noexcept {
    detail::Chunk chunk;
    const bool is_closed = error == ERROR_BROKEN_PIPE || error == ERROR_INVALID_HANDLE;
    chunk.kind = is_closed ? detail::ChunkKind::kClosed : detail::ChunkKind::kFailed;
    chunk.system = error;
    return chunk;
}

} // namespace

// Ba thao tác nền tảng của vòng đọc dòng.
namespace detail {

bool exited_now(ChildState& state) noexcept {
    if (state.exited || !state.process) return true;
    if (WaitForSingleObject(state.process.get(), 0) == WAIT_TIMEOUT) return false;
    DWORD code = 1;
    static_cast<void>(GetExitCodeProcess(state.process.get(), &code));
    state.exited = true;
    state.code = static_cast<int>(code);
    return true;
}

Chunk read_available(const ChildState& state) {
    auto* const output = state.output.get();
    DWORD available = 0;
    const BOOL peeked = PeekNamedPipe(output, nullptr, 0, nullptr, &available, nullptr);
    if (peeked == FALSE) return closed_or_failed(GetLastError());
    if (available == 0) return {};
    std::array<char, kReadChunk> buffer{};
    const DWORD want = std::min(available, static_cast<DWORD>(buffer.size()));
    DWORD got = 0;
    const BOOL read = ReadFile(output, buffer.data(), want, &got, nullptr);
    if (read == FALSE) return closed_or_failed(GetLastError());
    Chunk chunk;
    chunk.kind = ChunkKind::kBytes;
    chunk.bytes.assign(buffer.data(), got);
    return chunk;
}

void pause(const ChildState& state, std::chrono::milliseconds limit) noexcept {
    const DWORD slice = std::min(wait_span(limit), kPauseSlice);
    static_cast<void>(WaitForSingleObject(state.process.get(), slice));
}

} // namespace detail

Child::Child() noexcept = default;

Child::~Child() {
    shutdown();
}

Child::Child(Child&& other) noexcept = default;

Child& Child::operator=(Child&& other) noexcept {
    if (this == &other) return *this;
    shutdown();
    state_ = std::move(other.state_);
    return *this;
}

void Child::shutdown() noexcept {
    if (state_ == nullptr) return;
    close_input();
    force_stop();
    state_.reset();
}

Child::operator bool() const noexcept {
    return state_ != nullptr && state_->process.valid();
}

std::uint32_t Child::id() const noexcept {
    if (state_ == nullptr) return 0;
    return state_->pid;
}

void Child::close_input() noexcept {
    if (state_ == nullptr) return;
    state_->input.reset();
}

void Child::force_stop() noexcept {
    if (!*this || detail::exited_now(*state_)) return;
    static_cast<void>(TerminateProcess(state_->process.get(), 1));
    static_cast<void>(WaitForSingleObject(state_->process.get(), INFINITE));
    static_cast<void>(detail::exited_now(*state_));
}

std::optional<int> Child::try_wait() noexcept {
    if (!*this) return 1;
    if (!detail::exited_now(*state_)) return std::nullopt;
    return state_->code;
}

ExitStatus Child::wait_for(std::chrono::milliseconds limit) noexcept {
    if (!*this) return ExitStatus{.kind = WaitKind::kExited, .code = 1};
    static_cast<void>(WaitForSingleObject(state_->process.get(), wait_span(limit)));
    if (!detail::exited_now(*state_)) return {};
    return ExitStatus{.kind = WaitKind::kExited, .code = state_->code};
}

core::Result<Child> spawn(const Spawn& request) {
    const bool is_path = !request.executable.empty() && is_usable(request.executable);
    if (!is_path) return core::fail(core::ErrorCode::kInvalidArgument, "đường dẫn exe sai");
    Plan plan;
    plan.mode = request.mode;
    plan.executable = core::widen(request.executable);
    WideResult command = command_line(plan.executable, request.arguments);
    if (!command) return std::unexpected(command.error());
    plan.command = std::move(*command);
    const core::Status wired = wire(plan.wiring, plan.mode);
    if (!wired) return std::unexpected(wired.error());
    core::Result<Launch> launch = create_suspended(plan);
    if (!launch) return std::unexpected(launch.error());
    const core::Status running = start_running(*launch, plan.mode);
    if (!running) return std::unexpected(running.error());
    Child child;
    child.state_ = std::make_unique<detail::ChildState>();
    child.state_->process = std::move(launch->process);
    child.state_->input = std::move(plan.wiring.parent_input);
    child.state_->output = std::move(plan.wiring.parent_output);
    child.state_->pid = launch->pid;
    return child;
}

} // namespace game::process
