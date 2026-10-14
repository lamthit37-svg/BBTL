@echo off
rem Xuất tệp gốc của một chương trình trong dự án Ghidra TLBB ra đĩa (Game.exe 2026 không còn ở F:\tl 2026).
rem   export_original.cmd <tên chương trình, vd Game.exe> <đường dẫn tệp xuất>
rem Chỉ đọc dự án (-readOnly -noanalysis). Cần JDK 21 và Ghidra 12.1.4 như dòng set bên dưới.
setlocal
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "GH=C:\Users\myhea\Desktop\ghidra\ghidra_12.1.4_PUBLIC\support\analyzeHeadless.bat"
set "PROJDIR=C:\Users\myhea\Desktop\ghidra\projects"
call "%GH%" "%PROJDIR%" TLBB -process "%~1" -noanalysis -readOnly -scriptPath "%~dp0." -postScript ExportOriginal.java "%~2"
exit /b %errorlevel%
