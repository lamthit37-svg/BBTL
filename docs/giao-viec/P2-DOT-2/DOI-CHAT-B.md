# Đối chất vai B (P2 đợt 2): B xét chéo A

## Phạm vi

- Mã của A: `SRC/protocol/wire.hpp` (124 dòng), `SRC/protocol/wire.cpp` (359), `SRC/protocol/channel.hpp` (115), `SRC/protocol/channel.cpp` (110), `tests/protocol_tests.cpp` (500). Đếm bằng `(Get-Content -Encoding UTF8 <tệp>).Count`.
- Chỗ L dùng mã của A: `tests/protocol_fuzz_tests.cpp` (205 dòng), `tests/fuzz/targets.hpp` (162 dòng), đoạn nhận của `tests/wire_loop_tests.cpp`.
- `docs/giao-viec/P2-DOT-2/BAO-CAO-A.md`, `NGUON.md` mục "Vai A".
- Đối chiếu: `DE-BAI.md` mục 3.1 tới 3.4, mục 4 vai A, mục 5, T7, T9, T16; hợp đồng `hop-dong/wire.hpp`; Dev `G:\TLBB\Dev` (chỉ đọc) `src/protocol/wire.cpp` (311 dòng, khớp số đề bài ghi), `src/net/connection.hpp`, `src/net/connection.cpp`.
- Ngoài phạm vi: `messages.*` của C (chỉ xét chỗ nó dựa vào `Reader::count`), `SRC/net/` (C xét).

## Cách làm

B chỉ đọc mã, không chạy dựng hay test nào, không giữ NANG.lock. Không có probe, không đột biến, không ghi `build/lich-nang.tsv`.

Lệnh đã chạy đều là lệnh đọc, trên máy Hoon, thư mục `F:\tl 2026\THIENLONG\build\p2-dot-2`: `Get-Content -Encoding UTF8` có đánh số dòng, `Select-String -Encoding UTF8`, `Compare-Object` (hợp đồng và `wire.hpp`), `Get-Item` (giờ sửa tệp), `[System.IO.File]::ReadAllBytes` (BOM, byte CR), `Test-Path`, `Get-PSDrive F`, `git -c safe.directory=* status --short` và `log --oneline`. Mọi `tệp:dòng` dưới đây lấy từ Get-Content đánh số hoặc Select-String chạy trong khoảng 09:58 tới 10:03 (UTC+7). Các nghi vấn được mô tả bằng đầu vào cụ thể và đường đi của mã, ghi "chưa chạy thử, cần R/A xác nhận ở bước 4".

## Tóm tắt

| Mã | Mức | Chỗ | Tóm tắt | Của |
|---|---|---|---|---|
| X-BA-01 | vừa | `wire.cpp:98`, `wire.cpp:70`, `:72`, `:74`, `:76`; `protocol_tests.cpp:271-274` | phép kiểm byte nối thứ ba, thứ tư và cận dưới byte thứ hai của bốn dải chung không có ca nào giữ; xoá đi thì `protocol_tests` và fuzz hai tầng vẫn xanh | A |
| X-BA-02 | vừa | `channel.cpp:52-54`, `channel.hpp:54`, `channel.cpp:45` | hộp nhận chỉ cần chứa đúng một khung, `receive` nhận cả mẩu hoặc không gì; luồng hợp lệ bị `kInboxFull` khi bên gọi đọc socket theo mẩu cố định; không có hàm báo chỗ trống; Dev chừa khoảng đệm và ghi bất biến, A bỏ mà không ghi khác gốc | A |
| X-BA-03 | nhẹ | `tests/fuzz/targets.hpp:85-86` | đích kênh coi mọi lỗi `receive`, kể cả `kInboxFull` oan, là "từ chối đúng" | L |
| X-BA-04 | nhẹ | `protocol_tests.cpp:109-157`, `:446-455` | thiếu vài giá trị biên §4 A đòi; `queue` sau khi kênh hỏng chưa có ca | A |
| X-BA-05 | nhẹ | `channel.hpp:41-42`, `protocol_tests.cpp:457-466` | ánh xạ `ChannelError` và `WireError` chỉ khoá giá trị cuối; ca test lặp lại chính phép ép kiểu | A |
| X-BA-06 | nhẹ | `channel.cpp:1-3` | đầu tệp có `Nguồn:` nhưng thiếu `Khác gốc:` | A |
| X-BA-07 | nhẹ | `channel.cpp:56`, `channel.cpp:83` | trần là trần byte giữ; dung lượng cấp phát của hai vector không có trần và không trả lại | A |

