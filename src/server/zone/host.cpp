#include "zone/host.hpp"

#include <utility>
#include <vector>

namespace game::zone {

Host::Host(Config config) : config_(config) {}

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
    const Scene::Config made{.id = id, .grid = config_.grid, .player_max = config_.player_max};
    return &scenes_.try_emplace(id, made).first->second;
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
}

void Host::detach(std::uint64_t session, Outbox& out) {
    const auto found = where_.find(session);
    if (found == where_.end()) return;
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
    case ipc::Relay::kDown:
    case ipc::Relay::kRefuse:
    case ipc::Relay::kClose: ++ignored_; return;
    }
    ++ignored_;
}

void Host::advance(Outbox& out) {
    ++ticks_;
    const bool save_now = ticks_ % kAutosaveTicks == 0;
    for (auto& [id, scene] : scenes_) {
        scene.advance();
        if (save_now) scene.autosave(out);
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
