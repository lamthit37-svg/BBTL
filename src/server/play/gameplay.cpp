/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/gameplay.cpp
 *  PHÂN HỆ   : Server / Play / Gameplay
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt cửa vào gameplay của zone: nhận ý định hội thoại và nhiệm vụ, kiểm
 *    tốc độ, gọi talk::Service và dựng tin trả cho client.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "play/gameplay.hpp"

#include "account/play.hpp"
#include "bus/bus.hpp"
#include "ids/ids.hpp"
#include "ipc/relay.hpp"
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/engine.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"
#include "play/bag.hpp"
#include "play/battle.hpp"
#include "play/player.hpp"
#include "play/stage.hpp"
#include "play/text.hpp"
#include "play/world.hpp"
#include "protocol/messages.hpp"
#include "protocol/wire.hpp"
#include "talk/handler.hpp"
#include "talk/service.hpp"
#include "talk/view.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <variant>
#include <vector>

namespace game::play {

namespace {

constexpr std::size_t kLineBytes = 1024;
constexpr std::size_t kChoiceBytes = 256;
constexpr std::size_t kNoticeBytes = 512;
constexpr std::int64_t kSecondsPerDay = 86'400;
// 1970-01-01 là thứ năm; thứ trong tuần của Lua gốc tính chủ nhật = 0.
constexpr std::int64_t kEpochWeekday = 4;
// Tuần của lịch nhiệm vụ bắt đầu từ thứ hai: 1970-01-05 là thứ hai đầu tiên.
constexpr std::int64_t kFirstMondayOffset = 3;

[[nodiscard]] std::int64_t floor_div(std::int64_t value, std::int64_t unit) noexcept {
    const std::int64_t quotient = value / unit;
    return (value % unit != 0 && (value < 0) != (unit < 0)) ? quotient - 1 : quotient;
}

[[nodiscard]] protocol::DialogMode mode_of(talk::Mode mode) noexcept {
    switch (mode) {
    case talk::Mode::kList: return protocol::DialogMode::kList;
    case talk::Mode::kBox: return protocol::DialogMode::kBox;
    case talk::Mode::kMissionInfo: return protocol::DialogMode::kMissionInfo;
    case talk::Mode::kContinue: return protocol::DialogMode::kContinue;
    case talk::Mode::kDemand: return protocol::DialogMode::kDemand;
    case talk::Mode::kTips: return protocol::DialogMode::kTips;
    }
    return protocol::DialogMode::kList;
}

[[nodiscard]] protocol::BonusKind bonus_of(talk::BonusKind kind) noexcept {
    switch (kind) {
    case talk::BonusKind::kMoney: return protocol::BonusKind::kMoney;
    case talk::BonusKind::kItem: return protocol::BonusKind::kItem;
    case talk::BonusKind::kRadio: return protocol::BonusKind::kRadio;
    case talk::BonusKind::kRandom: return protocol::BonusKind::kRandom;
    case talk::BonusKind::kDemand: return protocol::BonusKind::kDemand;
    }
    return protocol::BonusKind::kMoney;
}

[[nodiscard]] protocol::MarkStage stage_of(talk::Stage stage) noexcept {
    switch (stage) {
    case talk::Stage::kAvailable: return protocol::MarkStage::kAvailable;
    case talk::Stage::kInProgress: return protocol::MarkStage::kInProgress;
    case talk::Stage::kReady: return protocol::MarkStage::kReady;
    }
    return protocol::MarkStage::kAvailable;
}

[[nodiscard]] protocol::QuestNoticeKind notice_of(mission::NoticeKind kind) noexcept {
    switch (kind) {
    case mission::NoticeKind::kAdded: return protocol::QuestNoticeKind::kAdded;
    case mission::NoticeKind::kUpdated: return protocol::QuestNoticeKind::kUpdated;
    case mission::NoticeKind::kReady: return protocol::QuestNoticeKind::kReady;
    case mission::NoticeKind::kRemoved: return protocol::QuestNoticeKind::kRemoved;
    case mission::NoticeKind::kDone: return protocol::QuestNoticeKind::kDone;
    case mission::NoticeKind::kFailed: return protocol::QuestNoticeKind::kFailed;
    case mission::NoticeKind::kText: return protocol::QuestNoticeKind::kText;
    case mission::NoticeKind::kAnnounce: return protocol::QuestNoticeKind::kAnnounce;
    case mission::NoticeKind::kRewardExp: return protocol::QuestNoticeKind::kRewardExp;
    case mission::NoticeKind::kRewardMoney: return protocol::QuestNoticeKind::kRewardMoney;
    case mission::NoticeKind::kRewardItem: return protocol::QuestNoticeKind::kRewardItem;
    case mission::NoticeKind::kRelation: return protocol::QuestNoticeKind::kRelation;
    }
    return protocol::QuestNoticeKind::kText;
}

[[nodiscard]] protocol::DialogCloseReason close_reason_of(talk::Error error) noexcept {
    switch (error) {
    case talk::Error::kFar: return protocol::DialogCloseReason::kFar;
    case talk::Error::kSceneChanged: return protocol::DialogCloseReason::kSceneChanged;
    case talk::Error::kNoNpc: return protocol::DialogCloseReason::kNpcGone;
    case talk::Error::kExpired: return protocol::DialogCloseReason::kExpired;
    default: return protocol::DialogCloseReason::kDone;
    }
}

[[nodiscard]] protocol::ErrorCode ledger_code(ledger::Reason reason) noexcept {
    switch (reason) {
    case ledger::Reason::kNoRoom: return protocol::ErrorCode::kBagFull;
    case ledger::Reason::kMissingMoney: return protocol::ErrorCode::kNotEnoughMoney;
    case ledger::Reason::kMissingItems: return protocol::ErrorCode::kNotEnoughItems;
    default: return protocol::ErrorCode::kQuestState;
    }
}

[[nodiscard]] protocol::ErrorCode mission_code(const mission::Failure& failure) noexcept {
    switch (failure.error) {
    case mission::Error::kUnknownQuest:
    case mission::Error::kNotRunnable:
    case mission::Error::kLevelTooLow:
    case mission::Error::kPrerequisite:
    case mission::Error::kCondition:
    case mission::Error::kBanned: return protocol::ErrorCode::kQuestUnavailable;
    case mission::Error::kAlreadyActive:
    case mission::Error::kAlreadyDone:
    case mission::Error::kNotActive:
    case mission::Error::kNotReady: return protocol::ErrorCode::kQuestState;
    case mission::Error::kBookFull:
    case mission::Error::kBookLimit: return protocol::ErrorCode::kQuestLogFull;
    case mission::Error::kNeedChoice:
    case mission::Error::kBadChoice: return protocol::ErrorCode::kBadChoice;
    case mission::Error::kLedger: return ledger_code(failure.ledger);
    }
    return protocol::ErrorCode::kQuestState;
}

[[nodiscard]] protocol::ErrorCode talk_code(const talk::Failure& failure) noexcept {
    switch (failure.error) {
    case talk::Error::kNoNpc:
    case talk::Error::kNoDialog: return protocol::ErrorCode::kNoSuchEntity;
    case talk::Error::kFar:
    case talk::Error::kSceneChanged: return protocol::ErrorCode::kTooFar;
    case talk::Error::kNoSession: return protocol::ErrorCode::kNoSession;
    case talk::Error::kStale:
    case talk::Error::kExpired: return protocol::ErrorCode::kStaleSession;
    case talk::Error::kBadOption:
    case talk::Error::kOptionGone: return protocol::ErrorCode::kBadOption;
    case talk::Error::kNotOffered: return protocol::ErrorCode::kQuestState;
    case talk::Error::kMission: return mission_code(failure.mission);
    case talk::Error::kTooLong:
    case talk::Error::kTooMany: return protocol::ErrorCode::kBusy;
    }
    return protocol::ErrorCode::kBusy;
}

// Cổng của phiên hội thoại: NPC và khoảng cách do zone trả, đo ngay lúc hỏi.
class Near final : public talk::World {
public:
    // NPC đang nói chuyện của người chơi: NpcRef chỉ mang GUID của bảng cảnh, vốn có thể trùng giữa các NPC, nên id thực thể đi riêng.
    struct Addressee {
        std::uint64_t session = 0;
        std::uint32_t entity = 0;
    };
    Near(const Surroundings& around, Addressee who) noexcept : around_(&around), session_(who.session), entity_(who.entity) {}
    [[nodiscard]] std::optional<talk::Presence> presence(ids::CharacterId, const talk::NpcRef& npc) const override {
        const std::optional<Surroundings::Presence> seen =
            around_->presence(session_, Surroundings::Spot{.entity = entity_, .scene = npc.scene});
        if (!seen) return std::nullopt;
        return talk::Presence{.hero_scene = seen->hero_scene, .npc_scene = seen->npc_scene, .distance = seen->distance_m};
    }

private:
    const Surroundings* around_;
    std::uint64_t session_;
    std::uint32_t entity_;
};

void put_done(protocol::QuestBook& out, const mission::Book& book) {
    for (std::size_t word = 0; word < book.done.size(); ++word) {
        for (std::size_t byte = 0; byte < 4; ++byte) {
            out.done.at((word * 4) + byte) = static_cast<std::byte>((book.done.at(word) >> (8U * byte)) & 0xFFU);
        }
    }
}

[[nodiscard]] protocol::QuestBook book_message(const mission::Book& book) {
    protocol::QuestBook out;
    for (const mission::Slot& slot : book.slots) {
        if (!slot.used()) continue;
        protocol::QuestSlot& one = out.slots.emplace_back();
        one.quest = static_cast<std::uint16_t>(slot.mission);
        one.script = slot.script;
        one.flags = slot.flags;
        one.params.assign(slot.params.begin(), slot.params.end());
    }
    put_done(out, book);
    return out;
}

} // namespace

Gameplay::Gameplay(const World& world, const Settings& settings)
    : world_(&world),
      settings_(settings),
      dice_(settings.seed),
      engine_(world.catalog(), dice_),
      service_(world.script(), engine_, world.handlers(), talk::Options{}) {}

void Gameplay::set_time(const Clock& clock) noexcept {
    unix_seconds_ = std::max<std::int64_t>(clock.unix_seconds, 0);
    tick_ = clock.tick;
}

ops::Calendar Gameplay::calendar() const noexcept {
    const std::int64_t local = unix_seconds_ + settings_.utc_offset_seconds;
    const std::int64_t days = floor_div(local, kSecondsPerDay);
    const std::int64_t seconds = local - (days * kSecondsPerDay);
    ops::Calendar out;
    out.unix_seconds = unix_seconds_;
    out.day = days;
    out.hour_time = floor_div(local, 3600);
    out.quarter_time = floor_div(local, 900);
    out.week_time = floor_div(days + kFirstMondayOffset, 7);
    out.hour = static_cast<std::int32_t>(seconds / 3600);
    out.minute = static_cast<std::int32_t>((seconds % 3600) / 60);
    out.weekday = static_cast<std::int32_t>(((days % 7) + kEpochWeekday) % 7);
    return out;
}

const Player* Gameplay::find(std::uint64_t session) const noexcept {
    const auto found = players_.find(session);
    return found == players_.end() ? nullptr : found->second.player.get();
}

bool Gameplay::allow(Entry& who) const noexcept {
    constexpr std::uint64_t kTicksPerSecond = 20;
    if (tick_ - who.window_start >= kTicksPerSecond) {
        who.window_start = tick_;
        who.window_count = 0;
    }
    return ++who.window_count <= settings_.intents_per_second;
}

Battle& Gameplay::battle(std::uint16_t scene) {
    std::unique_ptr<Battle>& slot = battles_[scene];
    // Hạt riêng mỗi cảnh: hai cảnh không rút chung dãy số, và chạy lại ra đúng dãy cũ.
    if (!slot) slot = std::make_unique<Battle>(*world_, scene, settings_.seed ^ (0x9E3779B97F4A7C15ULL * (scene + 1ULL)));
    return *slot;
}

bool Gameplay::attach(const Arrival& arrived, const ipc::Attach& arrival, Surroundings& around, Output& out) {
    const std::uint64_t session = arrived.session;
    // Gate gửi Attach lần hai cho cùng phiên: bỏ người chơi cũ trước, như Host với cảnh.
    detach(session, out);
    account::PlayRecord saved;
    if (!arrival.play.empty()) {
        std::expected<account::PlayRecord, account::PlayError> unpacked = account::unpack(arrival.play);
        if (!unpacked) return false;
        saved = std::move(*unpacked);
    } else {
        saved.level = std::max<std::uint16_t>(arrival.level, 1);
    }
    Identity who{.id = ids::CharacterId{arrival.character}, .name = arrival.name, .gender = arrival.gender, .sect = arrival.school};
    std::expected<std::unique_ptr<Player>, std::string> made = Player::restore(*world_, std::move(who), saved);
    if (!made) return false;
    Entry& entry = players_[session];
    entry.player = std::move(*made);
    entry.character = arrival.character;
    entry.scene = arrival.scene;
    entry.entity = arrived.entity;
    entry.window_start = tick_;
    Report report;
    const Env env{.stage = &around, .out = &out, .report = &report};
    const Seat seat{.session = session, .entity = arrived.entity, .player = entry.player.get(),
        .x_cm = static_cast<std::int32_t>(arrival.x_cm), .z_cm = static_cast<std::int32_t>(arrival.z_cm)};
    if (!battle(arrival.scene).join(seat, env)) {
        players_.erase(session);
        return false;
    }
    // Cái vừa đọc từ store là cái đã ghi: so với nó để biết khi nào có gì mới cần ghi.
    entry.saved = entry.player->record();
    sync(session, entry, out);
    return true;
}

void Gameplay::detach(std::uint64_t session, Output& out) {
    const auto found = players_.find(session);
    if (found == players_.end()) return;
    const Entry& entry = found->second;
    service_.close(entry.player->id());
    // Thân thể về lại Player trước khi đóng gói, và trước khi Player bị huỷ.
    if (const auto fight = battles_.find(entry.scene); fight != battles_.end()) fight->second->leave(session);
    if (std::optional<account::PlayRecord> last = entry.player->record()) {
        out.keeps.push_back(Output::Keep{.session = session, .character = entry.character, .record = std::move(*last)});
    }
    players_.erase(found);
}

void Gameplay::left_scene(std::uint64_t session, Output& out) {
    const auto found = players_.find(session);
    if (found == players_.end()) return;
    const std::optional<talk::SessionId> open = service_.session_of(found->second.player->id());
    service_.close(found->second.player->id());
    if (open) {
        out.down(session, protocol::DialogClosed{.session = open->value(), .reason = protocol::DialogCloseReason::kSceneChanged});
    }
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): entity là id thực thể, x_cm là toạ độ (HP-07)
bool Gameplay::change_scene(std::uint64_t session, std::uint16_t scene, std::uint32_t entity, float x_cm, float z_cm,
    Surroundings& around, Output& out) {
    const auto found = players_.find(session);
    if (found == players_.end()) return true;
    Entry& entry = found->second;
    if (const auto fight = battles_.find(entry.scene); fight != battles_.end()) fight->second->leave(session);
    const Seat seat{.session = session,
        .entity = entity,
        .player = entry.player.get(),
        .x_cm = static_cast<std::int32_t>(std::lround(x_cm)),
        .z_cm = static_cast<std::int32_t>(std::lround(z_cm))};
    Report report;
    const Env env{.stage = &around, .out = &out, .report = &report};
    if (!battle(scene).join(seat, env)) return false;
    entry.scene = scene;
    entry.entity = entity;
    settle(report, out);
    return true;
}

void Gameplay::autosave(Output& out) {
    for (auto& [session, entry] : players_) sync(session, entry, out);
}

void Gameplay::step(Surroundings& around, Output& out) {
    Report report;
    const Env env{.stage = &around, .out = &out, .report = &report};
    for (auto& [scene, fight] : battles_) fight->step(env);
    settle(report, out);
}

void Gameplay::intent(std::uint64_t session, protocol::ByteView frame, Surroundings& around, Output& out) {
    const auto found = players_.find(session);
    const protocol::FrameResult head = protocol::peek_frame(frame, protocol::kClientBodyBytes);
    if (found == players_.end() || !head) {
        ++ignored_;
        return;
    }
    const std::optional<protocol::Frame>& parsed = *head;
    if (!parsed || protocol::kHeaderBytes + parsed->body_bytes != frame.size()) {
        ++ignored_;
        return;
    }
    const protocol::GameClientResult decoded = protocol::decode_game_client(*parsed, frame.subspan(protocol::kHeaderBytes));
    if (!decoded) {
        ++ignored_;
        return;
    }
    Entry& entry = found->second;
    if (!allow(entry)) {
        out.reject(session, parsed->kind, protocol::ErrorCode::kRateLimited);
        return;
    }
    handle(session, entry, *decoded, around, out);
    sync(session, entry, out);
}

void Gameplay::handle(std::uint64_t session, Entry& who, const protocol::GameClientMessage& message,
    Surroundings& around, Output& out) {
    const Call call{.session = session, .who = &who, .around = &around, .out = &out};
    std::visit([this, &call](const auto& one) { on(call, one); }, message);
}

void Gameplay::on(const Call& call, const protocol::Talk& message) {
    const std::optional<Surroundings::Npc> npc = call.around->npc(call.session, Surroundings::Target{.entity = message.npc});
    if (!npc) {
        call.out->reject(call.session, protocol::Talk::kKind, protocol::ErrorCode::kNoSuchEntity);
        return;
    }
    const Near near{*call.around, Near::Addressee{.session = call.session, .entity = message.npc}};
    const talk::NpcRef ref{
        .guid = npc->guid, .scene = npc->scene, .name = ops::name_id(npc->name), .script = npc->script};
    talk::Result answer = service_.talk(*call.who->player, ref, near, ids::Tick{tick_}, calendar());
    call.who->npc_entity = message.npc;
    call.who->npc_name = npc->name;
    if (!answer) {
        fail(call.session, protocol::Talk::kKind, answer.error(), *call.who, npc->name, message.npc, *call.out);
        return;
    }
    reply(call.session, *call.who, npc->name, message.npc, *answer, *call.out);
}

// Từ đây phiên đã mở: tên NPC và id thực thể lấy lại từ NPC của phiên, không tin client nhắc lại.
void Gameplay::on(const Call& call, const protocol::DialogChoose& message) {
    const Near near{*call.around, Near::Addressee{.session = call.session, .entity = call.who->npc_entity}};
    talk::Result answer = service_.choose(
        *call.who->player, talk::SessionId{message.session}, message.index, near, ids::Tick{tick_}, calendar());
    finish(call, protocol::DialogChoose::kKind, answer);
}

void Gameplay::on(const Call& call, const protocol::QuestAccept& message) {
    const Near near{*call.around, Near::Addressee{.session = call.session, .entity = call.who->npc_entity}};
    talk::Result answer = service_.accept(
        *call.who->player, talk::SessionId{message.session}, message.quest, near, ids::Tick{tick_}, calendar());
    finish(call, protocol::QuestAccept::kKind, answer);
}

void Gameplay::on(const Call& call, const protocol::QuestTurnIn& message) {
    const Near near{*call.around, Near::Addressee{.session = call.session, .entity = call.who->npc_entity}};
    talk::Result answer = service_.turn_in(*call.who->player, talk::SessionId{message.session}, message.quest,
        message.reward, near, ids::Tick{tick_}, calendar());
    finish(call, protocol::QuestTurnIn::kKind, answer);
}

void Gameplay::on(const Call& call, const protocol::QuestAbandon& message) {
    const mission::Result done = service_.abandon(*call.who->player, message.quest, calendar());
    if (!done) {
        call.out->reject(call.session, protocol::QuestAbandon::kKind, mission_code(done.error()));
        return;
    }
    notices(call.session, *call.who, call.who->npc_name, *done, *call.out);
}

void Gameplay::on(const Call& call, const protocol::DialogClose& message) {
    const std::optional<talk::SessionId> open = service_.session_of(call.who->player->id());
    if (!open || open->value() != message.session) return;
    service_.close(call.who->player->id());
    call.out->down(call.session, protocol::DialogClosed{.session = message.session, .reason = protocol::DialogCloseReason::kClient});
}

void Gameplay::on(const Call& call, const protocol::CastSkill& message) {
    Report report;
    battle(call.who->scene).cast(call.session, message, Env{.stage = call.around, .out = call.out, .report = &report});
    settle(report, *call.out);
}

void Gameplay::on(const Call& call, const protocol::Respawn& message) {
    Report report;
    battle(call.who->scene).respawn(call.session, message, Env{.stage = call.around, .out = call.out, .report = &report});
    settle(report, *call.out);
}

void Gameplay::on(const Call& call, const protocol::PickUp& message) {
    Report report;
    battle(call.who->scene).pick_up(call.session, message, Env{.stage = call.around, .out = call.out, .report = &report});
    settle(report, *call.out);
}

void Gameplay::settle(const Report& report, Output& out) {
    const ops::Calendar now = calendar();
    const auto publish = [&](std::uint64_t session, const bus::Event& event) {
        const auto found = players_.find(session);
        if (found == players_.end()) return;
        const mission::Outcome outcome = engine_.handle(*found->second.player, event, now);
        notices(session, found->second, found->second.npc_name, outcome, out);
    };
    for (const Slain& kill : report.slain) {
        const auto found = players_.find(kill.session);
        if (found == players_.end()) continue;
        publish(kill.session, bus::Event{.kind = bus::Kind::kKill, .hero = found->second.player->id(), .a = kill.monster,
                                  .b = found->second.scene, .name = ops::name_id(kill.name), .c = 0});
    }
    for (const Picked& pick : report.picked) {
        const auto found = players_.find(pick.session);
        if (found == players_.end()) continue;
        const auto held = found->second.player->ports().items.count(pick.item);
        publish(pick.session, bus::Event{.kind = bus::Kind::kItemChanged, .hero = found->second.player->id(), .a = pick.item,
                                  .b = 0, .name = 0, .c = static_cast<std::int32_t>(std::min<std::int64_t>(held, INT32_MAX))});
    }
    for (const std::uint64_t session : report.changed) {
        const auto found = players_.find(session);
        if (found != players_.end()) sync(session, found->second, out);
    }
}

void Gameplay::finish(const Call& call, std::uint16_t request, talk::Result& answer) {
    if (!answer) {
        fail(call.session, request, answer.error(), *call.who, call.who->npc_name, call.who->npc_entity, *call.out);
        return;
    }
    reply(call.session, *call.who, call.who->npc_name, call.who->npc_entity, *answer, *call.out);
}

void Gameplay::reply(std::uint64_t session, Entry& who, const std::string& npc_name, std::uint32_t npc_entity,
    const talk::Reply& answer, Output& out) {
    notices(session, who, npc_name, answer.outcome, out);
    if (answer.closed) {
        out.down(session, protocol::DialogClosed{.session = answer.session.value(), .reason = protocol::DialogCloseReason::kDone});
        return;
    }
    const mission::HeroFacade facade{*who.player, &world_->catalog()};
    ops::Context context;
    context.hero = &facade;
    context.calendar = calendar();
    const Names names{.player = who.player->name(), .npc = npc_name};
    protocol::DialogOpen open;
    open.session = answer.session.value();
    open.npc = npc_entity;
    open.mode = mode_of(answer.view.mode);
    open.panel_quest = answer.view.panel_quest;
    fill_texts(open, answer.view, names, context);
    fill_marks(open, answer.view);
    out.down(session, open);
}

void Gameplay::fill_texts(protocol::DialogOpen& open, const talk::View& view, const Names& names,
    const ops::Context& context) const {
    for (const talk::Line& line : view.lines) {
        if (open.lines.size() >= protocol::kDialogOpenLinesCount) break;
        open.lines.push_back(protocol::DialogLine{.text = render(world_->text(), line.text, names, context, kLineBytes)});
    }
    for (const talk::Choice& choice : view.choices) {
        if (open.choices.size() >= protocol::kDialogOpenChoicesCount) break;
        open.choices.push_back(protocol::DialogChoice{
            .index = choice.index, .icon = choice.icon, .text = render(world_->text(), choice.text, names, context, kChoiceBytes)});
    }
}

void Gameplay::fill_marks(protocol::DialogOpen& open, const talk::View& view) {
    for (const talk::Mark& mark : view.marks) {
        if (open.marks.size() >= protocol::kDialogOpenMarksCount || mark.quest < 0 || mark.quest >= mission::kQuestIdLimit) continue;
        open.marks.push_back(protocol::DialogMark{.quest = static_cast<std::uint16_t>(mark.quest), .stage = stage_of(mark.stage)});
    }
    for (const talk::Bonus& bonus : view.bonuses) {
        if (open.bonuses.size() >= protocol::kDialogOpenBonusesCount) break;
        open.bonuses.push_back(protocol::DialogBonus{.kind = bonus_of(bonus.kind), .a = bonus.a, .b = bonus.b, .c = bonus.c});
    }
}

void Gameplay::fail(std::uint64_t session, std::uint16_t request, const talk::Failure& failure, Entry& who,
    const std::string& npc_name, std::uint32_t npc_entity, Output& out) {
    // Lựa chọn đã đổi: không phải lỗi của người chơi, gửi hộp thoại tính lại để vẽ thay.
    if (failure.error == talk::Error::kOptionGone) {
        const std::optional<talk::SessionId> open = service_.session_of(who.player->id());
        if (open) {
            talk::Reply again;
            again.session = *open;
            again.view = failure.view;
            reply(session, who, npc_name, npc_entity, again, out);
            return;
        }
    }
    out.reject(session, request, talk_code(failure));
    if (failure.closed) {
        out.down(session, protocol::DialogClosed{.session = 0, .reason = close_reason_of(failure.error)});
    }
}

void Gameplay::notices(std::uint64_t session, const Entry& who, const std::string& npc_name, const mission::Outcome& outcome,
    Output& out) {
    const mission::HeroFacade facade{*who.player, &world_->catalog()};
    ops::Context context;
    context.hero = &facade;
    context.calendar = calendar();
    const Names names{.player = who.player->name(), .npc = npc_name};
    for (const mission::Notice& notice : outcome.notices) {
        protocol::QuestNotice one;
        one.kind = notice_of(notice.kind);
        one.quest = notice.quest;
        one.text = render(world_->text(), notice.text, names, context, kNoticeBytes);
        one.value = notice.value;
        one.ref = notice.ref;
        out.down(session, one);
    }
}

void Gameplay::sync(std::uint64_t session, Entry& who, Output& out) {
    Player& hero = *who.player;
    if (!who.sent_once || !(hero.book() == who.sent_book)) {
        out.down(session, book_message(hero.book()));
        who.sent_book = hero.book();
    }
    // Lên cấp ngoài hội thoại (đánh quái): sổ nhiệm vụ có thể mở nhiệm vụ mới theo cấp.
    if (who.sent_once && hero.level() > who.sent_level) {
        const mission::Outcome opened = engine_.handle(hero, bus::Event{.kind = bus::Kind::kLevelUp, .hero = hero.id(),
            .a = static_cast<std::uint32_t>(hero.level()), .b = 0, .name = 0, .c = who.sent_level}, calendar());
        notices(session, who, who.npc_name, opened, out);
    }
    if (!who.sent_once || !(hero.bag().slots().size() == who.sent_bag.size() &&
                             std::equal(hero.bag().slots().begin(), hero.bag().slots().end(), who.sent_bag.begin()))) {
        protocol::SelfBag bag;
        for (std::size_t at = 0; at < hero.bag().slots().size() && bag.slots.size() < protocol::kSelfBagSlotsCount; ++at) {
            const BagSlot& held = hero.bag().slots()[at];
            bag.slots.push_back(protocol::BagSlot{.slot = static_cast<std::uint16_t>(at), .item = held.item,
                .count = static_cast<std::uint16_t>(std::min<std::uint32_t>(held.count, 65535U)), .bound = held.bound});
        }
        out.down(session, bag);
        who.sent_bag.assign(hero.bag().slots().begin(), hero.bag().slots().end());
    }
    if (!who.sent_once || hero.level() != who.sent_level || hero.exp() != who.sent_exp || hero.money() != who.sent_money ||
        hero.bound() != who.sent_bound) {
        out.down(session, protocol::SelfStats{.level = static_cast<std::uint16_t>(hero.level()),
                              .exp = hero.exp(), .money = hero.money(), .bound_money = hero.bound()});
        who.sent_level = static_cast<std::uint16_t>(hero.level());
        who.sent_exp = hero.exp();
        who.sent_money = hero.money();
        who.sent_bound = hero.bound();
    }
    who.sent_once = true;
    std::optional<account::PlayRecord> now = hero.record();
    if (!now || (who.saved && *who.saved == *now)) return;
    who.saved = now;
    out.keeps.push_back(Output::Keep{.session = session, .character = who.character, .record = std::move(*now)});
}

} // namespace game::play
