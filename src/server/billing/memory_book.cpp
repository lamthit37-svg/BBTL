#include "billing/memory_book.hpp"

#include "billing/book.hpp"
#include "billing/checks.hpp"
#include "billing/error.hpp"
#include "billing/rules.hpp"
#include "billing/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

constexpr std::string_view kSystem = "system";

[[nodiscard]] std::size_t clamp_limit(std::size_t limit, std::size_t most) noexcept {
    return std::clamp<std::size_t>(limit, 1, most);
}

[[nodiscard]] bool in_day(UnixTime when, std::int64_t day) noexcept {
    const std::optional<std::int64_t> mine = day_of(when);
    return mine && *mine == day;
}

[[nodiscard]] bool is_open(ExchangeStatus status) noexcept {
    return status == ExchangeStatus::kPending || status == ExchangeStatus::kStale;
}

} // namespace

MemoryBook::MemoryBook(BookConfig config) : config_(config) {}

Points MemoryBook::cache_of(AccountId account) const {
    const auto found = cache_.find(account);
    return found == cache_.end() ? Points{0} : found->second;
}

bool MemoryBook::frozen_of(AccountId account) const {
    return frozen_.contains(account);
}

Points MemoryBook::held_of(AccountId account) const {
    std::int64_t held = 0;
    for (const auto& [id, order] : exchanges_) {
        if (order.account == account && is_open(order.status)) held += order.points.value();
    }
    return Points{held};
}

std::int64_t MemoryBook::spent_today(CharacterId character, std::int64_t day) const {
    std::int64_t total = 0;
    for (const auto& [id, row] : spends_) {
        if (row.event.character == character && row.day == day) total += row.event.amount.value();
    }
    return total;
}

Result<void> MemoryBook::post(AccountId account, Points delta, LedgerKind kind, std::uint64_t ref,
    std::string_view reason, std::string_view actor, UnixTime now) {
    if (ref != 0 && ledger_keys_.contains({kind, ref})) return std::unexpected(Error::kConflict);
    const std::optional<std::int64_t> next = add_checked(cache_of(account).value(), delta.value());
    if (!next) return std::unexpected(Error::kBadAmount);
    if (*next < 0) return std::unexpected(Error::kInsufficient);
    ledger_.push_back(LedgerEntry{.id = next_ledger_++,
        .account = account,
        .delta = delta,
        .kind = kind,
        .ref = ref,
        .reason = std::string{reason},
        .actor = std::string{actor},
        .at = now});
    if (ref != 0) ledger_keys_.insert({kind, ref});
    cache_[account] = Points{*next};
    return {};
}

void MemoryBook::corrupt_cache_for_test(AccountId account, Points value) {
    cache_[account] = value;
}

Result<Balance> MemoryBook::ensure_account(AccountId account, UnixTime now) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    const bool wants_gift = config_.register_gift.value() > 0 && !ledger_keys_.contains({LedgerKind::kRegisterGift,
        account.value()});
    if (wants_gift) {
        const Result<Points> next = credit_step(config_.register_gift, cache_of(account), config_.limits);
        if (!next) return std::unexpected(next.error());
        const Result<void> posted = post(account, config_.register_gift, LedgerKind::kRegisterGift, account.value(),
            "quà đăng ký", kSystem, now);
        if (!posted) return std::unexpected(posted.error());
    }
    return balance(account);
}

Result<Balance> MemoryBook::balance(AccountId account) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    return Balance{.available = cache_of(account), .held = held_of(account), .frozen = frozen_of(account)};
}

Result<void> MemoryBook::set_frozen(AccountId account, bool frozen, const Audit& audit, UnixTime) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    if (!clean_text(audit.reason, kReasonMost) || !clean_text(audit.actor, kActorMost)) {
        return std::unexpected(Error::kReasonRequired);
    }
    if (frozen) frozen_.insert(account);
    if (!frozen) frozen_.erase(account);
    return {};
}

