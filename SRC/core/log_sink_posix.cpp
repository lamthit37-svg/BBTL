// Đích ghi log trên POSIX. stdout/stderr là byte UTF-8; tệp gộp 256 KiB qua write; debugger là
// logcat (Android, chỉ khi TracerPid khác 0) hoặc os_log (Apple, chỉ khi P_TRACED). FileSink giữ fd
// đã mã hoá fd+1 trong UniqueHandle, cùng công thức handle_posix.cpp.
// Nguồn: Forge2 src/core/log_sink_android.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; Apple
// dùng os_log. LogHistory nằm ở log_sink.cpp vì không phụ thuộc hệ điều hành.
#if !defined(_WIN32)

#include "core/log.hpp"

#include "core/error.hpp"
#include "core/handle.hpp"
#include "core/text.hpp"

#if defined(__ANDROID__)
#include <android/log.h>
#endif
#if defined(__APPLE__)
#include <os/log.h>
#endif

#include <fcntl.h>
#include <unistd.h>

#include <sys/stat.h>

#if defined(__APPLE__)
#include <sys/sysctl.h>
#endif

#include <algorithm>
#include <array>
#include <cerrno>
#include <cstring>
#include <format>
#include <string>
#include <utility>

namespace game::core {

namespace {

constexpr std::size_t kFileBuffer = std::size_t{256} << 10U;
constexpr std::string_view kColorReset = "\x1b[0m";
constexpr mode_t kLogMode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;

constexpr auto kColors = std::to_array<std::string_view>({"", "\x1b[90m", "", "\x1b[33m", "\x1b[91m"});

// EINTR thử lại. Byte dương thì cắt. Hết hoặc lỗi thì dừng.
[[nodiscard]] bool wrote_some(int fd, std::string_view& bytes) noexcept {
    const ssize_t wrote = ::write(fd, bytes.data(), bytes.size());
    if (wrote < 0 && errno == EINTR) return true;
    if (wrote <= 0) return false;
    bytes.remove_prefix(static_cast<std::size_t>(wrote));
    return true;
}

void write_fd(int fd, std::string_view bytes) noexcept {
    while (!bytes.empty() && wrote_some(fd, bytes)) {
    }
}

[[nodiscard]] std::string painted(std::string_view color, std::string_view line) {
    const bool newline = line.ends_with('\n');
    const std::string_view body = newline ? line.substr(0, line.size() - 1) : line;
    return std::format("{}{}{}{}", color, body, kColorReset, newline ? "\n" : "");
}

[[nodiscard]] void* encode_fd(int fd) noexcept {
    return reinterpret_cast<void*>(static_cast<std::uintptr_t>(fd) + 1U);
}

[[nodiscard]] int decode_fd(void* handle) noexcept {
    const auto encoded = reinterpret_cast<std::uintptr_t>(handle);
    return static_cast<int>(encoded - 1U);
}

[[nodiscard]] bool traced() noexcept {
#if defined(__APPLE__)
    std::array<int, 4> query{CTL_KERN, KERN_PROC, KERN_PROC_PID, ::getpid()};
    kinfo_proc info{};
    std::size_t size = sizeof(info);
    const int result = ::sysctl(query.data(), 4, &info, &size, nullptr, 0);
    if (result != 0) return false;
    return (info.kp_proc.p_flag & P_TRACED) != 0;
#else
    const int fd = ::open("/proc/self/status", O_RDONLY | O_CLOEXEC);
    if (fd < 0) return false;
    std::array<char, 4096> text{};
    const ssize_t got = ::read(fd, text.data(), text.size() - 1);
    static_cast<void>(::close(fd));
    if (got <= 0) return false;
    const std::string_view status(text.data(), static_cast<std::size_t>(got));
    constexpr std::string_view kKey = "TracerPid:";
    const std::size_t at = status.find(kKey);
    if (at == std::string_view::npos) return false;
    std::string_view rest = status.substr(at + kKey.size());
    while (!rest.empty() && (rest.front() == ' ' || rest.front() == '\t')) {
        rest.remove_prefix(1);
    }
    return !rest.empty() && rest.front() != '0';
#endif
}

#if defined(__ANDROID__)

[[nodiscard]] int priority_of(Level level) noexcept {
    if (level == Level::kDebug) return ANDROID_LOG_DEBUG;
    if (level == Level::kWarning) return ANDROID_LOG_WARN;
    if (level == Level::kError) return ANDROID_LOG_ERROR;
    return ANDROID_LOG_INFO;
}

void platform_debug(Level level, std::string_view line) noexcept {
    if (!traced()) return;
    std::array<char, 1024> chunk{};
    while (!line.empty()) {
        const std::size_t count = std::min(line.size(), chunk.size() - 1);
        std::memcpy(chunk.data(), line.data(), count);
        chunk[count] = '\0';
        __android_log_write(priority_of(level), "THIENLONG", chunk.data());
        line.remove_prefix(count);
    }
}

#elif defined(__APPLE__)

void platform_debug(Level level, std::string_view line) noexcept {
    if (!traced()) return;
    static_cast<void>(level);
    os_log(OS_LOG_DEFAULT, "%{public}.*s", static_cast<int>(line.size()), line.data());
}

#else

void platform_debug(Level level, std::string_view line) noexcept {
    static_cast<void>(level);
    static_cast<void>(line);
}

#endif

[[nodiscard]] int open_log(const char* path, int flags) noexcept {
    int fd = ::open(path, flags, kLogMode);
    while (fd < 0 && errno == EINTR) {
        fd = ::open(path, flags, kLogMode);
    }
    return fd;
}

class ConsoleSink final : public LogSink {
public:
    explicit ConsoleSink(Color color) noexcept : color_(color) {}

