// Đếm độ phủ tham chiếu. Mỗi tệp đi qua một lần, theo từng bản ghi; chữ của tệp không được giữ:
// thứ còn lại sau một tệp là các ô trỏ của cột con và tập khoá của cột cha.
#include "content/coverage.hpp"

#include "content/detail/order.hpp"
#include "content/detail/scan.hpp"
#include "content/lint.hpp"
#include "content/path_glob.hpp"
#include "content/ref_rule.hpp"
#include "content/table_text.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <format>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::content {
namespace {

using Size = std::size_t;
using Rule = RefRule;
using Totals = ChildTotals;
using Session = CoverageState;
using Pair = RefPair;
using Count = std::int64_t;
using Texts = std::vector<std::string>;
constexpr Size kMissingShown = 5;

// Tệp sau của cùng mẫu không được nuốt kiểu. So với cha ở lúc chốt.
void remember_type(Totals& totals, TextView type, TextView path) {
    if (!totals.typed) {
        totals.type = std::string(type);
        totals.typed = true;
        return;
    }
    if (totals.type == type) return;
    totals.clashes.push_back(TypeClash{.path = std::string(path), .type = std::string(type)});
}

[[nodiscard]] std::optional<Size> column_of(const TableHead& head, TextView name) {
    const auto found = std::ranges::find(head.columns, name);
    if (found == head.columns.end()) return std::nullopt;
    return static_cast<Size>(found - head.columns.begin());
}

// Tệp đang mở và nơi ghi kết quả của việc tìm cột.
struct Opening {
    Session* state = nullptr;
    const TextFile* file = nullptr;
    const TableHead* head = nullptr;
    TapList* taps = nullptr;
};

// Cột của một dòng refs trong tệp đang mở; thiếu thì ghi lỗi.
[[nodiscard]] std::optional<Size> wanted_column(const Opening& opening, const std::string& name) {
    const std::optional<Size> column = column_of(*opening.head, name);
    if (column) return column;
    add_issue(opening.state->issues, opening.file->path, 1, "không có cột " + name);
    return std::nullopt;
}

void tap_child(const Opening& opening, Size slot) {
    const Rule& rule = opening.state->rules[slot];
    const TextView path = opening.file->path;
    const GlobHit hit = match_glob(GlobQuery{.pattern = rule.child, .path = path});
    if (!hit.matched) return;
    Totals& totals = opening.state->children[slot];
    totals.files += 1;
    opening.taps->child_rules.push_back(slot);
    const std::optional<Size> column = wanted_column(opening, rule.child_column);
    if (!column) return;
    const std::vector<TextView>& types = opening.head->types;
    if (*column < types.size()) remember_type(totals, types[*column], path);
    ColumnTap tap;
    tap.rule = slot;
    tap.column = *column;
    // Cha không có * thì một giá trị ở nhiều cảnh vẫn là một giá trị.
    if (rule.parent_star) tap.capture = hit.capture;
    opening.taps->columns.push_back(std::move(tap));
}

void tap_parent(const Opening& opening, Size slot) {
    const Rule& rule = opening.state->rules[slot];
    const TextView path = opening.file->path;
    if (!match_glob(GlobQuery{.pattern = rule.parent, .path = path}).matched) return;
    opening.state->parent_files[slot] += 1;
    const std::optional<Size> column = wanted_column(opening, rule.parent_column);
    if (!column) return;
    KeySet& keys = opening.state->keys[std::make_pair(std::string(path), rule.parent_column)];
    const std::vector<TextView>& types = opening.head->types;
    const bool has_type = *column < types.size() && !keys.typed;
    if (has_type) keys.type = std::string(types[*column]);
    keys.typed = keys.typed || has_type;
    // Nhiều dòng refs cùng một cột cha. Lần sau không được coi giá trị đã nạp là lặp.
    if (std::exchange(keys.scanned, true)) return;
    ColumnTap tap;
    tap.rule = slot;
    tap.column = *column;
    tap.keys = &keys;
    opening.taps->columns.push_back(std::move(tap));
}

void take_child(Totals& totals, TextView cell, const Texts& absent, const std::string& capture) {
    if (cell.empty()) return;
    if (std::ranges::find(absent, cell) != absent.end()) return;
    totals.refs.push_back(Pair{.capture = capture, .value = std::string(cell)});
}

void take_parent(KeySet& keys, TextView cell, TextView column, const Blame& blame) {
    if (cell.empty()) {
        add_issue(*blame.issues, blame.path, blame.line, std::format("cột {} có ô rỗng", column));
        return;
    }
    if (!keys.values.contains(cell)) {
        keys.values.emplace(cell);
        return;
    }
    const std::string message = std::format("cột {} lặp giá trị {}", column, cell);
    add_issue(*blame.issues, blame.path, blame.line, message);
}

[[nodiscard]] bool present(const Session& session, const Rule& rule, const Pair& pair) {
    const StarFill fill{.pattern = rule.parent, .capture = pair.capture};
    const std::string path = fill_glob_star(fill);
    const auto key = std::make_pair(path, rule.parent_column);
    const auto found = session.keys.find(key);
    if (found == session.keys.end()) return false;
    return found->second.values.contains(pair.value);
}

// Bộ dựng mặc định của struct chứa std::set bị tidy coi là noexcept dù STL MSVC cấp phát nút.
// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
struct Tally {
    std::set<Pair, MissLess> distinct;
    std::set<Pair, MissLess> missing;
    Count missing_rows = 0;
};

void tally_one(Tally& tally, const Session& session, const Rule& rule, const Pair& pair) {
    tally.distinct.insert(pair);
    if (present(session, rule, pair)) return;
    tally.missing.insert(pair);
    tally.missing_rows += 1;
}

[[nodiscard]] Tally tally_rule(const Session& session, const Rule& rule, const Totals& totals) {
    Tally tally;
    for (const Pair& pair : totals.refs)
        tally_one(tally, session, rule, pair);
    return tally;
}

void append_missing_item(std::string& out, const Pair& item, bool starred, bool first) {
    if (!first) out.push_back(';');
    if (!starred) {
        out += item.value;
        return;
    }
    out += item.capture;
    out.push_back(':');
    out += item.value;
}

[[nodiscard]] std::string join_missing(const std::vector<Pair>& items, bool starred) {
    std::string out;
    const std::size_t count = std::min(items.size(), kMissingShown);
    for (std::size_t i = 0; i < count; ++i)
        append_missing_item(out, items[i], starred, i == 0);
    return out;
}

[[nodiscard]] std::vector<Pair> sorted_missing(const std::set<Pair, MissLess>& rows, bool as_int) {
    std::vector<Pair> items(rows.begin(), rows.end());
    std::ranges::sort(items, MissLess{.as_int = as_int});
    return items;
}

struct TypedKey {
    const std::pair<std::string, std::string>* name = nullptr;
    const KeySet* keys = nullptr;
};

// Cùng tên cột ở tệp khác không phải cha của dòng này.
[[nodiscard]] bool owns_parent(const Rule& rule, TextView path) {
    const GlobQuery query{.pattern = rule.parent, .path = path};
    return match_glob(query).matched;
}

void report_clash(const Rule& rule, TextView child_type, const TypedKey& typed, IssueList& issues) {
    if (typed.name->second != rule.parent_column || !typed.keys->typed) return;
    if (!owns_parent(rule, typed.name->first)) return;
    if (typed.keys->type == child_type) return;
    add_issue(issues, rule.path, rule.line, "cột con và cột cha khác kiểu");
}

struct ClashScan {
    bool saw_parent = false;
    bool clashed = false;
};

struct ClashProbe {
    const Rule* rule = nullptr;
    const TypeClash* clash = nullptr;
    ClashScan* scan = nullptr;
};

void scan_parent_type(const ClashProbe& probe, const TypedKey& typed) {
    if (typed.name->second != probe.rule->parent_column || !typed.keys->typed) return;
    if (!owns_parent(*probe.rule, typed.name->first)) return;
    probe.scan->saw_parent = true;
    if (typed.keys->type != probe.clash->type) probe.scan->clashed = true;
}

struct ClashReport {
    const Rule* rule = nullptr;
    const TypeClash* clash = nullptr;
    const Session* session = nullptr;
    IssueList* issues = nullptr;
};

using NamePair = std::pair<std::string, std::string>;

void scan_key(const ClashProbe& probe, const NamePair& name, const KeySet& keys) {
    const TypedKey typed{.name = &name, .keys = &keys};
    scan_parent_type(probe, typed);
}

void report_one_clash(const ClashReport& report) {
    if (report.clash->type == "float") {
        add_issue(*report.issues, report.clash->path, 1, "cột tham chiếu là float");
        return;
    }
    ClashScan scan;
    ClashProbe probe;
    probe.rule = report.rule;
    probe.clash = report.clash;
    probe.scan = &scan;
    for (const auto& entry : report.session->keys)
        scan_key(probe, entry.first, entry.second);
    if (!scan.clashed && scan.saw_parent) return;
    add_issue(*report.issues, report.clash->path, 1, "cột con và cột cha khác kiểu");
}

void bind_clash(ClashReport& report, const TypeClash& clash) {
    report.clash = &clash;
    report_one_clash(report);
}

void report_clashes(const Rule& rule, const Totals& totals, const Session& state, IssueList& out) {
    ClashReport report;
    report.rule = &rule;
    report.session = &state;
    report.issues = &out;
    for (const TypeClash& clash : totals.clashes)
        bind_clash(report, clash);
}

void agree_types(const Rule& rule, const Totals& totals, const Session& state, IssueList& out) {
    report_clashes(rule, totals, state, out);
    if (!totals.typed) return;
    if (totals.type == "float") {
        add_issue(out, rule.path, rule.line, "cột tham chiếu là float");
        return;
    }
    for (const auto& entry : state.keys) {
        const TypedKey typed{.name = &entry.first, .keys = &entry.second};
        report_clash(rule, totals.type, typed, out);
    }
}

void check_hits(const Rule& rule, const Totals& totals, Count parents, IssueList& issues) {
    if (totals.files == 0) add_issue(issues, rule.path, rule.line, "mẫu không khớp tệp nào");
    if (parents == 0) add_issue(issues, rule.path, rule.line, "mẫu không khớp tệp nào");
}

[[nodiscard]] CoverageRow row_of(const Rule& rule, const Totals& totals, const Tally& tally) {
    CoverageRow row;
    row.child = rule.child;
    row.child_column = rule.child_column;
    row.parent = rule.parent;
    row.parent_column = rule.parent_column;
    row.child_files = totals.files;
    row.child_rows = totals.rows;
    row.references = static_cast<Count>(totals.refs.size());
    row.distinct_values = static_cast<Count>(tally.distinct.size());
    row.missing_values = static_cast<Count>(tally.missing.size());
    row.missing_rows = tally.missing_rows;
    const bool as_int = totals.type == "int";
    const std::vector<Pair> missing = sorted_missing(tally.missing, as_int);
    row.first_missing = join_missing(missing, rule.parent_star);
    return row;
}

void note_gap(const Rule& rule, const Tally& tally, IssueList& issues) {
    if (!rule.known_ok) return;
    if (tally.missing.size() == static_cast<std::size_t>(rule.known_missing)) return;
    const auto missing = static_cast<Count>(tally.missing.size());
    const std::string message = "số giá trị thiếu " + std::to_string(missing);
    const std::string known = " khác known_missing " + std::to_string(rule.known_missing);
    add_issue(issues, rule.path, rule.line, message + known);
}

void finish_rule(Session& session, const Rule& rule, const Totals& totals, Count parents) {
    check_hits(rule, totals, parents, session.issues);
    agree_types(rule, totals, session, session.issues);
    const Tally tally = tally_rule(session, rule, totals);
    note_gap(rule, tally, session.issues);
    session.coverage.push_back(row_of(rule, totals, tally));
}

void append_field(std::string& text, TextView value, bool last) {
    text.append(value);
    text.push_back(last ? '\n' : '\t');
}

void append_number(std::string& text, Count value, bool last) {
    append_field(text, std::to_string(value), last);
}

void append_row(std::string& text, const CoverageRow& row) {
    append_field(text, row.child, false);
    append_field(text, row.child_column, false);
    append_field(text, row.parent, false);
    append_field(text, row.parent_column, false);
    append_number(text, row.child_files, false);
    append_number(text, row.child_rows, false);
    append_number(text, row.references, false);
    append_number(text, row.distinct_values, false);
    append_number(text, row.missing_values, false);
    append_number(text, row.missing_rows, false);
    append_field(text, row.first_missing, true);
}

} // namespace

