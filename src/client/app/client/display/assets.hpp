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
    {Asset::kUiPipeline, render::Tier::kBootstrap, render::Group::kUi, true, "pipeline giao diện"},
    {Asset::kUiLayout, render::Tier::kBootstrap, render::Group::kUi, true, "layout giao diện"},
    {Asset::kUiFont, render::Tier::kBootstrap, render::Group::kUi, true, "phông chữ"},
    {Asset::kUiImage, render::Tier::kBootstrap, render::Group::kUi, true, "ảnh giao diện"},
    {Asset::kAudio, render::Tier::kBootstrap, render::Group::kCore, true, "âm thanh"},
    {Asset::kModelPipeline, render::Tier::kEssential, render::Group::kCharacter, true, "pipeline model"},
    {Asset::kCharacter, render::Tier::kEssential, render::Group::kCharacter, true, "nhân vật người chơi"},
    {Asset::kSceneMesh, render::Tier::kScene, render::Group::kWorld, true, "mesh cảnh"},
    {Asset::kTerrain, render::Tier::kScene, render::Group::kWorld, true, "địa hình"},
    {Asset::kWalk, render::Tier::kScene, render::Group::kWorld, true, "lưới đi"},
    {Asset::kSkyLight, render::Tier::kScene, render::Group::kLight, true, "ánh sáng bầu trời"},
    {Asset::kRadar, render::Tier::kScene, render::Group::kUi, true, "ảnh minimap"},
    {Asset::kSceneGate, render::Tier::kScene, render::Group::kWorld, true, "cổng cảnh"},
    {Asset::kEffectPipeline, render::Tier::kScene, render::Group::kVfx, true, "pipeline hiệu ứng"},
    {Asset::kEffectData, render::Tier::kScene, render::Group::kVfx, true, "thư viện hiệu ứng"},
    {Asset::kSkyDome, render::Tier::kScene, render::Group::kWorld, true, "vòm trời"},
    {Asset::kLiquid, render::Tier::kScene, render::Group::kWorld, true, "mặt nước"},
    {Asset::kCollision, render::Tier::kScene, render::Group::kWorld, true, "va chạm công trình"},
    {Asset::kOtherActor, render::Tier::kScene, render::Group::kCharacter, true, "NPC và người chơi khác"},
    {Asset::kSpotLight, render::Tier::kEssential, render::Group::kLight, true, "đèn spot"},
    {Asset::kOptionalPipeline, render::Tier::kOptional, render::Group::kPost, false, "pipeline tầng 3"},
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
