// Vùng nhìn, cảnh và host của zone: lưới ô, ai thấy ai khi vào/đi/rời, id thực thể không dùng lại ngay,
// trần người chơi và cảnh, khung hỏng từ gate. Không mạng: đưa thẳng ipc::Frame và đọc Outbox.
#include "ipc/relay.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "test.hpp"
#include "zone/aoi.hpp"
#include "zone/content.hpp"
#include "zone/host.hpp"
#include "zone/outbox.hpp"
#include "zone/saver.hpp"
#include "zone/scene.hpp"

#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <numbers>
#include <optional>
#include <mutex>
#include <set>
#include <thread>
#include <variant>
#include <vector>

namespace game::test {
namespace {

using zone::Cell;
using zone::Grid;
using zone::Host;
using zone::Outbox;
using zone::Scene;

constexpr float kCell = 1000.0F;

// Một khung Down đã giải mã.
struct Seen {
    std::uint64_t session = 0;
    protocol::GameServerMessage message;
};

[[nodiscard]] std::vector<Seen> seen_in(const Outbox& out) {
    std::vector<Seen> seen;
    for (const zone::Letter& letter : out.letters()) {
        if (letter.kind != ipc::Relay::kDown) continue;
        const protocol::FrameResult peeked = protocol::peek_frame(letter.body, letter.body.size());
        if (!peeked || !peeked->has_value()) continue;
        const protocol::Frame frame = **peeked;
        const std::span<const std::byte> body = std::span{letter.body}.subspan(protocol::kHeaderBytes);
        protocol::GameServerResult decoded = protocol::decode_game_server(frame, body);
        if (decoded) seen.push_back(Seen{.session = letter.session, .message = std::move(*decoded)});
    }
    return seen;
}

template <typename Message>
[[nodiscard]] std::vector<Message> of_kind(const std::vector<Seen>& seen, std::uint64_t session) {
    std::vector<Message> found;
    for (const Seen& one : seen) {
        if (one.session != session) continue;
        if (const auto* message = std::get_if<Message>(&one.message)) found.push_back(*message);
    }
    return found;
}

[[nodiscard]] ipc::Attach arrival(std::uint64_t character, float x_cm, float z_cm, std::uint16_t scene = 1) {
    ipc::Attach attach;
    attach.character = character;
    attach.account = character + 1000;
    attach.scene = scene;
    attach.x_cm = x_cm;
    attach.z_cm = z_cm;
    attach.name = "nv" + std::to_string(character);
    attach.level = 7;
    attach.gender = 2;
    attach.face = 3;
    attach.hair = 4;
    attach.school = 5;
    attach.client_version = 3;
    return attach;
}

[[nodiscard]] Scene make_scene(std::size_t player_max = 100) {
    return Scene{Scene::Config{.id = 1, .grid = {.cell_cm = kCell, .radius = 2}, .player_max = player_max}};
}

// --- aoi ---

void grid_cells_and_clamp(Context& context) {
    const Grid grid{{.cell_cm = kCell, .radius = 2}};
    context.expect(grid.cell_of(0.0F, 0.0F) == Cell{0, 0}, "gốc ở ô 0,0");
    context.expect(grid.cell_of(999.0F, 1000.0F) == Cell{0, 1}, "biên ô: 1000 sang ô kế");
    context.expect(grid.cell_of(-1.0F, -1000.0F) == Cell{-1, -1}, "âm làm tròn xuống");
    const float inf = std::numeric_limits<float>::infinity();
    const Cell far = grid.cell_of(inf, -inf);
    context.expect(far.column == 10000 && far.row == -10000, "vô cực bị kẹp ở trần thế giới");
    context.expect(grid.cell_of(std::nanf(""), 5.0F) == Cell{0, 0}, "NaN về 0");
}

void grid_window_difference(Context& context) {
    Grid grid{{.cell_cm = kCell, .radius = 2}};
    grid.insert(1, Cell{0, 0});
    grid.insert(2, Cell{2, 0});
    grid.insert(3, Cell{3, 0});
    grid.insert(4, Cell{-2, -2});
    std::set<std::uint32_t> in_window;
    grid.for_each_in_window(Cell{0, 0}, [&](std::uint32_t id) { in_window.insert(id); });
    context.expect(in_window == std::set<std::uint32_t>({1, 2, 4}), "cửa sổ 5x5 quanh ô 0,0");
    std::set<std::uint32_t> entered;
    grid.for_each_entered(Cell{0, 0}, Cell{1, 0}, [&](std::uint32_t id) { entered.insert(id); });
    context.expect(entered == std::set<std::uint32_t>({3}), "bước sang phải thấy thêm cột x=3");
    std::set<std::uint32_t> left;
    grid.for_each_left(Cell{0, 0}, Cell{1, 0}, [&](std::uint32_t id) { left.insert(id); });
    context.expect(left == std::set<std::uint32_t>({4}), "bước sang phải mất cột x=-2");
    grid.erase(2, Cell{2, 0});
    grid.erase(2, Cell{2, 0});
    grid.erase(99, Cell{5, 5});
    context.expect(grid.population() == 3, "erase hai lần và erase lạ không làm lệch số đếm");
}

void direction_math(Context& context) {
    context.expect(zone::direction_of({.x_cm = 100.0F, .z_cm = 0.0F}, 7) == 0, "+X là 0");
    context.expect(zone::direction_of({.x_cm = 0.0F, .z_cm = 100.0F}, 7) == 16384, "+Z là một phần tư vòng");
    context.expect(zone::direction_of({.x_cm = -100.0F, .z_cm = 0.0F}, 7) == 32768, "-X là nửa vòng");
    context.expect(zone::direction_of({.x_cm = 0.0F, .z_cm = -100.0F}, 7) == 49152, "-Z là ba phần tư vòng");
    context.expect(zone::direction_of({.x_cm = 0.2F, .z_cm = 0.2F}, 7) == 7, "bước dưới 1 cm giữ hướng cũ");
    context.expect(zone::direction_of({.x_cm = std::nanf(""), .z_cm = 1.0F}, 9) == 9, "NaN giữ hướng cũ");
    context.expect(zone::direction_of({.x_cm = 100.0F, .z_cm = -0.0001F}, 7) == 65535, "sát 2π kẹp ở 65535, không quấn về 0");
}

// --- scene ---

void attach_shows_neighbours_both_ways(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    context.expect(!scene.attach(11, arrival(1, 500.0F, 500.0F), out).has_value(), "người đầu vào được");
    auto first = seen_in(out);
    context.expect(of_kind<protocol::SceneEnter>(first, 11).size() == 1, "người đầu nhận SceneEnter");
    context.expect(of_kind<protocol::EntityAppear>(first, 11).empty(), "cảnh trống: không ai để thấy");
    out.clear();

    context.expect(!scene.attach(22, arrival(2, 1500.0F, 500.0F), out).has_value(), "người hai vào được");
    const auto both = seen_in(out);
    const auto to_second = of_kind<protocol::EntityAppear>(both, 22);
    const auto to_first = of_kind<protocol::EntityAppear>(both, 11);
    context.expect(to_second.size() == 1 && to_second[0].name == "nv1" && to_second[0].level == 7, "người hai thấy người một");
    context.expect(to_first.size() == 1 && to_first[0].name == "nv2" && to_first[0].school == 5, "người một thấy người hai");
    context.expect(to_first[0].kind == protocol::EntityKind::kPlayer && to_first[0].speed_cm == zone::kPlayerSpeedCm &&
            to_first[0].gender == 2 && to_first[0].face == 3 && to_first[0].hair == 4,
        "hồ sơ hiển thị đi theo");
    context.expect(to_first[0].id != 0 && to_first[0].id != to_second[0].id, "id thực thể khác 0 và khác nhau");
    context.expect(scene.player_count() == 2 && scene.entity_count() == 2, "hai người trong cảnh");
}

void far_players_do_not_see_each_other(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    static_cast<void>(scene.attach(22, arrival(2, 5000.0F, 0.0F), out));
    const auto seen = seen_in(out);
    context.expect(of_kind<protocol::EntityAppear>(seen, 11).empty() && of_kind<protocol::EntityAppear>(seen, 22).empty(),
        "cách 5 ô (>2) không thấy nhau");
}

void moving_in_and_out_of_view(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    static_cast<void>(scene.attach(22, arrival(2, 6000.0F, 0.0F), out));
    out.clear();

    scene.moved(22, ipc::Moved{.x_cm = 2500.0F, .z_cm = 0.0F}, out);
    auto seen = seen_in(out);
    context.expect(of_kind<protocol::EntityAppear>(seen, 11).size() == 1, "người một thấy người hai hiện ra");
    context.expect(of_kind<protocol::EntityAppear>(seen, 22).size() == 1, "người hai thấy người một hiện ra");
    out.clear();

    scene.moved(22, ipc::Moved{.x_cm = 2600.0F, .z_cm = 0.0F}, out);
    seen = seen_in(out);
    context.expect(of_kind<protocol::EntityPos>(seen, 11).size() == 1 && of_kind<protocol::EntityAppear>(seen, 11).empty(),
        "cùng ô: chỉ vị trí");
    context.expect(of_kind<protocol::EntityPos>(seen, 22).empty(), "không gửi vị trí cho chính mình");
    out.clear();

    scene.moved(22, ipc::Moved{.x_cm = 1900.0F, .z_cm = 0.0F}, out);
    seen = seen_in(out);
    context.expect(of_kind<protocol::EntityPos>(seen, 11).size() == 1, "đổi ô nhưng vẫn thấy nhau: vị trí");
    out.clear();

    scene.moved(22, ipc::Moved{.x_cm = 9000.0F, .z_cm = 0.0F}, out);
    seen = seen_in(out);
    const auto gone_for_first = of_kind<protocol::EntityDisappear>(seen, 11);
    const auto gone_for_second = of_kind<protocol::EntityDisappear>(seen, 22);
    context.expect(gone_for_first.size() == 1, "người một thấy người hai biến mất");
    context.expect(gone_for_second.size() == 1, "người hai thấy người một biến mất (đúng một lần)");
    context.expect(scene.entity_count() == 2 && scene.player_count() == 2, "đi xa không làm mất người");
}

void teleport_does_not_hide_self(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    out.clear();
    scene.moved(11, ipc::Moved{.x_cm = 90000.0F, .z_cm = 90000.0F}, out);
    const auto seen = seen_in(out);
    context.expect(of_kind<protocol::EntityDisappear>(seen, 11).empty(), "nhảy xa một mình: không tự báo biến mất");
    scene.moved(11, ipc::Moved{.x_cm = std::nanf(""), .z_cm = 0.0F}, out);
    const auto where = scene.where(*scene.entity_of(11));
    context.expect(where && std::isfinite(where->x_cm), "toạ độ NaN không lọt vào cảnh");
}

void detach_and_reuse(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    static_cast<void>(scene.attach(22, arrival(2, 100.0F, 0.0F), out));
    const std::uint32_t old_id = *scene.entity_of(22);
    out.clear();
    scene.detach(22, out);
    auto seen = seen_in(out);
    const auto gone = of_kind<protocol::EntityDisappear>(seen, 11);
    context.expect(gone.size() == 1 && gone[0].id == old_id, "rời cảnh: người còn lại thấy biến mất đúng id");
    context.expect(!scene.has_session(22) && !scene.where(old_id).has_value(), "id cũ không còn tra được");
    scene.detach(22, out);
    context.expect(scene.entity_count() == 1, "detach lần hai không làm gì");
    static_cast<void>(scene.attach(33, arrival(3, 100.0F, 0.0F), out));
    const std::uint32_t new_id = *scene.entity_of(33);
    context.expect(new_id != old_id, "ô cấp lại có id khác (thế hệ đổi)");
    context.expect(!scene.where(old_id).has_value(), "id cũ không trỏ nhầm thực thể mới");
}

void same_character_replaces_old_session(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    out.clear();
    context.expect(!scene.attach(22, arrival(1, 0.0F, 0.0F), out).has_value(), "phiên mới của cùng nhân vật vào được");
    bool closed = false;
    for (const zone::Letter& letter : out.letters()) {
        if (letter.kind != ipc::Relay::kClose || letter.session != 11) continue;
        const auto close = ipc::decode_close(letter.body);
        closed = close && close->reason == protocol::DisconnectReason::kLoginElsewhere;
    }
    context.expect(closed, "phiên cũ bị đóng với lý do đăng nhập nơi khác");
    context.expect(!scene.has_session(11) && scene.has_session(22) && scene.player_count() == 1, "chỉ còn phiên mới");
}

void player_cap(Context& context) {
    Scene scene = make_scene(2);
    Outbox out;
    context.expect(!scene.attach(1, arrival(1, 0.0F, 0.0F), out).has_value(), "chỗ 1");
    context.expect(!scene.attach(2, arrival(2, 0.0F, 0.0F), out).has_value(), "chỗ 2");
    const auto refused = scene.attach(3, arrival(3, 0.0F, 0.0F), out);
    context.expect(refused == protocol::ErrorCode::kServerFull, "đầy thì từ chối kServerFull");
    context.expect(scene.player_count() == 2, "người bị từ chối không vào bảng");
}

void spawned_entities_are_seen(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    out.clear();
    zone::Spawn wolf;
    wolf.kind = protocol::EntityKind::kMonster;
    wolf.template_id = 42;
    wolf.level = 9;
    wolf.x_cm = 300.0F;
    const std::optional<std::uint32_t> wolf_id = scene.spawn(wolf, out);
    context.expect(wolf_id.has_value(), "đặt được quái");
    auto seen = seen_in(out);
    const auto appeared = of_kind<protocol::EntityAppear>(seen, 11);
    context.expect(appeared.size() == 1 && appeared[0].template_id == 42 && appeared[0].id == *wolf_id, "người chơi thấy quái");
    out.clear();

    scene.set_hp_percent(*wolf_id, 40, out);
    seen = seen_in(out);
    const auto vitals = of_kind<protocol::EntityVitals>(seen, 11);
    context.expect(vitals.size() == 1 && vitals[0].hp_percent == 40, "sinh lực đổi được báo");
    scene.set_hp_percent(*wolf_id, 40, out);
    context.expect(of_kind<protocol::EntityVitals>(seen_in(out), 11).size() == 1, "đặt cùng giá trị không báo lại");
    out.clear();

    scene.move_entity(*wolf_id, 9000.0F, 0.0F, out);
    context.expect(of_kind<protocol::EntityDisappear>(seen_in(out), 11).size() == 1, "quái đi xa khỏi tầm thấy");
    out.clear();
    scene.despawn(*wolf_id, out);
    context.expect(!scene.where(*wolf_id).has_value(), "quái đã gỡ");
    zone::Spawn not_a_player;
    not_a_player.kind = protocol::EntityKind::kPlayer;
    context.expect(!scene.spawn(not_a_player, out).has_value(), "spawn không tạo người chơi");
    scene.despawn(*scene.entity_of(11), out);
    context.expect(scene.has_session(11), "despawn không gỡ được người chơi");
}

// --- host ---

[[nodiscard]] ipc::Frame frame_of(ipc::Relay kind, std::uint64_t session, std::vector<std::byte> body) {
    return ipc::Frame{.kind = ipc::value_of(kind), .session = session, .body = std::move(body)};
}

void host_routes_frames(Context& context) {
    Host host{Host::Config{}};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, ipc::encode_body(arrival(1, 0.0F, 0.0F, 7))), out);
    host.handle(frame_of(ipc::Relay::kAttach, 22, ipc::encode_body(arrival(2, 100.0F, 0.0F, 7))), out);
    host.handle(frame_of(ipc::Relay::kAttach, 33, ipc::encode_body(arrival(3, 0.0F, 0.0F, 8))), out);
    context.expect(host.scene_count() == 2 && host.player_count() == 3, "hai cảnh được tạo lười, ba người");
    out.clear();
    host.handle(frame_of(ipc::Relay::kMoved, 22, ipc::encode_body(ipc::Moved{.x_cm = 200.0F, .z_cm = 0.0F})), out);
    const auto seen = seen_in(out);
    context.expect(of_kind<protocol::EntityPos>(seen, 11).size() == 1, "vị trí chỉ tới người cùng cảnh");
    context.expect(of_kind<protocol::EntityPos>(seen, 33).empty(), "không tới cảnh khác");
    out.clear();
    host.handle(frame_of(ipc::Relay::kDetach, 22, {}), out);
    host.handle(frame_of(ipc::Relay::kDetach, 22, {}), out);
    context.expect(host.player_count() == 2, "detach hai lần chỉ rút một người");
    host.handle(frame_of(ipc::Relay::kMoved, 22, ipc::encode_body(ipc::Moved{})), out);
    context.expect(host.ignored() == 1, "Moved của phiên đã rời bị bỏ và đếm");
    host.drop_all(out);
    context.expect(host.player_count() == 0, "mất kênh: không còn người nào");
}

