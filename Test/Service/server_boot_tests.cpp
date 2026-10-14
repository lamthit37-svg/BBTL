// Chạy trình giám sát thật với bảy exe thật và cấu hình thật, không PostgreSQL: stdin đóng sẵn thì
// đủ 13 dòng rồi thoát 0; ống còn mở thì cụm đứng yên tới khi đóng; stdin rỗng cũng dừng; cấu hình
// sai thì in hết lỗi, thoát 2 và không chạy tiến trình nào; cụm quá nhiều tiến trình cũng vậy; dòng
// lệnh sai thoát 2.
// Cụm chạy trên một bản chép của cấu hình thật, mọi cổng nghe là 127.0.0.1:0
// (support/loopback_config.hpp), và dòng ready của cụm mang cổng thật của gate; các ca chỉ chờ mã
// thoát 2 dùng thẳng cấu hình thật vì không tiến trình nào kịp nghe cổng.
#include "core/check.hpp"
#include "core/error.hpp"
#include "core/number.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "process/process.hpp"
#include "support/gate_key.hpp"
#include "support/loopback_config.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <fstream>
#include <ios>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
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
using Lines = std::vector<std::string>;
using Path = std::filesystem::path;

#ifdef GAME_SERVER_CONFIG
constexpr std::string_view kConfigDir = GAME_SERVER_CONFIG;
#else
// check.py dịch tệp này không có định nghĩa của CMake; đường dẫn từ gốc dự án để tệp tự đứng được.
constexpr std::string_view kConfigDir = "dev/server/config";
#endif

// Hạn cho một bước của cụm; bản ASan khởi động bảy tiến trình chậm hơn bản phát hành nhiều lần.
constexpr std::chrono::seconds kPatience{30};

constexpr std::array<std::string_view, 6> kStartLines{
    "started store 0",
    "started auth 0",
    "started billing 0",
    "started world 0",
    "started zone 0",
    "started gate",
};

// Dòng ready của cụm và khoá cần tìm trong nó; hai chuỗi cùng kiểu nên đi theo tên.
struct PortAsk {
    std::string_view line;
    std::string_view key;
};

// Cổng của một khoá trong dòng ready của cụm (`ready gate.game=<cổng> ...`); rỗng khi thiếu khoá
// hoặc số không nằm trong 1..65535.
[[nodiscard]] std::optional<std::uint16_t> cluster_port(const PortAsk& ask) {
    const std::string needle = std::format(" {}=", ask.key);
    const std::size_t found = ask.line.find(needle);
    if (found == std::string_view::npos) return std::nullopt;
    const std::string_view rest = ask.line.substr(found + needle.size());
    const std::optional<int> value = core::parse_whole_int(rest.substr(0, rest.find(' ')));
    if (!value || *value < 1 || *value > 65535) return std::nullopt;
    return static_cast<std::uint16_t>(*value);
}

// Dòng sẵn sàng của cụm: `ready` kèm hai cổng thật, khác nhau, của gate (zone báo thêm cổng ipc của nó,
// bốn tiến trình còn lại chưa mở cổng nào nên chưa báo gì).
[[nodiscard]] bool is_cluster_ready(std::string_view line) {
    const std::optional<std::uint16_t> game = cluster_port({.line = line, .key = "gate.game"});
    const std::optional<std::uint16_t> auth = cluster_port({.line = line, .key = "gate.auth"});
    return line.starts_with("ready ") && game && auth && *game != *auth;
}

constexpr std::array<std::string_view, 6> kStopLines{
    "stopped gate",
    "stopped zone 0",
    "stopped world 0",
    "stopped billing 0",
    "stopped auth 0",
    "stopped store 0",
};

[[nodiscard]] Result<Child> start(std::string_view program, Arguments arguments, Mode mode) {
    const Path path = io::executable_directory() / io::path_from_utf8(program);
    const std::string exe = io::utf8_of(path);
    const Spawn request{.executable = exe, .arguments = arguments, .mode = mode};
    return process::spawn(request);
}

