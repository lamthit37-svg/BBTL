# G1-K: đăng nhập tới vào game, phần client

Làn K (`thienlong-14`), nền `d08b9b6e`. Phần máy chủ là `G1-M.md`. Phiếu viết trước khi có mã:
chỗ nào là đo thì ghi số, chỗ nào là kế hoạch thì ghi "kế hoạch".

## Bằng chứng đã đo (2026-10-18)

- Hiện trạng: sáu cửa sổ đều là panel C++ (`ui/panel`: logon 304 dòng, select_server 783 cùng
  servers 248, select_role 250 cùng role_cast 203, create_role 989, scene_trans 55, softkey 123,
  login_flow 658). Host script chỉ chạy `ProgressBar`, `DebugListBox` (`hud.cpp:160`, `kScripted`)
  và chỉ nhận chuột khi `Phase::kPlay` (`hud.cpp:1148`); `Phase::kLogin` không có host.
- Lớp widget của host đã phủ ComboBox, EditBox, SoftKey, SetFakeObject, StartFade (`widget.cpp`
  1756 dòng). Chỗ thiếu thật là hàm game. Đếm trên sáu script gốc (`LogOn`, `SelectServer`,
  `SoftKeyBoard`, `SelectRole`, `CreateRole`, `SceneTrans`): 58 hàm `GameProduceLogin:*` khác
  nhau (host có 2: `IsWeGameClient`, `IsWeGameServer`, `native_state.cpp:193`; bảng gốc
  `lua_api.tsv` đăng ký 96, địa chỉ ở cột impl), 4 hàm `DataPool:*` (`AskCreateChar`,
  `AskCreateCharCode`, `GetCharSaletimeCyg`, `Lua_IsNewServerPlayerByZWID`), `Helper:GotoHelper`,
  `Player:ReportLoginTypeMsg`, `Sound:PlaySound`, `Sound:StopSound`. Các hàm khác (Variable,
  SystemSetup, `DataPool:SetCanUseHotKey`) đã có.
- Cửa sổ phụ, luồng gốc chỉ mở khi máy chủ trả kết quả tương ứng trong `LCRetLogin`
  (`docs/TAILIEU/ghidra/login_packets.txt`): Agreement khi kết quả `0x15` (dòng 1125, đẩy sự kiện
  `0x1f5`); FangChenMi khi kết quả `0x18` (dòng 1160-1190, đẩy `0x20c`); LoginTimer khi `0x17`
  (hàng chờ, `LOGIN_MUST_WAIT`). `SafeCenter_*` mở từ menu trong game (nhường chỗ loại 19), không
  thuộc đăng nhập. `LOGIN_MIBAO` (`0x1c1`, Pswprotect): chưa tìm thấy nơi đẩy trong
  `login_packets.txt`.
- Hộp thông báo lỗi của luồng gốc: sự kiện `0x116` GAMELOGIN_SHOW_SYSTEM_INFO, `0x122` YesNo,
  `0x123` không nút (`DANG-NHAP-GOC.md` mục 2-3), hàm `GameProduceLogin:GameLoginShowSystemInfo`
  (`0x1403448d0`). Đây là hộp G1 phải có, vì G1-M đổi mã từ chối thành mã gốc để script hiện câu.
- Move đầu (đã sửa, đo 2026-10-18, `e2ek1a2`): trước sửa client báo (160,5; 160,5), cổng kéo về
  (165,00; 169,00), `net.log` dòng `gửi Move x_cm=16050 z_cm=16050`, `nhận Position 16500 16900`.
  Dòng đo tạm trong `place_at` thấy `place_at(-2)` chạy trước `place_at(2)`: -2 là cảnh nền chọn
  nhân vật, còn giữ mặt đất lúc `Display::play` (`frame.cpp:159`) vừa ghi `entry_spot` (cảnh 2,
  165,169); `take_entry` lấy chỗ vào ở đó rồi bỏ đi vì `stand_for` thấy cảnh khác; `place_at(2)`
  sau đó hết chỗ vào nên đặt nhân vật ở ô giữa lưới (160,5; 160,5 m). Sửa: `take_entry_for(scene_id)`
  chỉ lấy khi chỗ vào đúng cảnh đang đặt (`play.cpp:96`, `state.hpp:164`). Sau sửa cùng tài
  khoản: `nhận SceneEnter 16500 17299`, `gửi Move x_cm=16500 z_cm=17306`, `walk +0,+4` báo "kéo về
  0 lần".

