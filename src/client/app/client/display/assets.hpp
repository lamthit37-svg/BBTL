// Cổng nạp của từng loại tài nguyên. is_used: client đọc tệp và đưa vào thứ đang chạy
// (vẽ, mô phỏng hoặc tra cứu). Bộ đọc có sẵn mà không ai gọi thì is_used sai.
// Nhóm là chỗ quản lý; tài nguyên không phải PSO vẫn mang nhóm của lúc nó được nạp.
// kOtherActor là object Model trong cảnh. Người chơi qua mạng chưa có socket.
// kOptionalPipeline trống: chưa có shader tầng 3, không bịa pipeline.
#pragma once

#include "render/catalog.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>

namespace game::client {

enum class Asset : std::uint8_t {
    kUiPipeline,
    kUiLayout,
    kUiFont,
    kUiImage,
    kAudio,
    kModelPipeline,
    kCharacter,
    kSceneMesh,
    kTerrain,
    kWalk,
    kSkyLight,
    kRadar,
    kSceneGate,
    kEffectPipeline,
    kEffectData,
    kSkyDome,
    kLiquid,
    kCollision,
    kOtherActor,
    kSpotLight,
    kOptionalPipeline,
    kCount,
};

struct AssetGate {
    Asset asset = Asset::kUiPipeline;
    render::Tier tier = render::Tier::kBootstrap;
    render::Group group = render::Group::kCore;
    bool is_used = false;
    std::string_view name;
};

// Một dòng một loại. Thêm loại là thêm một enumerator và một dòng, đúng thứ tự.
inline constexpr std::array<AssetGate, static_cast<std::size_t>(Asset::kCount)> kAssets{{
    {.asset = Asset::kUiPipeline, .tier = render::Tier::kBootstrap, .group = render::Group::kUi, .is_used = true, .name = "pipeline giao diện"},
    {.asset = Asset::kUiLayout, .tier = render::Tier::kBootstrap, .group = render::Group::kUi, .is_used = true, .name = "layout giao diện"},
    {.asset = Asset::kUiFont, .tier = render::Tier::kBootstrap, .group = render::Group::kUi, .is_used = true, .name = "phông chữ"},
    {.asset = Asset::kUiImage, .tier = render::Tier::kBootstrap, .group = render::Group::kUi, .is_used = true, .name = "ảnh giao diện"},
    {.asset = Asset::kAudio, .tier = render::Tier::kBootstrap, .group = render::Group::kCore, .is_used = true, .name = "âm thanh"},
    {.asset = Asset::kModelPipeline, .tier = render::Tier::kEssential, .group = render::Group::kCharacter, .is_used = true, .name = "pipeline model"},
    {.asset = Asset::kCharacter, .tier = render::Tier::kEssential, .group = render::Group::kCharacter, .is_used = true, .name = "nhân vật người chơi"},
    {.asset = Asset::kSceneMesh, .tier = render::Tier::kScene, .group = render::Group::kWorld, .is_used = true, .name = "mesh cảnh"},
    {.asset = Asset::kTerrain, .tier = render::Tier::kScene, .group = render::Group::kWorld, .is_used = true, .name = "địa hình"},
    {.asset = Asset::kWalk, .tier = render::Tier::kScene, .group = render::Group::kWorld, .is_used = true, .name = "lưới đi"},
    {.asset = Asset::kSkyLight, .tier = render::Tier::kScene, .group = render::Group::kLight, .is_used = true, .name = "ánh sáng bầu trời"},
    {.asset = Asset::kRadar, .tier = render::Tier::kScene, .group = render::Group::kUi, .is_used = true, .name = "ảnh minimap"},
    {.asset = Asset::kSceneGate, .tier = render::Tier::kScene, .group = render::Group::kWorld, .is_used = true, .name = "cổng cảnh"},
    {.asset = Asset::kEffectPipeline, .tier = render::Tier::kScene, .group = render::Group::kVfx, .is_used = true, .name = "pipeline hiệu ứng"},
    {.asset = Asset::kEffectData, .tier = render::Tier::kScene, .group = render::Group::kVfx, .is_used = true, .name = "thư viện hiệu ứng"},
    {.asset = Asset::kSkyDome, .tier = render::Tier::kScene, .group = render::Group::kWorld, .is_used = true, .name = "vòm trời"},
    {.asset = Asset::kLiquid, .tier = render::Tier::kScene, .group = render::Group::kWorld, .is_used = true, .name = "mặt nước"},
    {.asset = Asset::kCollision, .tier = render::Tier::kScene, .group = render::Group::kWorld, .is_used = true, .name = "va chạm công trình"},
    {.asset = Asset::kOtherActor, .tier = render::Tier::kScene, .group = render::Group::kCharacter, .is_used = true, .name = "NPC và người chơi khác"},
    {.asset = Asset::kSpotLight, .tier = render::Tier::kEssential, .group = render::Group::kLight, .is_used = true, .name = "đèn spot"},
    {.asset = Asset::kOptionalPipeline, .tier = render::Tier::kOptional, .group = render::Group::kPost, .is_used = false, .name = "pipeline tầng 3"},
}};

[[nodiscard]] constexpr bool asset_rows_match() noexcept {
    for (std::size_t index = 0; index < kAssets.size(); ++index) {
        if (static_cast<std::size_t>(kAssets[index].asset) != index) return false;
    }
    return true;
}

[[nodiscard]] constexpr bool port_is(Asset asset, bool is_used) noexcept {
    for (const AssetGate& row : kAssets) {
        if (row.asset != asset) continue;
        return row.is_used == is_used;
    }
    return false;
}

[[nodiscard]] constexpr std::size_t closed_ports() noexcept {
    std::size_t count = 0;
    for (const AssetGate& row : kAssets) {
        if (!row.is_used) ++count;
    }
    return count;
}

static_assert(asset_rows_match());
static_assert(closed_ports() == 1);
static_assert(port_is(Asset::kSceneMesh, true));
static_assert(port_is(Asset::kTerrain, true));
static_assert(port_is(Asset::kSkyLight, true));
static_assert(port_is(Asset::kSkyDome, true));
static_assert(port_is(Asset::kLiquid, true));
static_assert(port_is(Asset::kCollision, true));
static_assert(port_is(Asset::kOtherActor, true));
static_assert(port_is(Asset::kSpotLight, true));
static_assert(port_is(Asset::kOptionalPipeline, false));

// Một dòng log. Rỗng khi mọi loại đã có đường dùng.
[[nodiscard]] inline std::string closed_port_line() {
    std::string line;
    for (const AssetGate& row : kAssets) {
        if (row.is_used) continue;
        if (!line.empty()) line.append(", ");
        line.append(row.name);
    }
    if (line.empty()) return {};
    return "Cổng nạp chưa dùng: " + line;
}

} // namespace game::client
