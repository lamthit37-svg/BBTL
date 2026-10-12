# Đề bài P2 đợt 2: `protocol`, `net`, `gen_protocol.py`, fuzz

Soạn ngày 2026-10-08 cho đội Grok Build. Người kiểm cuối là Claude; người duyệt là chủ dự án.

## 1. Việc này là gì

P2 đợt 1 đã đạt: bảy exe khởi động theo thứ tự, in `ready`, dừng êm; cấu hình sai bị từ chối kèm số
dòng. Đợt này làm nền dây cho mọi mốc sau: tầng byte và khung của protocol, danh mục tin sinh từ
bảng, socket TCP không chặn, và fuzz cho mọi bộ giải mã. Xong đợt này, tiêu chí còn lại của P2 ở
`docs/KE-HOACH-SERVER.md` mục 10 phải đạt: fuzz một triệu vòng không lỗi dưới ASan và UBSan. Đợt 3
(`secure`, `ipc`, `metrics`, nối các tiến trình) không thuộc đề bài này.

Đợt này không sửa bảy exe: chúng vẫn không mở cổng mạng nào. Sản phẩm là hai thư viện, một công
cụ, bộ test và số đo.

Khác các đợt trước ở ba điểm, đọc kỹ:

- **Nơi làm việc là một worktree riêng**: `F:\tl 2026\THIENLONG\build\p2-dot-2`, nhánh `p2-dot-2`,
  Claude đã tạo và đã dựng sẵn ba preset trong đó. Mọi đường dẫn tương đối trong tệp này tính từ
  gốc worktree đó. Cây chính `F:\tl 2026\THIENLONG` đang có Claude viết mã client: không ghi, không
  dựng, không chạy gì ở ngoài worktree.
- **Nghiệm thu bằng số đo.** Mỗi con số trong báo cáo phải có lệnh, số lượt, trung vị, nhỏ nhất,
  lớn nhất và tệp log gốc (mục 8). Claude đo lại từng số; lệch quá ngưỡng ghi ở mục 7 thì báo cáo
  bị trả, kể cả khi mã đúng.
- **Một máy, nhiều vai.** Lệnh nặng chạy lần lượt theo lịch của L (mục 3.9). Hai lệnh nặng chạy
  cùng lúc đã từng làm clang-tidy và apksigner chết vì hết bộ nhớ (`AGENTS.md` mục 11).

Tổ chức như các đợt trước: bạn là phiên chính L; A, B, C viết mã song song; R review trong phiên
mới; đối chất chéo; L ghi `KET-QUA.md`. L có phần mã tích hợp (bước 1b) và phần đó cũng qua R. Giao
việc cho subagent bằng đường dẫn tệp này và tên vai.

Đọc trước khi viết mã, theo thứ tự:

1. Tệp này, kèm `docs/giao-viec/P2-DOT-2/hop-dong/wire.hpp`.
2. `AGENTS.md`, trọn mục 2 tới mục 11.
3. `docs/giao-viec/P1-DOT-3/DE-BAI.md` mục 5.5 (luật mã C++) và `docs/giao-viec/P2-DOT-1/DE-BAI.md`
   mục 4.5 (dựng, kiểm): vẫn có hiệu lực, trừ chỗ tệp này nói khác.
4. `docs/KE-HOACH-SERVER.md` mục 5 và mục 8.
5. Bộ quy cách, tra theo mã trong `~/.claude/cpp23/INDEX.md`: MMO-05 (khung có tiền tố độ dài),
   MMO-06 (`Reader`), UB-04 (kiểm độ dài trước mọi lần đọc), LH-03 (dữ liệu client không làm dừng
   máy chủ), KT-10 (byte mẫu), KT-11 (fuzz), UB-13 (hàng đợi gửi có trần), KTR-09 (phiên bản).
6. Trong `G:\TLBB\Dev`, chỉ đọc, theo vai: A và C đọc `docs\PROTOCOL.md`, `src\protocol\`,
   `tests\protocol\`, `src\net\connection.*`; B đọc `src\platform\socket*`,
   `tests\platform\socket_test.cpp`; L đọc `tests\protocol\protocol_fuzz_test.cpp`.

## 2. Điều Claude đã đo cho đợt này

**Worktree.** Ở commit đầu đợt, trong `build/p2-dot-2`, bằng đúng lệnh của `AGENTS.md` mục 3:
`msvc-release` dựng 94 giây, 0 cảnh báo, 43/43 test; `clang-asan` dựng 64 giây, 0 cảnh báo, 43/43;
`gcc-debug` dựng 49 giây, 0 cảnh báo, 37/37 (preset này không có các test cần GPU). Test Python
của `TOOLS/server`: 216 test, 8 bỏ qua, 1,3 giây; `lint_py.py` thoát 0. Worktree không có
`CLIENT/data` và `SERVER/tables` (hai thư mục không vào git); các test cần chúng tự bỏ qua hoặc
không đăng ký, đợt này không cần chúng. Ở `gcc-debug`, `log_tests` thỉnh thoảng chết với mã
`0xC0000374` vì lỗi TLS giả lập của GCC MinGW (`AGENTS.md` mục 11, `docs/NGHI-NGO.md` mục 12):
gặp thì chạy lại và ghi vào báo cáo, không sửa. Cùng lý do đó, mã và test của đợt này không dùng
đối tượng `thread_local` có huỷ tử trong luồng tạo bằng `std::thread` hay `std::jthread`.
`cmake --preset <p>` trong worktree tự cài thư viện vcpkg vào `vcpkg_installed/` của worktree từ bộ
đệm nhị phân (5 giây), không cần cờ thêm. Ba cây `build/msvc-release`, `build/clang-asan`,
`build/gcc-debug` đã dựng sẵn; chỉ L và R dùng.

**libFuzzer.** Clang 23.1.2 của máy (đích MSVC) có `clang_rt.fuzzer-x86_64.lib`. Một tệp thử 28
dòng dựng bằng `clang++ -std=c++23 -g -O1 -fsanitize=fuzzer,address,undefined
-fno-sanitize-recover=undefined x.cpp -o x.exe` rồi chạy `x.exe -runs=1000000 -seed=20261008
-max_len=4096 <thư mục corpus>`: bản đúng xong một triệu vòng trong 1 giây, thoát 0. Bản cố ý bỏ
phép kiểm biên: ASan báo `heap-buffer-overflow`, thoát 1, ghi tệp `crash-*`. Bẫy đã gặp: ở lần thử
đầu, hàm `LLVMFuzzerTestOneInput` gọi bộ giải mã rồi bỏ kết quả; trình dịch xoá luôn vòng đọc, bản
có lỗi chạy hết một triệu vòng "sạch". Harness phải dùng kết quả (mã hoá lại rồi so byte, hoặc ghi
vào một biến `volatile`). Chưa đo: ghép libFuzzer vào CMake của dự án; vì vậy mục 3.8 cho dựng bằng
lệnh trần qua một script.

**Winsock dưới `check.py`.** Một tệp thử mở cổng nghe trên `127.0.0.1` cổng 0, nối không chặn,
`WSAPoll`, gửi và nhận một byte: GCC 16 và Clang 23 dựng sạch, chạy thoát 0, nối `-lws2_32`. Thứ
phải làm đúng:

- Thứ tự include: `#include "core/win32.hpp" // IWYU pragma: keep` trong nhóm header dự án, rồi
  `<winsock2.h>`, `<ws2tcpip.h>` ở nhóm nền tảng. `core/win32.hpp` đã khai `WIN32_LEAN_AND_MEAN`
  nên `<windows.h>` không kéo `winsock.h` cũ.
