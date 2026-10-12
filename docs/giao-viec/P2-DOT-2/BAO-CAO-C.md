# Báo cáo vai C: danh mục và công cụ sinh (P2 đợt 2)

Tệp của C: `SRC/protocol/catalog/{groups,messages,fields,enums}.tsv`, `TOOLS/server/gen_protocol.py`,
`TOOLS/server/protocol_{model,tsv,rules,wire,cxx,cpp_hpp,cpp_src,samples,doc}.py`,
`TOOLS/server/test_gen_protocol.py`, `tests/protocol_catalog_tests.cpp`, bốn tệp sinh
(`SRC/protocol/messages.hpp`, `SRC/protocol/messages.cpp`, `tests/protocol_samples.hpp`,
`docs/PROTOCOL-TIN.md`) và script đo `so-do/c-do.py`. Dựng trong `build/p2-c` bằng preset
`clang-asan`, cây riêng của C. Mã sinh dựng trên `hop-dong/wire.hpp`; `SRC/protocol/wire.hpp` của A
trùng hợp đồng, test chạy với `wire.cpp` thật của A.

Điều kiện đo: commit `0e6da48f366b0a1d58d55fe9f807adba2425b47a` (cây làm việc chưa commit), máy
Hoon, Python 3.13.15, không giữ `NANG.lock` (không lệnh nào của C là lệnh nặng); A, B, L dùng chung
máy nên không loại được việc có bản dựng khác chạy cùng lúc. Ổ F còn trống 167.328.161.792 byte
(155,84 GiB) lúc 02:06:27 (`so-do/c-d4-gen.log`).

## 1. Kết quả

| Việc | Lệnh | Số lần | Kết quả | Log |
|---|---|---|---|---|
| Test đỏ | `python -B -W error -m unittest -v TOOLS/server/test_gen_protocol.py` khi `gen_protocol.py` còn là khung của bước 0 | 1 (01:42:07) | `Ran 22 tests`, `FAILED (errors=21)`, mã thoát 1 | `so-do/C-test-do.log` |
| Test đỏ của ca thêm sau | `PYTHONPATH=TOOLS/server python -B -W error -m unittest test_gen_protocol.OutputTests.test_doc_shows_kinds` trước khi sửa `protocol_doc.py` | 1 | `FAILED (failures=1)`, mã thoát 1 | `so-do/c-doc-kind-do.log` |
| T1 | `python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"` | 1 (lần cuối) | `Ran 239 tests`, `OK (skipped=8)`; 216 test cũ còn đủ, 23 test của `test_gen_protocol.py` không bỏ qua ca nào | `so-do/c-t1-unittest.log` |
| T2 | `python -B -W error TOOLS/server/lint_py.py` | 1 | mã thoát 0 | `so-do/c-t2-lint.log` |
| T3 | `gen_protocol.py --check`, rồi `--out` vào `build/p2-c/do/t3-a` và `t3-b`, so SHA-256 | 1 | `--check` thoát 0; `trùng cả ba: 4/4` (hai cây và cây làm việc) | `so-do/c-t3.log` |
| T4 | chép `SRC/protocol/catalog` sang `build/p2-c/do/t4-catalog`, sửa `limit` của `CharacterSummary.name` 48 thành 49, `--catalog <bản chép> --check` | 1 | thoát 1, in `cũ:` ba tệp | `so-do/c-t4.log` |
| T6 (phần của C) | `python %USERPROFILE%/.claude/cpp23/tools/check.py --only gcc` trên 4 tệp C++ của C, có clang-tidy (4 tệp, lệnh nhẹ) | 1 (lần cuối, 02:06:02–02:06:06) | `4 tệp, 0 lỗi.` | `so-do/c-check.log` |
| Dựng và chạy test C++ | `cmake --build build/p2-c --target protocol_catalog_tests`; `ctest --test-dir build/p2-c -R protocol_catalog --output-on-failure` | 1 | `100% tests passed out of 2` (`protocol_catalog_tests`, `protocol_catalog_fresh`) | `so-do/c-ctest.log` |
| T8 | 57 mẫu × (cắt ở mọi độ dài thân ngắn hơn + thêm một byte) trong `protocol_catalog_tests` | 1 | 2.912 ca cắt và 57 ca thêm byte; 0 ca cắt giải mã thành công (ca test xanh) | `so-do/c-t8-mau.log`, `so-do/c-ctest.log` |
| T9 | ca `byte Hello của Dev` | 1 | xanh: phiên bản 1, nền tảng 2 (`kAndroid`), bản dựng `0x01020304`, mã hoá lại trùng 15 byte | `so-do/c-ctest.log` |
| T16 (phần của C) | đếm dòng trong `so-do/c-do.py` | 1 | tệp `.py`/`.cpp` viết tay dài nhất 359 dòng (`protocol_rules.py`) | `so-do/c-d6-dong.log` |
| Danh mục thử đủ kiểu ra C++ | sinh từ danh mục thử của `test_gen_protocol.py`, clang-format, clang-tidy, `g++ -Werror`, chạy 5 ca chung | 1 | 3 tệp format `OK`, tidy 0 dòng, g++ thoát 0, chạy thoát 0 trên 12 mẫu | `so-do/c-probe.log` |

