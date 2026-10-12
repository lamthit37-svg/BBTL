#include "config/secrets.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <string>
#include <string_view>
#include <utility>

namespace game::config {
namespace {

using detail::Bag;
using detail::Cursor;
using detail::finish;
using detail::keep;
using detail::Node;
using detail::parse_text;

constexpr std::string_view kRoot[] = {"schema", "database"};
constexpr std::string_view kDatabase[] = {
    "postgres",
    "thienlong_auth",
    "thienlong_billing",
    "thienlong_store",
};
constexpr std::string_view kPassword[] = {"password"};

void read_password(Bag& bag, const Node* table, std::string& slot) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kPassword);
    keep(cursor.text("password", detail::kPasswordText), slot);
}

void read_database(Bag& bag, const Node* table, Secrets& secrets) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.unknown(kDatabase);
    read_password(bag, cursor.child("postgres"), secrets.postgres);
    read_password(bag, cursor.child("thienlong_auth"), secrets.auth);
    read_password(bag, cursor.child("thienlong_billing"), secrets.billing);
    read_password(bag, cursor.child("thienlong_store"), secrets.store);
}

[[nodiscard]] Secrets read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.unknown(kRoot);
    Secrets secrets;
    read_database(bag, cursor.child("database"), secrets);
    return secrets;
}

} // namespace

ReadResult<Secrets> read_secrets(std::string_view text) {
    const detail::Parsed parsed = parse_text(text);
    if (!parsed.issues.empty()) return std::unexpected(std::move(parsed.issues));
    Bag bag;
    return finish(read_sections(bag, parsed.root), bag);
}

} // namespace game::config
