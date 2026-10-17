/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/scene.cpp
 *  PHÂN HỆ   : Server / Zone / Scene
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt Scene: bảng thực thể, lưới vùng nhìn, báo hiện, ẩn, di chuyển,
 *    dừng và sinh lực cho người đang nhìn.
 *  - Thuần: không I/O, không đồng hồ thật, không ngẫu nhiên; thứ tự duyệt cố
 *    định để kết quả tất định.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/scene.hpp"

#include "core/check.hpp"
#include "ipc/relay.hpp"
#include "protocol/messages.hpp"
#include "zone/aoi.hpp"
#include "zone/gates.hpp"
#include "zone/outbox.hpp"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <numbers>
#include <optional>
#include <utility>
#include <vector>

namespace game::zone {
namespace {

constexpr float kMinStepCm = 1.0F;

bool motion_due(std::uint32_t sent, std::uint32_t tick, std::uint32_t stride) noexcept {
    if (sent == kNeverSent || sent == tick) return true;
    return tick - sent >= stride;
}
constexpr float kTurn = 65536.0F;

[[nodiscard]] float clamp_cm(float value) noexcept {
    if (std::isnan(value)) return 0.0F;
    return std::clamp(value, -Grid::kCoordLimitCm, Grid::kCoordLimitCm);
}

[[nodiscard]] std::uint32_t respawn_ticks(std::int32_t respawn_ms, std::int64_t hz) noexcept {
    const std::int32_t wait = respawn_ms > 0 ? respawn_ms : kDefaultRespawnMs;
    const std::int64_t wait_ms = wait;
    const ids::TickSpan span = ids::to_ticks(wait_ms, hz);
    return static_cast<std::uint32_t>(span.count);
}

struct RespawnSlot {
    std::unordered_map<std::uint32_t, Spawn>& homes;
    std::multimap<std::uint32_t, Spawn>& respawns;
};

void schedule_respawn(RespawnSlot& slot, std::uint32_t index, std::uint32_t tick, std::int64_t hz) {
    const auto home = slot.homes.find(index);
    if (home == slot.homes.end()) return;
    const std::uint32_t ticks = respawn_ticks(home->second.respawn_ms, hz);
    slot.respawns.emplace(tick + ticks, std::move(home->second));
    slot.homes.erase(home);
}

} // namespace

std::uint16_t direction_of(Delta step, std::uint16_t keep) noexcept {
    if (!std::isfinite(step.x_cm) || !std::isfinite(step.z_cm)) return keep;
    if ((step.x_cm * step.x_cm) + (step.z_cm * step.z_cm) < kMinStepCm * kMinStepCm) return keep;
    float angle = std::atan2(step.z_cm, step.x_cm);
    if (angle < 0.0F) angle += 2.0F * std::numbers::pi_v<float>;
    const float scaled = angle / (2.0F * std::numbers::pi_v<float>) * kTurn;
    // 2π làm tròn lên đúng 65536: quấn về 0 thay vì tràn u16.
    return static_cast<std::uint16_t>(static_cast<std::uint32_t>(scaled) & 0xFFFFU);
}

// Hạt giống ngẫu nhiên của cảnh: mỗi cảnh một dòng riêng, cùng id cho cùng dòng (phát lại được).
constexpr std::uint64_t kSeedBase = 0x5A17'E000'0000'0000ULL;

Scene::Scene(Config config)
    : config_(std::move(config)),
      grid_(config_.grid),
      rate_(rate_of(config_.hz)),
      rng_(kSeedBase + config_.id) {
    core::check(accepted_hz(config_.hz), "hz cảnh phải là 20, 30 hoặc 40");
    core::check(config_.player_max <= kEntityMax, "player_max vượt trần thực thể của cảnh");
}

std::optional<std::uint32_t> Scene::allocate() {
    if (!free_.empty()) {
        const std::uint32_t index = free_.back();
        free_.pop_back();
        return index;
    }
    if (entities_.size() >= kEntityMax) return std::nullopt;
    entities_.emplace_back();
    minds_.emplace_back();
    return static_cast<std::uint32_t>(entities_.size() - 1);
}

std::uint32_t Scene::id_at(std::uint32_t index) const noexcept { return id_of(index, entities_[index].generation); }

std::optional<std::uint32_t> Scene::index_of(std::uint32_t id) const noexcept {
    const std::uint32_t slot = id & 0xFFFFU;
    if (slot == 0 || slot > entities_.size()) return std::nullopt;
    const std::uint32_t index = slot - 1U;
    const Entity& who = entities_[index];
    if (!who.live || who.generation != (id >> 16U)) return std::nullopt;
    return index;
}

protocol::EntityAppear Scene::appear_of(std::uint32_t index) const {
    const Entity& who = entities_[index];
    protocol::EntityAppear out;
    out.id = id_at(index);
    out.kind = who.kind;
    out.template_id = who.template_id;
    out.name = who.name;
    out.level = who.level;
    out.x_cm = who.x_cm;
    out.z_cm = who.z_cm;
    out.direction = who.direction;
    out.speed_cm = who.speed_cm;
    out.hp_percent = who.hp_percent;
    out.gender = who.gender;
    out.face = who.face;
    out.hair = who.hair;
    out.school = who.school;
    out.state = who.state;
    return out;
}

std::vector<std::byte> Scene::flags_frame(std::uint32_t index, Outbox& out) const {
    const Entity& who = entities_[index];
    if (who.flags == 0) return {};
    return out.frame_of(protocol::EntityFlags{.id = id_at(index), .flags = who.flags});
}

void Scene::show_to(std::uint64_t session, std::uint32_t index, Outbox& out) const {
    out.down(session, appear_of(index));
    out.down_frame(session, flags_frame(index, out));
}

void Scene::broadcast(Cell around, std::uint32_t skip, const std::vector<std::byte>& frame,
    Outbox& out) const {
    grid_.for_each_in_window(around, [&](std::uint32_t index) {
        if (index == skip) return;
        const Entity& viewer = entities_[index];
        if (viewer.session != 0) out.down_frame(viewer.session, frame);
    });
}

void Scene::broadcast_pos(Cell around, std::uint32_t skip, const protocol::EntityPos& pos,
    Outbox& out) const {
    const Outbox::PosBlob blob = out.blob(pos);
    grid_.for_each_in_window(around, [&](std::uint32_t index) {
        if (index == skip) return;
        const Entity& viewer = entities_[index];
        if (viewer.session != 0) out.stage_blob(viewer.session, blob);
    });
}

void Scene::give_position(PosGate& gate, std::uint32_t self, std::uint32_t other, Cell at,
    const Outbox::PosBlob& blob, Outbox& out) {
    if (other == self) return;
    const Entity& viewer = entities_[other];
    if (viewer.session == 0) return;
    const bool near = grid_.rings(at, viewer.cell) <= 1;
    if (near && !gate.near_ok) return;
    if (!near && !gate.far_ok) return;
    out.stage_blob(viewer.session, blob);
    if (near) gate.sent_near = true;
    if (!near) gate.sent_far = true;
}

void Scene::fan_position(std::uint32_t index, Cell around, const protocol::EntityPos& pos,
    Outbox& out) {
    Entity& who = entities_[index];
    PosGate gate;
    gate.near_ok = motion_due(who.near_pos_tick, tick_, rate_.near_stride);
    gate.far_ok = motion_due(who.far_pos_tick, tick_, rate_.far_stride);
    if (!gate.near_ok && !gate.far_ok) return;
    const Outbox::PosBlob blob = out.blob(pos);
    grid_.for_each_in_window(around,
        [&](std::uint32_t other) { give_position(gate, index, other, around, blob, out); });
    if (gate.sent_near) who.near_pos_tick = tick_;
    if (gate.sent_far) who.far_pos_tick = tick_;
}

void Scene::show_neighbours(std::uint32_t viewer, Cell around, Outbox& out) const {
    const std::uint64_t session = entities_[viewer].session;
    grid_.for_each_in_window(around, [&](std::uint32_t index) {
        if (index != viewer) show_to(session, index, out);
    });
}

void Scene::enter_grid(std::uint32_t index, Outbox& out) {
    Entity& who = entities_[index];
    who.cell = grid_.cell_of(who.x_cm, who.z_cm);
    const std::vector<std::byte> shown = out.frame_of(appear_of(index));
    broadcast(who.cell, index, shown, out);
    broadcast(who.cell, index, flags_frame(index, out), out);
    grid_.insert(index, who.cell);
    ++live_;
}

std::optional<protocol::ErrorCode> Scene::attach(std::uint64_t session, const ipc::Attach& arrival, Outbox& out) {
    // Phiên đã có (gate gửi Attach hai lần) hay nhân vật đang đứng qua phiên khác: bỏ phiên cũ trước.
    if (const auto same = players_.find(session); same != players_.end()) remove(same->second, out);
    if (const auto twin = by_character_.find(arrival.character); twin != by_character_.end()) {
        out.close(entities_[twin->second].session, protocol::DisconnectReason::kLoginElsewhere);
        remove(twin->second, out);
    }
    if (players_.size() >= config_.player_max) return protocol::ErrorCode::kServerFull;
    const std::optional<std::uint32_t> slot = allocate();
    if (!slot) return protocol::ErrorCode::kServerFull;
    const std::uint32_t index = *slot;
    Entity& who = entities_[index];
    const std::uint16_t generation = who.generation;
    who = Entity{};
    who.live = true;
    who.generation = generation;
    who.kind = protocol::EntityKind::kPlayer;
    who.name = arrival.name;
    who.level = arrival.level;
    who.x_cm = clamp_cm(arrival.x_cm);
    who.z_cm = clamp_cm(arrival.z_cm);
    who.direction = arrival.direction;
    who.speed_cm = kPlayerSpeedCm;
    who.gender = arrival.gender;
    who.face = arrival.face;
    who.hair = arrival.hair;
    who.school = arrival.school;
    who.session = session;
    who.character = arrival.character;
    players_[session] = index;
    by_character_[arrival.character] = index;

    protocol::SceneEnter entered;
    entered.scene = config_.id;
    entered.x_cm = who.x_cm;
    entered.z_cm = who.z_cm;
    entered.direction = who.direction;
    entered.self_id = id_at(index);
    out.down(session, entered);
    enter_grid(index, out);
    show_neighbours(index, entities_[index].cell, out);
    return std::nullopt;
}

void Scene::save_spot(const Entity& who, Outbox& out) const {
    // clamp_cm đã giữ toạ độ trong ±1e7, nên lround không tràn int32.
    out.save(Save{.character = who.character,
        .scene = config_.id,
        .x_cm = static_cast<std::int32_t>(std::lround(who.x_cm)),
        .z_cm = static_cast<std::int32_t>(std::lround(who.z_cm)),
        .play = std::nullopt});
}

void Scene::autosave(Outbox& out) {
    for (Entity& who : entities_) {
        if (!who.live || who.session == 0 || !who.dirty) continue;
        who.dirty = false;
        save_spot(who, out);
    }
}

void Scene::moved(std::uint64_t session, const ipc::Moved& step, Outbox& out) {
    const auto found = players_.find(session);
    if (found == players_.end()) return;
    const Entity& who = entities_[found->second];
    // Người đã chết nằm yên: bước nào cũng bị kéo về chỗ nằm.
    if (who.state == protocol::EntityState::kDead || blocked(who, step)) {
        out.place(session, who.x_cm, who.z_cm);
        return;
    }
    relocate(found->second, Point{.x_cm = step.x_cm, .z_cm = step.z_cm}, out);
}

bool Scene::blocked(const Entity& who, const ipc::Moved& step) const {
    if (!config_.walkable) return false;
    // Phần lớn bước đi vào chỗ đi được: chỉ một lần tra. Tra chỗ đứng cũ chỉ khi bước mới không đi được.
    if (config_.walkable(step.x_cm, step.z_cm)) return false;
    return config_.walkable(who.x_cm, who.z_cm);
}

void Scene::detach(std::uint64_t session, Outbox& out) {
    const auto found = players_.find(session);
    if (found == players_.end()) return;
    remove(found->second, out);
}

std::optional<std::uint32_t> Scene::spawn(const Spawn& what, Outbox& out) {
    if (what.kind == protocol::EntityKind::kPlayer) return std::nullopt;
    const std::optional<std::uint32_t> slot = allocate();
    if (!slot) return std::nullopt;
    const std::uint32_t index = *slot;
    Entity& who = entities_[index];
    const std::uint16_t generation = who.generation;
    who = Entity{};
    who.live = true;
    who.generation = generation;
    who.kind = what.kind;
    who.template_id = what.template_id;
    who.name = what.name;
    who.level = what.level;
    who.x_cm = clamp_cm(what.x_cm);
    who.z_cm = clamp_cm(what.z_cm);
    who.direction = what.direction;
    who.speed_cm = what.speed_cm;
    who.hp_percent = std::min<std::uint8_t>(what.hp_percent, 100);
    who.script = what.script;
    who.flags = what.flags;
    who.guid = what.guid;
    if (what.kind == protocol::EntityKind::kMonster && what.respawn_ms >= 0) homes_[index] = what;
    enter_grid(index, out);
    if (what.nature) start_thinking(index, *what.nature);
    return id_at(index);
}

void Scene::despawn(std::uint32_t id, Outbox& out) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index || entities_[*index].session != 0) return;
    remove(*index, out);
}

