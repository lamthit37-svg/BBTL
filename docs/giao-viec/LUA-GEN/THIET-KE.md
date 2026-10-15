# LUA-GEN — đưa toàn bộ script giao diện của client 2026 vào client (máy: LuaPlus gốc), đối soát hàng loạt với LuaPlus.dll (điều phối: thienlong-2d)

Chủ dự án chốt ngày 2026-10-15: thay việc port tay từng cửa sổ (`docs/giao-viec/UI-PORT`) bằng đường dây công nghiệp —
"Bạn tiến hành sinh mã và đối soát hàng loạt chuẩn nhất có thể làm trong sức mình đi" — sau khi được báo đánh đổi: mã sinh
mang ngữ nghĩa Lua (kiểu động), không phải C++ viết tay; không nhúng máy Lua. Bảy cửa sổ đã port tay giữ nguyên; số vàng
của chúng thành ca kiểm thêm.

## Hướng chốt cuối 2026-10-15: dùng thẳng LuaPlus gốc

LỊCH SỬ ĐỔI HƯỚNG trong một ngày, mỗi lần theo số đo: (1) sinh C++ từ script (bộ dịch + runtime tự viết, đối soát 2 060 đơn vị)
ra 155-170 MB mã máy cho cả kho — quá nặng; (2) chủ dự án chốt bytecode + máy thông dịch tự viết — chưa viết dòng nào thì
(3) tìm được NGUỒN C của chính LuaPlus 5.0.1 trong mã client TLBB của chủ dự án (`G:\TLBB\_ref\client\Game\Client\LuaPlus`;
có `continue`, OP_POW là XOR). Dựng thử thành DLL và chạy trọng tài: 2 058/2 060 đơn vị trùng từng byte với `LuaPlus.dll` 2026,
2 lệch chỉ vì CRT in NaN. Chủ dự án chốt: "Cái đó là mã của tôi lấy thẳng source sang, có gì cải tiến thì cải tiến luôn".

- Máy Lua của script giao diện = chính LuaPlus, nguồn nguyên văn ở `third_party/luaplus` (NGUON.txt: nguồn, giấy phép, mục
  "Khác gốc" — mọi vá có chú thích `Khác gốc:` tại chỗ). Bytecode của chính nó, một vòng thông dịch đã chạy 20 năm: không máy
  thông dịch, bộ dịch bytecode hay bộ sinh C++ tự viết trong client.
- Không nâng lên Lua đời mới (5.4, LuaJIT, Luau): script là phương ngữ LuaPlus 5.0.1 (`continue`, `^` là XOR, bảng `arg`,
  `table.getn`, `string.gfind`, `math.mod`, đọc trường trên nil không lỗi); lên bản mới phải viết lại nghĩa của 3 173 tệp.
- Cải tiến làm trên nền gốc, mỗi cái có số đo hay bằng chứng và một dòng "Khác gốc":
  1. Sửa lỗi trình dịch: `computesizes` ở MSVC /O2 (đã làm, `ltable.c`).
  2. Định dạng số cố định theo MSVCR110, độc lập CRT từng nền tảng (`luanum`): tostring/nối chuỗi, string.format, strtod,
     math.random cho cùng chuỗi ở PC, Android, iOS.
  3. Vỏ C++ hiện đại (RAII `lua::State`): trần heap, móc đếm lệnh cắt vòng lặp vô hạn, trần độ sâu, nạp/gọi trả `std::expected`.
  4. Sau khi chạy đúng, đo thật rồi mới tối ưu: `TObject` đóng gói 1 byte (`pshpack1`) có chậm không; GC dừng-toàn-bộ chạy giữa
     hai khung có ngân sách thời gian; script nạp lười theo cửa sổ. Không làm khi chưa có số.
- Giữ làm mã tham khảo (không dựng): bộ phát C++ và bộ sinh (`TOOLS/port/luagen/ref_cpp/`), runtime tự viết
  (`TOOLS/port/luagen/ref_cpp/runtime/`). Giữ làm công cụ kiểm: bộ phân tích Python (khớp `luaL_loadbuffer` 24 942/24 942 chunk),
  `mass_units`, `mass_oracle`, `world.lua`, số vàng 10 835 ca của thư viện chuẩn.
- Kiểm bản dựng của dự án so với DLL gốc: ctest `lua_oracle` (2 060 đơn vị, vết từng byte) và `lua_golden` (10 835 ca thư viện),
  chạy ở mọi trình dịch và nền tảng dựng được.
