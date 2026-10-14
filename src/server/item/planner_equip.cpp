// Planner: mặc, tháo, giám định, thay thể hiện, hao mòn và sửa. Phần túi và ví ở planner.cpp.
#include "item/planner.hpp"

#include "item/catalog.hpp"
#include "item/detail/planner_edits.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/price.hpp"
#include "item/types.hpp"

#include <cstdint>
#include <expected>
#include <optional>

namespace game::item {
namespace {

using Unexpected = std::unexpected<Error>;

constexpr std::uint8_t kBlueQuality = 2;  // EQUALITY_BLUE của 2008: chỉ đồ lam cần giám định

} // namespace

Result Planner::equip(SlotRef from, const Actor& actor) {
    if (auto bad = check_slot(from); !bad) return bad;
    if (!is_bag(from.place)) return Unexpected(Error::kWrongPlace);
    const std::optional<Instance>& src = cell(from);
    if (!src) return Unexpected(Error::kSlotEmpty);
    if (base_->locked(from)) return Unexpected(Error::kLocked);
    const Template* tmpl = catalog_->find(src->tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (tmpl->kind != Kind::kEquipment || tmpl->equip.point == kNoEquipPoint || tmpl->equip.point >= kEquipSlots) {
        return Unexpected(Error::kNotEquipment);
    }
    // Thứ tự kiểm theo CGUseEquipHandler: cấp, rồi giám định; môn phái và giới tính là điều kiện thêm của bản này.
    if (tmpl->level > actor.level) return Unexpected(Error::kLevelTooLow);
    if (tmpl->quality == kBlueQuality && !src->identified) return Unexpected(Error::kNotIdentified);
    if (tmpl->equip.sect != kAnySect && tmpl->equip.sect != actor.sect) return Unexpected(Error::kWrongSect);
    if (tmpl->equip.sex != kAnySex && tmpl->equip.sex != actor.sex) return Unexpected(Error::kWrongSex);

    // Nhẫn và bùa hộ thân có hai ô: vào ô thứ nhất, đầy thì ô thứ hai, cả hai đầy thì đổi với ô thứ nhất.
    std::uint8_t point = tmpl->equip.point;
    if (point == kEquipRing && cell(SlotRef{.place = Place::kEquip, .index = kEquipRing}) &&
        !cell(SlotRef{.place = Place::kEquip, .index = kEquipRing2})) {
        point = kEquipRing2;
    } else if (point == kEquipCharm && cell(SlotRef{.place = Place::kEquip, .index = kEquipCharm}) &&
        !cell(SlotRef{.place = Place::kEquip, .index = kEquipCharm2})) {
        point = kEquipCharm2;
    }
    const SlotRef target{.place = Place::kEquip, .index = point};
    if (base_->locked(target)) return Unexpected(Error::kLocked);

    Edits edits(*this);
    Instance worn = *src;
    if (tmpl->rule.equip_bind) worn.bound = true;
    const std::optional<Instance>& previous = cell(target);
    edits.set(target, worn);
    edits.set(from, previous);  // ô trống hay món cũ về đúng chỗ món mới vừa rời
    commit(edits);
    return {};
}

Result Planner::unequip(std::uint8_t point) {
    const SlotRef from{.place = Place::kEquip, .index = point};
    if (auto bad = check_slot(from); !bad) return bad;
    const std::optional<Instance>& src = cell(from);
    if (!src) return Unexpected(Error::kSlotEmpty);
    if (base_->locked(from)) return Unexpected(Error::kLocked);
    const Template* tmpl = catalog_->find(src->tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    const Place home = tmpl->home;
    for (std::uint16_t i = 0; i < base_->unlocked(home); ++i) {
        const SlotRef to{.place = home, .index = i};
        if (cell(to) || base_->locked(to)) continue;
        Edits edits(*this);
        edits.set(to, *src);
        edits.set(from, std::nullopt);
        commit(edits);
        return {};
    }
    return Unexpected(Error::kBagFull);
}

Result Planner::identify(SlotRef where) {
    if (auto bad = check_slot(where); !bad) return bad;
    const std::optional<Instance>& src = cell(where);
    if (!src) return Unexpected(Error::kSlotEmpty);
    if (base_->locked(where)) return Unexpected(Error::kLocked);
    const Template* tmpl = catalog_->find(src->tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (tmpl->kind != Kind::kEquipment) return Unexpected(Error::kNotEquipment);
    if (src->identified) return Unexpected(Error::kNoChange);
    Instance next = *src;
    next.identified = true;
    Edits edits(*this);
    edits.set(where, next);
    commit(edits);
    return {};
}

Result Planner::update(SlotRef where, const Instance& next) {
    if (auto bad = check_slot(where); !bad) return bad;
    const std::optional<Instance>& src = cell(where);
    if (!src) return Unexpected(Error::kSlotEmpty);
    if (base_->locked(where)) return Unexpected(Error::kLocked);
    if (src->serial != next.serial || src->tmpl != next.tmpl || next.count == 0) {
        return Unexpected(Error::kBrokenPlan);
    }
    Edits edits(*this);
    edits.set(where, next);
    commit(edits);
    return {};
}

Result Planner::wear_impl(std::uint16_t first, std::uint16_t last, std::uint16_t threshold) {
    Edits edits(*this);
    for (std::uint16_t point = first; point <= last; ++point) {
        const SlotRef where{.place = Place::kEquip, .index = point};
        const std::optional<Instance>& src = cell(where);
        if (!src) continue;
        const Template* tmpl = catalog_->find(src->tmpl);
        if (tmpl == nullptr || tmpl->kind != Kind::kEquipment || tmpl->equip.max_durability == 0) continue;
        Instance next = *src;
        if (next.wear >= threshold) {  // wear + 1 > threshold, viết như vầy để wear không tràn uint16
            next.wear = 0;
            if (next.durability > 0) --next.durability;
        } else {
            ++next.wear;
        }
        edits.set(where, next);
    }
    commit(edits);
    return {};
}

Result Planner::wear_armor(std::uint16_t threshold) {
    return wear_impl(1, static_cast<std::uint16_t>(kEquipSlots - 1), threshold);
}

Result Planner::wear_weapon(std::uint16_t threshold) { return wear_impl(kEquipWeapon, kEquipWeapon, threshold); }

Result Planner::repair(SlotRef where, std::uint32_t shop_repair_permille) {
    if (auto bad = check_slot(where); !bad) return bad;
    if (where.place == Place::kBank) return Unexpected(Error::kWrongPlace);
    const std::optional<Instance>& src = cell(where);
    if (!src) return Unexpected(Error::kSlotEmpty);
    if (base_->locked(where)) return Unexpected(Error::kLocked);
    const Template* tmpl = catalog_->find(src->tmpl);
    if (tmpl == nullptr) return Unexpected(Error::kUnknownTemplate);
    if (tmpl->kind != Kind::kEquipment || tmpl->equip.max_durability == 0) return Unexpected(Error::kNoDurability);
    const std::expected<std::int64_t, Error> cost = repair_cost(*tmpl, *src, shop_repair_permille);
    if (!cost) return Unexpected(cost.error());
    if (*cost == 0 && src->durability >= tmpl->equip.max_durability) return Unexpected(Error::kNoChange);
    Wallet next_wallet = wallet_;
    if (*cost > 0) {
        if (auto paid = next_wallet.spend(account_of(Currency::kGold), *cost); !paid) return paid;
    }
    Instance fixed = *src;
    fixed.durability = tmpl->equip.max_durability;
    Edits edits(*this);
    edits.set(where, fixed);
    commit(edits);
    wallet_ = next_wallet;
    return {};
}

} // namespace game::item
