// Tiến trình con trên POSIX. Chưa chạy lần nào: máy phát triển là Windows, bản này mới qua kiểm
// cú pháp bằng trình dịch của NDK. Lần đầu dựng trên Linux phải chạy process_tests trước khi dùng.
// - Con có nhóm tiến trình riêng: Ctrl+C ở terminal của cha không tới thẳng con.
// - Đầu ống cha giữ mang FD_CLOEXEC nên không lọt sang con khác. POSIX không có job: con tự thoát
//   khi stdin của nó đóng theo cha.
// Nguồn: TLBB Dev src/platform/process_posix.cpp và console.cpp @e0d89a6.
// Khác gốc: lỗi core::Result; stdin rỗng và stderr gộp cho kCommand; tín hiệu dừng gồm SIGINT,
// SIGTERM và SIGHUP; câu hỏi dừng phân biệt ống, terminal và thiết bị rỗng.
#include "process/process.hpp"

#include "core/error.hpp"
#include "core/text.hpp"
#include "process/detail/child_state.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <fcntl.h>
#include <poll.h>
#include <spawn.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

// Biến môi trường của tiến trình. POSIX khai nó nhưng không buộc header nào đưa ra, nên tự khai;
// thư viện C nào đã có sẵn trong unistd.h thì khai lại là thừa mà vô hại (HP-07).
// NOLINTNEXTLINE(*-avoid-non-const-global-variables,readability-redundant-declaration)
extern char** environ;

namespace game::process {
namespace {

using Arguments = std::span<const std::string_view>;
using Milliseconds = std::chrono::milliseconds;
using Clock = std::chrono::steady_clock;
// Hai struct của C trùng tên với hàm cùng tên; alias để thân hàm không phải viết `struct`.
using SignalAction = struct sigaction;
using FileStatus = struct stat;

constexpr std::size_t kArgumentCeiling = 32768;
constexpr int kPauseSlice = 15;
constexpr int kSignalExitBase = 128;

void close_descriptor(int& descriptor) noexcept {
    if (descriptor < 0) return;
    static_cast<void>(::close(descriptor));
    descriptor = -1;
}

[[nodiscard]] int poll_span(Milliseconds limit) noexcept {
    return static_cast<int>(std::clamp<Milliseconds::rep>(limit.count(), 0, kPauseSlice));
}

void sleep_slice(Milliseconds limit) noexcept {
    static_cast<void>(::poll(nullptr, 0, poll_span(limit)));
}

// Ống.
// Một cặp đầu ống; huỷ là đóng đầu nào còn giữ.
struct Pipe {
    int read = -1;
    int write = -1;

    Pipe() = default;
    ~Pipe() {
        close_descriptor(read);
        close_descriptor(write);
    }
    Pipe(const Pipe&) = delete;
    Pipe& operator=(const Pipe&) = delete;
    Pipe(Pipe&&) = delete;
    Pipe& operator=(Pipe&&) = delete;