- Lớp B và C của bảng "Ba lớp" dưới đây vẫn là việc còn lại và là chỗ giá trị nằm; lớp A không còn việc (máy là hàng có sẵn).
  Hàm game viết theo đúng Lua C API như `Game.exe` (không cần đổi quy ước gọi). Các mục "Runtime", "Bộ dịch", "Cỡ mã sinh",
  "Thứ tự" bên dưới là của hướng sinh C++ đã bỏ, giữ như hồ sơ và vì chứa số đo ngôn ngữ nguồn còn đúng.

## Ba lớp

| Lớp | Việc | Thế nào là đúng |
|---|---|---|
| A. Dịch | Mọi chunk Lua (2 043 tệp `src/client/script/Interface`, mọi đoạn Lua nối sự kiện trong 2 033 layout) thành C++ chạy trên runtime `lua` | Vết đối soát của mọi cửa sổ khớp từng byte với chính script đó chạy trên `LuaPlus.dll` |
| B. API của game | 1 654 hàm `Đối tượng:Hàm` mà script gọi (836 hàm chiếm 90% lượt gọi; đo 2026-10-15), port từ mã máy `Game.exe` theo thứ tự tần suất | Test từng hàm theo mã máy (`TAILIEU/GAME-EXE-2026/lua_api.tsv`, `decompile.zip`) |
| C. Chủ | Nạp layout, đặt `this`, `arg0..`, đẩy sự kiện, nối widget `gui`; thay các panel port tay | Chạy client, nhìn ảnh, như UI-PORT |

Tách A khỏi B là chỗ then chốt: đối soát lớp A chạy với một "thế giới giả" chung cho cả hai phía, nên chứng minh được bản dịch
đúng cho mọi cửa sổ mà không cần API thật nào.

## Ngôn ngữ nguồn (đo trên `D:\XTLBB\Bin64\LuaPlus.dll` ngày 2026-10-15)

- `_VERSION` là `Lua 5.0.1`. Mã tham chiếu: `C:\dev\third_party\reference\lua-5.0.1` (`NGUON.txt` ở đó).
- Có `continue` (`for i=1,5 do if i==3 then continue end s=s+i end` ra 12). Không có `#`, `%` (lỗi cú pháp), không có
  `select`, `string.gmatch` (có `string.gfind`). Có `loadstring`, `setfenv`, `unpack`; script giao diện không dùng ba hàm
  đầu (quét 2 043 tệp: 0 lần `loadstring`, `dofile`, `setfenv`, `setmetatable`, `coroutine`).
- Chuỗi có bảng meta: `("abc"):len()` ra 3.
- `^` của hai số là XOR trên số nguyên 32 bit không dấu ngay trong VM, kể cả khi toán hạng là biến (`local a,b=2,10`
  thì `a^b` ra 8); có toán hạng là chuỗi thì Arith ép số rồi gọi hàm toàn cục `__pow`, mà `__pow` của DLL là pow thật
  (`"3"^2` ra 9, `__pow(2,10)` ra 1024). Số đo khác: `2^10` ra 8, `2.5^2` ra 0, `5^-1` ra 4294967290, `1e300^2` ra 2, `2^3^2` ra 3 (kết hợp phải). `math.pow(2,10)` vẫn 1024.
- `table.getn({1,2,nil,4})` ra 2; `math.mod(-7,3)` ra -1; `tostring(1e15)` là `1e+015`, `1/0` là `1.#INF`;
  `string.format('%5.2f|%d|%s|%x|%g', 3.14159, 42.9, 'x', 255, 1e20)` là ` 3.14|42|x|ff|1e+020`.
- So sánh chuỗi theo byte: `'a' < 'B'` là false.
- Đọc và ghi trường trên nil, boolean, số, hàm không lỗi: `local n=nil` thì `n.x` ra nil, `n.x=1` ghi vào bảng riêng của
  kiểu nil (`getmetatable(nil).x` ra 1); mỗi kiểu một bảng, chuỗi dùng bảng `string`. `n:m()` vẫn lỗi gọi phương thức.
- Literal `-0` và `-0.0` ra +0 (`tostring` là `0`), `-z` với `z=0` lúc chạy ra `-0`: bộ dịch phát hằng +0 cho dấu trừ đứng
  trước literal số 0.
