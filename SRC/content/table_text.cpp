// Đọc phần đầu, kiểm hình dạng rồi duyệt từng bản ghi của một bảng TSV. Dòng bắt đầu bằng # sau
// tiêu đề vẫn là bản ghi, đọc ở lượt thứ hai của RecordReader.
#include "content/table_text.hpp"

#include "content/detail/scan.hpp"
#include "content/lint.hpp"
#include "content/utf8.hpp"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <format>
#include <set>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::content {
namespace {

constexpr std::int64_t kInt32Min = -2147483647 - 1;
constexpr std::int64_t kInt32Max = 2147483647;

[[nodiscard]] bool note_comment(Preamble& preamble, const Line& line) {
    if (line.text == "# schema 1") {
        preamble.schemas += 1;
        preamble.schema_line = line.number;
        return true;
    }
    constexpr TextView kTypes = "# types: ";
    if (line.text.starts_with(kTypes)) {
        preamble.types += 1;
        preamble.types_line = line.number;
        preamble.type_text = std::string(line.text.substr(kTypes.size()));
        return true;
    }
    return line.text.starts_with('#');
}

void step_preamble(Preamble& preamble, const Line& line) {
    if (line.done || line.text.empty()) return;
    preamble.saw_header = !note_comment(preamble, line);
}

// Dòng parse_tsv bỏ qua: rỗng hoặc chú thích.
[[nodiscard]] bool is_skipped(TextView line) noexcept {
    return line.empty() || line.front() == '#';
}

// Tìm dòng tên cột: dòng đầu tiên không bị bỏ qua. false khi tệp không có dòng nào như vậy.
[[nodiscard]] bool find_header(TextView text, TableHead& head) {
    Line line = next_line(text, head.body);
    while (!line.done && is_skipped(line.text)) {
        line = next_line(text, head.body);
    }
    if (line.done) return false;
    split_tabs(line.text, head.columns);
    return true;
}

[[nodiscard]] std::size_t cell_count(TextView line) noexcept {
    return static_cast<std::size_t>(std::ranges::count(line, '\t')) + 1;
}

// Mọi bản ghi phải đủ số ô của dòng tên cột; dòng đầu tiên lệch làm cả tệp không đọc được, như
// parse_tsv. Chỉ đếm tab, không tách ô.
[[nodiscard]] bool rows_fit(const TextFile& file, const TableHead& head, IssueList& issues) {
    LinePlace place = head.body;
    Line line = next_line(file.text, place);
    const std::size_t wanted = head.columns.size();
    while (!line.done && (is_skipped(line.text) || cell_count(line.text) == wanted)) {
        line = next_line(file.text, place);
    }
    if (line.done) return true;
    const std::size_t found = cell_count(line.text);
    const std::string message = std::format(
        "không đọc được: dòng {}: {} ô, dòng tên cột có {}", line.number, found, wanted);
    add_issue(issues, file.path, 1, message);
    return false;
}

[[nodiscard]] bool is_name_byte(char byte) noexcept {
    const bool is_lower = byte >= 'a' && byte <= 'z';
    return is_lower || (byte >= '0' && byte <= '9') || byte == '_';
}

[[nodiscard]] bool is_column_name(TextView name) noexcept {
    if (name.empty() || name.front() < 'a' || name.front() > 'z') return false;
    return std::ranges::all_of(name, is_name_byte);
}

void check_name(std::set<TextView>& seen, TextView name, const Blame& blame) {
    if (!is_column_name(name)) {
        add_issue(*blame.issues, blame.path, blame.line, "tên cột không hợp lệ");
        return;
    }
    if (seen.insert(name).second) return;
    add_issue(*blame.issues, blame.path, blame.line, "tên cột lặp");
}

void check_names(const TableHead& head, const Blame& blame) {
    std::set<TextView> seen;
    for (const TextView name : head.columns) {
        check_name(seen, name, blame);
    }
}

[[nodiscard]] CellKind kind_of(TextView type) noexcept {
    if (type == "int") return CellKind::kInt;
    if (type == "float") return CellKind::kFloat;
    return CellKind::kOther;
}

void check_type(TextView type, const Blame& blame) {
    const bool is_known = kind_of(type) != CellKind::kOther || type == "text";
    if (!is_known) add_issue(*blame.issues, blame.path, blame.line, "kiểu cột không hợp lệ");
}

// type_text thuộc preamble của bên gọi; head.types giữ view vào chữ của tệp, nên tách lại từ tệp.
void read_types(TableHead& head, TextView type_text, const Blame& blame) {
    split_tabs(type_text, head.types);
    if (head.types.size() != head.columns.size()) {
        add_issue(*blame.issues, blame.path, blame.line, "số kiểu khác số cột");
        head.types.clear();
        return;
    }
    for (const TextView type : head.types) {
        check_type(type, blame);
    }
}

// Dòng `# types: ...` nằm trong chữ của tệp ở dòng types_line; trả phần sau tiền tố.
[[nodiscard]] TextView type_text_of(TextView text, std::size_t types_line) noexcept {
    LinePlace place;
    Line line = next_line(text, place);
    while (!line.done && line.number != types_line) {
        line = next_line(text, place);
    }
    constexpr TextView kTypes = "# types: ";
    if (line.done || !line.text.starts_with(kTypes)) return {};
    return line.text.substr(kTypes.size());
}

[[nodiscard]] bool match_int(TextView text) noexcept {
    const TextView digits = text.starts_with('-') ? text.substr(1) : text;
    if (digits.empty()) return false;
    if (digits.front() == '0') return digits.size() == 1;
    const auto is_digit = [](char byte) { return byte >= '0' && byte <= '9'; };
    return std::ranges::all_of(digits, is_digit);
}

[[nodiscard]] bool in_int32(TextView text) noexcept {
    std::int64_t value = 0;
    const CharSpan chars = chars_of(text);
    const auto result = std::from_chars(chars.begin, chars.end, value);
    if (result.ec != std::errc{} || result.ptr != chars.end) return false;
    return value >= kInt32Min && value <= kInt32Max;
}

// Bỏ một dãy chữ số ở đầu text; false khi không có chữ số nào.
[[nodiscard]] bool take_digits(TextView& text) noexcept {
    const std::size_t stop = text.find_first_not_of("0123456789");
    const std::size_t count = stop == TextView::npos ? text.size() : stop;
    text.remove_prefix(count);
    return count != 0;
}

// Phần định trị: `12`, `12.5` hoặc `.5`; không nhận `12.` hay `.`.
[[nodiscard]] bool take_mantissa(TextView& text) noexcept {
    const bool has_whole = take_digits(text);
    if (!text.starts_with('.')) return has_whole;
    text.remove_prefix(1);
    return take_digits(text);
}

[[nodiscard]] bool take_exponent(TextView& text) noexcept {
    const bool is_marked = text.starts_with('e') || text.starts_with('E');
    if (!is_marked) return true;
    text.remove_prefix(1);
    if (text.starts_with('+') || text.starts_with('-')) text.remove_prefix(1);
    return take_digits(text);
}

[[nodiscard]] bool match_float(TextView text) noexcept {
    if (text.starts_with('-')) text.remove_prefix(1);
    if (!take_mantissa(text)) return false;
    return take_exponent(text) && text.empty();
}

[[nodiscard]] bool finite_float(TextView text) noexcept {
    float value = 0;
    const CharSpan chars = chars_of(text);
    const auto result = std::from_chars(chars.begin, chars.end, value);
    if (result.ec != std::errc{} || result.ptr != chars.end) return false;
    return std::isfinite(value);
}

[[nodiscard]] bool cell_ok(TextView cell, CellKind kind) noexcept {
    if (cell.empty() || kind == CellKind::kOther) return true;
    if (kind == CellKind::kInt) return match_int(cell) && in_int32(cell);
    return match_float(cell) && finite_float(cell);
}

} // namespace

