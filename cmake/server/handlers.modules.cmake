# handlers: bảng handler hội thoại viết tay theo (script, num) và bộ kiểm audit. Rỗng cho tới khi một hệ thống ngoài làn của
# vai MISSION (kỹ năng sống, đội, thành phố, phụ bản) nối vào và thêm handler của nó.
game_module(handlers
    src/server/handlers/registry.cpp)
target_link_libraries(game_handlers PUBLIC game_core game_ids game_ops game_ledger game_mission game_talk)
