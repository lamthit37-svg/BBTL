# Màn tạo nhân vật của client 2026

Đọc từ `Interface/CreateRole/CreateRole.lua` (giải bằng `TOOLS/content/lua_plain.py`),
`CreateRole.layout.xml`, mã máy `Bin64/Game.exe` và `CEGUIFalagard.dll`, và bốn bảng Config. Bản
port: `SRC/ui/panel/role_cast.*` (dữ liệu), `SRC/ui/panel/create_role.*` (script), phần "game" trong
`SRC/ui/panel/login_flow.*`. Địa chỉ là địa chỉ ảo của `Game.exe` (gốc `0x140000000`), tìm bằng
`python -B TOOLS/port/lua_native.py "F:/tl 2026/Bin64/Game.exe" <tên hàm Lua>` rồi tháo bằng
`python -B TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/Game.exe" func <địa chỉ>`.

## 1. Bốn thứ người chơi chọn

Script tên đăng ký là `LoginCreateRole` (`LoginCreateRole_PreLoad`, `_OnLoad`, `_OnEvent`). Người chơi
chọn bốn thứ ĐỘC LẬP với nhau, cộng tên và giới:

| Thứ | Cửa sổ | Biến của script | Game ghi |
|---|---|---|---|
| Ảnh chân dung | chín ô `CreateRole_Select_Head1..9`, lật trang `CreateRole_PageUp/PageDown` | `g_FacePageCount`, `g_iFaceIndexInPage` | `SetFaceId` lúc bấm tạo |
| Kiểu tóc | mũi tên `CreateRole_SelectHair_TurnLeft1/TurnRight1` | `g_iCurSelHairIndex` | `SetHairModelId` |
| Kiểu mặt | mũi tên `CreateRole_SelectFace_TurnLeft1/TurnRight1` | `g_iCurSelectFace`, `g_FaceModel` | `SetFaceModelId` |
| Bộ đồ tân thủ | mũi tên `CreateRole_SelectClothin_TurnLeft1/TurnRight1` | `g_iCurSelEquipSetIndex` | `ChangeNewRoleEquipSet` |

Ảnh chân dung không gắn với kiểu mặt: bản port trước ngày 2026-10-09 suy ảnh từ id kiểu mặt nên
nhân vật nam có thể mang ảnh nữ.

## 2. Dữ liệu và phân bố

Thủ tục tạo nhân vật `CGamePro_CharCreate` (con trỏ toàn cục `0x14103d608`, vtable `0x140c2bea8`,
khởi tạo `0x1406413e0`) giữ ba bộ quản và bảng bộ đồ:

| Bộ quản | Nạp ở | Bảng Config | Cách giữ |
|---|---|---|---|
| `CharacterFaceMng` (chân dung) | `0x14063df70` | `CharacterFace.txt` (150 dòng) | mỗi giới một dãy MỌI dòng theo thứ tự tệp, rồi `std::stable_sort` (`0x14063f480`) tăng dần theo cột 5 (`order`, so có dấu) |
| `FaceModelMng` (kiểu mặt) | `0x14063fa20` | `CharFaceGeo.txt` (448 dòng) | mỗi giới một dãy mọi dòng theo thứ tự tệp, không lọc, không sắp |
| `HairModelMng` (kiểu tóc) | `0x140642d20` | `CharHairGeo.txt` (612 dòng) | cờ chế độ `[mng+0]` bằng 0 (hàm dựng `0x140642920`): chỉ giữ dòng có `choice` 1 hay 3, theo thứ tự tệp |
| bộ đồ tân thủ | `0x140640ec0` | `NewRoleEquipset.txt` (3 dòng) | mọi dòng theo thứ tự tệp |

"Chọn được lúc tạo" ở cả ba bảng là cột `choice` bằng 1 hay 3; mã máy viết
`((choice - 1) & ~2) == 0`. Cột `choice`: cột 4 của `CharacterFace`, cột 8 của `CharFaceGeo`, cột 10
của `CharHairGeo` (đếm từ 1).

Phân bố của bản 2026 (test `client_data_has_the_2026_spread` của `tests/ui_create_tests.cpp` canh):

