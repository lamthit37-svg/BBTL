// Cửa hàng của một NPC lúc chạy: xem npc_shop.hpp.
#include "shop/npc_shop.hpp"

#include "item/types.hpp"
#include "shop/tables.hpp"
#include "shop/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <utility>
#include <vector>

namespace game::shop {
namespace {

using Unexpected = std::unexpected<item::Error>;

} // namespace

NpcShop::NpcShop(const ShopTables& tables, const ShopDef& def, ids::Tick now, dice::Dice& dice)
    : tables_(&tables), def_(&def), interval_(ids::to_ticks(def.refresh_ms, item::kTicksPerSecond)),
      next_refresh_(ids::advance(now, interval_)) {
    if (def.random) {
        stock_random(dice);
    } else {
        stock_fixed();
    }
}

std::expected<NpcShop, item::Error> NpcShop::open(const ShopTables& tables, ShopId shop, ids::SceneId scene, ids::Tick now,
    dice::Dice& dice) {
    const ShopDef* def = tables.find(shop);
    if (def == nullptr) return Unexpected(item::Error::kNoSuchEntry);
    if (!tables.allowed_in(*def, scene)) return Unexpected(item::Error::kWrongScene);
    return NpcShop(tables, *def, now, dice);
}

void NpcShop::stock_fixed() {
    lines_.clear();
    for (const Goods& goods : tables_->goods(*def_)) lines_.push_back(Line{.goods = goods, .stock = goods.capacity});
}

void NpcShop::stock_random(dice::Dice& dice) {
    lines_.clear();
    const std::span<const PoolEntry> pool = tables_->pool(*def_);
    std::vector<std::uint32_t> weights;
    weights.reserve(pool.size());
    for (const PoolEntry& entry : pool) weights.push_back(entry.odds);
    // Rút không hoàn lại: mục đã rút có trọng số 0 nên không bao giờ rút lại.
    std::vector<std::size_t> chosen;
    const std::size_t want = std::min<std::size_t>(def_->pick_count, pool.size());
    while (chosen.size() < want) {
        const auto pick = dice.pick_weighted(weights);
        if (!pick) break;
        chosen.push_back(*pick);
        weights.at(*pick) = 0;
    }
    std::ranges::sort(chosen);
    for (const std::size_t index : chosen) {
        const Goods& goods = pool[index].goods;
        lines_.push_back(Line{.goods = goods, .stock = goods.capacity});
    }
}

bool NpcShop::tick(ids::Tick now, dice::Dice& dice) {
    if (!has_refresh() || now < next_refresh_) return false;
    // Một hạn bị lỡ chỉ làm mới một lần: hạn kế tính từ bây giờ.
    next_refresh_ = ids::advance(now, interval_);
    const std::vector<Line> before = lines_;
    if (def_->random) {
        stock_random(dice);
    } else {
        stock_fixed();
    }
    if (lines_ == before) return false;
    ++revision_;
    return true;
}

std::expected<void, item::Error> NpcShop::commit(const BuyTicket& ticket) {
    if (ticket.revision != revision_) return Unexpected(item::Error::kStalePlan);
    if (ticket.line >= lines_.size()) return Unexpected(item::Error::kNoSuchEntry);
    if (ticket.groups == 0) return Unexpected(item::Error::kBadCount);
    Line& line = lines_.at(ticket.line);
    if (line.stock == kUnlimited) return {};
    if (std::cmp_less(line.stock, ticket.groups)) return Unexpected(item::Error::kSoldOut);
    line.stock -= static_cast<std::int32_t>(ticket.groups);
    ++revision_;
    return {};
}

} // namespace game::shop
