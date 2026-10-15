# Luồng đăng nhập → chọn nhân vật → vào game của client 2026 (đo từ mã máy)

Nguồn: `Game.exe` 3.71 (Ghidra, dự án TLBB). Địa chỉ ảo, gốc ảnh `0x140000000`. Bằng chứng thô ở
`TAILIEU/ghidra/` (`states.txt`, `login2.txt`, `charsel.txt`, `enter2.txt`, `ntf.txt`, `cam.txt`). Chỗ nào là
suy luận (không đo thẳng) thì ghi "suy".

## 1. Máy trạng thái thủ tục

Game giữ một thủ tục đang chạy; mỗi thủ tục là một lớp có RTTI (vtable ghi bằng địa chỉ của nhãn `::vftable`).

| Lớp | vtable | Nội dung đo được |
|---|---|---|
| `CGamePro_Login` | `0x140c2b408` | slot 0 `0x140630fd0` là Init, slot 1 `0x140631290` là nhịp (công tắc theo `+0x2c0`), slot 4 `0x140630e10` là nhập phím |
| `CGamePro_CharSel` | `0x140c2c7b8` | slot 0 `0x14063d530` Init, slot 1 `0x14063d8b0` nhịp, slot 4 `0x14063b4f0` sự kiện chuột |
| `CGamePro_CharCreate` | `0x140c2cea8` | Init `0x1406413e0` (xem `docs/TAO-NHAN-VAT-2026.md`) |
| `CGamePro_ChangeScene` | `0x140c2f778` | nhịp `0x140650e80`: trạng thái 0 nối máy chủ game, 2 gửi `CGConnect`, 4 đổi sang Enter |
| `CGamePro_Enter` | `0x140c2d238` | nhịp `0x1406447f0`: trạng thái 0→1, 1 làm mờ rồi gửi `CGEnterScene`, 3 xong |
| `CGamePro_Main` | `0x140c2ea18` | màn chơi |

Chuỗi vào game lần đầu: Login → (LCRetLogin) → CharSel (danh sách `LCRetCharList`) → [CharCreate] →
bấm "进入游戏" gửi `CLAskCharLogin` → `LCRetCharLogin` (`0x140836eb0` đọc, handler `0x1405b1e90`: đặt biến `WorldID`,
`KVKExchangeMode`, đẩy sự kiện `0x127` GAMELOGIN_CLEAR_ACCOUNT, đổi sang ChangeScene) → ChangeScene (nối máy chủ game,
`CGConnect`, `GCConnect`) → Enter (làm mờ, `CGEnterScene`) → `GCEnterScene` → Main.

## 2. Thủ tục Login (`CGamePro_Login`)

Ô trạng thái `+0x2c0` (đã thấy): 2 = bảng chọn máy chủ đang hiện; 3 = bảng nhập tài khoản đang hiện; 5 → 6 = nối
máy chủ đăng nhập (`FUN_14050f120(mạng, host, cổng)`); 8 = ngắt rồi về 2; 9 = nhập tài khoản lại sau khi
`LCRetLogin` mã 10; `0xb`, `0xd`, `0x12` chưa xét.

- **Cửa sổ** (hàm `0x140631940`, gọi từ Init): `SetRect(0,0,0x500,0x2d0)` rồi `AdjustWindowRect` theo kiểu cửa sổ, cỡ
  tối thiểu 800 × 600; vị trí X = (rộng vùng làm việc − rộng khung)/2, Y = (cao vùng làm việc − cao khung)/2,
  kẹp ≥ 0, vùng làm việc lấy bằng `SystemParametersInfo(SPI_GETWORKAREA)` (màn hình chính, trừ thanh tác vụ).
  → **Cửa sổ luôn mở giữa màn hình chính.** Đã nối: `engine/window/window.cpp` `initial_frame` (2026-10-13), test
  `window_opens_centered_in_primary_work_area`.
- **Init** (`0x140630fd0`): nạp cảnh nền `erengu_DL.Scene` (id −1), bật chế độ đăng nhập của hệ vẽ; đọc biến hệ thống
  `GameServer_ConnectDirect` (=1 thì bỏ qua chọn máy chủ), `PlayLoadingVideo` (khác 0 và > 0 thì phát video nạp).
- **Vào thẳng bảng tài khoản** (`0x14062bf50`): nếu launcher truyền sẵn `Login_Area`, `Login_Server`,
  `Login_Provider` mà khớp danh sách máy chủ thì đẩy `0x1c5` GAMELOGIN_LASTSELECT_AREA_AND_SERVER(vùng, máy chủ), rồi
  `0x11a` GAMELOGIN_OPEN_COUNT_INPUT, đặt trạng thái 3. Đây là đường người chơi đi trong thực tế (launcher chọn
  máy chủ), nên màn ĐẦU là bảng tài khoản; bảng chọn máy chủ chỉ hiện khi quay lại.
