# Test của lò rèn. Ca đọc bảng thật chỉ chạy khi có dev/server/tables (GAME_SERVER_TABLES).
foreach(forge_test forge_tables forge_craft)
    game_test(${forge_test} game_forge)
    if(TARGET ${forge_test}_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/shared/items_common.tsv")
        target_compile_definitions(${forge_test}_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
    endif()
endforeach()