## Finding

### X-BA-01 [VỪA] Byte nối ở vị trí 3, 4 và cận dưới byte thứ hai của các dải chung không có ca nào giữ

- Chỗ: `SRC/protocol/wire.cpp:97-98`:

```cpp
    const ByteView rest = text.subspan(2, lead.length - 2);
    if (!std::ranges::all_of(rest, is_continuation)) return 0;
```

  và cận `.low = 0x80` ở `wire.cpp:70` (C2 tới DF), `:72` (E1 tới EC), `:74` (EE tới EF), `:76` (F1 tới F3).
- Bộ ca: `tests/protocol_tests.cpp:271-274` (`kBadUtf8`, 16 chuỗi). Rà từng chuỗi: chuỗi đủ độ dài nào cũng hỏng ở byte đầu (`C0`, `C1`, `F5`, `80`, `BF` sau `a`, `FF` sau `C3 A9`, `00`) hoặc ở byte thứ hai ngoài khoảng riêng của E0, ED, F0, F4 (`E0 80 80`, `E0 9F BF`, `ED A0 80`, `ED BF BF`, `F0 80 80 80`, `F4 90 80 80`). Hai chuỗi `E1 BB` và `F0 9F 98` bị cụt, bị bắt ở `wire.cpp:93` (`lead.length > text.size()`), không tới dòng 98. Không chuỗi nào có dạng "byte đầu đúng, byte thứ hai đúng, byte thứ ba hay thứ tư không phải byte nối", cũng không chuỗi nào có byte đầu thuộc C2 tới DF, E1 tới EC, EE tới EF, F1 tới F3 kèm byte thứ hai dưới `0x80`.
- Vì sao sai: §3.2 đòi UTF-8 đúng RFC 3629, kiểm ở cả hai chiều; §4 A đòi bộ ca UTF-8 sai. Hai nhánh trên là phép kiểm thật của bộ giải mã nhưng không có răng: đột biến xoá dòng 98, hay đổi `.low = 0x80` ở dòng 72 thành `0x00`, không làm đỏ ca nào của `protocol_tests` (suy từ bộ ca ở trên). Fuzz không bù được: đích giải mã (`targets.hpp:45-61`) so byte mã hoá lại, mà `Writer::text` (`wire.cpp:191`) gọi cùng `is_text`, nên chuỗi sai lọt qua chiều đọc thì cũng lọt qua chiều ghi và byte vẫn khớp; ASan không có gì để bắt vì không đọc ngoài vùng. Mẫu của C đều là UTF-8 đúng. Phép thử T12 của R bỏ phép kiểm biên trong `Reader::take` (`so-do/r-rang.log` dòng 7-15), không chạm nhánh này.
- Đầu vào cụ thể (chưa chạy thử, cần R/A xác nhận ở bước 4): thân `03 00 E1 BB 41` đọc bằng `Reader::text(64)`. Mã hiện tại: `E1` ra độ dài 3, `BB` nằm trong `[80, BF]`, `rest = {41}`, dòng 98 trả 0, kết quả `kBadText` (đúng). Nếu mất dòng 98: trả 3, chuỗi `E1 BB 41` được nhận và mã hoá lại trùng byte. Tương tự `04 00 F0 9F 98 41`, `04 00 F0 9F 41 80`; với cận dưới: `02 00 C3 41`, `03 00 E1 41 80`, `04 00 F1 7F 80 80`.
- Đề xuất: thêm vào `kBadUtf8` các chuỗi `"\xE1\xBB\x41"`, `"\xF0\x9F\x98\x41"`, `"\xF0\x9F\x41\x80"`, `"\xC3\x41"`, `"\xE1\x41\x80"`, `"\xF1\x7F\x80\x80"`. R chạy đột biến xoá dòng 98 trên bản chép trong `build/` để xác nhận ca mới đỏ còn ca cũ thì không.

