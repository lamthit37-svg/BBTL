#pragma once
// Bộ tách bảng TSV riêng của test, độc lập với bộ nạp của module: bỏ dòng trống và dòng bắt đầu bằng #, dòng đầu
// là tên cột, ô cách nhau bằng tab. Dùng để lấy số kỳ vọng thẳng từ tệp bảng thật. Bảng căn cột (dòng
// core::kAlignedLayout trước tên cột) được bỏ đệm theo core/aligned.hpp, cùng luật với mọi bộ đọc của dự án.

#include "core/aligned.hpp"

#include <cstddef>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {

[[nodiscard]] inline std::string unpadded_cell(std::string_view cell) {
    const core::AlignedCell aligned = core::unpad(cell);
    std::string text(aligned.body);
    text.append(aligned.trailing_spaces, ' ');
    return text;
}

// Các ô của một dòng, bỏ đệm khi bảng căn cột.
[[nodiscard]] inline std::vector<std::string> split_cells(std::string_view line, bool is_aligned) {
    std::vector<std::string> cells;
    std::size_t begin = 0;
    std::size_t tab = 0;
    while (tab != std::string_view::npos) {
        tab = line.find('\t', begin);
        const std::string_view cell = line.substr(begin, tab - begin);
        cells.push_back(is_aligned ? unpadded_cell(cell) : std::string(cell));
        begin = tab + 1;
    }
    return cells;
}

// Hàng đầu là tên cột; mọi ô của bảng căn cột đã bỏ đệm.
[[nodiscard]] inline std::vector<std::vector<std::string>> split_tsv(const std::string& text) {
    std::vector<std::vector<std::string>> rows;
    std::istringstream stream(text);
    std::string line;
    bool is_aligned = false;
    while (std::getline(stream, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (rows.empty() && line == core::kAlignedLayout) is_aligned = true;
        if (!line.empty() && line.front() != '#') rows.push_back(split_cells(line, is_aligned));
    }
    return rows;
}

} // namespace game::test
