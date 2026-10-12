// Bảng catalog không cần GPU: ui ở tầng 0, bốn biến thể model ở nhóm Character tầng 1, fx ở
// tầng 2. Tên không trùng. Thêm dòng mà quên nhóm hoặc tầng thì ca nhóm trống hoặc ca tầng đỏ.
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
    context.expect(table.size() == render::kSlotCount, "đủ sáu mục");
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
    bool saw = false;
    for (const Entry& entry : render::entries()) {
        if (entry.pso != Pso::kFx) continue;
        saw = true;
        context.expect(entry.group == Group::kVfx, "fx thuộc nhóm VFX");
        context.expect(entry.tier == Tier::kScene, "fx thuộc tầng 2");
        context.expect(!entry.is_required, "fx thiếu thì bỏ qua hiệu ứng");
        context.expect(entry.frame_bytes == 0, "fx không kiểm khối khung");
    }
    context.expect(saw, "có mục fx");
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

void idle_groups_stay_empty(Context& context) {
    for (const Entry& entry : render::entries()) {
        const bool is_idle = entry.group == Group::kCore || entry.group == Group::kWorld ||
            entry.group == Group::kLight || entry.group == Group::kPost || entry.group == Group::kCompute;
        context.expect(!is_idle, "nhóm chưa có shader thì không có dòng");
        context.expect(entry.tier != Tier::kOptional, "tầng 3 đang trống");
    }
}

constexpr std::array<Case, 6> kCases{{
    {.name = "ui_opens_with_the_client", .body = &ui_opens_with_the_client},
    {.name = "names_are_unique", .body = &names_are_unique},
    {.name = "model_variants_are_character", .body = &model_variants_are_character},
    {.name = "fx_waits_for_the_scene", .body = &fx_waits_for_the_scene},
    {.name = "optional_tier_follows_the_gpu", .body = &optional_tier_follows_the_gpu},
    {.name = "idle_groups_stay_empty", .body = &idle_groups_stay_empty},
}};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "catalog_tests: mọi ca phải qua");
    return 0;
}
