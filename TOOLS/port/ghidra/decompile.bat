@echo off
rem Decompile hàm của client 2026 từ dự án Ghidra TLBB (Desktop), đã phân tích sẵn, chỉ đọc.
rem   decompile.bat <chương trình, ví dụ Game.exe> <tệp xuất> <khoá>...
rem Khoá: 0xĐỊA_CHỈ, s:chuỗi, x:0xĐỊA_CHỈ (xem DecompileAt.java). Dự án bị khoá khi Ghidra đang mở
rem hay đang phân tích: chạy lần lượt, không song song.
setlocal
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "GH=C:\Users\myhea\Desktop\ghidra_12.1.4_PUBLIC\support\analyzeHeadless.bat"
set "PROJDIR=C:\Users\myhea\Desktop\ghidra-projects"
set "SCRIPTS=%~dp0."
set "PROG=%~1"
set "OUT=%~2"
shift
shift
set "KEYS="
:more
if "%~1"=="" goto run
set KEYS=%KEYS% "%~1"
shift
goto more
:run
call "%GH%" "%PROJDIR%" TLBB -process "%PROG%" -noanalysis -readOnly -scriptPath "%SCRIPTS%" -postScript DecompileAt.java "%OUT%"%KEYS%
exit /b %errorlevel%
