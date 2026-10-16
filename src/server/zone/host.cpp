/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/host.cpp
 *  PHÂN HỆ   : Server / Zone / Host
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt Host: nhận khung ipc của gate, chọn hoặc tạo cảnh theo id, chuyển
 *    Attach, Detach, Moved vào Scene.
 *  - Cảnh tạo lười lúc có người đầu tiên vào; trần scene_max chặn Attach với id
 *    lạ làm phình bộ nhớ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "zone/host.hpp"

#include "ipc/link.hpp"
#include "ipc/relay.hpp"
#include "play/gameplay.hpp"
#include "play/stage.hpp"
#include "protocol/messages.hpp"
#include "zone/content.hpp"
#include "zone/gates.hpp"
#include "zone/outbox.hpp"
#include "zone/scene.hpp"

#include <algorithm>
#include <cstddef>
#include <cmath>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::zone {

namespace {

// Một mét bằng trăm centimet: toạ độ của cảnh là centimet, khoảng cách hội thoại là mét.
constexpr float kCmPerMeter = 100.0F;
// EntityFlags bit 1: vật rơi nhặt được (bit 0 là bấm vào để nói chuyện).
constexpr std::uint8_t kPickableFlag = 2;

}  // namespace

// Cầu từ Scene sang gameplay: NPC nào đứng đó, người chơi cách bao xa, và việc gameplay nhờ cảnh làm (xác, vật rơi, tin phát quanh).
class Host::Around final : public play::Surroundings {
public:
    Around(Host& host, Outbox& out) noexcept : host_(&host), out_(&out) {}

    [[nodiscard]] std::optional<Npc> npc(std::uint64_t session, Target target) const override {
        const Scene* scene = host_->scene_of(session);
        if (scene == nullptr) return std::nullopt;
        std::optional<Scene::Npc> found = scene->npc(target.entity);
        if (!found) return std::nullopt;
        return Npc{.entity = target.entity, .scene = scene->id(), .guid = found->guid, .script = found->script,
            .name = std::move(found->name)};
    }

    [[nodiscard]] std::optional<Presence> presence(std::uint64_t session, Spot npc) const override {
        const Scene* scene = host_->scene_of(session);
        if (scene == nullptr) return std::nullopt;
        const std::optional<std::uint32_t> self = scene->entity_of(session);
        const std::optional<Scene::Where> hero = self ? scene->where(*self) : std::nullopt;
        // NPC của phiên thuộc cảnh khác (người chơi đã sang cảnh khác): để talk báo kSceneChanged.
        if (hero && std::cmp_not_equal(npc.scene, scene->id())) {
            return Presence{.hero_scene = scene->id(), .npc_scene = npc.scene, .distance_m = 0.0F};
        }
        const std::optional<Scene::Npc> there = scene->npc(npc.entity);
        if (!hero || !there) return std::nullopt;
        const float along = hero->x_cm - there->at.x_cm;
        const float across = hero->z_cm - there->at.z_cm;
        return Presence{.hero_scene = scene->id(), .npc_scene = npc.scene,
            .distance_m = std::sqrt((along * along) + (across * across)) / kCmPerMeter};
    }

    [[nodiscard]] std::optional<Unit> unit(Place place) const override {
        const Scene* scene = host_->find(place.scene);
        const std::optional<Info> seen = scene != nullptr ? scene->info(place.entity) : std::nullopt;
        if (!seen) return std::nullopt;
        Unit out = unit_of(place.entity, *seen);
        out.name = seen->name;
        return out;
    }

    void units_near(Place place, std::vector<Unit>& out) const override {
        const Scene* scene = host_->find(place.scene);
        if (scene == nullptr) return;
        scene->for_each_near(place.entity, [&out](std::uint32_t id, const Info& seen) { out.push_back(unit_of(id, seen)); });
    }

    void tell(Place place, std::span<const std::byte> frame, bool include_self) override {
        const Scene* scene = host_->find(place.scene);
        if (scene == nullptr) return;
        scene->tell_near(place.entity, std::vector<std::byte>{frame.begin(), frame.end()}, include_self, *out_);
    }

    void hurt(Place place, std::uint8_t percent) override {
        if (Scene* scene = host_->find(place.scene)) scene->set_hp_percent(HpChange{.id = place.entity, .percent = percent}, *out_);
    }

    void fell(Place place) override {
        if (Scene* scene = host_->find(place.scene)) scene->kill(place.entity);
    }

    void raise(Place place, std::int32_t x_cm, std::int32_t z_cm, std::uint8_t percent) override {
        Scene* scene = host_->find(place.scene);
        if (scene == nullptr) return;
        const std::optional<Info> seen = scene->info(place.entity);
        if (!seen || seen->session == 0) return;
        scene->revive(place.entity, Point{.x_cm = static_cast<float>(x_cm), .z_cm = static_cast<float>(z_cm)}, percent, *out_);
    }

