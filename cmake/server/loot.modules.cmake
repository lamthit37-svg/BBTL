# loot: rơi đồ của máy chủ (bảng gói rơi và bảng rơi của quái, xác suất bằng số nguyên, hộp rơi có chủ và hạn, chia đồ giữa
# người có quyền). Không mạng, không database; dựa vào item (mẫu, thể hiện, kế hoạch túi), dice và ids.
game_module(loot
    src/server/loot/chance.cpp
    src/server/loot/tables.cpp
    src/server/loot/box.cpp
    src/server/loot/roller.cpp)
target_link_libraries(game_loot PUBLIC game_core game_ids game_dice game_item)
