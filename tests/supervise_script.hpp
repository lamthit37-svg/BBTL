#pragma once
// Bộ chạy giả cho máy trạng thái của trình giám sát: không tiến trình thật, không đồng hồ. Test
// đặt kịch bản cho từng tiến trình giả và PostgreSQL giả, chạy máy ở các thời điểm tự chọn rồi
// đọc các dòng máy in ra. Tách khỏi supervise_tests.cpp để tệp test chỉ còn các ca.

#include "core/error.hpp"
#include "supervise/supervise.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {

using supervise::Event;
using supervise::Host;
using supervise::Machine;
using supervise::Outcome;
using supervise::Plan;
using supervise::Poll;
using supervise::PollKind;
using supervise::PostgresMode;
using supervise::PostgresState;
using supervise::Role;
using supervise::Slot;
using supervise::Step;
using supervise::StopAsk;
using supervise::Stream;
using supervise::Time;
using Lines = std::vector<std::string>;
using Milliseconds = std::chrono::milliseconds;

inline constexpr Slot kStore{.role = Role::kStore, .id = 0};
inline constexpr Slot kAuth{.role = Role::kAuth, .id = 0};
inline constexpr std::chrono::seconds kReadyLimit{10};
inline constexpr std::chrono::seconds kStopLimit{5};
// Số nhịp tối đa một lần chạy máy trong test; máy đứng yên ở pha chạy thì dừng sau chừng này nhịp.
inline constexpr int kStepBudget = 64;

inline constexpr std::array<std::string_view, 7> kStartLines{
    "started store 0",
    "started auth 0",
    "started billing 0",
    "started world 0",
    "started zone 0",
    "started gate",
    "ready",
};

inline constexpr std::array<std::string_view, 6> kStopLines{
    "stopped gate",
    "stopped zone 0",
    "stopped world 0",
    "stopped billing 0",
    "stopped auth 0",
    "stopped store 0",
};

// Một tiến trình giả. Nửa trên là kịch bản test đặt trước, nửa dưới là trạng thái bộ chạy ghi.
struct Actor {
    Slot slot;
    bool says_ready = true;
    // Dòng tiến trình giả in khi sẵn sàng; test đổi để báo cổng hoặc gửi dòng hỏng.
    std::string ready_line{"ready"};
    bool dies_before_ready = false;
    bool floods_output = false;
    bool obeys_close = true;
    bool fails_launch = false;
    int deaths_after_ready = 0;
    int code_on_close = 0;

    bool is_alive = false;
    bool has_said_ready = false;
    bool was_forced = false;
    int exit_code = 0;
    int launches = 0;
};

[[nodiscard]] inline Poll poll_of(PollKind kind, int code = 0) {
    Poll poll;
    poll.kind = kind;
    poll.code = code;
    return poll;
}

[[nodiscard]] inline Poll die(Actor& actor) {
    --actor.deaths_after_ready;
    actor.is_alive = false;
    actor.exit_code = 1;
    return poll_of(PollKind::kExited, 1);
}

[[nodiscard]] inline Poll say_ready(Actor& actor) {
    if (!actor.says_ready) return poll_of(PollKind::kRunning);
    actor.has_said_ready = true;
    Poll poll = poll_of(PollKind::kLine);
    poll.line = actor.ready_line;
    return poll;
}

// PostgreSQL giả: ba cờ đầu là kịch bản, phần còn lại là trạng thái bộ chạy ghi.
struct Database {
    bool answers_status = true;
    bool starts = true;
    bool stops = true;
    PostgresState state = PostgresState::kDown;
    int start_calls = 0;
    int stop_calls = 0;
};

// Bộ chạy giả: không tiến trình thật, không đồng hồ. Test đặt kịch bản qua actor() và database().
class Script final : public Host {
public:
    [[nodiscard]] Database& database() noexcept { return database_; }

    // Tiến trình giả của một ô; chưa có thì tạo với kịch bản mặc định (ngoan).
    [[nodiscard]] Actor& actor(const Slot& slot) {
        Actor* const found = known(slot);
        if (found != nullptr) return *found;
        Actor fresh;
        fresh.slot = slot;
        actors_.push_back(fresh);
        return actors_.back();
    }

    [[nodiscard]] core::Result<PostgresState> postgres_status() override {
        const core::ErrorCode code = core::ErrorCode::kIo;
        if (!database_.answers_status) return core::fail(code, "pg_ctl giả không trả lời");
        return database_.state;
    }

    [[nodiscard]] core::Status postgres_start(Milliseconds /*timeout*/) override {
        ++database_.start_calls;
        if (!database_.starts) return core::fail(core::ErrorCode::kTimeout, "pg_ctl giả hết hạn");
        database_.state = PostgresState::kUp;
        return core::ok();
    }