## Làm (kế hoạch, theo thứ tự)

1. Host chạy được ở `Phase::kLogin`: chuột, phím, `type` vào ô nhập, nhịp khung. Cửa sổ vẫn đi
   panel C++ cho tới khi bảng so chọn script.
2. Cài 66 hàm ở trên theo mã máy (địa chỉ trong comment), tái dùng dữ liệu `panel/servers`,
   `role_cast`, `create_role` (đã có địa chỉ), nhận danh sách nhân vật từ `CharacterList` của G1-M.
3. Mỗi cửa sổ một bản script và một bảng so bốn tiêu chí (HO-SO mục 2: đúng gốc, đủ, hiệu năng
   Release, chất lượng mã) ghi vào phiếu này, có số đo, ảnh cạnh nhau và danh sách "Khác gốc" của
   từng bản. Hoà thì giữ bản đang chạy; chỉ xoá panel khi bảng chứng minh script tốt hơn. Thứ tự:
   `scene_trans`, `softkey`, `select_role`, `logon`, `select_server`, `create_role`.
4. Ô nhập theo NGHI-NGO 40 (e)(f)(h)(i)(j) bằng widget gốc: bỏ giới hạn ASCII, có IME, chọn, dán,
   cuộn nếu bằng chứng gốc có; ngược lại ghi lý do giữ.
5. Sửa Move đầu ở nguyên nhân gốc (xem trên), không nới cổng gate.
6. E2E `TOOLS/run/e2e/g1.script`, không dùng `THIENLONG_ACCOUNT`: `type` tài khoản và mật khẩu,
   `click` đăng nhập, chọn máy chủ, tạo nhân vật, xoá, tạo lại, vào game, `walk`, `quit`.
   `click` cần địa chỉ con trỏ theo tên điều khiển con (`Hub::box`), chưa kiểm cho điều khiển con.

## Bảng so SceneTrans (panel C++ với `SceneTrans.lua` gốc, đo 2026-10-18, Release)

Cách chạy: cùng exe, cùng kịch bản `TOOLS/run/e2e/g1-scenetrans.script` (ba sự kiện của gốc qua
`event`, chụp từng bước), một lượt không biến, một lượt `THIENLONG_UI_SCRIPT=SceneTrans`.

| Tiêu chí | Panel C++ (đã gỡ) | Script gốc (giữ) |
|---|---|---|
| 1 Đúng gốc: hình | Cùng layout `SceneTrans.layout.xml`. Băng chữ 260 x 70 (18 200 điểm): lệch 51 điểm ở bước tên cảnh, 64 ở bước phần trăm so với script; ẩn so hiện trong cùng bản lệch 14 829. Ảnh: `build/e2e/G1/trans-cpp/shots`, `trans-script/shots`, cùng chữ "前往大理" rồi "前往大理[42]". | Như cột trái. |
| 1 Đúng gốc: khác gốc | (a) thiếu nhánh UI_COMMAND 89187003 (chờ vào biệt dã: chữ `JYGZ_160809_265`, khoá phím tắt, tự đóng sau 10 s); (b) chữ ghép trong C++ thay vì trong script. | Không có (a), (b). Còn chung hai bản: bảng ở lại tối thiểu 900 ms (`note_loading`), SceneTransB chưa làm. Thêm: mẫu "前往%s0" không qua `find_literal` như panel (bảng chuỗi hiện là phép đồng nhất, `ui_strings.lang.tsv:755`). |
| 2 Đủ | PLAYER_LEAVE_WORLD, ON_SCENE_TRANSING, SCENE_TRANSED. | Ba sự kiện đó cộng UI_COMMAND 89187003 mở và đóng, hẹn giờ 10 s (`SetTimer`), `DataPool:SetCanUseHotKey`. Nhánh biệt dã chưa chạy thật: máy chủ ta không phát lệnh. |
| 3 Hiệu năng | Mở HUD (`Hud::open` trừ lượt vẽ xong, `stdout.txt`, offline, 7 lượt): trung vị 18,9 ms, khoảng 18,6 đến 22,0. Dựng UI mỗi khung khi bảng hiện: 0,1 ms. | Trung vị 18,8 ms, khoảng 18,1 đến 20,0. Dựng UI mỗi khung: 0,1 ms. Phần đóng vào ngân sách nạp 450 ms: không đo được khác biệt. |
| 4 Chất lượng mã | 97 dòng (`scene_trans.cpp` 55, `.hpp` 42) cộng chỗ nối trong `hud.cpp`; chữ "前往" lặp lại trong C++. | 0 dòng riêng; script gốc 60 dòng, không sửa. `hud.cpp` còn dòng sự kiện chung (ba sự kiện qua `dispatch`) dùng lại cho mọi cửa sổ. |

