# HOST — nửa chủ của tầng C (`src/client/face/ui/script/host.{hpp,cpp}`, `windows.{hpp,cpp}`), 2026-10-15

Bổ sung cho `TANG-C.md` (do nửa widget giữ). Địa chỉ **[M]** là của `UI_CEGUI.dll` / `Game.exe` 3.71.9509.

## Đã làm

- Sổ cửa sổ: `src/client/script/windows.tsv` (1 975 dòng, `TOOLS/content/export_windows.py` đọc `Config.axp`), đưa vào
  `dev/client/assets/Script/` cùng đúng 1 975 script bằng target `thienlong_scripts` (`TOOLS/content/stage_scripts.py`); APK đóng theo
  `Script/script.files.tsv`. Bộ đọc `parse_windows` đổi `\` thành `/` (sổ gốc viết `\` ở ~590 dòng).
- `Host::open`: một máy Lua, thư viện như `LuaState::Init` trừ `loadlib`; theo thứ tự sổ: bảng `<Tên>_Env`, chạy script trong `_G` thường,
  `<Tên>_Env.this` (10 phương thức [M]), `<Tên>_PreLoad`. Layout nạp lười ở lần cần đầu (`load_window`: widget vào `<Tên>_Env`, `_OnLoad`).
- Gửi sự kiện (`post`: luật 0x180079310 và `_OnGameEvent` 0x18007b8e0), đoạn Lua của layout (`fire`), `Show`/`Hide`/`TogleShow` với
  `DemiseWindow` (loại 0..7) và `CloseAllWindow`, cửa sổ bật lên đóng khi bấm ra ngoài (`pressed`, cờ `ClickHide`), hẹn giờ `SetTimer`/
  `KillTimer` theo đồng hồ khung (`tick`), `CEArg:GetValue`, `GetChildOffset`, `CareObject` (Call `kCareObject`).
- Trần: 50 triệu lệnh Lua mỗi lời gọi ngoài cùng, 128 MiB bộ nhớ, 16 tầng gọi bảo vệ lồng nhau (đều của `lua::State`, E3), 512 dòng `notes`, 4096 hẹn giờ, 64 đối số sự kiện.
- Mọi lời gọi từ host vào Lua đi qua `lua::protect` (LuaPlus báo lỗi bằng longjmp; lỗi chạy kèm traceback); hàm C gọi từ Lua chỉ báo lỗi ở đầu hàm bằng
  `luaL_where` + `lua_concat` (không `luaL_error` vararg, không đối tượng C++ có destructor qua lời gọi có thể báo lỗi).

## Hàm toàn cục của host (nhóm C của TANG-B.md, 2026-10-15)

`SetTimer`, `KillTimer` và, đọc từ decompile `TAILIEU/GAME-EXE-2026` (địa chỉ ở comment từng hàm trong `host.cpp`): `PushEvent` (0x140255060),
`PushDebugMessage` (0x140233920), `OpenWindow` (0x140246320), `CloseWindow` (0x140246390, ép bằng boolean `true` thì đóng ngay),
`IsWindowShow` (0x140237f50), `GetCurClientSize` (0x140248ba0, không nhỏ hơn 800x600, cỡ do HUD báo qua `Host::set_client_size`).
Sự kiện đi qua hàng đợi `Call` rồi HUD đưa lại như CEventSystem; `OPEN_WINDOW`/`CLOSE_WINDOW` (0x176, 0x177) tới `Host::post` thì hiện (như `this:Show()`)
hay giấu cửa sổ mang tên ở đối số đầu. Chưa đối chiếu: nơi xử lý hai sự kiện đó trong `UI_CEGUI.dll`. `IsWindowShow` chỉ biết cửa sổ của host (bảng
port tay chưa chuyển trả false). Hình học widget (`GetWindowSize`...) đọc ô dàn trang của `Hub` qua `Screen::box` và cỡ màn qua `ItemServices::screen_box`.
Chưa có: `ScriptGlobal_Format` (0x140233f50, 2 616 lần gọi trong khảo sát), `FUN_14007af80(3)` sau `PushDebugMessage`, cờ khoá `FUN_140229d50` của `OpenWindow`.

## Khác gốc

- Hiện cửa sổ chưa nạp thì nạp trước (gốc gọi `setVisible` lên con trỏ rỗng).
- Cờ đã nạp đặt trước `_OnLoad` (gốc sau) để sự kiện đến giữa `_OnLoad` không nạp lại layout.
- Một cờ hiện cho cửa sổ gốc (gốc có hai: cờ CEGUI và `m_bShow`).
- Chưa port: âm thanh mở/đóng (cột `open_sound`, `close_sound`), cờ lớp vẽ `+0x1d8`, báo hệ hướng dẫn (vtable `0x340`), `PositionSelf` (loại 5,
  không cửa sổ nào của 9509 mang), `HyperLinkName`/`MousePosition`/`MouseClickCount` của `CEArg` (không script nào dùng).
- `KillTimer(id)` để dòng đã tắt nằm lại bảng như gốc (`KillTimer(đoạn lệnh)` vẫn xoá được); bảng chạm 2 × 4096 dòng thì bỏ dòng đã tắt.

## Nối HUD (2026-10-15)

- `ui/hud.cpp`: `Hud::State::open_host` mở host ngay sau Hub, chỉ cho các cửa sổ trong `kScripted` (`HostDesc::only`: cửa sổ ngoài danh sách
  không được nạp, nên nhóm nhường chỗ chỉ tính trong cửa sổ có mặt). Hiện `ProgressBar` và `DebugListBox` (hàm game `DataPool:GetUIColor`/
  `Check_StringCode` ở `ui/script/natives`, qua `HostDesc::natives`); bản port tay `ui/panel/progress_bar` và `debug_list_box` không còn dùng ở
  HUD (module và test còn làm bản đối chiếu thứ hai cho tới khi chuyển hết). `--ui-event "NEW_DEBUGMESSAGE|chữ"` ra đúng ba dòng như bản port tay.
- Sự kiện: `dispatch` gửi từng sự kiện của hàng đợi cho bảng port tay rồi `Host::post`; `Call::kPushEvent` của script quay lại hàng đợi.
  Nhấn trái: `MouseButtonDown`/`MouseLButtonDown` lên cửa sổ dưới chuột và `Host::pressed`; nhả: `MouseButtonUp`, và `Clicked` khi nhả
  trên chính cửa sổ đã nhấn. Chưa có: nhấn phải, `MouseEnter`/`MouseLeave`, nhấn đúp, phím, bánh xe, `OnEscape`.
- `Host::paint` ghi gốc layout đang hiện và trạng thái widget vào Deck ngay sau các bảng port tay. Layout mà host nạp thêm lúc chạy làm
  `GuiScreen::take_grown()` báo, `prepare` dựng lại Hub.
- `Host::tick` chạy `advance_widgets` (mờ dần của `SuperProgress`, vòng đời mục của `InfoList`).
- Kiểm bằng mắt: `thienlong_client --scene-id 2 --frames 60 --shot <png> --ui-event "PROGRESSBAR_SHOW|<chữ>" --ui-event "PROGRESSBAR_WIDTH|0.6"`:
  thanh vàng 60% như bản port tay (phần vẽ thiếu khung nền và chữ là của `gui::draw_progress`, `NGHI-NGO.md` mục 18).
- Nạp đầu (`bench_load.py`, 12 lượt, máy đang bận nhiều phiên): bản mới trung vị 504 ms, bản ngay trước 584 ms; không thấy host làm chậm,
  nhưng cả hai trên ngân sách 450 ms của AGENTS.md (đo 2026-10-13 là 387 ms): chưa tìm nguyên nhân, cần đo lúc máy rảnh.

## Số đo (msvc-release, i5-14600KF, 2026-10-15)

- `Host::open` trên sổ thật (1 975 cửa sổ, không native tầng B, không nạp layout): **522 ms**, 3 lỗi PreLoad, đều là hàm game chưa có:
  `YuanbaoShop` gọi `IsClassic` (method), `Memo` gọi `Lua_SetNeiGuaMemoId`, `BieYeFurnitureCreate` gọi `GetFurCreateInfo`.
- Ngân sách nạp đầu là 450 ms: nếu mở host nằm trên đường nạp đầu thì phải tách đọc tệp / dịch / chạy và/hoặc PreLoad lười (TANG-C mục 5, bước 5).
  Chưa nối HUD nên chưa nằm trên đường đó.

## Kiểm

`ui_script_host_tests` (9 ca): sổ nhận `\`, sổ thật mở được, luật gửi, nhường chỗ và cửa sổ bật lên, đoạn Lua của layout, hẹn giờ, trần lệnh,
`ProgressBar.lua` gốc qua host + widget khớp 12 khối `progress_bar_flow.tsv`. Đã chạy: msvc-release, clang ASan+UBSan; `check.py` (GCC+Clang
`-Werror`, clang-tidy) 0 lỗi. Chưa dựng bằng NDK/iOS (mã chỉ dùng C API Lua, `io::read_text`, đồng hồ khung từ ngoài).

## Còn lại

- Chuyển thêm cửa sổ vào `kScripted` theo từng cửa sổ khi hàm game của nó có (cần tầng B); khi hết bảng port tay thì bỏ `kScripted` và `only`.
- Esc, phím, nhấn phải, MouseEnter/Leave; mở host cả sổ cần PreLoad lười hoặc bytecode dựng sẵn để giữ ngân sách nạp đầu.
- Lượt đo phương thức widget còn thiếu trên 1 975 cửa sổ bằng `Missing::kRecord` của widget (cần post sự kiện + hiện từng cửa sổ).