- **Về bảng chọn máy chủ** (`0x14062c450`): đẩy `0x118` OPEN_SELECT_SERVER, `0x117` CLOSE_SYSTEM_INFO, `0x11b`
  CLOSE_COUNT_INPUT, ngắt mạng, đặt trạng thái 2. Nút "上一步" của `LogOn.lua` (dòng 422, `ExitToSelectServer`) đi đường
  này. **Phím Esc ở trạng thái 3 cũng đi đường này** (`0x140630e10`: sự kiện phím mã `0x1b` khi `+0x2c0 == 3`).
- **Phím Enter** (`0x140630e10`, mã `0xd` hay `0xff`): ở trạng thái 2 với ô tìm máy chủ `SelectServer_Server_SearchName`
  rỗng thì đẩy sự kiện xác nhận chọn máy chủ; ở trạng thái `0xd` đẩy sự kiện; ở trạng thái 3 phía C++ không xử lý
  (việc gửi tài khoản đi qua script `LogOn.lua`).
- **Nhịp** (`0x140631290`): trạng thái 3 đăng ký phím nóng PrintScreen (`0x2c`, hai tổ hợp) và tự thu nhỏ cửa sổ
  (`SendMessage(WM_SYSCOMMAND, SC_MINIMIZE = 0xf020)`) khi cửa sổ không còn là cửa sổ trước, không nút chuột nào
  đang nhấn và cửa sổ chưa thu nhỏ.
- **Thông điệp lỗi đăng nhập** (`LCRetLogin` → `0x116` GAMELOGIN_SHOW_SYSTEM_INFO): bảng mã kết quả ở
  `MAY-CHU-SUY-RA.md`.

## 3. Thủ tục CharSel (`CGamePro_CharSel`)

- **Init** (`0x14063d530`): `FUN_14063de10` (dọn), nạp cảnh `tl3chuangjian.Scene` (id −2), chế độ camera 3 (bảng chọn),
  dựng ba người mẫu (`0x14063b8f0`: mỗi ô một nhân vật với tới 19 ô trang bị nhìn thấy, vũ khí ngoại hình bảng
  `0x20f`, bảng trang bị `0x73`, màu tóc/da giải bằng `FUN_140766f30`), tham số trời `0x350(0, 0,9479)`, đặt tiêu đề
  cửa sổ `"%s %s (%s:%s%s)"` từ `Login_Area`, `Login_ServerName`, tên trò chơi, phiên bản.
- **Camera khi vào bảng chọn** (`0x14063d620`): gọi `0x1800025e0(ngược, không giữ, track = ô + 1, thời điểm 1,1 s)`
  (hằng `0x140b0cfd4` = 1,1). `0x1800025e0` (Render.dll, `cam.txt`): `track ≠ track vừa chạy` thì đặt
  `thời điểm = chiều ngược ? dài − min(1,1; dài) : min(1,1; dài)`. Track dài 2 s → bắt đầu ở 0,9 s (ngay trước khoá
  giữa lùi ra) chạy ngược về 0 (mắt của ô): **camera lướt chừng 0,9 s (ô 1: 1,4 s) vào ô đang chọn**. Đã nối:
  `RoleStage::rest_at` (2026-10-13; trước đó chạy xuôi từ 0 trên track kết thúc ở ô).
- **Đổi ô bằng giao diện** (`0x14063c480`, thay cho địa chỉ `0x14063bb70` ghi sai trong tài liệu cũ): bảng 0→1 xuôi
  track 1, 1→2 xuôi track 2, 2→0 xuôi track 3, 0→2 ngược track 3, 1→0 ngược track 1, 2→1 ngược track 2; đẩy `0x18e`
  GAMELOGIN_SELECTCHARACTER(ô); nếu camera đang chạy dở (`0x240`) thì ghi ô chờ (`+0x58c`). Khớp bản port.
- **Bấm trúng người mẫu** (`0x14063c0b0` + `0x14063d4a0` chọn mô hình dưới con trỏ): ô khác ô hiện tại thì đẩy `0x18e`
  và chạy track `ô + 1` với `xuôi = (ô hiện tại ≠ −1)`, thời điểm −1. Lần chọn đầu tiên (ô hiện tại −1) ép track 1
  chạy ngược. Chưa nối vào bản port (suy: bản port chọn ô bằng nút giao diện).
