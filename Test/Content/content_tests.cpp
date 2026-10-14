// Kiểm K1–K5, khớp *, biên int32 và thứ tự first_missing. Dữ liệu là chuỗi, không phải tệp.
#include "content/lint.hpp"
#include "core/check.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using content::CoverageRow;
using View = std::string_view;
using Text = std::string;
using content::Issue;
using content::LintResult;
using content::TextFile;

[[nodiscard]] std::string sheet(View types, View header, View body) {
    std::string text = "# schema 1\n# types: ";
    text += types;
    text += '\n';
    text += header;
    text += '\n';
    text += body;
    if (text.empty() || text.back() != '\n') text.push_back('\n');
    return text;
}

[[nodiscard]] std::string_view ref_header() {
    return "# schema 1\n# types: text\ttext\ttext\ttext\ttext\tint\ttext\ttext\n"
           "child\tchild_column\tparent\tparent_column\tabsent\tknown_missing\tbasis\tnote\n";
}

[[nodiscard]] std::string ref_row(std::string_view row) {
    std::string text = "# schema 1\n# types: text\ttext\ttext\ttext\ttext\tint\ttext\ttext\n";
    text += "child\tchild_column\tparent\tparent_column\tabsent\tknown_missing\tbasis\tnote\n";
    text += row;
    if (!text.ends_with('\n')) text.push_back('\n');
    return text;
}

[[nodiscard]] bool message_has(const Issue& issue, std::string_view part) {
    return issue.message.contains(part);
}

[[nodiscard]] bool has_message(const LintResult& result, std::string_view part) {
    bool found = false;
    for (const Issue& issue : result.issues)
        found = found || message_has(issue, part);
    return found;
}

[[nodiscard]] LintResult lint_one(const Text& path, const Text& text, const Text& refs) {
    const TextFile file{.path = path, .text = text};
    const TextFile ref{.path = "refs/scenes.tsv", .text = refs};
    const std::array<TextFile, 1> files{file};
    const std::array<TextFile, 1> ref_files{ref};
    const content::LintSources sources{.files = files, .refs = ref_files};
    return content::lint_texts(sources);
}

[[nodiscard]] LintResult lint_files(std::span<const TextFile> files, const std::string& refs) {
    const TextFile ref{.path = "refs/scenes.tsv", .text = refs};
    const std::array<TextFile, 1> ref_files{ref};
    const content::LintSources sources{.files = files, .refs = ref_files};
    return content::lint_texts(sources);
}

void k1_file_shape(Context& context) {
    const std::string good = sheet("int", "n", "1\n");
    const std::string refs(ref_header());
    const LintResult ok = lint_one("tables/a.tsv", good, refs);
    context.expect(ok.stats.errors == 0, "bảng đủ schema thì không lỗi");
    context.expect(ok.stats.files == 1 && ok.stats.records == 1 && ok.stats.cells == 1, "đếm tệp và ô");
    const std::string bom = std::string("\xEF\xBB\xBF") + good;
    context.expect(has_message(lint_one("tables/a.tsv", bom, refs), "BOM"), "BOM là lỗi");
    const std::string crlf_file = "# schema 1\r\n# types: int\r\nn\r\n1\r\n";
    context.expect(has_message(lint_one("tables/a.tsv", crlf_file, refs), "CR"), "CR là lỗi");
    const std::string cut = "# schema 1\n# types: int\nn\n1";
    context.expect(has_message(lint_one("tables/a.tsv", cut, refs), "xuống dòng"), "thiếu LF cuối");
    const std::string bare = "# types: int\nn\n1\n";
    context.expect(has_message(lint_one("tables/a.tsv", bare, refs), "schema"), "thiếu schema");
    const std::string bad_row = sheet("int", "n", "1\t2\n");
    context.expect(has_message(lint_one("tables/a.tsv", bad_row, refs), "không đọc được"), "parse_tsv từ chối");
    const std::string missing = ref_row("no/such.tsv\tn\tother.tsv\tn\t\t0\tdata\tx\n");
    context.expect(has_message(lint_one("tables/a.tsv", good, missing), "không khớp"), "mẫu không khớp tệp");
}

