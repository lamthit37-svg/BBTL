# runtime — máy Lua 5.0.1 tự viết bằng C++ (mã tham khảo)

Hướng này **đã bỏ** ngày 2026-10-15 (chủ dự án chốt: dùng thẳng LuaPlus 5.0.1 từ mã client TLBB, `third_party/luaplus`; "mã của tôi
lấy thẳng source sang, có gì cải tiến thì cải tiến luôn"). Thư mục này giữ mã đã viết làm tham khảo: **không dựng, không nằm trong
ctest, không còn trong bảng tầng** (`cmake/GameLayers.cmake`).

## Gồm gì

- `lua/`: module `lua` cũ (`game::lua`) — giá trị `Value`, chuỗi intern, bảng (`table.cpp` theo `ltable.c`), `State`, các phép của máy
  ảo (`ops.cpp`, `vm.hpp` là bề mặt mà mã C++ sinh gọi), thư viện chuẩn base/string/table/math (`lib_*.cpp`), hướng chủ `host.hpp`
  (`raise_error`, `set_metatable`), `gen_support.hpp`.
- `luamass/`: `thienlong_lua_mass`, chạy mọi đơn vị mà bộ phát C++ (`../generate.py`) sinh vào `game_luagen`, so sha256 vết với
  `Test/golden/lua_mass/oracle.tsv`. **Chưa chạy lần nào**: mã sinh không bao giờ đủ nhỏ để dựng cả kho (xem `../GHI-CHU.md`).
- `Test/Lua/lua_tests.cpp`: 3 ca; ca chính chạy 10 835 lời gọi thư viện và phép toán của máy ảo (mã C++ dựng tay đúng như bộ
  phát sinh cho từng hàm Lua nhỏ) so với `Test/golden/lua/lib_cases.tsv`.

## Trạng thái và số đo (trung thực)

- Trước khi bỏ: 10 835/10 835 ca số vàng khớp `LuaPlus.dll` (chữ số thứ 17 của sin, cos, tan, asin, acos, atan, atan2, exp, log,
  log10, pow được lệch một ulp). Câu lỗi của số vàng đã gỡ tên biến ("on local `a'") vì runtime này không có tên biến — số vàng sinh
  lại ngày 2026-10-15 để chạy trên LuaPlus gốc **giữ** tên biến, nên test này không còn khớp số vàng hiện hành.
- Chưa từng chạy script giao diện thật: chưa có bộ nạp bytecode hay trình biên dịch (hướng "bytecode + máy thông dịch" bị bỏ trước khi
  bắt đầu, hướng sinh C++ bị bỏ vì cỡ mã: `../GHI-CHU.md`).
- Chi phí một lời gọi hàm (msvc-release, i5-14600KF): `call()` 18,7 ns; LuaPlus gốc dựng cùng máy gọi hàm native 15,0 ns, hàm Lua
  13,9 ns (`docs/giao-viec/LUA-GEN/THIET-KE.md`). Gốc nhanh hơn, nên không có lý do giữ máy tự viết.

## Dùng lại

Chép `lua/` về `src/client/face/lua/`, `luamass/` về `src/client/face/luamass/`, test về `Test/Lua/`, rồi lấy khối `game_module(lua ...)`,
`game_test(lua ...)`, khối `luamass` trong CMake và hai dòng `game_layer_lua`, `game_layer_luamass` ở commit `4e90be7c`
(`git show 4e90be7c:CMakeLists.txt`, `git show 4e90be7c:cmake/GameLayers.cmake`). Số của máy này đi qua `luanum`
(`src/client/face/luanum`); module `lua` cũ include `lua/number.hpp`, `lua/cformat.hpp`, là hai tệp chuyển tiếp (`using luanum::...` trong
`game::lua`) có ở commit `4e90be7c` (`git show 4e90be7c:src/client/face/lua/number.hpp`).
