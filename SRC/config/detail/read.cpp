// Phần đọc giá trị đơn của Cursor. Mảng và các khối [[...]] ở read_list.cpp.
#include "config/detail/read.hpp"

#include "config/detail/node.hpp"
#include "config/issue.hpp"
#include "config/types.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::config::detail {
namespace {

[[nodiscard]] bool is_control(char character) noexcept {
    const auto byte = static_cast<unsigned char>(character);
    return byte < 0x20 || byte == 0x7F;
}

// Trong miền dài ngắn và không có ký tự điều khiển: giá trị này sẽ đi vào log và đường dẫn.
[[nodiscard]] bool fits_text(std::string_view text, TextBound bound) noexcept {
    if (text.size() < bound.least || text.size() > bound.most) return false;
    return std::ranges::none_of(text, is_control);
}

[[nodiscard]] bool is_letter(char character) noexcept {
    const bool is_lower = character >= 'a' && character <= 'z';
    return is_lower || (character >= 'A' && character <= 'Z');
}

[[nodiscard]] bool is_ident_char(char character) noexcept {
    const bool is_digit = character >= '0' && character <= '9';
    return is_letter(character) || is_digit || character == '_' || character == '-';
}

[[nodiscard]] bool is_ident(std::string_view text) noexcept {
    const bool has_size = !text.empty() && text.size() <= kIdentMost;
    if (!has_size || !is_letter(text.front())) return false;
    return std::ranges::all_of(text, is_ident_char);
}

[[nodiscard]] bool issue_less(const Issue& left, const Issue& right) noexcept {
    if (left.line != right.line) return left.line < right.line;
    return left.message < right.message;
}

// Nút vượt trần của bộ dịch: mảng quá nhiều phần tử, còn lại là chuỗi quá dài.
[[nodiscard]] std::string oversize_message(std::string_view key, NodeKind wanted) {
    if (wanted == NodeKind::kArray) return std::format("mảng {} vượt trần", key);
    return std::format("khoá {} ngoài miền", key);
}

void reject_field(Bag& bag, const FieldRef& field, KeyList known) {
    if (std::ranges::contains(known, field.key)) return;
    const std::string_view what = is_group(*field.node) ? "nhóm lạ" : "khoá lạ";
    add_issue(bag, field.line, std::format("{} {}", what, field.key));
}

} // namespace

void add_issue(Bag& bag, std::size_t line, std::string message) {
    bag.issues.push_back(Issue{.line = line, .message = std::move(message)});
}

IssueList take_issues(Bag& bag) {
    IssueList issues = std::exchange(bag.issues, {});
    std::ranges::sort(issues, issue_less);
    return issues;
}

Cursor::Cursor(Bag& bag, const Node& table) noexcept : bag_(&bag), table_(&table) {}

void Cursor::only(KeyList known) {
    const std::size_t count = field_count(*table_);
    for (std::size_t index = 0; index < count; ++index) {
        reject_field(*bag_, field_at(*table_, index), known);
    }
}

void Cursor::schema() {
    static_cast<void>(bounded("schema", kSchema));
}

const Node* Cursor::required(std::string_view key, NodeKind kind) {
    const Node* node = find_field(*table_, key);
    if (node == nullptr) {
        add_issue(*bag_, table_->line, std::format("thiếu khoá {}", key));
        return nullptr;
    }
    if (node->kind == kind) return node;
    const bool is_oversize = node->kind == NodeKind::kOversize;
    std::string message = std::format("khoá {} sai kiểu", key);
    if (is_oversize) message = oversize_message(key, kind);
    add_issue(*bag_, node->line, std::move(message));
    return nullptr;
}

void Cursor::reject_domain(std::string_view key, std::size_t line) {
    add_issue(*bag_, line, std::format("khoá {} ngoài miền", key));
}

const Node* Cursor::child(std::string_view key) {
    return required(key, NodeKind::kTable);
}