Quyết định: script thắng ở tiêu chí 1 và 4, ngang ở 3, không kém ở 2. Panel gỡ, `kScripted` có
`SceneTrans`. Lệnh đo mở HUD, bảy lượt mỗi bản (bản script đặt `THIENLONG_UI_SCRIPT=SceneTrans`):
`py -X utf8 TOOLS/run/e2e_client.py TOOLS/run/e2e/g0-offline.script --out build/e2e/G1/perf-<bản>-<i>`,
rồi lấy hai mốc `GPU: lượt vẽ và pipeline xong` và `HUD: Hud::open xong` ở `stdout.txt`, trừ nhau.

Chưa kiểm:
- UI_COMMAND 89187003 thật (không có máy chủ phát).
- Đường thật `note_loading` → `push_trans` → `dispatch` khi `view.loading` đổi cảnh qua cổng: E2E
  chỉ chèn sự kiện bằng lệnh `event`. Mã đã đổi ở `hud.cpp` (`note_loading`), nên đáng một lượt E2E
  khi có kịch bản đổi cảnh (G4). Lần vào game đầu từ bảng chọn không hiện bảng, khớp gốc
  (`face.cpp:466-478`, 6a kiểm chéo bằng tài khoản `e2ekx2`).
- Ảnh client gốc cạnh bản ta (client gốc không chạy tự động được, HO-SO mục 3).
- Số hiệu năng 7 lượt do một phiên đo; 6a chưa đo lại.

Chữ "前往<tên cảnh>": script ghép trong Lua (`SceneTrans.lua:33,38`) nên `find_literal` chỉ khớp
nguyên văn, hai khoá mẫu `=前往%s0`, `=前往%s0[%s1]` không bao giờ trúng và đã bỏ khỏi
`assets/i18n/{en,vi,zh}.tsv` (bản panel từng dùng chúng; git giữ bản dịch "Đến %s0"). Muốn dịch
tiếng Việt thì khoá theo từng tên cảnh ("前往大理" → "Đến Đại Lý"); hiện bảng chữ là phép đồng nhất
nên chưa thấy lệch.

## Host chạy ở màn đăng nhập (G1-K (2), đo 2026-10-18)

`Hud::step_login` đưa sự kiện của game và nhịp hẹn giờ cho host ở `Phase::kLogin`; `fill_panels` vẽ cửa sổ
của host sau bảng đăng nhập; chuột (nhấn, nhả, di chuột) tới host ở cả hai thủ tục (trước đây chỉ `kPlay`).
Ô nhập, phím và IME của host chưa có: chờ cửa sổ có ô nhập (LogOn, CreateRole) chạy bằng script.

Lượt chẩn đoán đầu cho "đạt" mà cửa sổ không hiện: báo cáo E2E chỉ phán các bước chạy xong, không phán
ảnh. Nhìn ảnh thấy bàn phím không hiện vì kịch bản đang ở bước chọn máy chủ và bảng đăng nhập đóng bàn phím
mỗi khung ngoài bước nhập tài khoản (đúng luật gốc: CloseWindow khi bảng đóng). Sửa kịch bản đi qua chọn
máy chủ bằng `click`, không sửa mã.

