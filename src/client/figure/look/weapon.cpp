// Bộ đọc bốn bảng vũ khí và các hàm tra (xem weapon.hpp).
// Nguồn: TLBB Dev src/tables/appearance.cpp@e0d89a6 (read_weapon, find_weapon). Khác gốc: đọc bằng
// table::RowReader; loại ở bảng vật phẩm; thêm objects và locators.
#include "look/weapon.hpp"

#include "look/appearance.hpp"
#include "look/detail/rows.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <format>
#include <functional>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::look {
namespace {

using detail::read_all;
using detail::sorted_unique;

constexpr std::uint32_t kMaxShort = 0xFFFFU;
constexpr std::uint32_t kMaxLong = 0xFFFFFFFFU;

// Tên khe theo Hold: cột của weapons.tsv và tên SlotCreate trong all.obj.
struct HoldName {
    std::string_view column;
    std::string_view slot;
};

constexpr std::array<HoldName, kHoldCount> kHolds{{{.column = "right", .slot = "RightWeaponObj"},
    {.column = "left", .slot = "LeftWeaponObj"}, {.column = "kfs", .slot = "KFSObj"},
    {.column = "foot", .slot = "FootWeaponObj"}, {.column = "back", .slot = "NewBackWeaponObj"},
    {.column = "waist1", .slot = "WaistWeaponObj1"}, {.column = "waist2", .slot = "WaistWeaponObj2"}}};

WeaponRow weapon_row(table::RowReader& reader) {
    WeaponRow weapon;
    weapon.id = static_cast<std::uint16_t>(reader.number("id", 1, kMaxShort));
    for (std::size_t hold = 0; hold < kHoldCount; ++hold) {
        weapon.objects.at(hold) = reader.text(kHolds.at(hold).column);
    }
    return weapon;
}

WeaponItemRow item_row(table::RowReader& reader) {
    WeaponItemRow item;
    item.item = reader.number("item", 0, kMaxLong);
    item.visual = reader.integer("visual", -1, static_cast<std::int32_t>(kMaxShort));
    const std::string_view name = reader.text("class");
    const std::optional<Weapon> kind = weapon_named(name);
    if (kind) {
        item.kind = *kind;
    } else {
        reader.reject("class", "tên loại vũ khí lạ");
    }
    return item;
}

// Tên lưới cách nhau bằng "|"; ô rỗng không có tên nào.
std::vector<std::string> split_meshes(std::string_view cell) {
    std::vector<std::string> names;
    std::size_t start = 0;
    while (start < cell.size()) {
        const std::size_t stop = cell.find('|', start);
        const std::size_t end = stop == std::string_view::npos ? cell.size() : stop;
        if (end > start) names.emplace_back(cell.substr(start, end - start));
        start = end + 1;
    }
    return names;
}

ObjectRow object_row(table::RowReader& reader) {
    ObjectRow object;
    object.name = reader.text("object");
    object.meshes = split_meshes(reader.text("meshes"));
    if (object.meshes.empty() && !reader.error()) reader.reject("meshes", "mẫu không có lưới nào");
    object.scale = {reader.positive("sx"), reader.positive("sy"), reader.positive("sz")};
    return object;
}

LocatorRow locator_row(table::RowReader& reader) {
    LocatorRow locator;
    locator.object = reader.text("object");
    locator.name = reader.text("locator");
    locator.bone = reader.text("bone");
    locator.offset = {reader.real("x"), reader.real("y"), reader.real("z")};
    locator.axis = {reader.real("qx"), reader.real("qy"), reader.real("qz")};
    locator.angle = reader.real("qw");
    locator.is_translate_first = reader.flag("translate_first");
    locator.slot = reader.text("slot");
    return locator;
}

// Tên effect cách nhau bằng ";", ô rỗng giữ chỗ; đúng kEffectSlots ô.
std::vector<std::string> split_effects(table::RowReader& reader, std::string_view cell) {
    std::vector<std::string> names;
    std::size_t start = 0;
    while (true) {
        const std::size_t stop = cell.find(';', start);
        const std::size_t end = stop == std::string_view::npos ? cell.size() : stop;
        names.emplace_back(cell.substr(start, end - start));
        if (stop == std::string_view::npos) break;
        start = stop + 1;
    }
    if (names.size() != kEffectSlots && !reader.error()) {
        reader.reject("effects", std::format("phải đủ {} ô, có {}", kEffectSlots, names.size()));
    }
    return names;
}

EffectRow effect_row(table::RowReader& reader) {
    EffectRow row;
    row.visual = static_cast<std::uint16_t>(reader.number("visual", 1, kMaxShort));
    row.has_back = reader.flag("back");
    row.has_waist1 = reader.flag("waist1");
    row.has_waist2 = reader.flag("waist2");
    row.effects = split_effects(reader, reader.text("effects"));
    return row;
}

GemRow gem_row(table::RowReader& reader) {
    GemRow gem;
    gem.gem = reader.number("gem", 0, kMaxLong);
    gem.colour = reader.text("colour");
    gem.effect = reader.integer("effect", std::numeric_limits<std::int32_t>::min(), std::numeric_limits<std::int32_t>::max());
    return gem;
}

// Màu RRGGBBAA như sscanf("%8X"): tối đa tám chữ số hex ở đầu chuỗi; không có chữ số nào thì 0.
std::uint32_t colour_of(std::string_view text) {
    std::uint32_t value = 0;
    for (const char digit : text.substr(0, 8)) {
        std::uint32_t nibble = 0;
        if (digit >= '0' && digit <= '9') {
            nibble = static_cast<std::uint32_t>(digit - '0');
        } else if (digit >= 'A' && digit <= 'F') {
            nibble = static_cast<std::uint32_t>(digit - 'A') + 10U;
        } else if (digit >= 'a' && digit <= 'f') {
            nibble = static_cast<std::uint32_t>(digit - 'a') + 10U;
        } else {
            break;
        }
        value = (value << 4U) | nibble;
    }
    return value;
}

} // namespace

