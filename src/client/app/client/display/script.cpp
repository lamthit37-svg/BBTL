/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/script.cpp
 *  PHÂN HỆ   : Client / Display / Script
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc tệp kịch bản E2E thành danh sách bước (display/script.hpp). Mỗi lệnh
 *    có một hàm đọc đối số; sai là trả câu lỗi, cả kịch bản bị từ chối.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/script.hpp"

#include "core/number.hpp"

#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::client {
namespace {

// Rỗng là đọc được; có giá trị là lý do (chưa kèm số dòng).
using Fault = std::optional<std::string>;

constexpr std::size_t kMostSteps = 4096;
// Số khung tối đa của một bước wait N, để gõ nhầm số không treo cả lần chạy.
constexpr double kMostWaitFrames = 1.0e7;
constexpr double kPlayWaitSeconds = 90.0;

[[nodiscard]] std::string_view trim(std::string_view text) noexcept {
    const std::size_t first = text.find_first_not_of(" \t\r");
    if (first == std::string_view::npos) return {};
    const std::size_t last = text.find_last_not_of(" \t\r");
    return text.substr(first, last - first + 1);
}

[[nodiscard]] bool is_whole(double value) noexcept {
    return std::isfinite(value) && std::floor(value) == value;
}

// Số thực chiếm trọn text, hữu hạn; "3", "2.5" đều nhận.
[[nodiscard]] std::optional<double> whole_number(std::string_view text) noexcept {
    const core::OptionalDouble parsed = core::parse_double(text);
    if (!parsed || parsed->length != text.size()) return std::nullopt;
    if (!std::isfinite(parsed->value)) return std::nullopt;
    return parsed->value;
}

Fault read_text(Step& step, std::string_view rest) {
    const std::string_view text = trim(rest);
    if (text.empty()) return "thiếu đối số";
    step.text = std::string(text);
    return std::nullopt;
}

Fault read_word(Step& step, std::string_view rest) {
    const std::string_view text = trim(rest);
    if (text.empty()) return "thiếu đối số";
    if (text.find_first_of(" \t") != std::string_view::npos) return "đối số phải là một từ";
    step.text = std::string(text);
    return std::nullopt;
}

[[nodiscard]] bool is_name_char(char letter) noexcept {
    const bool is_alpha = (letter >= 'a' && letter <= 'z') || (letter >= 'A' && letter <= 'Z');
    const bool is_digit = letter >= '0' && letter <= '9';
    return is_alpha || is_digit || letter == '_' || letter == '-' || letter == '.';
}

// Tên ảnh thành tên tệp trong thư mục --shot-dir: không dấu phân cách đường dẫn.
Fault read_shot(Step& step, std::string_view rest) {
    const std::string_view text = trim(rest);
    if (text.empty()) return "thiếu tên ảnh";
    for (const char letter : text) {
        if (!is_name_char(letter)) return "tên ảnh chỉ gồm chữ, số, _ - .";
    }
    step.text = std::string(text);
    return std::nullopt;
}

Fault read_event(Step& step, std::string_view rest) {
    Fault fault = read_text(step, rest);
    if (fault) return fault;
    if (step.text.front() == '|') return "sự kiện thiếu tên";
    return std::nullopt;
}

[[nodiscard]] std::optional<char> escaped(char letter) noexcept {
    if (letter == 'n') return '\r';
    if (letter == 't') return '\t';
    if (letter == 'b') return '\b';
    if (letter == '\\') return '\\';
    return std::nullopt;
}

// Ký tự kế tiếp của chữ gõ, đã đổi dấu \ ; cursor tiến qua phần đã đọc.
[[nodiscard]] std::optional<char> take_char(std::string_view text, std::size_t& cursor) {
    const char letter = text[cursor];
    ++cursor;
    if (letter != '\\') return letter;
    if (cursor >= text.size()) return std::nullopt;
    const char next = text[cursor];
    ++cursor;
    return escaped(next);
}

[[nodiscard]] std::optional<std::string> unescape(std::string_view text) {
    std::string out;
    std::size_t cursor = 0;
    while (cursor < text.size()) {
        const std::optional<char> one = take_char(text, cursor);
        if (!one) return std::nullopt;
        out.push_back(*one);
    }
    return out;
}

// Chữ gõ giữ nguyên dấu cách hai đầu (chỉ bỏ dấu cách ngăn lệnh); \n là Enter (13), \t là Tab, \b
// xoá lùi.
Fault read_typed(Step& step, std::string_view rest) {
    if (rest.empty()) return "thiếu chữ cần gõ";
    std::optional<std::string> text = unescape(rest);
    if (!text) return "dấu \\ chỉ đi với n, t, b, \\";
    step.text = std::move(*text);
    return std::nullopt;
}

[[nodiscard]] std::optional<Coord> coord_of(std::string_view text) {
    const std::string_view word = trim(text);
    if (word.empty()) return std::nullopt;
    const bool is_relative = word.front() == '+' || word.front() == '-';
    const std::string_view digits = word.front() == '+' ? word.substr(1) : word;
    const core::OptionalDouble parsed = core::parse_double(digits);
    if (!parsed || parsed->length != digits.size()) return std::nullopt;
    if (!std::isfinite(parsed->value)) return std::nullopt;
    const auto value = static_cast<float>(parsed->value);
    return Coord{.value = value, .is_relative = is_relative};
}

Fault read_walk(Step& step, std::string_view rest) {
    const std::size_t comma = rest.find(',');
    if (comma == std::string_view::npos) return "walk cần dạng x,z";
    const std::optional<Coord> across = coord_of(rest.substr(0, comma));
    const std::optional<Coord> down = coord_of(rest.substr(comma + 1));
    if (!across || !down) return "toạ độ phải là số";
    // Một trong hai số có dấu thì cả cặp là cộng dồn từ chỗ đứng: "+4,0" đi 4 m theo x, "0,+4" đi 4
    // m theo z. Không dấu cả hai là toạ độ tuyệt đối của game (mét).
    const bool is_relative = across->is_relative || down->is_relative;
    step.x = *across;
    step.z = *down;
    step.x.is_relative = is_relative;
    step.z.is_relative = is_relative;
    return std::nullopt;
}

Fault read_wait_play(Step& step, std::string_view rest) {
    step.kind = StepKind::kWaitPlay;
    step.amount = kPlayWaitSeconds;
    const std::string_view text = trim(rest);
    if (text.empty()) return std::nullopt;
    const std::optional<double> seconds = whole_number(text);
    if (!seconds || *seconds <= 0.0) return "số giây không hợp lệ";
    step.amount = *seconds;
    return std::nullopt;
}

// "N" là N khung; "Ns" là N giây.
Fault read_wait_time(Step& step, std::string_view text) {
    const bool is_seconds = text.ends_with('s');
    const std::string_view digits = is_seconds ? text.substr(0, text.size() - 1) : text;
    const std::optional<double> value = whole_number(digits);
    if (!value) return "wait cần số khung, số giây (3s) hay play";
    step.amount = *value;
    if (is_seconds && *value <= 0.0) return "số giây phải dương";
    if (is_seconds) return std::nullopt;
    const bool is_frames = is_whole(*value) && *value >= 1.0;
    if (!is_frames) return "số khung phải là số nguyên dương";
    if (*value > kMostWaitFrames) return "số khung quá lớn";
    return std::nullopt;
}

Fault read_wait(Step& step, std::string_view rest) {
    const std::string_view text = trim(rest);
    if (text.starts_with("play")) return read_wait_play(step, text.substr(4));
    const bool is_seconds = text.ends_with('s');
    step.kind = is_seconds ? StepKind::kWaitSeconds : StepKind::kWait;
    return read_wait_time(step, text);
}

// Thứ tự từ 1 như người chơi đếm (lựa chọn của hộp thoại, ô kỹ năng).
Fault read_index(Step& step, std::string_view rest) {
    const std::optional<int> whole = core::parse_whole_int(trim(rest));
    if (!whole || *whole < 1) return "cần số nguyên từ 1";
    step.amount = *whole;
    return std::nullopt;
}

Fault read_none(Step& /*step*/, std::string_view rest) {
    if (!trim(rest).empty()) return "lệnh này không nhận đối số";
    return std::nullopt;
}

struct Verb {
    std::string_view name;
    StepKind kind = StepKind::kQuit;
    Fault (*read)(Step& step, std::string_view rest) = nullptr;
};

constexpr std::array<Verb, 11> kVerbs{{
    {.name = "wait", .kind = StepKind::kWait, .read = &read_wait},
    {.name = "shot", .kind = StepKind::kShot, .read = &read_shot},
    {.name = "event", .kind = StepKind::kEvent, .read = &read_event},
    {.name = "click", .kind = StepKind::kClick, .read = &read_word},
    {.name = "type", .kind = StepKind::kType, .read = &read_typed},
    {.name = "walk", .kind = StepKind::kWalk, .read = &read_walk},
    {.name = "talk", .kind = StepKind::kTalk, .read = &read_text},
    {.name = "choose", .kind = StepKind::kChoose, .read = &read_index},
    {.name = "cast", .kind = StepKind::kCast, .read = &read_index},
    {.name = "pick", .kind = StepKind::kPick, .read = &read_none},
    {.name = "quit", .kind = StepKind::kQuit, .read = &read_none},
}};

[[nodiscard]] const Verb* find_verb(std::string_view name) noexcept {
    for (const Verb& verb : kVerbs) {
        if (verb.name == name) return &verb;
    }
    return nullptr;
}

struct Split {
    std::string_view verb;
    std::string_view rest;
};

// Lệnh là từ đầu; đối số là phần sau đúng một ký tự ngăn (type cần giữ nguyên dấu cách của chữ gõ).
[[nodiscard]] Split split_verb(std::string_view line) noexcept {
    const std::size_t gap = line.find_first_of(" \t");
    if (gap == std::string_view::npos) return {.verb = line, .rest = {}};
    return {.verb = line.substr(0, gap), .rest = line.substr(gap + 1)};
}

// Một dòng của tệp: thêm bước nếu có. Dòng trống và chú thích không thêm gì.
Fault read_line(ScriptSteps& steps, std::uint32_t number, std::string_view raw) {
    std::string_view line = raw;
    while (line.ends_with('\r'))
        line.remove_suffix(1);
    const std::size_t first = line.find_first_not_of(" \t");
    if (first == std::string_view::npos) return std::nullopt;
    line.remove_prefix(first);
    if (line.front() == '#') return std::nullopt;
    if (steps.size() >= kMostSteps) return "quá nhiều bước";
    const Split parts = split_verb(line);
    const Verb* verb = find_verb(parts.verb);
    if (verb == nullptr) return std::format("lệnh lạ: {}", parts.verb);
    Step step;
    step.kind = verb->kind;
    step.line = number;
    Fault fault = verb->read(step, parts.rest);
    if (fault) return fault;
    steps.push_back(std::move(step));
    return std::nullopt;
}

[[nodiscard]] std::string located(std::uint32_t number, const std::string& why) {
    return std::format("dòng {}: {}", number, why);
}

} // namespace

ScriptResult parse_script(std::string_view text) {
    ScriptSteps steps;
    std::uint32_t number = 0;
    while (!text.empty()) {
        const std::size_t end = text.find('\n');
        const std::string_view raw = text.substr(0, end);
        text = end == std::string_view::npos ? std::string_view{} : text.substr(end + 1);
        ++number;
        Fault fault = read_line(steps, number, raw);
        if (!fault) continue;
        std::string message = located(number, *fault);
        return std::unexpected(std::move(message));
    }
    return steps;
}

std::string_view name_of(StepKind kind) noexcept {
    for (const Verb& verb : kVerbs) {
        if (verb.kind == kind) return verb.name;
    }
    if (kind == StepKind::kWaitSeconds || kind == StepKind::kWaitPlay) return "wait";
    return "?";
}

} // namespace game::client
