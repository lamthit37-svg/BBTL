// Ca chạy exe phụ thật (thienlong_test_child): đường dẫn có dấu cách; đối số có dấu cách, nháy và
// chữ có dấu; dòng đúng trần và quá trần; hạn chờ; con lờ stdin bị buộc dừng; huỷ đối tượng không
// để lại tiến trình; đóng ống thì con tự thoát; lệnh kiểu kCommand thấy stdin rỗng và gộp stderr.
#include "core/check.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "process/process.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using game::core::Result;
using game::process::Child;
using game::process::ExitStatus;
using game::process::Line;
using game::process::LineKind;
using game::process::Mode;
using game::process::Spawn;
using game::process::WaitKind;
using Arguments = std::span<const std::string_view>;

// Hạn cho một bước của con ngoan; máy bận dưới ASan vẫn xong trong hạn này.
constexpr std::chrono::seconds kPatience{5};

[[nodiscard]] std::string child_path() {
    const std::filesystem::path path = io::executable_directory() / "thienlong_test_child.exe";
    return io::utf8_of(path);
}

[[nodiscard]] Result<Child> start(Arguments arguments, Mode mode = Mode::kService) {
    const std::string exe = child_path();
    const Spawn request{.executable = exe, .arguments = arguments, .mode = mode};
    return process::spawn(request);
}

// Dòng chữ kế tiếp của con; rỗng và ghi một kỳ vọng sai khi con không trả dòng chữ.
[[nodiscard]] std::string next_text(Context& context, Child& child) {
    const Result<Line> line = child.read_line(kPatience);
    const bool is_text = line.has_value() && line->kind == LineKind::kText;
    context.expect(is_text, "con trả một dòng chữ");
    return is_text ? line->text : std::string{};
}

[[nodiscard]] std::optional<LineKind> next_kind(Child& child, std::chrono::milliseconds limit) {
    const Result<Line> line = child.read_line(limit);
    if (!line) return std::nullopt;
    return line->kind;
}

[[nodiscard]] std::optional<int> exit_code(Child& child) {
    const ExitStatus status = child.wait_for(kPatience);
    if (status.kind != WaitKind::kExited) return std::nullopt;
    return status.code;
}

void split_keeps_spaces_quotes_slashes(Context& context) {
    const std::string_view command = R"(prog "hello world" "say \"hi\"" "C:\thu\\" a\b "")";
    const std::vector<std::string> pieces = process::split_command_line(command);
    context.expect(pieces.size() == 6, "đủ sáu mảnh");
    if (pieces.size() != 6) return;
    context.expect(pieces[0] == "prog", "mảnh tên");
    context.expect(pieces[1] == "hello world", "mảnh có dấu cách");
    context.expect(pieces[2] == R"(say "hi")", "mảnh có dấu nháy");
    context.expect(pieces[3] == R"(C:\thu\)", "mảnh kết thúc bằng chéo");
    context.expect(pieces[4] == R"(a\b)", "chéo không đứng trước nháy giữ nguyên");
    context.expect(pieces[5].empty(), "cặp nháy rỗng là một đối số rỗng");
}

void spawn_path_with_space_prints_ready(Context& context) {
    context.expect(child_path().contains(' '), "đường dẫn exe có dấu cách");
    Result<Child> child = start({});
    context.expect(child.has_value(), "chạy được exe có dấu cách trong đường dẫn");
    if (!child) return;
    context.expect(next_text(context, *child) == "ready", "con in ready");
}

// Các ca của test quote_arg ở Dev, kiểm bằng cả chuyến đi tới tiến trình con thay vì so chuỗi.
constexpr std::array<std::string_view, 6> kSentArguments{
    "hello world",
    R"(say "hi")",
    R"(ab\"c)",
    R"(C:\thu\)",
    "tiếng Việt có dấu",
    "",
};

