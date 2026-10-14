// Bộ đọc TSV theo dòng của item (item/rows.hpp): bảng thường, bảng căn cột (đệm dấu cách bỏ đi, dấu cách cuối
// thật qua core::kSpaceMark, bố cục lạ bị từ chối) và các lỗi hình dạng. Bộ đọc này không dùng table::parse_tsv nên
// phải tự giữ cùng luật với nó.
#include "core/aligned.hpp"
#include "core/check.hpp"
#include "item/rows.hpp"
#include "test.hpp"

#include <array>
#include <string>
#include <string_view>

namespace game::test {
namespace {

using item::tsv::Rows;

void plain_table(Context& context) {
    Rows rows("# schema 1\n\nid\tname\n1\tabc \n2\t\n");
    context.expect(!rows.error() && rows.column("name") == 1, "tên cột");
    context.expect(rows.next() && rows.cells()[1] == "abc ", "dấu cách cuối của bảng thường là dữ liệu");
    context.expect(rows.next() && rows.cells()[1].empty() && !rows.next() && !rows.error(), "ô rỗng rồi hết bảng");
}

void aligned_table(Context& context) {
    const std::string mark(core::kSpaceMark);
    const std::string text = std::string("# schema 1\n") + std::string(core::kAlignedLayout) + "\nid  \tname  \tnote\n"
        + "1   \tab    \tx\n" + "22  \t" + " c" + mark + mark + "  \t" + mark + "\n" + "3   \t      \t\n";
    Rows rows(text);
    context.expect(!rows.error() && rows.column("id") == 0 && rows.column("note") == 2, "tên cột bỏ đệm");
    context.expect(rows.next() && rows.cells()[0] == "1" && rows.cells()[1] == "ab" && rows.cells()[2] == "x", "ô bỏ đệm");
    context.expect(rows.next() && rows.cells()[1] == " c  " && rows.cells()[2] == " ", "ký hiệu cuối thành dấu cách");
    context.expect(rows.next() && rows.cells()[1].empty() && rows.cells()[2].empty(), "ô toàn đệm là ô rỗng");
    context.expect(!rows.next() && !rows.error(), "hết bảng");
}

void unknown_layout_is_refused(Context& context) {
    Rows rows("# layout: wide\nid\n1\n");
    context.expect(rows.error().has_value() && !rows.next(), "bố cục lạ trước tên cột là lỗi");
}

void short_row_is_refused(Context& context) {
    const std::string text = std::string(core::kAlignedLayout) + "\nid  \tname\n1   \n";
    Rows rows(text);
    context.expect(!rows.next() && rows.error().has_value(), "thiếu ô là lỗi");
}

constexpr std::array kCases{
    Case{.name = "plain_table", .body = &plain_table},
    Case{.name = "aligned_table", .body = &aligned_table},
    Case{.name = "unknown_layout_is_refused", .body = &unknown_layout_is_refused},
    Case{.name = "short_row_is_refused", .body = &short_row_is_refused},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "item_rows_tests: mọi ca phải qua");
    return 0;
}
