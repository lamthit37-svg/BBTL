#pragma once
// Bộ đọc bảng TSV theo dòng cho các bộ nạp bảng của item, loot, shop, forge.
//
// Vì sao không dùng table::Tsv: bảng trang bị có 24.577 dòng x 103 cột và bảng vật phẩm 20.501 dòng;
// table::Tsv dựng một std::string cho mỗi ô (vài triệu cấp phát) và giữ cả bảng trong bộ nhớ. Bộ đọc
// này đi qua văn bản một lần, mỗi dòng chỉ cắt thành string_view trỏ vào văn bản gốc (bên gọi giữ văn bản
// sống tới khi nạp xong). Cùng định dạng với table::parse_tsv: dòng bắt đầu bằng # là chú thích, dòng đầu
// còn lại là tên cột, ô cách nhau bằng tab, mọi dòng phải đủ số ô của dòng tên cột; bảng căn cột
// (core/aligned.hpp) bỏ đệm dấu cách ở cuối từng ô, ô có dấu cách cuối thật được dựng lại trong bộ nhớ
// của Rows (view của dòng hiện tại sống tới lời gọi next kế tiếp).

#include "core/aligned.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::item::tsv {

class Rows {
public:
    explicit Rows(std::string_view text);

    // Tên cột -> chỉ số; npos khi không có.
    [[nodiscard]] std::size_t column(std::string_view name) const noexcept;
    [[nodiscard]] std::size_t column_count() const noexcept { return header_.size(); }
    // Tên cột; rỗng khi ngoài miền (dùng cho câu báo lỗi).
    [[nodiscard]] std::string_view name(std::size_t col) const noexcept;

    // Sang dòng dữ liệu kế tiếp. false khi hết bảng hoặc gặp dòng hỏng (hỏi error()).
    [[nodiscard]] bool next();

    [[nodiscard]] std::span<const std::string_view> cells() const noexcept { return cells_; }
    [[nodiscard]] std::size_t line() const noexcept { return line_; }
    [[nodiscard]] const std::optional<std::string>& error() const noexcept { return error_; }

    static constexpr std::size_t npos = static_cast<std::size_t>(-1);

private:
    [[nodiscard]] bool take_line(std::string_view& line);
    [[nodiscard]] bool note_layout(std::string_view line);
    void read_header(std::string_view line);
    [[nodiscard]] bool read_cells(std::string_view line);
    void unpad_cells();

    std::string_view rest_;
    std::vector<std::string_view> header_;
    std::vector<std::string_view> cells_;
    // Chữ dựng lại của ô bảng căn cột có dấu cách cuối thật, theo chỉ số cột; cells_ trỏ vào.
    std::vector<std::string> restored_;
    core::Layout layout_ = core::Layout::kPlain;
    std::size_t line_ = 0;
    std::optional<std::string> error_;
};

// Ô -> số nguyên có dấu; nullopt khi rỗng, có ký tự lạ hoặc tràn int64.
[[nodiscard]] std::optional<std::int64_t> to_int(std::string_view cell) noexcept;

// Đọc ô của dòng hiện tại với kiểm miền; nhớ lỗi đầu tiên kèm số dòng, tên bảng và tên cột. Hàm đọc
// nào lỗi trả `fallback` để bộ nạp viết thẳng một lượt rồi hỏi error() một lần ở cuối dòng.
// Miền đóng {thấp, cao} của một ô số (first = thấp nhất, second = cao nhất).
using Bounds = std::pair<std::int64_t, std::int64_t>;

class Cells {
public:
    Cells(const Rows& rows, std::string_view table) noexcept : rows_(&rows), table_(table) {}

    // Số nguyên trong miền ở cột col; lỗi thì trả bounds.low.
    [[nodiscard]] std::int64_t integer(std::size_t col, Bounds bounds);
    // Như integer nhưng ô rỗng hay "-1" -> fallback (bảng gốc dùng -1 cho "không có").
    [[nodiscard]] std::int64_t optional_integer(std::size_t col, Bounds bounds, std::int64_t fallback);
    [[nodiscard]] std::string_view text(std::size_t col) const noexcept;

    void fail(std::size_t col, std::string_view what);
    [[nodiscard]] const std::optional<std::string>& error() const noexcept { return error_; }

private:
    const Rows* rows_;
    std::string_view table_;
    std::optional<std::string> error_;
};

} // namespace game::item::tsv
