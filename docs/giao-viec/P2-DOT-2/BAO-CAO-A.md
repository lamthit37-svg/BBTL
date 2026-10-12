# Báo cáo vai A: tầng byte, khung và kênh (P2 đợt 2)

Tệp của A: `SRC/protocol/wire.hpp`, `SRC/protocol/wire.cpp`, `SRC/protocol/channel.hpp`,
`SRC/protocol/channel.cpp`, `tests/protocol_tests.cpp`. Dựng trong `build/p2-a` bằng preset
`clang-asan`, cây riêng của A.

## 1. Kết quả

| Việc | Lệnh | Số lần | Kết quả | Log |
|---|---|---|---|---|
| Test đỏ | `ctest --test-dir build/p2-a -R ^protocol_tests$ --output-on-failure` với `wire.cpp`, `channel.cpp` là bản rỗng trả giá trị không | 1 | 22/22 ca hỏng, 150 dòng kỳ vọng hỏng, mã thoát `0xc0000409` | `so-do/a-protocol-do-truoc.log` |
| Test xanh, chạy lặp | `ctest --test-dir build/p2-a -R ^protocol_tests$ --repeat until-fail:20 --output-on-failure` | 20 | 20 lần `Passed`, mã thoát 0 | `so-do/a-lap-20.log` |
| `check.py` đầy đủ, có clang-tidy, dưới `NANG.lock` | `python %USERPROFILE%/.claude/cpp23/tools/check.py` trên 5 tệp | 1 (lần 3) | `5 tệp, 0 lỗi.`, 01:53:05–01:53:09 | `so-do/a-check-day-du.log` |
| Sau comment G6 cạnh `Reader::count`: chạy lặp | như dòng chạy lặp ở trên | 20 | 20 lần `Passed`, mã thoát 0 | `so-do/a-g6-lap-20.log` |
| Sau comment G6: `check.py` đầy đủ | `check.py` trên `wire.hpp`, `wire.cpp` | 1 | `2 tệp, 0 lỗi.`, mã thoát 0 | `so-do/a-g6-check.log` |

Hai lần chạy trước vẫn giữ log, không xoá:

- `so-do/a-check-day-du-lan1.log` (01:49:34–01:49:38): kết quả `5 tệp, 3 lỗi.`, lỗi đều do clang-tidy. Các nhóm lỗi
  là `misc-include-cleaner`, `readability-avoid-return-with-void-value`,
  `readability-function-cognitive-complexity` (hàm `classify`), `bugprone-easily-swappable-parameters`
  (`Writer::put`), `modernize-use-auto` và `bugprone-unchecked-optional-access` (trong test). Đã sửa
  hết.
- `so-do/a-check-day-du-lan2.log` (01:51:34–01:51:38): `5 tệp, 0 lỗi.` Sau đó mình thêm ca đọc
  `kUnknownKind` vào test, nên đã chạy lại lần 3 trên mã cuối.
- `so-do/a-lap-20-lan1.log`: 20 lần xanh trên mã trước khi thêm ca đó.

Output nguyên văn `check.py` lần 3, phần kết quả:

```
SRC\protocol\wire.hpp      ✓ clang-format ✓ độ lồng <= 1 (PH-01) ✓ biên dịch g14 ✓ biên dịch c20 ✓ clang-tidy
SRC\protocol\wire.cpp      (như trên, đủ năm dấu ✓)
SRC\protocol\channel.hpp   (như trên)
SRC\protocol\channel.cpp   (như trên)
tests\protocol_tests.cpp   (như trên)
5 tệp, 0 lỗi.
```

Trong log, mỗi phép kiểm nằm trên một dòng riêng. Trình dịch: g14 là gcc 16.2.0, c20 là clang
23.1.2. clang-format và clang-tidy đều bản 23.1.2.

Số dòng của tệp viết tay (đếm bằng `(Get-Content <tệp> -Encoding UTF8).Count`, log ở
`so-do/a-t16-dong.log`): `wire.hpp` 124, `wire.cpp` 359 (sau comment G6, dòng cuối của log), `channel.hpp` 115, `channel.cpp` 110,
`protocol_tests.cpp` 500. Không tệp `.cpp` nào quá 500 dòng.

## 2. Bảng lỗi (T7)

Ca nào cũng nằm trong `tests/protocol_tests.cpp`.

