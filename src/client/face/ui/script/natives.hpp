// Hàm của game mà script giao diện gọi (tầng B của LUA-GEN, docs/giao-viec/LUA-GEN/TANG-B.md): DataPool, và các bảng hay hàm
// toàn cục khác khi có. Mỗi hàm ghi địa chỉ mã máy của client 3.71.9509 (Game.exe, UI_CEGUI.dll) ở chỗ định nghĩa.
// Đưa vào host bằng HostDesc::natives = make_natives(context). Chỉ C API của Lua và ui/panel (logic thuần): dựng được ở mọi nền tảng.
#pragma once

#include <functional>

struct lua_State;

namespace game::ui::script {

struct Context;

// Đăng ký mọi hàm của game vào _G của state. Gọi trong lua_cpcall (lỗi cấp phát Lua không làm chết tiến trình).
// Hàm của nhóm cần Context (XSCRIPT, XParam...) tìm nó bằng native::context_of: chủ của host gắn Context cho state bằng native::attach
// (native_support.hpp) cùng chỗ gọi hàm này, trước khi script nào chạy; chưa gắn mà script gọi hàm cần Context là lỗi lập trình.
void open_natives(lua_State* lua);

// Việc của HostDesc::natives cho chủ host: open_natives rồi native::attach(context). context phải sống lâu hơn máy Lua.
[[nodiscard]] std::function<void(lua_State*)> make_natives(Context& context);

} // namespace game::ui::script
