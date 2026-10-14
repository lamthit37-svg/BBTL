@echo off
rem Chạy một lệnh trong môi trường MSVC của dev.bat, ở gốc dự án (gốc = thư mục cha của TOOLS\server).
rem Ví dụ: TOOLS\server\with_dev.bat cmake --build build\ag-x --target dice_tests
call "%USERPROFILE%\.claude\skills\cpp-build\dev.bat" || exit /b 1
cd /d "%~dp0..\.."
%*