| Lỗi | Chiều đọc | Chiều ghi |
|---|---|---|
| `kTruncated` | `truncated_is_sticky`: u16 trên 1 byte, text khai 5 byte mà thân có 1, u64 trên thân rỗng. `count_beyond_body_is_truncated`: count khai 0xFFFF trên thân còn 1 byte | Không áp dụng: Writer nối vào vector, không có chỗ để thiếu byte |
| `kTrailingBytes` | `trailing_bytes` | Không áp dụng: chỉ `Reader::finish` có khái niệm thừa byte |
| `kTooLong` | `too_long_both_ways`: text 5 byte với trần 4, count 11 với trần 10 | `too_long_both_ways`: text quá trần, text 65.536 byte quá 65.535, count quá trần |
| `kBadText` | `utf8_rejected_both_ways`: 16 chuỗi trong `kBadUtf8` | `utf8_rejected_both_ways`: cùng 16 chuỗi |
| `kNonFinite` | `non_finite_both_ways`: bốn mẫu `7FC00000`, `7F800000`, `FF800000`, `7F800001` | `non_finite_both_ways`: NaN và âm vô cực |
| `kBadEnum` | `bad_bool_is_bad_enum`: bool byte `02` và `FF` | Không có đường ghi trong tầng byte: `boolean(bool)` chỉ ghi 0 hay 1. enum và optional lạ là việc của mã sinh (vai C) |
| `kBodyTooLarge` | `body_too_large_both_ways`: peek thân 4.097 với trần 4.096, trần truyền vào lớn hơn 65.536 bị kẹp về 65.536, thân khai 0xFFFFFFFF. `peek_every_header_length`: 4.097 | `body_too_large_both_ways`: thân 65.537 byte. Thân đúng 65.536 byte thì qua |
| `kBadFlags` | `peek_every_header_length`: cờ 1 và cờ 0x8000 | Không áp dụng: Writer luôn ghi cờ 0, `header_golden` kiểm byte cờ |
| `kUnknownKind` | `writer_failure_is_sticky`: `Reader::fail` rồi `finish` trả đúng lỗi, lần đọc sau trả 0 | `writer_failure_is_sticky`: `Writer::fail` rồi `finish` trả lỗi và cắt `out` về cỡ cũ |
| `kOutOfRange` | `writer_failure_is_sticky`: như trên | `writer_failure_is_sticky`: lỗi đầu tiên được giữ, lỗi sau (`kBadEnum`) không đè, sau lỗi không ghi thêm byte nào |

Tầng byte không tự sinh `kUnknownKind` và `kOutOfRange`. Hai lỗi này đến từ mã sinh của danh mục tin
(vai C) qua `fail()`. Vì vậy ca của A chỉ kiểm đường đi của chúng qua `fail` và `finish` ở cả hai
chiều. Ca sinh thật nằm ở test của C.

| Lỗi kênh | Ca |
|---|---|
| `kInboxFull` | `channel_inbox_limit`: đúng trần 24 byte thì nhận, thêm 1 byte là lỗi, không giữ thêm byte nào, `next` sau đó cũng trả lỗi. Một mẩu 25 byte trên kênh mới cũng không giữ byte nào |
| `kOutboxFull` | `channel_outbox_limit`: hai khung 10 byte vừa trần 20, khung thứ ba bị từ chối, hộp gửi giữ nguyên 20 byte. Gửi bớt 10 thì thêm được |
| `kBadFlags` (bọc) | `channel_broken_frame_is_final`: lỗi lặp lại ở `next` lần hai và ở `receive` sau đó |
| `kBodyTooLarge` (bọc) | `channel_broken_frame_is_final`: kênh client, thân khai 4.097 |
| Tám giá trị bọc còn lại | `channel_error_wraps_wire`: `wrap` rồi `unwrap` ra đúng giá trị, câu `describe` trùng với WireError, cho đủ mười giá trị. Kênh chỉ gọi `peek_frame`, mà `peek_frame` chỉ trả `kBadFlags` và `kBodyTooLarge`, nên tám giá trị kia không có đường sinh trong kênh. `kInboxFull` và `kOutboxFull` không mở ra WireError |

## 3. Byte mẫu viết tay

Mọi byte dưới đây đều được gõ tay trong test, không sinh từ mã đang được kiểm. Thứ tự là little-endian.

- `header_golden`: `u16(0x0102)`, kind `0x8105`, nối sau byte `77` đã có sẵn:
  `77 02 00 00 00 05 81 00 00 02 01`. Thân rỗng, kind `0x0102`: `00 00 00 00 02 01 00 00`.
- `unsigned_golden`: u8 0 và FF, u16 0 và FFFF, u32 `01020304` và `FFFFFFFF`, u64
  `0102030405060708` và giá trị lớn nhất:
  `00 FF 00 00 FF FF 04 03 02 01 FF FF FF FF 08 07 06 05 04 03 02 01 FF FF FF FF FF FF FF FF`.
- `signed_golden`: i8 −128, −1, 127, i16 nhỏ nhất và −1, i32 nhỏ nhất và 0, i64 nhỏ nhất và −1:
  `80 FF 7F 00 80 FF FF 00 00 00 80 00 00 00 00 00 00 00 00 00 00 00 80 FF FF FF FF FF FF FF FF`.