void host_refuses_bad_attach(Context& context) {
    Host host{Host::Config{.scene_max = 2}};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, std::vector<std::byte>(5, std::byte{1})), out);
    ipc::Attach bad_gender = arrival(1, 0.0F, 0.0F);
    bad_gender.gender = 9;
    host.handle(frame_of(ipc::Relay::kAttach, 12, ipc::encode_body(bad_gender)), out);
    ipc::Attach bad_spot = arrival(2, 0.0F, 0.0F);
    bad_spot.x_cm = std::nanf("");
    host.handle(frame_of(ipc::Relay::kAttach, 13, ipc::encode_body(bad_spot)), out);
    std::size_t malformed = 0;
    for (const zone::Letter& letter : out.letters()) {
        const auto refuse = letter.kind == ipc::Relay::kRefuse ? ipc::decode_refuse(letter.body) : std::nullopt;
        if (refuse && refuse->code == protocol::ErrorCode::kMalformed) ++malformed;
    }
    context.expect(malformed == 3, "ba Attach hỏng đều bị từ chối kMalformed");
    context.expect(host.player_count() == 0 && host.scene_count() == 0, "Attach hỏng không tạo cảnh");

    out.clear();
    host.handle(frame_of(ipc::Relay::kAttach, 1, ipc::encode_body(arrival(1, 0.0F, 0.0F, 1))), out);
    host.handle(frame_of(ipc::Relay::kAttach, 2, ipc::encode_body(arrival(2, 0.0F, 0.0F, 2))), out);
    host.handle(frame_of(ipc::Relay::kAttach, 3, ipc::encode_body(arrival(3, 0.0F, 0.0F, 3))), out);
    std::size_t busy = 0;
    for (const zone::Letter& letter : out.letters()) {
        const auto refuse = letter.kind == ipc::Relay::kRefuse ? ipc::decode_refuse(letter.body) : std::nullopt;
        if (refuse && refuse->code == protocol::ErrorCode::kBusy && letter.session == 3) ++busy;
    }
    context.expect(busy == 1 && host.scene_count() == 2, "quá scene_max: cảnh thứ ba bị từ chối kBusy");
}

