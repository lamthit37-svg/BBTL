// Trạng thái ghi được mà hàm game (native_*.cpp) của script giao diện dùng chung. Chủ của host (HUD) dựng một Context, đưa cho
// open_natives, và lấy việc ra khỏi nó mỗi khung; hàm native tìm Context bằng native::context_of(lua_State*). Một luồng, như Host.
#pragma once

#include "ui/script/xscript.hpp"

namespace game::ui::script {

struct Context {
    // Bản ghi XSCRIPT đang soạn và hàng đợi ra (Send_XSCRIPT).
    XScript xscript;
    // Bản ghi XParam của sự kiện đang chạy; nullptr khi sự kiện không mang. Bên đưa sự kiện vào host đặt trước khi post và
    // trả về nullptr sau đó; con trỏ phải sống suốt lời gọi.
    const XParamRecord* xparam = nullptr;
};

} // namespace game::ui::script
