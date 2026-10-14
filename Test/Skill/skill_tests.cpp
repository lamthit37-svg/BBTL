// Module skill: bảy bộ đọc bảng và các hàm tra, sách kỹ năng của người chơi (thứ tự PosIndex, kỹ
// năng không cần học), hệ action (liệt kê theo PosIndex, tâm pháp sở hữu), theo từng nhánh của mã
// máy Game.exe 2026 (docs/NHIEM-VU-VO-CONG-2026.md), và kết quả trên bảng thật của client 2026 cho
// nhân vật mới khi bản dựng có dữ liệu client.
#include "core/check.hpp"
#include "io/file.hpp"
#include "skill/actions.hpp"
#include "skill/book.hpp"
#include "skill/tables.hpp"
#include "skill_sample.hpp"
#include "table/tsv.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <format>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using skill::Action;
using skill::ActionKind;
using skill::Actions;
using skill::Book;
using skill::Tables;

// Thư mục dữ liệu client mà bản dựng biết; rỗng thì ca trên bảng thật tự bỏ qua.
#ifdef GAME_CLIENT_DATA
constexpr std::string_view kClientData = GAME_CLIENT_DATA;
#else
constexpr std::string_view kClientData;
#endif

bool has_text(const std::string& error, std::string_view part) {
    return error.contains(part);
}

void skills_read_and_sorted(Context& context) {
    std::string text = skills_head();
    text += skill_line({.id = 7, .data_0 = 70, .data_1 = 71, .data_2 = 72});
    text += skill_line({.id = 3, .sect = 2, .inner_art = 4, .inner_art_level = 20, .level_offset = -1, .user_class = 3,
        .passivity = 1, .must_learn = -1, .column_101 = 2});
    text += skill_line({.id = 7, .sect = 5});
    const skill::SkillRows rows = skill::read_skills(sample_table(text));
    context.expect(rows.has_value() && rows->size() == 2, "hai id, dòng lặp bị bỏ");
    if (!rows || rows->size() != 2) return;
    const skill::SkillRow& first = rows->front();
    context.expect(first.id == 3 && first.sect == 2 && first.inner_art == 4, "xếp tăng theo id; môn phái, tâm pháp");
    context.expect(first.inner_art_level == 20 && first.level_offset == -1 && first.user_class == 3, "ba cột số");
    context.expect(first.passivity == 1 && first.must_learn == -1 && first.column_101 == 2, "ba cột cờ");
    context.expect(first.name == "Kỹ năng 3" && first.icon == "Icon_3" && first.explain == "Mô tả 3", "ba cột chữ");
    const skill::SkillRow& second = rows->back();
    context.expect(second.id == 7 && second.sect == 9, "id lặp giữ dòng gặp trước");
    context.expect(second.data.at(0) == 70 && second.data.at(2) == 72 && second.data.at(30) == -1, "31 cột số liệu");
}

void readers_report_bad_tables(Context& context) {
    const skill::SkillRows no_column = skill::read_skills(sample_table("id\tsect\n1\t2\n"));
    context.expect(!no_column && has_text(no_column.error(), "inner_art_level"), "thiếu cột nêu tên cột");
    std::string text = skills_head();
    text += skill_line({.id = 1});
    text.replace(text.find("\n1\t9"), 2, "\nx");
    const skill::SkillRows bad_id = skill::read_skills(sample_table(text));
    context.expect(!bad_id && has_text(bad_id.error(), "dòng 2") && has_text(bad_id.error(), "id"), "id không phải số");
    const skill::LevelRows levels = skill::read_skill_levels(sample_table("id\ttext\n1\ta\n"));
    context.expect(!levels && has_text(levels.error(), "description"), "bảng số liệu thiếu cột mô tả");
    const skill::InnerArtRows arts = skill::read_inner_arts(sample_table("id\tsect\tname\texplain\ticon\n1\t0\ta\tb\tc\n"));
    context.expect(!arts && has_text(arts.error(), "need_level"), "bảng tâm pháp thiếu cột cấp cần");
    const skill::LearnCostRows costs = skill::read_learn_costs(sample_table("id\tlevel\tmoney_0\texp_0\n1\t1\t5\t6\n"));
    context.expect(!costs && has_text(costs.error(), "money_1"), "bảng giá thiếu cột của tâm pháp 1");
    const skill::LifeSkillRows life = skill::read_life_skills(sample_table("id\tname\n1\ta\n"));
    context.expect(!life && has_text(life.error(), "max_level"), "bảng kỹ năng sống thiếu cột");
    const skill::LifeLevelRows life_levels = skill::read_life_levels(sample_table("table\tlevel\tlimit_exp\na\t1\t2.5\n"));
    context.expect(!life_levels && has_text(life_levels.error(), "limit_exp"), "trần thuần thục không phải số nguyên");
    const skill::IconRows icons = skill::read_icons(sample_table("icon\tset\na\tb\n"));
    context.expect(!icons && has_text(icons.error(), "imageset"), "bảng icon thiếu cột bộ ảnh");
    const skill::LevelRows big = skill::read_skill_levels(sample_table("id\tdescription\n2147483648\ta\n"));
    context.expect(!big && has_text(big.error(), "id"), "id vượt int32 bị từ chối");
}