- `_G` của DLL còn có `coroutine`, `newproxy`, `require`, `loadfile`, `dofile`, `loadstring`, `towstring`, `getfenv`,
  `setfenv`, `gcinfo`, `_LOADED`, `string.dump`, `string.lualex`, `table.foreach`, `table.foreachi`; runtime có đủ tên để
  `__index` của world.lua không biến chúng thành đối tượng giả khác phía gốc.
- Thứ tự `pairs` theo bảng băm của ltable.c: `t.b=1 t.a=2 t[10]=3 t.zz=4 t[1]=5 t[2.5]=6` duyệt ra `10,1,b,2.5,a,zz`.
- Game.exe tạo máy bằng `LuaPlus::LuaState::Create` (imports của `Game.exe`). Script dùng `os.` ở 6 tệp, `io.` ở 3 tệp.

Lệnh đo lại: `TOOLS/port/lua_oracle.py` có lớp `Machine` chạy một đoạn Lua trên DLL đó.

## Runtime — module `lua` (`src/client/face/lua/`, `game::lua`) — thienlong-e7

Bề mặt mà mã sinh gọi là `src/client/face/lua/vm.hpp` (hợp đồng, đã dịch sạch trên MSVC, GCC, Clang). Phần còn lại
(`state.hpp`, `table.hpp`, `string.hpp`, thư viện) do e7 thiết kế; không đổi bề mặt khi chưa báo c8 và 2d.

- Port đúng từ bản tham chiếu, giữ thứ tự thao tác (HP-07, ghi `Khác gốc:` khi lệch):
  - lstring: intern mọi chuỗi, hàm băm của `luaS_newlstr`.
  - ltable toàn bộ: phần mảng, phần node, `mainposition`, `luaH_next`, `rehash`/`computesizes`/`numuse*`, `luaH_new` theo
    hai số của OP_NEWTABLE (`luaO_int2fb`, `luaO_log2 + 1`). Thứ tự `pairs` phải khớp gốc ở mọi dãy chèn, xoá, đổi cỡ.
  - ltm, lvm: arith (ép chuỗi theo `luaO_str2d`), `__pow` toàn cục, concat, equal/lessthan/lessequal (chuỗi theo
    `l_strcmp`), gettable/settable qua metamethod, OP_FORLOOP, gọi qua `__call`.
  - lbaselib, lstrlib (mẫu Lua, `format`), ltablib (`sort` là `auxsort` của gốc: thứ tự phần tử bằng nhau phải khớp),
    lmathlib (`__pow` là pow thật, `math.random` là rand/srand của MSVCR110: LCG 214013, 2531011), getn/setn của lauxlib.
  - Số ↔ chuỗi: dùng lại `ui/panel/lua_value` (đã đo `%.14g` và `strtod` của MSVCR110); dời nó vào module `lua` nếu cần.
- Thu gom rác mark-sweep, chỉ chạy ở `State::collect()` khi độ sâu gọi là 0; gốc là bảng toàn cục, registry, giá trị chủ ghim.
- Trần (Khác gốc, để client không treo hay tràn ngăn xếp C 1 MB): độ sâu gọi 200 ("stack overflow"), số lần quay vòng mỗi
  lần gọi từ chủ, byte heap ("not enough memory").
- `tostring` của bảng và hàm: không có địa chỉ (gốc in địa chỉ, không tất định). Khoá là bảng hay hàm băm theo số thứ tự tạo
  (gốc băm theo địa chỉ, cũng không tất định).
- Test `Test/Lua/lua_tests.cpp` (logic thuần, sai thì hỏng thầm): số vàng sinh từ chính LuaPlus.dll bằng
  `python -B TOOLS/port/lua_rt_golden.py "D:/XTLBB/Bin64" Test/golden/lua/lib_cases.tsv` (không sửa tay), 10 835 ca chạy trong
  CÙNG MỘT State và so từng ký tự: mọi hàm base/string/table/math (kể cả câu lỗi, đối số sau lời gọi, vết hàm gọi lại, thứ tự
  `pairs` của mọi bảng thư viện và `_G`), rồi phép toán VM (số học và ép chuỗi, `^` XOR, `__pow`, concat, so sánh, mọi
  metamethod, index và set trên mọi kiểu, call, vòng `for` số, vararg, 40 hình dạng hàm dựng bảng). Bên DLL mỗi ca VM là một
  hàm Lua nhỏ; bên runtime là mã C++ dựng tay đúng như bộ dịch sinh (`op_*` trong tệp test).