    [[nodiscard]] bool open() noexcept {
        std::array<int, 2> ends{-1, -1};
        if (::pipe(ends.data()) != 0) return false;
        read = ends[0];
        write = ends[1];
        return true;
    }
};

[[nodiscard]] bool set_close_on_exec(int descriptor) noexcept {
    const int current = ::fcntl(descriptor, F_GETFD);
    return current >= 0 && ::fcntl(descriptor, F_SETFD, current | FD_CLOEXEC) == 0;
}

[[nodiscard]] bool set_non_blocking(int descriptor) noexcept {
    const int current = ::fcntl(descriptor, F_GETFL);
    return current >= 0 && ::fcntl(descriptor, F_SETFL, current | O_NONBLOCK) == 0;
}

// Đầu của cha không lọt sang con; đầu đọc không chặn để vòng đọc dòng tự giữ hạn chờ.
[[nodiscard]] bool keep_private(const Pipe& inbound, const Pipe& outbound) noexcept {
    const bool is_read_ready = set_close_on_exec(outbound.read) && set_non_blocking(outbound.read);
    if (inbound.write < 0) return is_read_ready;
    return is_read_ready && set_close_on_exec(inbound.write);
}

// Đối số.
struct ArgumentList {
    std::vector<std::string> owned;
    bool is_valid = true;
};

void keep_argument(ArgumentList& list, std::string_view argument) {
    const bool is_plain = argument.size() <= kArgumentCeiling && !argument.contains('\0');
    list.is_valid = list.is_valid && is_plain && core::is_valid_utf8(argument);
    if (!list.is_valid) return;
    list.owned.emplace_back(argument);
}

void push_pointer(std::vector<char*>& pointers, std::string& word) {
    pointers.push_back(word.data());
}

// Tạo tiến trình.
// Ba mô tả tệp chuẩn của tiến trình con.
enum class Standard : int {
    kInput = STDIN_FILENO,
    kOutput = STDOUT_FILENO,
    kError = STDERR_FILENO,
};

// Danh sách thao tác tệp và thuộc tính của posix_spawn; huỷ là giải phóng.
class SpawnSetup {
public:
    SpawnSetup() = default;
    ~SpawnSetup() {
        if (has_actions_) static_cast<void>(::posix_spawn_file_actions_destroy(&actions_));
        if (has_attributes_) static_cast<void>(::posix_spawnattr_destroy(&attributes_));
    }
    SpawnSetup(const SpawnSetup&) = delete;
    SpawnSetup& operator=(const SpawnSetup&) = delete;
    SpawnSetup(SpawnSetup&&) = delete;
    SpawnSetup& operator=(SpawnSetup&&) = delete;

    [[nodiscard]] bool prepare(const Pipe& inbound, const Pipe& outbound, Mode mode) noexcept;
    [[nodiscard]] const posix_spawn_file_actions_t* actions() const noexcept { return &actions_; }
    [[nodiscard]] const posix_spawnattr_t* attributes() const noexcept { return &attributes_; }

private:
    // Mô tả tệp chuẩn standard của con trỏ tới mô tả tệp source của cha.
    [[nodiscard]] bool redirect(Standard standard, int source) noexcept;
    [[nodiscard]] bool open_null_input() noexcept;
    [[nodiscard]] bool wire_input(const Pipe& inbound, Mode mode) noexcept;
    [[nodiscard]] bool own_group() noexcept;