void small_tables_read(Context& context) {
    const Tables tables = sample_tables();
    context.expect(tables.levels.size() == 4 && tables.levels.front().description == "Số liệu bậc 0", "bảng số liệu");
    const skill::InnerArtRow* art = skill::inner_art_row(tables, 2);
    context.expect(art != nullptr && art->name == "Tâm pháp 2" && art->icon == "Art_2", "tâm pháp theo id");
    context.expect(art != nullptr && art->sect == 0 && art->need_level == 20, "môn phái và cấp cần của tâm pháp");
    const skill::LifeSkillRow* life = skill::life_skill_row(tables, 3);
    context.expect(life != nullptr && life->popup == 2 && life->consume == 2 && life->max_level == 10, "kỹ năng sống");
    context.expect(life != nullptr && life->level_table == "cook.txt" && life->explain == "Mô tả khảm", "chữ của nó");
    context.expect(tables.learn_costs.size() == 4 && tables.learn_costs.front().level == 888, "bảng giá giữ thứ tự tệp");
    context.expect(tables.life_levels.front().table == "cook.txt" && tables.life_levels.back().table == "other.txt",
        "bảng lên cấp xếp theo tên bảng");
}

void rows_are_found_by_id(Context& context) {
    const Tables tables = sample_tables();
    context.expect(skill::skill_row(tables, 10) != nullptr && skill::skill_row(tables, 10)->id == 10, "kỹ năng có");
    for (const std::int32_t id : {-1, 4, 31, std::numeric_limits<std::int32_t>::max()}) {
        context.expect(skill::skill_row(tables, id) == nullptr, "kỹ năng không có: trước, giữa, sau");
    }
    context.expect(skill::level_row(tables, 101) != nullptr && skill::level_row(tables, 103) == nullptr, "dòng số liệu");
    context.expect(skill::inner_art_row(tables, 5) != nullptr && skill::inner_art_row(tables, 3) == nullptr, "tâm pháp");
    context.expect(skill::life_skill_row(tables, 26) != nullptr && skill::life_skill_row(tables, 0) == nullptr, "kỹ năng sống");
    const Tables empty;
    context.expect(skill::skill_row(empty, 0) == nullptr && skill::level_row(empty, 0) == nullptr, "bảng rỗng");
}

void learn_cost_scans_by_level(Context& context) {
    Tables tables = sample_tables();
    const std::optional<skill::LearnCost> first = skill::learn_cost(tables, {.id = 0, .level = 21});
    context.expect(first && first->money == 2100 && first->exp == 21000, "tâm pháp 0 lên cấp 21");
    const std::optional<skill::LearnCost> last = skill::learn_cost(tables, {.id = 120, .level = 2});
    context.expect(last && last->money == 320 && last->exp == 2120, "tâm pháp 120 là cột cuối");
    context.expect(!skill::learn_cost(tables, {.id = 1, .level = 3}), "bảng không có cấp 3");
    context.expect(!skill::learn_cost(tables, {.id = -1, .level = 1}), "id âm bị từ chối");
    context.expect(!skill::learn_cost(tables, {.id = 121, .level = 1}), "id 121 ngoài bảng");
    tables.learn_costs.push_back(tables.learn_costs.front());
    tables.learn_costs.back().costs.at(4).money = 7;
    const std::optional<skill::LearnCost> repeated = skill::learn_cost(tables, {.id = 4, .level = 888});
    context.expect(repeated && repeated->money == 88804, "cấp lặp thì dòng gặp trước thắng");
}

void life_limit_follows_level_table(Context& context) {
    const Tables tables = sample_tables();
    context.expect(skill::life_limit_exp(tables, {.id = 1, .level = 1}) == 15, "1500 chia 100");
    context.expect(skill::life_limit_exp(tables, {.id = 1, .level = 2}) == 58, "5850 chia 100 bỏ phần dư");
    context.expect(skill::life_limit_exp(tables, {.id = 1, .level = 3}) == -1, "-150 chia có dấu là -1");
    context.expect(skill::life_limit_exp(tables, {.id = 1, .level = 4}) == -1, "bảng không có cấp 4");
    context.expect(skill::life_limit_exp(tables, {.id = 2, .level = 1}) == -1, "không có bảng lên cấp tên đó");
    context.expect(skill::life_limit_exp(tables, {.id = 99, .level = 1}) == -1, "không có kỹ năng sống đó");
}

void icon_names_are_resolved(Context& context) {
    const Tables tables = sample_tables();
    context.expect(skill::icon_full_name(tables.icons, "Icon_1") == "set:Skills image:Icon_1", "icon có trong bảng");
    context.expect(skill::icon_full_name(tables.icons, "Icon_10") == "set:Skills image:Icon_10", "tên là tiền tố của tên khác");
    context.expect(skill::icon_full_name(tables.icons, "Icon_") == "set:X image:X", "tên cụt không khớp");
    context.expect(skill::icon_full_name(tables.icons, "") == "set:X image:X", "tên rỗng");
    context.expect(skill::icon_full_name(tables.icons, "icon_1") == "set:X image:X", "phân biệt hoa thường");
    context.expect(skill::icon_full_name({}, "Icon_1") == "set:X image:X", "bảng rỗng");
    const skill::IconRows rows = skill::read_icons(sample_table("icon\timageset\nB\tLate\nA\tOne\nB\tEarly\n"));
    context.expect(rows.has_value() && rows->size() == 2, "icon lặp bị bỏ");
    if (rows) context.expect(skill::icon_full_name(*rows, "B") == "set:Late image:B", "icon lặp giữ dòng gặp trước");
}

void cap_fills_first_mark_only(Context& context) {
    context.expect(skill::fill_cap("trần %d cấp", 119) == "trần 119 cấp", "điền giữa câu");
    context.expect(skill::fill_cap("%d", -5) == "-5", "cả câu là chỗ điền, số âm");
    context.expect(skill::fill_cap("a%db%dc", 7) == "a7b%dc", "chỉ điền chỗ đầu tiên");
    context.expect(skill::fill_cap("không có chỗ điền, 50%", 7) == "không có chỗ điền, 50%", "không có %d thì giữ nguyên");
    context.expect(skill::fill_cap("", 7).empty(), "câu rỗng");
}

