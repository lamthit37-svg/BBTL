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

#include "io/file.hpp"
#include "look/bullet.hpp"
#include "look/impact.hpp"
#include "ogre/quat.hpp"
#include "ogre/vec3.hpp"

#include <filesystem>

#include <algorithm>
#include <array>
#include <charconv>
#include <chrono>
#include <cmath>
#include <optional>
#include <ranges>
#include <span>
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
            HeardSound due;
            due.name = std::move(cue.name);
            due.x = cue.position.x;
            due.y = cue.position.y;
            due.z = cue.position.z;
            due.is_spatial = true;
            const std::scoped_lock<std::mutex> locked(steer_guard);
            sounds_due.push_back(std::move(due));
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
        const std::uint32_t handle = fx_view->spawn(spawn);
        GearHandle made;
        made.mount = place.mount;
        made.name = slot.effect;
        made.colour = slot.effect_colour;
        made.handle = handle;
        gear_handles.push_back(std::move(made));
    }
}

namespace {

[[nodiscard]] fx::Node ride_node(const RideFx& place) {
    return fx::Node{.position = place.position, .orientation = place.orientation};
}

} // namespace

bool Display::State::same_ride(const RideFx& place, const RideHandle& prior) {
    const bool same_slot = place.ride == prior.ride && place.index == prior.index;
    return same_slot && place.name == prior.name;
}

const Display::State::RideHandle* Display::State::find_ride(const RideFx& place) const {
    for (const RideHandle& prior : ride_handles) {
        if (same_ride(place, prior)) return &prior;
    }
    return nullptr;
}

bool Display::State::wants_ride(std::span<const RideFx> wanted, const RideHandle& prior) const {
    for (const RideFx& place : wanted) {
        if (same_ride(place, prior)) return true;
    }
    return false;
}

bool Display::State::drop_ride(const RideHandle& prior, std::span<const RideFx> wanted) {
    const bool is_live = prior.handle == 0 || fx_view->is_live(prior.handle);
    const bool keep = wants_ride(wanted, prior) && is_live;
    if (keep) return false;
    fx_view->release(prior.handle);
    return true;
}

void Display::State::spawn_ride(const RideFx& place) {
    fx::Spawn spawn;
    spawn.name = place.name;
    spawn.is_effect = true;
    spawn.is_tracked = true;
    spawn.node = ride_node(place);
    const std::uint32_t handle = fx_view->spawn(spawn);
    if (handle == 0) std::println(stderr, "Thú cưỡi: không dựng {}", place.name);
    RideHandle made;
    made.ride = place.ride;
    made.index = place.index;
    made.name = place.name;
    made.handle = handle;
    ride_handles.push_back(std::move(made));
}

void Display::State::move_or_spawn_ride(const RideFx& place) {
    const RideHandle* known = find_ride(place);
    if (known == nullptr) return spawn_ride(place);
    fx_view->move(known->handle, ride_node(place));
}

