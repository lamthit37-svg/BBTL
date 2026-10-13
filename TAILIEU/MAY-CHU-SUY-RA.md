# Suy ra cho máy chủ từ client gốc

Nguồn: `Game.exe` 3.71 (`TAILIEU/ghidra/login_packets.txt`, `login2.txt`, `ntf.txt`), bảng trường ở
`GOI-TIN-DANG-NHAP.md`, script `Logon.lua`, `SelectRole.lua`, `CreateRole.lua`. "Đo" là đọc thẳng từ mã máy; "suy" là
kết luận từ cách client dùng dữ liệu. Máy chủ của dự án KHÔNG nói giao thức gốc (có bắt tay libsodium, danh mục tin
ở `src/shared/protocol/catalog`); tài liệu này nêu client gốc cần máy chủ làm gì để giao diện hành xử như bản gốc.

## 1. Chuỗi gói tin gốc (đo từ tên lớp `Packets::*` và hàm Read/Write)

Máy chủ đăng nhập (client gửi `CL…`, nhận `LC…`):

| Bước | Client gửi | Máy chủ trả | Ghi chú |
|---|---|---|---|
| Nối | `CLConnect` (phiên bản, tên, nền…) | `LCRetConnect` | |
| Đăng nhập | `CLAskLogin` (tài khoản 0x32 byte, mật khẩu độ dài + bytes, ba cờ, MAC/ổ cứng, mã bảo mật…) | `LCRetLogin` (mã kết quả, bảng dưới) | thêm `CLAskQRCodeLogin`, `CLAskWeGameLogin`, `CLAskSMSCode` |
| Hàng đợi | `CLAskQueueMsg`, `CLAskQuitQuene` | `LCRetQueueMsg` | mã `0x17` LOGIN_MUST_WAIT |
| Danh sách | `CLAskCharList` | `LCRetCharList` | bản ghi 420 byte mỗi nhân vật, ≤ 5 (client kẹp 5, giao diện 3) |
| Tạo | `CLCheckAllowCreateChar` rồi `CLAskCreateChar` | `LCRetCheckAllowCreateChar` (u32), `LCRetCreateChar` | hỏi phép tạo TRƯỚC khi mở bảng tạo (`DataPool:AskCreateChar`) |
| Xoá | `CLAskDeleteChar` (id, tên 0x33 byte), `CLCancelDelChar` | `LCRetDeleteChar`, `LCRetCancelDelChar` | hộp YesNo trước khi gửi; huỷ xoá khi `iDelTime > 0` (mục 3) |
| Vào game | `CLAskCharLogin` (id nhân vật, tên, thông tin phiên…) | `LCRetCharLogin` (kết quả, **địa chỉ máy chủ game, cổng, khoá**) | client đặt biến `WorldID`, đổi sang ChangeScene |
| Trạng thái | | `LCStatus` | |

Máy chủ game (`CG…` / `GC…`):

| Bước | Client gửi | Máy chủ trả |
|---|---|---|
| Nối game | `CGConnect` (khoá, tên, … 0x80 byte chứng thực) | `GCConnect` (cảnh, vị trí…) |
| Vào cảnh | `CGEnterScene` (id cảnh u16, cờ u8, vị trí 8 byte) | `GCEnterScene` (17 trường), rồi `GCCharBaseAttrib`, `GCDetailAttrib`, `GCNewPlayer`… |
| Đổi cảnh | `CGAskChangeScene` | `GCNotifyChangeScene` (cảnh đích, resid, vị trí), `GCRetChangeScene` |

## 2. Mã kết quả `LCRetLogin` → thông điệp (đo từ `0x1405b4ba0`, `FUN_14009cd50` trả mã)

Thông điệp đi qua sự kiện `0x116` GAMELOGIN_SHOW_SYSTEM_INFO kèm một khoá chữ của client (bảng chữ gốc).

