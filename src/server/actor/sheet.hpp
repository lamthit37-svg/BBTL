#pragma once
// Bộ đọc bảng TSV có kiểm lỗi, dùng chung cho mọi bộ nạp luật của máy chủ (actor, combat): nhớ lỗi đầu tiên
// kèm tên bảng, số dòng và tên cột để hàm gọi hỏi một lần ở cuối. Lõi thuần: nhận chuỗi, không mở tệp.

#include "table/tsv.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>

namespace game::actor {

struct LoadError {
    std::string what;
};

template <typename T>
using Loaded = std::expected<T, LoadError>;

using Failure = std::optional<LoadError>;

[[nodiscard]] LoadError fail(std::string_view table, std::string_view what);

// Số nguyên nằm trọn trong ô và trong miền [low, high]. Bảng client in số nguyên lớn dạng khoa học
// ("1e+01"): ô không phải số nguyên thường thì thử số thực có giá trị nguyên chính xác.
[[nodiscard]] std::optional<std::int32_t> int_cell(std::string_view cell, std::int32_t low, std::int32_t high) noexcept;

// Số thực in dạng thường hoặc khoa học nhân scale rồi làm tròn; nullopt khi không phải số hay vượt miền.
[[nodiscard]] std::optional<std::int64_t> parse_scaled(std::string_view text, std::int64_t scale) noexcept;

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): tên bảng rồi nội dung, mọi nơi gọi cùng một thứ tự (HP-07)
[[nodiscard]] Loaded<table::Tsv> parse_table(std::string_view name, std::string_view text);

class Sheet {
public:
    Sheet(std::string_view name, const table::Tsv& tsv) : name_(name), tsv_(&tsv) {}

    [[nodiscard]] std::size_t rows() const noexcept { return tsv_->rows.size(); }
    [[nodiscard]] std::size_t columns() const noexcept { return tsv_->header.size(); }
    [[nodiscard]] const Failure& error() const noexcept { return error_; }

    // Chỉ số cột theo tên; thiếu cột thì ghi lỗi và trả 0.
    std::size_t column(std::string_view column_name);

    [[nodiscard]] std::string_view text(std::size_t row, std::size_t column_index) const {
        return tsv_->rows[row][column_index];
    }

    std::int32_t integer(std::size_t row, std::size_t column_index, std::int32_t low, std::int32_t high);

    // NOLINTNEXTLINE(bugprone-easily-swappable-parameters): dòng, cột, thang đo khác vai, nơi gọi nêu tên (HP-07)
    std::int64_t scaled(std::size_t row, std::size_t column_index, std::int64_t scale);

    void raise(std::size_t row, std::string_view column_name, std::string_view what);

private:
    std::string name_;
    const table::Tsv* tsv_;
    Failure error_;
};

} // namespace game::actor
