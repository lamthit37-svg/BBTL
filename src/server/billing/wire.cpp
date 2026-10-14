#include "billing/wire.hpp"

#include "billing/book.hpp"
#include "billing/checks.hpp"
#include "billing/rules.hpp"
#include "billing/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::billing::wire {
namespace {

constexpr std::size_t kCurrencyBytes = 3;

template <typename Enum>
[[nodiscard]] Enum enum_of(Reader& in, bool (*valid)(std::uint8_t) noexcept, Enum fallback) {
    const std::uint8_t raw = in.u8();
    if (!in.ok() || !valid(raw)) {
        in.fail();
        return fallback;
    }
    return static_cast<Enum>(raw);
}

[[nodiscard]] bool payment_status_valid(std::uint8_t raw) noexcept {
    return raw >= 1 && raw <= 4;
}
[[nodiscard]] bool exchange_status_valid(std::uint8_t raw) noexcept {
    return raw >= 1 && raw <= 4;
}
[[nodiscard]] bool grant_status_valid(std::uint8_t raw) noexcept {
    return raw >= 1 && raw <= 4;
}
[[nodiscard]] bool grant_order_status_valid(std::uint8_t raw) noexcept {
    return raw >= 1 && raw <= 3;
}
[[nodiscard]] bool payment_result_valid(std::uint8_t raw) noexcept {
    return raw >= 1 && raw <= 3;
}
[[nodiscard]] bool ledger_kind_valid(std::uint8_t raw) noexcept {
    return raw >= 1 && raw <= 7;
}

} // namespace

void Writer::u16(std::uint16_t value) {
    u8(static_cast<std::uint8_t>(value));
    u8(static_cast<std::uint8_t>(value >> 8U));
}

void Writer::u32(std::uint32_t value) {
    u16(static_cast<std::uint16_t>(value));
    u16(static_cast<std::uint16_t>(value >> 16U));
}

void Writer::u64(std::uint64_t value) {
    u32(static_cast<std::uint32_t>(value));
    u32(static_cast<std::uint32_t>(value >> 32U));
}

void Writer::text(std::string_view value) {
    const std::size_t size = std::min<std::size_t>(value.size(), 0xFFFFU);
    u16(static_cast<std::uint16_t>(size));
    for (std::size_t index = 0; index < size; ++index) {
        bytes_.push_back(static_cast<std::byte>(value[index]));
    }
}

std::uint8_t Reader::u8() {
    if (!ok_ || rest_.empty()) {
        ok_ = false;
        return 0;
    }
    const auto value = std::to_integer<std::uint8_t>(rest_.front());
    rest_ = rest_.subspan(1);
    return value;
}

std::uint16_t Reader::u16() {
    const auto low = static_cast<std::uint16_t>(u8());
    const auto high = static_cast<std::uint16_t>(static_cast<std::uint16_t>(u8()) << 8U);
    return static_cast<std::uint16_t>(low | high);
}

std::uint32_t Reader::u32() {
    const auto low = static_cast<std::uint32_t>(u16());
    const auto high = static_cast<std::uint32_t>(u16()) << 16U;
    return low | high;
}

std::uint64_t Reader::u64() {
    const auto low = static_cast<std::uint64_t>(u32());
    const auto high = static_cast<std::uint64_t>(u32()) << 32U;
    return low | high;
}

bool Reader::flag() {
    const std::uint8_t value = u8();
    if (value > 1) ok_ = false;
    return value == 1;
}

std::string Reader::text(std::size_t most) {
    const std::uint16_t size = u16();
    if (!ok_ || size > most || rest_.size() < size) {
        ok_ = false;
        return {};
    }
    std::string value(size, '\0');
    for (std::size_t index = 0; index < size; ++index) {
        value[index] = static_cast<char>(std::to_integer<unsigned char>(rest_[index]));
    }
    rest_ = rest_.subspan(size);
    return value;
}

