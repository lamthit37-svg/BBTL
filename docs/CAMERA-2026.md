# Camera và chuột của client 2026: mã gốc nằm ở đâu, làm gì, dự án port thế nào

Tệp này ghi kết quả đọc mã máy của client Thiên Long Bát Bộ bản 3.71 (`F:\tl 2026\Bin64`, dựng
bằng MSVC 2012, x64, không đóng gói) cho hai việc: camera cảnh và chuột điều khiển camera, nhân vật.
Mọi địa chỉ là địa chỉ ảo theo gốc ảnh mặc định: `Game.exe` gốc `0x140000000`, `Render.dll` gốc
`0x180000000`. Ngày đọc: 2026-10-08. Mã của dự án: `SRC/control/follow_camera.*` (camera),
`SRC/control/player_input.*` (chuột), nối vào `SRC/client/display/display_gpu.cpp` và
`SRC/client/viewer/viewer_win32.cpp`; test ở `tests/pilot_tests.cpp`.

Mức chắc chắn: mọi dòng dưới đây là ĐỌC TĨNH từ mã máy và tệp dữ liệu, chưa đối chiếu với một
client 2026 đang chạy. Chỗ suy ra chứ không đọc thẳng có ghi "suy ra". Các điểm còn ngờ nằm ở mục
38 của `docs/NGHI-NGO.md`.

## Cách tái hiện

Công cụ: `TOOLS/port/pe_refs.py` (cần `numpy`, `capstone`). Chạy ở gốc dự án; `G` là
`"F:/tl 2026/Bin64/Game.exe"`, `R` là `"F:/tl 2026/Bin64/Render.dll"`.

- Lớp camera và bảng hàm ảo: `python TOOLS/port/pe_refs.py R rtti CCamera_Scene`, `rtti
  CRenderSystem`, `rtti CCamera`.
- Tháo một hàm: `python TOOLS/port/pe_refs.py R func 180003d00` (hàm lá không có trong `.pdata`
  cũng tháo được, công cụ tự tìm chỗ hết; hàm bị `.pdata` chia mảnh thì nêu khoảng
  `<đầu>..<cuối>`).
- Ai gọi một hàm ảo của hệ vẽ (con trỏ `CRenderSystem` nằm ở biến `0x14103d668` của `Game.exe`):
  `python TOOLS/port/pe_refs.py G vcalls 14103d668:190` (độ dời `0x190` là `Camera_AddDirection`).
- Ai đọc một biến cấu hình: `python TOOLS/port/pe_refs.py G text Camera_Pitch_Min` rồi `refs` địa
  chỉ chuỗi.
- Hàm sinh sự kiện chuột: `python TOOLS/port/pe_refs.py G imports GetAsyncKeyState`.
- Bảng nhảy của vòng xử lý sự kiện: `python TOOLS/port/pe_refs.py G jump 64da38:17`.
- Thành viên của màn chơi do đâu ghi: `python TOOLS/port/pe_refs.py G uses
  164:140640000..140652000`.
- Chốt 500 ms của lệnh đi: `python TOOLS/port/pe_refs.py G imm 1f4:140613000..14061b000`.
- Phím xoay 0,04 radian của bản 2008 không còn: `python TOOLS/port/pe_refs.py G floats 0.04` in
  "không có lệnh nào đọc".

Mã nguồn bản 2008 để đối chiếu tên hàm: `G:\TLBB\_ref\client\Game\Client` (`WXRender/Camera`,
`WXClient/Procedure/GamePro_Main.cpp`, `WXClient/Input/GMInputSystem.cpp`).

## Render.dll: camera cảnh

Lớp `CCamera_Scene` (bảng hàm ảo ở `0x1802bbea8`), do `CRenderSystem` giữ ở `this+0x68`; camera
đang dùng ở `this+0x58`. Thành viên: điểm nhìn `+0x08`, pitch `+0x14`, pitch lúc dựng `+0x18`,
khoảng cách thế giới `+0x1c`, hướng `+0x20`, `Ogre::Camera` `+0x28`, độ cao cộng thêm `+0x38`, trạng
thái rung `+0x3c`, mặt cắt xa `+0x50`, mặt cắt gần `+0x54`.

