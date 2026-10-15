# LUA-GEN tầng B — API game mà script gọi: khảo sát và thiết kế (thienlong-e7, 2026-10-15)

Trạng thái (2026-10-15): phần khảo sát (mục 1, 3-6) còn đúng; phần thiết kế phía C++ (mục 2: module `gameapi`, `vm.hpp`, `GameHost`,
`raise_error`) đã THAY bằng cách làm ở mục 8: LuaPlus gốc chạy thẳng, hàm game là hàm C (`lua_CFunction`) viết theo
`src/client/face/lua/native.hpp`, đăng ký qua `open_natives`. Mục 8 là hiện trạng; đọc mục 2 như lịch sử. Mọi số dưới đây đo lại
được bằng `python -B TOOLS/port/luagen/api_survey.py --layouts <Interface của cây chính>` (đo 2026-10-15); chỗ nào chưa đo ghi ở mục 6.

Nguồn: `docs/giao-viec/LUA-GEN/API-TAN-SUAT.tsv`, `TAILIEU/GAME-EXE-2026/` (decompile, `lua_api.tsv`, `classes.tsv`, `packets.tsv`,
disasm), script ở `src/client/script/Interface`. Bản trích là `Game.exe` 9001 (`D:\rea\work\client\Game.exe`); script là của 3.71.9509.
Độ lệch hai bản đo được ở mục 6.

## 0. Tóm tắt để duyệt

1. Cơ chế của Game.exe đồng nhất và đơn giản: 6 055 hàm (1 025 hàm toàn cục + 5 030 hàm trong 119 bảng), mỗi hàm là một hàm C
   cùng một kiểu `int fn(đối tượng, LuaState**)` đọc đối số bằng Lua C API và đẩy kết quả. Trạng thái client nằm trong khoảng
   bảy singleton toàn cục (mục 1.4). Không có gì ở đó đòi hỏi closure có upvalue: upvalue duy nhất của Game.exe là con trỏ hàm
   mà bộ nhảy dùng, một chi tiết của C++ (mục 1.1).
2. `host.hpp` cần thêm MỘT hàm bắt buộc, `raise_error`, và MỘT hàm nên có, `set_metatable` (chữ ký ở mục 2.4). Không thêm
   `Type::kUserdata` ở giai đoạn 1: đối tượng "action" (83 native trả nó) mô phỏng bằng bảng có bảng meta, vì không script nào
   dùng chữ `userdata` (0 trong 2 043 tệp). Closure native có upvalue: không cần; chữ ký dự phòng ở 2.4 nếu về sau cần.
3. Phần "thuần" nhỏ hơn dự kiến: chỉ 363 trên 6 055 native không chạm biến toàn cục ghi được và không gọi hàm nào khác. Trong
   60 hàm đầu chỉ `SystemSetup:IsClassic` (luôn trả 1) là thuần thật; `OSAPI:GetTickCount` chỉ phụ thuộc đồng hồ. Phần lớn đọc `CDataPool` (2 428 hàm một mình, thêm các tổ
   hợp) hay `CObjectManager`: dữ liệu mà máy chủ cấp, client mới chưa có (mục 3).
4. 722 native (12%) gửi gói tin hay chạm `CNetManager`; protocol hiện không có tin nào cho `ExecuteScript` (catalog không có chữ
   `script`, `event`, `xparam`). Offline-first thì chúng ghi vào một hàng đợi ra (`Outbox`), không mở socket.
5. Quy mô: 60 hàm đầu chỉ làm cho 33,6% đơn vị (cửa sổ) chạy trọn; 50% đơn vị cần 578 hàm, 90% cần 2 715, 100% cần 5 349 tên
   (mục 4). Port tay từng hàm theo tần suất sẽ kéo dài; cần cách làm theo lô (mục 4).
6. Đối soát tầng B bằng Game.exe chạy thật CHƯA đo được. Đề xuất ba bậc (mục 5); bậc có số vàng từ mã máy chạy được ngay.

Việc cần duyệt: (a) `raise_error` và `set_metatable` vào `host.hpp`; (b) module mới `gameapi` và tầng của nó (2.1); (c) chính sách
hàm chưa port (2.3); (d) bậc đối soát (mục 5).

## 1. Cơ chế của Game.exe (đo trên bản trích 9001)

### 1.1 Đăng ký

- Một hàm lớn `0x1406557c0` (decompiler bỏ cuộc; chỉ có `disasm/0x1406557c0.asm`) đăng ký 5 807 hàm, 18 hàm nhỏ đăng ký phần
  còn lại (`lua_register.tsv`). Với mỗi bảng nó tạo `LuaObject` bằng `GetGlobals().CreateTable(tên)` rồi
  `SetObject("__index", chính nó)` (18 hàm nhỏ: đọc thẳng ở decompile; hàm lớn cùng khuôn theo disasm quanh
  `0x14065eeb1`..`0x14065ef18`, chưa đối chiếu từng lời gọi), rồi gọi `LuaObject::Register`.
- Mọi hàm của bảng đi qua cùng một cặp: `FUN_140686f20(bảng, tên, hàmThật)` tạo `lua_newuserdata(8)` giữ con trỏ `hàmThật` làm
  upvalue duy nhất và gọi `Register(bảng, tên, FUN_140686e10, 1)`; `FUN_140686e10` là bộ nhảy lấy userdata ấy, tìm đối tượng
  chủ và gọi `hàmThật(đối tượng, LuaState)`. Có bốn biến thể bộ nhảy (`0x140686f20`: 4 543 hàm, `0x140686e10` thành viên: 261,
  `0x140686ec0`: 67, `0x140686e60`: 21) và 1 020 hàm toàn cục đăng ký "C trần" (không bộ nhảy).
- Đối tượng chủ do `FUN_140293c00` lấy từ đối số 1: userdata thì con trỏ trong nó; bảng thì userdata ở trường `__object`.
  Các hàm đã đọc (60 mục ở mục 3) bỏ qua đối tượng chủ và dùng biến toàn cục.
- 84 hàm của `Player`, `Target`, `CachedTarget` chỉ là "chuyển tiếp ô ảo N": nhảy vào ô ảo N của đối tượng thuộc lớp
  `SCRIPT_SANDBOX::PlayerMySelf` (79 ô), `::Character` hay `::CachedCharacter` (21 ô). `lua_api.tsv` ghi địa chỉ của bộ chuyển
  tiếp (vd `Player:GetData` là `0x140687cc8`, không có decompile); hàm thật là ô ảo trong `classes.tsv` (vd ô 21 là `0x140387360`).
  Cùng chỗ: `Helper:*` ghi địa chỉ bộ nhảy `0x140653b70`, hàm thật là con trỏ trong userdata (`GotoHelper` là `0x140652640`).
- 120 bảng, hàm nhiều nhất: `DataPool` 1 207, `Pet` 332, `Player` 217, `PlayerPackage` 172, `Exterior` 159, `LifeAbility` 150.

### 1.2 Chữ ký và quy ước đối số

