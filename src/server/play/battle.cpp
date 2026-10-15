/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/battle.cpp
 *  PHÂN HỆ   : Server / Play / Battle
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt chiến đấu của một cảnh: ra chiêu, hồi sinh, nhặt đồ, bước 20 Hz,
 *    dịch sự kiện đấu trường thành tin, chia kinh nghiệm và đồ khi quái chết.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "play/battle.hpp"

#include "actor/attr.hpp"
#include "actor/body.hpp"
#include "actor/rules.hpp"
#include "combat/arena.hpp"
#include "combat/catalog.hpp"
#include "combat/fighter.hpp"
#include "combat/types.hpp"
#include "ids/ids.hpp"
#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/roll.hpp"
#include "ledger/ledger.hpp"
#include "loot/box.hpp"
#include "loot/roller.hpp"
#include "loot/types.hpp"
#include "play/player.hpp"
#include "play/stage.hpp"
#include "play/world.hpp"
#include "protocol/messages.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::play {

namespace {

// Toạ độ client gửi cho chiêu nhắm đất ngoài khoảng này là bậy (cảnh lớn nhất cỡ vài chục nghìn mét).
constexpr float kMaxGroundCm = 10'000'000.0F;
constexpr std::uint16_t kPlainAttack = 0;  // skills.tsv id 0: đòn thường chung
constexpr std::int32_t kPickRangeCm = 300;
// Quái trong tầm này quanh người ra chiêu được dựng Fighter để chiêu vùng quét tới, ngoài tầm đánh và bán kính chiêu.
constexpr std::int32_t kReachSlackCm = 200;
constexpr std::int32_t kMaxReachCm = 5000;
// SelfVitals tối đa 5 lần mỗi giây (20 tick mỗi giây).
constexpr std::uint64_t kVitalsGapTicks = 4;
constexpr std::uint64_t kPruneEveryTicks = std::uint64_t{20} * 60;
constexpr std::uint64_t kPruneIdleTicks = std::uint64_t{20} * 60;
// Số vật rơi tối đa chờ nhặt trong một cảnh: kẻ giết quái hàng loạt không làm phình bộ nhớ.
constexpr std::size_t kMaxDrops = 4096;
constexpr std::size_t kMaxSkillsSent = 128;
constexpr std::int64_t kMsPerTick = 1000 / combat::kTicksPerSecond;
// Số khối serial cấp cho vật rơi của cảnh: vật rơi chỉ để chuyển thành chồng trong túi, nên serial không cần duy nhất toàn cụm.
constexpr std::uint64_t kSerialFirst = 1;
constexpr std::uint64_t kSerialLast = 1ULL << 40U;

struct Offset {
    std::int32_t x_cm;
    std::int32_t z_cm;
};
// Vật rơi xếp quanh xác theo vòng cố định: tất định, và hai món không đè lên nhau.
constexpr std::array<Offset, 8> kRing{{{.x_cm = 0, .z_cm = 0}, {.x_cm = 80, .z_cm = 0}, {.x_cm = -80, .z_cm = 0},
    {.x_cm = 0, .z_cm = 80}, {.x_cm = 0, .z_cm = -80}, {.x_cm = 60, .z_cm = 60}, {.x_cm = -60, .z_cm = 60},
    {.x_cm = 60, .z_cm = -60}}};

[[nodiscard]] protocol::ErrorCode code_of(combat::CastOutcome outcome) noexcept {
    using combat::CastOutcome;
    switch (outcome) {
    case CastOutcome::kNoCaster: return protocol::ErrorCode::kNoSession;
    case CastOutcome::kDead: return protocol::ErrorCode::kDead;
    case CastOutcome::kUnknownSkill: return protocol::ErrorCode::kBadOption;
    case CastOutcome::kNotLearned: return protocol::ErrorCode::kNotLearned;
    case CastOutcome::kCooldown: return protocol::ErrorCode::kCooldown;
    case CastOutcome::kBusy: return protocol::ErrorCode::kBusy;
    case CastOutcome::kInvalidTarget:
    case CastOutcome::kTargetDead: return protocol::ErrorCode::kBadTarget;
    case CastOutcome::kOutOfRange: return protocol::ErrorCode::kOutOfRange;
    case CastOutcome::kLackMana:
    case CastOutcome::kLackHp: return protocol::ErrorCode::kNotEnoughMana;
    case CastOutcome::kLackRage:
    case CastOutcome::kLackStrike: return protocol::ErrorCode::kNotEnoughRage;
    case CastOutcome::kOk:
    case CastOutcome::kNoWeapon:
    case CastOutcome::kForbidden:
    case CastOutcome::kConditionFailed:
    case CastOutcome::kUnsupported: return protocol::ErrorCode::kCannotAttack;
    }
    return protocol::ErrorCode::kCannotAttack;
}

// Sinh lực theo phần trăm làm tròn lên: còn sống thì không bao giờ hiện 0%.
[[nodiscard]] std::uint8_t percent_of(const actor::Body& body) noexcept {
    if (!body.alive()) return 0;
    const std::int64_t most = std::max(body.stat(actor::Stat::kMaxHp), 1);
    const std::int64_t held = std::clamp<std::int64_t>(body.hp(), 0, most);
    return static_cast<std::uint8_t>(std::clamp<std::int64_t>(((held * 100) + most - 1) / most, 1, 100));
}

// Hồi sinh tại chỗ: 30% sinh lực và nội lực (số tự đặt cho bản thử; bản gốc đọc từ global.toml [revive], chưa có bộ đọc).
[[nodiscard]] actor::Revival revival_here() noexcept {
    return actor::Revival{.hp = actor::Amount{.percent = true, .value = 30},
        .mp = actor::Amount{.percent = true, .value = 30},
        .rage = actor::Amount{}};
}

[[nodiscard]] std::uint64_t amount_of(actor::Amount amount, std::uint64_t base) noexcept {
    if (!amount.percent) return static_cast<std::uint64_t>(std::max(amount.value, 0));
    const auto percent = static_cast<std::uint64_t>(std::clamp(amount.value, 0, 100));
    return base / 100U * percent + (base % 100U) * percent / 100U;
}

template <typename Message>
void tell(Surroundings& stage, Output& out, Surroundings::Place place, const Message& message, bool include_self) {
    std::vector<std::byte> frame;
    if (!protocol::encode(frame, message)) {
        ++out.encode_failures;
        return;
    }
    stage.tell(place, frame, include_self);
}

} // namespace

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): cảnh và hạt khác vai, nơi gọi nêu tên (HP-07)
Battle::Battle(const World& world, std::uint16_t scene, std::uint64_t seed)
    : world_(&world),
      scene_(scene),
      dice_(seed),
      arena_(world.combat(), dice_),
      serials_(kSerialFirst, kSerialLast),
      roller_(world.loot(), world.factory()) {
    // Đợt này chỉ có người đánh quái: người với người là bạn (chưa có PK, tổ đội, bang), người với quái là địch. Ma trận phe của
    // bảng (camp_relations) chưa dùng vì mọi người chơi cùng một phe và NPC chưa vào đấu trường.
    arena_.set_relation_policy([](const combat::Fighter& from, const combat::Fighter& to) {
        return from.kind == to.kind ? combat::Relation::kFriend : combat::Relation::kEnemy;
    });
}

