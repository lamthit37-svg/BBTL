// Ghép năm việc kiểm thành một phiên. Mỗi tệp được đọc theo từng bản ghi rồi bỏ: thứ phiên giữ lại
// sau một tệp chỉ là các ô trỏ và tập khoá mà dòng refs cần.
#include "content/lint.hpp"

#include "content/coverage.hpp"
#include "content/ref_rule.hpp"
#include "content/table_text.hpp"
#include "core/check.hpp"

#include <algorithm>
#include <cstdint>
#include <memory>
#include <string_view>
#include <utility>

namespace game::content {

LintSession::LintSession(TextList refs) : state_(std::make_unique<CoverageState>()) {
    for (const TextFile& file : refs) {
        read_ref_file(file, state_->rules, state_->issues);
    }
    state_->children.resize(state_->rules.size());
    state_->parent_files.resize(state_->rules.size());
}

LintSession::~LintSession() = default;
LintSession::LintSession(LintSession&&) noexcept = default;
LintSession& LintSession::operator=(LintSession&&) noexcept = default;

void LintSession::feed(const TextFile& file) {
    core::check(state_ != nullptr, "phiên lint đã chốt");
    CoverageState& state = *state_;
    state.stats.files += 1;
    const TableHead head = read_head(file, state.issues);
    if (!head.is_readable) return;
    TableTaps taps{state, file, head};
    CellChecker checker{file, head, state.issues};
    RecordReader reader{file, head};
    Record record;
    std::int64_t records = 0;
    while (reader.next(record, state.issues)) {
        checker.check(record);
        taps.take(record);
        ++records;
    }
    taps.close(records);
    state.stats.records += records;
    state.stats.cells += records * static_cast<std::int64_t>(head.columns.size());
}

LintResult LintSession::finish() {
    core::check(state_ != nullptr, "phiên lint đã chốt");
    const std::unique_ptr<CoverageState> state = std::move(state_);
    finish_coverage(*state);
    LintResult result;
    result.issues = std::move(state->issues);
    result.coverage = std::move(state->coverage);
    result.stats = state->stats;
    result.stats.ref_rows = static_cast<std::int64_t>(state->rules.size());
    result.stats.errors = static_cast<std::int64_t>(result.issues.size());
    return result;
}

LintResult lint_texts(const LintSources& sources) {
    LintSession session{sources.refs};
    for (const TextFile& file : sources.files) {
        session.feed(file);
    }
    return session.finish();
}

bool is_tsv_extension(std::string_view extension) noexcept {
    constexpr std::string_view kLower = ".tsv";
    const auto same = [](char left, char right) {
        const bool is_upper = left >= 'A' && left <= 'Z';
        return (is_upper ? static_cast<char>(left - 'A' + 'a') : left) == right;
    };
    return std::ranges::equal(extension, kLower, same);
}

} // namespace game::content