- `float_bool_golden`: f32 0, −0, 1, lớn nhất, nhỏ nhất, rồi bool false và true:
  `00 00 00 00 00 00 00 80 00 00 80 3F FF FF 7F 7F FF FF 7F FF 00 01`.
- `text_bytes_count_golden`: text rỗng, text "Aé" (`00 00`, `03 00 41 C3 A9`), text 30 byte gồm
  mười lần "ệ" (`1E 00` rồi mười lần `E1 BB 87`), bytes `01 FE 03`, count 0 (`00 00`) và count
  0xFFFF (`FF FF`).
- `peek_every_header_length`: khung đủ `02 00 00 00 02 01 00 00 AA BB`, cờ 1
  `00 00 00 00 02 01 01 00`, cờ 0x8000 `00 00 00 00 02 01 00 80`, thân 4.097
  `01 10 00 00 02 01 00 00`. Mọi độ dài 0 tới 7 của ba đầu khung này đều trả "chưa có khung", không
  trả lỗi.
- `body_too_large_both_ways`: `01 10 00 00 01 01 00 00` (4.097), `01 00 01 00 01 01 00 00`
  (65.537), `FF FF FF FF 01 01 00 00`.
- `dev_hello_sample` (T9): byte mẫu `Hello` của Dev
  `07 00 00 00 01 01 00 00 01 00 02 04 03 02 01`. Giải mã ra phiên bản 1, nền tảng 2, bản dựng
  `0x01020304`. Mã hoá lại ra trùng 15 byte.
- UTF-8 sai (16 chuỗi): `C0 80`, `C1 BF` (dài thừa 2 byte), `E0 80 80`, `E0 9F BF` (dài thừa 3
  byte), `ED A0 80`, `ED BF BF` (nửa cặp thay thế), `F4 90 80 80` (vượt U+10FFFF), `F5 80 80 80`,
  `80` (byte tiếp nối đứng đầu), `61 BF`, `E1 BB` và `F0 9F 98` (bị cắt), `61 00 62` và `00` (byte
  0), `F0 80 80 80` (dài thừa 4 byte), `C3 A9 FF`.
- UTF-8 đúng ở biên (12 chuỗi): `61`, `7F`, `C2 80`, `DF BF`, `E0 A0 80`, `ED 9F BF`, `EE 80 80`,
  `EF BF BF`, `F0 90 80 80`, `F0 9F 98 80`, `F4 8F BF BF`, "Thiên Long".
- NaN và vô cực đọc vào: `00 00 C0 7F`, `00 00 80 7F`, `00 00 80 FF`, `01 00 80 7F`.

## 4. Khác Dev

Mốc Dev là `G:\TLBB\Dev` @e0d89a6 (cùng mốc B ghi trong `NGUON.md`). Các dòng `Nguồn:` và
`Khác gốc:` ở đầu từng tệp ghi cùng nội dung.

- Tên: namespace `game::protocol`, lỗi đặt tên kiểu kCamelCase.
- Đọc: mỗi kiểu có một hàm đọc trả giá trị, thay cho `field(T&)`. Có thêm số có dấu, đi qua kiểu
  không dấu cùng cỡ.
- Không có `require`. Mã sinh tự gọi `fail(kOutOfRange)`.
- `count` thay `begin_list`. Ngoài trần, nó còn từ chối số phần tử lớn hơn số byte còn lại, trả
  `kTruncated`, để không cấp phát theo con số bên kia khai.
- Writer: sau lỗi đầu tiên không ghi thêm byte nào. `kBodyTooLarge` được báo ngay ở lần nối làm
  thân vượt trần, không đợi tới `finish`. `finish` có lỗi thì cắt `out` về cỡ lúc tạo.
- UTF-8 được kiểm trên vùng byte bằng bảng dải byte đầu (theo bảng 3-7 của chuẩn Unicode). Byte 0
  là byte đầu sai ngay trong bảng.
- Kênh không phải template theo cặp tin, mà nhận và trả khung thô. Trần là tham số lúc tạo.
- Hộp gửi từ chối khung làm vượt trần trước khi thêm. Dev kiểm trước khi thêm nên vượt được một
  khung.
- Hộp nhận đầy cũng làm kênh hỏng hẳn.
- Lỗi kênh là một enum riêng, bọc được `WireError`: mười giá trị đầu trùng số, thêm `kInboxFull`
  và `kOutboxFull`.
- Chữ ký công khai của `wire.hpp` trùng hợp đồng `hop-dong/wire.hpp`. Chỉ phần `private` khác:
  `put` thành template `template <std::unsigned_integral Value> void put(Value value)` (sửa lỗi
  tidy về tham số dễ đảo), nên header có thêm `#include <concepts>`.

## 5. Đã kiểm

