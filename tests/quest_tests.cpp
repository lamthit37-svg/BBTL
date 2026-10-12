// Module quest: sổ nhiệm vụ (bit "đã xong", ô đang giữ), bộ đọc hai bảng, bộ lọc nhiệm vụ nhận
// được theo từng phép xét của mã máy Game.exe 2026 (docs/NHIEM-VU-VO-CONG-2026.md), và kết quả trên
// bảng thật của client 2026 cho nhân vật mới khi bản dựng có dữ liệu client.
#include "quest/outline.hpp"

#include "core/check.hpp"
#include "io/file.hpp"
#include "quest/log.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using quest::Log;
using quest::Offers;
using quest::OutlineRow;
using quest::Seeker;

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì ca trên bảng thật tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

constexpr std::string_view kOutlineHead =
    "id\tmission\tkind\tsect\tcolumn_4\tcolumn_5\tlevel\tmin_level\tmax_level\tscene\tnpc\tcolumn_11\tname\t"
    "requires_1\trequires_2\trequires_3\tx\tz\thidden\thidden_original\tname_original\thidden_light\tname_light\t"
    "x_text\tz_text\tcolumn_25\tscene_name\n";
constexpr std::string_view kOutlineLine =
    "1087\t1682\t17\t-1\t0\t0\t1\t1\t31\t6\tNgười bị thương\t\tDuyên khởi\t-1\t-1\t-1\t187\t205\t0\t0\t\t0\t\t\t\t\t"
    "Vô Lượng Sơn\n";

table::Tsv table_of(std::string_view text) {
    table::TsvResult table = table::parse_tsv(text);
    core::check(table.has_value(), "bảng mẫu phải đọc được");
    return std::move(*table);
}

// Một dòng mẫu lọt với nhân vật mới: loại 3, cấp 1..10, không đòi môn phái hay tiền đề.
OutlineRow plain_row(std::int32_t mission) {
    OutlineRow row;
    row.id = mission;
    row.mission = mission;
    row.kind = 3;
    row.level = 5;
    row.min_level = 1;
    row.max_level = 10;
    row.name = "tên";
    return row;
}

// Số nhiệm vụ lọt của một dòng duy nhất với seeker và log.
std::size_t passed(const OutlineRow& row, const Seeker& seeker, const Log& log) {
    const std::array<OutlineRow, 1> rows = {row};
    Offers offers;
    quest::collect_offers(rows, seeker, log, offers);
    return quest::offer_count(offers, row.kind);
}

void done_bits_follow_mission_id(Context& context) {
    Log log;
    context.expect(!quest::is_done(log, 0) && !quest::is_done(log, 4095), "sổ mới chưa xong gì");
    quest::mark_done(log, 0);
    quest::mark_done(log, 33);
    quest::mark_done(log, 4095);
    context.expect(quest::is_done(log, 0) && quest::is_done(log, 33) && quest::is_done(log, 4095), "ba bit đã bật");
    context.expect(log.done[1] == 2U, "id 33 là bit 1 của từ 1");
    context.expect(!quest::is_done(log, 32) && !quest::is_done(log, 34), "bit kề không bật theo");
    quest::mark_done(log, 4096);
    quest::mark_done(log, -1);
    context.expect(!quest::is_done(log, 4096), "id từ 4096 trở lên là chưa xong");
    context.expect(!quest::is_done(log, -1) && !quest::is_done(log, -4096), "id âm là chưa xong");
}

void holding_looks_at_every_slot(Context& context) {
    Log log;
    context.expect(!quest::holds(log, 7), "sổ mới không giữ gì");
    context.expect(!quest::holds(log, -1), "id âm không bao giờ đang giữ dù ô trống mang -1");
    log.slots[19].mission = 7;
    context.expect(quest::holds(log, 7), "ô cuối cũng được xét");
}

void outline_table_reads_every_field(Context& context) {
    const std::string text = std::string(kOutlineHead) + std::string(kOutlineLine);
    const quest::OutlineRows rows = quest::read_outline(table_of(text));
    context.expect(rows.has_value() && rows->size() == 1, "một dòng");
    if (!rows || rows->size() != 1) return;
    const OutlineRow& row = rows->front();
    context.expect(row.id == 1087 && row.mission == 1682 && row.kind == 17, "ba số đầu");
    context.expect(row.sect == quest::kAny && row.level == 1, "môn phái và cấp hiển thị");
    context.expect(row.min_level == 1 && row.max_level == 31 && row.scene == 6, "khoảng cấp và cảnh");
    context.expect(row.needs[0] == -1 && row.needs[1] == -1 && row.needs[2] == -1, "không tiền đề");
    context.expect(row.x == 187 && row.z == 205, "toạ độ");
    context.expect(row.npc == "Người bị thương" && row.name == "Duyên khởi", "tên NPC và tên nhiệm vụ");
    context.expect(row.scene_name == "Vô Lượng Sơn", "tên cảnh nối sẵn");
}

