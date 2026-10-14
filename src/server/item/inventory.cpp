// Trạng thái vật phẩm và ví: xem inventory.hpp.
#include "item/inventory.hpp"

#include "item/instance.hpp"
#include "item/limits.hpp"
#include "item/types.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <vector>

namespace game::item {
namespace {

using Unexpected = std::unexpected<Error>;

[[nodiscard]] constexpr std::size_t place_index(Place place) noexcept { return static_cast<std::size_t>(place); }

} // namespace

// ----- Wallet ---------------------------------------------------------------------------------------

Wallet::Wallet(const Limits& limits) noexcept {
    // Tài khoản 0 (vàng kho) dùng trần kho; 1..16 dùng trần từng loại tiền.
    cap_.at(0) = limits.bank_gold_cap;
    for (std::size_t c = 1; c < kCurrencySlots; ++c) cap_.at(c) = limits.currency_cap.at(c);
}

std::int64_t Wallet::balance(Currency c) const noexcept {
    const auto index = static_cast<std::size_t>(c);
    return index < balance_.size() ? balance_.at(index) : 0;
}

std::expected<void, Error> Wallet::earn(Account a, std::int64_t amount) noexcept {
    const auto index = static_cast<std::size_t>(a);
    if (index >= balance_.size() || cap_.at(index) <= 0) return Unexpected(Error::kUnknownCurrency);
    if (amount <= 0) return Unexpected(Error::kBadAmount);
    // So amount với phần trần còn lại thay vì cộng rồi so: balance + amount có thể tràn int64 khi amount thù địch.
    if (amount > cap_.at(index) - balance_.at(index)) return Unexpected(Error::kOverCap);
    balance_.at(index) += amount;
    return {};
}

std::expected<void, Error> Wallet::spend(Account a, std::int64_t amount) noexcept {
    const auto index = static_cast<std::size_t>(a);
    if (index >= balance_.size() || cap_.at(index) <= 0) return Unexpected(Error::kUnknownCurrency);
    if (amount <= 0) return Unexpected(Error::kBadAmount);
    if (amount > balance_.at(index)) return Unexpected(Error::kInsufficientFunds);
    balance_.at(index) -= amount;
    return {};
}

void Wallet::set_cap(Account a, std::int64_t cap) noexcept {
    const auto index = static_cast<std::size_t>(a);
    if (index < cap_.size()) cap_.at(index) = std::max<std::int64_t>(cap, 0);
}

bool Wallet::set_balance(Account a, std::int64_t value) noexcept {
    const auto index = static_cast<std::size_t>(a);
    if (index >= balance_.size() || value < 0 || cap_.at(index) <= 0) return false;
    balance_.at(index) = value;
    return true;
}

// ----- Inventory ------------------------------------------------------------------------------------

Inventory::Inventory(const Limits& limits) : limits_(limits), wallet_(limits) {
    for (std::size_t p = 0; p < kPlaceCount; ++p) {
        const auto place = static_cast<Place>(p);
        const std::uint16_t cap = place == Place::kEquip ? static_cast<std::uint16_t>(kEquipSlots) : limits.capacity.at(p);
        slots_.at(p).resize(cap);
        locks_.at(p).assign(cap, false);
        unlocked_.at(p) = place == Place::kEquip ? cap : std::min(limits.unlocked.at(p), cap);
    }
    wallet_.set_cap(account_of(Currency::kGold), limits.gold_cap(1));
}

std::uint16_t Inventory::unlocked(Place place) const noexcept {
    const std::size_t p = place_index(place);
    return p < kPlaceCount ? unlocked_.at(p) : std::uint16_t{0};
}

std::uint16_t Inventory::capacity(Place place) const noexcept {
    const std::size_t p = place_index(place);
    return p < kPlaceCount ? static_cast<std::uint16_t>(slots_.at(p).size()) : std::uint16_t{0};
}

bool Inventory::in_range(SlotRef where) const noexcept { return where.index < unlocked(where.place); }

const Instance* Inventory::get(SlotRef where) const noexcept {
    if (!in_range(where)) return nullptr;
    const std::optional<Instance>& cell = slots_.at(place_index(where.place)).at(where.index);
    return cell ? &*cell : nullptr;
}

std::span<const std::optional<Instance>> Inventory::view(Place place) const noexcept {
    const std::size_t p = place_index(place);
    if (p >= kPlaceCount) return {};
    return std::span<const std::optional<Instance>>(slots_.at(p)).first(unlocked_.at(p));
}

bool Inventory::locked(SlotRef where) const noexcept {
    return in_range(where) && locks_.at(place_index(where.place)).at(where.index);
}

std::uint64_t Inventory::count_of(TemplateId tmpl) const noexcept {
    std::uint64_t total = 0;
    for (std::size_t p = 0; p < kPlaceCount; ++p) {
        for (const std::optional<Instance>& cell : view(static_cast<Place>(p))) {
            if (cell && cell->tmpl == tmpl) total += cell->count;
        }
    }
    return total;
}

std::expected<void, Error> Inventory::apply(const Plan& plan) {
    if (plan.revision != revision_) return Unexpected(Error::kStalePlan);
    if (plan.empty()) return {};

    // Giai đoạn kiểm: không ghi gì. Ô ngoài miền, ô trùng, thể hiện số lượng 0 đều là lỗi của nơi dựng kế hoạch.
    std::vector<SlotRef> seen;
    seen.reserve(plan.slots.size());
    for (const SlotChange& change : plan.slots) {
        if (!in_range(change.where)) return Unexpected(Error::kBrokenPlan);
        if (change.after && (change.after->count == 0 || change.after->tmpl.value() == 0)) {
            return Unexpected(Error::kBrokenPlan);
        }
        seen.push_back(change.where);
    }
    std::ranges::sort(seen);
    if (std::ranges::adjacent_find(seen) != seen.end()) return Unexpected(Error::kBrokenPlan);

    std::vector<Account> accounts;
    accounts.reserve(plan.balances.size());
    for (const BalanceChange& change : plan.balances) {
        const auto index = static_cast<std::size_t>(change.account);
        if (index >= kAccountSlots || wallet_.cap(change.account) <= 0) return Unexpected(Error::kBrokenPlan);
        if (change.before != wallet_.balance(change.account)) return Unexpected(Error::kStalePlan);
        if (change.after < 0) return Unexpected(Error::kBrokenPlan);
        // Cho phép giữ nguyên hay giảm khi đang vượt trần; chỉ chặn tăng vượt trần.
        if (change.after > change.before && change.after > wallet_.cap(change.account)) {
            return Unexpected(Error::kOverCap);
        }
        accounts.push_back(change.account);
    }
    std::ranges::sort(accounts);
    if (std::ranges::adjacent_find(accounts) != accounts.end()) return Unexpected(Error::kBrokenPlan);

    // Giai đoạn ghi: chỉ gán, không thể hỏng.
    for (const SlotChange& change : plan.slots) {
        slots_.at(place_index(change.where.place)).at(change.where.index) = change.after;
    }
    for (const BalanceChange& change : plan.balances) static_cast<void>(wallet_.set_balance(change.account, change.after));
    ++revision_;
    return {};
}

std::expected<void, Error> Inventory::set_lock(SlotRef where, bool value) {
    if (!in_range(where)) return Unexpected(Error::kNoSuchSlot);
    locks_.at(place_index(where.place)).at(where.index) = value;
    ++revision_;
    return {};
}

std::expected<void, Error> Inventory::unlock_slots(Place place, std::uint16_t more) {
    const std::size_t p = place_index(place);
    if (p >= kPlaceCount || place == Place::kEquip) return Unexpected(Error::kWrongPlace);
    const std::size_t total = static_cast<std::size_t>(unlocked_.at(p)) + more;
    if (more == 0 || total > slots_.at(p).size()) return Unexpected(Error::kBadCount);
    unlocked_.at(p) = static_cast<std::uint16_t>(total);
    ++revision_;
    return {};
}

void Inventory::set_level_cap(std::uint32_t level) noexcept {
    wallet_.set_cap(account_of(Currency::kGold), limits_.gold_cap(level));
}

bool Inventory::restore(SlotRef where, const Instance& item) {
    if (!in_range(where) || item.count == 0) return false;
    slots_.at(place_index(where.place)).at(where.index) = item;
    return true;
}

void Inventory::clear(Place place) {
    const std::size_t p = place_index(place);
    if (p >= kPlaceCount) return;
    ++revision_;
    std::ranges::fill(slots_.at(p), std::nullopt);
    locks_.at(p).assign(slots_.at(p).size(), false);
    unlocked_.at(p) = place == Place::kEquip ? static_cast<std::uint16_t>(kEquipSlots)
                                             : std::min(limits_.unlocked.at(p), static_cast<std::uint16_t>(slots_.at(p).size()));
}

bool Inventory::restore_unlocked(Place place, std::uint16_t value) noexcept {
    const std::size_t p = place_index(place);
    if (p >= kPlaceCount || place == Place::kEquip || value > slots_.at(p).size()) return false;
    unlocked_.at(p) = value;
    return true;
}

} // namespace game::item