Biến toàn cục của `Render.dll`:

| Địa chỉ | Giá trị đầu | Nghĩa |
|---|---|---|
| `0x1803b01e8` | -0,671951771 | pitch người chơi muốn (bản 2008 là hằng `STATIC_PITCH`) |
| `0x1803b01ec` | 6,0 | khoảng cách gần nhất, đơn vị game |
| `0x1803b01f0` | 17,5 | khoảng cách xa nhất |
| `0x1803b01f4` | 1750,0 | khoảng cách thế giới người chơi muốn, chỉ dùng khi cờ khác 0 |
| `0x1803b4cec` | 0 | cờ cách chữa mắt vướng: 0 sửa pitch, khác 0 sửa khoảng cách |
| `0x1803b4cf0` | 0 | góc nhìn ép của cảnh |
| `0x1803b0204` | 0,00174532924 | `MIN_ANGLE`, 0,1 độ |
| `0x1803b0208` | 0,0174532924 | `STEP_ANGLE`, 1 độ |
| `0x1803b01f8` | 10,0 | bước nới khoảng cách |

Hàm:

| Địa chỉ | Hàm | Việc làm |
|---|---|---|
| `0x180026115` | đoạn dựng camera trong `CRenderSystem::Initial` | pitch muốn = -`Camera_Pitch` độ (đổi bằng `TDU_PI` double); dựng `CCamera_Scene` với độ cao 0,7, pitch đó, khoảng cách 17,5, hướng 3,1416, mặt xa 15000, mặt gần 5 |
| `0x180003c10` | `SetLookAt` | đổi toạ độ game sang thế giới; điểm nhìn không đổi, pitch muốn trừ pitch đang dùng nhỏ hơn 0,1 độ và không rung thì thôi, không thì ghi và `Update` |
| `0x1800038d0` | `SetDistance` | khoảng cách thế giới = tỉ lệ đứng nhân khoảng cách game; cờ khác 0: mắt trống thì ghi khoảng cách muốn, vướng thì lùi từng 0,1 tới sàn; rồi `Update` |
| `0x180003d00` | `Update` | điểm nhìn cộng độ cao nhân tỉ lệ đứng; cờ 0 gọi `_GetValidPitch`, cờ khác 0 gọi hàm sửa khoảng cách; tính mắt; rung; `setPosition`, `lookAt`; đặt mặt xa, mặt gần; góc nhìn = `Camera_FOV` (thiếu thì 45), thay bằng góc ép khi góc ép lớn hơn 0,1 và lệch quá 0,01 |
| `0x1800048c0` | `_GetValidPitch` | mắt ổn: cách pitch muốn không quá 0,1 độ thì lấy pitch muốn, không thì tiến 1 độ (bước đó vướng thì đứng yên); mắt vướng: dốc thêm từng 1 độ tới khi thoát hoặc tới -(90 - 0,1) độ |
| `0x180004540` | sửa khoảng cách | mắt trống: nới 10, trần là khoảng cách muốn, nới quá thì lùi 0,1; mắt vướng: rút 1; sàn là gần nhất nhân tỉ lệ đứng |
| `0x180004c50` | `_IsValidEye` | quả cầu tâm mắt, bán kính là mặt gần của `Ogre::Camera`, không chạm hộp nào; không lấy được hộp thì trống khi cờ 0, vướng khi cờ khác 0 |
| `0x1800040e0` | `_GetInterPatch` | mắt ngoài map thì hỏng; bốn ô quanh đỉnh lưới gần mắt, mỗi ô một hộp đáy âm vô cùng, đỉnh là góc cao nhất của ô và độ cao mặt đi của công trình ở đỉnh đó (qua `CRenderSystem+0x2a0`, nhân 100); chỉ nhận khi có 2 hoặc 4 hộp |
| `0x180003770` | `AddOneVib` | rung của kỹ năng |
| `0x18002a9f0`..`0x18002ae40` | các hàm `Camera_*` của `CRenderSystem` | xem bảng dưới |

