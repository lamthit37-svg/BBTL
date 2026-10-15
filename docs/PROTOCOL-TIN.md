<!-- Tệp sinh bởi TOOLS/server/gen_protocol.py từ src/shared/protocol/catalog/*.tsv; không sửa tay. Sửa bảng rồi chạy lại: python -B TOOLS/server/gen_protocol.py -->

# Danh mục tin của giao thức

Bản danh mục 5: 39 tin, 6 record, 12 enum.
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

## Nhóm 04: world

Thế giới: người chơi vào cảnh, thực thể xuất hiện, di chuyển và biến mất trong vùng nhìn.

| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |
|---|---|---|---|---|---|
| `0x8401` | SceneEnter | game | server | 4 | 16 |
| `0x8402` | EntityAppear | game | server | 4 | 81 |
| `0x8403` | EntityDisappear | game | server | 4 | 4 |
| `0x8404` | EntityPos | game | server | 4 | 19 |
| `0x8405` | EntityVitals | game | server | 4 | 5 |
| `0x8406` | EntityFlags | game | server | 5 | 5 |

### SceneEnter (0x8401)

Server báo nhân vật đã vào một cảnh: id cảnh, vị trí và hướng đầu tiên. Gửi lúc vào game và mỗi lần đổi cảnh.

Cổng game, server gửi, có từ bản 4. Thân tối đa 16 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `scene` | `u16` | – | Id cảnh (SceneAttr của client 2026). |
| 2 | `x_cm` | `f32` | – | Toạ độ X đầu tiên, centimet. |
| 3 | `z_cm` | `f32` | – | Toạ độ Z đầu tiên, centimet. |
| 4 | `direction` | `u16` | – | Hướng nhìn: 0..65535 ứng với 0..2π; 0 là hướng +X, tăng dần quay về phía +Z. |
| 5 | `self_id` | `u32` | – | Id thực thể của chính nhân vật trong cảnh này (cùng không gian id với EntityAppear.id): client dùng để chọn mục tiêu và nhận ra mình trong EntityPos/EntityVitals. Đổi mỗi lần vào cảnh. |

### EntityAppear (0x8402)

Một thực thể (người, quái, NPC...) bước vào vùng nhìn của client.

Cổng game, server gửi, có từ bản 4. Thân tối đa 81 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `id` | `u32` | – | Id thực thể trong cảnh; không dùng lại ngay sau khi thực thể biến mất (có số thế hệ). |
| 2 | `kind` | `enum:EntityKind` | – | – |
| 3 | `template_id` | `u32` | – | Id mẫu: quái (monsters.tsv), NPC; 0 với người chơi. |
| 4 | `name` | `text` | 48 | Tên hiển thị của người chơi; rỗng với quái và NPC (client tra theo mẫu). |
| 5 | `level` | `u16` | – | – |
| 6 | `x_cm` | `f32` | – | Toạ độ X, centimet. |
| 7 | `z_cm` | `f32` | – | Toạ độ Z, centimet. |
| 8 | `direction` | `u16` | – | Hướng nhìn: 0..65535 ứng với 0..2π; 0 là hướng +X, tăng dần quay về phía +Z. |
| 9 | `speed_cm` | `u16` | – | Tốc độ chạy, centimet mỗi giây. |
| 10 | `hp_percent` | `u8` | – | Sinh lực theo phần trăm 0..100. |
| 11 | `gender` | `u8` | – | 1 nữ, 2 nam; 0 với thực thể không phải người. |
| 12 | `face` | `u16` | – | Id mặt trong faces.tsv; chỉ có nghĩa với người chơi. |
| 13 | `hair` | `u16` | – | Id tóc trong hairs.tsv; chỉ có nghĩa với người chơi. |
| 14 | `school` | `u8` | – | Môn phái 0..15; chỉ có nghĩa với người chơi. |
| 15 | `state` | `enum:EntityState` | – | Trạng thái lúc hiện: Idle, Walk (đang đi, EntityPos tiếp theo sẽ tới) hay Dead (xác còn nằm lại, hp_percent là 0). |

### EntityDisappear (0x8403)

Một thực thể rời vùng nhìn của client hoặc biến mất khỏi cảnh.

Cổng game, server gửi, có từ bản 4. Thân tối đa 4 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `id` | `u32` | – | Id thực thể. |

### EntityPos (0x8404)

Vị trí mới của một thực thể trong vùng nhìn; client nội suy giữa hai lần nhận.

Cổng game, server gửi, có từ bản 4. Thân tối đa 19 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `id` | `u32` | – | Id thực thể. |
| 2 | `x_cm` | `f32` | – | Toạ độ X, centimet. |
| 3 | `z_cm` | `f32` | – | Toạ độ Z, centimet. |
| 4 | `direction` | `u16` | – | Hướng nhìn: 0..65535 ứng với 0..2π; 0 là hướng +X, tăng dần quay về phía +Z. |
| 5 | `tick` | `u32` | – | Tick của cảnh lúc ghi nhận, 20 tick mỗi giây (50 ms một tick); khác bộ đếm tick 30/giây của Move/Position. Client nội suy giữa hai gói theo hiệu hai tick. |
| 6 | `state` | `enum:EntityState` | – | Walk khi đang di chuyển; gói cuối của một chặng đi mang Idle cùng toạ độ đích. Dead khi chết. |

### EntityVitals (0x8405)

Sinh lực của một thực thể trong vùng nhìn, theo phần trăm.

Cổng game, server gửi, có từ bản 4. Thân tối đa 5 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `id` | `u32` | – | Id thực thể. |
| 2 | `hp_percent` | `u8` | – | Sinh lực theo phần trăm 0..100. |

### EntityFlags (0x8406)

Cờ của một thực thể trong vùng nhìn; gửi ngay sau EntityAppear khi cờ khác 0 và mỗi khi cờ đổi.

Cổng game, server gửi, có từ bản 5. Thân tối đa 5 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `id` | `u32` | – | Id thực thể. |
| 2 | `flags` | `u8` | – | Bit 0: bấm vào được để nói chuyện (Talk). |

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

## Nhóm 06: dialogue

Hội thoại với NPC và nhiệm vụ: mở hộp thoại, chọn mục, nhận, nộp, bỏ nhiệm vụ và sổ nhiệm vụ.

| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |
|---|---|---|---|---|---|
| `0x0601` | Talk | game | client | 5 | 4 |
| `0x0602` | DialogChoose | game | client | 5 | 10 |
| `0x0603` | QuestAccept | game | client | 5 | 10 |
| `0x0604` | QuestTurnIn | game | client | 5 | 14 |
| `0x0605` | QuestAbandon | game | client | 5 | 2 |
| `0x0606` | DialogClose | game | client | 5 | 8 |
| `0x8601` | DialogOpen | game | server | 5 | 29 473 |
| `0x8602` | DialogClosed | game | server | 5 | 9 |
| `0x8603` | QuestBook | game | server | 5 | 1 334 |
| `0x8604` | QuestNotice | game | server | 5 | 531 |

### Talk (0x0601)

Bấm vào NPC để nói chuyện: mở phiên hội thoại. Server kiểm khoảng cách, cảnh và NPC còn đó.

Cổng game, client gửi, có từ bản 5. Thân tối đa 4 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `npc` | `u32` | – | EntityAppear.id của NPC. |

### DialogChoose (0x0602)

Chọn một lựa chọn của hộp thoại đang mở (theo index server đã gửi, không phải id script).

Cổng game, client gửi, có từ bản 5. Thân tối đa 10 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `session` | `u64` | – | Mã phiên trong DialogOpen. |
| 2 | `index` | `u16` | – | DialogChoice.index. |

### QuestAccept (0x0603)

Nhận nhiệm vụ mà hộp thoại đang mời.

Cổng game, client gửi, có từ bản 5. Thân tối đa 10 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `session` | `u64` | – | – |
| 2 | `quest` | `u16` | – | – |

### QuestTurnIn (0x0604)

Nộp nhiệm vụ đang làm, kèm phần thưởng chọn một nếu có.

Cổng game, client gửi, có từ bản 5. Thân tối đa 14 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `session` | `u64` | – | – |
| 2 | `quest` | `u16` | – | – |
| 3 | `reward` | `i32` | – | Mẫu vật phẩm đã chọn trong nhóm thưởng chọn một; -1 nếu nhiệm vụ không có nhóm đó. |

### QuestAbandon (0x0605)

Bỏ nhiệm vụ đang làm; bấm từ sổ nhiệm vụ nên không cần phiên hội thoại.

Cổng game, client gửi, có từ bản 5. Thân tối đa 2 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `quest` | `u16` | – | – |

### DialogClose (0x0606)

Client đóng hộp thoại; server đóng phiên.

Cổng game, client gửi, có từ bản 5. Thân tối đa 8 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `session` | `u64` | – | – |

### DialogOpen (0x8601)

Server mở hay thay hộp thoại của phiên: lời NPC, lựa chọn, dấu nhiệm vụ, bảng nhiệm vụ và phần thưởng.

Cổng game, server gửi, có từ bản 5. Thân tối đa 29 473 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `session` | `u64` | – | Mã phiên, tăng ngặt, không dùng lại; gửi lại trong mọi tin sau của hộp thoại này. |
| 2 | `npc` | `u32` | – | EntityAppear.id của NPC; 0 với hộp thoại không gắn NPC. |
| 3 | `mode` | `enum:DialogMode` | – | – |
| 4 | `lines` | `list:record:DialogLine` | 16 | – |
| 5 | `choices` | `list:record:DialogChoice` | 48 | – |
| 6 | `marks` | `list:record:DialogMark` | 16 | – |
| 7 | `panel_quest` | `i32` | – | Nhiệm vụ của bảng (MissionInfo, Continue, Demand, Tips); -1 nếu không có. |
| 8 | `bonuses` | `list:record:DialogBonus` | 24 | – |

### DialogClosed (0x8602)

Server đóng phiên hội thoại và nêu lý do.

Cổng game, server gửi, có từ bản 5. Thân tối đa 9 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `session` | `u64` | – | – |
| 2 | `reason` | `enum:DialogCloseReason` | – | – |

### QuestBook (0x8603)

Toàn bộ sổ nhiệm vụ: ô đang giữ và tập nhiệm vụ đã xong. Gửi sau SceneEnter và mỗi khi sổ đổi.

Cổng game, server gửi, có từ bản 5. Thân tối đa 1 334 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `slots` | `list:record:QuestSlot` | 20 | – |
| 2 | `done` | `bytes` | 512 | 128 từ u32 little-endian: bit (id % 32) của từ (id / 32) bật là nhiệm vụ id đã xong (id 0..4095). |

### QuestNotice (0x8604)

Thông báo của hệ nhiệm vụ cho người chơi: nhận, tiến độ, đủ điều kiện nộp, thưởng, chữ.

Cổng game, server gửi, có từ bản 5. Thân tối đa 531 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `kind` | `enum:QuestNoticeKind` | – | – |
| 2 | `quest` | `i32` | – | Id nhiệm vụ; -1 nếu không gắn nhiệm vụ. |
| 3 | `text` | `text` | 512 | Chữ đã dựng; rỗng với kind không có chữ. |
| 4 | `value` | `i64` | – | RewardExp: kinh nghiệm. RewardMoney: số tiền. RewardItem: số lượng. Relation: giá trị mới. |
| 5 | `ref` | `i32` | – | RewardMoney: 1 nếu tiền khoá. RewardItem: mẫu vật phẩm. Relation: chỉ số quan hệ. |

## Nhóm 07: self

Trạng thái của chính nhân vật: cấp, kinh nghiệm, tiền.

| Kind | Tin | Cổng | Chiều | Từ bản | Thân tối đa (byte) |
|---|---|---|---|---|---|
| `0x8701` | SelfStats | game | server | 5 | 26 |

### SelfStats (0x8701)

Cấp, kinh nghiệm và tiền của chính nhân vật. Gửi sau SceneEnter và mỗi khi đổi.

Cổng game, server gửi, có từ bản 5. Thân tối đa 26 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `level` | `u16` | – | – |
| 2 | `exp` | `u64` | – | Kinh nghiệm hiện có trong cấp. |
| 3 | `money` | `u64` | – | Tiền thường. |
| 4 | `bound_money` | `u64` | – | Tiền khoá. |

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

### DialogBonus

Một dòng phần thưởng hay yêu cầu của bảng nhiệm vụ.

Thân tối đa 13 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `kind` | `enum:BonusKind` | – | Money: a là số tiền. Item, Radio, Random, Demand: a là mẫu vật phẩm, b là số lượng. |
| 2 | `a` | `i32` | – | – |
| 3 | `b` | `i32` | – | – |
| 4 | `c` | `i32` | – | – |

### DialogChoice

Một lựa chọn của hộp thoại.

Thân tối đa 264 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `index` | `u16` | – | Số client gửi lại trong DialogChoose; không phải id script. |
| 2 | `icon` | `i32` | – | Biểu tượng của mục; 0 là không có. |
| 3 | `text` | `text` | 256 | Chữ của lựa chọn. |

### DialogLine

Một dòng lời NPC trong hộp thoại, đã dựng thành chữ.

Thân tối đa 1 026 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `text` | `text` | 1024 | Chữ đã dựng (tham số tên, cấp... đã thay), UTF-8; có thẻ màu #R #W... của game. |

### DialogMark

Dấu nhiệm vụ của một nhiệm vụ gắn với NPC đang nói chuyện.

Thân tối đa 3 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `quest` | `u16` | – | Id nhiệm vụ (0..4095). |
| 2 | `stage` | `enum:MarkStage` | – | – |

### QuestSlot

Một ô của sổ nhiệm vụ.

Thân tối đa 41 byte.

| Thứ tự | Trường | Kiểu | Trần | Ghi chú |
|---|---|---|---|---|
| 1 | `quest` | `u16` | – | Id nhiệm vụ của client 2026. |
| 2 | `script` | `i32` | – | Id script của nhiệm vụ; -1 nếu không có. |
| 3 | `flags` | `u8` | – | Bit 1 giết, 2 vùng, 4 vật phẩm: loại sự kiện nhiệm vụ này theo dõi. |
| 4 | `params` | `list:u32` | 8 | Tám tham số của ô; nhiệm vụ bảng: tham số 0 là cờ đủ điều kiện nộp, 1 + i là tiến độ mục tiêu i. |

## Enum

Giá trị ngoài bảng là lỗi kBadEnum ở cả hai chiều.

### AvatarFrame (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kRound` | – |
| 2 | `kSquare` | – |

### BonusKind (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kMoney` | – |
| 2 | `kItem` | – |
| 3 | `kRadio` | – |
| 4 | `kRandom` | – |
| 5 | `kDemand` | – |

### DialogCloseReason (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kDone` | – |
| 2 | `kFar` | – |
| 3 | `kSceneChanged` | – |
| 4 | `kNpcGone` | – |
| 5 | `kExpired` | – |
| 6 | `kReplaced` | – |
| 7 | `kDead` | – |
| 8 | `kClient` | – |

### DialogMode (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kList` | – |
| 2 | `kBox` | – |
| 3 | `kMissionInfo` | – |
| 4 | `kContinue` | – |
| 5 | `kDemand` | – |
| 6 | `kTips` | – |

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

### EntityKind (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kPlayer` | – |
| 2 | `kMonster` | – |
| 3 | `kNpc` | – |
| 4 | `kPet` | – |
| 5 | `kDrop` | – |
| 6 | `kObject` | – |

### EntityState (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kIdle` | – |
| 2 | `kWalk` | – |
| 3 | `kDead` | – |

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

### MarkStage (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kAvailable` | – |
| 2 | `kInProgress` | – |
| 3 | `kReady` | – |

### Platform (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kWindows` | – |
| 2 | `kAndroid` | – |
| 3 | `kIos` | – |

### QuestNoticeKind (u8)

| Giá trị | Tên | Ghi chú |
|---|---|---|
| 1 | `kAdded` | – |
| 2 | `kUpdated` | – |
| 3 | `kReady` | – |
| 4 | `kRemoved` | – |
| 5 | `kDone` | – |
| 6 | `kFailed` | – |
| 7 | `kText` | – |
| 8 | `kAnnounce` | – |
| 9 | `kRewardExp` | – |
| 10 | `kRewardMoney` | – |
| 11 | `kRewardItem` | – |
| 12 | `kRelation` | – |
