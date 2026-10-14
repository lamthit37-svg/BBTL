# combat: kỹ năng, buff/hiệu ứng, chuỗi sát thương và hồi phục, hồi chiêu, mục tiêu, gom/dẫn khí, sự kiện đầu ra.
# Thuần: không mạng, không database, không đồng hồ thật; thời gian là tick 20 Hz, ngẫu nhiên là dice::Dice do nơi gọi
# đưa vào. Dùng actor (thân thể), table (đọc TSV), ids, dice và protocol (tầng byte của bản ghi bền).
game_module(combat
    src/server/combat/arena.cpp
    src/server/combat/arena_buff.cpp
    src/server/combat/arena_cast.cpp
    src/server/combat/arena_damage.cpp
    src/server/combat/catalog.cpp
    src/server/combat/codec.cpp
    src/server/combat/damage.cpp
    src/server/combat/detail/effects.cpp
    src/server/combat/detail/effects_damage.cpp
    src/server/combat/detail/effects_hook.cpp
    src/server/combat/detail/effects_stat.cpp
    src/server/combat/detail/skills.cpp)
target_link_libraries(game_combat PUBLIC game_core game_table game_ids game_dice game_protocol game_actor)