Mắt: `r = cos(-pitch) * d`, `x = -(sin(hướng) * r)`, `y = sin(-pitch) * d`, `z = -(cos(hướng) *
r)`, cộng điểm nhìn; tính bằng float.

Hàm `Camera_*` của `CRenderSystem` (độ dời trong bảng hàm ảo `0x1802c0cb8`):

| Độ dời | Địa chỉ | Hàm | Việc làm |
|---|---|---|---|
| `0x158` | `0x18002ab60` | `Camera_SetCurrent` | chọn camera rồi `Update` |
| `0x160` | `0x18002ac40` | `Camera_SetLookAt` | gọi `SetLookAt` |
| `0x170` | `0x18002ad30` | `Camera_SetZoom(BOOL, INT)` | zoom = (khoảng cách - gần) / (xa - gần), bước = số nhân 0,05, kẹp [0, 1] |
| `0x178` | `0x18002add0` | `Camera_SetZoom(FLOAT)` | ngoài [0, 1] thì thôi; khoảng cách = gần + (xa - gần) * zoom, âm thì 17,5, dưới gần thì gần; `SetDistance`; rồi `0x180032510` nới sương khi xa hơn 16,5 |
| `0x180` | `0x18002ab20` | `Camera_GetZoom` | trả phần [0, 1] (bản 2008 trả nhầm khoảng cách) |
| `0x188` | `0x18002abd0` | `Camera_Direction` | đặt hướng rồi `Update`; không gói về [0, 2 pi) |
| `0x190` | `0x18002a910` | `Camera_AddDirection` | hướng cũ cộng thêm |
| `0x1a0` | `0x18002acd0` | `Camera_SetPitch` | chỉ nhận trong (-89, 89) độ; ghi pitch muốn và pitch đang dùng; `Update` hai lần |
| `0x1a8` | `0x18002a950` | `Camera_AddPitch` | pitch muốn cộng thêm |
| `0x1b0` | `0x18002aa70` | `Camera_GetPitch` | trả pitch muốn, không phải pitch đang bị địa hình ép |
| `0x1c0` | `0x18002aa10` | lấy pitch lúc dựng | thành viên `+0x18` |
| `0x1c8` | `0x18002ac90` | đặt khoảng zoom | gần, xa, cờ cách chữa |
| `0x1e0` | `0x18002ac00` | `Camera_SetFOV` | ghi góc ép và đặt ngay cho `Ogre::Camera` |
| `0x1e8` | `0x18002ab50` | đặt độ cao điểm nhìn | không âm thì ghi rồi `Update` |
| `0x1f8`, `0x208` | | đặt mặt xa, mặt gần | |
| `0x220` | `0x18002ae40` | `Camera_VibrateOneTime` | `AddOneVib(10, 8, 2)` |

## Màn đăng nhập: cảnh nền và camera cố định

Đọc ngày 2026-10-08. Mã của dự án: `SRC/control/login_view.hpp` (hằng số), `render::posed_camera`
(`SRC/render/camera.*`), `login_camera` và `Display::State::idle_view` trong
`SRC/client/display/display_gpu.cpp`, `run_login` trong `SRC/client/main.cpp`.

`CGamePro_Login::Init` (`Game.exe` `0x140630900`) không gọi hàm `Camera_*` nào. Nó đóng màn chờ nạp
(sự kiện `0x1a2`), ép cửa sổ về vùng chơi 1280 x 720 (`0x140631270`), rồi gọi lần lượt các ô của
`CRenderSystem`: `+0x268(1)` (hàm lá `0x1800314f0`, ghi byte `+0x13a` của đối tượng ở `+0x48`),
`+0x278(-1, "erengu_DL.Scene")` (nạp cảnh, `0x18002fdc0`), `+0x5d8`, `+0x370(1)`, `+0x3d8(1, 1)`,
`+0x260`.

Ô `+0x260` (`0x18002ae90`) dọn môi trường của cảnh nền rồi nhảy tới `0x180002a30` với camera đang
chọn (`CRenderSystem+0x58`; lúc này là camera chọn nhân vật, `CRenderSystem::Initial` gán ở
`0x180026254`). Hàm `0x180002a30` đặt thẳng lên `Ogre::Camera` (`+0x28` của camera), không qua
`Update` của lớp camera nào:

