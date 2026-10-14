#pragma once
// Bản dịch ô của một bảng Table/<bảng>.tsv: tệp Table/<bảng>.lang.tsv do TOOLS/content/build_i18n.py
// sinh từ các khoá table/<bảng>/<id>/<cột> của assets/i18n/<mã>.tsv, ba cột id, column, text. Ô có bản
// dịch thì thay bằng chữ dịch; ô không có giữ chữ gốc tiếng Trung của client 2026. Dòng bản dịch nêu
// id hay cột mà bảng không có thì bỏ qua và đếm vào missed: bảng xuất lại có thể đổi trước bản dịch,
// và thiếu một bản dịch không được làm hỏng bảng gốc.
// Bản mới của dự án, không có ở client gốc (client gốc chỉ có một ngôn ngữ).

#include "table/tsv.hpp"

#include <cstddef>
#include <expected>
#include <string>
#include <string_view>

namespace game::table {

// Đuôi của tệp bản dịch, thay cho ".tsv" của tệp bảng.
inline constexpr std::string_view kLangSuffix = ".lang.tsv";

struct LocalizeCount {
    // Số ô đã thay.
    std::size_t applied = 0;
    // Số dòng bản dịch không tìm thấy id hay cột trong bảng.
    std::size_t missed = 0;
};

using LocalizeResult = std::expected<LocalizeCount, std::string>;

// Thay các ô của table theo bản dịch lang. Cột khoá là id_column; id lặp trong bảng thì dịch dòng gặp
// trước, như bảng DBC gốc giữ dòng đầu. Lỗi (table giữ nguyên) khi lang thiếu cột id, column hay text,
// hoặc table không có cột khoá. Dòng dịch chính cột khoá cũng là missed. O(số dòng của table + số dòng
// của lang x số cột của table).
[[nodiscard]] LocalizeResult localize(Tsv& table, const Tsv& lang, std::string_view id_column = "id");

// Tên tệp bản dịch của tệp bảng name ("skills.tsv" -> "skills.lang.tsv"); rỗng khi name không có đuôi
// ".tsv", đã là tệp bản dịch, hay là một trong hai bảng chữ giao diện (ui_strings.tsv, scene_names.tsv):
// <bảng>.lang.tsv của hai bảng đó là bảng chữ khoá-chữ, không phải bản dịch ô (TABLE_RESERVED của
// build_i18n.py).
[[nodiscard]] std::string lang_name(std::string_view name);

} // namespace game::table