// Dòng chữ kế tiếp; rỗng khi con đã đóng stdout hoặc quá hạn.
[[nodiscard]] std::optional<std::string> next_text(Child& child) {
    Result<Line> line = child.read_line(kPatience);
    const bool is_text = line.has_value() && line->kind == LineKind::kText;
    if (!is_text) return std::nullopt;
    return std::move(line->text);
}

[[nodiscard]] Lines take_lines(Child& child, std::size_t most) {
    Lines lines;
    std::optional<std::string> text = next_text(child);
    while (text && lines.size() < most) {
        lines.push_back(std::move(*text));
        text = lines.size() < most ? next_text(child) : std::nullopt;
    }
    return lines;
}

[[nodiscard]] std::optional<int> exit_code(Child& child) {
    const ExitStatus status = child.wait_for(kPatience);
    if (status.kind != WaitKind::kExited) return std::nullopt;
    return status.code;
}

struct Finished {
    Lines lines;
    std::optional<int> code;
};

// Chạy tới khi tiến trình thoát. kCommand gộp stderr vào các dòng trả về.
[[nodiscard]] Finished run_to_end(std::string_view program, Arguments arguments, Mode mode) {
    Finished finished;
    Result<Child> child = start(program, arguments, mode);
    if (!child) return finished;
    child->close_input();
    finished.lines = take_lines(*child, 64);
    finished.code = exit_code(*child);
    return finished;
}

[[nodiscard]] bool has_line_with(const Lines& lines, std::string_view piece) {
    const auto holds = [&](const std::string& line) { return line.contains(piece); };
    return std::ranges::any_of(lines, holds);
}

// Dòng stderr mà cấu hình test (support/loopback_config.hpp: không chép *.local.toml, mọi cổng ipc là 0)
// in ra khi stderr gộp vào (Mode::kCommand): so nguyên dòng, mỗi dòng tối đa một lần. Hai dòng của auth và store
// chỉ có ở bản dựng có libpq (GAME_HAS_LIBPQ); bản không có libpq (gcc-debug) không in chúng, nên vắng là hợp lệ.
constexpr std::array<std::string_view, 5> kExpectedNoise{
    "auth: chưa có secrets.local.toml, bỏ qua database", // account/serve.cpp:296
    "store: chưa có secrets.local.toml, bỏ qua database", // account/serve.cpp:364
    "gate: cổng ipc của auth hoặc store là 0, đăng ký trả bận", // gate/front.cpp:540 (ở 4e22b54)
    "gate: cổng ipc của zone là 0, không nối thế giới", // gate/front.cpp open_zone
    "zone: cổng ipc của store là 0, không ghi được điểm đứng", // zone/serve.cpp run
};

// Dòng báo tick của gate (gate/front.cpp report: mỗi giây một lần, tám cặp khoá=số, số đổi theo máy). Có hay
// không tuỳ cụm sống quá một giây, nên được 0..n lần; khoá phải đúng thứ tự, giá trị phải là số thập phân.
[[nodiscard]] bool is_tick_report(std::string_view line) {
    constexpr std::string_view kHead = "gate: tick ";
    constexpr std::array<std::string_view, 8> kKeys{
        "p99_us", "max_us", "late", "conn", "accept_us", "pump_us", "advance_us", "flush_us"};
    if (!line.starts_with(kHead)) return false;
    line.remove_prefix(kHead.size());
    bool first = true;
    for (const std::string_view key : kKeys) {
        if (!first && !line.starts_with(' ')) return false;
        if (!first) line.remove_prefix(1);
        first = false;
        if (!line.starts_with(key)) return false;
        line.remove_prefix(key.size());
        if (!line.starts_with('=')) return false;
        line.remove_prefix(1);
        const std::size_t end = line.find_first_not_of("0123456789");
        const std::size_t digits = end == std::string_view::npos ? line.size() : end;
        if (digits == 0) return false;
        line.remove_prefix(digits);
    }
    return line.empty();
}