    posix_spawn_file_actions_t actions_{};
    posix_spawnattr_t attributes_{};
    bool has_actions_ = false;
    bool has_attributes_ = false;
};

bool SpawnSetup::redirect(Standard standard, int source) noexcept {
    const int target = std::to_underlying(standard);
    return ::posix_spawn_file_actions_adddup2(&actions_, source, target) == 0;
}

bool SpawnSetup::open_null_input() noexcept {
    constexpr int kInput = STDIN_FILENO;
    return ::posix_spawn_file_actions_addopen(&actions_, kInput, "/dev/null", O_RDONLY, 0) == 0;
}

bool SpawnSetup::wire_input(const Pipe& inbound, Mode mode) noexcept {
    if (mode == Mode::kCommand) return open_null_input();
    return redirect(Standard::kInput, inbound.read);
}

bool SpawnSetup::own_group() noexcept {
    if (::posix_spawnattr_setpgroup(&attributes_, 0) != 0) return false;
    return ::posix_spawnattr_setflags(&attributes_, POSIX_SPAWN_SETPGROUP) == 0;
}

bool SpawnSetup::prepare(const Pipe& inbound, const Pipe& outbound, Mode mode) noexcept {
    has_actions_ = ::posix_spawn_file_actions_init(&actions_) == 0;
    has_attributes_ = ::posix_spawnattr_init(&attributes_) == 0;
    if (!has_actions_ || !has_attributes_) return false;
    const bool has_input = wire_input(inbound, mode);
    const bool has_output = redirect(Standard::kOutput, outbound.write);
    const bool is_merged = mode == Mode::kCommand;
    const bool has_error = !is_merged || redirect(Standard::kError, outbound.write);
    return own_group() && has_input && has_output && has_error;
}

[[nodiscard]] int exit_code_of(int status) noexcept {
    if (WIFEXITED(status)) return WEXITSTATUS(status);
    if (WIFSIGNALED(status)) return kSignalExitBase + WTERMSIG(status);
    return 1;
}

// Yêu cầu dừng.
[[nodiscard]] std::atomic<bool>& stop_flag() noexcept {
    static std::atomic<bool> flag{false};
    return flag;
}

// Trình xử lý tín hiệu: chỉ ghi một atomic không khoá.
void on_signal(int /*signal*/) noexcept {
    stop_flag().store(true, std::memory_order_relaxed);
}

[[nodiscard]] bool install_stop_handler() noexcept {
    SignalAction action{};
    action.sa_handler = &on_signal;
    const bool has_interrupt = ::sigaction(SIGINT, &action, nullptr) == 0;
    const bool has_terminate = ::sigaction(SIGTERM, &action, nullptr) == 0;
    const bool has_hangup = ::sigaction(SIGHUP, &action, nullptr) == 0;
    return has_interrupt && has_terminate && has_hangup;
}

// Ống còn mở khi chưa có POLLHUP. Byte ai đó gửi vào thì đọc bỏ: stdin chỉ là dây báo dừng.
[[nodiscard]] bool pipe_ended() noexcept {
    pollfd item{};
    item.fd = STDIN_FILENO;
    item.events = POLLIN;
    if (::poll(&item, 1, 0) <= 0) return false;
    if ((item.revents & POLLIN) == 0) return true;
    std::array<char, detail::kReadChunk> sink{};
    const ssize_t got = ::read(STDIN_FILENO, sink.data(), sink.size());
    if (got > 0) return false;
    if (got == 0) return true;
    return errno != EINTR && errno != EAGAIN;
}

// Thiết bị rỗng, tệp thường và mô tả tệp hỏng đều là "đã hết dòng"; terminal thì chờ tín hiệu.
[[nodiscard]] bool input_ended() noexcept {
    FileStatus info{};
    if (::fstat(STDIN_FILENO, &info) != 0) return true;
    if (S_ISFIFO(info.st_mode) || S_ISSOCK(info.st_mode)) return pipe_ended();
    return ::isatty(STDIN_FILENO) == 0;
}

[[nodiscard]] detail::Chunk failed_chunk(int error) noexcept {
    detail::Chunk chunk;
    chunk.kind = detail::ChunkKind::kFailed;
    chunk.system = static_cast<std::uint32_t>(error);
    return chunk;
}

[[nodiscard]] detail::Chunk read_ready(int descriptor) {
    std::array<char, detail::kReadChunk> buffer{};
    const ssize_t got = ::read(descriptor, buffer.data(), buffer.size());
    detail::Chunk chunk;
    if (got > 0) {
        chunk.kind = detail::ChunkKind::kBytes;
        chunk.bytes.assign(buffer.data(), static_cast<std::size_t>(got));
        return chunk;
    }
    const bool is_retry = got < 0 && (errno == EINTR || errno == EAGAIN);
    if (is_retry) return chunk;
    if (got < 0) return failed_chunk(errno);
    chunk.kind = detail::ChunkKind::kClosed;
    return chunk;
}

} // namespace

// Ba thao tác nền tảng của vòng đọc dòng.
namespace detail {

bool exited_now(ChildState& state) noexcept {
    if (state.exited || state.pid <= 0) return true;
    int status = 0;
    const pid_t got = ::waitpid(state.pid, &status, WNOHANG);
    if (got == 0) return false;
    state.exited = true;
    state.code = got == state.pid ? exit_code_of(status) : 1;
    return true;
}

Chunk read_available(const ChildState& state) {
    if (state.output < 0) return Chunk{.kind = ChunkKind::kClosed, .bytes = {}, .system = 0};
    pollfd item{};
    item.fd = state.output;
    item.events = POLLIN;
    const int ready = ::poll(&item, 1, 0);
    const bool is_idle = ready == 0 || (ready < 0 && errno == EINTR);
    if (is_idle) return {};
    if (ready < 0) return failed_chunk(errno);
    return read_ready(state.output);
}

void pause(const ChildState& state, std::chrono::milliseconds limit) noexcept {
    pollfd item{};
    item.fd = state.output;
    item.events = POLLIN;
    static_cast<void>(::poll(&item, 1, poll_span(limit)));
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
    close_descriptor(state_->output);
    state_.reset();
}

Child::operator bool() const noexcept {
    return state_ != nullptr && state_->pid > 0;
}

std::uint32_t Child::id() const noexcept {
    if (!*this) return 0;
    return static_cast<std::uint32_t>(state_->pid);
}

void Child::close_input() noexcept {
    if (state_ == nullptr) return;
    close_descriptor(state_->input);
}

void Child::force_stop() noexcept {
    if (!*this || detail::exited_now(*state_)) return;
    static_cast<void>(::kill(state_->pid, SIGKILL));
    int status = 0;
    const pid_t got = ::waitpid(state_->pid, &status, 0);
    state_->exited = true;
    state_->code = got == state_->pid ? exit_code_of(status) : 1;
}

std::optional<int> Child::try_wait() noexcept {
    if (!*this) return 1;
    if (!detail::exited_now(*state_)) return std::nullopt;
    return state_->code;
}

ExitStatus Child::wait_for(std::chrono::milliseconds limit) noexcept {
    if (!*this) return ExitStatus{.kind = WaitKind::kExited, .code = 1};
    const auto deadline = Clock::now() + limit;
    while (!detail::exited_now(*state_) && Clock::now() < deadline) {
        const auto remaining = std::chrono::duration_cast<Milliseconds>(deadline - Clock::now());
        sleep_slice(remaining);
    }
    if (!detail::exited_now(*state_)) return {};
    return ExitStatus{.kind = WaitKind::kExited, .code = state_->code};
}

core::Result<Child> spawn(const Spawn& request) {
    ArgumentList list;
    keep_argument(list, request.executable);
    for (const std::string_view argument : request.arguments) {
        keep_argument(list, argument);
    }
    const bool is_valid = list.is_valid && !request.executable.empty();
    if (!is_valid) return core::fail(core::ErrorCode::kInvalidArgument, "đối số không hợp lệ");
    Pipe inbound;
    Pipe outbound;
    const bool has_input = request.mode == Mode::kCommand || inbound.open();
    const bool has_pipes = has_input && outbound.open() && keep_private(inbound, outbound);
    if (!has_pipes) return core::fail(core::ErrorCode::kIo, "không tạo được ống");
    SpawnSetup setup;
    if (!setup.prepare(inbound, outbound, request.mode)) {
        return core::fail(core::ErrorCode::kIo, "không dựng được thao tác tạo tiến trình");
    }
    std::vector<char*> pointers;
    for (std::string& word : list.owned) {
        push_pointer(pointers, word);
    }
    pointers.push_back(nullptr);
    pid_t pid = 0;
    const int spawned = ::posix_spawn(
        &pid, pointers.front(), setup.actions(), setup.attributes(), pointers.data(), environ);
    if (spawned != 0) {
        const auto system = static_cast<std::uint32_t>(spawned);
        return core::fail_system(system, "không tạo được tiến trình");
    }
    Child child;
    child.state_ = std::make_unique<detail::ChildState>();
    child.state_->pid = pid;
    child.state_->input = std::exchange(inbound.write, -1);
    child.state_->output = std::exchange(outbound.read, -1);
    return child;
}

void watch_stop_signals() noexcept {
    static const bool is_installed = install_stop_handler();
    static_cast<void>(is_installed);
}

bool stop_requested() noexcept {
    watch_stop_signals();
    if (stop_flag().load(std::memory_order_relaxed)) return true;
    return input_ended();
}

bool process_alive(std::uint32_t id) noexcept {
    if (id == 0) return false;
    if (::kill(static_cast<pid_t>(id), 0) == 0) return true;
    return errno == EPERM;
}

std::vector<std::string> utf8_arguments(int argc, const char* const* argv) {
    if (argc < 1 || argv == nullptr) return {};
    const std::span<const char* const> raw{argv, static_cast<std::size_t>(argc)};
    return std::vector<std::string>{raw.begin() + 1, raw.end()};
}

} // namespace game::process