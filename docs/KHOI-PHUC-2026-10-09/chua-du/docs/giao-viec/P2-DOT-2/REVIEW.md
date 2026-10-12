# Review vai R: P2 đợt 2

## 1. Đầu báo cáo

- Vai: R (Game Rà soát), bước 2 của DE-BAI mục 6.
- HEAD: `0e6da48f366b0a1d58d55fe9f807adba2425b47a`, nhánh `p2-dot-2`. Thay đổi của đợt chưa commit.
- Giờ viết: 2026-10-08 10:03 (UTC+7). Mọi giờ trong tệp này là UTC+7.
- Phạm vi: toàn bộ thay đổi của đợt trong worktree `F:/tl 2026/THIENLONG/build/p2-dot-2`, gồm
  `SRC/protocol/` (cả mã sinh), `SRC/net/`, `TOOLS/server/gen_protocol.py`, `protocol_*.py`,
  `fuzz_protocol.py`, `test_gen_protocol.py`, các tệp test mới trong `tests/`, `tests/fuzz/`,
  `tests/bench/`, `docs/PROTOCOL-TIN.md`, hai tệp CMake, các báo cáo vai và `so-do/`.
- Mốc mã: phần đọc mã làm lúc 09:2x tới 09:5x. Sau đó có hai tệp đổi: `SRC/net/socket_posix.cpp`
  (mtime 09:59:35) và `tests/bench/net_bench.cpp` (mtime 10:00:26). Số dòng các finding ở
  `socket_posix.cpp` đã đối lại trên bản 09:59:35; `net_bench.cpp` chưa đọc lại.

## 2. Output các phép thử của mục 6

### 2.1 T12: bộ dò có răng

Log: `so-do/r-rang.log`. Script `build/p2-r/rang.py` (prepare/build/run). Bản chép
`build/p2-r/src-rang/protocol` là bản chép trọn `SRC/protocol`. Dòng 2 của log ghi lý do không chạy
qua `fuzz_protocol.py`: "nó cố định PROJECT/SRC, build/p2-fuzz và ghi đè so-do/fuzz-*.log". Lần chạy
giữ `NANG.lock` (dòng 1: "NANG.lock của R giữ từ 2026-10-08 09:54:00 tới hết lần chạy này"), có dòng
22 và 23 trong `build/lich-nang.tsv`.

Phép kiểm biên bị bỏ trong bản chép (log dòng 8 tới 23):

```
diff --git a/SRC/protocol/wire.cpp b/build/p2-r/src-rang/protocol/wire.cpp
index 747fd8c..e381c78 100644
--- a/SRC/protocol/wire.cpp
+++ b/build/p2-r/src-rang/protocol/wire.cpp
@@ -335,10 +335,6 @@ WireStatus Reader::finish() const noexcept {
 
 ByteView Reader::take(std::size_t count) noexcept {
     if (error_) return {};
-    if (count > body_.size() - position_) {
-        fail(WireError::kTruncated);
-        return {};
-    }
     const ByteView part = body_.subspan(position_, count);
     position_ += count;
     return part;
```

Dòng `ERROR` đầu tiên của ASan (log dòng 141, đích `game_client`):

```
==22108==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x118db56c2f16 at pc 0x7ff626444faa bp 0x0017e28fe7a0 sp 0x0017e28fe7e8
```

Bản chép, lệnh `python -B build/p2-r/rang.py run rang 1000000`, cờ `-runs=1000000 -seed=20261008`
(log dòng 50: "09:55:27-09:55:28, mã 1"):

| đích | số vòng tới khi sập (`stat::number_of_executed_units`) | giây | mã thoát | dòng `SUMMARY` của ASan | dòng log |
|---|---|---|---|---|---|
| `game_client` | 8260 | 0.14 | 1 | `heap-buffer-overflow ... src-rang\protocol\wire.cpp:92 in ... sequence_length` (READ of size 1) | 141, 176, 214, 220 |
| `game_server` | 1353 | 0.10 | 1 | `heap-buffer-overflow ... xutility:4991 in std::_Impl_copy_memmeow_tail` (READ of size 16) | 272, 311, 349, 355 |
| `auth_client` | 3359 | 0.12 | 1 | `heap-buffer-overflow ... src-rang\protocol\wire.cpp:92 in ... sequence_length` (READ of size 1) | 434, 469, 507, 513 |
| `auth_server` | 4515 | 0.11 | 1 | `heap-buffer-overflow ... xutility:4991 in std::_Impl_copy_memmeow_tail` (READ of size 204) | 551, 590, 628, 634 |

Mỗi đích để lại một tệp `crash-*` trong `build/p2-r/fuzz/<đích>/`.

Đối chứng trên `SRC` gốc, lệnh `python -B build/p2-r/rang.py run goc 20000` (log dòng 636:
"09:55:28-09:55:29, mã 0"): cả bốn đích in `Done 20000 runs in 0 second(s)` (dòng 767, 934, 1044,
1112) và `mã thoát 0 ... tệp crash: không có` (dòng 774, 941, 1051, 1119).

Đích `frame` không được dùng. Đích này chỉ gọi `peek_frame` và `Channel`
(`tests/fuzz/targets.hpp:125`), còn `peek_frame` (`SRC/protocol/wire.cpp:347`) không đi qua
`Reader`, nên bỏ kiểm biên của `Reader::take` không chạm tới nó. `TARGETS` của `rang.py` (dòng 25)
chỉ có bốn đích giải mã.

Kết luận T12: **đạt**. Bản chép bị bỏ kiểm biên thoát 1 ở cả bốn đích, sớm nhất sau 1353 vòng, muộn
nhất sau 8260 vòng, đều trong một triệu vòng. Bản gốc chạy 20000 vòng, thoát 0.

### 2.2 Mười khung tự soạn

Log: `so-do/r-khung-tay.log`. Bốn exe dựng bằng `build/p2-r/probe/dung.ps1`:

- `probe_khung.exe`: ASan và UBSan, liên kết `build/p2-r/game_protocol.lib` và `game_core.lib`.
- `probe_khung_new.exe`: không sanitizer, dịch lại `SRC/protocol/*.cpp` từ nguồn.
- `probe_tuy_chon.exe` và `probe_tuy_chon_new.exe`: khung `bool` và `optional`, trên bản chép danh
  mục `build/p2-r/probe/catalog-tuy-chon`. Bản chép thêm tin `0x0106 ProbeFlag` (trường `flag bool`,
  `maybe optional:u8`), vì danh mục thật không có trường `bool` hay `optional` nào. Mã sinh bằng
  `python -B TOOLS/server/gen_protocol.py --catalog build/p2-r/probe/catalog-tuy-chon --out
  build/p2-r/probe/gen` (thoát 0).

Cách đếm cấp phát (log dòng 11 tới 16). Bản ASan dùng móc
`__sanitizer_install_malloc_and_free_hooks`, vì thay `operator new` toàn cục thì lld-link báo
"duplicate symbol: void * __cdecl operator new(unsigned __int64) ... defined at
clang_rt.asan_dynamic-x86_64.lib". Bản `*_new` thay `operator new/delete` thật. Hai cách cùng in tự
kiểm "vector<char>(1000) -> 1 lần, 1000 byte, lớn nhất 1000". Bộ đếm chỉ bật quanh lời gọi
`peek_frame`, `decode_*` và `Channel::receive` cùng `next`. Tên lỗi mong đợi đã viết sẵn trong mã
probe trước lần dựng đầu (log dòng 20 tới 36).

Số trong bảng lấy từ `probe_khung.exe` và `probe_tuy_chon.exe`; hai bản `*_new` in đúng các số đó.
Cột "giải mã" là cấp phát trong lúc giải mã; `peek_frame` cấp phát 0 lần ở mọi ca.