## Bảng so SoftKeyBoard (panel C++ với `SoftKeyBoard.lua` gốc, đo 2026-10-18, Release)

Cách chạy: cùng kịch bản `TOOLS/run/e2e/g1-softkey.script` (qua chọn máy chủ, bấm `LogOn_Keyboard` mở, bấm một
phím, bấm lại đóng, rồi sự kiện `OPEN_WINDOW`). Bản C++: exe trước khi chốt, không biến; bản script: cùng exe với
`THIENLONG_UI_SCRIPT=SoftKeyBoard`. Ảnh: `build/e2e/G1/softkey-cpp/shots`, `softkey-script/shots`; bản chốt:
`softkey-final/shots`.

| Tiêu chí | Panel C++ (phần mở/đóng đã gỡ) | Script gốc (giữ) |
|---|---|---|
| 1 Đúng gốc: hình | Cùng layout, khung 484 x 190 cùng chỗ trên màn; mặt phím xoay ngẫu nhiên mỗi lần mở ở cả hai (gốc dùng `rand()`), nên ảnh hai lượt không so từng điểm được. Gõ một phím: ký tự vào ô đang nhắm của bảng tài khoản (`Logon::aim`) ở cả hai; ảnh `soft-typed` là ô mật khẩu (dấu `*`) vì kịch bản đã sang ô đó. | Như cột trái. |
| 1 Đúng gốc: khác gốc | (a) chỉ mở bằng nút của bảng tài khoản, không nhận `OPEN_WINDOW`, `CLOSE_WINDOW`, `TOGGLE_WINDOW` của game (ảnh `soft-3`: bản C++ không mở khi nhận `OPEN_WINDOW`); (b) nút đóng của bảng do C++ đóng, layout nối `this:Hide()`. | Không có (a), (b). Còn chung hai bản: phím ăn ngay lúc nhấn, chưa kéo cửa sổ bằng `TLBB_DragTitle`, nút trợ giúp không làm gì, `xorshift32` thay `rand()` (NGHI-NGO 40 h). Thêm: `SET_SOFTKEY_AIM` ghi thuộc tính `AimEditBox` mà ký tự vẫn vào ô đang nhắm của bảng C++ (`Logon::aim`) (đường đúng là ô nhập của host, chờ LogOn chạy script). |
| 2 Đủ | mở bằng nút, đóng bằng nút đóng. | `OPEN_WINDOW`, `CLOSE_WINDOW`, `TOGGLE_WINDOW`, nút đóng của layout, `SET_SOFTKEY_AIM` (ghi, chưa dẫn đường). |
| 3 Hiệu năng | Mở HUD (`Hud::open` trừ lượt vẽ xong, offline, 15 cặp xen kẽ; máy có việc của phiên khác nên nhiễu): trung vị 41,4 ms (18,9 đến 273,2). Dựng UI mỗi khung khi bàn phím mở: 0,1 ms. | Trung vị 46,5 ms (17,9 đến 389,7); chênh từng cặp (script trừ C++) trung vị −1,2 ms. Dựng UI mỗi khung khi mở: 0,1 ms. Không đo được khác biệt. |
| 4 Chất lượng mã | `toggle_soft_keys`, `press_soft_keys`, hằng nút đóng: 10 dòng trong `softkey.cpp`, hai test (19 dòng). | `SoftKeyBoard.lua` gốc 44 dòng không sửa. Lúc này C++ nhiều hơn: chỗ nối trong `hud.cpp` 31 dòng (`step_login`, `sync_soft_keys`, `press_keys`, `close_keys`, `send_window_event`) và test mới 7 dòng; chỗ nối thu lại còn `sync_soft_keys` khi LogOn chạy script (LogOn.lua gọi `ToggleWindow`, `CloseWindow` thẳng). |

