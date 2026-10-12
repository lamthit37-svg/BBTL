| mã | đạt hay không | lệnh đã chạy | dòng output quyết định | tệp log |
|---|---|---|---|---|
| T1 | đạt | `python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"`; rồi `cd TOOLS\server && python -B -W error -m unittest -v test_gen_protocol`, trên mã cuối trong phiên 10:43:49 (`so-do/l-phien-cuoi.py`) | `Ran 249 tests` / `OK (skipped=8)`; `test_gen_protocol`: `Ran 29 tests` / `OK` | `so-do/l-t1-cuoi.log` (lượt trước bước 4: `l-t1.log`, 240 test) |
| T2 | đạt | `python -B -W error TOOLS/server/lint_py.py`, phiên 10:43:49 | `mã thoát: 0`, không in gì | `so-do/l-t2-cuoi.log` (trước: `l-t2.log`) |
| T3 | đạt | `gen_protocol.py --check`; `--out build/p2-l/do-cuoi/t3-a` và `t3-b` (qua `c-do.py t3()`), phiên 10:43:49 | `--check` thoát 0; `trùng cả ba: 4/4` (SHA-256 của t3-a, t3-b và tệp trong cây trùng nhau ở cả bốn tệp sinh) | `so-do/l-t3-cuoi.log` (trước: `l-t3.log`) |
| T4 | đạt | chép bảng sang `build/p2-l/do-cuoi/t4-catalog`, sửa `fields.tsv` dòng 6, `limit` 48 thành 49 (`CharacterSummary.name`), `--catalog … --check`, phiên 10:43:49 | `cũ: SRC/protocol/messages.hpp`, `cũ: tests/protocol_samples.hpp`, `cũ: docs/PROTOCOL-TIN.md`, `mã thoát: 1` | `so-do/l-t4-cuoi.log` (trước: `l-t4.log`) |
| T5 | đạt | ba preset trên mã cuối, phiên 10:43:49: `cmake --preset <p>`, `cmake --build --preset <p> --target all header_check`, `ctest --preset <p>` (`msvc-release` và `clang-asan` dựng trong `dev.bat`; ctest clang-asan không qua `dev.bat`, xem Lệch 2) | dựng: `exit=0` cả ba, 0 dòng `warning`. ctest: `100% tests passed out of 50` (clang-asan, 37.94 giây), `100% tests passed out of 50` (msvc-release), `100% tests passed out of 44` (gcc-debug). 50 = 43 nền + 7 mới; 44 = 37 nền + 7 mới (thứ bảy là `protocol_channel_tests` của A) | `so-do/l-cuoi-<preset>-{cau-hinh,dung,ctest}.txt` (lượt trước bước 4: `1b-*`) |
| T6 | đạt kèm lệch môi trường (L quyết lúc 10:35, V5 của R) | lần 3 trên mã cuối: `python -B ~/.claude/cpp23/tools/check.py <28 tệp .cpp/.hpp mới trong SRC/ và tests/, kể cả tệp sinh>` trong phiên 10:43:49 (`so-do/l-phien-cuoi.py`), có khoá. Đích NDK: clang-tidy `--target=aarch64-linux-android29` của B, 10:16:41 | Lần 3: `28 tệp, 3 lỗi.`, cả ba ở `SRC/net/socket_posix.cpp`, 27 tệp còn lại qua đủ năm bước. g14 và c20 báo `fatal error: arpa/inet.h` vì Windows không có header POSIX; clang-tidy trên Windows cũng không có header đó nên các cảnh báo nó in cho tệp này (include-cleaner, const-correctness, implicit-bool, easily-swappable, convert-to-static) không phải kết quả hợp lệ. Trên đích NDK, clang-tidy chạy thẳng ra 38 dòng ở `socket_posix.cpp`, cả 38 là `misc-include-cleaner` với header bionic, 0 loại khác. Cùng lượt NDK có thêm 3 lỗi ở header cũ ngoài danh sách T6: `SRC/core/clock.hpp:32` và `:46` (`bugprone-exception-escape`), `SRC/core/error.hpp:232` (`readability-qualified-auto`); module có sẵn mà đề cấm sửa, nên ghi là lệch có sẵn kèm log, không sửa (L, 10:39). Lần 1 (09:56, 27 tệp) cũng `3 lỗi` cùng tệp; lần 2 bị ngắt (Lệch 9) | `so-do/l-t6-lan3.log`, `so-do/l-t6.log`, `so-do/b-t6-xanh.log`, `so-do/b-t6-ndk.log`, `so-do/b-b4-check.log`, `so-do/b-b4-tidy-ndk.log` |
| T7 | đạt (theo log của A, L không chạy riêng) | bảng ở `BAO-CAO-A.md` mục 2; các ca nằm trong `protocol_tests`, xanh ở cả ba preset (T5) | đủ mười giá trị `WireError` ở chiều đọc và hai lỗi riêng của kênh, mỗi ô có tên ca | `BAO-CAO-A.md`, `so-do/1b-*-ctest.txt` |
| T8 | đạt (theo log của C) | ca `cắt ở mọi độ dài` và `thừa một byte` trong `protocol_catalog_tests` | 57 mẫu, 2.912 ca cắt và 57 ca thêm byte, 0 ca cắt giải mã thành công; ca xanh ở ba preset (T5) | `so-do/c-t8-mau.log`, `so-do/c-ctest.log`, `so-do/1b-*-ctest.txt` |
| T9 | đạt (theo log của A và C) | ca `dev_hello_sample` (protocol_tests) và `byte Hello của Dev` (protocol_catalog_tests); `test_dev_hello_bytes` (T1) | phiên bản 1, nền tảng 2, bản dựng `0x01020304`, mã hoá lại trùng 15 byte | `so-do/c-ctest.log`, `so-do/l-t1.log` |
| T10 | đạt | `protocol_fuzz_tests` trong ctest của T5 (mã cuối); `kRuns` đọc từ `tests/protocol_fuzz_tests.cpp` | `kRuns = 200'000` mỗi đích ở mọi preset; `Passed 25.64 sec` (clang-asan), `Passed 0.60 sec` (msvc-release), `Passed 1.98 sec` (gcc-debug) | `so-do/l-cuoi-<preset>-ctest.txt` (trước: `l-t10.log`) |
| T11 | đạt | `python -B TOOLS/server/fuzz_protocol.py --runs 1000000 --seed 20261008`, trên mã cuối, 10:48:30 tới 10:50:35, có khoá; corpus dùng lại từ lượt 02:30 | năm đích `runs 1000000`, cả năm `exit_code 0`; không có tệp crash, leak hay timeout (R đọc kiểm, REVIEW mục 5) | `so-do/l-cuoi-fuzz-tang-hai.log`, `so-do/fuzz-20261008-104830.tsv`, `so-do/fuzz-*-20261008-104830.log` (lượt 02:30: `fuzz.tsv`, `fuzz-*.log`) |
| T12 | đạt (của R) | `rang.py build` (10 harness), `run rang 1000000` (4 đích), `run goc 20000` (5 đích), 10:37:25 tới 10:38:00 | phán quyết ĐẠT ở `REVIEW.md` mục 5 | `so-do/r-rang-b4.log`, `REVIEW.md` |
| T13 | đạt | `ctest --test-dir build/msvc-release -R "^net_tests$" --repeat until-fail:20`, rồi cùng lệnh với `wire_loop_tests` (trong `dev.bat`), phiên 10:43:49 | `số dòng Passed: 20` và `100% tests passed out of 1` cho mỗi test | `so-do/l-t13-cuoi.log` (trước: `l-t13.log`) |
| T14 | đạt | hai lệnh NDK của mục 2 (`aarch64-` và `x86_64-linux-android29-clang++.cmd -std=c++23 -fsyntax-only -Wall -Wextra -Werror -I SRC`) trên `SRC/net/socket_posix.cpp`, phiên 10:43:49 | `mã thoát: 0` cả hai | `so-do/l-t14-lan3.log` (trước: `l-t14.log`, `l-t14-lan2.log`) |
| T15 | đạt theo quyết định của L | tìm `winsock2.h`, `ws2tcpip.h`, `sys/socket.h`, `poll.h`, `netinet/`, `arpa/` trong dòng `#include` của SRC/ và tests/, trên mã cuối 11:02 (`so-do/l-t15-t18-cuoi.py`) | 7 dòng ở `socket_posix.cpp` (27, 29–32) và `socket_win32.cpp` (29, 30); thêm `SRC/process/process_posix.cpp:32: #include <poll.h>` là ngoại lệ có từ đợt 1, L đã quyết giữ; `số dòng: 8` | `so-do/l-t15-cuoi.log` (trước: `l-t15.log`) |
| T16 | đạt | đếm byte xuống dòng (như `wc -l`) của 38 tệp `.cpp/.hpp/.py` viết tay mới, trên mã cuối 11:01 (`so-do/l-t16-t18-cuoi.py`) | `tệp .cpp hay .py quá 500 dòng: không có`; lớn nhất `496 tests/net_tests.cpp` | `so-do/l-t16-cuoi.log` (trước: `l-t16.log`, 36 tệp) |
| T17 | đạt (của R) | R rà độc lập từng làn, chỉ đọc | phán quyết ĐẠT ở `REVIEW.md` mục 5: 0 mục nặng, 0 mục vừa còn mở | `REVIEW.md` |
| T18 | đạt | `git status --short --untracked-files=all`; `git diff --numstat` hai tệp CMake; tìm tên hai tệp cấm và mẫu bí mật, trên mã cuối 11:01–11:02 | tệp mới chỉ ở SRC/protocol, SRC/net, TOOLS/server (mới), tests/, tests/fuzz, tests/bench, docs/PROTOCOL-TIN.md, docs/giao-viec/P2-DOT-2; tệp đã theo dõi bị đổi chỉ `CMakeLists.txt` (`44 0`) và `cmake/GameLayers.cmake` (`2 0`); `tên hai tệp cấm trong tệp mới: không có`; 15 dòng khớp mẫu bí mật, đều là gán trường `password`/`token` trong `messages.cpp` và `protocol_samples.hpp` (mã sinh và mẫu thử) | `so-do/l-t18-cuoi.log`, `so-do/l-t18-bi-mat-cuoi.log` (trước: `l-t18.log`, `l-t18-bi-mat.log`) |

