// Phần không phụ thuộc hệ điều hành: vòng đọc một dòng và phép tách dòng lệnh.
// Tách dòng lệnh theo quy tắc CommandLineToArgvW, cùng một quy tắc ở mọi nền tảng để test không
// cần Windows. Nguồn: TLBB Dev console.cpp và quote_arg của process_win32.cpp @e0d89a6.
// Khác gốc: tự tách, không gọi CommandLineToArgvW.
#include "process/process.hpp"

#include "core/error.hpp"
#include "process/detail/child_state.hpp"
#include "process/detail/line_buffer.hpp"

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::process {
namespace {

using Clock = std::chrono::steady_clock;
using Milliseconds = std::chrono::milliseconds;

// Đọc dòng.
struct Reading {
    bool done = false;
    Line line;
    std::optional<std::uint32_t> failure;
};

void accept(detail::ChildState& state, detail::Feed fed, Reading& reading) {
    if (fed.kind == detail::FeedKind::kNeedMore) return;
    reading.done = true;
    if (fed.kind == detail::FeedKind::kTooLong) {
        state.pending.clear();
        reading.line.kind = LineKind::kTooLong;
        return;
    }
    state.pending = std::move(fed.rest);
    reading.line.kind = LineKind::kText;
    reading.line.text = std::move(fed.line);
}

// pending có thể đang giữ trọn một dòng đọc dư từ lần trước.
void drain_pending(detail::ChildState& state, Reading& reading) {
    if (state.pending.empty()) return;
    const std::string held = std::exchange(state.pending, {});
    accept(state, detail::feed(state.pending, held, state.held_cr), reading);
}

void take_chunk(detail::ChildState& state, detail::Chunk chunk, Reading& reading) {
    if (chunk.kind == detail::ChunkKind::kBytes) {
        accept(state, detail::feed(state.pending, chunk.bytes, state.held_cr), reading);
        return;
    }
    reading.done = true;
    reading.line.kind = LineKind::kClosed;
    if (chunk.kind == detail::ChunkKind::kFailed) reading.failure = chunk.system;
}

[[nodiscard]] Milliseconds time_left(Clock::time_point deadline) noexcept {
    const auto left = std::chrono::duration_cast<Milliseconds>(deadline - Clock::now());
    return std::max(left, Milliseconds{0});
}

void pump(detail::ChildState& state, Reading& reading, Clock::time_point deadline) {
    drain_pending(state, reading);
    if (reading.done) return;
    // Hỏi "đã thoát" trước khi đọc: con in dòng cuối rồi thoát thì dòng đó vẫn được trả.
    const bool exited = detail::exited_now(state);
    detail::Chunk chunk = detail::read_available(state);
    const bool is_empty = chunk.kind == detail::ChunkKind::kEmpty;
    if (is_empty && exited) chunk.kind = detail::ChunkKind::kClosed;
    if (chunk.kind != detail::ChunkKind::kEmpty) {
        take_chunk(state, std::move(chunk), reading);
        return;
    }
    detail::pause(state, time_left(deadline));
}

// Tách dòng lệnh.
struct CommandParse {
    std::string_view text;
    std::size_t index = 0;
    std::string current;
    std::vector<std::string> arguments;
    bool is_quoted = false;
    bool has_started = false;
};

[[nodiscard]] bool ended(const CommandParse& parse) noexcept {
    return parse.index >= parse.text.size();
}

[[nodiscard]] char peek(const CommandParse& parse) noexcept {
    return parse.text[parse.index];
}

[[nodiscard]] bool is_gap(char byte) noexcept {
    return byte == ' ' || byte == '\t';
}

void skip_gaps(CommandParse& parse) noexcept {
    while (!ended(parse) && is_gap(peek(parse))) {
        ++parse.index;
    }
}

[[nodiscard]] std::size_t count_slashes(CommandParse& parse) noexcept {
    const std::size_t first = parse.index;
    const std::size_t stop = parse.text.find_first_not_of('\\', first);
    parse.index = stop == std::string_view::npos ? parse.text.size() : stop;
    return parse.index - first;
}

// Dãy `\` đứng trước `"`: mỗi cặp thành một `\`, lẻ một thì `"` là chữ. Không có `"` thì giữ
// nguyên.
void take_mark(CommandParse& parse) {
    const std::size_t slashes = count_slashes(parse);
    const bool is_quote = !ended(parse) && peek(parse) == '"';
    parse.has_started = true;
    if (!is_quote) {
        parse.current.append(slashes, '\\');
        return;
    }
    parse.current.append(slashes / 2, '\\');
    ++parse.index;
    const bool is_escaped = slashes % 2 == 1;
    if (is_escaped) parse.current.push_back('"');
    if (!is_escaped) parse.is_quoted = !parse.is_quoted;
}

// false khi gặp khoảng trắng ngoài nháy: đối số kết thúc.
[[nodiscard]] bool take_byte(CommandParse& parse) {
    const char byte = peek(parse);
    if (!parse.is_quoted && is_gap(byte)) return false;
    if (byte == '\\' || byte == '"') {
        take_mark(parse);
        return true;
    }
    parse.current.push_back(byte);
    parse.has_started = true;
    ++parse.index;
    return true;
}

void take_argument(CommandParse& parse) {
    skip_gaps(parse);
    parse.is_quoted = false;
    parse.has_started = false;
    bool is_inside = true;
    while (is_inside && !ended(parse)) {
        is_inside = take_byte(parse);
    }
    if (!parse.has_started) return;
    parse.arguments.push_back(std::exchange(parse.current, {}));
}

} // namespace

core::Result<Line> Child::read_line(std::chrono::milliseconds limit) {
    if (!*this) return core::fail(core::ErrorCode::kInvalidState, "không có tiến trình để đọc");
    Reading reading;
    const Clock::time_point deadline = Clock::now() + limit;
    pump(*state_, reading, deadline);
    while (!reading.done && Clock::now() < deadline) {
        pump(*state_, reading, deadline);
    }
    if (reading.failure) return core::fail_system(*reading.failure, "không đọc được ống của con");
    return std::move(reading.line);
}

std::vector<std::string> split_command_line(std::string_view command) {
    CommandParse parse;
    parse.text = command;
    while (!ended(parse)) {
        take_argument(parse);
    }
    return std::move(parse.arguments);
}

} // namespace game::process