- Khác gốc (đo trên LuaPlus.dll hoặc không thể giống; mỗi mục có `Khác gốc:` ở đầu tệp nguồn tương ứng):
  - Hàm toán `sin cos tan asin acos atan atan2 exp log log10 pow` lấy từ UCRT/libm của máy dựng, chữ số thứ 17 của vài kết quả
    lệch MSVCR110 của DLL tối đa một ulp (`sin(-2.5)`, `cos(1)`, `tan(-2.5)`); chuỗi `tostring` 14 chữ số vẫn khớp. Test chỉ
    nới một ulp cho đúng các hàm này. Các hàm còn lại (`deg` chia cho `PI/180`, `frexp`, `ldexp`, `mod`, `random`, NaN âm, ...) khớp
    từng bit.
  - `string.dump`, `string.lualex`, `loadstring`, `loadfile`, `dofile`, `require`, `coroutine.*`, `newproxy`, `towstring`: có đủ tên
    (thứ tự `pairs` của `_G` và các bảng thư viện khớp DLL) nhưng báo "not supported" — không có trình biên dịch Lua lúc chạy.
  - `xpcall`: hàm xử lý lỗi chạy sau khi ngăn xếp gọi đã gỡ; hàm xử lý tự lỗi thì ra ngay "error in error handling" (gốc gọi lại nó
    đệ quy ~200 lần rồi mới ra câu ấy).
  - Câu lỗi "malformed pattern (ends with `%')" của `find/gfind/gsub` bắt chước đúng lỗi của DLL: giá trị trên cùng của ngăn xếp
    hàm C bị nối vào đầu câu và cặp "%'" mất (`pcall(string.find, "abc", "b%")` ra `b%malformed pattern (ends with `)`).
  - Câu lỗi kiểu không có tên biến (`attempt to index local `a' (a nil value)` của DLL thành `attempt to index a nil value`): phép
    toán của runtime không biết tên biến; trọng tài bỏ phần tên khi sinh số vàng.
  - `tostring` của bảng/hàm in số thứ tự tạo thay địa chỉ; khoá bảng/hàm băm theo số thứ tự tạo (đo bằng `mass_oracle --perturb`:
    2 060/2 060 vết không phụ thuộc địa chỉ).
  - Trần: độ sâu 200, `loop_budget` 100 000 000 lần quay mỗi lần gọi từ chủ, heap 256 MiB mặc định (kẹp tối đa 512 MiB để cỡ
    bảng không vượt `Table::kMaxBits`).
  - `new_table(list_items, record_items)`: `record_items` CHỈ đếm mục `Tên = giá trị`, không đếm `[khoá] = giá trị` (recfield của
    lparser.c chỉ tăng `cc->nh` ở nhánh TK_NAME). Bộ dịch phải đếm đúng như vậy, nếu không thứ tự `pairs` lệch.
  - Không đưa vào số vàng `string.format("% ", 1)`/`("%-", 1)` (định dạng kết thúc ngay sau cờ): vòng quét cờ của gốc đọc quá NUL nên
    DLL cho kết quả khác nhau giữa các lần chạy.
- CMake: `game_module(lua ...)`, dòng `set(game_layer_lua "core lua")` ở `cmake/GameLayers.cmake`.

## Bộ dịch — `TOOLS/port/luagen/` (Python) — thienlong-c8

- Lexer, parser cho phương ngữ ở trên, AST, phân giải phạm vi (cục bộ, upvalue, toàn cục; biến cục bộ bị hàm con bắt
  thành `Cell`, biến khác là `Value` trong biến C++), phát C++ gọi `vm.hpp`.
- Parse 100% của 2 043 tệp và mọi đoạn Lua của layout. Tệp mà chính LuaPlus.dll cũng báo lỗi cú pháp thì liệt kê, xác
  nhận bằng `luaL_loadbuffer` của DLL.
