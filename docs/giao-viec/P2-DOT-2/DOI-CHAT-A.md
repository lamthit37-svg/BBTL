# Đối chất vai A

Bước 3 của P2 đợt 2 (DE-BAI mục 6, dòng 416): A xét chéo phần của C (danh mục tin và công cụ sinh).
Bước này chỉ đọc. A không sửa mã, bảng hay log của vai nào. Ngoài tệp này, A chỉ thêm năm
log `so-do/a-doi-chat-*.log` và ba dòng khai trong `build/lich-nang.tsv`. Giờ ghi theo giờ Bangkok. Mọi SHA-256 dưới đây đo lúc 09:57 hôm nay.

## Trả lời review

Lúc viết tệp này chưa có `REVIEW.md` của đợt và chưa có `DOI-CHAT-B.md`. Phần trả lời review và
trả lời xét chéo của B về A sẽ thêm vào đây khi có hai tệp đó.

## Xét chéo C

### Phạm vi đã đọc

- Đề: `DE-BAI.md` mục 2, 3.1, 3.2 (dòng 137), 3.5 (dòng 197), 3.6 (dòng 238), 4 phần C (dòng 378),
  5 (dòng 394), 6 (dòng 414), 7 (dòng 433), 8 (dòng 472). Hợp đồng `hop-dong/wire.hpp`, so với
  `SRC/protocol/wire.hpp` bằng `git diff --no-index`: phần công khai trùng, chỉ khác comment và phần
  `private`.
- Bảng: `SRC/protocol/catalog/groups.tsv`, `messages.tsv`, `fields.tsv`, `enums.tsv`, đọc trọn.
- Công cụ: `gen_protocol.py` (chỉ phần gọi), `protocol_model.py`, `protocol_rules.py`,
  `protocol_cxx.py`, `protocol_cpp_src.py`, `protocol_wire.py` đọc trọn; `protocol_samples.py`,
  `protocol_cpp_hpp.py`, `protocol_doc.py`, `protocol_tsv.py` chỉ đọc lướt.
- Test: `TOOLS/server/test_gen_protocol.py` và `tests/protocol_catalog_tests.cpp`, đọc trọn.
- Tệp sinh: `SRC/protocol/messages.hpp` và `messages.cpp` đọc trọn. `tests/protocol_samples.hpp`: đầu
  tệp, cuối tệp, các mẫu thời lượng, và đếm khung mẫu bằng regex. `docs/PROTOCOL-TIN.md`: 40 dòng đầu.
- Dev, chỉ đọc: `G:\TLBB\Dev\src\protocol\protocol.hpp`. Đọc dòng 1–347, 470–558, các struct của 19 tin,
  và dòng 1113–1129 (variant theo cổng).
- Báo cáo và log của C: `BAO-CAO-C.md` đọc trọn; `NGUON.md`; `so-do/c-t1-unittest.log`,
  `c-t2-lint.log`, `c-g6-chay-lai.log`, `c-dem-tin.log`, `c-t3.log`, `c-t4.log`, `c-check.log`,
  `c-ctest.log`, `c-t8-mau.log`, `c-d6-dong.log`, `c-d4-gen.log`, `c-probe-blank.log`.

### Lệnh A đã chạy

Trước mỗi lệnh chạy chương trình, A kiểm `build/NANG.lock` bằng `Test-Path`, và lần nào khoá cũng
không có. Theo `build/lich-nang.tsv`, trong lúc A làm có ba phiên giữ khoá: R 09:55:01–09:55:29, L
09:56:01–09:56:22, và 10:01:29–10:01:38 (Build & Test đo lại Đ2, Đ3; dòng lịch ghi vai L). Trong các
khoảng đó A chỉ đọc tệp. Không lệnh nào của A chồng lên một phiên khoá. Mỗi lệnh nhẹ có một
dòng `A	nhẹ: ...` trong `build/lich-nang.tsv`.

