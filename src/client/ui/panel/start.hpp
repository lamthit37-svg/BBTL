// HUD lúc vừa vào game. Client gốc nạp layout ở trạng thái ẩn rồi để script của từng cửa sổ hiện
// nó khi sự kiện đầu tiên tới, và OnLoad của script giấu một số cửa sổ con. Bảng này ghi lại đúng
// hai việc đó cho các cửa sổ luôn có mặt khi chơi.
// Nguồn: script Interface đọc được ở G:\TLBB\_content\source\Interface (PlayerFrame.lua 68-94,
// MiniMap.lua 75-114, MainMenuBar.lua 176-275, ChatFrame.lua 218-249, FunctionBarRight.lua 28-29).
// PlayerFrame_Head_Parent và PlayerFrame_Head_3D để hiện: chân dung gán vào con, cha che bằng
// mặt nạ HeadRoundRegion. Head_2D giữ ẩn như thuộc tính Visible của layout.
#pragma once

#include "ui/panel/deck.hpp"

namespace game::ui::panel {

// Hiện các gốc của HUD mặc định và giấu những cửa sổ con mà script gốc giấu lúc nạp.
void show_start(Deck& deck);

} // namespace game::ui::panel