| ca | khung | byte | mong đợi | thực tế | cấp phát giải mã | cấp phát `Channel` |
|---|---|---|---|---|---|---|
| (1) | `Login` 0x0102, `account` text trần 64, khai 65.535, còn 3 byte | `05 00 00 00 02 01 00 00 FF FF 61 62 63` | `kTooLong` | `kTooLong` | 0 lần | 1 lần, 13 byte |
| (1b) phụ | `Login.ticket` khai 512 (bằng trần), còn 3 byte | `07 00 00 00 02 01 00 00 00 00 00 02 61 62 63` | `kTruncated` | `kTruncated` | 0 lần | 1 lần, 15 byte |
| (2) | `CharacterList` 0x8201, list trần 8, khai 65.535, thân hết | `02 00 00 00 01 82 00 00 FF FF` | `kTooLong` | `kTooLong` | 0 lần | 1 lần, 10 byte |
| (2b) phụ | list khai 8 (bằng trần), thân hết | `02 00 00 00 01 82 00 00 08 00` | `kTruncated` | `kTruncated` | 0 lần | 1 lần, 10 byte |
| (2c) phụ | list khai 8, còn 8 byte rác | `0A 00 00 00 01 82 00 00 08 00 00 00 00 00 00 00 00 00` | `kTruncated` | `kTruncated` | 1 lần, 448 byte | 1 lần, 18 byte |
| (3) | `Hello.platform` enum bằng 0 | `07 00 00 00 01 01 00 00 01 00 00 04 03 02 01` | `kBadEnum` | `kBadEnum` | 0 lần | 1 lần, 15 byte |
| (4) | `ProbeFlag.flag` bool bằng 2 (bản chép) | `02 00 00 00 06 01 00 00 02 00` | `kBadEnum` | `kBadEnum` | 0 lần | 1 lần, 10 byte |
| (4) phụ | `Reader::boolean` trên byte `02` | không có khung | `kBadEnum` | trả 0, `finish` ra `kBadEnum` | 0 lần | không có |
| (5) | `ProbeFlag.maybe` optional, byte có mặt bằng 2 | `02 00 00 00 06 01 00 00 01 02` | `kBadEnum` | `kBadEnum` | 0 lần | 1 lần, 10 byte |
| (5b) phụ | optional bằng 1 nhưng thân hết | `02 00 00 00 06 01 00 00 00 01` | `kTruncated` | `kTruncated` | 0 lần | 1 lần, 10 byte |
| (5c) đối chứng | flag 1, maybe bằng 7 | `03 00 00 00 06 01 00 00 01 01 07` | OK | `OK(variant 5)` | 0 lần | 1 lần, 11 byte |
| (6) | `Hello` thân 0 byte (tin có 3 trường) | `00 00 00 00 01 01 00 00` | `kTruncated` | `kTruncated` | 0 lần | 1 lần, 8 byte |
| (7) | mã tin 0, thân rỗng, qua cả bốn bộ giải mã | `00 00 00 00 00 00 00 00` | `kUnknownKind` ở cả bốn | `kUnknownKind` ở cả bốn | 0 lần | 1 lần, 8 byte |
| (8) | `Hello` hợp lệ nhưng cờ bằng 1 | `07 00 00 00 01 01 01 00 01 00 02 04 03 02 01` | `kBadFlags` | `kBadFlags` ở `peek_frame` và `Channel::next` | không tới | 1 lần, 15 byte |
| (9) | thân khai `0xFFFFFFFF`, chỉ 8 byte đầu, trần client | `FF FF FF FF 01 01 00 00` | `kBodyTooLarge` | `kBodyTooLarge` | không tới | 1 lần, 8 byte |
| (9b) phụ | như (9), `Welcome` 0x8101, trần server 65.536 | `FF FF FF FF 01 81 00 00` | `kBodyTooLarge` | `kBodyTooLarge` | không tới | 1 lần, 8 byte |
| (10) | `CreateAccount.password` là `61 E1 BA` (dừng giữa ký tự ba byte U+1EA1) | `07 00 00 00 01 05 00 00 00 00 03 00 61 E1 BA` | `kBadText` | `kBadText` | 0 lần | 1 lần, 15 byte |

Cả bốn exe thoát 0, mỗi exe in "TỔNG: 0 ca lệch" (log dòng 131, 223, 257, 291).

Cấp phát của `Channel` ở mọi ca đúng bằng số byte đã nhận. Ca (2c) cấp phát 448 byte khi giải mã: đó
là `reserve` bị chặn bởi trần 8 phần tử, không theo số khai (log dòng 18 cho phép tới
`8*sizeof(CharacterSummary)`).

Trùng với test có sẵn (log dòng 37 tới 39): khung (9) trùng từng byte với `tests/protocol_tests.cpp`
dòng 334. Khung (8) khác byte với dòng 350. Các khung khác không có trong test.

Kết luận: **đạt**. Mười khung đều ra đúng tên lỗi, không ca nào cấp phát theo số khai.

### 2.3 Năm bảng sai và sáu ca thêm

Log: `so-do/r-bang-sai.log`, script `build/p2-r/bang_sai.py`. Mỗi ca chép `SRC/protocol/catalog` vào
`build/p2-r/bang-sai-<n>/`, sửa một chỗ, rồi chạy `gen_protocol.py --catalog <bản chép> --out
build/p2-r/out-<n>/`. Tiêu chí của script (log dòng 4): "mã thoát khác 0, có ít nhất một dòng dạng
`tệp:dòng: câu`, không có Python traceback". Bảng tóm tắt (log dòng 236 tới 247):

| số | lỗi cài | mã thoát | dòng lỗi đầu (hoặc dòng cuối traceback) | kết luận |
|---|---|---|---|---|
| 1 | BOM UTF-8 (`EF BB BF`) ở đầu `fields.tsv` | 1 | `build/p2-r/bang-sai-1/fields.tsv:1: [G1] tệp có BOM; phải là UTF-8 không BOM` | đạt |
| 2 | toàn bộ `messages.tsv` xuống dòng CRLF | 1 | `build/p2-r/bang-sai-2/messages.tsv:1: [G1] tệp có CR; chỉ dùng LF` | đạt |
| 3 | thừa một tab cuối dòng `Hello\t1\tversion...` (7 ô thay vì 6) | 1 | `build/p2-r/bang-sai-3/fields.tsv:13: [G1] có 7 ô, phải có 6` | đạt |
| 4 | underlying viết hoa `U8` ở hai dòng của enum `Gender` | 1 | `KeyError: 'U8'` | **phát hiện**: Python traceback thay cho lỗi `tệp:dòng` (V8) |
| 5 | kiểu có khoảng trắng thừa `u16 ` ở `Hello.version` | 1 | ``build/p2-r/bang-sai-5/fields.tsv:13: [G6] kiểu `u16 ` sai ngữ pháp`` | đạt |
| 6 | thêm: underlying `U8` ở ba dòng của enum `Platform` (không nằm trong list nào) | 1 | ``build/p2-r/bang-sai-6/enums.tsv:5: [G8] underlying `U8` phải là u8 hoặc u16`` | đạt |
| 7 | thêm: kind `0X0104` (X hoa) ở `Ping` | 1 | ``build/p2-r/bang-sai-7/messages.tsv:10: [G2] kind `0X0104` phải là `record` hoặc `0x` cộng 4 chữ số hex hoa`` | đạt |
| 8 | thêm: giá trị 256 trên enum u8 (`Platform Ios = 256`) | 1 | ``build/p2-r/bang-sai-8/enums.tsv:7: [G8] giá trị `256` phải từ 1 đến 255`` | đạt |
| 9 | thêm: `optional:optional:u8` thay kiểu u32 của `Hello.build` | 0 | (không in gì) | **phát hiện**: bảng được chấp nhận (N12) |
| 10 | thêm: limit âm `-1` ở `Login.account` | 1 | ``build/p2-r/bang-sai-10/fields.tsv:16: [G7] kiểu `text` cần limit từ 1 đến 65535`` | đạt |
| 11 | thêm: id nhóm ba chữ số `005` | 1 | ``build/p2-r/bang-sai-11/groups.tsv:7: [G2] id nhóm `005` phải là hai chữ số hex hoa từ 00 đến 7F`` | đạt |

