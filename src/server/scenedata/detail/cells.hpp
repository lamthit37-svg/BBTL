#pragma once
// Đọc ô của một dòng bảng cảnh theo tên cột, có kiểm miền. Khác table::RowReader ở chỗ ô rỗng là giá trị
// hợp lệ: bảng cảnh sinh từ tệp ini, ô rỗng nghĩa là khoá vắng hoặc chỉ có chú thích (`pos_x=;165`), và mã
// 2008 đọc ô như vậy bằng atoi("") = 0 hay lấy mặc định. Mỗi hàm đọc nói rõ ô rỗng thành gì.
// Chỉ lỗi đầu tiên được nhớ (kèm tệp, dòng, cột); hỏi error() sau khi đọc xong cả dòng.
//
// Chỉ nội bộ module scenedata.

#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::scenedata::detail {

// Trần chữ trong một ô (tên, tiêu đề, câu nói). Tên dài nhất của dữ liệu thật là vài chục byte.
inline constexpr std::size_t kMaxTextCell = 256;
// Toạ độ hợp lệ: |giá trị| <= trần này. Bản đồ lớn nhất của client 2026 cỡ vài nghìn đơn vị.
inline constexpr float kMaxCoordinate = 100000.0F;

class Cells {
public:
    Cells(std::string_view file, const table::Tsv& table, std::size_t row) noexcept
        : file_(file), table_(&table), row_(row) {}

    // Cột có trong bảng (cột tuỳ chọn như speech_N).
    [[nodiscard]] bool has(std::string_view column) const noexcept;
    // Ô rỗng.
    [[nodiscard]] bool blank(std::string_view column);

    // Số nguyên trong [low, high]; ô rỗng thành 0 (atoi("")), 0 phải nằm trong miền.
    [[nodiscard]] std::int32_t int_or_zero(std::string_view column, std::int32_t low, std::int32_t high);
    // Số nguyên trong [low, high]; ô rỗng thành fallback (khoá tuỳ chọn có mặc định riêng).
    [[nodiscard]] std::int32_t int_or(std::string_view column, std::int32_t fallback, std::int32_t low,
        std::int32_t high);
    // Số nguyên trong [low, high]; ô rỗng thành nullopt.
    [[nodiscard]] std::optional<std::int32_t> int_opt(std::string_view column, std::int32_t low, std::int32_t high);
    // Số nguyên không dấu trong [0, high]; ô rỗng thành 0.
    [[nodiscard]] std::uint32_t uint_or_zero(std::string_view column, std::uint32_t high);
    // Số nguyên không dấu trong [0, high]; ô rỗng thành nullopt.
    [[nodiscard]] std::optional<std::uint32_t> uint_opt(std::string_view column, std::uint32_t high);
    // Số thực hữu hạn, |giá trị| <= kMaxCoordinate; ô rỗng thành 0 (atof("")).
    [[nodiscard]] float real_or_zero(std::string_view column);
    [[nodiscard]] std::optional<float> real_opt(std::string_view column);
    // 0 hoặc 1; ô rỗng thành false.
    [[nodiscard]] bool flag(std::string_view column);
    // UTF-8 hợp lệ, không ký tự điều khiển, dài tối đa kMaxTextCell byte; rỗng cho phép.
    [[nodiscard]] std::string text(std::string_view column);

    // Ghi lỗi do nơi gọi tự kiểm; chỉ giữ lỗi đầu tiên.
    void reject(std::string_view column, std::string_view what);

    [[nodiscard]] const std::optional<std::string>& error() const noexcept { return error_; }

private:
    // Ô của cột; nullopt (và ghi lỗi) khi bảng thiếu cột.
    [[nodiscard]] std::optional<std::string_view> cell(std::string_view column);

    std::string_view file_;
    const table::Tsv* table_ = nullptr;
    std::size_t row_ = 0;
    std::optional<std::string> error_;
};

} // namespace game::scenedata::detail
