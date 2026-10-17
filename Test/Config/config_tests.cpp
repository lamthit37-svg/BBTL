// Bộ đọc cấu hình. Ca đúng đọc nguyên văn tệp thật trong dev/server/config (đường dẫn do CMake đưa),
// trừ secrets: test không bao giờ mở secrets.local.toml. Ca sai là chuỗi trong config_samples.hpp.
#include "config/admin.hpp"
#include "config/auth.hpp"
#include "config/billing.hpp"
#include "config/client.hpp"
#include "config/cluster.hpp"
#include "config/gate.hpp"
#include "config/issue.hpp"
#include "config/log.hpp"
#include "config/loose.hpp"
#include "config/secrets.hpp"
#include "config/startup.hpp"
#include "config/store.hpp"
#include "config/supervisor.hpp"
#include "config/types.hpp"
#include "config/world.hpp"
#include "config/zone.hpp"
#include "config_samples.hpp"
#include "core/check.hpp"
#include "io/file.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <filesystem>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using config::Issue;
using config::IssueList;

#ifdef GAME_SERVER_CONFIG
constexpr View kConfigDir = GAME_SERVER_CONFIG;
#else
// check.py dịch tệp này không có định nghĩa của CMake; đường dẫn từ gốc dự án để tệp tự đứng được.
constexpr View kConfigDir = "dev/server/config";
#endif

using IssueReader = IssueList (*)(View);

template <auto Reader>
[[nodiscard]] IssueList issues_of(View text) {
    auto result = Reader(text);
    if (result) return {};
    return std::move(result.error());
}

// Một bộ đọc và một khoá hay nhóm bắt buộc ở gốc tệp của nó.
struct ReaderEntry {
    Which which = Which::kCluster;
    IssueReader read = nullptr;
    View required;
};

constexpr std::array<ReaderEntry, 13> kReaders{{
    {.which = Which::kCluster, .read = &issues_of<&config::read_cluster>, .required = "world"},
    {.which = Which::kSupervisor, .read = &issues_of<&config::read_supervisor>, .required = "stop"},
    {.which = Which::kLog, .read = &issues_of<&config::read_log>, .required = "audit"},
    {.which = Which::kGate, .read = &issues_of<&config::read_gate>, .required = "listen"},
    {.which = Which::kAuth, .read = &issues_of<&config::read_auth>, .required = "database"},
    {.which = Which::kBilling, .read = &issues_of<&config::read_billing>, .required = "database"},
    {.which = Which::kWorld, .read = &issues_of<&config::read_world>, .required = "capacity"},
    {.which = Which::kZone, .read = &issues_of<&config::read_zone>, .required = "tick"},
    {.which = Which::kStore, .read = &issues_of<&config::read_store>, .required = "database"},
    {.which = Which::kAdmin, .read = &issues_of<&config::read_admin>, .required = "listen"},
    {.which = Which::kClient, .read = &issues_of<&config::read_client>, .required = "hud"},
    {.which = Which::kSecrets, .read = &issues_of<&config::read_secrets>, .required = "database"},
    {.which = Which::kLoose, .read = &issues_of<&config::read_loose>, .required = "schema"},
}};

[[nodiscard]] IssueList read_as(Which which, View text) {
    const auto entry = std::ranges::find(kReaders, which, &ReaderEntry::which);
    core::check(entry != kReaders.end(), "bộ đọc chưa có trong bảng");
    return entry->read(text);
}

[[nodiscard]] bool has_issue(const IssueList& issues, std::size_t line, View part) {
    const auto matches = [&](const Issue& issue) { return issue.line == line && issue.message.contains(part); };
    return std::ranges::any_of(issues, matches);
}

void expect_sample(Context& context, const Sample& sample) {
    const IssueList issues = read_as(sample.which, sample.text);
    context.expect(has_issue(issues, sample.line, sample.part), sample.part);
}

void bad_samples_are_reported_with_line(Context& context) {
    for (const Sample& sample : kSamples) {
        expect_sample(context, sample);
    }
}