Ca 1 tới 5 là năm bảng sai chính, mỗi ca kèm lý do chọn để không trùng ca G1 tới G11 nào (log dòng
7, 23, 59, 75, 115). Ca 4 vẫn bị từ chối: mã 1, log dòng 76 ghi "có tệp được ghi: False". Nhưng
output là traceback (log dòng 88 tới 111), kết thúc:

```
  File "F:\tl 2026\THIENLONG\build\p2-dot-2\TOOLS\server\protocol_rules.py", line 296, in least_bytes
    return UNDERLYING_BYTES[enums[ref.name].underlying] if ref.name in enums else 1
           ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^
KeyError: 'U8'
```

Ca 9 ghi tệp ra `build/p2-r/out-9/`: `SRC/protocol/messages.hpp` dòng 132 là
`std::optional<std::optional<std::uint8_t>> build;`.

Kết luận: 9 trên 11 ca đạt. Ca 4 lộ lỗi của công cụ (V8); ca 9 lộ chỗ đề bài để ngỏ (N12).

### 2.4 T17: 19 tin so với `protocol.hpp` của Dev

Nguồn Dev: `G:/TLBB/Dev/src/protocol/protocol.hpp`. Nguồn của ta: `SRC/protocol/catalog/fields.tsv`.
Dev không có trần cho số nguyên nên cột trần ghi "–". Cột note tóm nội dung `note` của `fields.tsv`
kèm nhận xét của R.

| tin | trường | kiểu Dev | kiểu của ta | trần Dev | trần của ta | dòng của Dev | note |
|---|---|---|---|---|---|---|---|
| CharacterSummary | id | `CharacterId` (enum class : u64) | u64 | – | – | 337 | "CharacterId của Dev." Mất kiểu ID mạnh (bảng kiểu §3.2 không có), byte giữ nguyên |
| CharacterSummary | name | text | text | `kNameBytes` = 48 | 48 | 338 | khớp |
| CharacterSummary | level | u16 | u16 | – | – | 339 | khớp |
| CharacterSummary | gender | `Gender` (u8) | enum:Gender (u8) | – | – | 340 | khớp |
| CharacterSummary | face | u16 | u16 | – | – | 341 | khớp kiểu. **Note sai nghĩa**: "0 là mặt mặc định (kDefaultLook của Dev)" (N1) |
| CharacterSummary | hair | u16 | u16 | – | – | 342 | như `face` |
| CharacterSummary | school | u8 | u8 | – | – | 343 | giá trị canh 0 là "chưa gia nhập" (Dev 332), note có ghi |
| CharacterSummary | scene | `SceneId` (enum class : u16) | u16 | – | – | 344 | "SceneId của Dev". Mất kiểu ID mạnh, byte giữ nguyên |
| Hello | version | u16 | u16 | – | – | 478 | khớp |
| Hello | platform | `Platform` (u8) | enum:Platform | – | – | 479 | khớp |
| Hello | build | u32 | u32 | – | – | 480 | khớp |
| Login | account | text | text | `kAccountBytes` = 64 | 64 | 492 | khớp |
| Login | ticket | text | text | `kTicketBytes` = 512 | 512 | 493 | khớp |
| Resume | token | `SessionToken` (byte[16]) | bytes | `kTokenBytes` = 16 | 16 | 503 | khớp |
| Ping | client_time | `Milliseconds32` (duration<u32, milli>) | millis32 (`std::chrono::milliseconds`, có dấu) | – | – | 512 | byte giữ nguyên; ghi giá trị âm hay lớn hơn 0xFFFFFFFF là `kOutOfRange`. Lý do ở DE-BAI §3.5, **note không ghi** (N2) |
| Logout | (không trường) | – | – | – | – | 516–521 | thân rỗng, khớp |
| CreateCharacter | name | text | text | 48 | 48 | 535 | khớp |
| CreateCharacter | gender | Gender | enum:Gender | – | – | 536 | khớp |
| CreateCharacter | face | u16 (`kDefaultLook` = 0) | u16 | – | – | 537 | giá trị canh 0 có ghi, đúng với Dev 523–525 |
| CreateCharacter | hair | u16 (`kDefaultLook`) | u16 | – | – | 538 | như `face` |
| DeleteCharacter | character | `CharacterId` (u64) | u64 | – | – | 547 | "CharacterId của Dev" |
| EnterGame | character | `CharacterId` (u64) | u64 | – | – | 556 | "CharacterId của Dev" |
| CreateAccount | account | text | text | 64 | 64 | 1085 | khớp |
| CreateAccount | password | text | text | `kPasswordBytes` = 128 | 128 | 1086 | khớp |
| SignIn | account | text | text | 64 | 64 | 1097 | khớp |
| SignIn | password | text | text | 128 | 128 | 1098 | khớp |
| Welcome | version | u16 | u16 | – | – | 697 | khớp |
| Welcome | server_time | `Milliseconds64` (duration<**u64**, milli>, Dev:68) | millis64 (**i64**) | – | – | 698 | đọc giá trị lớn hơn INT64_MAX là `kOutOfRange`. Lý do chỉ ở BAO-CAO-C §9 và §10.3, **note không ghi** (N2) |
| Welcome | heartbeat | `Seconds16` (duration<u16>) | seconds16 | – | – | 699 | như `Ping.client_time` |
| SessionStart | token | `SessionToken` | bytes | 16 | 16 | 709 | khớp |
| ContentKey | key | byte[`kContentKeyBytes`] | bytes | 32 | 32 | 720 | khớp |
| Pong | client_time | `Milliseconds32` | millis32 | – | – | 730 | như `Ping.client_time` |
| Pong | server_time | `Milliseconds64` (u64) | millis64 (i64) | – | – | 731 | như `Welcome.server_time` |
| Reject | request | `ClientKind` (enum u16, có `is_valid`) | u16 | – | – | 742 | note có lý do: "để u16 thay vì enum để giữ nguyên byte của Dev…". Khác hành vi: Dev trả `kBadEnum` với mã lạ, ta nhận mọi u16 (BAO-CAO-C §10.1) |
| Reject | code | `ErrorCode` (u16) | enum:ErrorCode (u16) | – | – | 743 | 32 giá trị, tên và số trùng Dev 173–212 |
| Goodbye | reason | `DisconnectReason` (u8) | enum:DisconnectReason | – | – | 752 | 9 giá trị trùng Dev 215–227 |
| ContentStamp | stamp | byte[`kContentStampBytes`] | bytes | 32 | 32 | 900 | khớp |
| CharacterList | characters | list<CharacterSummary> | list:record:CharacterSummary | `kCharacterSlots` = 8 | 8 | 761 | khớp |
| Ticket | token | byte[`kConnectTokenBytes`] | bytes | 204 | 204 | 1108 | khớp |

Đếm:

| mục | Dev | của ta |
|---|---|---|
| tin | 19 (client 10, server 9) | 19 (client 10, server 9) |
| trường | 38 (30 trong tin, 8 trong record) | 38 |
| record | 1 | 1 |
| enum | 5 | 4 (bỏ `ClientKind`, vì `Reject.request` là u16) |
| giá trị `ErrorCode` | 32 | 32 |
| giá trị `DisconnectReason` | 9 | 9 |

- Lệch trần: 0 dòng. Lệch byte trên dây: 0 dòng.
- Lệch kiểu: 10 dòng. Gồm `Reject.request` (1 dòng), thời lượng (5 dòng), ID mạnh thành số
  trần (4 dòng).
