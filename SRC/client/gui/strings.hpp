// Bảng chuỗi của giao diện gốc. Layout viết #{ID}; client gốc tra ID trong StrDictionary.txt (chữ
// Hán). Bảng của dự án là Table/ui_strings.tsv do TOOLS/content/collect_ui.py trích từ chính tệp đó
// (cột key và text, UTF-8). ID không có trong bảng thì ô chữ để trống, như lúc chưa có bảng.
// Các dòng xếp sẵn theo khoá để tra bằng tìm nhị phân. Bản dịch (Table/ui_strings.lang.tsv, cùng
// hai cột) nạp đè bằng overlay; trong bản dịch, khoá mở đầu bằng dấu = là nguyên văn một chuỗi viết
// thẳng trong layout (không qua #{ID}), tra bằng find_literal.
// Nguồn: TLBB Dev src/gui/string_book.hpp@e0d89a6. Khác gốc: namespace game::gui; đọc qua
// table::Tsv của dự án (dòng tên cột, dòng # là chú thích) thay cho tự cắt dòng.
#pragma once

#include "table/tsv.hpp"

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::gui {

class StringBook {
public:
    // Bảng có hai cột key và text. ID lặp thì dòng sau thắng. Thiếu cột thì bảng rỗng.
    [[nodiscard]] static StringBook from_table(const table::Tsv& table);

    // Nạp đè một bảng cùng dạng: khoá trùng thì dòng của table thắng, khoá mới thì thêm.
    void overlay(const table::Tsv& table);

    // ID viết không có #{ và }. Chuỗi trả về sống cùng bảng.
    [[nodiscard]] std::optional<std::string_view> find(std::string_view id) const noexcept;
    // Bản dịch của một chuỗi viết thẳng (dòng có khoá "=" nối nguyên văn); nullopt khi chưa dịch.
    [[nodiscard]] std::optional<std::string_view> find_literal(std::string_view text) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return rows_.size(); }

private:
    struct Row {
        std::string key;
        std::string text;
    };

    std::vector<Row> rows_;
};

} // namespace game::gui
