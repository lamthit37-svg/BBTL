# Test của lõi vật phẩm. Ca đọc bảng thật chỉ chạy khi có dev/server/tables (GAME_SERVER_TABLES).
foreach(item_test item_catalog item_roll item_bag item_codec item_conserve)
    game_test(${item_test} game_item)
    if(TARGET ${item_test}_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/shared/items_common.tsv")
        target_compile_definitions(${item_test}_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
    endif()
endforeach()
