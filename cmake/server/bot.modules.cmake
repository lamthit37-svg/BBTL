# thienlong_bot: khách giả để kiểm đường gate -> zone -> gate trên cụm máy chủ thật (TOOLS/server/bot.cpp).
if(TARGET game_link AND TARGET game_io)
    add_executable(thienlong_bot TOOLS/server/bot.cpp)
    target_link_libraries(thienlong_bot PRIVATE game_link game_secure game_protocol game_net game_io game_core
        game::warnings)
endif()
