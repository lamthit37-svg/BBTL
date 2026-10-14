// Công thức lò rèn: xem tables.hpp.
#include "forge/tables.hpp"

#include "item/catalog.hpp"
#include "item/rows.hpp"
#include "item/types.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <initializer_list>
#include <limits>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::forge {

using Fail = std::unexpected<std::string>;
using Loaded = std::expected<void, std::string>;

namespace {

using item::tsv::Bounds;
using item::tsv::Cells;
using item::tsv::Rows;

constexpr std::int64_t kMaxId = std::numeric_limits<std::int32_t>::max();
constexpr std::int64_t kMaxGold = std::numeric_limits<std::int32_t>::max();
constexpr std::int64_t kMaxCount = 100;  // số cái một vật liệu: bảng thật là 1

[[nodiscard]] constexpr std::size_t index_of(Kind kind) noexcept { return static_cast<std::size_t>(kind); }

// Tìm các cột theo tên; lỗi nếu thiếu cột nào.
[[nodiscard]] std::expected<std::vector<std::size_t>, std::string> resolve(const Rows& rows, std::string_view table,
    std::initializer_list<std::string_view> names) {
    std::vector<std::size_t> cols;
    for (const std::string_view name : names) {
        const std::size_t col = rows.column(name);
        if (col == Rows::npos) return Fail(std::string(table) + ": thiếu cột " + std::string(name));
        cols.push_back(col);
    }
    return cols;
}

} // namespace

// Bộ nạp: friend của ForgeTables để ghi thẳng vào thành viên.
struct ForgeLoader {
    static Loaded read_melting(ForgeTables& out, std::string_view text, const item::Catalog& catalog);
    static Loaded read_carving(ForgeTables& out, std::string_view text, const item::Catalog& catalog);
    static Loaded read_advances(ForgeTables& out, std::string_view text, const item::Catalog& catalog);
    static Loaded finish(ForgeTables& out, Kind kind, std::string_view table);
};

namespace {

[[nodiscard]] bool known(const item::Catalog& catalog, std::int64_t id) {
    return catalog.find(item::TemplateId{static_cast<std::uint32_t>(id)}) != nullptr;
}

// Thêm một vật liệu vào cuối kho và trả chỉ số của nó. Số lượng đã được kiểm trong [0, kMaxCount] nên vừa uint16.
std::uint32_t push(std::vector<Material>& pool, std::int64_t item, std::int64_t count) {
    pool.push_back(Material{.item = item::TemplateId{static_cast<std::uint32_t>(item)}, .count = static_cast<std::uint16_t>(count)});
    return static_cast<std::uint32_t>(pool.size() - 1);
}

} // namespace

Loaded ForgeLoader::read_melting(ForgeTables& out, std::string_view text, const item::Catalog& catalog) {
    Rows rows(text);
    if (rows.error()) return Fail("gem_melting: " + *rows.error());
    const auto cols = resolve(rows, "gem_melting", {"gem_id", "smelted_gem_id", "required_item_id", "required_money", "substitute_item_id"});
    if (!cols) return Fail(cols.error());
    const auto& c = *cols;
    Cells cells(rows, "gem_melting");
    while (rows.next()) {
        const std::int64_t input = cells.integer(c[0], Bounds{1, kMaxId});
        const std::int64_t output = cells.integer(c[1], Bounds{1, kMaxId});
        const std::int64_t need = cells.integer(c[2], Bounds{1, kMaxId});
        const std::int64_t gold = cells.integer(c[3], Bounds{0, kMaxGold});
        const std::int64_t substitute = cells.optional_integer(c[4], Bounds{1, kMaxId}, -1);
        if (cells.error()) return Fail(*cells.error());
        if (!known(catalog, input) || !known(catalog, output) || !known(catalog, need) || (substitute >= 0 && !known(catalog, substitute))) {
            ++out.diagnostics_.unknown_rows;
            continue;
        }
        Recipe recipe{.input = item::TemplateId{static_cast<std::uint32_t>(input)}, .output = item::TemplateId{static_cast<std::uint32_t>(output)}, .gold = gold};
        recipe.needs_begin = push(out.materials_, need, 1);
        recipe.needs_count = 1;
        if (substitute >= 0) {
            recipe.alt_begin = push(out.materials_, substitute, 1);
            recipe.alt_count = 1;
        }
        out.recipes_.at(index_of(Kind::kMelt)).push_back(recipe);
    }
    if (rows.error()) return Fail("gem_melting: " + *rows.error());
    return finish(out, Kind::kMelt, "gem_melting");
}