// Bốn lỗi mọi bộ đọc đều phải bắt: khoá lạ ở gốc, thiếu khoá bắt buộc, schema sai kiểu, schema lạ.
void expect_common_errors(Context& context, const ReaderEntry& entry) {
    const std::string missing = std::format("thiếu khoá {}", entry.required);
    const bool is_strict = entry.which != Which::kLoose;
    const IssueList extra = entry.read("schema = 1\nextra = 1\n");
    context.expect(!is_strict || has_issue(extra, 2, "khoá lạ extra"), "khoá lạ có số dòng");
    const IssueList bare = entry.read(is_strict ? "schema = 1\n" : "");
    context.expect(has_issue(bare, 1, missing), "thiếu khoá bắt buộc");
    context.expect(has_issue(entry.read("schema = true\n"), 1, "khoá schema sai kiểu"), "sai kiểu");
    context.expect(has_issue(entry.read("schema = 2\n"), 1, "khoá schema ngoài miền"), "schema lạ");
}

void every_reader_rejects_common_errors(Context& context) {
    for (const ReaderEntry& entry : kReaders) {
        expect_common_errors(context, entry);
    }
}

void every_error_is_reported_sorted_by_line(Context& context) {
    constexpr View kText = "schema = 2\n[file]\ndir = \"\"\nrotate_mb = 0\nextra = 1\n";
    const IssueList issues = read_as(Which::kLog, kText);
    const bool has_all = has_issue(issues, 1, "schema ngoài miền") && has_issue(issues, 1, "thiếu khoá audit") &&
        has_issue(issues, 1, "thiếu khoá level") && has_issue(issues, 3, "dir ngoài miền") &&
        has_issue(issues, 4, "rotate_mb ngoài miền") && has_issue(issues, 5, "khoá lạ extra");
    context.expect(has_all, "một lần đọc trả đủ sáu lỗi");
    context.expect(issues.size() == 6, "không lỗi thừa");
    context.expect(std::ranges::is_sorted(issues, {}, &Issue::line), "lỗi xếp theo dòng");
}

// cluster.toml có [world] name dài size byte bị từ chối ở đúng dòng của khoá.
[[nodiscard]] bool is_name_refused(std::size_t size) {
    const std::string name(size, 'a');
    const std::string text = std::format("schema = 1\n[world]\nname = \"{}\"\n", name);
    const IssueList issues = read_as(Which::kCluster, text);
    return has_issue(issues, 3, "khoá name ngoài miền");
}

void long_text_is_out_of_domain(Context& context) {
    context.expect(!is_name_refused(64), "64 byte còn vừa");
    context.expect(is_name_refused(65), "65 byte là quá");
    context.expect(is_name_refused(5000), "quá trần bộ dịch");
    constexpr View kSecret = "schema = 1\n[database.postgres]\npassword = \"{}\"\n";
    const std::string long_password(257, 'p');
    const std::string text = std::format(kSecret, long_password);
    const IssueList secret = read_as(Which::kSecrets, text);
    context.expect(has_issue(secret, 3, "khoá password ngoài miền"), "mật khẩu 257 byte là quá");
}

void oversized_document_is_refused(Context& context) {
    std::string wide = "schema = 1\n";
    for (int index = 0; index < 300; ++index) {
        wide += std::format("key{} = 1\n", index);
    }
    context.expect(has_issue(read_as(Which::kLoose, wide), 1, "vượt trần cấu trúc"), "300 khoá");
    const std::string huge(1048577, '#');
    context.expect(has_issue(read_as(Which::kLoose, huge), 1, "vượt trần 1048576 byte"), "tệp lớn");
}

