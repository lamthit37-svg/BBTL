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
using detail::keep;
using detail::Node;

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
    cursor.only(kPassword);
    keep(cursor.text("password", detail::kPasswordText), slot);
}

void read_database(Bag& bag, const Node* table, Secrets& secrets) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kDatabase);
    read_password(bag, cursor.child("postgres"), secrets.postgres);
    read_password(bag, cursor.child("thienlong_auth"), secrets.auth);
    read_password(bag, cursor.child("thienlong_billing"), secrets.billing);
    read_password(bag, cursor.child("thienlong_store"), secrets.store);
}

[[nodiscard]] Secrets read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Secrets secrets;
    read_database(bag, cursor.child("database"), secrets);
    return secrets;
}

} // namespace

ReadResult<Secrets> read_secrets(std::string_view text) {
    return detail::read_document<Secrets>(text, read_sections);
}

} // namespace game::config
