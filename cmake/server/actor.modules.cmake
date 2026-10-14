# actor: thân thể chiến đấu (chỉ số, HP/MP/nộ khí, kinh nghiệm, lên cấp, hình phạt chết, bản ghi bền).
# Thuần: không mạng, không database, không đồng hồ; dùng table (đọc TSV), ids, dice và protocol (tầng byte).
game_module(actor
    src/server/actor/body.cpp
    src/server/actor/codec.cpp
    src/server/actor/rules.cpp
    src/server/actor/sheet.cpp)
target_link_libraries(game_actor PUBLIC game_core game_table game_ids game_dice game_protocol)
