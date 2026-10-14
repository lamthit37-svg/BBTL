// Vùng nhìn, cảnh và host của zone: lưới ô, ai thấy ai khi vào/đi/rời, id thực thể không dùng lại ngay,
// trần người chơi và cảnh, khung hỏng từ gate. Không mạng: đưa thẳng ipc::Frame và đọc Outbox.
#include "ipc/relay.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "test.hpp"
#include "zone/aoi.hpp"
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
    context.expect(zone::direction_of({.x_cm = 100.0F, .z_cm = -0.0001F}, 7) <= 65535, "sát 2π không tràn u16");
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
    zone::Spawn wolf{.kind = protocol::EntityKind::kMonster, .template_id = 42, .level = 9, .x_cm = 300.0F, .z_cm = 0.0F};
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
    context.expect(!scene.spawn(zone::Spawn{.kind = protocol::EntityKind::kPlayer}, out).has_value(),
        "spawn không tạo người chơi");
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