- Giữ thứ tự của lparser.c và lcode.c 5.0.1 (đọc mã, không đoán):
  - biểu thức tính trái sang phải;
  - gán nhiều đích: tính đích và vế phải trước, gán từ phải sang trái (`restassign`);
  - hàm dựng bảng: `new_table(số mục danh sách, số mục có khoá)`, mục có khoá gán ngay khi gặp, mục danh sách xả bằng
    `set_list` theo lô 32 đúng chỗ `closelistfield`/`lastlistfield`, mục cuối là lời gọi thì mở rộng;
  - `a > b` là `less(b, a)`, `a >= b` là `less_equal(b, a)`;
  - chuỗi `a .. b .. c` gộp thành một `concat`;
  - `and`/`or` ngắn mạch và trả giá trị; `not`;
  - `for` số: `index = sub(init, step)` rồi `for_next` mỗi vòng; `for ... in`: gọi `f(s, c)` mỗi vòng, nhận đúng số biến,
    dừng khi biến đầu là nil;
  - `continue`: đo nghĩa trên LuaPlus.dll cho cả `while`, `for`, `repeat ... until` (biến cục bộ của thân có còn thấy
    trong `until` không) trước khi phát;
  - `local function f` khai `f` trước khi tạo closure; biến bị bắt trong thân vòng tạo `Cell` mới mỗi lượt;
  - `return f(x)` trả mọi kết quả.
