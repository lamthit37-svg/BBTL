#include "billing/rules.hpp"

#include "billing/error.hpp"
#include "billing/limits.hpp"
#include "billing/types.hpp"
#include "core/text.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <string>
#include <string_view>

namespace game::billing {
namespace {

[[nodiscard]] constexpr bool is_token_char(char c) noexcept {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '.' ||
        c == '-';
}

// Phần giữa của text sau khi cắt khoảng trắng đầu cuối; nullopt khi rỗng, quá dài, có byte điều khiển hoặc không
// phải UTF-8 đúng RFC 3629 (PostgreSQL từ chối dãy hỏng bằng lỗi 22021, mà lỗi database thì bên gọi coi là kBusy và gọi
// lại mãi). Byte >= 0x80 hợp lệ là tiếng Việt nên được giữ.
[[nodiscard]] std::optional<std::string_view> printable(std::string_view text, std::size_t most) noexcept {
    constexpr std::string_view kBlank = " 	";
    const std::size_t first = text.find_first_not_of(kBlank);
    if (first == std::string_view::npos) return std::nullopt;
    const std::size_t last = text.find_last_not_of(kBlank);
    const std::string_view body = text.substr(first, last - first + 1);
    if (body.size() > most) return std::nullopt;
    for (const char c : body) {
        const auto byte = static_cast<unsigned char>(c);
        if (byte < 0x20U || byte == 0x7FU) return std::nullopt;
    }
    if (!core::is_valid_utf8(body)) return std::nullopt;
    return body;
}

template <typename Enum>
struct Name {
    Enum value;
    std::string_view text;
};

template <typename Enum, std::size_t N>
[[nodiscard]] std::string_view text_of(const std::array<Name<Enum>, N>& table, Enum value) noexcept {
    for (const Name<Enum>& entry : table) {
        if (entry.value == value) return entry.text;
    }
    return {};
}

template <typename Enum, std::size_t N>
[[nodiscard]] std::optional<Enum> value_of(const std::array<Name<Enum>, N>& table, std::string_view text) noexcept {
    for (const Name<Enum>& entry : table) {
        if (entry.text == text) return entry.value;
    }
    return std::nullopt;
}

constexpr std::array kPaymentNames{
    Name<PaymentStatus>{.value = PaymentStatus::kPending, .text = "pending"},
    Name<PaymentStatus>{.value = PaymentStatus::kPaid, .text = "paid"},
    Name<PaymentStatus>{.value = PaymentStatus::kFailed, .text = "failed"},
    Name<PaymentStatus>{.value = PaymentStatus::kRefunded, .text = "refunded"},
};
constexpr std::array kExchangeNames{
    Name<ExchangeStatus>{.value = ExchangeStatus::kPending, .text = "pending"},
    Name<ExchangeStatus>{.value = ExchangeStatus::kStale, .text = "stale"},
    Name<ExchangeStatus>{.value = ExchangeStatus::kConfirmed, .text = "confirmed"},
    Name<ExchangeStatus>{.value = ExchangeStatus::kCancelled, .text = "cancelled"},
};
constexpr std::array kGrantNames{
    Name<GrantStatus>{.value = GrantStatus::kPending, .text = "pending"},
    Name<GrantStatus>{.value = GrantStatus::kDelivering, .text = "delivering"},
    Name<GrantStatus>{.value = GrantStatus::kDelivered, .text = "delivered"},
    Name<GrantStatus>{.value = GrantStatus::kVoid, .text = "void"},
};
constexpr std::array kGrantOrderNames{
    Name<GrantOrderStatus>{.value = GrantOrderStatus::kPending, .text = "pending"},
    Name<GrantOrderStatus>{.value = GrantOrderStatus::kDone, .text = "done"},
    Name<GrantOrderStatus>{.value = GrantOrderStatus::kCancelled, .text = "cancelled"},
};
constexpr std::array kKindNames{
    Name<GrantKind>{.value = GrantKind::kCoin, .text = "coin"},
    Name<GrantKind>{.value = GrantKind::kIngot, .text = "ingot"},
    Name<GrantKind>{.value = GrantKind::kBonusPoint, .text = "bonus_point"},
    Name<GrantKind>{.value = GrantKind::kBoundCoin, .text = "bound_coin"},
    Name<GrantKind>{.value = GrantKind::kItem, .text = "item"},
};

} // namespace

Result<PaymentAct> payment_step(std::optional<PaymentStatus> existing, PaymentStatus incoming) noexcept {
    using S = PaymentStatus;
    using A = PaymentAct;
    if (!existing) {
        switch (incoming) {
        case S::kPending: return A::kCreatePending;
        case S::kPaid: return A::kCreatePaid;
        case S::kFailed: return A::kCreateFailed;
        case S::kRefunded: return std::unexpected(Error::kBadState);
        }
        return std::unexpected(Error::kMalformed);
    }
    if (*existing == incoming) return A::kDuplicate;
    switch (*existing) {
    case S::kPending:
        if (incoming == S::kPaid) return A::kPromote;
        if (incoming == S::kFailed) return A::kFail;
        return std::unexpected(Error::kBadState);
    case S::kPaid:
        if (incoming == S::kPending) return A::kIgnore;
        if (incoming == S::kRefunded) return A::kRefund;
        return std::unexpected(Error::kConflict);
    case S::kFailed:
        if (incoming == S::kPending) return A::kIgnore;
        if (incoming == S::kPaid) return std::unexpected(Error::kConflict);
        return std::unexpected(Error::kBadState);
    case S::kRefunded:
        if (incoming == S::kPending || incoming == S::kPaid) return A::kIgnore;
        return std::unexpected(Error::kConflict);
    }
    return std::unexpected(Error::kMalformed);
}

Result<Points> exchange_cost(Ingot ingot, std::int64_t ingot_per_point, const Limits& limits) noexcept {
    if (ingot_per_point < 1) return std::unexpected(Error::kBadAmount);
    if (ingot.value() < limits.min_ingot_per_order || ingot.value() > limits.max_ingot_per_order) {
        return std::unexpected(Error::kBadAmount);
    }
    const std::optional<std::int64_t> scaled = multiply_checked(ingot.value(), kTenthsPerPoint);
    if (!scaled) return std::unexpected(Error::kBadAmount);
    const std::int64_t whole = *scaled / ingot_per_point;
    const std::int64_t cost = (*scaled % ingot_per_point) == 0 ? whole : whole + 1;
    // ingot_per_point rất lớn làm tử số nhỏ hơn mẫu số: vẫn phải trừ ít nhất 1 phần mười.
    return Points{cost < 1 ? 1 : cost};
}

Result<Points> exchange_begin_step(Ingot ingot, std::int64_t ingot_per_point, Points balance, bool frozen,
    const Limits& limits) noexcept {
    if (frozen) return std::unexpected(Error::kFrozen);
    const Result<Points> cost = exchange_cost(ingot, ingot_per_point, limits);
    if (!cost) return cost;
    if (balance.value() < cost->value()) return std::unexpected(Error::kInsufficient);
    return cost;
}

Result<FinishAct> exchange_finish_step(ExchangeStatus current, Verdict verdict) noexcept {
    using S = ExchangeStatus;
    const bool is_open = current == S::kPending || current == S::kStale;
    if (is_open) return verdict == Verdict::kDone ? FinishAct::kConfirm : FinishAct::kCancel;
    if (current == S::kConfirmed && verdict == Verdict::kDone) return FinishAct::kDuplicate;
    if (current == S::kCancelled && verdict == Verdict::kCancelled) return FinishAct::kDuplicate;
    return std::unexpected(Error::kBadState);
}

bool exchange_overdue(UnixTime created, UnixTime now, std::int64_t timeout_seconds) noexcept {
    if (timeout_seconds <= 0) return false;
    const std::optional<std::int64_t> deadline = add_checked(created.value(), timeout_seconds);
    if (!deadline) return false;
    return now.value() >= *deadline;
}

Result<FinishAct> grant_finish_step(GrantOrderStatus current, Verdict verdict) noexcept {
    using S = GrantOrderStatus;
    if (current == S::kPending) return verdict == Verdict::kDone ? FinishAct::kConfirm : FinishAct::kCancel;
    if (current == S::kDone && verdict == Verdict::kDone) return FinishAct::kDuplicate;
    if (current == S::kCancelled && verdict == Verdict::kCancelled) return FinishAct::kDuplicate;
    return std::unexpected(Error::kBadState);
}

Result<void> redeem_step(const CodeFacts& facts) noexcept {
    if (facts.frozen) return std::unexpected(Error::kFrozen);
    if (!facts.batch_enabled) return std::unexpected(Error::kCodeDisabled);
    if (facts.used) return std::unexpected(Error::kCodeUsed);
    if (facts.starts && facts.now.value() < facts.starts->value()) return std::unexpected(Error::kCodeNotYet);
    if (facts.ends && facts.now.value() > facts.ends->value()) return std::unexpected(Error::kCodeExpired);
    if (facts.used_in_batch >= facts.per_account_limit) return std::unexpected(Error::kLimitReached);
    return {};
}

std::optional<std::string> clean_text(std::string_view text, std::size_t most) {
    const std::optional<std::string_view> body = printable(text, most);
    if (!body) return std::nullopt;
    return std::string{*body};
}

Result<Points> admin_step(Points delta, std::string_view reason, std::string_view actor, Points balance,
    const Limits& limits) noexcept {
    if (!printable(reason, kReasonMost) || !printable(actor, kActorMost)) {
        return std::unexpected(Error::kReasonRequired);
    }
    const std::int64_t change = delta.value();
    if (change == 0) return std::unexpected(Error::kBadAmount);
    if (change == std::numeric_limits<std::int64_t>::min()) return std::unexpected(Error::kBadAmount);
    const std::int64_t magnitude = change < 0 ? -change : change;
    if (magnitude > limits.max_admin_adjust) return std::unexpected(Error::kBadAmount);
    const std::optional<std::int64_t> next = add_checked(balance.value(), change);
    if (!next || *next < 0) return std::unexpected(Error::kInsufficient);
    if (*next > limits.max_balance) return std::unexpected(Error::kBadAmount);
    return Points{*next};
}

Result<Points> credit_step(Points delta, Points balance, const Limits& limits) noexcept {
    if (delta.value() <= 0) return std::unexpected(Error::kBadAmount);
    const std::optional<std::int64_t> next = add_checked(balance.value(), delta.value());
    if (!next || *next > limits.max_balance) return std::unexpected(Error::kBadAmount);
    return Points{*next};
}

bool token_ok(std::string_view text, std::size_t most) noexcept {
    if (text.empty() || text.size() > most) return false;
    for (const char c : text) {
        if (!is_token_char(c)) return false;
    }
    return true;
}

bool currency_ok(std::string_view text) noexcept {
    if (text.size() != 3) return false;
    for (const char c : text) {
        if (c < 'A' || c > 'Z') return false;
    }
    return true;
}

std::optional<std::uint32_t> parse_ipv4(std::string_view text) noexcept {
    std::uint32_t packed = 0;
    std::size_t index = 0;
    for (int part = 0; part < 4; ++part) {
        if (index >= text.size()) return std::nullopt;
        std::uint32_t value = 0;
        std::size_t digits = 0;
        while (index < text.size() && text[index] >= '0' && text[index] <= '9') {
            value = (value * 10U) + static_cast<std::uint32_t>(text[index] - '0');
            ++index;
            ++digits;
            if (digits > 3 || value > 255U) return std::nullopt;
        }
        if (digits == 0) return std::nullopt;
        // Số 0 đứng đầu ("01") mơ hồ giữa thập phân và bát phân: từ chối.
        if (digits > 1 && text[index - digits] == '0') return std::nullopt;
        packed = (packed << 8U) | value;
        if (part < 3) {
            if (index >= text.size() || text[index] != '.') return std::nullopt;
            ++index;
        }
    }
    if (index != text.size()) return std::nullopt;
    return packed;
}

std::string_view to_text(PaymentStatus status) noexcept { return text_of(kPaymentNames, status); }
std::optional<PaymentStatus> payment_status_of(std::string_view text) noexcept { return value_of(kPaymentNames, text); }
std::string_view to_text(ExchangeStatus status) noexcept { return text_of(kExchangeNames, status); }
std::optional<ExchangeStatus> exchange_status_of(std::string_view text) noexcept {
    return value_of(kExchangeNames, text);
}
std::string_view to_text(GrantStatus status) noexcept { return text_of(kGrantNames, status); }
std::optional<GrantStatus> grant_status_of(std::string_view text) noexcept { return value_of(kGrantNames, text); }
std::string_view to_text(GrantOrderStatus status) noexcept { return text_of(kGrantOrderNames, status); }
std::optional<GrantOrderStatus> grant_order_status_of(std::string_view text) noexcept {
    return value_of(kGrantOrderNames, text);
}
std::string_view to_text(GrantKind kind) noexcept { return text_of(kKindNames, kind); }
std::optional<GrantKind> grant_kind_of(std::string_view text) noexcept { return value_of(kKindNames, text); }

} // namespace game::billing
