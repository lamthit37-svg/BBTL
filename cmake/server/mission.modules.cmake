# mission: sổ nhiệm vụ, danh mục nạp từ bảng, bộ chạy (nhận / làm / nộp / bỏ / hỏng, sự kiện) và bản ghi nhị phân có phiên bản.
game_module(mission
    src/server/mission/book.cpp
    src/server/mission/codec.cpp
    src/server/mission/catalog.cpp
    src/server/mission/hero.cpp
    src/server/mission/engine.cpp
    src/server/mission/turnin.cpp
    src/server/mission/events.cpp
    src/server/mission/detail/work.cpp
    src/server/mission/detail/progress.cpp)
target_link_libraries(game_mission PUBLIC game_core game_table game_ids game_dice game_protocol game_ops game_bus game_ledger)