void Scene::move_entity(std::uint32_t id, Point to, Outbox& out) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index || entities_[*index].session != 0) return;
    relocate(*index, to, out);
}

void Scene::set_hp_percent(HpChange change, Outbox& out) {
    const std::uint32_t id = change.id;
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return;
    Entity& who = entities_[*index];
    const std::uint8_t clamped = std::min<std::uint8_t>(change.percent, 100);
    if (who.hp_percent == clamped) return;
    who.hp_percent = clamped;
    protocol::EntityVitals vitals;
    vitals.id = id;
    vitals.hp_percent = clamped;
    const std::vector<std::byte> frame = out.frame_of(vitals);
    broadcast(who.cell, *index, frame, out);
    // Người chơi cũng cần thấy sinh lực của chính mình đổi.
    if (who.session != 0) out.down_frame(who.session, frame);
}

void Scene::kill(std::uint32_t id) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return;
    Entity& who = entities_[*index];
    if (who.state == protocol::EntityState::kDead) return;
    stop_walking(*index);
    stop_thinking(*index);
    who.state = protocol::EntityState::kDead;
    who.hp_percent = 0;
    if (who.session == 0) corpses_.emplace(tick_ + rate_.corpse_ticks, id);
}

void Scene::revive(std::uint32_t id, Point at, std::uint8_t hp_percent, Outbox& out) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return;
    Entity& who = entities_[*index];
    if (who.session == 0 || who.state != protocol::EntityState::kDead) return;
    who.state = protocol::EntityState::kIdle;
    who.hp_percent = std::clamp<std::uint8_t>(hp_percent, 1, 100);
    relocate(*index, at, out);
    protocol::EntityVitals vitals;
    vitals.id = id;
    vitals.hp_percent = who.hp_percent;
    tell_near(id, out.frame_of(vitals), true, out);
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): id thực thể và cấp khác vai, nơi gọi nêu tên (HP-07)
void Scene::set_level(std::uint32_t id, std::uint16_t level) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (index) entities_[*index].level = level;
}