Battle::~Battle() {
    // Người còn trong đấu trường khi Battle chết: trả thân thể về cho Player trước khi Fighter đi.
    for (auto& [session, who] : members_) {
        if (who.player != nullptr) who.player->unbind();
    }
}

std::vector<combat::SkillEntry> Battle::starting_skills(const Player& player) const {
    std::vector<combat::SkillEntry> skills;
    const std::int32_t sect = player.body().sect();
    // Đòn thường (skills.tsv id 0) ai cũng biết, kể cả nhân vật chưa vào môn phái; đứng đầu danh sách để client có chiêu mặc định.
    if (world_->combat().skill(kPlainAttack) != nullptr && world_->combat().level_of(kPlainAttack, 1) != nullptr) {
        skills.push_back(combat::SkillEntry{.id = kPlainAttack, .level = 1});
    }
    for (const combat::SkillTemplate& tmpl : world_->combat().skills()) {
        if (skills.size() >= combat::kMaxSkills) break;
        if (tmpl.id == kPlainAttack) continue;
        // Quy tắc tạm của bản thử: chưa có học kỹ năng ở NPC, nên cấp 1 mọi chiêu chủ động thuộc tâm pháp của môn phái.
        if (tmpl.sect != sect || tmpl.user_class != 0 || tmpl.passive || tmpl.type == combat::SkillType::kPassive) continue;
        if (tmpl.skill_class < 0 || tmpl.instance.front() == 0) continue;
        if (world_->combat().level_of(tmpl.id, 1) == nullptr) continue;
        skills.push_back(combat::SkillEntry{.id = tmpl.id, .level = 1});
    }
    return skills;
}

