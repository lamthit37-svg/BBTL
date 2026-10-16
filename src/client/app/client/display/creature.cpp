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

#include "anim/pose.hpp"
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

#include <algorithm>
#include <array>
#include <chrono>
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

// Trần phần lùi mốc khi xác đã nằm sẵn. Clip chết dài hơn là dữ liệu hỏng; lùi quá thì duration_cast sang
// nano-giây tràn (hành vi không xác định). Hai phút đủ mọi cú ngã của client gốc.
constexpr float kLongestDeath = 120.0F;

// Clip chết phát một lần. Hết thì lặp xác, không có xác thì giữ đúng độ dài: apply chỉ quay về khung đầu khi thời
// điểm vượt độ dài, đúng bằng độ dài thì giữ khoá cuối. Không có clip nào thì thời điểm 0 (tư thế đứng).
[[nodiscard]] avatar::Playing death_playing(float elapsed, float death_length, float corpse_length) noexcept {
    if (!std::isfinite(elapsed) || elapsed < 0.0F) elapsed = 0.0F;
    const bool has_death = std::isfinite(death_length) && death_length > 0.0F;
    const bool has_corpse = std::isfinite(corpse_length) && corpse_length > 0.0F;
    if (has_death && elapsed < death_length) return {.stance = avatar::Stance::kDeath, .time = elapsed};
    if (has_corpse) {
        const float into = has_death ? elapsed - death_length : elapsed;
        const float time = into > 0.0F ? anim::loop_time(into, corpse_length) : 0.0F;
        return {.stance = avatar::Stance::kCorpse, .time = time};
    }
    if (has_death) return {.stance = avatar::Stance::kDeath, .time = death_length};
    return {.stance = avatar::Stance::kDeath, .time = 0.0F};
}

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

avatar::Playing CreatureActor::clip_at(core::Clock::time_point now, const CreatureStand& stand) {
    const std::optional<avatar::Avatar>& loaded = asset_->avatar();
    if (!loaded) return {};
    const avatar::Avatar& body = *loaded;
    if (!stand.is_dead) {
        died_at_.reset();
        has_lived_ = true;
        return gait_.update(now, stand.is_moving, lengths_);
    }
    if (!died_at_) {
        float skip = has_lived_ ? 0.0F : body.death_length();
        if (!std::isfinite(skip) || skip < 0.0F) skip = 0.0F;
        if (skip > kLongestDeath) skip = kLongestDeath;
        const auto lead = std::chrono::duration_cast<core::Clock::duration>(std::chrono::duration<float>(skip));
        died_at_ = now - lead;
    }
    const float elapsed = std::chrono::duration<float>(now - *died_at_).count();
    return death_playing(elapsed, body.death_length(), body.corpse_length());
}

core::Status CreatureActor::update(core::Clock::time_point now, const CreatureStand& stand) {
    if (asset_->avatar()) {
        const core::Status posed = skinner_.update(*asset_->avatar(), clip_at(now, stand));
        if (!posed) return posed;
    }
    placed_ = placement(stand, asset_->figure().scale);
    return core::ok();
}

float CreatureActor::board_lift(float terrain_scale_y) const noexcept {
    if (!(terrain_scale_y > 0.0F) || !std::isfinite(terrain_scale_y)) return 0.0F;
    const look::CreatureFigure& figure = asset_->figure();
    // 0,1 mét trên đỉnh, cùng số RFObj_Actor.cpp cộng sau bbox hay fBoardHeight.
    constexpr float kClearanceMetres = 0.1F;
    constexpr float kMaxBoardMetres = 40.0F;
    const float clearance = kClearanceMetres * terrain_scale_y;
    const float cap = kMaxBoardMetres * terrain_scale_y;
    float lift = clearance;
    if (figure.plate_height > 0.0F) lift += figure.plate_height * terrain_scale_y;
    else lift += figure.height * figure.scale[1];
    return std::min(lift, cap);
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