void duplicate_process_pair_is_an_error(Context& context) {
    constexpr View kText = "schema = 1\n"
                           "[[machine]]\n"
                           "id = 0\n"
                           "[[process]]\n"
                           "kind = \"store\"\n"
                           "id = 0\n"
                           "machine = 0\n"
                           "host = \"127.0.0.1\"\n"
                           "port = 1\n"
                           "[[process]]\n"
                           "kind = \"store\"\n"
                           "id = 0\n"
                           "machine = 7\n"
                           "host = \"127.0.0.1\"\n"
                           "port = 2\n";
    const IssueList issues = read_as(Which::kCluster, kText);
    context.expect(has_issue(issues, 10, "cặp kind và id lặp"), "cặp lặp báo ở khối sau");
    context.expect(has_issue(issues, 10, "máy không có trong danh sách"), "máy 7 không có");
    context.expect(!has_issue(issues, 4, "lặp"), "khối đầu không bị báo");
}

// Cổng 0 (hệ điều hành chọn) chỉ được khai cho bên nghe trên đúng 127.0.0.1: [listen] của gate và
// [[process]] của cụm nhận, mọi địa chỉ khác và [postgres] thì không (mẫu hỏng ở config_samples.hpp).
void loopback_listeners_may_ask_for_any_port(Context& context) {
    const std::optional<config::Endpoint> any = config::Endpoint::parse("127.0.0.1:0");
    context.expect(any.has_value() && any->port.value() == 0, "127.0.0.1:0 được nhận, cổng là 0");
    context.expect(any.has_value() && config::is_loopback(any->host), "địa chỉ là đúng loopback");
    context.expect(!config::Endpoint::parse("0.0.0.0:0").has_value(), "0.0.0.0:0 bị từ chối");
    context.expect(!config::Endpoint::parse("127.0.0.2:0").has_value(), "127.0.0.2:0 bị từ chối");
    context.expect(!config::Endpoint::parse("127.0.0.1:00").has_value(), "cổng 00 không phải cổng 0");
    const std::optional<config::Endpoint> real = config::Endpoint::parse("10.1.2.3:41000");
    context.expect(real.has_value() && real->port.value() == 41000, "cổng thật ở địa chỉ khác vẫn được nhận");
    context.expect(!config::Port::parse(0).has_value(), "Port::parse vẫn từ chối 0");
    constexpr View kListen = "[listen]\ngame = \"127.0.0.1:0\"\nauth = \"127.0.0.1:0\"\n";
    const IssueList gate = read_as(Which::kGate, kListen);
    context.expect(!has_issue(gate, 2, "ngoài miền") && !has_issue(gate, 3, "ngoài miền"), "gate nhận cổng 0 ở loopback");
    constexpr View kProcess = "[[process]]\nkind = \"zone\"\nid = 0\nmachine = 0\n"
                              "host = \"127.0.0.1\"\nport = 0\n";
    context.expect(!has_issue(read_as(Which::kCluster, kProcess), 6, "ngoài miền"), "process nhận cổng 0 ở loopback");
}

void startup_needs_a_process_for_every_step(Context& context) {
    const auto cluster = config::read_cluster(kStoreOnlyCluster);
    const auto supervisor = config::read_supervisor(kSixStepSupervisor);
    context.expect(cluster.has_value() && supervisor.has_value(), "hai văn bản tối thiểu đọc được");
    if (!cluster || !supervisor) return;
    const config::StartupResult startup = config::check_startup(*cluster, *supervisor);
    context.expect(!startup.has_value(), "cụm chỉ có store thì không khởi động được");
    if (startup) return;
    const IssueList& issues = startup.error();
    context.expect(has_issue(issues, 12, "thiếu process auth trong cluster"), "bước auth");
    context.expect(has_issue(issues, 21, "thiếu process zone trong cluster"), "bước zone");
    context.expect(issues.size() == 4, "bốn loại thiếu; store có, gate không cần khối");
}

void repeated_start_step_is_an_error(Context& context) {
    const std::string text =
        std::format("{}[[start]]\nprocess = \"store\"\nready_timeout_seconds = 1\n", kSixStepSupervisor);
    const IssueList issues = read_as(Which::kSupervisor, text);
    context.expect(has_issue(issues, 27, "process của start lặp"), "bước lặp báo ở khối sau");
}

