#pragma once
// Bảng TSV của client (Table/*.tsv do TOOLS/content sinh ra) và của máy chủ (TOOLS/server/tsv_file.py):
// dòng bắt đầu bằng # là chú thích, dòng đầu tiên còn lại là tên cột, mỗi dòng sau là một bản ghi
// cách nhau bằng tab và phải đủ số ô của dòng tên cột. Không nháy, không escape: ô không chứa tab hay
// xuống dòng.
// Bảng căn cột (core/aligned.hpp): ô trả về đã bỏ đệm dấu cách ở cuối, dấu cách cuối thật được dựng lại.
// RowReader đọc ô theo tên cột với kiểm miền và nhớ lỗi đầu tiên (kèm số dòng của tệp và tên cột),
// để bộ đọc từng bảng viết một lượt rồi hỏi lỗi một lần.
// Bản mới của dự án; tương ứng tables/table.hpp của TLBB Dev, nhưng định dạng bảng đơn giản hơn vì
// bảng của client này do công cụ của chính dự án sinh ra.

#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::table {

struct Tsv {
    std::vector<std::string> header;
    std::vector<std::vector<std::string>> rows;
    // Số dòng của tệp (từ 1) ứng với từng bản ghi, để báo lỗi.
    std::vector<std::size_t> lines;
};

// Câu lỗi tiếng Việt kèm số dòng.
using TsvResult = std::expected<Tsv, std::string>;

// Bảng căn cột đọc đúng như bảng thường sau khi bỏ đệm (core::kAlignedLayout). O(độ dài văn bản).
[[nodiscard]] TsvResult parse_tsv(std::string_view text);

// Chỉ số cột tên name; không có thì nullopt.
[[nodiscard]] std::optional<std::size_t> column_of(const Tsv& table, std::string_view name);

// Đọc các ô của một bản ghi theo tên cột. Hàm đọc nào gặp lỗi (thiếu cột, ô sai kiểu, ngoài miền)
// thì ghi nhớ lỗi đầu tiên và trả giá trị 0 hay rỗng; hỏi error() sau khi đọc xong cả dòng.
class RowReader {
public:
    RowReader(const Tsv& table, std::size_t row) noexcept : table_(&table), row_(row) {}

    // Ô nguyên văn; cột phải có.
    [[nodiscard]] std::string_view text(std::string_view column);
    // Số nguyên không dấu trong [low, high].
    [[nodiscard]] std::uint32_t number(std::string_view column, std::uint32_t low, std::uint32_t high);
    // Số nguyên có dấu trong [low, high] (ô -1 của bảng gốc là "không có").
    [[nodiscard]] std::int32_t integer(std::string_view column, std::int32_t low, std::int32_t high);
    // Số thực hữu hạn lớn hơn 0.
    [[nodiscard]] float positive(std::string_view column);
    // Số thực hữu hạn, vừa kiểu float, được âm hay 0 (vị trí, trục, góc).
    [[nodiscard]] float real(std::string_view column);
    // 0 hoặc 1.
    [[nodiscard]] bool flag(std::string_view column);

    // Ghi lỗi của ô do nơi gọi tự kiểm (tên lạ, tổ hợp sai); chỉ giữ lỗi đầu tiên.
    void reject(std::string_view column, std::string_view what);

    [[nodiscard]] const std::optional<std::string>& error() const noexcept { return error_; }

private:
    const Tsv* table_ = nullptr;
    std::size_t row_ = 0;
    std::optional<std::string> error_;
};

} // namespace game::table
