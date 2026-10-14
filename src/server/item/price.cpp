// Giá bán và phí sửa: xem price.hpp.
#include "item/price.hpp"

#include "item/catalog.hpp"
#include "item/detail/arith.hpp"
#include "item/instance.hpp"
#include "item/types.hpp"

#include <algorithm>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>

namespace game::item {
namespace {

using Unexpected = std::unexpected<Error>;
using detail::checked_mul;

// Nhân dây chuyền; nullopt nếu tràn ở bước nào.
[[nodiscard]] std::optional<std::int64_t> product(std::int64_t a, std::int64_t b, std::int64_t c) noexcept {
    const std::optional<std::int64_t> ab = checked_mul(a, b);
    return ab ? checked_mul(*ab, c) : std::nullopt;
}

} // namespace

std::expected<std::int64_t, Error> sell_value(const Template& tmpl, const Instance& item, const PriceRules& rules,
    std::uint32_t shop_scale_permille) {
    if (!tmpl.rule.sell) return Unexpected(Error::kForbidden);
    const bool wears = tmpl.kind == Kind::kEquipment && tmpl.equip.max_durability > 0;
    const std::int64_t cur = wears ? std::min(item.durability, tmpl.equip.max_durability) : 1;
    const std::int64_t max = wears ? tmpl.equip.max_durability : 1;
    const std::int64_t factor = item.identified ? rules.identified_sale_permille : rules.unidentified_sale_permille;
    const std::int64_t fails = wears ? item.repair_fails : 0;

    const std::optional<std::int64_t> head = product(tmpl.base_price, item.count, factor);
    const std::optional<std::int64_t> mid = head ? product(*head, cur, shop_scale_permille) : std::nullopt;
    const std::optional<std::int64_t> divisor = product(kPermille, max * (fails + 1), kPermille);
    if (!mid || !divisor || *divisor == 0) return Unexpected(Error::kBadAmount);
    return *mid / *divisor;
}

std::expected<std::int64_t, Error> repair_cost(const Template& tmpl, const Instance& item,
    std::uint32_t shop_repair_permille) {
    if (tmpl.kind != Kind::kEquipment || tmpl.equip.max_durability == 0) return 0;
    const std::int64_t max = tmpl.equip.max_durability;
    const std::int64_t cur = std::min<std::int64_t>(item.durability, max);
    if (cur >= max) return 0;
    // phí = giá * (max - cur) / max * spend/1000 + 0,5  ->  (2*giá*(max-cur)*spend + 1000*max) / (2000*max)
    const std::optional<std::int64_t> raw = product(tmpl.base_price, max - cur, shop_repair_permille);
    if (!raw) return Unexpected(Error::kBadAmount);
    const std::optional<std::int64_t> twice = checked_mul(*raw, 2);
    const std::optional<std::int64_t> bias = checked_mul(1000, max);
    const std::optional<std::int64_t> divisor = checked_mul(2000, max);
    if (!twice || !bias || !divisor || *twice > std::numeric_limits<std::int64_t>::max() - *bias) return Unexpected(Error::kBadAmount);
    return (*twice + *bias) / *divisor;
}

} // namespace game::item