void loose_document_allows_unknown_keys(Context& context) {
    const auto result = config::read_loose("schema = 1\nextra = 2\n[group]\nx = true\n");
    context.expect(result.has_value() && result->schema == 1, "tệp chưa có struct chỉ cần schema");
}

// Nguyên văn một tệp thật; rỗng và một kỳ vọng sai khi không đọc được.
[[nodiscard]] std::string real_text(Context& context, View name) {
    const std::filesystem::path path = io::path_from_utf8(kConfigDir) / io::path_from_utf8(name);
    io::TextResult text = io::read_text(path);
    context.expect(text.has_value(), name);
    if (!text) return {};
    return std::move(*text);
}

template <typename Value>
using Reader = config::ReadResult<Value> (*)(View);

template <typename Value>
[[nodiscard]] std::optional<Value> real(Context& context, View name, Reader<Value> read) {
    config::ReadResult<Value> result = read(real_text(context, name));
    context.expect(result.has_value(), name);
    if (!result) return std::nullopt;
    return std::move(*result);
}

void real_rules_and_scene_have_schema(Context& context) {
    const std::optional rules = real(context, "rules/global.toml", config::read_loose);
    context.expect(rules.has_value() && rules->schema == 1, "rules/global.toml");
    const View scene_file = "../scenes/huoyangu/scene.toml";
    const std::optional scene = real(context, scene_file, config::read_loose);
    context.expect(scene.has_value() && scene->schema == 1, "scene.toml của một cảnh");
}

void real_cluster(Context& context) {
    const std::optional cluster = real(context, "cluster.toml", config::read_cluster);
    if (!cluster) return;
    const config::WorldSection& world = cluster->world;
    const bool is_world =
        world.id.value() == 1 && world.zone_group == 0 && world.name == "thienlong-test" && world.table_variant.empty();
    context.expect(is_world, "nhóm world");
    const config::PostgresPaths& postgres = cluster->postgres;
    const bool is_postgres = postgres.host.text() == "127.0.0.1" && postgres.port.value() == 5432 &&
        postgres.bin_dir == "../pgsql/bin" && postgres.data_dir == "../data/pg" &&
        postgres.log_file == "../log/postgres.log";
    context.expect(is_postgres, "nhóm postgres");
    const bool has_shape = cluster->machines.size() == 1 && cluster->processes.size() == 5;
    context.expect(has_shape, "một máy, năm tiến trình");
    if (!has_shape) return;
    constexpr std::array<config::ProcessKind, 5> kKinds{config::ProcessKind::kStore, config::ProcessKind::kAuth,
        config::ProcessKind::kBilling, config::ProcessKind::kWorld, config::ProcessKind::kZone};
    constexpr std::array<int, 5> kPorts{7010, 7011, 7012, 7013, 7020};
    const auto port_of = [](const config::ProcessBlock& block) { return block.port.value(); };
    const auto& blocks = cluster->processes;
    context.expect(std::ranges::equal(blocks, kKinds, {}, &config::ProcessBlock::kind), "loại");
    context.expect(std::ranges::equal(blocks, kPorts, {}, port_of), "cổng ipc");
    const config::ProcessBlock& store = blocks.front();
    const bool is_store = store.host.text() == "127.0.0.1" && store.id.value() == 0 && store.machine.value() == 0 &&
        cluster->machines.front().id.value() == 0;
    context.expect(is_store, "khối store");
}

// Thứ tự chạy và hạn `ready` từng bước của supervisor.toml thật.
constexpr std::array<config::ServiceKind, 6> kStepOrder{
    config::ServiceKind::kStore,
    config::ServiceKind::kAuth,
    config::ServiceKind::kBilling,
    config::ServiceKind::kWorld,
    config::ServiceKind::kZone,
    config::ServiceKind::kGate,
};
constexpr std::array<int, 6> kStepLimits{60, 120, 60, 180, 240, 60};

[[nodiscard]] auto step_limit(const config::StartStep& step) {
    return step.ready_timeout_seconds.count();
}