void arguments_arrive_unchanged(Context& context) {
    Result<Child> child = start(kSentArguments);
    context.expect(child.has_value(), "chạy được với đối số có dấu cách, nháy và chữ có dấu");
    if (!child) return;
    context.expect(next_text(context, *child) == "arg hello world", "đối số có dấu cách");
    context.expect(next_text(context, *child) == R"(arg say "hi")", "đối số có dấu nháy");
    context.expect(next_text(context, *child) == R"(arg ab\"c)", "chéo đứng ngay trước nháy");
    context.expect(next_text(context, *child) == R"(arg C:\thu\)", "đối số kết thúc bằng chéo");
    context.expect(next_text(context, *child) == "arg tiếng Việt có dấu", "đối số UTF-8");
    context.expect(next_text(context, *child) == "arg ", "đối số rỗng");
    context.expect(next_text(context, *child) == "ready", "sau đối số vẫn ready");
}

void bad_argument_is_refused(Context& context) {
    constexpr std::array<std::string_view, 1> kZero{std::string_view{"a\0b", 3}};
    const Result<Child> cut = start(kZero);
    const bool is_refused = !cut && cut.error().code() == core::ErrorCode::kInvalidArgument;
    context.expect(is_refused, "đối số có byte 0 bị từ chối");
    constexpr std::array<std::string_view, 1> kBroken{"\xC3\x28"};
    context.expect(!start(kBroken).has_value(), "đối số không phải UTF-8 bị từ chối");
    const Spawn missing{.executable = "khong-co-exe-nay.exe", .arguments = {}};
    context.expect(!process::spawn(missing).has_value(), "exe không có thì báo lỗi");
}

void line_at_ceiling_is_kept(Context& context) {
    constexpr std::array<std::string_view, 2> kFlags{"--line-size", "4096"};
    Result<Child> child = start(kFlags);
    context.expect(child.has_value(), "chạy được con in dòng đúng trần");
    if (!child) return;
    context.expect(next_text(context, *child).size() == process::kLineCeiling, "đủ 4096 byte");
    context.expect(next_text(context, *child) == "ready", "sau dòng đúng trần vẫn ready");
}

void line_over_ceiling_is_error(Context& context) {
    constexpr std::array<std::string_view, 2> kFlags{"--line-size", "4097"};
    Result<Child> child = start(kFlags);
    context.expect(child.has_value(), "chạy được con in dòng quá trần");
    if (!child) return;
    context.expect(next_kind(*child, kPatience) == LineKind::kTooLong, "dòng quá 4 KiB là lỗi");
}

void read_times_out_then_gets_delayed_ready(Context& context) {
    constexpr std::array<std::string_view, 2> kFlags{"--ready-after-ms", "600"};
    Result<Child> child = start(kFlags);
    context.expect(child.has_value(), "chạy được con ready trễ");
    if (!child) return;
    const std::optional<LineKind> early = next_kind(*child, std::chrono::milliseconds{50});
    context.expect(early == LineKind::kTimeout, "chưa tới hạn thì hết giờ");
    context.expect(next_text(context, *child) == "ready", "chờ tiếp thì nhận ready");
}

void last_line_before_exit_is_returned(Context& context) {
    constexpr std::array<std::string_view, 2> kFlags{"--exit-code", "3"};
    Result<Child> child = start(kFlags);
    context.expect(child.has_value(), "chạy được con thoát ngay sau ready");
    if (!child) return;
    context.expect(exit_code(*child) == 3, "nhận đúng mã thoát");
    context.expect(next_text(context, *child) == "ready", "dòng in trước khi thoát vẫn đọc được");
    context.expect(next_kind(*child, kPatience) == LineKind::kClosed, "hết dòng thì báo đã đóng");
    context.expect(child->try_wait() == 3, "hỏi lại vẫn cùng mã thoát");
}

void closing_input_stops_child(Context& context) {
    Result<Child> child = start({});
    context.expect(child.has_value(), "chạy được con ngoan");
    if (!child) return;
    context.expect(next_text(context, *child) == "ready", "con in ready");
    context.expect(!child->try_wait().has_value(), "ống còn mở thì con còn chạy");
    child->close_input();
    context.expect(exit_code(*child) == 0, "đóng ống thì con tự thoát mã 0");
}

void command_sees_empty_input(Context& context) {
    Result<Child> child = start({}, Mode::kCommand);
    context.expect(child.has_value(), "chạy được lệnh kiểu kCommand");
    if (!child) return;
    context.expect(exit_code(*child) == 0, "stdin rỗng là yêu cầu dừng: lệnh tự thoát mã 0");
    context.expect(next_text(context, *child) == "ready", "stdout của lệnh vẫn đọc được");
}

