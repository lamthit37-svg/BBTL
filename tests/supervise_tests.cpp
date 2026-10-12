// Máy trạng thái của trình giám sát với bộ chạy giả và đồng hồ giả: thứ tự chạy và dừng, yêu cầu
// dừng tới sớm, hết hạn ready, chết trước và sau ready, trần chạy lại, dòng quá trần, exe không
// chạy được, buộc dừng khi quá hạn, mã thoát của con, PostgreSQL chạy sẵn, chưa chạy và hỏng; bộ
// đọc dòng ready của con, dòng ready của cụm mang cổng, dòng ports khi con chạy lại ở cổng khác.
#include "core/check.hpp"
#include "supervise/supervise.hpp"
#include "supervise_script.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

void starts_in_order_then_stops_in_reverse(Context& context) {
    Script script;
    Machine machine{cluster_plan()};
    Trace rising;
    run_machine(machine, script, Moment{}, rising);
    context.expect(std::ranges::equal(rising.out, kStartLines), "sáu dòng started rồi ready");
    context.expect(!rising.is_finished, "không có yêu cầu dừng thì cụm chạy mãi");
    context.expect(rising.err.empty(), "chạy êm thì stderr trống");
    Trace down;
    run_machine(machine, script, Moment{.now = {}, .stop = StopAsk::kYes}, down);
    context.expect(std::ranges::equal(down.out, kStopLines), "dừng ngược thứ tự");
    context.expect(down.is_finished && down.exit_code == 0, "dừng theo yêu cầu thì thoát 0");
    context.expect(machine.finished(), "máy báo đã xong");
}

// stdin đóng từ trước khi chạy: vẫn khởi động đủ, in ready, rồi mới dừng.
void early_stop_request_waits_for_startup(Context& context) {
    Script script;
    Machine machine{cluster_plan()};
    Trace trace;
    run_machine(machine, script, Moment{.now = {}, .stop = StopAsk::kYes}, trace);
    const std::span<const std::string> lines{trace.out};
    context.expect(lines.size() == 13, "đủ 13 dòng");
    if (lines.size() != 13) return;
    context.expect(std::ranges::equal(lines.first(7), kStartLines), "khởi động đủ trước");
    context.expect(std::ranges::equal(lines.last(6), kStopLines), "rồi dừng ngược thứ tự");
    context.expect(trace.is_finished && trace.exit_code == 0, "thoát 0");
}

void ready_timeout_stops_what_started(Context& context) {
    Script script;
    script.actor(kStore).says_ready = false;
    Machine machine{store_plan()};
    Trace early;
    const Time start{};
    record(early, machine.advance(script, start, StopAsk::kNo));
    record(early, machine.advance(script, start + std::chrono::seconds{9}, StopAsk::kNo));
    context.expect(!early.is_finished && early.err.empty(), "chưa tới hạn thì còn chờ");
    Trace late;
    run_machine(machine, script, Moment{.now = start + kReadyLimit, .stop = StopAsk::kNo}, late);
    context.expect(late.is_finished && late.exit_code == 1, "hết hạn ready thì thoát 1");
    context.expect(has_line(late.err, "hết hạn chờ store 0"), "báo hết hạn chờ");
    context.expect(!has_line(late.out, "ready"), "không in ready");
    context.expect(has_line(late.out, "stopped store 0"), "dừng con đã chạy");
}

void death_before_ready_stops_cluster(Context& context) {
    constexpr std::array<Slot, 2> kSlots{kStore, kAuth};
    Script script;
    script.actor(kAuth).dies_before_ready = true;
    Machine machine{plan_of(kSlots)};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    context.expect(trace.is_finished && trace.exit_code == 1, "chết trước ready thì thoát 1");
    context.expect(has_line(trace.err, "auth 0 thoát mã 1 trước khi sẵn sàng"), "báo ai chết");
    context.expect(!has_line(trace.out, "ready"), "không in ready");
    constexpr std::array<std::string_view, 4> kWant{
        "started store 0", "started auth 0", "stopped auth 0", "stopped store 0"};
    context.expect(std::ranges::equal(trace.out, kWant), "dừng ngược thứ tự những con đã chạy");
}