void real_supervisor(Context& context) {
    const std::optional plan = real(context, "supervisor.toml", config::read_supervisor);
    if (!plan) return;
    const auto& postgres = plan->postgres;
    context.expect(postgres.managed && postgres.ready_timeout_seconds.count() == 60, "postgres");
    context.expect(plan->restart.max_per_hour == 3, "restart");
    context.expect(plan->stop.timeout_seconds.count() == 30, "stop");
    const auto& steps = plan->steps;
    const bool is_ordered = std::ranges::equal(steps, kStepOrder, {}, &config::StartStep::process);
    context.expect(is_ordered, "thứ tự");
    const bool has_limits = std::ranges::equal(steps, kStepLimits, {}, step_limit);
    context.expect(has_limits, "hạn từng bước");
}

void real_log(Context& context) {
    const std::optional log = real(context, "log.toml", config::read_log);
    if (!log) return;
    const bool is_same =
        log->audit && log->dir == "../log" && log->rotate_mb == 64 && log->level == config::LogLevel::kInfo;
    context.expect(is_same, "log.toml");
}

void real_gate(Context& context) {
    const std::optional gate = real(context, "gate.toml", config::read_gate);
    if (!gate) return;
    const config::GateListen& listen = gate->listen;
    // Cụm thử nghe loopback 7100/7101: cổng 7000/7001 trên máy này do cụm TLBB giữ (gate.toml).
    const bool is_listen = gate->identity_key_file == "../data/gate/identity.key" && gate->trusted_proxies.empty() &&
        listen.game.host.text() == "127.0.0.1" && listen.game.port.value() == 7100 &&
        listen.auth.host.text() == "127.0.0.1" && listen.auth.port.value() == 7101;
    context.expect(is_listen, "khoá danh tính và cổng nghe");
    const config::GateLimits& limits = gate->limits;
    const bool is_limits = limits.max_connections == 2000 && limits.per_ip_connections == 8 &&
        limits.handshake_timeout_ms.count() == 5000 && limits.idle_timeout_ms.count() == 10000 &&
        limits.client_frame_bytes == 4096 && limits.messages_per_second == 60 && gate->client.min_version == 9;
    context.expect(is_limits, "trần chống lạm dụng");
    context.expect(gate->ip_filter.allow.empty() && gate->ip_filter.deny.empty(), "lọc địa chỉ");
}

void real_auth(Context& context) {
    const std::optional auth = real(context, "auth.toml", config::read_auth);
    if (!auth) return;
    const bool is_database =
        auth->database.name == "thienlong_auth" && auth->database.user == "thienlong_auth" && auth->database.pool == 2;
    context.expect(is_database, "database");
    context.expect(auth->auto_register && auth->gift_points == 0, "đăng ký");
    context.expect(auth->ops_limit == 2 && auth->mem_limit_kib == 65536, "băm");
    context.expect(auth->ttl_seconds.count() == 300, "vé");
    const bool is_login = !auth->relogin_limit && !auth->relogin_block && auth->relogin_block_ms.count() == 600000 &&
        auth->queue_turn_size == 100 && auth->max_sessions_per_device == 30;
    context.expect(is_login, "luật đăng nhập");
    context.expect(!auth->on_create && !auth->on_enter && !auth->security_card, "mã và thẻ");
}

void real_billing(Context& context) {
    const std::optional billing = real(context, "billing.toml", config::read_billing);
    if (!billing) return;
    const bool is_database = billing->database.name == "thienlong_billing" &&
        billing->database.user == "thienlong_billing" && billing->database.pool == 2;
    context.expect(is_database, "database");
    const bool is_access = billing->allow.size() == 1 && billing->allow.front() == "127.0.0.1";
    context.expect(is_access, "quyền gọi");
    const bool is_money = billing->max_clients == 500 && billing->ingot_per_point == 1 && billing->register_gift == 0 &&
        billing->daily_ingot_cap == 120000 && billing->attempts_per_hour == 10 && billing->providers.empty();
    context.expect(is_money, "điểm, hạn mức, mã đổi");
    const bool is_orders =
        billing->pending_timeout_seconds.count() == 600 && billing->reconcile_interval_seconds.count() == 60;
    context.expect(is_orders, "đơn hàng");
}