void command_merges_error_stream(Context& context) {
    constexpr std::array<std::string_view, 1> kFlags{"--stderr-line"};
    Result<Child> child = start(kFlags, Mode::kCommand);
    context.expect(child.has_value(), "chạy được lệnh in ra stderr");
    if (!child) return;
    context.expect(next_text(context, *child) == "dòng stderr của con", "stderr đi vào ống stdout");
    context.expect(next_text(context, *child) == "ready", "rồi tới stdout");
}

void ignore_stdin_is_forced_within_deadline(Context& context) {
    constexpr std::array<std::string_view, 1> kFlags{"--ignore-stdin"};
    Result<Child> child = start(kFlags);
    context.expect(child.has_value(), "chạy được con lờ stdin");
    if (!child) return;
    const std::uint32_t id = child->id();
    child->close_input();
    const ExitStatus waited = child->wait_for(std::chrono::milliseconds{300});
    context.expect(waited.kind == WaitKind::kTimeout, "con lờ stdin không tự thoát");
    context.expect(process::process_alive(id), "con vẫn sống sau hạn chờ");
    const auto before = std::chrono::steady_clock::now();
    child->force_stop();
    const auto elapsed = std::chrono::steady_clock::now() - before;
    context.expect(!process::process_alive(id), "buộc dừng thì con không còn");
    context.expect(elapsed < kPatience, "buộc dừng trả về trong hạn");
    context.expect(child->try_wait().has_value(), "sau buộc dừng có mã thoát");
}

void destructor_leaves_no_process(Context& context) {
    constexpr std::array<std::string_view, 1> kFlags{"--ignore-stdin"};
    std::uint32_t id = 0;
    {
        const Result<Child> child = start(kFlags);
        context.expect(child.has_value(), "chạy được con để huỷ đối tượng");
        if (!child) return;
        id = child->id();
        context.expect(process::process_alive(id), "con sống trước khi huỷ");
    }
    context.expect(!process::process_alive(id), "huỷ đối tượng không để lại tiến trình");
}

void moved_child_keeps_process(Context& context) {
    Result<Child> first = start({});
    context.expect(first.has_value(), "chạy được con để chuyển chủ");
    if (!first) return;
    const std::uint32_t id = first->id();
    Child second = std::move(*first);
    context.expect(second.id() == id, "chủ mới giữ đúng tiến trình");
    context.expect(process::process_alive(id), "chuyển chủ không dừng con");
    second.close_input();
    context.expect(exit_code(second) == 0, "chủ mới dừng được con");
}

constexpr std::array kCases{
    Case{.name = "split_keeps_spaces_quotes_slashes", .body = &split_keeps_spaces_quotes_slashes},
    Case{.name = "spawn_path_with_space_prints_ready", .body = &spawn_path_with_space_prints_ready},
    Case{.name = "arguments_arrive_unchanged", .body = &arguments_arrive_unchanged},
    Case{.name = "bad_argument_is_refused", .body = &bad_argument_is_refused},
    Case{.name = "line_at_ceiling_is_kept", .body = &line_at_ceiling_is_kept},
    Case{.name = "line_over_ceiling_is_error", .body = &line_over_ceiling_is_error},
    Case{.name = "read_times_out_then_gets_delayed_ready", .body = &read_times_out_then_gets_delayed_ready},
    Case{.name = "last_line_before_exit_is_returned", .body = &last_line_before_exit_is_returned},
    Case{.name = "closing_input_stops_child", .body = &closing_input_stops_child},
    Case{.name = "command_sees_empty_input", .body = &command_sees_empty_input},
    Case{.name = "command_merges_error_stream", .body = &command_merges_error_stream},
    Case{.name = "ignore_stdin_is_forced_within_deadline", .body = &ignore_stdin_is_forced_within_deadline},
    Case{.name = "destructor_leaves_no_process", .body = &destructor_leaves_no_process},
    Case{.name = "moved_child_keeps_process", .body = &moved_child_keeps_process},
};

} // namespace
} // namespace game::test

int main() {
    const bool passed = game::test::run_all(game::test::kCases) == 0;
    game::core::check(passed, "process_tests");
    return 0;
}