| Việc | Giá trị |
|---|---|
| ô `+0x240` của `Ogre::Camera` (`setFOVy`) | 42 độ (nhân `Math::fDeg2Rad`) |
| `setPosition` | (-2279,21; 4462,81; -8181,77) |
| `setOrientation` | w 0,244674; x -0,00902838; y -0,968889; z -0,0357472 |
| ô `+0x260` (`setFarClipDistance`) | 40000 |

Tên ba ô của `Ogre::Camera` suy từ `CCamera_Scene::Update` (`0x180003d00`): sau `lookAt` nó gọi ô
`+0x260` với thành viên mặt xa (`+0x50`), ô `+0x250` với mặt gần (`+0x54`), ô `+0x240` với góc nhìn
đã đổi sang radian; `_IsValidEye` đọc mặt gần qua ô `+0x258`. Hàm `0x180002a30` không đặt mặt gần.
Dự án dùng 5: `CRenderSystem::Initial` dựng camera cảnh với mặt xa 15000, mặt gần 5 rồi gọi
`SetDistance(17,5)`, hàm này chạy `Update`. CHƯA kiểm bằng chạy thật: `Update` thoát sớm khi cỡ
khung nhìn chưa dương, khi đó mặt gần còn là số mặc định của OGRE.

Phần còn lại của ô `+0x260`, dự án CHƯA làm:

- Với đối tượng ở `CRenderSystem+0x48`: gọi `0x1800d4350(…, 2)`, `0x180046b10(…, 0)`,
  `0x180046200(…, 1, 0)`; ghi byte `+0x2b5` = 1 và hai số thực `+0x2ac`, `+0x2b0` = 65000; gọi
  `0x1800d10d0`. Chưa đọc từng hàm.
- Hai đối tượng đơn lấy bằng `0x1800a7800` và `0x1800d87e0` được bật (`0x1800ab5c0(…, 1)`,
  `0x1800d8d20(…, 1)`); ô `+0x418(18000, 1000)` (`0x18002e040`) ghi hai số ấy vào đối tượng thứ
  hai. Chưa xác định là hệ nào; cảnh có `SetCamDisCullDepth` 5000 và `SetCamDisCullParam` 14 trong
  `SceneConfig`, có thể liên quan.
- Ô `+0x300(0)` (`0x18002ca10`) đụng tới hậu kỳ tên `Floodlighting`.

Tái hiện: `python TOOLS/port/pe_refs.py "F:/tl 2026/Bin64/Render.dll" func 18002ae90`, `func
180002a30`, `func 180003d00..1800040e0`, `func 180026115..1800262a0`.

## Game.exe: màn chơi đọc cấu hình và đặt camera

Biến toàn cục của `Game.exe`:

| Địa chỉ | Giá trị đầu | Nghĩa |
|---|---|---|
| `0x14103d668` | | con trỏ `CRenderSystem` |
| `0x14103d640` | | con trỏ `CInputSystem` |
| `0x14103d618` | | con trỏ `CGamePro_Main` |
| `0x140fb2df4` | -0,0 | pitch cao nhất kéo được, radian (= -`Camera_Pitch_Min`) |
| `0x140fb2df8` | -1,5707964 | pitch thấp nhất kéo được (= -`Camera_Pitch_Max`) |
| `0x140fb2d74` | -0,69813174 | pitch khi đang đi (= -`Camera_Pitch_Moving`) |
| `0x140fb2db4` | 10,0 | `Camera_MoveSpeed_Auto`, độ mỗi giây |
| `0x140fb2ef0` | 0,1 | bước đích zoom mỗi nấc lăn |
| `0x140fb2ef4` | 0,01 | bước zoom mỗi nhịp |
| `0x140fb2ef8` | 1,0 | đích zoom |
| `0x140fb2dfc` | -1 | loại camera của cảnh đang dùng (cột 2 của `SpecialSceneCamera`) |
| `0x14103dfa8` | 0 | `m_nResetCamera`: dấu của chiều đang quay về |
| `0x14103dfc0` | 0 | hướng đang bị khoá trong một khoảng (cảnh và công trình đặc biệt) |