// Giao diện nhà phát hành đặt: khung chân dung vuông là mặc định của dự án (chủ dự án chốt 2026-10-14).
void real_client(Context& context) {
    const std::optional client = real(context, "client.toml", config::read_client);
    if (!client) return;
    context.expect(client->hud.avatar_frame == config::AvatarFrame::kSquare, "khung chân dung");
}

void real_world(Context& context) {
    const std::optional world = real(context, "world.toml", config::read_world);
    if (!world) return;
    const bool is_capacity = world->online_users == 4300 && world->mail_users == 52000 &&
        world->offline_cache == 50000 && world->speakers == 128 && world->pet_friend_ads == 1024;
    const bool is_notice = !world->join_guild && !world->pc_meets_mobile;
    context.expect(is_capacity && is_notice, "sức chứa, thông báo và phía");
    constexpr std::array<int, 3> kHours{13, 15, 21};
    context.expect(std::ranges::equal(world->hours, kHours), "giờ báo cáo");
}

void same_side_meets_until_the_flag_opens(Context& context) {
    config::World world;
    const bool pcs = config::may_meet(config::ClientKind::kPc, config::ClientKind::kPc, world);
    const bool phones = config::may_meet(config::ClientKind::kMobile, config::ClientKind::kMobile, world);
    context.expect(pcs && phones, "cùng phía gặp nhau");
    const bool closed = config::may_meet(config::ClientKind::kPc, config::ClientKind::kMobile, world);
    context.expect(!closed, "PC và mobile tách khi cờ tắt");
    world.pc_meets_mobile = true;
    const bool opened = config::may_meet(config::ClientKind::kMobile, config::ClientKind::kPc, world);
    context.expect(opened, "cờ bật thì hai phía gặp");
}

void real_zone(Context& context) {
    const std::optional zone = real(context, "zone.toml", config::read_zone);
    if (!zone) return;
    const bool is_pace = zone->hz == 20 && zone->cell_size == 10;
    context.expect(is_pace, "nhịp và ô vùng nhìn");
    const bool is_capacity = zone->monsters == 49000 && zone->pets == 3000 && zone->special_objects == 1024 &&
        zone->platforms == 1024 && zone->buses == 1024 && zone->player_shops == 256 && zone->scene_timers == 64 &&
        zone->human_timers == 3;
    context.expect(is_capacity, "sức chứa");
    const bool is_times = zone->linger_after_disconnect_ms.count() == 20000 &&
        zone->linger_hidden_ms.count() == 20000 && zone->kick_idle_ms.count() == 300000 &&
        zone->period_change_ms.count() == 150000 && zone->box_recycle_ms.count() == 60000 &&
        zone->packet_stats_ms.count() == 0;
    context.expect(is_times, "các thời lượng");
    context.expect(zone->language == "zh", "chữ thoại mặc định là chữ gốc");
}

void real_store(Context& context) {
    const std::optional store = real(context, "store.toml", config::read_store);
    if (!store) return;
    const bool is_same = store->database.name == "thienlong_game_1" && store->database.user == "thienlong_store" &&
        store->database.pool == 4 && store->character_ms.count() == 30000 && store->world_ms.count() == 60000 &&
        store->dir == "../data/store/journal";
    context.expect(is_same, "store.toml");
    const config::StoreSecurity& security = store->security;
    const config::StoreSecurity defaults;
    const bool is_security = security.standing_cache_ms.count() == 1000 && security.name_reserve_days == 30 &&
        security.female_faces == defaults.female_faces && security.male_faces == defaults.male_faces &&
        security.female_hairs == defaults.female_hairs && security.male_hairs == defaults.male_hairs;
    context.expect(is_security, "store.toml [security] khớp mặc định");
}

