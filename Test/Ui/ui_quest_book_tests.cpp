// Sổ nhiệm vụ của màn chơi (ui/panel/quest_book): bảng nhiệm vụ đọc từ hai bảng TSV, nút Button_Mission
// của thanh menu đảo bảng cùng thứ hạng của bàn (desk), nút đóng của bảng đóng cả hai, bàn đóng bảng
// thì bảng thôi hiện, và bảng chỉ kê khi đang hiện.
#include "ui/panel/quest_book.hpp"

#include "core/check.hpp"
#include "hero/hero.hpp"
#include "table/tsv.hpp"
#include "test.hpp"
#include "ui/panel/call.hpp"
#include "ui/panel/deck.hpp"
#include "ui/panel/desk.hpp"

#include <array>
#include <string_view>
#include <vector>

namespace game::test {
namespace {

using ui::panel::Board;
using ui::panel::Call;
using ui::panel::QuestBook;

constexpr std::string_view kOutline =
    "id\tmission\tkind\tsect\tcolumn_4\tcolumn_5\tlevel\tmin_level\tmax_level\tscene\tnpc\tcolumn_11\tname\t"
    "requires_1\trequires_2\trequires_3\tx\tz\thidden\thidden_original\tname_original\thidden_light\tname_light\t"
    "x_text\tz_text\tcolumn_25\tscene_name\n"
    "1087\t1682\t17\t-1\t0\t0\t1\t1\t31\t6\tNPC\t\tDuyen Khoi\t-1\t-1\t-1\t187\t205\t0\t0\t\t0\t\t\t\t\tVo Luong\n";
constexpr std::string_view kKinds = "id\tname\n17\tVo Luong Son\n";
constexpr std::string_view kBrokenOutline = "id\tmission\n1\tx\n";

void load(Context& context, QuestBook& book) {
    const table::TsvResult outline = table::parse_tsv(kOutline);
    const table::TsvResult kinds = table::parse_tsv(kKinds);
    context.expect(outline.has_value() && kinds.has_value(), "bảng mẫu phân tích được");
    if (!outline || !kinds) return;
    context.expect(!ui::panel::load_quest_tables(book, *outline, *kinds).has_value(), "nạp bảng không lỗi");
}

void tables_load_or_report(Context& context) {
    QuestBook book;
    load(context, book);
    context.expect(book.outline.size() == 1 && book.outline[0].mission == 1682, "một dòng nhiệm vụ");
    context.expect(book.kinds.size() == 1 && book.kinds[0].id == 17, "một loại");
    const table::TsvResult broken = table::parse_tsv(kBrokenOutline);
    const table::TsvResult kinds = table::parse_tsv(kKinds);
    if (!broken || !kinds) return;
    context.expect(ui::panel::load_quest_tables(book, *broken, *kinds).has_value(), "bảng thiếu cột báo lỗi");
    context.expect(book.outline.size() == 1, "lỗi thì giữ dữ liệu cũ");
}

void opener_toggles_book_and_desk(Context& context) {
    QuestBook book;
    load(context, book);
    ui::panel::Desk desk;
    hero::Hero hero;
    std::vector<Call> calls;
    ui::panel::press_desk(desk, ui::panel::kQuestLogOpener);
    ui::panel::press_quest_book(book, desk, ui::panel::kQuestLogOpener, &hero, nullptr, calls);
    context.expect(book.panel.is_shown, "nút mở hiện bảng");
    context.expect(ui::panel::is_open(desk, Board::kQuest), "bàn xếp hạng bảng nhiệm vụ");
    ui::panel::press_desk(desk, ui::panel::kQuestLogOpener);
    ui::panel::press_quest_book(book, desk, ui::panel::kQuestLogOpener, &hero, nullptr, calls);
    context.expect(!book.panel.is_shown, "bấm lại thì ẩn");
    context.expect(!ui::panel::is_open(desk, Board::kQuest), "bàn bỏ hạng");
}

void close_button_closes_both(Context& context) {
    QuestBook book;
    load(context, book);
    ui::panel::Desk desk;
    std::vector<Call> calls;
    ui::panel::press_desk(desk, ui::panel::kQuestLogOpener);
    ui::panel::press_quest_book(book, desk, ui::panel::kQuestLogOpener, nullptr, nullptr, calls);
    ui::panel::press_desk(desk, "QuestLog_Close");
    ui::panel::press_quest_book(book, desk, "QuestLog_Close", nullptr, nullptr, calls);
    context.expect(!book.panel.is_shown, "nút đóng ẩn bảng");
    context.expect(!ui::panel::is_open(desk, Board::kQuest), "nút đóng bỏ hạng của bàn");
}

void desk_close_hides_book(Context& context) {
    QuestBook book;
    load(context, book);
    ui::panel::Desk desk;
    std::vector<Call> calls;
    ui::panel::press_desk(desk, ui::panel::kQuestLogOpener);
    ui::panel::press_quest_book(book, desk, ui::panel::kQuestLogOpener, nullptr, nullptr, calls);
    ui::panel::close_board(desk, Board::kQuest);
    ui::panel::press_quest_book(book, desk, "QuestLog_Mode1", nullptr, nullptr, calls);
    context.expect(!book.panel.is_shown, "bàn đóng thì bảng thôi hiện");
}

void seeker_follows_hero(Context& context) {
    hero::Hero hero;
    hero.level = 42;
    const quest::Seeker seeker = ui::panel::seeker_of(&hero);
    context.expect(seeker.level == 42 && seeker.compat_level == 42, "cấp theo nhân vật");
    context.expect(seeker.sect == quest::kNoSect, "chưa nhập môn");
    context.expect(ui::panel::seeker_of(nullptr).level == quest::Seeker{}.level, "không nhân vật thì người mới");
}

void paints_only_when_shown(Context& context) {
    QuestBook book;
    load(context, book);
    ui::panel::Deck deck;
    ui::panel::paint_quest_book(deck, book);
    context.expect(deck.overrides().empty(), "chưa mở thì không kê");
    ui::panel::Desk desk;
    std::vector<Call> calls;
    ui::panel::press_desk(desk, ui::panel::kQuestLogOpener);
    ui::panel::press_quest_book(book, desk, ui::panel::kQuestLogOpener, nullptr, nullptr, calls);
    ui::panel::paint_quest_book(deck, book);
    context.expect(!deck.overrides().empty(), "đang mở thì kê");
}

constexpr std::array kCases{
    Case{.name = "tables_load_or_report", .body = &tables_load_or_report},
    Case{.name = "opener_toggles_book_and_desk", .body = &opener_toggles_book_and_desk},
    Case{.name = "close_button_closes_both", .body = &close_button_closes_both},
    Case{.name = "desk_close_hides_book", .body = &desk_close_hides_book},
    Case{.name = "seeker_follows_hero", .body = &seeker_follows_hero},
    Case{.name = "paints_only_when_shown", .body = &paints_only_when_shown},
};

} // namespace
} // namespace game::test

int main() {
    game::core::check(game::test::run_all(game::test::kCases) == 0, "ui_quest_book_tests: mọi ca phải qua");
    return 0;
}