// --- ghi điểm đứng ---

void detach_saves_final_spot(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(42, 1000.0F, 2000.0F, 1), out));
    context.expect(out.saves().empty(), "vào cảnh chưa phải lúc ghi");
    scene.moved(11, ipc::Moved{.x_cm = 1234.6F, .z_cm = -50.4F}, out);
    context.expect(out.saves().empty(), "đi chưa ghi ngay (chờ chu kỳ hay lúc rời)");
    scene.detach(11, out);
    const std::vector<zone::Save>& saves = out.saves();
    context.expect(saves.size() == 1 && saves[0] == zone::Save{.character = 42, .scene = 1, .x_cm = 1235, .z_cm = -50},
        "rời cảnh ghi đúng điểm cuối, làm tròn centimet");
    scene.detach(11, out);
    context.expect(out.saves().size() == 1, "detach lần hai không ghi lại");
}

void autosave_writes_only_walkers(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    static_cast<void>(scene.attach(22, arrival(2, 100.0F, 0.0F), out));
    scene.moved(22, ipc::Moved{.x_cm = 150.0F, .z_cm = 0.0F}, out);
    scene.autosave(out);
    context.expect(out.saves().size() == 1 && out.saves()[0].character == 2, "chỉ người đã đi được ghi");
    scene.autosave(out);
    context.expect(out.saves().size() == 1, "ghi xong thì sạch cờ, chu kỳ sau không ghi lại");
    scene.moved(22, ipc::Moved{.x_cm = 160.0F, .z_cm = 0.0F}, out);
    scene.autosave(out);
    context.expect(out.saves().size() == 2 && out.saves()[1].x_cm == 160, "đi tiếp thì ghi lại với điểm mới");
}

