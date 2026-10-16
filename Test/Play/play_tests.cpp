/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Play/play_tests.cpp
 *  PHÂN HỆ   : Server / Play Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cửa vào gameplay của zone trên bảng THẬT: nói chuyện với Triệu Thiên Sư
 *    (script 2030, Đại Lý), nhận nhiệm vụ tân thủ, ghi trạng chơi; rồi những
 *    đầu vào thù địch (NPC lạ, phiên cũ, quá xa, gửi dồn, khung rác) đều bị từ
 *    chối hoặc bỏ mà không đổi trạng thái. Bảng vắng (chưa chạy lua_extract.py)
 *    thì bỏ qua và nói rõ ở stdout.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "play/text.hpp"
#include "test.hpp"

#include <array>
#include <string>

#ifdef GAME_SERVER_TABLES

#include "account/play.hpp"
#include "ipc/relay.hpp"
#include "play/gameplay.hpp"
#include "play/world.hpp"
#include "protocol/messages.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <map>
#include <memory>
#include <optional>
#include <span>
#include <utility>
#include <variant>
#include <vector>

#endif

namespace game::test {
namespace {

void clip_never_splits_a_character(Context& context) {
    // "đạo": 'đ' là hai byte (C4 91), 'ạ' là ba byte (E1 BA A1); cắt giữa ký tự phải lùi về ranh giới.
    const std::string text = "\xC4\x91\xE1\xBA\xA1o";
    context.expect(play::clip_utf8(text, 100) == text, "đủ chỗ thì giữ nguyên");
    context.expect(play::clip_utf8(text, 1).empty(), "một byte không đủ chứa 'đ'");
    context.expect(play::clip_utf8(text, 2) == "\xC4\x91", "cắt đúng sau 'đ'");
    context.expect(play::clip_utf8(text, 4) == "\xC4\x91", "bốn byte chẻ giữa 'ạ': lùi về sau 'đ'");
    context.expect(play::clip_utf8(text, 0).empty(), "trần 0 cho rỗng");
}

#ifdef GAME_SERVER_TABLES

constexpr std::uint64_t kSession = 41;
constexpr std::uint32_t kNpcEntity = 0x10007;
constexpr std::int32_t kScene = 2;
constexpr std::uint32_t kScript = 2030;
// GUID của 赵天师 trong dev/server/scenes/dali/spawns.tsv: khoá của danh bạ nhiệm vụ theo NPC.
constexpr std::uint32_t kGuid = 4736980;

// Người chơi `session` vào cảnh với id thực thể suy từ phiên (đủ để test, không dùng chung với NPC).
play::Gameplay::Arrival arrive(std::uint64_t session) { return play::Gameplay::Arrival{.session = session, .entity = 0x30000U + static_cast<std::uint32_t>(session)}; }

// Cảnh giả: một NPC đứng cách người chơi `distance` mét.
class FakeAround final : public play::Surroundings {
public:
    float distance = 1.0F;

    [[nodiscard]] std::optional<Npc> npc(std::uint64_t, Target target) const override {
        if (target.entity != kNpcEntity) return std::nullopt;
        return Npc{.entity = target.entity, .scene = kScene, .guid = kGuid, .script = kScript, .name = "赵天师"};
    }
    [[nodiscard]] std::optional<Presence> presence(std::uint64_t, Spot npc) const override {
        if (npc.entity != kNpcEntity) return std::nullopt;
        return Presence{.hero_scene = kScene, .npc_scene = npc.scene, .distance_m = distance};
    }

    // Cảnh nhỏ cho chiến đấu: thực thể theo id, và những gì gameplay nhờ cảnh làm.
    struct Raised {
        std::uint32_t entity = 0;
        std::int32_t x_cm = 0;
        std::int32_t z_cm = 0;
        std::uint8_t percent = 0;
    };
    std::map<std::uint32_t, Unit> units;
    std::vector<std::vector<std::byte>> told;
    std::vector<std::uint32_t> felled;
    std::vector<Raised> raised;
    std::vector<std::pair<std::uint32_t, std::uint16_t>> promoted;
    std::uint32_t next_drop = 0x50000;