std::size_t Reader::count(std::size_t most, std::size_t element_min) {
    const std::uint16_t declared = u16();
    if (!ok_ || declared > most || (element_min != 0 && rest_.size() / element_min < declared)) {
        ok_ = false;
        return 0;
    }
    return declared;
}

void write_optional_time(Writer& out, const std::optional<UnixTime>& value) {
    out.i64(value ? value->value() : -1);
}

std::optional<UnixTime> read_optional_time(Reader& in) {
    const std::int64_t raw = in.i64();
    if (raw == -1) return std::nullopt;
    if (raw < 0) in.fail();
    return UnixTime{raw};
}

void write(Writer& out, const Balance& value) {
    out.i64(value.available.value());
    out.i64(value.held.value());
    out.flag(value.frozen);
}

Balance read_balance(Reader& in) {
    Balance value;
    value.available = Points{in.i64()};
    value.held = Points{in.i64()};
    value.frozen = in.flag();
    return value;
}

void write(Writer& out, const PaymentRecord& value) {
    out.u64(value.id.value());
    out.text(value.event.provider);
    out.text(value.event.trade_no);
    out.u64(value.event.account.value());
    out.i64(value.event.points.value());
    out.i64(value.event.amount_minor);
    out.text(value.event.currency);
    out.u8(static_cast<std::uint8_t>(value.event.status));
    out.i64(value.created.value());
    out.i64(value.updated.value());
}

PaymentRecord read_payment_record(Reader& in) {
    PaymentRecord value;
    value.id = PaymentId{in.u64()};
    value.event.provider = in.text(kProviderMost);
    value.event.trade_no = in.text(kTradeNoMost);
    value.event.account = AccountId{in.u64()};
    value.event.points = Points{in.i64()};
    value.event.amount_minor = in.i64();
    value.event.currency = in.text(kCurrencyBytes);
    value.event.status = enum_of(in, &payment_status_valid, PaymentStatus::kPending);
    value.created = UnixTime{in.i64()};
    value.updated = UnixTime{in.i64()};
    return value;
}

void write(Writer& out, const PaymentOutcome& value) {
    out.u8(static_cast<std::uint8_t>(value.result));
    write(out, value.record);
    out.i64(value.balance.value());
}

PaymentOutcome read_payment_outcome(Reader& in) {
    PaymentOutcome value;
    value.result = enum_of(in, &payment_result_valid, PaymentResult::kApplied);
    value.record = read_payment_record(in);
    value.balance = Points{in.i64()};
    return value;
}

void write(Writer& out, const ExchangeOrder& value) {
    out.u64(value.id.value());
    out.u64(value.account.value());
    out.u64(value.character.value());
    out.u64(value.request.value());
    out.i64(value.ingot.value());
    out.i64(value.points.value());
    out.u8(static_cast<std::uint8_t>(value.status));
    out.i64(value.created.value());
    out.i64(value.updated.value());
}

ExchangeOrder read_exchange_order(Reader& in) {
    ExchangeOrder value;
    value.id = ExchangeId{in.u64()};
    value.account = AccountId{in.u64()};
    value.character = CharacterId{in.u64()};
    value.request = RequestId{in.u64()};
    value.ingot = Ingot{in.i64()};
    value.points = Points{in.i64()};
    value.status = enum_of(in, &exchange_status_valid, ExchangeStatus::kPending);
    value.created = UnixTime{in.i64()};
    value.updated = UnixTime{in.i64()};
    return value;
}

void write(Writer& out, const ExchangeOutcome& value) {
    write(out, value.order);
    out.flag(value.replayed);
    out.i64(value.balance.value());
}

ExchangeOutcome read_exchange_outcome(Reader& in) {
    ExchangeOutcome value;
    value.order = read_exchange_order(in);
    value.replayed = in.flag();
    value.balance = Points{in.i64()};
    return value;
}