void oversized_line_stops_cluster(Context& context) {
    Script script;
    script.actor(kStore).floods_output = true;
    Machine machine{store_plan()};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    context.expect(trace.is_finished && trace.exit_code == 1, "dòng quá trần thì thoát 1");
    context.expect(has_line(trace.err, "store 0 gửi dòng dài quá trần"), "báo dòng quá trần");
}

using supervise::ReadyFault;
using supervise::ReadyPorts;

[[nodiscard]] bool faults_with(std::string_view line, ReadyFault fault) noexcept {
    const std::expected<ReadyPorts, ReadyFault> parsed = supervise::parse_ready(line);
    return !parsed.has_value() && parsed.error() == fault;
}

[[nodiscard]] bool reads_as(std::string_view line, const ReadyPorts& wanted) noexcept {
    const std::expected<ReadyPorts, ReadyFault> parsed = supervise::parse_ready(line);
    return parsed.has_value() && *parsed == wanted;
}

// Dòng ready của con: từ `ready` rồi các cặp `khoá=số`; mỗi nhánh của bộ đọc một phép thử.
void ready_line_parses_ports_and_names_each_fault(Context& context) {
    context.expect(reads_as("ready", ReadyPorts{}), "ready trần: không cổng nào");
    context.expect(reads_as("ready game=41001 auth=41002", ReadyPorts{.game = 41001, .auth = 41002}), "hai cổng của gate");
    const ReadyPorts all{.ipc = 1, .game = 2, .auth = 3, .metrics = 65535};
    context.expect(reads_as("ready metrics=65535 auth=3 game=2 ipc=1", all), "đủ bốn khoá, thứ tự bất kỳ, biên 1 và 65535");
    context.expect(reads_as("ready game=7 mode=standalone zone=x", ReadyPorts{.game = 7}), "khoá lạ bị bỏ qua");
    context.expect(faults_with("", ReadyFault::kNotReady), "dòng rỗng");
    context.expect(faults_with("readyx game=1", ReadyFault::kNotReady), "từ đầu khác ready");
    context.expect(faults_with("gate: ready", ReadyFault::kNotReady), "ready không đứng đầu");
    context.expect(faults_with("ready ", ReadyFault::kPair), "dấu cách thừa cuối dòng");
    context.expect(faults_with("ready  game=1", ReadyFault::kPair), "hai dấu cách liền nhau");
    context.expect(faults_with("ready game", ReadyFault::kPair), "từ không có dấu bằng");
    context.expect(faults_with("ready =1", ReadyFault::kPair), "khoá rỗng");
    context.expect(faults_with("ready game=1 game=4", ReadyFault::kDuplicate), "khoá cổng lặp");
    context.expect(faults_with("ready game=x", ReadyFault::kNumber), "cổng không phải số");
    context.expect(faults_with("ready game=", ReadyFault::kNumber), "cổng rỗng");
    context.expect(faults_with("ready game=12x", ReadyFault::kNumber), "số có đuôi lạ");
    context.expect(faults_with("ready game=-1", ReadyFault::kNumber), "số âm");
    context.expect(faults_with("ready game=0", ReadyFault::kRange), "cổng 0");
    context.expect(faults_with("ready game=65536", ReadyFault::kRange), "cổng 65536");
    context.expect(faults_with("ready game=99999999999999999999", ReadyFault::kRange), "số tràn 32 bit");
    constexpr std::array<ReadyFault, 5> kFaults{ReadyFault::kNotReady, ReadyFault::kPair, ReadyFault::kDuplicate,
        ReadyFault::kNumber, ReadyFault::kRange};
    const auto has_text = [](ReadyFault fault) { return !supervise::describe(fault).empty(); };
    context.expect(std::ranges::all_of(kFaults, has_text), "mỗi lỗi có một câu cho stderr");
}

constexpr Slot kZone{.role = Role::kZone, .id = 0};
constexpr Slot kGate{.role = Role::kGate, .id = std::nullopt};

