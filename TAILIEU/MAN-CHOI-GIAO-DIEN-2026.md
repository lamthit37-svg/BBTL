# Giao diện màn chơi của client 2026 — con trỏ, bản đồ, bản đồ thế giới, hòm đồ, xoay người mẫu, mặt đất

Đo từ mã máy `Game.exe`, `UI_CEGUI.dll`, `CEGUIFalagard.dll`, `CEGUIBase.dll` (client 3.71, `F:\tl 2026\2026\Bin64`) và script Lua đã giải ở
`build/lua-2026/Interface/**`. Bản decompile thô làm bằng chứng nằm ở `TAILIEU\ghidra\` (tên tệp ghi ở mỗi mục). Cách lấy lại:
`TOOLS\port\ghidra\decompile.bat <chương trình> <tệp ra> 0xĐịaChỉ...` và `python TOOLS/port/pe_refs.py <pe> func|refs|text|rtti|exports ...`.

## 1. Con trỏ chuột (`ghidra\con-tro-game.txt`, `con-tro-game-2.txt`)

- 22 con trỏ nằm TRONG `Game.exe` dưới dạng tài nguyên `RT_CURSOR` / `RT_GROUP_CURSOR`, không phải tệp rời. `CCursorMng::Initial`
  (`0x14007b2d0`) gọi `LoadCursorA` 23 lần với id nhóm `0x7f00` (mũi tên hệ thống, không có trong exe), `0x81`, `0x9b`, `0x82`... và cất tay
  cầm ở `this + 0x30 + 8 * i`; thứ tự `i` trùng thứ tự `control::CursorKind` của dự án (system, normal, normal_down, attack, auto_run, pick_up,
  unreachable, mine, herbs, fish, speak, interact, repair, hover, identify, add_friend, exchange, catch_pet, scroll, cabinet, house, bow, bow_down).
- `CCursorMng::GetCursor` (`0x14007b550`) chỉ xét chỉ số con trỏ và `GetAsyncKeyState` của nút chính: đang giữ nút chính thì dùng bản "đang nhấn"
  của con trỏ, cả khi con trỏ đang nằm trên cửa sổ giao diện.
- Công cụ xuất: `python -B TOOLS/content/export_cursors.py "F:/tl 2026/2026/Bin64/Game.exe" dev/client/assets` → `Interface/cursor/cursors.tsv` và
  `<loại>.ttex` (RGBA8, 32 x 32). Chạy lại được; `--check` chỉ kiểm.

## 2. Bản đồ lớn của cảnh — `FalagardSceneMap` (`ghidra\ban-do-canh.txt`)

- Địa chỉ trong `CEGUIFalagard.dll`: `UpdateAllWindow 0x1800c73b0`, `SetViewByCenter 0x1800c70f0`, `updateSelf 0x1800cac80`, `onMouseButtonDown
  0x1800c97a0`, `onMouseMove 0x1800c99e0`, các hàm cuộn `0x1800c6dd0..0x1800c6e60`, hằng cuộn 0,01 ở `0x18012fe04`, thời gian chờ 5 giây ở
  `updateSelf`. Chi tiết công thức (chế độ 0/1/2, kẹp, cuộn, kéo, toạ độ dưới chuột) ở đầu `src/client/face/ui/panel/scene_board.hpp` và
  `src/client/face/gui/radar.cpp`.
- Kéo bằng nút phải (`drag_by_pointer`), nút trái nhấp không kéo quá 5 điểm ảnh thì đi tự động tới điểm đó (`SceneMap_GotoDirectly` →
  `AutoRunToTarget`). Sau khi cuộn hay kéo, tâm bản đồ chờ 5 giây rồi mới theo người chơi lại.

## 3. Bản đồ thế giới — `FalagardWorldMap` (`ghidra\ban-do-the-gioi-widget.txt`, `ban-do-the-gioi-lua.txt`)

- Layout: `Interface/LargeMap/LargeMap.layout.xml`, widget `LargeMap_Frondground` kiểu `TLBB_WorldMap` → `Falagard/WorldMap`, `BackgroundName WorldMap`,
  `BackgroundSize w:5 h:4`. Script: `LargeMap.lua` (`LargeMap_Show`, `LargeMap_Click_NormalScene` mở bản đồ cảnh của `CurrentScene`).
- Nền: `createBackground` (`CEGUIFalagard.dll 0x18008b200`) dựng lưới 5 x 4 ô 256 x 256 (hằng `0x18013a820` = 256,0), ô thứ n đọc từ
  `LargeMap/jpg_WorldMap%02d.dds`. Ảnh ghép rộng 1280, cao 1024. Công cụ ghép: `python -B TOOLS/content/export_worldmap.py dev/client/assets`
  → `Interface/LargeMap/WorldMap.png`.
- Cuộn: `updataBackground` (`0x18008ea20`): nền to hơn cửa sổ thì độ lệch kẹp trong [cửa sổ − nền, 0], nhỏ hơn thì ở giữa. Kéo bằng NÚT PHẢI:
  `onDrapStart 0x18008dcd0` nhớ chuột và độ lệch, `onDrapMove 0x18008dc10` đặt độ lệch = lúc đầu + độ dời chuột, `onDrapEnd 0x18008dc00`.
  Độ lệch ban đầu (0, 0): mở lần đầu ở góc trên trái.
- Thành phố: `InitWorldMap` (`UI_CEGUI.dll 0x180027950`) duyệt bảng cảnh (`Config/SceneDefineEx.txt`), lấy dòng có CỘT 24 bằng loại bản đồ
  (0 là thế giới thường) và chỗ đặt nút khác (0, 0): cột 11, 12 là toạ độ nút, cột 13, 14 là toạ độ nhãn (điểm ảnh trên ảnh 1280 x 1024), cột 17
  là loại nút (`Sign5`...; `CityImageNormal` và `CityImageHover` của layout khoá theo loại này), cột 18..21 là bộ ảnh và ảnh của nhãn, cột 22 là
  chữ tooltip. 91 dòng loại 0 có chỗ đặt.
- Mỗi thành là hai cửa sổ ảnh (`createNewCity 0x18008c320`: nhãn `city_%d_Name_Window`, nút `city_%d_Flag_Window`), cả hai `HookMode 9` = Center
  (`hookModeToString 0x18005e5d0`: 1 Left, 2 Right, 3 Top, 4 Bottom, 5 LeftTop, 6 LeftBottom, 7 RightTop, 8 RightBottom, 9 Center), nên TÂM ảnh nằm
  đúng toạ độ cột 11..14. Dấu "tôi đang ở đây" (`MySelfImage`) đặt ở chỗ nút của cảnh người chơi đứng.
- Ảnh nhãn: vtable `0x180126ea8`: slot `0x30` là `setCityNameNormalImage` (ghi `+0x128`, nhận cột 18, 19), slot `0x38` là `setCityNameHoverImage`
  (ghi `+0x120`, nhận cột 20, 21). `resetWorldMap` (`0x18008dd50`) và `SetCityHover` (`0x18008aab0`) đặt lên cửa sổ nhãn ảnh ở `+0x120`, tức ảnh
  "khi trỏ" luôn, cả khi không trỏ; ảnh "thường" (`+0x128`) không còn chỗ nào đọc. Bản port vẽ đúng theo đó.
- Nút đổi ảnh khi trỏ (`cityHover 0x18008ae40` đặt ảnh hover, `cityNormal` đặt lại); nhấp trái (`onClick 0x18008db00`) bắn `NormalSceneClicked` trừ
  phó bản (`isCopyScene 0x18008d900`: cảnh 36, 37, 38, 61, 66, 168, 234, 280). `getCurrentSelectScene` trả thành đang trỏ (`this + 200`).
- Chưa làm: tooltip (`setCityInfo`), bạn bè (`UpdateWorldMap` ghi người chơi vào thành), đối địch (`SetCityInHostile`, `RedSword`), cờ chỉ huy, thông tin
  bang chiếm (`InitWorldMap` với `Get_XParam_*`): đều cần dữ liệu máy chủ.

## 4. Hòm đồ (Packet) và ô tiền — `ghidra\o-tien.txt`

- `Packet.lua`: `IsClassic = 1` thì chiều cao khung = số hàng * 35 + 278. Ô khoá hiện ảnh khoá (`CommonFrame38`).
- `FalagardMoney`: số tiền chia vàng = số / 10000, bạc = (số % 10000) / 100, đồng = số % 100; vàng chỉ hiện khi dương, bạc khi bạc hay vàng dương,
  đồng luôn hiện; mỗi phần là số rồi icon (`GoldIcon`, `SilverIcon`, `CopperIcon`), chạm đáy cửa sổ; `AlignFix` đệm bạc và đồng cho rộng hai chữ số.

## 5. Xoay người mẫu của bảng nhân vật

- `SelfEquip.lua`: `SelfEquip_Modle_TurnLeft(start)` / `TurnRight` gọi `SelfEquip_FakeObject:RotateBeginEx("Player", ∓0.3)` lúc nhấn trái, `RotateEndEx()` lúc
  nhả hay mất capture. `RotateBeginEx` (`UI_CEGUI.dll`, hàm bọc ở `0x180032df0`) NHÂN đối số với 0,5 (`0x180032e51`) rồi gọi vtable `+0x90` của
  `CFakeObjSystem` (`Game.exe 0x1402103e0`), hàm này ghi tốc độ vào đối tượng ở `+0x78` và gọi engine `[vtable + 0x498](tên, tốc độ, 1)`; `RotateEndEx`
  (`0x140210560`) gọi cùng chỗ với (tên, 0, 0). Đơn vị tốc độ trong engine chưa đọc (`docs/NGHI-NGO.md`): bản port coi là vòng mỗi giây, cùng thang với
  `ModelRotBegin` của màn tạo nhân vật.

## 6. Phông chữ có dấu tiếng Việt

- `GBK12.bin` (宋体 12, trang mã 936) có BẢN GHI cho các mã Latin mở rộng của tiếng Việt nhưng đó là ô giữ chỗ (hình ô vuông), không phải chữ: chữ có
  dấu ra ô vuông. `VTNAM14.bin` (Tahoma 14, trang mã 1258) có đủ chữ Việt (776 glyph, khối `U+1EA0..U+1EF9`, `Ơ ơ Ư ư Đ đ Ă ă`) nhưng không có chữ Hán.
  Bản port giữ GBK12 cho văn bản gốc và vẽ cả một run bằng VTNAM14 khi run có chữ Việt có dấu mà VTNAM14 vẽ trọn được (`Painter::add_text`).

## 7. Mặt đất của cảnh (nướng ảnh cọ)

- Bản gốc vẽ từng ô địa hình bằng GPU: hai lớp cọ (pixmap con của ảnh cọ), lớp phủ hòa theo alpha, nhân lightmap; ảnh cọ lọc có mip.
  Bản port nướng cả mặt đất thành MỘT ảnh (`client/map/surface.cpp`): tám điểm ảnh mỗi ô khi cạnh nướng tối đa là 4096 (PC; điện thoại 2048 thì bốn),
  lấy mẫu tam tuyến từ chuỗi mip của cọ (mức = log2 số điểm ảnh cọ mà một điểm ảnh nướng phủ). Lấy mẫu "điểm gần nhất" cũ biến hoạ tiết mịn (hoa văn
  rồng giữa sân Lạc Dương) thành nhiễu màu. Chi tiết của đá chạm lớn vẫn thấp hơn bản gốc (vẽ theo ô ở độ phân giải màn hình): cách làm đủ là shader mặt
  đất nhiều lớp (`docs/NGHI-NGO.md`).

## 8. Hiệu ứng (hệ hạt) của cảnh

- Thư viện hiệu ứng của client chỉ gom phần các cảnh đã gom gọi tới: sau khi `collect_map.py` gom một cảnh phải chạy
  `python -B TOOLS/content/collect_fx.py "F:/tl 2026/_goc" "F:/tl 2026/_cook" dev/client/assets` (không nêu cảnh thì lấy mọi `Scene/*.Scene`). Thiếu bước này
  thì tên hệ hạt của cảnh mới "không có trong thư viện" và biến mất (đo 2026-10-13: Lạc Dương bỏ 112 trên 168 chỗ đặt, mất đào, mây, đuốc, lá).
- Đã thêm `SequenceFrame` (phát ô stacks x slices của ảnh hạt: nến ở cảnh đăng nhập), `DirectionRandomiser` (lửa rung) và kiểu trộn
  `zero one_minus_src_colour` (khói, vẽ thành trộn alpha thẳng của màu đen với alpha là độ sáng ảnh).