std::optional<Info> Scene::info_at(std::uint32_t index, bool with_name) const {
    const Entity& who = entities_[index];
    return Info{.kind = who.kind,
        .template_id = who.template_id,
        .level = who.level,
        .x_cm = who.x_cm,
        .z_cm = who.z_cm,
        .hp_percent = who.hp_percent,
        .state = who.state,
        .session = who.session,
        .name = with_name ? who.name : std::string{}};
}

std::optional<Info> Scene::info(std::uint32_t id) const {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return std::nullopt;
    return info_at(*index, true);
}

void Scene::for_each_near(std::uint32_t id, const std::function<void(std::uint32_t, const Info&)>& visit) const {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return;
    grid_.for_each_in_window(entities_[*index].cell, [&](std::uint32_t other) {
        const std::optional<Info> seen = info_at(other, false);
        if (seen) visit(id_at(other), *seen);
    });
}

void Scene::tell_near(std::uint32_t id, const std::vector<std::byte>& frame, bool include_self, Outbox& out) const {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return;
    broadcast(entities_[*index].cell, include_self ? kNoSlot : *index, frame, out);
}

void Scene::tidy_corpses(Outbox& out) {
    while (!corpses_.empty() && corpses_.begin()->first <= tick_) {
        const std::uint32_t id = corpses_.begin()->second;
        corpses_.erase(corpses_.begin());
        const std::optional<std::uint32_t> index = index_of(id);
        if (!index) continue;
        RespawnSlot slot{.homes = homes_, .respawns = respawns_};
        schedule_respawn(slot, *index, tick_, rate_.hz);
        remove(*index, out);
    }
    while (!respawns_.empty() && respawns_.begin()->first <= tick_) {
        const Spawn again = std::move(respawns_.begin()->second);
        respawns_.erase(respawns_.begin());
        static_cast<void>(spawn(again, out));
    }
}

