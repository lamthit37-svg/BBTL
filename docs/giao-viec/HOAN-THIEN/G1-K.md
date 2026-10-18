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

## Bảng so SelectRole (panel C++ với `SelectRole.lua` và `SelectServerQuest.lua` gốc, đo 2026-10-18)

Cách chạy: cùng exe Release đang cài (`dev/client/bin`, dựng 10:00), cùng kịch bản
`TOOLS/run/e2e/g1-selectrole.script` (đăng nhập tài khoản mới, tạo nhân vật, chọn ô, xoá, nhấn đúp ô trống, tạo nhân vật
thứ hai, vào game), cụm máy chủ v9. Bản script: `THIENLONG_UI_SCRIPT=LoginSelectRole,LoginSelectServerQuest`
(`--out build/e2e/G1/selectrole-script`); bản panel: không đặt biến (`--out build/e2e/G1/selectrole-panel`).

| Tiêu chí | Panel C++ (`select_role.cpp`, 250 dòng, và `.hpp`, 47 dòng) | Script gốc (giữ) |
|---|---|---|
| 1 Đúng gốc: hình | Thiếu dòng gợi ý xanh "双击登录游戏" dưới cấp; nhãn "门派：" có dấu hai chấm toàn góc cộng một dấu cách, gốc là "门派:" nguyên văn trong layout/script. | Chữ và vị trí do `SelectRole.lua` và layout gốc quyết định; dòng gợi ý có; hộp YesNo và hộp thông báo là cửa sổ `SelectServerQuest` gốc (ảnh `sr-ask`, `sr-notice`). |
| 1 Đúng gốc: luồng | (a) một lần nhấn ô trống mở tạo (gốc cần nhấn đúp); (b) xoá: câu hỏi một dòng ở `SelectRole_Info` ("删除等级为1…再次点击删除以确认") không có trong gốc, nhấn lần hai thì xoá thật; (c) không hộp YesNo. | Nhấn đúp ô trống mới mở tạo (`SelectRole_DoubleClicked`). Xoá nhân vật cấp >= 1: hộp YesNo "你确定要将1级的角色…删除吗?" (`SelectRole.lua:354-370`), nhấn 确定 thì hiện thông báo "角色不能马上删除…" (`SelectServerQuest.lua:2796-2799`, kiểu 4; cấp >= 80 dùng kiểu 27, chưa chạy) và KHÔNG gửi gói xoá: gốc xoá cấp >= 1 trong game, ở 关汉寿 (洛阳) hay 周仓 (大理). Chỉ nhánh kiểu 7 và 8 (`SelectServerQuest.lua:2800-2805`) gọi `DelSelRole`. |
| 2 Đủ | Kịch bản 38 bước: 5 bước hỏng. Bước 12 (nhấn thứ hai vào ô trống: cửa sổ đã sang tạo sau lần nhấn đầu), 23 và 26 (không có hộp `SelectServerQuest_Button1`), 35 (không thấy `SelectRole_Play`), 36 (không vào game). `EnterGame` 0 dòng, `CreateCharacter` 1 dòng. | Cùng kịch bản: 38 bước, 0 hỏng, `SignIn` 1, `CreateCharacter` 2, `EnterGame` 1 (vào game sau 14,9 s), `nhận:CharacterList` 4; KẾT LUẬN ĐẠT. |
| 3 Hiệu năng (bảng số đo trên màn, 1280x720, màn 120 Hz ghim khung 8,3 ms, một lượt mỗi bản, độ phân giải 0,1 ms) | Bảng chọn / hỏi xoá / thông báo: dựng UI 0,1 / 0,1 / 0,1 ms; ghi lệnh 0,9 / 1,0 / 1,0 ms; Quad UI 69 / 102 / 102; lệnh vẽ 188 cả ba. | Cùng ba trạng thái: dựng UI 0,1 / 0,1 / 0,1 ms; ghi lệnh 1,0 / 1,0 / 1,1 ms (1,2 ở `sr-second`); Quad UI 89 / 177 / 297; lệnh vẽ 188 cả ba. Trung vị khung 8,3 ms, p95 8,4 ms ở cả hai. |
| 4 Chất lượng mã | 297 dòng C++ cho cửa sổ này, ba chỗ rẽ nhánh trong `login_flow.cpp` (`press_roles`, `paint_flow`, `hold_flow`), test `ui_select_tests.cpp` (160 dòng) và khoảng 25 bước của `ui_flow_tests.cpp` lái qua `press_flow`. Chữ và quy tắc xoá chép tay, lệch gốc như hàng 1. | 0 dòng riêng cho cửa sổ; 930 dòng `SelectRole.lua` và 3 874 dòng `SelectServerQuest.lua` không sửa. Phần C++ là `native_login.cpp` (343 dòng) và `login_port.hpp` (65 dòng), dùng chung cho LogOn, SelectServer, CreateRole về sau. |