void write(Writer& out, const GrantRecord& value) {
    out.u64(value.id.value());
    out.u64(value.account.value());
    out.u8(static_cast<std::uint8_t>(value.kind));
    out.u64(value.ref_id);
    out.i64(value.quantity);
    out.u8(static_cast<std::uint8_t>(value.status));
    out.text(value.source);
    out.i64(value.created.value());
}

GrantRecord read_grant_record(Reader& in) {
    GrantRecord value;
    value.id = GrantId{in.u64()};
    value.account = AccountId{in.u64()};
    const std::uint8_t kind = in.u8();
    if (!grant_kind_ok(kind)) in.fail();
    value.kind = grant_kind_ok(kind) ? static_cast<GrantKind>(kind) : GrantKind::kItem;
    value.ref_id = in.u64();
    value.quantity = in.i64();
    value.status = enum_of(in, &grant_status_valid, GrantStatus::kPending);
    value.source = in.text(kSourceMost);
    value.created = UnixTime{in.i64()};
    return value;
}

void write(Writer& out, const GrantOrder& value) {
    out.u64(value.id.value());
    out.u64(value.grant.value());
    out.u64(value.character.value());
    out.u8(static_cast<std::uint8_t>(value.status));
    out.i64(value.created.value());
    out.i64(value.updated.value());
}

GrantOrder read_grant_order(Reader& in) {
    GrantOrder value;
    value.id = GrantOrderId{in.u64()};
    value.grant = GrantId{in.u64()};
    value.character = CharacterId{in.u64()};
    value.status = enum_of(in, &grant_order_status_valid, GrantOrderStatus::kPending);
    value.created = UnixTime{in.i64()};
    value.updated = UnixTime{in.i64()};
    return value;
}

void write(Writer& out, const GrantClaimed& value) {
    write(out, value.order);
    write(out, value.grant);
    out.flag(value.replayed);
}

GrantClaimed read_grant_claimed(Reader& in) {
    GrantClaimed value;
    value.order = read_grant_order(in);
    value.grant = read_grant_record(in);
    value.replayed = in.flag();
    return value;
}

void write(Writer& out, const GrantFinished& value) {
    write(out, value.order);
    write(out, value.grant);
    out.flag(value.replayed);
}

GrantFinished read_grant_finished(Reader& in) {
    GrantFinished value;
    value.order = read_grant_order(in);
    value.grant = read_grant_record(in);
    value.replayed = in.flag();
    return value;
}

void write(Writer& out, const RedeemOutcome& value) {
    out.u64(value.batch.value());
    out.i64(value.points.value());
    out.i64(value.balance.value());
    out.u16(static_cast<std::uint16_t>(std::min<std::size_t>(value.grants.size(), kRewardsMost)));
    for (std::size_t index = 0; index < std::min<std::size_t>(value.grants.size(), kRewardsMost); ++index) {
        write(out, value.grants[index]);
    }
}

RedeemOutcome read_redeem_outcome(Reader& in) {
    RedeemOutcome value;
    value.batch = BatchId{in.u64()};
    value.points = Points{in.i64()};
    value.balance = Points{in.i64()};
    constexpr std::size_t kGrantMin = 8 + 8 + 1 + 8 + 8 + 1 + 2 + 8;
    const std::size_t count = in.count(kRewardsMost, kGrantMin);
    for (std::size_t index = 0; index < count && in.ok(); ++index) {
        value.grants.push_back(read_grant_record(in));
    }
    return value;
}