void read_preamble(Preamble& preamble, TextView text) {
    LinePlace place;
    bool done = false;
    while (!done && !preamble.saw_header) {
        const Line line = next_line(text, place);
        done = line.done;
        step_preamble(preamble, line);
    }
}

bool preamble_ok(const Preamble& preamble, TextView path, IssueList& issues) {
    if (preamble.schemas == 0) add_issue(issues, path, 1, "thiếu dòng # schema 1");
    if (preamble.schemas > 1) add_issue(issues, path, preamble.schema_line, "dòng # schema 1 lặp");
    if (preamble.types == 0) add_issue(issues, path, 1, "thiếu dòng # types");
    if (preamble.types > 1) add_issue(issues, path, preamble.types_line, "dòng # types lặp");
    return preamble.schemas == 1 && preamble.types == 1;
}

TableHead read_head(const TextFile& file, IssueList& issues) {
    TableHead head;
    if (!file_bytes_ok(file.text, file.path, issues)) return head;
    Preamble preamble;
    read_preamble(preamble, file.text);
    if (!preamble_ok(preamble, file.path, issues)) return head;
    if (!find_header(file.text, head)) {
        add_issue(issues, file.path, 1, "không đọc được: bảng không có dòng tên cột");
        return head;
    }
    if (!rows_fit(file, head, issues)) return head;
    head.is_readable = true;
    check_names(head, Blame{.path = file.path, .line = 1, .issues = &issues});
    const Blame at_types{.path = file.path, .line = preamble.types_line, .issues = &issues};
    read_types(head, type_text_of(file.text, preamble.types_line), at_types);
    return head;
}