| Giờ | Lệnh | Kết quả | Log |
|---|---|---|---|
| 09:58:15–09:58:17 | `python -B TOOLS/server/gen_protocol.py --check` | mã thoát 0 | `so-do/a-doi-chat-t1-t3.log` |
| cùng lượt | `python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"` (T1) | `Ran 240 tests`, `OK (skipped=8)`, mã thoát 0 | như trên |
| cùng lượt | cùng lệnh với `-p test_gen_protocol.py -v` | `Ran 24 tests`, `OK`, không ca nào bỏ qua | như trên |
| cùng lượt | `python -B -W error TOOLS/server/lint_py.py` (T2) | mã thoát 0 | như trên |
| 10:00:21–10:00:22 | `gen_protocol.py --catalog <bản chép có thêm ba dòng> --out build/p2-a/doi-chat/out`, rồi `g++ -std=c++23 -fsyntax-only` trên `messages.cpp` vừa sinh; xoá `build/p2-a/doi-chat` ngay sau đó | gen thoát 0, g++ thoát 1 (X-AC-03) | `so-do/a-doi-chat-trung-ten.log` |
| 10:01:20, 10:01:30 | đếm bằng PowerShell (Get-Content, Select-String, regex), không chạy mã dự án | xem từng mục | `so-do/a-doi-chat-doi-chieu.log`, `so-do/a-doi-chat-doi-chieu-lan2.log` |
| 10:01:57–10:02:01 | `cmake --build build/p2-a --target protocol_catalog_tests`; `ctest --test-dir build/p2-a -R "^protocol_catalog" --output-on-failure` | dựng thoát 0; `100% tests passed out of 2` | `so-do/a-doi-chat-ctest.log` |

Lượt 10:01:20 (`a-doi-chat-doi-chieu.log`) in sai một số: `trường ta: 39`, kèm ba lỗi `Cannot
index into a null array`. Lỗi nằm ở script của A: Logout không có trường, nhưng `@($null).Count`
bằng 1 nên Logout bị tính một trường. Log này để nguyên. Lượt 10:01:30
(`a-doi-chat-doi-chieu-lan2.log`) đếm lại từng chủ và ra 38. Số trường dùng trong tệp này lấy từ
lượt 2.

### Đã kiểm, không thấy lỗi

1. **Danh mục so với Dev.** 19 tin (10 của client, 9 của máy chủ), 1 record, 38 trường, khớp với
   số C báo (`a-doi-chat-doi-chieu-lan2.log`: `tin 19, record 1, tin client (bit 15 tắt) 10, tin
   server 9`; `dòng dữ liệu của fields.tsv: 38`; phía Dev ra
   `số lời gọi io.field/io.text/io.list(self. trong 20 struct: 38 (Logout 0)`). A so từng trường:
   tên, thứ tự, kiểu, trần và dòng Dev (bảng ở `a-doi-chat-doi-chieu.log`). Đủ 38 trường trùng. Mọi
   trần text và list trùng hằng của Dev: `kNameBytes=48`, `kAccountBytes=64`, `kTicketBytes=512`,
   `kPasswordBytes=128`, `kCharacterSlots=8`. Cỡ `bytes` trùng các hằng ở `protocol.hpp:46, 51, 80,
   83`: 16, 204, 32, 32. Mã tin trùng `ClientKind` và `ServerKind` (`protocol.hpp:109–164`). Cổng
   trùng các variant của Dev (`protocol.hpp:1113–1124`): Hello, Welcome, Reject và Goodbye là
   `both`. Giá trị enum trùng (`protocol.hpp:166–227`). Dev có 5 enum, ta có 4, vì `ClientKind` chỉ
   làm kiểu của `Reject.request` (`protocol.hpp:738`). `fields.tsv:37` ghi lý do của chỗ lệch này ở
   cột `note`.
