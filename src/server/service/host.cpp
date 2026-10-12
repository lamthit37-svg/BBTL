// Bộ chạy thật của trình giám sát. Tiến trình con chạy kiểu kService (ống stdin, chết theo giám
// sát). pg_ctl chạy kiểu kCommand: PostgreSQL nó khởi động không bị giết cứng khi giám sát chết và
// không giữ handle nào của giám sát.
// pg_ctl: `status` thoát 0 khi cụm đang chạy, 3 khi không chạy; `start` và `stop` dùng -w để chờ
// xong, -t để tự bỏ cuộc đúng hạn. Không gọi initdb, không dừng kiểu immediate, không ghi gì dưới
// thư mục dữ liệu.
#include "service/cluster_host.hpp"

#include "core/error.hpp"
#include "io/file.hpp"
#include "process/process.hpp"
#include "supervise/supervise.hpp"

#if defined(_WIN32)
#include "core/text.hpp"
#endif

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <format>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::service {
namespace {

using supervise::Poll;
using supervise::PollKind;
using supervise::PostgresState;
using supervise::Slot;
using Clock = std::chrono::steady_clock;
using Milliseconds = std::chrono::milliseconds;
using Path = std::filesystem::path;
using Words = std::vector<std::string>;

constexpr Milliseconds kStatusLimit{10000};
// pg_ctl tự bỏ cuộc sau hạn -t; giám sát chờ thêm chừng này rồi mới buộc dừng chính pg_ctl.
constexpr Milliseconds kCommandGrace{5000};
constexpr Milliseconds kCommandSlice{50};
constexpr int kNotRunning = 3;
constexpr std::size_t kTailLines = 6;

// Đường dẫn cho dòng lệnh: UTF-8, dấu phân cách của hệ điều hành.
[[nodiscard]] std::string native_utf8(const Path& path) {
#if defined(_WIN32)
    return core::narrow(path.native());
#else
    return path.native();
#endif
}

// Tuyệt đối và đã gọn, để lệnh con không phụ thuộc thư mục làm việc. Hệ điều hành không trả lời
// được thì giữ đường dẫn đã cho.
[[nodiscard]] Path settled(const Path& path) {
    std::error_code error;
    const Path absolute = std::filesystem::absolute(path, error);
    return (error ? path : absolute).lexically_normal();
}

[[nodiscard]] std::string program_file(const Path& dir, std::string_view stem) {
    Path file = dir / io::path_from_utf8(stem);
#if defined(_WIN32)
    file += ".exe";
#endif
    return native_utf8(file);
}

// Lệnh chạy rồi thoát.
struct CommandOutput {
    int code = 0;
    // Vài dòng cuối lệnh đã in, để ghép vào câu lỗi.
    Words tail;
};

using CommandResult = core::Result<CommandOutput>;

// Một dòng lệnh vừa in, nếu có. false khi chưa có dòng nào.
[[nodiscard]] bool take_line(process::Child& child, Milliseconds wait, Words& tail) {
    core::Result<process::Line> line = child.read_line(wait);
    const bool is_text = line.has_value() && line->kind == process::LineKind::kText;
    if (!is_text) return false;
    if (tail.size() == kTailLines) tail.erase(tail.begin());
    tail.push_back(std::move(line->text));
    return true;
}

// Chờ lệnh thoát trong hạn. Không đọc ống tới khi đóng: tiến trình nền lệnh để lại vẫn giữ đầu
// ghi của ống đó.
[[nodiscard]] CommandResult finish_command(process::Child& child, Milliseconds limit) {
    CommandOutput output;
    const Clock::time_point deadline = Clock::now() + limit;
    std::optional<int> code = child.try_wait();
    while (!code && Clock::now() < deadline) {
        static_cast<void>(take_line(child, kCommandSlice, output.tail));
        code = child.try_wait();
    }
    bool has_more = code.has_value();
    while (has_more) {
        has_more = take_line(child, Milliseconds{0}, output.tail);
    }
    if (!code) return core::fail(core::ErrorCode::kTimeout, "pg_ctl chạy quá hạn");
    output.code = *code;
    return output;
}

void append_line(std::string& text, const std::string& line) {
    if (!text.empty()) text += " | ";
    text += line;
}

// Một câu kể lệnh pg_ctl đã hỏng thế nào: không chạy được, quá hạn, hay thoát mã khác 0.
[[nodiscard]] std::string failure_text(std::string_view verb, const CommandResult& result) {
    if (!result) return std::format("{}: {}", verb, result.error());
    std::string said;
    for (const std::string& line : result->tail) {
        append_line(said, line);
    }
    return std::format("{} thoát mã {}: {}", verb, result->code, said);
}

[[nodiscard]] core::Failure command_failed(std::string_view verb, const CommandResult& result) {
    const core::ErrorCode code = core::ErrorCode::kInvalidState;
    return core::fail(code, "pg_ctl báo lỗi", failure_text(verb, result));
}

[[nodiscard]] Poll poll_of(PollKind kind, int code = 0) {
    Poll poll;
    poll.kind = kind;
    poll.code = code;
    return poll;
}

class ClusterHost final : public supervise::Host {
public:
    explicit ClusterHost(const HostSetup& setup);

    [[nodiscard]] core::Result<PostgresState> postgres_status() override;
    [[nodiscard]] core::Status postgres_start(Milliseconds timeout) override;
    [[nodiscard]] core::Status postgres_stop(Milliseconds timeout) override;
    [[nodiscard]] core::Status launch(const Slot& slot) override;
    void close_input(const Slot& slot) noexcept override;
    void force_stop(const Slot& slot) noexcept override;
    [[nodiscard]] Poll poll(const Slot& slot) override;

private:
    struct Running {
        Slot slot;
        process::Child child;
    };

    [[nodiscard]] Running* find(const Slot& slot) noexcept;
    [[nodiscard]] CommandResult pg_ctl(const Words& words, Milliseconds limit) const;
    [[nodiscard]] Words waiting_words(std::string_view verb, Milliseconds wait) const;

    Path program_dir_;
    std::string config_dir_;
    std::string pg_ctl_;
    std::string data_dir_;
    std::string log_file_;
    std::vector<Running> running_;
};

ClusterHost::ClusterHost(const HostSetup& setup) : program_dir_(settled(setup.program_dir)) {
    const Path config = settled(setup.config_dir);
    config_dir_ = native_utf8(config);
    pg_ctl_ = program_file(settled(config / io::path_from_utf8(setup.postgres.bin_dir)), "pg_ctl");
    data_dir_ = native_utf8(settled(config / io::path_from_utf8(setup.postgres.data_dir)));
    log_file_ = native_utf8(settled(config / io::path_from_utf8(setup.postgres.log_file)));
}

ClusterHost::Running* ClusterHost::find(const Slot& slot) noexcept {
    const auto same = [&](const Running& one) { return supervise::same_slot(one.slot, slot); };
    const auto found = std::ranges::find_if(running_, same);
    return found == running_.end() ? nullptr : std::to_address(found);
}

CommandResult ClusterHost::pg_ctl(const Words& words, Milliseconds limit) const {
    const std::vector<std::string_view> views(words.begin(), words.end());
    process::Spawn request;
    request.executable = pg_ctl_;
    request.arguments = views;
    request.mode = process::Mode::kCommand;
    core::Result<process::Child> child = process::spawn(request);
    if (!child) return std::unexpected(child.error());
    return finish_command(*child, limit);
}

Words ClusterHost::waiting_words(std::string_view verb, Milliseconds wait) const {
    const auto seconds = std::chrono::duration_cast<std::chrono::seconds>(wait).count();
    const std::string limit = std::to_string(std::max<std::int64_t>(seconds, 1));
    return Words{std::string{verb}, "-w", "-t", limit, "-D", data_dir_};
}

core::Result<PostgresState> ClusterHost::postgres_status() {
    const CommandResult asked = pg_ctl({"status", "-D", data_dir_}, kStatusLimit);
    const int code = asked ? asked->code : -1;
    if (code == 0) return PostgresState::kUp;
    if (code == kNotRunning) return PostgresState::kDown;
    return command_failed("status", asked);
}

core::Status ClusterHost::postgres_start(Milliseconds timeout) {
    Words words = waiting_words("start", timeout);
    words.insert(words.end(), {"-l", log_file_});
    const CommandResult started = pg_ctl(words, timeout + kCommandGrace);
    const bool is_up = started.has_value() && started->code == 0;
    if (is_up) return core::ok();
    // Khởi động hỏng có thể để lại postgres đang lên dở; còn chạy thì bảo nó dừng. Lỗi trả về vẫn
    // là lỗi khởi động, kèm một câu nếu cả việc dọn cũng hỏng.
    const core::Result<PostgresState> left = postgres_status();
    const bool is_left_up = left.has_value() && *left == PostgresState::kUp;
    const core::Status cleaned = is_left_up ? postgres_stop(timeout) : core::ok();
    const std::string_view note = cleaned ? "" : "; cụm còn chạy dở và không dừng lại được";
    const core::ErrorCode code = core::ErrorCode::kInvalidState;
    return core::fail(code, "pg_ctl báo lỗi", "{}{}", failure_text("start", started), note);
}

core::Status ClusterHost::postgres_stop(Milliseconds timeout) {
    Words words = waiting_words("stop", timeout);
    words.insert(words.end(), {"-m", "fast"});
    const CommandResult stopped = pg_ctl(words, timeout + kCommandGrace);
    const bool is_down = stopped.has_value() && stopped->code == 0;
    if (is_down) return core::ok();
    return command_failed("stop", stopped);
}

// Dừng tiến trình cũ trước khi tạo cái mới, để cổng nghe được trả lại trước lần bind.
core::Status ClusterHost::launch(const Slot& slot) {
    Running* const running = find(slot);
    if (running != nullptr) running->child.force_stop();
    const std::string stem = std::format("thienlong_{}", supervise::role_name(slot.role));
    const std::string program = program_file(program_dir_, stem);
    Words words{"--config", config_dir_};
    if (slot.id) words.insert(words.end(), {"--id", std::to_string(*slot.id)});
    const std::vector<std::string_view> views(words.begin(), words.end());
    process::Spawn request;
    request.executable = program;
    request.arguments = views;
    core::Result<process::Child> child = process::spawn(request);
    if (!child) return std::unexpected(child.error());
    if (running == nullptr) {
        running_.push_back(Running{.slot = slot, .child = std::move(*child)});
        return core::ok();
    }
    running->child = std::move(*child);
    return core::ok();
}

void ClusterHost::close_input(const Slot& slot) noexcept {
    Running* const running = find(slot);
    if (running != nullptr) running->child.close_input();
}

void ClusterHost::force_stop(const Slot& slot) noexcept {
    Running* const running = find(slot);
    if (running != nullptr) running->child.force_stop();
}

// Không chặn: một dòng nếu con vừa in, không thì trạng thái sống chết của nó.
Poll ClusterHost::poll(const Slot& slot) {
    Running* const running = find(slot);
    if (running == nullptr) return poll_of(PollKind::kExited, 1);
    core::Result<process::Line> line = running->child.read_line(Milliseconds{0});
    const process::LineKind kind = line ? line->kind : process::LineKind::kClosed;
    if (kind == process::LineKind::kText) {
        Poll poll = poll_of(PollKind::kLine);
        poll.line = std::move(line->text);
        return poll;
    }
    if (kind == process::LineKind::kTooLong) return poll_of(PollKind::kTooLong);
    const std::optional<int> code = running->child.try_wait();
    if (!code) return poll_of(PollKind::kRunning);
    return poll_of(PollKind::kExited, *code);
}

} // namespace

std::unique_ptr<supervise::Host> make_cluster_host(const HostSetup& setup) {
    return std::make_unique<ClusterHost>(setup);
}

} // namespace game::service