void inner_arts_keep_arrival_order(Context& context) {
    const Tables tables = sample_tables();
    Book book;
    skill::set_inner_art(book, tables, {.id = 2, .level = 30});
    skill::set_inner_art(book, tables, {.id = 1, .level = 0});
    skill::set_inner_art(book, tables, {.id = 9, .level = 5});
    context.expect(book.inner_arts.size() == 2, "tâm pháp không có dòng bị bỏ");
    if (book.inner_arts.size() != 2) return;
    context.expect(book.inner_arts.front().id == 1 && book.inner_arts.front().pos_index == 1, "xếp theo id, PosIndex theo lượt tới");
    context.expect(!book.inner_arts.front().is_learned && book.inner_arts.back().is_learned, "đã học khi cấp lớn hơn 0");
    skill::set_inner_art(book, tables, {.id = 2, .level = 0});
    const skill::OwnedInnerArt* art = skill::find_inner_art(book, 2);
    context.expect(art != nullptr && art->level == 0 && !art->is_learned && art->pos_index == 0, "đặt lại chỉ đổi cấp");
    context.expect(skill::find_inner_art(book, 5) == nullptr, "tâm pháp chưa có");
}

void skills_follow_sect_rule(Context& context) {
    const Tables tables = sample_tables();
    Book book;
    skill::set_skill(book, tables, 0, {.id = 20, .is_learned = true});
    skill::set_skill(book, tables, 0, {.id = 30, .is_learned = true});
    skill::set_skill(book, tables, 0, {.id = 77, .is_learned = true});
    skill::set_skill(book, tables, 0, {.id = 0, .is_learned = false});
    context.expect(book.skills.size() == 2, "kỹ năng của môn phái khác và id lạ bị bỏ");
    if (book.skills.size() != 2) return;
    context.expect(book.skills.front().id == 0 && book.skills.front().pos_index == 1, "kỹ năng không tâm pháp: môn phái nào cũng nhận");
    context.expect(book.skills.back().id == 20 && book.skills.back().pos_index == 0, "PosIndex không tính id bị bỏ");
    skill::set_skill(book, tables, 1, {.id = 0, .is_learned = true});
    context.expect(book.skills.front().is_learned && book.skills.front().pos_index == 1, "đặt lại chỉ đổi cờ đã học");
    const std::array<std::int32_t, 4> packet = {12, 30, 1, 10};
    skill::replace_skills(book, tables, 0, packet);
    context.expect(book.skills.size() == 3, "gói mới thay cả danh sách");
    const std::optional<skill::SkillView> third = skill::find_skill(book, tables, 10);
    context.expect(third && third->pos_index == 2 && third->is_learned, "PosIndex là vị trí trong gói, bỏ id bị loại");
}

void life_skills_scale_exp(Context& context) {
    const Tables tables = sample_tables();
    Book book;
    skill::set_life_skill(book, tables, {.id = 3, .level = 2, .exp = 1234, .mastery = -4});
    skill::set_life_skill(book, tables, {.id = 1, .level = 1, .exp = -7, .mastery = 30});
    skill::set_life_skill(book, tables, {.id = 99, .level = 1, .exp = 0, .mastery = 0});
    context.expect(book.life_skills.size() == 2, "kỹ năng sống không có dòng bị bỏ");
    const skill::OwnedLifeSkill* gem = skill::find_life_skill(book, 3);
    context.expect(gem != nullptr && gem->exp == 12 && gem->mastery == 0 && gem->pos_index == 0, "exp chia 100, số âm thành 0");
    const skill::OwnedLifeSkill* cook = skill::find_life_skill(book, 1);
    context.expect(cook != nullptr && cook->exp == 0 && cook->mastery == 30 && cook->pos_index == 1, "mục thứ hai");
    skill::set_life_skill(book, tables, {.id = 3, .level = -1, .exp = -1, .mastery = -1});
    context.expect(gem != nullptr && gem->level == 2 && gem->exp == 12 && gem->mastery == 0, "số âm giữ nguyên mục đã có");
    skill::set_life_skill(book, tables, {.id = 3, .level = 5, .exp = 99, .mastery = 8});
    context.expect(gem != nullptr && gem->level == 5 && gem->exp == 0 && gem->mastery == 8, "exp 99 chia 100 là 0");
    context.expect(skill::find_life_skill(book, 2) == nullptr, "kỹ năng sống chưa có");
}

void free_skills_are_always_known(Context& context) {
    const Tables tables = sample_tables();
    Book book;
    for (const std::int32_t id : {2, 3}) {
        const std::optional<skill::SkillView> free = skill::find_skill(book, tables, id);
        context.expect(free && free->is_learned && free->pos_index == -1, "không cần học: luôn có, PosIndex -1");
    }
    context.expect(!skill::find_skill(book, tables, 0), "kỹ năng phải học mà sách chưa có");
    context.expect(!skill::find_skill(book, tables, 77), "id không có dòng");
    skill::set_skill(book, tables, 9, {.id = 2, .is_learned = false});
    skill::set_skill(book, tables, 9, {.id = 0, .is_learned = false});
    const std::optional<skill::SkillView> listed = skill::find_skill(book, tables, 2);
    context.expect(listed && listed->is_learned && listed->pos_index == -1, "có trong sách vẫn trả bản không cần học");
    const std::optional<skill::SkillView> plain = skill::find_skill(book, tables, 0);
    context.expect(plain && !plain->is_learned && plain->pos_index == 1 && plain->row->id == 0, "kỹ năng thường tra sách");
}

