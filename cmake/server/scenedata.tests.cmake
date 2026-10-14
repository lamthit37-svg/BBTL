game_test(scenedata game_scenedata)
if(TARGET scenedata_tests)
    # Ca đọc dữ liệu thật tự bỏ qua khi thư mục này không có (checkout mới, thiết bị).
    target_compile_definitions(scenedata_tests PRIVATE GAME_SERVER_DATA="${PROJECT_SOURCE_DIR}/dev/server")
endif()
