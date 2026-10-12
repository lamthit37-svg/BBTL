# cmake/GameI18n.cmake — bản địa hoá dựng cùng client (chủ dự án chốt ngày 2026-10-08).
# Ngôn ngữ chọn lúc dựng bằng GAME_LANGUAGE; bản triển khai chỉ chứa chữ và ảnh của ngôn ngữ đó,
# client không chọn ngôn ngữ lúc chạy. Nguồn của mỗi ngôn ngữ là MỘT tệp assets/i18n/<mã>.tsv (chữ
# giao diện, tên cảnh, ảnh thay) kèm các PNG ở assets/i18n/<mã>/. TOOLS/content/build_i18n.py đưa
# nguồn đã chọn vào CLIENT/data: hai bảng Table/*.lang.tsv, và thay ảnh ngay trong các atlas của
# Interface (atlas gốc giữ ở build/i18n, ngoài bản triển khai). Target thienlong_i18n chạy ở mỗi
# lượt dựng và là phụ thuộc của thienlong_client; công cụ tự bỏ qua thứ không đổi. CLIENT/data dùng
# chung cho mọi preset, nên các preset phải dựng cùng một GAME_LANGUAGE. Không có Python thì bỏ qua
# kèm một dòng báo; client khi đó hiện chữ và ảnh gốc.
# GAME_I18N_STAMP là tệp mốc công cụ chỉ ghi lại khi bản triển khai đổi: bước đóng gói (APK) khai nó
# làm đầu vào để đóng lại ngay trong lượt dựng vừa đổi chữ hay ảnh. Thiếu mốc thì Ninja chỉ biết
# tệp trong CLIENT/data đổi ở lượt dựng SAU, vì nó xét ngày tệp trước khi bước i18n chạy.
set(GAME_LANGUAGE "vi" CACHE STRING "Ngôn ngữ của bản dựng: tên tệp assets/i18n/<mã>.tsv")
set(game_i18n_source "${PROJECT_SOURCE_DIR}/assets/i18n/${GAME_LANGUAGE}.tsv")
if(NOT EXISTS "${game_i18n_source}")
    message(FATAL_ERROR "GAME_LANGUAGE=${GAME_LANGUAGE}: không có tệp ${game_i18n_source}")
endif()
find_package(Python3 COMPONENTS Interpreter)
if(NOT Python3_Interpreter_FOUND)
    message(STATUS "i18n: không thấy Python, không dựng bản địa hoá")
    return()
endif()

set(GAME_I18N_STAMP "${PROJECT_SOURCE_DIR}/build/i18n/deployed.stamp")
add_custom_target(thienlong_i18n ALL
    COMMAND ${CMAKE_COMMAND} -E env PYTHONUTF8=1 "${Python3_EXECUTABLE}" -B
        TOOLS/content/build_i18n.py "assets/i18n/${GAME_LANGUAGE}.tsv" CLIENT/data --state build/i18n
    BYPRODUCTS "${GAME_I18N_STAMP}"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    COMMENT "i18n: đưa bản ${GAME_LANGUAGE} vào CLIENT/data"
    VERBATIM)
add_dependencies(thienlong_client thienlong_i18n)

# Test của chính bộ dựng (tệp nguồn sai dạng, ảnh lệch cỡ, thay ảnh trong atlas, trả về bản gốc).
add_test(NAME i18n_tool_tests
    COMMAND "${Python3_EXECUTABLE}" -B TOOLS/content/test_build_i18n.py
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
