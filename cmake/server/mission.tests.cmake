# Test của mission. mission_book_tests đối chiếu bố cục với sổ nhiệm vụ của client nên cần thêm đường include của nó;
# mission_data_tests đọc bảng thật khi có dev/server/tables/server (GAME_SERVER_TABLES), không có thì bỏ qua ca đó.
foreach(mission_test mission_book mission_flow mission_catalog mission_data)
    game_test(${mission_test} game_mission)
endforeach()
if(TARGET mission_book_tests)
    target_include_directories(mission_book_tests PRIVATE "${PROJECT_SOURCE_DIR}/src/client/book")
endif()
foreach(mission_test mission_data mission_catalog)
    if(TARGET ${mission_test}_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/server/mission_quests.tsv")
        target_compile_definitions(${mission_test}_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
    endif()
endforeach()