Số lượt khác trước lần cuối:

- `check.py` có tidy chạy nhiều lượt trong lúc sửa (lỗi clang-format của khởi tạo chỉ định trong
  `protocol_samples.hpp`, `performance-enum-size`, `pro-bounds-constant-array-index`,
  `modernize-use-designated-initializers`, PH-01 ở ca cắt). Các lượt đó không lưu log riêng; chỉ
  lượt cuối ở bảng trên là số được báo.
- Thử đột biến bằng tay trên danh mục thật (01:5x): đổi một byte khung `Hello/max` trong
  `tests/protocol_samples.hpp` thì `encode_matches_python` và `peek_and_decode_round_trip` hỏng ở
  `Hello/max` và `protocol_catalog_fresh` báo tệp cũ; sinh lại thì xanh. Lượt này không lưu log nên
  không tính là số đo. Đột biến tương tự trên danh mục thử có log ở `so-do/c-probe.log`.

## 2. Số tin, trường, enum, record (Dev và bảng của ta)

Lệnh: `python -B docs/giao-viec/P2-DOT-2/so-do/c-do.py`, log `so-do/c-dem-tin.log`. Dev đếm trên
`G:\TLBB\Dev\src\protocol\protocol.hpp` (chỉ đọc): tin là tên trong `ClientKind`/`ServerKind` có
nhóm 01, 02, 05; trường là số lời gọi `io.<hàm>(self.` trong struct; record là struct mà tin dùng
tới, đệ quy; enum là `enum class` có giá trị được dùng làm kiểu trường.

| Đại lượng | Dev | Bảng của ta | Ghi chú |
|---|---|---|---|
| Tin | 19 | 19 (10 client, 9 server) | cùng tên |
| Trường của tin và record | 38 | 38 | |
| Record | 1 (`CharacterSummary`) | 1 (`CharacterSummary`) | |
| Enum | 5 | 4 | Dev có `ClientKind` làm kiểu của `Reject.request`; ta để `u16` (mục 8.1) |

## 3. Luật G ứng với test

Mỗi luật một test trong `TOOLS/server/test_gen_protocol.py`, lớp `RuleTests`; mỗi test sửa một ô
của danh mục thử rồi kiểm mã thoát 1, đúng mã luật, đúng tệp và số dòng trong thông báo.

| Luật | Test |
|---|---|
| (danh mục gốc hợp lệ) | `test_base_catalog_is_valid` |
| G1 | `test_g1_header` |
| G2 | `test_g2_kind` |
| G3 | `test_g3_names` |
| G4 | `test_g4_port_and_since` |
| G5 | `test_g5_order` |
| G6 | `test_g6_types`, `test_g6_recursive_record` |
| G7 | `test_g7_limits` |
| G8 | `test_g8_enum_values` |
| G9 | `test_g9_body_size` |
| G10 | `test_g10_unused` |
| G11 | `test_g11_owner_without_declaration`, `test_g11_message_without_fields` |