- Ảnh chân dung: mỗi giới 15 ảnh, hai trang (9 và 6). Nữ: id 49, 50, 51 (`order` 0) rồi 1..12
  (`order` 1). Nam: id 52, 53, 54 rồi 13..24. Ảnh là `set:GirlProtagonist image:GirlProtagonist_N`,
  `set:GirlProtagonist1 ...`, `set:ManProtagonist ...`, `set:ManProtagonist1 ...`.
- Kiểu mặt chọn được (`choice` 3): nữ là dòng thứ 0..4 và 13 của giới (id 1..5, 14: 美艳型, 智慧型,
  开朗型, 高贵型, 淑女型, 清雅型); nam là dòng 0..4 và 13 (id 100..104, 113: 坚强型, 勇敢型, 果断型,
  自信型, 忧郁型, 清雅型).
- Kiểu tóc chọn được: nữ id 1, 17, 19 (游仙发, 鬓华发, 宝锦发); nam id 5, 12, 14 (流云发, 鬓华发,
  宝锦发).
- Bộ đồ tân thủ: ba dòng `新手套装1..3`; ba cột sau tên là id hình trang phục (`ItemVisualChar`) của
  áo, giày, bao tay: 437/440/443, 438/441/444, 439/442/445.
- Dòng cao mô: `choice` -1, id là id thường cộng 10000. Mặt: 10001..10005 (nữ), 10100..10104 (nam);
  kiểu 清雅型 (id 14, 113) không có dòng cao mô. Tóc: 10001, 10017, 10019 (nữ), 10005, 10012, 10014
  (nam).

Dữ liệu của client dự án: `Table/portraits.tsv` (`collect_ui.py`: id, race, image, choice, order),
`Table/faces.tsv` và `Table/hairs.tsv` (`export_look.py`: mọi dòng theo thứ tự tệp, kèm name và
choice), `Table/newbie_outfits.tsv` (`export_config.py`). Lưới của mọi thứ chọn được và dòng cao mô
của chúng do `collect_avatar.py` gom (chạy sau hai bộ xuất kia).

## 3. Hàm của game mà script gọi (`GameProduceLogin`)

| Hàm Lua | Địa chỉ | Hành vi |
|---|---|---|
| `GetWomanFaceCountForCreate`, `GetManFaceCountForCreate` | `0x140342610`, `0x140342670` | số dòng chân dung của giới có `choice` 1 hay 3 |
| `GetFaceName(giới, chỉ số)` | `0x140342850` | ảnh của dòng thứ chỉ số trong dãy ĐÃ SẮP của giới; rỗng khi dòng không chọn được hay không có |
| `SetFaceId(giới, chỉ số)` | `0x140342950` | ghi id chân dung (`m_iFaceId`, ô `+0x1b4`) khi dòng chọn được; không thì không ghi gì |
| `GetFaceModelCount`, `GetFaceModelInfo`, `GetFaceModelName` | `0x140342a10`, `0x140342b60`, `0x140342aa0` | số dòng kiểu mặt của giới; cột `choice` (-1 khi không có dòng); tên (rỗng khi không có) |
| `SetFaceModelId(giới, chỉ số)` | `0x140342c20` | ghi id kiểu mặt (ô `+0x1a4`; id 0 khi không có dòng, `0x14063fb90`) và đổi mặt người mẫu sang id cộng 10000 |
| `GetHairModelCount`, `GetHairModelName` | `0x140342cc0`, `0x140342d50` | trên dãy đã lọc |
| `SetHairModelId(giới, chỉ số)` | `0x140342e10` | ghi id kiểu tóc (ô `+0x1ac`) và đổi tóc người mẫu sang id cộng 10000 |
| `GetEquipSetCount`, `GetEquipSetName` | `0x1403433e0`, `0x140343430` | bảng bộ đồ tân thủ |
| `ChangeNewRoleEquipSet(giới, chỉ số)` | `0x1403434b0` (thủ tục `0x140641210`) | nhớ giới (`+0x3e0`) và chỉ số (`+0x3e4`), id bộ đồ (`+0x1b8`), đổi người mẫu sang ô `giới * 3 + chỉ số` của sáu người mẫu (`+0x1c8`) |
| `ShowModel(môn phái)` | `0x140343300` | -1 là người mẫu tự chọn, 0..14 là người mẫu của môn phái |
| `ModelRotBegin`, `ModelRotEnd`, `ModelZoom` | `0x140343540`, `0x1403435d0`, `0x1403436c0` | quay ±1 vòng mỗi giây, phóng ±1 |
| `CreateRole(tên, giới, chỉ số họ, chỉ số tên)` | `0x140340d40` (thủ tục `0x1406408a0`) | tên rỗng, dài quá 12 byte, có ký tự hay chuỗi cấm thì báo; không thì gửi máy chủ |
| `ChangeToSelectRoleDlgFromCreateRole` | `0x140340a20` | về bảng chọn |
| `GetIsForbidName`, `GetSelectLoginServerZWID`, `RandomCharName` | `0x1403432b0`, `0x14033fcb0`, `0x140342eb0` | cờ "chỉ được dùng tên ngẫu nhiên" của máy chủ; mã máy chủ đang chọn (-1 khi chưa chọn) |
| `GameLoginShowSystemInfo(chữ)` | `0x140343c70` | hộp thông báo của thủ tục đăng nhập |

