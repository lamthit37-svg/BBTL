// Kiểm bản dịch ô của bảng (table/localize.hpp): ô có bản dịch thì thay, ô không có giữ chữ gốc, id
// hay cột lạ và cột khoá bị bỏ qua có đếm, id lặp dịch dòng gặp trước, lỗi khi thiếu cột, và tên tệp
// bản dịch.
#include "core/check.hpp"
#include "table/localize.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace game::test {
namespace {

[[nodiscard]] table::Tsv must_parse(std::string_view text) {
    table::TsvResult parsed = table::parse_tsv(text);
    core::check(parsed.has_value(), "table_localize_tests: bảng mẫu phải đọc được");
    return std::move(*parsed);
}

constexpr std::string_view kItems = "id\tname\tdescription\n7\t青铜刀\t新手武器\n8\t泼风刀\t青铜打造\n";

void translated_cells_and_fallback(Context& context) {
    table::Tsv items = must_parse(kItems);
    const table::Tsv lang = must_parse("id\tcolumn\ttext\n7\tname\tKiếm đồng\n8\tdescription\t#GĐúc đồng\n");
    const table::LocalizeResult result = table::localize(items, lang);
    context.expect(result.has_value() && result->applied == 2 && result->missed == 0, "hai ô được thay");
    context.expect(items.rows[0][1] == "Kiếm đồng" && items.rows[1][2] == "#GĐúc đồng", "chữ dịch vào đúng ô");
    context.expect(items.rows[0][2] == "新手武器" && items.rows[1][1] == "泼风刀", "ô không có bản dịch giữ chữ gốc");
}

void unknown_rows_are_counted(Context& context) {
    table::Tsv items = must_parse(kItems);
    const table::Tsv lang = must_parse("id\tcolumn\ttext\n9\tname\tx\n7\ticon\tx\n7\tid\t99\n7\tname\tKiếm\n");
    const table::LocalizeResult result = table::localize(items, lang);
    context.expect(result.has_value() && result->applied == 1 && result->missed == 3, "id lạ, cột lạ, cột khoá");
    context.expect(items.rows[0][0] == "7" && items.rows[0][1] == "Kiếm", "cột khoá không đổi");
}

void first_repeated_id_wins(Context& context) {
    table::Tsv items = must_parse("id\tname\n7\ta\n7\tb\n");
    const table::LocalizeResult result = table::localize(items, must_parse("id\tcolumn\ttext\n7\tname\tc\n"));
    context.expect(result.has_value() && items.rows[0][1] == "c" && items.rows[1][1] == "b", "dịch dòng gặp trước");
}

void missing_columns_fail(Context& context) {
    table::Tsv items = must_parse(kItems);
    context.expect(!table::localize(items, must_parse("id\ttext\n7\tx\n")).has_value(), "bản dịch thiếu cột column");
    table::Tsv no_key = must_parse("code\tname\n7\ta\n");
    const table::Tsv lang = must_parse("id\tcolumn\ttext\n7\tname\tx\n");
    context.expect(!table::localize(no_key, lang).has_value(), "bảng không có cột id");
    context.expect(table::localize(no_key, lang, "code").has_value() && no_key.rows[0][1] == "x", "cột khoá khác");
}

void lang_names(Context& context) {
    context.expect(table::lang_name("skills.tsv") == "skills.lang.tsv", "tên bản dịch");
    context.expect(table::lang_name("skills.lang.tsv").empty(), "tệp bản dịch không có bản dịch");
    context.expect(table::lang_name("skills.txt").empty(), "không phải bảng TSV");
    context.expect(table::lang_name("ui_strings.tsv").empty(), "bảng chữ giao diện có bản dịch riêng");
}

constexpr std::array kCases{
    Case{.name = "translated_cells_and_fallback", .body = &translated_cells_and_fallback},
    Case{.name = "unknown_rows_are_counted", .body = &unknown_rows_are_counted},
    Case{.name = "first_repeated_id_wins", .body = &first_repeated_id_wins},
    Case{.name = "missing_columns_fail", .body = &missing_columns_fail},
    Case{.name = "lang_names", .body = &lang_names},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "table_localize_tests: mọi ca phải qua");
    return 0;
}