2. **Mã sinh gọi đúng hợp đồng tầng byte.** `messages.cpp` chỉ gọi hàm công khai của `wire.hpp`.
   Enum sai giá trị là `kBadEnum` ở cả hai chiều (`messages.cpp:51–93`). List gọi
   `reader.count(kCharacterListCharactersCount)` rồi mới `reserve`, và dừng vòng đọc khi reader lỗi
   (`messages.cpp:310–317`). Text truyền đúng hằng trần của trường (`messages.cpp:97, 109, 134–141`).
   Mọi bộ giải mã gọi `reader.finish()` qua `checked` (`messages.cpp:340–345`), nên thân còn byte
   là `kTrailingBytes`. `default:` của cả bốn bộ giải mã trả `kUnknownKind`
   (`messages.cpp:493, 508, 518, 529`). Thời lượng âm hay quá cỡ khi ghi là `kOutOfRange`
   (`messages.cpp:20–45`). Không có `throw`. `encode` và `decode_*` có `[[nodiscard]]`
   (`messages.hpp:313–338`). Cách đọc `optional` (`protocol_cpp_src.py:91–107`) dựa vào
   `Reader::boolean`, mà hàm này báo `kBadEnum` khi byte lớn hơn 1 (`wire.cpp:285–287`). Đọc và
   ghi đối xứng theo từng trường.
3. **G6 mới và record rỗng.** Hàm `least_bytes` (`protocol_rules.py:290–306`) đi đệ quy qua record
   và dừng ở record đã gặp. Hàm `check_list_elements` (`protocol_rules.py:309–315`) báo G6 cho phần
   tử 0 byte. `test_g6_types` (`test_gen_protocol.py:173–180`) có cả `list:record:Blank` lẫn
   `list:record:Hollow`, với Hollow chỉ chứa `record:Blank`. `empty_record_functions`
   (`protocol_cpp_src.py:275–282`) sinh `put_blank` và `get_blank`, nhận `const Writer&` và
   `const Reader&`. `test_empty_record_field` xanh trong lượt 09:58.
4. **T3, T4.** Lượt 09:58 có `--check` thoát 0. Bốn tệp sinh có SHA-256 trùng số C báo ở
   `c-g6-chay-lai.log`. Ví dụ `messages.cpp` là `0450a6012ac68d0cbfb198ae5f8537896898773be183359d8e38f7758ac7a04d`.
   Tệp sinh không đổi từ 02:06, nên `c-check.log` (4 tệp, 0 lỗi) vẫn ứng với đúng các byte này.
   Ở T4, việc `messages.cpp` không bị báo cũ là đúng: `.cpp` đọc trần qua hằng
   `kCharacterSummaryNameBytes` (`messages.cpp:97, 109`). A không chạy lại T3 bằng tay với `--out`
   vào hai cây. Phần đó lấy từ `c-t3.log` và từ `test_deterministic`, ca này xanh trong lượt 09:58
   và cũng sinh hai cây `--out` rồi so SHA-256.
5. **T8, T9.** A tự đếm từ `tests/protocol_samples.hpp`: `số mẫu: 57; tổng byte thân = tổng ca cắt:
   2912; ca thêm byte: 57` (`a-doi-chat-doi-chieu.log`). Kết quả khớp `c-t8-mau.log`. Ca cắt đòi
   đúng `kTruncated`, không chỉ đòi "có lỗi" (`protocol_catalog_tests.cpp:74–80`). Ca T9 so đủ 15
   byte, rồi giải mã lại và so cả struct (`protocol_catalog_tests.cpp:118–134`). Lượt 10:01 xanh:
   `protocol_catalog_tests ... Passed`, `protocol_catalog_fresh ... Passed`
   (`a-doi-chat-ctest.log`).
6. **Mẫu lớn nhất chạm trần.** Thân của các mẫu `Max` trùng bảng G9: Login 580, CreateAccount 196,
   SignIn 196, CharacterList 546, CreateCharacter 55. Mẫu `millis64` lớn nhất là
   `9223372036854775807` (`protocol_samples.hpp:312, 371`), đúng như C nêu ở mục Lệch quy tắc 3.
7. **Giới hạn của tệp sinh.** DE-BAI dòng 262 miễn trần 500 dòng cho tệp sinh, nên `messages.cpp`
   533 dòng không phạm luật. Hàm dài nhất là `decode_game_client`, `messages.cpp:482–495`, 14 dòng.
   Không hàm nào quá 2 tham số. Thân có `for` hoặc `switch` chỉ lồng 1 mức.