    [[nodiscard]] std::optional<Unit> unit(Place place) const override {
        const auto found = units.find(place.entity);
        if (found == units.end()) return std::nullopt;
        return found->second;
    }
    void units_near(Place, std::vector<Unit>& out) const override {
        for (const auto& [id, one] : units) out.push_back(one);
    }
    void tell(Place, std::span<const std::byte> frame, bool) override { told.emplace_back(frame.begin(), frame.end()); }
    void hurt(Place place, std::uint8_t percent) override {
        if (const auto found = units.find(place.entity); found != units.end()) found->second.hp_percent = percent;
    }
    void fell(Place place) override {
        felled.push_back(place.entity);
        if (const auto found = units.find(place.entity); found != units.end()) {
            found->second.dead = true;
            found->second.hp_percent = 0;
        }
    }
    void raise(Place place, std::int32_t x_cm, std::int32_t z_cm, std::uint8_t percent) override {
        raised.push_back(Raised{.entity = place.entity, .x_cm = x_cm, .z_cm = z_cm, .percent = percent});
        if (const auto found = units.find(place.entity); found != units.end()) {
            found->second.dead = false;
            found->second.hp_percent = percent;
            found->second.x_cm = x_cm;
            found->second.z_cm = z_cm;
        }
    }
    void promote(Place place, std::uint16_t level) override { promoted.emplace_back(place.entity, level); }
    [[nodiscard]] std::optional<std::uint32_t> drop(std::uint16_t, const DropSpot& spot) override {
        const std::uint32_t id = next_drop++;
        units[id] = Unit{.entity = id, .kind = protocol::EntityKind::kDrop, .template_id = spot.item_template, .level = 1,
            .x_cm = spot.x_cm, .z_cm = spot.z_cm, .hp_percent = 100, .dead = false, .name = {}};
        return id;
    }
    void sweep(Place place) override { units.erase(place.entity); }
};

// Mọi tin đã gửi, giải mã lại.
std::vector<protocol::GameServerMessage> decoded(const play::Output& out) {
    std::vector<protocol::GameServerMessage> all;
    for (const play::Output::Frame& frame : out.frames) {
        const protocol::FrameResult head = protocol::peek_frame(frame.bytes, protocol::kClientBodyBytes);
        if (!head || !head->has_value()) continue;
        auto message =
            protocol::decode_game_server(**head, protocol::ByteView{frame.bytes}.subspan(protocol::kHeaderBytes));
        if (message) all.push_back(std::move(*message));
    }
    return all;
}

template <typename Message>
const Message* first_of(const std::vector<protocol::GameServerMessage>& all) {
    for (const protocol::GameServerMessage& one : all) {
        if (const auto* hit = std::get_if<Message>(&one)) return hit;
    }
    return nullptr;
}

template <typename Message>
std::vector<std::byte> frame_of(const Message& message) {
    std::vector<std::byte> bytes;
    const bool ok = static_cast<bool>(protocol::encode(bytes, message));
    return ok ? bytes : std::vector<std::byte>{};
}

// Cấp 30: các nhiệm vụ của 赵天师 trong danh bạ client 2026 đòi cấp 20 và 30 (nhóm 440.. của bản cũ không có trong danh bạ).
ipc::Attach newcomer(std::uint16_t level = 30) {
    ipc::Attach arrival;
    arrival.character = 9001;
    arrival.account = 7;
    arrival.scene = kScene;
    arrival.name = "Tân Thủ";
    arrival.level = level;
    arrival.gender = 2;
    return arrival;
}

struct Fixture {
    std::unique_ptr<play::World> world;
    std::unique_ptr<play::Gameplay> gameplay;
    FakeAround around;
};

std::unique_ptr<Fixture> open_fixture(Context& context) {
    std::expected<play::World, std::string> loaded =
        play::World::load(play::Paths{.tables = GAME_SERVER_TABLES, .text_override = {}, .language = "zh"});
    if (!loaded) {
        context.expect(false, loaded.error());
        return nullptr;
    }
    auto fixture = std::make_unique<Fixture>();
    fixture->world = std::make_unique<play::World>(std::move(*loaded));
    fixture->gameplay = std::make_unique<play::Gameplay>(*fixture->world, play::Gameplay::Settings{});
    fixture->gameplay->set_time(play::Gameplay::Clock{.unix_seconds = 1'700'000'000, .tick = 100});
    return fixture;
}

void attach_sends_book_and_stats(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output out;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(1), fixture->around, out), "attach nhận nhân vật mới");
    const auto all = decoded(out);
    const auto* book = first_of<protocol::QuestBook>(all);
    const auto* stats = first_of<protocol::SelfStats>(all);
    context.expect(book != nullptr && book->slots.empty(), "sổ nhiệm vụ rỗng");
    context.expect(stats != nullptr && stats->level == 1, "SelfStats cấp 1");
    context.expect(fixture->gameplay->player_count() == 1, "đang giữ một người chơi");
    context.expect(out.encode_failures == 0, "không tin nào mã hoá hỏng");

    // Khối hỏng: không dựng nhân vật nửa vời.
    ipc::Attach broken = newcomer();
    broken.play = {std::byte{0xFF}, std::byte{0x00}, std::byte{0x13}};
    play::Output refused;
    context.expect(!fixture->gameplay->attach(arrive(kSession + 1), broken, fixture->around, refused), "khối chơi hỏng bị từ chối");
    context.expect(fixture->gameplay->find(kSession + 1) == nullptr, "không giữ người chơi hỏng");
}

// Duyệt từng lựa chọn của hộp thoại gốc (chọn, rồi nói lại với NPC để về gốc) tới khi gặp bảng nhận nhiệm vụ.
// Trả (nhiệm vụ được mời, mã phiên của bảng) hoặc nullopt.
std::optional<std::pair<std::int32_t, std::uint64_t>> find_offer(Fixture& fixture, const protocol::DialogOpen& root) {
    std::uint64_t session = root.session;
    std::vector<std::uint16_t> indexes;
    for (const protocol::DialogChoice& choice : root.choices) indexes.push_back(choice.index);
    std::uint64_t tick = 100;
    for (const std::uint16_t index : indexes) {
        play::Output picked;
        fixture.gameplay->intent(
            kSession, frame_of(protocol::DialogChoose{.session = session, .index = index}), fixture.around, picked);
        const auto after = decoded(picked);
        if (const auto* panel = first_of<protocol::DialogOpen>(after);
            panel != nullptr && panel->mode == protocol::DialogMode::kMissionInfo && panel->panel_quest >= 0) {
            return std::pair{panel->panel_quest, panel->session};
        }
        tick += 40;
        fixture.gameplay->set_time(play::Gameplay::Clock{.unix_seconds = 1'700'000'000, .tick = tick});
        play::Output again;
        fixture.gameplay->intent(kSession, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture.around, again);
        const auto reopened_all = decoded(again);
        const auto* reopened = first_of<protocol::DialogOpen>(reopened_all);
        if (reopened == nullptr) return std::nullopt;
        session = reopened->session;
    }
    return std::nullopt;
}

bool text_has(const protocol::DialogOpen& open, std::string_view needle) {
    for (const protocol::DialogLine& line : open.lines) {
        if (line.text.find(needle) != std::string::npos) return true;
    }
    return false;
}

const protocol::DialogLine* mark_for(const protocol::DialogOpen& open, std::string_view quest) {
    const std::string token = std::string("\x1f") + std::string(quest) + "\x1f";
    for (const protocol::DialogLine& line : open.lines) {
        if (!line.text.starts_with("TLQ")) continue;
        if (line.text.find(token) == std::string::npos) continue;
        return &line;
    }
    return nullptr;
}

int sep_count(std::string_view text) {
    int count = 0;
    for (const char one : text) {
        if (one == '\x1f') ++count;
    }
    return count;
}

// Vào lại từ bản ghi: sổ còn nguyên.
void expect_survives_rejoin(Context& context, Fixture& fixture, const account::PlayRecord& kept) {
    const std::expected<std::vector<std::byte>, account::PlayError> packed = account::pack(kept);
    context.expect(packed.has_value(), "bản ghi đóng gói được");
    if (!packed) return;
    play::Output second;
    ipc::Attach back = newcomer();
    back.play = *packed;
    context.expect(fixture.gameplay->attach(arrive(kSession + 2), back, fixture.around, second), "vào lại từ bản ghi");
    const auto restored = decoded(second);
    const auto* book = first_of<protocol::QuestBook>(restored);
    context.expect(book != nullptr && book->slots.size() == 1, "sổ nhiệm vụ còn sau khi vào lại");
}

void talk_accept_and_keep(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");

    play::Output talked;
    fixture->gameplay->intent(kSession, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture->around, talked);
    const auto opened = decoded(talked);
    const auto* dialog = first_of<protocol::DialogOpen>(opened);
    context.expect(dialog != nullptr, "Talk mở hộp thoại");
    if (dialog == nullptr) return;
    context.expect(dialog->npc == kNpcEntity, "hộp thoại gắn đúng NPC");
    context.expect(!dialog->lines.empty() && !dialog->lines.front().text.empty(), "lời NPC có chữ");
    context.expect(text_has(*dialog, "初涉江湖"), "lời hội thoại có tên 初涉江湖");
    const protocol::DialogLine* newbie = mark_for(*dialog, "1400");
    const bool newbie_ok = newbie != nullptr && newbie->text.ends_with("\x1f赵天师");
    context.expect(newbie_ok && sep_count(newbie->text) == 4, "dấu 1400 nêu 赵天师");
    const protocol::DialogLine* decade = mark_for(*dialog, "1424");
    const bool decade_ok = decade != nullptr && sep_count(decade->text) == 3;
    context.expect(decade_ok, "1424 không bịa mục tiêu");
    context.expect(!dialog->choices.empty(), "có lựa chọn");

    const auto offer = find_offer(*fixture, *dialog);
    context.expect(offer.has_value(), "một lựa chọn của 赵天师 dẫn tới bảng nhận nhiệm vụ");
    if (!offer) return;

    play::Output accepted;
    fixture->gameplay->intent(kSession,
        frame_of(protocol::QuestAccept{.session = offer->second, .quest = static_cast<std::uint16_t>(offer->first)}),
        fixture->around, accepted);
    const auto result = decoded(accepted);
    const auto* book = first_of<protocol::QuestBook>(result);
    context.expect(book != nullptr && book->slots.size() == 1, "sổ có đúng một nhiệm vụ sau khi nhận");
    context.expect(book != nullptr && !book->slots.empty() && std::cmp_equal(book->slots.front().quest, offer->first),
        "đúng nhiệm vụ được mời");
    context.expect(first_of<protocol::QuestNotice>(result) != nullptr, "có thông báo nhận nhiệm vụ");
    context.expect(accepted.keeps.size() == 1 && accepted.keeps.front().character == 9001,
        "trạng thái đổi thì có lần ghi");
    if (!accepted.keeps.empty()) {
        const account::PlayRecord& kept = accepted.keeps.front().record;
        context.expect(!kept.mission.empty() && !kept.body.empty() && !kept.bag.empty(), "bản ghi đủ ba khối");
        expect_survives_rejoin(context, *fixture, kept);
    }

    // Không đổi gì thì không ghi lại.
    play::Output idle;
    fixture->gameplay->autosave(idle);
    context.expect(idle.keeps.empty(), "không đổi gì thì không có lần ghi");
}

// Gửi một khung ở một giây riêng (các ca này kiểm từ chối theo nội dung, không theo tốc độ), trả mã Reject nếu có.
class Prober {
public:
    explicit Prober(Fixture& fixture) noexcept : fixture_(&fixture) {}

    std::optional<protocol::ErrorCode> code_of(const std::vector<std::byte>& frame) {
        advance();
        play::Output out;
        fixture_->gameplay->intent(kSession, frame, fixture_->around, out);
        const auto all = decoded(out);
        const auto* reject = first_of<protocol::Reject>(all);
        return reject != nullptr ? std::optional<protocol::ErrorCode>{reject->code} : std::nullopt;
    }
    void advance() {
        tick_ += 40;
        fixture_->gameplay->set_time(play::Gameplay::Clock{.unix_seconds = 1'700'000'000, .tick = tick_});
    }

private:
    Fixture* fixture_;
    std::uint64_t tick_ = 100;
};

void unknown_ids_are_rejected(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    Prober probe{*fixture};
    context.expect(probe.code_of(frame_of(protocol::Talk{.npc = 0xDEAD})) == protocol::ErrorCode::kNoSuchEntity, "NPC lạ");
    context.expect(probe.code_of(frame_of(protocol::DialogChoose{.session = 99, .index = 0})) == protocol::ErrorCode::kNoSession,
        "chọn khi chưa có phiên");
    context.expect(probe.code_of(frame_of(protocol::QuestAccept{.session = 99, .quest = 440})) == protocol::ErrorCode::kNoSession,
        "nhận khi chưa có phiên");
    context.expect(probe.code_of(frame_of(protocol::QuestTurnIn{.session = 99, .quest = 440, .reward = 0})) ==
            protocol::ErrorCode::kNoSession,
        "nộp khi chưa có phiên");
    context.expect(probe.code_of(frame_of(protocol::QuestAbandon{.quest = 4000})).has_value(), "bỏ nhiệm vụ không có trong sổ");
}

void far_and_stale_sessions_are_rejected(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    Prober probe{*fixture};
    fixture->around.distance = 50.0F;
    context.expect(probe.code_of(frame_of(protocol::Talk{.npc = kNpcEntity})) == protocol::ErrorCode::kTooFar, "quá xa 50 m");
    fixture->around.distance = 1.0F;

    // Mở phiên mới thì phiên trước hết hiệu lực.
    probe.advance();
    play::Output first;
    fixture->gameplay->intent(kSession, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture->around, first);
    const auto firsts = decoded(first);
    const auto* older = first_of<protocol::DialogOpen>(firsts);
    probe.advance();
    play::Output second;
    fixture->gameplay->intent(kSession, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture->around, second);
    context.expect(older != nullptr, "mở được phiên");
    if (older == nullptr) return;
    context.expect(probe.code_of(frame_of(protocol::DialogChoose{.session = older->session, .index = 0})) ==
            protocol::ErrorCode::kStaleSession,
        "phiên cũ bị từ chối");
}

void junk_is_ignored(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    Prober probe{*fixture};
    probe.advance();
    const std::size_t before = fixture->gameplay->ignored();
    play::Output junk;
    fixture->gameplay->intent(kSession, std::vector<std::byte>{std::byte{1}, std::byte{2}, std::byte{3}}, fixture->around, junk);
    fixture->gameplay->intent(kSession, frame_of(protocol::Ping{}), fixture->around, junk);
    context.expect(fixture->gameplay->ignored() >= before + 2, "khung rác và Ping bị đếm là bỏ");
    context.expect(junk.frames.empty() && junk.keeps.empty(), "đầu vào rác không sinh tin nào");

    // Người chơi chưa attach.
    play::Output stranger;
    fixture->gameplay->intent(777, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture->around, stranger);
    context.expect(stranger.frames.empty(), "người chơi chưa attach thì bị bỏ");
}

void flood_is_rate_limited(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    std::size_t limited = 0;
    for (int at = 0; at < 40; ++at) {
        play::Output out;
        fixture->gameplay->intent(kSession, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture->around, out);
        const auto* reject = first_of<protocol::Reject>(decoded(out));
        if (reject != nullptr && reject->code == protocol::ErrorCode::kRateLimited) ++limited;
    }
    context.expect(limited >= 20, "gửi dồn trong một tick bị chặn quá trần mỗi giây");
    // Sang giây sau thì nói chuyện lại được.
    fixture->gameplay->set_time(play::Gameplay::Clock{.unix_seconds = 1'700'000'001, .tick = 130});
    play::Output later;
    fixture->gameplay->intent(kSession, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture->around, later);
    context.expect(first_of<protocol::DialogOpen>(decoded(later)) != nullptr, "hết cửa sổ thì lại được");
}

void detach_hands_back_state(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    play::Output left;
    fixture->gameplay->detach(kSession, left);
    context.expect(fixture->gameplay->player_count() == 0, "không còn giữ người chơi");
    context.expect(left.keeps.empty() || left.keeps.front().character == 9001, "nếu có lần ghi thì đúng nhân vật");
    play::Output twice;
    fixture->gameplay->detach(kSession, twice);
    context.expect(twice.keeps.empty() && twice.frames.empty(), "rời lần hai không làm gì");
}

// Quái thật dễ đánh nhất trong bảng và có bảng rơi đồ: có kinh nghiệm, ít máu, cấp thấp, không phải thủ lĩnh.
const actor::MonsterRow* weakest_monster(const play::World& world) {
    const actor::MonsterRow* best = nullptr;
    for (const actor::MonsterRow& row : world.rules().data().monsters) {
        if (row.base_exp <= 0 || row.boss || row.can_interact != 0 || row.max_hp < 5 || row.level > 5) continue;
        if (world.loot().monster(ids::MonsterTemplateId{row.id}) == nullptr) continue;
        if (best == nullptr || row.max_hp < best->max_hp) best = &row;
    }
    return best;
}

constexpr std::uint32_t kMonsterEntity = 0x40001;

// Đặt người chơi và một con quái cách nhau 1 m trong cảnh giả.
void place_duel(Fixture& fixture, std::uint64_t session, const actor::MonsterRow& monster, std::uint32_t entity) {
    const std::uint32_t self = arrive(session).entity;
    fixture.around.units[self] = play::Surroundings::Unit{.entity = self, .kind = protocol::EntityKind::kPlayer, .template_id = 0,
        .level = 30, .x_cm = 0, .z_cm = 0, .hp_percent = 100, .dead = false, .name = "Tân Thủ"};
    fixture.around.units[entity] = play::Surroundings::Unit{.entity = entity, .kind = protocol::EntityKind::kMonster,
        .template_id = monster.id, .level = static_cast<std::uint16_t>(monster.level), .x_cm = 100, .z_cm = 0, .hp_percent = 100,
        .dead = false, .name = "quái"};
}

// Mọi tin đã phát quanh (tell) trong lượt vừa rồi, giải mã; xoá hàng đợi.
std::vector<protocol::GameServerMessage> told_messages(Fixture& fixture) {
    std::vector<protocol::GameServerMessage> all;
    for (const std::vector<std::byte>& frame : fixture.around.told) {
        const protocol::FrameResult head = protocol::peek_frame(frame, protocol::kClientBodyBytes);
        if (!head || !head->has_value()) continue;
        auto message = protocol::decode_game_server(**head, protocol::ByteView{frame}.subspan(protocol::kHeaderBytes));
        if (message) all.push_back(std::move(*message));
    }
    fixture.around.told.clear();
    return all;
}

// Chạy `count` bước 20 Hz của gameplay; trả mọi tin riêng nhận được.
std::vector<protocol::GameServerMessage> run_steps(Fixture& fixture, std::uint64_t& tick, int count) {
    std::vector<protocol::GameServerMessage> all;
    for (int step = 0; step < count; ++step) {
        play::Output idle;
        fixture.gameplay->set_time(play::Gameplay::Clock{.unix_seconds = 1'700'000'000, .tick = ++tick});
        fixture.gameplay->step(fixture.around, idle);
        for (auto& one : decoded(idle)) all.push_back(std::move(one));
    }
    return all;
}

struct Fight {
    bool saw_cast = false;
    bool saw_damage = false;
    bool died = false;
    int rejects = 0;
};

// Đánh con quái `entity` bằng Phục Hổ Quyền (kỹ năng 281 của Thiếu Lâm) cho tới khi nó chết hoặc hết 50 lượt.
Fight fight_until_dead(Fixture& fixture, std::uint64_t& tick, std::uint32_t entity, std::uint16_t skill = 281) {
    Fight fight;
    for (int round = 0; round < 50 && !fight.died; ++round) {
        play::Output cast;
        fixture.gameplay->intent(kSession,
            frame_of(protocol::CastSkill{.seq = static_cast<std::uint16_t>(round + 1), .skill = skill, .target = entity, .x_cm = 0.0F, .z_cm = 0.0F}),
            fixture.around, cast);
        const auto replies = decoded(cast);
        if (first_of<protocol::Reject>(replies) != nullptr) ++fight.rejects;
        if (const auto* shown = first_of<protocol::SkillCast>(replies)) fight.saw_cast = fight.saw_cast || shown->seq == round + 1;
        // 25 tick (1,25 giây) giữa hai lần ra chiêu: đủ hồi chiêu và đủ cho đòn tới đích.
        run_steps(fixture, tick, 25);
        for (const protocol::GameServerMessage& one : told_messages(fixture)) {
            if (const auto* event = std::get_if<protocol::CombatEvent>(&one)) {
                fight.saw_damage = fight.saw_damage || (event->kind == protocol::CombatKind::kDamage && event->value > 0);
            }
            if (std::holds_alternative<protocol::EntityDied>(one)) fight.died = true;
        }
    }
    return fight;
}

void kill_a_monster_end_to_end(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    const actor::MonsterRow* monster = weakest_monster(*fixture->world);
    context.expect(monster != nullptr, "bảng quái có một con dễ đánh và có bảng rơi đồ");
    if (monster == nullptr) return;
    place_duel(*fixture, kSession, *monster, kMonsterEntity);
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    const auto start = decoded(joined);
    const auto* vitals = first_of<protocol::SelfVitals>(start);
    context.expect(vitals != nullptr && vitals->hp > 0 && vitals->hp == vitals->hp_max, "vào cảnh nhận SelfVitals đầy máu");
    const auto* skills = first_of<protocol::SelfSkills>(start);
    context.expect(skills != nullptr && !skills->skills.empty(), "vào cảnh nhận SelfSkills có kỹ năng của phái");

    std::uint64_t tick = 100;
    const std::uint64_t exp_before = fixture->gameplay->find(kSession)->exp();
    const Fight first = fight_until_dead(*fixture, tick, kMonsterEntity);
    context.expect(first.saw_cast, "người ra chiêu nhận SkillCast mang seq của mình");
    context.expect(first.saw_damage, "có CombatEvent sát thương");
    context.expect(first.died, "quái chết (EntityDied được phát)");
    context.expect(!fixture->around.felled.empty() && fixture->around.felled.front() == kMonsterEntity, "cảnh được báo quái chết");
    const play::Player* hero = fixture->gameplay->find(kSession);
    context.expect(hero != nullptr && hero->exp() > exp_before, "người đánh nhận kinh nghiệm");
    // Sau khi chết, đánh tiếp vào xác bị từ chối (mục tiêu đã chết), không đổi gì.
    play::Output again;
    fixture->gameplay->intent(kSession, frame_of(protocol::CastSkill{.seq = 99, .skill = 281, .target = kMonsterEntity, .x_cm = 0.0F, .z_cm = 0.0F}),
        fixture->around, again);
    const auto replies = decoded(again);
    const auto* refused = first_of<protocol::Reject>(replies);
    context.expect(replies.size() == 1 && refused != nullptr && refused->code == protocol::ErrorCode::kBadTarget, "đánh vào xác bị từ chối");
}

// Đòn thường (id 0) ai cũng có, kể cả nhân vật chưa vào môn phái, và phải gây sát thương thật.
void plain_attack_kills(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    const actor::MonsterRow* monster = weakest_monster(*fixture->world);
    if (monster == nullptr) {
        context.expect(false, "bảng quái có một con dễ đánh");
        return;
    }
    place_duel(*fixture, kSession, *monster, kMonsterEntity);
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    const auto start = decoded(joined);
    const auto* skills = first_of<protocol::SelfSkills>(start);
    context.expect(skills != nullptr && !skills->skills.empty() && skills->skills.front().skill == 0, "đòn thường đứng đầu SelfSkills");
    std::uint64_t tick = 100;
    const Fight fight = fight_until_dead(*fixture, tick, kMonsterEntity, 0);
    context.expect(fight.saw_cast, "đòn thường được SkillCast xác nhận");
    context.expect(fight.rejects == 0, "đòn thường không bị từ chối");
    context.expect(fight.saw_damage, "đòn thường gây sát thương");
    context.expect(fight.died, "đòn thường hạ được quái");
}

// Giết liên tiếp tới khi có vật rơi (đồ rơi theo xác suất), nhặt nó: túi nhận món đó.
void loot_drops_and_pick_up(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    const actor::MonsterRow* monster = weakest_monster(*fixture->world);
    if (monster == nullptr) {
        context.expect(false, "bảng quái có một con dễ đánh và có bảng rơi đồ");
        return;
    }
    play::Output joined;
    place_duel(*fixture, kSession, *monster, kMonsterEntity);
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");
    std::uint64_t tick = 100;
    std::uint32_t drop = 0;
    for (std::uint32_t entity = kMonsterEntity; entity < kMonsterEntity + 40 && drop == 0; ++entity) {
        place_duel(*fixture, kSession, *monster, entity);
        const Fight fight = fight_until_dead(*fixture, tick, entity);
        context.expect(fight.died, "mỗi con quái đều chết");
        if (!fight.died) return;
        for (const auto& [id, one] : fixture->around.units) {
            if (one.kind == protocol::EntityKind::kDrop) drop = id;
        }
    }
    context.expect(drop != 0, "giết 40 con quái thì ít nhất một con rơi đồ");
    if (drop == 0) return;
    const std::uint32_t item = fixture->around.units[drop].template_id;
    // Đứng xa hơn tầm nhặt (3 m) thì bị từ chối và vật vẫn nằm đó.
    const std::uint32_t self_entity = arrive(kSession).entity;
    fixture->around.units[self_entity].x_cm = 5000;
    play::Output far;
    fixture->gameplay->intent(kSession, frame_of(protocol::PickUp{.drop = drop}), fixture->around, far);
    const auto too_far = decoded(far);
    const auto* far_reject = first_of<protocol::Reject>(too_far);
    context.expect(far_reject != nullptr && far_reject->code == protocol::ErrorCode::kTooFar, "nhặt từ xa: TooFar");
    context.expect(fixture->around.units.contains(drop), "bị từ chối thì vật rơi còn nguyên");
    fixture->around.units[self_entity].x_cm = fixture->around.units[drop].x_cm;
    play::Output picked;
    fixture->gameplay->intent(kSession, frame_of(protocol::PickUp{.drop = drop}), fixture->around, picked);
    const auto after = decoded(picked);
    const auto* bag = first_of<protocol::SelfBag>(after);
    context.expect(first_of<protocol::Reject>(after) == nullptr, "nhặt được vật rơi của mình");
    context.expect(bag != nullptr && !bag->slots.empty() && bag->slots.front().item == item, "túi nhận đúng món vừa nhặt");
    context.expect(!fixture->around.units.contains(drop), "vật rơi được gỡ khỏi cảnh");
    play::Output twice;
    fixture->gameplay->intent(kSession, frame_of(protocol::PickUp{.drop = drop}), fixture->around, twice);
    const auto again = decoded(twice);
    const auto* gone = first_of<protocol::Reject>(again);
    context.expect(gone != nullptr && gone->code == protocol::ErrorCode::kNoSuchEntity, "nhặt lần hai: vật rơi không còn");
}

// Đầu vào thù địch của ba tin chiến đấu: mỗi ca phải ra đúng một Reject, không đổi gì trong cảnh.
void combat_refuses_hostile_input(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    const actor::MonsterRow* monster = weakest_monster(*fixture->world);
    if (monster == nullptr) {
        context.expect(false, "bảng quái có một con dễ đánh");
        return;
    }
    place_duel(*fixture, kSession, *monster, kMonsterEntity);
    constexpr std::uint32_t kPasserby = 0x50001;
    fixture->around.units[kPasserby] = play::Surroundings::Unit{.entity = kPasserby, .kind = protocol::EntityKind::kNpc, .template_id = 1,
        .level = 1, .x_cm = 50, .z_cm = 0, .hp_percent = 100, .dead = false, .name = "npc"};
    play::Output joined;
    context.expect(fixture->gameplay->attach(arrive(kSession), newcomer(), fixture->around, joined), "attach");

    const auto refusal = [&](const protocol::CastSkill& cast) {
        play::Output out;
        fixture->gameplay->intent(kSession, frame_of(cast), fixture->around, out);
        const auto replies = decoded(out);
        const auto* refused = first_of<protocol::Reject>(replies);
        return replies.size() == 1 && refused != nullptr ? std::optional{refused->code} : std::nullopt;
    };
    constexpr float kNan = std::numeric_limits<float>::quiet_NaN();
    constexpr float kInf = std::numeric_limits<float>::infinity();
    using Code = protocol::ErrorCode;
    context.expect(refusal({.seq = 1, .skill = 60000, .target = kMonsterEntity, .x_cm = 0.0F, .z_cm = 0.0F}) == Code::kBadOption, "kỹ năng không có trong bảng: BadOption");
    // NaN và vô cực: tầng protocol đã không giải mã được khung; dù thế nào cũng không có SkillCast.
    for (const protocol::CastSkill& bad : {protocol::CastSkill{.seq = 2, .skill = 281, .target = 0, .x_cm = kNan, .z_cm = 0.0F},
             protocol::CastSkill{.seq = 3, .skill = 281, .target = 0, .x_cm = 0.0F, .z_cm = kInf}}) {
        play::Output out;
        fixture->gameplay->intent(kSession, frame_of(bad), fixture->around, out);
        context.expect(first_of<protocol::SkillCast>(decoded(out)) == nullptr, "toạ độ đất không hữu hạn không ra chiêu");
    }
    context.expect(refusal({.seq = 4, .skill = 281, .target = 0, .x_cm = 3.0e9F, .z_cm = 0.0F}) == Code::kBadOption, "toạ độ đất quá trần: BadOption");
    context.expect(refusal({.seq = 5, .skill = 281, .target = kPasserby, .x_cm = 0.0F, .z_cm = 0.0F}) == Code::kBadTarget, "đánh NPC: BadTarget");
    context.expect(refusal({.seq = 6, .skill = 281, .target = 0xDEADBEEFU, .x_cm = 0.0F, .z_cm = 0.0F}) == Code::kNoSuchEntity, "mục tiêu không có trong cảnh: NoSuchEntity");

    play::Output alive;
    fixture->gameplay->intent(kSession, frame_of(protocol::Respawn{.place = protocol::RespawnPlace::kTown}), fixture->around, alive);
    const auto revive = decoded(alive);
    const auto* not_dead = first_of<protocol::Reject>(revive);
    context.expect(revive.size() == 1 && not_dead != nullptr && not_dead->code == Code::kNotDead, "hồi sinh khi còn sống: NotDead");

    play::Output grab;
    fixture->gameplay->intent(kSession, frame_of(protocol::PickUp{.drop = 0xDEADBEEFU}), fixture->around, grab);
    const auto grabbed = decoded(grab);
    const auto* none = first_of<protocol::Reject>(grabbed);
    context.expect(grabbed.size() == 1 && none != nullptr && none->code == Code::kNoSuchEntity, "nhặt id lạ: NoSuchEntity");
    // Tin của phiên chưa vào cảnh không đụng được gì.
    play::Output stranger;
    fixture->gameplay->intent(kSession + 1, frame_of(protocol::PickUp{.drop = 1}), fixture->around, stranger);
    context.expect(first_of<protocol::SelfBag>(decoded(stranger)) == nullptr, "phiên lạ không nhận túi");
}

#endif

constexpr std::array kCases{
    Case{.name = "clip_never_splits_a_character", .body = &clip_never_splits_a_character},
#ifdef GAME_SERVER_TABLES
    Case{.name = "attach_sends_book_and_stats", .body = &attach_sends_book_and_stats},
    Case{.name = "talk_accept_and_keep", .body = &talk_accept_and_keep},
    Case{.name = "unknown_ids_are_rejected", .body = &unknown_ids_are_rejected},
    Case{.name = "far_and_stale_sessions_are_rejected", .body = &far_and_stale_sessions_are_rejected},
    Case{.name = "junk_is_ignored", .body = &junk_is_ignored},
    Case{.name = "flood_is_rate_limited", .body = &flood_is_rate_limited},
    Case{.name = "detach_hands_back_state", .body = &detach_hands_back_state},
    Case{.name = "kill_a_monster_end_to_end", .body = &kill_a_monster_end_to_end},
    Case{.name = "plain_attack_kills", .body = &plain_attack_kills},
    Case{.name = "loot_drops_and_pick_up", .body = &loot_drops_and_pick_up},
    Case{.name = "combat_refuses_hostile_input", .body = &combat_refuses_hostile_input},
#endif
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