- **Hoạt ảnh nhàn rỗi** (`0x14063c210`, `0x14063c290`): mỗi ô chọn ngẫu nhiên hoạt ảnh 1 hay 2 (`rand() & 1 + 1`).
- **Đếm ngược "Login_Char_Playing"** (nhịp `0x14063d8b0`, ô `+0x528 == 3`, `+0x530` mili giây còn lại): mỗi giây đẩy
  `0x123` GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON với chữ khoá `Login_Char_Playing` kèm số giây; hết giờ đẩy `0x117`
  rồi `0x14063a000`: về bảng nhập tài khoản (đẩy `0x11a`, `0x11d`, `0x31d`, đặt `Login.+0x2c0 = 9`). Dùng khi nhân vật đang
  chơi (suy). Chưa có trong bản port.

## 4. Vào game (Enter, ChangeScene)

- **ChangeScene** nhịp (`0x140650e80`): trạng thái 0 (`0x1406508f0`) nối TCP tới máy chủ game (host `0x140fb2b28`, cổng
  `0x14103e808`, thời hạn 15000 ms khi nối lại); trạng thái 2 (`0x140650a80`) gửi `CGConnect`; trạng thái 4
  (`0x140650db0`) ghi log `EnterScene` rồi đổi sang Enter.
- **Enter** trạng thái 1 (`0x140644700`): lần đầu ghi mốc, rồi mỗi nhịp gọi `Render.CRenderSystem+0x3e8(bật = 1,
  t·2, t)` với `t = (đã trôi)/2500` trong 2500 ms; hết thì tắt (`+0x3e8(0,0,0)`) và trả 1 → gửi `CGEnterScene(cảnh, x, z)`.
  `+0x3e8` (Render.dll `0x18002dd40`) bật compositor **`TransSceneEffect`** đặt tham số `timeFactor_Blur = t`
  — shader `MaterialTemplates/TransSceneEffect.hlsl` (`TransScene_Wave_fp`: xoắn sóng theo texture hỗn loạn, thời gian
  nhân 2,5). Tức khi bấm "进入游戏", cảnh chọn nhân vật **xoắn sóng trong 2,5 giây** rồi mới vào cảnh. **Chưa có trong
  bản port** (cần hậu kỳ trên render target ngoài màn hình).
- **Enter** trạng thái 3: đóng giao diện đăng nhập (`0x117`, `0x11b`, `0x11d`, `0x11f`; sau đó `0x11d`, `0x121`
  GAMELOGIN_CLOSE_BACK_GROUND), đọc `Camera_Zoom`, dựng người chơi (`0x1406441b0`), gửi `CGAskDynamicRegion`.
- **Bảng "前往 …" (SceneTrans)**: sự kiện `PLAYER_LEAVE_WORLD` (id 7, kèm tên cảnh) chỉ do `GCNotifyChangeScene`
  phát (handler `0x140549140`, đẩy `0x6dc`, rồi `7`, rồi `2` ON_SCENE_TRANSING). Chuỗi vào game lần đầu
  (`LCRetCharLogin`, ChangeScene, Enter, `GCEnterScene` `0x1405476d0`) không đẩy `7`. → **Lần vào đầu KHÔNG hiện bảng
  này**; chỉ lần đổi cảnh do máy chủ báo. Đã nối: `Display::State::scene_load` (2026-10-13). Kết luận mục 46 của sổ nghi ngờ.

## 5. Đã nối vào mã (2026-10-13) và còn thiếu

Đã nối: cửa sổ mở giữa màn hình chính; camera lướt vào ô khi mở bảng chọn; bảng SceneTrans chỉ cho lần đổi cảnh
sau lần vào đầu; đính chính địa chỉ `0x14063c480`.

Còn thiếu so với bản gốc (xếp theo độ thấy được):

1. Bảng chọn máy chủ (`SelectServer`, 3103 dòng Lua, dữ liệu `Patch/LoginServer.txt` mã hoá): "上一步" ở bảng tài
   khoản và phím Esc về đây; bản port đóng client.
2. Hiệu ứng xoắn sóng 2,5 s khi vào game (mục 4).
3. Hộp thông báo hệ thống của đăng nhập (`GAMELOGIN_SHOW_SYSTEM_INFO`, YesNo `0x122`): xoá nhân vật, quay lại, lỗi.
4. Đếm ngược "Login_Char_Playing" ở bảng chọn (mục 3); bấm trúng người mẫu để chọn ô.
5. Phím nóng PrintScreen, thu nhỏ cửa sổ khi mất focus.
