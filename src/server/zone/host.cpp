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
#include "protocol/messages.hpp"
#include "zone/content.hpp"
#include "zone/outbox.hpp"
#include "zone/scene.hpp"

#include <algorithm>
#include <cstddef>
#include <cmath>
#include <cstdint>
#include <memory>
#include <optional>
#include <utility>
#include <vector>

namespace game::zone {

namespace {

// Một mét bằng trăm centimet: toạ độ của cảnh là centimet, khoảng cách hội thoại là mét.
constexpr float kCmPerMeter = 100.0F;

}  // namespace

// Cầu từ Scene sang gameplay: NPC nào đứng đó và người chơi cách bao xa. Chỉ đọc.
class Host::Around final : public play::Surroundings {
public:
    explicit Around(const Host& host) noexcept : host_(&host) {}

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

private:
    const Host* host_;
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
                                 .walkable = std::move(content.walkable)})
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
        if (scene.spawn(entry.what, nobody)) ++placed;
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
    if (!play_) return;
    // Sau SceneEnter và EntityAppear: client đã vào cảnh khi nhận QuestBook và SelfStats.
    play::Output output;
    if (!play_->attach(session, *arrival, output)) {
        // Khối trạng thái chơi hỏng: không đoán, không cho vào với nhân vật nửa vời (vào lại được khi dữ liệu sửa).
        scene->detach(session, out);
        where_.erase(session);
        out.refuse(session, protocol::ErrorCode::kBusy);
        return;
    }
    deliver(output, out);
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
        play_->intent(frame.session, frame.body, Around{*this}, output);
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
    if (save_now && play_) {
        play::Output output;
        play_->autosave(output);
        deliver(output, out);
    }
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