Thành viên của `CGamePro_Main` (hàm dựng `0x14064de80`): `+0x138` vừa nhấn phải, chờ kéo; `+0x13c`
chỗ nhấn phải; `+0x144` đang kéo camera; `+0x148` đang giữ nút giữa; `+0x14c` tự chạy; `+0x150` zoom
đang tiến về đích; `+0x154` `Camera_Smooth`; `+0x15c` trạng thái tự chỉnh pitch (0 nghỉ, 1 đang
chỉnh, 2 người chơi vừa kéo); `+0x160` `Camera_RestoreView`; `+0x164` luôn bằng 1.

Hàm:

| Địa chỉ | Hàm | Việc làm |
|---|---|---|
| `0x1406bfad0` | `CScene::Initial` | mặt xa và mặt gần của cảnh = cột 16 và 17 của `SceneDefineEx` |
| `0x1406c0c53` | đoạn camera của `CScene::EnterScene` | tra `SpecialSceneCamera` theo id cảnh, không có thì dòng id 1; loại trùng loại đang dùng thì thôi; đặt giới hạn pitch, khoảng zoom, cờ, góc nhìn theo dòng; cảnh loại 0 mà `View_DefaultCamera` khác 0 thì lấy lại từ `System.cfg` (`Camera_Pitch_Min`, `Camera_Pitch_Max` trong [-90, 90] và đúng thứ tự; `Camera_MinDistance` mặc định 6, `Camera_MaxDistance` mặc định 27,5, cách nhau ít nhất 0,1; `Camera_FOV` mặc định 35); độ cao điểm nhìn = cột 10; bước lăn = cột 6, bước nhịp = cột 7; cảnh loại khác 0 còn đặt hướng (cột 11), pitch (cột 12) và `Camera_Zoom` (cột 13) |
| `0x140643d13` | đoạn camera của `CGamePro_Enter` | chọn camera cảnh; cảnh loại 0: hướng = 3,1415; zoom = `Camera_Zoom` (mặc định 1); cảnh loại 0: pitch = ((pitch lúc dựng tính bằng độ + 26) * zoom - 26) độ |
| `0x140647fd0` | `CGamePro_Main::Init` | đọc `Camera_Pitch_Moving`, `Camera_MoveSpeed_Auto`, `Camera_Smooth`, `Camera_RestoreView`; đích zoom = `Camera_Zoom`; tắt tự chạy |
| `0x14064c750` | `CGamePro_Main::Release` | thôi kéo camera (hiện con trỏ, nhả chuột), tắt tự chạy, ghi `Camera_Zoom` = `Camera_GetZoom` |
| `0x14064c960` | `ProcessInput_Mouse` | xem mục dưới |
| `0x14064b39f` | đoạn camera của `Tick` | xem mục dưới |
| `0x140239dc8` | Lua `ResetCamera` | gói hướng về [0, 6,283) rồi `m_nResetCamera` = 1 nếu hướng nhỏ hơn 3,1415, không thì -1 |
| `0x14021b490` | lệnh phím 0x2d và 0x2e | `Camera_SetZoom(TRUE, 2)` và `Camera_SetZoom(FALSE, 2)`; không chạy khi hướng bị khoá |
| `0x14045f6ba` | đổi `View_DefaultCamera` lúc đang chơi | đặt lại như `EnterScene`, zoom về 1 |

## Game.exe: sự kiện chuột (CInputSystem::MouseTick, 0x140212ad0)

Mỗi nhịp: vị trí cũ = vị trí nhịp trước; đọc nút bằng `GetAsyncKeyState` (đổi trái phải theo
`SM_SWAPBUTTON`); so cờ nút với nhịp trước rồi đẩy sự kiện vào hàng. Sự kiện chỉ được đẩy khi con
trỏ trong vùng chơi của cửa sổ game hoặc game đang giữ chuột, và cửa sổ không bị vô hiệu.

