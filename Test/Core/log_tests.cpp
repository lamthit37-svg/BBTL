// Test của log và luồng trong core: dòng log đi qua vòng đệm và luồng "log" tới đích ghi, mặt nạ
// mức lọc trước khi định dạng, LogHistory giữ các dòng mới nhất, chờ trên địa chỉ có hạn, luồng có
// tên. Mã được kiểm chép từ Forge2; các ca ở đây chạy đường thật (có luồng log) sau khi thân các
// vòng lặp của nó đổi hình dạng cho qua cổng. Chỉ dựng trên Windows như phần .cpp của core.
// Ca tám luồng dùng Full::kWait và không ngủ: mỗi mã dòng-T-N phải tới đúng một lần. Ca xanh không
// chứng minh hết race — máy này không chạy được TSan.
#include "core/check.hpp"
#include "core/error.hpp"
#include "core/log.hpp"
#include "core/thread.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <ratio>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using Lines = std::vector<std::string>;

// Đích ghi giữ lại mọi dòng; ca test đọc sau khi Log đã huỷ (luồng log đã dừng).
class CaptureSink final : public core::LogSink {
public:
    explicit CaptureSink(Lines& lines) noexcept : lines_(&lines) {}

    // Hết bộ nhớ trong test thì dừng tiến trình (LH-07).
    // NOLINTNEXTLINE(bugprone-exception-escape)
    void write(core::Level /*level*/, std::string_view line) noexcept override { lines_->emplace_back(line); }

private:
    Lines* lines_;
};

[[nodiscard]] bool has_line(const Lines& lines, std::string_view part) {
    const auto holds = [part](const std::string& line) { return line.contains(part); };
    return std::ranges::any_of(lines, holds);
}

// Các ca dưới không noexcept: cấp phát và định dạng có thể ném; ném thì tiến trình dừng.
void log_delivers_lines_to_sinks(Context& context) {
    Lines lines;
    {
        core::LogConfig config;
        config.console = false;
        core::Result<std::unique_ptr<core::Log>> opened = core::Log::create(config);
        context.expect(opened.has_value(), "tạo được log");
        if (!opened) return;
        const std::unique_ptr<core::Log> log = std::move(*opened);
        log->add_sink(core::kAllLevels, std::make_unique<CaptureSink>(lines));
        core::info("xin chào {}", 7);
        core::error("hỏng {}", "tệp");
        log->flush();
    }
    context.expect(has_line(lines, " TIN "), "dòng mức tin có nhãn TIN");
    context.expect(has_line(lines, "xin chào 7"), "tham số được định dạng vào dòng");
    context.expect(has_line(lines, " LỖI "), "dòng mức lỗi có nhãn LỖI");
    context.expect(has_line(lines, "hỏng tệp"), "dòng lỗi tới đích");
    context.expect(has_line(lines, "log_tests.cpp:"), "đầu dòng có tệp và số dòng của nơi gọi");
    context.expect(has_line(lines, "Đóng log"), "dòng cuối lúc huỷ Log cũng tới đích");
}

void log_filters_levels_before_formatting(Context& context) {
    Lines lines;
    {
        core::LogConfig config;
        config.console = false;
        core::Result<std::unique_ptr<core::Log>> opened = core::Log::create(config);
        context.expect(opened.has_value(), "tạo được log");
        if (!opened) return;
        const std::unique_ptr<core::Log> log = std::move(*opened);
        log->add_sink(core::kAllLevels, std::make_unique<CaptureSink>(lines));
        core::set_log_levels(core::at_least(core::Level::kWarning));
        core::info("dòng bị lọc");
        core::warn("cảnh báo còn lại");
    }
    context.expect(!has_line(lines, "dòng bị lọc"), "mức dưới mặt nạ không tới đích");
    context.expect(has_line(lines, "cảnh báo còn lại"), "mức trong mặt nạ tới đích");
    context.expect(core::log_levels() == core::kAllLevels, "huỷ Log trả mặt nạ về mọi mức");
}