Loaded ForgeLoader::read_carving(ForgeTables& out, std::string_view text, const item::Catalog& catalog) {
    Rows rows(text);
    if (rows.error()) return Fail("gem_carving: " + *rows.error());
    const auto cols = resolve(rows, "gem_carving", {"gem_id", "carved_gem_id", "required_item_id", "required_money"});
    if (!cols) return Fail(cols.error());
    const auto& c = *cols;
    Cells cells(rows, "gem_carving");
    while (rows.next()) {
        const std::int64_t input = cells.integer(c[0], Bounds{1, kMaxId});
        const std::int64_t output = cells.integer(c[1], Bounds{1, kMaxId});
        const std::int64_t need = cells.integer(c[2], Bounds{1, kMaxId});
        const std::int64_t gold = cells.integer(c[3], Bounds{0, kMaxGold});
        if (cells.error()) return Fail(*cells.error());
        if (!known(catalog, input) || !known(catalog, output) || !known(catalog, need)) {
            ++out.diagnostics_.unknown_rows;
            continue;
        }
        Recipe recipe{.input = item::TemplateId{static_cast<std::uint32_t>(input)}, .output = item::TemplateId{static_cast<std::uint32_t>(output)}, .gold = gold};
        recipe.needs_begin = push(out.materials_, need, 1);
        recipe.needs_count = 1;
        out.recipes_.at(index_of(Kind::kCarve)).push_back(recipe);
    }
    if (rows.error()) return Fail("gem_carving: " + *rows.error());
    return finish(out, Kind::kCarve, "gem_carving");
}

Loaded ForgeLoader::read_advances(ForgeTables& out, std::string_view text, const item::Catalog& catalog) {
    Rows rows(text);
    if (rows.error()) return Fail("super_weapon_advances: " + *rows.error());
    const auto cols = resolve(rows, "super_weapon_advances", {"item_id", "advanced_item_id", "gold_cost", "material_count", "material_1_id", "material_2_id"});
    if (!cols) return Fail(cols.error());
    const auto& c = *cols;
    Cells cells(rows, "super_weapon_advances");
    while (rows.next()) {
        const std::int64_t input = cells.integer(c[0], Bounds{1, kMaxId});
        const std::int64_t output = cells.integer(c[1], Bounds{1, kMaxId});
        const std::int64_t gold = cells.integer(c[2], Bounds{-1, kMaxGold});
        const std::int64_t count = cells.integer(c[3], Bounds{0, kMaxCount});
        const std::int64_t first = cells.optional_integer(c[4], Bounds{1, kMaxId}, -1);
        const std::int64_t second = cells.optional_integer(c[5], Bounds{1, kMaxId}, -1);
        if (cells.error()) return Fail(*cells.error());
        if (gold < 0) {
            ++out.diagnostics_.disabled_advances;
            continue;
        }
        if (!known(catalog, input) || !known(catalog, output) || (first >= 0 && !known(catalog, first)) || (second >= 0 && !known(catalog, second))) {
            ++out.diagnostics_.unknown_rows;
            continue;
        }
        Recipe recipe{.input = item::TemplateId{static_cast<std::uint32_t>(input)}, .output = item::TemplateId{static_cast<std::uint32_t>(output)}, .gold = gold};
        recipe.needs_begin = static_cast<std::uint32_t>(out.materials_.size());
        for (const std::int64_t material : {first, second}) {
            if (material < 0 || count == 0) continue;
            push(out.materials_, material, count);
            ++recipe.needs_count;
        }
        out.recipes_.at(index_of(Kind::kAdvance)).push_back(recipe);
    }
    if (rows.error()) return Fail("super_weapon_advances: " + *rows.error());
    return finish(out, Kind::kAdvance, "super_weapon_advances");
}

Loaded ForgeLoader::finish(ForgeTables& out, Kind kind, std::string_view table) {
    std::vector<Recipe>& recipes = out.recipes_.at(index_of(kind));
    std::ranges::sort(recipes, {}, &Recipe::input);
    const auto dup = std::ranges::adjacent_find(recipes, {}, &Recipe::input);
    if (dup != recipes.end()) return Fail(std::string(table) + ": đầu vào " + std::to_string(dup->input.value()) + " xuất hiện hai lần");
    return {};
}

std::expected<ForgeTables, std::string> ForgeTables::load(const ForgeSources& sources, const item::Catalog& catalog) {
    ForgeTables out;
    if (!sources.melting.empty()) {
        if (auto done = ForgeLoader::read_melting(out, sources.melting, catalog); !done) return Fail(done.error());
    }
    if (!sources.carving.empty()) {
        if (auto done = ForgeLoader::read_carving(out, sources.carving, catalog); !done) return Fail(done.error());
    }
    if (!sources.advances.empty()) {
        if (auto done = ForgeLoader::read_advances(out, sources.advances, catalog); !done) return Fail(done.error());
    }
    return out;
}

const Recipe* ForgeTables::find(Kind kind, item::TemplateId input) const noexcept {
    const std::vector<Recipe>& recipes = recipes_.at(index_of(kind));
    const auto at = std::ranges::lower_bound(recipes, input, {}, &Recipe::input);
    return at != recipes.end() && at->input == input ? &*at : nullptr;
}

std::span<const Recipe> ForgeTables::all(Kind kind) const noexcept { return recipes_.at(index_of(kind)); }

std::span<const Material> ForgeTables::needs(const Recipe& recipe) const noexcept {
    return std::span<const Material>(materials_).subspan(recipe.needs_begin, recipe.needs_count);
}

std::span<const Material> ForgeTables::alternative(const Recipe& recipe) const noexcept {
    return std::span<const Material>(materials_).subspan(recipe.alt_begin, recipe.alt_count);
}

} // namespace game::forge