Lớp `OutputTests`: `test_test_catalog_covers_every_type` (danh mục thử có đủ kiểu của mục 3.2, kể cả
`list` của record và `optional` của enum), `test_generated_files_start_with_notice`,
`test_generated_functions_fit_limits`, `test_deterministic` (hai lần sinh cùng SHA-256),
`test_check_reports_stale_files` (sửa một ô thì `--check` thoát 1), `test_check_passes_on_repo`,
`test_doc_shows_kinds`. Lớp `EncoderTests`: `test_dev_hello_bytes`, `test_every_type_bytes`.

Các ca của `tests/protocol_catalog_tests.cpp` (9 ca): `mã hoá khớp byte Python`, `peek_frame và giải
mã lại`, `cắt ở mọi độ dài` (mọi ca cắt phải ra `kTruncated`), `thừa một byte` (`kTrailingBytes`),
`cổng và chiều` (bốn bộ giải mã; ngoài mặt nạ của mẫu phải ra `kUnknownKind`), `byte Hello của Dev`,
`Reject giữ mã tin lạ` (thân `EF BE 01 00` ra `request` `0xBEEF`), `enum lạ` (`platform` 0 ra
`kBadEnum` khi giải mã; mã hoá `Platform` 9 ra `kBadEnum` và `out` giữ nguyên cỡ), `millis64 quá cỡ`.

## 4. Cỡ thân lớn nhất của từng tin

Tính bằng `protocol_model.body_max_bytes` (G9), log `so-do/c-dem-tin.log`; cùng số in ở
`docs/PROTOCOL-TIN.md`.

| Kind | Tin | Cổng | Trường | Thân tối đa (byte) |
|---|---|---|---|---|
| `0x0101` | Hello | game, auth | 3 | 7 |
| `0x0102` | Login | game | 2 | 580 |
| `0x0103` | Resume | game | 1 | 16 |
| `0x0104` | Ping | game | 1 | 4 |
| `0x0105` | Logout | game | 0 | 0 |
| `0x0201` | CreateCharacter | game | 4 | 55 |
| `0x0202` | DeleteCharacter | game | 1 | 8 |
| `0x0203` | EnterGame | game | 1 | 8 |
| `0x0501` | CreateAccount | auth | 2 | 196 |
| `0x0502` | SignIn | auth | 2 | 196 |
| `0x8101` | Welcome | game, auth | 3 | 12 |
| `0x8102` | SessionStart | game | 1 | 16 |
| `0x8103` | ContentKey | game | 1 | 32 |
| `0x8104` | Pong | game | 2 | 12 |
| `0x8106` | Reject | game, auth | 2 | 4 |
| `0x8107` | Goodbye | game, auth | 1 | 1 |
| `0x8108` | ContentStamp | game | 1 | 32 |
| `0x8201` | CharacterList | game | 1 | 546 |
| `0x8501` | Ticket | auth | 1 | 204 |

Record `CharacterSummary`: 8 trường, tối đa 68 byte. Tin client lớn nhất 580 byte (dưới 4.096), tin
server lớn nhất 546 byte (dưới 65.536).

## 5. Output của T3 và T4

T3 (`so-do/c-t3.log`):

```
$ python -B TOOLS/server/gen_protocol.py --check
mã thoát: 0
$ python -B TOOLS/server/gen_protocol.py --out build/p2-c/do/t3-a
mã thoát: 0
$ python -B TOOLS/server/gen_protocol.py --out build/p2-c/do/t3-b
mã thoát: 0
SRC/protocol/messages.hpp   462f25759e21f313091b8f190fa322d665e5be364d78787f116f9bad5d36dbd0  (a = b = cây)
SRC/protocol/messages.cpp   0450a6012ac68d0cbfb198ae5f8537896898773be183359d8e38f7758ac7a04d  (a = b = cây)
tests/protocol_samples.hpp  35d22e9857b5591c3bb2d3210e04b7282016ef1396f2be84fcff6d6dcddd8ccb  (a = b = cây)
docs/PROTOCOL-TIN.md        bd7e2a17c937768475a93709d488899376d0e4a4a13643209f8c58d03453154a  (a = b = cây)
trùng cả ba: 4/4
```

T4 (`so-do/c-t4.log`):