void log_history_keeps_newest_lines(Context& context) {
    // Mỗi bản ghi tốn 5 byte đầu cộng nội dung: ba dòng 10 byte cần 45 byte, vòng chỉ có 40.
    core::LogHistory history(40);
    history.append(core::Level::kInfo, "aaaaaaaaaa");
    history.append(core::Level::kWarning, "bbbbbbbbbb");
    history.append(core::Level::kInfo, "cccccccccc");
    Lines kept;
    const auto collect = [&kept](core::Level, std::string_view line) { kept.emplace_back(line); };
    history.for_each(collect);
    context.expect(history.lines() == 2, "dòng cũ nhất bị bỏ khi vòng đầy");
    context.expect(history.bytes() == 30, "hai bản ghi 15 byte còn lại");
    context.expect(kept == Lines{"bbbbbbbbbb", "cccccccccc"}, "duyệt từ cũ tới mới");
    context.expect(history.unseen() == core::Level::kWarning, "mức cao nhất chưa xem");
    history.mark_seen();
    context.expect(history.unseen() == core::Level::kRaw, "đánh dấu đã xem");
}

void log_formats_sizes_and_times(Context& context) {
    using Nanoseconds = std::chrono::duration<double, std::nano>;
    context.expect(core::human_size(512) == "512 B", "dưới 1 KiB in số byte");
    context.expect(core::human_size(1536) == "1.5 KiB", "cơ số 1024, bỏ số 0 thừa");
    context.expect(core::human_time(Nanoseconds(1500.0)) == "1.5 µs", "nano lên micro");
    context.expect(core::human_time(Nanoseconds(120.0e9)) == "2 min", "giây lên phút chia 60");
}

void thread_parks_until_value_differs_or_timeout(Context& context) noexcept {
    const std::atomic<std::uint32_t> value{0};
    const bool differs = core::park(value, std::uint32_t{1}, std::chrono::milliseconds(50));
    context.expect(differs, "giá trị đã khác old thì trả về ngay, không tính là hết hạn");
    const bool timed_out = !core::park(value, std::uint32_t{0}, std::chrono::milliseconds(5));
    context.expect(timed_out, "giá trị không đổi và không ai đánh thức thì hết hạn");
}

// Tên mà thân luồng thấy; trả về sau khi luồng đã chạy xong.
[[nodiscard]] std::string name_seen_by_worker() {
    std::string seen;
    core::ThreadConfig config;
    config.name = "thử";
    const auto body = [&seen](const std::stop_token&) { seen = core::thread_name(); };
    std::jthread worker = core::start_thread(std::move(config), body);
    worker.join();
    return seen;
}

void thread_runs_named_body(Context& context) {
    context.expect(name_seen_by_worker() == "thử", "thân luồng thấy tên đã đặt");
    context.expect(core::is_main_thread(), "ca test chạy trên luồng chính");
    context.expect(core::cpu_count() >= 1, "luôn có ít nhất một CPU");
    context.expect(core::performance_cpus().any(), "tập lõi hiệu năng không rỗng");
}

constexpr int kProducers = 8;
constexpr int kLinesEach = 200;
constexpr int kExpectedLines = kProducers * kLinesEach;
constexpr std::string_view kCodeMark = "dòng-";

struct LineTally {
    std::array<std::uint8_t, kExpectedLines> hits{};
    int data_lines = 0;
    bool well_formed = true;
};

struct ParsedCode {
    int thread_index = 0;
    int line_index = 0;
    bool is_valid = false;
};

using Producers = std::array<std::jthread, kProducers>;

[[nodiscard]] int digit_value(char digit) noexcept {
    if (digit < '0' || digit > '9') return -1;
    return static_cast<int>(digit) - static_cast<int>('0');
}

[[nodiscard]] int two_digits(std::string_view pair) noexcept {
    if (pair.size() != 2) return -1;
    const int tens = digit_value(pair.front());
    const int ones = digit_value(pair.back());
    if (tens < 0 || ones < 0) return -1;
    return (tens * 10) + ones;
}

[[nodiscard]] int line_number(std::string_view number) noexcept {
    if (number.size() == 1) return digit_value(number.front());
    if (number.size() == 2) return two_digits(number);
    if (number.size() != 3) return -1;
    const int hundreds = digit_value(number.front());
    number.remove_prefix(1);
    const int rest = two_digits(number);
    if (hundreds < 0 || rest < 0) return -1;
    return (hundreds * 100) + rest;
}