Sáu người mẫu của màn tạo (`0x140641e60`): id chủng tộc bằng `giới + 2 * (chỉ số bộ đồ + 1)`, tức dòng
2..7 của `CharRace.txt`, mẫu 2638..2643 của `CharModelEx.txt` = `男新手套装1..3.obj`,
`女新手套装1..3.obj` (xương chuẩn, ba lưới của bộ đồ gắn sẵn, mặt 10001 hay 10100, tóc 10001 hay
10005). Bản port dựng cùng hình bằng giới 0 hay 1 cộng `look::Look{body, foot, arm}` lấy từ bảng bộ
đồ và mặt, tóc cao mô (test `creation_figures_resolve` của `tests/avatar_data_tests.cpp` kiểm đủ 54 tổ
hợp mỗi giới, bản thường và bản cao mô). Chỗ đứng, camera và hoạt ảnh của người mẫu ở mục 8.

## 4. Thói quen lạ của script, giữ nguyên trong bản port

1. Mũi tên và nút ngẫu nhiên của kiểu mặt chỉ đi qua 3 kiểu đầu: `CreateRole_SelectFace_GetMaxValidFaceIndex`
   gọi `GetHairModelCount` (số kiểu TÓC, bằng 3) để lấy trần. Ba kiểu mặt 高贵型, 淑女型, 清雅型 (và ba
   kiểu tương ứng của nam) có trong bảng, chọn được, nhưng không nút nào tới.
2. Đổi giới (`CreateRole_SelectGirl`, `CreateRole_SelectBoy`) đặt ô dùng để tạo về ô đầu
   (`CreateRole_BnSelFace1`) mà không đổi dấu chọn của chín nút: dấu vẫn ở ô bấm trước đó. Chỉ sự kiện
   mở bảng mới `SetCheck` ô đầu.
3. Lật trang không dời ô đang chọn: ảnh dùng để tạo là `trang * 9 + ô`. Ô đó không có ảnh (trang hai
   chỉ có sáu ảnh) thì `SetFaceId(giới, -1)` không ghi gì, `GetFaceName` trả rỗng và game báo
   `#{DLXZ_090711_1}`. Nhánh "请选择头像!" (ô bằng -1) không tới được sau lần mở đầu.
4. `g_iCurSelectFace` không được đặt lại khi đổi giới hay mở lại bảng: người mẫu về kiểu mặt đầu,
   nhưng mũi tên bấm kế tính từ chỉ số cũ. `g_FaceModel` cũng không xoá khi đổi giới.
5. Bộ đồ tân thủ gieo `math.random(0, 2)` lúc nạp script, mỗi lần mở bảng và mỗi lần đổi giới.
6. Đang xem trước môn phái thì khung tuỳ chọn `CreateRole_Info_Frame` (giới, tóc, mặt, bộ đồ, ô
   ảnh, ngẫu nhiên, tạo, quay lại) bị khoá và mờ hẳn, ô tên bị giấu: chỉ còn mười lăm nút môn
   phái, nút thôi xem và hai nút giới của khung xem trước. Đổi giới ở khung xem trước đi qua
   `CreateRole_BnClickMenpaiModelEx`, bản này giấu hẳn khung tuỳ chọn.