bool Battle::join(const Seat& seat, const Env& env) {
    if (seat.player == nullptr || members_.contains(seat.session) || by_entity_.contains(seat.entity)) return false;
    Player& player = *seat.player;
    const ids::EntityHandle handle = handle_of(seat.entity);
    combat::Fighter fighter{handle, combat::FighterKind::kHuman, player.body()};
    fighter.character = player.id().value();
    fighter.position = combat::Position{.x_cm = seat.x_cm, .z_cm = seat.z_cm};
    fighter.female = player.gender() == 0;
    // Chưa có trang bị: coi như cầm vũ khí loại 0 để đòn thường (đòi vũ khí) ra được.
    fighter.weapon_type = 0;
    fighter.skills = starting_skills(player);
    if (!arena_.add(std::move(fighter))) return false;
    combat::Fighter* placed = arena_.find(handle);
    if (placed == nullptr) return false;
    player.bind(placed->body);
    arena_.refresh(handle);
    // Lưu lúc đang chết thì vào lại là đứng dậy ở chỗ vào cảnh (bảng hồi sinh chỉ có trong phiên đã chết).
    if (!placed->body.alive()) static_cast<void>(arena_.revive(handle, revival_here()));
    arena_.clear_events();

    Member who;
    who.player = &player;
    who.entity = seat.entity;
    who.home_x_cm = seat.x_cm;
    who.home_z_cm = seat.z_cm;
    who.sent_percent = percent_of(placed->body);
    Member& kept = members_.emplace(seat.session, who).first->second;
    by_entity_.emplace(seat.entity, seat.session);
    send_skills(seat.session, kept, env);
    push_vitals(seat.session, kept, env, true);
    return true;
}

void Battle::leave(std::uint64_t session) {
    const auto found = members_.find(session);
    if (found == members_.end()) return;
    const std::uint32_t entity = found->second.entity;
    if (found->second.player != nullptr) found->second.player->unbind();
    static_cast<void>(arena_.remove(handle_of(entity)));
    by_entity_.erase(entity);
    last_skill_.erase(entity);
    members_.erase(found);
}

bool Battle::ensure_monster(const Surroundings::Unit& unit) {
    const ids::EntityHandle handle = handle_of(unit.entity);
    touched_[unit.entity] = tick_;
    if (arena_.find(handle) != nullptr) return true;
    const actor::MonsterRow* row = world_->rules().monster(unit.template_id);
    if (row == nullptr) return false;
    combat::Fighter fighter{handle, combat::FighterKind::kMonster,
        actor::Body::monster(world_->rules(), world_->body_limits(), *row)};
    fighter.position = combat::Position{.x_cm = unit.x_cm, .z_cm = unit.z_cm};
    return arena_.add(std::move(fighter)).has_value();
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): thực thể và tầm khác vai, nơi gọi nêu tên (HP-07)
void Battle::sync_positions(const Env& env, std::uint32_t entity, std::int32_t reach_cm) {
    std::vector<Surroundings::Unit> near;
    env.stage->units_near(place_of(entity), near);
    combat::Position centre{};
    for (const Surroundings::Unit& unit : near) {
        if (unit.entity == entity) centre = combat::Position{.x_cm = unit.x_cm, .z_cm = unit.z_cm};
    }
    const auto reach = static_cast<std::int64_t>(reach_cm);
    for (const Surroundings::Unit& unit : near) {
        const combat::Position at{.x_cm = unit.x_cm, .z_cm = unit.z_cm};
        if (unit.kind == protocol::EntityKind::kMonster && !unit.dead && reach > 0 &&
            combat::distance_sq_cm(centre, at) <= reach * reach) {
            static_cast<void>(ensure_monster(unit));
        }
        if (combat::Fighter* fighter = arena_.find(handle_of(unit.entity))) fighter->position = at;
    }
}