8. **Bốn mục của báo cáo.** `BAO-CAO-C.md` có Đã kiểm (dòng 182), Chưa kiểm (195), Giả định (208)
   và Lệch quy tắc (219).

### X-AC-01 [vừa] Ba số Đ4 về thời gian trong BAO-CAO-C không có log nào chứa

Chỗ: `BAO-CAO-C.md:159–160`.

Báo cáo ghi trung vị 0,069296, nhỏ nhất 0,063512, lớn nhất 0,076711 cho thời gian chạy cả tiến trình.
Cho phần chạy trong tiến trình, báo cáo ghi 0,004877, 0,004737, 0,005214. Cả hai dòng ghi log là
`so-do/c-d4-gen.log`. Log đó chứa những số khác:

```text
c-d4-gen.log:11: trung vị 0.063233, nhỏ nhất 0.063073, lớn nhất 0.065619
c-d4-gen.log:15: trung vị 0.004532, nhỏ nhất 0.004440, lớn nhất 0.004961
```

A tìm sáu số của báo cáo trong mọi tệp dưới `docs/giao-viec/P2-DOT-2` (đệ quy). Sáu số chỉ có ở
`BAO-CAO-C.md:159` và `:160` (`a-doi-chat-doi-chieu.log`, mục Đ4). Dòng 161 (bộ nhớ: 0,536757,
0,536704, 0,536849) thì khớp log. Dòng 163 lại viết "số trên bảng là số gốc". Như vậy dòng 159–160
phạm luật số liệu của DE-BAI dòng 485. Claude đo lại sẽ so với số không có nguồn.

Đề xuất: ghi lại hai dòng 159–160 đúng theo `c-d4-gen.log`. Nếu số trong báo cáo đến từ một lượt
khác thì đưa log của lượt đó vào `so-do/`. Mục 11 đã nói Đ4 chính thức là số đo lại có khoá, nhưng
không thay được việc mỗi số phải có log.

### X-AC-02 [vừa] NGUON.md không có phần C; bảng chép từ Dev không ghi đủ chỗ khác gốc

Chỗ: `docs/giao-viec/P2-DOT-2/NGUON.md:1–23`. Tệp chỉ có `## Vai B` (dòng 3) và `## Vai A`
(dòng 15) (`a-doi-chat-doi-chieu.log`, mục NGUON.md). Dòng 2 của bốn bảng TSV là
`# source: TLBB Dev src/protocol/protocol.hpp (bản 2026-10, nhóm 01, 02, 05)`.

DE-BAI dòng 214 bảo C chép từng trường từ `protocol.hpp` của Dev. Dòng 131–132 đòi tệp port có
`Nguồn:` và `Khác gốc:`, và đòi danh sách tệp port nằm trong `NGUON.md`. Bốn bảng là bản port đó,
nhưng:

- `NGUON.md` không có dòng nào cho bảng, cho `protocol_catalog_tests.cpp` (byte Hello lấy từ test
  của Dev) hay cho tệp sinh.
- `# source:` ghi "bản 2026-10" mà không ghi mốc. A và B ghi `G:\TLBB\Dev @e0d89a6`
  (`NGUON.md:5, 17`).
- Bảng không có dòng `Khác gốc`. Các chỗ khác gốc sau không nằm ở cột `note` hay ở `NGUON.md`:
  - `Hello.version` mặc định là 0 (`messages.hpp:128`), còn Dev mặc định `kVersion`
    (`protocol.hpp:472`).
  - `Reject.request` mặc định là 0 (`messages.hpp:263`), còn Dev mặc định `ClientKind::Hello`
    (`protocol.hpp:738`).
  - `Welcome.server_time` và `Pong.server_time` (`fields.tsv:31, 36`) gặp số trên 2^63 − 1 thì
    giải mã ra `kOutOfRange`. Ở Dev, `Milliseconds64` không dấu (`protocol.hpp:68`) nhận mọi số.
    Chỗ này chỉ ghi ở `BAO-CAO-C.md:227–232`.

T17 (DE-BAI dòng 455) đòi mọi trường lệch phải có lý do ở cột `note`. Miền giá trị của hai trường
`server_time` hẹp lại mà cột `note` không có lý do.

