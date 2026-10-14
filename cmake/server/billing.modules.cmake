# billing: sổ điểm nạp, đơn nạp, đổi điểm lấy ingot, mã đổi, webhook, giao thức ipc. Lõi thuần (chỉ core, ids,
# table, secure); phần PostgreSQL (billing/db) và tiến trình (billing/serve) chỉ có khi có libpq.
game_module(billing
    src/server/billing/error.cpp
    src/server/billing/limits.cpp
    src/server/billing/rules.cpp
    src/server/billing/book.cpp
    src/server/billing/checks.cpp
    src/server/billing/memory_book.cpp
    src/server/billing/code.cpp
    src/server/billing/throttle.cpp
    src/server/billing/wire.cpp
    src/server/billing/rpc.cpp
    src/server/billing/http.cpp
    src/server/billing/webhook.cpp)
target_link_libraries(game_billing PUBLIC game_core game_ids game_table game_secure)
# PgBook (libpq) và tiến trình billingd. game_store và game_account chỉ có khi cấu hình có vcpkg (libpq).
if(TARGET game_store AND TARGET game_account)
    game_module(billing_db src/server/billing/db/pg_book.cpp)
    target_link_libraries(game_billing_db PUBLIC game_billing game_store)
    game_module(billing_serve
        src/server/billing/serve/setup.cpp
        src/server/billing/serve/client.cpp
        src/server/billing/serve/webhook_server.cpp
        src/server/billing/serve/serve.cpp)
    target_link_libraries(game_billing_serve PUBLIC game_billing_db game_account game_config game_io game_net
        game_process game_protocol game_secure game_ids)
    if(TARGET game_service)
        target_link_libraries(game_service PUBLIC game_billing_serve)
    endif()
endif()
