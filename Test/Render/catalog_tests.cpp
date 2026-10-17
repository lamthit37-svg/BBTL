/*==============================================================================
 *  THIENLONG  |  TEST
 *------------------------------------------------------------------------------
 *  TỆP       : Test/Render/catalog_tests.cpp
 *  PHÂN HỆ   : Render / Catalog Tests
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bảng catalog không cần GPU: ui ở tầng 0, bốn biến thể model ở nhóm
 *    Character tầng 1, mặt đất lớp cọ và hai model đục không discard ở nhóm
 *    World tầng 1, fx ở tầng 2. Tên không trùng. Thêm dòng mà quên nhóm hoặc
 *    tầng thì ca nhóm trống hoặc ca tầng đỏ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/check.hpp"
#include "gpu/device.hpp"
#include "render/catalog.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

using render::Entry;
using render::Group;
using render::Pso;
using render::Tier;

[[nodiscard]] bool same(std::string_view left, std::string_view right) noexcept {
    return left == right;
}

void ui_opens_with_the_client(Context& context) {
    const auto table = render::entries();
    context.expect(table.size() == render::kSlotCount, "đủ số mục catalog");
    bool saw = false;
    for (const Entry& entry : table) {
        if (entry.pso != Pso::kUi) continue;
        saw = true;
        context.expect(entry.group == Group::kUi, "ui thuộc nhóm UI");
        context.expect(entry.tier == Tier::kBootstrap, "ui thuộc tầng 0");
        context.expect(!entry.is_required, "ui thiếu thì bỏ qua HUD");
        context.expect(entry.frame_bytes == 0, "ui không kiểm khối khung");
    }
    context.expect(saw, "có mục ui");
}

[[nodiscard]] bool name_clashes(std::span<const Entry> table, std::size_t left) noexcept {
    for (std::size_t right = left + 1; right < table.size(); ++right) {
        if (same(table[left].name, table[right].name)) return true;
    }
    return false;
}

void names_are_unique(Context& context) {
    const auto table = render::entries();
    bool clash = false;
    for (std::size_t left = 0; left < table.size(); ++left)
        clash = clash || name_clashes(table, left);
    context.expect(!clash, "tên PSO trùng");
}

// Cộng sáng và ghi độ sâu dùng chung model.vs, model.ps nhưng nằm sau bốn biến thể model.
enum class ModelKind : std::uint8_t { kVariant, kAdd, kDepth };

[[nodiscard]] ModelKind model_kind(Pso pso) noexcept {
    const bool is_add = pso == Pso::kModelAdd || pso == Pso::kModelAddTwoSided;
    if (is_add) return ModelKind::kAdd;
    const bool is_depth = pso == Pso::kModelDepth || pso == Pso::kModelDepthTwoSided;
    if (is_depth) return ModelKind::kDepth;
    return ModelKind::kVariant;
}

void expect_character(Context& context, const Entry& entry) {
    context.expect(entry.tier == Tier::kEssential, "nhân vật thuộc tầng 1");
    context.expect(same(entry.vertex, "model.vs"), "model dùng model.vs");
    context.expect(same(entry.pixel, "model.ps"), "model dùng model.ps");
    context.expect(entry.is_required, "model là bắt buộc");
    context.expect(entry.frame_bytes == render::kModelFrameBytes, "khối khung của model");
    context.expect(entry.draw_bytes == render::kModelDrawBytes, "khối lệnh vẽ của model");
}

void model_variants_are_character(Context& context) {
    std::array<std::size_t, 3> counts{};
    for (const Entry& entry : render::entries()) {
        if (entry.group != Group::kCharacter) continue;
        expect_character(context, entry);
        const ModelKind kind = model_kind(entry.pso);
        const auto index = static_cast<std::size_t>(entry.pso);
        const bool in_front = kind != ModelKind::kVariant || index < render::kModelVariants;
        context.expect(in_front, "biến thể model nằm ở bốn ô đầu");
        ++counts.at(std::to_underlying(kind));
    }
    const auto count = [&counts](ModelKind kind) { return counts.at(std::to_underlying(kind)); };
    context.expect(count(ModelKind::kVariant) == render::kModelVariants, "đúng bốn biến thể model");
    context.expect(count(ModelKind::kAdd) == 2, "hai pipeline cộng sáng của model");
    context.expect(count(ModelKind::kDepth) == 2, "hai pipeline ghi độ sâu của model");
}

void fx_waits_for_the_scene(Context& context) {
    bool saw_add = false;
    bool saw_blend = false;
    std::size_t fx = 0;
    for (const Entry& entry : render::entries()) {
        if (entry.group != Group::kVfx) continue;
        ++fx;
        if (entry.pso == Pso::kFx) saw_add = true;
        if (entry.pso == Pso::kFxBlend) saw_blend = true;
        context.expect(entry.tier == Tier::kScene, "fx thuộc tầng 2");
        context.expect(!entry.is_required, "fx thiếu thì bỏ qua hiệu ứng");
        context.expect(entry.frame_bytes == 0, "fx không kiểm khối khung");
        context.expect(same(entry.vertex, "fx.vs") && same(entry.pixel, "fx.ps"), "pipeline hạt chung shader");
    }
    context.expect(fx == 7, "bảy cách trộn của hạt");
    context.expect(saw_add && saw_blend, "có hạt cộng sáng và hạt trộn alpha");
}

// Bầu trời: ba PSO chung cặp sky.vs, sky.ps, sao có cặp star.vs, star.ps; cả bốn chung một khối hằng cho cả
// khung; tầng 2, thiếu thì không vẽ trời.
void sky_waits_for_the_scene(Context& context) {
    std::size_t sky = 0;
    for (const Entry& entry : render::entries()) {
        if (entry.group != Group::kSky) continue;
        ++sky;
        context.expect(entry.tier == Tier::kScene, "bầu trời thuộc tầng 2");
        context.expect(!entry.is_required, "bầu trời thiếu thì bỏ qua");
        context.expect(entry.frame_bytes == render::kSkyFrameBytes, "khối khung của bầu trời");
        context.expect(entry.draw_bytes == render::kSkyDrawBytes, "khối lệnh vẽ của bầu trời");
        const bool is_star = entry.pso == render::Pso::kSkyStar;
        const char* vertex = is_star ? "star.vs" : "sky.vs";
        const char* pixel = is_star ? "star.ps" : "sky.ps";
        context.expect(same(entry.vertex, vertex) && same(entry.pixel, pixel), "bầu trời chung shader");
    }
    context.expect(sky == 4, "vòm, mây, trăng mặt trời và sao");
}

void optional_tier_follows_the_gpu(Context& context) {
    gpu::DeviceCaps caps;
    gpu::AdapterInfo adapter;
    context.expect(!render::optional_tier_allowed(adapter, caps), "GPU thường không mở tầng 3");
    caps.mesh_shader = true;
    context.expect(render::optional_tier_allowed(adapter, caps), "mesh shader mở tầng 3");
    caps.mesh_shader = false;
    caps.ray_query = true;
    context.expect(render::optional_tier_allowed(adapter, caps), "ray query mở tầng 3");
    adapter.is_software = true;
    context.expect(!render::optional_tier_allowed(adapter, caps), "GPU phần mềm không mở tầng 3");
}

// Nhóm World là mặt đất lớp cọ và hai model đục không discard: đỉnh của model, điểm ảnh riêng, cùng hai khối hằng
// với model, tầng 1 (vẽ ngay khung đầu), không bắt buộc (thiếu gói thì vẽ bằng biến thể model thường).
void world_group_extends_the_model(Context& context) {
    std::size_t terrain = 0;
    std::size_t solid = 0;
    for (const Entry& entry : render::entries()) {
        if (entry.group != Group::kWorld) continue;
        const bool is_terrain = entry.pso == Pso::kTerrain;
        const bool is_solid = entry.pso == Pso::kModelSolid || entry.pso == Pso::kModelSolidTwoSided;
        terrain += is_terrain ? 1U : 0U;
        solid += is_solid ? 1U : 0U;
        context.expect(is_terrain || is_solid, "nhóm World chỉ có mặt đất và model đục");
        context.expect(same(entry.pixel, is_terrain ? "terrain.ps" : "model_solid.ps"), "điểm ảnh đúng gói");
        context.expect(entry.tier == Tier::kEssential, "nhóm World thuộc tầng 1");
        context.expect(same(entry.vertex, "model.vs"), "nhóm World dùng đỉnh của model");
        context.expect(!entry.is_required, "thiếu gói thì vẽ như chất liệu thường");
        context.expect(entry.frame_bytes == render::kModelFrameBytes, "khối khung là của model");
        context.expect(entry.draw_bytes == render::kModelDrawBytes, "khối lệnh vẽ là của model");
    }
    context.expect(terrain == 1 && solid == 2, "một mặt đất và hai model đục");
}

void idle_groups_stay_empty(Context& context) {
    for (const Entry& entry : render::entries()) {
        const bool is_idle = entry.group == Group::kCore || entry.group == Group::kLight ||
            entry.group == Group::kPost || entry.group == Group::kCompute;
        context.expect(!is_idle, "nhóm chưa có shader thì không có dòng");
        context.expect(entry.tier != Tier::kOptional, "tầng 3 đang trống");
    }
}

constexpr std::array<Case, 8> kCases{{
    {.name = "ui_opens_with_the_client", .body = &ui_opens_with_the_client},
    {.name = "names_are_unique", .body = &names_are_unique},
    {.name = "model_variants_are_character", .body = &model_variants_are_character},
    {.name = "fx_waits_for_the_scene", .body = &fx_waits_for_the_scene},
    {.name = "sky_waits_for_the_scene", .body = &sky_waits_for_the_scene},
    {.name = "optional_tier_follows_the_gpu", .body = &optional_tier_follows_the_gpu},
    {.name = "world_group_extends_the_model", .body = &world_group_extends_the_model},
    {.name = "idle_groups_stay_empty", .body = &idle_groups_stay_empty},
}};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "catalog_tests: mọi ca phải qua");
    return 0;
}
