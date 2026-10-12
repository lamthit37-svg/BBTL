// Exe phụ cho process_tests: đóng vai một tiến trình con ngoan hoặc hư. Không cài.
// Mặc định: in `ready`, chờ yêu cầu dừng bằng chính process::stop_requested mà tiến trình máy chủ
// thật dùng, rồi thoát 0. Đối số không bắt đầu bằng `--` được in lại thành dòng `arg <chữ>`.
// Cờ: --line-size <n> in một dòng n byte trước ready; --stderr-line in một dòng ra stderr;
// --ready-after-ms <n> in ready trễ; --never-ready không in ready; --exit-code <n> thoát mã n ngay
// sau ready; --ignore-stdin không bao giờ tự thoát.
#include "core/number.hpp"
#include "process/process.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdio>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

namespace {

constexpr int kLineMost = 8192;

struct Options {
    std::vector<std::string> echoed;
    std::optional<int> line_size;
    std::optional<int> ready_delay_ms;
    std::optional<int> exit_code;
    bool prints_ready = true;
    bool ignores_stop = false;
    bool writes_error = false;
    bool is_valid = true;
};

struct Toggle {
    std::string_view flag;
    bool Options::* field = nullptr;
    bool value = false;
};

struct Valued {
    std::string_view flag;
    std::optional<int> Options::* field = nullptr;
};

constexpr std::array<Toggle, 3> kToggles{{
    {.flag = "--never-ready", .field = &Options::prints_ready, .value = false},
    {.flag = "--ignore-stdin", .field = &Options::ignores_stop, .value = true},
    {.flag = "--stderr-line", .field = &Options::writes_error, .value = true},
}};

constexpr std::array<Valued, 3> kValued{{
    {.flag = "--line-size", .field = &Options::line_size},
    {.flag = "--ready-after-ms", .field = &Options::ready_delay_ms},
    {.flag = "--exit-code", .field = &Options::exit_code},
}};

struct Cursor {
    std::span<const std::string> arguments;
    std::size_t index = 0;
};

[[nodiscard]] std::optional<int> take_number(Cursor& cursor) noexcept {
    if (cursor.index + 1 >= cursor.arguments.size()) return std::nullopt;
    ++cursor.index;
    return game::core::parse_whole_int(cursor.arguments[cursor.index]);
}

void take_valued(Options& options, Cursor& cursor, std::string_view word) {
    const auto valued = std::ranges::find(kValued, word, &Valued::flag);
    const bool is_known = valued != kValued.end();
    const std::optional<int> number = is_known ? take_number(cursor) : std::nullopt;
    options.is_valid = options.is_valid && number.has_value();
    if (number) options.*(valued->field) = number;
}

void take_word(Options& options, Cursor& cursor) {
    const std::string_view word = cursor.arguments[cursor.index];
    if (!word.starts_with("--")) {
        options.echoed.emplace_back(word);
        return;
    }
    const auto toggle = std::ranges::find(kToggles, word, &Toggle::flag);
    if (toggle == kToggles.end()) {
        take_valued(options, cursor, word);
        return;
    }
    options.*(toggle->field) = toggle->value;
}

[[nodiscard]] Options parse(std::span<const std::string> arguments) {
    Options options;
    Cursor cursor{.arguments = arguments};
    while (cursor.index < arguments.size()) {
        take_word(options, cursor);
        ++cursor.index;
    }
    const int size = options.line_size.value_or(0);
    options.is_valid = options.is_valid && size <= kLineMost;
    return options;
}

void print_preamble(const Options& options) {
    for (const std::string& text : options.echoed) {
        std::println("arg {}", text);
    }
    const auto size = static_cast<std::size_t>(options.line_size.value_or(0));
    if (options.line_size) std::println("{}", std::string(size, 'B'));
    if (options.writes_error) std::println(stderr, "dòng stderr của con");
    static_cast<void>(std::fflush(stdout));
}

void print_ready(const Options& options) {
    if (!options.prints_ready) return;
    std::this_thread::sleep_for(std::chrono::milliseconds{options.ready_delay_ms.value_or(0)});
    std::println("ready");
    static_cast<void>(std::fflush(stdout));
}

void sleep_forever() {
    while (true) {
        std::this_thread::sleep_for(std::chrono::seconds{1});
    }
}

void wait_for_stop() {
    while (!game::process::stop_requested()) {
        std::this_thread::sleep_for(std::chrono::milliseconds{10});
    }
}

} // namespace

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
int main(const int argc, const char* const* const argv) {
    game::process::watch_stop_signals();
    const std::vector<std::string> arguments = game::process::utf8_arguments(argc, argv);
    const Options options = parse(arguments);
    if (!options.is_valid) return 2;
    print_preamble(options);
    print_ready(options);
    if (options.exit_code) return *options.exit_code;
    if (options.ignores_stop) sleep_forever();
    wait_for_stop();
    return 0;
}
