/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/config/gate.cpp
 *  PHÂN HỆ   : Server / Config / Gate
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Đọc gate.toml: kiểm khoá lạ, miền giá trị, trần kết nối, lọc địa chỉ và
 *    hai khoá tuỳ chọn của bình chứa Move.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "config/gate.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <optional>
#include <string_view>

namespace game::config {
namespace {

using detail::Bag;
using detail::Cursor;
using detail::keep;
using detail::ListKind;
using detail::Node;

constexpr std::array<std::string_view, 8> kRoot{
    "schema", "identity_key_file", "trusted_proxies", "listen", "limits", "client", "ip_filter", "resume"};
constexpr std::array<std::string_view, 2> kListen{"game", "auth"};
constexpr std::array<std::string_view, 9> kLimits{"max_connections", "per_ip_connections",
    "handshake_timeout_ms", "idle_timeout_ms", "client_frame_bytes", "messages_per_second",
    "per_ip_prefix", "moves_per_second", "move_burst"};
constexpr std::array<std::string_view, 2> kResume{"bind_to_ip", "grace_ms"};
// Dải gom: /16 tới /32. Rộng hơn /16 thì một nhà mạng NAT chặn cả vùng.
constexpr detail::Bound kPrefix{.least = 16, .most = 32};
// Trần 5 phút cho cửa sổ token Resume còn hiệu lực.
constexpr detail::Bound kGraceMs{.least = 0, .most = 300000};
constexpr std::array<std::string_view, 2> kClient{"min_version", "allowed_builds"};
constexpr detail::Bound kBuildId{.least = 1, .most = 4294967295};
constexpr std::array<std::string_view, 2> kFilter{"allow", "deny"};

void read_listen(Bag& bag, const Node* table, GateListen& listen) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kListen);
    keep(cursor.endpoint("game"), listen.game);
    keep(cursor.endpoint("auth"), listen.auth);
}

// Ba khoá tuỳ chọn của [limits]: thiếu thì giữ mặc định của GateLimits.
void read_optional_limits(Cursor& cursor, GateLimits& limits) {
    if (cursor.has("per_ip_prefix")) {
        const std::optional<std::int64_t> prefix = cursor.bounded("per_ip_prefix", kPrefix);
        keep(prefix, limits.per_ip_prefix);
    }
    if (cursor.has("moves_per_second")) {
        const std::optional<std::int64_t> rate = cursor.bounded("moves_per_second", detail::kCount);
        keep(rate, limits.moves_per_second);
    }
    if (cursor.has("move_burst")) {
        const std::optional<std::int64_t> burst = cursor.bounded("move_burst", detail::kCount);
        keep(burst, limits.move_burst);
    }
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
    read_optional_limits(cursor, limits);
}

void read_resume(Bag& bag, const Node* table, GateResume& resume) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kResume);
    if (cursor.has("bind_to_ip")) keep(cursor.flag("bind_to_ip"), resume.bind_to_ip);
    if (cursor.has("grace_ms")) {
        const std::optional<std::int64_t> ms = cursor.bounded("grace_ms", kGraceMs);
        if (ms) resume.grace_ms = std::chrono::milliseconds{*ms};
    }
}

void read_client(Bag& bag, const Node* table, GateClient& client) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kClient);
    keep(cursor.bounded("min_version", detail::kCount), client.min_version);
    if (!cursor.has("allowed_builds")) return;
    keep(cursor.integers("allowed_builds", kBuildId, 32), client.allowed_builds);
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
    if (cursor.has("resume")) read_resume(bag, cursor.child("resume"), gate.resume);
    return gate;
}

} // namespace

ReadResult<Gate> read_gate(std::string_view text) {
    return detail::read_document<Gate>(text, read_sections);
}

} // namespace game::config
