# ids (dùng chung) và dice (máy chủ): nền của mọi module gameplay.
game_module(ids src/shared/ids/ids.cpp)
target_link_libraries(game_ids PUBLIC game_core)
game_module(dice src/server/dice/dice.cpp)
target_link_libraries(game_dice PUBLIC game_core)
