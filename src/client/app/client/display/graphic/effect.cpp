// Hạt và dải của cảnh, cộng mesh hiệu ứng đã nhận material hạt.
#include "client/display/graphic/state.hpp"
namespace game::client {

void Display::State::dispatch_cues() {
    std::vector<SkillCue> cues;
    player->take_cues(cues);
    for (SkillCue& cue : cues) {
        if (cue.kind == look::EventKind::kSound) {
            const std::scoped_lock<std::mutex> locked(steer_guard);
            sounds_due.push_back(std::move(cue.name));
            continue;
        }
        if (cue.kind != look::EventKind::kAnimEffect || !fx_view) continue;
        fx::Spawn spawn;
        spawn.name = std::move(cue.name);
        spawn.is_effect = true;
        spawn.is_tracked = true;
        spawn.node.position = cue.position;
        spawn.node.orientation = cue.orientation;
        const std::uint32_t handle = fx_view->spawn(spawn);
        if (handle != 0 && cue.token != 0) follow_handles.push_back(FollowHandle{.token = cue.token, .handle = handle});
        if (handle == 0 && cue.token != 0) player->drop_follow(cue.token);
    }
}

void Display::State::sync_follows() {
    if (!fx_view || !player) return;
    const std::span<const CueFollow> moved = player->follows();
    std::erase_if(follow_handles, [&](const FollowHandle& tracked) {
        if (!fx_view->is_live(tracked.handle)) {
            player->drop_follow(tracked.token);
            return true;
        }
        const auto at = std::ranges::find(moved, tracked.token, &CueFollow::token);
        if (at != moved.end()) fx_view->move(tracked.handle, fx::Node{.position = at->position, .orientation = at->orientation});
        return false;
    });
}

namespace {

// Màu RRGGBBAA của đá quý thành hệ số nhân vào hạt: rgb nhân trước với alpha (Effect::setColour của ref).
[[nodiscard]] fx::Colour gem_tint(std::uint32_t colour) {
    constexpr float kByte = 255.0F;
    const float alpha = static_cast<float>(colour & 0xFFU) / kByte;
    const float red = static_cast<float>((colour >> 24U) & 0xFFU) / kByte * alpha;
    const float green = static_cast<float>((colour >> 16U) & 0xFFU) / kByte * alpha;
    const float blue = static_cast<float>((colour >> 8U) & 0xFFU) / kByte * alpha;
    return fx::Colour{red, green, blue, alpha};
}

} // namespace

void Display::State::sync_gear() {
    if (!fx_view || !player) return;
    const std::span<const GearEffect> wanted = player->gear_effects();
    const std::vector<look::Held>& mounted = player->figure().held;
    const auto is_wanted = [&](const GearHandle& gear) {
        const auto at = std::ranges::find(wanted, gear.mount, &GearEffect::mount);
        if (at == wanted.end()) return false;
        const look::Held& slot = mounted.at(gear.mount);
        return slot.effect == gear.name && slot.effect_colour == gear.colour;
    };
    // Hết hạn, đổi đá, hay cảnh mới đã xoá hiệu ứng (adopt): dừng cái cũ, dựng lại nếu còn cần.
    std::erase_if(gear_handles, [&](const GearHandle& gear) {
        const bool is_alive = gear.handle == 0 || fx_view->is_live(gear.handle);
        if (is_wanted(gear) && is_alive) return false;
        fx_view->release(gear.handle);
        return true;
    });
    for (const GearEffect& place : wanted) {
        const look::Held& slot = mounted.at(place.mount);
        const fx::Node node{.position = place.position, .orientation = place.orientation};
        const auto known = std::ranges::find(gear_handles, place.mount, &GearHandle::mount);
        if (known != gear_handles.end()) {
            fx_view->move(known->handle, node);
            continue;
        }
        fx::Spawn spawn;
        spawn.name = slot.effect;
        spawn.is_effect = true;
        spawn.is_tracked = true;
        spawn.node = node;
        spawn.tint = gem_tint(slot.effect_colour);
        gear_handles.push_back(GearHandle{.mount = place.mount, .name = slot.effect, .colour = slot.effect_colour,
            .handle = fx_view->spawn(spawn)});
    }
}

void Display::State::say_fx_fault() {
    if (fx_fault_noted || catalog == nullptr) return;
    const core::Error* fault = catalog->fault(render::Pso::kFx);
    if (fault == nullptr) return;
    fx_fault_noted = true;
    std::println(stderr, "Hiệu ứng: bỏ qua, không dựng được bộ vẽ: {}", *fault);
}

void Display::State::open_fx() {
    if (fx_view || catalog == nullptr || device == nullptr) return;
    const gpu::PipelineHandle pipeline = catalog->get(render::Pso::kFx);
    if (!pipeline) return say_fx_fault();
    const gpu::PipelineHandle blend = catalog->get(render::Pso::kFxBlend);
    fx_view = FxView::open(*device, pipeline, blend);
    if (!fx_view) return;
    fx_view->load(data_root, texture_tier);
    if (stage != nullptr) fx_view->adopt(*stage);
}

void Display::State::advance_fx(float elapsed) {
    if (!fx_view) return;
    const float raw = elapsed - fx_stamp;
    const float step = fx_stamp < 0.0F ? 0.016F : std::min(raw, kMaxStep);
    fx_stamp = elapsed;
    fx_view->advance(step);
}

namespace {

[[nodiscard]] math::Quat fx_quat(ogre::Quat value) {
    return {value.x, value.y, value.z, value.w};
}

[[nodiscard]] math::Vector3 fx_vec(ogre::Vec3 value) {
    return {value.x, value.y, value.z};
}

// [R | t] rồi nhân scale: T * R * S, đúng nút OGRE.
[[nodiscard]] math::Matrix4 fx_placed(ogre::Vec3 position, ogre::Quat orientation, ogre::Vec3 scale) {
    const math::Transform3 spin(fx_quat(orientation), fx_vec(position));
    return math::Matrix4(spin) * math::Matrix4::scale(fx_vec(scale));
}

} // namespace

std::size_t Display::State::fx_mesh_slot(const fx::Field& field) {
    if (field.definition().renderer != fx::RendererKind::kMesh) return kMissing;
    if (field.definition().mesh_name.empty() || fx_view == nullptr) return kMissing;
    const fx::Paint* paint = fx_view->paint(field.definition().material);
    if (paint == nullptr || paint->blend != fx::Blend::kAlpha) return kMissing;
    return load_painted_mesh(field.definition().mesh_name, field.definition().material, *paint);
}

void Display::State::push_fx_field(const fx::Field& field, std::size_t slot) {
    if (slot == kMissing) return;
    const fx::Node& node = field.node();
    const math::Matrix4 parent = fx_placed(node.position, node.orientation, node.scale);
    const render::Drawable& drawable = kept.at(slot).loaded.drawable;
    for (const fx::MeshPose& pose : fx::mesh_poses(field)) {
        render::Instance instance;
        instance.drawable = &drawable;
        instance.world = parent * fx_placed(pose.position, pose.orientation, pose.scale);
        frame_instances.push_back(instance);
    }
}

void Display::State::append_fx_meshes() {
    if (!fx_view) return;
    const std::vector<const fx::Field*> live = fx_view->fields();
    std::vector<std::size_t> slots;
    slots.reserve(live.size());
    for (const fx::Field* field : live) {
        slots.push_back(fx_mesh_slot(*field));
    }
    for (std::size_t index = 0; index < live.size(); ++index) {
        push_fx_field(*live[index], slots[index]);
    }
}

void Display::State::draw_fx(const FxAsk& ask) const {
    if (!fx_view) return;
    fx_view->draw(*ask.list, ask.slot, *ask.camera);
}
} // namespace game::client