- Hàm toàn cục: `fn(LuaState** s)`; `*s` là `lua_State*`, đối số thứ i ở chỉ số i (từ 1). Hàm trong bảng: `fn(đối tượng,
  LuaState** s)`; chỉ số 1 là `self` (bảng gọi bằng `:`), đối số đầu của script ở chỉ số 2.
- Kiểm kiểu khác nhau và quan trọng: `lua_type(L,i) == 3` là kiểu số NGHIÊM (chuỗi số như `"5"` không qua); `lua_isstring`
  nhận cả chuỗi lẫn số; `GetString` ép số thành chuỗi theo `lua_tostring`. `lua_tonumber` ép chuỗi số.
- Trả về: `return N` với N là số giá trị đã đẩy (0, 1, hiếm 2). Nhiều hàm "đúng/sai" đẩy SỐ 1/0 chứ không đẩy boolean
  (`IsClassic`, `PlayerPackage:IsLock`, `CheckPhoneMibaoAndMinorPassword`...): trong Lua số 0 là TRUE, nên mã port phải đẩy
  đúng kiểu (`lua_pushboolean` chỉ ở 101 hàm).
- Số vào hàm C ép `(int)` bằng `cvttsd2si`: ngoài miền int32 hay NaN ra `INT32_MIN`. Cần hàm ép dùng chung khớp (như
  `xor_operand` trong `ops.cpp` đã làm cho 64 bit).

### 1.3 Lỗi

- 3 460 hàm gọi `tThrowStringException("LUA: Lua_X Wrong Param")` khi sai kiểu đối số, 1 021 hàm gọi
  `tThrowAssertException(tệp, dòng, "pMyself")` khi thiếu trạng thái (vd `Player:GetLevel` khi chưa có người chơi). Cả hai là
  NGOẠI LỆ C++ (`_CxxThrowException`), không phải `lua_error`; sau chúng không còn dòng nào chạy.
- `LuaPlus.dll` báo lỗi Lua bằng `setjmp`/`longjmp` (imports `_setjmp`, `longjmp`) và cũng có `_CxxThrowException`,
  `__CxxFrameHandler3`; script chạy bằng `lua_dostring` (`Game.exe` không nhập `lua_pcall`). Hệ quả: lỗi của hàm game là
  ngoại lệ lan lên nơi gọi script chứ không bị `pcall` của script bắt. Không đổi gì cho port vì 0 trong 2 043 tệp script dùng
  `pcall` hay `xpcall` (đã quét).
- Port: `raise_error(state, message)` đúng câu của Game.exe (không tiền tố `chunk:dòng:`), rồi trả `Results` rỗng. Việc dừng
  trình xử lý script là việc của chủ (tầng C), như khi lỗi runtime thường.

### 1.4 Trạng thái client mà hàm chạm tới

Chủ của từng biến toàn cục suy ra từ hàm gán nó (vftable của lớp trong hàm khởi tạo). Đếm số native (trên 6 055) chạm nó:

| Biến | Lớp | Native chạm (riêng một mình) | Vai trò trong client mới |
|---|---|---|---|
| `DAT_141034c40` | `CDataPool` | 2 428 | dữ liệu do máy chủ cấp: túi, nhiệm vụ, bảng xếp hạng, XSCRIPT. Chưa có một chỗ chung; phải chia theo module (mục 3) |
| `DAT_14103db40` | `CObjectManager` | 426 | đối tượng thế giới (người chơi chính ở `+0xb8`, NPC, quái). Client mới chưa có |
| `DAT_141035fd8` | `CEventSystem` | 331 | bus sự kiện: tầng C (`RegisterEvent`/`PushEvent`) |
| `DAT_14103e690` | `CUISystem` | 45 | quản lý cửa sổ: tầng C |
| `DAT_14103d490` | `CNetManager` | 230 | gửi gói: `Outbox` |
| `DAT_141034678` | `CActionSystem` | 128 | ô hành động (thanh phím, túi, kỹ năng): module `skill` có `actions.hpp` |
| `DAT_14103f8b8` | `CScriptSystem` | — | hẹn giờ, chạy script |

Không singleton nào: 1 481 hàm (gồm các hàm chỉ chạm biến khác chưa đặt tên: `DAT_141034c10` giữ kho nhiệm vụ ở `+0x28` và
chuỗi hướng dẫn tân thủ ở `+0x550`, `DAT_141040c98` là bộ quản lý cảnh, `DAT_14103e6a8` là cơ sở dữ liệu bảng; chưa xác nhận
lớp). Hàm tổ hợp lớn nhất: `CDataPool+CObjectManager` 185, `CDataPool+CNetManager` 126, `CDataPool+CEventSystem` 83.

### 1.5 Đối tượng action

83 native tạo `lua_newuserdata(8)` (con trỏ `CActionItem`), gắn bảng meta chung `DAT_141034670` (`SetMetaTable`) rồi đẩy nó, vd
`DataPool:CreateActionItemForShow(loại, id)` trả (handle, boolean). Bảng meta ấy gần chắc là chủ của `ActionButtonMetaTable` (76
hàm: `GetID`, `GetName`...; suy ra, chưa đọc chỗ dựng nó), đó là phần lớn các cuộc gọi "other" (mục 3b). Script chỉ truyền handle cho widget
(`SetActionItem`) và gọi phương thức của nó.

### 1.6 Sự kiện

`CEventSystem` đặt tên sự kiện trong hàm khởi tạo tĩnh `0x140a10cd0` (cũng chỉ có disasm): trích được 649 cặp (id, tên), vd
`0x85 NEW_DEBUGMESSAGE`, `0x176 OPEN_WINDOW`, `0x177 CLOSE_WINDOW`. Hàm game đẩy sự kiện bằng id (`vslot 0xd8`) hay bằng tên
(`PushEvent`, `FUN_1401fce10`). Bảng đầy đủ: chạy `api_survey.py` (in vài dòng) hay mở rộng thành tệp nếu duyệt.

## 2. Thiết kế phía C++

### 2.1 Module và tầng

Module mới `gameapi` (`game::api`, thư mục `src/client/face/gameapi/`), tầng ngay trên `lua`: `set(game_layer_gameapi "core table lua
hero quest skill gameapi")`. Nó không biết `gui`, `ui`, GPU: giữ thử được ở mọi preset như `hero`. Phần nối với cửa sổ (tầng C)
cài các cổng của nó. `ui/panel` hiện dùng `lua` cho `lua_value`; sau này `gameapi` đứng cạnh.

### 2.2 GameHost và cổng dịch vụ

```
class GameHost final : public lua::Host {        // set_host(state, &host) lúc dựng State
public:
    explicit GameHost(Ports ports);               // Ports: tham chiếu tới các cổng dưới, do client dựng
    ...
};
struct Ports {                                    // mỗi cổng là lớp trừu tượng nhỏ; test cài bản giả
    hero::Hero&   hero;                           // Player:* (đã có)
    quest::Log&   quest;                          // mission/flag (module quest, `book/quest/log.hpp`)
    skill::Book&  skill;                          // kỹ năng; skill::Actions cho ô hành động (module skill)
    Package&      package;                        // túi: PlayerPackage:* (chưa có module)
    World&        world;                          // CObjectManager: id server <-> client, cảnh hiện tại (chưa có)
    Events&       events;                         // PushEvent, hẹn giờ, cửa sổ: tầng C cài
    Outbox&       outbox;                         // XSCRIPT, di chuyển: hàng đợi ra; protocol chưa có tin
    Clock&        clock;                          // GetTickCount, giờ máy chủ: tiêm được để test tất định
};
```