RecordReader::RecordReader(const TextFile& file, const TableHead& head) noexcept
    : path_(file.path), text_(file.text), head_(&head), place_(head.body) {}

// Hết lượt dòng thường thì đọc lại thân bảng cho lượt dòng #; hết lượt đó là hết bản ghi.
void RecordReader::end_pass() noexcept {
    is_done_ = pass_ == Pass::kHash;
    pass_ = Pass::kHash;
    place_ = head_->body;
}

// Đọc một dòng; true khi dòng đó là một bản ghi của lượt đang chạy.
bool RecordReader::take_line(Record& record, IssueList& issues) {
    const Line line = next_line(text_, place_);
    if (line.done) {
        end_pass();
        return false;
    }
    if (line.text.empty()) return false;
    const bool is_hash = line.text.front() == '#';
    if (is_hash != (pass_ == Pass::kHash)) return false;
    if (is_hash) add_issue(issues, path_, line.number, "ô đầu bắt đầu bằng #");
    split_tabs(line.text, cells_);
    // Chỉ dòng # mới có thể lệch số ô ở đây: rows_fit đã bỏ qua chúng như parse_tsv.
    if (cells_.size() != head_->columns.size()) return false;
    record.cells = cells_;
    record.line = line.number;
    return true;
}

bool RecordReader::next(Record& record, IssueList& issues) {
    bool has_record = false;
    while (!has_record && !is_done_) {
        has_record = take_line(record, issues);
    }
    return has_record;
}

CellChecker::CellChecker(const TextFile& file, const TableHead& head, IssueList& issues)
    : path_(file.path), columns_(head.columns), issues_(&issues) {
    kinds_.resize(head.types.size());
    std::ranges::transform(head.types, kinds_.begin(), kind_of);
}

void CellChecker::check_cell(const Record& record, std::size_t column) {
    const CellKind kind = kinds_[column];
    if (cell_ok(record.cells[column], kind)) return;
    const TextView word = kind == CellKind::kInt ? "int" : "float";
    std::string message = std::format("cột {}: ô {} không hợp lệ", columns_[column], word);
    add_issue(*issues_, path_, record.line, std::move(message));
}

void CellChecker::check(const Record& record) {
    for (std::size_t column = 0; column < kinds_.size(); ++column) {
        check_cell(record, column);
    }
}

} // namespace game::content