constexpr View kStoreBase = "schema = 1\n[database]\nname = \"g\"\nuser = \"u\"\npool = 1\n"
                            "[flush]\ncharacter_ms = 1\nworld_ms = 1\n[journal]\ndir = \"x\"\n";

[[nodiscard]] bool store_ok(View tail) {
    return config::read_store(std::string{kStoreBase} + std::string{tail}).has_value();
}

// [security] tuỳ chọn và có miền: tệp cũ vẫn đọc được, giá trị nguy hiểm bị từ chối khi khởi động.
void store_security_is_optional_and_bounded(Context& context) {
    const auto plain = config::read_store(kStoreBase);
    context.expect(plain && plain->security.standing_cache_ms.count() == 1000 && plain->security.name_reserve_days == 30,
        "thiếu [security] thì dùng mặc định");
    const auto partial = config::read_store(std::string{kStoreBase} + "[security]\nname_reserve_days = 7\n");
    context.expect(partial && partial->security.name_reserve_days == 7 && partial->security.standing_cache_ms.count() == 1000,
        "thiếu khoá thì khoá đó lấy mặc định");
    context.expect(store_ok("[security]\nstanding_cache_ms = 0\nfemale_faces = [9]\n"), "0 và danh sách riêng hợp lệ");
    context.expect(!store_ok("[security]\nstanding_cache_ms = 20000\n"), "cửa sổ ban quá 10 giây bị từ chối");
    context.expect(!store_ok("[security]\nname_reserve_days = -1\n"), "ngày âm bị từ chối");
    context.expect(!store_ok("[security]\nfemale_faces = [65535]\n"), "id canh 65535 bị từ chối");
    context.expect(!store_ok("[security]\nmale_hairs = []\n"), "danh sách rỗng bị từ chối");
    context.expect(!store_ok("[security]\nmale_hairs = [5, 5]\n"), "id lặp bị từ chối");
    context.expect(!store_ok("[security]\nmale_hairs = [\"5\"]\n"), "phần tử sai kiểu bị từ chối");
    context.expect(!store_ok("[security]\nunknown = 1\n"), "khoá lạ bị từ chối");
}

[[nodiscard]] bool gate_ok_with(Context& context, View from, View to) {
    std::string text = real_text(context, "gate.toml");
    const std::size_t at = text.find(from);
    if (at == std::string::npos) return false;
    text.replace(at, from.size(), to);
    return config::read_gate(text).has_value();
}

// [resume] và per_ip_prefix của gate.toml: mặc định an toàn, miền chặt.
void gate_resume_and_prefix_are_bounded(Context& context) {
    const std::optional gate = real(context, "gate.toml", config::read_gate);
    if (!gate) return;
    context.expect(gate->resume.bind_to_ip && gate->resume.grace_ms.count() == 30000, "[resume] mặc định");
    context.expect(gate->limits.per_ip_prefix == 32, "per_ip_prefix mặc định /32");
    context.expect(gate_ok_with(context, "per_ip_prefix        = 32", "per_ip_prefix = 24"), "/24 hợp lệ");
    context.expect(!gate_ok_with(context, "per_ip_prefix        = 32", "per_ip_prefix = 8"), "/8 bị từ chối");
    context.expect(gate_ok_with(context, "grace_ms   = 30000", "grace_ms = 0"), "tắt Resume hợp lệ");
    context.expect(!gate_ok_with(context, "grace_ms   = 30000", "grace_ms = 400000"), "quá 5 phút bị từ chối");
    context.expect(!gate_ok_with(context, "bind_to_ip = true", "bind_to_ip = 1"), "bind_to_ip phải là bool");
}

void real_admin(Context& context) {
    const std::optional admin = real(context, "admin.toml", config::read_admin);
    if (!admin) return;
    const bool is_same = admin->listen.host.text() == "127.0.0.1" && admin->listen.port.value() == 7002 &&
        admin->token_file == "../data/admin/token" && admin->operators.empty();
    context.expect(is_same, "admin.toml");
}

