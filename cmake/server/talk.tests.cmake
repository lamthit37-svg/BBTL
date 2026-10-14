# Test của talk. talk_data_tests đọc bảng thật khi có dev/server/tables/server (GAME_SERVER_TABLES), không có thì bỏ qua ca đó.
foreach(talk_test talk_flow talk_script talk_data)
    game_test(${talk_test} game_talk)
endforeach()
foreach(talk_test talk_script talk_data)
    if(TARGET ${talk_test}_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/server/talk_blocks.tsv")
        target_compile_definitions(${talk_test}_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
    endif()
endforeach()