### X-BA-02 [VỪA] Hộp nhận không chừa chỗ cho mẩu đọc kế tiếp: luồng hợp lệ có thể bị `kInboxFull`

- Chỗ: `SRC/protocol/channel.cpp:52-54`:

```cpp
    const std::size_t held = inbox_held();
    if (bytes.size() > limits_.inbox_bytes - held) broken_ = ChannelError::kInboxFull;
    if (broken_) return std::unexpected(*broken_);
```

  `channel.hpp:54`: `inline constexpr std::size_t kInboxBytes = kHeaderBytes + kMaxBodyBytes;`. `channel.cpp:45` chỉ đòi `limits.inbox_bytes >= kHeaderBytes + limits.max_body`. Chú thích `channel.hpp:80-82` nói vượt trần là `kInboxFull` nhưng không nói bên gọi được đọc socket tối đa bao nhiêu byte. Lớp không có hàm trả chỗ trống; `inbox_held()` theo `channel.hpp:98` còn tính cả khung vừa trả bởi `next`.
- Dev: `G:\TLBB\Dev\src\net\connection.hpp:21-23` ghi bất biến "Bên gọi rút hết tin bằng next() sau mỗi lần receive(), nên bộ đệm chỉ chứa phần dở của một khung (tối đa kHeaderBytes + kClientBodyBytes) cộng mẩu vừa nhận" và đặt `kInboxBytes = 64 * 1024` cho thân client tối đa `kClientBodyBytes`: trần hộp nhận rộng hơn một khung, phần dư dành cho mẩu đọc. A giữ phép kiểm (`connection.cpp:45` của Dev) nhưng bỏ khoảng dư và câu bất biến; `Khác gốc` ở `channel.hpp:6-8`, `NGUON.md` mục Vai A và BAO-CAO-A §4 không nhắc.
- Vì sao sai: không trái chữ của §3.4 ("vượt trần hộp nhận là lỗi `kInboxFull`"), nhưng với trần mặc định (đúng một khung lớn nhất) hay bộ trần client chặt (`8 + 4096`, như `targets.hpp:127`), một bên kia hợp lệ gửi liền nhiều khung sẽ bị ngắt nếu bên gọi đọc socket vào bộ đệm cố định rồi đưa trọn vào `receive`. `tests/wire_loop_tests.cpp:156-159` đang làm đúng kiểu đó (`link.server.receive(loop.sink)` rồi `loop.channel.receive(ByteView{loop.sink}.first(*count))`). Hôm nay wire_loop không vấp vì tin lớn nhất của danh mục là 580 byte thân (BAO-CAO-C.md:117-118) so với hộp 65.544 byte, nhưng đợt 3 nối gate với kết nối client sẽ gặp. Đây là mặt kia của LH-03: client đúng luật bị đóng.
- Đầu vào cụ thể (chưa chạy thử, cần R/A xác nhận ở bước 4): `Channel ch{ChannelLimits{.inbox_bytes = 4104, .max_body = 4096}}`. `receive` 4.100 byte gồm đầu khung `00 10 00 00 01 01 00 00` và 4.092 byte thân: thành công, `next()` trả "chưa có khung", held = 4.100. `receive` 8 byte gồm 4 byte cuối của thân và `00 00 00 00` (4 byte đầu của khung kế, thân 0): 8 > 4.104 − 4.100 = 4, dòng 53 đặt `kInboxFull`, kênh hỏng hẳn, dù cả hai khung đều hợp lệ. Với trần mặc định: đang giữ phần dở hơn 8 byte rồi `receive` một mẩu 65.536 byte cũng ra `kInboxFull`.
- Đề xuất (A chọn, L duyệt): (a) thêm `[[nodiscard]] std::size_t inbox_room() const noexcept` (trần trừ số byte còn giữ sau khi bỏ khung đã trả), ghi ở `channel.hpp` rằng bên gọi đọc socket tối đa `inbox_room()` byte rồi rút hết khung bằng `next()`, kèm ca test hai khung với mẩu vắt qua ranh giới; hoặc (b) giữ API, chép câu bất biến của Dev vào chú thích `receive` và ghi khác gốc về trần mặc định so với Dev. Nếu giữ nguyên hành vi thì ghi vào Giả định của BAO-CAO-A.