// Tệp mẫu đọc từ đĩa; tệp thật (secrets.local.toml) không bao giờ được mở, nội dung giả nằm ở đây.
void secrets_shape(Context& context) {
    const std::optional example = real(context, "secrets.example.toml", config::read_secrets);
    context.expect(example.has_value() && example->postgres.empty(), "tệp mẫu để trống mật khẩu");
    constexpr View kText = "schema = 1\n"
                           "[database.postgres]\n"
                           "password = \"pg-pass\"\n"
                           "[database.thienlong_auth]\n"
                           "password = \"\"\n"
                           "[database.thienlong_billing]\n"
                           "password = \"bi-pass\"\n"
                           "[database.thienlong_store]\n"
                           "password = \"st-pass\"\n";
    const auto secrets = config::read_secrets(kText);
    context.expect(secrets.has_value(), "văn bản giả đọc được");
    if (!secrets) return;
    const bool is_same = secrets->postgres == "pg-pass" && secrets->auth.empty() && secrets->billing == "bi-pass" &&
        secrets->store == "st-pass";
    context.expect(is_same, "bốn mật khẩu về đúng chỗ");
}

void real_startup(Context& context) {
    const std::optional cluster = real(context, "cluster.toml", config::read_cluster);
    const std::optional plan = real(context, "supervisor.toml", config::read_supervisor);
    if (!cluster || !plan) return;
    const config::StartupResult startup = config::check_startup(*cluster, *plan);
    context.expect(startup.has_value(), "cấu hình thật khởi động được");
}

constexpr std::array kCases{
    Case{.name = "bad_samples_are_reported_with_line", .body = &bad_samples_are_reported_with_line},
    Case{.name = "every_reader_rejects_common_errors", .body = &every_reader_rejects_common_errors},
    Case{.name = "every_error_is_reported_sorted_by_line", .body = &every_error_is_reported_sorted_by_line},
    Case{.name = "long_text_is_out_of_domain", .body = &long_text_is_out_of_domain},
    Case{.name = "oversized_document_is_refused", .body = &oversized_document_is_refused},
    Case{.name = "duplicate_process_pair_is_an_error", .body = &duplicate_process_pair_is_an_error},
    Case{.name = "loopback_listeners_may_ask_for_any_port", .body = &loopback_listeners_may_ask_for_any_port},
    Case{.name = "startup_needs_a_process_for_every_step", .body = &startup_needs_a_process_for_every_step},
    Case{.name = "repeated_start_step_is_an_error", .body = &repeated_start_step_is_an_error},
    Case{.name = "loose_document_allows_unknown_keys", .body = &loose_document_allows_unknown_keys},
    Case{.name = "real_rules_and_scene_have_schema", .body = &real_rules_and_scene_have_schema},
    Case{.name = "real_cluster", .body = &real_cluster},
    Case{.name = "real_supervisor", .body = &real_supervisor},
    Case{.name = "real_log", .body = &real_log},
    Case{.name = "real_gate", .body = &real_gate},
    Case{.name = "real_auth", .body = &real_auth},
    Case{.name = "real_billing", .body = &real_billing},
    Case{.name = "real_client", .body = &real_client},
    Case{.name = "real_world", .body = &real_world},
    Case{.name = "same_side_meets_until_the_flag_opens", .body = &same_side_meets_until_the_flag_opens},
    Case{.name = "real_zone", .body = &real_zone},
    Case{.name = "real_store", .body = &real_store},
    Case{.name = "store_security_is_optional_and_bounded", .body = &store_security_is_optional_and_bounded},
    Case{.name = "gate_resume_and_prefix_are_bounded", .body = &gate_resume_and_prefix_are_bounded},
    Case{.name = "real_admin", .body = &real_admin},
    Case{.name = "secrets_shape", .body = &secrets_shape},
    Case{.name = "real_startup", .body = &real_startup},
};

} // namespace
} // namespace game::test

int main() {
    const bool passed = game::test::run_all(game::test::kCases) == 0;
    game::core::check(passed, "config_tests");
    return 0;
}
