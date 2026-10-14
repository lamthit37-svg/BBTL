game_test(billing game_billing)
# Hai test dưới nối PostgreSQL của bản thử (dev/server/config/secrets.local.toml); không có thì từng ca tự bỏ qua.
if(TARGET game_billing_db)
    game_test(billing_db game_billing_db game_config game_io)
    if(TARGET billing_db_tests)
        target_compile_definitions(billing_db_tests PRIVATE
            "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/dev/server/config\"")
    endif()
endif()
# billing_serve chạy exe thật thienlong_billing trên database tạm, nên cần bản dựng của nó cạnh test.
if(TARGET game_billing_serve AND TARGET thienlong_billing)
    game_test(billing_serve game_billing_serve game_billing_db game_process game_config game_io)
    if(TARGET billing_serve_tests)
        target_compile_definitions(billing_serve_tests PRIVATE
            "GAME_SERVER_CONFIG=\"${PROJECT_SOURCE_DIR}/dev/server/config\"")
        add_dependencies(billing_serve_tests thienlong_billing)
    endif()
endif()