std::string_view slot_name(Hold hold) noexcept {
    return kHolds.at(static_cast<std::size_t>(hold)).slot;
}

Rows<WeaponRow> read_weapons(const table::Tsv& table) {
    const auto key = [](const WeaponRow& row) { return row.id; };
    return sorted_unique(read_all<WeaponRow>(table, weapon_row), key, "weapons");
}

Rows<WeaponItemRow> read_weapon_items(const table::Tsv& table) {
    const auto key = [](const WeaponItemRow& row) { return row.item; };
    return sorted_unique(read_all<WeaponItemRow>(table, item_row), key, "weapon_items");
}

Rows<ObjectRow> read_objects(const table::Tsv& table) {
    const auto key = [](const ObjectRow& row) { return std::string_view(row.name); };
    return sorted_unique(read_all<ObjectRow>(table, object_row), key, "objects");
}

Rows<LocatorRow> read_locators(const table::Tsv& table) {
    const auto key = [](const LocatorRow& row) {
        return std::pair(std::string_view(row.object), std::string_view(row.name));
    };
    return sorted_unique(read_all<LocatorRow>(table, locator_row), key, "locators");
}

Rows<EffectRow> read_weapon_effects(const table::Tsv& table) {
    const auto key = [](const EffectRow& row) { return row.visual; };
    return sorted_unique(read_all<EffectRow>(table, effect_row), key, "weapon_effects");
}

Rows<GemRow> read_gems(const table::Tsv& table) {
    const auto key = [](const GemRow& row) { return row.gem; };
    return sorted_unique(read_all<GemRow>(table, gem_row), key, "gems");
}

std::optional<SlotEffect> gem_effect(const EffectRow& row, const GemRow& gem, Hold hold) {
    const bool is_hand = hold == Hold::kRight || hold == Hold::kLeft;
    const bool has_flag = (hold == Hold::kBack && row.has_back) || (hold == Hold::kWaist1 && row.has_waist1) ||
        (hold == Hold::kWaist2 && row.has_waist2);
    if (!is_hand && !has_flag) return std::nullopt;
    if (gem.colour.size() < 2 || gem.colour[0] == '-' || gem.colour[1] == '1') return std::nullopt;
    const std::int32_t index = gem.effect - 1;
    if (index < 0 || static_cast<std::size_t>(index) >= row.effects.size()) return std::nullopt;
    const std::string& name = row.effects.at(static_cast<std::size_t>(index));
    const std::uint32_t colour = colour_of(gem.colour);
    if (name.empty() || colour == 0) return std::nullopt;
    return SlotEffect{.name = name, .colour = colour};
}

const EffectRow* find_effects(std::span<const EffectRow> rows, std::uint16_t visual) {
    const auto found = std::ranges::lower_bound(rows, visual, std::less<>{}, &EffectRow::visual);
    return found != rows.end() && found->visual == visual ? &*found : nullptr;
}

const GemRow* find_gem(std::span<const GemRow> rows, std::uint32_t gem) {
    const auto found = std::ranges::lower_bound(rows, gem, std::less<>{}, &GemRow::gem);
    return found != rows.end() && found->gem == gem ? &*found : nullptr;
}

const WeaponRow* find_weapon(std::span<const WeaponRow> rows, std::uint16_t id) {
    const auto found = std::ranges::lower_bound(rows, id, std::less<>{}, &WeaponRow::id);
    return found != rows.end() && found->id == id ? &*found : nullptr;
}

const WeaponItemRow* find_weapon_item(std::span<const WeaponItemRow> rows, std::uint32_t item) {
    const auto found = std::ranges::lower_bound(rows, item, std::less<>{}, &WeaponItemRow::item);
    return found != rows.end() && found->item == item ? &*found : nullptr;
}

const ObjectRow* find_object(std::span<const ObjectRow> rows, std::string_view name) {
    const auto name_of = [](const ObjectRow& row) { return std::string_view(row.name); };
    const auto found = std::ranges::lower_bound(rows, name, std::less<>{}, name_of);
    return found != rows.end() && found->name == name ? &*found : nullptr;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): object, name khác vai (HP-07)
const LocatorRow* find_locator(std::span<const LocatorRow> rows, std::string_view object, std::string_view name) {
    const auto key_of = [](const LocatorRow& row) {
        return std::pair(std::string_view(row.object), std::string_view(row.name));
    };
    const std::pair<std::string_view, std::string_view> key{object, name};
    const auto found = std::ranges::lower_bound(rows, key, std::less<>{}, key_of);
    return found != rows.end() && key_of(*found) == key ? &*found : nullptr;
}

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): object, slot khác vai (HP-07)
const LocatorRow* find_slot_locator(std::span<const LocatorRow> rows, std::string_view object,
    std::string_view slot) {
    if (slot.empty()) return nullptr;
    const auto object_of = [](const LocatorRow& row) { return std::string_view(row.object); };
    const auto range = std::ranges::equal_range(rows, object, std::less<>{}, object_of);
    const auto found = std::ranges::find(range, slot, &LocatorRow::slot);
    return found == range.end() ? nullptr : &*found;
}

} // namespace game::look
