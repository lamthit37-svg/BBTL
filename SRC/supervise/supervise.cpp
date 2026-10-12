// Máy trạng thái một bước mỗi advance. Nguồn: TLBB Dev src/server/supervise.cpp
// @e0d89a6. Khác gốc: không giữ Child, không ngủ, không đọc đồng hồ; PostgreSQL,
// trần chạy lại mỗi giờ và nhiều tiến trình cùng một bước.
#include "supervise/supervise.hpp"

#include "core/check.hpp"
#include "core/error.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <iterator>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::supervise {

struct detail::MachineState {
    enum class Phase : std::uint8_t {
        kPostgres,
        kLaunch,
        kWait,
        kRun,
        kStopClose,
        kStopWait,
        kPostgresStop,
        kDone,
    };

    // Một tiến trình đã chạy. restarts giữ thời điểm các lần chạy lại trong một giờ gần nhất; ports
    // là các cổng nó báo ở dòng ready gần nhất.
    struct Live {
        Slot slot;
        Time started;
        std::chrono::milliseconds ready_timeout{};
        bool ready = false;
        ReadyPorts ports;
        std::vector<Time> restarts;
    };

    Plan plan;
    Phase phase = Phase::kPostgres;
    std::size_t step = 0;
    std::size_t slot = 0;
    std::size_t waiting = 0;
    std::size_t stop_remaining = 0;
    std::vector<Live> live;
    Time deadline;
    bool started_postgres = false;
    bool failed = false;
    bool stop_error = false;
    bool stopping = false;
    bool after_restart = false;
    int exit_code = 0;
};