- `if (handle == INVALID_SOCKET)` bị clang-tidy từ chối (`modernize-use-integer-sign-comparison`).
  Dùng hằng của mình: `constexpr SOCKET kNoSocket = ~SOCKET{0};`.
- `WSAEWOULDBLOCK` và các mã lỗi khác đòi include thẳng `<winerror.h>` (`misc-include-cleaner`).
- Ép `sockaddr_in*` sang `sockaddr*` và tham số `const char*` của `setsockopt` cần
  `reinterpret_cast`: mỗi chỗ một dòng NOLINT nêu check, lý do, và gom các chỗ đó vào ít hàm nhất.

**Bản POSIX.** Máy này không dựng được Linux. Kiểm cú pháp bằng trình dịch NDK, đã thử trên
`SRC/process/process_posix.cpp`, thoát 0 ở cả hai ABI:
`"%LOCALAPPDATA%\Android\Sdk\ndk\30.0.16248370\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android29-clang++.cmd"
-std=c++23 -fsyntax-only -Wall -Wextra -Werror -I SRC <tệp>` và cùng lệnh với
`x86_64-linux-android29-clang++.cmd`.

**Hợp đồng tầng byte.** `docs/giao-viec/P2-DOT-2/hop-dong/wire.hpp` (chỉ có khai báo) đã qua
`check.py` trọn bộ: clang-format, độ lồng, GCC, Clang, clang-tidy, 0 lỗi.

**Dự án tham chiếu `G:\TLBB\Dev`** (khảo sát bằng agent ngày 2026-10-08; vai nào port tệp nào thì
đọc trọn tệp đó, thấy số dưới đây lệch thì báo):

