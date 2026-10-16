/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/graphic/creature.cpp
 *  PHÂN HỆ   : Display / Graphic / Creature
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Quái và NPC trong cảnh: bảng, hình dùng chung theo template và tư thế mỗi
 *    khung (xem display/creature.hpp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/graphic/state.hpp"

#include "client/cast/cast.hpp"
#include "client/cast/note.hpp"
#include "client/display/creature.hpp"
#include "client/display/display.hpp"
#include "client/display/graphic/prelude.hpp"
#include "client/map/terrain.hpp"
#include "core/error.hpp"
#include "core/ground_point.hpp"

#include <ranges>
#include "io/file.hpp"
#include "look/creature.hpp"
#include "look/look.hpp"
#include "math/vector.hpp"
#include "ogre/vec3.hpp"
#include "render/forward.hpp"
#include "resource/image.hpp"
#include "resource/model.hpp"
#include "resource/ogre_mesh.hpp"
#include "resource/tier.hpp"

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <format>
#include <future>
#include <memory>
#include <numbers>
#include <optional>
#include <print>
#include <span>
#include <string>
#include <system_error>
#include <utility>

namespace game::client {
namespace {

// Hình mới nạp mỗi khung: nạp một hình là đọc xương, clip và lưới rồi đưa lên GPU, nên cảnh đông (hàng chục mẫu khác nhau)
// được trải ra nhiều khung thay vì đứng hình một lần.
constexpr std::size_t kNewAssetsPerFrame = 1;
// Người chơi khác dùng lưới đã cache theo tên. Bốn người một khung là trần của --peer và một cụm AOI nhỏ.
constexpr std::size_t kNewPeersPerFrame = 4;
// Trân thú cùng đường lưới với quái. Bốn con một khung đủ cho --pet và một nhóm nhỏ vừa vào vùng nhìn.
constexpr std::size_t kNewPetsPerFrame = 4;

// Giới trên dây là 1 nữ, 2 nam (EntityAppear). Race của bảng ngoại hình là 0 nữ, 1 nam.
[[nodiscard]] std::optional<look::Race> race_of_wire(std::uint8_t gender) noexcept {
    if (gender == 1) return look::Race::kFemale;
    if (gender == 2) return look::Race::kMale;
    return std::nullopt;
}

// Lưới chỉ có bản nấu .mesh.glb thì dùng nó; không thì giữ tên gốc để load_named_model báo lỗi có tên tệp.
[[nodiscard]] std::string resolve_mesh(const std::filesystem::path& data_root, const std::string& mesh) {
    std::error_code ignored;
    const std::filesystem::path folder = data_root / "Model";
    if (std::filesystem::is_regular_file(folder / io::path_from_utf8(mesh), ignored)) return mesh;
    std::string cooked = mesh + ".glb";
    if (std::filesystem::is_regular_file(folder / io::path_from_utf8(cooked), ignored)) return cooked;
    return mesh;
}

[[nodiscard]] resource::Alpha alpha_of(look::OverlayAlpha alpha) noexcept {
    switch (alpha) {
    case look::OverlayAlpha::kMask:
        return resource::Alpha::kMask;
    case look::OverlayAlpha::kBlend:
        return resource::Alpha::kBlend;
    case look::OverlayAlpha::kOpaque:
        break;
    }
    return resource::Alpha::kOpaque;
}

// Material chỉ có ảnh nền thì ảnh gốc của nó thay được hẳn; có khe khác (pháp tuyến, phát sáng) thì ảnh còn có người dùng.
[[nodiscard]] bool is_color_only(const resource::Material& material) noexcept {
    return !material.surface.image && !material.normal.image && !material.occlusion.image && !material.emissive_map.image &&
        !material.diffuse_map.image && !material.gloss_map.image;
}

// Thay ảnh nền của mọi material trong mô hình bằng ảnh của material chồng, với cách trộn của nó. Sai khi không đọc được ảnh.
[[nodiscard]] bool apply_skin(resource::Model& model, const look::CreatureMaterial& skin,
    const std::filesystem::path& data_root, resource::TextureTier tier) {
    // Điện thoại có bản nấu ASTC/ETC2 của ảnh thì lấy nó (nhỏ hơn RGBA8 bốn lần trên GPU); PC giữ đường dẫn gốc.
    core::Result<resource::Image> image =
        resource::load_image_file(resource::texture_file(io::utf8_of(data_root), skin.texture, tier));
    if (!image) {
        std::println(stderr, "Quái/NPC: không đọc được ảnh {}: {}", skin.texture, image.error());
        return false;
    }
    if (model.materials.empty()) return false;
    image->name = skin.texture;
    if (std::ranges::all_of(model.materials, is_color_only)) model.images.clear();
    const auto image_index = static_cast<std::uint32_t>(model.images.size());
    model.images.push_back(std::move(*image));
    const auto sampler_index = static_cast<std::uint32_t>(model.samplers.size());
    model.samplers.emplace_back();
    for (resource::Material& material : model.materials) {
        material.color.image = image_index;
        material.color.sampler = sampler_index;
        material.alpha = alpha_of(skin.alpha);
        material.alpha_cutoff = skin.cutoff;
        material.double_sided = skin.double_sided;
        material.unlit = skin.unlit;
    }
    return true;
}

} // namespace

std::size_t Display::State::load_skinned_mesh(const std::string& mesh, const look::CreatureMaterial& skin) {
    const std::string key = std::format("{}\n{}", mesh, skin.name);
    const auto found = kept_by_name.find(key);
    if (found != kept_by_name.end()) return found->second;
    auto model = resource::load_named_model(mesh, io::utf8_of(data_root), texture_tier);
    if (!model) {
        std::println(stderr, "Bỏ mesh {}: {}", mesh, model.error());
        kept_by_name.emplace(key, kMissing);
        return kMissing;
    }
    if (!apply_skin(*model, skin, data_root, texture_tier)) {
        kept_by_name.emplace(key, kMissing);
        return kMissing;
    }
    return keep_model(key, baked_mesh(std::move(*model), bake_rules()));
}

const render::Drawable* Display::State::load_creature_mesh(const std::string& mesh, const look::CreatureMaterial* skin) {
    const std::string name = resolve_mesh(data_root, mesh);
    const std::size_t index = skin == nullptr ? load_mesh(name) : load_skinned_mesh(name, *skin);
    return index == kMissing ? nullptr : &kept.at(index).loaded.drawable;
}

const look::CreatureTables* Display::State::ready_creature_tables() {
    if (creature_tables) return creature_tables.get();
    if (data_root.empty() || creature_tables_failed) return nullptr;
    if (!creature_job.valid()) {
        creature_job = start_creature_tables(data_root);
        return nullptr;
    }
    if (creature_job.wait_for(std::chrono::seconds::zero()) != std::future_status::ready) return nullptr;
    creature_tables = creature_job.get();
    creature_tables_failed = creature_tables == nullptr;
    return creature_tables.get();
}

std::shared_ptr<const CreatureAsset> Display::State::build_creature_asset(std::uint32_t template_id) {
    const auto figure = look::creature_figure(*creature_tables, template_id);
    if (!figure) {
        std::println(stderr, "Quái/NPC {}: {}", template_id, figure.error());
        return nullptr;
    }
    const CreatureMeshLoader loader = [this](const std::string& mesh, const look::CreatureMaterial* skin) {
        return load_creature_mesh(mesh, skin);
    };
    auto created = CreatureAsset::create(*figure, *creature_tables, data_root, loader);
    if (!created) {
        std::println(stderr, "Quái/NPC {} ({}): {}", template_id, figure->figure.skeleton, created.error());
        return nullptr;
    }
    return std::move(*created);
}

std::shared_ptr<const CreatureAsset> Display::State::creature_asset(std::uint32_t template_id, std::size_t& budget) {
    const auto found = creature_assets.find(template_id);
    if (found != creature_assets.end()) return found->second;
    if (budget == 0) return nullptr;
    --budget;
    // Hình hỏng cũng được nhớ (nullptr) để chỉ ghi log một lần cho template đó.
    std::shared_ptr<const CreatureAsset> made = build_creature_asset(template_id);
    creature_assets.emplace(template_id, made);
    return made;
}

// Chân đứng của thực thể ở toạ độ game (x, z): địa hình, nâng lên mặt công trình nếu có (như chân người chơi). Cần ground
// và terrain đã có; append_creatures và talkable_at kiểm trước khi gọi.
ogre::Vec3 Display::State::world_foot(const cast::Actor& actor) const {
    const map::TerrainFile& file = ground->file;
    const float world_x = file.origin.x + (actor.x * file.scale.x);
    const float world_z = file.origin.z + (actor.z * file.scale.z);
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access): append_creatures và talkable_at đã kiểm terrain trước khi gọi
    const float terrain_y = terrain->height_at(world_x, world_z);
    const float world_y = surface_y(held.get(), ground, world_x, world_z, terrain_y);
    return ogre::Vec3{.x = world_x, .y = world_y, .z = world_z};
}

math::Point3 Display::State::stand_of(const cast::Actor& actor) const {
    return point_of(world_foot(actor));
}

void Display::State::show_player(const cast::Actor& actor, std::size_t& budget) {
    // Xác người nằm lại là phần sau: 2008 dùng CHARACTER_LOGIC_DEAD, client này chưa có tư thế xác.
    if (actor.pose == cast::Pose::kDead) return;
    const std::optional<look::Race> race = race_of_wire(actor.gender);
    if (!race) return;
    auto slot = peers.find(actor.id);
    const bool same = slot != peers.end() && slot->second.gender == actor.gender && slot->second.face == actor.face &&
        slot->second.hair == actor.hair && (slot->second.actor.has_value() || slot->second.is_broken);
    if (!same) {
        if (budget == 0) return;
        --budget;
        PeerSlot fresh;
        fresh.gender = actor.gender;
        fresh.face = actor.face;
        fresh.hair = actor.hair;
        fresh.seen = peer_epoch;
        PlayerDesc desc;
        desc.data_root = data_root;
        desc.race = *race;
        desc.look = look::Look{.face = actor.face, .hair = actor.hair};
        desc.skills = fresh.skills;
        desc.tables = player_tables;
        core::Result<PlayerActor> made = PlayerActor::create(desc, meshes());
        if (!made) {
            std::println(stderr, "Người chơi khác {}: {}", actor.id, made.error());
            fresh.is_broken = true;
            peers.insert_or_assign(actor.id, std::move(fresh));
            return;
        }
        fresh.actor = std::move(*made);
        slot = peers.insert_or_assign(actor.id, std::move(fresh)).first;
    }
    PeerSlot& shown = slot->second;
    shown.seen = peer_epoch;
    if (shown.is_broken || !shown.actor) return;
    if (shown.pending_skill && shown.actor->steps_of(*shown.pending_skill).empty() && shown.skills.size() < 32) {
        const std::uint32_t skill = *shown.pending_skill;
        if (std::ranges::find(shown.skills, skill) == shown.skills.end()) shown.skills.push_back(skill);
        PlayerDesc desc;
        desc.data_root = data_root;
        desc.race = *race;
        desc.look = look::Look{.face = actor.face, .hair = actor.hair};
        desc.skills = shown.skills;
        desc.tables = player_tables;
        core::Result<PlayerActor> made = PlayerActor::create(desc, meshes());
        if (!made) {
            std::println(stderr, "Người chơi khác {}: {}", actor.id, made.error());
            shown.is_broken = true;
            return;
        }
        shown.actor = std::move(*made);
    }
    Stand stand;
    stand.foot = stand_of(actor);
    stand.facing = actor.facing;
    stand.is_moving = actor.pose == cast::Pose::kWalk;
    if (shown.pending_skill && !shown.actor->steps_of(*shown.pending_skill).empty()) {
        const std::optional<std::uint32_t> step = shown.actor->accept_strike(*shown.pending_skill, strike_dice(), frame_time);
        if (step) stand.strike = StrikeCall{.skill = *shown.pending_skill, .step = *step};
    }
    shown.pending_skill.reset();
    const core::Status posed = shown.actor->update(frame_time, stand);
    if (!posed) {
        std::println(stderr, "Người chơi khác {}: {}", actor.id, posed.error());
        shown.is_broken = true;
        return;
    }
    dispatch_actor_cues(*shown.actor, actor.id);
    shown.actor->append(frame_instances);
}

void Display::State::show_creature(const cast::Actor& actor, std::size_t& budget) {
    // 2008: CObject_PlayerPet::CreateRenderInterface lấy szModeleFile của mẫu creature rồi SetActorFile.
    // Trang bị đè lên mẫu chưa có trên dây, cùng lỗ với người chơi khác.
    const bool is_body = actor.kind == cast::Kind::kMonster || actor.kind == cast::Kind::kNpc || actor.kind == cast::Kind::kPet;
    if (!is_body) return;
    // Xác chưa vẽ: thực thể chết không có chỗ nào đứng trong khung (hợp đồng ở creature.hpp).
    if (actor.pose == cast::Pose::kDead) return;
    auto slot = creatures.find(actor.id);
    if (slot == creatures.end() || slot->second.template_id != actor.template_id) {
        std::shared_ptr<const CreatureAsset> asset = creature_asset(actor.template_id, budget);
        if (!asset) return;
        CreatureSlot fresh{.template_id = actor.template_id, .actor = CreatureActor(std::move(asset), actor.id)};
        slot = creatures.insert_or_assign(actor.id, std::move(fresh)).first;
    }
    CreatureSlot& shown = slot->second;
    shown.seen = creature_epoch;
    if (shown.is_broken) return;
    CreatureStand stand;
    stand.foot = stand_of(actor);
    stand.facing = actor.facing;
    stand.is_moving = actor.pose == cast::Pose::kWalk;
    const core::Status posed = shown.actor.update(frame_time, stand);
    if (!posed) {
        const char* const who = actor.kind == cast::Kind::kPet ? "Trân thú" : "Quái/NPC";
        std::println(stderr, "{} {}: {}", who, actor.id, posed.error());
        shown.is_broken = true;
        return;
    }
    shown.actor.append(frame_instances);
}

// Công cụ thử (--creature): báo cho people như máy chủ vừa cho thấy các mẫu. Nhiều mẫu xếp lưới tám cột cách ba mét, hàng đầu
// cách năm mét. Một mẫu đứng trước mặt; --talk-demo fight thì trong tầm đòn. Mặt quay về phía nhân vật.
void Display::State::seed_creature_demo(int scene_id) {
    constexpr std::size_t kColumns = 8;
    // Cột giữa của tám cột: lưới đối xứng qua nhân vật.
    constexpr float kCenter = 3.5F;
    constexpr float kSpacing = 3.0F;
    constexpr float kFirstRow = 5.0F;
    // Một con đứng trước mặt. 2,4 m thì camera nhìn từ trên chồng tên lên người. Lưới tám cột dành cho nhiều mẫu.
    constexpr std::uint32_t kFirstId = 1000;
    const core::GroundPoint here = game_of(ground->file, walk);
    const bool is_fight = is_fight_demo();
    const bool is_talk = !talk_demo.empty() && !is_fight;
    people.apply(cast::Arrive{.scene = static_cast<std::uint16_t>(scene_id), .x = here.x, .z = here.z, .self_id = 1});
    for (std::size_t at = 0; at < creature_demo.size(); ++at) {
        const float column = creature_demo.size() == 1 ? 0.0F : static_cast<float>(at % kColumns) - kCenter;
        const std::size_t line = at / kColumns;
        cast::Spawn spawn;
        spawn.id = kFirstId + static_cast<std::uint32_t>(at);
        spawn.template_id = creature_demo[at];
        spawn.x = here.x + (column * kSpacing);
        spawn.z = here.z + kFirstRow + (static_cast<float>(line) * kSpacing);
        spawn.facing = std::numbers::pi_v<float>;
        if (is_talk) spawn.kind = cast::Kind::kNpc;
        people.apply(spawn);
        if (is_talk) people.apply(cast::Flagged{.id = spawn.id, .flags = cast::kFlagTalk});
    }
    if (is_talk && !creature_demo.empty()) open_demo(kFirstId);
    if (is_fight && !creature_demo.empty()) start_fight_demo(kFirstId);
    creature_demo.clear();
}

// Công cụ thử (--peer): nữ (giới 1) rồi nam (giới 2), bộ mặc định, đứng trước mặt. Id từ 2000 để không đụng --creature.
void Display::State::seed_peer_demo(int scene_id) {
    constexpr std::uint32_t kFirstId = 2000;
    constexpr float kSpacing = 2.0F;
    constexpr float kAhead = 4.0F;
    const std::uint32_t count = peer_demo;
    peer_demo = 0;
    if (count == 0) return;
    const core::GroundPoint here = game_of(ground->file, walk);
    if (!people.scene()) {
        people.apply(cast::Arrive{.scene = static_cast<std::uint16_t>(scene_id), .x = here.x, .z = here.z, .self_id = 1});
    }
    for (std::uint32_t at = 0; at < count; ++at) {
        cast::Spawn spawn;
        spawn.id = kFirstId + at;
        spawn.kind = cast::Kind::kPlayer;
        spawn.gender = at % 2U == 0U ? std::uint8_t{1} : std::uint8_t{2};
        spawn.x = here.x + ((static_cast<float>(at) - 0.5F * static_cast<float>(count - 1U)) * kSpacing);
        spawn.z = here.z + kAhead;
        spawn.facing = std::numbers::pi_v<float>;
        people.apply(spawn);
    }
}

// Công cụ thử (--pet): mẫu creature đứng như trân thú (EntityKind::kPet), hàng cách nhân vật ba mét rưỡi.
void Display::State::seed_pet_demo(int scene_id) {
    constexpr std::uint32_t kFirstId = 3000;
    constexpr float kSpacing = 2.5F;
    constexpr float kAhead = 3.5F;
    const core::GroundPoint here = game_of(ground->file, walk);
    if (!people.scene()) {
        people.apply(cast::Arrive{.scene = static_cast<std::uint16_t>(scene_id), .x = here.x, .z = here.z, .self_id = 1});
    }
    const std::size_t count = pet_demo.size();
    for (std::size_t at = 0; at < count; ++at) {
        cast::Spawn spawn;
        spawn.id = kFirstId + static_cast<std::uint32_t>(at);
        spawn.kind = cast::Kind::kPet;
        spawn.template_id = pet_demo[at];
        const float column = static_cast<float>(at) - 0.5F * static_cast<float>(count - 1U);
        spawn.x = here.x + (column * kSpacing);
        spawn.z = here.z + kAhead;
        spawn.facing = std::numbers::pi_v<float>;
        people.apply(spawn);
    }
    pet_demo.clear();
}

void Display::State::append_creatures() {
    const std::span<const cast::Actor> actors = people.actors();
    if (actors.empty()) {
        creatures.clear();
        peers.clear();
        return;
    }
    if (ground == nullptr || !terrain || !scale_ok(ground->file)) return;
    const std::optional<std::uint16_t> online_scene = people.scene();
    if (!online_scene || std::cmp_not_equal(walk.scene_id, *online_scene)) return;
    ++peer_epoch;
    std::size_t peer_budget = kNewPeersPerFrame;
    for (const cast::Actor& actor : actors) {
        if (actor.kind == cast::Kind::kPlayer) show_player(actor, peer_budget);
    }
    std::erase_if(peers, [epoch = peer_epoch](const auto& entry) { return entry.second.seen != epoch; });
    if (ready_creature_tables() == nullptr) return;
    ++creature_epoch;
    std::size_t budget = kNewAssetsPerFrame;
    std::size_t pet_budget = kNewPetsPerFrame;
    for (const cast::Actor& actor : actors) {
        if (actor.kind == cast::Kind::kPlayer) continue;
        std::size_t& slot = actor.kind == cast::Kind::kPet ? pet_budget : budget;
        show_creature(actor, slot);
    }
    std::erase_if(creatures, [epoch = creature_epoch](const auto& entry) { return entry.second.seen != epoch; });
}

} // namespace game::client