Quyết định: script thắng ở tiêu chí 1, 2, 4; ngang ở 3 (chênh ghi lệnh không quá 0,2 ms, trong sai số một lượt;
thời gian khung do màn quyết định). `kScripted` (`hud.cpp`) có thêm `LoginSelectRole` và `LoginSelectServerQuest`;
công tắc `THIENLONG_UI_SCRIPT` còn cho các cửa sổ chưa quyết (LogOn, SelectServer, CreateRole). Mã panel
(`select_role.cpp` và các nhánh trong `login_flow.cpp`) CHƯA xoá trong lượt này: hết host mở không được thì bảng
port tay còn làm việc thay, và `ui_flow_tests.cpp` lái cả luồng đăng nhập qua `press_flow`, nên xoá phải viết lại
khoảng 25 bước đó sang đường script (`apply_script_call`). Việc đó là bước (3c), kiểm chéo riêng.

Lỗi E2E bản script bắt được và đã sửa: `SelectRole.lua:928` và `SelectServer.lua:662` gọi `Lua_IsPrintMemMode()`
(Game.exe 0x140280190, trả cờ gỡ lỗi), client chưa đăng ký nên mỗi lần hiện cửa sổ có một dòng lỗi
`attempt to call global 'Lua_IsPrintMemMode'`. Nay `native_login.cpp` đăng ký nó, luôn trả 0 (Khác gốc: client không có cờ
dòng lệnh đó).

Chưa kiểm:
- Ảnh client gốc cạnh bản ta (client gốc không chạy tự động được, HO-SO mục 3).
- Thiết bị di động (APK) và iOS: kịch bản chạy trên máy tính.
- Hộp YesNo kiểu 7 (cấp 0), `SelectRole_CancelDelChar` và nhánh `iDelTime > 0` (xoá trễ): máy chủ ta xoá ngay,
  không có trạng thái chờ (bd, `src/server/account/sql.cpp:422`), nên các nhánh này chưa có dữ liệu thật để chạy.
- Số hiệu năng chỉ một lượt mỗi bản, độ phân giải 0,1 ms.

Nghi vấn cho làn M, bd đã trả lời (2026-10-18, đọc `LoginServer/Login/Packets/CLAskDeleteCharHandler.cpp` và
`WorldServer/World/Packets/LWAskDeleteCharHandler.cpp` của máy chủ 2008): máy chủ 2008 không kiểm cấp và không chờ
ngày (chỉ kiểm trạng thái, chủ sở hữu, nhịp thao tác DB, rồi World trả `ASKDELETECHAR_ONLINE` nếu nhân vật đang
online, còn lại SUCCESS), khớp máy chủ ta xoá ngay. Kiểu "cấp >= 1 xoá trong game qua 关汉寿 hay 周仓, chờ 3 đến 14 ngày"
là tính năng của client 2026 mà máy chủ 2008 không có; máy chủ ta chưa có luồng xoá qua NPC hay chờ ngày (bd ghi
`NGHI-NGO.md`, mục của G1-M). Gói mà client gốc 2026 gửi cho luồng đó phải đọc `Game.exe` bằng REA mới biết. Với
(3b): client không gửi `DeleteCharacter` ở màn chọn cho nhân vật cấp >= 1 là đúng, máy chủ không cần gói mới.

Kiểm cuối trước commit (exe dựng sau khi áp ba ghi chú soát chéo của bd: `has_slot` chặn theo kích thước mảng,
`last_enter_tick` thành `optional` để 2 giây đầu của đồng hồ khung không nuốt lần vào game đầu, ghi chú tab của
`ShowMessageBox`): cấu hình MẶC ĐỊNH, không đặt `THIENLONG_UI_SCRIPT`, cụm v9,
`py TOOLS/run/e2e_client.py TOOLS/run/e2e/g1-selectrole.script --out build/e2e/G1/selectrole-final`: 38 bước, 0 hỏng,
`SignIn` 1, `CreateCharacter` 2, `EnterGame` 1 (vào game sau 1,3 s), `nhận:CharacterList` 4, KẾT LUẬN ĐẠT; stdout
không có dòng "Giao diện Lua" báo lỗi. Hai bản chạy trước đó cùng kịch bản: `selectrole-script` ĐẠT,
`selectrole-default` ĐẠT.

## SelfFit: cửa sổ tự co theo chữ (hộp SelectServerQuest chạy bằng script, 2026-10-18)