Result<PaymentOutcome> MemoryBook::apply_payment(const PaymentEvent& event, UnixTime now) {
    if (const Result<void> ok = check_payment_event(event, config_.limits); !ok) return std::unexpected(ok.error());
    const auto key = std::pair{event.provider, event.trade_no};
    const auto found = payments_.find(key);
    std::optional<PaymentStatus> existing;
    if (found != payments_.end()) {
        const PaymentEvent& old = found->second.event;
        const bool same = old.account == event.account && old.points == event.points &&
            old.amount_minor == event.amount_minor && old.currency == event.currency;
        if (!same) return std::unexpected(Error::kConflict);
        existing = old.status;
    }
    const Result<PaymentAct> act = payment_step(existing, event.status);
    if (!act) return std::unexpected(act.error());
    PaymentOutcome outcome;
    if (*act == PaymentAct::kDuplicate || *act == PaymentAct::kIgnore) {
        outcome.result = *act == PaymentAct::kDuplicate ? PaymentResult::kDuplicate : PaymentResult::kIgnored;
        outcome.record = found->second;
        outcome.balance = cache_of(event.account);
        return outcome;
    }
    const bool is_new = found == payments_.end();
    PaymentRecord record = is_new ? PaymentRecord{.id = PaymentId{next_payment_}, .event = event, .created = now,
                                        .updated = now}
                                  : found->second;
    record.event.status = event.status;
    record.updated = now;
    const bool credits = *act == PaymentAct::kCreatePaid || *act == PaymentAct::kPromote;
    if (credits) {
        const Result<void> posted = post(event.account, event.points, LedgerKind::kTopUp, record.id.value(), "nạp",
            event.provider, now);
        if (!posted) return std::unexpected(posted.error());
    }
    if (*act == PaymentAct::kRefund) {
        const Result<void> posted = post(event.account, Points{-event.points.value()}, LedgerKind::kRefund,
            record.id.value(), "nhà cung cấp hoàn tiền", event.provider, now);
        if (!posted) return std::unexpected(posted.error());
    }
    if (is_new) ++next_payment_;
    payments_[key] = record;
    outcome.record = std::move(record);
    outcome.balance = cache_of(event.account);
    return outcome;
}

Result<PaymentOutcome> MemoryBook::refund_payment(const PaymentKey& key, const Audit& audit, UnixTime now) {
    if (const Result<void> ok = check_payment_key(key.provider, key.trade_no); !ok) return std::unexpected(ok.error());
    const std::optional<std::string> reason = clean_text(audit.reason, kReasonMost);
    const std::optional<std::string> actor = clean_text(audit.actor, kActorMost);
    if (!reason || !actor) return std::unexpected(Error::kReasonRequired);
    const auto found = payments_.find({std::string{key.provider}, std::string{key.trade_no}});
    if (found == payments_.end()) return std::unexpected(Error::kNotFound);
    PaymentRecord record = found->second;
    const Result<PaymentAct> act = payment_step(record.event.status, PaymentStatus::kRefunded);
    if (!act) return std::unexpected(act.error());
    PaymentOutcome outcome;
    if (*act == PaymentAct::kDuplicate) {
        outcome.result = PaymentResult::kDuplicate;
        outcome.record = record;
        outcome.balance = cache_of(record.event.account);
        return outcome;
    }
    const Result<void> posted = post(record.event.account, Points{-record.event.points.value()}, LedgerKind::kRefund,
        record.id.value(), *reason, *actor, now);
    if (!posted) return std::unexpected(posted.error());
    record.event.status = PaymentStatus::kRefunded;
    record.updated = now;
    found->second = record;
    outcome.record = record;
    outcome.balance = cache_of(record.event.account);
    return outcome;
}

Result<PaymentRecord> MemoryBook::find_payment(const PaymentKey& key) {
    if (const Result<void> ok = check_payment_key(key.provider, key.trade_no); !ok) return std::unexpected(ok.error());
    const auto found = payments_.find({std::string{key.provider}, std::string{key.trade_no}});
    if (found == payments_.end()) return std::unexpected(Error::kNotFound);
    return found->second;
}