std::optional<std::int64_t> Cursor::bounded(std::string_view key, Bound bound) {
    const Node* node = required(key, NodeKind::kInteger);
    if (node == nullptr) return std::nullopt;
    const bool is_inside = node->integer >= bound.least && node->integer <= bound.most;
    if (is_inside) return node->integer;
    reject_domain(key, node->line);
    return std::nullopt;
}

std::optional<bool> Cursor::flag(std::string_view key) {
    const Node* node = required(key, NodeKind::kBoolean);
    if (node == nullptr) return std::nullopt;
    return node->flag;
}

std::optional<std::string> Cursor::text(std::string_view key, TextBound bound) {
    const Node* node = required(key, NodeKind::kString);
    if (node == nullptr) return std::nullopt;
    if (fits_text(node->text, bound)) return node->text;
    reject_domain(key, node->line);
    return std::nullopt;
}

std::optional<std::string> Cursor::ident(std::string_view key) {
    const Node* node = required(key, NodeKind::kString);
    if (node == nullptr) return std::nullopt;
    if (is_ident(node->text)) return node->text;
    reject_domain(key, node->line);
    return std::nullopt;
}

std::optional<std::chrono::seconds> Cursor::seconds(std::string_view key) {
    const std::optional<std::int64_t> value = bounded(key, kAmount);
    if (!value) return std::nullopt;
    return std::chrono::seconds{*value};
}

std::optional<std::chrono::milliseconds> Cursor::millis(std::string_view key) {
    const std::optional<std::int64_t> value = bounded(key, kAmount);
    if (!value) return std::nullopt;
    return std::chrono::milliseconds{*value};
}

std::optional<Port> Cursor::port(std::string_view key) {
    const std::optional<std::int64_t> value = bounded(key, kPortNumber);
    if (!value) return std::nullopt;
    return Port::parse(*value);
}

std::optional<Port> Cursor::listen_port(std::string_view key, const std::optional<Ipv4Address>& host) {
    const Node* node = required(key, NodeKind::kInteger);
    if (node == nullptr) return std::nullopt;
    const std::optional<Port> port = Port::parse(node->integer);
    if (port) return port;
    const bool is_any = node->integer == 0 && host && is_loopback(*host);
    if (is_any) return Port::any();
    reject_domain(key, node->line);
    return std::nullopt;
}

std::optional<ProcessId> Cursor::process_id(std::string_view key) {
    const std::optional<std::int64_t> value = bounded(key, kAmount);
    if (!value) return std::nullopt;
    return ProcessId::parse(*value);
}

std::optional<MachineId> Cursor::machine_id(std::string_view key) {
    const std::optional<std::int64_t> value = bounded(key, kAmount);
    if (!value) return std::nullopt;
    return MachineId::parse(*value);
}

std::optional<WorldId> Cursor::world_id(std::string_view key) {
    const std::optional<std::int64_t> value = bounded(key, kCount);
    if (!value) return std::nullopt;
    return WorldId::parse(*value);
}

std::optional<Ipv4Address> Cursor::ipv4(std::string_view key) {
    const Node* node = required(key, NodeKind::kString);
    if (node == nullptr) return std::nullopt;
    std::optional<Ipv4Address> address = Ipv4Address::parse(node->text);
    if (!address) reject_domain(key, node->line);
    return address;
}

std::optional<Endpoint> Cursor::endpoint(std::string_view key) {
    const Node* node = required(key, NodeKind::kString);
    if (node == nullptr) return std::nullopt;
    std::optional<Endpoint> endpoint = Endpoint::parse(node->text);
    if (!endpoint) reject_domain(key, node->line);
    return endpoint;
}

void read_login(Bag& bag, const Node* table, DatabaseLogin& login) {
    if (table == nullptr) return;
    constexpr std::array<std::string_view, 3> kKeys{"name", "user", "pool"};
    Cursor cursor{bag, *table};
    cursor.only(kKeys);
    keep(cursor.ident("name"), login.name);
    keep(cursor.ident("user"), login.user);
    keep(cursor.bounded("pool", kCount), login.pool);
}

} // namespace game::config::detail