| Mã | Khoá chữ / việc client làm |
|---|---|
| 0 | `LCRetLoginHandler_1`, sự kiện `0x123` (hộp không nút): đăng nhập qua, chờ danh sách |
| 1 | `LCRetLoginHandler_Info_UserId_Password_Err` — sai tài khoản hoặc mật khẩu |
| 2, 0x53 | `LCRetLoginHandler_Info_Error_Version` (kèm số phiên bản hex) — lệch phiên bản |
| 3 | `…Info_Point_Is_Not_Enough` — hết điểm |
| 4 | `…Info_Server_Is_Stop` — máy chủ dừng |
| 5 | `…Info_Player_is_on_other_server` — đang ở máy chủ khác |
| 7, 0x2f | `…Info_User_Stop` (`LOGNR_Forbit`, `ThreedAccForbit`) — tài khoản bị khoá |
| 8, 0x34 | `…Info_User_Online` (`USERONLINE`) — tài khoản đang trực tuyến |
| 9 | `GMGameInterface_Script_GameLogin_Info_Set_Password` — phải đặt mật khẩu |
| 10 | mở lại nhập tài khoản (`0x11a`), Login `+0x2c0 = 9` |
| 0xf, 0x10, 0x1b | thẻ bảo mật / mibao (`LOGIN_NO_MIBAO`, `…MiBao_Value_Err`, `…PhoneMibaoNoActive_Err`) |
| 0x11 | `…Info_Ip_Addr_Err` — IP không hợp lệ |
| 0x12 | `…Info_Lock_By_Mobile_Err` |
| 0x17 | `#{DLYH_180224_01}` (`LOGIN_MUST_WAIT`) — vào hàng đợi |
| 0x18 | `…Info_ConnectErr` |
| 0x1c | `LCRetLoginHandler_ReLogin_StopTime_Err` |
| 0x46, 0x47, 0x48, 0x4b, 0x4c | `CN_REMOVEACCOUNT`, `CN_SHIMING_INVALID`, `FCM_CERTNUM_CHECKERROR`, `CN_ERR_KAJIWAIGUA`, `CN_NOPHONE` (bản Trung Quốc) |
| khác | `…Info_ConnectErr` (nhánh mặc định) |

Đối chiếu với `ErrorCode` của dự án (`enums.tsv`): `BadCredentials`→1, `VersionMismatch`→2, `Maintenance`→4,
tài khoản bị khoá (chưa có mã)→7, phiên cũ còn sống `StaleSession`→8, `ServerFull`→0x17.

## 3. Dữ liệu mỗi bước cần máy chủ cung cấp (suy từ client và Lua)

**Danh sách nhân vật** — `GameProduceLogin:GetRoleInfo(i)` trả (tên, môn phái, cấp, ngày chờ xoá `iDelTime`, tên ảnh chân
dung, trạng thái bán `iCYGSate`, cấp PK); ngoài ra dựng người mẫu 3D cần: id mặt, id tóc, màu tóc/da, tới 19 ô
trang bị nhìn thấy (ô 0 là vũ khí ngoại hình), id ngoại hình thú cưỡi. `GetCurSelectRole()` là ô chọn sẵn (nhân vật
đăng nhập gần nhất). Tối đa 3 ô (script cố định ba); client đọc tới 5 bản ghi.

Đối chiếu `CharacterSummary` của dự án (`fields.tsv`: id, name, level, gender, face, hair, school, scene): **thiếu**
`portrait` (id ảnh chân dung, khác id mặt 3D), `body`/`arm`/`foot` (áo, bao tay, giày của bộ đồ tân thủ — bản local
`roles.tsv` đã lưu), `delete_pending_days`, `last_selected`; `face`/`hair` hiện là id bảng ngoại hình (đúng).
Cấp, môn phái đã có. (Lưu ý `scene` ở đây để vào game, không hiện ở bảng chọn.)

**Tạo nhân vật** — `CLAskCreateChar` mang tên (0x1e byte), giới, hai cờ byte (màu?), kiểu mặt, kiểu tóc, bộ đồ
tân thủ, ảnh chân dung (`SetFaceId`), dấu nhận (0x20 + 0x33 byte). Máy chủ phải kiểm tên theo luật bản gốc: không rỗng,
≤ 12 byte GBK, không ký tự/chuỗi cấm (`CreateRole` Lua → C++), không trùng trong thế giới. Dự án dùng luật Unicode ≤ 12
mã (`roles.hpp`); chỗ lệch ghi ở `docs/TAO-NHAN-VAT-2026.md` mục 7.

