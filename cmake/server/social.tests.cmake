# Test của lõi xã hội. Ca đọc bảng thật (social_tables) chỉ có nghĩa khi có dev/server/tables (GAME_SERVER_TABLES);
# bảng ở thư mục shared/ không vào git nên ca tự bỏ qua khi thiếu.
foreach(social_test social_team social_relation social_guild social_city social_mail social_wordfilter social_chat
        social_rank social_notice social_sim social_tables)
    game_test(${social_test} game_social)
endforeach()
if(TARGET social_tables_tests AND EXISTS "${PROJECT_SOURCE_DIR}/dev/server/tables/server/social_limits.tsv")
    target_compile_definitions(social_tables_tests PRIVATE "GAME_SERVER_TABLES=\"${PROJECT_SOURCE_DIR}/dev/server/tables\"")
endif()