// Một lần hỏi dòng số liệu: kỹ năng nào, khi tâm pháp 1 ở cấp nào.
struct DataAsk {
    std::int32_t skill = 0;
    std::int32_t level = 0;
};

std::string_view data_at(const Tables& tables, const DataAsk& ask) {
    Book book;
    skill::set_inner_art(book, tables, {.id = 1, .level = ask.level});
    return skill::skill_data_text(book, tables, *skill::skill_row(tables, ask.skill));
}

void skill_data_follows_inner_art_tier(Context& context) {
    const Tables tables = sample_tables();
    const Book none;
    context.expect(skill::skill_data_text(none, tables, *skill::skill_row(tables, 10)) == "Số liệu bậc 0", "chưa có tâm pháp: bậc 0");
    context.expect(skill::skill_data_text(none, tables, *skill::skill_row(tables, 0)) == "Số liệu bậc 0", "kỹ năng không tâm pháp");
    context.expect(skill::skill_data_text(none, tables, *skill::skill_row(tables, 1)) == "Mô tả 1", "dòng số liệu không có: mô tả");
    context.expect(skill::skill_data_text(none, tables, *skill::skill_row(tables, 2)) == "Mô tả 2", "ô số liệu -1: mô tả");
    context.expect(data_at(tables, {.skill = 10, .level = 9}) == "Số liệu bậc 0" && data_at(tables, {.skill = 10, .level = 10}) == "Số liệu bậc 1", "mười cấp một bậc");
    context.expect(data_at(tables, {.skill = 10, .level = 29}) == "Số liệu bậc 2", "cấp 29 là bậc 2");
    context.expect(data_at(tables, {.skill = 10, .level = 30}) == "Mô tả 10", "bậc 3 không có dòng số liệu");
    context.expect(data_at(tables, {.skill = 10, .level = 310}) == "Số liệu bậc 0", "bậc 31 quay về bậc 0");
    context.expect(data_at(tables, {.skill = 11, .level = 10}) == "Số liệu bậc 0" && data_at(tables, {.skill = 11, .level = 11}) == "Số liệu bậc 1", "cột 11 trừ một cấp");
    context.expect(data_at(tables, {.skill = 11, .level = 0}) == "Số liệu bậc 0", "-1 chia 10 là 0");
    context.expect(data_at(tables, {.skill = 11, .level = -9}) == "Mô tả 11", "bậc âm trả mô tả");
    context.expect(data_at(tables, {.skill = 10, .level = std::numeric_limits<std::int32_t>::min()}) == "Mô tả 10", "cấp nhỏ nhất không tràn");
    const std::string_view top = data_at(tables, {.skill = 11, .level = std::numeric_limits<std::int32_t>::max()});
    context.expect(top == "Mô tả 11", "cấp lớn nhất: bậc 23 không có dòng số liệu");
}

void requirement_needs_inner_art_level(Context& context) {
    const Tables tables = sample_tables();
    Book book;
    const skill::SkillRow& row = *skill::skill_row(tables, 11);
    context.expect(!skill::meets_requirement(book, row), "chưa có tâm pháp");
    skill::set_inner_art(book, tables, {.id = 1, .level = 29});
    context.expect(!skill::meets_requirement(book, row), "tâm pháp cấp 29, cần 30");
    skill::set_inner_art(book, tables, {.id = 1, .level = 30});
    context.expect(skill::meets_requirement(book, row), "tâm pháp đủ cấp 30");
    context.expect(!skill::meets_requirement(book, *skill::skill_row(tables, 0)), "kỹ năng không tâm pháp");
}

constexpr skill::OwnedInnerArt kThirdArt{.id = 3, .pos_index = 2, .level = 1, .is_learned = true};
constexpr skill::OwnedInnerArt kEighthArt{.id = 8, .pos_index = 7, .level = 1, .is_learned = true};
static_assert(skill::inner_art_cap(kThirdArt, {.level = 119, .is_light = false}) == 119);
static_assert(skill::inner_art_cap(kThirdArt, {.level = 120, .is_light = true}) == 129);
static_assert(skill::inner_art_cap(kEighthArt, {.level = 119, .is_light = false}) == 250);
static_assert(skill::inner_art_cap(kEighthArt, {.level = 120, .is_light = false}) == 300);
static_assert(skill::inner_art_cap(kEighthArt, {.level = 120, .is_light = true}) == 119);
static_assert(skill::inner_art_cap(kEighthArt, {.level = 1, .is_light = true}) == 119);
static_assert(skill::is_second_form(821) && skill::is_second_form(826) && skill::is_second_form(827));
static_assert(skill::is_second_form(834) && skill::is_second_form(4465) && skill::is_second_form(4466));
static_assert(!skill::is_second_form(820) && !skill::is_second_form(835));
static_assert(!skill::is_second_form(4464) && !skill::is_second_form(4467) && !skill::is_second_form(-1));

void cap_is_same_at_run_time(Context& context) {
    skill::OwnedInnerArt art = kThirdArt;
    for (std::int32_t pos = 0; pos < 9; ++pos) {
        art.pos_index = pos;
        const std::int32_t low = skill::inner_art_cap(art, {.level = 1, .is_light = false});
        context.expect(low == (pos == 7 ? 250 : 119), "chỉ tâm pháp thứ tám có trần riêng");
    }
}

// Sách của nhân vật môn phái 0 trên bảng mẫu: tâm pháp 2 rồi 1, kỹ năng 20, 0, 12, 10, 2, kỹ năng
// sống 3 rồi 1, action dựng như mã gốc (sau từng tâm pháp, từng kỹ năng sống, và một lần sau gói kỹ
// năng).
struct Shelf {
    Tables tables = sample_tables();
    Book book;
    Actions actions;