Result<ExchangeOutcome> MemoryBook::exchange_begin(const ExchangeRequest& request, UnixTime now) {
    if (const Result<void> ok = check_exchange_request(request); !ok) return std::unexpected(ok.error());
    const auto key = std::pair{request.account, request.request};
    if (const auto known = exchange_keys_.find(key); known != exchange_keys_.end()) {
        const ExchangeOrder& order = exchanges_.at(known->second);
        if (order.character != request.character || order.ingot != request.ingot) {
            return std::unexpected(Error::kConflict);
        }
        return ExchangeOutcome{.order = order, .replayed = true, .balance = cache_of(request.account)};
    }
    const Result<Points> cost = exchange_begin_step(request.ingot, config_.ingot_per_point, cache_of(request.account),
        frozen_of(request.account), config_.limits);
    if (!cost) return std::unexpected(cost.error());
    const ExchangeId id{next_exchange_};
    const Result<void> posted = post(request.account, Points{-cost->value()}, LedgerKind::kExchangeHold, id.value(),
        "giữ điểm đổi ingot", kSystem, now);
    if (!posted) return std::unexpected(posted.error());
    ++next_exchange_;
    const ExchangeOrder order{.id = id,
        .account = request.account,
        .character = request.character,
        .request = request.request,
        .ingot = request.ingot,
        .points = *cost,
        .status = ExchangeStatus::kPending,
        .created = now,
        .updated = now};
    exchanges_.emplace(id, order);
    exchange_keys_.emplace(key, id);
    return ExchangeOutcome{.order = order, .replayed = false, .balance = cache_of(request.account)};
}

Result<ExchangeOutcome> MemoryBook::exchange_finish(ExchangeId order, Verdict verdict, UnixTime now) {
    if (!id_ok(order.value())) return std::unexpected(Error::kMalformed);
    const auto found = exchanges_.find(order);
    if (found == exchanges_.end()) return std::unexpected(Error::kNotFound);
    ExchangeOrder& row = found->second;
    const Result<FinishAct> act = exchange_finish_step(row.status, verdict);
    if (!act) return std::unexpected(act.error());
    if (*act == FinishAct::kDuplicate) {
        return ExchangeOutcome{.order = row, .replayed = true, .balance = cache_of(row.account)};
    }
    if (*act == FinishAct::kCancel) {
        const Result<void> posted = post(row.account, row.points, LedgerKind::kExchangeRelease, row.id.value(),
            "huỷ đơn đổi ingot", kSystem, now);
        if (!posted) return std::unexpected(posted.error());
    }
    row.status = *act == FinishAct::kConfirm ? ExchangeStatus::kConfirmed : ExchangeStatus::kCancelled;
    row.updated = now;
    return ExchangeOutcome{.order = row, .replayed = false, .balance = cache_of(row.account)};
}

Result<ExchangeOrder> MemoryBook::find_exchange(ExchangeId order) {
    if (!id_ok(order.value())) return std::unexpected(Error::kMalformed);
    const auto found = exchanges_.find(order);
    if (found == exchanges_.end()) return std::unexpected(Error::kNotFound);
    return found->second;
}

Result<std::vector<ExchangeOrder>> MemoryBook::exchange_open(std::size_t limit) {
    std::vector<ExchangeOrder> open;
    for (const auto& [id, order] : exchanges_) {
        if (is_open(order.status)) open.push_back(order);
    }
    std::ranges::sort(open, [](const ExchangeOrder& left, const ExchangeOrder& right) {
        if (left.created != right.created) return left.created < right.created;
        return left.id < right.id;
    });
    open.resize(std::min(open.size(), clamp_limit(limit, kListMost)));
    return open;
}

Result<std::int64_t> MemoryBook::exchange_sweep(UnixTime now) {
    std::int64_t changed = 0;
    for (auto& [id, order] : exchanges_) {
        if (order.status != ExchangeStatus::kPending) continue;
        if (!exchange_overdue(order.created, now, config_.pending_timeout_seconds)) continue;
        order.status = ExchangeStatus::kStale;
        order.updated = now;
        ++changed;
    }
    return changed;
}