void Scene::start_walking(std::uint32_t index) {
    Entity& who = entities_[index];
    who.state = protocol::EntityState::kWalk;
    if (who.moving_slot != kNotMoving) return;
    who.moving_slot = static_cast<std::uint32_t>(moving_.size());
    moving_.push_back(index);
}

void Scene::stop_walking(std::uint32_t index) {
    Entity& who = entities_[index];
    who.state = protocol::EntityState::kIdle;
    if (who.moving_slot == kNotMoving) return;
    const std::uint32_t last = moving_.back();
    moving_[who.moving_slot] = last;
    entities_[last].moving_slot = who.moving_slot;
    moving_.pop_back();
    who.moving_slot = kNotMoving;
}

void Scene::advance(Outbox& out) {
    ++tick_;
    tidy_corpses(out);
    think(out);
    // Duyệt ngược: stop_walking chép phần tử cuối vào chỗ vừa xoá, mà phần tử cuối đã được xét.
    for (std::size_t at = moving_.size(); at > 0; --at) {
        const std::uint32_t index = moving_[at - 1];
        const Entity& who = entities_[index];
        if (tick_ - who.moved_at < rate_.idle_after) continue;
        stop_walking(index);
        protocol::EntityPos rest;
        rest.id = id_at(index);
        rest.x_cm = who.x_cm;
        rest.z_cm = who.z_cm;
        rest.direction = who.direction;
        rest.tick = tick_;
        rest.state = protocol::EntityState::kIdle;
        broadcast_pos(who.cell, index, rest, out);
    }
}