Đề xuất:

- Thêm `## Vai C` vào `NGUON.md`, cùng mốc `@e0d89a6`, liệt kê bốn bảng (nguồn là `protocol.hpp`)
  và `protocol_catalog_tests.cpp` (nguồn là `tests\protocol\protocol_test.cpp:217`). Cột khác gốc
  gồm: `Reject.request` để `u16`, thời lượng có dấu và trần `millis64`, `ClientKind` không chép,
  giá trị mặc định của struct.
- Ghi mốc vào dòng `# source:`.
- Thêm `note` cho `fields.tsv:31, 36`, ví dụ "u64 trên 2^63 − 1 là kOutOfRange, xem DE-BAI 3.2,
  BAO-CAO-C mục 10.3".

### X-AC-03 [nhẹ] G3 không chặn tên C++ sinh ra trùng nhau; bảng được nhận nhưng mã sinh không dịch được

Chỗ: `protocol_cxx.py:90–93`. Hằng trần đặt tên theo
`k{owner.name}{snake_to_camel(item.name)}{unit}`. `protocol_cpp_src.py:120, 123` đặt tên hàm phụ
thời lượng là `put_millis32` và `get_millis32`. `protocol_cpp_src.py:149, 152` đặt tên hàm của enum
là `put_<snake>` và `get_<snake>`. `protocol_rules.py:58–63` chỉ chặn từ khoá và tên ở
`RESERVED_TYPES` (dòng 31–35).

A thử trên một bản chép của danh mục thật (`a-doi-chat-trung-ten.log`). Bản chép thêm tin
`0x0503 Sign`, có trường `in_account text 64` và trường `unit enum:Millis32`, cùng enum
`Millis32 u8 1 One`. Mọi tên đều đúng CamelCase và snake_case.

Trích log, đường dẫn trong lỗi của g++ rút gọn thành `...`:

```text
$ python -B TOOLS/server/gen_protocol.py --catalog build/p2-a/doi-chat/catalog --out build/p2-a/doi-chat/out
mã thoát: 0
messages.hpp:101: inline constexpr std::size_t kSignInAccountBytes = 64;
messages.hpp:103: inline constexpr std::size_t kSignInAccountBytes = 64;
messages.cpp:25: [[nodiscard]] std::chrono::milliseconds get_millis32(Reader& reader) {
messages.cpp:89: [[nodiscard]] Millis32 get_millis32(Reader& reader) {
.../messages.hpp:103:30: error: redefinition of 'constexpr const std::size_t game::protocol::kSignInAccountBytes'
.../messages.cpp:89:24: error: ambiguating new declaration of '... get_millis32(game::protocol::Reader&)'
mã thoát g++: 1
```

Công cụ nhận bảng mà không in dòng `tệp:dòng:` nào, nên người sửa bảng chỉ thấy lỗi dịch trong mã
sinh. Hai ca trùng có thể xảy ra: `Foo.bar_baz` với `FooBar.baz`; record hay enum tên `Millis32`,
`Millis64` hay `Seconds16`. Danh mục thật hiện chưa có ca nào như vậy, và `protocol_catalog_fresh`
cùng `check.py` sẽ chặn trước khi lỗi lên dây. Vì thế mức là nhẹ.

Đề xuất: ở G3, gom mọi tên C++ mà công cụ sẽ sinh, gồm hằng trần, `put_*`, `get_*` và tên hàm phụ,
rồi báo trùng ở dòng của trường hay tin gây ra. Thêm một ca vào `test_g3_names`.

### X-AC-04 [nhẹ] Có nhánh của mã sinh không test nào chạm tới; bằng chứng probe nằm ở thư mục sẽ bị xoá

