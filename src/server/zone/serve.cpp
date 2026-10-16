/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/serve.cpp
 *  PHÂN HỆ   : Server / Zone / Serve
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Vòng chạy của thienlong_zone: nghe kênh ipc của gate, nạp cảnh lười, tick
 *    20 Hz, ghi điểm đứng qua store.
 *  - Mỗi tick chặn số khung xử lý; kênh chậm quá trần thì bỏ phần dư, gate nối
 *    lại sẽ mất phiên.
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
#include "zone/saver.hpp"
#include "zone/scene.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <format>
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
    if (zone.hz < 1 || zone.hz > 120) {
        error = "zone.toml [tick] hz ngoài miền 1..120";
        return false;
    }
    if (zone.cell_size < 1 || zone.cell_size > 1000) {
        error = "zone.toml [aoi] cell_size ngoài miền 1..1000";
        return false;
    }
    settings.hz = zone.hz;
    // cell_size tính bằng mét của cảnh; lưới tính centimet.
    settings.host.grid.cell_cm = static_cast<float>(zone.cell_size) * 100.0F;
    return true;
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
    const std::shared_ptr<const play::World> world = settings.world;
    settings.host.seeder = disk_seeder(
        DiskPaths{.scenes = data_root / "scenes",
            .ids_table = data_root / "tables" / "server" / "scene_ids.tsv",
            .templates = data_root / "tables" / "shared" / "monsters.tsv",
            .ai_types = data_root / "tables" / "server" / "monster_ai_types.tsv",
            .gates = data_root / "tables" / "shared" / "scene_positions_extended.tsv",
            .scripts = data_root / "tables" / "server" / "script_index.tsv"},
        static_cast<std::size_t>(zone->monsters),
        [world](std::uint32_t script) { return world != nullptr && world->speaks(script); });
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

// Đẩy thư của một lượt lên kênh rồi bật quan tâm ghi nếu còn byte chờ. Kênh đầy thì bỏ phần dư: bên nhận
// chậm tới trần 8 MiB là gate hỏng, và gate nối lại sẽ mất phiên.
void flush(Session& session, Outbox& out) {
    if (!session.link) return;
    ipc::Link& link = *session.link;
    for (Letter& letter : out.take()) {
        if (!link.send(ipc::value_of(letter.kind), letter.session, letter.body)) break;
    }
    static_cast<void>(link.pump());
    session.polls.want_write(kLinkTag, link.wants_write());
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

// Kéo khung từ kênh vào Host. false khi kênh đã hỏng hay đóng.
[[nodiscard]] bool drain(World& world) {
    if (!world.session.link) return false;
    ipc::Link& link = *world.session.link;
    const ipc::LinkState state = link.pump();
    std::size_t budget = kFramesPerTick;
    while (budget > 0) {
        std::optional<ipc::Frame> frame = link.next();
        if (!frame) break;
        world.host.handle(*frame, world.out);
        --budget;
    }
    flush(world.session, world.out);
    hand_over(world.out, world.saver);
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

[[nodiscard]] int run(const Settings& settings, net::TcpListener& listener, const net::Endpoint& local,
    const std::array<std::byte, account::kIpcKeyBytes>& key) {
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

    const auto period = std::chrono::nanoseconds{std::chrono::seconds{1}} / settings.hz;
    auto deadline = Clock::now() + period;
    net::PollEvents events;
    int code = 0;
    while (!process::stop_requested()) {
        const auto now = Clock::now();
        const auto left = deadline > now ? deadline - now : Clock::duration::zero();
        const auto wait = std::chrono::duration_cast<std::chrono::milliseconds>(left);
        if (!world.session.polls.wait(net::Milliseconds{static_cast<int>(wait.count())}, events)) {
            code = 1;
            break;
        }
        for (const net::PollEvent& event : events) {
            if (event.tag == kListenTag) accept_gate(listener, world, key);
        }
        if (world.session.link && !drain(world)) lose(world);
        if (Clock::now() < deadline) continue;
        world.host.set_unix_time(std::chrono::duration_cast<std::chrono::seconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
        world.host.advance(world.out);
        if (world.session.link) flush(world.session, world.out);
        world.out.clear();
        hand_over(world.out, world.saver);
        // Chậm quá một nhịp thì bỏ nhịp đã lỡ thay vì chạy bù dồn dập.
        deadline += period;
        if (deadline < Clock::now()) deadline = Clock::now() + period;
    }
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
