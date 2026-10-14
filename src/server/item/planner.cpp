// Planner: lớp phủ, cất, bỏ, chia, gộp, đổi chỗ, dồn túi và ví. Phần trang bị ở planner_equip.cpp.
#include "item/planner.hpp"

#include "item/catalog.hpp"
#include "item/detail/planner_edits.hpp"
#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/types.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <tuple>
#include <vector>

namespace game::item {
namespace {

using Unexpected = std::unexpected<Error>;

constexpr std::array<Place, kBagKinds> kBags{Place::kBaseBag, Place::kMaterialBag, Place::kQuestBag};

// Chỗ còn trống trong chồng; 0 khi đã đầy (hay dữ liệu cũ vượt cỡ).
[[nodiscard]] constexpr std::uint32_t room(std::uint16_t cap, std::uint16_t have) noexcept {
    return have >= cap ? 0U : std::uint32_t{cap} - std::uint32_t{have};
}

// Hai thể hiện cùng một chồng được không: cùng mẫu, cùng cờ khoá, giám định và hạn dùng. Chỉ đồ chồng được mới gộp.
[[nodiscard]] bool mergeable(const Template& tmpl, const Instance& a, const Instance& b) noexcept {
    return tmpl.stack_max > 1 && a.tmpl == b.tmpl && a.bound == b.bound && a.identified == b.identified
        && a.expires_at == b.expires_at;
}

} // namespace

Planner::Planner(const Inventory& base, const Catalog& catalog, SerialAllocator& serials) noexcept
    : base_(&base), catalog_(&catalog), serials_(&serials), wallet_(base.wallet()) {}

const std::optional<Instance>& Planner::cell(SlotRef where) const noexcept {
    static const std::optional<Instance> kEmpty;
    const auto it = std::ranges::lower_bound(touched_, where, {}, &SlotChange::where);
    if (it != touched_.end() && it->where == where) return it->after;
    const std::span<const std::optional<Instance>> view = base_->view(where.place);
    if (where.index >= view.size()) return kEmpty;
    return view[where.index];
}

const Instance* Planner::get(SlotRef where) const noexcept {
    const std::optional<Instance>& c = cell(where);
    return c ? &*c : nullptr;
}

Result Planner::check_slot(SlotRef where) const noexcept {
    if (static_cast<std::size_t>(where.place) >= kPlaceCount || where.index >= base_->unlocked(where.place)) {
        return Unexpected(Error::kNoSuchSlot);
    }
    return {};
}

bool Planner::placeable(const Template& tmpl, Place place) const noexcept {
    if (is_bag(place)) return place == tmpl.home;
    if (place == Place::kBank) return tmpl.home != Place::kQuestBag;
    return false;  // ô trang bị chỉ vào qua equip()
}

void Planner::commit(const Edits& edits) {
    for (const SlotChange& change : edits.list()) {
        const auto it = std::ranges::lower_bound(touched_, change.where, {}, &SlotChange::where);
        if (it != touched_.end() && it->where == change.where) {
            it->after = change.after;
        } else {
            touched_.insert(it, change);
        }
    }
}

std::uint64_t Planner::count_of(TemplateId tmpl) const noexcept {
    std::uint64_t total = 0;
    for (std::size_t p = 0; p < kPlaceCount; ++p) {
        const auto place = static_cast<Place>(p);
        for (std::uint16_t i = 0; i < base_->unlocked(place); ++i) {
            const std::optional<Instance>& c = cell(SlotRef{.place = place, .index = i});
            if (c && c->tmpl == tmpl) total += c->count;
        }
    }
    return total;
}

std::uint32_t Planner::free_slots(Place place) const noexcept {
    std::uint32_t free = 0;
    for (std::uint16_t i = 0; i < base_->unlocked(place); ++i) {
        const SlotRef where{.place = place, .index = i};
        if (!cell(where) && !base_->locked(where)) ++free;
    }
    return free;
}

// ----- cất -------------------------------------------------------------------------------------------

Result Planner::add(const Instance& item) {
    const Template* tmpl = catalog_->find(item.tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    return add_impl(tmpl->home, item);
}

Result Planner::add_to(Place place, const Instance& item) { return add_impl(place, item); }

Result Planner::add_impl(Place place, const Instance& item) {
    const Template* tmpl = catalog_->find(item.tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (item.count == 0 || (tmpl->stack_max == 1 && item.count != 1)) return Unexpected(Error::kBadCount);
    if (!placeable(*tmpl, place)) return Unexpected(Error::kWrongPlace);
    if (tmpl->max_owned > 0 && count_of(item.tmpl) + item.count > static_cast<std::uint64_t>(tmpl->max_owned)) {
        return Unexpected(Error::kUniqueOwned);
    }

    Edits edits(*this);
    const std::uint16_t cap = tmpl->stack_max;
    std::uint32_t remaining = item.count;
    const std::uint16_t slots = base_->unlocked(place);
    if (cap > 1) {
        for (std::uint16_t i = 0; i < slots && remaining > 0; ++i) {
            const SlotRef where{.place = place, .index = i};
            const std::optional<Instance>& c = edits.get(where);
            if (!c || base_->locked(where) || !mergeable(*tmpl, *c, item) || c->count >= cap) continue;
            Instance grown = *c;
            const auto take = static_cast<std::uint16_t>(std::min<std::uint32_t>(room(cap, c->count), remaining));
            grown.count = static_cast<std::uint16_t>(grown.count + take);
            remaining -= take;
            edits.set(where, grown);
        }
    }
    bool first = true;
    for (std::uint16_t i = 0; i < slots && remaining > 0; ++i) {
        const SlotRef where{.place = place, .index = i};
        if (edits.get(where) || base_->locked(where)) continue;
        Instance fresh = item;
        fresh.count = static_cast<std::uint16_t>(std::min<std::uint32_t>(cap, remaining));
        if (!first) {
            const std::expected<Serial, Error> serial = serials_->next();
            if (!serial) return Unexpected(serial.error());
            fresh.serial = *serial;
        }
        first = false;
        remaining -= fresh.count;
        edits.set(where, fresh);
    }
    if (remaining > 0) return Unexpected(Error::kBagFull);
    commit(edits);
    return {};
}

// ----- bỏ --------------------------------------------------------------------------------------------

Result Planner::remove_count(TemplateId tmpl, std::uint32_t count) {
    if (count == 0) return Unexpected(Error::kBadCount);
    std::uint64_t have = 0;
    for (const Place place : kBags) {
        for (std::uint16_t i = 0; i < base_->unlocked(place); ++i) {
            const SlotRef where{.place = place, .index = i};
            const std::optional<Instance>& c = cell(where);
            if (c && c->tmpl == tmpl && !base_->locked(where)) have += c->count;
        }
    }
    if (have < count) return Unexpected(Error::kNotEnoughItems);

    Edits edits(*this);
    std::uint32_t remaining = count;
    for (const Place place : kBags) {
        for (std::uint16_t i = 0; i < base_->unlocked(place) && remaining > 0; ++i) {
            const SlotRef where{.place = place, .index = i};
            const std::optional<Instance>& c = cell(where);
            if (!c || c->tmpl != tmpl || base_->locked(where)) continue;
            const auto take = static_cast<std::uint16_t>(std::min<std::uint32_t>(c->count, remaining));
            remaining -= take;
            if (take == c->count) {
                edits.set(where, std::nullopt);
            } else {
                Instance left = *c;
                left.count = static_cast<std::uint16_t>(c->count - take);
                edits.set(where, left);
            }
        }
    }
    commit(edits);
    return {};
}

Result Planner::remove_at(SlotRef where, std::uint16_t count) {
    if (auto bad = check_slot(where); !bad) return bad;
    const std::optional<Instance>& c = cell(where);
    if (!c) return Unexpected(Error::kSlotEmpty);
    if (base_->locked(where)) return Unexpected(Error::kLocked);
    if (count == 0 || count > c->count) return Unexpected(Error::kBadCount);
    Edits edits(*this);
    if (count == c->count) {
        edits.set(where, std::nullopt);
    } else {
        Instance left = *c;
        left.count = static_cast<std::uint16_t>(c->count - count);
        edits.set(where, left);
    }
    commit(edits);
    return {};
}

// ----- đổi chỗ ---------------------------------------------------------------------------------------

Result Planner::move(SlotRef from, SlotRef to) {
    if (from == to) return Unexpected(Error::kNoChange);
    if (auto bad = check_slot(from); !bad) return bad;
    if (auto bad = check_slot(to); !bad) return bad;
    if (from.place == Place::kEquip || to.place == Place::kEquip) return Unexpected(Error::kWrongPlace);
    if (base_->locked(from) || base_->locked(to)) return Unexpected(Error::kLocked);
    const std::optional<Instance>& src = cell(from);
    if (!src) return Unexpected(Error::kSlotEmpty);
    const Template* tmpl = catalog_->find(src->tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (!placeable(*tmpl, to.place)) return Unexpected(Error::kWrongPlace);

    Edits edits(*this);
    const std::optional<Instance>& dst = cell(to);
    if (!dst) {
        edits.set(to, *src);
        edits.set(from, std::nullopt);
    } else if (mergeable(*tmpl, *dst, *src) && dst->count < tmpl->stack_max) {
        const auto take = static_cast<std::uint16_t>(std::min<std::uint32_t>(room(tmpl->stack_max, dst->count), src->count));
        Instance grown = *dst;
        grown.count = static_cast<std::uint16_t>(grown.count + take);
        edits.set(to, grown);
        if (take == src->count) {
            edits.set(from, std::nullopt);
        } else {
            Instance left = *src;
            left.count = static_cast<std::uint16_t>(src->count - take);
            edits.set(from, left);
        }
    } else {
        const Template* other = catalog_->find(dst->tmpl);
        if (other == nullptr) return Unexpected(Error::kUnknownTemplate);
        if (!placeable(*other, from.place)) return Unexpected(Error::kWrongPlace);
        edits.set(to, *src);
        edits.set(from, *dst);
    }
    commit(edits);
    return {};
}

Result Planner::split(SlotRef from, SlotRef to, std::uint16_t count) {
    if (auto bad = check_slot(from); !bad) return bad;
    if (auto bad = check_slot(to); !bad) return bad;
    if (from.place == Place::kEquip || to.place == Place::kEquip) return Unexpected(Error::kWrongPlace);
    if (base_->locked(from) || base_->locked(to)) return Unexpected(Error::kLocked);
    const std::optional<Instance>& src = cell(from);
    if (!src) return Unexpected(Error::kSlotEmpty);
    if (cell(to)) return Unexpected(Error::kSlotOccupied);
    const Template* tmpl = catalog_->find(src->tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (tmpl->stack_max <= 1) return Unexpected(Error::kNotStackable);
    if (count == 0 || count >= src->count) return Unexpected(Error::kBadCount);
    if (!placeable(*tmpl, to.place)) return Unexpected(Error::kWrongPlace);

    const std::expected<Serial, Error> serial = serials_->next();
    if (!serial) return Unexpected(serial.error());
    Edits edits(*this);
    Instance moved = *src;
    moved.serial = *serial;
    moved.count = count;
    Instance left = *src;
    left.count = static_cast<std::uint16_t>(src->count - count);
    edits.set(to, moved);
    edits.set(from, left);
    commit(edits);
    return {};
}

Result Planner::merge(SlotRef from, SlotRef to) {
    if (from == to) return Unexpected(Error::kNoChange);
    if (auto bad = check_slot(from); !bad) return bad;
    if (auto bad = check_slot(to); !bad) return bad;
    if (from.place == Place::kEquip || to.place == Place::kEquip) return Unexpected(Error::kWrongPlace);
    if (base_->locked(from) || base_->locked(to)) return Unexpected(Error::kLocked);
    const std::optional<Instance>& src = cell(from);
    const std::optional<Instance>& dst = cell(to);
    if (!src || !dst) return Unexpected(Error::kSlotEmpty);
    const Template* tmpl = catalog_->find(src->tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (!mergeable(*tmpl, *dst, *src)) {
        return Unexpected(tmpl->stack_max <= 1 ? Error::kNotStackable : Error::kDifferentItems);
    }
    if (dst->count >= tmpl->stack_max) return Unexpected(Error::kStackFull);
    const auto take = static_cast<std::uint16_t>(std::min<std::uint32_t>(room(tmpl->stack_max, dst->count), src->count));
    Edits edits(*this);
    Instance grown = *dst;
    grown.count = static_cast<std::uint16_t>(grown.count + take);
    edits.set(to, grown);
    if (take == src->count) {
        edits.set(from, std::nullopt);
    } else {
        Instance left = *src;
        left.count = static_cast<std::uint16_t>(src->count - take);
        edits.set(from, left);
    }
    commit(edits);
    return {};
}

Result Planner::sort(Place place) {
    if (place == Place::kEquip || static_cast<std::size_t>(place) >= kPlaceCount) return Unexpected(Error::kWrongPlace);
    const std::uint16_t slots = base_->unlocked(place);
    std::vector<Instance> items;
    for (std::uint16_t i = 0; i < slots; ++i) {
        const SlotRef where{.place = place, .index = i};
        if (base_->locked(where)) return Unexpected(Error::kLocked);
        if (const std::optional<Instance>& c = cell(where)) {
            if (catalog_->find(c->tmpl) == nullptr) return Unexpected(Error::kUnknownTemplate);
            items.push_back(*c);
        }
    }
    // Gộp: nhóm các thể hiện cùng khoá rồi đổ đầy chồng đầu, phần dư sang chồng sau.
    std::ranges::sort(items, [](const Instance& a, const Instance& b) {
        return std::tie(a.tmpl, a.bound, a.identified, a.expires_at, a.serial)
            < std::tie(b.tmpl, b.bound, b.identified, b.expires_at, b.serial);
    });
    std::vector<Instance> merged;
    merged.reserve(items.size());
    for (Instance& item : items) {
        const Template* tmpl = catalog_->find(item.tmpl);
        if (!merged.empty() && mergeable(*tmpl, merged.back(), item) && merged.back().count < tmpl->stack_max) {
            Instance& back = merged.back();
            const auto take = static_cast<std::uint16_t>(std::min<std::uint32_t>(room(tmpl->stack_max, back.count), item.count));
            back.count = static_cast<std::uint16_t>(back.count + take);
            item.count = static_cast<std::uint16_t>(item.count - take);
            if (item.count == 0) continue;
        }
        merged.push_back(item);
    }
    // Thứ tự cuối: lớp, mã mẫu, khoá, serial.
    std::ranges::sort(merged, [this](const Instance& a, const Instance& b) {
        const Template* ta = catalog_->find(a.tmpl);
        const Template* tb = catalog_->find(b.tmpl);
        return std::tie(ta->item_class, a.tmpl, a.bound, a.expires_at, a.serial)
            < std::tie(tb->item_class, b.tmpl, b.bound, b.expires_at, b.serial);
    });
    Edits edits(*this);
    for (std::uint16_t i = 0; i < slots; ++i) {
        const SlotRef where{.place = place, .index = i};
        edits.set(where, i < merged.size() ? std::optional<Instance>(merged[i]) : std::nullopt);
    }
    commit(edits);
    return {};
}

// ----- tiền ------------------------------------------------------------------------------------------

Result Planner::earn(Currency currency, std::int64_t amount) {
    // Mã 0 là tài khoản vàng kho, không phải một loại tiền: mã tiền từ bảng cửa hàng không được lọt vào đó.
    if (!is_valid_currency(static_cast<std::uint8_t>(currency))) return Unexpected(Error::kUnknownCurrency);
    Wallet next = wallet_;
    if (auto done = next.earn(account_of(currency), amount); !done) return done;
    wallet_ = next;
    return {};
}

Result Planner::spend(Currency currency, std::int64_t amount) {
    if (!is_valid_currency(static_cast<std::uint8_t>(currency))) return Unexpected(Error::kUnknownCurrency);
    Wallet next = wallet_;
    if (auto done = next.spend(account_of(currency), amount); !done) return done;
    wallet_ = next;
    return {};
}

Result Planner::deposit_gold(std::int64_t amount) {
    Wallet next = wallet_;
    if (auto done = next.spend(account_of(Currency::kGold), amount); !done) return done;
    if (auto done = next.earn(Account::kBankGold, amount); !done) return done;
    wallet_ = next;
    return {};
}

Result Planner::withdraw_gold(std::int64_t amount) {
    Wallet next = wallet_;
    if (auto done = next.spend(Account::kBankGold, amount); !done) return done;
    if (auto done = next.earn(account_of(Currency::kGold), amount); !done) return done;
    wallet_ = next;
    return {};
}

Plan Planner::finish() && {
    Plan plan;
    plan.revision = base_->revision();
    for (const SlotChange& change : touched_) {
        const std::span<const std::optional<Instance>> view = base_->view(change.where.place);
        const bool same = change.where.index < view.size() && view[change.where.index] == change.after;
        if (!same) plan.slots.push_back(change);
    }
    for (std::size_t a = 0; a < kAccountSlots; ++a) {
        const auto account = static_cast<Account>(a);
        if (wallet_.balance(account) != base_->wallet().balance(account)) {
            plan.balances.push_back(BalanceChange{.account = account, .before = base_->wallet().balance(account),
                .after = wallet_.balance(account)});
        }
    }
    return plan;
}

} // namespace game::item
