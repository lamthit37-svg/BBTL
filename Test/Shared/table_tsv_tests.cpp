// Kiểm bố cục căn cột của bảng TSV (core/aligned.hpp, table/tsv.hpp): ô bỏ đệm dấu cách ở cuối, kSpaceMark cuối ô là
// dấu cách thật, bố cục lạ bị từ chối, bảng không khai bố cục đọc nguyên văn như trước, và unpad.
#include "core/aligned.hpp"
#include "core/check.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <array>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

constexpr std::string_view kHead = "# schema 1\n# types: int\ttext\ttext\n";

[[nodiscard]] std::string aligned(std::string_view body) {
    return std::string(kHead) + std::string(core::kAlignedLayout) + "\n" + std::string(body);
}

void padding_is_dropped(Context& context) {
    const std::string text = aligned("id  \tname    \tnote\n1   \tab      \tx\n22  \t        \t\n");
    const table::TsvResult parsed = table::parse_tsv(text);
    context.expect(parsed.has_value(), "bảng căn cột đọc được");
    if (!parsed) return;
    context.expect(parsed->header == std::vector<std::string>{"id", "name", "note"}, "tên cột bỏ đệm");
    context.expect(parsed->rows.size() == 2, "hai bản ghi");
    context.expect(parsed->rows[0][1] == "ab" && parsed->rows[0][2] == "x", "ô bỏ đệm");
    context.expect(parsed->rows[1][1].empty() && parsed->rows[1][2].empty(), "ô toàn đệm là ô rỗng");
}

void space_mark_restores_trailing_spaces(Context& context) {
    const std::string mark(core::kSpaceMark);
    const table::TsvResult parsed = table::parse_tsv(aligned("a   \tb\n x" + mark + mark + "  \t" + mark + "\n"));
    context.expect(parsed.has_value() && parsed->rows.size() == 1, "đọc được");
    if (!parsed || parsed->rows.empty()) return;
    context.expect(parsed->rows[0][0] == " x  ", "dấu cách đầu giữ, hai ký hiệu thành hai dấu cách");
    context.expect(parsed->rows[0][1] == " ", "ô chỉ có ký hiệu là một dấu cách");
}

void plain_table_is_verbatim(Context& context) {
    const table::TsvResult parsed = table::parse_tsv(std::string(kHead) + "a\tb\tc\n1  \tx \t\xE2\x90\xA3\n");
    context.expect(parsed.has_value() && parsed->rows.size() == 1, "đọc được");
    if (!parsed || parsed->rows.empty()) return;
    context.expect(parsed->rows[0][0] == "1  " && parsed->rows[0][1] == "x ", "dấu cách cuối là dữ liệu");
    context.expect(parsed->rows[0][2] == core::kSpaceMark, "ký hiệu không đổi khi không căn cột");
}

void unknown_layout_is_refused(Context& context) {
    const table::TsvResult unknown = table::parse_tsv(std::string(kHead) + "# layout: wide\na\tb\tc\n");
    context.expect(!unknown.has_value(), "bố cục lạ trước tên cột là lỗi");
    const table::TsvResult late = table::parse_tsv(std::string(kHead) + "a\tb\tc\n# layout: wide\n1\t2\t3\n");
    context.expect(late.has_value() && late->rows.size() == 1, "sau tên cột chỉ là chú thích");
}

void short_row_is_still_refused(Context& context) {
    context.expect(!table::parse_tsv(aligned("a   \tb   \tc\n1   \t2\n")).has_value(), "thiếu ô vẫn là lỗi");
}

void unpad_cell(Context& context) {
    const core::AlignedCell blank = core::unpad("   ");
    context.expect(blank.body.empty() && blank.trailing_spaces == 0, "toàn dấu cách là ô rỗng");
    const core::AlignedCell marks = core::unpad("ab\xE2\x90\xA3\xE2\x90\xA3   ");
    context.expect(marks.body == "ab" && marks.trailing_spaces == 2, "bỏ đệm rồi tách hai ký hiệu");
    const core::AlignedCell inner = core::unpad(" a b ");
    context.expect(inner.body == " a b" && inner.trailing_spaces == 0, "dấu cách đầu và giữa là dữ liệu");
    const core::AlignedCell lone = core::unpad("\xE2\x90\xA3");
    context.expect(lone.body.empty() && lone.trailing_spaces == 1, "chỉ một ký hiệu");
}

constexpr std::array kCases{
    Case{.name = "padding_is_dropped", .body = &padding_is_dropped},
    Case{.name = "space_mark_restores_trailing_spaces", .body = &space_mark_restores_trailing_spaces},
    Case{.name = "plain_table_is_verbatim", .body = &plain_table_is_verbatim},
    Case{.name = "unknown_layout_is_refused", .body = &unknown_layout_is_refused},
    Case{.name = "short_row_is_still_refused", .body = &short_row_is_still_refused},
    Case{.name = "unpad_cell", .body = &unpad_cell},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "table_tsv_tests: mọi ca phải qua");
    return 0;
}
