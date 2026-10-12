// Log của Forge2, thay ILog/Log.c/WindowsLog.c của _Ref, mạnh hơn log bất đồng bộ của VnS. Luồng
// gọi định dạng vào bộ đệm riêng của luồng rồi đặt chỗ trong một vòng đệm tĩnh 4 MiB bằng một CAS,
// không mutex, không cấp phát; luồng "log" của đối tượng Log xả ra các đích. Bộ đệm đầy: dòng dưới
// Error bị bỏ và đếm, Error chờ chỗ. Dòng dài hơn 64 KiB bị cắt đúng ký tự UTF-8. Chưa có Log thì
// ghi thẳng stderr. Crash (core/check.hpp) xả nốt vòng đệm trước khi ghi báo cáo. Sửa so với _Ref:
// lọc theo từng mức (gốc so mặt nạ toàn cục với cả mặt nạ nên lọt mức đã tắt); không in ngoài mutex
// nên các luồng không xen dòng; không bộ đệm 1 KiB cắt câm và tràn âm; std::format kiểm kiểu lúc
// dịch thay printf. Ghi log không bao giờ ném; gọi log từ trong sink hay formatter không tự khoá
// chết: lần lồng ra stderr kèm chuỗi định dạng gốc.
// Nguồn: Forge2 src/core/log.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; tham số của
// constructor Format và tham số at của LogHistory đổi tên (trùng tên trường, tên dưới ba ký tự).
#pragma once

#include "core/error.hpp"

#include <atomic>
#include <chrono>
#include <concepts>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <memory>
#include <mutex>
#include <ratio>
#include <source_location>
#include <span>
#include <string>
#include <string_view>
#include <type_traits>
#include <utility>
#include <vector>

namespace game::core {

// Raw ghi nguyên văn, không đầu dòng, không xuống dòng (RAW_LOGF của _Ref).
enum class Level : std::uint8_t {
    kRaw,
    kDebug,
    kInfo,
    kWarning,
    kError,
};

// Tập mức theo bit, như mặt nạ LogLevel của _Ref.
using LevelMask = std::uint8_t;

[[nodiscard]] constexpr LevelMask mask(Level level) noexcept {
    return static_cast<LevelMask>(1U << std::to_underlying(level));
}

// Mọi mức từ lowest tới Error; Raw chỉ có khi lowest là Raw.
[[nodiscard]] constexpr LevelMask at_least(Level lowest) noexcept {
    return static_cast<LevelMask>((mask(Level::kError) << 1U) - mask(lowest));
}

inline constexpr LevelMask kAllLevels = at_least(Level::kRaw);

enum class FileOpen : std::uint8_t {
    kTruncate,
    kAppend,
};

// Đích ghi. Luồng log gọi write và flush, mỗi lúc một luồng; dòng đã đủ đầu dòng và xuống dòng, chỉ
// sống trong lời gọi. Không được ghi log, tạo hay huỷ Log bên trong.
class LogSink {
public:
    virtual ~LogSink() = default;
    virtual void write(Level level, std::string_view line) noexcept = 0;
    virtual void flush() noexcept {}