Hàm game lấy ngữ cảnh bằng một hàm của `gameapi`: `GameHost& game(lua::State&)` (kiểm `dynamic_cast` một lần ở bước dựng,
sau đó `static_cast`). `host()` trả `Host*` sẵn có; `lua::Host` giữ nguyên (lớp rỗng, không thêm hàm ảo).

Mỗi hàm là `lua::Results fn(State&, const Function&, Args)` (kiểu `Body` có sẵn) trong `constexpr lua::Proto`, một tệp cho mỗi
bảng Lua lớn (`player.cpp`, `datapool_*.cpp`...). Trạng thái cục bộ không cần cổng: bộ đệm XSCRIPT/XParam là một struct trong
`GameHost`.

### 2.3 Đăng ký, hàm chưa port

- Bảng tên → hàm sinh từ `lua_api.tsv` (công cụ ở `TOOLS/port/luagen/`, tệp sinh vào cây dựng, như mã sinh của `luagen`):
  `{bảng, tên, địa chỉ impl}` cho cả 6 055 hàm. Dựng bảng Lua: `new_table`, `set_index(bảng, tên, native(state, proto))` (đều có
  sẵn ở `vm.hpp`/`host.hpp`), rồi `put_global`. Các tên đăng ký hai lần hay đè (56 + 4 dòng của `lua_api.tsv`) lấy hàm cuối.
- Hàm chưa port: đăng ký MỘT hàm thay thế dùng chung, ghi log một lần ("chưa port: Bảng:Tên, impl 0x...") và trả không giá trị
  (nil), thay vì để trống. Trống thì script gặp `attempt to call a nil value` và cả trình xử lý sự kiện dừng; thay thế như vậy
  giữ cửa sổ chạy tới chỗ còn lại (cách `world.lua` của đối soát tầng A đang làm). Hàm "rỗng" thật của Game.exe (32 hàm
  `xor eax,eax; ret`) cũng trả không giá trị: lưu ý để bảng sinh phân biệt "rỗng thật" với "chưa port".

### 2.4 Thay đổi `host.hpp` (đề xuất, CHƯA làm)

```cpp
// Hàm C++ của chủ báo lỗi cho script: đặt cờ lỗi của State với đúng message (không thêm "chunk:dòng:"; tThrowStringException
// của Game.exe không mang vị trí). Hàm C++ trả Results rỗng ngay sau đó. Gọi khi cờ lỗi đã bật là không làm gì.
void raise_error(State& state, std::string_view message);

// setmetatable(table, meta) từ phía chủ; meta là nil thì gỡ. Cần cho đối tượng action (mục 1.5): mọi handle chung một bảng meta.
void set_metatable(State& state, Value table, Value meta);

// Dự phòng, chưa cần: hàm C++ có upvalue (đọc bằng self.upvalue(i) của Body; Cell tạo bằng new_cell).
[[nodiscard]] Value native(State& state, const Proto& proto, std::span<const Value> upvalues);
```

`raise_error` bọc `State::raise_text` (có sẵn trong `state.hpp`, nội bộ module `lua`). `set_metatable` bọc việc gán bảng meta của
`Table` mà thư viện `setmetatable` đã làm. Hai hàm không đổi hợp đồng nào của `vm.hpp`.

Lý do không thêm `Type::kUserdata` bây giờ: nó đổi `Type`, `Value::Payload`, `raw_equal`, `type()` của thư viện, bảng meta theo kiểu,
`tostring`; mà không script nào so `type(x) == "userdata"` (quét 0). Bảng có `__handle` và bảng meta chung chỉ khác ở `type()` và
`tostring`. Nếu sau này cần: mở rộng khi một script đo được cần.

### 2.5 Đọc đối số, ép số

Một tệp `gameapi/args.hpp` nhỏ, đúng ngữ nghĩa mục 1.2: `is_number(args, i)` (kiểu số nghiêm), `is_stringish` (chuỗi hoặc số),
`to_int32(double)` (ép kiểu `cvttsd2si`), `to_text(args, i)` (ép số thành chuỗi theo `%.14g` của `lua::number_to_string`). Chỉ số
theo quy ước của Lua C API của gốc (self ở 1 với hàm trong bảng) để mã port đối chiếu từng dòng với decompile (HP-07).

### 2.6 Khác gốc dự kiến (ghi `Khác gốc:` ở từng tệp)

- Singleton toàn cục thành cổng tiêm được; không còn truy cập theo offset (`DAT_141034c40 + 0x138dc`).
- `Player:GetData` đi qua bảng khoá chuỗi → bộ đọc (băm tĩnh) thay vì chuỗi `strcmp` dài; kết quả cho từng khoá giữ.
- `OSAPI:GetTickCount`: ép int32 có dấu như gốc nhưng đọc từ `Clock` tiêm được.
- `OutputDebugStringA` trong `GetPlayerMission_DataRound` bỏ (không ảnh hưởng script).
- Lỗi của hàm game dừng trình xử lý hiện hành, không lan như ngoại lệ C++.

## 3. Bảng 60 mục đầu (bỏ widget; thứ tự theo `API-TAN-SUAT.tsv`, chỉ `game` và `global`)

Loại: T thuần (không chạm trạng thái); L trạng thái cục bộ client tự giữ; S dữ liệu do máy chủ cấp (offline: rỗng hoặc mẫu
của `hero::newcomer()`); G gửi máy chủ (`Outbox`); C cầu sang tầng C (sự kiện, cửa sổ, hẹn giờ); O đối tượng thế giới
(`CObjectManager`, client mới chưa có); A ô hành động. "Đọc": ✓ đọc gần đủ thân decompile, ~ một phần, – chỉ theo tín hiệu
(singleton và API Lua mà hàm gọi, `classify` của `api_survey.py`).

