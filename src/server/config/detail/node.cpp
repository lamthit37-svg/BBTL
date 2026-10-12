#include "config/detail/node.hpp"

#include "core/check.hpp"

#include <algorithm>
#include <cstddef>
#include <string_view>

namespace game::config::detail {

std::size_t field_count(const Node& table) noexcept {
    return table.keys.size();
}

FieldRef field_at(const Node& table, std::size_t index) noexcept {
    core::check(index < table.keys.size(), "chỉ số khoá ngoài bảng");
    core::check(table.keys.size() == table.items.size(), "khoá và giá trị lệch số lượng");
    core::check(table.keys.size() == table.key_lines.size(), "khoá và dòng lệch số lượng");
    FieldRef field;
    field.key = table.keys[index];
    field.line = table.key_lines[index];
    field.node = &table.items[index];
    return field;
}

const Node* find_field(const Node& table, std::string_view key) noexcept {
    const auto found = std::ranges::find(table.keys, key);
    if (found == table.keys.end()) return nullptr;
    const auto index = static_cast<std::size_t>(found - table.keys.begin());
    return field_at(table, index).node;
}

bool is_group(const Node& node) noexcept {
    if (node.kind == NodeKind::kTable) return true;
    if (node.kind != NodeKind::kArray || node.items.empty()) return false;
    return node.items.front().kind == NodeKind::kTable;
}

} // namespace game::config::detail
