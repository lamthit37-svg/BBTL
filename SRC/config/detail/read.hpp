#pragma once
// Con trỏ đọc một bảng Node thành giá trị đã kiểm: khoá lạ, thiếu khoá, sai kiểu, ngoài miền. Lỗi
// gom vào Bag kèm số dòng; bộ đọc đi hết tệp rồi mới trả, không dừng ở lỗi đầu.
// Mọi số nguyên của cấu hình nằm trong int32 (kIntMost): nơi dùng đổi sang kiểu hẹp hơn, hay sang
// std::chrono có đơn vị nhỏ hơn, mà không tràn. Lựa chọn trong chữ ký là enum, không phải bool.

#include "config/detail/node.hpp"
#include "config/detail/parse.hpp"
#include "config/issue.hpp"
#include "config/types.hpp"

#include <algorithm>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <limits>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::config::detail {

inline constexpr std::int64_t kIntMost = std::numeric_limits<std::int32_t>::max();
inline constexpr std::size_t kNameMost = 64;
inline constexpr std::size_t kPathMost = 512;
inline constexpr std::size_t kIdentMost = 63;
inline constexpr std::size_t kPasswordMost = 256;
inline constexpr std::size_t kHourMost = 24;

struct Bound {
    std::int64_t least = 0;
    std::int64_t most = kIntMost;
};

struct TextBound {
    std::size_t least = 0;
    std::size_t most = 0;
};

inline constexpr Bound kSchema{.least = 1, .most = 1};
// Số lượng phải dương.
inline constexpr Bound kCount{.least = 1, .most = kIntMost};
// Số lượng, số thứ tự hay thời lượng không âm.
inline constexpr Bound kAmount{.least = 0, .most = kIntMost};
inline constexpr Bound kHour{.least = 0, .most = 23};
inline constexpr Bound kPortNumber{.least = 1, .most = 65535};
inline constexpr TextBound kNameText{.least = 1, .most = kNameMost};
inline constexpr TextBound kVariantText{.least = 0, .most = kNameMost};
inline constexpr TextBound kPathText{.least = 1, .most = kPathMost};
inline constexpr TextBound kIdentText{.least = 1, .most = kIdentMost};
inline constexpr TextBound kPasswordText{.least = 0, .most = kPasswordMost};

enum class Presence : std::uint8_t { kRequired, kOptional };

enum class ListKind : std::uint8_t { kIpv4, kCidr };

// Một tên trong tập đóng và giá trị enum của nó.
template <typename Enum>
struct Choice {
    std::string_view name;
    Enum value;
};

using StringList = std::vector<std::string>;
using IntList = std::vector<std::int64_t>;
using KeyList = std::span<const std::string_view>;
// Các khối của một [[key]], theo thứ tự trong tệp.
using Rows = std::vector<const Node*>;

struct Bag {
    IssueList issues;
};

void add_issue(Bag& bag, std::size_t line, std::string message);

// Lấy mọi lỗi ra, xếp theo dòng rồi theo câu.
[[nodiscard]] IssueList take_issues(Bag& bag);

template <typename Value>
void keep(std::optional<Value> value, Value& slot) {
    if (!value) return;
    slot = std::move(*value);
}

class Cursor {
public:
    // bag và table phải sống lâu hơn con trỏ.
    Cursor(Bag& bag, const Node& table) noexcept;

    // Bảng chỉ được có các khoá này; khoá khác là "khoá lạ", nhóm khác là "nhóm lạ".
    void only(KeyList known);
    // Khoá schema của gốc tệp phải bằng 1.
    void schema();

    // Nhóm [key]; nullptr và một lỗi khi thiếu hoặc không phải nhóm.
    [[nodiscard]] const Node* child(std::string_view key);
    // Các khối [[key]], tối đa most khối. Khối không phải nhóm bị bỏ và ghi lỗi.
    [[nodiscard]] Rows rows(std::string_view key, Presence presence, std::size_t most);