void outline_table_rejects_bad_cells(Context& context) {
    const quest::OutlineRows no_column = quest::read_outline(table_of("id\tmission\n1\t2\n"));
    context.expect(!no_column && no_column.error().contains("kind"), "thiếu cột thì báo tên cột");
    std::string text = std::string(kOutlineHead) + std::string(kOutlineLine);
    text.replace(text.find("1682"), 4, "16x2");
    const quest::OutlineRows bad_number = quest::read_outline(table_of(text));
    context.expect(!bad_number && bad_number.error().contains("mission"), "ô không phải số là lỗi");
    std::string huge = std::string(kOutlineHead) + std::string(kOutlineLine);
    huge.replace(huge.find("1682"), 4, "2147483648");
    context.expect(!quest::read_outline(table_of(huge)), "số vượt 32 bit là lỗi");
}

void kinds_sort_and_title(Context& context) {
    const quest::KindRows kinds = quest::read_kinds(table_of("id\tname\n17\tNúi\n1\tVòng\n17\tLặp\n199\tCuối\n"));
    context.expect(kinds.has_value() && kinds->size() == 3, "id lặp chỉ giữ một dòng");
    if (!kinds) return;
    context.expect(quest::kind_title(*kinds, 17) == "Núi", "id lặp giữ dòng gặp trước");
    context.expect(quest::kind_title(*kinds, 1) == "Vòng" && quest::kind_title(*kinds, 199) == "Cuối", "tra theo id");
    context.expect(quest::kind_title(*kinds, 200) == "0", "loại 200 ra chữ 0 như mã gốc");
    context.expect(quest::kind_title(*kinds, -1) == "0" && quest::kind_title(*kinds, 4000) == "0", "ngoài 0..199");
    context.expect(quest::kind_title(*kinds, 0).empty() && quest::kind_title(*kinds, 5).empty(), "không có dòng");
    context.expect(!quest::read_kinds(table_of("id\nx\n")), "thiếu cột tên là lỗi");
}

void filter_checks_level_window(Context& context) {
    const Log log;
    OutlineRow row = plain_row(40);
    row.min_level = 5;
    row.max_level = 9;
    Seeker seeker;
    seeker.level = 4;
    context.expect(passed(row, seeker, log) == 0, "dưới cấp tối thiểu");
    seeker.level = 5;
    context.expect(passed(row, seeker, log) == 1, "bằng cấp tối thiểu");
    seeker.level = 9;
    context.expect(passed(row, seeker, log) == 1, "bằng cấp tối đa");
    seeker.level = 10;
    context.expect(passed(row, seeker, log) == 0, "trên cấp tối đa");
    seeker.compat_level = 7;
    context.expect(passed(row, seeker, log) == 0, "cấp tương thích PK không dùng ở máy chủ thường");
    seeker.is_pk = true;
    context.expect(passed(row, seeker, log) == 1, "máy chủ PK lấy cấp tương thích khi nó nhỏ hơn");
    seeker.compat_level = 30;
    context.expect(passed(row, seeker, log) == 0, "cấp tương thích lớn hơn thì vẫn là cấp thật");
}

void filter_checks_sect(Context& context) {
    const Log log;
    Seeker seeker;
    seeker.sect = 2;
    OutlineRow row = plain_row(41);
    context.expect(passed(row, seeker, log) == 1, "không đòi môn phái");
    row.sect = 2;
    context.expect(passed(row, seeker, log) == 1, "đúng môn phái");
    row.sect = 3;
    context.expect(passed(row, seeker, log) == 0, "môn phái khác");
    row.sect = 0;
    context.expect(passed(row, seeker, log) == 0, "môn phái 0 cũng là môn phái khác");
    row.sect = quest::kNoSect;
    context.expect(passed(row, seeker, log) == 1, "ô 9 lọt với mọi môn phái");
    row.sect = 16;
    context.expect(passed(row, seeker, log) == 1, "ô ngoài 0..15 không đòi gì");
    row.sect = -2;
    context.expect(passed(row, seeker, log) == 1, "ô âm khác -1 cũng không đòi gì");
}

