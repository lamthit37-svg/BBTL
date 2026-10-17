::==============================================================================
::  THIENLONG  |  TOOLS
::------------------------------------------------------------------------------
::  TỆP       : TOOLS/port/rea/start_server.cmd
::  PHÂN HỆ   : Port / Rea / Start Server
::  CHUẨN     : Batch
::------------------------------------------------------------------------------
::  CHỨC NĂNG
::  - Khởi động rea_server.mjs (giữ một phiên REA/Ghidra), chạy ẩn qua
::    Start-Process cmd.exe -ArgumentList '/c','<tệp này>' -WindowStyle Hidden.
::  - REA_GHIDRA_STARTUP_TIMEOUT_MS phải lớn: nạp nguội Game.exe ~308 giây.
::  - Ghidra ở đường dẫn ASCII C:\dev\ghidra; Desktop\ghidra không còn từ
::    2026-10-16, bản trong "CÔNG CỤ DỊCH NGƯỢC" có dấu và dấu cách.
::------------------------------------------------------------------------------
::  TÁC GIẢ   : HiepHoon
::  TELEGRAM  : @Hoon9xx
::==============================================================================
@echo off

set "GHIDRA_INSTALL_DIR=C:\dev\ghidra\ghidra_12.1.4_PUBLIC"
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"
set "REA_ANALYSIS_PROVIDER=ghidra"
set "REA_GHIDRA_STARTUP_TIMEOUT_MS=1800000"
set "REA_ROOT=D:/rea"
set "REA_WORK=D:/rea/work"
rem Node phải chạy từ thư mục REA để thấy node_modules của @modelcontextprotocol.
cd /d D:\rea
node "%~dp0rea_server.mjs"