- 22 ca của `protocol_tests` đỏ trên bản rỗng, rồi xanh 20 lần liền trên mã cuối, preset
  `clang-asan` trong `build/p2-a`.
- `check.py` đầy đủ trên 5 tệp: clang-format, PH-01, biên dịch bằng gcc 16.2.0 và clang 23.1.2,
  clang-tidy. Kết quả 0 lỗi.
- T7: đủ mười giá trị `WireError` ở chiều đọc, cùng hai lỗi riêng của kênh. T9: mẫu `Hello`.
- `peek_frame` ở mọi độ dài đầu khung 0 tới 7, ở 9 byte khi thân chưa đủ, và trên khung đủ.
- Kênh nhận từng byte một qua ba khung liền nhau, trong đó có một khung thân rỗng.
- `Reader::count` trả `kTruncated` khi số phần tử khai lớn hơn số byte còn lại. Phép kiểm này dựa
  vào bất biến "mỗi phần tử chiếm ít nhất một byte trên dây". C cho biết luật G không cấm record
  không trường, nên một `list` của record như vậy sẽ bị từ chối oan. L chốt cách (a): giữ phép kiểm,
  luật G6 của `gen_protocol.py` cấm phần tử `list` mã hoá ra 0 byte (C làm, ca thử ở test của C).
  Comment cạnh `Reader::count` trong `wire.cpp` và `wire.hpp` đã ghi rõ bất biến này. Dựng lại,
  chạy lặp và `check.py` sau thay đổi đều xanh (bảng ở mục 1).

## 6. Chưa kiểm

- Preset `msvc-release` và `gcc-debug`, cùng `header_check`: A chưa chạy. Ba cây preset là việc của
  L và R ở bước 1b, theo phân công của L.
- Fuzz (`protocol_fuzz_tests`, `fuzz_protocol.py`) và đo `protocol_bench`: thuộc L. A chưa chạy.
- T8 (cắt thân ở mọi độ dài trên mọi mẫu của danh mục): cần mẫu của C. A chỉ cắt đầu khung.
- Ca sinh thật của `kUnknownKind`, `kOutOfRange` và enum hay optional lạ (`kBadEnum`): ở mã sinh
  và test của C.

## 7. Giả định

- Byte 0 bị cấm trong text, theo đề.
- Đọc NaN hay vô cực thì trả 0 kèm `kNonFinite`. Giá trị −0 được giữ nguyên dấu.
- Hộp nhận tràn được coi là lỗi hỏng hẳn: luồng byte đã mất một đoạn, nên không đọc tiếp được.

## 8. Lệch quy tắc

- Log đỏ được chạy trên tệp test bản cũ, dài hơn bản hiện tại,, nên số dòng trong log không khớp tệp hiện tại.
  Sau bước đỏ, test được rút gọn để qua PH-01 và trần 500 dòng: gộp các kỳ vọng liền nhau, đưa
  lambda ra khỏi vòng lặp. Ngoài ra có ba thay đổi về nội dung:
  1. Ở `utf8_accepted_both_ways`, chiều ghi giờ chỉ kiểm là không có lỗi, không còn so byte đã ghi.
     Byte của text vẫn được so ở `text_bytes_count_golden`.
  2. Thêm ca đọc `kUnknownKind` vào `writer_failure_is_sticky`, để đủ mười giá trị ở chiều đọc
     (T7).
  3. Đổi `whole && (*frame)->...` thành hàm `is_frame`, để clang-tidy chấp nhận.
- `so-do/a-check-day-du-lan1.log` lẫn mã hoá: phần đầu là UTF-8, phần output là UTF-16 do PowerShell
  5 ghi bằng `*>>`. Nội dung vẫn đủ. Các log sau đều ghi UTF-8.
- Trước lần check thứ hai, công cụ chép tệp từ máy của A ghi bốn tệp nguồn vào
  `C:\Users\myhea\SRC\protocol\` và `C:\Users\myhea\tests\`, chứ không vào worktree. Đường dẫn
  tương đối được tính từ thư mục người dùng. Mình đã chuyển ngay cả bốn tệp vào worktree và
  xoá hai thư mục `SRC` và `tests` mới tạo ở đó. Đã kiểm trước khi xoá: hai thư mục chỉ chứa bốn tệp
  ấy. Từ lúc đó mình chỉ ghi bằng lệnh có đường dẫn tuyệt đối trong worktree.
- `so-do/a-t16-dong.log` được nối thêm ba dòng lúc 02:22:30, sau khi thêm comment G6. Đó là lần đếm lại số dòng của `wire.hpp` và `wire.cpp`. Các dòng cũ giữ nguyên, không sửa. Việc này làm trước khi L dặn không sửa log đã chạy; từ đó A chỉ ghi log mới vào tệp riêng.
