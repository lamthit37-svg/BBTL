#include "client/session/gates.hpp"

#include "net/net.hpp"
#include "secure/secure.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::client::session {
namespace {

constexpr std::size_t kHexChars = secure::kPublicBytes * 2;

[[nodiscard]] std::optional<std::uint8_t> nibble(char letter) noexcept {
    if (letter >= '0' && letter <= '9') return static_cast<std::uint8_t>(letter - '0');
    if (letter >= 'a' && letter <= 'f') return static_cast<std::uint8_t>(letter - 'a' + 10);
    if (letter >= 'A' && letter <= 'F') return static_cast<std::uint8_t>(letter - 'A' + 10);
    return std::nullopt;
}

[[nodiscard]] std::optional<net::Endpoint> endpoint_of(std::string_view host, std::uint32_t port) {
    const std::string text = std::format("{}:{}", host, port);
    const net::NetResult<net::Endpoint> parsed = net::parse_endpoint(text, net::ZeroPort::kRefuse);
    if (!parsed) return std::nullopt;
    return *parsed;
}

// Một dòng bảng thành Gate, hoặc câu lỗi (chưa kèm số dòng).
[[nodiscard]] std::expected<Gate, std::string> gate_of(table::RowReader& row) {
    Gate gate;
    gate.area = std::string{row.text("area")};
    gate.server = std::string{row.text("server")};
    const std::string_view host = row.text("host");
    const std::uint32_t game_port = row.number("game_port", 1, 65535);
    const std::uint32_t auth_port = row.number("auth_port", 1, 65535);
    const std::string_view key = row.text("key");
    if (row.error()) return std::unexpected(*row.error());
    if (gate.server.empty()) return std::unexpected("tên máy chủ rỗng");
    const std::optional<net::Endpoint> game = endpoint_of(host, game_port);
    const std::optional<net::Endpoint> auth = endpoint_of(host, auth_port);
    if (!game || !auth) return std::unexpected(std::format("địa chỉ \"{}\" không phải IPv4 dạng a.b.c.d", host));
    if (game->port == auth->port) return std::unexpected("cổng game trùng cổng xác thực");
    const std::optional<secure::PublicKey> pinned = decode_key(key);
    if (!pinned) return std::unexpected("khoá công khai phải là 64 chữ số hex");
    gate.game = *game;
    gate.auth = *auth;
    gate.key = *pinned;
    return gate;
}

} // namespace

std::optional<secure::PublicKey> decode_key(std::string_view hex) noexcept {
    if (hex.size() != kHexChars) return std::nullopt;
    secure::PublicKey key;
    for (std::size_t at = 0; at < secure::kPublicBytes; ++at) {
        const std::optional<std::uint8_t> high = nibble(hex[at * 2]);
        const std::optional<std::uint8_t> low = nibble(hex[(at * 2) + 1]);
        if (!high || !low) return std::nullopt;
        key.bytes.at(at) = static_cast<std::byte>((*high << 4U) | *low);
    }
    return key;
}

GateBookResult read_gate_book(std::string_view text) {
    table::TsvResult parsed = table::parse_tsv(text);
    if (!parsed) return std::unexpected(std::move(parsed.error()));
    const table::Tsv& rows = *parsed;
    if (rows.rows.size() > kGateCap) {
        return std::unexpected(std::format("bảng có {} dòng, quá trần {}", rows.rows.size(), kGateCap));
    }
    GateBook book;
    book.gates.reserve(rows.rows.size());
    for (std::size_t at = 0; at < rows.rows.size(); ++at) {
        table::RowReader row{rows, at};
        std::expected<Gate, std::string> gate = gate_of(row);
        if (!gate) return std::unexpected(std::format("dòng {}: {}", rows.lines.at(at), gate.error()));
        if (find_gate(book, gate->area, gate->server) != nullptr) {
            return std::unexpected(std::format("dòng {}: máy chủ \"{}\" của vùng \"{}\" bị lặp", rows.lines.at(at),
                gate->server, gate->area));
        }
        book.gates.push_back(std::move(*gate));
    }
    return book;
}

const Gate* find_gate(const GateBook& book, std::string_view area, std::string_view server) noexcept {
    const auto found = std::ranges::find_if(
        book.gates, [&](const Gate& gate) { return gate.area == area && gate.server == server; });
    return found == book.gates.end() ? nullptr : &*found;
}

} // namespace game::client::session