// Bỏ các dòng expected (mỗi dòng phải có đúng một lần) và dòng báo tick; dòng khác giữ lại, nên một dòng lạ
// làm hỏng phép đếm 13 dòng. nullopt khi một dòng expected lặp.
[[nodiscard]] std::optional<Lines> cycle_lines(const Lines& lines, std::span<const std::string_view> expected) {
    for (const std::string_view want : expected) {
        if (std::ranges::count(lines, want) > 1) return std::nullopt;
    }
    Lines kept;
    for (const std::string& line : lines) {
        const bool is_expected = std::ranges::find(expected, std::string_view{line}) != expected.end();
        if (!is_expected && !is_tick_report(line)) kept.push_back(line);
    }
    return kept;
}

void expect_full_cycle(Context& context, const Finished& finished, std::span<const std::string_view> noise) {
    context.expect(finished.code == 0, "giám sát thoát 0");
    const std::optional<Lines> cycle = cycle_lines(finished.lines, noise);
    context.expect(cycle.has_value(), "mỗi dòng stderr chờ đợi có tối đa một lần");
    if (!cycle) {
        // Đỏ thì in nguyên các dòng nhận được: không thấy chúng thì không biết dòng nào thiếu hay lặp.
        for (const std::string& line : finished.lines) std::println(stderr, "  dòng nhận được: {}", line);
        return;
    }
    const std::span<const std::string> lines{*cycle};
    context.expect(lines.size() == 13, "đủ 13 dòng");
    if (lines.size() != 13) return;
    context.expect(std::ranges::equal(lines.first(6), kStartLines), "sáu dòng started đúng thứ tự");
    context.expect(is_cluster_ready(lines[6]), "rồi dòng ready mang hai cổng thật của gate");
    context.expect(std::ranges::equal(lines.last(6), kStopLines), "sáu dòng dừng ngược thứ tự");
}

// Thư mục cấu hình tạm của một ca: bản chép mới của cấu hình thật, mọi cổng nghe là 127.0.0.1:0,
// kèm khoá danh tính sinh trong cây dựng. Rỗng, và ca bị ghi lỗi, khi một bước hỏng.
[[nodiscard]] std::optional<std::string> loopback_config(Context& context) {
    const std::optional<Path> staged = stage_config(io::path_from_utf8(kConfigDir), "server-boot");
    context.expect(staged.has_value(), "dựng được cấu hình tạm nghe loopback");
    if (!staged) return std::nullopt;
    std::string dir = io::utf8_of(*staged);
    const bool has_key = ensure_gate_identity(dir);
    context.expect(has_key, "có khoá danh tính của gate");
    if (!has_key) return std::nullopt;
    return dir;
}

void closed_input_runs_full_cycle(Context& context) {
    const std::optional<std::string> config = loopback_config(context);
    if (!config) return;
    const std::array<std::string_view, 3> arguments{"--config", *config, "--no-postgres"};
    expect_full_cycle(context, run_to_end("thienlong_server.exe", arguments, Mode::kService), {});
}

// stdin là thiết bị rỗng (chạy với `< NUL`): đọc là hết dòng ngay, cũng là yêu cầu dừng.
void empty_input_runs_full_cycle(Context& context) {
    const std::optional<std::string> config = loopback_config(context);
    if (!config) return;
    const std::array<std::string_view, 3> arguments{"--config", *config, "--no-postgres"};
    expect_full_cycle(context, run_to_end("thienlong_server.exe", arguments, Mode::kCommand), kExpectedNoise);
}

void cluster_stays_up_until_input_closes(Context& context) {
    const std::optional<std::string> config = loopback_config(context);
    if (!config) return;
    const std::array<std::string_view, 3> arguments{"--config", *config, "--no-postgres"};
    Result<Child> child = start("thienlong_server.exe", arguments, Mode::kService);
    context.expect(child.has_value(), "chạy được giám sát");
    if (!child) return;
    const Lines started = take_lines(*child, kStartLines.size() + 1);
    const bool is_whole = started.size() == kStartLines.size() + 1;
    context.expect(is_whole, "đủ sáu dòng started và một dòng ready");
    if (!is_whole) return;
    const std::span<const std::string> lines{started};
    context.expect(std::ranges::equal(lines.first(6), kStartLines), "khởi động đủ, đúng thứ tự");
    context.expect(is_cluster_ready(lines.back()), "rồi in ready kèm hai cổng thật của gate");
    const ExitStatus waited = child->wait_for(std::chrono::milliseconds{500});
    context.expect(waited.kind == WaitKind::kTimeout, "ống còn mở thì cụm còn chạy");
    child->close_input();
    const Lines stopped = take_lines(*child, kStopLines.size());
    context.expect(std::ranges::equal(stopped, kStopLines), "đóng ống thì dừng ngược thứ tự");
    context.expect(exit_code(*child) == 0, "giám sát thoát 0");
}