    [[nodiscard]] core::Status postgres_stop(Milliseconds /*timeout*/) override {
        ++database_.stop_calls;
        if (!database_.stops) return core::fail(core::ErrorCode::kIo, "pg_ctl giả không dừng");
        database_.state = PostgresState::kDown;
        return core::ok();
    }

    [[nodiscard]] core::Status launch(const Slot& slot) override {
        Actor& one = actor(slot);
        if (one.fails_launch) return core::fail(core::ErrorCode::kNotFound, "exe giả không có");
        one.is_alive = true;
        one.has_said_ready = false;
        one.was_forced = false;
        ++one.launches;
        return core::ok();
    }

    void close_input(const Slot& slot) noexcept override {
        Actor* const one = known(slot);
        if (one == nullptr || !one->obeys_close || !one->is_alive) return;
        one->is_alive = false;
        one->exit_code = one->code_on_close;
    }

    void force_stop(const Slot& slot) noexcept override {
        Actor* const one = known(slot);
        if (one == nullptr) return;
        one->was_forced = true;
        one->is_alive = false;
        one->exit_code = 1;
    }

    [[nodiscard]] Poll poll(const Slot& slot) override {
        Actor& one = actor(slot);
        if (!one.is_alive) return poll_of(PollKind::kExited, one.exit_code);
        if (one.floods_output) return poll_of(PollKind::kTooLong);
        if (one.dies_before_ready) return die(one);
        if (!one.has_said_ready) return say_ready(one);
        if (one.deaths_after_ready > 0) return die(one);
        return poll_of(PollKind::kRunning);
    }

private:
    // Tiến trình giả đã có của một ô; nullptr khi chưa ai chạy hay nhắc tới ô đó. Không cấp phát,
    // nên hai hàm noexcept của Host gọi được.
    [[nodiscard]] Actor* known(const Slot& slot) noexcept {
        const auto same = [&](const Actor& one) { return supervise::same_slot(one.slot, slot); };
        const auto found = std::ranges::find_if(actors_, same);
        return found == actors_.end() ? nullptr : &*found;
    }

    Database database_;
    std::vector<Actor> actors_;
};

struct Trace {
    Lines out;
    Lines err;
    bool is_finished = false;
    int exit_code = 0;
};

inline void record_event(Trace& trace, const Event& event) {
    Lines& lines = event.stream == Stream::kOut ? trace.out : trace.err;
    lines.push_back(event.line);
}

inline void record(Trace& trace, const Outcome& outcome) {
    for (const Event& event : outcome.events) {
        record_event(trace, event);
    }
    trace.is_finished = outcome.finished;
    trace.exit_code = outcome.exit_code;
}

// Một lần chạy máy ở một thời điểm cố định, với một câu trả lời "có yêu cầu dừng không".
struct Moment {
    Time now;
    StopAsk stop = StopAsk::kNo;
};

// Chạy máy tới khi xong hoặc hết số nhịp; các dòng nối thêm vào trace.
inline void run_machine(Machine& machine, Script& script, Moment moment, Trace& trace) {
    int budget = kStepBudget;
    while (budget > 0 && !trace.is_finished) {
        record(trace, machine.advance(script, moment.now, moment.stop));
        --budget;
    }
}

[[nodiscard]] inline bool has_line(const Lines& lines, std::string_view piece) {
    const auto holds = [&](const std::string& line) { return line.contains(piece); };
    return std::ranges::any_of(lines, holds);
}

[[nodiscard]] inline Step one_slot(const Slot& slot) {
    Step step;
    step.role = slot.role;
    step.ready_timeout = kReadyLimit;
    step.slots.push_back(slot);
    return step;
}

[[nodiscard]] inline Plan plan_of(std::span<const Slot> slots) {
    Plan plan;
    plan.stop_timeout = kStopLimit;
    plan.max_restarts_per_hour = 3;
    for (const Slot& slot : slots) {
        plan.steps.push_back(one_slot(slot));
    }
    return plan;
}

[[nodiscard]] inline Plan cluster_plan() {
    constexpr std::array<Slot, 6> kSlots{{
        kStore,
        kAuth,
        {.role = Role::kBilling, .id = 0},
        {.role = Role::kWorld, .id = 0},
        {.role = Role::kZone, .id = 0},
        {.role = Role::kGate, .id = std::nullopt},
    }};
    return plan_of(kSlots);
}

[[nodiscard]] inline Plan store_plan() {
    return plan_of(std::span{&kStore, 1});
}

[[nodiscard]] inline Plan managed_plan() {
    Plan plan = cluster_plan();
    plan.postgres = PostgresMode::kManage;
    plan.postgres_timeout = std::chrono::seconds{60};
    return plan;
}

} // namespace game::test