TableTaps::TableTaps(CoverageState& state, const TextFile& file, const TableHead& head)
    : state_(&state), path_(file.path) {
    const Opening opening{.state = &state, .file = &file, .head = &head, .taps = &list_};
    for (std::size_t slot = 0; slot < state.rules.size(); ++slot) {
        tap_child(opening, slot);
        tap_parent(opening, slot);
    }
}

void TableTaps::take_cell(const ColumnTap& tap, const Record& record) {
    const Rule& rule = state_->rules[tap.rule];
    const TextView cell = record.cells[tap.column];
    if (tap.keys == nullptr) {
        take_child(state_->children[tap.rule], cell, rule.absent, tap.capture);
        return;
    }
    const Blame blame{.path = path_, .line = record.line, .issues = &state_->issues};
    take_parent(*tap.keys, cell, rule.parent_column, blame);
}

void TableTaps::take(const Record& record) {
    for (const ColumnTap& tap : list_.columns) {
        take_cell(tap, record);
    }
}

void TableTaps::close(std::int64_t records) {
    for (const std::size_t slot : list_.child_rules) {
        state_->children[slot].rows += records;
    }
}

void finish_coverage(CoverageState& state) {
    for (std::size_t index = 0; index < state.rules.size(); ++index) {
        finish_rule(state, state.rules[index], state.children[index], state.parent_files[index]);
    }
}

std::string coverage_report(std::span<const CoverageRow> rows) {
    std::string text = "# schema 1\n";
    text += "# types: text\ttext\ttext\ttext\tint\tint\tint\tint\tint\tint\ttext\n";
    text += "child\tchild_column\tparent\tparent_column\tchild_files\tchild_rows\t";
    text += "references\tdistinct_values\tmissing_values\tmissing_rows\tfirst_missing\n";
    for (const CoverageRow& row : rows)
        append_row(text, row);
    return text;
}

} // namespace game::content
