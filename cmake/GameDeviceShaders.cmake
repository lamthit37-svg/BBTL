# Gói shader .f2s cho thiết bị (APK, bundle iOS). thienlong_shader chỉ chạy trên Windows, nên bản
# Android và iOS lấy gói từ một cây dựng PC đã có thay vì dựng lại. Hàm chọn cây đầu tiên có đủ gói:
# cây hàng ngày trước (msvc-release, msvc-debug), cây chẩn đoán còn sót (clang-asan) sau cùng. Không
# ghim một tên preset: cây chẩn đoán bị xoá khi hết đợt soi bug (CLAUDE.md, mục "Một cây build").
# Biến cache đã đặt tay và còn đủ gói thì giữ nguyên.
function(game_device_shaders variable doc)
    set(current "${${variable}}")
    if(current AND EXISTS "${current}/model.vs.f2s" AND EXISTS "${current}/model.ps.f2s")
        return()
    endif()
    # Không cây nào có gói thì vẫn trỏ về cây hàng ngày: thông báo thiếu tệp của nơi gọi nêu đúng
    # chỗ cần dựng.
    set(picked "${PROJECT_SOURCE_DIR}/build/msvc-release/shaders")
    foreach(preset msvc-release msvc-debug clang-asan)
        set(candidate "${PROJECT_SOURCE_DIR}/build/${preset}/shaders")
        if(EXISTS "${candidate}/model.vs.f2s" AND EXISTS "${candidate}/model.ps.f2s")
            set(picked "${candidate}")
            break()
        endif()
    endforeach()
    set(${variable} "${picked}" CACHE PATH "${doc}" FORCE)
endfunction()