Result<BatchRecord> MemoryBook::create_batch(const BatchSpec& spec, UnixTime now) {
    BatchSpec clean = spec;
    if (const Result<void> ok = check_batch_spec(clean, config_.limits); !ok) return std::unexpected(ok.error());
    if (batch_names_.contains(clean.name)) return std::unexpected(Error::kConflict);
    const BatchId id{next_batch_++};
    BatchRecord record{.id = id, .spec = clean, .enabled = true, .code_count = 0, .created = now};
    batch_names_.insert(clean.name);
    batches_.emplace(id, BatchRow{record});
    return record;
}

Result<void> MemoryBook::set_batch_enabled(BatchId batch, bool enabled, std::string_view actor, UnixTime) {
    if (!id_ok(batch.value())) return std::unexpected(Error::kMalformed);
    if (!clean_text(actor, kActorMost)) return std::unexpected(Error::kReasonRequired);
    const auto found = batches_.find(batch);
    if (found == batches_.end()) return std::unexpected(Error::kNotFound);
    found->second.record.enabled = enabled;
    return {};
}

Result<std::int64_t> MemoryBook::add_codes(BatchId batch, std::span<const std::string> hashes, UnixTime) {
    if (!id_ok(batch.value())) return std::unexpected(Error::kMalformed);
    if (const Result<void> ok = check_code_hashes(hashes); !ok) return std::unexpected(ok.error());
    const auto found = batches_.find(batch);
    if (found == batches_.end()) return std::unexpected(Error::kNotFound);
    BatchRecord& record = found->second.record;
    const auto added = static_cast<std::int64_t>(hashes.size());
    if (record.code_count + added > config_.limits.max_codes_per_batch) return std::unexpected(Error::kTooMany);
    std::set<std::string> fresh;
    for (const std::string& hash : hashes) {
        if (codes_.contains(hash) || !fresh.insert(hash).second) return std::unexpected(Error::kConflict);
    }
    for (const std::string& hash : hashes) {
        codes_.emplace(hash, CodeRow{.id = CodeId{next_code_++}, .batch = batch, .used_by = std::nullopt});
    }
    record.code_count += added;
    return added;
}

Result<RedeemOutcome> MemoryBook::redeem(AccountId account, std::string_view code_hash, std::string_view ip,
    UnixTime now) {
    if (!id_ok(account.value()) || !hash_hex_ok(code_hash) || !parse_ipv4(ip)) {
        return std::unexpected(Error::kMalformed);
    }
    if (frozen_of(account)) return std::unexpected(Error::kFrozen);
    const auto code = codes_.find(std::string{code_hash});
    if (code == codes_.end()) return std::unexpected(Error::kBadCode);
    const BatchRecord& batch = batches_.at(code->second.batch).record;
    std::int64_t used_in_batch = 0;
    for (const auto& [hash, row] : codes_) {
        if (row.batch == batch.id && row.used_by == account) ++used_in_batch;
    }
    const CodeFacts facts{.frozen = false,
        .batch_enabled = batch.enabled,
        .starts = batch.spec.starts,
        .ends = batch.spec.ends,
        .used = code->second.used_by.has_value(),
        .used_in_batch = used_in_batch,
        .per_account_limit = batch.spec.per_account_limit,
        .now = now};
    if (const Result<void> ok = redeem_step(facts); !ok) return std::unexpected(ok.error());
    std::int64_t point_sum = 0;
    for (const Reward& reward : batch.spec.rewards) {
        if (reward.kind != 0) continue;
        const std::optional<std::int64_t> next = add_checked(point_sum, reward.quantity);
        if (!next) return std::unexpected(Error::kBadAmount);
        point_sum = *next;
    }
    if (point_sum > 0) {
        const Result<Points> next = credit_step(Points{point_sum}, cache_of(account), config_.limits);
        if (!next) return std::unexpected(next.error());
        const Result<void> posted = post(account, Points{point_sum}, LedgerKind::kRedeem, code->second.id.value(),
            "mã đổi", kSystem, now);
        if (!posted) return std::unexpected(posted.error());
    }
    RedeemOutcome outcome;
    outcome.batch = batch.id;
    outcome.points = Points{point_sum};
    for (const Reward& reward : batch.spec.rewards) {
        if (reward.kind == 0) continue;
        const GrantRecord grant{.id = GrantId{next_grant_++},
            .account = account,
            .kind = static_cast<GrantKind>(reward.kind),
            .ref_id = reward.ref_id,
            .quantity = reward.quantity,
            .status = GrantStatus::kPending,
            .source = "redeem",
            .created = now};
        grants_.emplace(grant.id, GrantRow{.record = grant, .open_order = std::nullopt});
        outcome.grants.push_back(grant);
    }
    code->second.used_by = account;
    outcome.balance = cache_of(account);
    return outcome;
}