    Shelf() {
        for (const std::int32_t art : {2, 1}) {
            skill::set_inner_art(book, tables, {.id = art, .level = 10});
            skill::sync_inner_art_actions(actions, book);
        }
        const std::array<std::int32_t, 5> packet = {20, 0, 12, 10, 2};
        skill::replace_skills(book, tables, 0, packet);
        skill::sync_skill_actions(actions, book, tables);
        for (const std::int32_t life : {3, 1}) {
            skill::set_life_skill(book, tables, {.id = life, .level = 1, .exp = 0, .mastery = 0});
            skill::sync_life_actions(actions, book);
        }
    }

    [[nodiscard]] const Action* at(ActionKind kind, std::int32_t index) const {
        return skill::enum_action(actions, book, tables, {.kind = kind, .index = index});
    }
};

// Số thứ tự action của sách tính từ action sách đầu tiên (nhận id 21 khi mới có bốn action thú cưng); từ khi
// Initial tạo thêm bốn action trận pháp và đủ 1020 action của nó, action sách đầu tiên nhận id 1021.
[[nodiscard]] constexpr std::int32_t book_id(std::int32_t order) noexcept {
    return skill::kFirstBookAction + (order - 21);
}

void actions_start_with_pets(Context& context) {
    const Actions actions;
    context.expect(actions.all.size() == 8 && actions.next_id == skill::kFirstBookAction,
        "sau Initial: bốn action thú cưng, bốn action trận pháp, id kế là 1021");
    for (std::size_t slot = 0; slot < skill::kPetActions; ++slot) {
        const Action* pet = skill::pet_action(actions, static_cast<skill::PetAction>(slot));
        context.expect(pet != nullptr && pet->id == 17 + static_cast<std::int32_t>(slot), "id 17..20 theo thứ tự ô");
    }
    context.expect(skill::action_count(actions, ActionKind::kSkill) == 0, "chưa có action kỹ năng");
    Actions bare;
    bare.all.clear();
    context.expect(skill::pet_action(bare, skill::PetAction::kFight) == nullptr, "danh sách bị xoá thì không còn");
}

void actions_are_made_in_original_order(Context& context) {
    const Shelf shelf;
    const Action* art_two = shelf.at(ActionKind::kInnerArt, 0);
    const Action* art_one = shelf.at(ActionKind::kInnerArt, 1);
    context.expect(art_two != nullptr && art_two->define == 2 && art_two->id == book_id(21), "tâm pháp tới trước nhận id trước");
    context.expect(art_one != nullptr && art_one->define == 1 && art_one->id == book_id(22), "tâm pháp thứ hai");
    context.expect(skill::action_count(shelf.actions, ActionKind::kSkill) == 5, "năm action kỹ năng");
    const Action* first = shelf.at(ActionKind::kSkill, 0);
    context.expect(first != nullptr && first->define == 20 && first->id == book_id(27), "PosIndex 0 là kỹ năng 20, id theo id kỹ năng");
    const Action* second = shelf.at(ActionKind::kSkill, 1);
    context.expect(second != nullptr && second->define == 0 && second->id == book_id(23), "kỹ năng 0 có id nhỏ nhất");
    context.expect(shelf.at(ActionKind::kSkill, 4) == nullptr, "kỹ năng 2 không cần học: PosIndex -1, không liệt kê được");
    const Action* free = shelf.at(ActionKind::kSkill, -1);
    context.expect(free != nullptr && free->define == 2, "PosIndex -1 trả kỹ năng không cần học");
    context.expect(shelf.at(ActionKind::kSkill, 5) == nullptr && shelf.at(ActionKind::kInnerArt, 2) == nullptr, "ngoài miền");
    const Action* gem = shelf.at(ActionKind::kLifeSkill, 0);
    context.expect(gem != nullptr && gem->define == 3 && gem->id == book_id(28), "kỹ năng sống tới trước nhận id trước");
    context.expect(skill::action_count(shelf.actions, ActionKind::kLifeSkill) == 2, "hai action kỹ năng sống");
    context.expect(std::ranges::is_sorted(shelf.actions.all, {}, &Action::id), "danh sách xếp tăng theo id");
}

void sync_drops_gone_and_keeps_ids(Context& context) {
    Shelf shelf;
    const std::array<std::int32_t, 2> packet = {10, 1};
    skill::replace_skills(shelf.book, shelf.tables, 0, packet);
    skill::sync_skill_actions(shelf.actions, shelf.book, shelf.tables);
    context.expect(skill::action_count(shelf.actions, ActionKind::kSkill) == 3, "còn 10, thêm 1, và 2 không cần học ở lại");
    const Action* kept = shelf.at(ActionKind::kSkill, 0);
    context.expect(kept != nullptr && kept->define == 10 && kept->id == book_id(25), "action cũ giữ id");
    const Action* added = shelf.at(ActionKind::kSkill, 1);
    context.expect(added != nullptr && added->define == 1 && added->id == book_id(30), "action mới nhận id kế tiếp");
    context.expect(skill::action_by_id(shelf.actions, book_id(27)) == nullptr, "action của kỹ năng 20 đã gỡ");
    shelf.book.inner_arts.clear();
    shelf.book.life_skills.clear();
    skill::sync_inner_art_actions(shelf.actions, shelf.book);
    skill::sync_life_actions(shelf.actions, shelf.book);
    context.expect(skill::action_count(shelf.actions, ActionKind::kInnerArt) == 0, "tâm pháp mất thì action mất");
    context.expect(skill::action_count(shelf.actions, ActionKind::kLifeSkill) == 0, "kỹ năng sống mất thì action mất");
    context.expect(skill::action_count(shelf.actions, ActionKind::kPet) == 4, "action thú cưng không bị gỡ");
}