// Dòng ready của cụm mang mọi cổng các con báo, theo thứ tự khởi động và thứ tự khoá cố định.
void cluster_ready_line_carries_child_ports(Context& context) {
    constexpr std::array<Slot, 3> kSlots{kStore, kZone, kGate};
    Script script;
    script.actor(kZone).ready_line = "ready metrics=9 ipc=8";
    script.actor(kGate).ready_line = "ready game=40001 auth=40002";
    Machine machine{plan_of(kSlots)};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    context.expect(!trace.is_finished && trace.err.empty(), "cụm chạy êm");
    const std::string_view kWant = "ready zone.0.ipc=8 zone.0.metrics=9 gate.game=40001 gate.auth=40002";
    context.expect(!trace.out.empty() && trace.out.back() == kWant, "store không báo cổng; zone và gate có");
}

// Con chạy lại ở cổng khác thì máy in một dòng `ports` cho riêng con đó; cổng cũ thì im lặng.
void restart_on_new_ports_is_announced(Context& context) {
    constexpr std::array<Slot, 2> kSlots{kStore, kGate};
    Script script;
    script.actor(kGate).ready_line = "ready game=40001 auth=40002";
    Machine machine{plan_of(kSlots)};
    Trace first;
    run_machine(machine, script, Moment{}, first);
    script.actor(kGate).deaths_after_ready = 1;
    script.actor(kGate).ready_line = "ready game=40011 auth=40012";
    Trace moved;
    run_machine(machine, script, Moment{}, moved);
    context.expect(has_line(moved.err, "gate thoát, chạy lại"), "gate chết thì chạy lại");
    const bool is_told = moved.out.size() == 1 && moved.out.front() == "ports gate.game=40011 gate.auth=40012";
    context.expect(is_told, "cổng mới của gate được báo bằng đúng một dòng ports");
    script.actor(kGate).deaths_after_ready = 1;
    Trace same;
    run_machine(machine, script, Moment{}, same);
    context.expect(script.actor(kGate).launches == 3 && same.out.empty(), "chạy lại ở cổng cũ thì không in gì");
}

// Con gửi dòng ready hỏng là con hỏng: cụm dừng, thoát 1, không in ready của cụm.
void broken_ready_line_stops_cluster(Context& context) {
    constexpr std::array<Slot, 2> kSlots{kStore, kGate};
    Script script;
    script.actor(kGate).ready_line = "ready game=0 auth=40002";
    Machine machine{plan_of(kSlots)};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    context.expect(trace.is_finished && trace.exit_code == 1, "dòng ready hỏng thì thoát 1");
    context.expect(has_line(trace.err, "gate gửi dòng ready hỏng: cổng ngoài 1..65535"), "báo con nào và hỏng gì");
    context.expect(!has_line(trace.out, "ready"), "không in ready của cụm");
    context.expect(has_line(trace.out, "stopped store 0"), "dừng con đã chạy");
}

// Dòng khác của con trước dòng ready bị bỏ qua, như trước khi dòng ready mang cổng.
void other_lines_before_ready_are_ignored(Context& context) {
    Script script;
    script.actor(kStore).ready_line = "đang nạp bảng";
    Machine machine{store_plan()};
    Trace early;
    record(early, machine.advance(script, Time{}, StopAsk::kNo));
    record(early, machine.advance(script, Time{}, StopAsk::kNo));
    context.expect(!early.is_finished && early.err.empty(), "dòng lạ không làm hỏng cụm");
    context.expect(!has_line(early.out, "ready"), "và cũng không được coi là ready");
}

// Trần của dòng ready: `ready` cộng, cho mỗi ô, bốn cặp ` <ô>.<khoá>=<cổng năm chữ số>`.
void ready_line_bound_counts_every_slot(Context& context) {
    context.expect(supervise::ready_line_bound(Plan{}) == 5, "kế hoạch rỗng: chỉ có từ ready");
    constexpr std::array<Slot, 1> kOnlyGate{kGate};
    // gate: 4 × (1 + 4 + 1 + 1 + 5) + độ dài bốn khoá 18 = 66.
    context.expect(supervise::ready_line_bound(plan_of(kOnlyGate)) == 5 + 66, "gate không có số");
    constexpr std::array<Slot, 2> kTwo{kGate, Slot{.role = Role::kZone, .id = 12}};
    // zone.12: tên ô dài 7, nên 4 × (1 + 7 + 1 + 1 + 5) + 18 = 78.
    context.expect(supervise::ready_line_bound(plan_of(kTwo)) == 5 + 66 + 78, "ô có số dài hơn");
    Script script;
    script.actor(kGate).ready_line = "ready ipc=65535 game=65535 auth=65535 metrics=65535";
    Machine machine{plan_of(kOnlyGate)};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    const bool fits = !trace.out.empty() && trace.out.back().size() == supervise::ready_line_bound(plan_of(kOnlyGate));
    context.expect(fits, "dòng dài nhất của máy đúng bằng trần đã tính");
}