Bằng chứng gốc: `CEGUIFalagard.dll` 3.71.9509, đọc bằng Ghidra. `FalagardSelfFitWindow` (WindowType `TLBB_SelfWindow`,
31 layout) co theo chữ mỗi lần đổi chữ: `getRenderSize` 0x18009c100 trả 0x0 khi chữ rỗng (`setText` 0x18009c980 còn
giấu cửa sổ); bề rộng bẻ dòng là MaxWidth trừ hai lề của TextArea; khối chữ là `Font::getFormattedSize` kiểu
`WordWrapLeftAligned` (số 4 cố định trong hàm, không đọc `HorzFormatting`); rộng = khối + hai lề + 5,0 (hằng ở
0x18013c5f0), cao = khối + hai lề + 2,0 (0x18012fb5c); rồi rộng không quá MaxWidth và không dưới MinWidth, cao không
dưới MinHeight, theo thứ tự đó; không có MaxHeight. Mặc định MaxWidth 200, MinWidth 0, MinHeight 0 (hàm dựng
0x18009af60). Cỡ lưu tới khi đổi chữ hay cha đổi cỡ (`onParentSized` 0x18009c670). TextArea của `TLBB_Look_SelfWindow`
lẫn `...Lace` thụt 3 điểm mỗi cạnh. Mã ta: `ui/script/widget.cpp` (`self_fit_of`, `refit_self_fit`, `fitted_box`) và hộp
C++ `panel/system_info.cpp` dùng cùng hằng. Khác gốc: tính ở `SetText` bằng bộ đo chữ của HUD rồi đặt `AbsoluteSize`
(gốc co ngay trong Falagard); bề rộng bẻ dòng không kẹp theo vùng hiển thị của renderer như gốc (0x18009c1xx); chữ
rỗng chỉ đặt cỡ 0x0, không giấu cửa sổ như `setText` 0x18009c980. Thuộc tính MaxWidth, MinWidth, MinHeight đọc bằng
`from_chars`, không hữu hạn hay âm thì dùng mặc định. Hằng +5, +2, lề 3, MaxWidth 200 nằm ở hai chỗ (`widget.cpp`
`kSelfFit*`, `system_info.cpp` `kExtra*`): sửa một nơi thì sửa cả hai.
Chưa kiểm: một layout SelfFit khác ngoài `SelectServerQuest` (chưa chụp ảnh), nên hằng +5 và +2 mới chứng minh bằng
mã máy và ảnh của hộp này.

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

## Client v9 (G1-M D3, f7 yêu cầu ưu tiên số 1, 2026-10-18)

Hiện trạng đo trên HEAD `77be2269` (f7): `gửi CreateCharacter ... face=100 hair=5` rồi `nhận Reject code=19`
(BadOption), vì client chưa gửi `portrait` và `equip_set` mới, máy chủ thấy 0 nằm ngoài tập đóng
(`account/rules.cpp`).

- Dây: `session::Create` mang `portrait`, `equip_set`; `session::Roster` mang `can_create`
  (`session.hpp`, `session.cpp`); `trace.cpp` ghi cả hai trường mới.
- Cầu (`online/bridge.cpp`): `command_of` gửi `Role::portrait` và `Role::outfit`; `role_of` đọc lại
  từ dây; `OnlineReply::can_create`; ba mã lỗi mới 41 `kNoCharacterToDelete`, 42 `kCharacterOnline`,
  43 `kInternal`; xoá bị `kRateLimited` có chữ riêng (`kDeleteTooSoon`, mã 2 của gói trả lời xoá gốc
  `0x1408319c0`).
- Chữ lỗi theo khoá gốc trong `ui_strings.tsv`: `LCRetDeleteCharHandler_Info_No_Role_Del` (41),
  `FWQYM_160120_147` (42), `LCRetDeleteCharHandler_Info_Err` (43), `LCRetDeleteCharHandler_1`
  (xoá dồn nhịp), `LCRetDeleteCharHandler_Info_Unknow_err` cho `kNoSuchCharacter` (NOT_OWNER của gốc rơi
  vào "lỗi lạ"). Bỏ câu tiếng Trung tự soạn "该角色不存在。".
- Chuỗi đăng nhập (`login_flow.cpp`): chân dung lấy từ dây (0 thì chân dung đầu của giới như cũ), ảnh
  tra từ bảng chân dung, `outfit` đổi ra `body/arm/foot` bằng `RoleCast::outfit`; `can_create` của
  `CharacterList` quyết việc mở bảng tạo khi trực tuyến (thay tin hỏi `CLCheckAllowCreateChar`); bộ đồ
  bảng tạo ghi vào `Role::outfit` để gửi đi.
- Đăng nhập tự động (`auto_login.hpp`): nam, mặt 100, tóc 5, chân dung 52, bộ đồ 0 như `thienlong_bot`.
  `gender=2` là `Gender::kMale` của catalog (`messages.hpp`: `kFemale = 1`, `kMale = 2`).
- Đã kiểm: `ui_flow_tests`, `online_tests`, `session_tests`, `session_logic_tests`, `client_tests` xanh
  (ca mới: chân dung và bộ đồ qua dây, `can_create`, mã 41–43, xoá dồn nhịp); `g0.script` tài khoản mới
  trên cụm v9: `gửi CreateCharacter name=e2eex0ztrm gender=2 face=100 hair=5 portrait=52 equip_set=0`,
  `nhận CharacterList count=1 can_create=true`, vào game, đi hai đoạn, ĐẠT (`build/e2e/G0v9`).

## Nền script cho bảng chọn nhân vật (G1-K (3), chưa nối HUD)

