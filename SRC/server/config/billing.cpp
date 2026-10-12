#include "config/billing.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::config {
namespace {

using detail::Bag;
using detail::Cursor;
using detail::keep;
using detail::ListKind;
using detail::Node;
using detail::Presence;

constexpr std::array<std::string_view, 9> kRoot{
    "schema", "database", "access", "limits", "points", "spend", "orders", "redeem", "provider"};
constexpr std::array<std::string_view, 1> kAccess{"allow"};
constexpr std::array<std::string_view, 1> kLimits{"max_clients"};
constexpr std::array<std::string_view, 2> kPoints{"ingot_per_point", "register_gift"};
constexpr std::array<std::string_view, 1> kSpend{"daily_ingot_cap"};
constexpr std::array<std::string_view, 2> kOrders{"pending_timeout_seconds", "reconcile_interval_seconds"};
constexpr std::array<std::string_view, 1> kRedeem{"attempts_per_hour"};
constexpr std::array<std::string_view, 4> kProvider{"key", "webhook_path", "secret_file", "enabled"};
constexpr std::size_t kProviderMost = 32;

void read_access(Bag& bag, const Node* table, Billing& billing) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kAccess);
    keep(cursor.addresses("allow", ListKind::kIpv4), billing.allow);
}

void read_limits(Bag& bag, const Node* table, Billing& billing) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kLimits);
    keep(cursor.bounded("max_clients", detail::kCount), billing.max_clients);
}

void read_points(Bag& bag, const Node* table, Billing& billing) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kPoints);
    keep(cursor.bounded("ingot_per_point", detail::kCount), billing.ingot_per_point);
    keep(cursor.bounded("register_gift", detail::kAmount), billing.register_gift);
}

void read_spend(Bag& bag, const Node* table, Billing& billing) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kSpend);
    keep(cursor.bounded("daily_ingot_cap", detail::kAmount), billing.daily_ingot_cap);
}

void read_orders(Bag& bag, const Node* table, Billing& billing) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kOrders);
    keep(cursor.seconds("pending_timeout_seconds"), billing.pending_timeout_seconds);
    keep(cursor.seconds("reconcile_interval_seconds"), billing.reconcile_interval_seconds);
}

void read_redeem(Bag& bag, const Node* table, Billing& billing) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kRedeem);
    keep(cursor.bounded("attempts_per_hour", detail::kAmount), billing.attempts_per_hour);
}

void read_provider(Bag& bag, const Node& table, std::vector<Provider>& out) {
    Cursor cursor{bag, table};
    cursor.only(kProvider);
    std::optional<std::string> key = cursor.text("key", detail::kNameText);
    std::optional<std::string> path = cursor.text("webhook_path", detail::kPathText);
    std::optional<std::string> secret = cursor.text("secret_file", detail::kPathText);
    const std::optional<bool> enabled = cursor.flag("enabled");
    const bool is_whole = key && path && secret && enabled;
    if (!is_whole) return;
    Provider provider;
    provider.line = table.line;
    provider.key = std::move(*key);
    provider.webhook_path = std::move(*path);
    provider.secret_file = std::move(*secret);
    provider.enabled = *enabled;
    out.push_back(std::move(provider));
}

[[nodiscard]] Billing read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Billing billing;
    read_login(bag, cursor.child("database"), billing.database);
    read_access(bag, cursor.child("access"), billing);
    read_limits(bag, cursor.child("limits"), billing);
    read_points(bag, cursor.child("points"), billing);
    read_spend(bag, cursor.child("spend"), billing);
    read_orders(bag, cursor.child("orders"), billing);
    read_redeem(bag, cursor.child("redeem"), billing);
    for (const Node* block : cursor.rows("provider", Presence::kOptional, kProviderMost)) {
        read_provider(bag, *block, billing.providers);
    }
    return billing;
}

} // namespace

ReadResult<Billing> read_billing(std::string_view text) {
    return detail::read_document<Billing>(text, read_sections);
}

} // namespace game::config