void filter_checks_kind_done_needs_held(Context& context) {
    Log log;
    const Seeker seeker;
    OutlineRow row = plain_row(42);
    row.kind = 0;
    context.expect(passed(row, seeker, log) == 0, "loại 0 bị bỏ");
    row.kind = 201;
    context.expect(passed(row, seeker, log) == 0, "loại 201 bị bỏ");
    row.kind = 200;
    context.expect(passed(row, seeker, log) == 1, "loại 200 còn trong miền");
    row.kind = 1;
    row.needs = {100, 101, 102};
    context.expect(passed(row, seeker, log) == 0, "chưa xong tiền đề nào");
    quest::mark_done(log, 100);
    quest::mark_done(log, 101);
    context.expect(passed(row, seeker, log) == 0, "còn thiếu tiền đề thứ ba");
    quest::mark_done(log, 102);
    context.expect(passed(row, seeker, log) == 1, "đủ ba tiền đề");
    log.slots[3].mission = 42;
    context.expect(passed(row, seeker, log) == 0, "đang giữ thì không còn nhận được");
    log.slots[3].mission = quest::kNoMission;
    quest::mark_done(log, 42);
    context.expect(passed(row, seeker, log) == 0, "đã xong thì không còn nhận được");
}

void filter_hides_by_realm(Context& context) {
    const Log log;
    OutlineRow row = plain_row(43);
    row.hidden = 1;
    Seeker seeker;
    context.expect(passed(row, seeker, log) == 0, "giấu ở máy chủ thường");
    seeker.is_light = true;
    context.expect(passed(row, seeker, log) == 1, "máy chủ nhẹ xét cột của nó");
    row.hidden_light = 1;
    context.expect(passed(row, seeker, log) == 0, "giấu ở máy chủ nhẹ");
    seeker.is_original = true;
    context.expect(passed(row, seeker, log) == 1, "máy chủ gốc được xét trước máy chủ nhẹ");
    row.hidden_original = 1;
    context.expect(passed(row, seeker, log) == 0, "giấu ở máy chủ gốc");
    row.hidden_original = 2;
    context.expect(passed(row, seeker, log) == 1, "số 2 là hiện với tên riêng, không giấu");
}

void filter_checks_edict_rows(Context& context) {
    Log log;
    Seeker seeker;
    context.expect(passed(plain_row(3138), seeker, log) == 0, "3138 cần thẻ");
    context.expect(passed(plain_row(3139), seeker, log) == 0, "3139 cần số dương");
    context.expect(passed(plain_row(3140), seeker, log) == 1, "3140 lọt khi giai đoạn khác 1");
    context.expect(passed(plain_row(3141), seeker, log) == 0, "3141 bị chặn khi giai đoạn bằng 0");
    context.expect(passed(plain_row(3144), seeker, log) == 1, "id kề không bị xét riêng");
    seeker.edict.has_card = true;
    seeker.edict.tokens = 1;
    seeker.edict.stage = 1;
    context.expect(passed(plain_row(3138), seeker, log) == 1, "3138 có thẻ");
    context.expect(passed(plain_row(3139), seeker, log) == 1, "3139 có số dương");
    context.expect(passed(plain_row(3140), seeker, log) == 0, "3140 bị chặn khi giai đoạn bằng 1");
    context.expect(passed(plain_row(3142), seeker, log) == 1, "3142 lọt khi chưa giữ cái nào trong chuỗi");
    log.slots[0].mission = 3143;
    context.expect(passed(plain_row(3141), seeker, log) == 0, "đang giữ một cái trong chuỗi thì cả chuỗi bị chặn");
    seeker.edict.tokens = -5;
    context.expect(passed(plain_row(3139), seeker, log) == 0, "số âm không tính");
}

void offers_keep_table_order(Context& context) {
    std::vector<OutlineRow> rows = {plain_row(50), plain_row(51), plain_row(52), plain_row(53)};
    rows[1].kind = 200;
    rows[2].min_level = 2;
    const Seeker seeker;
    const Log log;
    Offers offers;
    offers.by_kind[7].push_back(99);
    quest::collect_offers(rows, seeker, log, offers);
    context.expect(offers.by_kind[7].empty(), "lượt gom mới xoá danh sách cũ");
    context.expect(quest::offer_count(offers, 3) == 2 && quest::offer_count(offers, 200) == 1, "đếm theo loại");
    context.expect(offers.by_kind[2] == std::vector<std::uint32_t>{0, 3}, "giữ thứ tự dòng của bảng");
    context.expect(quest::offer_count(offers, 0) == 0 && quest::offer_count(offers, 201) == 0, "loại ngoài miền");
    context.expect(quest::offer_count(offers, -7) == 0, "loại âm");
}

