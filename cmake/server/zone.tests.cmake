if(TARGET game_zone)
    game_test(zone game_zone)
    if(TARGET zone_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/scenes")
        # Ca đọc cảnh thật tự bỏ qua khi thư mục này không có (checkout rút gọn, thiết bị).
        target_compile_definitions(zone_tests PRIVATE GAME_SERVER_DATA="${PROJECT_SOURCE_DIR}/dev/server")
    endif()
endif()