void host_autosaves_each_period(Context& context) {
    Host host{Host::Config{}};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, ipc::encode_body(arrival(1, 0.0F, 0.0F, 7))), out);
    host.handle(frame_of(ipc::Relay::kMoved, 11, ipc::encode_body(ipc::Moved{.x_cm = 50.0F, .z_cm = 0.0F})), out);
    for (std::uint32_t tick = 1; tick < Host::kAutosaveTicks; ++tick) {
        host.advance(out);
    }
    context.expect(out.saves().empty(), "chưa tới chu kỳ thì chưa ghi");
    host.advance(out);
    context.expect(out.saves().size() == 1 && out.saves()[0].scene == 7 && out.saves()[0].x_cm == 50,
        "đủ chu kỳ thì ghi người đã đi");
    host.drop_all(out);
    context.expect(out.saves().size() == 2, "mất kênh: ghi nốt mọi người còn lại");
}

// --- luồng ghi ---

struct Recorder {
    std::mutex lock;
    std::vector<zone::Save> sent;
    std::atomic<int> calls{0};
};

template <typename Pred>
[[nodiscard]] bool wait_until(Pred done) {
    for (int round = 0; round < 3000; ++round) {
        if (done()) return true;
        std::this_thread::sleep_for(std::chrono::milliseconds{1});
    }
    return done();
}

void saver_keeps_newest_and_retries(Context& context) {
    Recorder recorder;
    std::atomic<bool> release{false};
    zone::Saver saver{[&](const zone::Save& spot) {
        const int call = ++recorder.calls;
        if (call == 1) {
            // Lần đầu: giữ lại tới khi test đã đẩy bản mới hơn, rồi báo hỏng.
            while (!release.load()) std::this_thread::yield();
            return false;
        }
        const std::scoped_lock guard{recorder.lock};
        recorder.sent.push_back(spot);
        return true;
    }, zone::Saver::Waits{.retry = std::chrono::milliseconds{5}, .flush = std::chrono::milliseconds{1000}}};
    saver.push(zone::Save{.character = 1, .scene = 1, .x_cm = 100, .z_cm = 0});
    context.expect(wait_until([&] { return recorder.calls.load() >= 1; }), "lần gửi đầu bắt đầu");
    saver.push(zone::Save{.character = 1, .scene = 1, .x_cm = 200, .z_cm = 0});
    release = true;
    context.expect(wait_until([&] { return saver.saved() == 1; }), "bản mới hơn được gửi sau lần hỏng");
    const std::scoped_lock guard{recorder.lock};
    context.expect(recorder.sent.size() == 1 && recorder.sent[0].x_cm == 200, "bản cũ đang bay không đè bản mới");
    context.expect(saver.failures() == 1 && saver.pending() == 0, "một lần hỏng, hết hàng chờ");
}

void saver_flushes_on_destruction(Context& context) {
    Recorder recorder;
    {
        zone::Saver saver{[&](const zone::Save& spot) {
            const std::scoped_lock guard{recorder.lock};
            recorder.sent.push_back(spot);
            return true;
        }};
        for (std::uint64_t id = 1; id <= 5; ++id) {
            saver.push(zone::Save{.character = id, .scene = 1, .x_cm = static_cast<std::int32_t>(id), .z_cm = 0});
        }
    }
    const std::scoped_lock guard{recorder.lock};
    std::set<std::uint64_t> seen;
    for (const zone::Save& spot : recorder.sent) {
        seen.insert(spot.character);
    }
    context.expect(seen == std::set<std::uint64_t>({1, 2, 3, 4, 5}), "huỷ Saver gửi nốt hàng chờ");
}

void saver_gives_up_when_store_is_dead(Context& context) {
    std::atomic<int> calls{0};
    const auto began = std::chrono::steady_clock::now();
    {
        zone::Saver saver{[&](const zone::Save&) {
            ++calls;
            return false;
        }, zone::Saver::Waits{.retry = std::chrono::milliseconds{5}, .flush = std::chrono::milliseconds{100}}};
        saver.push(zone::Save{.character = 9, .scene = 1, .x_cm = 1, .z_cm = 1});
        context.expect(wait_until([&] { return calls.load() >= 2; }), "thử lại khi store chưa nhận");
    }
    const auto took = std::chrono::steady_clock::now() - began;
    context.expect(took < std::chrono::seconds{3}, "store chết không giữ zone dừng quá hạn flush");
}

// --- quái và NPC đặt sẵn ---

[[nodiscard]] scenedata::Spawn row_at(std::uint32_t type, float x_unit, float z_unit, bool is_npc = false) {
    scenedata::Spawn row;
    row.type = ids::MonsterTemplateId{type};
    row.position = core::GroundPoint{.x = x_unit, .z = z_unit};
    row.position_given = true;
    row.is_npc = is_npc;
    return row;
}

