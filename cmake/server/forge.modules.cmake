# forge: lò rèn của máy chủ (công thức nung ngọc, chạm ngọc và nâng cấp siêu vũ khí; chế biến nguyên tử trên kế hoạch túi và
# ví). Không mạng, không database; dựa vào item (mẫu, kế hoạch túi và ví, Factory), dice và ids.
game_module(forge
    src/server/forge/tables.cpp
    src/server/forge/craft.cpp)
target_link_libraries(game_forge PUBLIC game_core game_ids game_dice game_item)
