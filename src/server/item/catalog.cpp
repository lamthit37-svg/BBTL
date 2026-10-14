// Nạp danh mục mẫu vật phẩm: xem catalog.hpp.
#include "item/catalog.hpp"

#include "item/rows.hpp"
#include "item/types.hpp"

#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <initializer_list>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::item {
namespace {

using tsv::Bounds;
using tsv::Cells;
using tsv::Rows;

using Fail = std::unexpected<std::string>;

constexpr std::size_t kRuleFlagColumns = 9;  // cột 1..9 của ItemRule.txt
constexpr Bounds kByte{0, 255};
constexpr Bounds kWord{0, 65535};
constexpr Bounds kPrice{-1, std::numeric_limits<std::int32_t>::max()};

// Tìm các cột theo tên; thiếu cột nào là lỗi của bảng (đổi cấu trúc bảng mà không đổi bộ nạp).
std::expected<std::vector<std::size_t>, std::string> resolve(const Rows& rows, std::string_view table,
    std::initializer_list<std::string_view> names) {
    std::vector<std::size_t> out;
    out.reserve(names.size());
    for (const std::string_view name : names) {
        const std::size_t col = rows.column(name);
        if (col == Rows::npos) {
            return Fail(std::string(table) + ": thiếu cột " + std::string(name));
        }
        out.push_back(col);
    }
    return out;
}

Place home_of(std::uint8_t item_class) noexcept {
    switch (item_class) {
    case 2: return Place::kMaterialBag;  // ICLASS_MATERIAL
    case 4: return Place::kQuestBag;     // ICLASS_TASKITEM
    default: return Place::kBaseBag;
    }
}

std::int32_t price_of(std::int64_t cell) noexcept {
    return cell < 0 ? 0 : static_cast<std::int32_t>(cell);
}

} // namespace

const Template* Catalog::find(TemplateId id) const noexcept {
    const auto it = std::ranges::lower_bound(templates_, id, {}, &Template::id);
    return it != templates_.end() && it->id == id ? &*it : nullptr;
}

std::span<const Weighted> Catalog::weights(const Template& t) const noexcept {
    const auto& pool = weight_pool_;
    if (t.equip.weight_count == 0 || t.equip.weight_begin > pool.size()
        || t.equip.weight_count > pool.size() - t.equip.weight_begin) {
        return {};
    }
    return std::span<const Weighted>(pool).subspan(t.equip.weight_begin, t.equip.weight_count);
}

std::span<const AttrValue> Catalog::gem_attrs(const Template& t) const noexcept {
    const auto& pool = gem_pool_;
    if (t.gem_count == 0 || t.gem_begin > pool.size() || t.gem_count > pool.size() - t.gem_begin) return {};
    return std::span<const AttrValue>(pool).subspan(t.gem_begin, t.gem_count);
}

const Rule* Catalog::rule(std::uint32_t index) const noexcept {
    const auto it = std::ranges::lower_bound(rule_ids_, index);
    if (it == rule_ids_.end() || *it != index) return nullptr;
    return &rules_[static_cast<std::size_t>(it - rule_ids_.begin())];
}


// Bộ nạp từng bảng. Mỗi bộ ghi vào `into` và trả lỗi; Catalog là bạn của chúng qua struct này.
struct CatalogLoader {
    Catalog* cat;

    [[nodiscard]] const Rule* rule(std::int64_t index) const noexcept {
        const auto it = std::ranges::lower_bound(cat->rule_ids_, static_cast<std::uint32_t>(index));
        if (index < 0 || it == cat->rule_ids_.end() || std::cmp_not_equal(*it, index)) return nullptr;
        return &cat->rules_[static_cast<std::size_t>(it - cat->rule_ids_.begin())];
    }

    [[nodiscard]] std::optional<std::string> load_rules(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "item_rules: " + *rows.error();
        if (rows.column_count() <= kRuleFlagColumns) return "item_rules: thiếu cột cờ";
        Cells cells(rows, "item_rules");
        while (rows.next()) {
            const std::int64_t id = cells.integer(0, {0, 1 << 20});
            std::array<bool, kRuleFlagColumns> flags{};
            for (std::size_t i = 0; i < kRuleFlagColumns; ++i) flags.at(i) = cells.integer(i + 1, {0, 1}) == 1;
            if (cells.error()) return cells.error();
            if (!cat->rule_ids_.empty() && std::cmp_less_equal(id, cat->rule_ids_.back())) {
                return "item_rules: id " + std::to_string(id) + " không tăng dần";
            }
            cat->rule_ids_.push_back(static_cast<std::uint32_t>(id));
            cat->rules_.push_back(Rule{.discard = flags[0], .tile = flags[1], .shortcut = flags[2], .sell = flags[3],
                .exchange = flags[4], .use = flags[5], .pick_bind = flags[6], .equip_bind = flags[7],
                .unique = flags[8]});
        }
        if (rows.error()) return "item_rules: " + *rows.error();
        if (cat->rules_.empty()) return "item_rules: bảng rỗng";
        return std::nullopt;
    }