void k2_columns(Context& context) {
    const std::string refs(ref_header());
    const std::string name = sheet("int", "No", "1\n");
    context.expect(has_message(lint_one("tables/a.tsv", name, refs), "tên cột"), "tên hoa là lỗi");
    const std::string dup = sheet("int\tint", "a\ta", "1\t2\n");
    context.expect(has_message(lint_one("tables/a.tsv", dup, refs), "lặp"), "tên cột lặp");
    const std::string kind = sheet("string", "n", "a\n");
    context.expect(has_message(lint_one("tables/a.tsv", kind, refs), "kiểu"), "kiểu lạ");
    const std::string count = sheet("int\ttext", "n", "1\n");
    context.expect(has_message(lint_one("tables/a.tsv", count, refs), "số kiểu"), "thiếu kiểu");
    const std::string good = sheet("int\ttext", "n\tname", "1\ta\n");
    context.expect(lint_one("tables/a.tsv", good, refs).stats.errors == 0, "tên và kiểu đúng thì qua");
}

void k3_int_bounds(Context& context) {
    const std::string refs(ref_header());
    const std::string edge = sheet("int\tint", "lo\thi", "-2147483648\t2147483647\n");
    context.expect(lint_one("tables/a.tsv", edge, refs).stats.errors == 0, "hai biên int32 hợp lệ");
    const std::string zero = sheet("int", "n", "040001\n");
    const LintResult padded = lint_one("tables/a.tsv", zero, refs);
    context.expect(has_message(padded, "int"), "số 0 đứng đầu là lỗi");
    const bool padded_line = !padded.issues.empty() && padded.issues[0].line == 4;
    context.expect(padded_line, "lỗi int đúng dòng dữ liệu");
    const std::string high = sheet("int", "n", "2147483648\n");
    context.expect(has_message(lint_one("tables/a.tsv", high, refs), "int"), "vượt int32 dương");
    const std::string low = sheet("int", "n", "-2147483649\n");
    context.expect(has_message(lint_one("tables/a.tsv", low, refs), "int"), "vượt int32 âm");
    const std::string empty = sheet("int\tint", "a\tb", "1\t\n");
    context.expect(lint_one("tables/a.tsv", empty, refs).stats.errors == 0, "ô int rỗng hợp lệ");
}

void k3_float(Context& context) {
    const std::string refs(ref_header());
    const std::string good = sheet("float\tfloat\tfloat", "a\tb\tc", "1.5\t.5\t1e-2\n");
    context.expect(lint_one("tables/a.tsv", good, refs).stats.errors == 0, "số thực hữu hạn hợp lệ");
    const std::string dot = sheet("float", "a", "1.\n");
    context.expect(has_message(lint_one("tables/a.tsv", dot, refs), "float"), "dấu chấm trần là lỗi");
    const std::string huge = sheet("float", "a", "1e9999\n");
    context.expect(has_message(lint_one("tables/a.tsv", huge, refs), "float"), "vô hạn là lỗi");
    const std::string space = sheet("float", "a", "1.5 \n");
    context.expect(has_message(lint_one("tables/a.tsv", space, refs), "float"), "float có trắng là lỗi");
}

