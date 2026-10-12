#include "config/admin.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
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
using detail::Node;
using detail::Presence;

constexpr std::array<std::string_view, 4> kRoot{"schema", "listen", "token_file", "operator"};
constexpr std::array<std::string_view, 2> kOperator{"name", "level"};
constexpr std::size_t kOperatorMost = 64;

void read_operator(Bag& bag, const Node& table, std::vector<Operator>& out) {
    Cursor cursor{bag, table};
    cursor.only(kOperator);
    std::optional<std::string> name = cursor.text("name", detail::kNameText);
    const std::optional<std::int64_t> level = cursor.bounded("level", detail::kAmount);
    if (!name || !level) return;
    Operator added;
    added.line = table.line;
    added.name = std::move(*name);
    added.level = *level;
    out.push_back(std::move(added));
}

[[nodiscard]] Admin read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Admin admin;
    keep(cursor.endpoint("listen"), admin.listen);
    keep(cursor.text("token_file", detail::kPathText), admin.token_file);
    for (const Node* block : cursor.rows("operator", Presence::kOptional, kOperatorMost)) {
        read_operator(bag, *block, admin.operators);
    }
    return admin;
}

} // namespace

ReadResult<Admin> read_admin(std::string_view text) {
    return detail::read_document<Admin>(text, read_sections);
}

} // namespace game::config
