# cmake/GameSplitDebug.cmake
function(game_split_debug target)
    # Clang nhắm MSVC: debug info đã nằm riêng trong .pdb, không có objcopy.
    # Khác mẫu: cl của MSVC cũng ghi PDB riêng.
    if(CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC" OR CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        return()
    endif()
    # Khác mẫu: Apple tách symbol bằng dsymutil của Xcode, không có objcopy.
    if(APPLE)
        return()
    endif()
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} --only-keep-debug $<TARGET_FILE:${target}>
                $<TARGET_FILE:${target}>.debug
        COMMAND ${CMAKE_OBJCOPY} --strip-debug --strip-unneeded $<TARGET_FILE:${target}>
        COMMAND ${CMAKE_OBJCOPY} --add-gnu-debuglink=$<TARGET_FILE:${target}>.debug
                $<TARGET_FILE:${target}>
        VERBATIM)
endfunction()
