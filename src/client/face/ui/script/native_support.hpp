// Hạ tầng chung của hàm game viết bằng C++ cho script giao diện (tầng B của LUA-GEN, docs/giao-viec/LUA-GEN/TANG-B.md): đăng ký
// bảng và hàm toàn cục, đọc đối số theo quy ước của Game.exe, tìm Context. Hàm native viết theo lua/native.hpp (NativeResult +
// lua::adapt): LuaPlus báo lỗi bằng longjmp nên thân hàm không giữ đối tượng có destructor qua một lời gọi API Lua.
//
// Quy ước đối số của Game.exe (đo trên bản trích 9001 ở TANG-B.md mục 1.2), mỗi hàm tự chọn một trong hai:
//  - số NGHIÊM: lua_type == LUA_TNUMBER (chuỗi số "5" không qua) rồi lua_tonumber, ép (int) bằng cvttsd2si;
//  - chuỗi: lua_isstring (chuỗi hay số), lấy bằng lua_tostring.
// Chỉ số đối số theo C API: hàm gọi bằng `Bảng:Hàm(x)` có self ở 1 và x ở 2; hàm toàn cục `Hàm(x)` có x ở 1.
// Lỗi sai tham số mỗi hàm có câu riêng của Game.exe (tThrowStringException), không có câu chung.
#pragma once

#include "lua/capi.hpp"
#include "lua/native.hpp"

#include <cstdint>
#include <optional>
#include <span>
#include <string_view>

namespace game::ui::script {

struct Context;

namespace native {

struct Entry {
    const char* name;
    lua_CFunction function;
};

// Đăng ký vào _G. Gọi trong lua_cpcall (host chạy HostDesc::natives ở đó).
void register_globals(lua_State* lua, std::span<const Entry> entries);
// Đăng ký vào bảng toàn cục `table` (tạo nếu chưa có; nhiều nhóm cùng góp vào một bảng, như DataPool). Gọi trong lua_cpcall.
void register_table(lua_State* lua, const char* table, std::span<const Entry> entries);

// Gắn Context cho state: hàm native lấy lại bằng context_of. Gọi trong lua_cpcall, một lần mỗi state (open_natives).
void attach(lua_State* lua, Context& context);
// Context của state. Vi phạm hợp đồng (chưa attach) là lỗi lập trình: dừng bằng core::check.
[[nodiscard]] Context& context_of(lua_State* lua);

// Đối số index là số nghiêm (lua_type == LUA_TNUMBER); nullopt nếu không.
[[nodiscard]] std::optional<double> strict_number(lua_State* lua, int index);
// Đối số index là chuỗi hoặc số (lua_isstring), trả về nội dung (số được đổi thành chuỗi tại chỗ như lua_tostring); nullopt nếu
// không. string_view trỏ vào chuỗi do Lua giữ, hợp lệ tới khi giá trị rời ngăn xếp.
[[nodiscard]] std::optional<std::string_view> text_arg(lua_State* lua, int index);
// Phần đầu của chuỗi tới byte NUL đầu tiên: các hàm của gốc lấy chuỗi bằng GetString (char*) nên NUL nhúng trong chuỗi Lua cắt nó.
[[nodiscard]] inline std::string_view c_string(std::string_view text) noexcept { return text.substr(0, text.find('\0')); }
// Ép double sang int32 như (int) của C trên x64 (cvttsd2si): ngoài miền hay NaN ra INT32_MIN.
[[nodiscard]] std::int32_t to_int(double value) noexcept;
// Câu "sai tham số" kèm kiểu Lua của đối số index (số theo lua_type: nil 0, boolean 1, lightuserdata 2, number 3, string 4, table 5,
// function 6, userdata 7, thread 8), dùng cho hàm mà Game.exe in kiểu vào câu lỗi.
[[nodiscard]] int type_at(lua_State* lua, int index);

} // namespace native
} // namespace game::ui::script