// Bản chép của thư mục cấu hình thật, nằm cạnh exe test, để sửa hỏng mà không đụng bản thật.
// Tệp bí mật *.local.toml không bao giờ được chép.
[[nodiscard]] Path copy_config(std::string_view name) {
    const Path target = io::executable_directory() / io::path_from_utf8(name);
    std::error_code error;
    std::filesystem::remove_all(target, error);
    std::filesystem::create_directories(target, error);
    const bool copied = copy_public_toml({.from = io::path_from_utf8(kConfigDir), .into = target});
    core::check(copied, "server_boot: không chép được cấu hình thật");
    return target;
}

void append_text(const Path& file, std::string_view text) {
    std::ofstream out{file, std::ios::binary | std::ios::app};
    out << text;
}

void bad_config_is_refused_before_any_start(Context& context) {
    const Path config = copy_config("server-boot-bad-config");
    append_text(config / "gate.toml", "\nnot_a_real_key = 1\n");
    append_text(config / "zone.toml", "\n[tick]\nhz = 30\n");
    const std::string dir = io::utf8_of(config);
    const std::array<std::string_view, 3> arguments{"--config", dir, "--no-postgres"};
    const Finished finished = run_to_end("thienlong_server.exe", arguments, Mode::kCommand);
    context.expect(finished.code == 2, "cấu hình sai thì thoát 2");
    context.expect(has_line_with(finished.lines, "gate.toml:"), "lỗi của gate.toml có số dòng");
    context.expect(has_line_with(finished.lines, "not_a_real_key"), "nêu tên khoá lạ");
    context.expect(has_line_with(finished.lines, "zone.toml:"), "lỗi của tệp thứ hai cũng được in");
    context.expect(!has_line_with(finished.lines, "started"), "không tiến trình nào được chạy");
}

// Dòng ready của cụm mang cổng của mọi con và phải vừa trần một dòng của bên đọc. Cụm khai nhiều
// tiến trình tới mức dòng ấy có thể dài quá trần thì bị từ chối trước khi chạy tiến trình nào.
void oversized_cluster_is_refused_before_any_start(Context& context) {
    const Path config = copy_config("server-boot-too-many");
    std::string zones;
    for (int id = 1; id <= 60; ++id) {
        zones += std::format("\n[[process]]\nkind = \"zone\"\nid = {}\nmachine = 0\n", id);
        zones += "host = \"127.0.0.1\"\nport = 0\n";
    }
    append_text(config / "cluster.toml", zones);
    const std::string dir = io::utf8_of(config);
    const std::array<std::string_view, 3> arguments{"--config", dir, "--no-postgres"};
    const Finished finished = run_to_end("thienlong_server.exe", arguments, Mode::kCommand);
    context.expect(finished.code == 2, "cụm quá nhiều tiến trình thì thoát 2");
    context.expect(has_line_with(finished.lines, "dòng ready của cụm"), "nêu lý do là dòng ready quá dài");
    context.expect(!has_line_with(finished.lines, "started"), "không tiến trình nào được chạy");
}

