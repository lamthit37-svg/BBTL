# Nguồn port P2 đợt 2

## Vai B: `net`

Mốc Dev: `G:\TLBB\Dev` @e0d89a6. POSIX đã port, máy này chưa chạy, chỉ kiểm cú pháp bằng NDK.

| Tệp dự án | Tệp Dev | Khác gốc |
|---|---|---|
| `SRC/net/net.hpp` | `src/platform/socket.hpp` | `Endpoint` IPv4; `accept` trả kèm địa chỉ bên kia; chỉ nối hai bước; thêm `abort`, `local`, `nodelay`; chỉ giữ `PollSet`; lỗi `NetError`. |
| `SRC/net/net.cpp`, `SRC/net/detail/native.hpp` | `src/platform/socket.cpp` | Đọc `Endpoint` từ chữ bằng `inet_pton`, không phân giải tên; cổng 0 chỉ khi cho phép. |
| `SRC/net/socket_win32.cpp` | `src/platform/socket_win32.cpp` | `WSA_FLAG_NO_HANDLE_INHERIT`; `TCP_NODELAY` từ lúc tạo; không `SO_REUSEADDR`; tập rỗng không gọi `WSAPoll`. |
| `SRC/net/socket_posix.cpp` | `src/platform/socket_posix.cpp` | Cùng hợp đồng; `MSG_NOSIGNAL`/`SO_NOSIGPIPE`; `FD_CLOEXEC`. Chưa chạy. |
| `tests/net_tests.cpp` | `tests/platform/socket_test.cpp` | Viết lại không `sleep_for`; chờ qua `PollSet::wait` có hạn. |

## Vai A: `protocol`

Mốc Dev: `G:\TLBB\Dev` @e0d89a6 (cùng mốc với vai B).

| Tệp dự án | Tệp Dev | Khác gốc |
|---|---|---|
| `SRC/protocol/wire.hpp`, `SRC/protocol/wire.cpp` | `src/protocol/wire.hpp`, `src/protocol/wire.cpp` | namespace `game::protocol`, lỗi kCamelCase; mỗi kiểu một hàm đọc trả giá trị thay `field(T&)`; có số có dấu; không có `require`, mã sinh gọi `fail(kOutOfRange)`; `count` thay `begin_list` và từ chối số phần tử vượt số byte còn lại; Writer sau lỗi không ghi thêm và báo `kBodyTooLarge` ở từng lần nối; UTF-8 kiểm trên byte bằng bảng byte đầu, cấm byte 0 |
| `SRC/protocol/channel.hpp`, `SRC/protocol/channel.cpp` | `src/net/connection.hpp`, `src/net/connection.cpp` | không phải template, nhận và trả khung thô; trần là tham số lúc tạo; hộp gửi từ chối trước khi thêm (Dev vượt được một khung); hộp nhận đầy làm kênh hỏng hẳn; `ChannelError` riêng bọc `WireError` |
| `tests/protocol_tests.cpp` | không có | viết mới; chỉ byte mẫu `Hello` lấy từ test của Dev (T9) |