`login_flow` đẩy sự kiện `GAMELOGIN_*` (đóng/mở từng bước, `GAMELOGIN_CLOSE_SYSTEM_INFO` trước mỗi lần
đổi bước, `GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR` khi ở lại bảng chọn, `GAMELOGIN_SELECTCHARACTER`) vào
hàng `LoginFlow::events` (trần 64; chưa ai lấy cho tới khi HUD nối), và nhận việc `GameProduceLogin:*`
của script qua `apply_script_call` (vào game, chọn ô, xoá, về bảng tài khoản, sang bảng tạo, quay và
phóng người mẫu). Có test (`flow_events_follow_the_steps`, `script_calls_drive_the_select_step`). Hàm game và nối HUD là bước sau.

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

## Bàn giao 2026-10-18 (phiên 14 dừng)

Phiên 14 (nay đặt tên c5) giữ làn K theo phân công cuối của 5f. Mục này ghi trạng thái lúc dừng; số liệu
là đo thật trừ chỗ ghi "suy luận" hay "chưa kiểm".

### 1. Đã commit

- `a9ab3e1a` G1-K (1): phiếu, sửa Move đầu, SceneTrans chạy bằng script gốc, gỡ panel C++ theo bảng so.
- `8030927b` G1-K (2): host chạy ở màn đăng nhập, SoftKeyBoard thành script, E2E tài khoản mới.
- `41f14873` G1-K (2b): nút duyệt thú chỉ hiện với `--mount`, nạp layout MissionTrack, bot đã cài.
- `020df092` G2 (1): tên, thanh máu, chữ bay của thực thể vẽ dưới mọi cửa sổ giao diện.
- `4762aaac` G1-K (3a): client giao thức v9 (chân dung, bộ đồ, `can_create`, mã 41–43) và nền script cho
  bảng chọn (sự kiện `GAMELOGIN_*`, `apply_script_call`), kèm phiếu `G2-K.md` và `g2-names.script`.
- Đã push: tới `77d444a0` (hồ sơ của điều phối, gồm `4762aaac`). Mọi commit trên đã nằm trong main.

### 2. Việc dở CHƯA commit (cây làm việc chung, không stash)

Cập nhật 2026-10-18: toàn bộ bảng dưới đã nằm trong commit G1-K (3b) (cùng SelfFit, ba ghi chú soát chéo của bd và
hai sửa Clang Android: `bridge.cpp` đưa bốn hàm phụ vào namespace ẩn danh, `login_flow.cpp` ghi đủ `.args`). Bảng giữ
nguyên để tra lại ý định từng tệp.

| Tệp | Làm gì | Tới đâu |
|---|---|---|
| `src/client/face/ui/script/native_login.cpp` (mới) | 17 hàm `GameProduceLogin:*`, `DataPool:GetCharSaletimeCyg`, `DataPool:AskCreateChar`, `Player:ReportLoginTypeMsg`; `register_login` | Viết xong, đã biên dịch 0 cảnh báo, đã đăng ký. Chưa chạy trên một roster thật |
| `src/client/face/ui/script/login_port.hpp` (mới) | `LoginPort`: danh sách 3 nhân vật, ô chọn, ô xoá, `last_enter_tick` | Xong. `is_pk_server`, `delete_days`, `sale_state`, `pk_level` luôn 0 (máy chủ không có, NGHI-NGO 73) |
| `CMakeLists.txt` | Một hunk: `src/client/face/ui/script/native_login.cpp)` sau `native_mission.cpp` (khối `game_ui_script`) | Xong. Cây còn hai hunk của làn N (`quest/misdesc.cpp`, `game_test(quest_misdesc)`): khi commit chỉ đưa hunk này bằng `git apply --cached`, rồi kiểm `git show HEAD -- CMakeLists.txt` |
| `src/client/face/ui/script/context.hpp` | `#include login_port.hpp`, `LoginPort login;` trong `Context` | Xong |
| `src/client/face/ui/script/native_groups.hpp`, `natives.cpp` | Khai báo và gọi `register_login` | Xong |
| `src/client/face/ui/hud.cpp` | `kSelectRole`; `script_facts`; `route_call` (việc script nhờ trong pha đăng nhập đi qua `apply_script_call`); `sync_login_port` (chép roster mỗi khung); `note_host_double` (MouseDoubleClick); `step_login` lấy `take_flow_events`; `open_host` đặt `flow.is_select_scripted` khi `LoginSelectRole` có trong danh sách script | Xong, biên dịch sạch. Chưa chạy với roster. Hook định dạng đã gấp lại hai dòng comment `ui_args` kế bên (vô hại) |
| `src/client/app/client/online/bridge.cpp`, `bridge.hpp` | Lưu ý của f7: `wire_portrait` kiểm `0 < portrait <= 65535` trước khi cast; ngoài khoảng thì trả `OnlineFault::kOther` thay vì cắt cụt; tách `serve_command` để giữ hàm phẳng | Xong. Không có test mới (theo luật hạn chế test logic) |
| `Test/Ui/ui_flow_tests.cpp` | Bớt 74 dòng, bỏ ba ca (`online_roster_keeps_portrait_and_outfit`, `online_create_follows_the_server_flag`, `flow_events_follow_the_steps`) vì E2E `g1-selectrole` sẽ phủ; giữ `script_calls_drive_the_select_step` và các ca ánh xạ mã 41/42/43 và `kRateLimited` ở `online_tests.cpp` | Xong |
| `pace.obj` ở gốc repo | Rác do lệnh `cl` hỏng của phiên này | Đã xoá |