### X-BA-03 [NHẸ, của L] Đích kênh của fuzz không phân biệt `kInboxFull` đúng và oan

- Chỗ: `tests/fuzz/targets.hpp:85-86`:

```cpp
    if (!channel.receive(chunk)) {
        return channel.inbox_held() <= limits.inbox_bytes;
```

- Vì sao: mọi lỗi `receive` được tính là không phá bất biến, nên đích này không thể thấy X-BA-02. Với bộ trần client (`targets.hpp:126-128`) và cỡ mẩu `1 + (input.size() % 13)` (`targets.hpp:97`), đầu vào gồm một khung thân 4.096 byte rồi một khung thân 0 byte dài 4.112 byte, mẩu là 1 + 4.112 % 13 = 5 byte; 820 mẩu đầu là 4.100 byte chưa đủ khung, mẩu thứ 821 (byte 4.100 tới 4.104) đi đúng đường của X-BA-02 và vẫn được tính "sạch" (`frame` trả `kSkipped` vì đầu vào không phải đúng một khung). Chưa chạy thử.
- Đề xuất: khi đầu vào ghép toàn từ khung hợp lệ dưới trần, `kInboxFull` là `kBroken`; hoặc cho đích đọc theo `inbox_room()` nếu A thêm hàm đó.

### X-BA-04 [NHẸ] Thiếu vài ca so với §4 A và lời hứa của `channel.hpp`

- Giá trị biên: `protocol_tests.cpp:109-157`. `unsigned_golden` không có u32 0 và u64 0; `signed_golden` không có i8 0, không có giá trị lớn nhất của i16, i32, i64, không có i32 −1. §4 A: "byte mong đợi viết tay cho từng kiểu sơ cấp ở giá trị biên (0, lớn nhất, âm nhỏ nhất, -1, -0.0F, ...)". BAO-CAO-A §3 liệt kê đúng những giá trị đã có, không nói quá, nhưng mục Chưa kiểm không ghi phần thiếu. Rủi ro của mã thấp vì mọi kiểu đi chung `store` và `load` (`wire.cpp:32-49`).
- `queue` sau khi kênh hỏng: `channel.hpp:73-74` hứa "mọi lời gọi receive, next, queue sau đó trả đúng lỗi ấy"; `channel_broken_frame_is_final` (`protocol_tests.cpp:446-455`) chỉ thử `next` và `receive`, nhánh `channel.cpp:74` không có ca.
- Đề xuất: thêm các giá trị trên vào hai ca golden, thêm một kỳ vọng `queue` vào `channel_broken_frame_is_final`; không thêm thì ghi vào Chưa kiểm.

### X-BA-05 [NHẸ] `ChannelError` chỉ khoá giá trị cuối với `WireError`

- Chỗ: `channel.hpp:41-42`:

```cpp
static_assert(
    std::to_underlying(ChannelError::kOutOfRange) == std::to_underlying(WireError::kOutOfRange));
```