Quyết định: script thắng tiêu chí 1 và 2, ngang 3, thua tạm 4 (mã C++ cộng 21 dòng: 31 thêm, 10 bớt; trả khi LogOn chạy script).
Theo thứ tự tiêu chí: giữ script. `kScripted` có `SoftKeyBoard`; `panel/softkey` bỏ `press_soft_keys`, đổi
`toggle_soft_keys` thành `open_soft_keys` (cờ mở theo cờ hiện của cửa sổ); phần mặt phím (lớp widget SoftKey
của `CEGUIFalagard.dll`, gốc cũng là C++) giữ ở C++. Test `toggle_opens_then_closes` và `close_button_closes` thay
bằng `open_then_close`: hành vi mà chúng kiểm (nút đóng gọi `this:Hide()`) nay là của script và chứng minh bằng ảnh
`soft-2`; không nới kỳ vọng nào còn lại.

## Kịch bản E2E tái lập được (yêu cầu f7, 2026-10-18)

`e2e_client.py` có chỉ thị `#! account fresh [<tiền tố>]`: mỗi lượt một tài khoản mới (tiền tố, mốc giờ viết hệ 36,
hai ký tự ngẫu nhiên; thử hai lần liên tiếp ra hai tên khác), luôn có `CreateCharacter`; `#! account <tên>` còn
cho kịch bản cố ý dùng tài khoản có sẵn; không khai thì không đăng nhập tự động. `{account}` thay được trong
dòng `#! sidecar` (tiền tố tài khoản của bot). `g0.script`, `g0-talk.script`, `g1-scenetrans.script` chuyển sang `fresh`.
Đã chạy `g0.script` và `g0-talk.script` trên cụm v8 (đo 2026-10-18, exe dựng từ cây, `--client`): cả hai ĐẠT; `g0.script` dùng
bot ở `dev/server/bin/thienlong_bot.exe` (đã cài, v8). `g1-scenetrans.script` chưa chạy lại trên cụm v8.

## Nút duyệt thú cưỡi và layout MissionTrack (f7, 1e; 2026-10-18)

- Cụm nút "Thú trước", "Thú sau" và dòng "Chưa cưỡi 0/N" là công cụ dev (8bfa3cb6); client gốc không có nên chỉ vẽ và
  nhận bấm khi client mở với `--mount`. Cờ `Display::State::browses_rides` chốt lúc khởi động từ `DisplayDesc::ride_id`
  (không suy từ `ride_id` hiện tại vì nó đổi khi bấm). Không xoá mã duyệt thú. Kiểm: `g0.script` không `--mount` thì
  ảnh `g0-vao` không còn ba dòng đó; `--mount 0` thì hiện đủ ("Thú trước", "Thú sau", "0 1/353": 353 là tổng thú trong bảng CharMount lúc đo; hổ dưới nhân vật).
  Chưa kiểm: bấm nút (kịch bản chưa có bước chuột, và không chiếm chuột người dùng); đường bấm không đổi.
- `kLayouts` thêm `MissionTrack/MissionTrack.layout.xml` (1e nhờ): trước đó `THIENLONG_UI_SCRIPT=MissionTrack` mở cửa sổ
  thì báo "không nạp được layout MissionTrack"; nay layout nạp được và lỗi kế tiếp là native `GetPlayerMission_InUse`
  còn thiếu (họ DataPool nhiệm vụ của 1e).

## Không làm (không có bằng chứng gốc hoặc ngoài loại máy chủ này)

- Agreement, FangChenMi*, LoginTimer, Pswprotect, SafeCenter_*: máy chủ của ta không có kết quả
  `LCRetLogin` `0x15`, `0x17`, `0x18` hay mật bảo; thêm khi G1-M thêm kết quả tương ứng.
- Xoá trễ nhân vật (D1 của G1-M), `GameProduceLogin:*` của WeGame và thẻ QR ngoài trả giá trị
  "không phải WeGame" như gốc.
- Test logic mới. Bằng chứng là E2E, ảnh và bảng so.

## Đạt khi

`g1.script` thoát 0 từ tài khoản mới; ảnh từng màn so được với layout gốc; `net.log` có gửi
`SignIn`, `CreateCharacter`, `DeleteCharacter`, `EnterGame`, `Move` và nhận `CharacterList`; Move
đầu khớp chỗ máy chủ gửi; log kiểm của zone khớp từng bước; bảng so sáu cửa sổ có số đo.