void k4_parent_key(Context& context) {
    const std::string child = sheet("int", "id", "1\n");
    const std::string dup = sheet("int", "id", "1\n1\n");
    const std::string refs = ref_row("tables/c.tsv\tid\ttables/p.tsv\tid\t\t0\tdata\tx\n");
    const std::array<TextFile, 2> files{{
        TextFile{.path = "tables/c.tsv", .text = child},
        TextFile{.path = "tables/p.tsv", .text = dup},
    }};
    const LintResult repeated = lint_files(files, refs);
    context.expect(has_message(repeated, "lặp giá trị"), "khoá cha lặp");
    const std::string hole = sheet("int\tint", "id\textra", "1\t0\n\t0\n");
    const std::array<TextFile, 2> holed{{
        TextFile{.path = "tables/c.tsv", .text = child},
        TextFile{.path = "tables/p.tsv", .text = hole},
    }};
    context.expect(has_message(lint_files(holed, refs), "ô rỗng"), "khoá cha rỗng");
    const std::string once = sheet("int", "id", "1\n");
    const std::array<TextFile, 2> fine{{
        TextFile{.path = "tables/c.tsv", .text = child},
        TextFile{.path = "tables/p.tsv", .text = once},
    }};
    context.expect(lint_files(fine, refs).stats.errors == 0, "khoá cha duy nhất thì qua");
    const std::string shared = ref_row("tables/c.tsv\tid\ttables/p.tsv\tid\t\t0\tdata\tx\n"
                                       "tables/d.tsv\tid\ttables/p.tsv\tid\t\t0\tdata\tx\n");
    const std::array<TextFile, 3> both{{
        TextFile{.path = "tables/c.tsv", .text = child},
        TextFile{.path = "tables/d.tsv", .text = child},
        TextFile{.path = "tables/p.tsv", .text = once},
    }};
    context.expect(lint_files(both, shared).stats.errors == 0, "hai dòng refs cùng cột cha");
    const std::array<TextFile, 3> both_dup{{
        TextFile{.path = "tables/c.tsv", .text = child},
        TextFile{.path = "tables/d.tsv", .text = child},
        TextFile{.path = "tables/p.tsv", .text = dup},
    }};
    context.expect(has_message(lint_files(both_dup, shared), "lặp giá trị"), "lặp thật vẫn là lỗi");
}

void plain_distinct(Context& context) {
    const std::string spawn_a = sheet("int", "type", "2\n9\n");
    const std::string spawn_b = sheet("int", "type", "9\n");
    const std::string monsters = sheet("int", "monster_id", "2\n");
    const std::string refs = ref_row("scenes/*/spawns.tsv\ttype\ttables/monsters.tsv\tmonster_id\t\t1\tdata\tx\n");
    const std::array<TextFile, 3> files{{
        TextFile{.path = "scenes/a/spawns.tsv", .text = spawn_a},
        TextFile{.path = "scenes/b/spawns.tsv", .text = spawn_b},
        TextFile{.path = "tables/monsters.tsv", .text = monsters},
    }};
    const LintResult result = lint_files(files, refs);
    const bool ok = !result.coverage.empty();
    const CoverageRow row = ok ? result.coverage[0] : CoverageRow{};
    context.expect(ok && result.stats.errors == 0, "cùng giá trị thiếu ở hai cảnh vẫn là một");
    context.expect(ok && row.distinct_values == 2, "cha không có * thì gộp cảnh");
    context.expect(ok && row.missing_values == 1, "giá trị thiếu gộp cảnh");
    context.expect(ok && row.missing_rows == 2, "mỗi ô thiếu một dòng");
    context.expect(ok && row.references == 3, "mỗi ô một tham chiếu");
}