    // painted có thể ném; hết bộ nhớ thì terminate (LH-07).
    // NOLINTNEXTLINE(bugprone-exception-escape)
    void write(Level level, std::string_view line) noexcept override {
        const int fd = level == Level::kError ? STDERR_FILENO : STDOUT_FILENO;
        const std::string_view color = kColors.at(std::to_underlying(level));
        const bool paint = color_ == Color::kAuto && ::isatty(fd) != 0 && !color.empty();
        if (!paint) return write_fd(fd, line);
        write_fd(fd, painted(color, line));
    }

private:
    Color color_;
};

class FileSink final : public LogSink {
public:
    explicit FileSink(UniqueHandle file) : file_(std::move(file)) { buffer_.reserve(kFileBuffer); }

    ~FileSink() override { FileSink::flush(); }

    FileSink(const FileSink&) = delete;
    FileSink& operator=(const FileSink&) = delete;
    FileSink(FileSink&&) = delete;
    FileSink& operator=(FileSink&&) = delete;

    // append không vượt chỗ đã reserve; tidy không thấy điều đó (LH-07).
    // NOLINTNEXTLINE(bugprone-exception-escape)
    void write([[maybe_unused]] Level level, std::string_view line) noexcept override {
        if (buffer_.size() + line.size() > kFileBuffer) flush();
        if (line.size() > kFileBuffer) return write_fd(decode_fd(file_.get()), line);
        buffer_.append(line);
    }

    void flush() noexcept override {
        if (buffer_.empty()) return;
        write_fd(decode_fd(file_.get()), buffer_);
        buffer_.clear();
    }

private:
    UniqueHandle file_;
    std::string buffer_;
};

class DebuggerSink final : public LogSink {
public:
    void write(Level level, std::string_view line) noexcept override { platform_debug(level, line); }
};

} // namespace

std::unique_ptr<LogSink> console_sink(Color color) {
    return std::make_unique<ConsoleSink>(color);
}

Result<std::unique_ptr<LogSink>> file_sink(const std::filesystem::path& path, FileOpen open) {
    std::error_code ignored;
    std::filesystem::create_directories(path.parent_path(), ignored);
    const bool append = open == FileOpen::kAppend;
    const int extra = append ? O_APPEND : O_TRUNC;
    const int flags = O_CLOEXEC | O_WRONLY | O_CREAT | extra;
    const int fd = open_log(path.c_str(), flags);
    const std::string text = path.string();
    if (fd < 0) return fail_system(static_cast<std::uint32_t>(errno), "không mở được tệp log", text);
    UniqueHandle handle(encode_fd(fd));
    return std::make_unique<FileSink>(std::move(handle));
}

std::unique_ptr<LogSink> debugger_sink() {
    return std::make_unique<DebuggerSink>();
}

} // namespace game::core

#endif
