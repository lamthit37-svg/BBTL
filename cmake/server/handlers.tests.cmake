game_test(handlers game_handlers)
if(TARGET handlers_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/server/talk_blocks.tsv")
    target_compile_definitions(handlers_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
endif()