void k5_missing(Context& context) {
    const std::string child = sheet("int", "id", "2\n-1\n");
    const std::string parent = sheet("int", "id", "1\n");
    const std::string bad = ref_row("tables/c.tsv\tid\ttables/p.tsv\tid\t-1\t0\tdata\tx\n");
    const std::array<TextFile, 2> files{{
        TextFile{.path = "tables/c.tsv", .text = child},
        TextFile{.path = "tables/p.tsv", .text = parent},
    }};
    const LintResult wrong = lint_files(files, bad);
    context.expect(has_message(wrong, "số giá trị thiếu 1"), "ghi số thiếu");
    context.expect(has_message(wrong, "known_missing 0"), "ghi known_missing");
    const bool refs_path = !wrong.issues.empty() && wrong.issues[0].path == "refs/scenes.tsv";
    context.expect(refs_path, "lỗi K5 trỏ tệp refs");
    const std::string good = ref_row("tables/c.tsv\tid\ttables/p.tsv\tid\t-1\t1\tdata\tx\n");
    const LintResult match = lint_files(files, good);
    context.expect(match.stats.errors == 0, "known_missing khớp thì qua");
    context.expect(match.coverage.size() == 1, "một dòng refs một dòng phủ");
    const bool covered = match.coverage.size() == 1;
    const CoverageRow row = covered ? match.coverage[0] : CoverageRow{};
    context.expect(covered && row.references == 1, "ô -1 không phải tham chiếu");
    context.expect(covered && row.missing_values == 1, "một giá trị thiếu");
    context.expect(covered && row.missing_rows == 1, "một ô mang giá trị thiếu");
    context.expect(covered && row.first_missing == "2", "giá trị thiếu đầu");
}

void star_and_order(Context& context) {
    const std::string spawn_a = sheet("int", "type", "10\n2\n");
    const std::string spawn_b = sheet("int", "type", "2\n");
    const std::string monsters = sheet("int", "monster_id", "2\n");
    const std::string refs = ref_row("scenes/*/spawns*.tsv\ttype\ttables/monsters.tsv\tmonster_id\t\t1\tdata\tx\n");
    const std::array<TextFile, 4> files{{
        TextFile{.path = "scenes/a/spawns.level_1.tsv", .text = spawn_b},
        TextFile{.path = "scenes/a/spawns.tsv", .text = spawn_a},
        TextFile{.path = "scenes/b/notes.tsv", .text = monsters},
        TextFile{.path = "tables/monsters.tsv", .text = monsters},
    }};
    const LintResult result = lint_files(files, refs);
    context.expect(result.stats.errors == 0, "mẫu * khớp và known_missing đúng");
    const bool starred = !result.coverage.empty();
    const CoverageRow star = starred ? result.coverage[0] : CoverageRow{};
    context.expect(starred && star.child_files == 2, "* không vượt qua dấu /");
    context.expect(starred && star.child_rows == 3, "cộng bản ghi mọi tệp con");
    context.expect(starred && star.distinct_values == 2, "hai giá trị khác nhau");
    context.expect(starred && star.first_missing == "10", "thiếu 10");
    const std::string many = sheet("int", "id", "10\n2\n3\n9\n8\n4\n");
    const std::string none = sheet("int", "id", "1\n");
    const std::string order_refs = ref_row("tables/c.tsv\tid\ttables/p.tsv\tid\t\t6\tdata\tx\n");
    const std::array<TextFile, 2> ordered{{
        TextFile{.path = "tables/c.tsv", .text = many},
        TextFile{.path = "tables/p.tsv", .text = none},
    }};
    const LintResult ordered_result = lint_files(ordered, order_refs);
    const bool ordered_ok = !ordered_result.coverage.empty();
    const std::string ordered_missing = ordered_ok ? ordered_result.coverage[0].first_missing : "";
    context.expect(ordered_missing == "2;3;4;8;9", "int xếp theo số, lấy năm");
}