- Vì sao: bảo đảm số lượng, không bảo đảm thứ tự tên. `channel_error_wraps_wire` (`protocol_tests.cpp:457-466`) so `unwrap(wrap(x)) == x` và `describe(wrap(x)) == describe(x)`; `wrap`, `unwrap` là ép số còn `describe(ChannelError)` gọi lại `describe(WireError)` qua `unwrap` (`channel.cpp:35-41`), nên hai kỳ vọng luôn đúng kể cả khi hai enum lệch tên. Hiện hai enum trùng thứ tự (B so `wire.hpp:28-39` với `channel.hpp:24-34`).
- Đề xuất: mỗi giá trị một `static_assert`, hoặc ca test so theo tên, ví dụ `wrap(WireError::kBadText) == ChannelError::kBadText`.

### X-BA-06 [NHẸ] `channel.cpp` thiếu dòng `Khác gốc:`

- Chỗ: `channel.cpp:1-3` có `// Nguồn: TLBB Dev src/net/connection.cpp.` nhưng không có `Khác gốc:`. §3.1: "Mã port từ Dev ghi `Nguồn:` và `Khác gốc:` đầu tệp". `wire.cpp:3-5` và `channel.hpp:5-8` có đủ hai dòng.
- Đề xuất: thêm một dòng `Khác gốc:` (có thể trỏ sang `channel.hpp`), kèm khác biệt `compact` không còn kiểm `start == 0` và `mark_sent` dừng bằng `core::check` thay vì kẹp như Dev (`connection.cpp:14-19`, `:92` của Dev).

### X-BA-07 [NHẸ] Trần là trần byte giữ, không phải trần cấp phát

- Chỗ: `channel.cpp:56` `inbox_.insert(inbox_.end(), bytes.begin(), bytes.end());` và `channel.cpp:83` `outbox_.insert(outbox_.end(), frame.begin(), frame.end());`.
- Vì sao: số byte giữ luôn không quá trần (đúng §3.4 và bất biến fuzz "kênh không bao giờ giữ quá trần"), nhưng dung lượng vector tăng theo hệ số của thư viện chuẩn nên có thể vượt trần, và `erase`, `clear` không trả lại bộ nhớ sau đợt cao điểm. Hộp gửi mặc định 1 MiB (`channel.hpp:55`) mỗi kết nối nên bộ nhớ thật mỗi kết nối có thể lớn hơn con số trên giấy. Chưa đo.
- Đề xuất: `reserve` đúng trần ở lần thêm đầu, hoặc ghi vào Giả định rằng trần của §3.4 là trần byte giữ.

## Đã kiểm, không thấy lỗi

