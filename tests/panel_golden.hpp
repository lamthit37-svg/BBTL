// Đối chiếu một bảng port từ script Lua với số vàng của trọng tài (TOOLS/port/lua_oracle.py chạy
// script gốc trên LuaPlus.dll của client 2026). Tệp số vàng gồm các khối, mỗi khối mở đầu bằng dòng
// "# nhãn" và chứa trạng thái cửa sổ sau một bước của kịch bản; test chạy cùng các bước trên bản
// port rồi so tập dòng của từng khối. Thứ tự dòng trong khối không tính (trọng tài ghi theo thứ tự
// của layout, bản port theo thứ tự đụng tới).
#pragma once

#include "io/file.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/widgets.hpp"

#include <algorithm>
#include <cstddef>
#include <filesystem>
#include <format>
#include <iterator>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {

// Thư mục tests/golden/panel mà bản dựng biết; rỗng thì các ca đối chiếu số vàng tự bỏ qua (test
// chạy trên thiết bị không thấy cây nguồn).
#ifdef GAME_PANEL_GOLDEN
inline constexpr std::string_view kPanelGolden = GAME_PANEL_GOLDEN;
#else
inline constexpr std::string_view kPanelGolden;
#endif

// Một khối của tệp số vàng: nhãn của bước và các dòng trạng thái.
struct GoldenBlock {
    std::string label;
    std::vector<std::string> lines;
};

// Đọc tệp số vàng name trong thư mục số vàng. Rỗng khi bản dựng không biết thư mục hay tệp không
// đọc được (ca gọi tự báo thiếu).
[[nodiscard]] inline std::vector<GoldenBlock> read_golden(std::string_view name) {
    std::vector<GoldenBlock> blocks;
    if (kPanelGolden.empty()) return blocks;
    const io::TextResult text = io::read_text(io::path_from_utf8(kPanelGolden) / io::path_from_utf8(name));
    if (!text) return blocks;
    std::size_t start = 0;
    while (start < text->size()) {
        const std::size_t stop = std::min(text->find('\n', start), text->size());
        const std::string_view line = std::string_view(*text).substr(start, stop - start);
        start = stop + 1;
        if (line.starts_with("# ")) blocks.push_back(GoldenBlock{.label = std::string(line.substr(2)), .lines = {}});
        if (!line.starts_with("# ") && !blocks.empty()) blocks.back().lines.emplace_back(line);
    }
    std::erase_if(blocks, [](const GoldenBlock& block) { return block.lines.empty(); });
    return blocks;
}

// Trạng thái của một bảng port sau một bước, theo dạng dòng của trọng tài: cờ hiện của cả bảng, mọi
// thứ Widgets đang giữ, rồi các việc đã nhờ game kể từ bước trước (xoá calls sau khi ghi).
[[nodiscard]] inline std::vector<std::string> panel_lines(
    bool is_shown, const ui::panel::Widgets& widgets, std::vector<ui::panel::Call>& calls) {
    std::vector<std::string> lines;
    lines.push_back(std::format("this\tVisible\t{}", is_shown ? "True" : "False"));
    widgets.describe(lines);
    std::size_t number = 0;
    for (const ui::panel::Call& call : calls) {
        ++number;
        const std::string tail = call.text.empty() ? std::string() : std::format("\t{}", call.text);
        lines.push_back(std::format("!call{}\t{}{}", number, ui::panel::name_of(call.ask), tail));
    }
    calls.clear();
    return lines;
}

// So các dòng của bản port với một khối số vàng; mỗi dòng thiếu hay thừa báo một lần kèm nhãn.
inline void expect_block(Context& context, const GoldenBlock& block, std::vector<std::string> lines) {
    std::vector<std::string> wanted = block.lines;
    std::ranges::sort(wanted);
    std::ranges::sort(lines);
    std::vector<std::string> missing;
    std::vector<std::string> extra;
    std::ranges::set_difference(wanted, lines, std::back_inserter(missing));
    std::ranges::set_difference(lines, wanted, std::back_inserter(extra));
    for (const std::string& line : missing) context.expect(false, std::format("[{}] thiếu: {}", block.label, line));
    for (const std::string& line : extra) context.expect(false, std::format("[{}] thừa: {}", block.label, line));
}

} // namespace game::test
