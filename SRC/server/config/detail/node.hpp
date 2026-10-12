#pragma once
// Cây tài liệu trung gian giữa thư viện TOML và các bộ đọc: bộ đọc không thấy kiểu toml:: nào.
// Các trần ở đây chặn cấp phát theo số liệu của tệp; giá trị vượt trần thành nút kOversize.

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::config::detail {

inline constexpr std::size_t kMaxDocumentBytes = 1048576;
inline constexpr std::size_t kMaxTextBytes = 4096;
inline constexpr std::size_t kMaxKeyBytes = 128;
inline constexpr std::size_t kMaxArrayItems = 256;
inline constexpr std::size_t kMaxDepth = 8;

enum class NodeKind : std::uint8_t {
    kString,
    kInteger,
    kBoolean,
    kFloat,
    kArray,
    kTable,
    // Ngày, giờ và mọi kiểu TOML mà cấu hình của dự án không dùng.
    kOther,
    kOversize,
};

// Một nút. Mảng giữ phần tử trong items. Bảng giữ khoá, dòng của khoá và giá trị ở ba mảng song
// song, cùng thứ tự với tệp. Chỉ move: chép một nút là chép cả cây con, không chỗ nào cần.
struct Node {
    Node() = default;
    ~Node() = default;
    Node(const Node&) = delete;
    Node& operator=(const Node&) = delete;
    Node(Node&&) noexcept = default;
    Node& operator=(Node&&) noexcept = default;

    NodeKind kind = NodeKind::kOther;
    std::size_t line = 1;
    std::string text;
    std::int64_t integer = 0;
    bool flag = false;
    std::vector<Node> items;
    std::vector<std::string> keys;
    std::vector<std::size_t> key_lines;
};

struct FieldRef {
    std::string_view key;
    std::size_t line = 1;
    const Node* node = nullptr;
};

[[nodiscard]] std::size_t field_count(const Node& table) noexcept;

// Khoá thứ index của bảng, theo thứ tự trong tệp.
[[nodiscard]] FieldRef field_at(const Node& table, std::size_t index) noexcept;

// Giá trị của khoá; nullptr khi bảng không có khoá đó.
[[nodiscard]] const Node* find_field(const Node& table, std::string_view key) noexcept;

// Nhóm [x] hoặc mảng nhóm [[x]], để câu lỗi gọi nó là "nhóm" thay vì "khoá".
[[nodiscard]] bool is_group(const Node& node) noexcept;

} // namespace game::config::detail