void launch_failure_stops_cluster(Context& context) {
    constexpr std::array<Slot, 2> kSlots{kStore, kAuth};
    Script script;
    script.actor(kAuth).fails_launch = true;
    Machine machine{plan_of(kSlots)};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    context.expect(trace.is_finished && trace.exit_code == 1, "exe không chạy được thì thoát 1");
    context.expect(has_line(trace.err, "không chạy được auth 0"), "báo ô không chạy được");
    context.expect(has_line(trace.err, "exe giả không có"), "kèm nguyên nhân của bộ chạy");
    constexpr std::array<std::string_view, 2> kWant{"started store 0", "stopped store 0"};
    context.expect(std::ranges::equal(trace.out, kWant), "con đã chạy được dừng lại");
}

void death_after_ready_restarts_until_ceiling(Context& context) {
    Script script;
    Plan plan = store_plan();
    plan.max_restarts_per_hour = 1;
    Machine machine{std::move(plan)};
    Trace first;
    run_machine(machine, script, Moment{}, first);
    script.actor(kStore).deaths_after_ready = 1;
    Trace second;
    run_machine(machine, script, Moment{}, second);
    context.expect(has_line(second.err, "store 0 thoát, chạy lại"), "chết sau ready thì chạy lại");
    context.expect(!second.is_finished, "chạy lại xong thì cụm chạy tiếp");
    context.expect(script.actor(kStore).launches == 2, "đã chạy lại một lần");
    script.actor(kStore).deaths_after_ready = 1;
    Trace third;
    run_machine(machine, script, Moment{}, third);
    context.expect(third.is_finished && third.exit_code == 1, "vượt trần thì dừng cụm, thoát 1");
    context.expect(has_line(third.err, "store 0 vượt trần chạy lại mỗi giờ"), "báo vượt trần");
    context.expect(script.actor(kStore).launches == 2, "không chạy lại lần thứ hai");
}

void restart_ceiling_forgets_after_an_hour(Context& context) {
    Script script;
    Plan plan = store_plan();
    plan.max_restarts_per_hour = 1;
    Machine machine{std::move(plan)};
    const Time start{};
    Trace first;
    script.actor(kStore).deaths_after_ready = 1;
    run_machine(machine, script, Moment{.now = start, .stop = StopAsk::kNo}, first);
    context.expect(script.actor(kStore).launches == 2, "lần chết đầu được chạy lại");
    script.actor(kStore).deaths_after_ready = 1;
    const Time later = start + std::chrono::hours{1} + Milliseconds{1};
    Trace second;
    run_machine(machine, script, Moment{.now = later, .stop = StopAsk::kNo}, second);
    context.expect(!second.is_finished, "qua một giờ thì lần chết sau lại được chạy lại");
    context.expect(script.actor(kStore).launches == 3, "đã chạy lại lần nữa");
}