    // Phần chung của mọi dòng mẫu; trả mẫu đã điền id, lớp, phẩm, loại.
    static Template header(Cells& cells, std::size_t id_col, std::size_t class_col, std::size_t quality_col,
        std::size_t type_col) {
        Template t;
        t.id = TemplateId{static_cast<std::uint32_t>(cells.integer(id_col, {1, std::numeric_limits<std::int32_t>::max()}))};
        t.item_class = static_cast<std::uint8_t>(cells.integer(class_col, kByte));
        t.quality = static_cast<std::uint8_t>(cells.integer(quality_col, kByte));
        t.type = static_cast<std::uint8_t>(cells.integer(type_col, kByte));
        t.home = home_of(t.item_class);
        return t;
    }

    std::optional<std::string> attach_rule(Template& t, std::int64_t rule_index, std::string_view table,
        std::size_t line) const {
        const Rule* r = rule(rule_index);
        if (r == nullptr) {
            return std::string(table) + ":" + std::to_string(line) + ": luật vật phẩm " + std::to_string(rule_index)
                + " không có trong item_rules";
        }
        t.rule = *r;
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> load_common(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "items_common: " + *rows.error();
        const auto cols = resolve(rows, "items_common",
            {"index", "class", "quality", "type", "level", "base_price", "sale_price", "fit_rules", "column_12",
                "max_owned"});
        if (!cols) return cols.error();
        const auto& c = *cols;
        Cells cells(rows, "items_common");
        while (rows.next()) {
            Template t = header(cells, c[0], c[1], c[2], c[3]);
            t.kind = Kind::kCommon;
            t.level = static_cast<std::uint16_t>(cells.integer(c[4], kWord));
            t.base_price = price_of(cells.integer(c[5], kPrice));
            t.sale_price = price_of(cells.integer(c[6], kPrice));
            const std::int64_t rule_index = cells.integer(c[7], {0, 1 << 20});
            const std::int64_t tile = cells.integer(c[8], {-1, 65535});
            t.max_owned = static_cast<std::int32_t>(cells.optional_integer(c[9], {1, 1 << 20}, 0));
            if (cells.error()) return cells.error();
            if (auto bad = attach_rule(t, rule_index, "items_common", rows.line())) return bad;
            t.stack_max = t.rule.tile ? static_cast<std::uint16_t>(std::clamp<std::int64_t>(tile, 1, kMaxStack)) : 1;
            if (t.rule.unique) t.max_owned = 1;
            cat->templates_.push_back(t);
        }
        if (rows.error()) return "items_common: " + *rows.error();
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> load_equipment(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "equipment: " + *rows.error();
        const auto cols = resolve(rows, "equipment",
            {"index_1", "class", "quality", "type", "equip_point", "column_7", "lv", "required_sect", "base_price",
                "sale_price", "max_durability", "column_17", "base_physical_attack", "base_magic_attack",
                "base_physical_defence", "base_magic_defence", "base_hit", "base_miss", "quality_rules",
                "value_band_start", "attribute_count_min", "attribute_count_max", "aptitude_min", "aptitude_max",
                "column_100", "max_hp_bonus"});
        if (!cols) return cols.error();
        const auto& c = *cols;
        const std::size_t first_attr = c[25];
        if (rows.column_count() < first_attr + kRollableAttrs) return "equipment: thiếu cột thuộc tính";
        Cells cells(rows, "equipment");
        while (rows.next()) {
            Template t = header(cells, c[0], c[1], c[2], c[3]);
            t.kind = Kind::kEquipment;
            EquipSpec& e = t.equip;
            e.point = static_cast<std::uint8_t>(cells.integer(c[4], {0, kEquipSlots - 1}));
            const std::int64_t rule_index = cells.integer(c[5], {0, 1 << 20});
            t.level = static_cast<std::uint16_t>(cells.integer(c[6], kWord));
            e.sect = static_cast<std::uint8_t>(cells.optional_integer(c[7], {0, ids::kSectCount - 1}, kAnySect));
            t.base_price = price_of(cells.integer(c[8], kPrice));
            t.sale_price = price_of(cells.integer(c[9], kPrice));
            e.max_durability = static_cast<std::uint16_t>(cells.integer(c[10], kWord));
            e.max_repairs = static_cast<std::uint8_t>(cells.integer(c[11], kByte));
            static constexpr std::array<std::size_t, 6> kBaseOrder{12, 13, 14, 15, 16, 17};  // vị trí trong cols
            for (std::size_t i = 0; i < kBaseOrder.size(); ++i) {
                e.base.at(i) = static_cast<std::int32_t>(
                    cells.optional_integer(c[kBaseOrder.at(i)], {0, 1 << 24}, 0));
            }
            e.seg_rule = static_cast<std::uint8_t>(cells.integer(c[18], kByte));
            e.band_start = static_cast<std::int16_t>(cells.optional_integer(c[19], {0, 32767}, -1));
            e.attr_min = static_cast<std::uint8_t>(cells.integer(c[20], {0, kMaxRolledAttrs}));
            e.attr_max = static_cast<std::uint8_t>(cells.integer(c[21], {0, kMaxRolledAttrs}));
            e.apt_min = static_cast<std::uint16_t>(cells.integer(c[22], {0, 255}));
            e.apt_max = static_cast<std::uint16_t>(cells.integer(c[23], {0, 255}));
            e.gem_slots = static_cast<std::uint8_t>(cells.integer(c[24], {0, kMaxGemSlots}));
            const auto pool_begin = static_cast<std::uint32_t>(cat->weight_pool_.size());
            for (std::size_t k = 0; k < kRollableAttrs; ++k) {
                const std::int64_t w = cells.optional_integer(first_attr + k, {0, 65535}, 0);
                if (w > 0) cat->weight_pool_.push_back(Weighted{.attr = AttrId{static_cast<std::uint16_t>(k)}, .weight = static_cast<std::uint16_t>(w)});
            }
            if (cells.error()) return cells.error();
            if (e.attr_min > e.attr_max || e.apt_min > e.apt_max) {
                return "equipment:" + std::to_string(rows.line()) + ": cận dưới lớn hơn cận trên";
            }
            e.weight_begin = pool_begin;
            e.weight_count = static_cast<std::uint16_t>(cat->weight_pool_.size() - pool_begin);
            if (auto bad = attach_rule(t, rule_index, "equipment", rows.line())) return bad;
            t.stack_max = 1;
            cat->templates_.push_back(t);
        }
        if (rows.error()) return "equipment: " + *rows.error();
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> load_gems(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "gems: " + *rows.error();
        const auto cols = resolve(rows, "gems",
            {"index", "class", "quality", "type", "fit_rules", "base_price", "sale_price", "max_hp_bonus",
                "base_physical_attack", "base_magic_attack", "base_hit", "base_physical_defence",
                "base_magic_defence", "base_miss"});
        if (!cols) return cols.error();
        const auto& c = *cols;
        if (rows.column_count() < c[7] + kRollableAttrs) return "gems: thiếu cột thuộc tính";
        // Cột đá quý ở vị trí 69..74 xếp khác thứ tự id 58..63 của thuộc tính nền.
        static constexpr std::array<std::pair<std::size_t, std::uint16_t>, 6> kBase{{
            {8, kAttrBasePhysicalAttack}, {9, kAttrBaseMagicAttack}, {10, kAttrBaseHit},
            {11, kAttrBasePhysicalDefence}, {12, kAttrBaseMagicDefence}, {13, kAttrBaseMiss}}};
        Cells cells(rows, "gems");
        while (rows.next()) {
            Template t = header(cells, c[0], c[1], c[2], c[3]);
            t.kind = Kind::kGem;
            const std::int64_t rule_index = cells.integer(c[4], {0, 1 << 20});
            t.base_price = price_of(cells.integer(c[5], kPrice));
            t.sale_price = price_of(cells.integer(c[6], kPrice));
            const auto begin = static_cast<std::uint32_t>(cat->gem_pool_.size());
            for (std::size_t k = 0; k < kRollableAttrs; ++k) {
                const std::int64_t v = cells.optional_integer(c[7] + k, {-(1 << 24), 1 << 24}, 0);
                if (v != 0) cat->gem_pool_.push_back(AttrValue{.id = AttrId{static_cast<std::uint16_t>(k)}, .value = static_cast<std::int32_t>(v)});
            }
            for (const auto& [slot, id] : kBase) {
                const std::int64_t v = cells.optional_integer(c.at(slot), {-(1 << 24), 1 << 24}, 0);
                if (v != 0) cat->gem_pool_.push_back(AttrValue{.id = AttrId{id}, .value = static_cast<std::int32_t>(v)});
            }
            if (cells.error()) return cells.error();
            t.gem_begin = begin;
            t.gem_count = static_cast<std::uint16_t>(cat->gem_pool_.size() - begin);
            if (auto bad = attach_rule(t, rule_index, "gems", rows.line())) return bad;
            t.stack_max = t.rule.tile ? kMaxStack : 1;
            cat->templates_.push_back(t);
        }
        if (rows.error()) return "gems: " + *rows.error();
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> load_pet_equipment(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "pet_equipment_base: " + *rows.error();
        // Bảng chưa đặt tên cột; vị trí theo dòng mẫu của PetEquipBase.txt (docs/SERVER-ITEM.md).
        if (rows.column_count() < 15) return "pet_equipment_base: thiếu cột";
        Cells cells(rows, "pet_equipment_base");
        while (rows.next()) {
            Template t = header(cells, 0, 1, 2, 3);
            t.kind = Kind::kPetEquipment;
            const std::int64_t rule_index = cells.integer(7, {0, 1 << 20});
            t.level = static_cast<std::uint16_t>(cells.integer(11, kWord));
            t.base_price = price_of(cells.integer(13, kPrice));
            t.sale_price = price_of(cells.integer(14, kPrice));
            t.equip.point = static_cast<std::uint8_t>(cells.integer(5, {0, kEquipSlots - 1}));
            if (cells.error()) return cells.error();
            if (auto bad = attach_rule(t, rule_index, "pet_equipment_base", rows.line())) return bad;
            t.stack_max = 1;
            cat->templates_.push_back(t);
        }
        if (rows.error()) return "pet_equipment_base: " + *rows.error();
        return std::nullopt;
    }

    [[nodiscard]] std::optional<std::string> apply_durations(std::string_view text) const {
        Rows rows(text);
        if (rows.error()) return "equipment_extra_attributes: " + *rows.error();
        const auto cols = resolve(rows, "equipment_extra_attributes", {"index", "duration_hours"});
        if (!cols) return cols.error();
        Cells cells(rows, "equipment_extra_attributes");
        while (rows.next()) {
            const std::int64_t id = cells.integer((*cols)[0], {1, std::numeric_limits<std::int32_t>::max()});
            const std::int64_t hours = cells.optional_integer((*cols)[1], {1, 1 << 20}, 0);
            if (cells.error()) return cells.error();
            const auto it = std::ranges::lower_bound(cat->templates_, TemplateId{static_cast<std::uint32_t>(id)}, {},
                &Template::id);
            if (it != cat->templates_.end() && std::cmp_equal(it->id.value(), id)) it->duration_hours = static_cast<std::int32_t>(hours);
        }
        if (rows.error()) return "equipment_extra_attributes: " + *rows.error();
        return std::nullopt;
    }
};


std::expected<Catalog, std::string> Catalog::load(const CatalogSources& sources) {
    Catalog out;
    const CatalogLoader builder{&out};
    if (auto bad = builder.load_rules(sources.rules)) return Fail(*bad);
    if (!sources.common.empty()) {
        if (auto bad = builder.load_common(sources.common)) return Fail(*bad);
    }
    if (!sources.equipment.empty()) {
        if (auto bad = builder.load_equipment(sources.equipment)) return Fail(*bad);
    }
    if (!sources.gems.empty()) {
        if (auto bad = builder.load_gems(sources.gems)) return Fail(*bad);
    }
    if (!sources.pet_equipment.empty()) {
        if (auto bad = builder.load_pet_equipment(sources.pet_equipment)) return Fail(*bad);
    }
    std::ranges::sort(out.templates_, {}, &Template::id);
    const auto dup = std::ranges::adjacent_find(out.templates_, {}, &Template::id);
    if (dup != out.templates_.end()) {
        return Fail("danh mục: id " + std::to_string(dup->id.value()) + " xuất hiện ở hai bảng hoặc hai dòng");
    }
    if (!sources.extra_attributes.empty()) {
        if (auto bad = builder.apply_durations(sources.extra_attributes)) return Fail(*bad);
    }
    return out;
}

} // namespace game::item