## 5. Nút đánh dấu của CEGUI (`FalagardCheckButton`)

Chín ô ảnh (`TLBB_ButtonCheckHead`, `CheckMode` 1 theo looknfeel), hai nút giới (script đặt
`CheckMode` "1" lúc nạp) và hai nút giới của khung xem trước (`CheckMode` 1 trong layout) là nút
chọn một: `setCheck(true)` (`CEGUIFalagard.dll` `0x1800d31a0`) và lần bấm (`onMouseButtonUp`
`0x1800d2ed0`) tắt mọi nút đánh dấu cùng cha; bấm nút đang bật thì nó vẫn bật
(`onMouseButtonDown` `0x1800d2e50`). Chi tiết ở `docs/GIAO-DIEN-2026.md` mục 7.3. Trọng tài
`TOOLS/port/lua_oracle.py` mô phỏng luật này từ 2026-10-09 (đọc `CheckMode` mặc định từ scheme và
looknfeel); số vàng của bảng nhiệm vụ sinh trước ngày đó giữ sai trạng thái thẻ "hiện tại" sau khi
bấm thẻ "nhận được" và đã sinh lại.

## 6. Số vàng và lệnh tái hiện

```
python -B TOOLS/content/export_look.py "F:/tl 2026/_raw" "F:/tl 2026/_glb" CLIENT/data
python -B TOOLS/content/export_config.py "F:/tl 2026/_raw" CLIENT/data
python -B TOOLS/content/collect_avatar.py "F:/tl 2026/_raw" "F:/tl 2026/_glb" CLIENT/data
python -B TOOLS/content/collect_ui.py "F:/tl 2026/_raw" CLIENT/data
python -B TOOLS/content/lua_plain.py ...   (giải CreateRole.lua vào build/lua-2026)
python -B TOOLS/port/lua_oracle.py "F:/tl 2026/Bin64" build/lua-2026/Interface/CreateRole/CreateRole.lua
    CLIENT/data/Interface/CreateRole/CreateRole.layout.xml TOOLS/port/oracle/create_role_newcomer.lua
    tests/golden/panel/create_role_newcomer.tsv --name LoginCreateRole
    --words TOOLS/port/oracle/words.vi.tsv --lib TOOLS/port/oracle/create_role_api.lua
    --table portraits=CLIENT/data/Table/portraits.tsv --table faces=CLIENT/data/Table/faces.tsv
    --table hairs=CLIENT/data/Table/hairs.tsv --table outfits=CLIENT/data/Table/newbie_outfits.tsv
```

(lệnh trọng tài viết trên một dòng). Kịch bản `create_role_newcomer.lua` có 30 bước và đưa sẵn tám
số cho `math.random`; `TOOLS/port/oracle/create_role_api.lua` là các hàm `GameProduceLogin` viết lại
bằng Lua trên bảng thật. `port_matches_original_script` của `tests/ui_create_tests.cpp` chạy cùng 30
bước trên bản port và so 2393 dòng trạng thái. Thử đột biến ngày 2026-10-09: cho mũi tên mặt đếm theo
số kiểu mặt thay vì số kiểu tóc thì test đỏ ở bước "mặt quay vòng về đầu".

## 7. Khác gốc và chưa port

- Chưa có máy chủ: `GetIsForbidName` luôn 0 (nút tên ngẫu nhiên luôn ẩn, `RandomCharName` và sự kiện
  `RESHOW_CREATE_PLAYERNAME` không có), `LoginCreateRole_DingZhiMenPai` không khoá môn phái nào,
  `CreateRole` lưu vào sổ cục bộ `CLIENT/data/Save/roles.tsv` (phiên bản 2: thêm áo, bao tay, giày).
- Tên: luật của `ui/panel/roles` (12 mã Unicode, không `#`, không trùng trong tài khoản) thay cho
  luật 12 byte GBK và hai bộ lọc ký tự, chuỗi cấm của bản gốc; ô tên lọc ngay lúc gõ.
