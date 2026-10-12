# Báo cáo vai B: `net`

Commit worktree: `0e6da48f366b0a1d58d55fe9f807adba2425b47a` (chưa commit thay đổi của đợt). Mốc Dev:
`G:\TLBB\Dev` @e0d89a6. Preset duy nhất đã dựng: `clang-asan` trong `build/p2-b`. Ổ F còn 156,0 GB
(167.495.618.560 byte, `so-do/b-t14-t15-t16.log`).

## Tệp và nguồn port

| Tệp | Dòng | Port từ Dev | Khác gốc |
|---|---|---|---|
| `SRC/net/net.hpp` | 228 | `src/platform/socket.hpp` (210 dòng) | `Endpoint` IPv4 thay cặp chuỗi host và cổng; `accept` trả kèm `Endpoint` bên kia (Dev bỏ ở `socket_win32.cpp:292`); chỉ nối hai bước, bỏ connect chặn và `getaddrinfo`; thêm `abort`, `local`, `nodelay`; bỏ hàm poll rời, chỉ giữ `PollSet` với nhãn 64 bit; lỗi là `NetError` trong `std::expected`; không lộ kiểu nào của hệ điều hành (`SocketHandle` là `enum class` trên `uintptr_t`). |
| `SRC/net/detail/native.hpp` | 35 | không có | Chuyển `Ipv4` qua lại số 32 bit thứ tự máy; khai `parse_ipv4`, mỗi nền tảng định nghĩa bằng `inet_pton`. |
| `SRC/net/net.cpp` | 81 | `src/platform/socket.cpp` (33 dòng) | `describe` tiếng Việt; `parse_endpoint` đọc `"a.b.c.d:port"`, cổng 1–65535, cổng 0 chỉ khi gọi với `ZeroPort::kAllow`, không phân giải tên. |
| `SRC/net/socket_win32.cpp` | 393 | `src/platform/socket_win32.cpp` (411 dòng) | `WSASocketW` với `WSA_FLAG_NO_HANDLE_INHERIT`; `TCP_NODELAY` bật ngay lúc tạo socket nối; `abort` bằng `SO_LINGER {1, 0}`; tập rỗng ngủ bằng `core::sleep_for`. |
| `SRC/net/socket_posix.cpp` | 402 | `src/platform/socket_posix.cpp` (485 dòng) | Cùng hợp đồng; `MSG_NOSIGNAL` hoặc `SO_NOSIGPIPE` tuỳ nền tảng; `FD_CLOEXEC`; `EINTR` của `poll` tính là hết hạn; cổng nghe đặt `SO_REUSEADDR`. **Chưa chạy.** |
| `tests/net_tests.cpp` | 468 | danh sách ca của `tests/platform/socket_test.cpp` (393 dòng) | Viết lại toàn bộ, không `sleep_for` hay quãng ngủ cố định: mọi chỗ chờ đi qua `PollSet::wait` có hạn. |

## Bẫy của Dev ứng với mã và ca test

| Bẫy (DE-BAI mục 2) | Dòng mã | Ca test |
|---|---|---|
| `WSAPoll` với 0 phần tử là lỗi | `socket_win32.cpp:382` (tập rỗng gọi `core::sleep_for`, không tới `WSAPoll` ở dòng 385); posix `:389` | `empty_poll_set_waits_out_limit` |
| `recv` trả 0 là bên kia đóng; không gọi `recv` với bộ đệm rỗng | `socket_win32.cpp:270` (sink rỗng trả 0 trước `recv`), `recv` 0 thành `kClosed`; posix `:273` | `receive_without_data_returns_zero`, `peer_shutdown_gives_closed` (`receive({})` trả 0, FIN là `kClosed`) |
| Socket vừa `accept` phải đặt lại không chặn và `TCP_NODELAY` | `socket_win32.cpp:322` | `streams_set_nodelay` (luồng accept), `accept_without_pending_returns_nothing` |
| Không đặt `SO_REUSEADDR` cho cổng nghe trên Windows | `socket_win32.cpp:301-307` (`open` chỉ bind và `listen(SOMAXCONN)`) | `listener_port_in_use_fails` (cổng đang dùng là `kBind`) |
| Đóng êm là gửi, `shutdown` chiều gửi, đọc tới khi bên kia đóng | `socket_win32.cpp:278-280` (`SD_SEND`); posix `:283` (`SHUT_WR`) | `peer_shutdown_gives_closed` (5 byte tới trước FIN, chiều kia vẫn gửi được 3 byte) |
| RST nuốt tin cuối | `socket_win32.cpp:283-286` (`abort` là đường RST có chủ ý) | `peer_abort_gives_reset` |
| Trễ khoảng 200 ms trên loopback (Nagle) | `socket_win32.cpp:238` và `:322` bật `TCP_NODELAY` | `streams_set_nodelay`; độ trễ **chưa đo** (không có tiêu chí đo trong DE-BAI cho B) |

