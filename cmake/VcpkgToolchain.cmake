# Toolchain vcpkg chung cho mọi preset (CMakePresets.json). Gốc vcpkg lấy từ biến môi trường
# VCPKG_ROOT. Nếu cạnh gốc đó có toolchain dùng chung của máy (<VCPKG_ROOT>/../third_party/vcpkg.cmake,
# chỗ đặt cây installed, tải về và binary cache chung) thì nạp nó; không thì nạp thẳng toolchain của
# vcpkg. Thiếu VCPKG_ROOT hay thiếu tệp thì dừng cấu hình kèm lời chỉ dẫn.
if(NOT DEFINED ENV{VCPKG_ROOT} OR "$ENV{VCPKG_ROOT}" STREQUAL "")
    message(FATAL_ERROR "Chưa đặt biến môi trường VCPKG_ROOT (thư mục gốc của vcpkg, vd C:/dev/vcpkg).")
endif()
file(TO_CMAKE_PATH "$ENV{VCPKG_ROOT}" GAME_VCPKG_ROOT)
get_filename_component(GAME_VCPKG_SHARED "${GAME_VCPKG_ROOT}/../third_party/vcpkg.cmake" ABSOLUTE)
set(GAME_VCPKG_UPSTREAM "${GAME_VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
if(EXISTS "${GAME_VCPKG_SHARED}")
    include("${GAME_VCPKG_SHARED}")
elseif(EXISTS "${GAME_VCPKG_UPSTREAM}")
    include("${GAME_VCPKG_UPSTREAM}")
else()
    message(FATAL_ERROR "VCPKG_ROOT=${GAME_VCPKG_ROOT} không có scripts/buildsystems/vcpkg.cmake.")
endif()