- Lời nhắn của `GameLoginShowSystemInfo` và lỗi tên hiện ở dòng mô tả `CreateRole_Info` cho tới lần
  rê chuột kế; bản gốc mở hộp thông báo.
- `StartFade` đổi độ trong ngay (bản gốc chạy 0,5 giây); `Clicked` chạy lúc nhấn (bản gốc lúc nhả).
- Ô mô tả môn phái `Createshow_Info2` là khung cuộn chữ (`gui::TextScroll`): tự trôi và lăn chuột
  được, không có thanh cuộn. Bản gốc là `FalagardSimpleText` không cuộn (`docs/GIAO-DIEN-2026.md` mục
  D.1), chữ Hán cỡ 12 vừa khít ô; chữ Việt cỡ 14 dài 10 đến 12 dòng trong ô 9 dòng.
- Khung chữ góc dưới trái `Createshow_Info_Back` không vẽ (bảng vẫn đặt chữ cho nó): ở vùng vẽ thấp
  hơn 769 điểm nó đè lên nút môn phái cuối danh sách, và nội dung của nó đã có ở khung bên phải.
- Ảnh có chữ vẽ sẵn (nút môn phái, nút khung, tiêu đề, nhãn, câu đối) mang chữ Việt dựng bằng
  `TOOLS/content/letter_labels.py`; hai vế câu đối canh giữa, ảnh gốc để so le trái phải.
- `ShowModel(môn phái)`: người mẫu riêng của môn và bài múa đã có (mục 8.4); còn thiếu hiệu ứng gắn
  vũ khí, hiệu ứng của skill và đoạn trộn 0,3 giây.
- Vòm trời: thủ tục gọi hai hàm của hệ vẽ lên vòm trời của cảnh (mục 8.5); dự án chưa vẽ vòm trời.
- Chuỗi "chuangjiannan" (nam) và "default" (nữ) của `0x140641210` đi tới vòm trời (mục 8.5).
- Kiểu mặt không có dòng cao mô thì người mẫu giữ dòng thường (bản gốc vẫn cộng 10000); với ba kiểu
  mà nút tới được thì không xảy ra.
- Enter trong ô tên chạy như nút tạo; layout gốc không nối `TextAccepted` cho ô tên, còn thủ tục
  `CGamePro_CharCreate` có tự bắt phím Enter hay không thì chưa tháo (`docs/NGHI-NGO.md` mục 40).

## 8. Người mẫu trong cảnh 3D, camera và hoạt ảnh (2026-10-09)

Đọc từ `Game.exe` (thủ tục `CGamePro_CharCreate`), `Render.dll` (`CCamera_CharSel`, vtable
`0x1802bbc58`) và `OgreMain.dll`. Bản port: `SRC/control/char_camera.*` (camera),
`SRC/client/display/role_stage.*` (phần thủ tục điều khiển camera), `SRC/ui/panel/create_role.cpp`
(`settle_models`), `SRC/client/display/role_preview.*` (người mẫu).

### 8.1 Người mẫu đứng trong cảnh, không ở cửa sổ giao diện

Script vẫn gọi `CreateRole_Model:SetFakeObject("CreateRole_Woman" | "CreateRole_Man")`, nhưng
`Game.exe` không có chuỗi `CreateRole_` nào (`pe_refs.py Game.exe text CreateRole_` rỗng): không fake
object nào tên như vậy được tạo, cửa sổ `CreateRole_Model` để trống. Người mẫu là đối tượng của
`CObjectManager` đặt thẳng vào cảnh `tl3chuangjian`:

- Chỗ đứng (hàm dựng `0x140641bd0` ghi `+0x3f8`, `+0x404`): cả hai giới ở (818, 1064, 3033) hệ GFX,
  đúng mặt bục `天龙3选人场景选人台.mesh` của cảnh (bục đặt ở y 1000, hai hệ hạt của cảnh ở y 1064).
  Hướng (`+0x410`, `+0x41c`) là 0. Tỉ lệ 1,5 (`0x14064206e`).
