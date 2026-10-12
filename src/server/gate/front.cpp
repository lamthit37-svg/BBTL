// Vòng tick của gate: chờ I/O tới hạn tick, đọc có ngân sách, chạy đồng hồ, đẩy hộp gửi.
#include "gate/front.hpp"

#include "account/ipc_key.hpp"
#include "account/realm.hpp"
#include "config/cluster.hpp"
#include "config/gate.hpp"
#include "config/issue.hpp"
#include "config/types.hpp"
#include "gate/table.hpp"
#include "io/file.hpp"
#include "net/net.hpp"
#include "net/reactor.hpp"
#include "process/process.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <format>
#include <iterator>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::gate {
namespace {

constexpr std::uint64_t kListenGame = ~std::uint64_t{0} - 1U;
constexpr std::uint64_t kListenAuth = ~std::uint64_t{0};
constexpr std::size_t kAcceptBudget = 32;
constexpr std::size_t kResumeBudget = 32;
constexpr std::int64_t kStatNs = 1'000'000'000;

struct Held {
    net::TcpStream stream;
    Handle handle{};
    bool open = false;
};

struct Listeners {
    net::TcpListener game;
    net::TcpListener auth;
    bool polled = false;
};

// Vòng không sở hữu bảng hay socket nghe: tham chiếu, không có trạng thái null hợp lệ.
// NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members)
struct Loop {
    Table& table;
    Listeners& listeners;
    std::vector<Held>& held;
    net::Reactor reactor;
    net::PollEvents events;
    std::int64_t now = 0;
    std::int64_t deadline = 0;
    std::array<std::uint64_t, 60> samples{};
    std::size_t sample_count = 0;
    std::uint64_t late = 0;
    std::uint64_t max_us = 0;
    std::uint64_t accept_us = 0;
    std::uint64_t pump_us = 0;
    std::uint64_t advance_us = 0;
    std::uint64_t flush_us = 0;
    std::int64_t next_report = 0;
};
// NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)

struct TickSpan {
    std::int64_t start = 0;
    std::int64_t end = 0;
};

enum class AcceptStep : std::uint8_t { kStop, kAgain };

enum class CloseHow : std::uint8_t { kReset, kFinish };

[[nodiscard]] std::int64_t steady_ns() noexcept {
    const auto now = std::chrono::steady_clock::now().time_since_epoch();
    return std::chrono::duration_cast<std::chrono::nanoseconds>(now).count();
}

[[nodiscard]] std::uint64_t tag_of(Handle handle) noexcept {
    return (static_cast<std::uint64_t>(handle.generation) << 32U) | handle.index;
}

[[nodiscard]] net::NetResult<net::Endpoint> endpoint_of(const config::Endpoint& endpoint) {
    const std::string_view host = endpoint.host.text();
    const std::uint16_t port = endpoint.port.value();
    const std::string text = std::format("{}:{}", host, port);
    return net::parse_endpoint(text, net::ZeroPort::kRefuse);
}

void fail_listen(std::string_view name, net::NetError error) {
    std::println(stderr, "gate: không nghe được cổng {}: {}", name, net::describe(error));
}

[[nodiscard]] bool add_cidr(std::string_view row, std::vector<Cidr>& out) {
    const std::optional<Cidr> parsed = parse_cidr(row);
    if (!parsed) {
        std::println(stderr, "gate: dải địa chỉ không đọc được {}", row);
        return false;
    }
    out.push_back(*parsed);
    return true;
}

[[nodiscard]] bool cidrs_of(const std::vector<std::string>& rows, std::vector<Cidr>& out) {
    const auto add = [&](const std::string& row) { return add_cidr(row, out); };
    return std::ranges::all_of(rows, add);
}

[[nodiscard]] Limits limits_of(const config::Gate& gate) noexcept {
    Limits limits;
    limits.max_connections = static_cast<std::size_t>(gate.limits.max_connections);
    limits.per_ip = static_cast<std::size_t>(gate.limits.per_ip_connections);
    limits.handshake_ns = gate.limits.handshake_timeout_ms.count() * kNsPerMs;
    limits.idle_ns = gate.limits.idle_timeout_ms.count() * kNsPerMs;
    limits.frame_bytes = static_cast<std::size_t>(gate.limits.client_frame_bytes);
    limits.per_second = gate.limits.messages_per_second;
    limits.min_version = static_cast<std::uint16_t>(gate.client.min_version);
    limits.per_ip_prefix = static_cast<std::uint32_t>(gate.limits.per_ip_prefix);
    limits.resume_grace_ns = gate.resume.grace_ms.count() * kNsPerMs;
    limits.resume_bind_ip = gate.resume.bind_to_ip;
    return limits;
}

[[nodiscard]] bool policy_ok(const config::Gate& gate) {
    if (!gate.trusted_proxies.empty()) {
        std::println(stderr, "gate: trusted_proxies chưa được hỗ trợ, từ chối khởi động");
        return false;
    }
    const bool frame_ok = gate.limits.client_frame_bytes >= 0 && gate.limits.client_frame_bytes <= 4096;
    const bool version_ok = gate.client.min_version >= 0 && gate.client.min_version <= 65535;
    if (frame_ok && version_ok) return true;
    std::println(stderr, "gate: trần khung hoặc phiên bản tối thiểu ngoài miền bản này");
    return false;
}

void listen_on(Listeners& listeners, net::Reactor& reactor) {
    const bool game = reactor.watch_listener(listeners.game, kListenGame);
    const bool auth = reactor.watch_listener(listeners.auth, kListenAuth);
    if (game && auth) {
        listeners.polled = true;
        return;
    }
    if (game) reactor.unwatch(kListenGame);
    if (auth) reactor.unwatch(kListenAuth);
    listeners.polled = false;
}

void listen_off(Listeners& listeners, net::Reactor& reactor) {
    reactor.unwatch(kListenGame);
    reactor.unwatch(kListenAuth);
    listeners.polled = false;
}

void sync_listeners(Listeners& listeners, net::Reactor& reactor, bool want) {
    if (want == listeners.polled) return;
    if (want) listen_on(listeners, reactor);
    if (!want) listen_off(listeners, reactor);
}

void drop_socket(Held& place, net::Reactor& reactor, CloseHow how) {
    if (!place.open) return;
    reactor.unwatch(tag_of(place.handle));
    if (how == CloseHow::kReset) place.stream.abort();
    if (how == CloseHow::kFinish) place.stream.shutdown_send();
    place.stream = net::TcpStream{};
    place.open = false;
}

void keep_stream(Held& place, net::TcpStream stream, Handle handle, net::Reactor& reactor) {
    place.stream = std::move(stream);
    place.handle = handle;
    place.open = true;
    const bool added = reactor.watch(place.stream.handle(), tag_of(handle));
    if (added) return;
    place.stream.abort();
    place.open = false;
}

[[nodiscard]] AcceptStep accept_one(net::TcpListener&, Loop& loop, Door door) {
    const std::uint64_t tag = door == Door::kGame ? kListenGame : kListenAuth;
    net::NetResult<std::optional<net::Accepted>> got = loop.reactor.take_accept(tag);
    if (!got || !got->has_value()) return AcceptStep::kStop;
    std::optional<net::Accepted>& waiting = *got;
    net::Accepted accepted = std::move(*waiting);
    const Admit admitted = loop.table.admit(accepted.peer.address, loop.now, door);
    if (admitted.code != AdmitCode::kOk) {
        accepted.stream.abort();
        return AcceptStep::kAgain;
    }
    Held& place = loop.held[admitted.handle.index];
    keep_stream(place, std::move(accepted.stream), admitted.handle, loop.reactor);
    if (!place.open) loop.table.drop(admitted.handle, Drop::kClosed);
    return AcceptStep::kAgain;
}

[[nodiscard]] bool take_one(net::TcpListener& listener, Loop& loop, std::size_t& budget, Door door) {
    if (budget == 0 || !loop.table.listening()) return false;
    const AcceptStep step = accept_one(listener, loop, door);
    if (step == AcceptStep::kStop) return false;
    --budget;
    return true;
}

void accept_some(net::TcpListener& listener, Loop& loop, Door door) {
    std::size_t budget = kAcceptBudget;
    while (take_one(listener, loop, budget, door)) {
    }
}

void read_one(Held& place, Loop& loop) {
    const std::size_t room = loop.table.read_room(place.handle);
    if (room == 0) return;
    std::array<std::byte, kHeldBytes> buffer{};
    const std::size_t ask = std::min(room, buffer.size());
    const std::span<std::byte> sink{buffer.data(), ask};
    const net::NetResult<std::size_t> got = place.stream.receive(sink);
    if (!got) {
        const Handle handle = place.handle;
        drop_socket(place, loop.reactor, CloseHow::kReset);
        loop.table.drop(handle, Drop::kClosed);
        return;
    }
    loop.reactor.note_read(tag_of(place.handle), *got);
    if (*got == 0) return;
    const secure::ByteView bytes{buffer.data(), *got};
    loop.table.receive(place.handle, bytes, loop.now);
    if (loop.table.is_live(place.handle)) return;
    drop_socket(place, loop.reactor, CloseHow::kReset);
}

void flush_one(Held& place, Loop& loop) {
    for (int spin = 0; spin < 4; ++spin) {
        const secure::ByteView pending = loop.table.outgoing(place.handle);
        if (pending.empty()) return;
        const net::SendOutcome outcome = loop.reactor.submit_send(tag_of(place.handle), pending);
        if (outcome.state == net::SendState::kReset) {
            const Handle handle = place.handle;
            drop_socket(place, loop.reactor, CloseHow::kReset);
            loop.table.drop(handle, Drop::kClosed);
            return;
        }
        if (outcome.state == net::SendState::kPending) return;
        loop.table.mark_sent(place.handle, outcome.sent);
        if (loop.table.is_live(place.handle) && outcome.sent > 0) continue;
        if (!loop.table.is_live(place.handle)) drop_socket(place, loop.reactor, CloseHow::kFinish);
        return;
    }
}

void pump(Loop& loop);

void flush_at(Loop& loop, Handle handle) {
    if (handle.index >= loop.held.size()) return;
    Held& place = loop.held[handle.index];
    if (!place.open || place.handle != handle) return;
    flush_one(place, loop);
}

void flush_batch(Loop& loop, std::span<const Handle> pending) {
    for (const Handle handle : pending) {
        flush_at(loop, handle);
    }
}

void flush_pending(Loop& loop) {
    std::array<Handle, 64> batch{};
    std::size_t count = loop.table.take_pending(std::span{batch});
    while (count > 0) {
        flush_batch(loop, std::span{batch.data(), count});
        count = loop.table.take_pending(std::span{batch});
    }
    for (int pass = 0; pass < 4; ++pass) {
        if (!loop.reactor.wait(net::Milliseconds{0}, loop.events)) return;
        if (loop.events.empty()) return;
        pump(loop);
    }
}

void resume_one(Loop& loop, Handle handle) {
    if (handle.index >= loop.held.size()) return;
    Held& place = loop.held[handle.index];
    if (!place.open || place.handle != handle) return;
    loop.table.receive(handle, {}, loop.now);
    if (loop.table.is_live(handle)) return;
    drop_socket(place, loop.reactor, CloseHow::kReset);
}

void resume_some(Loop& loop) {
    std::array<Handle, kResumeBudget> batch{};
    const std::size_t count = loop.table.take_resume(std::span{batch});
    const std::span<const Handle> pending{std::span{batch}.first(count)};
    for (const Handle handle : pending) {
        resume_one(loop, handle);
    }
}

void close_if(Loop& loop, Handle handle) {
    if (handle.index >= loop.held.size()) return;
    Held& place = loop.held[handle.index];
    if (!place.open || place.handle != handle) return;
    drop_socket(place, loop.reactor, CloseHow::kFinish);
}

void close_batch(Loop& loop, std::span<const Handle> dead) {
    for (const Handle handle : dead) {
        close_if(loop, handle);
    }
}

void close_dead(Loop& loop) {
    std::array<Handle, 64> dead{};
    std::size_t count = loop.table.take_closed(std::span{dead});
    while (count > 0) {
        close_batch(loop, std::span{dead.data(), count});
        count = loop.table.take_closed(std::span{dead});
    }
}

void handle_event(const net::PollEvent& event, Loop& loop) {
    if (event.tag == kListenGame || event.tag == kListenAuth) return;
    const auto index = static_cast<std::uint32_t>(event.tag);
    if (index >= loop.held.size()) return;
    Held& place = loop.held[index];
    if (!place.open) return;
    const auto generation = static_cast<std::uint32_t>(event.tag >> 32U);
    if (place.handle.generation != generation) return;
    if (event.sent > 0) {
        loop.table.mark_sent(place.handle, event.sent);
        if (!loop.table.is_live(place.handle)) {
            drop_socket(place, loop.reactor, CloseHow::kFinish);
            return;
        }
        flush_one(place, loop);
    }
    if (!place.open) return;
    if (event.readable || event.failed) read_one(place, loop);
    if (!place.open || !event.writable) return;
    flush_one(place, loop);
}

// Mọi sự kiện phải được xử lý: reactor đã xoá cờ readable/sent khi trả sự kiện, bỏ một sự kiện là
// socket ấy không bao giờ được đăng đọc lại và byte đã gửi không bao giờ được trừ khỏi outbox.
// Việc mỗi socket đã có trần: read_room, kRecordBudget bản ghi mỗi lần đọc, bốn vòng gửi.
void pump(Loop& loop) {
    for (const net::PollEvent& event : loop.events) {
        handle_event(event, loop);
    }
}

void report(Loop& loop, std::int64_t end) {
    if (end < loop.next_report) return;
    std::array<std::uint64_t, 60> ordered{};
    const std::size_t have = std::min<std::size_t>(loop.sample_count, ordered.size());
    std::copy_n(loop.samples.begin(), have, ordered.begin());
    const auto count = static_cast<std::ptrdiff_t>(have);
    std::sort(ordered.begin(), ordered.begin() + count);
    const std::size_t at = have == 0 ? 0 : (have * 99) / 100;
    const std::size_t pick = at < have ? at : 0;
    auto picked = ordered.begin();
    std::advance(picked, static_cast<std::ptrdiff_t>(pick));
    const std::uint64_t p99 = have == 0 ? 0 : *picked;
    const std::size_t live = loop.table.live();
    std::println(stderr,
        "gate: tick p99_us={} max_us={} late={} conn={} accept_us={} pump_us={} advance_us={} flush_us={}", p99,
        loop.max_us, loop.late, live, loop.accept_us, loop.pump_us, loop.advance_us, loop.flush_us);
    loop.next_report = end + kStatNs;
}

void note_tick(Loop& loop, TickSpan span) {
    const auto micros = static_cast<std::uint64_t>((span.end - span.start) / 1000);
    auto slot = loop.samples.begin();
    std::advance(slot, static_cast<std::ptrdiff_t>(loop.sample_count % loop.samples.size()));
    *slot = micros;
    ++loop.sample_count;
    if (micros > loop.max_us) loop.max_us = micros;
    if (span.end - span.start > kTickNs) ++loop.late;
    report(loop, span.end);
}

void note_phase(std::uint64_t& slot, std::int64_t began) {
    const auto micros = static_cast<std::uint64_t>((steady_ns() - began) / 1000);
    if (micros > slot) slot = micros;
}

void catch_up(Loop& loop, TickSpan span) {
    const TickPlan plan = next_tick(loop.deadline, span.start);
    loop.deadline = plan.deadline;
    loop.late += plan.missed;
}

[[nodiscard]] int one_tick(Loop& loop) {
    const std::int64_t now = steady_ns();
    std::int64_t wait_ns = loop.deadline - now;
    if (wait_ns < 0) wait_ns = 0;
    const auto wait_ms = static_cast<int>(wait_ns / kNsPerMs);
    const net::Milliseconds limit{wait_ms};
    if (!loop.reactor.wait(limit, loop.events)) return 1;
    const std::int64_t start = steady_ns();
    loop.now = start;
    sync_listeners(loop.listeners, loop.reactor, loop.table.listening());
    resume_some(loop);
    std::int64_t mark = steady_ns();
    if (loop.table.listening()) accept_some(loop.listeners.game, loop, Door::kGame);
    if (loop.table.listening()) accept_some(loop.listeners.auth, loop, Door::kAuth);
    note_phase(loop.accept_us, mark);
    mark = steady_ns();
    pump(loop);
    loop.table.collect();
    note_phase(loop.pump_us, mark);
    mark = steady_ns();
    loop.table.advance(start);
    note_phase(loop.advance_us, mark);
    mark = steady_ns();
    flush_pending(loop);
    close_dead(loop);
    sync_listeners(loop.listeners, loop.reactor, loop.table.listening());
    note_phase(loop.flush_us, mark);
    const TickSpan span{.start = start, .end = steady_ns()};
    note_tick(loop, span);
    catch_up(loop, span);
    return 0;
}

[[nodiscard]] bool keep_running(Loop& loop, int& code) {
    if (process::stop_requested()) return false;
    code = one_tick(loop);
    return code == 0;
}

[[nodiscard]] int run_loop(Table& table, Listeners& listeners, std::vector<Held>& held) {
    Loop loop{.table = table, .listeners = listeners, .held = held, .reactor = {}, .events = {}};
    loop.events.reserve(held.size() + 2);
    sync_listeners(listeners, loop.reactor, true);
    loop.deadline = steady_ns();
    loop.next_report = loop.deadline + kStatNs;
    std::println("ready");
    static_cast<void>(std::fflush(stdout));
    int code = 0;
    while (keep_running(loop, code)) {
    }
    if (code != 0) return code;
    table.close_all();
    close_dead(loop);
    return 0;
}

struct Opened {
    Listeners listeners;
    int code = 0;
};

[[nodiscard]] Opened open_both(const config::Gate& gate) {
    Opened opened;
    const net::NetResult<net::Endpoint> game = endpoint_of(gate.listen.game);
    const net::NetResult<net::Endpoint> auth = endpoint_of(gate.listen.auth);
    if (!game || !auth) {
        opened.code = 2;
        return opened;
    }
    net::NetResult<net::TcpListener> game_listen = net::TcpListener::open(*game);
    if (!game_listen) {
        fail_listen("game", game_listen.error());
        opened.code = 1;
        return opened;
    }
    net::NetResult<net::TcpListener> auth_listen = net::TcpListener::open(*auth);
    if (!auth_listen) {
        fail_listen("auth", auth_listen.error());
        opened.code = 1;
        return opened;
    }
    opened.listeners.game = std::move(*game_listen);
    opened.listeners.auth = std::move(*auth_listen);
    return opened;
}

using Path = std::filesystem::path;

[[nodiscard]] secure::Result<secure::Identity> load_identity(const Path& config_dir, const config::Gate& gate) {
    const std::filesystem::path relative = io::path_from_utf8(gate.identity_key_file);
    const std::filesystem::path key = (config_dir / relative).lexically_normal();
    secure::Result<secure::Identity> identity = secure::Identity::load(key);
    if (identity) return identity;
    const std::string where = io::utf8_of(key);
    std::println(stderr, "gate: {} {}", where, secure::describe(identity.error()));
    return identity;
}

} // namespace

