#include "billing/rpc.hpp"

#include "billing/book.hpp"
#include "billing/checks.hpp"
#include "billing/code.hpp"
#include "billing/error.hpp"
#include "billing/rules.hpp"
#include "billing/throttle.hpp"
#include "billing/types.hpp"
#include "billing/wire.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

using wire::Reader;
using wire::Writer;

constexpr std::size_t kIpBytes = 15;
constexpr std::size_t kCodeTypedBytes = 64;
// Kích thước nhỏ nhất của một phần tử khi kiểm số phần tử khai trước.
constexpr std::size_t kSpendWire = 8 + 8 + 8 + 8;
constexpr std::size_t kRewardWire = 1 + 8 + 8;

[[nodiscard]] Reply done_reply(Writer& out) {
    return Reply{.code = 0, .body = out.take()};
}

[[nodiscard]] Reply empty_reply() {
    return Reply{};
}

template <typename Value, typename Put>
[[nodiscard]] Reply reply_with(const Result<Value>& result, Put put) {
    if (!result) return error_reply(result.error());
    Writer out;
    put(out, *result);
    return done_reply(out);
}

[[nodiscard]] Reply reply_unit(const Result<void>& result) {
    if (!result) return error_reply(result.error());
    return empty_reply();
}

// ---- xử lý từng Op --------------------------------------------------------------------------------

[[nodiscard]] Reply on_balance(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->balance(account), [](Writer& out, const Balance& v) { wire::write(out, v); });
}