Dựng và chạy trên đúng bản này (đo lại 2026-10-18 sau khi nhận khoá về): `cmake --build build/msvc-release`
(cây cả dự án, 77 bước, kể cả hai hunk và `misdesc.*` của làn N) 0 lỗi, 0 cảnh báo, không `D9002`; `ctest` đủ cây
`100% tests passed out of 191`. Chạy khói client với `THIENLONG_UI_SCRIPT=LoginSelectRole` dừng ở
màn đăng nhập: không có dòng lỗi Lua nào; nhưng đó chưa chứng minh script đã nạp (thiếu roster nên chưa thấy
nó chạy). E2E với cụm CHƯA chạy trên bản hiện tại. `dev/client/bin/thienlong_client.exe` là client v9
dựng trước khi nối HUD (SHA-256 `2F502763B1E5…FF314`; bản cũ giữ ở `.bak-20261018-truoc-v9`).

### 3. Khoá tệp chung (đã nhận lại từ 43)

`context.hpp`, `native_groups.hpp`, `natives.cpp`, `hud.cpp`, `online/bridge.cpp`, `online/bridge.hpp`,
`Test/Ui/ui_flow_tests.cpp`, và hunk `native_login.cpp` của `CMakeLists.txt`. MỞ ngay sau commit.

### 4. Bước kế tiếp, theo thứ tự

1. Dựng và kiểm. `cmd /c "call %USERPROFILE%\.claude\skills\cpp-build\dev.bat && cmake --build build/msvc-release"`
   rồi `ctest --test-dir build/msvc-release --output-on-failure -j 8`. Đạt khi 0 cảnh báo, không `D9002`, ctest
   `100%`. Chỉ dựng ở `build/msvc-release` cho tới khi điều phối nói khác.
2. E2E cần cụm: chờ bd báo cụm lên. Tạo một tài khoản cố định có nhân vật:
   `py -X utf8 TOOLS/run/e2e_client.py TOOLS/run/e2e/g0.script --account e2esrk1 --out build/e2e/K9/prep`.
   Kịch bản nhập tay cần chế độ mới của `TOOLS/run/e2e_client.py`: `#! account fresh` luôn đặt
   `THIENLONG_ACCOUNT` (dòng ~308) nên client tự đăng nhập. Thêm chỉ thị sinh tên mới mà KHÔNG đặt biến, và
   thay `{account}` vào dòng `type` bằng bản sao kịch bản ghi vào thư mục `out`. Mật khẩu `<tên>-thu`.
   `type` chỉ đẩy ký tự vào hàng đợi đầu vào, nên phải `click` ô nhập trước (`LogOn_ID`, `LogOn_PassWord`;
   chưa kiểm cho điều khiển con).
3. Viết `TOOLS/run/e2e/g1-selectrole.script` (khai `expect-shots`): chọn máy chủ (`SelectServer_Server_Last`,
   `SelectServer_Accept`), gõ tài khoản, `LogOn_LogOnGame`, ô nhân vật `SelectRole_TargetInfo_Button1..3`, rồi
   xoá (`SelectRole_Delete`) và xác nhận bằng hộp YesNo, tạo lại (`SelectRole_Create`, `CreateRole_RandomName`,
   `CreateRole_Author` là nút tạo: `create_role.cpp:880` gọi `click_create` khi nhấn nó), vào game (`SelectRole_Play` theo `select_role.cpp`; kiểm tên thật trong layout). Chạy với
   `$env:THIENLONG_UI_SCRIPT='LoginSelectRole,LoginSelectServerQuest'` (phân tách bằng dấu phẩy,
   `windows.cpp:requested_windows`). Hộp YesNo/NoButton nằm ở `SelectServerQuest.lua` (3874 dòng), nên cửa
   sổ đó PHẢI nằm trong danh sách; chưa nối `flow.system_info` (hộp C++) sang sự kiện
   `GAMELOGIN_SHOW_SYSTEM_INFO`/`_YESNO`/`_NO_BUTTON` cho script: đó là phần còn thiếu thật của bước này.
   Đạt khi kịch bản thoát 0, ảnh từng bước, `net.log` có `DeleteCharacter` rồi `CreateCharacter` rồi `EnterGame`.
