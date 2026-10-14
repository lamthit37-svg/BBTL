# Test của ops. Ca đọc bảng thật chỉ chạy khi có dev/server/tables/server (GAME_SERVER_TABLES).
game_test(ops game_ops)
if(TARGET ops_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/server/ops_conditions.tsv")
    target_compile_definitions(ops_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
endif()