- `docs\PROTOCOL.md` 401 dòng, "bản 5". `src\protocol\`: `wire.hpp` 253, `wire.cpp` 311,
  `protocol.hpp` 1.156, `protocol.cpp` 321. Tin khai bằng struct viết tay; không có công cụ sinh
  mã; không có libFuzzer. 48 tin, 20 của client và 28 của máy chủ, chia nhóm ở byte cao: 01 phiên
  (5 và 7), 02 nhân vật (3 và 1), 03 cảnh (3 và 6), 04 chat (1 và 2), 05 xác thực (2 và 1), 06 hội
  thoại (3 và 3), 07 nhiệm vụ (3 và 4), 08 túi (0 và 3), 09 chỉ số (0 và 1).
- Byte mẫu của `Hello` ở `tests\protocol\protocol_test.cpp:217`:
  `07 00 00 00 01 01 00 00 01 00 02 04 03 02 01`.
- `tests\protocol\`: `protocol_test.cpp` 707 dòng 21 ca, `protocol_v5_test.cpp` 592 dòng 18 ca,
  `protocol_samples.hpp` 139, `protocol_fuzz_test.cpp` 273 dòng: bộ đột biến tự viết, splitmix64,
  200.000 vòng mỗi bộ giải mã, 11/16 khung thật bị đột biến, 4/16 mã tin thật với thân ngẫu nhiên,
  1/16 ngẫu nhiên hẳn; kiểm không sập và thứ giải mã được thì mã hoá lại trùng byte.
- Socket: `src\platform\socket.hpp` 210, `socket.cpp` 33, `socket_win32.cpp` 411,
  `socket_posix.cpp` 485; `WSAPoll` và `poll`, kiểu mức. `src\net\connection.hpp` 92 và
  `connection.cpp` 100 là bộ đệm khung, không đụng socket. `accept` của Dev bỏ địa chỉ bên kia
  (`socket_win32.cpp:292`), nên trần kết nối mỗi IP không làm được.
- Bẫy Dev đã ghi: `WSAPoll` với 0 phần tử là lỗi; `recv` trả 0 nghĩa là bên kia đóng, nên không gọi
  `recv` với bộ đệm rỗng; socket vừa `accept` phải đặt lại không chặn và `TCP_NODELAY`; không đặt
  `SO_REUSEADDR` cho cổng nghe trên Windows; đóng êm là gửi, `shutdown` chiều gửi, rồi đọc tới khi
  bên kia đóng, vì RST nuốt mất tin cuối; trễ khoảng 200 ms trên loopback còn chưa giải thích
  (`docs\NGHI-NGO.md:197-209` của Dev). Test socket của Dev dựa vào `sleep_for` và các quãng ngủ cố
  định: không port các chỗ đó.

## 3. Thiết kế đã chốt

### 3.1 Module và tầng

| Module | Vai | Được include | Việc |
|---|---|---|---|
| `SRC/protocol/` | A, C | `core` | tầng byte, khung, kênh, danh mục tin (phần danh mục do công cụ sinh) |
| `SRC/net/` | B | `core` | socket TCP không chặn, tập chờ; nơi duy nhất include header mạng của hệ điều hành |
| `TOOLS/server/gen_protocol.py` và các tệp `protocol_*.py` cạnh nó | C | thư viện chuẩn Python | bảng mô tả tin thành mã C++, byte mẫu, tài liệu |
| `TOOLS/server/fuzz_protocol.py`, `tests/fuzz/` | L | | dựng và chạy libFuzzer |

`protocol` không include `net` và ngược lại; chỗ ghép hai bên là test của L. Namespace
`game::protocol`, `game::net`. Hai dòng mới của `cmake/GameLayers.cmake`: `game_layer_protocol` là
`"core protocol"`, `game_layer_net` là `"core net"`. Mã port từ Dev ghi `Nguồn:` và `Khác gốc:` đầu
tệp; danh sách tệp port ghi vào `docs/giao-viec/P2-DOT-2/NGUON.md`.

Phiên bản protocol của dự án bắt đầu từ 1 (`gate.toml` có `min_version = 1`); nó lấy hình dạng từ
bản 5 của Dev nhưng là một protocol khác, chưa phát hành, nên đợt này chưa có luật tương thích ngược.

### 3.2 Khung và phép mã hoá

Mọi số little-endian, ghép và tách từng byte bằng phép dịch bit; không `memcpy` cả struct, không
`reinterpret_cast` vùng byte.

- Đầu khung 8 byte: `u32` số byte của thân, `u16` mã tin, `u16` cờ. Cờ khác 0 là `kBadFlags`.
- Trần thân: 65.536 byte cho mọi tin, 4.096 byte cho tin từ client (trùng `client_frame_bytes` của
  `gate.toml`). Thân khai quá trần bị từ chối ngay khi đủ 8 byte đầu, trước khi chờ hay cấp phát
  cho thân (`kBodyTooLarge`).
- Mã tin: byte cao là nhóm; bit 15 bật là tin của máy chủ; tin trả lời dùng lại số thấp của tin hỏi.
- Lỗi giải mã, đúng mười giá trị, thứ tự như `hop-dong/wire.hpp`: `kTruncated`, `kTrailingBytes`,
  `kTooLong`, `kBadText`, `kNonFinite`, `kBadEnum`, `kBodyTooLarge`, `kBadFlags`, `kUnknownKind`,
  `kOutOfRange`. Thân còn byte thừa là `kTrailingBytes`; thiếu byte là `kTruncated`. Khung chưa tới
  đủ không phải lỗi.

| Kiểu trong bảng | Trên dây | Kiểu C++ | Luật |
|---|---|---|---|
| `u8` `u16` `u32` `u64` | 1, 2, 4, 8 byte | `std::uintN_t` | |
| `i8` `i16` `i32` `i64` | bù hai, cùng cỡ | `std::intN_t` | đổi qua kiểu không dấu cùng cỡ, không dịch số âm |
| `bool` | 1 byte | `bool` | 0 hoặc 1; khác là `kBadEnum` |
| `f32` | 4 byte, bit của IEEE 754 | `float` | `std::bit_cast`; NaN và vô cực bị từ chối ở cả hai chiều (`kNonFinite`) |
| `seconds16` `millis32` `millis64` | `u16`, `u32`, `u64` | `std::chrono::seconds`, `milliseconds` | ghi giá trị âm hoặc quá cỡ là `kOutOfRange` |
| `enum:<Tên>` | `u8` hoặc `u16` theo bảng enum | `enum class` | giá trị bắt đầu từ 1; ngoài tập là `kBadEnum` ở cả hai chiều |
| `text` | `u16` số byte rồi các byte | `std::string` | có trần byte riêng từng trường; UTF-8 đúng RFC 3629 (không mã hoá dài thừa, không nửa cặp thay thế, không quá U+10FFFF), cấm byte 0; sai là `kBadText`, quá trần là `kTooLong`; kiểm ở cả hai chiều |
| `bytes` | đúng N byte, không tiền tố | `std::array<std::byte, N>` | N lấy từ cột trần |
| `list:<kiểu>` | `u16` số phần tử rồi các phần tử | `std::vector<T>` | có trần số phần tử riêng; quá trần là `kTooLong`; kiểm trần trước khi cấp phát |
| `optional:<kiểu>` | 1 byte 0 hoặc 1, rồi giá trị nếu 1 | `std::optional<T>` | byte khác 0 và 1 là `kBadEnum` |
| `record:<Tên>` | các trường theo thứ tự | `struct` | không đệ quy |

`list` và `optional` bọc một kiểu không phải `list`. Đợt này chưa có `variant` và `f64`.

### 3.3 Giao diện `Reader`, `Writer`, `peek_frame`

`hop-dong/wire.hpp` là hợp đồng giữa A và C: A chép nó thành `SRC/protocol/wire.hpp` rồi viết phần
cài đặt; C sinh mã chỉ gọi các hàm công khai trong đó. A cần đổi một chữ ký thì báo L, L báo C, và
ghi vào báo cáo; phần `private` A tuỳ ý.

- `Writer` nối một khung vào cuối `out`: lúc tạo chừa 8 byte đầu khung; `finish(kind)` điền đầu
  khung. Lỗi đầu tiên được nhớ, các lời gọi sau không làm gì; `finish` thấy lỗi thì cắt `out` về cỡ
  lúc tạo và trả lỗi đó. Thân vượt 65.536 byte là `kBodyTooLarge`.
- `Reader` đọc thân một khung: mỗi lần đọc kiểm `cần > còn lại` trước; lỗi đầu tiên được nhớ, các
  lời gọi sau trả giá trị không và không đọc. `text` kiểm độ dài với trần và với số byte còn lại
  trước khi cấp phát. `finish` trả lỗi đã nhớ, hoặc `kTrailingBytes` khi còn byte.
- `peek_frame(buffer, max_body)`: không có khung khi chưa đủ 8 byte đầu hoặc chưa đủ thân; lỗi khi
  cờ khác 0 hoặc thân khai quá `max_body`, báo ngay khi đủ 8 byte đầu.

### 3.4 Kênh

`SRC/protocol/channel.hpp`, của A: bộ đệm khung cho một kết nối, không đụng socket. Nguồn:
`src\net\connection.*` của Dev.

- Hộp nhận có trần 65.536 + 8 byte, hộp gửi có trần 1 MiB; cả hai là tham số lúc tạo, cùng trần
  thân (4.096 cho kết nối của client).
- Nhận byte: vượt trần hộp nhận là lỗi `kInboxFull`, không cấp phát thêm. Lấy khung kế: không có
  khi chưa đủ; có thì trả mã tin và vùng nhìn vào thân, còn hiệu lực tới lời gọi kế; khung hỏng thì
  kênh hỏng hẳn, mọi lời gọi sau trả cùng lỗi.
- Xếp một khung đã mã hoá vào hộp gửi: nếu thêm vào sẽ vượt trần thì từ chối bằng `kOutboxFull` và
  không thêm byte nào. Khác gốc: Dev kiểm trước khi thêm nên có thể vượt trần một khung.
- Lỗi của kênh là một `enum class` riêng bọc được `WireError`.

### 3.5 Danh mục tin

Nguồn sự thật là bốn bảng TSV ở `SRC/protocol/catalog/`, cùng hình dạng với các bảng của
`TOOLS/server` (dòng `# schema 1`, `# source:`, `# types:`, rồi dòng tên cột). Thêm một dòng
`# version 1` ở `messages.tsv`: phiên bản protocol.