void offer_view_matches_script_values(Context& context) {
    std::vector<OutlineRow> rows = {plain_row(60)};
    rows[0].level = quest::kAny;
    rows[0].npc = "người giao";
    rows[0].scene = 6;
    rows[0].scene_name = "cảnh";
    rows[0].x = 187;
    rows[0].z = 205;
    rows[0].name_original = "tên gốc";
    rows[0].name_light = "tên nhẹ";
    Seeker seeker;
    seeker.level = 8;
    const Log log;
    Offers offers;
    quest::collect_offers(rows, seeker, log, offers);
    const auto view = quest::offer_at(rows, offers, seeker, quest::OfferAsk{.kind = 3, .number = 1});
    context.expect(view.has_value(), "nhiệm vụ đầu của loại 3");
    if (!view) return;
    context.expect(view->level == 8, "cấp -1 của bảng thành cấp người chơi");
    context.expect(view->min_level == 1 && view->max_level == 10, "khoảng cấp");
    context.expect(view->npc == "người giao" && view->scene_name == "cảnh" && view->name == "tên", "ba chuỗi");
    context.expect(view->x == 187 && view->z == 205 && view->scene == 6, "toạ độ và cảnh");
    context.expect(!quest::offer_at(rows, offers, seeker, quest::OfferAsk{.kind = 3, .number = 0}), "số 0");
    context.expect(!quest::offer_at(rows, offers, seeker, quest::OfferAsk{.kind = 3, .number = 2}), "quá số lượng");
    context.expect(!quest::offer_at(rows, offers, seeker, quest::OfferAsk{.kind = 0, .number = 1}), "loại 0");
    context.expect(!quest::offer_at(rows, offers, seeker, quest::OfferAsk{.kind = 4, .number = 1}), "loại rỗng");
}

void offer_view_renames_by_realm(Context& context) {
    std::vector<OutlineRow> rows = {plain_row(61)};
    rows[0].name_original = "tên gốc";
    rows[0].name_light = "tên nhẹ";
    rows[0].hidden_original = 2;
    rows[0].hidden_light = 2;
    Seeker seeker;
    const Log log;
    Offers offers;
    quest::collect_offers(rows, seeker, log, offers);
    const quest::OfferAsk first{.kind = 3, .number = 1};
    const auto name_now = [&rows, &offers, &seeker, &first] {
        const auto view = quest::offer_at(rows, offers, seeker, first);
        return view ? view->name : std::string_view("(không trả)");
    };
    context.expect(name_now() == "tên", "máy chủ thường giữ tên bảng");
    seeker.is_original = true;
    context.expect(name_now() == "tên gốc", "tên riêng của máy chủ gốc");
    seeker.is_light = true;
    context.expect(name_now() == "tên nhẹ", "tên của máy chủ nhẹ xét sau");
    rows[0].name_light.clear();
    context.expect(name_now() == "tên gốc", "tên riêng rỗng thì bỏ qua");
    rows[0].hidden_original = 1;
    context.expect(!quest::offer_at(rows, offers, seeker, first), "dòng bị giấu sau lượt gom thì không trả");
    const std::vector<OutlineRow> none;
    context.expect(!quest::offer_at(none, offers, seeker, first), "bảng ngắn hơn danh sách thì không trả");
}

// Hai bảng nhiệm vụ thật của client 2026 đã đọc; nullopt khi bản dựng không có dữ liệu client.
struct RealTables {
    std::vector<OutlineRow> rows;
    std::vector<quest::KindRow> kinds;
};

std::optional<RealTables> real_tables(Context& context) {
    if (kClientData.empty()) return std::nullopt;
    const std::filesystem::path folder = std::filesystem::path(io::path_from_utf8(kClientData)) / "Table";
    const io::TextResult outline_text = io::read_text(folder / "mission_outline.tsv");
    const io::TextResult kinds_text = io::read_text(folder / "mission_kinds.tsv");
    context.expect(outline_text.has_value() && kinds_text.has_value(), "hai bảng nhiệm vụ đã xuất");
    if (!outline_text || !kinds_text) return std::nullopt;
    quest::OutlineRows rows = quest::read_outline(table_of(*outline_text));
    quest::KindRows kinds = quest::read_kinds(table_of(*kinds_text));
    context.expect(rows.has_value() && kinds.has_value(), "hai bảng nhiệm vụ đọc được");
    if (!rows || !kinds) return std::nullopt;
    return RealTables{.rows = std::move(*rows), .kinds = std::move(*kinds)};
}

