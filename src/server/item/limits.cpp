// Giới hạn túi, kho, ví: xem limits.hpp.
#include "item/limits.hpp"

#include "item/rows.hpp"
#include "item/types.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::item {
namespace {

using tsv::Cells;
using tsv::Rows;
using Fail = std::unexpected<std::string>;

// Tên khoá trong bảng -> nơi ghi. Khoá lạ hay thiếu khoá là lỗi bảng.
enum class Field : std::uint8_t { kCapacity, kUnlocked, kBankGold, kCurrency };

struct Slot {
    std::string key;
    Field field;
    std::size_t index;
    std::int64_t max;
};

struct Parsed {
    std::array<std::int64_t, kPlaceCount> capacity{};
    std::array<std::int64_t, kPlaceCount> unlocked{};
    std::array<std::int64_t, kCurrencySlots> caps{};
    std::int64_t bank_gold = 0;

    void set(const Slot& slot, std::int64_t value) {
        switch (slot.field) {
        case Field::kCapacity: capacity.at(slot.index) = value; break;
        case Field::kUnlocked: unlocked.at(slot.index) = value; break;
        case Field::kBankGold: bank_gold = value; break;
        case Field::kCurrency: caps.at(slot.index) = value; break;
        }
    }
};

constexpr std::int64_t kMaxSlots = 1000;
constexpr std::int64_t kMaxMoney = std::int64_t{1} << 40;

} // namespace

Limits Limits::defaults() {
    Limits out;
    out.capacity = {60, 60, 60, static_cast<std::uint16_t>(kEquipSlots), 100};
    out.unlocked = {20, 20, 60, static_cast<std::uint16_t>(kEquipSlots), 100};
    out.bank_gold_cap = 10'000'000;
    out.currency_cap.fill(2'000'000'000);
    out.currency_cap.at(0) = 0;
    out.currency_cap.at(static_cast<std::size_t>(Currency::kGold)) = 100'000'000;
    return out;
}

std::expected<Limits, std::string> Limits::load(const LimitSources& sources) {
    Limits out = defaults();
    Parsed parsed;
    std::vector<Slot> slots;
    const std::array<std::string_view, 3> bag_names{"base_bag", "material_bag", "quest_bag"};
    const auto add = [&slots](std::string key, Field field, std::size_t index, std::int64_t max) {
        slots.push_back(Slot{.key = std::move(key), .field = field, .index = index, .max = max});
    };
    for (std::size_t i = 0; i < bag_names.size(); ++i) {
        add("capacity." + std::string(bag_names.at(i)), Field::kCapacity, i, kMaxSlots);
        add("unlocked." + std::string(bag_names.at(i)), Field::kUnlocked, i, kMaxSlots);
    }
    constexpr auto kBank = static_cast<std::size_t>(Place::kBank);
    add("capacity.bank", Field::kCapacity, kBank, kMaxSlots);
    add("unlocked.bank", Field::kUnlocked, kBank, kMaxSlots);
    add("bank.gold_cap", Field::kBankGold, 0, kMaxMoney);
    for (std::size_t c = 1; c < kCurrencySlots; ++c) {
        add("currency_cap." + std::to_string(c), Field::kCurrency, c, kMaxMoney);
    }

    Rows rows(sources.limits);
    if (rows.error()) return Fail("item_limits: " + *rows.error());
    const std::size_t key_col = rows.column("key");
    const std::size_t value_col = rows.column("value");
    const std::size_t basis_col = rows.column("basis");
    if (key_col == Rows::npos || value_col == Rows::npos || basis_col == Rows::npos) {
        return Fail("item_limits: thiếu cột key, value hay basis");
    }
    std::vector<bool> seen(slots.size(), false);
    Cells cells(rows, "item_limits");
    while (rows.next()) {
        const std::string_view key = cells.text(key_col);
        const auto it = std::ranges::find(slots, key, &Slot::key);
        if (it == slots.end()) return Fail("item_limits:" + std::to_string(rows.line()) + ": khoá lạ " + std::string(key));
        const auto index = static_cast<std::size_t>(it - slots.begin());
        if (seen.at(index)) return Fail("item_limits: khoá " + std::string(key) + " xuất hiện hai lần");
        seen.at(index) = true;
        parsed.set(*it, cells.integer(value_col, {0, it->max}));
        const std::string_view basis = cells.text(basis_col);
        if (basis != "client_lua" && basis != "source_2008" && basis != "made_up") {
            return Fail("item_limits:" + std::to_string(rows.line()) + ": basis lạ " + std::string(basis));
        }
        if (cells.error()) return Fail(*cells.error());
    }
    if (rows.error()) return Fail("item_limits: " + *rows.error());
    for (std::size_t i = 0; i < slots.size(); ++i) {
        if (!seen.at(i)) return Fail("item_limits: thiếu khoá " + slots.at(i).key);
    }

    for (std::size_t p = 0; p < kPlaceCount; ++p) {
        if (p == static_cast<std::size_t>(Place::kEquip)) continue;
        if (parsed.unlocked.at(p) > parsed.capacity.at(p) || parsed.capacity.at(p) == 0) {
            return Fail("item_limits: số ô mở vượt cỡ hoặc cỡ bằng 0 ở " + std::string(describe(static_cast<Place>(p))));
        }
        out.capacity.at(p) = static_cast<std::uint16_t>(parsed.capacity.at(p));
        out.unlocked.at(p) = static_cast<std::uint16_t>(parsed.unlocked.at(p));
    }
    out.bank_gold_cap = parsed.bank_gold;
    for (std::size_t c = 1; c < kCurrencySlots; ++c) out.currency_cap.at(c) = parsed.caps.at(c);

    if (!sources.gold_caps.empty()) {
        Rows gold(sources.gold_caps);
        if (gold.error()) return Fail("money_caps_by_level: " + *gold.error());
        const std::size_t level_col = gold.column("level");
        const std::size_t cap_col = gold.column("max_money");
        if (level_col == Rows::npos || cap_col == Rows::npos) return Fail("money_caps_by_level: thiếu cột level hay max_money");
        Cells gcells(gold, "money_caps_by_level");
        while (gold.next()) {
            const std::int64_t level = gcells.integer(level_col, {1, 1000});
            const std::int64_t cap = gcells.integer(cap_col, {0, kMaxMoney});
            if (gcells.error()) return Fail(*gcells.error());
            if (static_cast<std::size_t>(level) != out.gold_cap_by_level.size() + 1) {
                return Fail("money_caps_by_level: cấp phải liên tục từ 1, gặp " + std::to_string(level));
            }
            out.gold_cap_by_level.push_back(cap);
        }
        if (gold.error()) return Fail("money_caps_by_level: " + *gold.error());
    }
    return out;
}

std::int64_t Limits::gold_cap(std::uint32_t level) const noexcept {
    if (gold_cap_by_level.empty()) return currency_cap.at(static_cast<std::size_t>(Currency::kGold));
    const std::size_t index = std::clamp<std::size_t>(level, 1, gold_cap_by_level.size()) - 1;
    return gold_cap_by_level.at(index);
}

} // namespace game::item