Result<GrantRecord> MemoryBook::grant_add(const GrantSpec& spec, UnixTime now) {
    GrantSpec clean = spec;
    if (const Result<void> ok = check_grant_spec(clean, config_.limits); !ok) return std::unexpected(ok.error());
    GrantRecord grant{.id = GrantId{next_grant_++},
        .account = clean.account,
        .kind = clean.kind,
        .ref_id = clean.ref_id,
        .quantity = clean.quantity,
        .status = GrantStatus::kPending,
        .source = clean.source,
        .created = now};
    grants_.emplace(grant.id, GrantRow{.record = grant, .open_order = std::nullopt});
    return grant;
}

Result<std::vector<GrantRecord>> MemoryBook::grant_list(AccountId account, std::size_t limit) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    std::vector<GrantRecord> out;
    const std::size_t most = clamp_limit(limit, kListMost);
    for (const auto& [id, row] : grants_) {
        if (out.size() >= most) break;
        if (row.record.account == account && row.record.status == GrantStatus::kPending) out.push_back(row.record);
    }
    return out;
}

Result<GrantClaimed> MemoryBook::grant_claim(GrantId grant, AccountId account, CharacterId character, UnixTime now) {
    if (!id_ok(grant.value()) || !id_ok(account.value()) || !id_ok(character.value())) {
        return std::unexpected(Error::kMalformed);
    }
    const auto found = grants_.find(grant);
    if (found == grants_.end() || found->second.record.account != account) return std::unexpected(Error::kNotFound);
    GrantRow& row = found->second;
    if (frozen_of(account)) return std::unexpected(Error::kFrozen);
    if (row.record.status == GrantStatus::kDelivering && row.open_order) {
        const GrantOrder& open = grant_orders_.at(*row.open_order);
        if (open.character != character) return std::unexpected(Error::kBadState);
        return GrantClaimed{.order = open, .grant = row.record, .replayed = true};
    }
    if (row.record.status != GrantStatus::kPending) return std::unexpected(Error::kBadState);
    const GrantOrder order{.id = GrantOrderId{next_grant_order_++},
        .grant = grant,
        .character = character,
        .status = GrantOrderStatus::kPending,
        .created = now,
        .updated = now};
    grant_orders_.emplace(order.id, order);
    row.open_order = order.id;
    row.record.status = GrantStatus::kDelivering;
    return GrantClaimed{.order = order, .grant = row.record, .replayed = false};
}

Result<GrantFinished> MemoryBook::grant_finish(GrantOrderId order, Verdict verdict, UnixTime now) {
    if (!id_ok(order.value())) return std::unexpected(Error::kMalformed);
    const auto found = grant_orders_.find(order);
    if (found == grant_orders_.end()) return std::unexpected(Error::kNotFound);
    GrantOrder& row = found->second;
    GrantRow& grant = grants_.at(row.grant);
    const Result<FinishAct> act = grant_finish_step(row.status, verdict);
    if (!act) return std::unexpected(act.error());
    if (*act == FinishAct::kDuplicate) return GrantFinished{.order = row, .grant = grant.record, .replayed = true};
    row.updated = now;
    grant.open_order.reset();
    if (*act == FinishAct::kConfirm) {
        row.status = GrantOrderStatus::kDone;
        grant.record.status = GrantStatus::kDelivered;
    } else {
        row.status = GrantOrderStatus::kCancelled;
        grant.record.status = GrantStatus::kPending;
    }
    return GrantFinished{.order = row, .grant = grant.record, .replayed = false};
}

