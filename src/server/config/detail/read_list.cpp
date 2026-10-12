// Phần đọc mảng của Cursor: các khối [[...]], mảng địa chỉ, mảng giờ. Một phần tử hỏng không làm
// bỏ sót lỗi của phần tử sau: mỗi phần tử ghi lỗi của riêng nó.
#include "config/detail/read.hpp"

#include "config/detail/node.hpp"
#include "config/types.hpp"

#include <algorithm>
#include <cstddef>
#include <format>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::config::detail {
namespace {

// Mảng đang đọc và nơi ghi lỗi của từng phần tử.
struct ItemScan {
    Bag* bag = nullptr;
    std::string_view key;
    bool is_valid = true;
};

void reject_item(ItemScan& scan, const Node& item, std::string message) {
    add_issue(*scan.bag, item.line, std::move(message));
    scan.is_valid = false;
}

void take_row(ItemScan& scan, const Node& item, Rows& rows) {
    if (item.kind == NodeKind::kTable) {
        rows.push_back(&item);
        return;
    }
    reject_item(scan, item, std::format("phần tử của {} sai kiểu", scan.key));
}

[[nodiscard]] bool is_address(std::string_view text, ListKind kind) {
    if (kind == ListKind::kIpv4) return Ipv4Address::parse(text).has_value();
    return parse_cidr(text).has_value();
}

void take_address(ItemScan& scan, const Node& item, ListKind kind, StringList& values) {
    if (item.kind != NodeKind::kString) {
        reject_item(scan, item, std::format("phần tử của {} sai kiểu", scan.key));
        return;
    }
    if (!is_address(item.text, kind)) {
        reject_item(scan, item, std::format("khoá {} ngoài miền", scan.key));
        return;
    }
    values.push_back(item.text);
}

void take_hour(ItemScan& scan, const Node& item, IntList& values) {
    if (item.kind != NodeKind::kInteger) {
        reject_item(scan, item, std::format("phần tử của {} sai kiểu", scan.key));
        return;
    }
    const bool is_hour = item.integer >= kHour.least && item.integer <= kHour.most;
    if (!is_hour) {
        reject_item(scan, item, std::format("khoá {} ngoài miền", scan.key));
        return;
    }
    values.push_back(item.integer);
}

[[nodiscard]] bool has_repeat(IntList values) {
    std::ranges::sort(values);
    return std::ranges::adjacent_find(values) != values.end();
}

} // namespace

Rows Cursor::rows(std::string_view key, Presence presence, std::size_t most) {
    Rows rows;
    const bool is_absent = find_field(*table_, key) == nullptr;
    if (is_absent && presence == Presence::kOptional) return rows;
    const Node* node = required(key, NodeKind::kArray);
    if (node == nullptr) return rows;
    if (node->items.size() > most) {
        add_issue(*bag_, node->line, std::format("mảng {} vượt trần", key));
        return rows;
    }
    ItemScan scan{.bag = bag_, .key = key};
    for (const Node& item : node->items) {
        take_row(scan, item, rows);
    }
    return rows;
}

std::optional<StringList> Cursor::addresses(std::string_view key, ListKind kind) {
    const Node* node = required(key, NodeKind::kArray);
    if (node == nullptr) return std::nullopt;
    StringList values;
    ItemScan scan{.bag = bag_, .key = key};
    for (const Node& item : node->items) {
        take_address(scan, item, kind, values);
    }
    if (!scan.is_valid) return std::nullopt;
    return values;
}

std::optional<IntList> Cursor::integers(std::string_view key, Bound bound, std::size_t most) {
    const Node* node = required(key, NodeKind::kArray);
    if (node == nullptr) return std::nullopt;
    if (node->items.empty() || node->items.size() > most) {
        add_issue(*bag_, node->line, std::format("mảng {} rỗng hoặc vượt trần", key));
        return std::nullopt;
    }
    IntList values;
    ItemScan scan{.bag = bag_, .key = key};
    for (const Node& item : node->items) {
        if (item.kind != NodeKind::kInteger) {
            reject_item(scan, item, std::format("phần tử của {} sai kiểu", key));
            continue;
        }
        if (item.integer < bound.least || item.integer > bound.most) {
            reject_item(scan, item, std::format("phần tử của {} ngoài miền", key));
            continue;
        }
        values.push_back(item.integer);
    }
    const bool is_repeated = scan.is_valid && has_repeat(values);
    if (is_repeated) add_issue(*bag_, node->line, std::format("khoá {} có giá trị lặp", key));
    if (!scan.is_valid || is_repeated) return std::nullopt;
    return values;
}

std::optional<IntList> Cursor::hours(std::string_view key) {
    const Node* node = required(key, NodeKind::kArray);
    if (node == nullptr) return std::nullopt;
    if (node->items.size() > kHourMost) {
        add_issue(*bag_, node->line, std::format("mảng {} vượt trần", key));
        return std::nullopt;
    }
    IntList values;
    ItemScan scan{.bag = bag_, .key = key};
    for (const Node& item : node->items) {
        take_hour(scan, item, values);
    }
    const bool is_repeated = has_repeat(values);
    if (is_repeated) add_issue(*bag_, node->line, std::format("khoá {} có giờ lặp", key));
    if (!scan.is_valid || is_repeated) return std::nullopt;
    return values;
}

} // namespace game::config::detail
