// Hàm của game mà script giao diện gọi (tầng B của LUA-GEN, docs/giao-viec/LUA-GEN/TANG-B.md): DataPool, và các bảng hay hàm
// toàn cục khác khi có. Mỗi hàm ghi địa chỉ mã máy của client 3.71.9509 (Game.exe, UI_CEGUI.dll) ở chỗ định nghĩa.
// Đưa vào host bằng HostDesc::natives = open_natives. Chỉ C API của Lua và ui/panel (logic thuần): dựng được ở mọi nền tảng.
#pragma once

struct lua_State;

namespace game::ui::script {

// Đăng ký mọi hàm của game vào _G của state. Gọi trong lua_cpcall (lỗi cấp phát Lua không làm chết tiến trình).
void open_natives(lua_State* lua);

} // namespace game::ui::script