void stubborn_child_is_forced_after_stop_timeout(Context& context) {
    Script script;
    script.actor(kStore).obeys_close = false;
    Machine machine{store_plan()};
    const Time start{};
    Trace rising;
    run_machine(machine, script, Moment{.now = start, .stop = StopAsk::kNo}, rising);
    Trace waiting;
    record(waiting, machine.advance(script, start, StopAsk::kYes));
    record(waiting, machine.advance(script, start, StopAsk::kYes));
    record(waiting, machine.advance(script, start + std::chrono::seconds{4}, StopAsk::kYes));
    context.expect(!script.actor(kStore).was_forced, "chưa tới hạn thì chưa buộc dừng");
    Trace forced;
    run_machine(machine, script, Moment{.now = start + kStopLimit, .stop = StopAsk::kYes}, forced);
    context.expect(script.actor(kStore).was_forced, "quá hạn thì buộc dừng");
    context.expect(has_line(forced.err, "quá hạn dừng store 0, buộc dừng"), "ghi lỗi buộc dừng");
    context.expect(has_line(forced.out, "stopped store 0"), "vẫn báo đã dừng");
    context.expect(forced.is_finished && forced.exit_code == 1, "buộc dừng là lỗi lúc chạy");
}

void nonzero_exit_at_stop_is_an_error(Context& context) {
    Script script;
    script.actor(kStore).code_on_close = 3;
    Machine machine{store_plan()};
    Trace trace;
    run_machine(machine, script, Moment{.now = {}, .stop = StopAsk::kYes}, trace);
    context.expect(has_line(trace.out, "stopped store 0"), "con vẫn được báo đã dừng");
    const bool has_failed = trace.is_finished && trace.exit_code == 1;
    context.expect(has_failed, "con thoát khác 0 thì giám sát thoát 1");
}

void two_zones_share_one_step(Context& context) {
    constexpr Slot kZoneOne{.role = Role::kZone, .id = 1};
    Step zones = one_slot(Slot{.role = Role::kZone, .id = 0});
    zones.slots.push_back(kZoneOne);
    Plan plan;
    plan.stop_timeout = kStopLimit;
    plan.steps.push_back(std::move(zones));
    Script script;
    Machine machine{std::move(plan)};
    Trace trace;
    run_machine(machine, script, Moment{.now = {}, .stop = StopAsk::kYes}, trace);
    constexpr std::array<std::string_view, 5> kWant{
        "started zone 0", "started zone 1", "ready", "stopped zone 1", "stopped zone 0"};
    context.expect(std::ranges::equal(trace.out, kWant), "hai zone chạy lần lượt, dừng ngược lại");
}

void running_postgres_is_used_and_left_alone(Context& context) {
    Script script;
    script.database().state = PostgresState::kUp;
    Machine machine{managed_plan()};
    Trace trace;
    run_machine(machine, script, Moment{.now = {}, .stop = StopAsk::kYes}, trace);
    context.expect(!trace.out.empty() && trace.out.front() == "using postgres", "dùng cụm có sẵn");
    const Database& database = script.database();
    const bool is_untouched = database.start_calls == 0 && database.stop_calls == 0;
    context.expect(is_untouched, "không chạy, không dừng cụm");
    context.expect(!has_line(trace.out, "stopped postgres"), "không in stopped postgres");
    context.expect(trace.out.size() == 14, "using postgres và 13 dòng của cụm");
    context.expect(trace.is_finished && trace.exit_code == 0, "thoát 0");
}

void stopped_postgres_is_started_then_stopped(Context& context) {
    Script script;
    Machine machine{managed_plan()};
    Trace trace;
    run_machine(machine, script, Moment{.now = {}, .stop = StopAsk::kYes}, trace);
    context.expect(trace.out.size() == 15, "đủ 15 dòng");
    if (trace.out.size() != 15) return;
    context.expect(trace.out.front() == "started postgres", "PostgreSQL chạy đầu tiên");
    context.expect(trace.out.back() == "stopped postgres", "PostgreSQL dừng sau cùng");
    const Database& database = script.database();
    const bool is_once = database.start_calls == 1 && database.stop_calls == 1;
    context.expect(is_once, "chạy một lần, dừng một lần");
    context.expect(database.state == PostgresState::kDown, "cụm đã dừng");
    context.expect(trace.is_finished && trace.exit_code == 0, "thoát 0");
}

void postgres_start_failure_runs_nothing(Context& context) {
    Script script;
    script.database().starts = false;
    Machine machine{managed_plan()};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    context.expect(trace.is_finished && trace.exit_code == 1, "PostgreSQL không chạy thì thoát 1");
    context.expect(trace.out.empty(), "không tiến trình nào được chạy");
    context.expect(has_line(trace.err, "PostgreSQL không chạy"), "báo PostgreSQL không chạy");
    context.expect(has_line(trace.err, "pg_ctl giả hết hạn"), "kèm nguyên nhân của bộ chạy");
}

