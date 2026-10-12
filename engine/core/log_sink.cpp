// Các đích ghi của log và LogHistory. Chạy trên luồng log (hay luồng đang flush, đang báo crash),
// mỗi lúc một luồng, nên đích không tự khoá — trừ LogHistory, vì UI đọc nó từ luồng khác.
// So với _Ref: tệp ghi gộp 256 KiB mỗi lần WriteFile thay vì fwrite+fflush từng dòng; console đúng
// Unicode không cần đổi code page; debugger chỉ khi đang gắn.
// Nguồn: Forge2 src/core/log_sink.cpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; macro của
// windows.h lấy từ core/win32.hpp (gốc khai ở CMake); header con của Win32 include trực tiếp; tham
// số và biến tên at đổi thành position, cursor; struct Step ra khỏi thân human_time; handle cục bộ
// viết auto* const; lệnh return kèm lời gọi hàm void tách làm hai.
#include "core/error.hpp"
#include "core/handle.hpp"
#include "core/log.hpp"
#include "core/text.hpp"
#if defined(_WIN32)
#include "core/win32.hpp" // IWYU pragma: keep

#include <consoleapi.h>
#include <debugapi.h>
#include <errhandlingapi.h>
#include <fileapi.h>
#include <handleapi.h>
#include <processenv.h>
#include <winbase.h>
#include <winnt.h>
#endif

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <format>
#include <memory>
#include <mutex>
#include <ratio>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>