void seeds_convert_units_and_skip_unplaced(Context& context) {
    scenedata::Scene scene;
    scene.spawns.push_back(row_at(101, 12.5F, 30.0F));
    scene.spawns.back().direction = 9; // 9 * 10 + 90 = 180 độ
    scene.spawns.back().level = 40;
    scene.spawns.back().respawn_ms = 15000;
    scene.spawns.push_back(row_at(202, 1.0F, 2.0F, true));
    scene.spawns.back().name = "Tiêu Phong";
    scenedata::Spawn blank = row_at(303, 0.0F, 0.0F);
    blank.position_given = false;
    scene.spawns.push_back(blank);
    scenedata::Spawn pet = row_at(404, 3.0F, 4.0F);
    pet.is_pet = true;
    scene.spawns.push_back(pet);
    scene.spawns.push_back(row_at(505, 5.0F, 5.0F));

    const zone::Seeding all = zone::seeds_of(scene, 100, zone::TemplateTable{});
    context.expect(all.seeds.size() == 4 && all.unplaced == 1 && all.over_cap == 0, "bốn dòng có vị trí, một dòng bỏ trống");
    const zone::Seed& monster = all.seeds[0];
    context.expect(monster.what.kind == protocol::EntityKind::kMonster && monster.what.template_id == 101 &&
            monster.what.level == 40 && monster.respawn_ms == 15000,
        "quái giữ mẫu, cấp và thời gian hồi sinh");
    context.expect(monster.what.x_cm == 1250.0F && monster.what.z_cm == 3000.0F, "đơn vị game nhân 100 ra centimet");
    context.expect(monster.what.direction == 32768, "180 độ là nửa vòng");
    context.expect(all.seeds[1].what.kind == protocol::EntityKind::kNpc && all.seeds[1].what.name == "Tiêu Phong" &&
            all.seeds[1].what.level == 0,
        "NPC giữ tên, cấp 0 nghĩa là lấy theo mẫu");
    context.expect(all.seeds[2].what.kind == protocol::EntityKind::kPet, "trân thú hoang");

    const zone::Seeding capped = zone::seeds_of(scene, 2, zone::TemplateTable{});
    context.expect(capped.seeds.size() == 2 && capped.over_cap == 2 && capped.unplaced == 1,
        "trần chặn từ dòng thứ ba, dòng thừa được đếm");
    context.expect(zone::seeds_of(scene, 0, zone::TemplateTable{}).seeds.empty(), "trần 0 không đặt gì");

    // Bảng mẫu làm giàu: can_interact = 1 thành NPC, cấp mẫu thay cấp 0 của bảng cảnh, cấp bảng cảnh vẫn thắng.
    const auto templates = zone::TemplateTable::parse(
        "# schema 1\nmonster_id\tname\tlevel\tcan_interact\n101\tNhện\t30\t0\n202\tThợ rèn\t60\t1\n505\tChó\t5\t-1\n");
    context.expect(templates.has_value() && templates->size() == 3, "bảng mẫu đọc được ba dòng");
    if (!templates) return;
    const zone::Seeding enriched = zone::seeds_of(scene, 100, *templates);
    context.expect(enriched.seeds[0].what.level == 40 && enriched.seeds[0].what.kind == protocol::EntityKind::kMonster,
        "cấp trong bảng cảnh thắng cấp của mẫu");
    context.expect(enriched.seeds[1].what.kind == protocol::EntityKind::kNpc && enriched.seeds[1].what.level == 60,
        "mẫu tương tác được là NPC, cấp lấy theo mẫu");
    context.expect(enriched.seeds[3].what.kind == protocol::EntityKind::kMonster && enriched.seeds[3].what.level == 5,
        "can_interact = -1 là quái");
}

void template_table_rejects_bad_text(Context& context) {
    const auto head = [](std::string_view rows) { return std::string{"monster_id\tlevel\tcan_interact\n"}.append(rows); };
    context.expect(zone::TemplateTable::parse(head("1\t10\t1\n")).has_value(), "bảng tối thiểu hợp lệ");
    context.expect(zone::TemplateTable::parse(head("1\t10\t1\r\n2\t11\t0\r\n")).has_value(), "xuống dòng CRLF");
    context.expect(!zone::TemplateTable::parse(""), "rỗng không có dòng tên cột");
    context.expect(!zone::TemplateTable::parse("monster_id\tlevel\n1\t2\n"), "thiếu cột can_interact");
    context.expect(!zone::TemplateTable::parse(head("1\t10\n")), "dòng thiếu ô");
    context.expect(!zone::TemplateTable::parse(head("x\t10\t1\n")), "id không phải số");
    context.expect(!zone::TemplateTable::parse(head("1\t70000\t1\n")), "cấp ngoài u16");
    context.expect(!zone::TemplateTable::parse(head("-5\t1\t1\n")), "id âm");
    context.expect(!zone::TemplateTable::parse(head("1\t10\t1\n1\t11\t0\n")), "id trùng");
    context.expect(!zone::TemplateTable::parse(std::string(300, '\t')), "dòng tên cột quá nhiều cột");
}

void scene_directory_lookup_and_hostile_tables(Context& context) {
    constexpr std::string_view kText =
        "# schema 1\n"
        "client_id_first\tclient_id_last\tscene_dir\tclient_res_id\tmatch\n"
        "0\t0\tluoyang\t0\tid\n"
        "2\t2\tdali\t2\tid\n"
        "61\t62\tleitai_1\t82\tid\n"
        "65535\t65535\tlast\t1\tid\n";
    const auto directory = zone::SceneDirectory::parse(kText);
    context.expect(directory.has_value() && directory->range_count() == 4, "bốn khoảng đọc được");
    if (!directory) return;
    context.expect(directory->dir_of(0) == "luoyang" && directory->dir_of(2) == "dali", "id đơn");
    context.expect(directory->dir_of(61) == "leitai_1" && directory->dir_of(62) == "leitai_1", "khoảng gồm cả hai đầu");
    context.expect(directory->dir_of(1).empty() && directory->dir_of(63).empty() && directory->dir_of(5000).empty(),
        "id nằm giữa các khoảng không có thư mục");
    context.expect(directory->dir_of(65535) == "last", "id lớn nhất của u16");

    const auto header = [](std::string_view rows) {
        return std::string{"client_id_first\tclient_id_last\tscene_dir\tclient_res_id\tmatch\n"}.append(rows);
    };
    context.expect(!zone::SceneDirectory::parse(header("5\t9\ta\t0\tid\n7\t7\tb\t0\tid\n")), "khoảng chồng nhau bị từ chối");
    context.expect(!zone::SceneDirectory::parse(header("5\t9\ta\t0\tid\n5\t5\tb\t0\tid\n")), "trùng id đầu bị từ chối");
    context.expect(!zone::SceneDirectory::parse(header("1\t9\ta\t0\tid\n9\t12\tb\t0\tid\n")), "chạm đầu mút bị từ chối");
    context.expect(!zone::SceneDirectory::parse(header("9\t5\ta\t0\tid\n")), "đầu lớn hơn cuối");
    context.expect(!zone::SceneDirectory::parse(header("1\t1\t../etc\t0\tid\n")), "tên thư mục dẫn ra ngoài");
    context.expect(!zone::SceneDirectory::parse(header("1\t1\ta/b\t0\tid\n")), "tên thư mục có dấu gạch");
    context.expect(!zone::SceneDirectory::parse(header("1\t1\t\t0\tid\n")), "tên thư mục rỗng");
    context.expect(!zone::SceneDirectory::parse(header("1\t70000\ta\t0\tid\n")), "id ngoài u16");
    context.expect(!zone::SceneDirectory::parse(header("x\t1\ta\t0\tid\n")), "id không phải số");
    context.expect(zone::SceneDirectory::parse(header("")).has_value(), "bảng không dòng nào là hợp lệ, không có cảnh");
}

