#include "config/supervisor.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"
#include "config/types.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <optional>
#include <string_view>
#include <vector>

namespace game::config {
namespace {

using detail::add_issue;
using detail::Bag;
using detail::Choice;
using detail::Cursor;
using detail::keep;
using detail::Node;
using detail::Presence;

constexpr std::array<std::string_view, 5> kRoot{"schema", "postgres", "restart", "stop", "start"};
constexpr std::array<std::string_view, 2> kPostgres{"managed", "ready_timeout_seconds"};
constexpr std::array<std::string_view, 1> kRestart{"max_per_hour"};
constexpr std::array<std::string_view, 1> kStop{"timeout_seconds"};
constexpr std::array<std::string_view, 2> kStart{"process", "ready_timeout_seconds"};
constexpr std::array<Choice<ServiceKind>, 6> kServices{{
    {.name = "store", .value = ServiceKind::kStore},
    {.name = "auth", .value = ServiceKind::kAuth},
    {.name = "billing", .value = ServiceKind::kBilling},
    {.name = "world", .value = ServiceKind::kWorld},
    {.name = "zone", .value = ServiceKind::kZone},
    {.name = "gate", .value = ServiceKind::kGate},
}};
constexpr std::size_t kStepMost = 16;

void read_postgres(Bag& bag, const Node* table, SupervisorPostgres& postgres) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kPostgres);
    keep(cursor.flag("managed"), postgres.managed);
    keep(cursor.seconds("ready_timeout_seconds"), postgres.ready_timeout_seconds);
}

void read_restart(Bag& bag, const Node* table, SupervisorRestart& restart) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kRestart);
    keep(cursor.bounded("max_per_hour", detail::kAmount), restart.max_per_hour);
}

void read_stop(Bag& bag, const Node* table, SupervisorStop& stop) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kStop);
    keep(cursor.seconds("timeout_seconds"), stop.timeout_seconds);
}

// Mỗi loại tiến trình chỉ được có một bước: bước lặp là lỗi ở dòng của khối lặp.
void read_start(Bag& bag, const Node& table, std::vector<StartStep>& steps) {
    Cursor cursor{bag, table};
    cursor.only(kStart);
    const std::optional<ServiceKind> process = cursor.choice("process", kServices);
    const std::optional<std::chrono::seconds> timeout = cursor.seconds("ready_timeout_seconds");
    if (!process || !timeout) return;
    const bool is_repeated = std::ranges::contains(steps, *process, &StartStep::process);
    if (is_repeated) add_issue(bag, table.line, "process của start lặp");
    StartStep step;
    step.line = table.line;
    step.process = *process;
    step.ready_timeout_seconds = *timeout;
    steps.push_back(step);
}

[[nodiscard]] Supervisor read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Supervisor supervisor;
    read_postgres(bag, cursor.child("postgres"), supervisor.postgres);
    read_restart(bag, cursor.child("restart"), supervisor.restart);
    read_stop(bag, cursor.child("stop"), supervisor.stop);
    for (const Node* start : cursor.rows("start", Presence::kRequired, kStepMost)) {
        read_start(bag, *start, supervisor.steps);
    }
    return supervisor;
}

} // namespace

ReadResult<Supervisor> read_supervisor(std::string_view text) {
    return detail::read_document<Supervisor>(text, read_sections);
}

} // namespace game::config
