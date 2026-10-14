#include "billing/checks.hpp"

#include "billing/book.hpp"
#include "billing/error.hpp"
#include "billing/limits.hpp"
#include "billing/rules.hpp"
#include "billing/types.hpp"

#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::billing {

Result<void> check_payment_key(std::string_view provider, std::string_view trade_no) {
    if (!token_ok(provider, kProviderMost) || !token_ok(trade_no, kTradeNoMost)) {
        return std::unexpected(Error::kMalformed);
    }
    return {};
}

Result<void> check_payment_event(const PaymentEvent& event, const Limits& limits) {
    if (const Result<void> key = check_payment_key(event.provider, event.trade_no); !key) return key;
    if (!id_ok(event.account.value()) || !currency_ok(event.currency)) return std::unexpected(Error::kMalformed);
    if (event.points.value() < 1 || event.points.value() > limits.max_points_per_topup) {
        return std::unexpected(Error::kBadAmount);
    }
    if (event.amount_minor < 0 || event.amount_minor > kAmountMinorMost) return std::unexpected(Error::kBadAmount);
    return {};
}

Result<void> check_exchange_request(const ExchangeRequest& request) {
    if (!id_ok(request.account.value()) || !id_ok(request.character.value()) || !id_ok(request.request.value())) {
        return std::unexpected(Error::kMalformed);
    }
    return {};
}

Result<void> check_batch_spec(BatchSpec& spec, const Limits& limits) {
    const std::optional<std::string> name = clean_text(spec.name, kBatchNameMost);
    const std::optional<std::string> actor = clean_text(spec.actor, kActorMost);
    if (!name || !actor) return std::unexpected(Error::kReasonRequired);
    if (spec.per_account_limit < 1 || spec.per_account_limit > kPerAccountLimitMost) {
        return std::unexpected(Error::kBadAmount);
    }
    if (spec.rewards.empty() || spec.rewards.size() > kRewardsMost) return std::unexpected(Error::kTooMany);
    for (const Reward& reward : spec.rewards) {
        if (!reward_ok(reward, limits)) return std::unexpected(Error::kBadAmount);
    }
    if (spec.starts && spec.starts->value() < 0) return std::unexpected(Error::kBadAmount);
    if (spec.ends && spec.ends->value() < 0) return std::unexpected(Error::kBadAmount);
    if (spec.starts && spec.ends && spec.starts->value() > spec.ends->value()) {
        return std::unexpected(Error::kBadAmount);
    }
    spec.name = *name;
    spec.actor = *actor;
    return {};
}

Result<void> check_grant_spec(GrantSpec& spec, const Limits& limits) {
    if (!id_ok(spec.account.value())) return std::unexpected(Error::kMalformed);
    if (!grant_ref_ok(spec.kind, spec.ref_id)) return std::unexpected(Error::kMalformed);
    if (spec.quantity < 1 || spec.quantity > limits.max_grant_quantity) return std::unexpected(Error::kBadAmount);
    if (!token_ok(spec.source, kSourceMost)) return std::unexpected(Error::kMalformed);
    const std::optional<std::string> reason = clean_text(spec.reason, kReasonMost);
    const std::optional<std::string> actor = clean_text(spec.actor, kActorMost);
    if (!reason || !actor) return std::unexpected(Error::kReasonRequired);
    spec.reason = *reason;
    spec.actor = *actor;
    return {};
}

bool hash_hex_ok(std::string_view hash) noexcept {
    if (hash.size() != 64) return false;
    for (const char c : hash) {
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) return false;
    }
    return true;
}

Result<void> check_code_hashes(std::span<const std::string> hashes) {
    if (hashes.empty() || hashes.size() > kCodesPerCallMost) return std::unexpected(Error::kTooMany);
    for (const std::string& hash : hashes) {
        if (!hash_hex_ok(hash)) return std::unexpected(Error::kMalformed);
    }
    return {};
}

Result<void> check_spend_events(std::span<const SpendEvent> events) {
    if (events.empty() || events.size() > kSpendBatchMost) return std::unexpected(Error::kTooMany);
    for (const SpendEvent& event : events) {
        if (!id_ok(event.event) || !id_ok(event.account.value()) || !id_ok(event.character.value())) {
            return std::unexpected(Error::kMalformed);
        }
        if (event.amount.value() < 1 || event.amount.value() > kSpendAmountMost) {
            return std::unexpected(Error::kBadAmount);
        }
    }
    return {};
}

} // namespace game::billing