void host_seeds_scene_once_on_creation(Context& context) {
    int calls = 0;
    Host::Config config;
    config.seeder = [&calls](std::uint16_t scene) {
        ++calls;
        zone::SceneContent content;
        if (scene != 1) return content;
        for (const float x : {500.0F, 1500.0F, 90000.0F}) {
            zone::Spawn what;
            what.kind = protocol::EntityKind::kNpc;
            what.template_id = 7000 + static_cast<std::uint32_t>(x / 1000.0F);
            what.x_cm = x;
            what.z_cm = 500.0F;
            content.seeds.push_back(zone::Seed{.what = what});
        }
        return content;
    };
    Host host{config};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, ipc::encode_body(arrival(1, 600.0F, 500.0F, 1))), out);
    const auto first = seen_in(out);
    const auto shown = of_kind<protocol::EntityAppear>(first, 11);
    context.expect(calls == 1, "seeder chỉ được hỏi khi cảnh được tạo");
    context.expect(shown.size() == 2 && shown[0].kind == protocol::EntityKind::kNpc, "người vào thấy hai NPC trong cửa sổ, không thấy NPC ở xa");
    const Scene* scene = host.find(1);
    context.expect(scene != nullptr && scene->entity_count() == 4 && scene->player_count() == 1,
        "cảnh có 3 NPC đặt sẵn và 1 người, kể cả NPC ngoài cửa sổ");
    out.clear();
    host.handle(frame_of(ipc::Relay::kAttach, 22, ipc::encode_body(arrival(2, 700.0F, 500.0F, 1))), out);
    context.expect(calls == 1, "người thứ hai vào cảnh cũ không đặt lại");
    host.handle(frame_of(ipc::Relay::kAttach, 33, ipc::encode_body(arrival(3, 100.0F, 100.0F, 2))), out);
    context.expect(calls == 2 && host.find(2) != nullptr && host.find(2)->entity_count() == 1, "cảnh khác có seeder riêng, trống");
}

void host_seeding_leaves_room_for_players(Context& context) {
    Host::Config config;
    config.player_max = zone::kEntityMax - 3;
    config.seeder = [](std::uint16_t) {
        zone::SceneContent content;
        for (int at = 0; at < 10; ++at) {
            zone::Spawn what;
            what.template_id = 1;
            what.x_cm = static_cast<float>(at) * 10.0F;
            content.seeds.push_back(zone::Seed{.what = what});
        }
        return content;
    };
    Host host{config};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, ipc::encode_body(arrival(1, 0.0F, 0.0F, 1))), out);
    const Scene* scene = host.find(1);
    context.expect(scene != nullptr && scene->entity_count() == 3 + 1, "đặt tối đa kEntityMax - player_max, còn chỗ cho người");
}

// Dữ liệu thật: id 2 của client là Đại Lý. Tự bỏ qua khi bản dựng không có thư mục dữ liệu máy chủ.
void real_scene_seeds(Context& context) {
#ifdef GAME_SERVER_DATA
    const std::filesystem::path root{GAME_SERVER_DATA};
    std::error_code error;
    if (!std::filesystem::is_directory(root / "scenes" / "dali", error)) return;
    const zone::Seeder seeder = zone::disk_seeder(
        zone::DiskPaths{.scenes = root / "scenes",
            .ids_table = root / "tables" / "server" / "scene_ids.tsv",
            .templates = root / "tables" / "shared" / "monsters.tsv"},
        49000);
    const zone::SceneContent dali = seeder(2);
    const std::vector<zone::Seed>& seeds = dali.seeds;
    context.expect(!seeds.empty(), "Đại Lý có quái và NPC đặt sẵn");
    context.expect(static_cast<bool>(dali.walkable), "Đại Lý có luật đi (lưới .path của client 2026)");
    if (dali.walkable) {
        // Đổi centimet sang đơn vị game sai thì gần như không điểm đặt nào nằm trong lưới; đúng thì đa số nằm trong.
        std::size_t standing = 0;
        for (const zone::Seed& one : seeds) {
            if (dali.walkable(one.what.x_cm, one.what.z_cm)) ++standing;
        }
        // docs/SERVER-SCENEDATA.md mục 5: bảng quái 2008 lệch bố cục map 2026, Đại Lý có 50/164 điểm đặt ngoài lưới (khoảng 70% trong).
        context.expect(standing * 10 >= seeds.size() * 6, "từ 60% quái và NPC đặt sẵn đứng trong lưới đi của cảnh");
        context.expect(!dali.walkable(-5000000.0F, -5000000.0F), "điểm ngoài cảnh không đi được");
    }
    std::size_t npcs = 0;
    bool inside = true;
    for (const zone::Seed& one : seeds) {
        if (one.what.kind == protocol::EntityKind::kNpc) ++npcs;
        inside = inside && std::isfinite(one.what.x_cm) && std::isfinite(one.what.z_cm) && one.what.x_cm >= 0.0F &&
            one.what.z_cm >= 0.0F && one.what.x_cm < 100000.0F && one.what.z_cm < 100000.0F;
    }
    // NPC chỉ nhận ra được khi có bảng mẫu của client (tables/shared bị git bỏ qua, sinh bởi build_data.py).
    if (std::filesystem::exists(root / "tables" / "shared" / "monsters.tsv", error)) {
        context.expect(npcs > 0, "có NPC trong số đó");
    }
    context.expect(inside, "toạ độ đổi ra centimet nằm trong khoảng hợp lý (0..1000 m)");
    context.expect(seeder(65534).seeds.empty() && !seeder(65534).walkable, "id lạ không có cảnh nào");
    Host::Config config;
    config.seeder = seeder;
    Host host{config};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, ipc::encode_body(arrival(1, 0.0F, 0.0F, 2))), out);
    const Scene* scene = host.find(2);
    context.expect(scene != nullptr && scene->entity_count() == seeds.size() + 1, "cảnh thật đặt đủ số thực thể rồi thêm người");
