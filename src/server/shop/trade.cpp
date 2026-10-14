// Mua, bán, sửa, thu hồi phế phẩm: xem trade.hpp.
#include "shop/trade.hpp"

#include "item/catalog.hpp"
#include "item/factory.hpp"
#include "item/instance.hpp"
#include "item/inventory.hpp"
#include "item/planner.hpp"
#include "item/price.hpp"
#include "item/types.hpp"
#include "shop/npc_shop.hpp"
#include "shop/tables.hpp"
#include "shop/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <iterator>
#include <limits>
#include <optional>
#include <span>
#include <utility>
#include <vector>

namespace game::shop {
namespace {

using Unexpected = std::unexpected<item::Error>;

// Mẫu số của giá: hệ số cửa hàng theo phần nghìn nhân chiết khấu theo phần trăm.
constexpr std::int64_t kPriceDenominator = std::int64_t{item::kPermille} * kPercent;

[[nodiscard]] std::optional<std::int64_t> checked_mul(std::int64_t a, std::int64_t b) noexcept {
    if (a == 0 || b == 0) return 0;
    if (a < 0 || b < 0) return std::nullopt;
    if (a > std::numeric_limits<std::int64_t>::max() / b) return std::nullopt;
    return a * b;
}

// Lỗi của ô không có đồ: ô ngoài biên hay ô trống. Planner::get trả nullptr cho cả hai nên hỏi remove_at để biết cái nào.
[[nodiscard]] item::Error empty_slot_error(const item::Planner& planner, item::SlotRef where) {
    item::Planner probe = planner;
    const item::Result probed = probe.remove_at(where, 1);
    return probed ? item::Error::kSlotEmpty : probed.error();
}

// Cửa hàng có sửa món này không (cấp và điểm lắp).
[[nodiscard]] bool repairable_here(const ShopDef& shop, const item::Template& tmpl) noexcept {
    return tmpl.level <= shop.repair_level && covers_point(shop.repair_scope, tmpl.equip.point);
}

[[nodiscard]] bool wears_out(const item::Template& tmpl) noexcept {
    return tmpl.kind == item::Kind::kEquipment && tmpl.equip.max_durability > 0;
}

} // namespace

std::expected<std::int64_t, item::Error> price_of(const ShopDef& shop, const Goods& goods, const item::Catalog& catalog) {
    std::int64_t listed = goods.listed_price;
    if (is_gold_like(shop.currency)) {
        const item::Template* tmpl = catalog.find(goods.item);
        if (tmpl == nullptr) return Unexpected(item::Error::kUnknownTemplate);
        const std::optional<std::int64_t> base = checked_mul(tmpl->base_price, goods.group);
        if (!base) return Unexpected(item::Error::kBadAmount);
        listed = *base;
    }
    const std::optional<std::int64_t> scaled = checked_mul(listed, shop.scale_permille);
    const std::optional<std::int64_t> numerator = scaled ? checked_mul(*scaled, goods.discount_percent) : std::nullopt;
    if (!numerator || *numerator > std::numeric_limits<std::int64_t>::max() - kPriceDenominator) {
        return Unexpected(item::Error::kBadAmount);
    }
    // Làm tròn nửa lên một lần; hàng có giá thì không bao giờ về 0 (chiết khấu 5% của món giá 2 không thành đồ cho không).
    const std::int64_t rounded = (*numerator + (kPriceDenominator / 2)) / kPriceDenominator;
    return listed > 0 ? std::max<std::int64_t>(rounded, 1) : 0;
}

std::expected<BuyTicket, item::Error> plan_buy(const NpcShop& shop, const BuyRequest& request, const item::Factory& factory,
    dice::Dice& dice, item::SerialAllocator& serials, ids::Tick now, item::Planner& planner) {
    if (request.groups == 0 || request.groups > kMaxBuyGroups) return Unexpected(item::Error::kBadCount);
    const std::span<const Line> lines = shop.lines();
    if (request.line >= lines.size()) return Unexpected(item::Error::kNoSuchEntry);
    const Line& line = *std::next(lines.begin(), static_cast<std::ptrdiff_t>(request.line));
    if (line.stock != kUnlimited && std::cmp_less(line.stock, request.groups)) return Unexpected(item::Error::kSoldOut);

    const item::Template* tmpl = factory.catalog().find(line.goods.item);
    if (tmpl == nullptr) return Unexpected(item::Error::kUnknownTemplate);
    const std::expected<std::int64_t, item::Error> price = price_of(shop.def(), line.goods, factory.catalog());
    if (!price) return Unexpected(price.error());
    const std::optional<std::int64_t> total = checked_mul(*price, request.groups);
    if (!total) return Unexpected(item::Error::kBadAmount);

    // Mọi bước dựng trên bản sao: một bước hỏng thì planner của người gọi không đổi gì.
    item::Planner trial = planner;
    if (*total > 0) {
        if (const item::Result paid = trial.spend(shop.def().currency, *total); !paid) return Unexpected(paid.error());
    }
    std::uint32_t remaining = std::uint32_t{line.goods.group} * request.groups;
    const std::uint32_t stack = std::max<std::uint32_t>(tmpl->stack_max, 1);
    while (remaining > 0) {
        const auto chunk = static_cast<std::uint16_t>(std::min(remaining, stack));
        const std::expected<item::Instance, item::Error> made =
            factory.create({.tmpl = line.goods.item, .count = chunk, .picked = false, .now = now, .roll = {}}, dice, serials);
        if (!made) return Unexpected(made.error());
        if (const item::Result added = trial.add(*made); !added) return Unexpected(added.error());
        remaining -= chunk;
    }
    planner = std::move(trial);
    return BuyTicket{.line = static_cast<std::uint16_t>(request.line), .groups = request.groups, .revision = shop.revision()};
}

std::expected<SellTicket, item::Error> plan_sell(const ShopDef& shop, const item::Catalog& catalog, const item::PriceRules& rules,
    item::SlotRef from, item::Planner& planner) {
    if (!item::is_bag(from.place)) return Unexpected(item::Error::kWrongPlace);
    const item::Instance* held = planner.get(from);
    if (held == nullptr) return Unexpected(empty_slot_error(planner, from));
    const item::Template* tmpl = catalog.find(held->tmpl);
    if (tmpl == nullptr) return Unexpected(item::Error::kUnknownTemplate);
    if (tmpl->level > shop.buy_level || !accepts(shop.buy_scope, *tmpl)) return Unexpected(item::Error::kShopRefuses);
    const std::expected<std::int64_t, item::Error> price = item::sell_value(*tmpl, *held, rules, shop.scale_permille);
    if (!price) return Unexpected(price.error());

    const item::Instance sold = *held;  // sao trước: remove_at làm `held` không còn nghĩa
    item::Planner trial = planner;
    if (const item::Result removed = trial.remove_at(from, sold.count); !removed) return Unexpected(removed.error());
    if (*price > 0) {
        if (const item::Result paid = trial.earn(item::Currency::kGold, *price); !paid) return Unexpected(paid.error());
    }
    planner = std::move(trial);
    return SellTicket{.item = sold, .price = *price, .remember = shop.can_buy_back};
}

void SoldList::remember(const SellTicket& ticket) {
    if (!ticket.remember) return;
    if (entries_.size() >= kSoldCapacity) entries_.erase(entries_.begin());
    entries_.push_back(SoldEntry{.item = ticket.item, .price = ticket.price});
}

std::expected<void, item::Error> SoldList::take(const BuyBackTicket& ticket) {
    if (entries_.empty()) return Unexpected(item::Error::kNoSuchEntry);
    if (entries_.back().item.serial != ticket.serial) return Unexpected(item::Error::kStalePlan);
    entries_.pop_back();
    return {};
}

std::expected<BuyBackTicket, item::Error> plan_buy_back(const SoldList& list, item::Planner& planner) {
    const SoldEntry* top = list.top();
    if (top == nullptr) return Unexpected(item::Error::kNoSuchEntry);
    item::Planner trial = planner;
    if (top->price > 0) {
        if (const item::Result paid = trial.spend(item::Currency::kGold, top->price); !paid) return Unexpected(paid.error());
    }
    if (const item::Result added = trial.add(top->item); !added) return Unexpected(added.error());
    planner = std::move(trial);
    return BuyBackTicket{.serial = top->item.serial};
}

std::expected<RepairReport, item::Error> plan_repair(const ShopDef& shop, const item::Catalog& catalog, item::SlotRef where,
    item::Planner& planner) {
    const item::Instance* held = planner.get(where);
    if (held == nullptr) {
        item::Planner probe = planner;
        const item::Result probed = probe.repair(where, shop.repair_permille);
        return Unexpected(probed ? item::Error::kSlotEmpty : probed.error());
    }
    const item::Template* tmpl = catalog.find(held->tmpl);
    if (tmpl == nullptr) return Unexpected(item::Error::kUnknownTemplate);
    if (!repairable_here(shop, *tmpl)) return Unexpected(item::Error::kShopRefuses);
    const std::int64_t before = planner.wallet().balance(item::Currency::kGold);
    if (const item::Result fixed = planner.repair(where, shop.repair_permille); !fixed) return Unexpected(fixed.error());
    return RepairReport{
        .repaired = 1, .spent = before - planner.wallet().balance(item::Currency::kGold), .short_of_money = false};
}

std::expected<RepairReport, item::Error> plan_repair_all(const ShopDef& shop, const item::Catalog& catalog, item::Planner& planner) {
    item::Planner trial = planner;
    const std::int64_t before = trial.wallet().balance(item::Currency::kGold);
    RepairReport report;
    for (std::uint16_t point = 0; point < item::kEquipSlots; ++point) {
        const item::SlotRef where{.place = item::Place::kEquip, .index = point};
        const item::Instance* held = trial.get(where);
        if (held == nullptr) continue;
        const item::Template* tmpl = catalog.find(held->tmpl);
        if (tmpl == nullptr || !wears_out(*tmpl) || !repairable_here(shop, *tmpl)) continue;
        const item::Result fixed = trial.repair(where, shop.repair_permille);
        if (fixed) {
            ++report.repaired;
        } else if (fixed.error() == item::Error::kInsufficientFunds) {
            report.short_of_money = true;
            break;
        } else if (fixed.error() != item::Error::kNoChange && fixed.error() != item::Error::kLocked) {
            return Unexpected(fixed.error());
        }
    }
    if (report.repaired == 0) {
        return Unexpected(report.short_of_money ? item::Error::kInsufficientFunds : item::Error::kNoChange);
    }
    report.spent = before - trial.wallet().balance(item::Currency::kGold);
    planner = std::move(trial);
    return report;
}

std::expected<RecycleReceipt, item::Error> plan_recycle(const ShopTables& tables, item::SlotRef from, std::uint16_t count,
    item::Planner& planner) {
    if (!item::is_bag(from.place)) return Unexpected(item::Error::kWrongPlace);
    const item::Instance* held = planner.get(from);
    if (held == nullptr) return Unexpected(empty_slot_error(planner, from));
    if (count == 0 || count > held->count) return Unexpected(item::Error::kBadCount);
    const item::TemplateId id = held->tmpl;
    const std::optional<std::int64_t> each = tables.junk_value(id);
    if (!each) return Unexpected(item::Error::kShopRefuses);
    const std::optional<std::int64_t> gold = checked_mul(*each, count);
    if (!gold) return Unexpected(item::Error::kBadAmount);

    item::Planner trial = planner;
    if (const item::Result removed = trial.remove_at(from, count); !removed) return Unexpected(removed.error());
    if (*gold > 0) {
        if (const item::Result paid = trial.earn(item::Currency::kGold, *gold); !paid) return Unexpected(paid.error());
    }
    planner = std::move(trial);
    return RecycleReceipt{.item = id, .count = count, .gold = *gold};
}

} // namespace game::shop