| mã | đại lượng | lệnh | số lượt | trung vị | nhỏ nhất | lớn nhất | tệp log |
|---|---|---|---|---|---|---|---|
| Đ1 | mã hoá, tin mỗi giây (mã cuối) | `build/msvc-release/protocol_bench.exe` ×5, không ghim | 5 | 5929633 | 4930505 | 5979044 | `so-do/l-cuoi-lan3-d1-sach-vong1.log` |
| Đ1 | giải mã, tin mỗi giây (mã cuối) | như trên | 5 | 6260513 | 5142911 | 6447227 | `so-do/l-cuoi-lan3-d1-sach-vong1.log` |
| Đ2 | khứ hồi p50, µs (mã cuối) | `cmd /c start "" /b /wait /affinity FFF build\msvc-release\net_bench.exe` ×5 | 5 | 18.4 | 18.1 | 18.8 | `so-do/l-cuoi-lan3-d2-d3-moi-vong1.log` |
| Đ2 | khứ hồi p99, µs (mã cuối) | như trên | 5 | 32.1 | 27.7 | 35.6 | `so-do/l-cuoi-lan3-d2-d3-moi-vong1.log` |
| Đ2 | khứ hồi lớn nhất, µs. Cột không ngưỡng: lớn/nhỏ 9.238, log in "đo lại" nhưng không chấm (xem Điều kiện đo) | như trên | 5 | 316.1 | 285.4 | 2636.4 | `so-do/l-cuoi-lan3-d2-d3-moi-vong1.log` |
| Đ3 | MiB/giây theo cách đo mới: một mẻ khởi động, rồi lặp mẻ 2.000 khung thân 65.536 byte cho đủ ít nhất 1 giây, tính trên cả đoạn (mã cuối) | như trên | 5 | 3126.8 | 2875.0 | 3857.7 | `so-do/l-cuoi-lan3-d2-d3-moi-vong1.log` |
| Đ3 | số mẻ có tính giờ mỗi lượt (cột không ngưỡng) | như trên | 5 | 26 | 25 | 31 | `so-do/l-cuoi-lan3-d2-d3-moi-vong1.log` |
| Đ3 | MiB/giây của mẻ đầu có tính giờ, tức đúng định nghĩa gốc một mẻ 2.000 khung. Cột không ngưỡng: lớn/nhỏ 2.274, log in "đo lại" nhưng không chấm | như trên | 5 | 3786.2 | 2273.0 | 5169.7 | `so-do/l-cuoi-lan3-d2-d3-moi-vong1.log` |
| Đ3 | MiB/giây theo định nghĩa gốc: một mẻ 2.000 khung, không khởi động, không ghim nhân. **Không đạt luật 1,5** sau 6 vòng | `build/msvc-release/net_bench.exe` ×5 (bản trước 09:58, trước mã cuối) | 5 mỗi vòng, 6 vòng | vòng sạch 1: 1655.5 | 933.0 | 5087.7 | `so-do/l-d2-d3-sach-vong1..3.log`, `l-d2-d3-p-vong1..3.log`, `l-d2-d3-vong1..3.log` |
| Đ4 | `gen_protocol.py --check` cả tiến trình, giây (mã cuối) | `so-do/l-cuoi-d4.py` (dùng `d4_round` của `l-do.py` và kiểm tiến trình của `l-do-sach.py`; hàm `run` của `c-do.py`) | 5 | 0.0665 | 0.0639 | 0.0835 | `so-do/l-cuoi-d4-sach-vong1.log` (lượt 09:49: `l-d4-sach-vong1.log`) |
| Đ4 | `load_catalog` + `render_all` trong tiến trình, giây (mã cuối) | hàm `one_render` của `c-do.py` | 5 | 0.0049 | 0.0047 | 0.0053 | `so-do/l-cuoi-d4-sach-vong1.log` |
| Đ4 | đỉnh bộ nhớ Python của phần trên, MiB (mã cuối) | `tracemalloc` | 5 | 0.5373 | 0.5370 | 0.6099 | `so-do/l-cuoi-d4-sach-vong1.log` |
| Đ5 | vòng mỗi giây: frame / game_client / game_server / auth_client / auth_server (mã cuối) | lấy từ T11, lượt 10:48:30 | 1 | 10971 / 240466 / 149572 / 226726 / 356230 | | | `so-do/fuzz-20261008-104830.tsv` |
| Đ6 | số dòng từng tệp viết tay và tệp sinh; số ca test; dòng bảng tin; số mẫu (mã cuối) | đếm byte xuống dòng; đếm `Case{.name` và `def test_`; đếm dòng dữ liệu bảng và `Frame{` (`so-do/l-cuoi-d6.py`) | 1 | xem mục "Đ6" | | | `so-do/l-cuoi-d6.log` (lượt 09:52: `l-d6.log`, `l-d6-bo-sung.log`) |