- `ShowModel` của thủ tục (`0x140640450`) chạy cho cả hai giới, giữ mỗi giới một con trỏ "người mẫu
  hiện tại" (`+0x2e8`, `+0x2f0`). Người mẫu hiện tại vẫn đúng là thứ cần hiện thì chỉ đổi ẩn hiện;
  khác thì bỏ, rồi chỉ giới thủ tục đang nhớ (`+0x3e0`) nhận người mẫu mới, và người mẫu vừa nhận
  được `SetRotation` về hướng 0. Hệ quả giữ trong bản port: đổi bộ đồ hay vào xem trước môn phái thì
  người mẫu quay mặt lại; đổi giới rồi đổi lại với cùng bộ đồ thì người mẫu cũ còn nguyên hướng đang
  quay dở; đổi mặt hay tóc không đổi hướng.
- Nhịp (`0x1406416f1`) chỉ quay người mẫu hiện tại của giới đang nhớ: y += spin × 6,28318548 × mili
  giây / 1000.

### 8.2 Camera

`CCamera_CharSel` gắn camera vào một SceneNode chạy theo bốn animation dựng ở `0x180001dc0`:

| Track | Dài | Nội suy | Khoá |
|---|---|---|---|
| `CameraTrack` | 0,5 giây | tuyến tính | đầu: mắt (822,06; 1347,22; 3678,52) của NAM; cuối: mắt (822,06; 1307,38; 3708,29) của NỮ; cùng hướng nhìn (cúi 5,05 độ) |
| `Role0To1` | 2 giây | spline | mắt ô 0, khoá giữa lùi ra (−77,42; 1307,86; 1927,47), mắt ô 1 |
| `Role1To2` | 2,5 giây | spline | mắt ô 1, khoá giữa (799,46; 1307,86; 2230,02), mắt ô 2 |
| `Role2To0` | 2 giây | spline | mắt ô 2, khoá giữa (1609,60; 1307,86; 1927,47), mắt ô 0 |

Mắt của màn tạo cao ngang tầm mắt người mẫu (người mẫu cao 200 × 1,5 hay 180 × 1,5, chân ở 1064) và
cách 645 đến 675 cm; FOV dọc 65 độ (`0x1800027a0`).

- `0x1800027a0(chế độ)` (hệ vẽ `+0x228`): 1 là giữ `CameraTrack` ở khoá cuối, 2 là giữ ở khoá đầu, 3
  (bảng chọn) không đụng track. `CGamePro_CharCreate::Init` (`0x1406413e0`) gọi với `giới đang nhớ +
  1`.
- `0x1800025e0(xuôi, giữ, track, thời điểm)` (hệ vẽ `+0x248`): bật đúng một track. Giữ thì nhảy tới
  cuối chiều đang đi. Thời điểm âm thì chạy từ đầu chiều đang đi, trừ khi track này vừa chạy (ô
  `+0x90`): lúc đó chỉ đổi chiều, camera quay đầu từ chỗ đang đứng. `ChangeNewRoleEquipSet`
  (`0x140641210`) gọi (xuôi = nữ, không giữ, track 0, −1): mở bảng thì camera lướt 0,5 giây từ mắt nam
  sang mắt nữ; đổi giới thì lướt sang mắt giới kia.
- Mỗi khung (`frameStarted`, `0x180003410`) cộng thời gian khung, xuôi hay ngược, vào track đang
  bật nếu không giữ. `AnimationState` không lặp nên thời điểm kẹp trong [0, dài].
- Lớp gốc không tắt state nào. `SceneManager::_applySceneAnimations` của client (`OgreMain.dll`
  `0x18016e340`) áp từng state, state nào cũng đặt lại node trước khi áp, và `setEnabled(true)` đưa
  state về cuối danh sách: tư thế đang vẽ là của track được bật gần nhất, không cộng dồn.
- Nội suy: `NodeAnimationTrack::getInterpolatedKeyFrame`; spline là `SimpleSpline` (Catmull-Rom) cho
  mắt và `RotationalSpline` (squad) cho hướng. `Quaternion::Slerp` của bản OGRE này là bản có ngưỡng
  1 − 1e-3 và `atan2` (`0x18014a670`).