**Xoá nhân vật** — `SelectRole_DelRole` (script hiện hành): ô chưa có nhân vật báo "chưa chọn nhân vật"; nhân vật
có `iDelTime > 0` (đã xin xoá) thì bấm lại là HUỶ xoá (`SelectRole_CancelDelChar` → `CLCancelDelChar`); ngược lại hộp YesNo
"Bạn chắc chắn xoá nhân vật cấp N <tên>?" (mã hộp 4, hoặc 27 khi cấp ≥ 80), đồng ý thì gửi `CLAskDeleteChar`. Nhãn
"đang chờ xoá" hiện theo `iDelTime`. Cơ chế chờ nhiều ngày rồi tới NPC (Lạc Dương 268,46 / Đại Lý 80,136) chỉ còn là
chú thích trong script, nên máy chủ quyết định có dùng độ trễ hay không. Dự án xoá ngay (`DeleteCharacter`); muốn có huỷ xoá
phải thêm `delete_requested_at` và tin `CancelDelete`.

**Vào game** — sau `CLAskCharLogin` máy chủ đăng nhập trả địa chỉ máy chủ game và khoá; client nối, `CGConnect`, rồi
`CGEnterScene(cảnh, vị trí)`. Dự án gộp thành `EnterGame` → `Position` (mốc vào, `Position` đã đủ làm `GCEnterScene`
tối thiểu: cảnh, x, z). `GCEnterScene` gốc mang thêm 17 trường (cảnh, hướng, thời tiết?, …) chưa giải nghĩa.

**Đổi cảnh trong game** — máy chủ phát `GCNotifyChangeScene(cảnh đích, resid, vị trí)`; client hiện bảng "前往 …" (sự kiện
`PLAYER_LEAVE_WORLD`), nạp, rồi `CGEnterScene`. Dự án chưa có tin này; cần khi làm cổng bản đồ qua máy chủ
(`SERVER-DI-CHUYEN.md`).

## 4. Việc máy chủ cần làm để màn đăng nhập hành xử như gốc (đề xuất, chưa làm)

1. Thêm mã lỗi cho tài khoản bị khoá và tài khoản đang trực tuyến; client ánh xạ sang khoá chữ ở mục 2.
2. Mở rộng `CharacterSummary` bằng `portrait`, `body`, `arm`, `foot`, `delete_pending_days`, thêm `last_selected` vào
   `CharacterList`.
3. Quyết định xoá có độ trễ và huỷ xoá (cơ chế `iDelTime` của gốc) hay xoá ngay (hiện tại); nếu có thì thêm `CancelDelete` và cột `delete_requested_at`.
4. Tin hỏi phép tạo nhân vật (`CheckAllowCreateChar`) hoặc cờ `can_create` trong `CharacterList`.
5. Khi làm cổng bản đồ: `NotifyChangeScene` (cảnh đích, vị trí) để bảng chuyển cảnh hiện đúng lúc.
6. Hàng đợi vào máy chủ (`LOGIN_MUST_WAIT`, `QueueMsg`) chỉ cần khi có giới hạn người chơi đồng thời.

## 5. Chưa giải

- Bố cục bản ghi nhân vật 420 byte của `LCRetCharList` (client giải một khối đã mã hoá bằng `FUN_140001000`, rồi sao 0x1a4
  byte mỗi bản ghi). Suy từ `0x14063b8f0`: đọc các ô dword/word cho mặt, tóc, màu, 19 ô trang bị.
- Ý nghĩa 17 trường của `GCEnterScene`; thân `LCRetCharLogin` (khối byte độ dài tuỳ ý, nhánh `== 0xf`).
- Thuật toán mã hoá mật khẩu trong `CLAskLogin` (`FUN_140766440` với byte ngẫu nhiên; dự án dùng Argon2id qua cổng xác
  thực, không cần giống).