void Display::State::sync_ride() {
    if (!fx_view || !player) return;
    const std::span<const RideFx> wanted = player->ride_fx();
    const auto drop = [&](const RideHandle& prior) { return drop_ride(prior, wanted); };
    std::erase_if(ride_handles, drop);
    for (const RideFx& place : wanted)
        move_or_spawn_ride(place);
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

void Display::State::open_sky() {
    if (sky_view || catalog == nullptr || device == nullptr) return;
    SkyPipelines pipelines;
    pipelines.dome = catalog->get(render::Pso::kSkyDome);
    pipelines.cloud = catalog->get(render::Pso::kSkyCloud);
    pipelines.body = catalog->get(render::Pso::kSkyBody);
    pipelines.star = catalog->get(render::Pso::kSkyStar);
    sky_view = SkyView::open(*device, pipelines);
    if (!sky_view) return;
    sky_view->load(data_root, texture_tier);
    // Màn đăng nhập của Game.exe không ghim giờ: ngày chạy tự do một phút từ 0.
    if (procedure == Procedure::kLogin) sky_view->run_day();
    if (procedure == Procedure::kPlay) sky_view->pin_day(kOfflineDayTime);
    adopt_sky();
}

void Display::State::adopt_sky() {
    sky_effects.clear();
    if (!sky_view || stage == nullptr) return;
    sky_view->adopt(*stage);
    sky_light_serial = 0;
    if (!fx_view) return;
    for (const std::string& name : sky_view->effects()) {
        fx::Spawn spawn;
        spawn.name = name;
        spawn.is_effect = true;
        spawn.is_tracked = true;
        const std::uint32_t handle = fx_view->spawn(spawn);
        if (handle != 0) sky_effects.push_back(handle);
    }
}

void Display::State::follow_sky_effects(const render::Camera& camera) {
    if (sky_effects.empty() || !fx_view) return;
    const math::Matrix4 placed = math::affine_inverse(camera.view);
    fx::Node node;
    node.position = {.x = placed.at(3, 0), .y = placed.at(3, 1), .z = placed.at(3, 2)};
    for (const std::uint32_t handle : sky_effects) {
        fx_view->move(handle, node);
    }
}

void Display::State::refresh_sky_light() {
    if (!sky_view || stage == nullptr) return;
    const std::uint32_t serial = sky_view->env_serial();
    if (serial == 0 || serial == sky_light_serial) return;
    const std::optional<ensky::EnvKey> env = sky_view->env();
    if (!env) return;
    sky_light_serial = serial;
    light = SceneLight(*stage, *env);
}

void Display::State::advance_sky(float elapsed) {
    if (!sky_view) return;
    const float raw = elapsed - en_sky_stamp;
    const float step = en_sky_stamp < 0.0F ? 0.016F : std::min(raw, kMaxStep);
    en_sky_stamp = elapsed;
    sky_view->advance(step);
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
    if (paint == nullptr || !fx::has_mesh_pipeline(paint->blend)) return kMissing;
    return load_painted_mesh(field.definition().mesh_name, field.definition().material, *paint);
}

void Display::State::push_fx_field(const fx::Field& field, std::size_t slot,
    const fx::CameraAxes& axes) {
    if (slot == kMissing) return;
    const fx::Node& node = field.node();
    const math::Matrix4 parent = fx_placed(node.position, node.orientation, node.scale);
    const render::Drawable& drawable = kept.at(slot).loaded.drawable;
    for (const fx::MeshPose& pose : fx::mesh_poses(field, axes)) {
        render::Instance instance;
        instance.drawable = &drawable;
        instance.world = parent * fx_placed(pose.position, pose.orientation, pose.scale);
        const fx::Colour& colour = pose.colour;
        instance.tint = {.x = colour[0], .y = colour[1], .z = colour[2], .w = colour[3]};
        frame_instances.push_back(instance);
    }
}

void Display::State::append_fx_meshes(const render::Camera& camera) {
    if (!fx_view) return;
    const fx::CameraAxes axes = fx_axes_of(camera);
    const std::vector<const fx::Field*> live = fx_view->fields();
    std::vector<std::size_t> slots;
    slots.reserve(live.size());
    for (const fx::Field* field : live) {
        slots.push_back(fx_mesh_slot(*field));
    }
    for (std::size_t index = 0; index < live.size(); ++index) {
        push_fx_field(*live[index], slots[index], axes);
    }
}

// Vòng chọn dưới chân. ring_size của CharModelEx là centimét, cùng đơn vị thế giới với chân
// (terrain scale 100: 1 mét = 100). Khác gốc: client 2026 chiếu một mesh chọn riêng; thư viện hạt
// không có mesh đó, nên dùng ảnh vòng cộng sáng có sẵn và tô theo loại mục tiêu.
void Display::State::paint_select_ring(std::vector<fx::BillboardBatch>& out) const {
    if (!ground || !terrain) return;
    const std::optional<std::uint32_t> chosen = combat.target();
    if (!chosen) return;
    const cast::Actor* actor = people.find(*chosen);
    if (actor == nullptr || actor->pose == cast::Pose::kDead) return;
    float size = 120.0F;
    if (creature_tables) {
        const look::CreatureTemplate* row = creature_tables->find_template(actor->template_id);
        if (row != nullptr && row->ring_size > 0.0F && std::isfinite(row->ring_size)) size = row->ring_size;
    }
    size = std::clamp(size, 40.0F, 4000.0F);
    ogre::Vec3 foot = world_foot(*actor);
    foot.y += 4.0F;
    fx::Colour ink{1.0F, 0.25F, 0.25F, 1.0F};
    if (actor->kind == cast::Kind::kNpc) ink = {0.25F, 0.88F, 0.38F, 1.0F};
    if (actor->kind == cast::Kind::kPet) ink = {0.38F, 0.75F, 1.0F, 1.0F};
    if (actor->kind == cast::Kind::kPlayer) ink = {1.0F, 0.85F, 0.35F, 1.0F};
    fx::Node node;
    node.position = foot;
    fx::BillboardBatch ring;
    ring.material = "m01_cr_千里追击A03";
    fx::append_deck(ring, node, size, ink);
    if (!ring.vertices.empty()) out.push_back(std::move(ring));
}

void Display::State::draw_fx(const FxAsk& ask) const {
    if (!fx_view) return;
    std::vector<fx::BillboardBatch> extras;
    fx::BillboardBatch batch;
    batch.material = std::string(kRibbonPaint);
    for (const SkillRibbon& ribbon : skill_ribbons) paint_skill_ribbon(ribbon, batch);
    if (!batch.vertices.empty()) extras.push_back(std::move(batch));
    paint_select_ring(extras);
    fx_view->draw(*ask.list, ask.slot, *ask.camera, extras);
}

namespace {

constexpr std::size_t kMaxLiveBullets = 32;

// Tên riêng: point_of ở prelude.hpp trả math::Point3.
[[nodiscard]] look::FlightPoint flight_at(ogre::Vec3 place) {
    return look::FlightPoint{.x = place.x, .y = place.y, .z = place.z};
}

[[nodiscard]] ogre::Vec3 vec_of(look::FlightPoint point) {
    return ogre::Vec3{.x = point.x, .y = point.y, .z = point.z};
}

[[nodiscard]] ogre::Vec3 up_axis() {
    return ogre::Vec3{.x = 0.0F, .y = 1.0F, .z = 0.0F};
}

} // namespace

void Display::State::hear_at(std::string name, ogre::Vec3 place) {
    if (name.empty()) return;
    HeardSound due;
    due.name = std::move(name);
    due.x = place.x;
    due.y = place.y;
    due.z = place.z;
    due.is_spatial = true;
    const std::scoped_lock<std::mutex> locked(steer_guard);
    sounds_due.push_back(std::move(due));
}

std::uint32_t Display::State::spawn_tracked(std::string_view name, look::FlightPoint at) {
    if (!fx_view || name.empty()) return 0;
    fx::Spawn spawn;
    spawn.name = std::string(name);
    spawn.is_effect = true;
    spawn.is_tracked = true;
    spawn.node.position = vec_of(at);
    return fx_view->spawn(spawn);
}

fx::Node Display::State::body_node() const {
    // Khác gốc: avatar chưa có locator 身体受击点, gắn hạt ở chân.
    const ogre::Vec3 up = up_axis();
    fx::Node node;
    node.position = foot();
    node.orientation = ogre::quat_from_angle_axis(facing, up);
    return node;
}

std::string Display::State::table_text(const char* file) const {
    const std::filesystem::path path = data_root / "Table" / file;
    const io::TextResult text = io::read_text(path);
    if (!text) {
        std::println(stderr, "Bảng {} không đọc được", file);
        return {};
    }
    return *text;
}

void Display::State::take_impacts(std::string text) {
    if (text.empty()) return;
    look::ImpactRows rows = look::parse_impacts(text);
    if (!rows) {
        std::println(stderr, "Bảng impacts: {}", rows.error());
        return;
    }
    impacts.reset(std::move(*rows));
}

void Display::State::take_bullets(std::string text) {
    if (text.empty()) return;
    look::BulletRows rows = look::parse_bullets(text);
    if (!rows) {
        std::println(stderr, "Bảng bullets: {}", rows.error());
        return;
    }
    bullets.reset(std::move(*rows));
}

void Display::State::take_skills(std::string text) {
    if (text.empty()) return;
    look::SkillRows rows = look::parse_skill_bullets(text);
    if (!rows) {
        std::println(stderr, "Bảng skill_bullets: {}", rows.error());
        return;
    }
    skill_bullets.reset(std::move(*rows));
}

void Display::State::apply_one_cue(const look::ImpactCue& cue) {
    const ogre::Vec3 place = foot();
    const bool is_sound = cue.kind == look::ImpactCueKind::kSound;
    if (is_sound) hear_at(cue.name, place);
    if (cue.kind != look::ImpactCueKind::kOnce) return;
    const look::FlightPoint at = flight_at(place);
    static_cast<void>(spawn_tracked(cue.name, at));
}

const look::ImpactSlot* Display::State::impact_slot(std::uint32_t id) const {
    for (const look::ImpactSlot& slot : impacts.slots()) {
        if (slot.id == id) return &slot;
    }
    return nullptr;
}

ImpactHandle* Display::State::find_impact(std::uint32_t id) {
    for (ImpactHandle& item : impact_handles) {
        if (item.id == id) return &item;
    }
    return nullptr;
}

bool Display::State::drop_impact(const ImpactHandle& item) {
    const look::ImpactSlot* slot = impact_slot(item.id);
    const bool same = slot != nullptr && slot->continuous == item.name;
    // Handle 0 là lần dựng đã hỏng. Giữ ô để khung sau không dựng lại và không xối log.
    if (same && item.handle == 0) return false;
    const bool live = item.handle != 0 && fx_view->is_live(item.handle);
    if (same && live) return false;
    fx_view->release(item.handle);
    return true;
}

void Display::State::spawn_impact(const look::ImpactSlot& slot, const fx::Node& node) {
    fx::Spawn spawn;
    spawn.name = slot.continuous;
    spawn.is_effect = true;
    spawn.is_tracked = true;
    spawn.node = node;
    const std::uint32_t handle = fx_view->spawn(spawn);
    if (handle == 0) std::println(stderr, "Hiệu ứng {}: không dựng {}", slot.id, slot.continuous);
    ImpactHandle made;
    made.id = slot.id;
    made.name = slot.continuous;
    made.handle = handle;
    impact_handles.push_back(std::move(made));
}

void Display::State::keep_impact(const look::ImpactSlot& slot, const fx::Node& node) {
    if (slot.continuous.empty()) return;
    ImpactHandle* known = find_impact(slot.id);
    if (known != nullptr) return fx_view->move(known->handle, node);
    spawn_impact(slot, node);
}

void Display::State::release_flight(std::uint32_t handle) {
    if (fx_view && handle != 0) fx_view->release(handle);
}

void Display::State::open_bullet(const look::BulletRow& row, std::uint32_t id,
    look::FlightPoint to) {
    if (live_bullets.size() >= kMaxLiveBullets) {
        release_flight(live_bullets.front().handle);
        live_bullets.erase(live_bullets.begin());
    }
    const ogre::Vec3 place = foot();
    const look::FlightPoint from = flight_at(place);
    const float speed = row.speed * ground->file.scale.x;
    LiveBullet live;
    live.flight = look::begin_flight(row.trail, speed, 0.0F, from, to);
    live.target = id;
    live.explosion = row.explosion;
    live.explosion_sound = row.explosion_sound;
    const bool flies = row.trail != look::Trail::kNone && !row.flight.empty();
    if (flies) live.handle = spawn_tracked(row.flight, from);
    hear_at(row.flight_sound, place);
    live_bullets.push_back(std::move(live));
}

look::FlightPoint Display::State::bullet_aim(std::uint32_t id) const {
    const cast::Actor* actor = people.find(id);
    if (actor == nullptr) return look::FlightPoint{.x = -1.0F, .y = -1.0F, .z = -1.0F};
    const ogre::Vec3 place = world_foot(*actor);
    return flight_at(place);
}

void Display::State::burst_bullet(LiveBullet& live, look::FlightPoint at) {
    release_flight(live.handle);
    live.handle = 0;
    const ogre::Vec3 place = vec_of(at);
    hear_at(live.explosion_sound, place);
    if (live.explosion.empty()) return;
    static_cast<void>(spawn_tracked(live.explosion, at));
}

void Display::State::glide_bullet(const LiveBullet& live, const look::BulletStep& step) {
    if (live.handle == 0 || !fx_view) return;
    if (!fx_view->is_live(live.handle)) return;
    const ogre::Vec3 up = up_axis();
    fx::Node node;
    node.position = vec_of(step.at);
    node.orientation = ogre::quat_from_angle_axis(step.facing, up);
    fx_view->move(live.handle, node);
}

void Display::State::step_one_bullet(LiveBullet& live) {
    const look::FlightPoint aim = bullet_aim(live.target);
    const look::BulletStep step = look::step_bullet(live.flight, aim, frame_seconds);
    live.flight.at = step.at;
    live.flight.hit = step.hit;
    if (step.hit) return burst_bullet(live, step.at);
    glide_bullet(live, step);
}

void Display::State::ensure_actor_fx() {
    if (actor_fx_ready) return;
    actor_fx_ready = true;
    if (data_root.empty()) return;
    const std::string impacts_text = table_text("impacts.tsv");
    const std::string bullets_text = table_text("bullets.tsv");
    const std::string skills_text = table_text("skill_bullets.tsv");
    take_impacts(impacts_text);
    take_bullets(bullets_text);
    take_skills(skills_text);
}

void Display::State::arm_impact() {
    if (!impact_demo || !fx_view) return;
    ensure_actor_fx();
    const std::uint32_t id = *impact_demo;
    impact_demo.reset();
    if (!impacts.known(id)) std::println(stderr, "Hiệu ứng {}: không có dòng", id);
    const std::vector<look::ImpactCue> cues = impacts.enable(id, true);
    for (const look::ImpactCue& cue : cues)
        apply_one_cue(cue);
}

void Display::State::sync_impacts() {
    if (!fx_view) return;
    ensure_actor_fx();
    const fx::Node node = body_node();
    const auto drop = [this](const ImpactHandle& held) { return drop_impact(held); };
    std::erase_if(impact_handles, drop);
    for (const look::ImpactSlot& slot : impacts.slots())
        keep_impact(slot, node);
}

void Display::State::launch_bullet(const StrikeCall& call) {
    // Khác gốc: chưa có sự kiện logic đạn, chỉ bắn khi đang có mục tiêu.
    const bool has_ground = ground != nullptr && scale_ok(ground->file);
    const bool can_fly = fx_view != nullptr && terrain.has_value();
    if (!has_ground || !can_fly) return;
    ensure_actor_fx();
    const look::SkillBullet* skill = skill_bullets.find(call.skill);
    if (skill == nullptr) return;
    const look::BulletRow* row = bullets.find(skill->bullet);
    if (row == nullptr) return;
    const std::optional<std::uint32_t> aimed = combat.target();
    if (!aimed) return;
    const cast::Actor* actor = people.find(*aimed);
    if (actor == nullptr) return;
    const ogre::Vec3 place = world_foot(*actor);
    const look::FlightPoint to = flight_at(place);
    open_bullet(*row, *aimed, to);
}

void Display::State::step_bullets() {
    const bool has_room = ground != nullptr && terrain.has_value();
    if (live_bullets.empty() || !has_room) return;
    for (LiveBullet& live : live_bullets)
        step_one_bullet(live);
    const auto done = [](const LiveBullet& live) { return live.flight.hit; };
    std::erase_if(live_bullets, done);
}

} // namespace game::client
