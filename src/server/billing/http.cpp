#include "billing/http.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::billing::http {
namespace {

constexpr std::string_view kBlankLine = "\r\n\r\n";
constexpr std::size_t kSignatureHex = 64;
constexpr std::size_t kTimestampDigits = 12;
constexpr std::size_t kContentLengthDigits = 5;
constexpr std::size_t kFormPairsMost = 16;
constexpr std::size_t kFormKeyMost = 24;
constexpr std::size_t kFormValueMost = 128;
constexpr std::string_view kFormType = "application/x-www-form-urlencoded";

[[nodiscard]] bool is_target_char(char c) noexcept {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '/' || c == '_' ||
        c == '.' || c == '-';
}

[[nodiscard]] bool is_name_char(char c) noexcept {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-';
}

[[nodiscard]] bool all_digits(std::string_view text, std::size_t most) noexcept {
    if (text.empty() || text.size() > most) return false;
    return std::ranges::all_of(text, [](char c) { return c >= '0' && c <= '9'; });
}

[[nodiscard]] std::int64_t number_of(std::string_view digits) noexcept {
    std::int64_t value = 0;
    for (const char c : digits)
        value = (value * 10) + (c - '0');
    return value;
}

[[nodiscard]] bool is_lower_hex(std::string_view text) noexcept {
    return std::ranges::all_of(text, [](char c) { return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'); });
}

[[nodiscard]] char lower(char c) noexcept {
    return (c >= 'A' && c <= 'Z') ? static_cast<char>(c - 'A' + 'a') : c;
}

[[nodiscard]] bool equals_nocase(std::string_view left, std::string_view right) noexcept {
    return std::ranges::equal(left, right, [](char a, char b) { return lower(a) == lower(b); });
}

// Đầu yêu cầu chỉ gồm ASCII in được và CRLF; '\r' hoặc '\n' lẻ bị từ chối.
[[nodiscard]] bool head_bytes_ok(std::string_view head) noexcept {
    for (std::size_t index = 0; index < head.size(); ++index) {
        const char c = head[index];
        if (c == '\r') {
            if (index + 1 >= head.size() || head[index + 1] != '\n') return false;
            ++index;
            continue;
        }
        if (c < 0x20 || c > 0x7E) return false;
    }
    return true;
}

[[nodiscard]] Parsed reject(Status status) {
    Parsed parsed;
    parsed.state = Parsed::State::kReject;
    parsed.reject = status;
    return parsed;
}

struct Fields {
    std::optional<std::int64_t> length;
    std::optional<std::int64_t> timestamp;
    std::optional<std::string> signature;
    bool saw_type = false;
};

// Trả mã từ chối nếu dòng này cấm yêu cầu; nullopt nếu chấp nhận.
[[nodiscard]] std::optional<Status> take_header(std::string_view line, Fields& fields) {
    const std::size_t colon = line.find(':');
    if (colon == std::string_view::npos || colon == 0) return Status::kBadRequest;
    const std::string_view name = line.substr(0, colon);
    if (!std::ranges::all_of(name, is_name_char)) return Status::kBadRequest;
    std::string_view value = line.substr(colon + 1);
    while (!value.empty() && value.front() == ' ')
        value.remove_prefix(1);
    while (!value.empty() && value.back() == ' ')
        value.remove_suffix(1);
    if (value.size() > kHeaderValueMost) return Status::kHeaderTooLarge;
    if (equals_nocase(name, "transfer-encoding") || equals_nocase(name, "expect")) return Status::kBadRequest;
    if (equals_nocase(name, "content-length")) {
        if (fields.length || !all_digits(value, kContentLengthDigits)) return Status::kBadRequest;
        fields.length = number_of(value);
        return std::nullopt;
    }
    if (equals_nocase(name, "x-timestamp")) {
        if (fields.timestamp || !all_digits(value, kTimestampDigits)) return Status::kBadRequest;
        fields.timestamp = number_of(value);
        return std::nullopt;
    }
    if (equals_nocase(name, "x-signature")) {
        if (fields.signature || value.size() != kSignatureHex || !is_lower_hex(value)) return Status::kBadRequest;
        fields.signature = std::string{value};
        return std::nullopt;
    }
    if (equals_nocase(name, "content-type")) {
        if (fields.saw_type) return Status::kBadRequest;
        fields.saw_type = true;
        // Cho phép ";charset=..." nhưng không cho kiểu khác.
        const std::string_view main = value.substr(0, value.find(';'));
        std::string_view trimmed = main;
        while (!trimmed.empty() && trimmed.back() == ' ')
            trimmed.remove_suffix(1);
        if (!equals_nocase(trimmed, kFormType)) return Status::kBadRequest;
    }
    return std::nullopt;
}

[[nodiscard]] std::optional<int> hex_value(char c) noexcept {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return std::nullopt;
}

[[nodiscard]] std::optional<std::string> decode_value(std::string_view raw) {
    std::string out;
    for (std::size_t index = 0; index < raw.size(); ++index) {
        char c = raw[index];
        if (c == '+') {
            c = ' ';
        } else if (c == '%') {
            if (index + 2 >= raw.size()) return std::nullopt;
            const std::optional<int> high = hex_value(raw[index + 1]);
            const std::optional<int> low = hex_value(raw[index + 2]);
            if (!high || !low) return std::nullopt;
            c = static_cast<char>((*high << 4) | *low);
            index += 2;
        }
        const auto byte = static_cast<unsigned char>(c);
        if (byte < 0x20U || byte == 0x7FU) return std::nullopt;
        out.push_back(c);
        if (out.size() > kFormValueMost) return std::nullopt;
    }
    return out;
}

} // namespace

std::string_view reason_of(Status status) noexcept {
    switch (status) {
    case Status::kOk: return "OK";
    case Status::kBadRequest: return "Bad Request";
    case Status::kUnauthorized: return "Unauthorized";
    case Status::kNotFound: return "Not Found";
    case Status::kMethodNotAllowed: return "Method Not Allowed";
    case Status::kTimeout: return "Request Timeout";
    case Status::kConflict: return "Conflict";
    case Status::kLengthRequired: return "Length Required";
    case Status::kTooLarge: return "Payload Too Large";
    case Status::kUnprocessable: return "Unprocessable Content";
    case Status::kHeaderTooLarge: return "Request Header Fields Too Large";
    case Status::kNotImplemented: return "Not Implemented";
    case Status::kUnavailable: return "Service Unavailable";
    }
    return "Error";
}

Parsed parse(std::string_view data) {
    const std::string_view window = data.substr(0, std::min(data.size(), kHeadMost + kBlankLine.size()));
    const std::size_t head_end = window.find(kBlankLine);
    if (head_end == std::string_view::npos) {
        if (data.size() > kHeadMost) return reject(Status::kHeaderTooLarge);
        return Parsed{};
    }
    if (head_end > kHeadMost) return reject(Status::kHeaderTooLarge);
    const std::string_view head = data.substr(0, head_end);
    if (!head_bytes_ok(head)) return reject(Status::kBadRequest);

    const std::size_t first_end = head.find("\r\n");
    const std::string_view request_line = head.substr(0, first_end);
    const std::size_t sp1 = request_line.find(' ');
    const std::size_t sp2 = sp1 == std::string_view::npos ? sp1 : request_line.find(' ', sp1 + 1);
    if (sp1 == std::string_view::npos || sp2 == std::string_view::npos) return reject(Status::kBadRequest);
    const std::string_view method = request_line.substr(0, sp1);
    const std::string_view target = request_line.substr(sp1 + 1, sp2 - sp1 - 1);
    const std::string_view version = request_line.substr(sp2 + 1);
    if (version != "HTTP/1.1" && version != "HTTP/1.0") return reject(Status::kBadRequest);
    if (method != "POST") return reject(Status::kMethodNotAllowed);
    if (target.empty() || target.size() > kTargetMost || target.front() != '/' ||
        !std::ranges::all_of(target, is_target_char)) {
        return reject(Status::kBadRequest);
    }

    Fields fields;
    std::size_t count = 0;
    std::size_t cursor = first_end == std::string_view::npos ? head.size() : first_end + 2;
    while (cursor < head.size()) {
        const std::size_t line_end = std::min(head.find("\r\n", cursor), head.size());
        if (++count > kHeaderCountMost) return reject(Status::kHeaderTooLarge);
        if (const std::optional<Status> bad = take_header(head.substr(cursor, line_end - cursor), fields)) {
            return reject(*bad);
        }
        cursor = line_end + 2;
    }
    if (!fields.length) return reject(Status::kLengthRequired);
    if (!fields.signature || !fields.timestamp) return reject(Status::kUnauthorized);
    if (!fields.saw_type) return reject(Status::kBadRequest);
    if (std::cmp_greater(*fields.length, kBodyMost)) return reject(Status::kTooLarge);
    const std::size_t body_at = head_end + kBlankLine.size();
    const auto body_size = static_cast<std::size_t>(*fields.length);
    if (data.size() < body_at + body_size) return Parsed{};

    Parsed done;
    done.state = Parsed::State::kDone;
    done.request.path = std::string{target};
    done.request.timestamp = *fields.timestamp;
    done.request.signature = *fields.signature;
    done.request.body = std::string{data.substr(body_at, body_size)};
    done.consumed = body_at + body_size;
    return done;
}

std::string respond(Status status, std::string_view body) {
    return std::format("HTTP/1.1 {} {}\r\nContent-Type: text/plain; charset=utf-8\r\nContent-Length: {}\r\n"
                       "Connection: close\r\n\r\n{}",
        static_cast<unsigned>(status), reason_of(status), body.size(), body);
}

std::optional<FormFields> parse_form(std::string_view body) {
    FormFields fields;
    if (body.empty()) return fields;
    std::size_t cursor = 0;
    while (cursor <= body.size()) {
        const std::size_t amp = std::min(body.find('&', cursor), body.size());
        const std::string_view pair = body.substr(cursor, amp - cursor);
        const std::size_t eq = pair.find('=');
        if (eq == std::string_view::npos) return std::nullopt;
        const std::string_view key = pair.substr(0, eq);
        if (key.empty() || key.size() > kFormKeyMost) return std::nullopt;
        if (!std::ranges::all_of(key, [](char c) { return (c >= 'a' && c <= 'z') || c == '_'; })) return std::nullopt;
        if (fields.size() >= kFormPairsMost) return std::nullopt;
        if (std::ranges::any_of(fields, [&](const auto& field) { return field.first == key; })) return std::nullopt;
        std::optional<std::string> value = decode_value(pair.substr(eq + 1));
        if (!value) return std::nullopt;
        fields.emplace_back(std::string{key}, std::move(*value));
        cursor = amp + 1;
    }
    return fields;
}

} // namespace game::billing::http
