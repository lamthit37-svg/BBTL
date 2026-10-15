/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/creature.cpp
 *  PHÂN HỆ   : Client / Display / Creature
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Quái và NPC trên màn hình (xem creature.hpp).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "client/display/creature.hpp"

#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "io/file.hpp"
#include "look/creature.hpp"
#include "look/look.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "render/forward.hpp"

#include <array>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <expected>
#include <filesystem>
#include <future>
#include <memory>
#include <optional>
#include <print>
#include <string>
#include <utility>
#include <vector>

namespace game::client {
namespace {

// Ma trận đặt: phóng theo ba trục của mẫu, quay quanh +y theo hướng mặt rồi dời tới chân. Hướng 0 nhìn +z, hướng pi/2
// nhìn +x (cùng phép với PlayerActor, chỉ thêm tỉ lệ riêng từng trục).
[[nodiscard]] math::Matrix4 placement(const CreatureStand& stand, const std::array<float, 3>& scale) {
    const float sine = std::sin(stand.facing);
    const float cosine = std::cos(stand.facing);
    const math::Vector4 col0(cosine * scale[0], 0.0F, -sine * scale[0], 0.0F);
    const math::Vector4 col1(0.0F, scale[1], 0.0F, 0.0F);
    const math::Vector4 col2(sine * scale[2], 0.0F, cosine * scale[2], 0.0F);
    const math::Vector4 col3(stand.foot.x(), stand.foot.y(), stand.foot.z(), 1.0F);
    return {col0, col1, col2, col3};
}

// Mọi lưới của hình; lưới không nạp được thì bỏ, ghi log, vẽ phần còn lại.
std::vector<const render::Drawable*> load_parts(const look::CreatureFigure& figure, const look::CreatureTables& tables,
    const CreatureMeshLoader& load_mesh) {
    std::vector<const render::Drawable*> parts;
    parts.reserve(figure.figure.parts.size());
    for (const look::Part& part : figure.figure.parts) {
        const look::CreatureMaterial* skin = part.materials.empty() ? nullptr : tables.find_material(part.materials.front());
        const render::Drawable* drawable = load_mesh(part.mesh, skin);
        if (drawable == nullptr) {
            std::println(stderr, "Quái/NPC: bỏ lưới {}", part.mesh);
            continue;
        }
        parts.push_back(drawable);
    }
    return parts;
}

[[nodiscard]] std::expected<std::string, std::string> read_table(const std::string& path) {
    const auto text = io::read_text(io::path_from_utf8(path));
    if (!text) return std::unexpected(std::string(io::describe(text.error())));
    return *text;
}

} // namespace

CreatureTablesJob start_creature_tables(std::filesystem::path data_root) {
    return std::async(std::launch::async, [root = std::move(data_root)]() -> std::shared_ptr<const look::CreatureTables> {
        auto loaded = look::load_creature_tables(io::utf8_of(root / "Table"), read_table);
        if (!loaded) {
            std::println(stderr, "Quái/NPC: không đọc được bảng: {}", loaded.error());
            return nullptr;
        }
        return std::make_shared<const look::CreatureTables>(std::move(*loaded));
    });
}

core::Result<std::shared_ptr<const CreatureAsset>> CreatureAsset::create(look::CreatureFigure figure,
    const look::CreatureTables& tables, const std::filesystem::path& data_root, const CreatureMeshLoader& load_mesh) {
    std::optional<avatar::Avatar> avatar;
    if (figure.is_animated) {
        auto loaded = avatar::Avatar::load(figure.figure, data_root);
        if (!loaded) return std::unexpected(loaded.error());
        avatar.emplace(std::move(*loaded));
    }
    std::vector<const render::Drawable*> parts = load_parts(figure, tables, load_mesh);
    if (parts.empty()) return core::fail(core::ErrorCode::kNotFound, "không lưới nào nạp được");
    return std::make_shared<const CreatureAsset>(std::move(figure), std::move(avatar), std::move(parts));
}

CreatureActor::CreatureActor(std::shared_ptr<const CreatureAsset> asset, std::uint32_t seed)
    : asset_(std::move(asset)),
      gait_(seed, avatar::kIdleInterval),
      lengths_(asset_->avatar() ? asset_->avatar()->lengths() : avatar::ClipLengths{}) {
    gait_.set_fidget(true);
}

core::Status CreatureActor::update(core::Clock::time_point now, const CreatureStand& stand) {
    if (asset_->avatar()) {
        const avatar::Playing playing = gait_.update(now, stand.is_moving, lengths_);
        const core::Status posed = skinner_.update(*asset_->avatar(), playing);
        if (!posed) return posed;
    }
    placed_ = placement(stand, asset_->figure().scale);
    return core::ok();
}

void CreatureActor::append(std::vector<render::Instance>& out) const {
    for (const render::Drawable* drawable : asset_->parts()) {
        render::Instance instance;
        instance.drawable = drawable;
        instance.world = placed_;
        instance.joints = skinner_.joints();
        instance.is_actor = true;
        out.push_back(instance);
    }
}

} // namespace game::client
