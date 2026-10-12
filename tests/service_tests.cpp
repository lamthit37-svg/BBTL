// Bộ chạy thật của trình giám sát với exe thật nằm cạnh test: chạy một ô tới `ready`, đóng ống thì
// thoát 0; chạy lại một ô đã chết; thay một ô còn sống; ô không có; exe thiếu; con từ chối số lạ.
// Mỗi ca chạy trên một bản chép mới của cấu hình thật, mọi cổng nghe là 127.0.0.1:0
// (support/loopback_config.hpp); gate báo cổng thật ở dòng ready.
#include "core/check.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "io/platform.hpp"
#include "service/cluster_host.hpp"
#include "supervise/supervise.hpp"
#include "support/gate_key.hpp"
#include "support/loopback_config.hpp"
#include "test.hpp"

#include <array>
#include <chrono>
#include <expected>
#include <filesystem>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <thread>

namespace game::test {
namespace {

using supervise::Host;
using supervise::Poll;
using supervise::PollKind;
using supervise::Role;
using supervise::Slot;
using Clock = std::chrono::steady_clock;

#ifdef GAME_SERVER_CONFIG
constexpr std::string_view kConfigDir = GAME_SERVER_CONFIG;
#else
// check.py dịch tệp này không có định nghĩa của CMake; đường dẫn từ gốc dự án để tệp tự đứng được.
constexpr std::string_view kConfigDir = "SERVER/config";
#endif

// Hạn cho một bước của tiến trình thật; bản ASan khởi động chậm hơn bản phát hành nhiều lần.
constexpr std::chrono::seconds kPatience{15};
constexpr Slot kZone{.role = Role::kZone, .id = 0};
constexpr Slot kGate{.role = Role::kGate, .id = std::nullopt};

// Tên thư mục tạm cạnh exe test; cấu hình nằm ở <tên>/config.
constexpr std::string_view kStage = "service-tests";

[[nodiscard]] std::filesystem::path staged_dir() {
    return io::executable_directory() / io::path_from_utf8(kStage) / "config";
}

// Bộ chạy thật trên một bản chép mới của cấu hình thật, mọi cổng nghe là 127.0.0.1:0. Không dựng
// được bản chép là hỏng môi trường test: dừng luôn, không chạy tiếp với cấu hình thật.
[[nodiscard]] std::unique_ptr<Host> real_host() {
    const std::optional<std::filesystem::path> staged = stage_config(io::path_from_utf8(kConfigDir), kStage);
    if (!staged) core::fail("service_tests: không dựng được cấu hình tạm nghe loopback");
    service::HostSetup setup;
    setup.program_dir = io::executable_directory();
    setup.config_dir = *staged;
    return service::make_cluster_host(setup);
}

// Hỏi con tới khi nó có tin (một dòng, đã thoát, dòng quá trần) hoặc hết hạn.
[[nodiscard]] Poll next_news(Host& host, const Slot& slot) {
    const Clock::time_point deadline = Clock::now() + kPatience;
    Poll poll = host.poll(slot);
    while (poll.kind == PollKind::kRunning && Clock::now() < deadline) {
        std::this_thread::sleep_for(std::chrono::milliseconds{10});
        poll = host.poll(slot);
    }
    return poll;
}

[[nodiscard]] bool is_ready(const Poll& poll) {
    return poll.kind == PollKind::kLine && supervise::parse_ready(poll.line).has_value();
}

// Dòng ready của gate mang hai cổng thật, khác nhau, do hệ điều hành cấp cho cấu hình cổng 0.
[[nodiscard]] bool tells_gate_ports(const Poll& poll) {
    if (poll.kind != PollKind::kLine) return false;
    const std::expected<supervise::ReadyPorts, supervise::ReadyFault> ports = supervise::parse_ready(poll.line);
    return ports.has_value() && ports->game != 0 && ports->auth != 0 && ports->game != ports->auth;
}

[[nodiscard]] bool exited_with(const Poll& poll, int code) {
    return poll.kind == PollKind::kExited && poll.code == code;
}

void slot_runs_until_input_closes(Context& context) {
    const std::unique_ptr<Host> host = real_host();
    context.expect(host->launch(kZone).has_value(), "chạy được zone 0");
    context.expect(is_ready(next_news(*host, kZone)), "zone 0 in ready");
    context.expect(host->poll(kZone).kind == PollKind::kRunning, "ống còn mở thì zone còn chạy");
    host->close_input(kZone);
    context.expect(exited_with(next_news(*host, kZone), 0), "đóng ống thì zone thoát mã 0");
}

void relaunch_replaces_dead_process(Context& context) {
    const std::unique_ptr<Host> host = real_host();
    context.expect(host->launch(kZone).has_value(), "chạy được zone 0");
    context.expect(is_ready(next_news(*host, kZone)), "lần đầu in ready");
    host->force_stop(kZone);
    const Poll after_force = next_news(*host, kZone);
    context.expect(after_force.kind == PollKind::kExited, "buộc dừng thì thấy đã thoát");
    context.expect(host->launch(kZone).has_value(), "chạy lại được zone 0");
    context.expect(is_ready(next_news(*host, kZone)), "tiến trình mới in ready, không còn tin cũ");
    host->close_input(kZone);
    context.expect(exited_with(next_news(*host, kZone), 0), "tiến trình mới dừng êm");
}

void relaunch_replaces_live_process(Context& context) {
    const std::unique_ptr<Host> host = real_host();
    const std::string config = io::utf8_of(staged_dir());
    context.expect(ensure_gate_identity(config), "có khoá danh tính của gate");
    context.expect(host->launch(kGate).has_value(), "chạy được gate");
    context.expect(tells_gate_ports(next_news(*host, kGate)), "gate in ready kèm hai cổng thật");
    context.expect(host->launch(kGate).has_value(), "chạy đè lên gate còn sống");
    context.expect(tells_gate_ports(next_news(*host, kGate)), "gate mới in ready kèm hai cổng thật");
    host->close_input(kGate);
    context.expect(exited_with(next_news(*host, kGate), 0), "gate mới dừng êm");
}

void unknown_slot_reads_as_exited(Context& context) {
    const std::unique_ptr<Host> host = real_host();
    constexpr Slot kNever{.role = Role::kWorld, .id = 0};
    context.expect(exited_with(host->poll(kNever), 1), "ô chưa chạy đọc như đã thoát mã 1");
    host->close_input(kNever);
    host->force_stop(kNever);
}

void missing_program_is_an_error(Context& context) {
    service::HostSetup setup;
    setup.program_dir = io::executable_directory() / "khong-co-thu-muc-nay";
    setup.config_dir = io::path_from_utf8(kConfigDir);
    const std::unique_ptr<Host> host = service::make_cluster_host(setup);
    const core::Status launched = host->launch(kZone);
    context.expect(!launched.has_value(), "thiếu exe thì launch báo lỗi");
    context.expect(exited_with(host->poll(kZone), 1), "ô chạy hỏng đọc như đã thoát");
}

void child_refuses_unknown_number(Context& context) {
    const std::unique_ptr<Host> host = real_host();
    constexpr Slot kStray{.role = Role::kZone, .id = 7};
    context.expect(host->launch(kStray).has_value(), "exe zone chạy được với số lạ");
    const Poll news = next_news(*host, kStray);
    context.expect(exited_with(news, 2), "cluster.toml không có zone 7: con thoát mã 2");
}

constexpr std::array kCases{
    Case{.name = "slot_runs_until_input_closes", .body = &slot_runs_until_input_closes},
    Case{.name = "relaunch_replaces_dead_process", .body = &relaunch_replaces_dead_process},
    Case{.name = "relaunch_replaces_live_process", .body = &relaunch_replaces_live_process},
    Case{.name = "unknown_slot_reads_as_exited", .body = &unknown_slot_reads_as_exited},
    Case{.name = "missing_program_is_an_error", .body = &missing_program_is_an_error},
    Case{.name = "child_refuses_unknown_number", .body = &child_refuses_unknown_number},
};

} // namespace
} // namespace game::test

int main() {
    const bool passed = game::test::run_all(game::test::kCases) == 0;
    game::core::check(passed, "service_tests");
    return 0;
}
