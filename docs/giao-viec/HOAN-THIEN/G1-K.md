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