void Battle::send_skills(std::uint64_t session, const Member& who, const Env& env) {
    const combat::Fighter* fighter = arena_.find(handle_of(who.entity));
    if (fighter == nullptr) return;
    protocol::SelfSkills list;
    for (const combat::SkillEntry& entry : fighter->skills) {
        if (list.skills.size() >= kMaxSkillsSent) break;
        const combat::SkillTemplate* tmpl = world_->combat().skill(entry.id);
        const std::int64_t left = tmpl == nullptr ? 0 : arena_.cooldown_remaining(*fighter, tmpl->cooldown_id);
        protocol::SkillEntry& one = list.skills.emplace_back();
        one.skill = static_cast<std::uint16_t>(entry.id);
        one.level = entry.level;
        one.cooldown_ms = static_cast<std::uint32_t>(std::max<std::int64_t>(left, 0) * kMsPerTick);
    }
    env.out->down(session, list);
}

void Battle::push_vitals(std::uint64_t session, Member& who, const Env& env, bool force) {
    const combat::Fighter* fighter = arena_.find(handle_of(who.entity));
    if (fighter == nullptr) return;
    if (!force && tick_ - who.vitals_tick < kVitalsGapTicks) return;
    const actor::Body& body = fighter->body;
    const std::int32_t max_hp = body.stat(actor::Stat::kMaxHp);
    const std::int32_t max_mp = body.stat(actor::Stat::kMaxMp);
    const std::int32_t max_rage = body.stat(actor::Stat::kMaxRage);
    const std::uint8_t percent = percent_of(body);
    if (percent != who.sent_percent) {
        who.sent_percent = percent;
        env.stage->hurt(place_of(who.entity), percent);
    }
    if (body.hp() == who.sent_hp && body.mp() == who.sent_mp && body.rage() == who.sent_rage && max_hp == who.sent_hp_max &&
        max_mp == who.sent_mp_max && max_rage == who.sent_rage_max) {
        return;
    }
    who.sent_hp = body.hp();
    who.sent_mp = body.mp();
    who.sent_rage = body.rage();
    who.sent_hp_max = max_hp;
    who.sent_mp_max = max_mp;
    who.sent_rage_max = max_rage;
    who.vitals_tick = tick_;
    protocol::SelfVitals vitals;
    vitals.hp = who.sent_hp;
    vitals.hp_max = max_hp;
    vitals.mp = who.sent_mp;
    vitals.mp_max = max_mp;
    vitals.rage = who.sent_rage;
    vitals.rage_max = max_rage;
    env.out->down(session, vitals);
}

void Battle::cast(std::uint64_t session, const protocol::CastSkill& message, const Env& env) {
    Output& out = *env.out;
    Surroundings& stage = *env.stage;
    const auto reject = [&](protocol::ErrorCode code) { out.reject(session, protocol::CastSkill::kKind, code); };
    const auto found = members_.find(session);
    if (found == members_.end()) return reject(protocol::ErrorCode::kNoSession);
    Member& who = found->second;
    combat::Fighter* me = arena_.find(handle_of(who.entity));
    if (me == nullptr) return reject(protocol::ErrorCode::kNoSession);
    if (!me->alive()) return reject(protocol::ErrorCode::kDead);
    const combat::SkillTemplate* tmpl = world_->combat().skill(message.skill);
    if (tmpl == nullptr) return reject(protocol::ErrorCode::kBadOption);
    const std::optional<Surroundings::Unit> self = stage.unit(place_of(who.entity));
    if (!self) return reject(protocol::ErrorCode::kNoSession);

    combat::Target target;
    if (message.target != 0) {
        const std::optional<Surroundings::Unit> unit = stage.unit(place_of(message.target));
        if (!unit) return reject(protocol::ErrorCode::kNoSuchEntity);
        if (unit->dead) return reject(protocol::ErrorCode::kBadTarget);
        if (unit->kind == protocol::EntityKind::kMonster) {
            if (!ensure_monster(*unit)) return reject(protocol::ErrorCode::kCannotAttack);
        } else if (unit->kind != protocol::EntityKind::kPlayer || !by_entity_.contains(unit->entity)) {
            return reject(protocol::ErrorCode::kBadTarget);
        }
        target.unit = handle_of(unit->entity);
        target.position = combat::Position{.x_cm = unit->x_cm, .z_cm = unit->z_cm};
    } else {
        // Chiêu nhắm đất: toạ độ do client gửi, kiểm hữu hạn và trong biên trước khi đổi sang số nguyên.
        if (!std::isfinite(message.x_cm) || !std::isfinite(message.z_cm) || std::fabs(message.x_cm) > kMaxGroundCm ||
            std::fabs(message.z_cm) > kMaxGroundCm) {
            return reject(protocol::ErrorCode::kBadOption);
        }
        target.position = combat::Position{.x_cm = static_cast<std::int32_t>(std::lround(message.x_cm)),
            .z_cm = static_cast<std::int32_t>(std::lround(message.z_cm))};
    }

    const std::int32_t reach = std::clamp(std::max(tmpl->range_cm, 0) + std::max(tmpl->radius_cm, 0) + kReachSlackCm, 0, kMaxReachCm);
    sync_positions(env, who.entity, reach);
    me->position = combat::Position{.x_cm = self->x_cm, .z_cm = self->z_cm};

    const combat::CastOutcome outcome = arena_.cast(me->handle, message.skill, 0, target);
    if (outcome != combat::CastOutcome::kOk) {
        arena_.clear_events();
        return reject(code_of(outcome));
    }
    last_skill_[who.entity] = message.skill;
    std::uint8_t level = 1;
    for (const combat::SkillEntry& entry : me->skills) {
        if (entry.id == message.skill) level = entry.level;
    }
    protocol::SkillCast cast;
    cast.seq = 0;
    cast.source = who.entity;
    cast.skill = message.skill;
    cast.target = message.target;
    cast.x_cm = static_cast<float>(target.position.x_cm);
    cast.z_cm = static_cast<float>(target.position.z_cm);
    cast.level = level;
    tell(stage, out, place_of(who.entity), cast, false);
    cast.seq = message.seq;
    out.down(session, cast);

    drain(env, true);
    const std::int64_t left = arena_.cooldown_remaining(*me, tmpl->cooldown_id);
    if (left > 0) {
        out.down(session, protocol::SkillCooldown{.skill = message.skill, .ms = static_cast<std::uint32_t>(left * kMsPerTick)});
    }
    push_vitals(session, who, env, false);
    env.report->changed.push_back(session);
}