void star_parent(Context& context) {
    const std::string spawn_a = sheet("int", "patrol", "10\n");
    const std::string spawn_b = sheet("int", "patrol", "2\n");
    const std::string patrol_a = sheet("int", "id", "1\n");
    const std::string refs = ref_row("scenes/*/spawns.tsv\tpatrol\tscenes/*/patrols.tsv\tid\t\t2\tdata\tx\n");
    const std::array<TextFile, 3> files{{
        TextFile{.path = "scenes/a/spawns.tsv", .text = spawn_a},
        TextFile{.path = "scenes/b/spawns.tsv", .text = spawn_b},
        TextFile{.path = "scenes/a/patrols.tsv", .text = patrol_a},
    }};
    const LintResult result = lint_files(files, refs);
    context.expect(result.stats.errors == 0, "cảnh thiếu tệp cha tính là thiếu");
    const bool paired = !result.coverage.empty();
    const CoverageRow pair = paired ? result.coverage[0] : CoverageRow{};
    context.expect(paired && pair.missing_values == 2, "đếm cặp cảnh và giá trị");
    context.expect(paired && pair.first_missing == "a:10;b:2", "xếp theo cảnh rồi theo số");
    const std::string report = content::coverage_report(result.coverage);
    context.expect(report.starts_with("# schema 1\n"), "báo cáo có schema");
    context.expect(report.contains("child\tchild_column\t"), "báo cáo có dòng tên cột");
    context.expect(report.contains("scenes/*/spawns.tsv\tpatrol\tscenes/*/patrols.tsv\tid\t"),
        "dòng phủ giữ nguyên mẫu");
}

void known_missing_text(Context& context) {
    const std::string child = sheet("int", "id", "1\n");
    const std::string blank = ref_row("tables/a.tsv\tid\ttables/a.tsv\tid\t\t\tdata\ttrống\n");
    const LintResult empty = lint_one("tables/a.tsv", child, blank);
    context.expect(has_message(empty, "không phải số nguyên"), "known_missing rỗng là lỗi");
    const bool on_line = !empty.issues.empty() && empty.issues[0].line == 4;
    const bool on_path = on_line && empty.issues[0].path == "refs/scenes.tsv";
    context.expect(on_path, "lỗi known_missing đúng tệp và dòng");
    context.expect(empty.coverage.size() == 1, "dòng refs rỗng vẫn nằm trong báo cáo");
    context.expect(empty.stats.ref_rows == 1 && empty.stats.errors >= 1, "đếm dòng và lỗi");
    const std::string word = ref_row("tables/a.tsv\tid\ttables/a.tsv\tid\t\tx\tdata\tchữ\n");
    const LintResult text = lint_one("tables/a.tsv", child, word);
    context.expect(has_message(text, "không phải số nguyên"), "known_missing chữ là lỗi");
    context.expect(text.coverage.size() == 1, "dòng refs chữ vẫn nằm trong báo cáo");
}

void ref_shape(Context& context) {
    const std::string good = sheet("int", "n", "1\n");
    const std::string swapped = "# schema 1\n# types: text\ttext\ttext\ttext\ttext\tint\ttext\ttext\n"
                                "child_column\tchild\tparent\tparent_column\tabsent\tknown_missing\tbasis\tnote\n"
                                "tables/a.tsv\tn\ttables/a.tsv\tn\t\t0\tdata\tx\n";
    const LintResult header = lint_one("tables/a.tsv", good, swapped);
    context.expect(has_message(header, "tên cột"), "đổi thứ tự cột refs là lỗi");
    const std::string two = ref_row("tables/a*b*.tsv\tn\ttables/a.tsv\tn\t\t0\tdata\tx\n");
    const LintResult stars = lint_one("tables/a.tsv", good, two);
    context.expect(has_message(stars, "sai hình"), "hai dấu * trong một đoạn là lỗi hình dạng");
}

void feed_matches_batch(Context& context) {
    const std::string child = sheet("int", "id", "1\n");
    const std::string parent = sheet("int", "id", "1\n");
    const std::string refs = ref_row("tables/c.tsv\tid\ttables/p.tsv\tid\t\t0\tdata\tx\n");
    const TextFile child_file{.path = "tables/c.tsv", .text = child};
    const TextFile parent_file{.path = "tables/p.tsv", .text = parent};
    const std::array<TextFile, 2> files{{child_file, parent_file}};
    const LintResult batch = lint_files(files, refs);
    const TextFile ref{.path = "refs/scenes.tsv", .text = refs};
    const std::array<TextFile, 1> ref_files{ref};
    content::LintSession session{ref_files};
    session.feed(child_file);
    session.feed(parent_file);
    const LintResult streamed = session.finish();
    context.expect(streamed.stats.errors == batch.stats.errors, "đưa từng tệp cùng số lỗi");
    context.expect(streamed.stats.cells == batch.stats.cells, "đưa từng tệp cùng số ô");
    const std::string left = content::coverage_report(streamed.coverage);
    const std::string right = content::coverage_report(batch.coverage);
    context.expect(left == right, "báo cáo từng tệp trùng cả lô");
}