Điều kiện đo: commit `0e6da48f366b0a1d58d55fe9f807adba2425b47a` (cây có thay đổi chưa commit, xem T18), preset `msvc-release` dựng trên mã cuối trong phiên 10:43:49, CPU Intel Core i5-14600KF (14 nhân, 20 luồng logic, `so-do/l-may.log`).

- Đ1, Đ2, Đ3 lấy từ phiên khoá riêng 10:56:47 tới 10:58:32 (`so-do/l-phien-cuoi-do3.py`), trên mã cuối (không tệp mã nào đổi sau 10:43:49). Cả hai phép đạt ngay vòng 1, không bỏ lượt nào.
  - Trong suốt mỗi vòng, psutil lấy mẫu tiến trình mỗi 0,1 giây: `tiến trình khác của dự án hay trình dựng trong vòng (psutil, mỗi 0,1 giây): không có` ở cả hai log.
  - Log Đ2/Đ3 có dòng `tiến trình nền lúc bắt đầu: code.exe ×17, clangd.exe ×5, python.exe ×11, blender.exe ×0`. Log Đ1 không có dòng liệt kê đó (xem Lệch 13).
  - Lead kiểm lúc 10:58:51: không còn `cl`, `cc1plus`, `ninja`, `clang` hay `link` nào.
- Đ4 đo lại trên mã cuối ở phiên khoá 11:21:27 (`so-do/l-cuoi-d4.py`), đạt vòng 1: lớn/nhỏ 1.306 (A), 1.134 (B), 1.136 (C), mã thoát của A đều 0. Log ghi tiến trình nặng lúc bắt đầu vòng: chỉ có `gcc.exe`, là GIGABYTE Control Center (psutil thấy đường dẫn `/GIGABYTE/` nên bỏ qua, xem Giả định); psutil suốt vòng: `không có`. Lượt 09:49 (`l-d4-sach-vong1.log`) giữ làm lịch sử vì `TOOLS/server/protocol_*.py` đổi lúc 10:21. Đ5 lấy từ T11 trên mã cuối. Đ6 đếm lại trên mã cuối lúc 11:21:56 (`so-do/l-cuoi-d6.log`).
- Ghim nhân:
  - Đ1 và Đ4 không ghim.
  - Đ2 và Đ3 ghim cố định vào luồng logic 0 tới 11 (sáu nhân P), bằng đúng lệnh `cmd /c start "" /b /wait /affinity FFF build\msvc-release\net_bench.exe` chạy từ gốc worktree, 5 lần.
- Luật 1,5 (L quyết lúc 10:03) áp lên đại lượng chính: Đ1 mã hoá và giải mã, Đ2 p50 và p99, Đ3 MiB/giây cả đoạn. Tỉ số lớn/nhỏ trên mã cuối: 1.213, 1.254, 1.039, 1.285, 1.342, cả năm đạt. R đối chiếu với dòng tsv và xác nhận (REVIEW mục 5).
- Ba cột không ngưỡng vẫn ghi đủ, kèm tỉ số, không đo lại, không bỏ lượt (L, 11:00). Log tự in "quá 1,5: đo lại" ở hai cột, nhưng đó không phải trượt:
  - Đ2 lớn nhất: 285.4 tới 2636.4 µs, tỉ số 9.238. Đây là một mẫu đuôi đơn lẻ, đề không đặt ngưỡng.
  - Đ3 MiB/giây mẻ đầu: 2273.0 tới 5169.7, tỉ số 2.274. Đây là số của một mẻ duy nhất, chỉ để đối chiếu với định nghĩa gốc.
  - Đ3 số mẻ: 25 tới 31, tỉ số 1.240.
- Số đo trước mã cuối (`l-d1-sach-vong1.log`: Đ1 5916680 và 6388248; `l-d2-d3-moi-vong1.log`: Đ2 p50 18.4, p99 33.3, Đ3 2880.8) giữ làm đối chiếu, không dùng làm số chính.
- Hai lượt đo trong và ngay sau phiên cuối (`l-cuoi-d*`, `l-cuoi-lan2-d*`) bị bản dựng ngoài nhóm chen vào, không dùng (Lệch 11).

## Đ3

### Theo định nghĩa gốc của đề

Một mẻ 2.000 khung thân 65.536 byte, không chạy khởi động, không ghim nhân. Chưa đạt luật 1,5. Đã đo sáu vòng, mỗi vòng 5 lượt, không bỏ lượt nào:

- Ba vòng không ghim nhân, chồng với ctest lặp của R (`l-d2-d3-vong1..3.log`): lớn/nhỏ là 6.699, 3.735, 1.804.
- Ba vòng ghim 12 luồng logic 0..11 (`l-d2-d3-p-vong1..3.log`): lớn/nhỏ là 3.791, 3.478, 2.546.
- Ba vòng sạch (`l-d2-d3-sach-vong1..3.log`): lớn/nhỏ là 5.453, 4.178, 2.680. Trung vị từng vòng là 1655.5, 1968.8, 3246.8 MiB/giây.