| # | Hàm | Đơn vị | Lần gọi | Loại | Đọc | Đo được |
|---|---|---|---|---|---|---|
| 1 | `Get_XParam_INT(n)` | 1130 | 859 | L,S | ✓ | n phải là số, sai: "LUA: Lua_Get_XParam_INT Wrong Param". Đọc bản ghi XPARAM do `CEventSystem +0x6c/+0x70` chọn (`FUN_1400d4780`). Giá trị đẩy khi thiếu bản ghi: decompiler mất (thanh ghi xmm) |
| 2 | `Set_XSCRIPT_Function_Name(s)` | 1097 | 3972 | L | ~ | chuỗi (`lua_isstring`), sao tối đa 63 byte vào `CDataPool +0x138e1`; sai kiểu: ném câu có `uiEnv`, `type`, `sid` |
| 3 | `Set_XSCRIPT_ScriptID(n)` | 1097 | 3972 | L | ✓ | số, ghi int vào `+0x138dc` |
| 4 | `Clear_XSCRIPT()` | 1097 | 3972 | L | ~ | xoá bản ghi tại `+0x138dc` (`FUN_1407688d0`), 0 kết quả |
| 5 | `Send_XSCRIPT()` | 1097 | 3966 | G | ~ | dựng `Packets::CGExecuteScript` (opcode 2219, đọc ủy quyền) từ 32 int `+0x138dc..+0x13958`, gửi bằng `CNetManager`. Protocol chưa có tin |
| 6 | `Set_XSCRIPT_ParamCount(n)` | 1096 | 3954 | L | ✓ | số, ghi byte `+0x13921` |
| 7 | `PushDebugMessage(s)` | 1011 | 3580 | C | ✓ | chuỗi (số cũng được), sự kiện `NEW_DEBUGMESSAGE` (0x85) rồi `FUN_14007af80(3)`; sai kiểu: ném "LUA: Lua_PushDebugMessage Wrong Param" |
| 8 | `ScriptGlobal_Format(fmt, ...)` | 978 | 10272 | C | ~ | fmt và tối đa 15 đối số đều phải là chuỗi/số (sai: ném "Wrong Param0!" hay "Wrong Param%d! Param0=%s"); định dạng rồi `NEW_DEBUGMESSAGE`. Có `lua_pushstring` (trả chuỗi?): chưa đọc phần cuối |
| 9 | `Set_XSCRIPT_Parameter(i, v)` | 920 | 4994 | L | ✓ | cả hai số; i < 14 ghi int vào `+0x13924 + 4i`, ngoài miền bỏ qua im lặng |
| 10 | `PushEvent(tên, ...)` | 792 | 2595 | C | ~ | đối số chuỗi gom tới nil/không phải chuỗi đầu tiên, rồi `FUN_1401fce10(CEventSystem, tên, danh sách)`; đối số 1 không phải chuỗi: ném |
| 11 | `Player:GetData(khoá)` | 552 | 14758 | S | ~ | hàm thật `0x140387360` (ô ảo 21), 1 963 dòng, dò khoá chuỗi. Script dùng 171 khoá chuỗi (3 203 chỗ literal, 1 chỗ không): `Is2606S` 734, `MONEY` 549, `MONEY_JZ` 511, `LEVEL` 267, `YUANBAO` 265, `IsOriginalJD` 141. Đối số 1 không phải chuỗi hay chưa có người chơi: 0 kết quả, không ném (khoá lạ: chưa đọc). `hero` đã có `MEMPAI`, `MONEY`, `MONEY_JZ`, `YUANBAO` |
| 12 | `Helper:GotoHelper(s)` | 426 | 449 | C | ~ | hàm thật `0x140652640` (`CHelperSystem`); đối số 2 là chuỗi, tách theo `*` |
| 13 | `DataPool:GetNPCIDByServerID(id)` | 399 | 250 | O | ✓ | số; `CObjectManager` ô 0x90 (tìm theo id máy chủ) rồi ô 0x78 (id client). Giá trị khi không thấy: mất ở decompile |
| 14 | `IsWindowShow(tên)` | 338 | 2528 | C | ✓ | chuỗi; `CUISystem` ô 0xc0; không có CUISystem: false; đẩy boolean |
| 15 | `DataPool:CreateActionItemForShow(a, b)` | 335 | 555 | A | ✓ | hai số (sai: ném "...parameter N error!"); tạo `CActionItem` (`CDataPool` ô 0x1748), trả 2 giá trị (handle, boolean); handle null thì vẫn trả userdata với vftable giữ chỗ |
| 16 | `EnumAction(i, loại)` | 322 | 1882 | A | ~ | `CActionSystem`; trả handle cùng bảng meta |
| 17 | `CloseWindow(tên[, force])` | 315 | 2637 | C | ✓ | `force == true` (boolean): `CUISystem` ô 0xe0 đóng ngay; không thì sự kiện `CLOSE_WINDOW` (0x177) |
| 18 | `KillTimer(idHayTên)` | 253 | 1559 | C | ~ | mã ngắn `0x14069a9e0` nhảy vào `FUN_14069a5d0`: số thì huỷ theo id, chuỗi thì theo tên; trả true |
| 19 | `SetTimer(tên, script, ms)` | 252 | 294 | C | ~ | `FUN_14069a3c0`: tham số 3 không phải số thì trả -1 (không ném); phần sau (tạo hẹn giờ, giá trị trả) chưa đọc |
| 20 | `LifeAbility:Lock_Packet_Item(ô, cờ)` | 224 | 356 | S | ✓ | hai số; ô ≥ 0 thì đặt khoá (ô ảo 0x110 của ô túi), rồi `CEventSystem` ô 0xe0 với 10 |
| 21 | `DataPool:GetLeftProtectTime()` | 191 | 288 | S | ✓ | số học trên ba trường `CDataPool +0x5c11c8/+0x5c11d0/+0x5c11e4`: nếu `+d0 == 0` thì `+c8` ngược lại max(1, `+e4`) |
| 22 | `Player:GetLevel()` | 182 | 2544 | S | ✓ | ném assert "pMyself"/"pCharData" khi chưa có người chơi (cấp ở `dữ liệu +8 +0x74`) |
| 23 | `DataPool:GetServerDayTime()` | 169 | 868 | S | ~ | giờ máy chủ + chênh múi giờ `(8 - múi)*3600` qua `_localtime64`; cần `Clock` tiêm được |
| 24 | `CheckPhoneMibaoAndMinorPassword()` | 158 | 155 | S | ✓ | cờ số 1 của dữ liệu người chơi (`FUN_140190040(dữ liệu, 1)`); đẩy SỐ 1/0 |
| 25 | `Get_XParam_STR(n)` | 158 | 24 | L,S | ✓ | như 1; thiếu bản ghi thì chuỗi hằng `DAT_140b120ae`, null thì `DAT_140b120af` (chưa đọc giá trị hai hằng) |
| 26 | `PlayerPackage:GetItemTableIndex(ô)` | 154 | 197 | S | ✓ | số; `CDataPool` ô 0x240 lấy ô túi, ô ảo 0xd8 của nó |
| 27 | `DataPool:Lua_GetItemNameByIndex(i)` | 142 | 97 | S | ~ | số; phân loại vật phẩm (ô 0x98) rồi tra bảng vật phẩm của loại (medic, campaign...), 102 dòng |
| 28 | `DataPool:CreateBindActionItemForShow` | 131 | 164 | A | ✓ | như 15 |
| 29 | `AutoRuntoTargetExWithName(x, z, d, tên)` | 118 | 71 | G,O | ~ | ba số + một chuỗi (sai: ném); đặt đích chạy tự động có tên (suy ra: gửi di chuyển; thuộc `control` + `nav`) |
| 30 | `KaJi:LuaFnGetKaJiType(n)` | 111 | 853 | S | ✓ | số; tra đối tượng tĩnh `DAT_14103d440` (`FUN_14050a6b0`) |
| 31 | `SystemSetup:IsClassic()` | 98 | 689 | T | ✓ | LUÔN đẩy số 1 (9 dòng) |
| 32 | `PlayerPackage:IsLock(ô)` | 91 | 57 | S | ✓ | số; đẩy SỐ 1/0 |
| 33 | `Player:GetName()` | 81 | 205 | S | ✓ | hàm thật `0x1403872f0` (ô ảo 1), đẩy chuỗi |
| 34 | `Target:GetServerId2ClientId(id)` | 79 | 29 | O | ✓ | như 13 (sai kiểu: ném) |
| 35 | `DataPool:GetServerName(i)` | 75 | 327 | S | ~ | số (sai: ném); danh sách máy chủ đăng nhập (`DAT_14103e618`) → chuỗi |
| 36 | `KaJi:LuaFnIsKaJiServer()` | 72 | 271 | S | ✓ | đẩy số |
| 37 | `DataPool:GetSelfZoneWorldID()` | 71 | 294 | S | ✓ | -1 khi chưa có người chơi |
| 38 | `GetSceneID()` | 66 | 260 | O | ✓ | cảnh hiện hành qua `DAT_141040c98` ô 0x80; không có cảnh: 0 kết quả (nil) |
| 39 | `PlayerPackage:CountAvailableItemByIDTable(id)` | 64 | 319 | S | ✓ | số; `CDataPool` ô 0x278 |
| 40 | `DataPool:GetPlayerMission_DataRound(id)` | 61 | 264 | S | ✓ | số; rẽ theo `id < 0xf5c` (3 932), nhánh trong có `sprintf` + `OutputDebugStringA`; giá trị đẩy mất ở decompile |
| 41 | `Pneuma:GetMF(id)` | 54 | 658 | S | ✓ | số; đẩy `0 < giá trị` |
| 42 | `OpenWindow(tên)` | 53 | 47 | C | ✓ | sự kiện `OPEN_WINDOW` (0x176) trừ khi `FUN_140229d50(DAT_141036068)` báo khoá |
| 43 | `PlayerPackage:GetItemName(i)` | 52 | 86 | S | ~ | như 27 |
| 44 | `SetDefaultMouse()` | 51 | 321 | C,A | ✓ | `CActionSystem` ô 0x178 lấy hành động mặc định rồi đặt (`DAT_141036068` ô 0x90); đọc từ disasm |
| 45 | `OSAPI:GetTickCount()` | 50 | 236 | T | ✓ | `GetTickCount` ép int32 CÓ DẤU (`cvtdq2pd`) rồi double: âm sau 24,8 ngày; đọc từ disasm |
| 46 | `CloseFreshManGuide()` | 50 | 117 | C | ✓ | `CEventSystem` ô 0xe8 với 0x3f0 (không phải ô 0xd8/0xe0 của các hàm trên: chưa rõ nghĩa), rồi xoá chuỗi hướng dẫn tân thủ; từ disasm |
| 47 | `DataPool:Lua_IsMissionHaveDone(id)` | 44 | 404 | S | ✓ | số; kho nhiệm vụ `DAT_141034c10 +0x28` (`FUN_14009e620`); đẩy số |
| 48 | `IsInTServer()` | 43 | 138 | S | ✓ | rẽ theo `DAT_14103e6b0`; đẩy số |
| 49 | `SystemSetup:OpenPrivatePage(s)` | 43 | 66 | C,G | ~ | chuỗi ở chỉ số 2 (sai: ném); chạm `CEventSystem`, `CNetManager`, `CObjectManager` |
| 50 | `AutoRunToTargetEx(x, z, d)` | 42 | 27 | G,O | ~ | ba số (sai: ném); chạm `DAT_14103e638`, `DAT_141034c10`, `DAT_141040c98` |
| 51 | `LuaFnOpenUnderArmour(s)` | 42 | 22 | C | – | chuỗi; `CEventSystem` |
| 52 | `GameProduceLogin:OpenURL(s)` | 41 | 173 | C | ~ | chuỗi ở chỉ số 2; mở trang ngoài (dịch vụ Shell của chủ) |
| 53 | `PlayerPackage:GetItemBindStatusByIndex(ô)` | 40 | 4 | S | – | `CDataPool`, số |
| 54 | `Player:GetGUID()` | 39 | 175 | S | ✓ | chuỗi `"0X%08X%08X"` của hai nửa; `""` khi cả hai là -1 |
| 55 | `OpenFreshManGuide(...)` | 39 | 24 | C | – | số + chuỗi; `CEventSystem`, đặt chuỗi chủ hướng dẫn |
| 56 | `GetFreshManGuideOwner()` | 38 | 336 | L | ✓ | đẩy chuỗi `DAT_141034c10 +0x550` |
| 57 | `GetWeblink(khoá)` | 38 | 169 | S | ~ | chuỗi (sai: ném); tra URL theo khoá, đẩy chuỗi |
| 58 | `GetActionNum(tên)` | 35 | 175 | A | ✓ | chuỗi; `CActionSystem` ô 0xb0 |
| 59 | `Infant:GetInfantCount()` | 34 | 187 | S | ✓ | `FUN_140105e90(CDataPool)`, đẩy số |
| 60 | `LifeAbility:Get_Equip_Point(ô)` | 34 | 0 | S | ~ | số; nhánh khác 1 hiện câu hệ thống "GMGameInterface_Script_LifeAbility_13" qua `DAT_14103e6e0` |

