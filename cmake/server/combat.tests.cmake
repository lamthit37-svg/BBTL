game_test(combat game_combat)
if(TARGET combat_tests)
    target_compile_definitions(combat_tests PRIVATE GAME_SERVER_TABLES="${PROJECT_SOURCE_DIR}/dev/server/tables")
endif()