- Đầu khung: `u32` số byte thân, `u16` mã tin, `u16` cờ, little-endian, ghép và tách từng byte bằng phép dịch (`wire.cpp:32-49`, `:224-227`, `:347-357`). Không `memcpy`, không `reinterpret_cast`; `Select-String 'NOLINT'` trên năm tệp của A ra 0 dòng.
- `peek_frame`: dưới 8 byte là chưa có khung (`wire.cpp:348`); cờ khác 0 là `kBadFlags` (`:351`); thân khai lớn hơn `min(max_body, kMaxBodyBytes)` là `kBodyTooLarge` ngay khi đủ 8 byte (`:352-354`), so trong `uint64_t` nên `FF FF FF FF` không tràn; chỉ sau đó mới so với số byte đã có (`:355`). Không cấp phát theo số bên kia khai (LH-03). `Channel::next` gọi nó trên vùng đã có, không cấp phát theo số khai (`channel.cpp:63-70`).
- `Reader::take` kiểm `count > body_.size() - position_` trước khi đọc (`wire.cpp:338`), không tràn vì `position_` không vượt cỡ thân; lỗi dính (`:337`); `finish` phân biệt lỗi đã nhớ và `kTrailingBytes` (`:330-333`).
- `Reader::text`: đọc `u16`, so trần (`:293`), rồi `take` (`:295`) trước khi tạo `std::string` (`:299`): cấp phát không quá trần và không quá số byte còn lại.
- `Reader::count`: `kTooLong` trước `kTruncated` (`:312`, `:317`). Chú thích nêu bất biến G6 ở `wire.cpp:313-316` và `wire.hpp:97`. Luật được thực thi ở `TOOLS/server/protocol_rules.py:309-315` (`check_list_elements`, dựa vào `least_bytes` ở `:290-306`).
- `Writer`: `append` kiểm `value.size() > kMaxBodyBytes - body_bytes()` không tràn (`wire.cpp:233`); thân đúng 65.536 byte qua, 65.537 là `kBodyTooLarge` (ca `body_too_large_both_ways`); `finish` có lỗi thì cắt về cỡ lúc tạo (`:221`); số có dấu đi qua kiểu không dấu cùng cỡ (`:157-171`); `f32` từ chối NaN và vô cực hai chiều (`:174`, `:280`), −0 giữ dấu; `bool` lớn hơn 1 là `kBadEnum` (`:287`).
- Bảng byte đầu UTF-8 `wire.cpp:68-78` khớp Dev `src/protocol/wire.cpp:56-64`; byte 0 nằm ngoài mọi dải nên bị từ chối.
- Kênh: lỗi khung hay hộp nhận đầy làm kênh hỏng hẳn (`channel.cpp:50`, `:61-66`, `:74`); hộp gửi kiểm trước khi thêm (`:79-81`), sửa đúng chỗ Dev vượt được một khung (Dev `connection.cpp:75`); vùng nhìn thân hết hạn ở lời gọi kế, đã ghi ở `channel.hpp:64` và `:102`. `core::check` chỉ ở tham số lúc tạo (`channel.cpp:44-45`), đầu vào `queue` (`:78`) và `mark_sent` (`:92`): không byte nào từ mạng đi vào `core::check`. Lưu ý cho đợt 3: `queue` sẽ dừng tiến trình nếu ai đưa byte chuyển tiếp chưa qua `Writer`.
- Tầng: `protocol` chỉ include `protocol/wire.hpp` và `core/check.hpp` (Select-String `#include "`), không include `net`, đúng §3.1. Phần ghép với `game::net` nằm ở `wire_loop_tests.cpp` của L: 0 byte nhận được đưa vào `receive` như mẩu rỗng (vô hại), lỗi socket dừng vòng (`wire_loop_tests.cpp:157`).
- Chữ ký công khai của `wire.hpp` trùng `hop-dong/wire.hpp`: `Compare-Object` chỉ ra dòng chú thích đầu tệp, phần `private` và chú thích.
- Luật tệp: năm tệp không BOM, 0 byte CR, kết thúc bằng LF; không tệp `.cpp` nào quá 500 dòng (`protocol_tests.cpp` đúng 500); hàm đều dưới 40 dòng và không quá 5 tham số (đọc bằng mắt); độ lồng do `check.py` báo qua (`so-do/a-check-day-du.log`).
- T7: đủ mười giá trị ở chiều đọc. `kUnknownKind` và `kOutOfRange` ở tầng byte chỉ đi qua `fail()`; BAO-CAO-A dòng 63-65 nói rõ ca sinh thật nằm ở test của C. T9: `dev_hello_sample` (`protocol_tests.cpp:366-379`) giải mã ra 1, 2, `0x01020304` và mã hoá lại trùng 15 byte.
- §4 A: UTF-8 sai đủ các nhóm đề kể (dài thừa hai và ba byte, nửa cặp thay thế, quá U+10FFFF, byte nối lẻ, cụt giữa ký tự, byte 0); `peek_frame` ở mọi độ dài 0 tới 7 cho ba đầu khung, 9 byte, khung đủ (`protocol_tests.cpp:348-363`); kênh nhận từng byte qua ba khung (`:406-419`); hai trần của kênh (`:421-444`).

## Kiểm báo cáo A

