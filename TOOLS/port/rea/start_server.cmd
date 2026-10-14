@echo off
rem Khởi động rea_server.mjs (giữ một phiên REA/Ghidra). Chạy ẩn: Start-Process cmd.exe -ArgumentList '/c','<đường dẫn tệp này>' -WindowStyle Hidden
rem REA_GHIDRA_STARTUP_TIMEOUT_MS phải lớn: lần nạp nguội Game.exe mất ~308 giây, mặc định của REA chỉ 330000.
set "GHIDRA_INSTALL_DIR=C:\Users\myhea\Desktop\ghidra\ghidra_12.1.4_PUBLIC"
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
set "REA_ANALYSIS_PROVIDER=ghidra"
set "REA_GHIDRA_STARTUP_TIMEOUT_MS=1800000"
set "REA_ROOT=D:/rea"
set "REA_WORK=D:/rea/work"
rem Node phải chạy từ thư mục REA để thấy node_modules của @modelcontextprotocol.
cd /d D:\rea
node "%~dp0rea_server.mjs"