void write(Writer& out, const BatchRecord& value) {
    out.u64(value.id.value());
    out.text(value.spec.name);
    write_optional_time(out, value.spec.starts);
    write_optional_time(out, value.spec.ends);
    out.i64(value.spec.per_account_limit);
    out.u16(static_cast<std::uint16_t>(std::min<std::size_t>(value.spec.rewards.size(), kRewardsMost)));
    for (std::size_t index = 0; index < std::min<std::size_t>(value.spec.rewards.size(), kRewardsMost); ++index) {
        const Reward& reward = value.spec.rewards[index];
        out.u8(reward.kind);
        out.u64(reward.ref_id);
        out.i64(reward.quantity);
    }
    out.text(value.spec.actor);
    out.flag(value.enabled);
    out.i64(value.code_count);
    out.i64(value.created.value());
}

BatchRecord read_batch_record(Reader& in) {
    BatchRecord value;
    value.id = BatchId{in.u64()};
    value.spec.name = in.text(kBatchNameMost);
    value.spec.starts = read_optional_time(in);
    value.spec.ends = read_optional_time(in);
    value.spec.per_account_limit = in.i64();
    constexpr std::size_t kRewardWire = 1 + 8 + 8;
    const std::size_t count = in.count(kRewardsMost, kRewardWire);
    for (std::size_t index = 0; index < count && in.ok(); ++index) {
        Reward reward;
        reward.kind = in.u8();
        reward.ref_id = in.u64();
        reward.quantity = in.i64();
        value.spec.rewards.push_back(reward);
    }
    value.spec.actor = in.text(kActorMost);
    value.enabled = in.flag();
    value.code_count = in.i64();
    value.created = UnixTime{in.i64()};
    return value;
}

void write(Writer& out, const LedgerEntry& value) {
    out.u64(value.id);
    out.u64(value.account.value());
    out.i64(value.delta.value());
    out.u8(static_cast<std::uint8_t>(value.kind));
    out.u64(value.ref);
    out.text(value.reason);
    out.text(value.actor);
    out.i64(value.at.value());
}

LedgerEntry read_ledger_entry(Reader& in) {
    LedgerEntry value;
    value.id = in.u64();
    value.account = AccountId{in.u64()};
    value.delta = Points{in.i64()};
    value.kind = enum_of(in, &ledger_kind_valid, LedgerKind::kTopUp);
    value.ref = in.u64();
    value.reason = in.text(kReasonMost);
    value.actor = in.text(kActorMost);
    value.at = UnixTime{in.i64()};
    return value;
}

void write(Writer& out, const Conservation& value) {
    out.i64(value.topped_up.value());
    out.i64(value.refunded.value());
    out.i64(value.other_net.value());
    out.i64(value.balance_sum.value());
    out.i64(value.exchange_confirmed.value());
    out.i64(value.exchange_held.value());
    out.i64(value.mismatched_accounts);
    out.flag(value.balanced);
}

Conservation read_conservation(Reader& in) {
    Conservation value;
    value.topped_up = Points{in.i64()};
    value.refunded = Points{in.i64()};
    value.other_net = Points{in.i64()};
    value.balance_sum = Points{in.i64()};
    value.exchange_confirmed = Points{in.i64()};
    value.exchange_held = Points{in.i64()};
    value.mismatched_accounts = in.i64();
    value.balanced = in.flag();
    return value;
}

void write(Writer& out, const DayReport& value) {
    out.i64(value.day);
    out.i64(value.topped_up.value());
    out.i64(value.refunded.value());
    out.i64(value.exchanged.value());
    out.i64(value.ingot_issued.value());
    out.i64(value.ingot_spent.value());
    out.i64(value.spend_events);
    out.i64(value.open_exchanges);
    write(out, value.conservation);
}

DayReport read_day_report(Reader& in) {
    DayReport value;
    value.day = in.i64();
    value.topped_up = Points{in.i64()};
    value.refunded = Points{in.i64()};
    value.exchanged = Points{in.i64()};
    value.ingot_issued = Ingot{in.i64()};
    value.ingot_spent = Ingot{in.i64()};
    value.spend_events = in.i64();
    value.open_exchanges = in.i64();
    value.conservation = read_conservation(in);
    return value;
}

} // namespace game::billing::wire