```
sửa fields.tsv dòng 6, cột limit: 48 thành 49 (trường CharacterSummary.name)
$ python -B TOOLS/server/gen_protocol.py --catalog build/p2-c/do/t4-catalog --check
cũ: SRC/protocol/messages.hpp
cũ: tests/protocol_samples.hpp
cũ: docs/PROTOCOL-TIN.md
Chạy lại: python -B TOOLS/server/gen_protocol.py (3 tệp cũ).
mã thoát: 1
```

`messages.cpp` không cũ là đúng: trần của text đọc từ hằng `kCharacterSummaryNameBytes` ở
`messages.hpp`, nên đổi trần không đổi mã trong `.cpp`. Lượt T4 đầu tiên ghi bảng bằng `write_text`
nên Windows thêm CR; công cụ báo `[G1] tệp có CR; chỉ dùng LF`, thoát 1. Script đã sửa sang ghi
byte giữ LF; log hiện tại là lượt sau khi sửa.

## 6. Số đo

| Mã | Đại lượng | Lệnh | Số lượt | Trung vị | Nhỏ nhất | Lớn nhất | Log |
|---|---|---|---|---|---|---|---|
| Đ4 | thời gian cả tiến trình `gen_protocol.py --check` (giây) | `c-do.py`, `time.perf_counter` quanh `subprocess.run` | 5 | 0,069296 | 0,063512 | 0,076711 | `so-do/c-d4-gen.log` |
| Đ4 | thời gian `load_catalog` + `render_all` trong tiến trình (giây) | `c-do.py`, `time.perf_counter` | 5 | 0,004877 | 0,004737 | 0,005214 | `so-do/c-d4-gen.log` |
| Đ4 | đỉnh bộ nhớ Python của `load_catalog` + `render_all` (MiB) | `c-do.py`, `tracemalloc`, lượt riêng | 5 | 0,536757 | 0,536704 | 0,536849 | `so-do/c-d4-gen.log` |

Số gốc của cả năm lượt nằm trong log; số trên bảng là số gốc, không làm tròn.

Đ6 (`so-do/c-d6-dong.log`, đếm bằng `splitlines`):

| Tệp viết tay | Dòng | Tệp viết tay | Dòng |
|---|---|---|---|
| `catalog/groups.tsv` | 7 | `protocol_wire.py` | 150 |
| `catalog/messages.tsv` | 25 | `protocol_cxx.py` | 150 |
| `catalog/fields.tsv` | 42 | `protocol_cpp_hpp.py` | 145 |
| `catalog/enums.tsv` | 50 | `protocol_cpp_src.py` | 311 |
| `gen_protocol.py` | 112 | `protocol_samples.py` | 225 |
| `protocol_model.py` | 194 | `protocol_doc.py` | 87 |
| `protocol_tsv.py` | 149 | `test_gen_protocol.py` | 303 |
| `protocol_rules.py` | 359 | `tests/protocol_catalog_tests.cpp` | 189 |

Tệp sinh: `messages.hpp` 340, `messages.cpp` 533, `tests/protocol_samples.hpp` 1.854,
`docs/PROTOCOL-TIN.md` 336. Số ca: `test_gen_protocol.py` 23 test, `protocol_catalog_tests.cpp` 9 ca,
`protocol_samples.hpp` 57 mẫu; danh mục 19 tin, 38 trường.

## 7. Đã kiểm

- Bốn tệp sinh qua clang-format, PH-01, g14 và clang-tidy (`so-do/c-check.log`).
- `protocol_catalog_tests` và `protocol_catalog_fresh` xanh ở `build/p2-c` (`clang-asan`).
- Tất định và `--check` (T3, T4, `test_deterministic`, `test_check_reports_stale_files`).
- Danh mục thử đủ kiểu đi trọn đường tới C++: sinh, format, tidy, `g++ -Werror -Wconversion
  -Wsign-conversion -D_GLIBCXX_ASSERTIONS -ftrapv`, chạy 5 ca chung trên 12 mẫu; đột biến một byte
  thì hỏng đúng hai ca (`so-do/c-probe.log`). Lượt này bắt được `readability-trivial-switch` ở bộ
  giải mã có một tin; công cụ nay sinh `if` cho trường hợp đó.
- Trong lúc đo bắt được lỗi `docs/PROTOCOL-TIN.md` in repr của phương thức `kind_text` thay vì mã
  tin; đã sửa, thêm `test_doc_shows_kinds`, có log đỏ trước khi sửa.