    LogSink(const LogSink&) = delete;
    LogSink& operator=(const LogSink&) = delete;
    LogSink(LogSink&&) = delete;
    LogSink& operator=(LogSink&&) = delete;

protected:
    LogSink() = default;
};

// Auto tô màu khi đích là console thật hỗ trợ chuỗi VT; tệp và ống không bao giờ dính mã màu.
enum class Color : std::uint8_t {
    kOff,
    kAuto,
};

// Error ra stderr, mức khác ra stdout. Console thật thì WriteConsoleW, đúng Unicode dù code page
// nào và không đổi code page của tiến trình; chuyển hướng thì nguyên byte UTF-8. Handle hỏi lại mỗi
// lần ghi nên SetStdHandle, AllocConsole sau đó vẫn có tác dụng. Bật VT lúc tạo, trả chế độ cũ lúc
// huỷ.
[[nodiscard]] std::unique_ptr<LogSink> console_sink(Color color);

// Tệp log, ghi gộp tới 256 KiB mỗi lần WriteFile; mở chia sẻ đọc để xem được khi đang ghi. Thư mục
// cha được tạo nếu chưa có.
[[nodiscard]] Result<std::unique_ptr<LogSink>> file_sink(const std::filesystem::path& path, FileOpen open);

// OutputDebugStringW khi debugger đang gắn; _Ref gọi cho mọi dòng dù không có debugger.
[[nodiscard]] std::unique_ptr<LogSink> debugger_sink();

// Vòng đệm đầy: Drop bỏ dòng dưới Error và đếm (luồng chơi không chờ đĩa, như VnS và No1); Wait cho
// luồng gọi chờ chỗ, không mất dòng nào — cho công cụ và máy chủ cần log đủ hơn cần nhanh.
enum class Full : std::uint8_t {
    kDrop,
    kWait,
};

struct LogConfig {
    // Tệp log; rỗng thì không ghi tệp.
    std::filesystem::path file{};
    LevelMask levels = kAllLevels;
    FileOpen open = FileOpen::kTruncate;
    bool console = true;
    Color color = Color::kAuto;
    // Luồng log tự xả sau khoảng này dù chưa có Error và vòng đệm chưa đầy nửa.
    std::chrono::milliseconds flush_interval{200};
    Full full = Full::kDrop;
};

// Mỗi lúc một Log; tạo cái thứ hai khi cái trước còn sống là vi phạm hợp đồng. Huỷ thì xả hết rồi
// dừng luồng log. create trả lỗi khi không tạo được luồng, không ném system_error.
class Log {
public:
    // Chỉ Log dựng được Key, nên người ngoài không gọi constructor mà gọi create.
    class Key {
        friend class Log;
        Key() = default;
    };

    // make_unique có thể ném bad_alloc; hết bộ nhớ cho đối tượng Log thì không trả được Status.
    [[nodiscard]] static Result<std::unique_ptr<Log>> create(const LogConfig& config = {});

    explicit Log(Key);
    ~Log();
    Log(const Log&) = delete;
    Log& operator=(const Log&) = delete;
    Log(Log&&) = delete;
    Log& operator=(Log&&) = delete;

    // Thêm một tệp log (addLogFile của _Ref) qua file_sink.
    [[nodiscard]] Status add_file(const std::filesystem::path& path, LevelMask levels, FileOpen open);

    // Thêm đích ghi của người dùng (addLogCallback của _Ref); đích sống tới khi Log huỷ.
    void add_sink(LevelMask levels, std::unique_ptr<LogSink> sink);

    // Chờ mọi dòng gửi trước lời gọi này ra tới đích và đích đã flush.
    void flush();

    // Số dòng đã bỏ vì vòng đệm đầy, từ lúc tạo Log.
    [[nodiscard]] std::uint64_t dropped() const noexcept;

    struct State;

private:
    // Nhận chỗ duy nhất rồi mở. system_error thành Status; bad_alloc của make_unique vẫn ném.
    [[nodiscard]] Status open(const LogConfig& config);
    void prepare(const LogConfig& config);

    std::unique_ptr<State> state_;
};

// Mặt nạ lọc ở phía luồng gọi, trước khi định dạng. Log đặt nó lúc tạo; đổi được lúc chạy.
void set_log_levels(LevelMask levels) noexcept;
[[nodiscard]] LevelMask log_levels() noexcept;

// Ghi vào log hiện hành. noexcept chủ ý: formatter của người dùng ném hay hết bộ nhớ khi định dạng
// thì std::terminate, CrashGuard báo cáo kèm stack thay vì nuốt mất dòng log.
void emit(Level level, std::source_location where, std::string_view format, std::format_args args) noexcept;

// Cho trình báo crash: xả nốt vòng đệm rồi ghi báo cáo, không chờ khoá quá khoảng 100 ms; không
// được thì ghi thẳng stderr và debugger.
void emit_fatal(std::string_view report) noexcept;

// Chuỗi định dạng kèm vị trí gọi. consteval: chuỗi sai số tham số hay sai kiểu là lỗi biên dịch.
template <class... Args>
struct Format {
    template <class Text>
        requires std::convertible_to<const Text&, std::string_view>
    // Chuyển ngầm từ chuỗi là chủ ý: vị trí được bắt đúng ở chỗ gọi log (lệch API-04).
    // NOLINTNEXTLINE(cppcoreguidelines-explicit-constructor,misc-explicit-constructor)
    consteval Format(const Text& from, std::source_location place = std::source_location::current())
        : text(from), where(place) {}