- `groups.tsv`: `id` (hai chữ số hex), `name`, `summary`.
- `messages.tsv`: `kind` (dạng `0x0101`), `name` (CamelCase), `port` (`game`, `auth` hoặc `both`),
  `since` (phiên bản đầu tiên có tin), `summary` (một câu tiếng Việt).
- `fields.tsv`: `owner` (tên tin hoặc record), `order` (từ 1, liền nhau), `name` (snake_case),
  `type` (theo bảng ở mục 3.2), `limit` (trần byte của `text`, trần số phần tử của `list`, N của
  `bytes`; kiểu khác để trống), `note`.
- `enums.tsv`: `enum`, `underlying` (`u8` hoặc `u16`), `value`, `name`, `note`.

Record khai bằng một dòng trong `messages.tsv` có `kind` là chữ `record`, `port` và `since` để
trống; các trường của nó nằm ở `fields.tsv` như của tin.

Nội dung đợt này: đúng ba nhóm đủ cho mốc P3, chép từng trường từ `src\protocol\protocol.hpp` của
Dev: nhóm 01 phiên, 02 nhân vật, 05 xác thực. Theo khảo sát đó là 19 tin, 10 của client và 9 của
máy chủ; C đếm lại trên tệp gốc và báo số thật. Tên trường chuyển sang snake_case của dự án; thứ
tự, kiểu và trần giữ nguyên. Trường thời lượng của Dev (`u64` mili giây, `u16` giây) khai bằng kiểu
thời lượng của mục 3.2. Dev dùng giá trị canh thay cho "không có" (0, 0xFF): giữ nguyên trên dây và
ghi chú ở cột `note`, không tự đổi sang `optional`.

Công cụ từ chối bảng sai. Mỗi luật dưới đây có một test trong `test_gen_protocol.py`, đặt tên theo
mã luật, và lỗi in ra dạng `tệp:dòng: câu`:

| Mã | Luật |
|---|---|
| G1 | dòng tên cột đúng tên, đúng thứ tự |
| G2 | `kind` là `record` hoặc đúng dạng `0x` kèm bốn chữ số hex, mã tin không lặp; byte cao (bỏ bit 15) có trong `groups.tsv` |
| G3 | tên tin, record, enum không lặp nhau; tin và record CamelCase, trường snake_case, không trùng từ khoá C++ |
| G4 | với tin: `port` thuộc tập cho phép, `since` từ 1 tới `# version`; với record: hai ô đó trống |
| G5 | `order` của mỗi chủ liền nhau từ 1; tên trường không lặp trong một chủ |
| G6 | `type` đúng văn phạm; enum và record được nhắc phải tồn tại; record không đệ quy; `list` và `optional` không bọc `list` |
| G7 | `text`, `list`, `bytes` có `limit` từ 1; kiểu khác không có `limit` |
| G8 | giá trị enum từ 1, không lặp, vừa kiểu nền; tên không lặp |
| G9 | cỡ thân lớn nhất tính từ các trần: tin của client không quá 4.096 byte, tin của máy chủ không quá 65.536 |
| G10 | record và enum nào cũng có nơi dùng |
| G11 | tin không có trường nào là hợp lệ (thân 0 byte); chủ có trường mà không có dòng khai là lỗi |

### 3.6 `gen_protocol.py`

`python -B TOOLS/server/gen_protocol.py` đọc `SRC/protocol/catalog/` và ghi:

- `SRC/protocol/messages.hpp`, `SRC/protocol/messages.cpp`: `kVersion`; enum kèm `is_valid`; mỗi
  tin và record một struct có giá trị mặc định cho mọi thành viên và `operator==` mặc định; hằng
  trần của từng trường; `encode(std::vector<std::byte>& out, const <Tin>&)` trả `WireStatus`; bốn
  bộ giải mã `decode_game_client`, `decode_game_server`, `decode_auth_client`, `decode_auth_server`
  nhận `Frame` và thân, trả `std::expected<std::variant<...>, WireError>`. Mã tin không thuộc đúng
  cổng và đúng chiều của bộ giải mã là `kUnknownKind`: tin của cổng kia và tin sai chiều đều rơi
  vào đây.
- `tests/protocol_samples.hpp`: với mỗi tin ba mẫu (nhỏ nhất, lớn nhất theo mọi trần với chữ nhiều
  byte, điển hình), mỗi mẫu gồm giá trị C++ và byte mong đợi. Byte do một bộ mã hoá viết bằng
  Python trong công cụ tính ra, độc lập với mã C++: hai bản cài đặt phải ra cùng byte.
- `docs/PROTOCOL-TIN.md`: bảng tra danh mục tin, sinh từ bảng.

Luật của công cụ:

- Tất định: hai lần chạy ra tệp trùng từng byte; thứ tự theo `kind` rồi `order`, không phụ thuộc
  thứ tự của `dict` hay hệ tệp; xuống dòng LF; UTF-8 không BOM.
- `--out <thư mục>` ghi cả cây đầu ra vào thư mục khác; `--check` so tệp trên đĩa với thứ sẽ sinh,
  thoát 1 và in tên từng tệp cũ.
