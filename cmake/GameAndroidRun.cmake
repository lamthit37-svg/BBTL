# cmake/GameAndroidRun.cmake — chạy một exe Android trên thiết bị qua adb.
# ctest gọi tệp này làm CMAKE_CROSSCOMPILING_EMULATOR: cmake -P <tệp này> <exe> [đối số...].
# Exe được đẩy vào /data/local/tmp/thienlong rồi chạy tại đó; mã thoát của nó thành mã thoát ở đây.
# Chọn thiết bị bằng biến môi trường ANDROID_SERIAL khi cắm nhiều máy.
set(exe "${CMAKE_ARGV3}")
if(NOT EXISTS "${exe}")
    message(FATAL_ERROR "android: không thấy exe ${exe}")
endif()
set(arguments "")
math(EXPR last "${CMAKE_ARGC} - 1")
if(last GREATER 3)
    foreach(index RANGE 4 ${last})
        string(APPEND arguments " \"${CMAKE_ARGV${index}}\"")
    endforeach()
endif()
get_filename_component(name "${exe}" NAME)
set(folder "/data/local/tmp/thienlong")
execute_process(COMMAND adb shell "mkdir -p ${folder}" RESULT_VARIABLE made OUTPUT_QUIET)
if(NOT made EQUAL 0)
    message(FATAL_ERROR "android: adb không tới được thiết bị")
endif()
execute_process(COMMAND adb push "${exe}" "${folder}/${name}" RESULT_VARIABLE pushed OUTPUT_QUIET)
if(NOT pushed EQUAL 0)
    message(FATAL_ERROR "android: không đẩy được ${name}")
endif()
execute_process(
    COMMAND adb shell "chmod 755 ${folder}/${name} && cd ${folder} && ./${name}${arguments}"
    RESULT_VARIABLE code)
if(NOT code EQUAL 0)
    message(FATAL_ERROR "android: ${name} thoát với mã ${code}")
endif()
