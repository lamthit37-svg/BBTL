/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/effect.cpp
 *  PHÂN HỆ   : Display / Graphic / Effect
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hạt và dải của cảnh. Mỗi scene_blend của hạt một pipeline.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/graphic/state.hpp"

#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <chrono>
#include <cmath>
#include <optional>
#include <ranges>
#include <string>
#include <string_view>
namespace game::client {
namespace {

// Material cộng sáng có ảnh vệt (png_flaretrail). Tên material trong kịch bản ribbon không có trong
// effect/materials.tsv. Khác gốc: AnimationRibbon::setMaterial dùng đúng tên ấy.
constexpr std::string_view kRibbonPaint = "cw_danbing_08";

[[nodiscard]] std::string_view prop_value(std::string_view props, std::string_view key) {
    while (!props.empty()) {
        const std::size_t cut = props.find('|');
        const std::string_view item = props.substr(0, cut);
        props = cut == std::string_view::npos ? std::string_view{} : props.substr(cut + 1);
        const std::size_t mark = item.find('=');
        if (mark == std::string_view::npos) continue;
        if (item.substr(0, mark) != key) continue;
        return item.substr(mark + 1);
    }
    return {};
}

[[nodiscard]] float prop_float(std::string_view props, std::string_view key, float fallback) {
    const std::string_view text = prop_value(props, key);
    if (text.empty()) return fallback;
    float value = 0.0F;
    const char* const end = text.data() + text.size();
    const std::from_chars_result read = std::from_chars(text.data(), end, value);
    if (read.ec != std::errc{} || read.ptr != end) return fallback;
    return value;
}

void prop_rgb(std::string_view props, std::string_view key, float& red, float& green, float& blue) {
    const std::string_view text = prop_value(props, key);
    if (text.empty()) return;
    float channels[3] = {red, green, blue};
    std::size_t at = 0;
    for (float& channel : channels) {
        while (at < text.size() && text[at] == ' ') ++at;
        const char* const begin = text.data() + at;
        const std::from_chars_result read = std::from_chars(begin, text.data() + text.size(), channel);
        if (read.ec != std::errc{}) return;
        at = static_cast<std::size_t>(read.ptr - text.data());
    }
    red = channels[0];
    green = channels[1];
    blue = channels[2];
}

void paint_ribbon_corner(fx::BillboardBatch& batch, ogre::Vec3 place, float along, float red, float green, float blue,
    float fade, float v) {
    fx::BillboardVertex vertex;
    vertex.x = place.x;
    vertex.y = place.y;
    vertex.z = place.z;
    vertex.u = along;
    vertex.v = v;
    vertex.red = red * fade;
    vertex.green = green * fade;
    vertex.blue = blue * fade;
    vertex.alpha = 1.0F;
    batch.vertices.push_back(vertex);
}

} // namespace

std::optional<Display::State::SkillRibbon> Display::State::make_ribbon(const SkillCue& cue) const {
    const float width = prop_float(cue.props, "RibbonWidth", 0.0F);
    const float life = prop_float(cue.props, "LifeTime", 0.0F);
    const float count = prop_float(cue.props, "PointCount", 0.0F);
    if (!(width > 0.0F) || !(life > 0.0F) || !(count >= 4.0F)) return std::nullopt;
    SkillRibbon ribbon;
    ribbon.token = cue.token;
    ribbon.life = life;
    ribbon.width = width;
    const auto points = static_cast<std::uint32_t>(count);
    ribbon.point_count = points - (points % 2U);
    prop_rgb(cue.props, "StartColour", ribbon.start_red, ribbon.start_green, ribbon.start_blue);
    prop_rgb(cue.props, "EndColour", ribbon.end_red, ribbon.end_green, ribbon.end_blue);
    ribbon.start_alpha = prop_float(cue.props, "StartAlphaValue", 1.0F);
    ribbon.end_alpha = prop_float(cue.props, "EndAlphaValue", 1.0F);
    return ribbon;
}

void Display::State::push_ribbon_edge(SkillRibbon& ribbon, ogre::Vec3 hand, ogre::Quat orientation) const {
    ogre::Vec3 axis = ogre::quat_rotate(orientation, ogre::Vec3{.x = 1.0F});
    const float length = ogre::length_vec3(axis);
    if (length > 1.0e-8F) axis = ogre::scale_vec3(axis, 1.0F / length);
    const ogre::Vec3 outer = ogre::add_vec3(hand, ogre::scale_vec3(axis, ribbon.width));
    ribbon.hands.insert(ribbon.hands.begin(), hand);
    ribbon.outers.insert(ribbon.outers.begin(), outer);
    const std::size_t cap = ribbon.point_count / 2U;
    while (ribbon.hands.size() > cap) {
        ribbon.hands.pop_back();
        ribbon.outers.pop_back();
    }
}

void Display::State::paint_skill_ribbon(const SkillRibbon& ribbon, fx::BillboardBatch& batch) const {
    const std::size_t edges = std::min(ribbon.hands.size(), ribbon.outers.size());
    if (edges < 2) return;
    const float vertices = static_cast<float>(edges * 2U);
    const float span = vertices - 2.0F;
    if (!(span > 0.0F)) return;
    for (std::size_t index = 1; index < edges; ++index) {
        const float newer = (static_cast<float>(index - 1) * 2.0F) / span;
        const float older = (static_cast<float>(index) * 2.0F) / span;
        paint_ribbon_corner(batch, ribbon.hands[index - 1], newer, ribbon.end_red, ribbon.end_green, ribbon.end_blue,
            (1.0F - newer) * ribbon.end_alpha, 1.0F);
        paint_ribbon_corner(batch, ribbon.outers[index - 1], newer, ribbon.start_red, ribbon.start_green,
            ribbon.start_blue, (1.0F - newer) * ribbon.start_alpha, 0.0F);
        paint_ribbon_corner(batch, ribbon.hands[index], older, ribbon.end_red, ribbon.end_green, ribbon.end_blue,
            (1.0F - older) * ribbon.end_alpha, 1.0F);
        paint_ribbon_corner(batch, ribbon.outers[index], older, ribbon.start_red, ribbon.start_green, ribbon.start_blue,
            (1.0F - older) * ribbon.start_alpha, 0.0F);
    }
}

void Display::State::dispatch_cues() {
    if (player) dispatch_actor_cues(*player, 0);
}

void Display::State::dispatch_actor_cues(PlayerActor& actor, std::uint32_t owner) {
    std::vector<SkillCue> cues;
    actor.take_cues(cues);
    for (SkillCue& cue : cues) {
        if (cue.kind == look::EventKind::kShake) {
            follow.add_one_vib();
            continue;
        }
        if (cue.kind == look::EventKind::kSound) {
            const std::scoped_lock<std::mutex> locked(steer_guard);
            sounds_due.push_back(std::move(cue.name));
            continue;
        }
        // SceneLight là đèn cảnh: chưa có chỗ vẽ. Ribbon là dải của AnimationRibbon, dựng ở step_skill_ribbons.
        if (cue.kind == look::EventKind::kRibbon && cue.token != 0) {
            std::optional<SkillRibbon> ribbon = make_ribbon(cue);
            if (!ribbon) continue;
            ribbon->owner = owner;
            push_ribbon_edge(*ribbon, cue.position, cue.orientation);
            skill_ribbons.push_back(std::move(*ribbon));
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
        if (handle != 0 && cue.token != 0) {
            follow_handles.push_back(FollowHandle{.owner = owner, .token = cue.token, .handle = handle});
        }
        if (handle == 0 && cue.token != 0) actor.drop_follow(cue.token);
    }
}

void Display::State::sync_follows() {
    if (!fx_view) return;
    const auto actor_of = [this](std::uint32_t owner) -> PlayerActor* {
        if (owner == 0) return player ? &*player : nullptr;
        const auto slot = peers.find(owner);
        if (slot == peers.end() || !slot->second.actor) return nullptr;
        return &*slot->second.actor;
    };
    const auto follow_at = [&](std::uint32_t owner, std::uint32_t token) -> const CueFollow* {
        PlayerActor* actor = actor_of(owner);
        if (actor == nullptr) return nullptr;
        const std::span<const CueFollow> moved = actor->follows();
        const auto at = std::ranges::find(moved, token, &CueFollow::token);
        if (at == moved.end()) return nullptr;
        return &*at;
    };
    std::erase_if(follow_handles, [&](const FollowHandle& tracked) {
        if (!fx_view->is_live(tracked.handle)) {
            if (PlayerActor* actor = actor_of(tracked.owner)) actor->drop_follow(tracked.token);
            return true;
        }
        if (const CueFollow* at = follow_at(tracked.owner, tracked.token)) {
            fx_view->move(tracked.handle, fx::Node{.position = at->position, .orientation = at->orientation});
        }
        return false;
    });
    float step = 0.0F;
    if (ribbon_stamp.time_since_epoch().count() != 0) {
        step = std::chrono::duration<float>(frame_time - ribbon_stamp).count();
    }
    ribbon_stamp = frame_time;
    if (!(step >= 0.0F)) step = 0.0F;
    for (SkillRibbon& ribbon : skill_ribbons) {
        ribbon.age += step;
        if (const CueFollow* at = follow_at(ribbon.owner, ribbon.token)) {
            push_ribbon_edge(ribbon, at->position, at->orientation);
        }
    }
    std::erase_if(skill_ribbons, [&](const SkillRibbon& ribbon) {
        const bool is_over = ribbon.age >= ribbon.life;
        if (is_over) {
            if (PlayerActor* actor = actor_of(ribbon.owner)) actor->drop_follow(ribbon.token);
        }
        return is_over;
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
    constexpr std::array<render::Pso, fx::kDrawnBlends> fx_psos{render::Pso::kFx,
        render::Pso::kFxAlphaAdd, render::Pso::kFxBlend, render::Pso::kFxDarken,
        render::Pso::kFxGlow, render::Pso::kFxColour, render::Pso::kFxReplace};
    std::array<gpu::PipelineHandle, fx::kDrawnBlends> pipelines{};
    for (std::size_t index = 0; index < fx_psos.size(); ++index)
        pipelines[index] = catalog->get(fx_psos[index]);
    if (!pipelines[static_cast<std::size_t>(fx::Blend::kAdd)]) return say_fx_fault();
    fx_view = FxView::open(*device, pipelines);
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
    std::vector<fx::BillboardBatch> ribbons;
    fx::BillboardBatch batch;
    batch.material = std::string(kRibbonPaint);
    for (const SkillRibbon& ribbon : skill_ribbons) paint_skill_ribbon(ribbon, batch);
    if (!batch.vertices.empty()) ribbons.push_back(std::move(batch));
    fx_view->draw(*ask.list, ask.slot, *ask.camera, ribbons);
}
} // namespace game::client