    void promote(Place place, std::uint16_t level) override {
        if (Scene* scene = host_->find(place.scene)) scene->set_level(place.entity, level);
    }

    [[nodiscard]] std::optional<std::uint32_t> drop(std::uint16_t scene_id, const DropSpot& spot) override {
        Scene* scene = host_->find(scene_id);
        if (scene == nullptr) return std::nullopt;
        Spawn what;
        what.kind = protocol::EntityKind::kDrop;
        what.template_id = spot.item_template;
        what.level = 1;
        what.x_cm = static_cast<float>(spot.x_cm);
        what.z_cm = static_cast<float>(spot.z_cm);
        what.flags = kPickableFlag;
        return scene->spawn(what, *out_);
    }

    void sweep(Place place) override {
        if (Scene* scene = host_->find(place.scene)) scene->despawn(place.entity, *out_);
    }

private:
    [[nodiscard]] static Unit unit_of(std::uint32_t id, const Info& seen) noexcept {
        return Unit{.entity = id,
            .kind = seen.kind,
            .template_id = seen.template_id,
            .level = seen.level,
            .x_cm = static_cast<std::int32_t>(std::lround(seen.x_cm)),
            .z_cm = static_cast<std::int32_t>(std::lround(seen.z_cm)),
            .hp_percent = seen.hp_percent,
            .dead = seen.state == protocol::EntityState::kDead,
            .name = {}};
    }

    Host* host_;
    Outbox* out_;
};

Host::Host(Config config) : config_(std::move(config)) {
    if (config_.world != nullptr) play_ = std::make_unique<play::Gameplay>(*config_.world, config_.play);
}

void Host::set_unix_time(std::int64_t seconds) noexcept {
    unix_seconds_ = seconds;
    clock_play();
}

void Host::clock_play() noexcept {
    if (play_) play_->set_time(play::Gameplay::Clock{.unix_seconds = unix_seconds_, .tick = ticks_});
}

const Scene* Host::scene_of(std::uint64_t session) const noexcept {
    const auto found = where_.find(session);
    return found == where_.end() ? nullptr : find(found->second);
}

// Đổ kết quả của gameplay vào Outbox: tin xuống client, và trạng thái chơi cần ghi kèm điểm đứng hiện tại.
void Host::deliver(play::Output& output, Outbox& out) {
    for (const play::Output::Frame& frame : output.frames) out.down_frame(frame.session, frame.bytes);
    // Gate đặt mốc mới cho guard::Pace rồi gửi Position: client dời nhân vật về chỗ hồi sinh, sau mọi tin của lượt.
    for (const play::Output::Place& spot : output.places) {
        out.place(spot.session, static_cast<float>(spot.x_cm), static_cast<float>(spot.z_cm));
    }
    for (play::Output::Keep& keep : output.keeps) {
        const Scene* scene = scene_of(keep.session);
        const std::optional<std::uint32_t> self = scene != nullptr ? scene->entity_of(keep.session) : std::nullopt;
        const std::optional<Scene::Where> at = self ? scene->where(*self) : std::nullopt;
        if (!at) continue;
        out.save(Save{.character = keep.character,
            .scene = scene->id(),
            .x_cm = static_cast<std::int32_t>(std::lround(at->x_cm)),
            .z_cm = static_cast<std::int32_t>(std::lround(at->z_cm)),
            .play = std::move(keep.record)});
    }
    out.count_failures(output.encode_failures);
}

const Scene* Host::find(std::uint16_t scene) const noexcept {
    const auto found = scenes_.find(scene);
    return found == scenes_.end() ? nullptr : &found->second;
}

Scene* Host::find(std::uint16_t scene) noexcept {
    const auto found = scenes_.find(scene);
    return found == scenes_.end() ? nullptr : &found->second;
}

Scene* Host::scene_for(std::uint16_t id) {
    if (Scene* existing = find(id)) return existing;
    if (scenes_.size() >= config_.scene_max) return nullptr;
    SceneContent content = config_.seeder ? config_.seeder(id) : SceneContent{};
    Scene& created = scenes_
                         .try_emplace(id,
                             Scene::Config{.id = id,
                                 .grid = config_.grid,
                                 .player_max = config_.player_max,
                                 .walkable = std::move(content.walkable),
                                 .areas = std::move(content.areas)})
                         .first->second;
    seed(created, content.seeds);
    return &created;
}