std::size_t total_of(const Offers& offers) {
    std::size_t total = 0;
    for (const std::vector<std::uint32_t>& list : offers.by_kind) total += list.size();
    return total;
}

// Bảng thật của client 2026: nhân vật mới (cấp 1, chưa nhập môn, sổ rỗng) chỉ nhận được đúng một
// nhiệm vụ. Kết quả này đã tính độc lập bằng Python trên bảng DBC gốc.
void real_tables_offer_newcomer_one_mission(Context& context) {
    const std::optional<RealTables> real = real_tables(context);
    if (!real) return;
    context.expect(real->rows.size() == 994 && real->kinds.size() == 200, "994 dòng nhận được, 200 loại");
    const Seeker seeker;
    const Log log;
    Offers offers;
    quest::collect_offers(real->rows, seeker, log, offers);
    context.expect(total_of(offers) == 1 && quest::offer_count(offers, 17) == 1, "một nhiệm vụ, loại 17");
    const auto found = quest::offer_at(real->rows, offers, seeker, quest::OfferAsk{.kind = 17, .number = 1});
    context.expect(found.has_value(), "nhiệm vụ đầu của loại 17");
    const quest::OfferView view = found.value_or(quest::OfferView{});
    context.expect(view.level == 1 && view.min_level == 1 && view.max_level == 31, "cấp 1, nhận tới cấp 31");
    context.expect(view.x == 187 && view.z == 205 && view.scene == 6, "NPC ở (187, 205) cảnh 6");
    context.expect(view.name == "缘起无量" && view.npc == "受伤的山民", "tên gốc của nhiệm vụ và NPC");
    context.expect(view.scene_name == "无量山", "tên cảnh nối sẵn");
    context.expect(quest::kind_title(real->kinds, 17) == "无量山", "tên loại 17");
}

// Cấp 10 nhận được ba nhiệm vụ, mỗi loại 11, 17, 19 một cái (cũng đã tính độc lập bằng Python).
void real_tables_offer_level_ten_three(Context& context) {
    const std::optional<RealTables> real = real_tables(context);
    if (!real) return;
    Seeker seeker;
    seeker.level = 10;
    const Log log;
    Offers offers;
    quest::collect_offers(real->rows, seeker, log, offers);
    context.expect(total_of(offers) == 3, "ba nhiệm vụ");
    const bool has_edges = quest::offer_count(offers, 11) == 1 && quest::offer_count(offers, 19) == 1;
    context.expect(has_edges && quest::offer_count(offers, 17) == 1, "loại 11, 17, 19 mỗi loại một");
}

constexpr std::array kCases{
    Case{.name = "done_bits_follow_mission_id", .body = &done_bits_follow_mission_id},
    Case{.name = "holding_looks_at_every_slot", .body = &holding_looks_at_every_slot},
    Case{.name = "outline_table_reads_every_field", .body = &outline_table_reads_every_field},
    Case{.name = "outline_table_rejects_bad_cells", .body = &outline_table_rejects_bad_cells},
    Case{.name = "kinds_sort_and_title", .body = &kinds_sort_and_title},
    Case{.name = "filter_checks_level_window", .body = &filter_checks_level_window},
    Case{.name = "filter_checks_sect", .body = &filter_checks_sect},
    Case{.name = "filter_checks_kind_done_needs_held", .body = &filter_checks_kind_done_needs_held},
    Case{.name = "filter_hides_by_realm", .body = &filter_hides_by_realm},
    Case{.name = "filter_checks_edict_rows", .body = &filter_checks_edict_rows},
    Case{.name = "offers_keep_table_order", .body = &offers_keep_table_order},
    Case{.name = "offer_view_matches_script_values", .body = &offer_view_matches_script_values},
    Case{.name = "offer_view_renames_by_realm", .body = &offer_view_renames_by_realm},
    Case{.name = "real_tables_offer_newcomer_one_mission", .body = &real_tables_offer_newcomer_one_mission},
    Case{.name = "real_tables_offer_level_ten_three", .body = &real_tables_offer_level_ten_three},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "quest_tests: mọi ca phải qua");
    return 0;
}