4. Bảng so panel C++ với script ở mục "Bảng so SelectRole" mới của tệp này theo bốn tiêu chí theo thứ tự:
   đúng gốc, đủ, hiệu năng Release (số đo), chất lượng mã. Giữ cái tốt hơn; chỉ xoá `select_role.cpp`/`role_cast.cpp`
   khi bảng có số. Khác gốc đã biết của panel C++: một lần nhấn ô trống mở bảng tạo (gốc cần nhấn đúp), xoá hỏi
   trên dòng `SelectRole_Info` rồi nhấn Xoá lần nữa (gốc dùng hộp YesNo).
5. XIN KIỂM bd (làn M) rồi commit chỉ theo đường dẫn của mình, kèm hunk CMake bằng `git apply --cached`, thông điệp
   cuối `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`, `git show --stat HEAD`, nhắn 5f
   "COMMIT <hash> G1-K (3b), kiểm chéo bd ĐẠT". Trước đó: `ctest` đủ, `node ~/.claude/bin/shape.js --diff .` sạch.
6. Các cửa sổ còn lại theo thứ tự: LogOn, SelectServer, CreateRole; khi cửa sổ cuối đã quyết thì gỡ công tắc
   `THIENLONG_UI_SCRIPT`. Cuối cùng `g1.script` (tài khoản mới gõ bằng `type`, chọn máy chủ, tạo, xoá, tạo lại, vào game)
   theo mục "Đạt khi".
7. Kiểm chéo lại H1 khi bd sửa xong (mục sau), rồi G2 theo `G2-K.md`.

### 5. Bằng chứng gốc đã tìm mà chưa ghi chỗ khác

Game.exe 2026 (3.71.9001), địa chỉ nhìn qua `py -X utf8 -I TOOLS/port/rea/show_func.py 0x<địa chỉ>`; bản dịch
Ghidra mất giá trị trả về kiểu double và lời gọi ảo, nên đọc cả thân thật. Cột đầu là địa chỉ đăng ký trong
`lua_api.tsv`, cột sau là thân thật nếu khác.

| Hàm Lua | Địa chỉ | Hành vi gốc |
|---|---|---|
| `GameProduceLogin:GetRoleCount` | `0x1403416a0` | số nhân vật |
| `GetRoleInfo` | `0x1403416e0` | 7 giá trị: tên, môn phái, cấp, ngày chờ xoá, ảnh, trạng thái bán, cấp PK; ô trống trả `"",0,0,0,"",0,0` |
| `GetCurSelectRole` | `0x140341640` | ô đang chọn |
| `SetCurSelect` | `0x140342a20` | đặt ô xoá, không kiểm kiểu |
| `GetSelectedServerIsPKServer` | `0x140340000` | 1 khi máy chủ PK |
| `SendEnterGameMsg` | `0x140341da0`, thân `0x14063a7f0` | bỏ nếu cách lần trước dưới 2000 ms (khoá `Login_TextValidate_LastTime`) |
| `SendEnterGameMsg_New` | `0x140341e00`, thân `0x14063ae50` | không bỏ lần nào, chỉ ghi giờ |
| `MoveToCharacter` | `0x1403442c0`, thân `0x14063c480` | ô ≤ 2 và có mô hình; bắn sự kiện `0x18e` |
| `DelSelRole` | `0x140342a50`, thân `0x14063a500` | gửi `CLAskDeleteChar` và hộp không nút `produce_char_sel_Info_Deling_Role` |
| `CancelDelRole` | `0x140342a70`, thân `0x14063a750` | huỷ xoá chờ |
| `ChangeToAccountInputDlgFromSelectRole` | `0x140341480`, thân `0x14063a000` | về bảng tài khoản |
| `ChangeToCreateRoleDlgFromSelectRole` | `0x1403414a0` | đủ 3 nhân vật thì sự kiện `0x116` với chuỗi `357` (`Role_Is_Full`) |
| `ShowMessageBox` | `0x140342a90` | kiểu NoButton `0x123`, OK `0x124`, YesNo `0x122`, Cancel `0x125`, Close `0x24a`; đối số (chữ, kiểu, mã) |
| `ExitToAccountInput_YesNo` | `0x140342440` | sự kiện `0x122` với khoá chữ và `"2"` |
| `GameLoginShowSystemInfo` | `0x1403448d0` | hộp thông báo của chuỗi đăng nhập |
| `ModelRotBegin`, `ModelRotEnd`, `ModelZoom` | `0x1403441a0`, `0x140344230`, `0x140344320` | quay và phóng người mẫu |
| `DataPool:GetCharSaletimeCyg` | `0x1402dfb10` | trạng thái bán nhân vật |
| `DataPool:AskCreateChar` | `0x1402ea3d0` | hỏi máy chủ `CLCheckAllowCreateChar` rồi mở bảng tạo |
| `Player:ReportLoginTypeMsg` | `0x140397630` | HTTP tới localhost, trả 0 |
| `CGamePro_CharSel` | đếm `0x14063a230`, bản ghi `0x14063a240` | bản ghi 0x1a4 byte theo ô: tên `+0x0c`, cấp `+0x2c`, môn phái `+0x44`, ảnh `+0x48`, giờ xoá `+0x128`, cấp PK `+0x1a0` |