Tổng theo loại (60 hàng, hàng nhiều loại tính loại đầu): S 25, C 15, L 8, A 4, G 3, O 3, T 2 (đếm tay từ bảng trên).

### 3b. Mười sáu mục `other` trong 60 mục đầu không-widget

`GetID` (780 đơn vị), `Show`, `SetProperty`, `Hide`, `SetText`, `GetVariable`, `SetActionItem`, `SetVariable`, `GetSubItem`,
`SetToolTip`, `GetName`, `GetValue`, `Enable`, `Disable`, `SetCheck`, `GetProperty`. Bên nhận là biến cục bộ hay phần tử bảng,
chỉ biết lúc chạy (`api_frequency.py`): hoặc cửa sổ/widget (tầng C: `Show`, `Hide`, `SetText`, `SetProperty`, `Enable`,
`SetCheck`...), hoặc handle action (mục 1.5: `GetID`, `GetName`...). Thuộc tầng C và `ActionButtonMetaTable`; chưa tách được
từng hàm một bằng phân tích tĩnh. `SetVariable`/`GetVariable`: biến người dùng của cửa sổ CEGUI.

## 4. Quy mô và thứ tự

Đo trên 2 060 đơn vị (script + đoạn Lua của layout), không tính widget, 5 350 tên game/global script gọi:

| Port N hàm đầu bảng tần suất | Đơn vị chạy trọn |
|---|---|
| 10 | 9,2% |
| 20 | 17,2% |
| 60 | 33,6% |
| 100 | 36,3% |
| 400 | 41,7% |
| 1600 | 55,6% |

