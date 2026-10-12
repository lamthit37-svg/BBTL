// Thanh chính (MainMenuBar): phần do trạng thái nhân vật điều khiển. Hiện mới có thanh kinh nghiệm,
// theo MainMenuBar_UpdateExp của script gốc: SetProgress(EXP / NEEDEXP, 1).
// Nguồn: G:\TLBB\_content\source\Interface\MainMenuBar\MainMenuBar.lua (dòng 633-643).
// Khác gốc: kinh nghiệm cần bằng 0 thì chia cho 1 như các thanh khác (bản gốc chia cho 0).
#pragma once

#include "hero/hero.hpp"
#include "ui/panel/deck.hpp"

namespace game::ui::panel {

// Ghi chỉ thị của thanh chính cho hero.
void fill_menubar(Deck& deck, const hero::Hero& hero);

} // namespace game::ui::panel