Nguyên nhân L thấy được: 2.000 khung thân 65.536 byte chỉ là 128 MiB, nên mỗi lượt chỉ chạy vài chục mili giây. Thời gian ngắn như vậy làm lịch của Windows quyết định kết quả.

### Theo cách đo mới (L quyết lúc 09:58)

- `net_bench` chạy một mẻ khởi động không tính giờ. Sau đó nó lặp mẻ, mỗi mẻ đúng 2.000 khung thân 65.536 byte, tới khi tổng giờ các mẻ đạt ít nhất 1 giây.
- Giờ của một mẻ tính từ lúc bắt đầu gửi tới lúc bên nhận có đủ khung cuối.
- Dòng TSV in ba số: MiB/giây của cả đoạn, số mẻ, và MiB/giây của mẻ đầu có tính giờ.
- Lệnh và cách ghim nằm ở phần "Điều kiện đo".
- `check.py` trên `tests/bench/net_bench.cpp`:
  - `l-check-bench-d3-moi.log`: lỗi clang-format.
  - `l-check-bench-d3-moi-lan2.log`: sau `clang-format -i`, NOLINTNEXTLINE không còn đúng dòng `fprintf` nữa.
  - `l-check-bench-d3-moi-lan3.log`: đổi sang NOLINTBEGIN/NOLINTEND, kết quả `1 tệp, 0 lỗi.`
- Dựng lại có khoá: `l-d23-dung.txt`, mã thoát 0, 0 dòng `warning`.
- Vòng 1 (`l-d2-d3-moi-vong1.log`): cả đoạn ra trung vị 2880.8 MiB/giây, tỉ số lớn/nhỏ 1.332, đạt.
  - Cùng các lượt đó, MiB/giây của mẻ đầu có tỉ số 3.508. Điều này xác nhận lệch nằm ở độ dài của một mẻ.
- Trên mã cuối (`l-cuoi-lan3-d2-d3-moi-vong1.log`, 10:56:57): cả đoạn ra trung vị 3126.8 MiB/giây, tỉ số 1.342, đạt. Mẻ đầu có tỉ số 2.274 (cột không ngưỡng).

## Đ6

Đếm lại trên mã cuối lúc 11:21:56 (`so-do/l-cuoi-d6.log`, script `so-do/l-cuoi-d6.py`), cùng cách đếm với lượt 09:52.

- Số dòng: 38 tệp viết tay mới, tổng 7482 dòng; lớn nhất `496 tests/net_tests.cpp`, `431 SRC/net/socket_posix.cpp`, `425 tests/protocol_tests.cpp`. Tệp sinh: `533 SRC/protocol/messages.cpp`, `351 SRC/protocol/messages.hpp`, `1850 tests/protocol_samples.hpp`, `336 docs/PROTOCOL-TIN.md`.
- Ca test C++ (đếm `Case{.name`): `net_tests` 20, `protocol_catalog_tests` 9, `protocol_channel_tests` 10, `protocol_fuzz_tests` 13, `protocol_tests` 17, `wire_loop_tests` 4; tổng 73.
- Test Python (đếm `def test_`): `test_gen_protocol.py` 29, `test_fuzz_protocol.py` 4.
- Bảng tin (dòng dữ liệu, bỏ dòng chú thích `#` và một dòng tiêu đề): `groups.tsv` 3, `messages.tsv` 20 (19 tin và 1 record), `fields.tsv` 38, `enums.tsv` 46. Lượt 09:52 ra 4, 21, 39, 47 vì tính cả dòng tiêu đề.
- Mẫu: `tests/protocol_samples.hpp` có 57 `Frame{`.
- Lượt 09:52 (`l-d6.log`, `l-d6-bo-sung.log`, `c-dem-tin.log`) giữ làm lịch sử: khi đó chưa có `protocol_channel_tests`, `test_fuzz_protocol.py` và các ca mới của bước 4.

## L: dòng thêm vào hai tệp CMake

`CMakeLists.txt` thêm 44 dòng, bớt 0 (43 ở đợt đầu, cộng dòng `game_test(protocol_channel game_protocol)` ở bước 4); `cmake/GameLayers.cmake` thêm 2 dòng, bớt 0 (`l-t18-cuoi.log`).

- `GameLayers.cmake`: `set(game_layer_protocol "core protocol")`, `set(game_layer_net "core net")`.
- `CMakeLists.txt`, sau dòng 289:
  - Khối `if(NOT CMAKE_CROSSCOMPILING)` khai `game_module(protocol …wire.cpp …channel.cpp …messages.cpp)`.
  - Khai `game_module(net SRC/net/net.cpp SRC/net/socket_win32.cpp|socket_posix.cpp)` theo `WIN32`; trên Windows link thêm `ws2_32`.
  - Danh sách tệp ghi tường minh, thay cho glob.
- Sau dòng 837: lọc `SRC/(protocol|net)/` khỏi `game_headers` khi không có `game_net`.
- Sau dòng 993:
  - Năm `game_test`: protocol, protocol_catalog, protocol_fuzz, net, wire_loop; thêm `protocol_channel` ở `CMakeLists.txt:1019` (bước 4, theo A).
  - Hai exe đo `protocol_bench` và `net_bench`, không vào ctest.
  - Test `protocol_catalog_fresh`.

## L: lịch lệnh nặng

Chép nguyên các dòng của `build/lich-nang.tsv` (bắt đầu, xong, vai, lệnh). Các dòng của L:

