# cmake/GameI18n.cmake — bản địa hoá dựng cùng client (chủ dự án chốt ngày 2026-10-08).
# Ngôn ngữ chọn lúc dựng bằng GAME_LANGUAGE; bản triển khai chỉ chứa chữ và ảnh của ngôn ngữ đó,
# client không chọn ngôn ngữ lúc chạy. Nguồn của mỗi ngôn ngữ là MỘT tệp assets/i18n/<mã>.tsv (chữ
# giao diện, tên cảnh, ảnh thay) kèm các PNG ở assets/i18n/<mã>/. TOOLS/content/build_i18n.py đưa
# nguồn đã chọn vào dev/client/assets: hai bảng Table/*.lang.tsv, và thay ảnh ngay trong các atlas của
# Interface (atlas gốc giữ ở build/i18n). Target thienlong_i18n không gắn vào lượt dựng thường
# (bản đang chạy dùng assets gốc). Gọi tay khi muốn phủ ngôn ngữ. Bản thử dùng một cây assets, nên các preset
# phải dựng cùng một GAME_LANGUAGE. Không có Python thì bỏ qua kèm một dòng báo; client khi đó hiện
# chữ và ảnh gốc.
# GAME_I18N_STAMP là tệp mốc công cụ chỉ ghi lại khi bản thử đổi: bước đóng gói (APK) khai nó
# làm đầu vào để đóng lại ngay trong lượt dựng vừa đổi chữ hay ảnh. Thiếu mốc thì Ninja chỉ biết
# tệp trong dev/client/assets đổi ở lượt dựng SAU, vì nó xét ngày tệp trước khi bước i18n chạy.
# 2026-10-16: chủ dự án trả toàn bộ giao diện về chữ gốc của client. Mặc định zh.
# Bản vi vẫn dựng được bằng -DGAME_LANGUAGE=vi.
set(GAME_LANGUAGE "zh" CACHE STRING "Ngôn ngữ của bản dựng: tên tệp assets/i18n/<mã>.tsv")
set(game_i18n_source "${PROJECT_SOURCE_DIR}/assets/i18n/${GAME_LANGUAGE}.tsv")
if(NOT EXISTS "${game_i18n_source}")
    message(FATAL_ERROR "GAME_LANGUAGE=${GAME_LANGUAGE}: không có tệp ${game_i18n_source}")
endif()
find_package(Python3 COMPONENTS Interpreter)
if(NOT Python3_Interpreter_FOUND)
    message(STATUS "i18n: không thấy Python, không dựng bản địa hoá")
    return()
endif()

# 2026-10-16: chủ dự án trả dev/client/assets về bản gom gốc, không phủ chữ. Target còn để
# dựng tay (cmake --build --target thienlong_i18n) khi muốn phủ một ngôn ngữ trở lại.
set(GAME_I18N_STAMP "${PROJECT_SOURCE_DIR}/build/i18n/deployed.stamp")
add_custom_target(thienlong_i18n
    COMMAND ${CMAKE_COMMAND} -E env PYTHONUTF8=1 "${Python3_EXECUTABLE}" -B
        TOOLS/content/build_i18n.py "assets/i18n/${GAME_LANGUAGE}.tsv" dev/client/assets --state build/i18n
    BYPRODUCTS "${GAME_I18N_STAMP}"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    COMMENT "i18n: đưa bản ${GAME_LANGUAGE} vào dev/client/assets"
    VERBATIM)

# Test của chính bộ dựng (tệp nguồn sai dạng, ảnh lệch cỡ, thay ảnh trong atlas, trả về bản gốc).
add_test(NAME i18n_tool_tests
    COMMAND "${Python3_EXECUTABLE}" -B TOOLS/content/test_build_i18n.py
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
# Bộ nấu texture điện thoại phải lấy ảnh giao diện đã địa hoá (<gốc>.png cùng cỡ), không phải bản gốc.
add_test(NAME bake_mobile_textures_tests
    COMMAND "${Python3_EXECUTABLE}" -B TOOLS/content/test_bake_mobile_textures.py
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
# Cổng i18n ba thứ tiếng (luật chữ của chủ dự án): khoá zh/en/vi lệch, chữ Hán sót trong en/vi,
# khoá dùng mà thiếu, thoại lệch khoá, chuỗi Hán viết cứng trong client. Danh sách nền chỉ co lại.
add_test(NAME i18n_gate
    COMMAND "${Python3_EXECUTABLE}" -B -X utf8 TOOLS/content/check_i18n.py
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