- **Kiểm biên khi ghi `millis32` và `seconds16`.** Danh mục thật dùng hai kiểu này ở
  `Ping.client_time`, `Pong.client_time` và `Welcome.heartbeat`. Phép kiểm ở `messages.cpp:21` và
  `messages.cpp:43` (số âm, số trên `0xFFFF'FFFF`, số trên `0xFFFF`) không có ca nào. Tìm
  `client_time|heartbeat` trong `tests/protocol*.cpp` và `tests/wire*.cpp` ra 0 dòng
  (`a-doi-chat-doi-chieu-lan2.log`). Ca `millis64 quá cỡ` chỉ thử `millis64`
  (`protocol_catalog_tests.cpp:160–170`). Nếu dòng 21 hay 43 mất, Writer sẽ ghi số bị cắt bớt, và
  không ca nào A tìm thấy bắt được chỗ đó. A chưa chạy thử đột biến này.
- **Kiểu `bool`, `f32`, `i8` tới `i64`, `optional`, record lồng trong list.** Danh mục thật không
  dùng các kiểu này, nên mã C++ sinh cho chúng chỉ được dịch và chạy trong probe của C
  (`c-probe-blank.log`: `g++: mã thoát 0`, `probe.exe ... mã thoát 0`). Script probe là
  `build/p2-c/probe/make_probe.py` và `probe_main.cpp`. Hai tệp này nằm dưới `/build/`, bị
  `.gitignore:7` bỏ qua (`a-doi-chat-doi-chieu.log`). DE-BAI dòng 410–412 lại bảo L xoá
  `build/p2-c`. Sau bước đó, bằng chứng này không chạy lại được.
- **Cắt thân ở cổng auth.** Mỗi mẫu chỉ giải mã bằng bộ giải mã đầu tiên nhận tin
  (`protocol_samples.hpp:32–33, 478–483`). Bốn tin `both` (12 mẫu) vì vậy chỉ được cắt và thêm byte
  qua `decode_game_*`. Đếm ra `decode_auth_client` 6 lần và `decode_auth_server` 3 lần.

Đề xuất:

- Thêm vào `protocol_catalog_tests.cpp` một ca ghi `Ping` có `client_time` bằng −1 và bằng 2^32, và
  ghi `Welcome` có `heartbeat` bằng 65.536. Ca phải đòi `kOutOfRange` và `out` giữ nguyên cỡ.
- Đưa script probe vào nơi được giữ, chẳng hạn `so-do/` như `c-do.py`, hoặc thêm một test sinh danh
  mục thử rồi dịch nó.

### X-AC-05 [nhẹ] Mỗi luật G có một test, nhưng nhiều vế của luật chưa có ca

Đề chỉ đòi mỗi luật một test (DE-BAI dòng 221–222), và điều đó đã đạt. A đọc từng test và chưa thấy
ca nào cho các vế sau:

- G2 (`test_gen_protocol.py:133–138`): `kind` sai dạng như `0x101`, `0x01ab` hay `1`. Chỉ có ca trùng
  mã và ca nhóm không có.
- G3 (`:140–147`): tên trường trùng từ khoá C++, và tên enum trùng tên tin. Chỉ có ca `Id`, ca tin
  trùng tên và ca enum tên `class`.
- G6 (`:165–185`): `optional:list:u8`, và record được nhắc mà không có. Chỉ có ca `list:list:u8` và
  ca `enum:Missing`.
- G7 (`:187–194`): `bytes` thiếu `limit`, và `limit` trên 65.535.
- G8 (`:196–203`): tên giá trị trùng, và `underlying` khác `u8` và `u16`.
- G9 (`:205–208`): tin của máy chủ trên 65.536 byte. Ca duy nhất là `Probe` (`0x0101`), một tin của
  client.

Mã luật xử lý đủ các vế trên (`protocol_rules.py:90–99, 144–159, 182–205, 330–336`), nhưng không
ca nào giữ chúng khỏi bị sửa hỏng.

Đề xuất: mỗi vế một `expect_rule` trong test của luật đó.

### X-AC-06 [nhẹ] BAO-CAO-C chưa cập nhật sau lần sửa cuối; vài số không có log chứa đúng số đó

- `BAO-CAO-C.md:175` ghi `test_gen_protocol.py | 303`. Log `c-d6-dong.log` ghi
  `309	TOOLS/server/test_gen_protocol.py`, và không log nào của C chứa `303`
  (`a-doi-chat-doi-chieu.log`).
