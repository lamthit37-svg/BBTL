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
#include <memory>
#include <optional>
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
    context.expect(fixture->gameplay->attach(kSession, newcomer(1), out), "attach nhận nhân vật mới");
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
    context.expect(!fixture->gameplay->attach(kSession + 1, broken, refused), "khối chơi hỏng bị từ chối");
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

// Vào lại từ bản ghi: sổ còn nguyên.
void expect_survives_rejoin(Context& context, Fixture& fixture, const account::PlayRecord& kept) {
    const std::expected<std::vector<std::byte>, account::PlayError> packed = account::pack(kept);
    context.expect(packed.has_value(), "bản ghi đóng gói được");
    if (!packed) return;
    play::Output second;
    ipc::Attach back = newcomer();
    back.play = *packed;
    context.expect(fixture.gameplay->attach(kSession + 2, back, second), "vào lại từ bản ghi");
    const auto restored = decoded(second);
    const auto* book = first_of<protocol::QuestBook>(restored);
    context.expect(book != nullptr && book->slots.size() == 1, "sổ nhiệm vụ còn sau khi vào lại");
}

void talk_accept_and_keep(Context& context) {
    const std::unique_ptr<Fixture> fixture = open_fixture(context);
    if (fixture == nullptr) return;
    play::Output joined;
    context.expect(fixture->gameplay->attach(kSession, newcomer(), joined), "attach");

    play::Output talked;
    fixture->gameplay->intent(kSession, frame_of(protocol::Talk{.npc = kNpcEntity}), fixture->around, talked);
    const auto opened = decoded(talked);
    const auto* dialog = first_of<protocol::DialogOpen>(opened);
    context.expect(dialog != nullptr, "Talk mở hộp thoại");
    if (dialog == nullptr) return;
    context.expect(dialog->npc == kNpcEntity, "hộp thoại gắn đúng NPC");
    context.expect(!dialog->lines.empty() && !dialog->lines.front().text.empty(), "lời NPC có chữ");
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
    context.expect(fixture->gameplay->attach(kSession, newcomer(), joined), "attach");
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
    context.expect(fixture->gameplay->attach(kSession, newcomer(), joined), "attach");
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
    context.expect(fixture->gameplay->attach(kSession, newcomer(), joined), "attach");
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
    context.expect(fixture->gameplay->attach(kSession, newcomer(), joined), "attach");
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
    context.expect(fixture->gameplay->attach(kSession, newcomer(), joined), "attach");
    play::Output left;
    fixture->gameplay->detach(kSession, left);
    context.expect(fixture->gameplay->player_count() == 0, "không còn giữ người chơi");
    context.expect(left.keeps.empty() || left.keeps.front().character == 9001, "nếu có lần ghi thì đúng nhân vật");
    play::Output twice;
    fixture->gameplay->detach(kSession, twice);
    context.expect(twice.keeps.empty() && twice.frames.empty(), "rời lần hai không làm gì");
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
#endif
};

} // namespace
} // namespace game::test

int main() {
    return game::test::run_all(game::test::kCases) == 0 ? 0 : 1;
}
