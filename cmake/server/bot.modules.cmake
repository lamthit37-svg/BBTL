# thienlong_bot: khách giả để kiểm đường gate -> zone -> gate trên cụm máy chủ thật (TOOLS/server/bot.cpp).
# game_nav cho --walk (đi vòng vật cản bằng luật đi của client); TARGET_NAME_IF_EXISTS để không phụ thuộc
# thứ tự nạp module.
if(TARGET game_link AND TARGET game_io)
    add_executable(thienlong_bot TOOLS/server/bot.cpp)
    target_link_libraries(thienlong_bot PRIVATE game_link game_secure game_protocol game_net game_io game_core
        $<TARGET_NAME_IF_EXISTS:game_nav> game::warnings)
endif()