```
2026-10-08 00:51:47	2026-10-08 00:51:55	L	ctest --preset clang-asan (moc)
2026-10-08 00:56:59	2026-10-08 00:57:56	L	dung + ctest ba preset ... (buoc 0, gcc-debug chay lai ctest vi log_tests 0xC0000374)
2026-10-08 02:18:24	2026-10-08 02:18:55	L	check.py đủ bộ 7 tệp fuzz (lần 1)
2026-10-08 02:20:39	2026-10-08 02:20:53	L	check.py đủ bộ 9 tệp fuzz, bench (lần 2)
2026-10-08 02:21:28	2026-10-08 02:28:07	L	fuzz_protocol.py chạy thử --runs 2000: lệnh bị ngắt ...; trả khoá
2026-10-08 02:28:19	2026-10-08 02:28:22	L	fuzz_protocol.py chạy thử --runs 2000
2026-10-08 02:28:36	2026-10-08 02:28:57	L	fuzz_protocol.py chạy thử --runs 2000 (lần 2, thêm define Windows)
2026-10-08 02:29:11	2026-10-08 02:30:39	L	fuzz_protocol.py --runs 1000000 --seed 20261008 (fuzz tầng hai)
2026-10-08 09:41:46	2026-10-08 09:42:20	L	dựng preset clang-asan (cấu hình, dựng all và header_check, ctest)
2026-10-08 09:42:20	2026-10-08 09:42:41	L	dựng preset msvc-release (...)
2026-10-08 09:42:41	2026-10-08 09:43:05	L	dựng preset gcc-debug (...)
2026-10-08 09:45:06	2026-10-08 09:45:35	L	ctest --preset clang-asan lượt 2, không qua dev.bat
2026-10-08 09:45:45	2026-10-08 09:46:00	L	đo Đ1 tới Đ4 trên msvc-release (so-do/l-do.py)
2026-10-08 09:47:15	2026-10-08 09:47:18	L	đo lại Đ2, Đ3 ghim nhân P (so-do/l-do-ghim.py)
2026-10-08 09:49:40	2026-10-08 09:49:54	L	đo lại Đ1 tới Đ4, có kiểm tiến trình (so-do/l-do-sach.py)
2026-10-08 09:52:05	2026-10-08 09:52:56	L	T1 tới T18 trừ T12, T17, kèm ctest lặp 20 lần (so-do/l-t.py)
2026-10-08 09:56:01	2026-10-08 09:56:22	L	T6 check.py đủ bộ trên mọi tệp C++ mới, kèm T14 (so-do/l-t6.py)
2026-10-08 10:01:29	2026-10-08 10:01:38	L	dựng msvc-release và đo lại Đ2, Đ3 theo mẻ, ghim FFF (so-do/l-do-d23.py)
2026-10-08 10:10:49	2026-10-08 10:15:30	L	T6 lượt 2 (so-do/l-t6-lan2.py) chạy tiền cảnh bị ngắt ở bước T14, chưa ghi log nào; đã kiểm không còn tiến trình, trả khoá
2026-10-08 10:15:30	2026-10-08 10:15:31	L	T6 lượt 2 check.py đủ bộ trên mọi tệp C++ mới, kèm T14 (so-do/l-t6-lan2.py)
2026-10-08 10:16:26	2026-10-08 10:16:26	L	đính chính dòng 10:10:49 của L: lượt đó đã ghi so-do/l-t14-lan2.log (10:10:50) rồi treo ở bước T6, chưa ghi l-t6-lan2.log; lần chạy lại 10:15:30 dừng ngay vì l-t14-lan2.log đã có, không chạy gì. T6 sẽ chạy lại ở lượt 3 sau mốc 11:00
2026-10-08 10:17:50	2026-10-08 10:39:00	L	nhẹ: Build & Test xong bước 4 (V3, V4, V6, V7, X-BA-03, N11; log l-v3-*, l-v6-*, l-v7-sleep, l-xba03-*, l-check-wire-loop-v6*, l-check-xba03, l-check-targets-nguon*, l-t1-t2-sau-v3; không giữ NANG.lock)
2026-10-08 10:43:49	2026-10-08 10:51:24	L	phiên cuối trên mã cuối (so-do/l-phien-cuoi.py): ba preset cấu hình, dựng all + header_check, ctest; T1-T4; T14, T6 lần 3; ctest net_tests và wire_loop_tests lặp 20; fuzz tầng hai 1.000.000 (fuzz-*-20261008-104830); Đ1-Đ3 3 vòng không đạt vì có bản dựng ngoài nhóm chạy cùng (l-cuoi-*)
2026-10-08 10:52:16	2026-10-08 10:52:59	L	đo lại Đ1-Đ3 (so-do/l-phien-cuoi-do2.py) bị ngắt khi đang ở vòng đầu, chưa ghi log nào, không còn tiến trình
2026-10-08 10:53:26	2026-10-08 10:54:39	L	đo lại Đ1-Đ3 (so-do/l-phien-cuoi-do2.py): 3 vòng mỗi phép không đạt, cây chính đang dựng msvc-release và gcc (cl, cc1plus, ninja) cùng lúc (l-cuoi-lan2-*); trả khoá 2026-10-08 10:55:16
2026-10-08 10:56:47	2026-10-08 10:58:32	L (Build & Test)	python -B -X utf8 docs/giao-viec/P2-DOT-2/so-do/l-phien-cuoi-do3.py (đo Đ1-Đ3 lần 3 trên mã cuối, đạt vòng 1)
2026-10-08 11:21:27	2026-10-08 11:22:38	L (Build & Test)	đo lại Đ4 trên mã cuối, đạt vòng 1 (so-do/l-cuoi-d4.py, l-cuoi-d4-sach-vong1.log); đếm Đ6 trên mã cuối (so-do/l-cuoi-d6.py, l-cuoi-d6.log, nhẹ)
```

Dòng 02:29:11 trong tệp gốc là mojibake (`táº§ng`), vì được ghi trước khi chuyển sang UTF-8. Dòng đó để nguyên; ở trên L chép lại theo nghĩa. Các dòng trước 01:43 không dấu.

## L: output nguyên văn của T11

```
# 2026-10-08 02:29:11 -> 2026-10-08 02:30:39 fuzz tầng hai, giữ NANG.lock, không có bản dựng nào khác đang chạy
> python -B TOOLS/server/fuzz_protocol.py --runs 1000000 --seed 20261008
target	runs	seconds	runs_per_s	cov	ft	corpus_files	exit_code
frame	1000000	51.49	19419	83	390	134	0
game_client	1000000	4.52	221375	231	390	110	0
game_server	1000000	9.70	103095	269	580	118	0
auth_client	1000000	3.81	262419	179	321	102	0
auth_server	1000000	2.82	354098	123	146	69	0
exit 0
```

Dòng `Done` của từng đích: `Done 1000000 runs in 51 second(s)` (frame), `4` (game_client), `9` (game_server), `3` (auth_client), `2` (auth_server) (`so-do/fuzz-*.log`).

## L: lần chạy test đỏ

- Fuzz tầng một: `l-fuzz-mutator-do-truoc.log`, `l-fuzz-dich-do-truoc.log` (đỏ trước khi viết), rồi `l-fuzz-xanh.log`: 12 ca, 5 đích × 200.000 lượt, clang-asan, 23.59 giây.
- `wire_loop_tests`: `l-wire-loop-do.log` lúc 09:12:28, chạy với bản chép phá hỏng của `channel.cpp` trong `build/p2-l/red/`. Bản chép đó bỏ byte cuối của mảnh 7 byte, và `next()` trả rỗng khi view không quá 8 byte.
  - Kết quả: `pieces_of_7_bytes` hỏng 3 phép kiểm, `oversized_body_fails_after_header` hỏng 1, exe thoát -1073740791.
  - `pieces_of_1_byte` và `pieces_of_4096_bytes` vẫn xanh với bản chép đó.
  - Bản thật: `l-wire-loop-xanh.log`.

## L: output check.py