void tsv_extension_case(Context& context) {
    context.expect(content::is_tsv_extension(".tsv"), "đuôi thường là tsv");
    context.expect(content::is_tsv_extension(".TSV"), "đuôi hoa vẫn là tsv");
    context.expect(content::is_tsv_extension(".Tsv"), "đuôi lẫn hoa thường vẫn là tsv");
    context.expect(!content::is_tsv_extension(".txt"), "đuôi txt không phải tsv");
    context.expect(!content::is_tsv_extension("tsv"), "thiếu dấu chấm thì không phải đuôi");
}

void hash_data_row(Context& context) {
    const std::string child = sheet("int", "id", "1\n#3364\n");
    const std::string parent = sheet("int", "id", "1\n");
    const std::string refs = ref_row("tables/child.tsv\tid\ttables/parent.tsv\tid\t\t0\tdata\tx\n");
    const std::array<TextFile, 2> files{{
        TextFile{.path = "tables/child.tsv", .text = child},
        TextFile{.path = "tables/parent.tsv", .text = parent},
    }};
    const LintResult result = lint_files(files, refs);
    context.expect(result.stats.errors != 0, "ô đầu bắt đầu bằng # không được thoát sạch");
    context.expect(result.stats.records == 3, "dòng # vẫn là một bản ghi");
    bool on_line = false;
    for (const Issue& issue : result.issues) {
        const bool path_ok = issue.path == "tables/child.tsv" && issue.line == 5;
        on_line = on_line || (path_ok && message_has(issue, "ô đầu bắt đầu bằng #"));
    }
    context.expect(on_line, "lỗi đúng tệp và đúng dòng của ô #");
}

void child_types_differ(Context& context) {
    const std::string spawn_a = sheet("int", "type", "1\n");
    const std::string spawn_b = sheet("float", "type", "1\n");
    const std::string monsters = sheet("int", "monster_id", "1\n");
    const std::string refs = ref_row("scenes/*/spawns.tsv\ttype\ttables/monsters.tsv\tmonster_id\t\t0\tdata\tx\n");
    const std::array<TextFile, 3> files{{
        TextFile{.path = "scenes/a/spawns.tsv", .text = spawn_a},
        TextFile{.path = "scenes/b/spawns.tsv", .text = spawn_b},
        TextFile{.path = "tables/monsters.tsv", .text = monsters},
    }};
    const LintResult result = lint_files(files, refs);
    context.expect(result.stats.errors != 0, "hai tệp cùng mẫu khác kiểu phải lỗi");
    context.expect(has_message(result, "float"), "cột float của tệp sau vẫn là lỗi");
}

void parent_column_type(Context& context) {
    const std::string parent_int = sheet("int", "id", "1\n");
    const std::string parent_text = sheet("text", "id", "a\n");
    const std::string child_int = sheet("int", "id", "1\n");
    const std::string child_text = sheet("text", "label", "a\n");
    const std::string refs = ref_row("tables/child_int.tsv\tid\ttables/parent_int.tsv\tid\t\t0\tdata\tint\n"
                                     "tables/child_text.tsv\tlabel\ttables/parent_text.tsv\tid\t\t0\tdata\ttext\n");
    const std::array<TextFile, 4> files{{
        TextFile{.path = "tables/child_int.tsv", .text = child_int},
        TextFile{.path = "tables/child_text.tsv", .text = child_text},
        TextFile{.path = "tables/parent_int.tsv", .text = parent_int},
        TextFile{.path = "tables/parent_text.tsv", .text = parent_text},
    }};
    const LintResult same_name = lint_files(files, refs);
    context.expect(same_name.stats.errors == 0, "hai cha cùng tên cột khác kiểu không làm nhau đỏ");
    const std::string clash_refs = ref_row("tables/c.tsv\tid\ttables/p.tsv\tid\t\t1\tdata\tx\n");
    const std::array<TextFile, 2> clash{{
        TextFile{.path = "tables/c.tsv", .text = child_int},
        TextFile{.path = "tables/p.tsv", .text = parent_text},
    }};
    const LintResult clash_result = lint_files(clash, clash_refs);
    context.expect(has_message(clash_result, "khác kiểu"), "đúng tệp cha khác kiểu vẫn là lỗi");
}