void postgres_status_failure_runs_nothing(Context& context) {
    Script script;
    script.database().answers_status = false;
    Machine machine{managed_plan()};
    Trace trace;
    run_machine(machine, script, Moment{}, trace);
    context.expect(trace.is_finished && trace.exit_code == 1, "không hỏi được thì thoát 1");
    context.expect(trace.out.empty() && script.database().start_calls == 0, "không chạy gì");
    context.expect(has_line(trace.err, "không hỏi được PostgreSQL"), "báo không hỏi được");
}

void postgres_stop_failure_is_an_error(Context& context) {
    Script script;
    script.database().stops = false;
    Machine machine{managed_plan()};
    Trace trace;
    run_machine(machine, script, Moment{.now = {}, .stop = StopAsk::kYes}, trace);
    context.expect(trace.is_finished && trace.exit_code == 1, "PostgreSQL không dừng thì thoát 1");
    context.expect(has_line(trace.err, "PostgreSQL không dừng"), "báo PostgreSQL không dừng");
    context.expect(!has_line(trace.out, "stopped postgres"), "không in stopped postgres");
    context.expect(has_line(trace.out, "stopped store 0"), "các con vẫn dừng đủ");
}

constexpr std::array kCases{
    Case{.name = "starts_in_order_then_stops_in_reverse", .body = &starts_in_order_then_stops_in_reverse},
    Case{.name = "early_stop_request_waits_for_startup", .body = &early_stop_request_waits_for_startup},
    Case{.name = "ready_timeout_stops_what_started", .body = &ready_timeout_stops_what_started},
    Case{.name = "death_before_ready_stops_cluster", .body = &death_before_ready_stops_cluster},
    Case{.name = "oversized_line_stops_cluster", .body = &oversized_line_stops_cluster},
    Case{.name = "ready_line_parses_ports_and_names_each_fault", .body = &ready_line_parses_ports_and_names_each_fault},
    Case{.name = "cluster_ready_line_carries_child_ports", .body = &cluster_ready_line_carries_child_ports},
    Case{.name = "restart_on_new_ports_is_announced", .body = &restart_on_new_ports_is_announced},
    Case{.name = "broken_ready_line_stops_cluster", .body = &broken_ready_line_stops_cluster},
    Case{.name = "other_lines_before_ready_are_ignored", .body = &other_lines_before_ready_are_ignored},
    Case{.name = "ready_line_bound_counts_every_slot", .body = &ready_line_bound_counts_every_slot},
    Case{.name = "launch_failure_stops_cluster", .body = &launch_failure_stops_cluster},
    Case{.name = "death_after_ready_restarts_until_ceiling", .body = &death_after_ready_restarts_until_ceiling},
    Case{.name = "restart_ceiling_forgets_after_an_hour", .body = &restart_ceiling_forgets_after_an_hour},
    Case{.name = "stubborn_child_is_forced_after_stop_timeout", .body = &stubborn_child_is_forced_after_stop_timeout},
    Case{.name = "nonzero_exit_at_stop_is_an_error", .body = &nonzero_exit_at_stop_is_an_error},
    Case{.name = "two_zones_share_one_step", .body = &two_zones_share_one_step},
    Case{.name = "running_postgres_is_used_and_left_alone", .body = &running_postgres_is_used_and_left_alone},
    Case{.name = "stopped_postgres_is_started_then_stopped", .body = &stopped_postgres_is_started_then_stopped},
    Case{.name = "postgres_start_failure_runs_nothing", .body = &postgres_start_failure_runs_nothing},
    Case{.name = "postgres_status_failure_runs_nothing", .body = &postgres_status_failure_runs_nothing},
    Case{.name = "postgres_stop_failure_is_an_error", .body = &postgres_stop_failure_is_an_error},
};

} // namespace
} // namespace game::test

int main() {
    const bool passed = game::test::run_all(game::test::kCases) == 0;
    game::core::check(passed, "supervise_tests");
    return 0;
}