Thứ tự tham lam (lần lượt lấy đơn vị cần ít hàm chưa có nhất): 25% đơn vị cần 240 hàm, 50% cần 578, 75% cần 1 326, 90% cần
2 715, 100% cần 5 349. Đuôi dài: sau 60 hàm đầu, mỗi hàm thêm chỉ làm một đơn vị chạy trọn rất hiếm. 81 đơn vị không cần hàm
game/global nào.

Hệ quả đề xuất:

1. Vừa đủ cơ sở hạ tầng (host, `args`, đăng ký, stub log) trước, rồi 60 hàm đầu; sau đó theo thứ tự tham lam của
   `api_survey.py`, không theo tần suất thô.
2. Hàm đọc dữ liệu máy chủ cấp (loại S, chiếm phần lớn) làm theo lô: mỗi lô một nhóm dữ liệu (túi, nhiệm vụ, kỹ năng, bạn bè...)
   cùng với module giữ dữ liệu đó, trả giá trị của trạng thái RỖNG như Game.exe khi chưa có dữ liệu.
3. 722 hàm gửi gói: đầu tiên ghi vào `Outbox` và log, không cần protocol; làm tin thật theo kế hoạch máy chủ.

## 5. Đối soát tầng B

Game.exe chạy thật là thứ cần nhất. Ba bậc, từ rẻ đến đắt; chỉ bậc 1 đã chạy được ngay:

1. **Hợp đồng sinh từ decompile (đề xuất làm ngay).** Một công cụ `TOOLS/port/luagen/api_contract.py` đọc thân mỗi native và
   trích: chỉ số đối số và kiểu bị kiểm (`lua_type(L,i) != 3`, `lua_isstring`), câu ném, số giá trị trả về, kiểu đẩy (số, chuỗi,
   boolean). Sinh bảng `Test/golden/gameapi/contract.tsv` và test C++ gọi từng native với đối số đúng/sai kiểu, so câu lỗi và
   số/kiểu kết quả. Bắt phần lớn lỗi port (kiểu số/boolean, kiểm kiểu nghiêm, câu lỗi) mà không cần chạy Game.exe. Phần giá
   trị còn lại (đọc trường nào của trạng thái) thì test viết tay cho từng hàm, đọc từ decompile; vòng tròn (người port và
   người sinh số vàng cùng đọc một decompile) nên ghi rõ trong test.
2. **Giả lập x86-64 trên `D:\rea\work\client\Game.exe` (9001), không chạy mã ngoài tiến trình.** Nạp các đoạn PE vào bộ giả lập,
   móc các import `lua_*`, `LuaPlus::*`, `tThrow*` (khoảng 80 import) vào một Lua C API giả viết bằng Python hay chính
   `LuaPlus.dll` qua `lua_oracle.Machine`, dựng ảnh bộ nhớ của `CDataPool` (hàm đã thấy đọc tới `+0x6f56f8`), `CObjectManager`... rồi
   chạy từng native: ra giá trị chính xác cho mọi native đọc trường thẳng, và quét "trạng thái rỗng" cho cả 6 055 hàm để
   lấy giá trị mặc định offline. Ô ảo gọi hàm của đối tượng C++ phải móc từng cái (vftable giả). Cần `pip install unicorn`: máy
   chưa có (`capstone` và `pefile` có sẵn); chưa cài vì thêm phụ thuộc cần anh duyệt. CHƯA ĐO độ khả thi.
3. **Nạp `D:\XTLBB\Bin64\Game.exe` (9509, đúng bản của script) làm thư viện và gọi hàm đã đăng ký.** Chính xác nhất nhưng chạy
   mã thật của client (kèm `tEngine.dll`, Ogre, fmod...) và cần dựng ảnh bộ nhớ thật cho singleton; không thử được trong phiên này
   (thao tác bị chặn). CHƯA ĐO. Quyết định thuộc chủ dự án.

Đối soát toàn đường (script + hàm game) vẫn dùng khung tầng A: hai phía chạy cùng script; phía gốc dùng Lua giả cho API như
`world.lua` đang làm. Khi hàm C++ thật thay hàm giả, vết phải khớp bảng vàng của tầng A trừ chỗ hàm giả trả khác hàm thật
(số vàng của chỗ đó cần sinh lại từ bậc 1 hay 2).

## 6. Chưa chắc, chưa đo

- Giá trị đẩy ở nhánh "không thấy" của nhiều hàm (vd 1, 13, 26, 34): decompiler mất thanh ghi xmm; cần đọc disasm từng hàm
  (`capstone` + `pefile` sẵn sàng) — nằm trong bậc 1.
- Thân `Player:GetData` (1 963 dòng): bảng khoá đầy đủ chưa dựng; script dùng 171 khoá, cần đọc từng khoá.
- `CEventSystem::PushEvent` đồng bộ hay xếp hàng? Chưa đọc `FUN_1401fce10`; quyết định ở tầng C.
- Bản `Game.exe` 9001 (decompile) và 9509 (script). Độ lệch đo được: script gọi 29 cặp `Bảng:Hàm` (110 chỗ) mà bảng 9001 không
  có (vd `DataPool:Lua_SetBieYeOperateActionItem` 14 chỗ, `ZhanTuanInterface:*`, `Guild:AskGuildYXSSInfo`); hành vi của hàm
  có mặt ở cả hai bản chưa so.
- Lớp của `DAT_141034c10`, `DAT_141040c98`, `DAT_14103e6a8`, `DAT_141036068`, `DAT_14103e6b0`, `DAT_14103e638`: chưa xác nhận.
- Việc ngoại lệ C++ của `Game.exe` có bị `pcall` của `LuaPlus.dll` bắt không chưa đo trực tiếp (0 script dùng `pcall`).
- 59 hàm không có decompile (mã ngắn Ghidra chưa tạo hàm, hàm rỗng, hàm chuyển tiếp ngoài ba lớp có bảng ô ảo).
- Tên sự kiện: 649 cặp trích từ disasm, chưa đối chiếu với số lớn nhất (1928) để biết có thiếu.

## 7. Nếu được duyệt

1. Thêm `raise_error`, `set_metatable` vào `host.hpp`/`host.cpp` (+ một vài ca vào `lua_tests`).
2. Module `gameapi`: `GameHost`, `Ports`, `args`, bảng đăng ký sinh, hàm thay thế log; tầng ở `cmake/GameLayers.cmake`.
3. `api_contract.py` + `Test/golden/gameapi/contract.tsv` (bậc 1).
4. 60 hàm đầu (mục 3), nối `hero` cho `Player:*`; sau đó theo thứ tự tham lam.
5. Quyết định bậc 2/3 của mục 5 trước khi mở lô lớn.

## 8. Hiện trạng đã làm (cách làm thật, thay mục 2)

Tệp: `src/client/face/ui/script/`. Hàm game là `lua_CFunction` thật của LuaPlus 5.0.1, không có VM tự viết ở giữa.