void id_counter_wraps_without_overflow(Context& context) {
    const Tables tables = sample_tables();
    Book book;
    Actions actions;
    actions.next_id = std::numeric_limits<std::int32_t>::max();
    skill::set_inner_art(book, tables, {.id = 1, .level = 1});
    skill::sync_inner_art_actions(actions, book);
    context.expect(actions.all.back().id == std::numeric_limits<std::int32_t>::max() && actions.next_id == 1, "id lớn nhất rồi về 1");
    skill::set_inner_art(book, tables, {.id = 2, .level = 1});
    skill::sync_inner_art_actions(actions, book);
    context.expect(actions.all.front().id == 1 && actions.all.front().define == 2, "id 1 chèn vào đầu danh sách");
    actions.next_id = -5;
    skill::set_inner_art(book, tables, {.id = 5, .level = 1});
    skill::sync_inner_art_actions(actions, book);
    context.expect(actions.next_id == 2, "bộ đếm âm thì lấy id 1");
}

void define_and_owner_follow_book(Context& context) {
    Shelf shelf;
    const Action* skill_ten = shelf.at(ActionKind::kSkill, 3);
    const Action* art_one = shelf.at(ActionKind::kInnerArt, 1);
    const Action* plain = shelf.at(ActionKind::kSkill, 1);
    const Action* other_class = shelf.at(ActionKind::kSkill, 0);
    const Action* pet = skill::pet_action(shelf.actions, skill::PetAction::kRelax);
    const bool is_ready = skill_ten != nullptr && art_one != nullptr && plain != nullptr && other_class != nullptr && pet != nullptr;
    context.expect(is_ready, "sách mẫu có đủ action");
    if (!is_ready) return;
    const auto owner = [&shelf](const Action& one) { return skill::owner_inner_art(shelf.actions, shelf.book, shelf.tables, one); };
    const auto define = [&shelf](const Action& one) { return skill::define_id(one, shelf.book, shelf.tables); };
    context.expect(owner(*skill_ten) == art_one->id, "kỹ năng 10 thuộc action của tâm pháp 1");
    context.expect(owner(*plain) == skill::kNoOwnerArt, "kỹ năng không tâm pháp: -9999");
    context.expect(owner(*other_class) == skill::kNotOwned, "user_class khác 0: -1");
    context.expect(owner(*art_one) == skill::kNotOwned && owner(*pet) == skill::kNotOwned, "không phải kỹ năng: -1");
    context.expect(define(*skill_ten) == 10 && define(*art_one) == 1 && define(*pet) == -1, "id định nghĩa");
    const auto number = [&shelf](std::int32_t id) { return skill::defined_by(shelf.actions, shelf.book, shelf.tables, id); };
    context.expect(number(skill_ten->id) == 10 && number(art_one->id) == 1, "GetLifeAbility_Number của kỹ năng và tâm pháp");
    context.expect(!number(pet->id) && !number(0) && !number(999), "action thú cưng, action rỗng, id lạ: nil");
    const Action stale = *skill_ten;
    const Action stale_art = *art_one;
    shelf.book.inner_arts.clear();
    context.expect(owner(stale) == stale_art.id, "action tâm pháp chưa gỡ thì vẫn là chủ");
    skill::sync_inner_art_actions(shelf.actions, shelf.book);
    context.expect(owner(stale) == skill::kNoOwnerArt && define(stale_art) == -1, "tâm pháp không còn: -9999 và -1");
    shelf.book.skills.clear();
    context.expect(owner(stale) == skill::kNotOwned && define(stale) == -1, "kỹ năng không còn: -1");
}

void action_icons_come_from_rows(Context& context) {
    const Shelf shelf;
    const Action* skill_ten = shelf.at(ActionKind::kSkill, 3);
    const Action* art_two = shelf.at(ActionKind::kInnerArt, 0);
    const Action* cook = shelf.at(ActionKind::kLifeSkill, 1);
    context.expect(skill_ten != nullptr && skill::action_icon(*skill_ten, shelf.tables) == "Icon_10", "icon kỹ năng");
    context.expect(art_two != nullptr && skill::action_icon(*art_two, shelf.tables) == "Art_2", "icon tâm pháp");
    context.expect(cook != nullptr && skill::action_icon(*cook, shelf.tables) == "Life_1", "icon kỹ năng sống");
    const Action* possess = skill::pet_action(shelf.actions, skill::PetAction::kPossess);
    context.expect(possess != nullptr && skill::action_icon(*possess, shelf.tables) == "FightSkillXinShou_11", "icon thú cưng");
    const Tables empty;
    for (const ActionKind kind : {ActionKind::kSkill, ActionKind::kInnerArt, ActionKind::kLifeSkill}) {
        context.expect(skill::action_icon(Action{.id = 1, .kind = kind, .define = 1}, empty).empty(), "bảng không có dòng: rỗng");
    }
    for (const std::int32_t define : {-1, 4}) {
        context.expect(skill::action_icon(Action{.id = 1, .kind = ActionKind::kPet, .define = define}, empty).empty(), "số thú cưng lạ");
    }
}

void newcomer_book_matches_default_char(Context& context) {
    Tables tables = sample_tables();
    const Book book = skill::newcomer_book(tables);
    context.expect(book.skills.size() == 2 && book.inner_arts.empty(), "bảng mẫu chỉ có kỹ năng 0 và 1; không tâm pháp");
    context.expect(book.life_skills.size() == 2, "bảng mẫu có kỹ năng sống 1 và 26");
    const skill::OwnedLifeSkill* cook = skill::find_life_skill(book, 1);
    context.expect(cook != nullptr && cook->level == 1 && cook->exp == 0 && cook->pos_index == 0, "nấu ăn cấp 1");
}