- Số tin, trường, record khớp Dev (mục 2).

## 8. Chưa kiểm

- Ba preset của T5 (`msvc-release`, `gcc-debug`, `clang-asan` đầy đủ) và `header_check`: lệnh nặng,
  thuộc bước 1b của L. C chỉ dựng target của mình ở `build/p2-c`.
- `check.py` trên mọi tệp C++ mới của đợt (T6 đầy đủ): C chỉ chạy trên 4 tệp của mình.
- `is_valid` của enum có hơn 37 khoảng giá trị không được chia nhỏ; danh mục hiện có enum lớn nhất
  là `ErrorCode` một khoảng liền 1–32, chưa có danh mục nào chạm giới hạn này.
- Nhánh một dòng của khởi tạo chỉ định `Sample` (khi cả khai báo vừa 120 cột): mọi mẫu hiện có đều
  dài hơn, nên nhánh này chưa qua clang-format thật.
- Bộ giải mã một tin chỉ chạy qua danh mục thử; danh mục thật không có cổng nào chỉ một tin.
- Bộ mô phỏng clang-format trong `protocol_cxx.pack` chỉ được kiểm trên output của danh mục thật và
  danh mục thử; dạng mới (tên rất dài, nhiều trường) có thể lệch và sẽ lộ ở `check.py`.

## 9. Giả định

- `list:text` và `list:bytes` bị từ chối (G7): bảng chỉ có một cột `limit`, nên phần tử cần trần
  riêng phải bọc trong record. Danh mục thật không cần kiểu này.
- G10 tính theo khả năng với tới: record hay enum chỉ được record không ai dùng nhắc tới vẫn là lỗi.
- `millis64` lớn hơn `INT64_MAX` mili giây trên dây là dữ liệu hỏng chứ không phải giờ thật (khoảng
  292 triệu năm), nên báo `kOutOfRange` thay vì quấn số (mục 10.3).
- Giá trị điển hình của mẫu (`typical`) là số tất định từ thứ tự trường, không lấy từ dữ liệu Dev.
- `Hello`, `Welcome`, `Reject`, `Goodbye` thuộc cả hai cổng (`both`), theo Dev dùng chung ở cổng game và
  cổng xác thực.

## 10. Lệch quy tắc

1. `Reject.request` là `u16`, không phải enum `ClientKind` như Dev: giữ nguyên byte của Dev, không
   chép mã tin vào `enums.tsv`, và giữ được mã tin lạ để báo lại. Ghi ở cột `note` của
   `fields.tsv`; R đã nhận; test `Reject giữ mã tin lạ`.
2. `ErrorCode` khai `u16` theo Dev nhưng mọi giá trị đều ≤ 255, nên clang-tidy báo
   `performance-enum-size`. Công cụ sinh `// NOLINTNEXTLINE(performance-enum-size): cỡ trên dây theo
   bảng, giữ byte của Dev (HP-07)` ngay trên enum đó, đúng mẫu NOLINT của `AGENTS.md`.
3. `millis64` ra `std::chrono::milliseconds` (nền `int64`), còn Dev khai
   `using Milliseconds64 = std::chrono::duration<std::uint64_t, std::milli>;`
   (`protocol.hpp:68`). Byte trên dây giống nhau với mọi giá trị đến `INT64_MAX`; trên đó giải mã ra
   `kOutOfRange` (byte cao `0x80` của `Pong`), và mã hoá giá trị âm cũng ra `kOutOfRange`. Test
   `millis64 quá cỡ`. Lý do: phía C++ của ta tính giờ bằng `std::chrono` có dấu, trừ hai mốc không
   bị quấn.
4. `tests/protocol_samples.hpp` dài 1.854 dòng: là tệp sinh, T16 chỉ áp cho tệp viết tay.

## 11. Bổ sung theo quyết định (a) của L, 02:22 (chạy lại 09:07 sau khi máy Hoon lên lại)

**Luật mới của G6:** phần tử của `list` phải chiếm ít nhất 1 byte trên dây, tính đệ quy qua record (`least_bytes` và `check_list_elements` trong `protocol_rules.py`). Đây là bất biến mà `Reader::count` dựa vào (A đã ghi cạnh `Reader::count`). Vòng lặp record vẫn là lỗi G6 riêng; `least_bytes` dừng ở record đã gặp nên không lặp vô hạn.

