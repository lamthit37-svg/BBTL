# Nguồn port P2 đợt 1

Mốc Dev: `G:\TLBB\Dev` @e0d89a6. POSIX đã port, máy này không dựng được.

| Tệp dự án | Tệp Dev | Khác gốc |
|---|---|---|
| `SRC/process/process.hpp` | `src/platform/process.hpp`, `process_win32.cpp`, `process_posix.cpp`, `console.hpp`, `console.cpp` | Lỗi là `core::Result`. Đọc một dòng có hạn chờ và trần 4 KiB. Huỷ đối tượng thì buộc dừng rồi chờ. Câu hỏi dừng gồm stdin đóng, Ctrl+C, Ctrl+Break và đóng cửa sổ. Không gọi shell. |
| `SRC/process/process_win32.cpp`, `process_win32_read.cpp` | `src/platform/process_win32.cpp`, `console.cpp` | Job `KILL_ON_JOB_CLOSE`. Tạo treo rồi mới đưa vào job. Nhóm tiến trình riêng để Ctrl+C của cha không giết con. |
| `SRC/process/process_posix.cpp` | `src/platform/process_posix.cpp`, `console.cpp` | Cùng hợp đồng lỗi và trần dòng. Chưa dựng trên máy này. |
| `SRC/supervise/supervise.hpp`, `supervise.cpp` | `src/server/supervise.cpp` | Thuần trạng thái, không include `process`, không đọc đồng hồ. Thêm PostgreSQL, trần chạy lại mỗi giờ và nhiều tiến trình cùng loại. |

`SRC/config`, `SRC/service` và bảy `main.cpp` không có bản tương ứng ở Dev.
