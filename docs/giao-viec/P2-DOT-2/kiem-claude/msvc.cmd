@echo off
rem Cau hinh, dung va chay test preset msvc-release trong moi truong cua dev.bat.
call "%USERPROFILE%\.claude\skills\cpp-build\dev.bat"
if errorlevel 1 exit /b 90
cmake --preset msvc-release
if errorlevel 1 exit /b 91
cmake --build --preset msvc-release --target all header_check
if errorlevel 1 exit /b 92
ctest --preset msvc-release
exit /b %errorlevel%