- Lý do của 10 dòng lệch kiểu:
  - `Reject.request`: note có lý do.
  - 4 dòng ID: note nêu tên kiểu Dev; lý do là bảng kiểu §3.2 không có kiểu ID.
  - 5 dòng thời lượng: DE-BAI §3.5 bắt khai bằng kiểu thời lượng. Riêng lệch dấu của millis64 chỉ có
    ở báo cáo C. Không dòng nào ghi lý do trong cột `note` (N2).
- Cổng khớp Dev: biến thể auth của Dev (1113–1124); `Hello`, `Welcome`, `Reject`, `Goodbye` là
  `both`. Mã kind đúng theo `messages.tsv`.

Kết luận T17: không có trường nào lệch mà không có lý do ở đâu cả. Theo đúng chữ của T17 ("0 trường
lệch không có lý do ghi ở cột `note`"), năm dòng thời lượng còn thiếu lý do trong cột `note` (N2).

### 2.5 Tìm `sleep_for`, `Sleep(`, `this_thread` trong `tests/`

Lệnh (chạy 10:01, cây hiện tại):
`Get-ChildItem -LiteralPath 'tests' -Recurse -File | Select-String -Pattern 'sleep_for','Sleep(','this_thread' -SimpleMatch`

```
\audio_tests.cpp:564: std::this_thread::sleep_for(std::chrono::milliseconds(400));
\net_tests.cpp:3: // Nguồn: danh sách ca của TLBB Dev tests/platform/socket_test.cpp, viết lại không sleep_for.
\service_tests.cpp:52: std::this_thread::sleep_for(std::chrono::milliseconds{10});
\window_tests.cpp:161: std::this_thread::sleep_for(kStep);
\window_tests.cpp:334: std::this_thread::sleep_for(std::chrono::milliseconds{50});
\wire_loop_tests.cpp:7: // sleep_for, không có vòng thử lại theo giờ: số vòng có trần, hết trần là test đỏ.
\support\server_child.cpp:118: std::this_thread::sleep_for(std::chrono::milliseconds{options.ready_delay_ms.value_or(0)});
\support\server_child.cpp:123: void sleep_forever() {
\support\server_child.cpp:125: std::this_thread::sleep_for(std::chrono::seconds{1});
\support\server_child.cpp:131: std::this_thread::sleep_for(std::chrono::milliseconds{10});
\support\server_child.cpp:146: if (options.ignores_stop) sleep_forever();
```

So với `git -c safe.directory=* ls-files tests`:

- Có từ trước (tracked): `audio_tests.cpp`, `service_tests.cpp`, `window_tests.cpp`,
  `support/server_child.cpp`.
- Tệp mới (untracked): `net_tests.cpp:3` và `wire_loop_tests.cpp:7`. Cả hai chỉ là chú thích, không
  có lời gọi ngủ nào.

Kết luận: theo đúng chữ của mục 6 ("các tệp mới phải ra 0 dòng"), tệp mới ra **2 dòng**, nên
**không đạt** (V7).

### 2.6 `net_tests` hai mươi lần

Log: `so-do/r-net-lap-20.log`, cây `build/p2-r`, preset `clang-asan`. Trích dòng 1 tới 3:

```
# bắt đầu 2026-10-08 09:45:11 (UTC+7); lệnh nhẹ, cây build/p2-r (preset clang-asan)
# lệnh: ctest --test-dir build/p2-r -R "^net_tests$" --repeat until-fail:20 --output-on-failure
# xong 09:46:01, mã thoát 0, số dòng Passed: 20, tổng thời gian đồng hồ tường 50 s
```

Cuối log:

```
100% tests passed out of 1

Total Test time (real) =  49.98 sec
```

Mỗi lượt từ 2.48 tới 2.54 giây. Kết luận: **20/20 xanh**.

Lượt này chạy **không giữ `NANG.lock`** và chồng lên lệnh của L (N13). T13 chính thức trên
`msvc-release` là của L (`KET-QUA.md`, dòng T13, log `so-do/l-t13.log`).

### 2.7 T11, kiểm lại

`so-do/fuzz.tsv` (mtime 02:30:39):

```
target	runs	seconds	runs_per_s	cov	ft	corpus_files	exit_code
frame	1000000	51.49	19419	83	390	134	0
game_client	1000000	4.52	221375	231	390	110	0
game_server	1000000	9.70	103095	269	580	118	0
auth_client	1000000	3.81	262419	179	321	102	0
auth_server	1000000	2.82	354098	123	146	69	0
```

Các tệp `so-do/fuzz-*.log` (mtime 02:30:18 tới 02:30:39) đều có dòng
`Done 1000000 runs in N second(s)`, seed 20261008, không có dòng `ERROR` hay crash:

| tệp | dòng | thời gian |
|---|---|---|
| `fuzz-frame.log` | 222 | 51 s |
| `fuzz-game_client.log` | 215 | 4 s |
| `fuzz-game_server.log` | 259 | 9 s |
| `fuzz-auth_client.log` | 170 | 3 s |
| `fuzz-auth_server.log` | 64 | 2 s |

Mã được fuzz là mã cuối của phần protocol. Mọi nguồn được fuzz có mtime trước 02:29:11: `wire.cpp`
và `wire.hpp` 02:22:02, `tests/fuzz/*` 02:20:08, `messages.cpp` 01:52:02, `messages.hpp` 01:58:10,
`channel.*` 01:44 và 01:51, `fuzz_protocol.py` 02:28:35. Từ đó tới lúc viết, không tệp nào trong số
đó đổi.

`so-do/l-fuzz-tang-hai.log` có dòng đầu
`# 2026-10-08 02:29:11 -> 2026-10-08 02:30:39 fuzz tầng hai, giữ NANG.lock, …`, cùng năm dòng số
trên và `exit 0`. Nhưng tệp này đã được ghi lại lúc 09:12:38 (V4). Mã thoát của từng đích có ở
`fuzz.tsv` gốc.

Kết luận T11: **đạt**.

### 2.8 `wire.hpp` so với hợp đồng

Lệnh:
`git -c safe.directory=* diff --no-index docs/giao-viec/P2-DOT-2/hop-dong/wire.hpp SRC/protocol/wire.hpp`.
Kết quả `--stat` (chạy lại 10:01): `1 file changed, 21 insertions(+), 1 deletion(-)`. Phần khác:

- Thay comment đầu tệp (dòng `Nguồn:` và `Khác gốc:`).
- Thêm `#include <concepts>`.
- Thêm phần `private` của `Writer`: `template <std::unsigned_integral Value> void put(Value)`,
  `void append(ByteView)`, `body_bytes()`.
- Thêm phần `private` của `Reader`: `ByteView take(std::size_t)`.
- Thêm một comment trước `count`: "Số vượt số byte còn lại là kTruncated: mỗi phần tử ít nhất 1
  byte, theo G6."

**Không đổi chữ ký công khai nào.** BAO-CAO-A §4 khai đúng như vậy.

Phần cài đặt trong `wire.cpp` cũng đúng mục 3.3:

- Mọi phép đọc kiểm số byte còn lại trước khi đọc. `text` kiểm trần rồi mới cấp phát.
- `count` trả `kTooLong` trước `kTruncated`.
- Bảng byte đầu UTF-8 đúng RFC 3629: cấm 0, 80–C1, F5–FF; ràng buộc byte hai sau E0, ED, F0, F4.
- f32 kiểm `isfinite` cả hai chiều.
- `Writer::append` báo `kBodyTooLarge` ở lần nối làm vượt trần. `finish` có lỗi thì cắt `out`.
- `peek_frame`:
  - dưới 8 byte là chưa có khung;
  - cờ khác 0 là `kBadFlags`;
  - thân lớn hơn `min(max_body, kMaxBodyBytes)` là `kBodyTooLarge`;
  - thân chưa đủ là chưa có khung.

### 2.9 Lượt đỏ của `wire_loop`

L cài lỗi trong `build/p2-l/red/channel_red.cpp`:

- Dòng 56, `receive` bỏ byte cuối, chỉ với mẩu dài đúng 7 byte:
  `inbox_.insert(inbox_.end(), bytes.begin(), bytes.end() - (bytes.size() == 7 ? 1 : 0));`
- Dòng 64, `next` giữ khung khi số byte đang có bằng đúng 8:
  `if (view.size() <= kHeaderBytes) return std::nullopt;`

Log `so-do/l-wire-loop-do.log` (09:12:28):

```
tests\wire_loop_tests.cpp:208: [pieces_of_7_bytes] kênh không báo lỗi
tests\wire_loop_tests.cpp:209: [pieces_of_7_bytes] nhận đủ khung của mọi mẫu
tests\wire_loop_tests.cpp:210: [pieces_of_7_bytes] mọi khung giải mã ra đúng giá trị gốc
tests\wire_loop_tests.cpp:253: [oversized_body_fails_after_header] đủ 8 byte đầu: kênh báo kBodyTooLarge, không chờ thân
tests\wire_loop_tests.cpp:270: check thất bại: wire_loop_tests
exit=-1073740791 ms=596
```

Log xanh `l-wire-loop-xanh.log` thoát 0 lúc 09:12:29. Lượt 2 lúc 09:13:13, sau khi thêm
`#include <expected>`; số dòng lệch đi 1.

Đánh giá:

- Ca 1 byte và ca 4096 byte vẫn xanh là đúng dự kiến, vì lỗi (1) được cài riêng cho mẩu 7 byte.
- Ba ca chia mẩu đều so đủ nội dung, kind và số khung (`checked == 57`, `wrong == 0`). Vì vậy chúng
  bắt được mất, hỏng hay đảo thứ tự khung.
- Điểm yếu:
  - Không ca nào kiểm khung có được trả ngay khi byte cuối của nó tới hay không.
  - Không luồng nào kết thúc bằng khung thân rỗng.
- Hệ quả: lỗi (2) lọt qua cả ba ca chia mẩu. Nó lọt luôn `protocol_tests` `channel_byte_by_byte`, vì
  khung thân rỗng ở giữa luồng. Chỉ ca quá cỡ và `channel_broken_frame_is_final` bắt được nó.

Kết luận: lượt đỏ có thật và bắt được lỗi (1). Với lớp lỗi "trả khung muộn" thì độ phủ yếu (V6).

## 3. Finding theo mức

Mỗi finding ghi: chỗ, trích, lý do (luật), cách sửa, người sửa.

### Nặng

Không có. Bằng chứng:

- T12 đạt (2.1). Mười khung đạt, không cấp phát theo số khai (2.2). T11 đạt (2.7).
- `net_tests` xanh 20/20 (2.6). `wire.hpp` không đổi chữ ký công khai (2.8).
- T17: 0 lệch trần, 0 lệch byte trên dây (2.4).
- Hai tệp CMake chỉ thêm dòng: `git diff --no-index` với `moc/CMakeLists.txt` ra 43 dòng thêm, 0
  dòng xoá; với `moc/GameLayers.cmake` ra 2 dòng thêm.
- T15: header mạng chỉ ở hai tệp socket, cộng ngoại lệ có từ trước
  `SRC/process/process_posix.cpp:32`.

### Vừa

**V1. NOLINT thiếu mã quy tắc.**

- Chỗ:
  - `SRC/net/socket_win32.cpp:68, 73, 78, 83, 89, 97, 277, 315`
  - `SRC/net/socket_posix.cpp:72, 77, 95, 97, 99, 280, 322` (bản 09:59:35)
  - `SRC/net/net.cpp:34`
- Trích: `// NOLINTNEXTLINE(cppcoreguidelines-pro-type-reinterpret-cast): hợp đồng Winsock`;
  `// NOLINTNEXTLINE(readability-make-member-function-const): đổi trạng thái socket của hệ điều hành`.
- Lý do: `AGENTS.md` mục 5 đòi NOLINT nêu check, lý do và mã quy tắc. Các dòng trên chỉ có check và
  lý do. Mã sinh làm đúng: `messages.hpp` có `(HP-07)`.
- Cách sửa: thêm mã quy tắc vào cuối từng dòng.
- Người sửa: B.

**V2. Bộ sinh có thể cắt một `case` ra hai hàm.**

- Chỗ:
  - `TOOLS/server/protocol_cpp_src.py:227`:
    `parts = chunks([line for message in messages for line in decode_case(message)], PART)`
  - `protocol_cpp_src.py:204`: `decode_case` gọi `one_line_or_wrapped(...)`, có thể ra 2 dòng.
  - `protocol_cpp_src.py:16`: `PART = 30`.
  - `TOOLS/server/protocol_cxx.py:143`: `def chunks`.
- Lý do: `chunks` cắt danh sách dòng phẳng. Một `case` bị bẻ hai dòng có thể rơi vào hai phần: nhãn
  `case` ở phần i, `return` ở phần i+1. Mã sinh ra sẽ không dịch được.
  - Hiện chưa xảy ra: mỗi bộ giải mã có tối đa 8 ca.
  - Không test nào chạy qua nhánh chia phần của bộ giải mã. Danh mục thử `Probe` có 20 trường.
  - BAO-CAO-C §8 không nêu chỗ này.
  - DE-BAI §3.6: "tin nhiều trường thì công cụ tách hàm", và mã sinh phải dịch được.
- Cách sửa: chia theo đơn vị ca (`list[list[str]]`), không theo dòng. Thêm test sinh hơn 30 ca có
  tên dài để buộc bẻ dòng.
- Người sửa: C.

**V3. `fuzz_protocol.py` ghi đè log của lượt trước.**

- Chỗ:
  - `TOOLS/server/fuzz_protocol.py:208`:
    `(SO_DO / f"fuzz-{target.name}.log").write_text(log, encoding="utf-8", newline="\n")`
  - `fuzz_protocol.py:236`: `write_tsv(SO_DO / "fuzz.tsv", outcomes)`
- Lý do: DE-BAI §7: "lượt nào đã chạy thì log của nó nằm trong `so-do/`". Chạy lại là mất bằng chứng
  T11 hiện có. R đã phải viết `rang.py` riêng vì chỗ này (`r-rang.log` dòng 2).
- Cách sửa: thêm giờ hoặc số lượt vào tên tệp, hoặc từ chối chạy khi tệp đã có.
- Người sửa: L.

**V4. Log đã chạy bị viết lại.**

- Chỗ: `so-do/l-fuzz-tang-hai.log`.
  - Nội dung ghi lượt `02:29:11 -> 02:30:39`, nhưng mtime là 09:12:38.
  - `build/lich-nang.tsv` dòng 13 còn chữ lỗi mã hoá "táº§ng", dấu vết của bản gốc.
- Lý do: trái luật không sửa log đã chạy (DE-BAI §7, cùng luật 09:20 của L).
  - Lúc R đọc mã, chưa vai nào khai việc này. A và C đã tự khai việc chạm log của mình.
  - Bản nháp `KET-QUA.md` (09:57–09:58) nay đã khai ở dòng 150: "Dòng đầu của
    `so-do/l-fuzz-tang-hai.log` được ghi lại sang UTF-8. Chỉ đổi mã hoá của dòng đó, nội dung giữ
    nguyên." Dòng khai chưa ghi giờ sửa.
- Cách sửa: ghi giờ sửa (09:12:38) vào `KET-QUA.md`. Coi `fuzz.tsv` và `fuzz-*.log` (mtime 02:30) là
  bằng chứng chính của T11. L nhận lệch này một cách rõ ràng.
- Người sửa: L.

**V5. `socket_posix.cpp` chưa qua `check.py`.**

- Chỗ: BAO-CAO-B dòng 67: "`socket_posix.cpp`: không đưa vào `check.py` vì không dịch được trên
  Windows; đã qua clang-format và T14."
- Cập nhật: T6 của L lúc 09:56:03 (`so-do/l-t6.log`) đã chạy `check.py` trên tệp này:
  - Độ lồng qua (dòng 33).
  - g14 và c20 dừng ở `fatal error: arpa/inet.h` (dòng 35, 40).
  - clang-tidy báo lỗi ở dòng 45 tới 59: `misc-include-cleaner`, `readability-identifier-length`
    (`fd`), `misc-const-correctness`, `readability-implicit-bool-conversion`.
  - `KET-QUA.md` ghi T6 "không đạt (1 trên 27 tệp)".
  - Tệp đổi lúc 09:59:35 (`fd` thành `descriptor`), chưa ai chạy lại.
- Lý do: T6 đòi `check.py` 0 lỗi trên mọi tệp C++ mới.
- Cách sửa: chạy lại `check.py` sau khi sửa. Cho clang-tidy chạy với `--target` và sysroot của NDK
  để bỏ lỗi giả do thiếu header. Nếu vẫn không chạy được thì L ghi lệch có lý do.
- Người sửa: B (L quyết cách chấm).

**V6. `wire_loop` không bắt được lỗi trả khung muộn.**

- Chỗ:
  - `tests/wire_loop_tests.cpp:210–211`:
    `context.expect(loop.checked == samples::kSamples.size(), "nhận đủ khung của mọi mẫu");` và
    `context.expect(loop.wrong == 0, ...)`
  - Các ca `pieces_of_1_byte`, `pieces_of_7_bytes`, `pieces_of_4096_bytes` (dòng 214–225).
- Lý do: chỉ kiểm tổng ở cuối. Lỗi (2) của lượt đỏ (giữ khung khi có đúng 8 byte) lọt qua cả ba ca
  (mục 2.9). `wire_loop` sinh ra để soi ghép kênh và socket (DE-BAI §4, L).
- Cách sửa: sau mỗi lần `receive`, kiểm số khung đã giải mã bằng số khung đã nhận đủ byte. Thêm một
  luồng kết thúc bằng tin thân rỗng (`Logout`).
- Người sửa: L.

**V7. Tìm sleep ra 2 dòng ở tệp mới.**

- Chỗ:
  - `tests/net_tests.cpp:3`: "viết lại không sleep_for."
  - `tests/wire_loop_tests.cpp:7`: "// sleep_for, không có vòng thử lại theo giờ: ..."
- Lý do: DE-BAI §6: "các tệp mới phải ra 0 dòng". Không có lời gọi ngủ thật, nhưng tiêu chí là phép
  tìm chữ, nên theo đúng chữ là không đạt.
- Cách sửa: viết lại hai chú thích, ví dụ "không ngủ cố định".
- Người sửa: B (`net_tests.cpp`), L (`wire_loop_tests.cpp`).

**V8. `gen_protocol.py` sập bằng traceback ở bảng sai số 4.**

- Chỗ: `so-do/r-bang-sai.log` dòng 74 tới 112.
  - Lỗi cài: enum `Gender` có underlying viết hoa `U8`. `Gender` nằm trong record
    `CharacterSummary`, là phần tử list của `CharacterList`.
  - Output kết thúc bằng `KeyError: 'U8'` thay cho dòng `tệp:dòng: câu`.
  - Bảng vẫn bị từ chối: mã 1, không ghi tệp nào.
  - Ca đối chứng 6 (`U8` ở `Platform`, không nằm trong list) báo đúng
    ``build/p2-r/bang-sai-6/enums.tsv:5: [G8] underlying `U8` phải là u8 hoặc u16``.
- Nguyên nhân (R đọc mã):
  1. `TOOLS/server/protocol_rules.py:151` ghi lỗi G8 cho underlying lạ, nhưng enum vẫn được dựng:
     dòng 174 `underlying.setdefault(name, row.cells["underlying"])` giữ `U8`, và dòng 176–179 tạo
     `Enum(name, underlying[name], ...)`.
  2. `build_catalog` gọi `check_list_elements(...)` ở dòng 379, trước dòng 380 `if problems:` và
     dòng 381 `return None`.
  3. `check_list_elements` (dòng 313) gọi `least_bytes` cho phần tử list. `least_bytes` đi vào
     record (dòng 306), rồi tới dòng 296
     `return UNDERLYING_BYTES[enums[ref.name].underlying] if ref.name in enums else 1`.
  4. `UNDERLYING_BYTES` (`TOOLS/server/protocol_model.py:15`) chỉ có `"u8"` và `"u16"`, nên ném
     `KeyError`.
  5. `TOOLS/server/gen_protocol.py:48` gọi `build_catalog` vì bảng đã qua G1. Không có chỗ nào bắt
     ngoại lệ.
- Lý do: DE-BAI §3.5: "Công cụ từ chối bảng sai … lỗi in ra dạng `tệp:dòng: câu`".
- Cách sửa: dừng trước `check_list_elements` khi đã có lỗi (chuyển khối `if problems: return None`
  lên trước dòng 379), hoặc bỏ qua enum có underlying sai trong `least_bytes`. Thêm test hồi quy vào
  `test_gen_protocol.py`: enum có underlying sai nằm trong phần tử list, mong đợi dòng `[G8]` và
  không có traceback. Hiện test chưa có ca underlying sai nào.
- Người sửa: C.

### Nhẹ

**N1. Note của `CharacterSummary.face` và `hair` sai nghĩa.**

- Chỗ: `SRC/protocol/catalog/fields.tsv:9–10`, "0 là mặt mặc định (kDefaultLook của Dev)".
- Lý do: Dev `protocol.hpp:523–524`: "Mặt, tóc trong CreateCharacter: kDefaultLook là mặc định của
  giới …, server thay bằng id thật trước khi lưu." Trong `CharacterSummary`, face và hair là id
  thật. Note này đi thẳng vào `docs/PROTOCOL-TIN.md`.
- Cách sửa: bỏ câu về giá trị 0 ở record.
- Người sửa: C.

**N2. Note của năm trường thời lượng không nêu lý do lệch kiểu.**

- Chỗ: `fields.tsv:19, 31, 32, 35, 36`.
- Lý do: T17 đòi lý do ở cột `note`. Lệch u64 sang i64 của millis64 chỉ ghi ở BAO-CAO-C §9 và §10.3.
- Cách sửa: thêm một câu vào note, ví dụ "u64 của Dev; > INT64_MAX là kOutOfRange".
- Người sửa: C.

**N3. Chữ ký hàm bị bẻ dòng.**

- Chỗ:
  - `tests/protocol_fuzz_tests.cpp:115` `[[nodiscard]] std::size_t miss(`
  - `tests/fuzz/targets.hpp:83` `[[nodiscard]] inline bool give(`
  - `tests/bench/bench.hpp:17, 22` (`seconds_between(`, `micros_between(`)
  - Tệp sinh `tests/protocol_samples.hpp:875, 940, 1079, 1289, 1616, 1716`, ví dụ
    `encode_create_character_typical(`.
- Lý do: `AGENTS.md` mục 7: "Chữ ký nằm trọn một dòng ≤ 100 cột; … không để bẻ bậc thang".
  `check.py` không bắt lỗi này.
- Cách sửa: rút tên hoặc dùng `using` alias. Với tệp sinh, sửa `protocol_samples.py`.
- Người sửa: L (ba tệp tay), C (bộ sinh).

**N4. Test độ dài hàm của bộ sinh bỏ sót chữ ký bẻ dòng.**

- Chỗ: `TOOLS/server/test_gen_protocol.py:316–321`. Đầu hàm chỉ được nhận khi
  `line.endswith("{") and "(" in line`.
- Lý do: hàm có chữ ký bẻ dòng bị bỏ qua. Không có test cho độ lồng.
- Cách sửa: nhận đầu hàm theo dòng mở `{` sau một chữ ký nhiều dòng.
- Người sửa: C.

**N5. Hộp nhận có thể chiếm bộ nhớ vượt trần.**

- Chỗ: `SRC/protocol/channel.cpp:56` `inbox_.insert(inbox_.end(), bytes.begin(), bytes.end());`
- Lý do: không `reserve` theo trần, nên vector có thể nới dung lượng vượt `inbox_bytes`. Số byte đã
  kiểm vẫn đúng trần.
- Cách sửa: `reserve(limits_.inbox_bytes)` lúc tạo, hoặc ghi rõ đó là trần nội dung.
- Người sửa: A.

**N6. Bộ giải mã sinh ra không dùng `frame.body_bytes`.**

- Chỗ: `SRC/protocol/messages.cpp:483, 498, 513` `Reader reader{body};` (sinh từ
  `protocol_cpp_src.py:213, 239`).
- Lý do: không đối chiếu cỡ thân với đầu khung. Vô hại khi thân đến từ `peek_frame`.
- Cách sửa: kiểm `body.size() == frame.body_bytes` ở đầu bộ giải mã. Thiếu thì trả `kTruncated`,
  thừa thì trả `kTrailingBytes`.
- Người sửa: C.

**N7. `RESERVED_TYPES` thiếu tên của kênh.**

- Chỗ: `TOOLS/server/protocol_rules.py:31–35`.
- Lý do: thiếu `Channel`, `ChannelError`, `ChannelLimits`, `InFrame`, `NextFrame`, `ChannelStatus`,
  nên bảng có thể đặt tên tin trùng tên lớp của `channel.hpp`.
- Cách sửa: thêm các tên đó.
- Người sửa: C.

**N8. POSIX đặt cờ không nguyên tử.**

- Chỗ: `SRC/net/socket_posix.cpp:94–100` (`prepare`: `fcntl` đặt `O_NONBLOCK` rồi `FD_CLOEXEC` sau
  `socket()`), dòng 326 `::accept(...)`.
- Lý do: có kẽ hở với `fork`/`exec` ở luồng khác.
- Cách sửa: dùng `SOCK_NONBLOCK | SOCK_CLOEXEC` và `accept4` khi nền có.
- Người sửa: B.

**N9. Câu `if` hai dòng không ngoặc nhọn.**

- Chỗ: `SRC/net/socket_posix.cpp:309–310`
  `if (!set_option(descriptor, SOL_SOCKET, SO_REUSEADDR, enabled))` rồi xuống dòng
  `return std::unexpected(NetError::kSocket);`
- Lý do: kiểu viết; các chỗ khác viết một dòng hoặc có ngoặc.
- Cách sửa: gộp một dòng hoặc thêm ngoặc.
- Người sửa: B.

**N10. `fuzz_protocol.py` không chỉ được bản chép mã.**

- Chỗ: `TOOLS/server/fuzz_protocol.py:27` `PROTOCOL = PROJECT / "SRC" / "protocol"`.
- Lý do: muốn chạy bộ dò có răng (§3.8) thì phải viết script khác, như `rang.py` của R.
- Cách sửa: thêm `--source` và `--out`.
- Người sửa: L.

**N11. Báo cáo còn số cũ.**

- Chỗ:
  - BAO-CAO-C dòng 22 (`Ran 239 tests`, "23 test"), dòng 30 và 176 (`protocol_rules.py` 359 dòng),
    dòng 179 (23 test). §11 đã có số mới nhưng các bảng cũ chưa sửa.
  - `NGUON.md` chưa có tệp port của L (`tests/fuzz/mutator.hpp`, `targets.hpp` port từ
    `tests/protocol_fuzz_test.cpp` của Dev).
- Lý do: DE-BAI §8: "Mỗi báo cáo vai được cập nhật sau lần sửa cuối"; danh sách tệp port nằm ở
  `NGUON.md`.
- Cách sửa: sửa các bảng cũ; thêm dòng của L vào `NGUON.md`.
- Người sửa: C, L.

**N12. `optional:optional:u8` được chấp nhận.**

- Chỗ: `so-do/r-bang-sai.log` dòng 185 tới 198. Ca 9 thoát 0 và sinh
  `std::optional<std::optional<std::uint8_t>> build;`
  (`build/p2-r/out-9/SRC/protocol/messages.hpp:132`).
- Lý do: DE-BAI §3.5 G6 chỉ cấm "`list` và `optional` không bọc `list`", nên đề bài để ngỏ. Dev
  không dùng kiểu này. Không có test.
- Cách sửa: L quyết. Hoặc cấm `optional` bọc `optional` (thêm vào G6 và test), hoặc ghi là được phép
  kèm test mã hoá hai byte cờ.
- Người sửa: L quyết, C làm.

**N13. Quy trình: R chạy lệnh không giữ `NANG.lock`.**

- Các lệnh của R không giữ khoá:
  - Dựng `clang-asan` (09:44:54–09:45:02, `r-dung.log`).
  - `net_tests` 20 lần (09:45:11–09:46:01).
  - Sinh mã probe, bốn probe khung tay, bảng sai (09:49–09:52).
- Hai lệnh đầu chồng lên lệnh của L:
  - Dòng 17 `lich-nang.tsv`: ctest clang-asan lượt 2, 09:45:06–09:45:35.
  - Dòng 18: đo Đ1 tới Đ4 lần đầu, 09:45:45–09:46:00.
- L đã đo lại sạch ở dòng 20 (09:49:40–09:49:54, "có kiểm tiến trình") và khai ở
  `KET-QUA.md` dòng 158.
- Ba lệnh sau của R không chồng dòng nào của L: dòng 20 xong 09:49:54, dòng 21 bắt đầu 09:52:05.
- Đã khai bù: dòng 24 và 25 (khai lúc trước) và dòng 28 tới 30 (khai trong lúc viết báo cáo này) của
  `build/lich-nang.tsv`.
- Hai lượt T12 (dòng 22 và 23, 09:54:06–09:55:29) có giữ khoá (`r-rang.log` dòng 1).
- Lý do: DE-BAI §3.9, điều phối máy.
- Cách sửa: từ nay mọi lệnh dựng, test hay đo của R đều lấy khoá trước.
- Người sửa: R.

### Trạng thái ở bước 4 (R, ghi 10:45, rà đọc mã xong 10:58)

Phần này viết ở bước 4. Mục 1 tới 4 ở trên giữ nguyên như lúc viết ở bước 2. Phần rà đọc mã (từ
10:42) chỉ đọc tệp, `Select-String` và log của các vai; không chạy tiến trình dựng hay test nào.
Build & Test giữ NANG.lock từ 10:43:49.

**Chạy lại trên mã cuối.** Tất cả chạy trong một phiên NANG.lock của R, từ 10:36:11 tới 10:39:36.
Không qua `dev.bat`. Lịch: sáu dòng R trong `build/lich-nang.tsv` (dòng 77 tới 82), từ 10:36:26 tới
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
## 5. Phán quyết

### Phán quyết cuối 11:02

**ĐẠT (nhận).** Không có finding nặng. Không còn finding vừa nào mở: V1, V2, V3, V6, V7, V8 đã sửa;
V4, V5 đã được chấp nhận. Mọi mục còn mở đều là mục nhẹ, và L đã quyết dời sang vòng sau (danh sách
dưới).

Cơ sở: kết quả chạy lại của R ở bước 4 (mục Trạng thái ở bước 4, cuối mục 3) và phiên cuối của
Build & Test trên mã cuối. Phiên này giữ NANG.lock 10:43:49–10:55:16 (`build/lich-nang.tsv`
dòng 83–85).

- **Mã không đổi sau khi Build & Test bắt đầu dựng.** R kiểm mtime lúc 11:00: không tệp nào trong
  `SRC/`, `tests/`, `TOOLS/`, `cmake/`, `CMakeLists.txt`, `CMakePresets.json`,
  `docs/PROTOCOL-TIN.md` đổi sau 10:43:49. Ba tệp mới nhất:
  - `SRC/net/socket_posix.cpp` 10:43:07 (sửa HP-12, chỉ đổi chú thích);
  - `tests/fuzz/targets.hpp` 10:37:38;
  - `CMakeLists.txt` 10:26:00.
- **T11 trên mã cuối: đạt.**
  - Bảng: `so-do/fuzz-20261008-104830.tsv`. Log: `so-do/fuzz-{frame,game_client,game_server,auth_client,auth_server}-20261008-104830.log`.
    Lệnh và giờ: `so-do/l-cuoi-fuzz-tang-hai.log`, 10:48:30–10:50:35,
    `fuzz_protocol.py --runs 1000000 --seed 20261008`.
  - Đủ 5 đích. Mỗi đích `runs = 1000000`, `exit_code = 0`. Mỗi log có `INFO: Seed: 20261008` và
    `Done 1000000 runs`. Không có dòng `ERROR`, `SUMMARY` hay `LeakSanitizer`. Không có tệp
    `crash-*`, `leak-*`, `timeout-*`, `oom-*` dưới `build/p2-fuzz`.
  - exec/s trong bảng khớp đúng số Build & Test báo: frame 10.971, game_client 240.466,
    game_server 149.572, auth_client 226.726, auth_server 356.230.
  - Năm exe dựng lại lúc 10:48:32–10:48:45, sau lần sửa cuối của `channel.*` (10:19:45) và
    `targets.hpp` (10:37:38).
  - Corpus giữ từ lượt 02:30, như log ghi.
- **ctest đủ bộ ba preset: đạt.**
  - `so-do/l-cuoi-clang-asan-ctest.txt`: 100% của 50, `exit=0`, không qua `dev.bat`.
  - `so-do/l-cuoi-msvc-release-ctest.txt`: 100% của 50, `exit=0`.
  - `so-do/l-cuoi-gcc-debug-ctest.txt`: 100% của 44, `exit=0`.
  - Cả ba preset có `protocol_tests`, `protocol_channel_tests`, `protocol_catalog_tests`,
    `protocol_fuzz_tests`, `net_tests`, `wire_loop_tests`, `protocol_catalog_fresh`.
  - Dựng `all header_check` ở cả ba preset đều `exit=0` (`so-do/l-cuoi-*-dung.txt`).
  - `net_tests` lặp 20 lần ở msvc-release: 20 dòng Passed, mã 0 (`so-do/l-t13-cuoi.log`).
- **T1–T4 trên tệp sinh cuối: đạt.**
  - T1: `Ran 249 tests`, `OK (skipped=8)` (`so-do/l-t1-cuoi.log`).
  - T2: mã 0 (`so-do/l-t2-cuoi.log`).
  - T3: `--check` mã 0; bốn SHA-256 trùng cả ba (`so-do/l-t3-cuoi.log`). Bốn SHA giống
    `so-do/c-v2-sha-sau.log`.
  - T4: `--check` mã 1, báo ba tệp cũ, như mong đợi (`so-do/l-t4-cuoi.log`).
- **T6 lần 3: đạt kèm lệch môi trường V5.**
  - `so-do/l-t6-lan3.log`: 28 tệp, 3 lỗi. Cả 3 lỗi ở `SRC/net/socket_posix.cpp` (g14, c20,
    clang-tidy trên Windows: thiếu `arpa/inet.h`, nên kiểu không phân giải, sinh lỗi giả). 27 tệp
    còn lại ✓ đủ bộ.
  - `socket_posix.cpp` ✓ clang-format, ✓ độ lồng. T14: hai lệnh NDK đều mã 0
    (`so-do/l-t14-lan3.log`).
- **Các phép thử của R trên mã cuối** (phiên khoá 10:36:11–10:39:36) đều đạt:
  - mười khung tự soạn: `so-do/r-khung-tay-b4.log`;
  - bảng sai: `so-do/r-bang-sai-b4.log` (ca 4 ra `tệp:dòng`);
  - T12: `so-do/r-rang-b4.log` (4/4 đích sập với `ERROR: AddressSanitizer`, đối chứng sạch);
  - `net_tests` 20 lần: `so-do/r-net-lap-20-b4.log`;
  - tìm sleep: `so-do/r-sleep-b4.log`;
  - T17: đạt (đọc `fields.tsv`).
  - L chốt không ai sửa mã sau phiên của Build & Test, nên R không chạy lại.
- **DD-08 → HP-12.** `socket_posix.cpp:102, 104, 106` đã sửa lúc 10:43:07 (chỉ đổi chú thích; T6 lần
  3 chạy sau lần sửa). M3 đã sửa lúc 10:52:39: R đọc kiểm, BAO-CAO-B dòng 260, 262, 331 nay ghi
  HP-12; `DD-08` chỉ còn trong câu kể lịch sử ở dòng 132.
- **Đo hiệu năng (không phải điều kiện của R).** Đ1–Đ3 đã đo lại trên mã cuối và đạt.
  - Phiên khoá 10:56:47–10:58:32, `build/lich-nang.tsv` dòng 86.
  - Log: `so-do/l-cuoi-lan3-d1-sach-vong1.log`, `so-do/l-cuoi-lan3-d2-d3-moi-vong1.log`.
  - Số và tỉ lệ lớn/nhỏ (ngưỡng 1,5):
    - Đ1 mã hoá: 5,93 triệu/s, tỉ lệ 1,213.
    - Đ1 giải mã: 6,26 triệu/s, tỉ lệ 1,254.
    - Đ2 p50: 18,4 µs, tỉ lệ 1,039.
    - Đ2 p99: 32,1 µs, tỉ lệ 1,285.
    - Đ3: 3126,8 MiB/s, tỉ lệ 1,342.
  - Hai cột không có ngưỡng vượt 1,5, như log ghi: khứ hồi lớn nhất 9,238 và MiB/s mẻ đầu 2,274.
  - Hai lượt `l-cuoi-d*` và `l-cuoi-lan2-d*` bị bản dựng ngoài nhóm chen vào. Build & Test ghi chúng
    ở mục Lệch của `KET-QUA.md` và giữ nguyên log.

Mục còn mở, theo quyết định của L lúc 10:52. Tất cả là mục nhẹ, dời vòng sau:

| Mục | Chỗ | Người | Ghi chú |
|---|---|---|---|
| M1 | `SRC/net/socket_posix.cpp:170` | B | RST sau FIN trên Linux (`EPIPE`) ra `kConnect` thay vì `kReset`; B nhận cho vòng sau |
| M2 | `tests/protocol_channel_tests.cpp` | A | thêm ca trần hộp nhận sát 65.544; A nhận cho vòng sau |
| M4 | `tests/protocol_channel_tests.cpp:33–34, 78–79` | A | thân `for` không ngoặc nhọn; A nhận cho vòng sau |
| N3 phần L | `tests/protocol_fuzz_tests.cpp:116`, `tests/bench/bench.hpp:17, 22` | L | chữ ký bẻ dòng |
| N10 | `TOOLS/server/fuzz_protocol.py:29` | L | chưa có `--source`, `--out` |
| N6 | bộ giải mã sinh (`messages.cpp`) | C | L chấp nhận lúc 10:24, dời vòng sau |
| N12 | G6, `optional:optional:u8` | L quyết, C làm | DE-BAI để ngỏ, không sửa đợt này; bằng chứng `so-do/r-bang-sai-b4.log` ca 9 |

Lưu bằng chứng: `so-do/r-vat-chung/` có đủ:
- `bang_sai.py`, `rang.py`, `bo-kiem-bien-reader-take.diff`;
- `probe/` (`dung.ps1`, `khung.cpp`, `tuy_chon.cpp`, `khung_chung.hpp`, `dem_cap_phat.*`, và từ
  11:01 thêm `catalog-tuy-chon/`, danh mục mà probe bool/optional cần);
- `crash-b4/` (4 tệp).

`build/p2-r` xoá được sau 12:15.

R, Thursday 2026-10-08 11:02 (UTC+7).

### Phán quyết tạm 10:09

⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
