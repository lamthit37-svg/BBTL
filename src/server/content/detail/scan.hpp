#pragma once
// Quét chữ dùng chung cho năm việc kiểm. Không giữ trạng thái và không mở tệp.

#include "content/lint.hpp"

#include <algorithm>
#include <cstddef>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::content {

using IssueList = std::vector<Issue>;
using TextView = std::string_view;

inline void add_issue(IssueList& issues, TextView path, std::size_t line, std::string message) {
    Issue issue;
    issue.path = std::string(path);
    issue.line = line;
    issue.message = std::move(message);
    issues.push_back(std::move(issue));
}

struct Line {
    TextView text;
    std::size_t number = 0;
    bool done = false;
};

struct LinePlace {
    std::size_t start = 0;
    std::size_t number = 0;
};

inline Line next_line(TextView text, LinePlace& place) {
    Line line;
    if (place.start >= text.size()) {
        line.done = true;
        return line;
    }
    const auto stop = text.find('\n', place.start);
    const bool last = stop == TextView::npos;
    const auto end = last ? text.size() : stop;
    line.text = text.substr(place.start, end - place.start);
    place.number += 1;
    line.number = place.number;
    place.start = end + 1;
    return line;
}

inline void split_tabs(TextView line, std::vector<TextView>& cells) {
    cells.clear();
    std::size_t start = 0;
    bool done = false;
    while (!done) {
        const auto stop = line.find('\t', start);
        done = stop == TextView::npos;
        const auto end = done ? line.size() : stop;
        cells.push_back(line.substr(start, end - start));
        start = end + 1;
    }
}

struct CharSpan {
    const char* begin = nullptr;
    const char* end = nullptr;
};

// from_chars chỉ nhận cặp con trỏ, không có bản string_view.
[[nodiscard]] inline CharSpan chars_of(TextView text) noexcept {
    const char* begin = text.data();
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic): hợp đồng from_chars
    const char* end = begin + text.size();
    return CharSpan{.begin = begin, .end = end};
}

inline void count_newline(std::size_t& line, char byte) noexcept {
    if (byte == '\n') line += 1;
}

[[nodiscard]] inline std::size_t line_of(TextView text, std::size_t offset) noexcept {
    std::size_t line = 1;
    const std::size_t end = std::min(offset, text.size());
    for (std::size_t i = 0; i < end; ++i)
        count_newline(line, text[i]);
    return line;
}

// Vị trí để gắn lỗi vào đúng dòng của tệp đang xét.
struct Blame {
    TextView path;
    std::size_t line = 1;
    IssueList* issues = nullptr;
};

} // namespace game::content