void Host::seed(Scene& scene, const std::vector<Seed>& seeds) const {
    // Chưa có ai trong cảnh mới, nên thư báo hiện của spawn() không có người nhận: bỏ.
    Outbox nobody;
    const std::size_t room = kEntityMax - std::min<std::size_t>(config_.player_max, kEntityMax);
    std::size_t placed = 0;
    for (const Seed& entry : seeds) {
        if (placed >= room) break;
        Spawn what = entry.what;
        what.respawn_ms = entry.respawn_ms;
        if (scene.spawn(what, nobody)) ++placed;
    }
}

void Host::attach(std::uint64_t session, const ipc::Frame& frame, Outbox& out) {
    const std::optional<ipc::Attach> arrival = ipc::decode_attach(frame.body);
    if (!arrival) {
        out.refuse(session, protocol::ErrorCode::kMalformed);
        return;
    }
    // Gate gửi Attach thứ hai cho cùng phiên (đổi cảnh): rời cảnh cũ trước.
    detach(session, out);
    Scene* scene = scene_for(arrival->scene);
    if (scene == nullptr) {
        out.refuse(session, protocol::ErrorCode::kBusy);
        return;
    }
    if (const auto refused = scene->attach(session, *arrival, out)) {
        out.refuse(session, *refused);
        return;
    }
    where_[session] = arrival->scene;
    if (!play_) {
        remember_foot(session, *scene);
        return;
    }
    // Sau SceneEnter và EntityAppear: client đã vào cảnh khi nhận QuestBook và SelfStats.
    play::Output output;
    const std::optional<std::uint32_t> self = scene->entity_of(session);
    Around around{*this, out};
    if (!self || !play_->attach(play::Gameplay::Arrival{.session = session, .entity = *self}, *arrival, around, output)) {
        // Khối trạng thái chơi hỏng: không đoán, không cho vào với nhân vật nửa vời (vào lại được khi dữ liệu sửa).
        scene->detach(session, out);
        where_.erase(session);
        out.refuse(session, protocol::ErrorCode::kBusy);
        return;
    }
    deliver(output, out);
    remember_foot(session, *scene);
}

void Host::detach(std::uint64_t session, Outbox& out) {
    const auto found = where_.find(session);
    if (found == where_.end()) return;
    if (play_) {
        // Trước khi rời cảnh: trạng thái cuối cần điểm đứng, mà điểm đứng chỉ còn khi người chơi còn trong cảnh.
        play::Output output;
        play_->detach(session, output);
        deliver(output, out);
    }
    if (Scene* scene = find(found->second)) scene->detach(session, out);
    where_.erase(found);
    feet_.erase(session);
}

void Host::handle(const ipc::Frame& frame, Outbox& out) {
    switch (static_cast<ipc::Relay>(frame.kind)) {
    case ipc::Relay::kAttach: attach(frame.session, frame, out); return;
    case ipc::Relay::kDetach: detach(frame.session, out); return;
    case ipc::Relay::kMoved: {
        const auto found = where_.find(frame.session);
        const std::optional<ipc::Moved> step = ipc::decode_moved(frame.body);
        Scene* scene = found == where_.end() ? nullptr : find(found->second);
        if (scene != nullptr && step) {
            scene->moved(frame.session, *step, out);
            consider_gate(frame.session, out);
            return;
        }
        ++ignored_;
        return;
    }
    case ipc::Relay::kUp: {
        if (!play_ || !where_.contains(frame.session)) {
            ++ignored_;
            return;
        }
        play::Output output;
        Around around{*this, out};
        play_->intent(frame.session, frame.body, around, output);
        deliver(output, out);
        return;
    }
    case ipc::Relay::kDown:
    case ipc::Relay::kRefuse:
    case ipc::Relay::kClose:
    case ipc::Relay::kPlace: ++ignored_; return;
    }
    ++ignored_;
}

void Host::advance(Outbox& out) {
    ++ticks_;
    clock_play();
    const bool save_now = ticks_ % kAutosaveTicks == 0;
    for (auto& [id, scene] : scenes_) {
        scene.advance(out);
        if (save_now) scene.autosave(out);
    }
    if (play_) {
        play::Output output;
        Around around{*this, out};
        play_->step(around, output);
        if (save_now) play_->autosave(output);
        deliver(output, out);
    }
}

void Host::remember_foot(std::uint64_t session, const Scene& scene) {
    const std::optional<std::uint32_t> self = scene.entity_of(session);
    const std::optional<Scene::Where> at = self ? scene.where(*self) : std::nullopt;
    if (!at) {
        feet_.erase(session);
        return;
    }
    const AreaStand stand = scene.standing(at->x_cm, at->z_cm);
    feet_[session] = Foot{.known = true, .inside = stand.inside, .index = stand.index};
}

