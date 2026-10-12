# cmake/GameWarnings.cmake — một nguồn sự thật cho cảnh báo.
foreach(kind IN ITEMS common gcc clang)
    set(file "${PROJECT_SOURCE_DIR}/config/warnings-${kind}.txt")
    file(STRINGS "${file}" GAME_WARNINGS_${kind})
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${file}")
endforeach()

add_library(game_warnings INTERFACE)
add_library(game::warnings ALIAS game_warnings)
# Biểu thức sinh có danh sách bên trong PHẢI nằm trong ngoặc kép, nếu không ';' cắt đôi nó.
target_compile_options(game_warnings INTERFACE
    "$<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:${GAME_WARNINGS_common}>"
    "$<$<CXX_COMPILER_ID:GNU>:${GAME_WARNINGS_gcc}>"
    "$<$<CXX_COMPILER_ID:Clang,AppleClang>:${GAME_WARNINGS_clang}>"
    "$<$<CXX_COMPILER_ID:MSVC>:/W4;/permissive-;/Zc:__cplusplus;/Zc:preprocessor;/utf-8>")