namespace {

using State = detail::MachineState;
using Phase = State::Phase;
using Live = State::Live;

[[nodiscard]] std::string slot_label(const Slot& slot) {
    const std::string_view name = role_name(slot.role);
    if (!slot.id.has_value()) return std::string{name};
    return std::format("{} {}", name, *slot.id);
}

// Một khoá cổng của dòng ready và trường giữ nó. Thứ tự ở đây là thứ tự in trong dòng của cụm.
struct PortKey {
    std::string_view name;
    std::uint16_t ReadyPorts::* field = nullptr;
};

constexpr std::array<PortKey, 4> kPortKeys{{
    {.name = "ipc", .field = &ReadyPorts::ipc},
    {.name = "game", .field = &ReadyPorts::game},
    {.name = "auth", .field = &ReadyPorts::auth},
    {.name = "metrics", .field = &ReadyPorts::metrics},
}};

constexpr std::string_view kReadyWord = "ready";
// Số chữ số nhiều nhất của một cổng.
constexpr std::size_t kPortDigits = 5;

// Số ký tự của `.<số>` khi in số của một ô bằng thập phân, kể cả dấu trừ.
[[nodiscard]] constexpr std::size_t id_width(std::int32_t id) noexcept {
    std::size_t width = id < 0 ? 3 : 2;
    for (std::int32_t rest = id / 10; rest != 0; rest /= 10) {
        ++width;
    }
    return width;
}
static_assert(id_width(0) == 2 && id_width(9) == 2 && id_width(10) == 3 && id_width(2147483647) == 11);
static_assert(id_width(-1) == 3 && id_width(-2147483647 - 1) == 12);

// Tên một ô trong khoá cổng của dòng cụm: `gate`, `zone.0`.
[[nodiscard]] std::string slot_key(const Slot& slot) {
    const std::string_view name = role_name(slot.role);
    if (!slot.id.has_value()) return std::string{name};
    return std::format("{}.{}", name, *slot.id);
}

// Nối ` <ô>.<khoá>=<cổng>` cho từng cổng con đã báo.
void append_ports(std::string& line, const Slot& slot, const ReadyPorts& ports) {
    const std::string owner = slot_key(slot);
    for (const PortKey& key : kPortKeys) {
        const std::uint16_t port = ports.*key.field;
        if (port != 0) std::format_to(std::back_inserter(line), " {}.{}={}", owner, key.name, port);
    }
}

// Số thập phân 1..65535 chiếm trọn chuỗi.
[[nodiscard]] std::expected<std::uint16_t, ReadyFault> port_of(std::string_view text) noexcept {
    std::uint32_t value = 0;
    const char* const first = text.data();
    const char* const last = std::next(first, static_cast<std::ptrdiff_t>(text.size()));
    const std::from_chars_result parsed = std::from_chars(first, last, value);
    if (parsed.ec == std::errc::result_out_of_range) return std::unexpected(ReadyFault::kRange);
    if (parsed.ec != std::errc{} || parsed.ptr != last) return std::unexpected(ReadyFault::kNumber);
    if (value < 1 || value > 65535) return std::unexpected(ReadyFault::kRange);
    return static_cast<std::uint16_t>(value);
}

// Ghi một cặp `khoá=giá trị` vào ports; khoá không phải khoá cổng thì bỏ qua.
[[nodiscard]] std::optional<ReadyFault> take_pair(ReadyPorts& ports, std::string_view pair) noexcept {
    const std::size_t equals = pair.find('=');
    if (equals == std::string_view::npos || equals == 0) return ReadyFault::kPair;
    const auto found = std::ranges::find(kPortKeys, pair.substr(0, equals), &PortKey::name);
    if (found == kPortKeys.end()) return std::nullopt;
    std::uint16_t& slot = ports.*(found->field);
    if (slot != 0) return ReadyFault::kDuplicate;
    const std::expected<std::uint16_t, ReadyFault> port = port_of(pair.substr(equals + 1));
    if (!port) return port.error();
    slot = *port;
    return std::nullopt;
}

[[nodiscard]] Event out_line(std::string line) {
    Event event;
    event.stream = Stream::kOut;
    event.line = std::move(line);
    return event;
}

[[nodiscard]] Event err_line(std::string line) {
    Event event;
    event.stream = Stream::kErr;
    event.line = std::move(line);
    return event;
}

[[nodiscard]] Outcome one(Event event) {
    Outcome outcome;
    outcome.events.push_back(std::move(event));
    return outcome;
}

[[nodiscard]] Outcome finished_outcome(const State& state) {
    Outcome outcome;
    outcome.finished = true;
    outcome.exit_code = state.exit_code;
    return outcome;
}

// Dừng ngay, chưa có tiến trình nào để dọn: chỉ dùng trước bước chạy đầu tiên.
[[nodiscard]] Outcome fail_done(State& state, std::string_view what, const core::Error& error) {
    state.failed = true;
    state.phase = Phase::kDone;
    state.exit_code = 1;
    Outcome outcome = one(err_line(std::format("{}: {}", what, error)));
    outcome.finished = true;
    outcome.exit_code = 1;
    return outcome;
}

void begin_stop(State& state, bool as_failure) {
    if (state.stopping) return;
    if (as_failure) state.failed = true;
    state.stopping = true;
    state.after_restart = false;
    state.stop_remaining = state.live.size();
    state.phase = state.stop_remaining == 0 ? Phase::kPostgresStop : Phase::kStopClose;
}

void note_stop(State& state, StopAsk stop) {
    if (stop != StopAsk::kYes || state.stopping) return;
    // Stdin đóng từ lúc chạy vẫn phải khởi động hết rồi mới dừng.
    if (state.phase != Phase::kRun) return;
    begin_stop(state, false);
}

[[nodiscard]] Outcome skip_postgres(State& state) {
    state.phase = state.stopping ? Phase::kPostgresStop : Phase::kLaunch;
    return {};
}

[[nodiscard]] Outcome use_postgres(State& state) {
    state.phase = Phase::kLaunch;
    return one(out_line("using postgres"));
}

[[nodiscard]] Outcome start_postgres(State& state, Host& host) {
    const core::Status started = host.postgres_start(state.plan.postgres_timeout);
    if (!started) return fail_done(state, "PostgreSQL không chạy", started.error());
    state.started_postgres = true;
    state.phase = Phase::kLaunch;
    return one(out_line("started postgres"));
}

[[nodiscard]] Outcome query_postgres(State& state, Host& host) {
    const core::Result<PostgresState> status = host.postgres_status();
    if (!status) return fail_done(state, "không hỏi được PostgreSQL", status.error());
    if (*status == PostgresState::kUp) return use_postgres(state);
    return start_postgres(state, host);
}

[[nodiscard]] Outcome postgres_phase(State& state, Host& host) {
    const bool leave = state.stopping || state.plan.postgres == PostgresMode::kLeave;
    if (leave) return skip_postgres(state);
    return query_postgres(state, host);
}

[[nodiscard]] Outcome mark_ready(State& state) {
    state.phase = Phase::kRun;
    std::string line{kReadyWord};
    for (const Live& live : state.live) {
        append_ports(line, live.slot, live.ports);
    }
    return one(out_line(std::move(line)));
}

[[nodiscard]] Outcome advance_step(State& state) {
    ++state.step;
    state.slot = 0;
    return {};
}

[[nodiscard]] Outcome launch_failed(State& state, const Slot& slot, const core::Error& error) {
    begin_stop(state, true);
    return one(err_line(std::format("không chạy được {}: {}", slot_label(slot), error)));
}

[[nodiscard]] Outcome launch_slot(State& state, Host& host, Time now, const Step& step) {
    const Slot slot = step.slots[state.slot];
    core::check(slot.role == step.role, "ô không thuộc bước");
    const core::Status launched = host.launch(slot);
    if (!launched) return launch_failed(state, slot, launched.error());
    Live live;
    live.slot = slot;
    live.started = now;
    live.ready_timeout = step.ready_timeout;
    state.live.push_back(std::move(live));
    state.waiting = state.live.size() - 1;
    ++state.slot;
    state.deadline = now + step.ready_timeout;
    state.phase = Phase::kWait;
    state.after_restart = false;
    return one(out_line(std::format("started {}", slot_label(slot))));
}

[[nodiscard]] Outcome launch_phase(State& state, Host& host, Time now) {
    if (state.step >= state.plan.steps.size()) return mark_ready(state);
    const Step& step = state.plan.steps[state.step];
    if (state.slot >= step.slots.size()) return advance_step(state);
    return launch_slot(state, host, now, step);
}

[[nodiscard]] const Live& waiting_live(const State& state) {
    core::check(state.waiting < state.live.size(), "không có tiến trình đang chờ");
    return state.live[state.waiting];
}

// Dòng không mở đầu bằng `ready` là dòng khác của con: bỏ qua. Dòng ready hỏng là con hỏng.
[[nodiscard]] Outcome on_bad_ready(State& state, ReadyFault fault) {
    if (fault == ReadyFault::kNotReady) return {};
    const std::string label = slot_label(waiting_live(state).slot);
    begin_stop(state, true);
    return one(err_line(std::format("{} gửi dòng ready hỏng: {}", label, describe(fault))));
}

[[nodiscard]] Outcome on_wait_line(State& state, std::string_view line) {
    const std::expected<ReadyPorts, ReadyFault> ports = parse_ready(line);
    if (!ports) return on_bad_ready(state, ports.error());
    Live& live = state.live[state.waiting];
    // Con chạy lại ở cổng khác: dòng ready của cụm đã in rồi, nên báo riêng cổng mới của con này.
    const bool has_moved = state.after_restart && *ports != live.ports;
    live.ready = true;
    live.ports = *ports;
    state.phase = state.after_restart ? Phase::kRun : Phase::kLaunch;
    state.after_restart = false;
    if (!has_moved) return {};
    std::string moved{"ports"};
    append_ports(moved, live.slot, live.ports);
    return one(out_line(std::move(moved)));
}

[[nodiscard]] Outcome on_wait_running(State& state, Time now) {
    if (now < state.deadline) return {};
    const std::string label = slot_label(waiting_live(state).slot);
    begin_stop(state, true);
    return one(err_line(std::format("hết hạn chờ {} sẵn sàng", label)));
}

[[nodiscard]] Outcome on_wait_dead(State& state, const Poll& poll) {
    const std::string label = slot_label(waiting_live(state).slot);
    begin_stop(state, true);
    if (poll.kind == PollKind::kTooLong) {
        return one(err_line(std::format("{} gửi dòng dài quá trần", label)));
    }
    return one(err_line(std::format("{} thoát mã {} trước khi sẵn sàng", label, poll.code)));
}

[[nodiscard]] Outcome wait_phase(State& state, Host& host, Time now) {
    const Poll poll = host.poll(waiting_live(state).slot);
    if (poll.kind == PollKind::kLine) return on_wait_line(state, poll.line);
    if (poll.kind == PollKind::kRunning) return on_wait_running(state, now);
    return on_wait_dead(state, poll);
}

struct Seen {
    std::optional<std::size_t> index;
};

void consider(Host& host, const Live& live, std::size_t index, Seen& seen) {
    if (seen.index.has_value()) return;
    const Poll poll = host.poll(live.slot);
    if (poll.kind == PollKind::kExited || poll.kind == PollKind::kTooLong) seen.index = index;
}

[[nodiscard]] std::optional<std::size_t> find_dead(Host& host, const std::vector<Live>& live) {
    Seen seen;
    for (std::size_t index = 0; index < live.size(); ++index) {
        consider(host, live[index], index, seen);
    }
    return seen.index;
}

void prune(std::vector<Time>& times, Time now) {
    const Time cutoff = now - std::chrono::hours{1};
    std::erase_if(times, [&](Time moment) { return moment < cutoff; });
}

[[nodiscard]] Outcome ceiling_hit(State& state, const Live& live) {
    begin_stop(state, true);
    return one(err_line(std::format("{} vượt trần chạy lại mỗi giờ", slot_label(live.slot))));
}

[[nodiscard]] Outcome restart(State& state, Host& host, Time now, Live& live, std::size_t index) {
    const core::Status launched = host.launch(live.slot);
    if (!launched) return launch_failed(state, live.slot, launched.error());
    live.restarts.push_back(now);
    live.ready = false;
    live.started = now;
    state.deadline = now + live.ready_timeout;
    state.waiting = index;
    state.phase = Phase::kWait;
    state.after_restart = true;
    const std::string text = std::format("{} thoát, chạy lại", slot_label(live.slot));
    return one(err_line(text));
}

[[nodiscard]] Outcome on_died(State& state, Host& host, Time now, std::size_t index) {
    Live& live = state.live[index];
    prune(live.restarts, now);
    if (live.restarts.size() >= state.plan.max_restarts_per_hour) return ceiling_hit(state, live);
    return restart(state, host, now, live, index);
}

[[nodiscard]] Outcome run_phase(State& state, Host& host, Time now) {
    const std::optional<std::size_t> dead = find_dead(host, state.live);
    if (!dead.has_value()) return {};
    return on_died(state, host, now, *dead);
}

[[nodiscard]] Outcome on_stopped(State& state, const Live& live, int code) {
    if (code != 0) state.stop_error = true;
    if (state.stop_remaining > 0) --state.stop_remaining;
    state.phase = Phase::kStopClose;
    return one(out_line(std::format("stopped {}", slot_label(live.slot))));
}

[[nodiscard]] Outcome on_force(State& state, Host& host, const Live& live) {
    host.force_stop(live.slot);
    state.stop_error = true;
    std::string text = std::format("quá hạn dừng {}, buộc dừng", slot_label(live.slot));
    Outcome outcome = one(err_line(std::move(text)));
    Outcome stopped = on_stopped(state, live, 1);
    outcome.events.push_back(std::move(stopped.events.front()));
    return outcome;
}

[[nodiscard]] const Live& stop_target(const State& state) {
    core::check(state.stop_remaining > 0, "không còn tiến trình để dừng");
    core::check(state.stop_remaining <= state.live.size(), "chỉ số dừng vượt danh sách");
    return state.live[state.stop_remaining - 1];
}

[[nodiscard]] Outcome stop_close(State& state, Host& host, Time now) {
    if (state.stop_remaining == 0) {
        state.phase = Phase::kPostgresStop;
        return {};
    }
    const Live& live = stop_target(state);
    host.close_input(live.slot);
    state.deadline = now + state.plan.stop_timeout;
    state.phase = Phase::kStopWait;
    return {};
}

[[nodiscard]] Outcome stop_wait(State& state, Host& host, Time now) {
    const Live& live = stop_target(state);
    const Poll poll = host.poll(live.slot);
    if (poll.kind == PollKind::kExited) return on_stopped(state, live, poll.code);
    if (now >= state.deadline) return on_force(state, host, live);
    return {};
}

[[nodiscard]] Outcome finish(State& state) {
    state.phase = Phase::kDone;
    const bool bad = state.failed || state.stop_error;
    state.exit_code = bad ? 1 : 0;
    return finished_outcome(state);
}

[[nodiscard]] Outcome postgres_stop_phase(State& state, Host& host) {
    if (!state.started_postgres) return finish(state);
    const core::Status stopped = host.postgres_stop(state.plan.stop_timeout);
    state.stop_error = state.stop_error || !stopped;
    Outcome outcome = finish(state);
    Event event = out_line("stopped postgres");
    if (!stopped) event = err_line(std::format("PostgreSQL không dừng: {}", stopped.error()));
    outcome.events.push_back(std::move(event));
    return outcome;
}

[[nodiscard]] Outcome dispatch(State& state, Host& host, Time now) {
    switch (state.phase) {
    case Phase::kPostgres: return postgres_phase(state, host);
    case Phase::kLaunch: return launch_phase(state, host, now);
    case Phase::kWait: return wait_phase(state, host, now);
    case Phase::kRun: return run_phase(state, host, now);
    case Phase::kStopClose: return stop_close(state, host, now);
    case Phase::kStopWait: return stop_wait(state, host, now);
    case Phase::kPostgresStop: return postgres_stop_phase(state, host);
    case Phase::kDone: return finished_outcome(state);
    }
    core::fail("pha giám sát không có");
}

} // namespace