- `l-check-day-du.log` (3 tệp chuẩn bị). `l-check-fuzz-lan1.log` có lỗi; `l-check-fuzz.log` 0 lỗi.
- `l-check-wire-loop.log`: lượt 1 có 1 lỗi `misc-include-cleaner` (thiếu `<expected>`), lượt 2 0 lỗi.
- Bench: `l-check-bench.log` 3 lỗi, `l-check-bench-lan2.log` 2 lỗi (`bugprone-exception-escape`), `l-check-bench-lan3.log` `2 tệp, 0 lỗi.`
- `net_bench.cpp` sau khi đổi Đ3: `l-check-bench-d3-moi.log` 1 lỗi, `-lan2` 1 lỗi, `-lan3` `1 tệp, 0 lỗi.` (xem mục Đ3).
- T6 trên mọi tệp mới (`l-t6.log`): `27 tệp, 3 lỗi.`, cả ba ở `socket_posix.cpp` (xem bảng).

## L: bước 4 (sửa theo REVIEW, lead giao lúc 10:15)

Mỗi mục có lượt đỏ trước, lượt xanh sau, log mới trong `so-do/`, không sửa log cũ.

- V3, `TOOLS/server/fuzz_protocol.py` không ghi đè log lượt trước:
  - Log mỗi đích là `fuzz-<đích>-<giờ>.log`, bảng là `fuzz-<giờ>.tsv`, `<giờ>` là lúc bắt đầu lượt. Tệp mở chế độ `"x"`; tên đã có thì dừng trước khi dựng. Lượt 02:30 của T11 giữ tên cũ.
  - Test mới `TOOLS/server/test_fuzz_protocol.py`, 4 ca.
  - Đỏ, mã chưa sửa: `FAILED (failures=1, errors=2)` (`so-do/l-v3-do.log`, 10:17:50).
  - Xanh: `Ran 4 tests`, `OK`; `lint_py.py` hai tệp mã thoát 0 (`so-do/l-v3-xanh.log`, 10:18:10).
  - T1, T2 chạy lại: `Ran 249 tests`, `OK (skipped=8)`; `lint_py.py` mã thoát 0 (`so-do/l-t1-t2-sau-v3.log`, 10:25:08).
- V4: ghi ở mục Lệch quy tắc 1.
- V6, `tests/wire_loop_tests.cpp`:
  - Sau mỗi lần receive, số khung đã lấy phải bằng số khung đã đủ byte (tính từ độ dài thân khai ở đầu từng khung). Dòng byte kết thúc bằng `Logout` thân rỗng; khung cuối phải là `Logout` với thân rỗng.
  - Đột biến (bản chép `channel.cpp` ở `build/p2-l/red2`): `next()` thêm `if (view.size() <= kHeaderBytes) return std::nullopt;`, tức giữ khung khi có đúng 8 byte.
  - Test trước V6 với đột biến: ba ca `pieces_of_*` vẫn xanh, chỉ ca khung quá trần đỏ (`so-do/l-v6-cu-voi-dot-bien.log`).
  - Test mới với đột biến: đỏ ở cả ba ca `pieces_of_*` (`nhận đủ khung của mọi mẫu và Logout cuối`, `sau mỗi lần nhận, kênh trả ngay mọi khung đã đủ byte`) và ở ca khung quá trần (`so-do/l-v6-do.log`; sau clang-format `so-do/l-v6-do-lan2.log`).
  - Mã thật, clang-asan: `exit=0` (`so-do/l-v6-xanh.log`; sau clang-format `so-do/l-v6-xanh-lan2.log`).
  - check.py: lần 1 có 1 lỗi clang-format (`so-do/l-check-wire-loop-v6.log`); sửa bằng `clang-format -i`, lần 2 `1 tệp, 0 lỗi.` (`so-do/l-check-wire-loop-v6-lan2.log`). Tệp còn 306 dòng.
  - Script: `so-do/l-v6.py`.
- V7: chú thích đầu tệp `wire_loop_tests.cpp` viết lại; tìm chữ `sleep` ra 0 dòng (`so-do/l-v7-sleep.log`).
- X-BA-03, `tests/fuzz/targets.hpp`:
  - `feed` đưa mỗi mẩu không quá `inbox_room()` (như chú thích `receive` của A đòi; chỗ trống bằng 0 vẫn đưa 1 byte), `give` coi mọi `kInboxFull` là `kBroken`, lỗi nhận khác là từ chối đúng cách.
  - Ca cố định mới `frame_target_reads_by_inbox_room` trong `tests/protocol_fuzz_tests.cpp`: đúng đầu vào R nêu, khung thân 4.096 byte rồi khung thân rỗng, 4.112 byte, mẩu 5 byte, trần client.
  - Đột biến (bản chép `channel.cpp` ở `build/p2-l/red3`): `receive` so `>=` thay `>` với `inbox_room()`, báo đầy oan khi mẩu vừa khít.
  - `targets.hpp` trước sửa với đột biến: xanh hết, `exit=0` (`so-do/l-xba03-cu-voi-dot-bien.log`).
  - `targets.hpp` mới với đột biến: đỏ ở `frame_target_reads_by_inbox_room` (`so-do/l-xba03-do.log`). Fuzz ngẫu nhiên 200.000 lượt của đích `frame` không gặp đột biến này; chỉ ca cố định bắt được.
  - Mã thật, clang-asan: `exit=0`, 17.684 ms (`so-do/l-xba03-xanh.log`).
  - check.py hai tệp: `2 tệp, 0 lỗi.` (`so-do/l-check-xba03.log`). Script: `so-do/l-xba03.py`.
- N11: thêm mục Vai L vào `NGUON.md` (`tests/fuzz/mutator.hpp`, `tests/fuzz/targets.hpp`). Chú thích nguồn ở `targets.hpp` sửa đường dẫn Dev thành `tests\protocol\protocol_fuzz_test.cpp`; check.py lần 1 lỗi clang-format vì dòng dài (`so-do/l-check-targets-nguon.log`), lần 2 `1 tệp, 0 lỗi.` (`so-do/l-check-targets-nguon-lan2.log`).
- CMake: theo A, thêm `    game_test(protocol_channel game_protocol)` ở `CMakeLists.txt:1019`, sau khi kiểm `tests/protocol_channel_tests.cpp` đã có. `git diff --numstat` của `CMakeLists.txt`: 44 dòng thêm, 0 dòng bớt.
- Trên mã cuối: phiên khoá 10:43:49 tới 10:51:24 (`so-do/l-phien-cuoi.py`) dựng ba preset với ctest đủ bộ, chạy T1 tới T4, T6 lần 3, T13, T14 và fuzz tầng hai mới cho T11 và Đ5; Đ1 tới Đ3 đo lại ở phiên 10:56:47 (`so-do/l-phien-cuoi-do3.py`). Kết quả ở bảng trên.

## L: Đã kiểm

