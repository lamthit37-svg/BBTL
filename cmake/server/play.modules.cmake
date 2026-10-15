# play: người chơi trong zone nhìn từ lõi gameplay (sổ nhiệm vụ, thân thể, ví, túi), thế giới dữ liệu đã nạp (World) và cửa vào
# của zone (Gameplay: nhận ý định hội thoại/nhiệm vụ, trả tin). Nối actor, item, ledger, mission, talk, handlers với account::PlayRecord;
# không biết socket hay đồng hồ thật. Phụ thuộc account nên chỉ có khi account dựng được.
if(TARGET game_account)
    game_module(play
        src/server/play/text.cpp
        src/server/play/bag.cpp
        src/server/play/world.cpp
        src/server/play/player.cpp
        src/server/play/battle.cpp
        src/server/play/gameplay.cpp)
    target_link_libraries(game_play
        PUBLIC game_core game_table game_ids game_dice game_protocol game_ops game_ledger game_mission game_talk game_handlers
               game_actor game_item game_combat game_loot game_account game_ipc
        PRIVATE game_io)
endif()