// Bảng thật của client 2026, đọc từ Table/ của dữ liệu client.
std::optional<table::Tsv> real_table(Context& context, std::string_view name) {
    const std::filesystem::path path = io::path_from_utf8(kClientData) / "Table" / io::path_from_utf8(name);
    const io::TextResult text = io::read_text(path);
    context.expect(text.has_value(), std::format("đọc được Table/{}", name));
    if (!text) return std::nullopt;
    table::TsvResult table = table::parse_tsv(*text);
    context.expect(table.has_value(), std::format("Table/{} là bảng TSV", name));
    if (!table) return std::nullopt;
    return std::move(*table);
}

template <typename Rows, typename Read>
void load(Context& context, std::string_view name, Read read, Rows& rows) {
    const std::optional<table::Tsv> table = real_table(context, name);
    if (!table) return;
    auto read_rows = read(*table);
    context.expect(read_rows.has_value(), std::format("Table/{} qua bộ đọc", name));
    if (read_rows) rows = std::move(*read_rows);
}

// Bảy bảng thật; nullopt khi bản dựng không có dữ liệu client hay một bảng không đọc được (đã báo).
std::optional<Tables> read_real_tables(Context& context) {
    if (kClientData.empty()) return std::nullopt;
    const std::int32_t before = context.failures();
    Tables tables;
    load(context, "skills.tsv", skill::read_skills, tables.skills);
    load(context, "skill_levels.tsv", skill::read_skill_levels, tables.levels);
    load(context, "inner_arts.tsv", skill::read_inner_arts, tables.inner_arts);
    load(context, "inner_art_learn_costs.tsv", skill::read_learn_costs, tables.learn_costs);
    load(context, "life_skills.tsv", skill::read_life_skills, tables.life_skills);
    load(context, "life_skill_levels.tsv", skill::read_life_levels, tables.life_levels);
    load(context, "icons.tsv", skill::read_icons, tables.icons);
    if (context.failures() != before) return std::nullopt;
    return tables;
}

void real_tables_have_original_sizes(Context& context, const Tables& real) {
    const Tables* tables = &real;
    context.expect(tables->skills.size() == 4586 && tables->levels.size() == 20667, "4586 kỹ năng, 20667 dòng số liệu");
    context.expect(tables->inner_arts.size() == 120 && tables->learn_costs.size() == 302, "120 tâm pháp, 302 dòng giá");
    context.expect(tables->life_skills.size() == 66 && tables->icons.size() == 19513, "66 kỹ năng sống, 19513 icon");
    const auto has_one_mark = [](const skill::InnerArtRow& row) {
        const std::size_t at = row.explain.find('%');
        return at != std::string::npos && row.explain.find('%', at + 1) == std::string::npos && row.explain.at(at + 1) == 'd';
    };
    context.expect(std::ranges::all_of(tables->inner_arts, has_one_mark), "mô tả tâm pháp nào cũng có đúng một %d");
    const std::optional<skill::LearnCost> cost = skill::learn_cost(*tables, {.id = 0, .level = 298});
    context.expect(cost && cost->money == 1547099 && cost->exp == 9309747, "giá cấp 298 của tâm pháp 0 như bảng gốc");
    context.expect(!skill::learn_cost(*tables, {.id = 0, .level = 301}), "bảng giá không có cấp 301");
}

// Điều mục D của tài liệu nêu cho một ô kỹ năng của nhân vật mới.
struct NewcomerSkill {
    std::int32_t id = 0;
    std::string_view name;
    std::string_view icon;
    std::string_view explain;
};

constexpr std::array<NewcomerSkill, 6> kNewcomerSkills = {{
    {.id = 0, .name = "普通攻击", .icon = "set:TaskTools2 image:TaskTools2_13", .explain = "江湖上流传甚广，人人会使的武功招式。"},
    {.id = 1, .name = "捕兽", .icon = "set:PetSkill2 image:PetSkill2_4",
        .explain = "捕捉一只没有主人的珍兽。捕捉成功的话，你就可以成为它的主人。"},
    {.id = 21, .name = "召唤坐骑", .icon = "set:RideHeader1 image:RideHeader1_1", .explain = "召唤你的坐骑，使你的移动速度大幅提升。"},
    {.id = 22, .name = "返回大理城", .icon = "set:TaskTools4 image:TaskTools4_1", .explain = "使你回到大理城五华坛。"},
    {.id = 34, .name = "新手轻功", .icon = "set:Shoes2 image:Shoes2_4", .explain = "江湖上流传甚广，人人会使的轻功招式。"},
    {.id = 35, .name = "打坐", .icon = "set:MenpaiLiveSkill2 image:MenpaiLiveSkill2_7",
        .explain = "静坐冥思，吐故纳新。使用之后可以缓慢回复你的血和气。"},
}};