    std::format_string<Args...> text;
    std::source_location where;
};

// Mỗi lần raw là một lần ghi riêng; luồng khác có thể chen giữa hai lần. Dựng đủ đoạn văn bản rồi
// gọi một lần (RAW_LOGF của _Ref từng byte một trong trình phân tích HID).
template <class... Args>
void raw(Format<std::type_identity_t<Args>...> format, const Args&... args) noexcept {
    emit(Level::kRaw, format.where, format.text.get(), std::make_format_args(args...));
}

template <class... Args>
void debug(Format<std::type_identity_t<Args>...> format, const Args&... args) noexcept {
    emit(Level::kDebug, format.where, format.text.get(), std::make_format_args(args...));
}

template <class... Args>
void info(Format<std::type_identity_t<Args>...> format, const Args&... args) noexcept {
    emit(Level::kInfo, format.where, format.text.get(), std::make_format_args(args...));
}

template <class... Args>
void warn(Format<std::type_identity_t<Args>...> format, const Args&... args) noexcept {
    emit(Level::kWarning, format.where, format.text.get(), std::make_format_args(args...));
}

template <class... Args>
void error(Format<std::type_identity_t<Args>...> format, const Args&... args) noexcept {
    emit(Level::kError, format.where, format.text.get(), std::make_format_args(args...));
}

// Vòng đệm byte cố định cho console trong trò chơi: giữ các dòng mới nhất, bỏ dòng cũ nhất khi đầy.
// Ghi không cấp phát; dòng dài hơn sức chứa giữ phần đầu, cắt đúng UTF-8. Hàm duyệt không được ghi
// log.
class LogHistory {
public:
    explicit LogHistory(std::size_t capacity);

    // Duyệt từ dòng cũ nhất tới mới nhất, dưới khoá của lịch sử.
    template <std::invocable<Level, std::string_view> Visit>
    void for_each(const Visit& visit) const;

    [[nodiscard]] std::size_t lines() const;
    [[nodiscard]] std::size_t bytes() const;
    [[nodiscard]] std::size_t capacity() const noexcept { return ring_.size(); }

    // Mức cao nhất kể từ lần mark_seen gần nhất; chưa có gì thì Raw. Gợi ý cho UI nháy biểu tượng.
    [[nodiscard]] Level unseen() const noexcept { return unseen_.load(); }
    void mark_seen() noexcept { unseen_.store(Level::kRaw); }

    void append(Level level, std::string_view line) noexcept;

private:
    using Visitor = void (*)(Level level, std::string_view line, const void* user);

    void visit_all(Visitor visit, const void* user) const;
    void evict_oldest() noexcept;
    void put(std::size_t position, std::span<const char> data) noexcept;
    void get(std::size_t position, std::span<char> out) const noexcept;
    [[nodiscard]] std::uint32_t length_at(std::size_t position) const noexcept;

    // Bảo vệ mọi trường dưới đây trừ unseen_.
    mutable std::mutex mutex_;
    // Bản ghi [u32 độ dài][u8 mức][byte]; dữ liệu ở [head_, head_ + used_) quấn quanh ring_.
    std::vector<char> ring_;
    std::size_t head_ = 0;
    std::size_t used_ = 0;
    std::size_t count_ = 0;
    std::atomic<Level> unseen_ = Level::kRaw;
};

template <std::invocable<Level, std::string_view> Visit>
void LogHistory::for_each(const Visit& visit) const {
    const auto call = [](Level level, std::string_view line, const void* user) {
        (*static_cast<const Visit*>(user))(level, line);
    };
    visit_all(call, std::addressof(visit));
}

[[nodiscard]] std::unique_ptr<LogSink> history_sink(LogHistory& history);

// "512 B", "1.5 KiB" — humanReadableSize của _Ref, cơ số 1024, thêm PiB và EiB cho int64 đủ dải.
[[nodiscard]] std::string human_size(std::int64_t bytes);

// "1.5 µs", "2 min" — humanReadableTime của _Ref. Gốc sai hai bậc: ns lên thẳng "ms" khi chia
// 1000, và giây lên phút cũng chia 1000.
[[nodiscard]] std::string human_time(std::chrono::duration<double, std::nano> time);

} // namespace game::core
