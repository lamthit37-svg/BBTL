#include "billing/book.hpp"

#include "billing/limits.hpp"
#include "billing/rules.hpp"

#include <array>
#include <optional>
#include <string_view>

namespace game::billing {
namespace {

struct KindName {
    LedgerKind kind;
    std::string_view text;
};

constexpr std::array kKinds{
    KindName{.kind = LedgerKind::kTopUp, .text = "top_up"},
    KindName{.kind = LedgerKind::kRefund, .text = "refund"},
    KindName{.kind = LedgerKind::kExchangeHold, .text = "exchange_hold"},
    KindName{.kind = LedgerKind::kExchangeRelease, .text = "exchange_release"},
    KindName{.kind = LedgerKind::kRegisterGift, .text = "register_gift"},
    KindName{.kind = LedgerKind::kRedeem, .text = "redeem"},
    KindName{.kind = LedgerKind::kAdmin, .text = "admin"},
};

} // namespace

std::string_view to_text(LedgerKind kind) noexcept {
    for (const KindName& entry : kKinds) {
        if (entry.kind == kind) return entry.text;
    }
    return {};
}

std::optional<LedgerKind> ledger_kind_of(std::string_view text) noexcept {
    for (const KindName& entry : kKinds) {
        if (entry.text == text) return entry.kind;
    }
    return std::nullopt;
}

bool reward_ok(const Reward& reward, const Limits& limits) noexcept {
    if (reward.kind == 0) {
        return reward.ref_id == 0 && reward.quantity >= 1 && reward.quantity <= limits.max_points_per_topup;
    }
    if (!grant_kind_ok(reward.kind)) return false;
    if (!grant_ref_ok(static_cast<GrantKind>(reward.kind), reward.ref_id)) return false;
    return reward.quantity >= 1 && reward.quantity <= limits.max_grant_quantity;
}

} // namespace game::billing
