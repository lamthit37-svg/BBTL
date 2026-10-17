/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/serve.cpp
 *  PHÂN HỆ   : Server / Zone / Serve
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Vòng chạy của thienlong_zone: nghe kênh ipc của gate, nạp cảnh lười, chạy
 *    nhịp đã chọn (mặc định 20 Hz), ghi điểm đứng qua store.
 *  - Mỗi tick chặn số khung xử lý. Thư chưa gửi được giữ tới trần hộp ipc; vượt
 *    trần thì bỏ kênh, gate nối lại sẽ mất phiên.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/serve.hpp"

#include "account/book.hpp"
#include "account/ipc_key.hpp"
#include "account/rpc.hpp"
#include "config/cluster.hpp"
#include "config/issue.hpp"
#include "config/types.hpp"
#include "config/zone.hpp"
#include "io/file.hpp"
#include "ipc/link.hpp"
#include "ipc/relay.hpp"
#include "net/net.hpp"
#include "play/world.hpp"
#include "process/process.hpp"
#include "secure/secure.hpp"
#include "zone/content.hpp"
#include "zone/host.hpp"
#include "zone/outbox.hpp"
#include "zone/rate.hpp"
#include "zone/saver.hpp"
#include "zone/scene.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
#include <iterator>
#include <memory>
#include <optional>
#include <print>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>