- Bảng chọn (`0x14063c480`): đổi ô thì chạy track nối hai ô (0 sang 1 xuôi `Role0To1`, 0 sang 2 ngược
  `Role2To0`, 1 sang 2 xuôi `Role1To2`, 1 sang 0 ngược `Role0To1`, 2 sang 0 xuôi `Role2To0`, 2 sang 1
  ngược `Role1To2`). Đang chạy (`0x180001ce0`) mà đòi ô thứ ba thì ghi ô chờ, nhịp `0x14063cfa0` cho
  đi tiếp khi tới nơi; đòi quay lại ô vừa rời thì đảo chiều ngay.

### 8.3 Phóng

Nút `CreateRole_ModelZoomIn` / `ZoomOut` gọi `ModelZoom(±1)` lúc nhấn và `ModelZoom(0)` lúc nhả; hàm
đó đặt thẳng tốc độ phóng của camera (`0x180002b20`, ô `+0x8c`). Con lăn (`0x1406418be`, sự kiện 18
và 19; bảng chọn `0x14063d41e`) đặt tốc độ ±1 và cộng ±5 vào bộ đếm của thủ tục; mỗi nhịp bộ đếm
lùi 1 về 0, tới 0 thì tốc độ về 0 (bộ đếm rơi đúng 0 do lăn ngược chiều thì cờ còn bật và tốc độ
giữ nguyên tới nấc lăn kế).

Nhịp camera (`0x180002b30`): lượng phóng cộng `mili giây × tốc độ`, kẹp trong [0, 400] ở màn tạo
(ô `+0x88`) và [0,1; 100] ở bảng chọn (ô `+0x80`); phần vừa đổi được trừ vào vị trí của khoá đầu và
khoá cuối theo trục z của chính khoá đó (camera tiến theo hướng nhìn). Lượng phóng chỉ được đặt ở
hàm dựng camera: rời màn rồi vào lại vẫn giữ.

### 8.4 Hoạt ảnh

- Người mẫu tự chọn là `CObject_PlayerOther` thường: đứng `空手站立01`, thỉnh thoảng động tác nghỉ.
  Bộ hành động của sáu mẫu (1465..1467 nam, 868..870 nữ) khác bộ của người chơi (1415, 819): cả
  hai động tác nghỉ đều là `空手休闲`. Bản port dùng bộ của người chơi (nghỉ thứ hai là
  `空手站立01`). `男新手套装N.obj` chỉ nối `4_男空手非战斗.skeleton` (không có `空手休闲`); người
  mẫu nam của bản gốc làm gì khi tới lượt nghỉ thì chưa kết luận (`docs/NGHI-NGO.md` mục 40).
- Xem trước môn phái: `ShowModel(môn)` gọi `Actor_EnterSkill(tên, không lặp, trộn 0,3)` trên người
  mẫu của môn. Tên: `演武` cho môn 0..11; môn 12 `m01_主角时装桃花岛高模男_演武` (nam),
  `g01_主角时装桃花岛高模女_演武` (nữ); môn 13 `m01_npcM_cloth_CR_2021gaoji_演武`,
  `g01_npcW_cloth_CR_2021gaoji_演武`; môn 14 `npc_ERG_2024高模演武_女` cho NAM và
  `npc_ERG_2024高模演武_男` cho NỮ (con trỏ ở `0x140fb22c8..0x140fb22f8`). Ba mươi người mẫu môn
  phái dựng ở `0x1406420d0` (`CharModelEx` dòng 4950 + giới × 15 + môn), cùng chỗ đứng và tỉ lệ 1,5.
  Mỗi mẫu trong `all.obj` kê thẳng các lưới (thân, mặt, tóc, vũ khí), xương riêng chỉ có hai animation
  `站立` và `演武` (nữ Đào Hoa Đảo: `休闲`). Bộ hành động của mười hai môn đầu lấy `演武` làm cả hai
  động tác nghỉ, nên người mẫu thỉnh thoảng múa lại; ba môn cuối để trống.
  Bản port (2026-10-09): `export_look.py` sinh `Table/sect_models.tsv`, `collect_avatar.py` gom 30
  xương và lưới của chúng, `look::sect_figure` dựng hình, `PlayerActor` múa một lần lúc dựng rồi về
  clip đứng. Khác gốc: vào thẳng bài múa (gốc trộn 0,3 giây); chưa vẽ hiệu ứng của khối `Effects`
  trong mẫu (hào quang vũ khí `wq_...` gắn locator) và hiệu ứng của skill ba môn cuối.