Result<std::vector<GrantOrder>> MemoryBook::grant_open(std::size_t limit) {
    std::vector<GrantOrder> open;
    for (const auto& [id, order] : grant_orders_) {
        if (order.status == GrantOrderStatus::kPending) open.push_back(order);
    }
    std::ranges::sort(open, [](const GrantOrder& left, const GrantOrder& right) {
        if (left.created != right.created) return left.created < right.created;
        return left.id < right.id;
    });
    open.resize(std::min(open.size(), clamp_limit(limit, kListMost)));
    return open;
}

Result<Points> MemoryBook::admin_adjust(AccountId account, Points delta, RequestId request, const Audit& audit,
    UnixTime now) {
    if (!id_ok(account.value()) || !id_ok(request.value())) return std::unexpected(Error::kMalformed);
    if (ledger_keys_.contains({LedgerKind::kAdmin, request.value()})) {
        for (const LedgerEntry& entry : ledger_) {
            if (entry.kind != LedgerKind::kAdmin || entry.ref != request.value()) continue;
            if (entry.account != account || entry.delta != delta) return std::unexpected(Error::kConflict);
            return cache_of(account);
        }
    }
    const std::optional<std::string> reason = clean_text(audit.reason, kReasonMost);
    const std::optional<std::string> actor = clean_text(audit.actor, kActorMost);
    if (!reason || !actor) return std::unexpected(Error::kReasonRequired);
    const Result<Points> next = admin_step(delta, *reason, *actor, cache_of(account), config_.limits);
    if (!next) return std::unexpected(next.error());
    const Result<void> posted = post(account, delta, LedgerKind::kAdmin, request.value(), *reason, *actor, now);
    if (!posted) return std::unexpected(posted.error());
    return cache_of(account);
}

Result<std::vector<LedgerEntry>> MemoryBook::ledger_tail(AccountId account, std::size_t limit) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    std::vector<LedgerEntry> out;
    const std::size_t most = clamp_limit(limit, kLedgerTailMost);
    for (auto it = ledger_.rbegin(); it != ledger_.rend() && out.size() < most; ++it) {
        if (it->account == account) out.push_back(*it);
    }
    return out;
}

Result<SpendSummary> MemoryBook::record_spend(std::span<const SpendEvent> events, UnixTime now) {
    if (const Result<void> ok = check_spend_events(events); !ok) return std::unexpected(ok.error());
    const std::optional<std::int64_t> day = day_of(now);
    if (!day) return std::unexpected(Error::kBadAmount);
    std::map<std::uint64_t, SpendEvent> fresh;
    SpendSummary summary;
    for (const SpendEvent& event : events) {
        const SpendEvent* known = nullptr;
        if (const auto stored = spends_.find(event.event); stored != spends_.end()) known = &stored->second.event;
        if (const auto batch = fresh.find(event.event); batch != fresh.end()) known = &batch->second;
        if (known == nullptr) {
            fresh.emplace(event.event, event);
            ++summary.recorded;
            continue;
        }
        const bool same = known->account == event.account && known->character == event.character &&
            known->amount == event.amount;
        if (!same) return std::unexpected(Error::kConflict);
        ++summary.duplicates;
    }
    for (const auto& [id, event] : fresh) {
        spends_.emplace(id, SpendRow{.event = event, .day = *day});
    }
    return summary;
}

Result<Ingot> MemoryBook::spend_headroom(CharacterId character, UnixTime now) {
    if (!id_ok(character.value())) return std::unexpected(Error::kMalformed);
    const std::optional<std::int64_t> day = day_of(now);
    if (!day) return std::unexpected(Error::kBadAmount);
    if (config_.daily_ingot_cap == 0) return Ingot{kNoCapHeadroom};
    return Ingot{std::max<std::int64_t>(config_.daily_ingot_cap - spent_today(character, *day), 0)};
}

