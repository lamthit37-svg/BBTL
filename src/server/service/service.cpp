// Điểm vào chung của bảy exe máy chủ. stdout chỉ mang các dòng cho máy đọc (`ready ...`,
// `started ...`, `stopped ...`, `ports ...`); mọi câu cho người đọc ra stderr.
#include "service/service.hpp"

#include "account/serve.hpp"
#include "billing/serve/serve.hpp"
#include "config/cluster.hpp"
#include "config/supervisor.hpp"
#include "config/types.hpp"
#include "gate/front.hpp"
#include "io/platform.hpp"
#include "process/process.hpp"
#include "service/cluster_host.hpp"
#include "service/detail/load.hpp"
#include "service/detail/request.hpp"
#include "supervise/supervise.hpp"
#include "zone/serve.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <memory>
#include <optional>
#include <print>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace game::service {
namespace {

using supervise::Plan;
using supervise::Role;
using supervise::Slot;
using supervise::Step;

constexpr int kExitMisuse = 2;
// Nhịp hỏi lại khi không có gì xảy ra: đủ ngắn để dòng `ready` của con được thấy ngay.
constexpr std::chrono::milliseconds kIdleSleep{20};

void print_errors(const detail::ErrorLines& lines) {
    for (const std::string& line : lines) {
        std::println(stderr, "{}", line);
    }
}

[[nodiscard]] int fail_usage(Kind kind, std::string_view error) {
    std::println(stderr, "thienlong_{}: {}", detail::kind_name(kind), error);
    std::println(stderr, "{}", detail::usage(kind));
    return kExitMisuse;
}

// Kế hoạch của trình giám sát.
[[nodiscard]] Role role_of(config::ServiceKind kind) noexcept {
    switch (kind) {
    case config::ServiceKind::kStore: return Role::kStore;
    case config::ServiceKind::kAuth: return Role::kAuth;
    case config::ServiceKind::kBilling: return Role::kBilling;
    case config::ServiceKind::kWorld: return Role::kWorld;
    case config::ServiceKind::kZone: return Role::kZone;
    case config::ServiceKind::kGate: return Role::kGate;
    }
    return Role::kGate;
}

void add_slot(Step& step, config::ServiceKind kind, const config::ProcessBlock& block) {
    if (config::service_of(block.kind) != kind) return;
    // Số của khối đã qua miền của config: không âm và vừa int32.
    const auto id = static_cast<std::int32_t>(block.id.value());
    step.slots.push_back(Slot{.role = step.role, .id = id});
}

// Một bước chạy mọi khối [[process]] cùng loại; gate không có khối nên là một tiến trình không số.
[[nodiscard]] Step step_of(const config::StartStep& start, const config::Cluster& cluster) {
    Step step;
    step.role = role_of(start.process);
    step.ready_timeout = start.ready_timeout_seconds;
    if (start.process == config::ServiceKind::kGate) {
        step.slots.push_back(Slot{.role = Role::kGate, .id = std::nullopt});
        return step;
    }
    for (const config::ProcessBlock& block : cluster.processes) {
        add_slot(step, start.process, block);
    }
    return step;
}

[[nodiscard]] Plan plan_of(const detail::Request& request, const detail::ClusterFiles& files) {
    const config::Supervisor& supervisor = files.supervisor;
    const bool is_managed = supervisor.postgres.managed && !request.skips_postgres;
    Plan plan;
    plan.postgres = is_managed ? supervise::PostgresMode::kManage : supervise::PostgresMode::kLeave;
    plan.postgres_timeout = supervisor.postgres.ready_timeout_seconds;
    plan.stop_timeout = supervisor.stop.timeout_seconds;
    plan.max_restarts_per_hour = static_cast<std::uint32_t>(supervisor.restart.max_per_hour);
    for (const config::StartStep& start : supervisor.steps) {
        plan.steps.push_back(step_of(start, files.cluster));
    }
    return plan;
}

void print_event(const supervise::Event& event) {
    if (event.stream == supervise::Stream::kErr) {
        std::println(stderr, "{}", event.line);
        return;
    }
    std::println("{}", event.line);
    static_cast<void>(std::fflush(stdout));
}

// Một nhịp của máy trạng thái. Nhịp không sinh dòng nào thì nghỉ, để vòng chạy không quay rỗng.
[[nodiscard]] supervise::Outcome advance_once(supervise::Machine& machine, supervise::Host& host) {
    const bool wants_stop = process::stop_requested();
    const supervise::StopAsk stop = wants_stop ? supervise::StopAsk::kYes : supervise::StopAsk::kNo;
    supervise::Outcome outcome = machine.advance(host, std::chrono::steady_clock::now(), stop);
    for (const supervise::Event& event : outcome.events) {
        print_event(event);
    }
    const bool is_idle = outcome.events.empty() && !outcome.finished;
    if (is_idle) std::this_thread::sleep_for(kIdleSleep);
    return outcome;
}

[[nodiscard]] int run_supervisor(const detail::Request& request) {
    const detail::ClusterResult files = detail::load_cluster(request.config_dir);
    if (!files) {
        print_errors(files.error());
        return kExitMisuse;
    }
    Plan plan = plan_of(request, *files);
    // Dòng `ready` của cụm mang cổng của mọi con và bên đọc đọc nó bằng Child::read_line: kế hoạch
    // có thể sinh dòng dài quá trần một dòng thì từ chối trước khi chạy tiến trình nào.
    const std::size_t longest = supervise::ready_line_bound(plan);
    if (longest > process::kLineCeiling) {
        std::println(stderr, "thienlong_server: quá nhiều tiến trình, dòng ready của cụm có thể dài {} byte, trần {}",
            longest, process::kLineCeiling);
        return kExitMisuse;
    }
    HostSetup setup;
    setup.program_dir = io::executable_directory();
    setup.config_dir = request.config_dir;
    setup.postgres = files->cluster.postgres;
    // host khai trước machine: lúc ra khỏi hàm host bị huỷ sau cùng và dọn mọi con còn sót.
    const std::unique_ptr<supervise::Host> host = make_cluster_host(setup);
    supervise::Machine machine{std::move(plan)};
    supervise::Outcome outcome;
    while (!outcome.finished) {
        outcome = advance_once(machine, *host);
    }
    return outcome.exit_code;
}

[[nodiscard]] int run_child(Kind kind, const detail::Request& request) {
    const detail::ErrorLines errors = detail::check_child(kind, request);
    if (!errors.empty()) {
        print_errors(errors);
        return kExitMisuse;
    }
    if (kind == Kind::kGate) return gate::serve(request.config_dir);
    if (kind == Kind::kZone) return zone::serve(request.config_dir);
#if defined(GAME_HAS_LIBPQ)
    if (kind == Kind::kAuth) return account::serve_auth(request.config_dir);
    if (kind == Kind::kStore) return account::serve_game(request.config_dir);
    if (kind == Kind::kBilling) return billing::serve_billing(request.config_dir);
#endif
    std::println("ready");
    static_cast<void>(std::fflush(stdout));
    while (!process::stop_requested()) {
        std::this_thread::sleep_for(kIdleSleep);
    }
    return 0;
}

} // namespace

int run(Kind kind, int argc, const char* const* argv) {
    io::use_utf8_console();
    process::watch_stop_signals();
    const std::vector<std::string> arguments = process::utf8_arguments(argc, argv);
    const detail::RequestResult request = detail::parse_request(kind, arguments);
    if (!request) return fail_usage(kind, request.error());
    if (request->identity_out) return gate::write_identity(*request->identity_out);
    if (kind == Kind::kSupervisor) return run_supervisor(*request);
    return run_child(kind, *request);
}

} // namespace game::service
