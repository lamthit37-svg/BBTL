# Test của play. play_tests đọc bảng thật khi có dev/server/tables/server (GAME_SERVER_TABLES), không có thì chỉ chạy ca thuần.
if(TARGET game_play)
    game_test(play game_play)
    if(TARGET play_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/server/talk_blocks.tsv")
        target_compile_definitions(play_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
    endif()
endif()