- Tệp sinh mở đầu bằng một dòng nói nó là tệp sinh và lệnh sinh lại. Mã sinh phải qua `check.py`
  như mã viết tay; chỗ nào buộc NOLINT thì chính công cụ ghi NOLINT kèm check, lý do, mã quy tắc.
- Tệp sinh được miễn trần 500 dòng, nhưng mỗi hàm sinh ra vẫn theo trần 40 dòng và độ lồng 1: tin
  nhiều trường thì công cụ tách hàm.
- Qua cổng `lint_py.py` (hàm tối đa 50 dòng, lồng tối đa 3 mức); không tệp Python nào quá 500 dòng.

### 3.7 `net`

Port từ `src\platform\socket*` của Dev, viết lại theo luật của dự án. Kiểu công khai:
`Network` (RAII của `WSAStartup`), `Endpoint` (IPv4 và cổng), `TcpStream`, `TcpListener`, `PollSet`,
`NetError`. Header công khai không lộ kiểu nào của hệ điều hành.

- Mọi socket không chặn từ lúc tạo; thư viện không có lời gọi chặn nào ngoài `PollSet::wait` có
  hạn. Nối là hai bước: bắt đầu nối, rồi hỏi kết quả khi tập chờ báo ghi được.
- `Endpoint` đọc từ chữ dạng `"0.0.0.0:7000"` (dạng của `gate.toml`) bằng `inet_pton`; không phân
  giải tên, không `getaddrinfo`. Chỉ IPv4.
- `accept` trả luồng kèm `Endpoint` của bên kia. Khác gốc: Dev bỏ địa chỉ này.
- Gửi và nhận trả số byte đã chuyển; 0 là "chưa được, chờ tập chờ báo"; bên kia đóng là `kClosed`,
  lỗi khác là `kReset`. Nhận với bộ đệm rỗng trả 0 mà không gọi `recv`.
- Mọi luồng bật `TCP_NODELAY`, kể cả luồng vừa `accept`. Cổng nghe trên Windows không đặt
  `SO_REUSEADDR`.
- `PollSet`: thêm, bớt theo nhãn 64 bit, bật tắt quan tâm ghi, chờ có hạn. Tập rỗng thì chờ hết hạn
  rồi trả không sự kiện, không gọi `WSAPoll` với 0 phần tử.
- Đóng êm là việc của bên gọi; thư viện cho đủ phép: gửi, đóng chiều gửi, nhận tới `kClosed`.
- `SRC/net/socket_win32.cpp` dựng và chạy test. `SRC/net/socket_posix.cpp` port theo, kiểm cú pháp
  bằng hai lệnh NDK ở mục 2, ghi rõ "chưa chạy" trong báo cáo. Header mạng của hệ điều hành chỉ
  xuất hiện trong hai tệp này.
- CMake nối `ws2_32` cho `game_net` trên Windows.

### 3.8 Fuzz, hai tầng

**Tầng một, trong ctest, cả ba preset**: `tests/protocol_fuzz_tests.cpp`, của L. Bộ đột biến tự
viết, splitmix64, hạt giống `0x7D1BB5A020261008`, tỉ lệ đầu vào như Dev (11/16, 4/16, 1/16), hạt
giống corpus là mọi mẫu của `protocol_samples.hpp`. Năm đích: `peek_frame` cùng kênh, và bốn bộ giải
mã. Bất biến: không sập; thứ giải mã được thì mã hoá lại trùng byte đầu vào; kênh không bao giờ
giữ quá trần. 200.000 vòng mỗi đích. Nếu ở `clang-asan` test này chạy quá 60 giây thì cho số vòng
của riêng preset đó thấp xuống tới mức dưới 60 giây và ghi số vòng thật vào báo cáo.

**Tầng hai, libFuzzer**: `python -B TOOLS/server/fuzz_protocol.py --runs 1000000 --seed 20261008`.
Script dựng năm harness ở `tests/fuzz/` bằng lệnh trần đã đo ở mục 2 (không qua CMake), mỗi harness
kèm các tệp `.cpp` của `protocol` nó cần, vào `build/p2-fuzz/`; mồi corpus bằng byte mẫu; chạy lần
lượt từng đích; `-max_len` là trần thân của đích cộng 64. In và ghi
`docs/giao-viec/P2-DOT-2/so-do/fuzz.tsv`: đích, số vòng, giây, vòng mỗi giây, `cov`, `ft`, số tệp
corpus, mã thoát. Có đích thoát khác 0 thì script thoát 1 và giữ tệp `crash-*`.

Harness phải dùng kết quả giải mã (bẫy ở mục 2): giải mã, nếu được thì mã hoá lại và so byte, lệch
thì `__builtin_trap()`.

**Bộ dò phải có răng** (R làm, mục 6): trên một bản chép của `SRC/protocol` đặt trong `build/`, bỏ
một phép kiểm biên của `Reader` rồi chạy tầng hai trên bản chép đó: phải thoát khác 0 trong một
triệu vòng. Không sập thì tiêu chí fuzz không đạt, vì harness không soi được gì.

### 3.9 Dựng, kiểm, điều phối máy

- L sửa hai tệp có sẵn, chỉ thêm dòng: `CMakeLists.txt`, `cmake/GameLayers.cmake`. Không vai nào
  khác sửa hai tệp này. `vcpkg.json`, `CMakePresets.json` không đụng: đợt này không thêm thư viện.
- `protocol` và `net` khai cho mọi nền tảng dựng được máy chủ, trong khối
  `if(NOT CMAKE_CROSSCOMPILING)` như `process`. Ở bước 1 danh sách nguồn lấy bằng `file(GLOB ...
  CONFIGURE_DEPENDS)`; bước 1b L đổi thành danh sách tường minh.
- Test `protocol_catalog_fresh` chạy `gen_protocol.py --check`; chỉ đăng ký khi
  `find_package(Python3 COMPONENTS Interpreter)` thấy Python.
- Mỗi vai dựng trong thư mục riêng: `cmake --preset clang-asan -B build/p2-<vai>`, rồi `cmake
  --build build/p2-<vai> --target <target của mình>`, `ctest --test-dir build/p2-<vai> -R <test của
  mình>`. Ba cây `build/msvc-release`, `build/clang-asan`, `build/gcc-debug` chỉ L và R dùng.
