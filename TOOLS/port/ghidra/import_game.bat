@echo off
rem Nhập Game.exe của client 2026 vào dự án Ghidra TLBB (Desktop) và phân tích đầy đủ.
rem Chạy một lần, mất lâu. Sau đó đọc hàm bằng decompile.bat. Tệp PE chỉ đọc.
setlocal
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "GH=C:\Users\myhea\Desktop\ghidra_12.1.4_PUBLIC\support\analyzeHeadless.bat"
set "PROJDIR=C:\Users\myhea\Desktop\ghidra-projects"
call "%GH%" "%PROJDIR%" TLBB -import "F:\tl 2026\2026\Bin64\Game.exe" -overwrite -analysisTimeoutPerFile 10800
exit /b %errorlevel%