int write_identity(const std::filesystem::path& path) {
    const secure::Result<secure::Identity> made = secure::Identity::generate();
    if (!made) {
        std::println(stderr, "gate: {}", secure::describe(made.error()));
        return 2;
    }
    const secure::Result<void> stored = made->store_new(path);
    if (!stored) {
        const std::string where = io::utf8_of(path);
        std::println(stderr, "gate: {} {}", where, secure::describe(stored.error()));
        return 2;
    }
    std::println("{}", secure::hex_encode(made->public_key().bytes));
    std::println(stderr, "đã ghi khoá danh tính; khoá công khai ở stdout");
    return 0;
}

[[nodiscard]] std::optional<net::Endpoint> ipc_of(const config::Cluster& cluster, config::ProcessKind kind) {
    for (const config::ProcessBlock& block : cluster.processes) {
        const bool match = block.kind == kind && block.id.value() == 0 && block.port.value() != 0;
        if (!match) continue;
        const std::string text = std::format("{}:{}", block.host.text(), block.port.value());
        const net::NetResult<net::Endpoint> parsed = net::parse_endpoint(text, net::ZeroPort::kRefuse);
        if (!parsed) return std::nullopt;
        return *parsed;
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<account::Realm> open_realm(const std::filesystem::path& config_dir) {
    const io::TextResult text = io::read_text(config_dir / "cluster.toml");
    if (!text) return std::nullopt;
    const config::ReadResult<config::Cluster> cluster = config::read_cluster(*text);
    if (!cluster) return std::nullopt;
    const std::optional<net::Endpoint> auth = ipc_of(*cluster, config::ProcessKind::kAuth);
    const std::optional<net::Endpoint> store = ipc_of(*cluster, config::ProcessKind::kStore);
    if (!auth || !store) {
        std::println(stderr, "gate: cổng ipc của auth hoặc store là 0, đăng ký trả bận");
        return std::nullopt;
    }
    std::string error;
    const std::optional<std::array<std::byte, account::kIpcKeyBytes>> key = account::load_ipc_key(account::ipc_key_path(config_dir), error);
    if (!key) {
        std::println(stderr, "gate: {}", error);
        return std::nullopt;
    }
    return account::Realm{*auth, *store, *key};
}

int serve(const std::filesystem::path& config_dir) {
    const io::TextResult text = io::read_text(config_dir / "gate.toml");
    if (!text) {
        std::println(stderr, "gate: không đọc được gate.toml");
        return 2;
    }
    const config::ReadResult<config::Gate> loaded = config::read_gate(*text);
    if (!loaded || !policy_ok(*loaded)) {
        if (!loaded) std::println(stderr, "gate: gate.toml không hợp lệ");
        return 2;
    }
    const secure::Result<secure::Identity> identity = load_identity(config_dir, *loaded);
    if (!identity) return 2;
    std::vector<Cidr> allow;
    std::vector<Cidr> deny;
    const bool allow_ok = cidrs_of(loaded->ip_filter.allow, allow);
    const bool deny_ok = cidrs_of(loaded->ip_filter.deny, deny);
    if (!allow_ok || !deny_ok) return 2;
    const net::NetResult<net::Network> network = net::Network::start();
    if (!network) return 1;
    Opened opened = open_both(*loaded);
    if (opened.code != 0) return opened.code;
    const Limits limits = limits_of(*loaded);
    Table table{limits, std::move(allow), std::move(deny), *identity};
    std::optional<account::Realm> realm = open_realm(config_dir);
    if (realm) table.set_realm(*realm);
    std::vector<Held> held(limits.max_connections);
    return run_loop(table, opened.listeners, held);
}

} // namespace game::gate
