# zone: cảnh, vùng nhìn và thực thể của máy chủ; zoned chạy nó ở 20 Hz. Dựa vào kênh ipc với gate.
if(TARGET game_account)
    game_module(zone
        src/server/zone/aoi.cpp
        src/server/zone/scene.cpp
        src/server/zone/host.cpp
        src/server/zone/saver.cpp
        src/server/zone/serve.cpp)
    target_link_libraries(game_zone
        PUBLIC game_core game_ipc game_protocol game_ids
        PRIVATE game_config game_account game_io game_net game_process)
    target_link_libraries(game_service PUBLIC game_zone)
endif()