## Ca test bắt buộc (DE-BAI mục 4 B)

| Yêu cầu | Ca |
|---|---|
| `accept` trả đúng địa chỉ và cổng bên nối | `accept_reports_peer`, `accepts_two_hundred` (200 cổng peer khớp 200 cổng client) |
| Nối tới cổng không ai nghe báo lỗi trong hạn | `connect_to_closed_port_fails` (hạn 10 giây) |
| Bên kia đóng là `kClosed`, huỷ là `kReset` | `peer_shutdown_gives_closed`, `peer_abort_gives_reset` |
| 8 MiB với bên nhận chậm, gửi trả 0 ít nhất một lần, băm khớp | `slow_reader_gets_eight_mib` (FNV-1a 64 bit, nhận từng mẩu 4 KiB) |
| 200 kết nối cùng lúc đều được nhận | `accepts_two_hundred` |
| `PollSet` thêm, bớt, bật tắt ghi | `poll_set_add_and_remove`, `poll_set_toggles_write` |
| Tập rỗng chờ hết hạn không lỗi | `empty_poll_set_waits_out_limit` |
| `Endpoint` đúng và sai | `endpoint_parses_valid` (5 chuỗi), `endpoint_rejects_invalid` (20 chuỗi: thiếu cổng, cổng 0, 65536, 99999, tên máy, IPv6, có `\0`…) |

Thêm: `describe_covers_every_error`, `listener_picks_port`, `connect_rejects_port_zero`. Tổng 18 ca.

## Lần chạy test đỏ

`so-do/b-net-do-truoc.log`, 2026-10-08 01:35:07, một lần chạy,
`ctest --test-dir build/p2-b -R '^net_tests$' --output-on-failure`. `socket_win32.cpp` lúc đó là bản
giả trả lỗi, `net.cpp` đã là bản thật: 16 ca đỏ, `endpoint_rejects_invalid` và
`describe_covers_every_error` qua; ctest `0% tests passed, 1 tests failed out of 1`.

## Xanh và chạy lặp

- `ctest --test-dir build/p2-b -R '^net_tests$' --output-on-failure`: 18/18 ca qua, ctest
  `100% tests passed out of 1`, 2,49 giây (một lần, 01:45).
- `ctest --test-dir build/p2-b -R '^net_tests$' --repeat until-fail:20 --output-on-failure`: 20 lần
  xanh, tổng 48,86 giây, mã thoát 0 (`so-do/b-lap-20.log`). Đây là tự kiểm trên `clang-asan`; T13
  chính thức trên `msvc-release` là việc của L.

## `check.py`

- `check.py -j 2` đủ bộ (clang-format, độ lồng, GCC 16.2.0, Clang 23.1.2, clang-tidy) trên
  `SRC/net/net.hpp`, `SRC/net/detail/native.hpp`, `SRC/net/net.cpp`, `SRC/net/socket_win32.cpp`,
  `tests/net_tests.cpp`: `5 tệp, 0 lỗi.`, mã thoát 0, 01:43:13–01:43:25 dưới `NANG.lock`
  (`so-do/b-check-day-du.log`, dòng lịch trong `build/lich-nang.tsv`).
- `check.py --no-tidy --only gcc` trên cùng 5 tệp: `5 tệp, 0 lỗi.`
- `socket_posix.cpp`: không đưa vào `check.py` vì không dịch được trên Windows; đã qua clang-format và
  T14.

## T14, T15, T16 (`so-do/b-t14-t15-t16.log`)

- T14: hai lệnh NDK `aarch64` và `x86_64-linux-android29-clang++ -std=c++23 -fsyntax-only -Wall
  -Wextra -Werror -I SRC SRC/net/socket_posix.cpp` đều thoát 0.