void Scene::relocate(std::uint32_t index, Point to, Outbox& out) {
    Entity& who = entities_[index];
    const float target_x = clamp_cm(to.x_cm);
    const float target_z = clamp_cm(to.z_cm);
    who.direction = direction_of(Delta{.x_cm = target_x - who.x_cm, .z_cm = target_z - who.z_cm}, who.direction);
    who.x_cm = target_x;
    who.z_cm = target_z;
    who.dirty = true;
    const Cell before = who.cell;
    const Cell after = grid_.cell_of(target_x, target_z);
    const std::uint32_t id = id_at(index);

    protocol::EntityPos pos;
    pos.id = id;
    pos.x_cm = target_x;
    pos.z_cm = target_z;
    pos.direction = who.direction;
    pos.tick = tick_;
    pos.state = protocol::EntityState::kWalk;
    start_walking(index);
    who.moved_at = tick_;
    if (before == after) {
        fan_position(index, after, pos, out);
        return;
    }
    const std::vector<std::byte> shown = out.frame_of(appear_of(index));
    protocol::EntityDisappear gone;
    gone.id = id;
    const std::vector<std::byte> hidden = out.frame_of(gone);
    const std::vector<std::byte> marked = flags_frame(index, out);
    PosGate gate;
    gate.near_ok = motion_due(who.near_pos_tick, tick_, rate_.near_stride);
    gate.far_ok = motion_due(who.far_pos_tick, tick_, rate_.far_stride);
    const Outbox::PosBlob blob = out.blob(pos);
    // Người thấy tôi cả trước lẫn sau chỉ nhận vị trí; người mới thấy nhận hiện ra.
    grid_.for_each_in_window(after, [&](std::uint32_t other) {
        if (other == index) return;
        const Entity& viewer = entities_[other];
        if (viewer.session == 0) return;
        const bool kept = grid_.sees(before, viewer.cell);
        if (!kept) out.down_frame(viewer.session, shown);
        if (!kept) out.down_frame(viewer.session, marked);
        if (kept) give_position(gate, index, other, after, blob, out);
    });
    if (gate.sent_near) who.near_pos_tick = tick_;
    if (gate.sent_far) who.far_pos_tick = tick_;
    grid_.for_each_left(before, after, [&](std::uint32_t other) {
        const Entity& viewer = entities_[other];
        if (other != index && viewer.session != 0) out.down_frame(viewer.session, hidden);
    });
    if (who.session != 0) {
        grid_.for_each_entered(before, after, [&](std::uint32_t other) {
            show_to(who.session, other, out);
        });
        grid_.for_each_left(before, after, [&](std::uint32_t other) {
            if (other == index) return;
            protocol::EntityDisappear lost;
            lost.id = id_at(other);
            out.down(who.session, lost);
        });
    }
    grid_.erase(index, before);
    grid_.insert(index, after);
    who.cell = after;
}