- Lúc bấm tạo, nhịp của thủ tục chờ tên hoạt ảnh đang phát của người mẫu khác `选人动作`
  (`0x140fb22c0`) rồi mới gửi yêu cầu tạo; màn tạo không tự phát `选人动作`.

### 8.5 Vòm trời

`Init` gọi hệ vẽ `+0x350(0, 0,132951)` (`Render.dll` `0x18002dc80`: ghi số đó vào mọi đối tượng
`SkySphere` của cảnh). `ChangeNewRoleEquipSet` gọi hệ vẽ `+0x348` (`0x180031120`) với chuỗi
`"chuangjiannan"` khi chọn nam và `"default"` khi chọn nữ: hàm tìm đối tượng `#FairySkySphere` của
cảnh và đưa chuỗi cho `0x1800f3440`. Hàm cuối chưa tháo; dự án chưa vẽ vòm trời nên chưa có gì để
nối.

### 8.6 Bộ tài nguyên `_iv` không được dùng

`CharModelEx.txt`, `CharFaceGeo.txt`, `CharHairGeo.txt` có thêm cột tên `_iv` (`男主角_iv.obj`,
`男主角脸01_iv.mesh`...), `Config` có `ItemVisualChar_iv.txt`, `Model` có `*_iv.skeleton`. `Game.exe`
chọn bộ `_iv` khi biến `0x14103ef58` khác 0 (34 chỗ đọc), nhưng không lệnh nào ghi biến đó (quét mọi
tham chiếu theo RIP với mọi cỡ hằng theo sau, tham chiếu theo gốc ảnh, con trỏ tuyệt đối; biến nằm
trong vùng khởi tạo 0, tệp không xuất nó). `SystemSetup:IsClassic()` (`0x14045fbb0`) trả hằng 1:
tệp này là bản "kinh điển", còn `_iv` là dữ liệu của bản "唯美" không được biên dịch vào. Bản 2026
luôn dùng bộ thường, như dự án.

Hai bộ khác nhau thật: clip `空手站立01` của nam trong `4_男空手非战斗.skeleton` để xương đầu thẳng
đứng, tức ngửa 12 đến 15 độ so với tư thế bind của `男主角.skeleton` (xương đầu của bind chúi 15 độ
về trước); cùng clip trong `4_男空手非战斗_iv.skeleton` lệch bind dưới 5 độ. Nữ lệch bind 0 đến 3
độ. Nam ngẩng cằm là dữ liệu của bản thường, không phải lỗi nội suy. Trước ngày 2026-10-09 bản port
vẽ người mẫu trong cửa sổ giao diện bằng một camera FOV 20 độ đặt ngang thắt lưng, nên nam trông
như ngước lên trời; camera gốc đặt ngang tầm mắt và cúi 5 độ. Pháp tuyến trung bình của lưới mặt ở
bind chúc xuống 14,6 độ (nam) và 17,8 đến 19,5 độ (nữ): mặt hai giới ở bind đều nhìn ngang, nên ở clip
đứng mặt nam ngẩng thật. Chủ dự án thử tay với camera mới vẫn thấy "nam ngước cổ lên một chút"; phân
tích tĩnh không tìm ra chỗ nào bản gốc làm khác, cần ảnh chụp màn tạo của bản gốc để so (`docs/NGHI-NGO.md`
mục 40).

### 8.7 Ống kính của cửa sổ fake object

Số đo cũ còn dùng được cho các cửa sổ fake object thật (trang bị, trân thú): `Render.dll` `0x17C10`
đặt FOV dọc 20 độ và mặt cắt gần 10 cho camera của fake object. Tệp `SRC/look/body.hpp` giữ hai số
này đã gỡ ngày 2026-10-09 vì màn tạo không còn dùng.