namespace game::zone {
namespace {

using Path = std::filesystem::path;
using Clock = std::chrono::steady_clock;

constexpr std::uint64_t kListenTag = 1;
constexpr std::uint64_t kLinkTag = 2;
// Một tick tối đa xử lý chừng này khung từ gate: trần thời gian mỗi tick, phần dư để tick sau.
constexpr std::size_t kFramesPerTick = 4096;
// Một lần ghi tới store chờ tối đa chừng này.
constexpr std::chrono::milliseconds kStoreWait{2000};

struct Settings {
    net::Endpoint endpoint{};
    // Điểm nối store để ghi điểm đứng; không có (cổng 0) thì zone chạy nhưng không lưu gì.
    std::optional<net::Endpoint> store;
    std::int64_t hz = kTickHz;
    Host::Config host{};
    // Dữ liệu chơi; rỗng khi cây bảng không có (cụm thử cấu hình tạm): zone vẫn chạy nhưng không có hội thoại.
    std::shared_ptr<const play::World> world;
};

[[nodiscard]] std::optional<net::Endpoint> endpoint_of(const config::ProcessBlock& block) {
    const std::string text = std::format("{}:{}", block.host.text(), block.port.value());
    const net::ZeroPort zero = block.port.value() == 0 ? net::ZeroPort::kAllow : net::ZeroPort::kRefuse;
    const net::NetResult<net::Endpoint> parsed = net::parse_endpoint(text, zero);
    if (!parsed) return std::nullopt;
    return *parsed;
}

[[nodiscard]] bool loopback(const net::Endpoint& endpoint) noexcept {
    return endpoint.address == net::Ipv4{127, 0, 0, 1};
}

[[nodiscard]] bool tune(const config::Zone& zone, Settings& settings, std::string& error) {
    if (!accepted_hz(zone.hz)) {
        error = "zone.toml [tick] hz chỉ nhận 20, 30 hoặc 40";
        return false;
    }
    if (zone.cell_size < 1 || zone.cell_size > 1000) {
        error = "zone.toml [aoi] cell_size ngoài miền 1..1000";
        return false;
    }
    settings.hz = zone.hz;
    settings.host.hz = zone.hz;
    // cell_size tính bằng mét của cảnh; lưới tính centimet.
    settings.host.grid.cell_cm = static_cast<float>(zone.cell_size) * 100.0F;
    return true;
}

struct SeedAsk {
    const Path* root = nullptr;
    std::size_t cap = 0;
    const play::World* world = nullptr;
    std::int64_t hz = kTickHz;
};

[[nodiscard]] bool scene_speaks(const play::World* world, std::uint32_t script) {
    return world != nullptr && world->speaks(script);
}

[[nodiscard]] Seeder make_seeder(const SeedAsk& ask) {
    const Path tables = *ask.root / "tables";
    const Path server = tables / "server";
    const Path shared = tables / "shared";
    DiskPaths paths;
    paths.scenes = *ask.root / "scenes";
    paths.ids_table = server / "scene_ids.tsv";
    paths.templates = shared / "monsters.tsv";
    paths.ai_types = server / "monster_ai_types.tsv";
    paths.gates = shared / "scene_positions_extended.tsv";
    paths.scripts = server / "script_index.tsv";
    const play::World* world = ask.world;
    const auto speaks = [world](std::uint32_t script) { return scene_speaks(world, script); };
    return disk_seeder(paths, ask.cap, speaks, ask.hz);
}

// Nạp dữ liệu chơi. Cây bảng nhiệm vụ vắng hẳn thì chạy không gameplay (nói ra stderr); có mà hỏng thì dừng: nửa vời
// còn tệ hơn không có.
struct Roots {
    Path data;
    Path config;
};

[[nodiscard]] bool load_world(const Roots& roots, Settings& settings, std::string_view language, std::string& error) {
    const Path tables = roots.data / "tables";
    std::error_code missing;
    if (!std::filesystem::exists(tables / "server" / "mission_quests.tsv", missing)) {
        std::println(stderr, "zone: không có bảng nhiệm vụ: chạy không có hội thoại và nhiệm vụ");
        return true;
    }
    const Path base = roots.config.has_filename() ? roots.config : roots.config.parent_path();
    std::expected<play::World, std::string> loaded =
        play::World::load(play::Paths{.tables = tables, .text_override = base / "text", .language = std::string(language)});
    if (!loaded) {
        error = "dữ liệu chơi: " + loaded.error();
        return false;
    }
    settings.world = std::make_shared<const play::World>(std::move(*loaded));
    settings.host.world = settings.world.get();
    return true;
}

[[nodiscard]] std::optional<Settings> load_settings(const Path& config_dir, std::string& error) {
    const io::TextResult cluster_text = io::read_text(config_dir / "cluster.toml");
    const io::TextResult zone_text = io::read_text(config_dir / "zone.toml");
    if (!cluster_text || !zone_text) {
        error = "không đọc được cluster.toml hoặc zone.toml";
        return std::nullopt;
    }
    const config::ReadResult<config::Cluster> cluster = config::read_cluster(*cluster_text);
    const config::ReadResult<config::Zone> zone = config::read_zone(*zone_text);
    if (!cluster || !zone) {
        error = "cluster.toml hoặc zone.toml không hợp lệ";
        return std::nullopt;
    }
    Settings settings;
    if (!tune(*zone, settings, error)) return std::nullopt;
    // Bố cục dev/server và release/server: config, scenes và tables là anh em.
    const Path data_root = (config_dir.has_filename() ? config_dir : config_dir.parent_path()).parent_path();
    if (!load_world(Roots{.data = data_root, .config = config_dir}, settings, zone->language, error)) return std::nullopt;
    SeedAsk ask;
    ask.root = &data_root;
    ask.cap = static_cast<std::size_t>(zone->monsters);
    ask.world = settings.world.get();
    ask.hz = settings.hz;
    settings.host.seeder = make_seeder(ask);
    bool found = false;
    for (const config::ProcessBlock& block : cluster->processes) {
        if (block.id.value() != 0) continue;
        if (block.kind == config::ProcessKind::kZone) {
            const std::optional<net::Endpoint> parsed = endpoint_of(block);
            if (!parsed || !loopback(*parsed)) {
                error = "ipc của zone chỉ nghe 127.0.0.1";
                return std::nullopt;
            }
            settings.endpoint = *parsed;
            found = true;
        }
        if (block.kind == config::ProcessKind::kStore && block.port.value() != 0) {
            settings.store = endpoint_of(block);
        }
    }
    if (!found) {
        error = "cluster.toml không có tiến trình zone 0";
        return std::nullopt;
    }
    return settings;
}

struct Session {
    net::PollSet polls;
    std::optional<ipc::Link> link;
};

[[nodiscard]] bool send_one(ipc::Link& link, const Letter& letter) {
    const std::uint16_t kind = ipc::value_of(letter.kind);
    return link.send(kind, letter.session, letter.body);
}

// 256 khung/lượt * 20 Hz = 5120 khung/s, trên quạt vị trí của 64 người (~1280 khung/s). Niêm cả
// hàng tồn (có thể tới hộp 8 MiB) giữ luồng tick vài giây; gate xử lý dồn rồi cắt vì vượt trần tin.
constexpr std::size_t kSendPerWake = 256;

[[nodiscard]] bool can_send(ipc::Link& link, const Letter& letter, std::size_t sent) {
    if (sent >= kSendPerWake) return false;
    return send_one(link, letter);
}

// Đẩy thư lên kênh rồi bật quan tâm ghi nếu còn byte chờ. Phần chưa vào được hộp 8 MiB thì giữ lại.
// Giữ quá trần ấy là gate không đọc: trả false để bên gọi bỏ kênh, không nuốt thư rồi giả vờ đã
// gửi. Một lượt chỉ niêm kSendPerWake khung; phần còn lại chờ lượt sau, không bị xoá.
[[nodiscard]] bool flush(Session& session, Outbox& out) {
    if (!session.link) return true;
    ipc::Link& link = *session.link;
    static_cast<void>(link.pump());
    const std::vector<Letter>& mail = out.letters();
    std::size_t sent = 0;
    while (sent < mail.size() && can_send(link, mail[sent], sent))
        ++sent;
    out.drop_front(sent);
    static_cast<void>(link.pump());
    session.polls.want_write(kLinkTag, link.wants_write());
    return out.queued_bytes() <= ipc::kOutboxMax;
}

// Điểm đứng không bao giờ bị bỏ cùng thư: chuyển hết cho luồng ghi.
void hand_over(Outbox& out, Saver* saver) {
    for (const Save& spot : out.take_saves()) {
        if (saver != nullptr) saver->push(spot);
    }
}

struct World {
    Host host;
    Session session;
    Outbox out;
    Saver* saver = nullptr;
};

void adopt(World& world, net::TcpStream stream, secure::ByteView key) {
    // Gate mới thay gate cũ: phiên của kênh cũ không còn ai giữ.
    if (world.session.link) {
        world.session.polls.remove(kLinkTag);
        world.host.drop_all(world.out);
        world.out.clear();
        hand_over(world.out, world.saver);
    }
    world.session.link.emplace(std::move(stream), key);
    if (!world.session.polls.add(world.session.link->handle(), kLinkTag)) {
        world.session.link.reset();
    }
}

void lose(World& world) {
    world.session.polls.remove(kLinkTag);
    world.session.link.reset();
    world.host.drop_all(world.out);
    world.out.clear();
    hand_over(world.out, world.saver);
}

void accept_gate(net::TcpListener& listener, World& world, secure::ByteView key) {
    net::NetResult<std::optional<net::Accepted>> got = listener.accept();
    if (!got || !got->has_value()) return;
    net::Accepted accepted = std::move(**got);
    // Chỉ loopback: kênh này không có xác thực ngoài khoá cụm, và cổng đã bị ép 127.0.0.1.
    adopt(world, std::move(accepted.stream), key);
}

[[nodiscard]] std::uint64_t micros_since(Clock::time_point began) noexcept {
    const auto elapsed = Clock::now() - began;
    const auto micros = std::chrono::duration_cast<std::chrono::microseconds>(elapsed);
    return static_cast<std::uint64_t>(micros.count());
}

// Thời gian một lần kéo khung, micro giây. Nợ tick mà catch_up vẫn nhỏ thì chỗ chậm nằm ở đây.
struct Phases {
    std::uint64_t pump_us = 0;
    std::uint64_t handle_us = 0;
    std::uint64_t flush_us = 0;
};

// In ngay khi một pha vượt nửa giây: cửa sổ một giây có thể nuốt mất pha ấy nếu tiến trình chết
// giữa chừng.
void warn_slow(std::string_view name, std::uint64_t us) {
    if (us < 500'000ULL) return;
    std::println(stderr, "zone: chậm {} {}", name, us);
}

// Kéo khung từ kênh vào Host. false khi kênh đã hỏng hay đóng.
[[nodiscard]] bool drain(World& world, Phases& phases) {
    if (!world.session.link) return false;
    ipc::Link& link = *world.session.link;
    const auto pump_began = Clock::now();
    const ipc::LinkState state = link.pump();
    phases.pump_us = micros_since(pump_began);
    warn_slow("bơm", phases.pump_us);
    const auto handle_began = Clock::now();
    std::size_t budget = kFramesPerTick;
    while (budget > 0) {
        std::optional<ipc::Frame> frame = link.next();
        if (!frame) break;
        world.host.handle(*frame, world.out);
        --budget;
    }
    phases.handle_us = micros_since(handle_began);
    warn_slow("xử lý", phases.handle_us);
    // flush và hand_over cùng một pha: push điểm đứng có thể chờ khoá của luồng ghi.
    const auto flush_began = Clock::now();
    const bool flushed = flush(world.session, world.out);
    if (!flushed) lose(world);
    if (flushed) hand_over(world.out, world.saver);
    phases.flush_us = micros_since(flush_began);
    warn_slow("đẩy", phases.flush_us);
    if (!flushed) return false;
    return state == ipc::LinkState::kUp;
}

// Ghi một điểm đứng tới store. true khi store báo đã ghi.
[[nodiscard]] bool send_to_store(const net::Endpoint& store, secure::ByteView key, const Save& spot) {
    const account::SaveSpot wire{.character = spot.character,
        .scene = spot.scene,
        .x_cm = spot.x_cm,
        .z_cm = spot.z_cm,
        .play = spot.play};
    const std::optional<account::Call> call = account::save_call(wire);
    if (!call) {
        // Trạng thái chơi ngoài miền: gửi lại cũng hỏng như vậy, nên bỏ lần ghi này thay vì kẹt hàng chờ.
        std::println(stderr, "zone: bỏ lần ghi của nhân vật {}: trạng thái chơi không đóng gói được", spot.character);
        return true;
    }
    const std::optional<account::Reply> reply = account::exchange(store, *call, kStoreWait, key);
    return reply.has_value() && account::enter_from(*reply).ok;
}

// Cửa sổ một giây của phần mô phỏng (catch_up), không tính lúc chờ hạn tick. p99 lấy hạng
// (n - 1) * 99 / 100, cùng cách pos_fan_bench. late là số lần catch_up vượt ngân sách của số tick
// nó chạy, ngân sách là một nhịp đầy đủ chứ chưa phải mức 70%.
constexpr std::size_t kMeterSlots = 128;
constexpr std::int64_t kMeterNs = 1'000'000'000;

struct Meter {
    std::array<std::uint64_t, kMeterSlots> samples{};
    std::size_t filled = 0;
    std::uint64_t max_us = 0;
    std::uint64_t late = 0;
    std::uint64_t debt = 0;
    int ran = 0;
    std::uint64_t wait_us = 0;
    std::uint64_t pump_us = 0;
    std::uint64_t handle_us = 0;
    std::uint64_t flush_us = 0;
    std::int64_t next_ns = 0;
};

struct Loop {
    World& world;
    net::TcpListener& listener;
    secure::ByteView key;
    Clock::time_point origin{};
    Pace pace{};
    bool told = false;
    net::PollEvents events;
    Meter meter{};
};

[[nodiscard]] std::uint64_t rank_p99(const std::uint64_t* data, std::size_t count) {
    std::array<std::uint64_t, kMeterSlots> ordered{};
    const std::size_t have = count < ordered.size() ? count : ordered.size();
    if (have == 0) return 0;
    std::copy_n(data, have, ordered.begin());
    const auto last = std::next(ordered.begin(), static_cast<std::ptrdiff_t>(have));
    std::sort(ordered.begin(), last);
    const std::size_t at = (have - 1) * 99 / 100;
    return ordered[at];
}

void store_sample(Meter& meter, std::uint64_t per_us, std::uint64_t debt, int ran, bool over) {
    if (meter.filled >= meter.samples.size()) return;
    meter.samples[meter.filled] = per_us;
    ++meter.filled;
    if (per_us > meter.max_us) meter.max_us = per_us;
    if (over) ++meter.late;
    if (debt > meter.debt) meter.debt = debt;
    if (ran > meter.ran) meter.ran = ran;
}

// per_us là thời gian catch_up chia cho số tick vừa chạy. Bỏ qua lần thức không có tick.
void remember_sim(Meter& meter, std::int64_t hz, int ran, std::uint64_t debt,
    std::uint64_t spent_us) {
    if (ran <= 0 || hz <= 0) return;
    const auto ticks = static_cast<std::uint64_t>(ran);
    const auto budget = static_cast<std::uint64_t>(1'000'000 / hz);
    const std::uint64_t per_us = spent_us / ticks;
    const bool over = spent_us > ticks * budget;
    store_sample(meter, per_us, debt, ran, over);
}

void write_meter(const Meter& meter, std::int64_t hz) {
    const std::uint64_t p99 = rank_p99(meter.samples.data(), meter.filled);
    const std::size_t n = meter.filled;
    const std::uint64_t hi = meter.max_us;
    const std::uint64_t late = meter.late;
    const std::uint64_t debt = meter.debt;
    const int ran = meter.ran;
    const std::string head = std::format("zone: hz={} n={} p99_us={} max_us={}", hz, n, p99, hi);
    const std::string tail = std::format("late={} debt={} ran={}", late, debt, ran);
    const std::uint64_t wait_us = meter.wait_us;
    const std::uint64_t pump_us = meter.pump_us;
    const std::uint64_t handle_us = meter.handle_us;
    const std::uint64_t flush_us = meter.flush_us;
    std::println(stderr, "{} {}", head, tail);
    std::println(stderr, "zone: pha w={} p={} h={} f={}", wait_us, pump_us, handle_us, flush_us);
}

void publish_sim(Meter& meter, std::int64_t hz, std::int64_t now_ns) {
    if (meter.next_ns == 0 || now_ns < meter.next_ns) return;
    if (meter.filled > 0) write_meter(meter, hz);
    meter.filled = 0;
    meter.max_us = 0;
    meter.late = 0;
    meter.debt = 0;
    meter.ran = 0;
    meter.wait_us = 0;
    meter.pump_us = 0;
    meter.handle_us = 0;
    meter.flush_us = 0;
    meter.next_ns = now_ns + kMeterNs;
}

[[nodiscard]] std::int64_t nanos_since(Clock::time_point origin, Clock::time_point now) noexcept {
    const auto elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(now - origin);
    return elapsed.count();
}

[[nodiscard]] int wait_ms_for(const Pace& pace, std::int64_t now_ns) noexcept {
    const std::uint64_t due = due_count(now_ns, pace.hz);
    if (due > pace.done) return 0;
    const std::int64_t next = tick_due_ns(pace.done, pace.hz);
    if (next <= now_ns) return 0;
    const std::int64_t left = next - now_ns;
    const std::int64_t ms = left / 1'000'000;
    if (ms > 1000) return 1000;
    return static_cast<int>(ms);
}

void step_world(World& world) {
    const auto wall = std::chrono::system_clock::now().time_since_epoch();
    const auto seconds = std::chrono::duration_cast<std::chrono::seconds>(wall);
    world.host.set_unix_time(seconds.count());
    world.host.advance(world.out);
    if (!world.session.link) {
        world.out.clear();
        hand_over(world.out, world.saver);
        return;
    }
    if (!flush(world.session, world.out)) lose(world);
    hand_over(world.out, world.saver);
}

void catch_up(World& world, int steps) {
    for (int step = 0; step < steps; ++step)
        step_world(world);
}

void note_overload(const Pace& pace, const Wake& wake, bool& told) {
    if (wake.entered_overload && !told) {
        told = true;
        std::println(stderr, "zone: quá tải, tick trễ hơn một giây");
    }
    if (!pace.overloaded) told = false;
}

void accept_one(Loop& loop, const net::PollEvent& event) {
    if (event.tag != kListenTag) return;
    accept_gate(loop.listener, loop.world, loop.key);
}

void accept_ready(Loop& loop) {
    for (const net::PollEvent& event : loop.events)
        accept_one(loop, event);
}

void keep_phase(Meter& meter, std::uint64_t wait_us, const Phases& phases) {
    if (wait_us > meter.wait_us) meter.wait_us = wait_us;
    if (phases.pump_us > meter.pump_us) meter.pump_us = phases.pump_us;
    if (phases.handle_us > meter.handle_us) meter.handle_us = phases.handle_us;
    if (phases.flush_us > meter.flush_us) meter.flush_us = phases.flush_us;
}

[[nodiscard]] bool one_turn(Loop& loop) {
    const std::int64_t now_ns = nanos_since(loop.origin, Clock::now());
    const int wait_ms = wait_ms_for(loop.pace, now_ns);
    const net::Milliseconds wait{wait_ms};
    const auto wait_began = Clock::now();
    const net::NetResult<void> waited = loop.world.session.polls.wait(wait, loop.events);
    const std::uint64_t wait_us = micros_since(wait_began);
    warn_slow("chờ", wait_us);
    if (!waited) return false;
    accept_ready(loop);
    Phases phases;
    if (loop.world.session.link && !drain(loop.world, phases)) lose(loop.world);
    keep_phase(loop.meter, wait_us, phases);
    const std::int64_t after_ns = nanos_since(loop.origin, Clock::now());
    const Wake wake = take_wake(loop.pace, after_ns);
    note_overload(loop.pace, wake, loop.told);
    const auto began = Clock::now();
    catch_up(loop.world, wake.run);
    const std::uint64_t spent_us = micros_since(began);
    const std::int64_t done_ns = nanos_since(loop.origin, Clock::now());
    remember_sim(loop.meter, loop.pace.hz, wake.run, loop.pace.debt, spent_us);
    publish_sim(loop.meter, loop.pace.hz, done_ns);
    return true;
}

[[nodiscard]] int run(const Settings& settings, net::TcpListener& listener,
    const net::Endpoint& local, const std::array<std::byte, account::kIpcKeyBytes>& key) {
    std::unique_ptr<Saver> saver;
    if (settings.store) {
        const net::Endpoint store = *settings.store;
        saver = std::make_unique<Saver>([store, &key](const Save& spot) { return send_to_store(store, key, spot); });
    } else {
        std::println(stderr, "zone: cổng ipc của store là 0, không ghi được điểm đứng");
    }
    World world{.host = Host{settings.host}, .session = {}, .out = {}, .saver = saver.get()};
    if (!world.session.polls.add(listener.handle(), kListenTag)) {
        std::println(stderr, "zone: không theo dõi được cổng ipc");
        return 1;
    }
    std::println("ready ipc={}", local.port);
    static_cast<void>(std::fflush(stdout));

    Pace pace;
    pace.hz = settings.hz;
    Loop loop{world, listener, key, Clock::now(), pace, false, {}};
    loop.meter.next_ns = kMeterNs;
    int code = 0;
    while (!process::stop_requested() && one_turn(loop))
        ;
    if (!process::stop_requested()) code = 1;
    // Dừng êm: mọi người còn trong cảnh được ghi điểm đứng, rồi Saver gửi nốt trước khi thoát.
    world.host.drop_all(world.out);
    world.out.clear();
    hand_over(world.out, world.saver);
    return code;
}

} // namespace

int serve(const Path& config_dir) {
    std::string error;
    const std::optional<Settings> settings = load_settings(config_dir, error);
    if (!settings) {
        std::println(stderr, "zone: {}", error);
        return 2;
    }
    const std::optional<std::array<std::byte, account::kIpcKeyBytes>> key =
        account::load_or_create_ipc_key(account::ipc_key_path(config_dir), error);
    if (!key) {
        std::println(stderr, "zone: {}", error);
        return 1;
    }
    const net::NetResult<net::Network> network = net::Network::start();
    if (!network) {
        std::println(stderr, "zone: không khởi động được mạng");
        return 1;
    }
    net::NetResult<net::TcpListener> listener = net::TcpListener::open(settings->endpoint);
    const net::NetResult<net::Endpoint> local = listener ? listener->local() : net::NetResult<net::Endpoint>{};
    if (!listener || !local) {
        std::println(stderr, "zone: không nghe được cổng ipc");
        return 1;
    }
    return run(*settings, *listener, *local, *key);
}

} // namespace game::zone