Machine::Machine(Plan plan) : state_(std::make_unique<State>()) {
    state_->plan = std::move(plan);
    if (state_->plan.postgres == PostgresMode::kLeave) state_->phase = Phase::kLaunch;
}

Machine::~Machine() = default;

Outcome Machine::advance(Host& host, Time now, StopAsk stop) {
    if (state_->phase == Phase::kDone) return finished_outcome(*state_);
    note_stop(*state_, stop);
    return dispatch(*state_, host, now);
}

bool Machine::finished() const noexcept {
    return state_->phase == Phase::kDone;
}

std::expected<ReadyPorts, ReadyFault> parse_ready(std::string_view line) noexcept {
    std::size_t space = line.find(' ');
    if (line.substr(0, space) != kReadyWord) return std::unexpected(ReadyFault::kNotReady);
    ReadyPorts ports;
    while (space != std::string_view::npos) {
        line.remove_prefix(space + 1);
        space = line.find(' ');
        const std::optional<ReadyFault> fault = take_pair(ports, line.substr(0, space));
        if (fault) return std::unexpected(*fault);
    }
    return ports;
}

std::string_view describe(ReadyFault fault) noexcept {
    switch (fault) {
    case ReadyFault::kNotReady: return "không phải dòng ready";
    case ReadyFault::kPair: return "có từ không ở dạng khoá=giá trị";
    case ReadyFault::kDuplicate: return "một khoá cổng lặp lại";
    case ReadyFault::kNumber: return "cổng không phải số";
    case ReadyFault::kRange: return "cổng ngoài 1..65535";
    }
    return "";
}

std::size_t ready_line_bound(const Plan& plan) noexcept {
    // Mỗi cặp là ` <ô>.<khoá>=<cổng>`: dấu cách, dấu chấm và dấu bằng là ba byte.
    std::size_t keys = 0;
    for (const PortKey& key : kPortKeys) {
        keys += key.name.size() + kPortDigits + 3;
    }
    std::size_t bound = kReadyWord.size();
    for (const Step& step : plan.steps) {
        for (const Slot& slot : step.slots) {
            const std::size_t suffix = slot.id.has_value() ? id_width(*slot.id) : 0;
            bound += keys + (kPortKeys.size() * (role_name(slot.role).size() + suffix));
        }
    }
    return bound;
}

std::string_view role_name(Role role) noexcept {
    switch (role) {
    case Role::kPostgres: return "postgres";
    case Role::kStore: return "store";
    case Role::kAuth: return "auth";
    case Role::kBilling: return "billing";
    case Role::kWorld: return "world";
    case Role::kZone: return "zone";
    case Role::kGate: return "gate";
    }
    return "";
}

bool same_slot(const Slot& left, const Slot& right) noexcept {
    return left.role == right.role && left.id == right.id;
}

} // namespace game::supervise