- `BAO-CAO-C.md:248` ghi 389, 322, 330 dòng. Ba số này đúng với tệp hiện tại (A đếm bằng
  `Get-Content`), nhưng không log `c-*` nào chứa chúng.
- `BAO-CAO-C.md:23` lấy `c-t2-lint.log` làm bằng chứng cho "mã thoát 0", trong khi tệp đó 0 byte.
  Lượt sau có `mã thoát: 0` trong `c-g6-chay-lai.log`.
- Mục 1, 3 và 6 còn số của lượt 02:06: `Ran 239 tests`, "23 test" (dòng 22, 179), "dài nhất 359
  dòng" (dòng 30). Danh sách test ở dòng 78–82 thiếu `test_empty_record_field`. DE-BAI dòng 500 đòi
  báo cáo cập nhật sau lần sửa cuối. Lượt 09:58 của A ra `Ran 240 tests`, `OK (skipped=8)` và
  `Ran 24 tests`, khớp mục 11 của C, nên phần đáng tin là mục 11.

Đề xuất: sửa mục 1, 3 và 6 theo `c-g6-chay-lai.log`. Ghi số dòng bằng một lượt `c-do.py` mới có log.
Bỏ `c-t2-lint.log` khỏi cột log, hoặc ghi rõ tệp đó rỗng vì lệnh không in gì.

### X-AC-07 [nhẹ] T1 ghi vào cây của C, cây mà L phải xoá

Chỗ: `test_gen_protocol.py:18` có `SCRATCH = REPO / "build" / "p2-c" / "gen-tests"`. Test xoá thư
mục con của nó (dòng 103–104) nhưng giữ `SCRATCH`. DE-BAI dòng 410–412 bảo L xoá `build/p2-c`
trước khi báo xong. Sau bước đó, mỗi lần chạy T1 lại tạo `build/p2-c/gen-tests`. Hiện thư mục này
có và rỗng (`a-doi-chat-doi-chieu.log`: `build/p2-c/gen-tests có: True, số mục: 0`).

Đề xuất: dùng `tempfile.mkdtemp()` mặc định, hoặc một thư mục dưới `build/` không thuộc vai nào, và
xoá cả thư mục cha khi xong.

### Lệch quy tắc của A trong bước này

- Lượt 10:01:57–10:02:01 (`a-doi-chat-ctest.log`) là một lần dựng. `cmake --build` tự cấu hình lại
  cây `build/p2-a` (`Configuring done (2.4s)`) rồi dựng lại `game_protocol.lib` và
  `protocol_catalog_tests.exe`. Sau đó A chạy `ctest`. Theo luật khoá, dựng và ctest là lệnh nặng,
  phải giữ `build/NANG.lock`. A không lấy khoá: A chỉ kiểm thấy khoá vắng, rồi khai lượt này trong
  lịch là `nhẹ`. Lượt này không chồng phiên khoá nào, vì phiên gần nhất kết thúc lúc 10:01:38. Chỉ
  cây `build/p2-a` của A bị ghi. Kết quả 2/2 Passed vẫn đúng, nhưng lượt này không được tính là một
  lượt đo có khoá.

## Kết luận

Danh mục khớp Dev ở cả 19 tin và 38 trường. Mã sinh gọi đúng hợp đồng tầng byte của A: kiểm trần
trước khi cấp phát, enum lạ là `kBadEnum`, kind ngoài cổng hay sai chiều là `kUnknownKind`, thừa byte
là `kTrailingBytes`. A chạy lại T1, T2, `--check` và hai test C++ của C, và tất cả đều xanh. A không
tìm ra lỗi làm sai byte trên dây.

Phải sửa trước bước 4:

- X-AC-01: hai dòng số Đ4 không có log.
- X-AC-02: thiếu phần C ở `NGUON.md` và thiếu ghi chú khác gốc. T17 có thể không đạt vì chỗ này.

Các mục nhẹ không chặn đợt này. X-AC-03 và X-AC-04 nên sửa trước khi danh mục có thêm nhóm tin.

Số mục: nặng 0, vừa 2, nhẹ 5.