    // Các hàm dưới trả rỗng và ghi đúng một lỗi khi khoá thiếu, sai kiểu hoặc ngoài miền.
    [[nodiscard]] std::optional<std::int64_t> bounded(std::string_view key, Bound bound);
    [[nodiscard]] std::optional<bool> flag(std::string_view key);
    [[nodiscard]] std::optional<std::string> text(std::string_view key, TextBound bound);
    // Tên database và role: chữ cái đầu, rồi chữ, số, `_` hoặc `-`.
    [[nodiscard]] std::optional<std::string> ident(std::string_view key);
    [[nodiscard]] std::optional<std::chrono::seconds> seconds(std::string_view key);
    [[nodiscard]] std::optional<std::chrono::milliseconds> millis(std::string_view key);
    [[nodiscard]] std::optional<Port> port(std::string_view key);
    // Cổng của một bên nghe đứng ở host: 1 tới 65535, hoặc 0 (hệ điều hành chọn) khi host là đúng
    // 127.0.0.1. host rỗng (khoá host đã hỏng) thì cổng 0 cũng bị từ chối.
    [[nodiscard]] std::optional<Port> listen_port(std::string_view key, const std::optional<Ipv4Address>& host);
    [[nodiscard]] std::optional<ProcessId> process_id(std::string_view key);
    [[nodiscard]] std::optional<MachineId> machine_id(std::string_view key);
    [[nodiscard]] std::optional<WorldId> world_id(std::string_view key);
    [[nodiscard]] std::optional<Ipv4Address> ipv4(std::string_view key);
    [[nodiscard]] std::optional<Endpoint> endpoint(std::string_view key);
    // Mảng địa chỉ IPv4 hoặc dải CIDR.
    [[nodiscard]] std::optional<StringList> addresses(std::string_view key, ListKind kind);
    // Mảng giờ trong ngày, 0 tới 23, không lặp.
    [[nodiscard]] std::optional<IntList> hours(std::string_view key);

    // Chuỗi thuộc một tập đóng; choices là mảng Choice<Enum>, trả giá trị ứng với tên.
    template <typename Choices>
    [[nodiscard]] auto choice(std::string_view key, const Choices& choices) {
        using Enum = decltype(std::ranges::begin(choices)->value);
        std::optional<Enum> value;
        const Node* node = required(key, NodeKind::kString);
        if (node == nullptr) return value;
        const std::string_view name = node->text;
        const auto found = std::ranges::find(choices, name, &Choice<Enum>::name);
        const bool is_known = found != std::ranges::end(choices);
        if (!is_known) reject_domain(key, node->line);
        if (is_known) value = found->value;
        return value;
    }

private:
    // Giá trị của khoá bắt buộc, đúng loại nút; không thì ghi lỗi và trả nullptr.
    [[nodiscard]] const Node* required(std::string_view key, NodeKind kind);
    void reject_domain(std::string_view key, std::size_t line);

    Bag* bag_ = nullptr;
    const Node* table_ = nullptr;
};

// Nhóm [database] chung của auth, billing và store.
void read_login(Bag& bag, const Node* table, DatabaseLogin& login);

template <typename Value>
using Sections = Value (*)(Bag&, const Node&);

// Khung chung của một bộ đọc: dịch chữ thành cây, cho sections đọc gốc, rồi trả giá trị hoặc mọi
// lỗi đã xếp theo dòng.
template <typename Value>
[[nodiscard]] ReadResult<Value> read_document(std::string_view text, Sections<Value> sections) {
    Parsed parsed = parse_text(text);
    if (!parsed.issues.empty()) return std::unexpected(std::move(parsed.issues));
    Bag bag;
    if (parsed.root.kind != NodeKind::kTable) add_issue(bag, 1, "tệp vượt trần cấu trúc");
    if (!bag.issues.empty()) return std::unexpected(take_issues(bag));
    Value value = sections(bag, parsed.root);
    if (!bag.issues.empty()) return std::unexpected(take_issues(bag));
    return value;
}

} // namespace game::config::detail