- `native_support.{hpp,cpp}` — nền chung của mọi nhóm: `native::Entry`, `register_globals` (hàm toàn cục), `register_table` (bảng như
  `DataPool`, nhiều nhóm góp chung một bảng), `attach`/`context_of` (Context gắn vào registry của state bằng lightuserdata),
  `strict_number` (số NGHIÊM: `lua_type == LUA_TNUMBER`, chuỗi số "5" không qua), `text_arg` (`lua_isstring`: chuỗi hay số), `to_int`
  (`luanum_to_int32`, tức `(int)` của x64: ngoài miền ra INT32_MIN), `type_at`.
- `context.hpp` — `Context`: trạng thái ghi được mà hàm native chia sẻ; HUD giữ một cái (`Hud::State::script_context`, khai trước `host`)
  và đưa cho host bằng `HostDesc::natives = make_natives(context)` (= `open_natives(lua)` rồi `native::attach(lua, context)`). Hiện có `xscript` (bản ghi đang soạn và hàng đợi ra) và `xparam` (bản ghi tham số của sự kiện
  đang chạy; `nullptr` khi sự kiện không mang). `facts` giữ điều game biết về thế giới (cảnh, hội thoại, nhân vật `hero`, cờ máy chủ); nhóm sau cần thêm trạng thái thì thêm trường vào đây.
- `native_groups.hpp` + `native_<nhóm>.cpp` — mỗi nhóm một tệp, một hàm `register_<nhóm>(lua_State*)`, gọi từ `open_natives`
  (`natives.cpp`). Thêm nhóm: viết tệp, khai hàm đăng ký ở `native_groups.hpp`, thêm vào `game_module(ui_script ...)`, gọi trong `open_natives`.
- Thân hàm viết `lua::NativeResult body(lua_State*)` rồi đăng ký `lua::adapt<body>`: lỗi trả bằng `std::unexpected(NativeError::of/format(...))`,
  không `luaL_error`, không để đối tượng có destructor sống qua một lời gọi API Lua (LuaPlus báo lỗi bằng longjmp).
- Lời lỗi: mỗi hàm có câu riêng của Game.exe (`tThrowStringException`), KHÔNG có câu chung. Dạng phổ biến `LUA: Lua_<Tên> Wrong Param`,
  nhưng không phải mọi hàm: `Check_StringCode` ném `LUA:Check_StringCode Param error` (không dấu cách sau `LUA:`), các hàm khác thêm
  `[type=%d]`, `[type=%d,sid=%d]`... Phải đọc decompile từng hàm; không tự suy câu lỗi từ tên.
- Booleans game trả cho script là số 1/0, không phải `true`/`false` của Lua.

Nhóm đã port:

| Nhóm | Hàm | Ghi chú |
|---|---|---|
| DataPool (`natives.cpp`) | `GetUIColor`, `Check_StringCode` | `GetUIColor` chưa có bảng màu nên trả "-1" "-1" (Khác gốc, ghi tại chỗ). |
| XSCRIPT/XParam (`native_xscript.cpp`, `xscript.{hpp,cpp}`) | `Get_XParam_INT/UINT/STR/INT_Count/STR_Count`, `Set_XSCRIPT_ScriptID/Function_Name/ParamCount/Parameter`, `Clear_XSCRIPT`, `Send_XSCRIPT` | Dùng trong khoảng 1 100 cửa sổ. |
| Biến (`native_variable.cpp`, `variable.{hpp,cpp}`) | `Variable:GetVariable`, `Variable:SetVariable` | Bảng chuỗi=>chuỗi (CVariableSystem). Đổi giá trị thì phát VARIABLE_CHANGED (0x13c) qua `Context::calls`. Bảng bắt đầu rỗng (Khác gốc: chưa nạp biến mặc định). Trần 4096 biến, tên 255 byte, giá trị 5199 byte (trần là Khác gốc). |
| Thế giới (`native_world.cpp`, `Context::facts`) | `DataPool:GetCurDialogNpcId`, `DataPool:LuaFnGetGMVisibleType`, `SystemSetup:IsClassic`, `WuLinZhiDian:IsWuLinZhiDianScene`, `JueZhanWuLinZhiDian:IsJueZhanWuLinZhiDianScene`, `CSongliaoWarData:TSLGetLocalSceneID`, `GetSceneID`, `IsZbs2018SpeicalServer` | Facts do HUD đặt mỗi khung (hiện chỉ `scene_id`). Ba cảnh Võ Lâm Chi Điên là id 0x2f1..0x2f3. |
| Lời nhắn (`native_format.cpp`, `message_format.{hpp,cpp}`) | `ScriptGlobal_Format` | KHÔNG phải printf: đóng gói mẫu và đối số thành chuỗi mà lớp lời nhắn của game tách lại (bố cục byte ở `message_format.hpp`). Không đối số thì phát NEW_DEBUGMESSAGE. |
| Nhân vật (`native_player.cpp`, `Facts::hero`, `Facts::server`) | `Player:GetData` (Game.exe 0x140387360): LEVEL, HP/MAXHP, MP/MAXMP, RAGE/MAXRAGE, STRIKEPOINT, MEMPAI, STR/SPR/CON/INT/DEX, POINT_REMAIN, tám chỉ số chiến đấu, VIGOR/MAXVIGOR, ENERGY/MAXENERGY, BATTLESCORE, MONEY (bốn số: tổng, vàng, bạc, đồng), MONEY_JZ, YUANBAO, BIND_YUANBAO, GIFTTOKEN, ZENGDIAN, LIJIN, EXP và NEEDEXP (chuỗi thập phân), IsPKServer_JD, IsOriginalJD, Is2606S | Mỗi khoá là một getter của CCharacterData đọc `*(*(người+8) + offset)` (offset ghi cạnh từng khoá ở mã), đẩy bằng PushInteger. Chỉ port khoá mà `hero::Hero` có dữ liệu thật; hơn 130 khoá còn lại (TODAYACTIVEPOINT, SPECKAJI89, TCWLSvrOpenFlag, XIULIAN_*, PORTRAIT...) và khoá lạ KHÔNG trả gì (nil) cho tới khi máy chủ có nguồn — gốc với khoá lạ đẩy số thừa trong r8d, không bắt chước. Chưa có nhân vật (chưa vào cảnh) hay đối số không phải chuỗi/số: không trả gì (đúng gốc). `MAXRAGE` là hằng 1000 (0x140388065). Ba cờ máy chủ ở đối tượng hệ thống (+0x6f5868/6c/74), hàm dựng đặt 0, máy chủ ghi. GUILD (-1 là không có bang) và ZONEWORLDID là số 16 bit có dấu (`movswl`) đọc từ `Facts::guild_id`, `zone_world_id`. |
| Nhân vật, thêm (`native_player.cpp`) | `Player:GetLevel`, `Player:GetName` | GetLevel khi chưa có nhân vật ném assert `pMyself` (lỗi Lua mang tên điều kiện, Khác gốc: không có đường dẫn máy dựng); GetName trả chuỗi rỗng. |
| Hệ thống (`native_system.cpp`, `Facts`, `Context::can_use_hotkey`) | `OSAPI:GetTickCount`, `ZBS:IsViewerWatching`, `IsDfsSpeicalServer`, `Infant:GetMaxSkillNum` (hằng 4), `KaJi:LuaFnIsKaJiServer`, `KaJi:LuaFnGetKaJiType`, `CloseMessageBoxCommon`, `DataPool:SetCanUseHotKey`, `DataPool:Lua_GetUpdateTipsFlag` | GetTickCount ép `(int)` nên quấn sang âm sau 2^31 ms (đồng hồ khung thay đồng hồ hệ thống, Khác gốc). KaJi: bảng máy chủ KaJi (DBC 0x225) chưa nạp nên luôn 0. `CloseMessageBoxCommon` đẩy MESSAGEBOX_COMMON_CLOSE (0x23a). `Lua_GetUpdateTipsFlag` so chỉ số không dấu với 100 (âm hay ≥ 100 ra 0). Cờ chưa có nguồn từ máy chủ mặc định 0. |
| Cảnh và cờ máy chủ, thêm (`native_world.cpp`, `native_player.cpp`) | `GetSceneSize`, `GetSceneSizeByID`, `GetSceneMapByID`, `IsInTServer`, `IsTBFinalServer`, `KVKInterface:IsInKVKServer`, `TLCJ:IsInTLCJScene`, `Player:IsLeader`, `DataPool:GetSelfZoneWorldID`, `DataPool:GetGuildClanID` | Cỡ cảnh và token minimap lấy từ bảng cảnh (`Facts::scenes`, `Facts::scene_size`); id lạ ra 0|0 và chuỗi rỗng. `IsInTServer` = biến IsTServer (atoi, ô ảo 22 của CVariableSystem, `VariableSystem::get_int`) khác 0 hoặc cảnh 0x28a/0x2d8/0x2d9. `IsInKVKServer` = atoi biến IsKVKServer. `IsInTLCJScene` cần nhân vật và cảnh 0x3e0/0x3f7. `GetGuildClanID` đẩy id bang rồi -1 cố định. Khi chưa có nhân vật/cảnh, gốc đọc con trỏ null (sập): ở đây trả 0 hay giá trị rỗng (Khác gốc). Chưa làm `GetSceneNameByResID` (bảng SceneAttr DBC 0xb7) và `GetCurrentSceneName`. |
| Đẩy sự kiện, sinh tự động (`native_events.cpp`, bộ sinh `TOOLS/port/luagen/gen_event_natives.py`) | 163 hàm, như `OpenSafeScore`, `CloseTitleList`, `ToggleYuanbaoShop` (chuỗi hằng "normal"), `ToggleContainer`, `ToggleMission`, `TogglePetPage`, `OpenEquip(n)`, `ShowTeamInfoDlg(n)`, `DataPool:OpenFriendList`, `DataPool:OpenMailRead`, `Guild:ToggleGuildDetailInfo`, `LuaFnOpenCangPin(n)`... | Chỉ hàm mà thân decompile KHỚP ĐÚNG một lần gọi `CEventSystem` (ô 0xe8 không đối số, 0xe0 số in `%d`, 0xd8 chuỗi hằng) rồi trả 0, có thể bọc thêm: kiểm khoá cảnh `FUN_140229d50` (= `IsInHell`: cảnh 0x4d/0x242/0x337 thì im lặng bỏ qua, `Facts::in_hell`) và một đối số số của script (`lua_type == 3` nghiêm, ép `(int)`; sai kiểu thì bỏ qua im lặng hoặc ném câu riêng của hàm, thứ tự ném/khoá theo từng hàm của gốc). Thân có thêm việc khác (đọc trạng thái, ghi biến, gọi đối tượng khác) thì không sinh, để port tay (OpenSkillBook, OpenLifePage... còn ghi trang vào kho nhiệm vụ). Bảng id → tên sự kiện đọc từ ba hàm khởi tạo tĩnh của Game.exe (0x140a10cd0, 0x140a18c10, 0x140a272b0), nên `TAILIEU/SU-KIEN-GAME.tsv` đủ 3 162 sự kiện (trước 649, tên cũ không đổi). Chuỗi hằng truyền bằng địa chỉ (`&DAT_140b3e66c` = "2", `&DAT_140b30af8` = "save") ghi trong `KNOWN_STRINGS` của bộ sinh. Chạy lại: `python -B -X utf8 TOOLS/port/luagen/gen_event_natives.py --write`; tệp sinh không sửa tay. `IsInHell` (0x140232890) port tay ở `native_world.cpp`. Khác gốc: `OpenWindow` ở `host.cpp` chưa gọi `Facts::in_hell` (việc của phần host). |