Result<Conservation> MemoryBook::ledger_check() {
    Conservation report;
    std::map<AccountId, std::int64_t> sums;
    std::int64_t topped = 0;
    std::int64_t refunded = 0;
    std::int64_t other = 0;
    std::int64_t hold_sum = 0;
    std::int64_t release_sum = 0;
    for (const LedgerEntry& entry : ledger_) {
        sums[entry.account] += entry.delta.value();
        switch (entry.kind) {
        case LedgerKind::kTopUp: topped += entry.delta.value(); break;
        case LedgerKind::kRefund: refunded -= entry.delta.value(); break;
        case LedgerKind::kExchangeHold: hold_sum += entry.delta.value(); break;
        case LedgerKind::kExchangeRelease: release_sum += entry.delta.value(); break;
        case LedgerKind::kRegisterGift:
        case LedgerKind::kRedeem:
        case LedgerKind::kAdmin: other += entry.delta.value(); break;
        }
    }
    std::int64_t balance_sum = 0;
    for (const auto& [account, cached] : cache_) {
        balance_sum += cached.value();
        const auto summed = sums.find(account);
        if ((summed == sums.end() ? 0 : summed->second) != cached.value()) ++report.mismatched_accounts;
    }
    for (const auto& [account, sum] : sums) {
        if (!cache_.contains(account) && sum != 0) ++report.mismatched_accounts;
    }
    std::int64_t confirmed = 0;
    std::int64_t held = 0;
    std::int64_t all_points = 0;
    std::int64_t cancelled_points = 0;
    for (const auto& [id, order] : exchanges_) {
        all_points += order.points.value();
        if (order.status == ExchangeStatus::kConfirmed) confirmed += order.points.value();
        if (is_open(order.status)) held += order.points.value();
        if (order.status == ExchangeStatus::kCancelled) cancelled_points += order.points.value();
    }
    report.topped_up = Points{topped};
    report.refunded = Points{refunded};
    report.other_net = Points{other};
    report.balance_sum = Points{balance_sum};
    report.exchange_confirmed = Points{confirmed};
    report.exchange_held = Points{held};
    const bool identity = topped + other == balance_sum + confirmed + held + refunded;
    const bool exchange_rows = hold_sum == -all_points && release_sum == cancelled_points;
    report.balanced = identity && exchange_rows && report.mismatched_accounts == 0;
    return report;
}

Result<Points> MemoryBook::rebuild_balance(AccountId account, std::string_view actor, UnixTime) {
    if (!id_ok(account.value())) return std::unexpected(Error::kMalformed);
    if (!clean_text(actor, kActorMost)) return std::unexpected(Error::kReasonRequired);
    std::int64_t sum = 0;
    for (const LedgerEntry& entry : ledger_) {
        if (entry.account == account) sum += entry.delta.value();
    }
    cache_[account] = Points{sum};
    return Points{sum};
}

Result<DayReport> MemoryBook::day_report(std::int64_t day) {
    if (day < 0 || day > std::numeric_limits<std::int64_t>::max() / kSecondsPerDay) {
        return std::unexpected(Error::kBadAmount);
    }
    DayReport report;
    report.day = day;
    for (const LedgerEntry& entry : ledger_) {
        if (!in_day(entry.at, day)) continue;
        if (entry.kind == LedgerKind::kTopUp) report.topped_up = Points{report.topped_up.value() + entry.delta.value()};
        if (entry.kind == LedgerKind::kRefund) report.refunded = Points{report.refunded.value() - entry.delta.value()};
    }
    std::int64_t issued = 0;
    for (const auto& [id, order] : exchanges_) {
        if (order.status == ExchangeStatus::kConfirmed && in_day(order.updated, day)) {
            report.exchanged = Points{report.exchanged.value() + order.points.value()};
            issued += order.ingot.value();
        }
        if (is_open(order.status)) ++report.open_exchanges;
    }
    for (const auto& [id, order] : grant_orders_) {
        if (order.status != GrantOrderStatus::kDone || !in_day(order.updated, day)) continue;
        const GrantRecord& grant = grants_.at(order.grant).record;
        if (grant.kind == GrantKind::kIngot) issued += grant.quantity;
    }
    report.ingot_issued = Ingot{issued};
    std::int64_t spent = 0;
    for (const auto& [id, row] : spends_) {
        if (row.day != day) continue;
        spent += row.event.amount.value();
        ++report.spend_events;
    }
    report.ingot_spent = Ingot{spent};
    const Result<Conservation> check = ledger_check();
    if (!check) return std::unexpected(check.error());
    report.conservation = *check;
    return report;
}

} // namespace game::billing
