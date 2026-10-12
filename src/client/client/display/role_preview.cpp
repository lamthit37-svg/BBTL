// Người mẫu của bảng chọn và màn tạo (xem role_preview.hpp).
#include "client/display/role_preview.hpp"

#include "client/display/player.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "look/appearance.hpp"
#include "look/look.hpp"
#include "render/forward.hpp"

#include <cstdio>
#include <expected>
#include <memory>
#include <print>
#include <utility>
#include <vector>

namespace game::client {
namespace {

void remember(RoleLook& look, const PlayerDesc& player) noexcept {
    look.sex = player.race == look::Race::kFemale ? 0 : 1;
    look.face = player.look ? player.look->face : 0;
    look.hair = player.look ? player.look->hair : 0;
    look.body = player.look ? player.look->body : 0;
    look.arm = player.look ? player.look->arm : 0;
    look.foot = player.look ? player.look->foot : 0;
    look.sect = player.sect ? static_cast<std::int8_t>(*player.sect) : static_cast<std::int8_t>(-1);
}

} // namespace

struct RoleShot::State {
    explicit State(PlayerActor made) : actor(std::move(made)) {}

    PlayerActor actor;
    RoleLook look;
    std::vector<render::Instance> instances;
};

RoleShot::RoleShot(std::unique_ptr<State> state) noexcept : state_(std::move(state)) {}
RoleShot::RoleShot(RoleShot&&) noexcept = default;
RoleShot& RoleShot::operator=(RoleShot&&) noexcept = default;
RoleShot::~RoleShot() = default;

RoleShot::ShotResult RoleShot::create(const PlayerDesc& player, const MeshLoader& load) {
    core::Result<PlayerActor> actor = PlayerActor::create(player, load);
    if (!actor) return std::unexpected(actor.error());
    auto state = std::make_unique<State>(std::move(*actor));
    remember(state->look, player);
    return RoleShot(std::move(state));
}

bool RoleShot::matches(RoleLook look) const noexcept {
    return state_->look == look;
}

bool RoleShot::retarget(const PlayerDesc& player, const MeshLoader& load_mesh) {
    core::Result<PlayerActor> actor = PlayerActor::create(player, load_mesh);
    if (!actor) {
        std::println(stderr, "Nhân vật: không đổi được ngoại hình: {}", actor.error());
        return false;
    }
    state_->actor = std::move(*actor);
    remember(state_->look, player);
    return true;
}

core::Status RoleShot::pose(const Stand& stand) {
    State& state = *state_;
    const core::Status posed = state.actor.update(core::Clock::now(), stand);
    if (!posed) return posed;
    state.instances.clear();
    state.actor.append(state.instances);
    return core::ok();
}

void RoleShot::append(std::vector<render::Instance>& out) const {
    const std::vector<render::Instance>& posed = state_->instances;
    out.insert(out.end(), posed.begin(), posed.end());
}

} // namespace game::client
