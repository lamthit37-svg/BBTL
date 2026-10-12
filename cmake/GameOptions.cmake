# cmake/GameOptions.cmake — macro cấu hình chung cho MỌI đơn vị dịch.
add_library(game_options INTERFACE)
add_library(game::options ALIAS game_options)
option(GAME_DEBUG_CHECKS_IN_RELEASE "Bật core::debug_check cả ở bản tối ưu" OFF)
target_compile_definitions(game_options INTERFACE
    "$<$<OR:$<CONFIG:Debug>,$<BOOL:${GAME_DEBUG_CHECKS_IN_RELEASE}>>:GAME_DEBUG_CHECKS>")