Số của sự kiện (bản 2026 chèn thêm kéo nút giữa ở số 5 nên từ đó lệch 1 so với bản 2008): 2 di
chuyển, 3 kéo trái, 4 kéo phải, 5 kéo giữa, 6 nhấn trái, 7 nhả trái, 8 bấm trái, 9 nhấn phải, 10 nhả
phải, 11 bấm phải, 12 nhấn giữa, 13 nhả giữa, 14 bấm giữa, 15 đến 17 bấm đúp, 18 lăn lên, 19 lăn
xuống, 20 giữ trái lặp.

- Bấm trái: nhả trong 500 ms và cách chỗ nhấn không quá 4 điểm ảnh mỗi trục. Nhả luôn có sự kiện
  nhả, kể cả khi không thành bấm.
- Bấm giữa: chỉ cần nhả trong 500 ms.
- Bấm phải: như bấm trái, và KHÔNG sinh ra khi màn chơi đang kéo camera (`CGamePro_Main+0x144`).
  Bản 2008 không có điều kiện này.
- Kéo (trái, giữa, phải): nút giữ qua hai nhịp và con trỏ dời.
- Giữ trái lặp: mỗi nhịp, khi đã giữ quá 1000 ms (`0x140f0c850`).
- Lăn: cờ do `WM_MOUSEWHEEL` đặt, nhịp sau sinh một sự kiện mỗi chiều; nhiều nấc trong một nhịp
  chỉ là một sự kiện.

## Game.exe: chuột của màn chơi (ProcessInput_Mouse, 0x14064c960)

Đầu hàm: lấy vị trí và vị trí cũ, `dx`, `dy`; tìm vật thể dưới chuột và điểm đất dưới chuột; nhịp
không có bấm trái hay bấm phải thì đặt lệnh chuột trái, phải (`MouseCommand_Set`) theo điểm đó. Rồi
duyệt sự kiện chưa bị giao diện nhận (bảng nhảy `0x14064da38`):

- Nhấn phải (`0x14064d06a`): ghi chỗ nhấn, chờ kéo.
- Kéo phải (`0x14064d0d9`): đang chờ mà lệch NGANG quá 4 điểm ảnh so với chỗ nhấn thì bắt đầu kéo:
  giữ chuột (`SetCapture`), ẩn con trỏ. Đang kéo: hướng cộng `-dx / 300`; pitch = pitch muốn trừ
  `dy / 300`, kẹp trong [`0x140fb2df8`, `0x140fb2df4`] (bỏ kẹp khi hàm ảo `+0x288` của nhân vật trả
  khác 0, chưa biết là gì), `Camera_SetPitch`; kéo con trỏ về vị trí cũ (`MouseSetPos`); dừng lệnh
  `ResetCamera` đang chạy.
- Nhấn giữa (`0x14064d08c`): giữ chuột, ẩn con trỏ. Kéo giữa (`0x14064d2a5`): pitch = pitch muốn
  cộng `-dy * 0,25` độ, kẹp như trên; kéo con trỏ về vị trí cũ.
- Nhả phải (`0x14064d48f`), nhả giữa (`0x14064d442`): thôi kéo, đặt cờ zoom tiến về đích, hiện con
  trỏ, nhả chuột.
- Nhấn trái (`0x14064d3e4`): tắt tự chạy. Giữ trái lặp (`0x14064d34b`): bật tự chạy (trừ vài hành
  động mặc định đặc biệt). Nhả trái (`0x14064d3f9`): kích hoạt lệnh chuột trái. Bấm phải
  (`0x14064d4d3`): có vật thể dưới chuột thì tắt tự chạy, rồi kích hoạt lệnh chuột phải.
- Lăn lên (`0x14064d50e`), lăn xuống (`0x14064d6bb`): đang giữ Shift thì lật trang thanh phím tắt
  chứ không zoom; `Camera_Smooth` bật: đích zoom trừ hay cộng bước lăn, kẹp [0, 1], đặt cờ tiến về
  đích; tắt: `Camera_SetZoom(TRUE hay FALSE, 2)`.

