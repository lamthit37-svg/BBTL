#include "config/types.hpp"

#include "core/check.hpp"
#include "core/number.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::config {
namespace {

struct OctetRead {
    std::uint8_t value = 0;
    std::size_t size = 0;
    bool ok = false;
};

struct Scan {
    std::string_view rest;
    bool ok = true;
};

[[nodiscard]] bool not_digit(char character) noexcept {
    return character < '0' || character > '9';
}

[[nodiscard]] bool all_digits(std::string_view text) noexcept {
    return std::ranges::find_if(text, not_digit) == text.end();
}

[[nodiscard]] std::size_t digit_run(std::string_view text) noexcept {
    const auto stop = std::ranges::find_if(text, not_digit);
    return static_cast<std::size_t>(stop - text.begin());
}

[[nodiscard]] bool leading_zero(std::string_view text) noexcept {
    if (text.size() < 2) return false;
    return text.front() == '0';
}

[[nodiscard]] OctetRead read_octet(std::string_view text) noexcept {
    const std::size_t length = digit_run(text);
    if (length == 0 || length > 3) return {};
    const std::string_view slice = text.substr(0, length);
    if (leading_zero(slice)) return {};
    const std::optional<int> number = core::parse_whole_int(slice);
    if (!number || *number > 255) return {};
    OctetRead read;
    read.value = static_cast<std::uint8_t>(*number);
    read.size = length;
    read.ok = true;
    return read;
}

void take_octet(Scan& scan) noexcept {
    if (!scan.ok) return;
    const OctetRead read = read_octet(scan.rest);
    if (!read.ok) {
        scan.ok = false;
        return;
    }
    scan.rest.remove_prefix(read.size);
}

void take_dot(Scan& scan) noexcept {
    if (!scan.ok) return;
    if (scan.rest.empty() || scan.rest.front() != '.') {
        scan.ok = false;
        return;
    }
    scan.rest.remove_prefix(1);
}

[[nodiscard]] bool prefix_ok(std::string_view text) noexcept {
    if (text.empty() || leading_zero(text) || !all_digits(text)) return false;
    const std::optional<int> number = core::parse_whole_int(text);
    if (!number) return false;
    return *number <= 32;
}

[[nodiscard]] std::optional<Port> port_text(std::string_view text) noexcept {
    if (text.empty() || leading_zero(text)) return std::nullopt;
    const std::optional<int> number = core::parse_whole_int(text);
    if (!number) return std::nullopt;
    return Port::parse(*number);
}

} // namespace

std::optional<Port> Port::parse(std::int64_t value) noexcept {
    if (value < 1 || value > 65535) return std::nullopt;
    return Port{static_cast<std::uint16_t>(value)};
}

std::optional<ProcessId> ProcessId::parse(std::int64_t value) noexcept {
    if (value < 0) return std::nullopt;
    return ProcessId{value};
}

std::optional<MachineId> MachineId::parse(std::int64_t value) noexcept {
    if (value < 0) return std::nullopt;
    return MachineId{value};
}

std::optional<WorldId> WorldId::parse(std::int64_t value) noexcept {
    if (value < 1) return std::nullopt;
    return WorldId{value};
}

Ipv4Address::Ipv4Address(std::string text) : text_(std::move(text)) {}

std::optional<Ipv4Address> Ipv4Address::parse(std::string_view text) {
    Scan scan{.rest = text};
    take_octet(scan);
    take_dot(scan);
    take_octet(scan);
    take_dot(scan);
    take_octet(scan);
    take_dot(scan);
    take_octet(scan);
    if (!scan.ok || !scan.rest.empty()) return std::nullopt;
    return Ipv4Address{std::string{text}};
}

bool is_loopback(const Ipv4Address& host) noexcept {
    return host.text() == "127.0.0.1";
}

std::optional<Endpoint> Endpoint::parse(std::string_view text) {
    const std::size_t colon = text.rfind(':');
    if (colon == std::string_view::npos || colon == 0) return std::nullopt;
    if (colon + 1 >= text.size()) return std::nullopt;
    const std::optional<Ipv4Address> host = Ipv4Address::parse(text.substr(0, colon));
    if (!host) return std::nullopt;
    const std::string_view port_part = text.substr(colon + 1);
    const bool is_any = port_part == "0" && is_loopback(*host);
    const std::optional<Port> port = is_any ? std::optional<Port>{Port::any()} : port_text(port_part);
    if (!port) return std::nullopt;
    Endpoint endpoint;
    endpoint.host = *host;
    endpoint.port = *port;
    return endpoint;
}

std::optional<std::string> parse_cidr(std::string_view text) {
    const std::size_t slash = text.rfind('/');
    if (slash == std::string_view::npos || slash == 0) return std::nullopt;
    if (slash + 1 >= text.size()) return std::nullopt;
    const std::optional<Ipv4Address> host = Ipv4Address::parse(text.substr(0, slash));
    if (!host || !prefix_ok(text.substr(slash + 1))) return std::nullopt;
    return std::string{text};
}

std::string_view name_of(ProcessKind kind) noexcept {
    switch (kind) {
    case ProcessKind::kStore: return "store";
    case ProcessKind::kAuth: return "auth";
    case ProcessKind::kBilling: return "billing";
    case ProcessKind::kWorld: return "world";
    case ProcessKind::kZone: return "zone";
    }
    core::fail("loại tiến trình");
}

std::string_view name_of(ServiceKind kind) noexcept {
    switch (kind) {
    case ServiceKind::kStore: return "store";
    case ServiceKind::kAuth: return "auth";
    case ServiceKind::kBilling: return "billing";
    case ServiceKind::kWorld: return "world";
    case ServiceKind::kZone: return "zone";
    case ServiceKind::kGate: return "gate";
    }
    core::fail("loại dịch vụ");
}

ServiceKind service_of(ProcessKind kind) noexcept {
    switch (kind) {
    case ProcessKind::kStore: return ServiceKind::kStore;
    case ProcessKind::kAuth: return ServiceKind::kAuth;
    case ProcessKind::kBilling: return ServiceKind::kBilling;
    case ProcessKind::kWorld: return ServiceKind::kWorld;
    case ProcessKind::kZone: return ServiceKind::kZone;
    }
    core::fail("loại tiến trình");
}

} // namespace game::config
