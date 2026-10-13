// Bảng catalog không cần GPU: ui ở tầng 0, bốn biến thể model ở nhóm Character tầng 1, mặt đất lớp cọ ở nhóm
// World tầng 1, fx ở tầng 2. Tên không trùng. Thêm dòng mà quên nhóm hoặc tầng thì ca nhóm trống hoặc ca tầng đỏ.
#include "core/check.hpp"
#include "gpu/device.hpp"
#include "render/catalog.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <span>
#include <string_view>

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

void model_variants_are_character(Context& context) {
    std::size_t models = 0;
    for (const Entry& entry : render::entries()) {
        if (entry.group != Group::kCharacter) continue;
        ++models;
        context.expect(entry.tier == Tier::kEssential, "nhân vật thuộc tầng 1");
        context.expect(same(entry.vertex, "model.vs"), "model dùng model.vs");
        context.expect(same(entry.pixel, "model.ps"), "model dùng model.ps");
        context.expect(entry.is_required, "model là bắt buộc");
        context.expect(entry.frame_bytes == render::kModelFrameBytes, "khối khung của model");
        context.expect(entry.draw_bytes == render::kModelDrawBytes, "khối lệnh vẽ của model");
        const auto index = static_cast<std::size_t>(entry.pso);
        context.expect(index < render::kModelVariants, "biến thể model nằm ở bốn ô đầu");
    }
    context.expect(models == render::kModelVariants, "đúng bốn biến thể model");
}

void fx_waits_for_the_scene(Context& context) {
    bool saw_add = false;
    bool saw_blend = false;
    for (const Entry& entry : render::entries()) {
        const bool is_fx = entry.pso == Pso::kFx || entry.pso == Pso::kFxBlend;
        if (!is_fx) continue;
        if (entry.pso == Pso::kFx) saw_add = true;
        if (entry.pso == Pso::kFxBlend) saw_blend = true;
        context.expect(entry.group == Group::kVfx, "fx thuộc nhóm VFX");
        context.expect(entry.tier == Tier::kScene, "fx thuộc tầng 2");
        context.expect(!entry.is_required, "fx thiếu thì bỏ qua hiệu ứng");
        context.expect(entry.frame_bytes == 0, "fx không kiểm khối khung");
        context.expect(same(entry.vertex, "fx.vs") && same(entry.pixel, "fx.ps"), "hai pipeline hạt chung shader");
    }
    context.expect(saw_add && saw_blend, "có hạt cộng sáng và hạt trộn alpha");
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

// Mặt đất lớp cọ là dòng duy nhất của nhóm World: đỉnh của model, điểm ảnh riêng, cùng hai khối hằng với model.
void terrain_is_the_world_group(Context& context) {
    std::size_t terrain = 0;
    for (const Entry& entry : render::entries()) {
        if (entry.group != Group::kWorld) continue;
        ++terrain;
        context.expect(entry.pso == Pso::kTerrain, "nhóm World chỉ có mặt đất");
        context.expect(entry.tier == Tier::kEssential, "mặt đất thuộc tầng 1 (vẽ ngay khung đầu)");
        context.expect(same(entry.vertex, "model.vs"), "mặt đất dùng đỉnh của model");
        context.expect(same(entry.pixel, "terrain.ps"), "mặt đất có điểm ảnh riêng");
        context.expect(!entry.is_required, "thiếu terrain.ps thì mặt đất vẽ như chất liệu thường");
        context.expect(entry.frame_bytes == render::kModelFrameBytes, "khối khung của mặt đất là của model");
        context.expect(entry.draw_bytes == render::kModelDrawBytes, "khối lệnh vẽ của mặt đất là của model");
    }
    context.expect(terrain == 1, "đúng một dòng nhóm World");
}

void idle_groups_stay_empty(Context& context) {
    for (const Entry& entry : render::entries()) {
        const bool is_idle = entry.group == Group::kCore || entry.group == Group::kLight ||
            entry.group == Group::kPost || entry.group == Group::kCompute;
        context.expect(!is_idle, "nhóm chưa có shader thì không có dòng");
        context.expect(entry.tier != Tier::kOptional, "tầng 3 đang trống");
    }
}

constexpr std::array<Case, 7> kCases{{
    {.name = "ui_opens_with_the_client", .body = &ui_opens_with_the_client},
    {.name = "names_are_unique", .body = &names_are_unique},
    {.name = "model_variants_are_character", .body = &model_variants_are_character},
    {.name = "fx_waits_for_the_scene", .body = &fx_waits_for_the_scene},
    {.name = "optional_tier_follows_the_gpu", .body = &optional_tier_follows_the_gpu},
    {.name = "terrain_is_the_world_group", .body = &terrain_is_the_world_group},
    {.name = "idle_groups_stay_empty", .body = &idle_groups_stay_empty},
}};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "catalog_tests: mọi ca phải qua");
    return 0;
}
