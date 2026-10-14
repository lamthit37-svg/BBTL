#include "billing/webhook.hpp"

#include "billing/book.hpp"
#include "billing/checks.hpp"
#include "billing/error.hpp"
#include "billing/http.hpp"
#include "billing/rules.hpp"
#include "billing/types.hpp"
#include "secure/secure.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::billing {
namespace {

constexpr std::string_view kMessagePrefix = "TLBBPAY1\n";

[[nodiscard]] std::optional<int> nibble(char c) noexcept {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return std::nullopt;
}

[[nodiscard]] std::string message_of(const SignedPart& part) {
    std::string message{kMessagePrefix};
    message.append(part.path);
    message.push_back('\n');
    message.append(std::to_string(part.timestamp));
    message.push_back('\n');
    message.append(part.body);
    return message;
}

// Giải 2 ký tự hex mỗi byte đầu ra; hex phải dài đúng 2 lần out.
[[nodiscard]] bool decode_hex(std::string_view hex, std::span<std::byte> out) noexcept {
    if (hex.size() != out.size() * 2) return false;
    for (std::byte& slot : out) {
        const std::optional<int> high = nibble(hex.front());
        const std::optional<int> low = nibble(hex[1]);
        if (!high || !low) return false;
        slot = static_cast<std::byte>((*high << 4) | *low);
        hex.remove_prefix(2);
    }
    return true;
}

[[nodiscard]] std::span<const std::byte> bytes_of(const std::string& text) noexcept {
    return std::as_bytes(std::span{text.data(), text.size()});
}

[[nodiscard]] std::optional<std::int64_t> parse_digits(std::string_view text, std::int64_t most) noexcept {
    // Tối đa 18 chữ số nên int64 không tràn; không dấu, không khoảng trắng, không "0x".
    if (text.empty() || text.size() > 18) return std::nullopt;
    std::int64_t value = 0;
    for (const char c : text) {
        if (c < '0' || c > '9') return std::nullopt;
        value = (value * 10) + (c - '0');
    }
    if (value > most) return std::nullopt;
    return value;
}

[[nodiscard]] http::Status status_of(Error error) noexcept {
    switch (error) {
    case Error::kMalformed:
    case Error::kBadAmount: return http::Status::kUnprocessable;
    case Error::kConflict:
    case Error::kBadState:
    case Error::kInsufficient: return http::Status::kConflict;
    default: return http::Status::kUnavailable;
    }
}

[[nodiscard]] std::string_view word_of(Error error) noexcept {
    switch (error) {
    case Error::kMalformed:
    case Error::kBadAmount: return "invalid";
    case Error::kConflict: return "conflict";
    case Error::kBadState: return "bad_state";
    case Error::kInsufficient: return "insufficient";
    default: return "busy";
    }
}

// Đọc bộ trường bắt buộc: trade_no, account, points, amount, currency, status; trường lạ là hỏng.
[[nodiscard]] std::optional<PaymentEvent> event_of(const http::FormFields& fields, std::string_view provider) {
    constexpr std::size_t kFieldCount = 6;
    if (fields.size() != kFieldCount) return std::nullopt;
    const auto field = [&](std::string_view key) -> const std::string* {
        for (const auto& [name, value] : fields) {
            if (name == key) return &value;
        }
        return nullptr;
    };
    const std::string* const trade_no = field("trade_no");
    const std::string* const account_text = field("account");
    const std::string* const points_text = field("points");
    const std::string* const amount_text = field("amount");
    const std::string* const currency = field("currency");
    const std::string* const status_text = field("status");
    if (trade_no == nullptr || account_text == nullptr || points_text == nullptr || amount_text == nullptr ||
        currency == nullptr || status_text == nullptr) {
        return std::nullopt;
    }
    const std::optional<std::int64_t> account = parse_digits(*account_text, static_cast<std::int64_t>(kIdMax));
    const std::optional<std::int64_t> points = parse_digits(*points_text, 0x7FFFFFFF);
    const std::optional<std::int64_t> amount = parse_digits(*amount_text, kAmountMinorMost);
    const std::optional<PaymentStatus> status = payment_status_of(*status_text);
    if (!account || !points || !amount || !status) return std::nullopt;
    return PaymentEvent{.provider = std::string{provider},
        .trade_no = *trade_no,
        .account = AccountId{static_cast<std::uint64_t>(*account)},
        .points = Points{*points},
        .amount_minor = *amount,
        .currency = *currency,
        .status = *status};
}

} // namespace

std::optional<ProviderKey> parse_provider_key(std::string_view text) {
    while (!text.empty() && (text.back() == '\n' || text.back() == '\r' || text.back() == ' ' || text.back() == '\t'))
        text.remove_suffix(1);
    if (text.size() != kProviderKeyBytes * 2) return std::nullopt;
    ProviderKey key{};
    if (!decode_hex(text, key)) return std::nullopt;
    return key;
}

std::string sign_webhook(const ProviderKey& key, const SignedPart& part) {
    const std::string message = message_of(part);
    std::array<std::byte, 32> tag{};
    if (!secure::mac32(key, bytes_of(message), tag)) return {};
    return secure::hex_encode(tag);
}

bool verify_webhook(const ProviderKey& key, const SignedPart& part, std::string_view signature_hex) {
    std::array<std::byte, 32> tag{};
    if (!decode_hex(signature_hex, tag)) return false;
    const std::string message = message_of(part);
    return secure::mac32_verify(key, bytes_of(message), tag);
}

Webhooks::Webhooks(std::vector<WebhookProvider> providers, std::int64_t max_skew_seconds)
    : providers_(std::move(providers)), max_skew_(max_skew_seconds) {}

Webhooks::~Webhooks() {
    for (WebhookProvider& provider : providers_)
        secure::wipe_bytes(provider.key);
}

WebhookAnswer Webhooks::handle(Book& book, const http::Request& request, UnixTime now) const {
    const auto route = std::ranges::find(providers_, request.path, &WebhookProvider::path);
    if (route == providers_.end()) return WebhookAnswer{.status = http::Status::kNotFound, .body = "not_found"};
    if (!verify_webhook(route->key, {.path = request.path, .timestamp = request.timestamp, .body = request.body},
            request.signature)) {
        return WebhookAnswer{.status = http::Status::kUnauthorized, .body = "bad_signature"};
    }
    const std::optional<std::int64_t> skew = add_checked(now.value(), -request.timestamp);
    if (!skew || (*skew < -max_skew_ || *skew > max_skew_)) return WebhookAnswer{.status = http::Status::kUnauthorized, .body = "stale_timestamp"};
    const std::optional<http::FormFields> fields = http::parse_form(request.body);
    if (!fields) return WebhookAnswer{.status = http::Status::kUnprocessable, .body = "invalid"};
    const std::optional<PaymentEvent> event = event_of(*fields, route->name);
    if (!event) return WebhookAnswer{.status = http::Status::kUnprocessable, .body = "invalid"};
    const Result<PaymentOutcome> outcome = book.apply_payment(*event, now);
    if (!outcome) return WebhookAnswer{.status = status_of(outcome.error()), .body = std::string{word_of(outcome.error())}};
    switch (outcome->result) {
    case PaymentResult::kApplied: return WebhookAnswer{.status = http::Status::kOk, .body = "ok"};
    case PaymentResult::kDuplicate: return WebhookAnswer{.status = http::Status::kOk, .body = "duplicate"};
    case PaymentResult::kIgnored: return WebhookAnswer{.status = http::Status::kOk, .body = "ignored"};
    }
    return WebhookAnswer{.status = http::Status::kUnavailable, .body = "busy"};
}

} // namespace game::billing