- Số dòng 124, 359, 115, 110, 500 khớp `so-do/a-t16-dong.log` (dòng 5-7 và 9-10) và khớp lệnh B chạy.
- Test đỏ: `so-do/a-protocol-do-truoc.log` có 150 dòng kỳ vọng hỏng dạng `tests\protocol_tests.cpp:<n>: [<ca>]`, 22 tên ca khác nhau, `Exit code 0xc0000409` (dòng 5). Đếm bằng `Select-String -Pattern '^tests\\protocol_tests\.cpp:\d+: \[([a-z0-9_]+)\]'`. Khớp "22/22 ca hỏng, 150 dòng". Số dòng trong log (tới 514) là của bản test cũ; A đã ghi ở Lệch quy tắc.
- `check.py`: lần 1 01:49:34 tới 01:49:38, "5 tệp, 3 lỗi.", mã thoát 1 (phần output là UTF-16, B đọc bằng cách bỏ byte 0); lần 2 01:51:34 tới 01:51:38, 0 lỗi; lần 3 01:53:05 tới 01:53:09, "5 tệp, 0 lỗi."; sau comment G6 02:22:11 tới 02:22:13, "2 tệp, 0 lỗi.". Ba lượt đủ bộ có dòng của A trong `build/lich-nang.tsv` đúng giờ.
- Chạy lặp: `so-do/a-lap-20.log` và `so-do/a-g6-lap-20.log` đều 20 lần `Passed`, mã thoát 0.
- Giờ sửa tệp so với log: `wire.hpp`, `wire.cpp` 02:22:02; `channel.hpp` 01:44:31; `channel.cpp` 01:51:18; `protocol_tests.cpp` 01:52:51. `build/p2-a/protocol_tests.exe` 02:22:10, đúng lúc lượt `a-g6-lap-20` bắt đầu: lượt chạy lặp cuối dùng bản dựng từ mã cuối. Không tệp nào của A sửa sau log cuối.
- Lệch quy tắc §8 trung thực: ghi nhầm vào `C:\Users\myhea\SRC` rồi dọn (ngoài worktree, trái §5, A tự khai); nối thêm ba dòng vào `a-t16-dong.log` (log có đúng ba dòng sau dòng 7). Dòng 166 của BAO-CAO-A có hai dấu phẩy liền (",,"), lỗi chữ.
- Thiếu: Chưa kiểm không nhắc giá trị biên còn thiếu (X-BA-04) và nhánh UTF-8 không có ca (X-BA-01); Khác Dev không nhắc khoảng dư của hộp nhận (X-BA-02).

## Chưa kiểm

- Không chạy gì, theo lệnh của lead lúc 09:56: X-BA-01, X-BA-02, X-BA-03 chưa chạy thử, cần R/A xác nhận ở bước 4 bằng đột biến hay ca test trên bản chép.
- Không xét `messages.*` của C, trừ chỗ dựa vào `Reader::count` qua luật G6.
- Không kiểm lại T5, T6, T10, T11 ở ba preset; không đọc log của L và R cho các tiêu chí đó.
- Trần 40 dòng mỗi hàm và 5 tham số: đọc bằng mắt, không đo bằng công cụ.

## Kết luận

0 nặng, 2 vừa (X-BA-01, X-BA-02), 5 nhẹ (X-BA-03 của L; X-BA-04 tới X-BA-07 của A). Không thấy lỗi bộ nhớ, tràn số hay cấp phát theo số bên kia khai trong mã của A; tầng byte và kênh đúng chữ của §3.2 tới §3.4. Hai điểm vừa: một phép kiểm UTF-8 không có răng ở mọi tầng test, và hộp nhận dễ ngắt nhầm bên kia hợp lệ khi bên gọi đọc socket theo mẩu cố định.

B chỉ đọc mã, không chạy dựng hay test nào, không giữ NANG.lock.

Ổ F còn trống 166574333952 byte, 155.13 GB (lệnh `(Get-PSDrive F).Free`, lúc ghi tệp). Tệp ghi lúc 2026-10-08 10:05:57 (UTC+7).