void Battle::drain(const Env& env, bool from_cast) {
    Output& out = *env.out;
    Surroundings& stage = *env.stage;
    const std::span<const combat::Event> raw = arena_.events();
    const std::vector<combat::Event> events{raw.begin(), raw.end()};
    arena_.clear_events();
    std::vector<std::uint32_t> touched;
    std::vector<combat::Event> deaths;
    for (const combat::Event& event : events) {
        const std::uint32_t source = event.actor.index;
        const std::uint32_t victim = event.target.index;
        const auto skill_of = [&](std::uint32_t entity) {
            const auto last = last_skill_.find(entity);
            return last == last_skill_.end() ? std::uint16_t{0} : last->second;
        };
        struct Figure {
            std::int32_t value = 0;
            std::uint8_t flags = 0;
        };
        const auto number = [&](protocol::CombatKind kind, Figure figure) {
            protocol::CombatEvent shown;
            shown.source = source;
            shown.target = victim;
            shown.skill = skill_of(source);
            shown.kind = kind;
            shown.value = figure.value;
            shown.flags = figure.flags;
            tell(stage, out, place_of(victim), shown, true);
        };
        switch (event.kind) {
        case combat::EventKind::kCastStarted: last_skill_[source] = static_cast<std::uint16_t>(event.id); break;
        case combat::EventKind::kDamaged:
            number(protocol::CombatKind::kDamage, Figure{.value = event.value, .flags = static_cast<std::uint8_t>((event.extra & 1) != 0 ? 1 : 0)});
            touched.push_back(victim);
            break;
        case combat::EventKind::kHealed:
            // Tự hồi theo nhịp (người hồi là chính nó, ngoài lúc ra chiêu) không hiện số bay.
            if (from_cast || event.actor != event.target) number(protocol::CombatKind::kHeal, Figure{.value = event.value, .flags = 0});
            touched.push_back(victim);
            break;
        case combat::EventKind::kMissed:
            number(event.value == static_cast<std::int32_t>(combat::MissKind::kMiss) ? protocol::CombatKind::kMiss
                                                                                       : protocol::CombatKind::kImmune,
                Figure{});
            break;
        case combat::EventKind::kCastFinished:
        case combat::EventKind::kCastInterrupted: {
            const combat::SkillTemplate* tmpl = world_->combat().skill(event.id);
            const bool interrupted = event.kind == combat::EventKind::kCastInterrupted;
            // Chiêu tức thời không có "đoạn kết": chỉ chiêu gom khí hay dẫn khí cần báo, hay bất kỳ chiêu nào bị ngắt.
            if (tmpl == nullptr || (!interrupted && tmpl->type == combat::SkillType::kInstant)) break;
            protocol::SkillCastEnd end;
            end.source = source;
            end.skill = static_cast<std::uint16_t>(event.id);
            end.interrupted = interrupted;
            tell(stage, out, place_of(source), end, true);
            break;
        }
        case combat::EventKind::kDied: deaths.push_back(event); break;
        case combat::EventKind::kManaChanged:
        case combat::EventKind::kRageChanged:
        case combat::EventKind::kStrikeChanged:
        case combat::EventKind::kImpact:
        case combat::EventKind::kBuffAdded:
        case combat::EventKind::kBuffRemoved:
        case combat::EventKind::kBuffRefused:
        case combat::EventKind::kRevived:
        case combat::EventKind::kTeleport:
        case combat::EventKind::kAggro:
        case combat::EventKind::kSpawn:
        case combat::EventKind::kMove:
        case combat::EventKind::kFriendliness:
        case combat::EventKind::kCooldownCleared:
        case combat::EventKind::kUnsupported:
        case combat::EventKind::kThreat:
        case combat::EventKind::kReliveOffered: break;
        }
    }
    // Sinh lực theo phần trăm của những thực thể vừa đổi, mỗi thực thể một lần (người chơi tự báo qua push_vitals).
    std::ranges::sort(touched);
    touched.erase(std::ranges::unique(touched).begin(), touched.end());
    for (const std::uint32_t entity : touched) {
        const combat::Fighter* fighter = arena_.find(handle_of(entity));
        if (fighter != nullptr && fighter->kind == combat::FighterKind::kMonster && fighter->alive()) {
            stage.hurt(place_of(entity), percent_of(fighter->body));
        }
    }
    for (const combat::Event& death : deaths) {
        if (by_entity_.contains(death.target.index)) {
            on_player_death(death, env);
        } else {
            on_monster_death(death, env);
        }
    }
}

