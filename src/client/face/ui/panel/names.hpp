// Tên cửa sổ đánh số dựng lúc biên dịch. Deck giữ string_view của tên tới hết khung, nên tên dựng
// bằng định dạng lúc chạy không dùng được; bảng ở đây có chuỗi nằm trong chính hằng.
#pragma once

#include <array>
#include <cstddef>
#include <string_view>

namespace game::ui::panel {

template <std::size_t Count>
struct NameTable {
    static constexpr std::size_t kWidth = 48;
    std::array<std::array<char, kWidth>, Count> text{};
    std::array<std::size_t, Count> size{};

    [[nodiscard]] constexpr std::string_view at(std::size_t index) const noexcept {
        return std::string_view(text.at(index).data(), size.at(index));
    }
};

// Phần chữ quanh số thứ tự của một dãy tên: "<prefix><số><suffix>".
struct NameParts {
    std::string_view prefix;
    std::string_view suffix;
};

namespace detail {

// Ghi chữ rồi số thập phân của value vào slot từ vị trí written; trả vị trí mới.
// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): vị trí ghi và giá trị khác vai trò, ba chỗ gọi nêu rõ (DD-08)
[[nodiscard]] constexpr std::size_t write_number(std::array<char, 48>& slot, std::size_t written, std::size_t value) {
    std::array<char, 8> digits{};
    std::size_t used = 0;
    for (std::size_t rest = value; rest > 0; rest /= 10) digits.at(used++) = static_cast<char>('0' + (rest % 10));
    while (used > 0) slot.at(written++) = digits.at(--used);
    return written;
}

[[nodiscard]] constexpr std::size_t write_text(std::array<char, 48>& slot, std::size_t written, std::string_view text) {
    for (const char letter : text) slot.at(written++) = letter;
    return written;
}

} // namespace detail

// "<prefix>1<suffix>" tới "<prefix>Count<suffix>".
template <std::size_t Count>
[[nodiscard]] consteval NameTable<Count> numbered(NameParts parts) {
    NameTable<Count> table;
    for (std::size_t index = 0; index < Count; ++index) {
        std::array<char, NameTable<Count>::kWidth>& slot = table.text.at(index);
        std::size_t written = detail::write_text(slot, 0, parts.prefix);
        written = detail::write_number(slot, written, index + 1);
        written = detail::write_text(slot, written, parts.suffix);
        table.size.at(index) = written;
    }
    return table;
}

// Phần chữ của lưới tên hai số: "<prefix><hàng><infix><cột><suffix>".
struct GridParts {
    std::string_view prefix;
    std::string_view infix;
    std::string_view suffix;
};

// Lưới Rows hàng, Cols cột; chỉ số của ô (hàng, cột) đếm từ 0 là hàng * Cols + cột.
template <std::size_t Rows, std::size_t Cols>
[[nodiscard]] consteval NameTable<Rows * Cols> grid(GridParts parts) {
    NameTable<Rows * Cols> table;
    for (std::size_t row = 0; row < Rows; ++row) {
        for (std::size_t column = 0; column < Cols; ++column) {
            const std::size_t index = (row * Cols) + column;
            std::array<char, NameTable<Rows * Cols>::kWidth>& slot = table.text.at(index);
            std::size_t written = detail::write_text(slot, 0, parts.prefix);
            written = detail::write_number(slot, written, row + 1);
            written = detail::write_text(slot, written, parts.infix);
            written = detail::write_number(slot, written, column + 1);
            written = detail::write_text(slot, written, parts.suffix);
            table.size.at(index) = written;
        }
    }
    return table;
}

} // namespace game::ui::panel