void Host::consider_gate(std::uint64_t session, Outbox& out) {
    const auto found = where_.find(session);
    if (found == where_.end()) return;
    Scene* scene = find(found->second);
    if (scene == nullptr) return;
    const std::optional<Scene::PlayerCard> card = scene->player_card(session);
    const std::optional<std::uint32_t> self = scene->entity_of(session);
    const std::optional<Scene::Where> at = self ? scene->where(*self) : std::nullopt;
    if (!card || !at || card->state == protocol::EntityState::kDead) return;
    const AreaStand stand = scene->standing(at->x_cm, at->z_cm);
    Foot& foot = feet_[session];
    if (!foot.known) {
        foot.known = true;
        foot.inside = stand.inside;
        foot.index = stand.index;
        return;
    }
    const bool same = stand.inside == foot.inside && (!stand.inside || stand.index == foot.index);
    if (same) return;
    foot.inside = stand.inside;
    foot.index = stand.index;
    if (!stand.crossing || stand.dest_scene == scene->id()) return;
    transfer(session, *scene, stand, out);
}

namespace {

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): scene rồi toạ độ, nơi gọi ghi tên (HP-07)
[[nodiscard]] ipc::Attach attach_of(const Scene::PlayerCard& card, std::uint16_t scene, float x_cm, float z_cm) {
    ipc::Attach next;
    next.character = card.character;
    next.scene = scene;
    next.x_cm = x_cm;
    next.z_cm = z_cm;
    next.direction = card.direction;
    next.name = card.name;
    next.level = card.level;
    next.gender = card.gender;
    next.face = card.face;
    next.hair = card.hair;
    next.school = card.school;
    return next;
}

} // namespace

void Host::restore(std::uint64_t session, std::uint16_t scene, float x_cm, float z_cm, const Scene::PlayerCard& card,
    Outbox& out) {
    Scene* back = find(scene);
    const ipc::Attach next = attach_of(card, scene, x_cm, z_cm);
    if (back == nullptr || back->attach(session, next, out)) {
        where_.erase(session);
        feet_.erase(session);
        if (!play_) return;
        play::Output output;
        play_->detach(session, output);
        deliver(output, out);
        return;
    }
    where_[session] = scene;
    out.place(session, x_cm, z_cm);
    remember_foot(session, *back);
}

void Host::transfer(std::uint64_t session, Scene& from, const AreaStand& stand, Outbox& out) {
    Scene* dest = scene_for(stand.dest_scene);
    if (dest == nullptr || dest == &from || !dest->can_admit()) return;
    const std::optional<Scene::PlayerCard> card = from.player_card(session);
    if (!card || card->state == protocol::EntityState::kDead) return;
    const float old_x = card->x_cm;
    const float old_z = card->z_cm;
    const std::uint16_t old_scene = from.id();
    const Scene::PlayerCard& kept = *card;

    if (play_) {
        play::Output dialog;
        play_->left_scene(session, dialog);
        deliver(dialog, out);
    }
    from.detach(session, out);
    const ipc::Attach next = attach_of(kept, stand.dest_scene, stand.dest_x_cm, stand.dest_z_cm);
    if (dest->attach(session, next, out)) {
        restore(session, old_scene, old_x, old_z, kept, out);
        return;
    }
    where_[session] = stand.dest_scene;
    out.place(session, stand.dest_x_cm, stand.dest_z_cm);
    if (play_) {
        const std::optional<std::uint32_t> self = dest->entity_of(session);
        play::Output moved;
        Around around{*this, out};
        const bool seated = self && play_->change_scene(session, stand.dest_scene, *self, stand.dest_x_cm, stand.dest_z_cm,
                                              around, moved);
        deliver(moved, out);
        if (!seated) {
            dest->detach(session, out);
            restore(session, old_scene, old_x, old_z, kept, out);
            const Scene* back = find(old_scene);
            const std::optional<std::uint32_t> again = back != nullptr ? back->entity_of(session) : std::nullopt;
            if (!again) return;
            play::Output returned;
            Around second{*this, out};
            static_cast<void>(play_->change_scene(session, old_scene, *again, old_x, old_z, second, returned));
            deliver(returned, out);
            return;
        }
    }
    dest->keep_spot(session, out);
    remember_foot(session, *dest);
}

void Host::drop_all(Outbox& out) {
    // Sao danh sách phiên: detach sửa where_ trong lúc duyệt.
    std::vector<std::uint64_t> sessions;
    sessions.reserve(where_.size());
    for (const auto& [session, scene] : where_) {
        sessions.push_back(session);
    }
    for (const std::uint64_t session : sessions) {
        detach(session, out);
    }
}

} // namespace game::zone