void Battle::on_monster_death(const combat::Event& event, const Env& env) {
    Surroundings& stage = *env.stage;
    const std::uint32_t entity = event.target.index;
    const combat::Fighter* monster = arena_.find(event.target);
    if (monster == nullptr) return;
    const std::optional<Surroundings::Unit> unit = stage.unit(place_of(entity));
    if (unit) {
        tell(stage, *env.out, place_of(entity), protocol::EntityDied{.id = entity, .killer = event.actor.index}, true);
        stage.fell(place_of(entity));
        if (const auto killer = by_entity_.find(event.actor.index); killer != by_entity_.end()) {
            const auto member = members_.find(killer->second);
            if (member != members_.end()) reward(member->second, killer->second, *monster, *unit, env);
        }
    }
    static_cast<void>(arena_.remove(event.target));
    touched_.erase(entity);
    last_skill_.erase(entity);
}

void Battle::reward(Member& killer, std::uint64_t session, const combat::Fighter& monster, const Surroundings::Unit& unit,
    const Env& env) {
    Player& player = *killer.player;
    const actor::MonsterRow* row = monster.body.monster_row();
    if (row != nullptr) {
        const std::uint64_t exp = actor::monster_exp(world_->rules(), world_->body_limits(), player.body().level(), *row,
            player.body().stat(actor::Stat::kExpRefix));
        if (exp > 0) static_cast<void>(player.ports().exp.give(static_cast<std::int64_t>(std::min<std::uint64_t>(exp, INT64_MAX))));
    }
    if (player.take_levels_gained() > 0) {
        env.stage->promote(place_of(killer.entity), player.body().level());
        arena_.refresh(handle_of(killer.entity));
    }
    env.report->slain.push_back(Slain{.session = session, .monster = unit.template_id, .level = unit.level, .name = unit.name});
    env.report->changed.push_back(session);
    scatter_loot(killer, unit, env);
    push_vitals(session, killer, env, false);
}