void Scene::remove(std::uint32_t index, Outbox& out) {
    Entity& who = entities_[index];
    protocol::EntityDisappear gone;
    gone.id = id_at(index);
    const std::vector<std::byte> hidden = out.frame_of(gone);
    grid_.erase(index, who.cell);
    broadcast(who.cell, index, hidden, out);
    if (who.session != 0) {
        save_spot(who, out);
        players_.erase(who.session);
        by_character_.erase(who.character);
    }
    stop_walking(index);
    stop_thinking(index);
    homes_.erase(index);
    who.dirty = false;
    who.live = false;
    who.name.clear();
    who.script = 0;
    who.flags = 0;
    who.guid = 0;
    who.session = 0;
    who.character = 0;
    // Thế hệ quấn sau 65536 lần cấp lại cùng ô; id vẫn khác 0 vì phần chỉ số cộng 1.
    who.generation = static_cast<std::uint16_t>(who.generation + 1U);
    free_.push_back(index);
    --live_;
}

std::optional<std::uint32_t> Scene::entity_of(std::uint64_t session) const noexcept {
    const auto found = players_.find(session);
    if (found == players_.end()) return std::nullopt;
    return id_at(found->second);
}

bool Scene::can_admit() const noexcept {
    return players_.size() < config_.player_max && live_ < kEntityMax;
}

AreaStand Scene::standing(float x_cm, float z_cm) const noexcept {
    return area_stand(config_.areas, x_cm * kGameUnitsPerCm, z_cm * kGameUnitsPerCm);
}

std::optional<Scene::PlayerCard> Scene::player_card(std::uint64_t session) const {
    const auto found = players_.find(session);
    if (found == players_.end()) return std::nullopt;
    const Entity& who = entities_[found->second];
    PlayerCard card;
    card.character = who.character;
    card.name = who.name;
    card.level = who.level;
    card.gender = who.gender;
    card.face = who.face;
    card.hair = who.hair;
    card.school = who.school;
    card.direction = who.direction;
    card.state = who.state;
    card.x_cm = who.x_cm;
    card.z_cm = who.z_cm;
    return card;
}

void Scene::keep_spot(std::uint64_t session, Outbox& out) const {
    const auto found = players_.find(session);
    if (found == players_.end()) return;
    save_spot(entities_[found->second], out);
}

std::optional<Scene::Npc> Scene::npc(std::uint32_t id) const {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return std::nullopt;
    const Entity& who = entities_[*index];
    if (who.kind != protocol::EntityKind::kNpc || who.script == 0 || (who.flags & 1U) == 0) return std::nullopt;
    return Npc{.guid = who.guid,
        .script = who.script,
        .name = who.name,
        .at = Where{.x_cm = who.x_cm, .z_cm = who.z_cm, .direction = who.direction}};
}

std::optional<Scene::Where> Scene::where(std::uint32_t id) const noexcept {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return std::nullopt;
    const Entity& who = entities_[*index];
    return Where{.x_cm = who.x_cm, .z_cm = who.z_cm, .direction = who.direction};
}

} // namespace game::zone