- **Lệnh nặng** là: dựng trọn một preset; `check.py` có clang-tidy trên hơn năm tệp; tầng hai của
  fuzz; mọi phép đo của mục 7. Mỗi lúc chỉ một lệnh nặng trên cả máy. L giữ lịch: vai nào cần thì
  xin L, chạy xong thì báo. Vai A, B, C trong lúc viết mã chỉ dựng target của mình và chạy
  `check.py --no-tidy --only gcc` để lặp nhanh; lượt `check.py` đủ bộ xin lịch.
- Phép đo chỉ chạy khi không có lệnh nặng nào khác; log của phép đo ghi dòng đầu là giờ bắt đầu và
  câu "không có bản dựng nào khác đang chạy". Claude dựng client ở cây chính trong cùng thời gian
  nên máy không hoàn toàn rảnh: mỗi phép đo chạy ít nhất năm lượt, báo trung vị, nhỏ nhất, lớn
  nhất; lượt lớn nhất quá 1,5 lần lượt nhỏ nhất thì đo lại.
- Luật mã C++ như mục 5.5 của đề bài P1 đợt 3. Thêm: không tệp `.cpp` viết tay nào quá 500 dòng;
  byte từ mạng và ô của bảng danh mục là dữ liệu ngoài, kiểm trần trước khi cấp phát, không đi vào
  `core::check`, `assert`, `.at()`; test không có `sleep_for`, `Sleep`, vòng thử lại theo giờ: chờ
  bằng `PollSet::wait` có hạn.

## 4. Việc của từng vai

### L

Bước 0, một mình: ghi mốc vào `docs/giao-viec/P2-DOT-2/moc/` (`git-status.txt`, bản chép của
`CMakeLists.txt` và `cmake/GameLayers.cmake`, output của `ctest --preset clang-asan`); khai hai
module và các test mới với tệp khung rỗng cho tới khi ba preset dựng được và `layers` xanh; lập
lịch lệnh nặng.

Bước 1b, sau khi A, B, C xong:

- `tests/protocol_fuzz_tests.cpp`, `tests/fuzz/*.cpp`, `TOOLS/server/fuzz_protocol.py` (mục 3.8).
- `tests/wire_loop_tests.cpp`: ghép hai module qua loopback thật. Bên gửi mã hoá mọi mẫu của
  `protocol_samples.hpp`, đẩy qua `TcpStream` từng mẩu nhỏ (1, 7, 4.096 byte); bên nhận đưa vào
  kênh, lấy khung, giải mã, so với giá trị gốc. Kèm ca gửi một khung khai thân quá trần: bên nhận
  báo `kBodyTooLarge` khi mới có 8 byte đầu, không chờ thân.
- `tests/bench/protocol_bench.cpp` và `tests/bench/net_bench.cpp`: hai exe đo, không vào ctest
  (mục 7, Đ1 tới Đ3). In một dòng TSV mỗi lượt.
- Đổi glob thành danh sách tường minh; dựng và chạy ba preset; chạy đủ mục 7.

Bước 5: ghi `KET-QUA.md`.

### A: tầng byte, khung, kênh

`SRC/protocol/wire.hpp`, `wire.cpp`, `channel.hpp`, `channel.cpp` và tệp phụ nếu cần (kiểm UTF-8),
`tests/protocol_tests.cpp`. Test đỏ trước. Phải có: byte mong đợi viết tay cho từng kiểu sơ cấp ở
giá trị biên (0, lớn nhất, âm nhỏ nhất, -1, -0.0F, chữ nhiều byte dài đúng trần); mỗi giá trị của
`WireError` có ít nhất một ca sinh ra nó ở chiều đọc, và ở chiều ghi nếu chiều ghi sinh được; bộ ca
UTF-8 sai (mã hoá dài thừa hai và ba byte, nửa cặp thay thế, quá U+10FFFF, byte nối lẻ, cụt giữa
ký tự, byte 0); `peek_frame` với mọi độ dài đầu vào từ 0 tới 8; kênh nhận từng byte một vẫn ra đủ
khung; hai trần của kênh.

### B: `net`

`SRC/net/**`, `tests/net_tests.cpp`. Test đỏ trước, trên loopback thật, cổng 0. Phải có: `accept`
trả đúng địa chỉ và cổng của bên nối; nối tới cổng không ai nghe báo lỗi trong hạn; bên kia đóng
là `kClosed`, bên kia huỷ là `kReset`; gửi 8 MiB qua một luồng khi bên nhận đọc chậm: lời gọi gửi
trả 0 ít nhất một lần, cuối cùng bên nhận có đủ 8 MiB với cùng mã băm; 200 kết nối cùng lúc đều
được nhận; `PollSet` thêm, bớt, bật tắt ghi; tập rỗng chờ hết hạn không lỗi; đọc `Endpoint` từ chữ
đúng và sai (thiếu cổng, cổng 0 khi không cho phép, cổng quá 65535, tên máy, IPv6).

### C: danh mục và công cụ sinh

`SRC/protocol/catalog/*.tsv`, `TOOLS/server/gen_protocol.py` và các tệp `protocol_*.py`,
`TOOLS/server/test_gen_protocol.py`, bốn tệp sinh của mục 3.6, `tests/protocol_catalog_tests.cpp`.
Trong lúc A chưa xong, C dựng mã sinh với chính `hop-dong/wire.hpp`.

- `test_gen_protocol.py`: một test cho mỗi luật G1 tới G11; tất định (hai lần sinh cùng mã băm);
  `--check` thoát 1 khi sửa một ô; và một **danh mục thử** nằm trong test, không phải danh mục
  thật, dùng đủ mọi kiểu của mục 3.2 kể cả `list` của record và `optional` của enum, để công cụ
  được kiểm trên mọi kiểu dù danh mục thật mới có 19 tin.
- `tests/protocol_catalog_tests.cpp`: mọi mẫu mã hoá ra đúng byte của Python và giải mã về đúng giá
  trị; cắt thân của mọi mẫu ở mọi độ dài ngắn hơn đều ra lỗi, không ca nào thành công; mọi mẫu thêm
  một byte ra `kTrailingBytes`; tin của cổng kia và tin sai chiều ra `kUnknownKind`; byte mẫu
  `Hello` của Dev ở mục 2 giải mã ra phiên bản 1, nền tảng 2, bản dựng `0x01020304` và mã hoá lại
  trùng từng byte.