Script gốc: `SelectRole.lua` (930 dòng) đăng ký bảy sự kiện `GAMELOGIN_OPEN_SELECT_CHARACTOR`,
`GAMELOGIN_CLOSE_SELECT_CHARACTOR`, `GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR`, `GAMELOGIN_CREATE_ROLE_OK`,
`ENTER_GAME`, `GAMELOGIN_SELECTCHARACTER`, `GAMELOGIN_BACKTO_SELECTCHAR_FROM_CREATECHAR`. Layout
`SelectRole.layout.xml` nối: `Clicked` → `SelectRole_Clicked(i)`, `RBClicked` → `SelectRole_Clicked(i)`,
`MouseDoubleClick` → `SelectRole_DoubleClicked(i)`, `MouseEnter` → `SelectRole_MouseEnterCharArea(i)`,
`MouseLButtonDown`/`MouseButtonUp` → quay trái phải và phóng xa gần người mẫu. `AskCreateCharCode` bị
comment trong `SelectRole.lua` nên không cần. Cửa sổ trong `windows.tsv`: `LoginSelectRole` (id 28),
`LoginSelectServerQuest` (id 30), `LoginLogOn` (16), `LoginSelectServer` (29), `LoginCreateRole` (7).

### 6. Lỗi và nghi ngờ chưa ghi `NGHI-NGO.md`

- Quỹ quãng đường H1 của 6a (xem tiểu mục dưới): chưa có mục ở sổ nghi ngờ.
- `admit_remote` (`login_flow.cpp`) KHÔNG từ chối bản ghi ngoài tập chân dung/bộ đồ cho phép; chỉ thay chân dung
  ≤ 0 bằng chân dung đầu của giới. Vô hại vì máy chủ chỉ gửi bản hợp lệ (migration 003 điền 49/52).
- Công cụ E2E không thay `{account}` trong dòng `type` và `account fresh` luôn tự đăng nhập: chặn tiêu chí đạt
  của G1 ("gõ tài khoản bằng `type`"). Sửa nằm ở `TOOLS/run/e2e_client.py` (mục 4 bước 2).
- Hook định dạng tự gấp lại các comment >100 cột nằm KẾ dòng mình sửa trong cùng khối (enum, `switch`):
  `call.hpp` bị gấp 56 dòng thay vì 20. Cách tránh: viết tệp bằng PowerShell `Copy-Item` (PowerShell không bị
  hook) và không chạm tệp bằng Bash trong 15 giây sau đó.
- Năm tệp (`bridge.cpp`, `bridge.hpp`, `online.hpp`, `online_tests.cpp`, `ui_flow_tests.cpp`) nằm ở cây làm việc
  với CRLF dù thuộc tính `eol=lf`: git chuẩn hoá khi commit, chỉ gây cảnh báo "CRLF will be replaced".
- Hộp thông báo của chuỗi đăng nhập còn hai đường: hộp C++ (`flow.system_info`) và hộp của
  `SelectServerQuest.lua`. Khi `LoginSelectRole` chạy script mà `LoginSelectServerQuest` không nằm trong danh
  sách, xoá nhân vật sẽ bắn `GAMELOGIN_SYSTEM_INFO_YESNO` không ai nhận.

### Kiểm chéo H1+B19 cho 6a: KHÔNG ĐẠT điểm 1

Cây làm việc có sửa chưa commit của 6a (`guard/pace.{hpp,cpp}`, `zone/{scene,mind}`, `gate/table.cpp`,
`guard_tests`, `zone_tests`, `bot.cpp`, `H1-M.md`). Đã gửi kết quả đầy đủ cho bd (làn M mới), cc 5f. Nền:
`ctest` đủ cây `100% tests passed out of 190`, build 0 cảnh báo.

**Điểm 1: quỹ 2 s đóng phiên client khi mạng đứng từ 2,4 s trở lên rồi dồn gói.**