Sau vòng: nút phải không còn giữ thì thôi kéo. Đang tự chạy: con trỏ tự chạy, `Player_MoveTo` tới
điểm đất dưới chuột, mỗi nhịp.

Nhịp ra lệnh đi:

- `CCursorMng::MouseCommand_Active` (`0x14007c610`), lệnh đi (`0x14007c6cb`): chỉ nhận khi đã quá
  100 ms từ lệnh đi trước.
- `CAI_MySelf::Enter_Move` (`0x140616a00`): đang tự chạy mà lệnh trước chưa quá 500 ms thì trả mã
  chờ, lệnh nằm lại và được thử ở các nhịp sau. Không tự chạy thì không có chốt này (bản 2008 chốt
  500 ms cho mọi lệnh).

## Game.exe: camera tự động mỗi nhịp (Tick, 0x14064b39f)

1. `m_nResetCamera` khác 0: hướng cộng (thời gian nhịp tính bằng giây) nhân dấu; vượt 3,1415 thì
   đặt đúng 3,1415 và dừng. Nhịp đó không làm hai bước dưới.
2. `Camera_Smooth` bật và cờ zoom đang tiến: zoom cao hơn đích quá một bước thì trừ một bước; thấp
   hơn quá một bước thì cộng; không thì đặt đúng đích và hạ cờ. Rồi `Camera_SetPitch(pitch muốn)`.
3. `Camera_RestoreView` bật: nhân vật đang đi và trạng thái là nghỉ thì chuyển sang đang chỉnh;
   nhân vật đứng và trạng thái là "vừa kéo" thì về nghỉ. Đang chỉnh: pitch tiến
   `Camera_MoveSpeed_Auto` độ mỗi giây về `Camera_Pitch_Moving`, tới nơi thì về nghỉ.

## Dữ liệu

- `F:\tl 2026\Bin\System.cfg`: `Camera_MinDistance=6.0`, `Camera_MaxDistance=27.5`,
  `Camera_Zoom=1.0`, `Camera_Pitch=40.0`, `Camera_FOV=35.0`, `Camera_Smooth=1`,
  `Camera_RestoreView=0`, `Camera_Pitch_Min=-40.0`, `Camera_Pitch_Max=60.0`,
  `Camera_Pitch_Moving=40.0`, `Camera_MoveSpeed_Auto=30.0`, `View_DefaultCamera = 1`,
  `System_MaxFPS_Front=45`.
- `Config/SpecialSceneCamera.txt` (60 dòng): cột 1 id cảnh, 2 loại, 3 góc nhìn, 4 và 5 khoảng
  zoom, 6 bước lăn, 7 bước nhịp, 8 và 9 giới hạn pitch, 10 độ cao điểm nhìn, 11 hướng, 12 pitch, 13
  zoom, 14 câu nhắc. Dòng 1: `1, 0, 55, 2, 25, 0.1, 0.01, -40, 60, 1.5, -2.822, 10, 0.6`. 56 cảnh
  loại 2 và 3 cảnh loại 1 (id từ 712), còn lại dùng dòng 1.
- `Config/SceneDefineEx.txt` cột 16 và 17: mặt xa và mặt gần. Gần luôn là 10; xa là 15000 ở 522
  trên 680 cảnh, lớn nhất 65000. Số này đếm trên bảng DBC của `_raw` (25 cột, 680 bản ghi). Bảng
  mà client đang nạp, `CLIENT/data/Config/SceneDefineEx.txt`, là bản chữ 24 cột chỉ có 297 cảnh và
  cả 297 đều ghi mặt xa 15000 (đo 2026-10-08; chỗ lệch giữa hai bảng ở mục 20 của
  `docs/NGHI-NGO.md`).

Hệ quả ở một cảnh thường với `System.cfg` gốc: zoom 6 đến 27,5, vào cảnh ở xa nhất; pitch vào
cảnh 40 độ nhìn xuống (26 độ khi zoom gần nhất); pitch kéo được từ 60 độ nhìn xuống tới 40 độ nhìn
lên; góc nhìn dọc 35 độ; điểm nhìn cao 1,5 trên chân; mặt cắt 10 và 15000; mắt vướng địa hình thì
pitch tự dốc lên, không rút khoảng cách.