- T15: mẫu tìm giữ đúng như đề (`winsock2.h`, `ws2tcpip.h`, `sys/socket.h`, `poll.h`, `netinet/`,
  `arpa/`) trên mọi `.hpp` và `.cpp` của `SRC/` và `tests/`. Output nguyên văn:

  ```
  .\SRC\net\socket_posix.cpp:27: #include <arpa/inet.h>
  .\SRC\net\socket_posix.cpp:29: #include <netinet/in.h>
  .\SRC\net\socket_posix.cpp:30: #include <netinet/tcp.h>
  .\SRC\net\socket_posix.cpp:31: #include <poll.h>
  .\SRC\net\socket_posix.cpp:32: #include <sys/socket.h>
  .\SRC\net\socket_win32.cpp:29: #include <winsock2.h>
  .\SRC\net\socket_win32.cpp:30: #include <ws2tcpip.h>
  .\SRC\process\process_posix.cpp:32: #include <poll.h>
  ```

  Ngoại lệ theo chốt của L: `SRC/process/process_posix.cpp:32` là tệp có sẵn từ đợt 1, ngoài phạm vi
  sửa (DE-BAI mục 5), dùng `poll` cho ống của tiến trình con. Mọi trúng còn lại nằm trong hai tệp
  socket, nên T15 đạt.
- T16: tệp `.cpp` dài nhất của B là `tests/net_tests.cpp` 468 dòng; không tệp nào quá 500.
- `tests/net_tests.cpp` không gọi `sleep_for`, `Sleep(` hay `this_thread`; chỉ dòng 3 nhắc chữ
  `sleep_for` trong chú thích nguồn.

## Đã kiểm

- 18 ca xanh trên `clang-asan` (ASan bật), 20 lần lặp liên tiếp xanh.
- `check.py` đủ bộ 0 lỗi trên 5 tệp dựng được trên Windows.
- Cú pháp POSIX qua hai ABI của NDK.
- Mọi tệp UTF-8 không BOM, xuống dòng LF.
- Chỉ mở cổng trên `127.0.0.1`, cổng 0; không để tiến trình nào chạy sau test.

## Chưa kiểm

- `socket_posix.cpp` **chưa chạy**: máy không dựng được Linux, chỉ kiểm cú pháp.
- `gcc-debug` và `msvc-release` (T5, T13): theo mục 3.9 chỉ L và R dựng các cây này.
- Độ trễ loopback sau khi bật `TCP_NODELAY`: chưa đo.
- Hành vi khi hết cổng tạm hoặc hết handle với hơn 200 kết nối: chưa thử.

## Giả định

- Socket nhận từ `accept` trên Windows thừa hưởng cờ không kế thừa handle của socket nghe (tạo bằng
  `WSA_FLAG_NO_HANDLE_INHERIT`); chưa có test kiểm điều này.
- `send` một lần tối đa 1 MiB (`kMaxChunk`) để không tràn `int` của Winsock; bên gọi gửi tiếp phần
  còn lại.
- `PollSet::wait` báo `failed` cho `POLLERR`/`POLLNVAL` (`socket_win32.cpp:170`); `POLLHUP` tính là đọc được (dòng 168) để lần `receive` sau trả `kClosed` hoặc `kReset`; bên gọi tự bỏ luồng đó.
- Luồng đã đóng hoặc nối hỏng: `send` và `receive` trả `kReset`.

## Lệch quy tắc

- `shutdown_send` và `TcpListener::accept` không khai `const` dù clang-tidy gợi ý
  (`readability-make-member-function-const`): hai hàm đổi trạng thái socket của hệ điều hành; mỗi chỗ
  một dòng NOLINT nêu check và lý do, ở cả hai tệp nền tảng.
- `reinterpret_cast` cho `sockaddr` và con trỏ `char` của Winsock/POSIX, cùng các vararg `fcntl` ở
  POSIX: gom vào ít hàm nhất, mỗi chỗ một dòng NOLINT nêu check và lý do ("hợp đồng Winsock",
  "hợp đồng POSIX").
- `so-do/b-check-day-du.log`: lượt `check.py` đủ bộ đầu tiên (trước 01:43, mã thoát 1, `5 tệp, 3 lỗi` của clang-tidy ở `net.cpp`, `socket_win32.cpp`, `net_tests.cpp`) đã bị lượt 01:43:13 ghi đè cùng tên, trước khi L chốt luật không sửa log đã chạy. Log của lượt đầu không còn; các lỗi đó đã sửa như mô tả trong mục `check.py`. Từ giờ B chỉ ghi tệp log mới.