| Việc | Ca thử | Log |
|---|---|---|
| `list:record:Blank` và `list:record:Hollow` (Hollow chỉ chứa `record:Blank`) báo G6 ở đúng dòng 33 và 34 | `RuleTests.test_g6_types` | đỏ rồi xanh: `so-do/c-g6-phan-tu-list.log` |
| `Blank` (record không trường) làm trường đơn `Report.blank` trong danh mục thử; mã hoá Python ra 0 byte | `EncoderTests.test_every_type_bytes` | như trên |
| Sinh `put_blank`/`get_blank` rỗng cho record không trường (trước đó `Report` gọi hàm không tồn tại, g++ và tidy đều báo lỗi) | `OutputTests.test_empty_record_field` | đỏ `so-do/c-probe-blank-do.log`, `so-do/c-blank-do-xanh.log` |
| Tidy `misc-const-correctness` ở hai hàm rỗng, sửa thành `const Writer&`/`const Reader&` | probe | đỏ `so-do/c-probe-blank-do-2.log` |
| Probe danh mục thử (13 mẫu): clang-format, clang-tidy 0 cảnh báo trên 3 tệp, `g++ -Werror` mã thoát 0, `probe.exe` mã thoát 0 | probe | xanh `so-do/c-probe-blank.log` (09:06:56) |
| Toàn bộ unittest TOOLS/server: 240 ca OK (8 bỏ qua), `lint_py` 0, `gen_protocol.py --check` 0 | T1, T2 | `so-do/c-g6-chay-lai.log` (09:07:21) |

`test_gen_protocol.py` nay có 24 ca. Số dòng: `protocol_rules.py` 389, `protocol_cpp_src.py` 322, `test_gen_protocol.py` 330. Tệp đã sửa đợt này: ba tệp trên; `tests/protocol_catalog_tests.cpp` và bảng TSV thật không đổi.

**Tệp sinh của danh mục thật không đổi byte nào** (ghi lại bằng `gen_protocol.py` rồi `Get-FileHash -Algorithm SHA256`):

| Tệp | Trước (02:24:41) | Sau (09:07:21) |
|---|---|---|
| `SRC/protocol/messages.hpp` | `462f25759e21f313091b8f190fa322d665e5be364d78787f116f9bad5d36dbd0` | giống hệt |
| `SRC/protocol/messages.cpp` | `0450a6012ac68d0cbfb198ae5f8537896898773be183359d8e38f7758ac7a04d` | giống hệt |
| `tests/protocol_samples.hpp` | `35d22e9857b5591c3bb2d3210e04b7282016ef1396f2be84fcff6d6dcddd8ccb` | giống hệt |
| `docs/PROTOCOL-TIN.md` | `bd7e2a17c937768475a93709d488899376d0e4a4a13643209f8c58d03453154a` | giống hệt |

Vì tệp sinh thật không đổi, mình không dựng lại `build/p2-c` và không chạy lại check.py trên 4 tệp sinh (log cũ `c-check.log`, `c-ctest.log` vẫn đúng cho cùng byte).

**Đ4:** số đo Đ4 ở mục 6 chỉ để tham khảo vì chạy không có `NANG.lock`. Số chính thức là của Build & Test, đo lại có khoá (có thể dùng `so-do/c-do.py`).

Ổ F còn trống 155,6 GB lúc 09:07.
**Log đã chạm sau khi chạy** (trước luật 09:19 của L, ghi để minh bạch): `so-do/c-probe-blank-do.log` vốn là `c-probe-blank.log` của lượt đỏ 02:25. Tệp được đổi tên và thêm một dòng ghi chú cuối tệp lúc 02:28, nói rằng dòng `probe.exe: mã thoát 0` là của exe cũ lúc 02:06. `so-do/c-probe-blank-do-2.log` vốn là `c-probe-blank.log` của lượt đỏ 09:05. Tệp được đổi tên và thêm một dòng ghi chú cuối tệp lúc 09:07. Cả hai tệp chỉ có thêm dòng cuối, mọi dòng đã chạy giữ nguyên. Từ giờ C không sửa log đã chạy.