void real_newcomer_skills_match_document(Context& context, const Tables& real) {
    const Tables* tables = &real;
    const Book book = skill::newcomer_book(*tables);
    Actions actions;
    skill::sync_skill_actions(actions, book, *tables);
    context.expect(skill::action_count(actions, ActionKind::kSkill) == 6, "GetActionNum(\"skill\") là 6");
    for (std::size_t slot = 0; slot < kNewcomerSkills.size(); ++slot) {
        const NewcomerSkill& wanted = kNewcomerSkills.at(slot);
        const Action* action = skill::enum_action(actions, book, *tables, {.kind = ActionKind::kSkill, .index = static_cast<std::int32_t>(slot)});
        context.expect(action != nullptr && action->define == wanted.id, std::format("PosIndex {} là kỹ năng {}", slot, wanted.id));
        if (action == nullptr) continue;
        context.expect(skill::owner_inner_art(actions, book, *tables, *action) == skill::kNoOwnerArt, "GetOwnerXinfa là -9999");
        const std::optional<skill::SkillView> view = skill::find_skill(book, *tables, wanted.id);
        context.expect(view && view->is_learned && view->row->passivity == 0, "đã học, chủ động");
        if (!view) continue;
        context.expect(view->row->name == wanted.name && view->row->explain == wanted.explain, std::format("tên và mô tả kỹ năng {}", wanted.id));
        const std::string icon = skill::icon_full_name(tables->icons, skill::action_icon(*action, *tables));
        context.expect(icon == wanted.icon, std::format("icon kỹ năng {}: {}", wanted.id, icon));
    }
    const std::string_view mount = skill::skill_data_text(book, *tables, *skill::skill_row(*tables, 21));
    context.expect(mount == "召唤坐骑，坐骑可以提升一定的移动速度#c54FF00（拖至快捷栏中使用）#r#c5BC257需要装备坐骑", "số liệu kỹ năng 21");
    const std::string_view jump = skill::skill_data_text(book, *tables, *skill::skill_row(*tables, 34));
    context.expect(jump == "轻功飞跃#r有效距离：0～15米#r冷却时间：5秒", "số liệu kỹ năng 34");
}

void real_newcomer_life_skills_match_document(Context& context, const Tables& real) {
    const Tables* tables = &real;
    const Book book = skill::newcomer_book(*tables);
    context.expect(book.life_skills.size() == 5 && book.inner_arts.empty(), "năm kỹ năng sống, không tâm pháp");
    const skill::LifeSkillRow* cook = skill::life_skill_row(*tables, 1);
    context.expect(cook != nullptr && cook->name == "烹饪" && cook->popup == 1, "kỹ năng sống 1 là nấu ăn, có giao diện chế tạo");
    if (cook == nullptr) return;
    context.expect(skill::icon_full_name(tables->icons, cook->icon) == "set:CommonLiveSkill image:CommonLiveSkill_6", "icon nấu ăn");
    context.expect(skill::life_limit_exp(*tables, {.id = 1, .level = 1}) == 15, "trần thuần thục cấp 1 là 15");
    context.expect(skill::life_limit_exp(*tables, {.id = 1, .level = 11}) == -1, "bảng nấu ăn không có cấp 11");
    const skill::LifeSkillRow* riding = skill::life_skill_row(*tables, 38);
    context.expect(riding != nullptr && riding->name == "骑术" && riding->icon == "RideHeader1_1", "kỹ năng sống 38");
    const std::array<skill::PetFace, skill::kPetActions> pets = skill::kPetFaces;
    for (const skill::PetFace& pet : pets) {
        context.expect(skill::icon_full_name(tables->icons, pet.icon) != "set:X image:X", std::format("icon thú cưng {} có bộ ảnh", pet.icon));
    }
}

// Bảng thật chỉ đọc một lần cho cả ba nhóm kỳ vọng (bảng số liệu nặng 13 MB).
void real_tables_match_document(Context& context) {
    const std::optional<Tables> tables = read_real_tables(context);
    if (!tables) return;
    real_tables_have_original_sizes(context, *tables);
    real_newcomer_skills_match_document(context, *tables);
    real_newcomer_life_skills_match_document(context, *tables);
}

constexpr std::array kCases{
    Case{.name = "skills_read_and_sorted", .body = &skills_read_and_sorted},
    Case{.name = "readers_report_bad_tables", .body = &readers_report_bad_tables},
    Case{.name = "small_tables_read", .body = &small_tables_read},
    Case{.name = "rows_are_found_by_id", .body = &rows_are_found_by_id},
    Case{.name = "learn_cost_scans_by_level", .body = &learn_cost_scans_by_level},
    Case{.name = "life_limit_follows_level_table", .body = &life_limit_follows_level_table},
    Case{.name = "icon_names_are_resolved", .body = &icon_names_are_resolved},
    Case{.name = "cap_fills_first_mark_only", .body = &cap_fills_first_mark_only},
    Case{.name = "inner_arts_keep_arrival_order", .body = &inner_arts_keep_arrival_order},
    Case{.name = "skills_follow_sect_rule", .body = &skills_follow_sect_rule},
    Case{.name = "life_skills_scale_exp", .body = &life_skills_scale_exp},
    Case{.name = "free_skills_are_always_known", .body = &free_skills_are_always_known},
    Case{.name = "skill_data_follows_inner_art_tier", .body = &skill_data_follows_inner_art_tier},
    Case{.name = "requirement_needs_inner_art_level", .body = &requirement_needs_inner_art_level},
    Case{.name = "cap_is_same_at_run_time", .body = &cap_is_same_at_run_time},
    Case{.name = "actions_start_with_pets", .body = &actions_start_with_pets},
    Case{.name = "actions_are_made_in_original_order", .body = &actions_are_made_in_original_order},
    Case{.name = "sync_drops_gone_and_keeps_ids", .body = &sync_drops_gone_and_keeps_ids},
    Case{.name = "id_counter_wraps_without_overflow", .body = &id_counter_wraps_without_overflow},
    Case{.name = "define_and_owner_follow_book", .body = &define_and_owner_follow_book},
    Case{.name = "action_icons_come_from_rows", .body = &action_icons_come_from_rows},
    Case{.name = "newcomer_book_matches_default_char", .body = &newcomer_book_matches_default_char},
    Case{.name = "real_tables_match_document", .body = &real_tables_match_document},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "skill_tests: mọi ca phải qua");
    return 0;
}
