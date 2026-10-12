#include "ui/panel/menubar.hpp"

#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"

namespace game::ui::panel {

void fill_menubar(Deck& deck, const hero::Hero& hero) {
    deck.bar("MainMenuBar_EXP2", hero::fill_of(hero.experience));
}

} // namespace game::ui::panel