[[nodiscard]] Reply on_ensure(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->ensure_account(account, cx.now), [](Writer& out, const Balance& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_set_frozen(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    const bool frozen = in.flag();
    const std::string reason = in.text(kReasonMost);
    const std::string actor = in.text(kActorMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_unit(cx.book->set_frozen(account, frozen, {.reason = reason, .actor = actor}, cx.now));
}

[[nodiscard]] Reply on_quote(const Dispatch& cx, Reader& in) {
    const Ingot ingot{in.i64()};
    if (!in.done()) return error_reply(Error::kMalformed);
    const Result<Points> cost = exchange_cost(ingot, cx.config->ingot_per_point, cx.config->limits);
    return reply_with(cost, [&](Writer& out, const Points& v) {
        out.i64(v.value());
        out.i64(cx.config->ingot_per_point);
        out.i64(cx.config->limits.min_ingot_per_order);
        out.i64(cx.config->limits.max_ingot_per_order);
    });
}

[[nodiscard]] Reply on_exchange_begin(const Dispatch& cx, Reader& in) {
    ExchangeRequest request;
    request.account = AccountId{in.u64()};
    request.character = CharacterId{in.u64()};
    request.request = RequestId{in.u64()};
    request.ingot = Ingot{in.i64()};
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->exchange_begin(request, cx.now), [](Writer& out, const ExchangeOutcome& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] std::optional<Verdict> read_verdict(Reader& in) {
    const std::uint8_t raw = in.u8();
    if (raw != static_cast<std::uint8_t>(Verdict::kDone) && raw != static_cast<std::uint8_t>(Verdict::kCancelled)) {
        in.fail();
        return std::nullopt;
    }
    return static_cast<Verdict>(raw);
}

[[nodiscard]] Reply on_exchange_finish(const Dispatch& cx, Reader& in) {
    const ExchangeId order{in.u64()};
    const std::optional<Verdict> verdict = read_verdict(in);
    if (!in.done() || !verdict) return error_reply(Error::kMalformed);
    return reply_with(cx.book->exchange_finish(order, *verdict, cx.now), [](Writer& out, const ExchangeOutcome& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_exchange_open(const Dispatch& cx, Reader& in) {
    const std::uint16_t limit = in.u16();
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->exchange_open(limit), [](Writer& out, const std::vector<ExchangeOrder>& v) {
        out.u16(static_cast<std::uint16_t>(v.size()));
        for (const ExchangeOrder& order : v)
            wire::write(out, order);
    });
}

[[nodiscard]] Reply on_find_exchange(const Dispatch& cx, Reader& in) {
    const ExchangeId order{in.u64()};
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->find_exchange(order), [](Writer& out, const ExchangeOrder& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_exchange_sweep(const Dispatch& cx, Reader& in) {
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->exchange_sweep(cx.now), [](Writer& out, std::int64_t v) { out.i64(v); });
}

[[nodiscard]] Reply on_redeem(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    const std::string ip = in.text(kIpBytes);
    const std::string typed = in.text(kCodeTypedBytes);
    if (!in.done()) return error_reply(Error::kMalformed);
    const std::optional<std::uint32_t> packed = parse_ipv4(ip);
    if (!packed || !id_ok(account.value())) return error_reply(Error::kMalformed);
    // Bộ đếm chặn trước mọi việc khác: kể cả mã sai hình dạng cũng tốn một lượt, nên không có cách đoán
    // mã miễn phí.
    if (!cx.throttle->take(account.value(), *packed, cx.tick)) return error_reply(Error::kRateLimited);
    const std::optional<std::string> normalized = normalize_code(typed);
    if (!normalized) return error_reply(Error::kBadCode);
    const std::string hash = hash_code(*normalized);
    if (hash.empty()) return error_reply(Error::kBusy);
    return reply_with(cx.book->redeem(account, hash, ip, cx.now), [](Writer& out, const RedeemOutcome& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_grant_list(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    const std::uint16_t limit = in.u16();
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->grant_list(account, limit), [](Writer& out, const std::vector<GrantRecord>& v) {
        out.u16(static_cast<std::uint16_t>(v.size()));
        for (const GrantRecord& grant : v)
            wire::write(out, grant);
    });
}

[[nodiscard]] Reply on_grant_claim(const Dispatch& cx, Reader& in) {
    const GrantId grant{in.u64()};
    const AccountId account{in.u64()};
    const CharacterId character{in.u64()};
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->grant_claim(grant, account, character, cx.now), [](Writer& out, const GrantClaimed& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_grant_finish(const Dispatch& cx, Reader& in) {
    const GrantOrderId order{in.u64()};
    const std::optional<Verdict> verdict = read_verdict(in);
    if (!in.done() || !verdict) return error_reply(Error::kMalformed);
    return reply_with(cx.book->grant_finish(order, *verdict, cx.now), [](Writer& out, const GrantFinished& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_grant_open(const Dispatch& cx, Reader& in) {
    const std::uint16_t limit = in.u16();
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->grant_open(limit), [](Writer& out, const std::vector<GrantOrder>& v) {
        out.u16(static_cast<std::uint16_t>(v.size()));
        for (const GrantOrder& order : v)
            wire::write(out, order);
    });
}

[[nodiscard]] Reply on_grant_add(const Dispatch& cx, Reader& in) {
    GrantSpec spec;
    spec.account = AccountId{in.u64()};
    const std::uint8_t kind = in.u8();
    spec.ref_id = in.u64();
    spec.quantity = in.i64();
    spec.source = in.text(kSourceMost);
    spec.reason = in.text(kReasonMost);
    spec.actor = in.text(kActorMost);
    if (!in.done() || !grant_kind_ok(kind)) return error_reply(Error::kMalformed);
    spec.kind = static_cast<GrantKind>(kind);
    return reply_with(cx.book->grant_add(spec, cx.now), [](Writer& out, const GrantRecord& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_admin_adjust(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    const Points delta{in.i64()};
    const RequestId request{in.u64()};
    const std::string reason = in.text(kReasonMost);
    const std::string actor = in.text(kActorMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->admin_adjust(account, delta, request, {.reason = reason, .actor = actor}, cx.now),
        [](Writer& out, const Points& v) { out.i64(v.value()); });
}

[[nodiscard]] Reply on_refund(const Dispatch& cx, Reader& in) {
    const std::string provider = in.text(kProviderMost);
    const std::string trade_no = in.text(kTradeNoMost);
    const std::string reason = in.text(kReasonMost);
    const std::string actor = in.text(kActorMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->refund_payment({.provider = provider, .trade_no = trade_no}, {.reason = reason, .actor = actor}, cx.now),
        [](Writer& out, const PaymentOutcome& v) { wire::write(out, v); });
}

[[nodiscard]] Reply on_find_payment(const Dispatch& cx, Reader& in) {
    const std::string provider = in.text(kProviderMost);
    const std::string trade_no = in.text(kTradeNoMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->find_payment({.provider = provider, .trade_no = trade_no}), [](Writer& out, const PaymentRecord& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_create_batch(const Dispatch& cx, Reader& in) {
    BatchSpec spec;
    spec.name = in.text(kBatchNameMost);
    spec.starts = wire::read_optional_time(in);
    spec.ends = wire::read_optional_time(in);
    spec.per_account_limit = in.i64();
    const std::size_t count = in.count(kRewardsMost, kRewardWire);
    for (std::size_t index = 0; index < count && in.ok(); ++index) {
        Reward reward;
        reward.kind = in.u8();
        reward.ref_id = in.u64();
        reward.quantity = in.i64();
        spec.rewards.push_back(reward);
    }
    spec.actor = in.text(kActorMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->create_batch(spec, cx.now), [](Writer& out, const BatchRecord& v) {
        wire::write(out, v);
    });
}

[[nodiscard]] Reply on_set_batch_enabled(const Dispatch& cx, Reader& in) {
    const BatchId batch{in.u64()};
    const bool enabled = in.flag();
    const std::string actor = in.text(kActorMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_unit(cx.book->set_batch_enabled(batch, enabled, actor, cx.now));
}

// Sinh `count` mã mới và thêm vào đợt. Hai mã trùng băm xác suất ~2^-79 mỗi cặp; vẫn xử lý bằng cách sinh
// lại tối đa vài lần thay vì giả định.
[[nodiscard]] Reply on_mint(const Dispatch& cx, Reader& in) {
    const BatchId batch{in.u64()};
    const std::uint16_t count = in.u16();
    const std::string actor = in.text(kActorMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    if (!clean_text(actor, kActorMost)) return error_reply(Error::kReasonRequired);
    if (count < 1 || count > kMintPerCallMost) return error_reply(Error::kTooMany);
    constexpr int kAttempts = 3;
    for (int attempt = 0; attempt < kAttempts; ++attempt) {
        std::vector<std::string> normalized;
        std::vector<std::string> hashes;
        for (std::uint16_t index = 0; index < count; ++index) {
            std::optional<std::string> code = mint_code(cx.random);
            if (!code) return error_reply(Error::kBusy);
            hashes.push_back(hash_code(*code));
            normalized.push_back(std::move(*code));
        }
        const Result<std::int64_t> added = cx.book->add_codes(batch, hashes, cx.now);
        if (!added && added.error() == Error::kConflict) continue;
        if (!added) return error_reply(added.error());
        Writer out;
        out.u16(count);
        for (const std::string& code : normalized)
            out.text(format_code(code));
        return done_reply(out);
    }
    return error_reply(Error::kBusy);
}

[[nodiscard]] Reply on_spend_record(const Dispatch& cx, Reader& in) {
    const std::size_t count = in.count(kSpendBatchMost, kSpendWire);
    std::vector<SpendEvent> events;
    for (std::size_t index = 0; index < count && in.ok(); ++index) {
        SpendEvent event;
        event.event = in.u64();
        event.account = AccountId{in.u64()};
        event.character = CharacterId{in.u64()};
        event.amount = Ingot{in.i64()};
        events.push_back(event);
    }
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->record_spend(events, cx.now), [](Writer& out, const SpendSummary& v) {
        out.i64(v.recorded);
        out.i64(v.duplicates);
    });
}

[[nodiscard]] Reply on_headroom(const Dispatch& cx, Reader& in) {
    const CharacterId character{in.u64()};
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->spend_headroom(character, cx.now), [](Writer& out, const Ingot& v) {
        out.i64(v.value());
    });
}

[[nodiscard]] Reply on_ledger_check(const Dispatch& cx, Reader& in) {
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->ledger_check(), [](Writer& out, const Conservation& v) { wire::write(out, v); });
}

[[nodiscard]] Reply on_rebuild(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    const std::string actor = in.text(kActorMost);
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->rebuild_balance(account, actor, cx.now), [](Writer& out, const Points& v) {
        out.i64(v.value());
    });
}

[[nodiscard]] Reply on_day_report(const Dispatch& cx, Reader& in) {
    const std::int64_t day = in.i64();
    if (!in.done()) return error_reply(Error::kMalformed);
    return reply_with(cx.book->day_report(day), [](Writer& out, const DayReport& v) { wire::write(out, v); });
}

[[nodiscard]] Reply on_ledger_tail(const Dispatch& cx, Reader& in) {
    const AccountId account{in.u64()};
    const std::uint16_t limit = in.u16();
    if (!in.done()) return error_reply(Error::kMalformed);
    const std::size_t wanted = std::min<std::size_t>(limit, kLedgerTailWireMost);
    return reply_with(cx.book->ledger_tail(account, wanted), [](Writer& out, const std::vector<LedgerEntry>& v) {
        out.u16(static_cast<std::uint16_t>(v.size()));
        for (const LedgerEntry& entry : v)
            wire::write(out, entry);
    });
}

// ---- phía bộ gọi ----------------------------------------------------------------------------------

[[nodiscard]] Request make(Op op, Writer& out) {
    return Request{.op = op, .body = out.take()};
}

template <typename Value, typename Get>
[[nodiscard]] Result<Value> parse_reply(const Reply& reply, Get get) {
    if (reply.code != 0) return std::unexpected(error_of(reply.code));
    Reader in{reply.body};
    Value value = get(in);
    if (!in.done()) return std::unexpected(Error::kBusy);
    return value;
}

} // namespace

Reply error_reply(Error error) {
    return Reply{.code = wire_code(error), .body = {}};
}

Reply handle(const Dispatch& cx, const Request& request) {
    Reader in{request.body};
    switch (request.op) {
    case Op::kBalance: return on_balance(cx, in);
    case Op::kEnsureAccount: return on_ensure(cx, in);
    case Op::kSetFrozen: return on_set_frozen(cx, in);
    case Op::kQuote: return on_quote(cx, in);
    case Op::kExchangeBegin: return on_exchange_begin(cx, in);
    case Op::kExchangeFinish: return on_exchange_finish(cx, in);
    case Op::kExchangeOpen: return on_exchange_open(cx, in);
    case Op::kFindExchange: return on_find_exchange(cx, in);
    case Op::kExchangeSweep: return on_exchange_sweep(cx, in);
    case Op::kRedeem: return on_redeem(cx, in);
    case Op::kGrantList: return on_grant_list(cx, in);
    case Op::kGrantClaim: return on_grant_claim(cx, in);
    case Op::kGrantFinish: return on_grant_finish(cx, in);
    case Op::kGrantOpen: return on_grant_open(cx, in);
    case Op::kGrantAdd: return on_grant_add(cx, in);
    case Op::kAdminAdjust: return on_admin_adjust(cx, in);
    case Op::kRefundPayment: return on_refund(cx, in);
    case Op::kFindPayment: return on_find_payment(cx, in);
    case Op::kCreateBatch: return on_create_batch(cx, in);
    case Op::kSetBatchEnabled: return on_set_batch_enabled(cx, in);
    case Op::kMintCodes: return on_mint(cx, in);
    case Op::kSpendRecord: return on_spend_record(cx, in);
    case Op::kSpendHeadroom: return on_headroom(cx, in);
    case Op::kLedgerCheck: return on_ledger_check(cx, in);
    case Op::kRebuildBalance: return on_rebuild(cx, in);
    case Op::kDayReport: return on_day_report(cx, in);
    case Op::kLedgerTail: return on_ledger_tail(cx, in);
    }
    return error_reply(Error::kMalformed);
}

namespace rpc {

Request balance(AccountId account) {
    Writer out;
    out.u64(account.value());
    return make(Op::kBalance, out);
}

Request ensure_account(AccountId account) {
    Writer out;
    out.u64(account.value());
    return make(Op::kEnsureAccount, out);
}

Request set_frozen(AccountId account, bool frozen, const Audit& audit) {
    Writer out;
    out.u64(account.value());
    out.flag(frozen);
    out.text(audit.reason);
    out.text(audit.actor);
    return make(Op::kSetFrozen, out);
}

Request quote(Ingot ingot) {
    Writer out;
    out.i64(ingot.value());
    return make(Op::kQuote, out);
}

Request exchange_begin(const ExchangeRequest& request) {
    Writer out;
    out.u64(request.account.value());
    out.u64(request.character.value());
    out.u64(request.request.value());
    out.i64(request.ingot.value());
    return make(Op::kExchangeBegin, out);
}

Request exchange_finish(ExchangeId order, Verdict verdict) {
    Writer out;
    out.u64(order.value());
    out.u8(static_cast<std::uint8_t>(verdict));
    return make(Op::kExchangeFinish, out);
}

Request exchange_open(std::uint16_t limit) {
    Writer out;
    out.u16(limit);
    return make(Op::kExchangeOpen, out);
}

Request find_exchange(ExchangeId order) {
    Writer out;
    out.u64(order.value());
    return make(Op::kFindExchange, out);
}

Request exchange_sweep() {
    Writer out;
    return make(Op::kExchangeSweep, out);
}

Request redeem(AccountId account, const TypedCode& typed) {
    Writer out;
    out.u64(account.value());
    out.text(typed.ip);
    out.text(typed.code);
    return make(Op::kRedeem, out);
}

Request grant_list(AccountId account, std::uint16_t limit) {
    Writer out;
    out.u64(account.value());
    out.u16(limit);
    return make(Op::kGrantList, out);
}

Request grant_claim(GrantId grant, AccountId account, CharacterId character) {
    Writer out;
    out.u64(grant.value());
    out.u64(account.value());
    out.u64(character.value());
    return make(Op::kGrantClaim, out);
}

Request grant_finish(GrantOrderId order, Verdict verdict) {
    Writer out;
    out.u64(order.value());
    out.u8(static_cast<std::uint8_t>(verdict));
    return make(Op::kGrantFinish, out);
}

Request grant_open(std::uint16_t limit) {
    Writer out;
    out.u16(limit);
    return make(Op::kGrantOpen, out);
}

Request grant_add(const GrantSpec& spec) {
    Writer out;
    out.u64(spec.account.value());
    out.u8(static_cast<std::uint8_t>(spec.kind));
    out.u64(spec.ref_id);
    out.i64(spec.quantity);
    out.text(spec.source);
    out.text(spec.reason);
    out.text(spec.actor);
    return make(Op::kGrantAdd, out);
}

Request admin_adjust(AccountId account, Points delta, RequestId request, const Audit& audit) {
    Writer out;
    out.u64(account.value());
    out.i64(delta.value());
    out.u64(request.value());
    out.text(audit.reason);
    out.text(audit.actor);
    return make(Op::kAdminAdjust, out);
}

Request refund_payment(const PaymentKey& key, const Audit& audit) {
    Writer out;
    out.text(key.provider);
    out.text(key.trade_no);
    out.text(audit.reason);
    out.text(audit.actor);
    return make(Op::kRefundPayment, out);
}

Request find_payment(const PaymentKey& key) {
    Writer out;
    out.text(key.provider);
    out.text(key.trade_no);
    return make(Op::kFindPayment, out);
}

Request create_batch(const BatchSpec& spec) {
    Writer out;
    out.text(spec.name);
    wire::write_optional_time(out, spec.starts);
    wire::write_optional_time(out, spec.ends);
    out.i64(spec.per_account_limit);
    const std::size_t count = std::min<std::size_t>(spec.rewards.size(), kRewardsMost);
    out.u16(static_cast<std::uint16_t>(count));
    for (std::size_t index = 0; index < count; ++index) {
        out.u8(spec.rewards[index].kind);
        out.u64(spec.rewards[index].ref_id);
        out.i64(spec.rewards[index].quantity);
    }
    out.text(spec.actor);
    return make(Op::kCreateBatch, out);
}

Request set_batch_enabled(BatchId batch, bool enabled, std::string_view actor) {
    Writer out;
    out.u64(batch.value());
    out.flag(enabled);
    out.text(actor);
    return make(Op::kSetBatchEnabled, out);
}

Request mint_codes(BatchId batch, std::uint16_t count, std::string_view actor) {
    Writer out;
    out.u64(batch.value());
    out.u16(count);
    out.text(actor);
    return make(Op::kMintCodes, out);
}

Request spend_record(std::span<const SpendEvent> events) {
    Writer out;
    const std::size_t count = std::min<std::size_t>(events.size(), kSpendBatchMost);
    out.u16(static_cast<std::uint16_t>(count));
    for (std::size_t index = 0; index < count; ++index) {
        out.u64(events[index].event);
        out.u64(events[index].account.value());
        out.u64(events[index].character.value());
        out.i64(events[index].amount.value());
    }
    return make(Op::kSpendRecord, out);
}

Request spend_headroom(CharacterId character) {
    Writer out;
    out.u64(character.value());
    return make(Op::kSpendHeadroom, out);
}

Request ledger_check() {
    Writer out;
    return make(Op::kLedgerCheck, out);
}

Request rebuild_balance(AccountId account, std::string_view actor) {
    Writer out;
    out.u64(account.value());
    out.text(actor);
    return make(Op::kRebuildBalance, out);
}

Request day_report(std::int64_t day) {
    Writer out;
    out.i64(day);
    return make(Op::kDayReport, out);
}

Request ledger_tail(AccountId account, std::uint16_t limit) {
    Writer out;
    out.u64(account.value());
    out.u16(limit);
    return make(Op::kLedgerTail, out);
}

Result<Balance> read_balance(const Reply& reply) {
    return parse_reply<Balance>(reply, [](Reader& in) { return wire::read_balance(in); });
}

Result<void> read_done(const Reply& reply) {
    if (reply.code != 0) return std::unexpected(error_of(reply.code));
    if (!reply.body.empty()) return std::unexpected(Error::kBusy);
    return {};
}

Result<Quote> read_quote(const Reply& reply) {
    return parse_reply<Quote>(reply, [](Reader& in) {
        Quote value;
        value.cost = Points{in.i64()};
        value.ingot_per_point = in.i64();
        value.min_ingot = in.i64();
        value.max_ingot = in.i64();
        return value;
    });
}

Result<ExchangeOutcome> read_exchange_outcome(const Reply& reply) {
    return parse_reply<ExchangeOutcome>(reply, [](Reader& in) { return wire::read_exchange_outcome(in); });
}

Result<std::vector<ExchangeOrder>> read_exchange_list(const Reply& reply) {
    return parse_reply<std::vector<ExchangeOrder>>(reply, [](Reader& in) {
        std::vector<ExchangeOrder> out;
        const std::size_t count = in.count(kListMost, 65);
        for (std::size_t index = 0; index < count && in.ok(); ++index)
            out.push_back(wire::read_exchange_order(in));
        return out;
    });
}

Result<ExchangeOrder> read_exchange(const Reply& reply) {
    return parse_reply<ExchangeOrder>(reply, [](Reader& in) { return wire::read_exchange_order(in); });
}

Result<std::int64_t> read_count(const Reply& reply) {
    return parse_reply<std::int64_t>(reply, [](Reader& in) { return in.i64(); });
}

Result<RedeemOutcome> read_redeem(const Reply& reply) {
    return parse_reply<RedeemOutcome>(reply, [](Reader& in) { return wire::read_redeem_outcome(in); });
}

Result<std::vector<GrantRecord>> read_grant_list(const Reply& reply) {
    return parse_reply<std::vector<GrantRecord>>(reply, [](Reader& in) {
        std::vector<GrantRecord> out;
        constexpr std::size_t kGrantMin = 8 + 8 + 1 + 8 + 8 + 1 + 2 + 8;
        const std::size_t count = in.count(kListMost, kGrantMin);
        for (std::size_t index = 0; index < count && in.ok(); ++index)
            out.push_back(wire::read_grant_record(in));
        return out;
    });
}

Result<GrantClaimed> read_grant_claimed(const Reply& reply) {
    return parse_reply<GrantClaimed>(reply, [](Reader& in) { return wire::read_grant_claimed(in); });
}

Result<GrantFinished> read_grant_finished(const Reply& reply) {
    return parse_reply<GrantFinished>(reply, [](Reader& in) { return wire::read_grant_finished(in); });
}

Result<std::vector<GrantOrder>> read_grant_orders(const Reply& reply) {
    return parse_reply<std::vector<GrantOrder>>(reply, [](Reader& in) {
        std::vector<GrantOrder> out;
        const std::size_t count = in.count(kListMost, 41);
        for (std::size_t index = 0; index < count && in.ok(); ++index)
            out.push_back(wire::read_grant_order(in));
        return out;
    });
}

Result<GrantRecord> read_grant(const Reply& reply) {
    return parse_reply<GrantRecord>(reply, [](Reader& in) { return wire::read_grant_record(in); });
}

Result<Points> read_points(const Reply& reply) {
    return parse_reply<Points>(reply, [](Reader& in) { return Points{in.i64()}; });
}

Result<PaymentOutcome> read_payment_outcome(const Reply& reply) {
    return parse_reply<PaymentOutcome>(reply, [](Reader& in) { return wire::read_payment_outcome(in); });
}

Result<PaymentRecord> read_payment(const Reply& reply) {
    return parse_reply<PaymentRecord>(reply, [](Reader& in) { return wire::read_payment_record(in); });
}

Result<BatchRecord> read_batch(const Reply& reply) {
    return parse_reply<BatchRecord>(reply, [](Reader& in) { return wire::read_batch_record(in); });
}

Result<MintedCodes> read_minted(const Reply& reply) {
    return parse_reply<MintedCodes>(reply, [](Reader& in) {
        MintedCodes value;
        const std::size_t count = in.count(kMintPerCallMost, 2);
        for (std::size_t index = 0; index < count && in.ok(); ++index)
            value.codes.push_back(in.text(32));
        return value;
    });
}

Result<SpendSummary> read_spend_summary(const Reply& reply) {
    return parse_reply<SpendSummary>(reply, [](Reader& in) {
        SpendSummary value;
        value.recorded = in.i64();
        value.duplicates = in.i64();
        return value;
    });
}

Result<SpendHeadroom> read_headroom(const Reply& reply) {
    return parse_reply<SpendHeadroom>(reply, [](Reader& in) { return SpendHeadroom{Ingot{in.i64()}}; });
}

Result<Conservation> read_conservation(const Reply& reply) {
    return parse_reply<Conservation>(reply, [](Reader& in) { return wire::read_conservation(in); });
}

Result<DayReport> read_day_report(const Reply& reply) {
    return parse_reply<DayReport>(reply, [](Reader& in) { return wire::read_day_report(in); });
}

Result<std::vector<LedgerEntry>> read_ledger_tail(const Reply& reply) {
    return parse_reply<std::vector<LedgerEntry>>(reply, [](Reader& in) {
        std::vector<LedgerEntry> out;
        constexpr std::size_t kEntryMin = 8 + 8 + 8 + 1 + 8 + 2 + 2 + 8;
        const std::size_t count = in.count(kLedgerTailWireMost, kEntryMin);
        for (std::size_t index = 0; index < count && in.ok(); ++index)
            out.push_back(wire::read_ledger_entry(in));
        return out;
    });
}

} // namespace rpc

} // namespace game::billing