void bad_command_line_exits_two(Context& context) {
    const std::array<std::string_view, 3> stray{"--config", kConfigDir, "--bogus"};
    const Finished gate = run_to_end("thienlong_gate.exe", stray, Mode::kCommand);
    context.expect(gate.code == 2, "đối số lạ thì thoát 2");
    context.expect(has_line_with(gate.lines, "--bogus"), "nêu đối số lạ");
    context.expect(!has_line_with(gate.lines, "ready"), "không in ready");
    const Finished bare = run_to_end("thienlong_server.exe", {}, Mode::kCommand);
    context.expect(bare.code == 2, "thiếu --config thì thoát 2");
    const std::array<std::string_view, 4> numbered{"--config", kConfigDir, "--id", "7"};
    const Finished zone = run_to_end("thienlong_zone.exe", numbered, Mode::kCommand);
    context.expect(zone.code == 2, "số tiến trình không có trong cluster.toml thì thoát 2");
    context.expect(has_line_with(zone.lines, "cluster.toml:"), "lỗi chỉ vào cluster.toml");
}

// Hàm kiểm thuần, không chạy cụm: dòng stderr lạ, dòng chờ đợi thiếu hoặc lặp, và dòng tick sai dạng đều
// làm kiểm tra chu trình thất bại.
void stray_stderr_breaks_cycle(Context& context) {
    Lines whole{kStartLines.begin(), kStartLines.end()};
    whole.emplace_back("ready gate.game=40001 gate.auth=40002");
    whole.insert(whole.end(), kStopLines.begin(), kStopLines.end());
    Lines noisy = whole;
    noisy.insert(noisy.begin() + 2, kExpectedNoise.begin(), kExpectedNoise.end());
    noisy.emplace_back("gate: tick p99_us=12 max_us=40 late=0 conn=0 accept_us=1 pump_us=2 advance_us=3 flush_us=4");
    const std::optional<Lines> clean = cycle_lines(noisy, kExpectedNoise);
    context.expect(clean.has_value() && *clean == whole, "năm dòng chờ đợi và dòng tick được bỏ, còn đúng 13 dòng");
    Lines stray = noisy;
    stray.emplace_back("gate: không nghe được cổng game: lỗi");
    const std::optional<Lines> with_stray = cycle_lines(stray, kExpectedNoise);
    context.expect(with_stray.has_value() && with_stray->size() == 14, "dòng lạ được giữ, phép đếm 13 dòng hỏng");
    Lines missing = noisy;
    std::erase(missing, std::string{kExpectedNoise[0]});
    context.expect(cycle_lines(missing, kExpectedNoise) == clean, "vắng một dòng chờ đợi vẫn qua (bản dựng không libpq)");
    Lines twice = noisy;
    twice.emplace_back(kExpectedNoise[2]);
    context.expect(!cycle_lines(twice, kExpectedNoise).has_value(), "một dòng chờ đợi lặp thì hỏng");
    Lines bad_tick = whole;
    bad_tick.emplace_back("gate: tick p99_us=x max_us=40 late=0 conn=0 accept_us=1 pump_us=2 advance_us=3 flush_us=4");
    const std::optional<Lines> kept_tick = cycle_lines(bad_tick, {});
    context.expect(kept_tick.has_value() && kept_tick->size() == 14, "dòng tick sai dạng bị coi là dòng lạ");
    context.expect(cycle_lines(whole, kExpectedNoise) == clean, "vắng cả năm dòng chờ đợi vẫn qua, chu trình vẫn đủ 13 dòng");
}

constexpr std::array kCases{
    Case{.name = "stray_stderr_breaks_cycle", .body = &stray_stderr_breaks_cycle},
    Case{.name = "closed_input_runs_full_cycle", .body = &closed_input_runs_full_cycle},
    Case{.name = "empty_input_runs_full_cycle", .body = &empty_input_runs_full_cycle},
    Case{.name = "cluster_stays_up_until_input_closes", .body = &cluster_stays_up_until_input_closes},
    Case{.name = "bad_config_is_refused_before_any_start", .body = &bad_config_is_refused_before_any_start},
    Case{.name = "oversized_cluster_is_refused_before_any_start",
        .body = &oversized_cluster_is_refused_before_any_start},
    Case{.name = "bad_command_line_exits_two", .body = &bad_command_line_exits_two},
};

} // namespace
} // namespace game::test

int main() {
    const bool passed = game::test::run_all(game::test::kCases) == 0;
    game::core::check(passed, "server_boot");
    return 0;
}