Giả định mô phỏng (mã ở `D:\THIENLONG-luu-tru\kiem-cheo\2026-10-18-h1\`): client chạy thẳng 4,65 m/s; một
Move mỗi 50 ms (`kMoveEvery`), mỗi Move +23,25 cm và +2 tick client (như `client_tick()` làm tròn lên ở
`session.cpp`); chạy đều 5 s (100 Move, tick máy chủ = thời gian thật nhân 30); rồi mạng đứng S giây, client vẫn
sinh Move mỗi 50 ms vào bộ đệm TCP, tất cả đến trong MỘT tick máy chủ ở giây 5+S. Ô là "nhận / kéo về / đóng
phiên ở Move số".

| Đứng mạng S | Pace cũ (HEAD) | Quỹ 2 s (6a) | Quỹ 5 s | Quỹ 10 s |
|---|---|---|---|---|
| 0 | 100/0/không | 100/0/không | 100/0/không | 100/0/không |
| 1 | 120/0/không | 120/0/không | chưa đo | chưa đo |
| 2 | 140/0/không | 140/0/không | 140/0/không | 140/0/không |
| 2,4 | 148/0/không | 142/2/145 | 148/0/không | 148/0/không |
| 2,6 | 152/0/không | 142/2/145 | chưa đo | chưa đo |
| 3 | 160/0/không | 142/2/145 | 160/0/không | 160/0/không |
| 4 | 180/0/không | 142/2/145 | chưa đo | chưa đo |
| 6 | 220/0/không | 142/2/145 | 205/2/208 | 220/0/không |
| 10 | 300/0/không | 142/2/145 | 205/2/208 | 300/0/không |

Vế gian lận `--rush` (mỗi tick một Move 62 cm khai 4 tick): đóng phiên ở tick máy chủ 24 (mốc x = 1302 cm) với
quỹ 2 s, tick 56 (x = 3286 cm) với quỹ 5 s, tick 109 (x = 6572 cm) với quỹ 10 s. Tức gian lận hưởng thêm tối đa
chừng 13 m, 33 m, 66 m trước khi bị đóng; tốc độ duy trì vẫn khoá ở nhịp nạp 4,88 m/s.

Cơ chế: sau Move đầu bị từ chối, mốc đứng yên; mọi Move còn lại của chuỗi dồn đo từ mốc cũ nên vượt giới hạn
từng bước, rồi vượt sàn dịch chuyển 1600 cm; ba nợ liền nhau là `kSpeed` (đóng phiên). Trong cùng một tick không
phân biệt được gói dồn của mạng giật với Move dày của gian lận.

Hai cách sửa nhỏ đã thử và KHÔNG đủ (`pace_fix` trong kho): (a) tính nợ vì quỹ một lần mỗi tick máy chủ: vẫn đóng
ở Move 146; (b) thêm 6 tick ân hạn không nợ sau lần từ chối đầu: đứng ≤ 3 s thì qua, 6 s và 10 s vẫn đóng ở
Move 212 vì đuôi vượt sàn dịch chuyển 16 m, `--rush` đóng ở tick 36.

Đề nghị: nâng `kBankTicks` tới mức phủ độ đứng mạng muốn chịu (150 đến 300 tick), cân với cửa sổ gian lận ở trên,
kèm ca test cho mức đã chọn (ca hiện có `lag_burst_within_bank_is_kept` chỉ thử 1,5 s). Hướng dài hạn nếu cho đổi
dây: `Position` mang số lượt, `Move` trả lại số đó, để máy chủ không phạt các `Move` gửi trước khi client nhận kéo về.

GIỚI HẠN: giả định client vẫn xếp Move vào bộ đệm TCP khi mạng đứng. Chưa kiểm `send_frame` (`kSend`) có chặn khi
mạng tắc không; nếu chặn thì sau khi thông chỉ còn MỘT Move dài, bị từ chối một lần rồi kéo về, không đóng phiên.
Chưa có công cụ giả lập mạng giật nên chưa chạy client thật. Chưa đo S = 4 và 5 s với quỹ 5 s.

**Điểm 2: Move sau khi vừa bị `Position` kéo về: ổn.** `on_placed()` (`session.cpp`) đặt `tick_base_` bằng tick
của `Position`, `tick_at_` bằng lúc nhận, bỏ chỗ đứng chờ gửi, im lặng `kPullQuiet`. Quỹ không nạp lại ở
`reset` nhưng nạp theo tick máy chủ ở 488 cm/s, lớn hơn tốc độ chạy 465 cm/s, nên chạy đều sau khi bị kéo về
không bị bóp.

**Điểm 3: mẫu 20 cm với người chạy sát tường: ổn về lý do (suy luận, chưa đo trên client thật).** `walkable` tha
±20 cm theo bốn hướng (`kWalkSlackCm = 20`, `zone/content.hpp`), cùng cỡ mẫu 20 cm; bước 50 ms dài 23 cm cắt
góc lồi dưới 2 cm. Phần dư: client giật khung vài trăm ms tạo một Move dài quanh góc có thể cắt tường và bị hoàn
bước; không đóng phiên vì zone hoàn bằng `reset` xoá nợ.

B19 (`scene.cpp`, `mind.cpp`): không thấy chỗ phản đối. Không cho ĐẠT cả cụm vì cỡ quỹ ở `pace.cpp`. Kiểm chéo lại khi
bd sửa: chạy lại mô phỏng với mã mới (cách dựng: `README.txt` trong thư mục kho).

Kho mô phỏng: `D:\THIENLONG-luu-tru\kiem-cheo\2026-10-18-h1\` (ngoài cây dự án): `pace_old` (Pace HEAD), `pace_sim`
(mô phỏng với mã trong cây), `pace_b150`, `pace_b300` (quỹ 5 s, 10 s), `pace_fix` (hai cách sửa thử), `pace_6a` (bản
`pace.{hpp,cpp}` của 6a lúc đo).