## Khác bản 2008

- Pitch do người chơi đặt (kéo phải, kéo giữa), có giới hạn; bản 2008 pitch cố định.
- Ngưỡng 4 điểm ảnh ngang trước khi kéo phải thành xoay; bấm phải không sinh khi đang kéo camera.
- Zoom mượt qua đích (`Camera_Smooth`); `Camera_GetZoom` trả phần [0, 1].
- Tự chỉnh pitch khi đi (`Camera_RestoreView`, mặc định tắt).
- Không còn phím trái phải xoay 0,04 radian: lời gọi `Camera_AddDirection` chỉ còn ở kéo phải và
  `ResetCamera`.
- Độ cao điểm nhìn 1,5 thay cho 0,7; mặt cắt lấy theo cảnh thay cho 0,25 và 150 nhân thước.
- Chốt 500 ms của lệnh đi chỉ còn khi tự chạy.
- Cách chữa mắt vướng thứ hai (sửa khoảng cách) cho các cảnh có dòng riêng.

## Dự án port thế nào

- `control::FollowCamera` là `CCamera_Scene` cùng các hàm `Camera_*`: mỗi hàm đặt gọi `update` ngay
  như bản gốc, nên nhận mặt đất. `CameraFit::kPitch` là cờ 0, `kDistance` là cờ khác 0.
- `control::MouseTicker` là `MouseTick`; `control::Pilot` là phần chuột và camera của
  `CGamePro_Main`. `Display` gom sự kiện của cửa sổ thành một mẫu chuột mỗi khung.
- `client/viewer`: màn chơi báo đang kéo camera thì cửa sổ ẩn, giữ con trỏ và kéo con trỏ về chỗ
  cũ sau mỗi lần dời.
- `client/map/book`, `client/world`: đọc hai cột mặt cắt của bảng cảnh.
- `control/char_camera.*`: camera của màn chọn và tạo nhân vật (`CCamera_CharSel`, `Render.dll`
  0x180001b30, cảnh `tl3chuangjian.Scene`): bốn track, chạy xuôi ngược, phóng. Địa chỉ và hành vi
  ghi ở mục 8 của `docs/TAO-NHAN-VAT-2026.md`.
- Kính ClientCamera của Loong (`SRC/camera`) và lưới mực nước chỉ nó dùng (`WaterCover` của
  `client/map/liquid`) đã gỡ: `_IsValidEye` của bản 2026 chỉ thử hộp ô địa hình, không dò nước.

Khác gốc có chủ đích:

- Bước zoom mượt nhân theo thời gian của khung (0,01 nhân 45 nhịp mỗi giây) thay cho 0,01 mỗi
  khung: cùng tốc độ với bản gốc ở trần 45 khung mỗi giây, không nhanh lên khi vẽ 120 khung mỗi
  giây.
- Một nút đổi trạng thái hai lần trong một khung (bấm ngắn hơn một khung) thì lần đổi thứ hai chờ
  khung sau; bản gốc đọc `GetAsyncKeyState` nên mất cú bấm đó.
- Quả cầu mắt luôn lấy mặt gần của luật; bản gốc đọc mặt gần mà lần `Update` trước đặt, chỉ khác ở
  lần đầu.
- Con trỏ ẩn khi đang kéo bằng nút phải hoặc nút giữa; bản gốc hiện con trỏ ở mỗi lần nhả nút phải
  kể cả khi nút giữa còn giữ.
- Phím mũi tên trái phải của cửa sổ vẫn xoay 0,04 radian như bản 2008; W A S D là của cửa sổ này.

Chưa port (không có đường nào trong dự án gọi tới): rung của kỹ năng; độ cao mặt đi của công trình
trong hộp ô; dòng riêng của `SpecialSceneCamera` cho 59 cảnh đặc biệt (cần xuất bảng và nối theo
id cảnh; mã `CameraFit::kDistance` đã có và có test); khoá hướng của công trình đặc biệt; phim cắt
cảnh; nới sương theo zoom (`0x180032510`); lệnh chuột lên vật thể, kỹ năng và giao diện.