#else
    static_cast<void>(context);
#endif
}

// --- luật đi ---

// Vùng đi được hình chữ nhật [0, 5000] x [0, 5000] cm.
[[nodiscard]] bool in_yard(float x_cm, float z_cm) { return x_cm >= 0.0F && x_cm <= 5000.0F && z_cm >= 0.0F && z_cm <= 5000.0F; }

[[nodiscard]] Scene make_walled_scene() {
    return Scene{Scene::Config{
        .id = 1, .grid = {.cell_cm = kCell, .radius = 2}, .player_max = 100, .walkable = &in_yard}};
}

[[nodiscard]] std::vector<ipc::Place> places_in(const Outbox& out, std::uint64_t session) {
    std::vector<ipc::Place> found;
    for (const zone::Letter& letter : out.letters()) {
        if (letter.kind != ipc::Relay::kPlace || letter.session != session) continue;
        if (const auto spot = ipc::decode_place(letter.body)) found.push_back(*spot);
    }
    return found;
}

void walkable_blocks_step_into_wall(Context& context) {
    Scene scene = make_walled_scene();
    Outbox out;
    context.expect(!scene.attach(11, arrival(1, 1000.0F, 1000.0F), out).has_value(), "vào trong sân");
    out.clear();
    scene.moved(11, ipc::Moved{.x_cm = 1100.0F, .z_cm = 1000.0F}, out);
    const std::optional<Scene::Where> inside = scene.where(*scene.entity_of(11));
    context.expect(inside && inside->x_cm == 1100.0F && places_in(out, 11).empty(), "bước trong sân được nhận, không hoàn lại");

    scene.moved(11, ipc::Moved{.x_cm = 5100.0F, .z_cm = 1000.0F}, out);
    const std::optional<Scene::Where> held = scene.where(*scene.entity_of(11));
    context.expect(held && held->x_cm == 1100.0F && held->z_cm == 1000.0F, "bước ra ngoài sân không dời người chơi");
    const std::vector<ipc::Place> back = places_in(out, 11);
    context.expect(back.size() == 1 && back[0] == ipc::Place{.x_cm = 1100.0F, .z_cm = 1000.0F},
        "zone ra lệnh đặt lại đúng chỗ cũ");
    context.expect(of_kind<protocol::EntityPos>(seen_in(out), 11).empty(), "không phát EntityPos của bước bị chặn");
}

void walkable_neighbour_does_not_see_blocked_step(Context& context) {
    Scene scene = make_walled_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 1000.0F, 1000.0F), out));
    static_cast<void>(scene.attach(22, arrival(2, 1200.0F, 1000.0F), out));
    out.clear();
    scene.moved(11, ipc::Moved{.x_cm = 5200.0F, .z_cm = 1000.0F}, out);
    context.expect(of_kind<protocol::EntityPos>(seen_in(out), 22).empty(), "người đứng cạnh không thấy bước bị chặn");
    context.expect(places_in(out, 22).empty() && places_in(out, 11).size() == 1, "chỉ người đi sai bị đặt lại");
}

void walkable_lets_trapped_player_leave(Context& context) {
    Scene scene = make_walled_scene();
    Outbox out;
    // Điểm lưu cũ nằm ngoài lưới (lưới đổi sau khi lưu): vẫn vào được, vẫn đi ra được.
    context.expect(!scene.attach(11, arrival(1, 6000.0F, 1000.0F), out).has_value(), "vào ở chỗ không đi được");
    out.clear();
    scene.moved(11, ipc::Moved{.x_cm = 6100.0F, .z_cm = 1000.0F}, out);
    scene.moved(11, ipc::Moved{.x_cm = 5000.0F, .z_cm = 1000.0F}, out);
    const std::optional<Scene::Where> now = scene.where(*scene.entity_of(11));
    context.expect(now && now->x_cm == 5000.0F && places_in(out, 11).empty(), "đi từ ngoài vào trong sân, không bị hoàn lại");
}

void walkable_absent_allows_everything(Context& context) {
    Scene scene = make_scene();
    Outbox out;
    static_cast<void>(scene.attach(11, arrival(1, 0.0F, 0.0F), out));
    out.clear();
    scene.moved(11, ipc::Moved{.x_cm = 9999999.0F, .z_cm = -9999999.0F}, out);
    context.expect(places_in(out, 11).empty(), "cảnh không có lưới đi thì không chặn bước nào");
}

void walkable_of_keeps_the_edge_slack(Context& context) {
    // Lưới ô 0,5 đơn vị (50 cm) 20 x 20, cột x >= 10 (x >= 500 cm) có trạng thái 15: không đi bộ được.
    scenedata::LegacyGrid grid;
    grid.width = 20;
    grid.height = 20;
    grid.state.assign(400, 0);
    for (std::size_t row = 0; row < 20; ++row) {
        for (std::size_t column = 10; column < 20; ++column) {
            grid.state[(row * 20) + column] = 15;
        }
    }
    scenedata::Walk walk;
    walk.source = scenedata::WalkSource::kLegacyNav;
    walk.grid = std::move(grid);
    const zone::Walkable stands = zone::walkable_of(std::make_shared<const scenedata::Walk>(std::move(walk)));
    context.expect(static_cast<bool>(stands), "cảnh có lưới thì có luật đi");
    context.expect(stands(250.0F, 250.0F), "giữa vùng đi được");
    context.expect(!stands(700.0F, 250.0F), "giữa vùng không đi được");
    context.expect(stands(515.0F, 250.0F), "lệch ra mép dưới độ nới 20 cm vẫn nhận");
    context.expect(!stands(525.0F, 250.0F), "quá độ nới 20 cm thì chặn");
    context.expect(!stands(-30.0F, 250.0F), "ngoài lưới không đi được");
    context.expect(!zone::walkable_of(std::make_shared<const scenedata::Walk>()), "cảnh không có lưới: không có luật đi");
    context.expect(!zone::walkable_of(nullptr), "con trỏ rỗng: không có luật đi");
}

void host_ignores_place_from_gate(Context& context) {
    Host host{Host::Config{}};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, ipc::encode_body(arrival(1, 0.0F, 0.0F, 1))), out);
    const std::uint64_t before = host.ignored();
    host.handle(frame_of(ipc::Relay::kPlace, 11, ipc::encode_body(ipc::Place{.x_cm = 9.0F, .z_cm = 9.0F})), out);
    context.expect(host.ignored() == before + 1, "kPlace chỉ đi từ zone về gate, gửi ngược chiều thì bị bỏ và đếm");
}

