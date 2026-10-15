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
- Trần: 50 triệu lệnh Lua mỗi lời gọi ngoài cùng (móc đếm mỗi 1000 lệnh), 512 dòng `notes`, 4096 hẹn giờ, 64 đối số sự kiện.
- Mọi lời gọi từ host vào Lua đi qua `lua_cpcall` (LuaPlus báo lỗi bằng longjmp); hàm C gọi từ Lua chỉ báo lỗi ở đầu hàm bằng
  `luaL_where` + `lua_concat` (không `luaL_error` vararg, không đối tượng C++ có destructor qua lời gọi có thể báo lỗi).

## Khác gốc

- Hiện cửa sổ chưa nạp thì nạp trước (gốc gọi `setVisible` lên con trỏ rỗng).
- Cờ đã nạp đặt trước `_OnLoad` (gốc sau) để sự kiện đến giữa `_OnLoad` không nạp lại layout.
- Một cờ hiện cho cửa sổ gốc (gốc có hai: cờ CEGUI và `m_bShow`).
- Chưa port: âm thanh mở/đóng (cột `open_sound`, `close_sound`), cờ lớp vẽ `+0x1d8`, báo hệ hướng dẫn (vtable `0x340`), `PositionSelf` (loại 5,
  không cửa sổ nào của 9509 mang), `HyperLinkName`/`MousePosition`/`MouseClickCount` của `CEArg` (không script nào dùng).
- `KillTimer(id)` để dòng đã tắt nằm lại bảng như gốc (`KillTimer(đoạn lệnh)` vẫn xoá được); bảng chạm 2 × 4096 dòng thì bỏ dòng đã tắt.

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

- Nối `hud.cpp`: `Screen` trên `GuiLoader`/`Hub` (`offset`, `hits` từ lần dàn trang gần nhất), đưa sự kiện/click/Esc/đồng hồ khung, thay bảng port tay từng cửa sổ.
- Tầng B qua `HostDesc::natives`; chuyển sang `lua::State` của E3 (trần bộ nhớ, móc lệnh, pcall có traceback).
- Lượt đo phương thức widget còn thiếu trên 1 975 cửa sổ bằng `Missing::kRecord` của widget (cần post sự kiện + hiện từng cửa sổ).