void expect_same_as_parse_tsv(Context& context, View body) {
    const std::string text = "# schema 1\n# types: text\n" + std::string(body);
    const table::TsvResult parsed = table::parse_tsv(text);
    const LintResult linted = lint_one("tables/a.tsv", text, std::string(ref_header()));
    const bool is_refused = has_message(linted, "không đọc được");
    context.expect(parsed.has_value() != is_refused, "cùng nhận hoặc cùng từ chối");
    const auto rows = parsed ? static_cast<std::int64_t>(parsed->rows.size()) : 0;
    context.expect(linted.stats.records == rows, "cùng số bản ghi");
}

// Bộ đọc theo dòng của content và table::parse_tsv phải cùng nhận, cùng từ chối, cùng đếm bản ghi:
// máy chủ nạp bảng bằng parse_tsv, nên bảng qua lint mà parse_tsv từ chối là lint vô dụng.
void row_rules_match_parse_tsv(Context& context) {
    constexpr std::array<View, 12> kBodies{
        "n\n1\n2\n",
        "n\tm\n1\t2\n3\n",
        "n\n\n1\n\n2\n",
        "",
        "n\tm\n\t\n",
        "a\tb\n1\t2\t3\n",
        "a\tb\n1\t2\n\t\t\n",
        "n\n1\n-2\n",
        // Bố cục căn cột: đệm dấu cách bỏ đi, dòng bố cục lạ trước tên cột là lỗi. (Dòng "# layout:" sau tên
        // cột là dòng # như mọi dòng #, lint đếm nó là bản ghi; ca đó ở table_tsv_tests.)
        "# layout: aligned\nn   \tm\n1   \t2\n",
        "# layout: aligned\nn   \tm\n1   \t2\t3\n",
        "# layout: wide\nn\n1\n",
        "# layout: aligned\nn\n1\n",
    };
    for (const View body : kBodies) {
        expect_same_as_parse_tsv(context, body);
    }
}

constexpr std::array kCases{
    Case{.name = "row_rules_match_parse_tsv", .body = &row_rules_match_parse_tsv},
    Case{.name = "k1_file_shape", .body = &k1_file_shape},
    Case{.name = "k2_columns", .body = &k2_columns},
    Case{.name = "k3_int_bounds", .body = &k3_int_bounds},
    Case{.name = "k3_float", .body = &k3_float},
    Case{.name = "k4_parent_key", .body = &k4_parent_key},
    Case{.name = "plain_distinct", .body = &plain_distinct},
    Case{.name = "k5_missing", .body = &k5_missing},
    Case{.name = "star_and_order", .body = &star_and_order},
    Case{.name = "star_parent", .body = &star_parent},
    Case{.name = "known_missing_text", .body = &known_missing_text},
    Case{.name = "ref_shape", .body = &ref_shape},
    Case{.name = "feed_matches_batch", .body = &feed_matches_batch},
    Case{.name = "tsv_extension_case", .body = &tsv_extension_case},
    Case{.name = "hash_data_row", .body = &hash_data_row},
    Case{.name = "child_types_differ", .body = &child_types_differ},
    Case{.name = "parent_column_type", .body = &parent_column_type},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "content_tests: mọi ca phải qua");
    return 0;
}