namespace game::core {

namespace {

#if defined(_WIN32)

constexpr std::size_t kFileBuffer = std::size_t{256} << 10U;
constexpr std::string_view kColorReset = "\x1b[0m";

// Màu theo mức; rỗng là không tô.
constexpr auto kColors = std::to_array<std::string_view>({
    "",
    "\x1b[90m",
    "",
    "\x1b[33m",
    "\x1b[91m",
});

void write_bytes(HANDLE handle, std::string_view bytes) noexcept {
    DWORD written = 0;
    WriteFile(handle, bytes.data(), static_cast<DWORD>(bytes.size()), &written, nullptr);
}

// Console nhớ chế độ cũ của stdout và stderr để trả lại khi huỷ.
struct ConsoleMode {
    HANDLE handle = nullptr;
    DWORD original = 0;
    bool changed = false;
};

[[nodiscard]] ConsoleMode enable_vt(DWORD which) noexcept {
    auto* const handle = GetStdHandle(which);
    DWORD mode = 0;
    if (GetConsoleMode(handle, &mode) == 0) return {};
    if ((mode & ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0) return {};
    const bool changed = SetConsoleMode(handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0;
    return ConsoleMode{.handle = handle, .original = mode, .changed = changed};
}

void restore(const ConsoleMode& mode) noexcept {
    if (mode.changed) SetConsoleMode(mode.handle, mode.original);
}

class ConsoleSink final : public LogSink {
public:
    explicit ConsoleSink(Color color) noexcept : color_(color) {
        if (color_ == Color::kOff) return;
        out_ = enable_vt(STD_OUTPUT_HANDLE);
        err_ = enable_vt(STD_ERROR_HANDLE);
    }

    ~ConsoleSink() override {
        restore(out_);
        restore(err_);
    }

    ConsoleSink(const ConsoleSink&) = delete;
    ConsoleSink& operator=(const ConsoleSink&) = delete;
    ConsoleSink(ConsoleSink&&) = delete;
    ConsoleSink& operator=(ConsoleSink&&) = delete;

    // noexcept theo hợp đồng của LogSink: hết bộ nhớ khi tô màu hay đổi mã là std::terminate
    // (LH-07). NOLINTNEXTLINE(bugprone-exception-escape)
    void write(Level level, std::string_view line) noexcept override {
        const DWORD which = level == Level::kError ? STD_ERROR_HANDLE : STD_OUTPUT_HANDLE;
        auto* const handle = GetStdHandle(which);
        if (handle == nullptr || handle == INVALID_HANDLE_VALUE) return;
        DWORD mode = 0;
        if (GetConsoleMode(handle, &mode) == 0) {
            write_bytes(handle, line);
            return;
        }
        const bool has_vt = (mode & ENABLE_VIRTUAL_TERMINAL_PROCESSING) != 0;
        const std::string_view color = kColors.at(std::to_underlying(level));
        const bool paint = color_ == Color::kAuto && has_vt && !color.empty();
        write_console(handle, paint ? painted(color, line) : std::string(line));
    }

private:
    // Màu bọc phần thân, '\n' đứng sau mã trả màu để dòng kế không dính màu.
    // Mã màu và nội dung dòng: hai vai khác hẳn, nơi gọi duy nhất ở ngay trên (lệch API-03).
    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters)
    [[nodiscard]] static std::string painted(std::string_view color, std::string_view line) {
        const bool newline = line.ends_with('\n');
        const std::string_view body = newline ? line.substr(0, line.size() - 1) : line;
        return std::format("{}{}{}{}", color, body, kColorReset, newline ? "\n" : "");
    }

    static void write_console(HANDLE handle, std::string_view text) {
        const std::wstring wide = widen(text);
        DWORD written = 0;
        WriteConsoleW(handle, wide.data(), static_cast<DWORD>(wide.size()), &written, nullptr);
    }

    Color color_;
    ConsoleMode out_{};
    ConsoleMode err_{};
};

// Gộp dòng tới 256 KiB rồi một lần WriteFile; flush của luồng log mỗi lượt xả đẩy phần còn lại.
class FileSink final : public LogSink {
public:
    explicit FileSink(UniqueHandle file) : file_(std::move(file)) { buffer_.reserve(kFileBuffer); }

    ~FileSink() override { FileSink::flush(); }

    FileSink(const FileSink&) = delete;
    FileSink& operator=(const FileSink&) = delete;
    FileSink(FileSink&&) = delete;
    FileSink& operator=(FileSink&&) = delete;

    // Xả trước khi nối: bộ đệm không bao giờ vượt chỗ đã giữ, nên sink không cấp phát sau lúc tạo —
    // nó chạy cả trên đường báo crash, khi heap có thể đã hỏng. Dòng dài hơn cả bộ đệm ghi thẳng.
    // append không vượt chỗ đã reserve nên không cấp phát; clang-tidy không thấy điều đó (LH-07).
    // NOLINTNEXTLINE(bugprone-exception-escape)
    void write([[maybe_unused]] Level level, std::string_view line) noexcept override {
        if (buffer_.size() + line.size() > kFileBuffer) flush();
        if (line.size() > kFileBuffer) {
            write_bytes(file_.get(), line);
            return;
        }
        buffer_.append(line);
    }

    void flush() noexcept override {
        if (buffer_.empty()) return;
        write_bytes(file_.get(), buffer_);
        buffer_.clear();
    }

private:
    UniqueHandle file_;
    std::string buffer_;
};

class DebuggerSink final : public LogSink {
public:
    void write([[maybe_unused]] Level level, std::string_view line) noexcept override {
        if (IsDebuggerPresent() == FALSE) return;
        OutputDebugStringW(widen(line).c_str());
    }
};

#endif

class HistorySink final : public LogSink {
public:
    explicit HistorySink(LogHistory& history) noexcept : history_(history) {}

    void write(Level level, std::string_view line) noexcept override { history_.append(level, line); }

private:
    LogHistory& history_;
};

// Bản ghi của LogHistory: [u32 độ dài][u8 mức][byte].
constexpr std::size_t kHistoryHeader = sizeof(std::uint32_t) + 1;

// Bỏ các số 0 thừa sau dấu thập phân: "1.50" thành "1.5", "2.00" thành "2".
[[nodiscard]] std::string trimmed(double value, int decimals) {
    std::string text = std::format("{:.{}f}", value, decimals);
    if (!text.contains('.')) return text;
    text.erase(text.find_last_not_of('0') + 1);
    if (text.back() == '.') text.pop_back();
    return text;
}

// Khoảng ba chữ số có nghĩa, như humanReadableTime của _Ref.
[[nodiscard]] int decimals_for(double value) {
    const double size = std::abs(value);
    if (size < 10.0) return 2;
    return size < 100.0 ? 1 : 0;
}

} // namespace

#if defined(_WIN32)

std::unique_ptr<LogSink> console_sink(Color color) {
    return std::make_unique<ConsoleSink>(color);
}

Result<std::unique_ptr<LogSink>> file_sink(const std::filesystem::path& path, FileOpen open) {
    std::error_code ignored;
    std::filesystem::create_directories(path.parent_path(), ignored);
    const bool append = open == FileOpen::kAppend;
    const DWORD access = append ? FILE_APPEND_DATA : GENERIC_WRITE;
    const DWORD disposition = append ? OPEN_ALWAYS : CREATE_ALWAYS;
    const DWORD share = FILE_SHARE_READ | FILE_SHARE_DELETE;
    const wchar_t* file_name = path.c_str();
    const DWORD flags = FILE_ATTRIBUTE_NORMAL;
    UniqueHandle file(CreateFileW(file_name, access, share, nullptr, disposition, flags, nullptr));
    if (!file) return fail_system(GetLastError(), "không mở được tệp log", narrow(path.native()));
    return std::unique_ptr<LogSink>(std::make_unique<FileSink>(std::move(file)));
}

std::unique_ptr<LogSink> debugger_sink() {
    return std::make_unique<DebuggerSink>();
}

#endif

std::unique_ptr<LogSink> history_sink(LogHistory& history) {
    return std::make_unique<HistorySink>(history);
}

// LogHistory

LogHistory::LogHistory(std::size_t capacity) : ring_(capacity) {}

std::size_t LogHistory::lines() const {
    const std::scoped_lock lock(mutex_);
    return count_;
}

std::size_t LogHistory::bytes() const {
    const std::scoped_lock lock(mutex_);
    return used_;
}

// Chép data vào vòng tại position, tách hai đoạn khi vắt qua cuối.
void LogHistory::put(std::size_t position, std::span<const char> data) noexcept {
    const std::span<char> ring(ring_);
    const std::size_t start = position % ring.size();
    const std::size_t first = std::min(data.size(), ring.size() - start);
    std::ranges::copy(data.first(first), ring.subspan(start).begin());
    std::ranges::copy(data.subspan(first), ring.begin());
}

void LogHistory::get(std::size_t position, std::span<char> out) const noexcept {
    const std::span<const char> ring(ring_);
    const std::size_t start = position % ring.size();
    const std::size_t first = std::min(out.size(), ring.size() - start);
    std::ranges::copy(ring.subspan(start, first), out.begin());
    std::ranges::copy(ring.first(out.size() - first), out.subspan(first).begin());
}

[[nodiscard]] std::uint32_t LogHistory::length_at(std::size_t position) const noexcept {
    std::array<char, sizeof(std::uint32_t)> bytes{};
    get(position, bytes);
    std::uint32_t length = 0;
    std::memcpy(&length, bytes.data(), sizeof(length));
    return length;
}

void LogHistory::evict_oldest() noexcept {
    const std::size_t size = kHistoryHeader + length_at(head_);
    head_ = (head_ + size) % ring_.size();
    used_ -= size;
    --count_;
}

void LogHistory::append(Level level, std::string_view line) noexcept {
    if (ring_.size() <= kHistoryHeader) return;
    const std::string_view kept = utf8_prefix(line, ring_.size() - kHistoryHeader);
    const std::size_t need = kHistoryHeader + kept.size();
    std::array<char, kHistoryHeader> header{};
    const auto length = static_cast<std::uint32_t>(kept.size());
    std::memcpy(header.data(), &length, sizeof(length));
    header.back() = static_cast<char>(std::to_underlying(level));
    const std::scoped_lock lock(mutex_);
    while (used_ + need > ring_.size()) {
        evict_oldest();
    }
    put(head_ + used_, header);
    put(head_ + used_ + kHistoryHeader, kept);
    used_ += need;
    ++count_;
    Level seen = unseen_.load();
    while (level > seen && !unseen_.compare_exchange_weak(seen, level)) {
    }
}

// Mỗi dòng chép vào bộ đệm của luồng đọc (dùng lại, không cấp phát sau lần đầu), vì dòng có thể vắt
// qua cuối vòng.
void LogHistory::visit_all(Visitor visit, const void* user) const {
    thread_local std::string joined;
    const std::scoped_lock lock(mutex_);
    std::size_t cursor = head_;
    for (std::size_t i = 0; i < count_; ++i) {
        const std::uint32_t length = length_at(cursor);
        std::array<char, 1> level{};
        get(cursor + sizeof(std::uint32_t), level);
        joined.resize(length);
        get(cursor + kHistoryHeader, joined);
        visit(static_cast<Level>(level.front()), joined, user);
        cursor += kHistoryHeader + length;
    }
}

// Định dạng cho người đọc

std::string human_size(std::int64_t bytes) {
    constexpr auto kUnits = std::to_array<std::string_view>({"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"});
    auto value = static_cast<double>(bytes);
    std::size_t unit = 0;
    while (std::abs(value) >= 1024.0 && unit + 1 < kUnits.size()) {
        value /= 1024.0;
        ++unit;
    }
    const int decimals = unit == 0 ? 0 : 1;
    return std::format("{} {}", trimmed(value, decimals), kUnits.at(unit));
}

namespace {

// Hệ số đổi sang đơn vị kế tiếp; 0 là đơn vị cuối.
struct Step {
    std::string_view unit;
    double next = 0.0;
};

} // namespace

std::string human_time(std::chrono::duration<double, std::nano> time) {
    constexpr auto kSteps = std::to_array<Step>({
        {.unit = "ns", .next = 1000.0},
        {.unit = "µs", .next = 1000.0},
        {.unit = "ms", .next = 1000.0},
        {.unit = "s", .next = 60.0},
        {.unit = "min", .next = 60.0},
        {.unit = "h", .next = 24.0},
        {.unit = "d", .next = 0.0},
    });
    double value = time.count();
    std::size_t step = 0;
    while (kSteps.at(step).next > 0.0 && std::abs(value) >= kSteps.at(step).next) {
        value /= kSteps.at(step).next;
        ++step;
    }
    return std::format("{} {}", trimmed(value, decimals_for(value)), kSteps.at(step).unit);
}

} // namespace game::core
