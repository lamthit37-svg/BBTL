# talk: hội thoại do máy chủ giữ (phiên, chương trình hội thoại trích từ script Lua, dấu nhiệm vụ của NPC). Không biết mạng,
# thế giới hay kho đồ: zone nối vào qua talk::World và mission::Character.
game_module(talk
    src/server/talk/script.cpp
    src/server/talk/service.cpp
    src/server/talk/detail/runner.cpp)
target_link_libraries(game_talk PUBLIC game_core game_table game_ids game_ops game_ledger game_bus game_mission)