## 5. Ranh giới

- Chỉ ghi trong `F:\tl 2026\THIENLONG\build\p2-dot-2`. Không ghi, không dựng, không chạy lệnh nào
  có thư mục làm việc ở cây chính hay ở worktree khác. `G:\TLBB\Dev` chỉ đọc.
- Được tạo mới: các thư mục và tệp nêu ở mục 3 và mục 4, `tests/fuzz/`, `tests/bench/`,
  `docs/PROTOCOL-TIN.md`, và mọi thứ dưới `docs/giao-viec/P2-DOT-2/` trừ `DE-BAI.md` và
  `hop-dong/`.
- Được sửa bằng cách chỉ thêm dòng, chỉ L: `CMakeLists.txt`, `cmake/GameLayers.cmake`. So với bản
  chép ở `moc/`, không dòng cũ nào bị xoá hay đổi.
- Không sửa: mọi module có sẵn của `SRC/` (thiếu gì ở `core` thì viết trong module mới và báo),
  mọi test có sẵn, `AGENTS.md`, `docs/*.md` có sẵn, `SERVER/`, `vcpkg.json`, `CMakePresets.json`,
  `.clang-format`, `.clang-tidy`, các công cụ có sẵn của `TOOLS/`.
- Không mở cổng nào ngoài `127.0.0.1`. Không để lại tiến trình nào sau khi test xong.
- Không mở, không in, không chép `SERVER/config/secrets.local.toml` và `Server\Config\Account.txt`.
- Git chỉ dùng lệnh đọc. Không commit, không đổi nhánh, không `stash`, `reset`, `checkout`,
  `restore`, `clean`, `worktree`.
- Thứ sinh ra khi dựng và đo nằm dưới `build/` của worktree. Trước khi báo xong, L xoá
  `build/p2-a`, `build/p2-b`, `build/p2-c`, `build/p2-fuzz` (giữ ba cây preset) và liệt kê dung
  lượng đã giải phóng.

## 6. Các bước

0 (L), 1 (A, B, C song song), 1b (L tích hợp), 2 (R review), 3 (đối chất chéo: A xem C, C xem B, B
xem A), 4 (sửa, rồi R phán quyết trên mã cuối), 5 (L ghi kết quả).

Bước 2, R review trong phiên mới, đọc trọn mã, kể cả mã của L và mã sinh. Ngoài việc đọc, R tự tay
làm các phép thử sau và ghi output:

- Bộ dò có răng (mục 3.8).
- Thử phá bộ giải mã bằng tay: mười khung tự soạn không có trong test (độ dài `text` khai 65.535,
  `list` khai 65.535 phần tử với thân rỗng, enum 0, `bool` 2, `optional` 2, thân 0 byte cho tin có
  trường, mã tin 0, cờ 1, thân khai `0xFFFFFFFF`, chuỗi kết thúc giữa ký tự ba byte). Mỗi khung phải
  ra lỗi đúng tên, không cấp phát theo số khai.
- Thử phá công cụ: năm bảng sai không trùng ca nào của G1 tới G11.
- So 19 tin với `protocol.hpp` của Dev từng trường: bảng `tin, trường, kiểu Dev, kiểu của ta, trần
  Dev, trần của ta, dòng của Dev`.
- Tìm `sleep_for`, `Sleep(`, `this_thread` trong `tests/`: các tệp mới phải ra 0 dòng.
- Chạy `net_tests` hai mươi lần liền (`ctest --repeat until-fail:20`): 20 lần xanh.

## 7. Tiêu chí đạt

Lệnh chạy ở gốc worktree. Preset MSVC chạy trong `dev.bat` như `AGENTS.md` mục 3.

| Mã | Lệnh hoặc phép kiểm | Đạt khi |
|---|---|---|
| T1 | `python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"` | xanh; 216 test cũ còn đủ, số bỏ qua không quá 8; test mới của `test_gen_protocol.py` không bỏ qua ca nào |
| T2 | `python -B -W error TOOLS/server/lint_py.py` | thoát 0 |
| T3 | `gen_protocol.py --check`; rồi `--out` vào hai thư mục dưới `build/` và so SHA-256 từng tệp | thoát 0; hai cây trùng từng byte |
| T4 | chép `SRC/protocol/catalog` sang `build/`, sửa một ô `limit`, chạy `--check` trên bản chép | thoát 1, in đúng tên các tệp sinh bị cũ |
| T5 | ba preset: cấu hình, dựng mọi target và `header_check`, `ctest --preset <p>` | 0 cảnh báo; test cũ vẫn xanh đủ số nền (43 ở `msvc-release` và `clang-asan`, 37 ở `gcc-debug`); sáu test mới xanh ở cả ba preset: `protocol_tests`, `protocol_catalog_tests`, `protocol_fuzz_tests`, `net_tests`, `wire_loop_tests`, `protocol_catalog_fresh` |
| T6 | `check.py` trên mọi tệp C++ mới, kể cả tệp sinh, `tests/fuzz/`, `tests/bench/` | 0 lỗi |
| T7 | bảng lỗi: mỗi giá trị `WireError` và mỗi lỗi của kênh ứng với tên ca test sinh ra nó | đủ mười giá trị ở chiều đọc; không ô trống không lý do |
| T8 | ca cắt thân ở mọi độ dài và ca thêm một byte, trên mọi mẫu | 0 ca cắt nào giải mã thành công; báo cáo ghi tổng số ca đã chạy |
| T9 | byte mẫu `Hello` của Dev | giải mã đúng ba giá trị, mã hoá lại trùng 15 byte |
| T10 | `protocol_fuzz_tests` ở ba preset | xanh; báo số vòng và số giây của từng preset; ở `msvc-release` và `gcc-debug` đủ 200.000 vòng mỗi đích |
| T11 | `python -B TOOLS/server/fuzz_protocol.py --runs 1000000 --seed 20261008` | năm đích đều `Done 1000000 runs`, thoát 0; `so-do/fuzz.tsv` đủ năm dòng |
| T12 | bộ dò có răng (R) | bản chép bị bỏ phép kiểm biên thoát khác 0 trong một triệu vòng; dán dòng `ERROR` của ASan |
| T13 | `ctest --test-dir build/msvc-release -R "^net_tests$" --repeat until-fail:20`, và cùng lệnh với `wire_loop_tests` | 20 lần xanh mỗi test |
| T14 | hai lệnh NDK của mục 2 trên `SRC/net/socket_posix.cpp` | cả hai thoát 0 |
| T15 | tìm header mạng của hệ điều hành (`winsock2.h`, `ws2tcpip.h`, `sys/socket.h`, `poll.h`, `netinet/`, `arpa/`) trong `SRC/` và `tests/` | chỉ có ở `SRC/net/socket_win32.cpp` và `SRC/net/socket_posix.cpp` |
| T16 | `wc -l` các tệp `.cpp`, `.hpp`, `.py` viết tay của đợt | không tệp `.cpp` hay `.py` nào quá 500 dòng |
| T17 | bảng 19 tin so với Dev (R) | 0 trường lệch không có lý do ghi ở cột `note` |
| T18 | `git status --short` so với `moc/git-status.txt`; `diff` hai tệp CMake với bản ở `moc/`; tìm bí mật | tệp mới chỉ ở chỗ được phép; hai tệp chỉ thêm dòng; không có nội dung của hai tệp cấm |

