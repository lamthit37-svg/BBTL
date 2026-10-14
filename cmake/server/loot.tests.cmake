# Test của lõi rơi đồ. Ca đọc bảng thật chỉ chạy khi có dev/server/tables (GAME_SERVER_TABLES).
foreach(loot_test loot_tables loot_roll loot_box)
    game_test(${loot_test} game_loot)
    if(TARGET ${loot_test}_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/shared/items_common.tsv")
        target_compile_definitions(${loot_test}_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
    endif()
endforeach()