- Sau mỗi op có thể lỗi: `if (failed(L)) return {};`. Đầu mỗi lượt vòng: `if (!tick(L)) return {};`.
- Số: hex float literal của C++ (đúng từng bit với `float.hex()` của Python). Chuỗi: giải escape của Lua 5.0 (`\ddd` thập
  phân, `\n`, `\\`, xuống dòng sau `\`...), phát dạng `std::string_view` có độ dài (chuỗi có byte 0).
- Đầu ra: mỗi chunk một tệp C++, một tệp sổ cho mỗi cửa sổ (tên → `Chunk`). Sinh lúc dựng bằng CMake (lệnh tuỳ chỉnh phụ
  thuộc mọi `.lua`, layout và mã bộ dịch), vào `<cây dựng>/gen/luagen/`; mã sinh không vào git. 0 cảnh báo dưới
  `game::warnings` trên MSVC, GCC, Clang.
- Đo và báo trước khi nối vào client: số dòng C++, cỡ `.obj`/`.lib`, thời gian dịch MSVC release.
- Test Python `TOOLS/port/luagen/test_luagen.py` cho lexer và parser (ca biên của phương ngữ).

## Đối soát hàng loạt — thienlong-2d

- `TOOLS/port/luagen/world.lua`: thế giới giả viết bằng Lua. Phía gốc chạy nguyên văn trên LuaPlus.dll, phía C++ chạy bản
  dịch của chính nó. Như vậy hai phía dùng một thế giới, khác nhau chỉ ở bản dịch và runtime.
  - `_G` có bảng meta: đọc một tên toàn cục chưa có thì ra đối tượng giả mang tên đó. Gọi phương thức trên đối tượng giả thì
    ghi vết `call Tên:Hàm đối số...` và trả giá trị từ dãy tất định (Park–Miller, số nguyên dưới 2^46 nên đúng tuyệt đối
    trong double).
  - `this` là đối tượng giả; `RegisterEvent` ghi tên sự kiện.
  - Bộ chạy: `PreLoad`, `OnLoad`, mỗi sự kiện đã đăng ký với ba bộ đối số (`arg0..` là chuỗi), mỗi đoạn Lua của layout,
    rồi mọi hàm toàn cục script đã định nghĩa (theo thứ tự định nghĩa). Mỗi bước chạy trong `pcall`; lỗi ghi `!err`
    (không so câu lỗi).
- Chunk layout: một hàm Python sinh từ `layout.xml` một đoạn Lua dữ liệu (cửa sổ, cha, sự kiện → `function() <đoạn> end`),
  dùng chung cho cả hai phía.
- Phía gốc: `TOOLS/port/luagen/mass_oracle.py` ghi vết từng cửa sổ vào `build/luagen/oracle/<cửa sổ>.trace` và bảng tóm
  `Test/golden/lua_mass/oracle.tsv` (cửa sổ, số dòng, sha256) — bảng tóm vào git, vết đầy đủ thì không.
- Phía C++: exe `thienlong_lua_mass` chạy mọi cửa sổ (mỗi cửa sổ một State mới), ghi cùng vết, so với `oracle.tsv`; ctest
  `lua_mass`. Lệch thì in dòng lệch đầu tiên (vết đầy đủ của phía gốc lấy bằng `mass_oracle.py`).
- Vết không phụ thuộc địa chỉ (đo 2026-10-15): `mass_oracle.py --perturb N` giữ N bảng và chuỗi rác trước world để dời địa
  chỉ mọi đối tượng sau đó. Với N = 37 và 1013, 2 060/2 060 sha256 trùng bảng vàng (N = 0), trong khi cùng phép xáo đổi thứ
  tự `pairs` trên tám khoá là bảng (`12837645`, `13458672`, `15387426`). Vậy thứ tự băm theo địa chỉ của runtime (khác gốc)
  không làm lệch vết của kho này; đơn vị mới hay world.lua đổi thì đo lại. Chạy lại không xáo thì trùng từng byte (2 lượt).
- Mục tiêu: mọi cửa sổ khớp. Mỗi cửa sổ lệch là một lỗi của bộ dịch hay runtime, sửa tại gốc rồi chạy lại toàn bộ.

## Cỡ mã sinh — ngân sách trước khi nối vào client

- Đo 2026-10-15 trên bộ phát đầu (`140dc88b`): cả kho 2 060 đơn vị, 24 943 chunk, 77 330 hàm ra 4,39 triệu dòng C++ (187 MB)
  trong 16 s; MSVC `msvc-release` dựng 49 TU trong 408 s tường (khoảng 10 phút CPU), `.text` khoảng 3,2 MB mỗi TU, tức
  155-170 MB mã nếu nối cả kho. Để so: nguồn Lua cả kho 27,5 MB, `Game.exe` 2026 cả tệp 18,6 MB.
- Quyết định: chưa nối mã sinh vào `thienlong_client` cho tới khi `.text` của mã sinh cả kho ≤ 40 MB ở `msvc-release` (cộng
  `.text` của obj dựng không `/Zi`) và `game_luagen` dựng ≤ 3 phút tường ở `-j20`. Lý do: client chạy cả trên điện thoại
  (APK), và cây dựng hằng ngày không được trả 10 phút CPU mỗi lần dựng.
- Đúng trước, gọn sau: giảm mật độ (một nhãn lỗi chung mỗi hàm, gộp `get_global` + `call` ngoài dòng, hằng không kiểm biên
  vì chỉ số biết lúc sinh, tránh `Results` trả theo giá trị ở chỗ chỉ dùng kết quả đầu) làm sau khi `lua_mass` xanh, và mỗi
  bước giảm phải giữ `lua_mass` xanh; đo `.text` trước và sau mỗi bước.
- `game_luagen`, `thienlong_lua_mass` và ctest `lua_mass` chỉ dựng khi cấu hình với `-DGAME_LUA_MASS=ON` (mặc định tắt).

## Thứ tự

1. thienlong-2d: `vm.hpp` và tài liệu này (xong), rồi `world.lua`, `mass_oracle.py`, `oracle.tsv`.
2. thienlong-e7: commit FalagardSuperProgress đang làm (như đã giao), rồi runtime. thienlong-c8: dừng MainMenuBar, sang bộ dịch
   (lexer, parser, phân giải chạy được trên toàn bộ tệp trước, rồi phát C++).
3. Khi c8 phát được một tệp nhỏ (ProgressBar) dịch sạch với `vm.hpp` và e7 có đủ runtime để chạy nó: 2d nối
   `thienlong_lua_mass`, đối soát ProgressBar, rồi mở ra toàn bộ.
4. Xong A thì sang B theo bảng tần suất, rồi C.

## Khác gốc đã biết

- Script đã đổi GBK sang UTF-8 (`src/client/script/NGUON.txt`): `string.len/sub/byte` trên chữ Hán ra số byte khác gốc
  (125 tệp dùng ba hàm này). Đối soát chạy cùng bản UTF-8 ở hai phía nên không lộ; lớp C phải xét từng chỗ.
- Khoá bảng là bảng hay hàm: thứ tự duyệt theo số thứ tự tạo. `tostring` của bảng, hàm: không địa chỉ.
- Trần độ sâu gọi, số lần quay vòng, byte heap.
- Số trong mã nguồn đọc bằng `float()` của Python (làm tròn đúng); `strtod` của MSVCR110 có thể khác ở chuỗi rất nhiều chữ
  số. Đối soát sẽ lộ nếu có.

## Luật làm việc

Như `docs/giao-viec/UI-PORT/GIAO-VIEC.md` mục "Luật chung" và bước 5, 7: worktree riêng, mỗi phần một commit dựng được và
xanh, `check.py` xanh trên tệp C++ đã đổi, báo thienlong-2d mã commit; 2d gộp, dựng lại, chạy `ctest`. Không push.