Số đo, đều ở `msvc-release`, mỗi phép năm lượt, log gốc ở `docs/giao-viec/P2-DOT-2/so-do/`:

| Mã | Đại lượng | Cách đo | Ngưỡng |
|---|---|---|---|
| Đ1 | mã hoá và giải mã, tin mỗi giây | `protocol_bench`: mọi mẫu của danh mục, lặp cho đủ ít nhất một giây mỗi chiều | không có ngưỡng tuyệt đối; số Claude đo lại lệch quá 30% trung vị của bạn thì báo cáo bị trả |
| Đ2 | khứ hồi một khung thân 16 byte qua loopback, 10.000 lần: p50, p99, lớn nhất, micro giây | `net_bench`: hai đầu trong một tiến trình, hai luồng, chờ bằng `PollSet` | p99 dưới 20.000 micro giây ở cả năm lượt (trễ 200 ms kiểu Nagle của Dev sẽ lộ ở đây); lệch đo lại như Đ1 |
| Đ3 | thông lượng một chiều, khung thân 65.536 byte, 2.000 khung: MiB mỗi giây | `net_bench` | như Đ1 |
| Đ4 | thời gian và đỉnh bộ nhớ của `gen_protocol.py` | năm lượt, đo bằng `time.perf_counter` và `tracemalloc` hoặc công cụ ngoài | như Đ1 |
| Đ5 | vòng mỗi giây của từng đích libFuzzer | lấy từ T11 | chỉ báo số |
| Đ6 | số dòng: từng tệp viết tay, từng tệp sinh; số tin, số trường, số mẫu, số ca test của từng tệp test | đếm bằng lệnh, ghi lệnh | chỉ báo số |

Tiêu chí không đạt thì ghi không đạt kèm output. Không sửa kỳ vọng của test, không hạ ngưỡng,
không bỏ lượt đo xấu: lượt nào đã chạy thì log của nó nằm trong `so-do/`.

## 8. Báo cáo

Mọi tệp ở `docs/giao-viec/P2-DOT-2/`, cùng tên và hình dạng như các đợt trước: `BAO-CAO-A.md`,
`BAO-CAO-B.md`, `BAO-CAO-C.md`, `REVIEW.md`, `DOI-CHAT-A.md`, `DOI-CHAT-B.md`, `DOI-CHAT-C.md`,
`NGUON.md`, `KET-QUA.md`, thư mục `moc/` và `so-do/`.

`KET-QUA.md` mở đầu bằng hai bảng, không có câu dẫn:

1. Bảng tiêu chí: `mã`, `đạt hay không`, `lệnh đã chạy`, `dòng output quyết định`, `tệp log`.
2. Bảng số đo: `mã`, `đại lượng`, `lệnh`, `số lượt`, `trung vị`, `nhỏ nhất`, `lớn nhất`, `tệp log`.
   Kèm một dòng mô tả điều kiện đo: commit (`git rev-parse HEAD`), preset, CPU, có hay không có
   bản dựng khác chạy cùng lúc.

Luật của con số: không số nào trong báo cáo mà không có tệp log trong `so-do/` chứa đúng số đó;
số làm tròn thì ghi cả số gốc; "nhanh", "ổn", "không đáng kể" không phải là kết quả. Thứ chưa đo
ghi "chưa đo" kèm lý do, không ước lượng.

Riêng từng vai:

- A: bảng `WireError` và lỗi kênh ứng với ca test; danh sách byte mẫu viết tay; chỗ khác Dev.
- B: tệp nào port từ tệp nào, khác gốc ở đâu; từng bẫy của Dev ở mục 2 ứng với dòng mã và ca test
  nào; thứ chưa chạy (POSIX).
- C: số tin, trường, enum, record đếm trên tệp của Dev và trên bảng của ta; từng luật G ứng với
  test; cỡ thân lớn nhất tính được của từng tin; output của T3 và T4.
- L: những dòng đã thêm vào hai tệp CMake; lịch lệnh nặng đã chạy (giờ bắt đầu, giờ xong, vai);
  output nguyên văn của T11.
- R: output của từng phép thử ở mục 6; danh sách finding theo mức nặng; phán quyết trên mã cuối.
- Mỗi vai: lần chạy test đỏ, output `check.py`, và bốn mục Đã kiểm, Chưa kiểm, Giả định, Lệch quy
  tắc. Mỗi báo cáo vai được cập nhật sau lần sửa cuối.

## 9. Ngoài phạm vi

Để các đợt sau: `secure`, `ipc`, `metrics`; cho bảy exe mở cổng; trần kết nối mỗi IP, hạn bắt tay,
trần tin mỗi giây, danh sách chặn của `gate`; sáu nhóm tin còn lại của Dev (03, 04, 06, 07, 08, 09);
kiểu `variant` và `f64`; `link` phía client; IPv6; ghép libFuzzer vào CMake; TSan (máy này không
có); commit.

Thấy vấn đề ngoài phạm vi thì ghi vào báo cáo, không tự sửa.