void host_gives_scene_the_walkable_rule(Context& context) {
    Host::Config config;
    config.seeder = [](std::uint16_t) { return zone::SceneContent{.seeds = {}, .walkable = &in_yard}; };
    Host host{config};
    Outbox out;
    host.handle(frame_of(ipc::Relay::kAttach, 11, ipc::encode_body(arrival(1, 1000.0F, 1000.0F, 1))), out);
    out.clear();
    host.handle(frame_of(ipc::Relay::kMoved, 11, ipc::encode_body(ipc::Moved{.x_cm = 7000.0F, .z_cm = 1000.0F})), out);
    context.expect(places_in(out, 11).size() == 1, "luật đi của nguồn dữ liệu được áp cho cảnh mới tạo");
}

// --- relay codec ---

void relay_codec_round_trip(Context& context) {
    const ipc::Attach sent = arrival(77, -1234.5F, 99.0F, 12);
    const auto got = ipc::decode_attach(ipc::encode_body(sent));
    context.expect(got.has_value() && *got == sent, "Attach đi về nguyên vẹn");
    const std::vector<std::byte> body = ipc::encode_body(sent);
    context.expect(!ipc::decode_attach(std::span{body}.first(body.size() - 1)).has_value(), "thiếu byte bị từ chối");
    std::vector<std::byte> longer = body;
    longer.push_back(std::byte{0});
    context.expect(!ipc::decode_attach(longer).has_value(), "thừa byte bị từ chối");
    const ipc::Moved step{.x_cm = 1.5F, .z_cm = -2.5F};
    context.expect(ipc::decode_moved(ipc::encode_body(step)) == step, "Moved đi về nguyên vẹn");
    const ipc::Place spot{.x_cm = -3.5F, .z_cm = 4.25F};
    context.expect(ipc::decode_place(ipc::encode_body(spot)) == spot, "Place đi về nguyên vẹn");
    context.expect(!ipc::decode_place(std::vector<std::byte>(8, std::byte{0xFF})).has_value(), "Place NaN bị từ chối");
    const std::vector<std::byte> place_body = ipc::encode_body(spot);
    context.expect(!ipc::decode_place(std::span{place_body}.first(7)).has_value(), "Place thiếu byte bị từ chối");
    std::vector<std::byte> long_place = place_body;
    long_place.push_back(std::byte{0});
    context.expect(!ipc::decode_place(long_place).has_value(), "Place thừa byte bị từ chối");
    context.expect(!ipc::decode_moved(std::vector<std::byte>(8, std::byte{0xFF})).has_value(), "Moved NaN bị từ chối");
    context.expect(ipc::decode_refuse(ipc::encode_body(ipc::Refuse{protocol::ErrorCode::kServerFull})).has_value(),
        "Refuse đi về");
    context.expect(!ipc::decode_refuse(std::vector<std::byte>{std::byte{0xFF}, std::byte{0xFF}}).has_value(),
        "Refuse mã lạ bị từ chối");
    context.expect(!ipc::decode_close(std::vector<std::byte>{std::byte{0}}).has_value(), "Close lý do lạ bị từ chối");
    std::vector<std::byte> framed;
    context.expect(protocol::encode(framed, protocol::EntityDisappear{.id = 5}).has_value(), "mã hoá một khung");
    context.expect(ipc::is_single_frame(framed), "một khung đầy đủ");
    context.expect(!ipc::is_single_frame(std::span{framed}.first(framed.size() - 1)), "thiếu byte không phải khung");
    framed.push_back(std::byte{0});
    context.expect(!ipc::is_single_frame(framed), "thừa byte không phải một khung");
    context.expect(!ipc::is_single_frame({}), "rỗng không phải khung");
}

constexpr std::array kCases{
    Case{"grid_cells_and_clamp", grid_cells_and_clamp},
    Case{"grid_window_difference", grid_window_difference},
    Case{"direction_math", direction_math},
    Case{"attach_shows_neighbours_both_ways", attach_shows_neighbours_both_ways},
    Case{"far_players_do_not_see_each_other", far_players_do_not_see_each_other},
    Case{"moving_in_and_out_of_view", moving_in_and_out_of_view},
    Case{"teleport_does_not_hide_self", teleport_does_not_hide_self},
    Case{"detach_and_reuse", detach_and_reuse},
    Case{"same_character_replaces_old_session", same_character_replaces_old_session},
    Case{"player_cap", player_cap},
    Case{"spawned_entities_are_seen", spawned_entities_are_seen},
    Case{"host_routes_frames", host_routes_frames},
    Case{"host_refuses_bad_attach", host_refuses_bad_attach},
    Case{"relay_codec_round_trip", relay_codec_round_trip},
    Case{"seeds_convert_units_and_skip_unplaced", seeds_convert_units_and_skip_unplaced},
    Case{"scene_directory_lookup_and_hostile_tables", scene_directory_lookup_and_hostile_tables},
    Case{"template_table_rejects_bad_text", template_table_rejects_bad_text},
    Case{"host_seeds_scene_once_on_creation", host_seeds_scene_once_on_creation},
    Case{"host_seeding_leaves_room_for_players", host_seeding_leaves_room_for_players},
    Case{"real_scene_seeds", real_scene_seeds},
    Case{"walkable_blocks_step_into_wall", walkable_blocks_step_into_wall},
    Case{"walkable_neighbour_does_not_see_blocked_step", walkable_neighbour_does_not_see_blocked_step},
    Case{"walkable_lets_trapped_player_leave", walkable_lets_trapped_player_leave},
    Case{"walkable_absent_allows_everything", walkable_absent_allows_everything},
    Case{"walkable_of_keeps_the_edge_slack", walkable_of_keeps_the_edge_slack},
    Case{"host_ignores_place_from_gate", host_ignores_place_from_gate},
    Case{"host_gives_scene_the_walkable_rule", host_gives_scene_the_walkable_rule},
    Case{"detach_saves_final_spot", detach_saves_final_spot},
    Case{"autosave_writes_only_walkers", autosave_writes_only_walkers},
    Case{"host_autosaves_each_period", host_autosaves_each_period},
    Case{"saver_keeps_newest_and_retries", saver_keeps_newest_and_retries},
    Case{"saver_flushes_on_destruction", saver_flushes_on_destruction},
    Case{"saver_gives_up_when_store_is_dead", saver_gives_up_when_store_is_dead},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
