/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/online/bridge.cpp
 *  PHÂN HỆ   : Client / Online / Bridge
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nối OnlineAsk và OnlineReply của panel với lệnh và sự kiện của phiên.
 *  - Dịch mã lỗi và ngắt kết nối của protocol sang OnlineFault; UiConfig đổi
 *    FrameStyle; bí mật của việc nhờ được xoá sau khi chuyển.
 *  - Dịch hai chiều tin hội thoại NPC, sổ nhiệm vụ và chỉ số bản thân (nhóm 06,
 *    07 của protocol) sang cast::talk.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/online/bridge.hpp"

#include "client/cast/note.hpp"
#include "ui/panel/talk.hpp"
#include "client/session/gates.hpp"
#include "client/session/machine.hpp"
#include "client/session/session.hpp"
#include "net/net.hpp"
#include "protocol/messages.hpp"
#include "secure/secure.hpp"
#include "ui/panel/online.hpp"
#include "ui/panel/player_frame.hpp"
#include "ui/panel/roles.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <numbers>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <utility>
#include <variant>
#include <vector>

namespace game::client::online {
namespace {

using ui::panel::OnlineFault;
using ui::panel::OnlineReply;
namespace talk = ui::panel::talk;

[[nodiscard]] OnlineFault fault_of_goodbye(protocol::DisconnectReason reason) noexcept {
    switch (reason) {
    case protocol::DisconnectReason::kLoginElsewhere: return OnlineFault::kElsewhere;
    case protocol::DisconnectReason::kServerFull: return OnlineFault::kServerFull;
    case protocol::DisconnectReason::kProtocolViolation:
    case protocol::DisconnectReason::kVersionMismatch:
    case protocol::DisconnectReason::kContentMismatch: return OnlineFault::kProtocol;
    case protocol::DisconnectReason::kLoggedOut:
    case protocol::DisconnectReason::kIdle:
    case protocol::DisconnectReason::kKicked:
    case protocol::DisconnectReason::kShutdown: return OnlineFault::kClosed;
    }
    return OnlineFault::kClosed;
}

[[nodiscard]] OnlineReply plain(OnlineReply::Kind kind) {
    OnlineReply reply;
    reply.kind = kind;
    return reply;
}

[[nodiscard]] OnlineReply fault_reply(OnlineReply::Kind kind, OnlineFault fault) {
    OnlineReply reply = plain(kind);
    reply.fault = fault;
    return reply;
}

[[nodiscard]] OnlineReply roster_reply(const session::Roster& roster) {
    OnlineReply reply = plain(OnlineReply::Kind::kRoster);
    reply.roles.reserve(roster.characters.size());
    for (const protocol::CharacterSummary& character : roster.characters) reply.roles.push_back(role_of(character));
    return reply;
}

[[nodiscard]] OnlineReply entered_reply(const session::Entered& entered) {
    OnlineReply reply = plain(OnlineReply::Kind::kEntered);
    reply.scene = entered.character.scene;
    reply.x_cm = entered.position.x_cm;
    reply.z_cm = entered.position.z_cm;
    return reply;
}

[[nodiscard]] std::optional<OnlineReply> world_reply(const session::World& world) {
    const auto* config = std::get_if<protocol::UiConfig>(&world.message);
    if (config == nullptr) return std::nullopt;
    OnlineReply reply = plain(OnlineReply::Kind::kStyle);
    reply.style = config->avatar_frame == protocol::AvatarFrame::kSquare ? ui::panel::FrameStyle::kSquare
                                                                         : ui::panel::FrameStyle::kRound;
    return reply;
}

[[nodiscard]] std::optional<session::Command> command_of(const ui::panel::OnlineAsk& ask) {
    switch (ask.work) {
    case ui::panel::OnlineWork::kCreate: {
        session::Create made;
        made.name = ask.role.name;
        made.gender = ask.role.sex == 1 ? protocol::Gender::kMale : protocol::Gender::kFemale;
        made.face = ask.role.face;
        made.hair = ask.role.hair;
        return made;
    }
    case ui::panel::OnlineWork::kDelete: return session::Delete{.character = ask.role.id};
    case ui::panel::OnlineWork::kEnter: return session::Enter{.character = ask.role.id};
    case ui::panel::OnlineWork::kDrop: return session::Drop{};
    case ui::panel::OnlineWork::kSignIn: return std::nullopt;
    }
    return std::nullopt;
}

// Trần hàng chờ tin thế giới khi luồng game không lấy. Tin vị trí và sinh lực là trạng thái tức thời nên bỏ được; tin
// hiện, biến mất, vào cảnh và kéo về thì không.
constexpr std::size_t kNoteCap = 4096;

constexpr float kCmPerMeter = 100.0F;
constexpr float kDirectionSteps = 65536.0F;

[[nodiscard]] float meters(float centimeters) noexcept {
    return centimeters / kCmPerMeter;
}

// Hướng của dây: 0..65535 ứng với 0..2π, 0 là +X và tăng dần quay về +Z, tức vectơ (cos a, sin a) trên (x, z). Hướng của
// client là atan2(dx, dz) = π/2 - a.
[[nodiscard]] float facing_of(std::uint16_t direction) noexcept {
    const float angle = static_cast<float>(direction) * (2.0F * std::numbers::pi_v<float>) / kDirectionSteps;
    return (std::numbers::pi_v<float> / 2.0F) - angle;
}

[[nodiscard]] cast::Kind kind_of(protocol::EntityKind kind) noexcept {
    switch (kind) {
    case protocol::EntityKind::kPlayer: return cast::Kind::kPlayer;
    case protocol::EntityKind::kMonster: return cast::Kind::kMonster;
    case protocol::EntityKind::kNpc: return cast::Kind::kNpc;
    case protocol::EntityKind::kPet: return cast::Kind::kPet;
    case protocol::EntityKind::kDrop: return cast::Kind::kDrop;
    case protocol::EntityKind::kObject: return cast::Kind::kObject;
    }
    return cast::Kind::kObject;
}

[[nodiscard]] cast::Pose pose_of(protocol::EntityState state) noexcept {
    switch (state) {
    case protocol::EntityState::kIdle: return cast::Pose::kIdle;
    case protocol::EntityState::kWalk: return cast::Pose::kWalk;
    case protocol::EntityState::kDead: return cast::Pose::kDead;
    }
    return cast::Pose::kIdle;
}

struct Spot {
    std::uint32_t id = 0;
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    std::uint16_t direction = 0;
    std::uint32_t tick = 0;
    protocol::EntityState state = protocol::EntityState::kIdle;
};

template <typename Place>
[[nodiscard]] Spot spot_of(const Place& pos) {
    Spot spot;
    spot.id = pos.id;
    spot.x_cm = pos.x_cm;
    spot.z_cm = pos.z_cm;
    spot.direction = pos.direction;
    spot.tick = pos.tick;
    spot.state = pos.state;
    return spot;
}

[[nodiscard]] cast::Moved moved_note(Spot spot) {
    cast::Moved moved;
    moved.id = spot.id;
    moved.x = meters(spot.x_cm);
    moved.z = meters(spot.z_cm);
    moved.facing = facing_of(spot.direction);
    moved.tick = spot.tick;
    moved.pose = pose_of(spot.state);
    return moved;
}

// CombatEvent::flags bit 0: hội tâm (chí mạng).
constexpr std::uint8_t kCriticalFlag = 1;

[[nodiscard]] cast::Blow blow_of(protocol::CombatKind kind) noexcept {
    switch (kind) {
    case protocol::CombatKind::kDamage: return cast::Blow::kDamage;
    case protocol::CombatKind::kHeal: return cast::Blow::kHeal;
    case protocol::CombatKind::kMiss: return cast::Blow::kMiss;
    case protocol::CombatKind::kImmune: return cast::Blow::kImmune;
    }
    return cast::Blow::kMiss;
}

[[nodiscard]] cast::Note spawn_note(const protocol::EntityAppear& shown) {
    cast::Spawn spawn;
    spawn.id = shown.id;
    spawn.kind = kind_of(shown.kind);
    spawn.template_id = shown.template_id;
    spawn.name = shown.name;
    spawn.level = shown.level;
    spawn.x = meters(shown.x_cm);
    spawn.z = meters(shown.z_cm);
    spawn.facing = facing_of(shown.direction);
    spawn.speed = meters(static_cast<float>(shown.speed_cm));
    spawn.hp_percent = shown.hp_percent;
    spawn.gender = shown.gender;
    spawn.face = shown.face;
    spawn.hair = shown.hair;
    spawn.school = shown.school;
    spawn.pose = pose_of(shown.state);
    return spawn;
}

struct NotePick {
    std::optional<cast::Note> operator()(const protocol::SceneEnter& entered) const {
        return cast::Arrive{.scene = entered.scene,
            .x = meters(entered.x_cm),
            .z = meters(entered.z_cm),
            .facing = facing_of(entered.direction),
            .self_id = entered.self_id};
    }
    std::optional<cast::Note> operator()(const protocol::EntityAppear& shown) const { return spawn_note(shown); }
    std::optional<cast::Note> operator()(const protocol::EntityDisappear& gone) const {
        return cast::Vanish{.id = gone.id};
    }
    std::optional<cast::Note> operator()(const protocol::EntityPos& moved) const {
        return moved_note(spot_of(moved));
    }
    std::optional<cast::Note> operator()(const protocol::EntityVitals& vitals) const {
        return cast::Hurt{.id = vitals.id, .hp_percent = vitals.hp_percent};
    }
    std::optional<cast::Note> operator()(const protocol::Position& spot) const {
        return cast::Pulled{.x = meters(spot.x_cm), .z = meters(spot.z_cm)};
    }
    std::optional<cast::Note> operator()(const protocol::EntityFlags& flagged) const {
        return cast::Flagged{.id = flagged.id, .flags = flagged.flags};
    }
    std::optional<cast::Note> operator()(const protocol::SkillCast& cast) const {
        return cast::Casting{.source = cast.source,
            .skill = cast.skill,
            .target = cast.target,
            .x = meters(cast.x_cm),
            .z = meters(cast.z_cm),
            .level = cast.level,
            .seq = cast.seq};
    }
    std::optional<cast::Note> operator()(const protocol::SkillCastEnd& end) const {
        return cast::CastEnded{.source = end.source, .skill = end.skill, .is_interrupted = end.interrupted};
    }
    std::optional<cast::Note> operator()(const protocol::CombatEvent& blow) const {
        return cast::Struck{.source = blow.source,
            .target = blow.target,
            .skill = blow.skill,
            .kind = blow_of(blow.kind),
            .value = blow.value,
            .is_critical = (blow.flags & kCriticalFlag) != 0};
    }
    std::optional<cast::Note> operator()(const protocol::EntityDied& died) const {
        return cast::Died{.id = died.id, .killer = died.killer};
    }
    template <typename Other>
    std::optional<cast::Note> operator()(const Other& /*message*/) const {
        return std::nullopt;
    }
};

// Các enum của dây và của cast::talk cùng số nhưng khác kiểu; đổi bằng switch để thêm giá trị vào một bên là biên dịch báo.
[[nodiscard]] talk::Mode mode_of(protocol::DialogMode mode) noexcept {
    switch (mode) {
    case protocol::DialogMode::kList: return talk::Mode::kList;
    case protocol::DialogMode::kBox: return talk::Mode::kBox;
    case protocol::DialogMode::kMissionInfo: return talk::Mode::kMissionInfo;
    case protocol::DialogMode::kContinue: return talk::Mode::kContinue;
    case protocol::DialogMode::kDemand: return talk::Mode::kDemand;
    case protocol::DialogMode::kTips: return talk::Mode::kTips;
    }
    return talk::Mode::kList;
}

[[nodiscard]] talk::Stage stage_of(protocol::MarkStage stage) noexcept {
    switch (stage) {
    case protocol::MarkStage::kAvailable: return talk::Stage::kAvailable;
    case protocol::MarkStage::kInProgress: return talk::Stage::kInProgress;
    case protocol::MarkStage::kReady: return talk::Stage::kReady;
    }
    return talk::Stage::kAvailable;
}

[[nodiscard]] talk::BonusKind bonus_of(protocol::BonusKind kind) noexcept {
    switch (kind) {
    case protocol::BonusKind::kMoney: return talk::BonusKind::kMoney;
    case protocol::BonusKind::kItem: return talk::BonusKind::kItem;
    case protocol::BonusKind::kRadio: return talk::BonusKind::kRadio;
    case protocol::BonusKind::kRandom: return talk::BonusKind::kRandom;
    case protocol::BonusKind::kDemand: return talk::BonusKind::kDemand;
    }
    return talk::BonusKind::kMoney;
}

[[nodiscard]] talk::Reason reason_of(protocol::DialogCloseReason reason) noexcept {
    switch (reason) {
    case protocol::DialogCloseReason::kDone: return talk::Reason::kDone;
    case protocol::DialogCloseReason::kFar: return talk::Reason::kFar;
    case protocol::DialogCloseReason::kSceneChanged: return talk::Reason::kSceneChanged;
    case protocol::DialogCloseReason::kNpcGone: return talk::Reason::kNpcGone;
    case protocol::DialogCloseReason::kExpired: return talk::Reason::kExpired;
    case protocol::DialogCloseReason::kReplaced: return talk::Reason::kReplaced;
    case protocol::DialogCloseReason::kDead: return talk::Reason::kDead;
    case protocol::DialogCloseReason::kClient: return talk::Reason::kClient;
    }
    return talk::Reason::kDone;
}

[[nodiscard]] talk::NoticeKind notice_kind_of(protocol::QuestNoticeKind kind) noexcept {
    switch (kind) {
    case protocol::QuestNoticeKind::kAdded: return talk::NoticeKind::kAdded;
    case protocol::QuestNoticeKind::kUpdated: return talk::NoticeKind::kUpdated;
    case protocol::QuestNoticeKind::kReady: return talk::NoticeKind::kReady;
    case protocol::QuestNoticeKind::kRemoved: return talk::NoticeKind::kRemoved;
    case protocol::QuestNoticeKind::kDone: return talk::NoticeKind::kDone;
    case protocol::QuestNoticeKind::kFailed: return talk::NoticeKind::kFailed;
    case protocol::QuestNoticeKind::kText: return talk::NoticeKind::kText;
    case protocol::QuestNoticeKind::kAnnounce: return talk::NoticeKind::kAnnounce;
    case protocol::QuestNoticeKind::kRewardExp: return talk::NoticeKind::kRewardExp;
    case protocol::QuestNoticeKind::kRewardMoney: return talk::NoticeKind::kRewardMoney;
    case protocol::QuestNoticeKind::kRewardItem: return talk::NoticeKind::kRewardItem;
    case protocol::QuestNoticeKind::kRelation: return talk::NoticeKind::kRelation;
    }
    return talk::NoticeKind::kText;
}

[[nodiscard]] talk::Refusal refusal_of(protocol::ErrorCode code) noexcept {
    switch (code) {
    case protocol::ErrorCode::kNoSession: return talk::Refusal::kNoSession;
    case protocol::ErrorCode::kStaleSession: return talk::Refusal::kStaleSession;
    case protocol::ErrorCode::kBadOption: return talk::Refusal::kBadOption;
    case protocol::ErrorCode::kTooFar: return talk::Refusal::kTooFar;
    case protocol::ErrorCode::kNoSuchEntity: return talk::Refusal::kNoSuchEntity;
    case protocol::ErrorCode::kQuestUnavailable: return talk::Refusal::kQuestUnavailable;
    case protocol::ErrorCode::kQuestLogFull: return talk::Refusal::kQuestLogFull;
    case protocol::ErrorCode::kQuestState: return talk::Refusal::kQuestState;
    case protocol::ErrorCode::kBagFull: return talk::Refusal::kBagFull;
    case protocol::ErrorCode::kNotEnoughMoney: return talk::Refusal::kNotEnoughMoney;
    case protocol::ErrorCode::kNotEnoughItems: return talk::Refusal::kNotEnoughItems;
    case protocol::ErrorCode::kBadChoice: return talk::Refusal::kBadChoice;
    case protocol::ErrorCode::kCannotAbandon: return talk::Refusal::kCannotAbandon;
    case protocol::ErrorCode::kRateLimited: return talk::Refusal::kRateLimited;
    default: return talk::Refusal::kOther;
    }
}

[[nodiscard]] talk::Decline decline_of(protocol::ErrorCode code) noexcept {
    switch (code) {
    case protocol::ErrorCode::kNotLearned: return talk::Decline::kNotLearned;
    case protocol::ErrorCode::kCooldown: return talk::Decline::kCooldown;
    case protocol::ErrorCode::kNotEnoughMana: return talk::Decline::kNotEnoughMana;
    case protocol::ErrorCode::kNotEnoughRage: return talk::Decline::kNotEnoughRage;
    case protocol::ErrorCode::kBadTarget: return talk::Decline::kBadTarget;
    case protocol::ErrorCode::kOutOfRange: return talk::Decline::kOutOfRange;
    case protocol::ErrorCode::kCannotAttack: return talk::Decline::kCannotAttack;
    case protocol::ErrorCode::kNoSuchEntity: return talk::Decline::kGone;
    case protocol::ErrorCode::kDead: return talk::Decline::kDead;
    case protocol::ErrorCode::kNotDead: return talk::Decline::kNotDead;
    case protocol::ErrorCode::kNotYours: return talk::Decline::kNotYours;
    case protocol::ErrorCode::kBusy: return talk::Decline::kBusy;
    default: return talk::Decline::kOther;
    }
}

// Reject của một việc thuộc hộp thoại hay sổ nhiệm vụ (mã tin 0x0601..0x0606).
[[nodiscard]] bool is_speech_request(std::uint16_t request) noexcept {
    return request >= protocol::Talk::kKind && request <= protocol::DialogClose::kKind;
}

// Reject của một việc chiêu thức: ra chiêu, hồi sinh, nhặt đồ (mã tin 0x0801..0x0803).
[[nodiscard]] bool is_fight_request(std::uint16_t request) noexcept {
    return request >= protocol::CastSkill::kKind && request <= protocol::PickUp::kKind;
}

[[nodiscard]] talk::Dialog dialog_of(const protocol::DialogOpen& open) {
    talk::Dialog dialog;
    dialog.session = open.session;
    dialog.npc = open.npc;
    dialog.mode = mode_of(open.mode);
    dialog.panel_quest = open.panel_quest;
    dialog.lines.reserve(open.lines.size());
    for (const protocol::DialogLine& line : open.lines) dialog.lines.push_back(line.text);
    dialog.choices.reserve(open.choices.size());
    for (const protocol::DialogChoice& choice : open.choices) {
        dialog.choices.push_back(talk::Choice{.index = choice.index, .icon = choice.icon, .text = choice.text});
    }
    dialog.marks.reserve(open.marks.size());
    for (const protocol::DialogMark& mark : open.marks) {
        dialog.marks.push_back(talk::Mark{.quest = mark.quest, .stage = stage_of(mark.stage)});
    }
    dialog.bonuses.reserve(open.bonuses.size());
    for (const protocol::DialogBonus& bonus : open.bonuses) {
        dialog.bonuses.push_back(talk::Bonus{.kind = bonus_of(bonus.kind), .a = bonus.a, .b = bonus.b, .c = bonus.c});
    }
    return dialog;
}

// Mảng "đã xong" của dây là 128 từ 32 bit little-endian; ghép từng byte nên không phụ thuộc thứ tự byte của máy.
[[nodiscard]] talk::Book book_of(const protocol::QuestBook& book) {
    constexpr std::size_t kBytesPerWord = 4;
    static_assert(protocol::kQuestBookDoneBytes == talk::kDoneWords * kBytesPerWord);
    talk::Book made;
    made.slots.reserve(book.slots.size());
    for (const protocol::QuestSlot& slot : book.slots) {
        made.slots.push_back(
            talk::Slot{.quest = slot.quest, .script = slot.script, .flags = slot.flags, .params = slot.params});
    }
    for (std::size_t word = 0; word < talk::kDoneWords; ++word) {
        std::uint32_t value = 0;
        for (std::size_t byte = 0; byte < kBytesPerWord; ++byte) {
            const auto part = static_cast<std::uint32_t>(book.done.at((word * kBytesPerWord) + byte));
            value |= part << (8U * byte);
        }
        made.done.at(word) = value;
    }
    return made;
}

// Ảnh chụp túi. Ô item 0 hoặc count 0 là ô trống gửi nhầm: bỏ. Giữ tối đa talk::kBagSlots ô đã nhận,
// kể cả khi bản dựng trong tiến trình dài hơn trần dây. Khác gốc: một túi, không loại túi.
talk::Bag bag_of(const protocol::SelfBag& source) {
    talk::Bag made;
    const std::size_t room = std::min(source.slots.size(), talk::kBagSlots);
    made.slots.reserve(room);
    for (const protocol::BagSlot& slot : source.slots) {
        if (made.slots.size() == talk::kBagSlots) break;
        if (slot.item == 0 || slot.count == 0) continue;
        talk::BagSlot held;
        held.slot = slot.slot;
        held.item = slot.item;
        held.count = slot.count;
        held.bound = slot.bound;
        made.slots.push_back(held);
    }
    return made;
}

struct HearPick {
    std::optional<talk::Hear> operator()(const protocol::DialogOpen& open) const { return dialog_of(open); }
    std::optional<talk::Hear> operator()(const protocol::DialogClosed& closed) const {
        return talk::Closed{.session = closed.session, .reason = reason_of(closed.reason)};
    }
    std::optional<talk::Hear> operator()(const protocol::QuestBook& book) const { return book_of(book); }
    std::optional<talk::Hear> operator()(const protocol::QuestNotice& notice) const {
        return talk::Notice{.kind = notice_kind_of(notice.kind),
            .quest = notice.quest,
            .text = notice.text,
            .value = notice.value,
            .ref = notice.ref};
    }
    std::optional<talk::Hear> operator()(const protocol::SelfStats& stats) const {
        return talk::Stats{
            .level = stats.level, .exp = stats.exp, .money = stats.money, .bound_money = stats.bound_money};
    }
    std::optional<talk::Hear> operator()(const protocol::SelfVitals& vitals) const {
        return talk::Vitals{.hp = vitals.hp,
            .hp_max = vitals.hp_max,
            .mp = vitals.mp,
            .mp_max = vitals.mp_max,
            .rage = vitals.rage,
            .rage_max = vitals.rage_max};
    }
    std::optional<talk::Hear> operator()(const protocol::SelfSkills& list) const {
        talk::Skills skills;
        skills.learned.reserve(list.skills.size());
        for (const protocol::SkillEntry& entry : list.skills) {
            skills.learned.push_back(
                talk::Learned{.skill = entry.skill, .level = entry.level, .cooldown_ms = entry.cooldown_ms});
        }
        return skills;
    }
    std::optional<talk::Hear> operator()(const protocol::SkillCooldown& cooldown) const {
        return talk::Cooldown{.skill = cooldown.skill, .ms = cooldown.ms};
    }
    std::optional<talk::Hear> operator()(const protocol::DeathNotice& notice) const {
        return talk::Slain{.exp_lost = notice.exp_lost, .money_lost = notice.money_lost};
    }
    std::optional<talk::Hear> operator()(const protocol::Reject& refused) const {
        if (is_fight_request(refused.request)) return talk::Declined{.why = decline_of(refused.code)};
        if (!is_speech_request(refused.request)) return std::nullopt;
        return talk::Refused{.why = refusal_of(refused.code)};
    }
    std::optional<talk::Hear> operator()(const protocol::SelfBag& bag) const { return bag_of(bag); }
    template <typename Other>
    std::optional<talk::Hear> operator()(const Other& /*message*/) const {
        return std::nullopt;
    }
};

struct SpeechPick {
    session::Speech operator()(const talk::Talk& said) const noexcept { return protocol::Talk{.npc = said.npc}; }
    session::Speech operator()(const talk::Choose& said) const noexcept {
        return protocol::DialogChoose{.session = said.session, .index = said.index};
    }
    session::Speech operator()(const talk::Accept& said) const noexcept {
        return protocol::QuestAccept{.session = said.session, .quest = said.quest};
    }
    session::Speech operator()(const talk::TurnIn& said) const noexcept {
        return protocol::QuestTurnIn{.session = said.session, .quest = said.quest, .reward = said.reward};
    }
    session::Speech operator()(const talk::Abandon& said) const noexcept {
        return protocol::QuestAbandon{.quest = said.quest};
    }
    session::Speech operator()(const talk::Close& said) const noexcept {
        return protocol::DialogClose{.session = said.session};
    }
    session::Speech operator()(const talk::Cast& said) const noexcept {
        return protocol::CastSkill{.seq = said.seq,
            .skill = said.skill,
            .target = said.target,
            .x_cm = said.x * kCmPerMeter,
            .z_cm = said.z * kCmPerMeter};
    }
    session::Speech operator()(const talk::Revive& said) const noexcept {
        const bool is_here = said.place == talk::Place::kHere;
        return protocol::Respawn{.place = is_here ? protocol::RespawnPlace::kHere : protocol::RespawnPlace::kTown};
    }
    session::Speech operator()(const talk::PickUp& said) const noexcept { return protocol::PickUp{.drop = said.drop}; }
};

// Trần hàng chờ tin hội thoại khi luồng game không lấy; quá thì bỏ tin cũ nhất (bản mới của sổ và hộp thay bản cũ).
constexpr std::size_t kHeardCap = 256;

// Xoá chữ nhạy cảm của việc nhờ sau khi đã chuyển đi.
void forget(std::string& secret) noexcept {
    secure::wipe_bytes(std::as_writable_bytes(std::span{secret.data(), secret.size()}));
    secret.clear();
}

} // namespace

OnlineFault fault_of(protocol::ErrorCode code) noexcept {
    switch (code) {
    case protocol::ErrorCode::kBadCredentials:
    case protocol::ErrorCode::kNotAuthenticated:
    case protocol::ErrorCode::kPasswordInvalid: return OnlineFault::kBadLogin;
    case protocol::ErrorCode::kServerFull: return OnlineFault::kServerFull;
    case protocol::ErrorCode::kBusy:
    case protocol::ErrorCode::kRateLimited: return OnlineFault::kBusy;
    case protocol::ErrorCode::kMaintenance: return OnlineFault::kMaintenance;
    case protocol::ErrorCode::kNameTaken: return OnlineFault::kNameTaken;
    case protocol::ErrorCode::kNameInvalid: return OnlineFault::kNameInvalid;
    case protocol::ErrorCode::kCharacterLimit: return OnlineFault::kRoleLimit;
    case protocol::ErrorCode::kNoSuchCharacter: return OnlineFault::kNoRole;
    case protocol::ErrorCode::kVersionMismatch:
    case protocol::ErrorCode::kMalformed:
    case protocol::ErrorCode::kOutOfOrder: return OnlineFault::kProtocol;
    default: return OnlineFault::kOther;
    }
}

OnlineFault fault_of(const session::Lost& lost) noexcept {
    switch (lost.fault) {
    case session::Fault::kUnreachable: return OnlineFault::kUnreachable;
    case session::Fault::kSecure: return OnlineFault::kSecure;
    case session::Fault::kProtocol: return OnlineFault::kProtocol;
    case session::Fault::kTimeout: return OnlineFault::kTimeout;
    case session::Fault::kQueueFull: return OnlineFault::kOther;
    case session::Fault::kGoodbye:
        return lost.reason ? fault_of_goodbye(*lost.reason) : OnlineFault::kClosed;
    }
    return OnlineFault::kOther;
}

ui::panel::Role role_of(const protocol::CharacterSummary& character) {
    ui::panel::Role role;
    role.id = character.id;
    role.name = character.name;
    role.sex = character.gender == protocol::Gender::kMale ? std::uint8_t{1} : std::uint8_t{0};
    role.face = character.face;
    role.hair = character.hair;
    role.level = character.level;
    role.sect = character.school;
    return role;
}

std::optional<OnlineReply> reply_of(const session::Event& event) {
    struct Pick {
        std::optional<OnlineReply> operator()(const session::Roster& roster) const { return roster_reply(roster); }
        std::optional<OnlineReply> operator()(const session::Rejected& rejected) const {
            // Việc hộp thoại bị từ chối không liên quan chuỗi đăng nhập.
            if (rejected.ask == session::Ask::kSpeak) return std::nullopt;
            return fault_reply(OnlineReply::Kind::kRefused, fault_of(rejected.code));
        }
        std::optional<OnlineReply> operator()(const session::Entered& entered) const { return entered_reply(entered); }
        std::optional<OnlineReply> operator()(const session::World& world) const { return world_reply(world); }
        std::optional<OnlineReply> operator()(const session::Lost& lost) const {
            return fault_reply(OnlineReply::Kind::kLost, fault_of(lost));
        }
    };
    return std::visit(Pick{}, event);
}

using Entry = protocol::PosEntry;

void push_place(Notes& notes, const Entry& place, std::size_t cap, std::size_t& added) {
    if (notes.size() >= cap) return;
    const cast::Moved moved = moved_note(spot_of(place));
    notes.push_back(moved);
    ++added;
}

std::size_t append_positions(Notes& notes, const PosBatch& batch, std::size_t cap) {
    std::size_t added = 0;
    for (const Entry& place : batch.places)
        push_place(notes, place, cap, added);
    return added;
}

void keep_one(Notes& notes, cast::Note note) {
    const bool is_move = std::holds_alternative<cast::Moved>(note);
    const bool is_hurt = std::holds_alternative<cast::Hurt>(note);
    const bool is_state = is_move || is_hurt;
    if (is_state && notes.size() >= kNoteCap) return;
    notes.push_back(std::move(note));
}

void keep_world_note(const session::Event& event, Notes& notes) {
    const session::World* world = std::get_if<session::World>(&event);
    const protocol::EntityPosBatch* batch = nullptr;
    if (world != nullptr) batch = std::get_if<protocol::EntityPosBatch>(&world->message);
    if (batch != nullptr) {
        static_cast<void>(append_positions(notes, *batch, kNoteCap));
        return;
    }
    std::optional<cast::Note> note = note_of(event);
    if (!note) return;
    keep_one(notes, std::move(*note));
}

std::optional<cast::Note> note_of(const session::Event& event) {
    const auto* world = std::get_if<session::World>(&event);
    if (world == nullptr) return std::nullopt;
    return std::visit(NotePick{}, world->message);
}

std::optional<talk::Hear> hear_of(const session::Event& event) {
    const auto* world = std::get_if<session::World>(&event);
    if (world == nullptr) return std::nullopt;
    return std::visit(HearPick{}, world->message);
}

session::Speech speech_of(const talk::Say& say) {
    return std::visit(SpeechPick{}, say);
}

Bridge::Bridge(session::GateBook book) : network_(net::Network::start()), book_(std::move(book)) {
    // Không mở được thư viện mạng thì vẫn chạy cục bộ; SignIn sau đó hỏng ở socket và báo kUnreachable như mất mạng.
    if (!network_) std::println(stderr, "Mạng: không khởi động được thư viện mạng: {}", net::describe(network_.error()));
}

Bridge::~Bridge() = default;

std::vector<ui::panel::ServerName> Bridge::servers() const {
    std::vector<ui::panel::ServerName> names;
    names.reserve(book_.gates.size());
    for (const session::Gate& gate : book_.gates) {
        names.push_back(ui::panel::ServerName{.area = gate.area, .server = gate.server});
    }
    return names;
}

session::Session& Bridge::line() {
    if (!session_) session_.emplace();
    return *session_;
}

void Bridge::refuse(OnlineFault fault) {
    immediate_.push_back(fault_reply(OnlineReply::Kind::kRefused, fault));
}

void Bridge::serve(std::span<ui::panel::OnlineAsk> asks) {
    for (ui::panel::OnlineAsk& ask : asks) {
        if (ask.work == ui::panel::OnlineWork::kSignIn) {
            const session::Gate* gate = session::find_gate(book_, ask.server.area, ask.server.server);
            if (gate == nullptr) {
                refuse(OnlineFault::kUnreachable);
            } else if (!line().submit(session::SignIn{.gate = *gate, .account = ask.account, .password = ask.password})) {
                refuse(OnlineFault::kBusy);
            }
            forget(ask.password);
            continue;
        }
        // Việc ngoài đăng nhập cần phiên đã dựng; trả phiên khi chưa có phiên thì không có gì để trả.
        if (!session_ && ask.work == ui::panel::OnlineWork::kDrop) continue;
        if (std::optional<session::Command> command = command_of(ask)) {
            if (!line().submit(std::move(*command))) refuse(OnlineFault::kBusy);
        }
    }
}

std::vector<OnlineReply> Bridge::collect() {
    std::vector<OnlineReply> replies = std::exchange(immediate_, {});
    if (!session_) return replies;
    for (const session::Event& event : session_->drain()) {
        std::optional<OnlineReply> reply = reply_of(event);
        if (reply) replies.push_back(std::move(*reply));
        if (std::optional<talk::Hear> heard = hear_of(event)) {
            if (heard_.size() >= kHeardCap) heard_.erase(heard_.begin());
            heard_.push_back(std::move(*heard));
        }
        keep_world_note(event, notes_);
    }
    return replies;
}

std::vector<cast::Note> Bridge::take_notes() {
    return std::exchange(notes_, {});
}

void Bridge::speak(std::span<const talk::Say> says) {
    if (!session_) return;
    for (const talk::Say& say : says) {
        if (!session_->submit(session::Speak{.speech = speech_of(say)})) return;
    }
}

std::vector<talk::Hear> Bridge::take_heard() {
    return std::exchange(heard_, {});
}

void Bridge::report(float x_m, float z_m) {
    if (session_) session_->report(x_m, z_m);
}

session::Phase Bridge::phase() const noexcept {
    return session_ ? session_->phase() : session::Phase::kIdle;
}

} // namespace game::client::online