- Các mã T và Đ ghi "đạt" ở bảng trên, với đúng lệnh và log đã ghi.
- Bốn SHA-256 tệp sinh trùng giữa hai lần `--out` và tệp trong cây trên mã cuối (T3, `l-t3-cuoi.log`). Fuzz tầng hai chạy lại trên mã cuối (T11).
- Ba preset dựng không cảnh báo trên mã cuối; số test đúng 43 + 7 / 37 + 7.

## L: Chưa kiểm

- T6 trên `socket_posix.cpp`: không dịch được trên Windows, nên g14, c20 và clang-tidy không có kết quả hợp lệ trên tệp này. T14 chỉ kiểm cú pháp.
- Đ3 theo định nghĩa gốc: không có vòng nào đạt luật 1,5.
- T7, T8, T9: L không chạy riêng, chỉ dựa vào log của A và C cùng ctest xanh của T5.
- Bản POSIX của net chưa chạy, chỉ kiểm cú pháp (T14).

## L: Giả định

- `GCC.exe` ở `C:\Program Files\GIGABYTE\Control Center` là GIGABYTE Control Center, không phải trình dịch. `l-do-sach.py` bỏ qua nó khi kiểm tiến trình.
- Không đọc hai tệp cấm. Phần "tìm bí mật" của T18 chỉ tìm tên hai tệp và mẫu `password|token|secret|api key` gán giá trị.

## L: Lệch quy tắc và sự cố

1. Log đã sửa sau khi chạy:
   - Dòng đầu của `so-do/l-fuzz-tang-hai.log` được ghi lại sang UTF-8 lúc 09:12:38 (giờ sửa của tệp), sau lượt chạy 02:29:11 tới 02:30:39. Chỉ đổi mã hoá của dòng đó, nội dung giữ nguyên. Lead chấp nhận lệch này (V4 của R, 10:15); bằng chứng chính của T11 là `so-do/fuzz.tsv` và năm `so-do/fuzz-*.log` có giờ sửa 02:30, không ai đụng tới sau lượt chạy.
   - Lúc 09:13 (trước quy định 09:20) L nối thêm lượt 2 vào `l-wire-loop-xanh.log` và `l-check-wire-loop.log`.
   - Từ 09:20, mọi lượt mới đều ghi ra tệp mới.
2. ctest clang-asan lượt 1 (`1b-clang-asan-ctest.txt`) hỏng 41/49 test, mã `0xc0000139`.
   - Nguyên nhân: `dev.bat` đưa `clang_rt.asan_dynamic-x86_64.dll` của MSVC 14.51 lên trước bản của LLVM 23 trong PATH. Kiểm trên `fx_tests.exe`: qua `dev.bat` thoát -1073741511, không qua `dev.bat` thoát 0.
   - Lượt 2 không qua `dev.bat`: 49/49 (`1b-clang-asan-ctest-lan2.txt`). Lượt 1 giữ nguyên.
   - Việc `dev.bat` chọn sai DLL cho clang-asan là chuyện ngoài phạm vi, L không sửa.
3. Đo chồng với test của vai khác:
   - Lệnh `ctest net_tests --repeat until-fail:20` của R (build/p2-r, 09:45:11 tới 09:46:01, không lấy khoá) chạy chồng lên `l-d1-vong1`, `l-d2-d3-vong1..3`, `l-d4-vong1`, và cả ctest clang-asan lượt 2 của L (09:45:06 tới 09:45:35).
   - Dòng đầu các log đo đó ghi "không có bản dựng nào khác đang chạy". Câu đó đúng về dựng, nhưng lúc đó có test khác chạy. Các log được giữ nguyên.
   - Số trong bảng lấy từ các vòng `*-sach-*`, đo lại khi đã có kiểm tiến trình.
4. Lượt 1 của `l-do.py` đặt ngưỡng 1,5 cho p50, p99 và MiB/giây, không đặt cho "khứ hồi lớn nhất". Cột đó là một mẫu đơn lẻ nên dao động mạnh: trong vòng sạch 1 là 333.4 tới 2190.3.
4a. Đổi cách đo Đ3, theo quyết định của L lúc 09:58:
   - Định nghĩa gốc là một mẻ 2.000 khung. Cách mới thêm một mẻ khởi động, rồi lặp mẻ cho đủ ít nhất 1 giây, và ghim cố định luồng logic 0 tới 11.
   - Sáu vòng theo cách cũ giữ nguyên trong `so-do/`. Bảng ghi cả hai cách.
   - `net_bench.cpp` thêm `struct Stream`, `stream_batch` và `kMinStreamSeconds`. Dòng TSV thêm hai cột, từ 5 thành 7.
4b. Đo lại Đ2:
   - Các vòng trước có vòng vượt 1,5: vòng sạch 2 có p99 lớn/nhỏ 1.516, các vòng sạch còn lại hỏng vì cột MiB/giây của Đ3 chung dòng.
   - Đ2 được đo lại trong cùng phiên khoá với Đ3 mới, cùng lệnh ghim. Số trong bảng lấy từ `l-d2-d3-moi-vong1.log`. Không bỏ lượt nào.
5. Hai exe đo:
   - `std::println` đổi thành `fprintf` (lệch STD-04), kèm `NOLINTNEXTLINE(modernize-use-std-print,cppcoreguidelines-pro-type-vararg)`, chuỗi định dạng ASCII.
   - `main` có `NOLINTNEXTLINE(bugprone-exception-escape)`, lý do ghi theo HP-07.
6. Libfuzzer trên Windows cần thêm define (02:28:36). Lượt chạy thử 02:21:28 bị ngắt giữa chừng. L đã kiểm không còn exe hay tiến trình nào rồi mới trả khoá, và ghi lại trong `lich-nang.tsv`.
7. Fuzz tầng một trên clang-asan: 200.000 lượt mỗi đích, 23.59 giây.
8. Sự cố khác ghi từ trước:
   - A ghi một tệp ra ngoài worktree.
   - gcc-debug `log_tests` gặp 0xC0000374 ở bước 0 (chạy lại ctest thì xanh).
   - Máy Hoon có lúc mất kết nối.
   - Chi tiết các mục này còn phải đối chiếu với báo cáo của từng vai trước khi chốt.
9. T6 lượt 2 bị ngắt:
   - `so-do/l-t6-lan2.py` chạy ở tiền cảnh lúc 10:10:49. Nó ghi xong `so-do/l-t14-lan2.log` (10:10:50) rồi treo ở bước T6 và bị người dùng ngắt, nên không có `l-t6-lan2.log`. L kiểm không còn tiến trình rồi trả khoá lúc 10:15:30.
   - Dòng `lich-nang.tsv` lúc đó ghi nhầm là ngắt ở bước T14; dòng đính chính 10:16:26 đã sửa bằng một dòng mới.
   - Chạy lại lúc 10:15:30 dừng ngay vì `l-t14-lan2.log` đã có, không chạy gì (`build/p2-l/t6b-out.txt`, `t6b-err.txt`).
   - Từ đó mọi script dài chạy tách ra bằng `Start-Process`. T6 lượt kế tiếp dùng tên mới (lần 3).
