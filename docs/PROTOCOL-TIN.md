<!-- Tệp sinh bởi TOOLS/server/gen_protocol.py từ src/shared/protocol/catalog/*.tsv; không sửa tay. Sửa bảng rồi chạy lại: python -B TOOLS/server/gen_protocol.py -->

# Danh mục tin của giao thức

Bản danh mục 2: 22 tin, 1 record, 5 enum.
Khung có 8 byte đầu (u32 số byte thân, u16 kind, u16 flags bằng 0), little-endian; thân tối đa 65 536 byte, tin client gửi tối đa 4 096 byte.
Byte cao của kind là nhóm, bit 15 bật là tin server gửi. Trần của text tính bằng byte UTF-8, trần của list tính bằng số phần tử.

## Nhóm 01: session

Phiên kết nối: chào, đăng nhập, nối lại, nhịp tim và rời phiên.

| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |
|---|---|---|---|---|---|
| `0x0101` | Hello | game, auth | client | 1 | 7 |
| `0x0102` | Login | game | client | 1 | 580 |
| `0x0103` | Resume | game | client | 1 | 16 |
| `0x0104` | Ping | game | client | 1 | 4 |
| `0x0105` | Logout | game | client | 1 | 0 |
| `0x8101` | Welcome | game, auth | server | 1 | 12 |
| `0x8102` | SessionStart | game | server | 1 | 16 |
| `0x8103` | ContentKey | game | server | 1 | 32 |
| `0x8104` | Pong | game | server | 1 | 12 |
| `0x8106` | Reject | game, auth | server | 1 | 4 |
| `0x8107` | Goodbye | game, auth | server | 1 | 1 |
| `0x8108` | ContentStamp | game | server | 1 | 32 |
| `0x8109` | UiConfig | game | server | 2 | 1 |

### Hello (0x0101)

Tin đầu tiên của mọi kết nối, báo phiên bản giao thức, nền tảng và bản dựng client.

Cổng game, auth, client gửi, có từ bản 1. Thân tối đa 7 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `version` | `u16` | – | Phiên bản giao thức của client. |
| 2 | `platform` | `enum:Platform` | – | – |
| 3 | `build` | `u32` | – | Số bản dựng client. |

### Login (0x0102)

Đăng nhập cổng game bằng vé do cổng xác thực cấp, không bao giờ mang mật khẩu.

Cổng game, client gửi, có từ bản 1. Thân tối đa 580 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `account` | `text` | 64 | Tên tài khoản (kAccountBytes của Dev). |
| 2 | `ticket` | `text` | 512 | Vé do cổng xác thực cấp. |

### Resume (0x0103)

Nối lại phiên cũ bằng token phiên sau khi rớt mạng.

Cổng game, client gửi, có từ bản 1. Thân tối đa 16 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `token` | `bytes` | 16 | Token phiên nhận trong SessionStart. |

### Ping (0x0104)

Nhịp tim của client, mang giờ client để đo độ trễ khứ hồi.

Cổng game, client gửi, có từ bản 1. Thân tối đa 4 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `client_time` | `millis32` | – | Giờ client lúc gửi, server trả lại nguyên trong Pong. Khác Dev (duration<uint32_t, milli>): ta dùng std::chrono::milliseconds có dấu để trừ hai mốc không bị quấn; trên dây vẫn u32 như Dev, ghi số âm hay trên 2^32 - 1 ra kOutOfRange. |

### Logout (0x0105)

Client chủ động rời phiên; thân rỗng.

Cổng game, client gửi, có từ bản 1. Thân tối đa 0 byte.

Tin không có trường: thân rỗng.

### Welcome (0x8101)

Server đáp Hello: phiên bản giao thức, giờ server và chu kỳ nhịp tim.

Cổng game, auth, server gửi, có từ bản 1. Thân tối đa 12 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `version` | `u16` | – | Phiên bản giao thức của server. |
| 2 | `server_time` | `millis64` | – | Giờ server theo mili giây. Khác Dev (duration<uint64_t, milli>): ta dùng std::chrono::milliseconds nền int64 có dấu để trừ hai mốc không bị quấn; trên dây vẫn u64, nhưng số trên 2^63 - 1 (khoảng 292 triệu năm, chỉ có ở dữ liệu hỏng) đọc ra kOutOfRange, ghi số âm cũng ra kOutOfRange. |
| 3 | `heartbeat` | `seconds16` | – | Chu kỳ client phải gửi Ping. Khác Dev (duration<uint16_t>): ta dùng std::chrono::seconds có dấu cho cùng kiểu giờ với phần còn lại; trên dây vẫn u16 như Dev, ghi số âm hay trên 65535 ra kOutOfRange. |

### SessionStart (0x8102)

Server mở phiên và cấp token để nối lại sau này.

Cổng game, server gửi, có từ bản 1. Thân tối đa 16 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `token` | `bytes` | 16 | Token phiên dùng cho Resume. |

### ContentKey (0x8103)

Khoá giải mã gói nội dung của phiên.

Cổng game, server gửi, có từ bản 1. Thân tối đa 32 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `key` | `bytes` | 32 | Khoá giải mã gói nội dung. |

### Pong (0x8104)

Server đáp Ping, trả lại giờ client kèm giờ server.

Cổng game, server gửi, có từ bản 1. Thân tối đa 12 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `client_time` | `millis32` | – | Giờ client lấy nguyên từ Ping. Khác Dev như Ping.client_time: std::chrono::milliseconds có dấu thay cho duration<uint32_t, milli>, trên dây vẫn u32. |
| 2 | `server_time` | `millis64` | – | Giờ server lúc trả lời. Khác Dev như Welcome.server_time: nền int64 có dấu thay cho u64, số trên 2^63 - 1 đọc ra kOutOfRange. |

### Reject (0x8106)

Server từ chối một tin của client và nêu mã lỗi.

Cổng game, auth, server gửi, có từ bản 1. Thân tối đa 4 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `request` | `u16` | – | Mã tin của client bị từ chối; để u16 thay vì enum để giữ nguyên byte của Dev và không chép mã tin vào enums.tsv. |
| 2 | `code` | `enum:ErrorCode` | – | – |

### Goodbye (0x8107)

Server báo sắp đóng kết nối và nêu lý do.

Cổng game, auth, server gửi, có từ bản 1. Thân tối đa 1 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `reason` | `enum:DisconnectReason` | – | – |

### ContentStamp (0x8108)

Dấu băm của gói nội dung để client đối chiếu với bản đang có.

Cổng game, server gửi, có từ bản 1. Thân tối đa 32 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `stamp` | `bytes` | 32 | Dấu băm của gói nội dung. |

### UiConfig (0x8109)

Cấu hình giao diện do nhà phát hành đặt ở server (client.toml): gửi sau SessionStart, chỉ cho client khai phiên bản giao thức từ 2.

Cổng game, server gửi, có từ bản 2. Thân tối đa 1 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `avatar_frame` | `enum:AvatarFrame` | – | Dạng khung chân dung của HUD (client.toml, [hud] avatar_frame). |

## Nhóm 02: character

Nhân vật: danh sách, tạo, xoá và vào game.

| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |
|---|---|---|---|---|---|
| `0x0201` | CreateCharacter | game | client | 1 | 55 |
| `0x0202` | DeleteCharacter | game | client | 1 | 8 |
| `0x0203` | EnterGame | game | client | 1 | 8 |
| `0x8201` | CharacterList | game | server | 1 | 546 |

### CreateCharacter (0x0201)

Tạo nhân vật mới với tên, giới tính, khuôn mặt và kiểu tóc.

Cổng game, client gửi, có từ bản 1. Thân tối đa 55 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `name` | `text` | 48 | Tên nhân vật muốn tạo. |
| 2 | `gender` | `enum:Gender` | – | – |
| 3 | `face` | `u16` | – | 0 là mặt mặc định (kDefaultLook của Dev). |
| 4 | `hair` | `u16` | – | 0 là tóc mặc định (kDefaultLook của Dev). |

### DeleteCharacter (0x0202)

Xoá một nhân vật của tài khoản.

Cổng game, client gửi, có từ bản 1. Thân tối đa 8 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `character` | `u64` | – | CharacterId của Dev. |

### EnterGame (0x0203)

Vào game bằng nhân vật đã chọn.

Cổng game, client gửi, có từ bản 1. Thân tối đa 8 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `character` | `u64` | – | CharacterId của Dev. |

### CharacterList (0x8201)

Danh sách nhân vật của tài khoản để chọn vào game.

Cổng game, server gửi, có từ bản 1. Thân tối đa 546 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `characters` | `list:record:CharacterSummary` | 8 | Tối đa 8 nhân vật mỗi tài khoản (kCharacterSlots của Dev). |

## Nhóm 03: move

Di chuyển: client xin bước, server làm chủ vị trí và kéo về mốc khi không nhận.

| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |
|---|---|---|---|---|---|
| `0x0301` | Move | game | client | 1 | 12 |
| `0x8301` | Position | game | server | 1 | 12 |

### Move (0x0301)

Client xin một bước trên mặt phẳng ngang; server đo bằng guard::Pace theo tick của server, không tin vị trí client.

Cổng game, client gửi, có từ bản 1. Thân tối đa 12 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `x_cm` | `f32` | – | Toạ độ X muốn tới, centimet. NaN/vô cực bị Pace từ chối. |
| 2 | `z_cm` | `f32` | – | Toạ độ Z muốn tới, centimet. |
| 3 | `tick` | `u32` | – | Tick client (30/giây) đếm từ tick trong Position gần nhất; chỉ làm trần dưới của thời gian, server cắt theo đồng hồ của mình. |

### Position (0x8301)

Vị trí server làm chủ: gửi khi vào game (mốc đầu), khi dịch chuyển hợp lệ, và khi bước của client bị từ chối (kéo về).

Cổng game, server gửi, có từ bản 1. Thân tối đa 12 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `x_cm` | `f32` | – | Toạ độ X server chấp nhận, centimet. |
| 2 | `z_cm` | `f32` | – | Toạ độ Z server chấp nhận, centimet. |
| 3 | `tick` | `u32` | – | Tick client mới làm gốc: client đặt bộ đếm tick về giá trị này rồi đếm tiếp. |

## Nhóm 05: auth

Cổng xác thực: tạo tài khoản, đăng nhập bằng mật khẩu và cấp vé vào cổng game.

| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |
|---|---|---|---|---|---|
| `0x0501` | CreateAccount | auth | client | 1 | 196 |
| `0x0502` | SignIn | auth | client | 1 | 196 |
| `0x8501` | Ticket | auth | server | 1 | 204 |

### CreateAccount (0x0501)

Tạo tài khoản mới ở cổng xác thực.

Cổng auth, client gửi, có từ bản 1. Thân tối đa 196 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `account` | `text` | 64 | Tên tài khoản (kAccountBytes của Dev). |
| 2 | `password` | `text` | 128 | Mật khẩu, chỉ đi qua cổng xác thực. |

### SignIn (0x0502)

Đăng nhập bằng mật khẩu ở cổng xác thực để nhận vé.

Cổng auth, client gửi, có từ bản 1. Thân tối đa 196 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `account` | `text` | 64 | Tên tài khoản (kAccountBytes của Dev). |
| 2 | `password` | `text` | 128 | Mật khẩu, chỉ đi qua cổng xác thực. |

### Ticket (0x8501)

Vé vào cổng game do cổng xác thực cấp sau khi đăng nhập đúng.

Cổng auth, server gửi, có từ bản 1. Thân tối đa 204 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `token` | `bytes` | 204 | Vé vào cổng game (kConnectTokenBytes của Dev). |

## Record

### CharacterSummary

Tóm tắt một nhân vật trong danh sách chọn nhân vật.

Thân tối đa 68 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `id` | `u64` | – | CharacterId của Dev. |
| 2 | `name` | `text` | 48 | Tên nhân vật, UTF-8, tối đa 48 byte (kNameBytes của Dev). |
| 3 | `level` | `u16` | – | – |
| 4 | `gender` | `enum:Gender` | – | – |
| 5 | `face` | `u16` | – | Id mặt trong faces.tsv mà server đã lưu; server thay kDefaultLook bằng id thật lúc tạo nhân vật, nên ở đây không có nghĩa mặc định. |
| 6 | `hair` | `u16` | – | Id tóc trong hairs.tsv mà server đã lưu (0 là id tóc hợp lệ); kDefaultLook chỉ có nghĩa trong CreateCharacter. |
| 7 | `school` | `u8` | – | Môn phái; 0 là chưa vào môn phái, giữ giá trị canh của Dev thay cho optional. |
| 8 | `scene` | `u16` | – | SceneId của Dev: cảnh nhân vật đang đứng. |

## Enum

Giá trị ngoài bảng là lỗi kBadEnum ở cả hai chiều.

### AvatarFrame (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kRound` | – |
| 2 | `kSquare` | – |

### DisconnectReason (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kLoggedOut` | – |
| 2 | `kLoginElsewhere` | – |
| 3 | `kIdle` | – |
| 4 | `kKicked` | – |
| 5 | `kShutdown` | – |
| 6 | `kProtocolViolation` | – |
| 7 | `kVersionMismatch` | – |
| 8 | `kServerFull` | – |
| 9 | `kContentMismatch` | – |

### ErrorCode (u16)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kMalformed` | – |
| 2 | `kVersionMismatch` | – |
| 3 | `kNotAuthenticated` | – |
| 4 | `kBadCredentials` | – |
| 5 | `kSessionExpired` | – |
| 6 | `kOutOfOrder` | – |
| 7 | `kNameTaken` | – |
| 8 | `kNameInvalid` | – |
| 9 | `kCharacterLimit` | – |
| 10 | `kNoSuchCharacter` | – |
| 11 | `kMoveBlocked` | – |
| 12 | `kRateLimited` | – |
| 13 | `kServerFull` | – |
| 14 | `kMaintenance` | – |
| 15 | `kPasswordInvalid` | – |
| 16 | `kBusy` | – |
| 17 | `kNoSession` | – |
| 18 | `kStaleSession` | – |
| 19 | `kBadOption` | – |
| 20 | `kTooFar` | – |
| 21 | `kNoSuchEntity` | – |
| 22 | `kQuestUnavailable` | – |
| 23 | `kQuestLogFull` | – |
| 24 | `kQuestState` | – |
| 25 | `kBagFull` | – |
| 26 | `kNotEnoughMoney` | – |
| 27 | `kNotEnoughItems` | – |
| 28 | `kDuplicate` | – |
| 29 | `kCannotAbandon` | – |
| 30 | `kBadChoice` | – |
| 31 | `kOutOfRange` | – |
| 32 | `kCannotAttack` | – |

### Gender (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kFemale` | – |
| 2 | `kMale` | – |

### Platform (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kWindows` | – |
| 2 | `kAndroid` | – |
| 3 | `kIos` | – |
