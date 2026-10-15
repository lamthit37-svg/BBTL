# TẦNG C — máy chủ cửa sổ giao diện chạy script gốc (bản nháp 1, 2026-10-15)

Chạy script `Interface/*.lua` nguyên văn của client 2026 trên `game_luaplus`, nối với giao diện đã có (`gui`, `ui::panel::Widgets`),
thay dần các bảng port tay. Tầng A (máy Lua) đã xong; tầng B (hàm game: DataPool, Player, Target...) do e2; tầng này là
**cửa sổ** và **đối tượng widget**. Ký hiệu: **[M]** đo trên mã máy `UI_CEGUI.dll` / `Game.exe` bản 3.71.9509 của `D:\XTLBB\Bin64`
(tháo bằng `TOOLS/port/pe_refs.py`; địa chỉ chỉ đúng bản này, bản 9001 trong `TAILIEU/GAME-EXE-2026` lệch địa chỉ), **[N]** đọc mã nguồn
client 2008 (`G:\TLBB\_ref\client\Game\Client\CEGUISystem\`, cùng dòng, không phải chuẩn), **[?]** chưa đo.

## 0. Phân việc và giao diện giữa hai nửa

- Nửa chủ (thienlong-34): sổ cửa sổ `InterfaceEx` → `Table/interfaces.tsv`, `CUIWindowMng`/`CUIWindowItem` (môi trường, `this`,
  PreLoad/OnLoad/OnEvent, RegisterEvent, Demise, đoạn Lua của layout, hàng đợi sự kiện), nối `hud.cpp`.
- Nửa widget (lane này): `src/client/face/ui/script/widget.{hpp,cpp}` — các lớp Lua của widget (`UILuaControl`) trên C API của
  `lua_State*`, ghi vào `ui::panel::Widgets` và hàng `Call`. Target `game_ui_script` (link `game_ui_panel`, `game_luaplus`, `game_luanum`, `game_core`),
  không đụng GPU, dựng được ở mọi preset; một dòng `game_layer_ui/script` trong `cmake/GameLayers.cmake`. Host (`host.cpp`, `windows.cpp`) vào chính target này.

Bản đã viết (`widget.hpp`; đối chiếu 2026-10-15), khác bản nháp ở hai trường cuối của `WindowRef` và lớp `Services`:

```cpp
namespace game::ui::script {
enum class Kind : std::uint8_t { kWindow, kProgressBar, kActionButton, kCheckButton, kListBox, kComplexWindow, kCtrlList, /* ... 22 kiểu */ };
[[nodiscard]] Kind kind_of(std::string_view falagard_type) noexcept;     // "Falagard/SuperProgress" -> kProgressBar; lạ -> kWindow
class Services {                    // phía host/game mà widget hỏi; mọi hàm ảo có mặc định
    virtual std::string icon_full_name(std::string_view icon) const;      // SetProperty("ShortImage")
    virtual std::string action_icon(std::int32_t action) const;           // SetActionItem
    virtual bool root_shown() const;                                       // cờ hiện của `this`: gốc layout = this
    virtual void set_root_shown(bool);                                     // SetFadeState <= 0 trên cửa sổ gốc
    virtual std::optional<PixelBox> window_box(std::string_view) const;    // ô trên màn hình theo lần dàn trang gần nhất (GetWindowSize, CenterWindow...); mặc định nullopt = 0
    virtual std::optional<PixelBox> screen_box() const;                    // cỡ màn hình để kẹp (AutoMousePosition, PositionSelf...); mặc định nullopt = không kẹp
};
struct WindowRef {                  // trivially copyable; sao vào userdata Lua
    panel::Widgets* store;          // Widgets của cửa sổ chủ (CUIWindowItem)
    std::vector<panel::Call>* calls;// hàng việc nhờ game (DoAction...)
    const gui::GuiAsset* asset;     // GetProperty đọc giá trị gốc của layout; cha và anh em của nút đánh dấu
    std::string_view name;          // tên cửa sổ con; host giữ chuỗi
    Kind kind;
    std::int32_t window = -1;       // chỉ số trong asset->windows; -1 thì widget tìm theo tên (chậm, sai khi hai layout trùng tên)
    Services* services = nullptr;   // null: icon giữ nguyên tên, gốc coi là đang hiện
};
void open_widget_classes(lua_State*, Missing = Missing::kRaise);  // sau khi mở state; gọi lại được, đổi được chế độ
std::vector<MissingMethod> missing_methods(lua_State*);          // chế độ kRecord: phương thức bị gọi mà chưa có (tên, số lần)
void push_widget(lua_State*, const WindowRef&);      // userdata + metatable chung; seed_hidden khi layout khai Visible=False
void advance_widgets(Widgets&, const gui::GuiAsset&, Services&, float seconds);  // nhịp thời gian: SetFadeState > 0 mờ dần rồi giấu; mục InfoList (AddInfo) già đi, mờ và bị bỏ
}
```

Điều kiện sống: `store`, `calls`, `asset`, `name`, `services` sống lâu hơn `lua_State`. Chỉ dùng C API thô (`lua.h` của LuaPlus), không phụ thuộc vỏ `lua::State` của e2.
Bảng phương thức đã viết và hàng đợi còn lại: `WIDGET-PHUONG-THUC.tsv` (125 xong, 6 của `this` thuộc host, còn lại chưa). Kiểm: `Test/Ui/ui_script_widget_tests.cpp`
(22 ca; chạy `ProgressBar.lua` và `DebugListBox.lua` gốc qua một host tối thiểu của test, khớp 12/12 khối `progress_bar_flow.tsv` và 11/11 khối `debug_list_box_flow.tsv`). Lưu ý LuaPlus 5.0.1: `luaL_checkudata` trả NULL
chứ không báo lỗi; `lua_getmetatable` chết khi ngăn xếp không có chỉ số; `lua_dobuffer` in lỗi ra stderr qua `_ALERT` (dùng `luaL_loadbuffer` + `lua_pcall`).

## 1. Client gốc nạp một cửa sổ thế nào

### 1.1 Sổ cửa sổ [M]
`Config.axp/InterfaceEx.txt` (bản 2008: DBC 801 `Interface.txt`), nhị phân DBC, đọc bằng `TOOLS/content/dbc.py`. Bản 9509: **1 975 dòng, 1 975 tên
không trùng**, cột: 0 số, 1 tên, 2 đường dẫn layout, 3 đường dẫn script (một tệp mỗi cửa sổ, dưới `Interface/`, ví dụ
`ProgressBar/ProgressBar.lua`), 4 demise (đếm: 3→748, 1→631, 0→359, 2→228, 7→5, 6→2, 4→2), 5 mã nhóm, 6-7 id âm thanh mở/đóng, 8 cờ
(-1 hoặc 1), 9 ghi chú Hán. Hàm `collect_ui.py` đã đọc bảng này (`Registry`). Client nạp **đúng một script mỗi cửa sổ** theo bảng, khác với
`mass_units` (mọi `.lua` trong thư mục).

### 1.2 Vòng đời [M, khớp 2008 [N]]
Khi khởi động `CUIWindowMng::Init` duyệt mọi dòng sổ, mỗi dòng dựng `CUIWindowItem` và gọi **PreLoadWindow** (0x180078390):
1. `NewEnvironment(tên, script)`: tạo bảng toàn cục `<Tên>_Env` (đối tượng môi trường giữ nó ở `+0x68`, hàm `GetLuaObject`).
2. `DoFile(script)` (Game.exe 0x140652d60): đọc tệp qua `loadResource("General")`, giải mã nếu là bản mã hoá (hai hàm 0x1406dcf20, 0x1406dd030), rồi `lua_dostring(nội dung)`
   **không đặt môi trường**: chạy trong **`_G`** thường (không phải trong `_Env`); hàm `<Tên>_PreLoad`, `_OnLoad`, `_OnEvent` thành hàm toàn cục.
3. Đặt `this`: userdata 8 byte giữ con trỏ `CUIWindowItem`, metatable `MetaTable_UIWindowItem`, **gán vào `<Tên>_Env.this`**.
4. `DoFunction("<Tên>_PreLoad")` (`snprintf("%s(%s);")` rồi DoString, đối số rỗng); `m_bLayoutLoaded = 0`.

**LoadWindow** (0x180077f20) chạy lười, ở lần đầu cần: `loadWindowLayout(layout)`, giấu cửa sổ gốc, thêm vào màn hình, đăng ký từng cửa sổ con
làm đối tượng widget trong `<Tên>_Env[tên cửa sổ con]` (hàm 0x1800797a0, theo `getType`: `Falagard/ProgressBar`, `ActionButton`... 20 kiểu ở 2008),
rồi `DoFunction("<Tên>_OnLoad")`; `m_bLayoutLoaded = 1`.

### 1.3 Môi trường [M] (không có ở 2008 dạng này; 2008: `SetActiveEnvironment` cùng ý)
Mọi `DoString`/`DoFunction`/timer của một cửa sổ chạy giữa hai phép đặt môi trường: trước đó `lua_dostring("setmetatable(_G, {__index = <Tên>_Env});")`
(0x140653830), sau đó đặt lại môi trường cũ **chỉ khi môi trường cũ khác rỗng**, nên môi trường cuối còn lại sau lần gọi đầu tiên. Hệ quả cho
script: tên cửa sổ con và `this` không phải biến toàn cục thật mà tra qua `__index` của `_G` khi ở trong lời gọi của cửa sổ đó; hàm của cửa sổ
A gọi thẳng hàm của cửa sổ B vẫn dùng `this`/tên con của A. Lỗi Lua trong lời gọi: `EnableLuaCrash` (biến hệ thống, mặc định 1 [M]) chọn nhánh;
nhánh bật đi qua 0x140653230 (theo 2008 [N]: bắt ngoại lệ rồi hiện hộp thoại lỗi; bản 2026 chưa tháo [?]), nhánh tắt chạy `lua_dostring` trơn. Có mã đếm lời gọi của ba chuỗi riêng (`PlayerList_ButtonClickForXuanZhan();`, `ContexMenu_PVP_Challenge_Clicked();`,
`MessageBox_Self_OK_Clicked();`) — không phải hành vi giao diện, bỏ qua.

### 1.4 Đăng ký và gửi sự kiện [M]
- `this:RegisterEvent(tên, cờ)` (0x180077be0): chỉ nhận khi đối số 2 là chuỗi; cờ là đối số 3, **boolean thì lấy, không thì mặc định true**; nếu đã nạp
  layout → lỗi `"%s Must register event in \"***PreLoad\" Function "`; tên chưa có trong bảng sự kiện của cửa sổ thì đăng ký bộ gửi 0x180079310
  với hệ sự kiện và ghi `bảng[tên] = cờ` (tên đã có thì **cờ lần đầu thắng**); tên bắt đầu bằng `UI_COMMAND` (so 10 ký tự đầu) đặt cờ `+0x184`.
- Bộ gửi 0x180079310 (một sự kiện, một cửa sổ): bỏ nếu id `0x13a` mà `+0x184` = 0. Sự kiện **có đăng ký với cờ false và cờ `+0x160` của cửa sổ bằng 0** (đọc là "đang
  ẩn": `+0x160` đứng ngay sau `m_bShow`-tương-đương, chưa đối chiếu với `Show` [?]): chưa nạp layout thì bỏ; đã
  nạp thì chỉ giữ **bản mới nhất** của hai sự kiện id `0x166` và `0x2f7` (kèm đối số) rồi bỏ; mọi trường hợp khác: nạp layout nếu chưa nạp
  (LoadWindow), phát lại hai bản đã giữ (nếu có) rồi gửi sự kiện này. (Tên hai sự kiện [?]; `ui/panel/events.hpp` mới ghi "cờ true là nhận cả lúc ẩn",
  thiếu chi tiết giữ-và-phát-lại.)
- `_OnGameEvent` (0x18007b8e0): `arg<k>` toàn cục = đối số k (chuỗi), **và** `eventTable[k+1]` (bảng toàn cục, tạo một lần, không xoá); không xoá `arg` cũ
  giữa hai sự kiện; rồi `DoFunction("<Tên>_OnEvent", "\"<SỰ KIỆN>\"")` tức `<Tên>_OnEvent("SỰ KIỆN");`.
- Đoạn Lua của layout (`<Event Name="Clicked" Function="MainMenuBar_3_Clicked(1);"/>`, 1 942 layout có, tên top: Clicked 16 505, MouseLButtonDown 1 234, MouseButtonUp
  1 221, Hidden 1 099, RBClicked 1 098): `FireUIEvent` (0x1800768b0) đặt `globals.arg0 = tên cửa sổ phát` rồi `env->DoString(đoạn)`, môi trường là của cửa sổ chủ
  tìm ngược từ cửa sổ phát qua `getParent` (cửa sổ gốc mang user data là `CUIWindowItem`). Đối tượng `CEArg` (toàn cục) có `GetValue(khoá)`; kho script chỉ
  dùng `CEArg:GetValue("MouseButton")` (193 chỗ, 91 tệp): trả `"LeftButton"`, `"RightButton"`, `"MiddleButton"`, `"X1Button"`, `"X2Button"`, `"NoButton"`.
  Không layout nào dùng `arg0` trong đoạn Lua của chính nó.
- Hàng đợi `PushEvent` đã mô hình: `ui/panel/call_events.hpp` (đo 2026-10-15).

### 1.5 `this` — 10 phương thức của `CUIWindowItem` [M tên, hành vi [N]]
`RegisterEvent`, `Show`, `Hide`, `TogleShow`, `IsVisible`, `TransAllWindowText`, `CareObject`, và **mới so với 2008**: `ClickHide`, `GetChildOffset`, `Activate`
(10 phương thức, hàm gốc bọc qua một bộ nối chung 0x18001d220). Show/Hide gọi `DemiseWindow` (loại 2, 3: đóng các cửa sổ cùng loại; 4, 6: đóng tất cả trừ 0 và 6;
5: đặt cạnh con trỏ — theo 2008 [N]; 2026 có thêm loại 1, 7 [?]). **Thuộc nửa chủ.**

### 1.6 Hàm toàn cục liên quan [M]
- `PushEvent(tên[, đối số...])`: đưa vào danh sách chờ của `CEventSystem` (xem `call_events.hpp`).
- `OpenWindow(tên)`, `CloseWindow(tên)` (Game.exe 0x140245d50, 0x140245dc0): đã có dạng `Call` (`kOpenWindow`, `kCloseWindow`).
- `SetTimer(tên cửa sổ, đoạn lệnh, ms)` trả id; `KillTimer(đoạn lệnh | id)` trả boolean. Dùng `SetTimer` của Win32 (`WM_TIMER`, không gắn với khung vẽ, hàm gọi
  lại 0x140698430, chuỗi `"LUA: TimerFunc"`). Khi nổ: môi trường `<tên>_Env`, `lua_dostring(đoạn lệnh)`, đặt lại môi trường cũ (0x140697cc0). 273 tệp script gọi `SetTimer` (grep;
  252 đơn vị trong bảng tần suất). **Đề xuất** cho client: bộ hẹn giờ theo đồng hồ trò chơi chạy ở đầu khung (Android/iOS không có `WM_TIMER`); **khác gốc** ở độ trễ phát ≤ 1 khung — nửa chủ quyết.

## 2. Đối tượng widget (`UILuaControl`) — nửa của lane này

### 2.1 Lớp [N, M]
Mỗi cửa sổ con có một đối tượng Lua (userdata + metatable); metatable gốc `MetaTable_Control_Window` (38 phương thức ở 2026 [M, `docs/GIAO-DIEN-2026.md` mục 8]), lớp con
(`ProgressBar`, `ActionButton`, `PopMenu`, `ComplexWindow`, `Minimap`, `Listbox`, `ImageListbox(Ex)`, `ImageCheckbox`, `Combobox`, `StaticImage`, `Scrollbar`,
`SuperTooltip`, `MeshWindow`, `ChatHistory`, `ChatChannel`, `SceneMap`, `WorldMap`, `InfoList`, `CtrlList`, `SoftKeyWindow`, `AnimateWindow`, ...) chồng thêm
phương thức riêng và **thừa kế Window qua `__index`**. (Ở 2008 mọi lớp con gán `*s_pMetaTable = *Window::s_pMetaTable` — cùng một bảng — nên mọi
phương thức có mặt trên mọi widget; ở 2026 là xích thừa kế. Gọi một phương thức của lớp khác lên widget không có: lỗi Lua, bỏ cả lời gọi sự kiện.)

Bảng ánh xạ từng phương thức sang `Widgets` / `Hub` / `Call` đặt ở `docs/giao-viec/LUA-GEN/WIDGET-PHUONG-THUC.tsv` (sinh khi viết mã bước 2, mỗi dòng: tên,
bậc, lớp, đối số, hành vi [M/N], hàm `Widgets` hay chỗ thiếu).

### 2.2 Ưu tiên theo tần suất (`API-TAN-SUAT.tsv`: 193 phương thức widget, 83 467 chỗ gọi)

| Bậc | Số phương thức | Phủ chỗ gọi | Phương thức (chỗ gọi/đơn vị) |
|---|---|---|---|
| P0 | 13 | 90,7% | SetText 14203/1347, RegisterEvent*, Hide, Show, SetProperty 8335/1813, GetProperty 4091/1663, IsVisible, Disable, SetCheck, Enable, SetToolTip, SetActionItem, CareObject* |
| P1 | 9 | 95,1% | GetText, Play, AddTextElement, AddTextItem, DoAction, AddNewItem, SetFakeObject, GetCheck, AddChild |
| P2 | 36 | 99,0% | SetCurrentSelect/GetCurrentSelect, RotateBegin/End(Ex), Clear, GetChildOffset*, AddItem, ClearAllElement, SetProgress, ComboBoxAddItem, Flash, ResetList, SetSelected, SetImage, GetFirstSelectItem, GetSelectItem, RemoveAllItem, AddItemElement, ... |
| P3 | 135 | 1,0% | phần còn lại; 58 phương thức chỉ có ở đúng 1 đơn vị |

(* thuộc `this`, nửa chủ.) Đếm theo tên có mặt trong chú thích `widgets.hpp` / prelude trọng tài (ước lượng, chưa đối chiếu hành vi): hiện **28 phương thức đã có hàm trong `Widgets`** (do các cửa sổ port tay cần) phủ 71,6% chỗ gọi; 12 phương thức nữa có mô hình trong prelude
trọng tài nhưng chưa có trong `Widgets` (GetProperty, GetText, AddTextElement, DoAction, SetFakeObject, PlayWarning, AddActionElement, AddMoneyElement,
AddJiaoZiElement, GetAlpha, AddInfo, GetName: 7,2%); 153 phương thức (21,2%, tính cả 10 của `this`) chưa có gì.

`SetProperty` là cửa ngõ của hơn 40 thuộc tính (đếm theo chuỗi hằng ở đối số 1, 11 345 chỗ): Image 2305, UnifiedPosition 1747, MoneyNumber 1323, UnifiedXPosition 575,
NormalImage 558, UnifiedYPosition 531, HoverImage 489, Visible 427, Timer 301, Animate 287, DefaultEditBox 284, Selected 225, PushedImage 185, Disabled 177, ...; 601 chỗ truyền
tên thuộc tính bằng biến. `SetFadeState` và `ShortImage` có xử lý riêng ([M] 0x18003f570: `ShortImage` đổi tên icon qua `IconManager::GetIconFullName` rồi đặt `Image`;
`SetFadeState` ra `Alpha` trong số vàng ProgressBar). `GetProperty` chủ yếu là hình học: UnifiedPosition 2481, UnifiedXPosition 574, UnifiedYPosition 524, AbsoluteXPosition 244,
AbsoluteYPosition 211, AbsoluteHeight 179, AbsoluteWidth 167 → cần giá trị gốc của layout (`asset`) cộng giá trị script đã đặt (`store`), chứ không phải trạng thái vẽ.

### 2.3 Lỗi và kiểm đối số
Theo [N] mỗi phương thức kiểm kiểu đối số và `return 0` im lặng khi sai (ví dụ `SetProgress` không nhận số thì không làm gì; `SetText` nhận số thì `sprintf("%d")`, nhận
chuỗi thì phân tích thẻ màu; `CareObject` sai đối số thì `TDThrow`). Mỗi phương thức khi viết đối chiếu [N] rồi [M] (hàm 2026 qua `docs/GIAO-DIEN-2026.md` hoặc tháo), ghi dòng `Khác gốc:` nếu lệch.
Lỗi Lua của lời gọi: host ghi nhật ký một dòng tiếng Việt (cửa sổ, hàm, thông điệp), bỏ lời gọi đó, không đổi môi trường (**khác gốc**: gốc hiện hộp thoại).

### 2.4 Đọc mã máy của `UI_CEGUI.dll` để port phương thức widget
Hàm Lua của mỗi phương thức là hàm đăng ký trong một hàm lớn duy nhất (9509: chứa 0x18002ba00), mỗi lời gọi đăng ký nạp con trỏ hàm
vào RCX hay RSI rồi tên vào RDX. `TOOLS/port/ghidra/DecompileAt.java` có các khoá `m:<địa chỉ trong hàm đó>` (in `0xhàm tên` theo thứ tự đăng
ký, tên lớp và `__index` xen giữa là nhãn của lớp, con trỏ đứng cạnh chúng không có nghĩa), `d:` (mọi lệnh máy của hàm, khi decompile làm
mất đối số dấu phẩy động như `lua_pushnumber(L)`), `r:` (16 byte dữ liệu: hằng số). Hàm tên phương thức đăng ký là hàm Lua thật, không phải
thunk: nó đọc đối số bằng `lua_type`/`lua_isstring`/`lua_tonumber` rồi gọi thẳng lớp CEGUI (ví dụ `Combobox::addItem`).
Hai bản mã máy cho cùng một mã: dự án Ghidra TLBB (`decompile.bat UI_CEGUI.dll ...`) và `D:\XTLBB\Bin64\UI_CEGUI.dll` 3.71.9509 (nhập vào dự án
riêng: `analyzeHeadless <thư mục> <tên dự án> -import D:\XTLBB\Bin64\UI_CEGUI.dll`, rồi `-process UI_CEGUI.dll -noanalysis -readOnly -scriptPath
TOOLS/port/ghidra -postScript DecompileAt.java <tệp xuất> <khoá>...`). Cả hai có đúng 384 tên phương thức, và 31 hàm đã port (hộp thả,
CtrlList, `SetImage`, thanh cuộn) cho bản decompile giống từng dòng sau khi bỏ địa chỉ và tên biến (địa chỉ lệch nhau vài trăm byte); chú
thích trong `widget.cpp` ghi địa chỉ 9509.

## 3. Kiểm bằng số vàng của chín cửa sổ port tay

`Test/golden/panel/*.tsv` (9 tệp: `progress_bar_flow`, `main_menu_bar_2_bar`, `main_menu_bar_3_pet`, `main_menu_bar_4_bar`, `function_bar_right_bar`, `function_bar_right_2_bar`,
`debug_list_box_flow`, `quest_log_newcomer`, `create_role_newcomer`) do trọng tài sinh: script gốc chạy trên `LuaPlus.dll` với prelude `TOOLS/port/lua_oracle.lua` (mô hình widget bằng Lua)
và `TOOLS/port/oracle/*_api.lua` (mô phỏng hàm game), kịch bản `TOOLS/port/oracle/<tên>.lua` (`__event`, `__dump`, `__dump_events`). Phép kiểm tầng C (đường mới):

1. Cùng script gốc, cùng kịch bản, cùng `*_api.lua` (đóng vai tầng B tạm), nhưng **widget là native C++** (`widget.cpp`) ghi vào `Widgets`; host thật nạp cửa sổ (PreLoad, sự kiện).
2. `__event` → đẩy sự kiện qua hàng đợi của host; `__dump(nhãn)` → `Widgets::describe` + cờ hiện của `this` + các `Call` đã nhờ; so từng dòng với khối cùng nhãn (`panel_golden.hpp`
   đã có đọc khối và so tập dòng; thứ tự dòng trong khối không tính).
3. Thứ tự: ProgressBar (chỉ 5 phương thức: `this:RegisterEvent/Show/Hide`, `SetText`, `SetProperty`, `SetProgress`) → MainMenuBar_2/3/4, FunctionBarRight(_2) (nút action) →
   DebugListBox (danh sách, `string.len`) → QuestLog (cửa sổ phức hợp, danh sách) → CreateRole.
4. Test mới `Test/Ui/ui_script_*_tests.cpp`; bỏ qua (Skipped) khi không thấy `dev/client/assets/Interface` hay thư mục số vàng, như `collision_tests`. Số vàng **không sửa tay**; lệch thì sửa native hay
   chỉ ra chỗ prelude mô hình sai (có chứng cứ mã máy).
5. Sau khi chín cửa sổ xanh, các bảng port tay (`ui/panel/*.cpp`) là mã thừa: giữ tới khi `hud.cpp` chạy cửa sổ bằng script, rồi xoá (việc nửa chủ).

Kiểm rộng (không phải số vàng): chạy **cả 1 975 cửa sổ**: PreLoad, mọi sự kiện đã đăng ký với đối số tổng hợp, trên cầu "ghi nhận" (gọi phương thức chưa có thì ghi tên, không dừng). Ra
bảng "phương thức/hàm chưa có, số cửa sổ chạm" làm hàng đợi việc theo số đo. Không có đối chứng từng byte (prelude chỉ mô hình 40 phương thức) nên không gọi là xanh/đỏ.

## 4. Chuỗi: UTF-8 hay trang mã gốc

- Client gốc giữ chuỗi Lua theo **trang mã của máy** (zh: GBK 936; có sẵn các nhánh 1251, 1252, 1254, 1258, 874, 949, ví dụ `DataPool:Check_StringCode`) và đổi ở biên widget
  (`SetText`: mbcs→utf8 qua `ParserString_Runtime`, `GetText`: utf8→mbcs, `GetProperty` cũng; [N], [M] `docs/GIAO-DIEN-2026.md` mục 8). Script dựa vào đó: 128 tệp gọi
  `strlen`/`string.len`/`strsub`/`string.sub`/`strbyte`/`string.byte` (364 chỗ cắt, 156 chỗ đo, 32 chỗ đọc byte, đo 2026-10-15), ví dụ cắt tên 8 byte, đọc `string.byte(password, i)`.
  Trên UTF-8 chữ Hán dài 3 byte thay vì 2: cắt giữa ký tự, hiển thị khác, điều kiện độ dài lệch. Trọng tài chạy UTF-8 cả hai phía nên số vàng không lộ điều này
  (`DebugListBox` port tay đã phải vá bằng "lùi tới đầu ký tự UTF-8", ghi `Khác gốc`).
- Bản sao trong repo (`src/client/script`, UTF-8) khứ hồi UTF-8→GB18030 trùng từng byte với bản gốc ở **3 128/3 173 tệp**; 45 tệp lệch vì chính tệp gốc 2026 đã chứa dòng UTF-8
  (ghi chú; đo 2026-10-15 ba tệp đầu) — nên đường chuyển trang mã **không** dựng bản chạy từ bản UTF-8 trong repo mà từ byte gốc ở gói `.axp` (công cụ gom tập lệnh như `collect_*.py`).
- **Đề xuất** (cần chủ dự án duyệt vì chạm cả tầng B của e2): một chính sách duy nhất `ScriptText` ở `lua/` với hai chế độ: `kLocal` (GBK, mặc định cho bản `zh`: chữ Lua là byte gốc) và `kUtf8` (bản
  `vi`/`en`, và mọi test/số vàng, vì trọng tài chạy UTF-8), hai hàm `to_script`/`from_script` gọi ở mọi biên: phương thức widget (lane này), hàm game trả/nhận chuỗi (e2), đối số sự kiện
  (`arg<k>`), đoạn Lua của layout (XML UTF-8 → trang mã trước `DoString`), bảng chuỗi `#{}` . Bảng GBK↔Unicode: dùng bảng riêng gọn trong repo (không
  `MultiByteToWideChar`: Android/iOS không có). Ngay bây giờ lane này **viết biên một chỗ** (`script_text.hpp`) và để chế độ mặc định `kUtf8` đến khi được duyệt; đổi chế độ là đổi một hằng.

## 5. Kế hoạch từng bước (mỗi bước kết thúc bằng build + ctest xanh, báo hash)

1. **(nửa chủ + lane này)** ProgressBar chạy script gốc trong test: host tối thiểu (môi trường, `this`, PreLoad, RegisterEvent, OnEvent) + `Window`/`ProgressBar` native (P0: `SetText`, `SetProperty`, `Show`, `Hide`, `SetProgress`) → khớp `progress_bar_flow.tsv`.
   Việc của lane này: `widget.{hpp,cpp}` khung lớp + `Window` cơ sở (SetText/GetText/SetProperty/GetProperty/Show/Hide/IsVisible/Enable/Disable/SetToolTip/...) trên `Widgets`, `ProgressBar::SetProgress`, test dùng host giả ở lúc chưa có nửa chủ.
2. Toàn bộ P0 + bảng `WIDGET-PHUONG-THUC.tsv`; nút action (`SetActionItem`, `SetCheck`, `SetPushed`, `Gloom`, `Bright`, `DoAction`) → MainMenuBar_2/3/4, FunctionBarRight(_2).
3. Danh sách và cửa sổ phức hợp (`AddItem`, `ClearListBox`, `AddTextElement`, `AddActionElement`, ...) → DebugListBox, QuestLog; CreateRole (kèm hàm `GameProduceLogin` ở tầng B).
4. P1, P2 (MeshWindow `SetFakeObject`/`Rotate*`, `PopMenu`, `Combobox`, `ComplexWindow`, `Minimap`, `SceneMap`/`WorldMap`...); chạy 1 975 cửa sổ trên cầu "ghi nhận", cập nhật hàng đợi.
5. Chế độ chuỗi (mục 4) theo quyết định của chủ dự án; đo thời gian khởi động: nạp mọi PreLoad lúc đầu (gốc làm thế; 26,6 MB nguồn dịch 320 ms) so với PreLoad lười theo sự kiện (cần danh sách sự kiện tính sẵn: `__dump_events` của trọng tài đã có).
   Ngân sách nạp đầu `≤ 450 ms` (AGENTS.md) quyết định có cần lười hay không; không làm khi chưa có số.
6. P3 theo hàng đợi đo ở bước 4; xoá bảng port tay khi `hud.cpp` chạy bằng cửa sổ script (nửa chủ).

## 6. Còn mở [?]

- `DemiseWindow` 2026 (loại 1, 7, 2, 3, 4, 6, 0), `CloseAllWindow`, `OnEscape` — nửa chủ tháo.
- Tên hai sự kiện id `0x166` và `0x2f7` (được giữ-và-phát-lại), ý nghĩa cờ `+0x180` của `CUIWindowItem`, và `+0x160` đúng là cờ hiện hay không.
- Tập đối tượng thật của 38 phương thức `MetaTable_Control_Window` và bảng phương thức từng lớp con ở 2026 (`build/scratch/gui/lua_methods.txt` đã mất cùng `build/`): tháo lại bằng
  `pe_refs.py` quanh `UI_CEGUI.dll` 0x180027930..0x18003faba khi viết bước 2.
- Bộ nối hàm toàn cục `PushEvent`/`OpenWindow`/`CloseWindow` cho bản "ghi nhận" của bước 4 (dùng lại `Call`).
- Nhật ký lỗi Lua và cách báo người chơi (gốc: hộp thoại): chưa có yêu cầu, mặc định ghi nhật ký.