void Battle::scatter_loot(const Member& killer, const Surroundings::Unit& unit, const Env& env) {
    const Player& player = *killer.player;
    const loot::Kill kill{.monster = ids::MonsterTemplateId{unit.template_id}, .level = unit.level,
        .origin = item::Origin::kMonster, .now = ids::Tick{tick_}};
    const loot::Claimant claimant{.who = player.id(), .level = player.body().level(), .wallow_ppm = loot::kPpm, .quest_items = {}};
    // Lỗi cuộn (hết serial, mẫu lạ) thì quái chết mà không rơi gì: dữ liệu hỏng không chặn được trận đánh.
    auto rolled = roller_.roll_kill(kill, std::span{&claimant, 1}, dice_, serials_);
    if (!rolled) return;
    std::size_t placed = 0;
    for (const loot::Delivered& delivered : rolled->boxes) {
        for (const std::optional<item::Instance>& slot : delivered.box.slots) {
            if (!slot || drops_.size() >= kMaxDrops) continue;
            const Offset& shift = kRing.at(placed++ % kRing.size());
            const std::optional<std::uint32_t> entity = env.stage->drop(scene_,
                Surroundings::DropSpot{.item_template = slot->tmpl.value(), .x_cm = unit.x_cm + shift.x_cm, .z_cm = unit.z_cm + shift.z_cm});
            if (!entity) continue;
            drops_[*entity] = Loose{.tmpl = slot->tmpl, .count = slot->count, .bound = slot->bound, .owner = delivered.box.owner,
                .expires_at = delivered.box.expires_at, .public_from = delivered.box.public_from};
        }
    }
}

void Battle::on_player_death(const combat::Event& event, const Env& env) {
    Surroundings& stage = *env.stage;
    const std::uint32_t entity = event.target.index;
    const auto owner = by_entity_.find(entity);
    if (owner == by_entity_.end()) return;
    const std::uint64_t session = owner->second;
    Member& who = members_.at(session);
    Player& player = *who.player;
    // Người quanh nhận EntityDied ngay; chính người chết nhận sau DeathNotice và SelfVitals (hp 0) để client dựng bảng hồi sinh
    // đúng thứ tự (cả ba cùng nằm trong Output nên giữ nguyên thứ tự).
    const protocol::EntityDied died{.id = entity, .killer = event.actor.index};
    tell(stage, *env.out, place_of(entity), died, false);
    stage.fell(place_of(entity));

    protocol::DeathNotice notice;
    const std::uint32_t id = actor::penalty_id(0, player.body().level(), 0, actor::DieType::kMonster);
    if (const std::optional<actor::PenaltyOutcome> penalty = actor::roll_penalty(world_->rules(), id, dice_)) {
        notice.exp_lost = player.body().lose_exp(penalty->exp);
        const std::uint64_t money = amount_of(penalty->money, player.money());
        if (money > 0 && player.ports().wallet.take(static_cast<std::int64_t>(std::min<std::uint64_t>(money, INT64_MAX)), false)) {
            notice.money_lost = money;
        }
    }
    env.out->down(session, notice);
    push_vitals(session, who, env, true);
    env.out->down(session, died);
    env.report->changed.push_back(session);
}

void Battle::respawn(std::uint64_t session, const protocol::Respawn& message, const Env& env) {
    Output& out = *env.out;
    const auto reject = [&](protocol::ErrorCode code) { out.reject(session, protocol::Respawn::kKind, code); };
    const auto found = members_.find(session);
    if (found == members_.end()) return reject(protocol::ErrorCode::kNoSession);
    Member& who = found->second;
    combat::Fighter* me = arena_.find(handle_of(who.entity));
    if (me == nullptr) return reject(protocol::ErrorCode::kNoSession);
    if (me->alive()) return reject(protocol::ErrorCode::kNotDead);
    std::int32_t x_cm = me->position.x_cm;
    std::int32_t z_cm = me->position.z_cm;
    if (message.place == protocol::RespawnPlace::kTown) {
        x_cm = who.home_x_cm;
        z_cm = who.home_z_cm;
    }
    if (!arena_.revive(me->handle, revival_here())) return reject(protocol::ErrorCode::kNotDead);
    arena_.clear_events();
    me->position = combat::Position{.x_cm = x_cm, .z_cm = z_cm};
    who.sent_percent = percent_of(me->body);
    env.stage->raise(place_of(who.entity), x_cm, z_cm, who.sent_percent);
    push_vitals(session, who, env, true);
    // Position đi sau SelfVitals (hp > 0): client coi hp <= 0 là đang chết.
    out.place(session, x_cm, z_cm);
    env.report->changed.push_back(session);
}