XSCRIPT (bản ghi 128 byte ở `CDataPool + 0x138dc`): id 4 byte (+0), độ dài tên 1 byte (+4), tên 63 byte (+5), đếm tham số (+0x45), 14 tham số
4 byte (+0x48). `Clear_XSCRIPT` đặt id -1 và xoá phần còn lại. `Set_XSCRIPT_Function_Name` chép tối đa 63 byte và dừng ở NUL đầu tiên.
`Set_XSCRIPT_Parameter(i, v)` lấy 8 bit thấp của i (256 là ô 0), ngoài 14 ô thì bỏ qua không lỗi. `Set_XSCRIPT_ParamCount` giữ 8 bit thấp.
`Send_XSCRIPT` đóng bản ghi vào gói `CGExecuteScript` (opcode 2219) cho `CNetManager`; protocol của dự án chưa có tin này nên bản ghi vào hàng
đợi ra của `XScript` (trần 1 024, quá thì bỏ và đếm `dropped()`); HUD lấy ra mỗi khung và ghi một dòng stderr cho mỗi bản ghi.
`Send` không xoá bản ghi đang soạn.

XParam (bản ghi server gắn vào sự kiện, tối đa 16 số và 16 chuỗi): chưa có nguồn cấp (chưa có tin máy chủ mang tham số), nên `Context::xparam`
luôn `nullptr`: `Get_XParam_INT`/`UINT` trả -1, `STR` trả "", hai hàm đếm trả 0. Khi có bản ghi: chỉ số ngoài đếm cho 0 hay "", `UINT` đọc
số `int32` thành không dấu. Bên đưa sự kiện vào host đặt `xparam` trước `Host::post` và trả về `nullptr` sau đó.

Khác gốc: câu lỗi của `Set_XSCRIPT_Function_Name` và `Set_XSCRIPT_ScriptID` gốc kèm tên môi trường giao diện đang chạy (`uiEnv=%s`); native
không biết nó nên bỏ trường này. Câu lỗi của `Set_XSCRIPT_Parameter` gốc có `<%s>` mà decompile không thấy đối số; bỏ phần đó.

Kiểm: `Test/Ui/ui_script_xscript_tests.cpp` (năm ca: chuỗi lệnh điền và gửi, giới hạn tên và chỉ số, trần hàng đợi, đọc XParam, câu lỗi);
`ui_script_natives_tests` (DataPool). Chạy dưới ASan + UBSan (Clang) và debug mode (GCC) bằng `check.py --run`. Đã thử gài lỗi
(bỏ cắt NUL, bỏ mặt nạ 8 bit) để xem test đỏ.
