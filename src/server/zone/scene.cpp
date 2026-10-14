#include "zone/scene.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <cmath>
#include <numbers>
#include <utility>

namespace game::zone {
namespace {

constexpr float kMinStepCm = 1.0F;
constexpr float kTurn = 65536.0F;

[[nodiscard]] float clamp_cm(float value) noexcept {
    if (std::isnan(value)) return 0.0F;
    return std::clamp(value, -Grid::kCoordLimitCm, Grid::kCoordLimitCm);
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

Scene::Scene(Config config) : config_(config), grid_(config.grid) {
    core::check(config.player_max <= kEntityMax, "player_max vượt trần thực thể của cảnh");
}

std::optional<std::uint32_t> Scene::allocate() {
    if (!free_.empty()) {
        const std::uint32_t index = free_.back();
        free_.pop_back();
        return index;
    }
    if (entities_.size() >= kEntityMax) return std::nullopt;
    entities_.emplace_back();
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
    return out;
}

void Scene::broadcast(Cell around, std::uint32_t skip, const std::vector<std::byte>& frame, Outbox& out) const {
    grid_.for_each_in_window(around, [&](std::uint32_t index) {
        if (index == skip) return;
        const Entity& viewer = entities_[index];
        if (viewer.session != 0) out.down_frame(viewer.session, frame);
    });
}

void Scene::show_neighbours(std::uint32_t viewer, Cell around, Outbox& out) const {
    const std::uint64_t session = entities_[viewer].session;
    grid_.for_each_in_window(around, [&](std::uint32_t index) {
        if (index != viewer) out.down(session, appear_of(index));
    });
}

void Scene::enter_grid(std::uint32_t index, Outbox& out) {
    Entity& who = entities_[index];
    who.cell = grid_.cell_of(who.x_cm, who.z_cm);
    const std::vector<std::byte> shown = out.frame_of(appear_of(index));
    broadcast(who.cell, index, shown, out);
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
        .z_cm = static_cast<std::int32_t>(std::lround(who.z_cm))});
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
    relocate(found->second, step.x_cm, step.z_cm, out);
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
    enter_grid(index, out);
    return id_at(index);
}

void Scene::despawn(std::uint32_t id, Outbox& out) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index || entities_[*index].session != 0) return;
    remove(*index, out);
}

void Scene::move_entity(std::uint32_t id, float x_cm, float z_cm, Outbox& out) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index || entities_[*index].session != 0) return;
    relocate(*index, x_cm, z_cm, out);
}

void Scene::set_hp_percent(std::uint32_t id, std::uint8_t percent, Outbox& out) {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return;
    Entity& who = entities_[*index];
    const std::uint8_t clamped = std::min<std::uint8_t>(percent, 100);
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

void Scene::relocate(std::uint32_t index, float x_cm, float z_cm, Outbox& out) {
    Entity& who = entities_[index];
    const float target_x = clamp_cm(x_cm);
    const float target_z = clamp_cm(z_cm);
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
    const std::vector<std::byte> moving = out.frame_of(pos);
    if (before == after) {
        broadcast(after, index, moving, out);
        return;
    }
    const std::vector<std::byte> shown = out.frame_of(appear_of(index));
    protocol::EntityDisappear gone;
    gone.id = id;
    const std::vector<std::byte> hidden = out.frame_of(gone);
    // Người thấy tôi cả trước lẫn sau chỉ nhận vị trí; người mới thấy nhận hiện ra.
    grid_.for_each_in_window(after, [&](std::uint32_t other) {
        if (other == index) return;
        const Entity& viewer = entities_[other];
        if (viewer.session == 0) return;
        out.down_frame(viewer.session, grid_.sees(before, viewer.cell) ? moving : shown);
    });
    grid_.for_each_left(before, after, [&](std::uint32_t other) {
        const Entity& viewer = entities_[other];
        if (other != index && viewer.session != 0) out.down_frame(viewer.session, hidden);
    });
    if (who.session != 0) {
        grid_.for_each_entered(before, after, [&](std::uint32_t other) {
            out.down(who.session, appear_of(other));
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
    who.dirty = false;
    who.live = false;
    who.name.clear();
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

std::optional<Scene::Where> Scene::where(std::uint32_t id) const noexcept {
    const std::optional<std::uint32_t> index = index_of(id);
    if (!index) return std::nullopt;
    const Entity& who = entities_[*index];
    return Where{.x_cm = who.x_cm, .z_cm = who.z_cm, .direction = who.direction};
}

} // namespace game::zone