void Battle::pick_up(std::uint64_t session, const protocol::PickUp& message, const Env& env) {
    Output& out = *env.out;
    Surroundings& stage = *env.stage;
    const auto reject = [&](protocol::ErrorCode code) { out.reject(session, protocol::PickUp::kKind, code); };
    const auto found = members_.find(session);
    if (found == members_.end()) return reject(protocol::ErrorCode::kNoSession);
    const Member& who = found->second;
    const combat::Fighter* me = arena_.find(handle_of(who.entity));
    if (me == nullptr) return reject(protocol::ErrorCode::kNoSession);
    if (!me->alive()) return reject(protocol::ErrorCode::kDead);
    const auto drop = drops_.find(message.drop);
    if (drop == drops_.end()) return reject(protocol::ErrorCode::kNoSuchEntity);
    const Loose& loose = drop->second;
    const ids::Tick now{tick_};
    Player& player = *who.player;
    if (now >= loose.expires_at) {
        stage.sweep(place_of(message.drop));
        drops_.erase(drop);
        return reject(protocol::ErrorCode::kNoSuchEntity);
    }
    const bool mine = !loose.owner || *loose.owner == player.id() || (loose.public_from && now >= *loose.public_from);
    if (!mine) return reject(protocol::ErrorCode::kNotYours);
    const std::optional<Surroundings::Unit> there = stage.unit(place_of(message.drop));
    const std::optional<Surroundings::Unit> here = stage.unit(place_of(who.entity));
    if (!there || !here) {
        if (!there) drops_.erase(drop);
        return reject(protocol::ErrorCode::kNoSuchEntity);
    }
    const combat::Position from{.x_cm = here->x_cm, .z_cm = here->z_cm};
    const combat::Position to{.x_cm = there->x_cm, .z_cm = there->z_cm};
    if (combat::distance_sq_cm(from, to) > static_cast<std::int64_t>(kPickRangeCm) * kPickRangeCm) {
        return reject(protocol::ErrorCode::kTooFar);
    }
    const item::Template* tmpl = world_->items().find(loose.tmpl);
    if (tmpl == nullptr) {
        stage.sweep(place_of(message.drop));
        drops_.erase(drop);
        return reject(protocol::ErrorCode::kNoSuchEntity);
    }
    const ledger::Stack stack{.item = loose.tmpl.value(), .count = loose.count, .bound = loose.bound || tmpl->rule.pick_bind};
    ledger::ItemPort& bag = player.ports().items;
    if (!bag.fits({}, std::span{&stack, 1}) || !bag.give(stack.item, stack.count, stack.bound)) {
        return reject(protocol::ErrorCode::kBagFull);
    }
    stage.sweep(place_of(message.drop));
    drops_.erase(drop);
    env.report->picked.push_back(Picked{.session = session, .item = stack.item});
    env.report->changed.push_back(session);
}

void Battle::step(const Env& env) {
    ++tick_;
    if (members_.empty()) {
        // Cảnh vắng: đấu trường đứng yên, nhưng vật rơi vẫn hết hạn.
        std::erase_if(drops_, [&](const auto& entry) {
            if (ids::Tick{tick_} < entry.second.expires_at) return false;
            env.stage->sweep(place_of(entry.first));
            return true;
        });
        return;
    }
    arena_.tick();
    drain(env, false);
    std::erase_if(drops_, [&](const auto& entry) {
        if (ids::Tick{tick_} < entry.second.expires_at) return false;
        env.stage->sweep(place_of(entry.first));
        return true;
    });
    for (auto& [session, who] : members_) push_vitals(session, who, env, false);
    if (tick_ % kPruneEveryTicks == 0) prune();
}

void Battle::prune() {
    for (const ids::EntityHandle handle : arena_.handles()) {
        const combat::Fighter* fighter = arena_.find(handle);
        if (fighter == nullptr || fighter->kind != combat::FighterKind::kMonster) continue;
        const auto seen = touched_.find(handle.index);
        const bool idle = seen == touched_.end() || tick_ - seen->second >= kPruneIdleTicks;
        const bool whole = fighter->body.hp() >= fighter->body.stat(actor::Stat::kMaxHp);
        if (!idle || !whole || fighter->buff_count != 0) continue;
        static_cast<void>(arena_.remove(handle));
        touched_.erase(handle.index);
        last_skill_.erase(handle.index);
    }
}

} // namespace game::play