// Khớp hết hậu tố T-N, không lấy tiền tố.
[[nodiscard]] ParsedCode parse_code(std::string_view code) noexcept {
    const std::size_t dash = code.find('-');
    const std::size_t newline = code.find('\n');
    const bool shape = dash == 1 && newline != std::string_view::npos && newline + 1 == code.size();
    if (!shape) return {};
    const int thread_index = digit_value(code.front());
    code.remove_prefix(2);
    code.remove_suffix(1);
    const int line_index = line_number(code);
    if (thread_index < 0 || line_index < 0) return {};
    return {.thread_index = thread_index, .line_index = line_index, .is_valid = true};
}

void note_logged_line(LineTally& tally, std::string_view line) {
    if (line.contains("Đóng log")) return;
    tally.data_lines += 1;
    const std::size_t mark = line.rfind(kCodeMark);
    if (mark == std::string_view::npos) {
        tally.well_formed = false;
        return;
    }
    const ParsedCode parsed = parse_code(line.substr(mark + kCodeMark.size()));
    const bool in_range = parsed.is_valid && parsed.thread_index >= 0 && parsed.thread_index < kProducers &&
        parsed.line_index >= 0 && parsed.line_index < kLinesEach;
    if (!in_range) {
        tally.well_formed = false;
        return;
    }
    const int slot = (parsed.thread_index * kLinesEach) + parsed.line_index;
    std::uint8_t& hit = tally.hits.at(static_cast<std::size_t>(slot));
    if (hit != 0) {
        tally.well_formed = false;
        return;
    }
    hit = 1;
}

void tally_lines(LineTally& tally, const Lines& lines) {
    for (const std::string& line : lines) {
        note_logged_line(tally, line);
    }
}

[[nodiscard]] bool every_code_once(const LineTally& tally) noexcept {
    if (!tally.well_formed) return false;
    const auto once = [](std::uint8_t hit) { return hit == std::uint8_t{1}; };
    return std::ranges::all_of(tally.hits, once);
}

void emit_producer_lines(int thread_index) noexcept {
    for (int line_index = 0; line_index < kLinesEach; ++line_index) {
        core::info("dòng-{}-{}", thread_index, line_index);
    }
}

void launch_producer(std::jthread& worker, int thread_index) {
    const auto body = [thread_index] noexcept { emit_producer_lines(thread_index); };
    worker = std::jthread(body);
}

void launch_producers(Producers& workers) {
    for (int thread_index = 0; thread_index < kProducers; ++thread_index) {
        launch_producer(workers.at(static_cast<std::size_t>(thread_index)), thread_index);
    }
}

void join_producers(Producers& workers) {
    for (std::jthread& worker : workers) {
        worker.join();
    }
}

// Full::kWait, không ngủ: mất hoặc nhân một mã thì đỏ.
void log_eight_threads_keep_every_line(Context& context) {
    Lines lines;
    {
        core::LogConfig config;
        config.console = false;
        config.full = core::Full::kWait;
        core::Result<std::unique_ptr<core::Log>> opened = core::Log::create(config);
        context.expect(opened.has_value(), "tạo được log");
        if (!opened) return;
        const std::unique_ptr<core::Log> log = std::move(*opened);
        log->add_sink(core::kAllLevels, std::make_unique<CaptureSink>(lines));
        Producers workers;
        launch_producers(workers);
        join_producers(workers);
        log->flush();
    }
    LineTally tally;
    tally_lines(tally, lines);
    context.expect(tally.data_lines == kExpectedLines, "trừ đóng log còn đúng 8*200 dòng");
    context.expect(every_code_once(tally), "mỗi mã dòng-T-N đúng một lần");
}

constexpr std::array kCases{
    Case{.name = "log_delivers_lines_to_sinks", .body = &log_delivers_lines_to_sinks},
    Case{.name = "log_filters_levels_before_formatting", .body = &log_filters_levels_before_formatting},
    Case{.name = "log_history_keeps_newest_lines", .body = &log_history_keeps_newest_lines},
    Case{.name = "log_formats_sizes_and_times", .body = &log_formats_sizes_and_times},
    Case{.name = "thread_parks_until_value_differs_or_timeout", .body = &thread_parks_until_value_differs_or_timeout},
    Case{.name = "thread_runs_named_body", .body = &thread_runs_named_body},
    Case{.name = "log_eight_threads_keep_every_line", .body = &log_eight_threads_keep_every_line},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "log_tests: mọi ca phải qua");
    return 0;
}
