# Test của lõi cửa hàng. Ca đọc bảng thật chỉ chạy khi có dev/server/tables (GAME_SERVER_TABLES).
foreach(shop_test shop_tables shop_trade shop_stock)
    game_test(${shop_test} game_shop)
    if(TARGET ${shop_test}_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/shared/items_common.tsv")
        target_compile_definitions(${shop_test}_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
    endif()
endforeach()
