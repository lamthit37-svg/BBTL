// Dịch văn bản TOML thành cây Node. Tệp duy nhất của dự án include thư viện toml++.
// Thư viện dùng ở dạng không exception và header-only, không nối target của vcpkg: bản đã dịch của
// vcpkg bật exception (AGENTS.md mục 11). Lỗi cú pháp, khoá lặp, nhóm lặp, số vượt int64 và UTF-8
// hỏng đều do thư viện bắt và về đây thành một lỗi có số dòng.
#include "config/detail/parse.hpp"

#include "config/detail/node.hpp"
#include "config/issue.hpp"

// Hai macro là cách thư viện nhận cấu hình: phải khai trước khi include nó.
// NOLINTBEGIN(cppcoreguidelines-macro-usage)
#define TOML_EXCEPTIONS 0
#define TOML_HEADER_ONLY 1
// NOLINTEND(cppcoreguidelines-macro-usage)

// Thư viện chỉ cho include tệp ô toml.hpp, nên mọi kiểu toml:: bên dưới bị coi là thiếu include.
// NOLINTBEGIN(misc-include-cleaner)
#include <toml++/toml.hpp>

#include <cstddef>
#include <cstdint>
#include <format>
#include <string>
#include <string_view>
#include <utility>

namespace game::config::detail {
namespace {

// Thư viện đánh số dòng từ 1; 0 là "không biết", coi như dòng đầu.
[[nodiscard]] std::size_t line_of(const toml::source_region& source) noexcept {
    const std::uint32_t line = source.begin.line;
    return line == 0 ? 1 : line;
}

[[nodiscard]] Node oversize_at(std::size_t line) {
    Node node;
    node.kind = NodeKind::kOversize;
    node.line = line;
    return node;
}

void fill_text(Node& out, std::string_view text) {
    out.kind = text.size() > kMaxTextBytes ? NodeKind::kOversize : NodeKind::kString;
    if (out.kind == NodeKind::kString) out.text = text;
}

void fill_integer(Node& out, std::int64_t value) noexcept {
    out.kind = NodeKind::kInteger;
    out.integer = value;
}

void fill_flag(Node& out, bool value) noexcept {
    out.kind = NodeKind::kBoolean;
    out.flag = value;
}

[[nodiscard]] Node convert_scalar(const toml::node& node) {
    Node out;
    out.line = line_of(node.source());
    if (const auto* text = node.as_string()) fill_text(out, text->get());
    if (const auto* number = node.as_integer()) fill_integer(out, number->get());
    if (const auto* flag = node.as_boolean()) fill_flag(out, flag->get());
    if (node.is_floating_point()) out.kind = NodeKind::kFloat;
    return out;
}

// Ba hàm dưới gọi lẫn nhau theo hình cây của tệp; độ sâu có trần kMaxDepth nên ngăn xếp có trần.
// NOLINTBEGIN(misc-no-recursion)
[[nodiscard]] Node convert_node(const toml::node& node, std::size_t depth);

void append_field(Node& table, const toml::key& key, const toml::node& value, std::size_t depth) {
    const std::string_view name = key.str();
    const std::size_t line = line_of(key.source());
    const bool is_long = name.size() > kMaxKeyBytes;
    table.key_lines.push_back(line);
    table.keys.emplace_back(is_long ? std::string_view{} : name);
    table.items.push_back(is_long ? oversize_at(line) : convert_node(value, depth + 1));
}

[[nodiscard]] Node convert_array(const toml::array& array, std::size_t depth) {
    const std::size_t line = line_of(array.source());
    if (depth > kMaxDepth || array.size() > kMaxArrayItems) return oversize_at(line);
    Node node;
    node.kind = NodeKind::kArray;
    node.line = line;
    node.items.reserve(array.size());
    for (const toml::node& child : array) {
        node.items.push_back(convert_node(child, depth + 1));
    }
    return node;
}

[[nodiscard]] Node convert_table(const toml::table& table, std::size_t depth) {
    const std::size_t line = line_of(table.source());
    if (depth > kMaxDepth || table.size() > kMaxArrayItems) return oversize_at(line);
    Node node;
    node.kind = NodeKind::kTable;
    node.line = line;
    for (const auto& [key, value] : table) {
        append_field(node, key, value, depth);
    }
    return node;
}

Node convert_node(const toml::node& node, std::size_t depth) {
    if (const toml::table* table = node.as_table()) return convert_table(*table, depth);
    if (const toml::array* array = node.as_array()) return convert_array(*array, depth);
    return convert_scalar(node);
}
// NOLINTEND(misc-no-recursion)

[[nodiscard]] Parsed syntax_error(const toml::parse_error& error) {
    Parsed parsed;
    Issue issue;
    issue.line = line_of(error.source());
    issue.message = std::format("lỗi cú pháp: {}", error.description());
    parsed.issues.push_back(std::move(issue));
    return parsed;
}

} // namespace

Parsed parse_text(std::string_view text) {
    Parsed parsed;
    if (text.size() > kMaxDocumentBytes) {
        parsed.issues.push_back(Issue{.line = 1, .message = "tệp vượt trần 1048576 byte"});
        return parsed;
    }
    const toml::parse_result result = toml::parse(text);
    if (!result) return syntax_error(result.error());
    parsed.root = convert_table(result.table(), 0);
    return parsed;
}

} // namespace game::config::detail
// NOLINTEND(misc-include-cleaner)
