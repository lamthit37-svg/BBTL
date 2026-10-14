#include "ui/panel/quest_book.hpp"

#include <utility>

namespace game::ui::panel {
namespace {

[[nodiscard]] QuestFacts facts_of(QuestBook& book, const hero::Hero* hero, const gui::StringBook* scenes) {
    QuestFacts facts;
    facts.seeker = seeker_of(hero);
    facts.log = &book.log;
    facts.outline = book.outline;
    facts.kinds = book.kinds;
    facts.tracking = &book.tracking;
    facts.scenes = scenes;
    return facts;
}

// Bảng tự đóng (nút đóng, từ chối) hay tự mở (nút mở) thì thứ hạng của bàn theo nó; bàn đã đóng
// bảng bằng nút đóng chung thì bảng cũng thôi hiện.
void settle_desk(QuestBook& book, Desk& desk) noexcept {
    const bool is_ranked = is_open(desk, Board::kQuest);
    if (book.panel.is_shown && !is_ranked) toggle_board(desk, Board::kQuest);
    if (!book.panel.is_shown && is_ranked) close_board(desk, Board::kQuest);
}

} // namespace

std::optional<std::string> load_quest_tables(QuestBook& book, const table::Tsv& outline, const table::Tsv& kinds) {
    quest::OutlineRows rows = quest::read_outline(outline);
    if (!rows) return std::move(rows.error());
    quest::KindRows names = quest::read_kinds(kinds);
    if (!names) return std::move(names.error());
    book.outline = std::move(*rows);
    book.kinds = std::move(*names);
    return std::nullopt;
}

quest::Seeker seeker_of(const hero::Hero* hero) noexcept {
    quest::Seeker seeker;
    if (hero == nullptr) return seeker;
    seeker.level = hero->level;
    seeker.compat_level = hero->level;
    seeker.sect = static_cast<std::int32_t>(hero->sect);
    return seeker;
}

void press_quest_book(QuestBook& book, Desk& desk, std::string_view window, const hero::Hero* hero,
    const gui::StringBook* scenes, std::vector<Call>& calls) {
    const QuestFacts facts = facts_of(book, hero, scenes);
    // press_desk vừa đảo thứ hạng theo nút mở; bảng dựng lại thẻ hiện tại rồi đảo theo đúng sự kiện.
    if (window == kQuestLogOpener) {
        toggle_quest_log(book.panel, facts, calls);
    } else if (book.panel.is_shown) {
        press_quest_log(book.panel, window, facts, calls);
        if (!is_open(desk, Board::kQuest)) book.panel.is_shown = false;
    }
    settle_desk(book, desk);
}

bool pick_quest_row(QuestBook& book, std::size_t row, const hero::Hero* hero, const gui::StringBook* scenes) {
    if (!book.panel.is_shown) return false;
    const std::optional<std::int32_t> id = book.panel.widgets.item_id(kQuestLogList, row);
    if (!id) return false;
    pick_quest_item(book.panel, *id, facts_of(book, hero, scenes));
    return true;
}

void paint_quest_book(Deck& deck, const QuestBook& book) {
    paint_quest_log(deck, book.panel);
}

} // namespace game::ui::panel