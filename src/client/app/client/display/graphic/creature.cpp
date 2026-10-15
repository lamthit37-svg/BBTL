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
#include "io/file.hpp"
#include "look/creature.hpp"
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
        return kMissing;
    }
    if (!apply_skin(*model, skin, data_root, texture_tier)) return kMissing;
    return keep_model(key, baked_mesh(std::move(*model)));
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
// và terrain đã có; append_creatures kiểm trước khi gọi.
math::Point3 Display::State::stand_of(const cast::Actor& actor) const {
    const map::TerrainFile& file = ground->file;
    const float world_x = file.origin.x + (actor.x * file.scale.x);
    const float world_z = file.origin.z + (actor.z * file.scale.z);
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access): append_creatures đã kiểm terrain trước khi gọi
    const float terrain_y = terrain->height_at(world_x, world_z);
    const float world_y = surface_y(held.get(), ground, world_x, world_z, terrain_y);
    return point_of(ogre::Vec3{.x = world_x, .y = world_y, .z = world_z});
}

void Display::State::show_creature(const cast::Actor& actor, std::size_t& budget) {
    if (actor.kind != cast::Kind::kMonster && actor.kind != cast::Kind::kNpc) return;
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
        std::println(stderr, "Quái/NPC {}: {}", actor.id, posed.error());
        shown.is_broken = true;
        return;
    }
    shown.actor.append(frame_instances);
}

// Công cụ thử (--creature): báo cho people như máy chủ vừa cho thấy các mẫu, xếp lưới tám cột cách nhau ba mét, hàng đầu cách
// nhân vật năm mét, mặt quay về phía nhân vật.
void Display::State::seed_creature_demo(int scene_id) {
    constexpr std::size_t kColumns = 8;
    // Cột giữa của tám cột: lưới đối xứng qua nhân vật.
    constexpr float kCenter = 3.5F;
    constexpr float kSpacing = 3.0F;
    constexpr float kFirstRow = 5.0F;
    constexpr std::uint32_t kFirstId = 1000;
    const core::GroundPoint here = game_of(ground->file, walk);
    people.apply(cast::Arrive{.scene = static_cast<std::uint16_t>(scene_id), .x = here.x, .z = here.z, .self_id = 1});
    for (std::size_t at = 0; at < creature_demo.size(); ++at) {
        const auto column = static_cast<float>(at % kColumns) - kCenter;
        const std::size_t line = at / kColumns;
        cast::Spawn spawn;
        spawn.id = kFirstId + static_cast<std::uint32_t>(at);
        spawn.template_id = creature_demo[at];
        spawn.x = here.x + (column * kSpacing);
        spawn.z = here.z + kFirstRow + (static_cast<float>(line) * kSpacing);
        spawn.facing = std::numbers::pi_v<float>;
        people.apply(spawn);
    }
    creature_demo.clear();
}

void Display::State::append_creatures() {
    const std::span<const cast::Actor> actors = people.actors();
    if (actors.empty()) {
        creatures.clear();
        return;
    }
    if (ground == nullptr || !terrain || !scale_ok(ground->file)) return;
    const std::optional<std::uint16_t> online_scene = people.scene();
    if (!online_scene || std::cmp_not_equal(walk.scene_id, *online_scene)) return;
    if (ready_creature_tables() == nullptr) return;
    ++creature_epoch;
    std::size_t budget = kNewAssetsPerFrame;
    for (const cast::Actor& actor : actors) {
        show_creature(actor, budget);
    }
    std::erase_if(creatures, [epoch = creature_epoch](const auto& entry) { return entry.second.seen != epoch; });
}

} // namespace game::client
