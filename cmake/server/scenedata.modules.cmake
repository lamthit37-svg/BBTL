# scenedata: nạp dữ liệu cảnh máy chủ (dev/server/scenes/<tên>) và bảng luật AI quái thành struct có kiểu.
# Thuần ngoài disk.cpp (chỗ duy nhất đọc hệ tệp, qua io); dùng table (TSV), ids, nav (lưới đi .path của client 2026).
game_module(scenedata
    src/server/scenedata/ai_rules.cpp
    src/server/scenedata/disk.cpp
    src/server/scenedata/scene.cpp
    src/server/scenedata/tables.cpp
    src/server/scenedata/walk.cpp
    src/server/scenedata/detail/cells.cpp)
target_link_libraries(game_scenedata PUBLIC game_core game_io game_table game_ids game_nav)
