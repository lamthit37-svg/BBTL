#include "config/gate.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <string_view>

namespace game::config {
namespace {

using detail::Bag;
using detail::Cursor;
using detail::keep;
using detail::ListKind;
using detail::Node;

constexpr std::array<std::string_view, 7> kRoot{
    "schema", "identity_key_file", "trusted_proxies", "listen", "limits", "client", "ip_filter"};
constexpr std::array<std::string_view, 2> kListen{"game", "auth"};
constexpr std::array<std::string_view, 6> kLimits{"max_connections", "per_ip_connections", "handshake_timeout_ms",
    "idle_timeout_ms", "client_frame_bytes", "messages_per_second"};
constexpr std::array<std::string_view, 1> kClient{"min_version"};
constexpr std::array<std::string_view, 2> kFilter{"allow", "deny"};

void read_listen(Bag& bag, const Node* table, GateListen& listen) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kListen);
    keep(cursor.endpoint("game"), listen.game);
    keep(cursor.endpoint("auth"), listen.auth);
}

void read_limits(Bag& bag, const Node* table, GateLimits& limits) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kLimits);
    keep(cursor.bounded("max_connections", detail::kCount), limits.max_connections);
    keep(cursor.bounded("per_ip_connections", detail::kCount), limits.per_ip_connections);
    keep(cursor.millis("handshake_timeout_ms"), limits.handshake_timeout_ms);
    keep(cursor.millis("idle_timeout_ms"), limits.idle_timeout_ms);
    keep(cursor.bounded("client_frame_bytes", detail::kCount), limits.client_frame_bytes);
    keep(cursor.bounded("messages_per_second", detail::kCount), limits.messages_per_second);
}

void read_client(Bag& bag, const Node* table, GateClient& client) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kClient);
    keep(cursor.bounded("min_version", detail::kCount), client.min_version);
}

void read_filter(Bag& bag, const Node* table, GateIpFilter& filter) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kFilter);
    keep(cursor.addresses("allow", ListKind::kCidr), filter.allow);
    keep(cursor.addresses("deny", ListKind::kCidr), filter.deny);
}

[[nodiscard]] Gate read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Gate gate;
    keep(cursor.text("identity_key_file", detail::kPathText), gate.identity_key_file);
    keep(cursor.addresses("trusted_proxies", ListKind::kIpv4), gate.trusted_proxies);
    read_listen(bag, cursor.child("listen"), gate.listen);
    read_limits(bag, cursor.child("limits"), gate.limits);
    read_client(bag, cursor.child("client"), gate.client);
    read_filter(bag, cursor.child("ip_filter"), gate.ip_filter);
    return gate;
}

} // namespace

ReadResult<Gate> read_gate(std::string_view text) {
    return detail::read_document<Gate>(text, read_sections);
}

} // namespace game::config