10. Chạy trong lúc vai khác giữ khoá:
   - Hai lượt `check.py` trên một tệp `tests/fuzz/targets.hpp`, lúc 10:37:22 và 10:37:41 (`so-do/l-check-targets-nguon.log`, `l-check-targets-nguon-lan2.log`), chạy khi R đang giữ `NANG.lock` (từ 10:36:11, dựng `build/p2-r` và `net_tests` ×20).
   - Lượt một tệp thuộc loại nhẹ, nhưng vẫn chạy chồng lên phiên khoá của R. L nhắc lúc 10:39. Từ đó tới khi R trả khoá, Build & Test không chạy gì.

11. Đo bị bản dựng ngoài nhóm chen vào:
    - Lượt `l-cuoi-d1-sach-vong1..3` và `l-cuoi-d2-d3-moi-vong1..3` (trong phiên 10:43:49): psutil thấy `g++`/`cc1plus` của cây chính (chủ dự án và Claude chạy `verify_commits.cmd`) trong các vòng, nên mọi vòng đều không đạt, kể cả vòng có tỉ số dưới 1,5.
    - Lượt `l-cuoi-lan2-d1-sach-vong1..3` và `l-cuoi-lan2-d2-d3-moi-vong1..3` (10:53:26 tới 10:54:39): cây chính dựng `msvc-release` và gcc cùng lúc (`cl`, `cc1plus`, `ninja`), số tụt rõ (Đ1 khoảng 2,6 triệu/giây, Đ3 khoảng 700 tới 900 MiB/giây), mọi vòng không đạt.
    - Hai lượt này giữ nguyên log, không dùng làm số chính (L, 11:00). Build & Test không đụng tiến trình của cây chính, chỉ chờ máy rảnh rồi đo lại ở phiên 10:56:47.
12. Lượt đo lại 10:52:16 (`so-do/l-phien-cuoi-do2.py`) chạy tiền cảnh và bị người dùng ngắt sau khoảng 43 giây, đang ở vòng đầu, chưa ghi log nào. Đã kiểm không còn tiến trình; dòng tsv 10:52:16 tới 10:52:59. Lượt sau chạy tách bằng `Start-Process`.
13. L dặn ghi danh sách tiến trình nặng trước mỗi vòng. `l-cuoi-lan3-d2-d3-moi-vong1.log` có dòng `tiến trình nền lúc bắt đầu`, còn `l-cuoi-lan3-d1-sach-vong1.log` chỉ có dòng psutil theo dõi suốt vòng (`không có`), không có dòng liệt kê lúc bắt đầu. Lead kiểm máy lúc 10:58:51 không còn trình dựng nào. Log giữ nguyên, không đo lại (R nêu lúc 11:00).
14. Dọn dẹp lúc 11:01:53: dòng "ổ F trống sau khi dọn" trong `l-don-dep.log` không in ra vì lỗi định dạng chuỗi của PowerShell. Việc xoá đã xong; số ổ F sau khi dọn ghi ở tệp mới `l-don-dep-o-f.log` (11:02:06). Các đường dẫn `build/p2-l/*` nhắc ở trên (ví dụ `t6b-out.txt`) không còn sau khi dọn.

## Mục còn mở cho vòng sau

Mã đã đóng băng từ 10:43:49. Các mục dưới đây không sửa ở đợt này (L quyết lúc 10:24 và 10:52; R ghi ở `REVIEW.md` mục 5):

| mục | chỗ | người | nội dung |
|---|---|---|---|
| M1 | `SRC/net/socket_posix.cpp:170` | B | POSIX: RST tới sau FIN trước lần hỏi đầu (`EPIPE` trên Linux) ra `kConnect` thay cho `kReset` |
| M2 | `tests/protocol_channel_tests.cpp` | A | thiếu ca test ở trần hộp nhận sát của server (65.544) |
| M4 | `tests/protocol_channel_tests.cpp:33–34, 78–79` | A | thân `for` xuống dòng không ngoặc nhọn |
| N3 (phần L) | `tests/protocol_fuzz_tests.cpp:115`, `tests/fuzz/targets.hpp:83`, `tests/bench/bench.hpp:17, 22` | L | chữ ký hàm bị bẻ dòng |
| N6 | `SRC/protocol/messages.cpp:483, 498, 513` (sinh từ `protocol_cpp_src.py:213, 239`) | C | bộ giải mã sinh ra không đối chiếu `body.size()` với `frame.body_bytes`; L dời sang vòng sau lúc 10:24 |
| N10 | `TOOLS/server/fuzz_protocol.py:27` | L | không chỉ được bản chép mã; cần thêm `--source` và `--out` |
| N12 | `so-do/r-bang-sai.log` dòng 185 tới 198 (ca 9) | C | `optional:optional:u8` được chấp nhận; DE-BAI §3.5 G6 để ngỏ; L quyết lúc 10:24 để mở cho vòng sau (L quyết cách sửa, C làm) |

M3 (BAO-CAO-B còn ghi `DD-08`) đã sửa lúc 10:52:39.

## Dọn dẹp (L giao lúc 11:00)

Xoá sáu thư mục tạm lúc 11:01:53, giữ ba cây preset. Trước khi xoá không có tiến trình nào chạy từ các thư mục đó (`so-do/l-don-dep.log`, `so-do/l-don-dep-o-f.log`).

| thư mục | byte giải phóng | GiB | số tệp |
|---|---|---|---|
| `build/p2-a` | 85054192 | 0.079 | 407 |
| `build/p2-b` | 54839661 | 0.051 | 394 |
| `build/p2-c` | 62422779 | 0.058 | 438 |
| `build/p2-fuzz` | 105311720 | 0.098 | 566 |
| `build/p2-l` | 148144729 | 0.138 | 515 |
| `build/p2-r` | 292797698 | 0.273 | 1339 |
| tổng | 748570779 | 0.697 | 3659 |

- Ổ F trống trước khi dọn: 166377521152 byte (≈155,0 GiB), lúc 11:01:53.
- Ổ F trống sau khi dọn: 167128547328 byte (≈155,7 GiB), lúc 11:02:06; tăng 751026176 byte.
- Còn lại trong `build/`: ba cây preset, `baseline`, các thư mục `p1-*` của đợt 1, `p2-c-refs-star`, `p2-a-build.log`, `p2-a-configure.log`, `lich-nang.tsv`. Các mục này ngoài danh sách sáu thư mục nên L chưa xoá.
- Sau khi dọn: không còn tiến trình nào chạy từ worktree `p2-dot-2`.