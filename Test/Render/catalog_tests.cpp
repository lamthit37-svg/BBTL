// Bảng catalog không cần GPU: sáu PSO tầng 0, tên không trùng, bốn biến thể model chung một cặp
// shader. Thêm dòng vào bảng mà quên tầng thì ca này đỏ.
#include "core/check.hpp"
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

void six_bootstrap_entries(Context& context) {
    const auto table = render::entries();
    context.expect(table.size() == render::kSlotCount, "đủ sáu mục");
    for (const Entry& entry : table) {
        context.expect(entry.tier == Tier::kBootstrap, "mọi mục hiện có thuộc tầng 0");
    }
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

void model_variants_share_one_pair(Context& context) {
    std::size_t models = 0;
    for (const Entry& entry : render::entries()) {
        if (entry.group != Group::kWorld) continue;
        ++models;
        context.expect(same(entry.vertex, "model.vs"), "model dùng model.vs");
        context.expect(same(entry.pixel, "model.ps"), "model dùng model.ps");
        context.expect(entry.is_required, "model là bắt buộc");
        const auto index = static_cast<std::size_t>(entry.pso);
        context.expect(index < render::kModelVariants, "biến thể model nằm ở bốn ô đầu");
    }
    context.expect(models == render::kModelVariants, "đúng bốn biến thể model");
}

void ui_and_fx_are_optional(Context& context) {
    bool saw_ui = false;
    bool saw_fx = false;
    for (const Entry& entry : render::entries()) {
        if (entry.pso == Pso::kUi) {
            saw_ui = true;
            context.expect(entry.group == Group::kUi, "ui thuộc nhóm UI");
            context.expect(!entry.is_required, "ui thiếu thì bỏ qua HUD");
        }
        if (entry.pso == Pso::kFx) {
            saw_fx = true;
            context.expect(entry.group == Group::kVfx, "fx thuộc nhóm VFX");
            context.expect(!entry.is_required, "fx thiếu thì bỏ qua hiệu ứng");
        }
    }
    context.expect(saw_ui, "có mục ui");
    context.expect(saw_fx, "có mục fx");
}

void later_groups_have_no_entry(Context& context) {
    for (const Entry& entry : render::entries()) {
        const bool is_later = entry.group == Group::kCharacter || entry.group == Group::kLight ||
            entry.group == Group::kPost || entry.group == Group::kCompute || entry.group == Group::kCore;
        context.expect(!is_later, "nhóm chưa có shader thì không có dòng");
        const bool is_later_tier =
            entry.tier == Tier::kEssential || entry.tier == Tier::kScene || entry.tier == Tier::kOptional;
        context.expect(!is_later_tier, "tầng 1, 2 và 3 đang trống");
    }
}

constexpr std::array<Case, 5> kCases{{
    {.name = "six_bootstrap_entries", .body = &six_bootstrap_entries},
    {.name = "names_are_unique", .body = &names_are_unique},
    {.name = "model_variants_share_one_pair", .body = &model_variants_share_one_pair},
    {.name = "ui_and_fx_are_optional", .body = &ui_and_fx_are_optional},
    {.name = "later_groups_have_no_entry", .body = &later_groups_have_no_entry},
}};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "catalog_tests: mọi ca phải qua");
    return 0;
}
