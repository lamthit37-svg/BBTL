// Đọc refs. Dòng tên cột phải đúng tám tên; một đoạn đường dẫn chỉ được một dấu *.
#include "content/ref_rule.hpp"

#include "content/detail/scan.hpp"
#include "content/lint.hpp"
#include "content/path_glob.hpp"
#include "content/table_text.hpp"

#include <algorithm>
#include <array>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

namespace game::content {
namespace {

using Size = std::size_t;
using Views = std::vector<TextView>;
using Rules = std::vector<RefRule>;

constexpr std::array<TextView, 8> kRefNames{
    "child",
    "child_column",
    "parent",
    "parent_column",
    "absent",
    "known_missing",
    "basis",
    "note",
};

[[nodiscard]] bool header_matches(std::span<const TextView> cells) noexcept {
    if (cells.size() != kRefNames.size()) return false;
    return std::ranges::equal(cells, kRefNames);
}

void split_semi(TextView text, std::vector<std::string>& out) {
    if (text.empty()) return;
    std::size_t start = 0;
    bool done = false;
    while (!done) {
        const auto stop = text.find(';', start);
        done = stop == TextView::npos;
        const auto end = done ? text.size() : stop;
        out.emplace_back(text.substr(start, end - start));
        start = end + 1;
    }
}

[[nodiscard]] bool parse_known(TextView text, std::int64_t& value) noexcept {
    const CharSpan chars = chars_of(text);
    const auto result = std::from_chars(chars.begin, chars.end, value);
    return result.ec == std::errc{} && result.ptr == chars.end && value >= 0;
}

// Dòng sai số vẫn ở báo cáo, kẻo lỗi biến mất.
void note_known(RefRule& rule, TextView text, IssueList& issues) {
    rule.known_ok = parse_known(text, rule.known_missing);
    if (rule.known_ok) return;
    add_issue(issues, rule.path, rule.line, "known_missing không phải số nguyên");
}

void add_rule(Rules& rules, TextView path, Size line, const Views& cells, IssueList& issues) {
    if (cells.size() != 8) return;
    RefRule rule;
    rule.child = std::string(cells[0]);
    rule.child_column = std::string(cells[1]);
    rule.parent = std::string(cells[2]);
    rule.parent_column = std::string(cells[3]);
    split_semi(cells[4], rule.absent);
    rule.path = std::string(path);
    rule.line = line;
    rule.parent_star = rule.parent.contains('*');
    note_known(rule, cells[5], issues);
    rules.push_back(std::move(rule));
}

struct RefCursor {
    LinePlace place;
    bool header = false;
    bool done = false;
};

void take_header(RefCursor& cursor, const Line& line, const TextFile& file, IssueList& issues) {
    cursor.header = true;
    Views cells;
    split_tabs(line.text, cells);
    if (header_matches(cells)) return;
    add_issue(issues, file.path, line.number, "dòng tên cột không khớp");
    cursor.done = true;
}

void take_data(const TextFile& file, const Line& line, Rules& rules, IssueList& issues) {
    Views cells;
    split_tabs(line.text, cells);
    if (cells.size() != 8) {
        add_issue(issues, file.path, line.number, "dòng refs sai số cột");
        return;
    }
    if (!glob_shape_ok(cells[0]) || !glob_shape_ok(cells[2])) {
        add_issue(issues, file.path, line.number, "mẫu đường dẫn sai hình");
        return;
    }
    add_rule(rules, file.path, line.number, cells, issues);
}

void take_ref_line(RefCursor& cursor, const TextFile& file, Rules& rules, IssueList& issues) {
    const Line line = next_line(file.text, cursor.place);
    cursor.done = line.done;
    if (line.done || line.text.empty()) return;
    if (!cursor.header && line.text.starts_with('#')) return;
    if (!cursor.header) {
        take_header(cursor, line, file, issues);
        return;
    }
    take_data(file, line, rules, issues);
}

} // namespace

void read_ref_file(const TextFile& file, std::vector<RefRule>& rules, IssueList& issues) {
    Preamble preamble;
    read_preamble(preamble, file.text);
    if (!preamble_ok(preamble, file.path, issues)) return;
    RefCursor cursor;
    while (!cursor.done)
        take_ref_line(cursor, file, rules, issues);
    if (!cursor.header) add_issue(issues, file.path, 1, "thiếu dòng tên cột");
}

} // namespace game::content
