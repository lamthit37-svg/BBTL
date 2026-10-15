// Trạng thái ghi được mà hàm game (native_*.cpp) của script giao diện dùng chung. Chủ của host (HUD) dựng một Context, đưa cho
// HostDesc::natives bằng make_natives, cập nhật facts mỗi khung và lấy việc ra khỏi nó (calls, xscript); hàm native tìm Context bằng
// native::context_of(lua_State*). Một luồng, như Host.
#pragma once

#include "hero/hero.hpp"
#include "ui/panel/call.hpp"
#include "ui/script/variable.hpp"
#include "ui/script/xscript.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::ui::script {

// Trần số việc chờ lấy: một script lặp vô hạn trong trần lệnh vẫn đẩy được hàng triệu sự kiện trước khi HUD lấy ra.
inline constexpr std::size_t kCallLimit = 4096;

// Điều game biết về thế giới mà hàm native đọc (phía game ghi, script chỉ đọc). Mỗi trường là nguồn của một hàm; chủ host đặt lại
// từ trạng thái thật mỗi khung.
struct Facts {
    // Id cảnh đang đứng (cột 0 của bảng cảnh); nullopt khi chưa vào cảnh (GetSceneID, IsWuLinZhiDianScene...).
    std::optional<std::int32_t> scene_id;
    // Id NPC đang hội thoại (DataPool:GetCurDialogNpcId); nullopt khi không có hội thoại (gốc trả -1).
    std::optional<std::int32_t> dialog_npc_id;
    // DataPool:LuaFnGetGMVisibleType: loại hiện của GM (byte ở DataPool + 0x632bd8).
    std::uint8_t gm_visible_type = 0;
    // IsZbs2018SpeicalServer: số nguyên ở DataPool + 0x632c0c (máy chủ đặc biệt 2018); 0 là máy chủ thường.
    std::int32_t zbs2018_server = 0;
    // Nhân vật người chơi đang điều khiển (Player:GetData...); nullptr khi chưa vào cảnh, như gốc chưa có đối tượng người chơi.
    // Chủ host đặt lại mỗi khung; con trỏ chỉ dùng trong lúc script chạy, không giữ qua khung.
    const hero::Hero* hero = nullptr;
    // Cờ loại máy chủ ở đối tượng hệ thống của gốc (DAT_141034c40 + 0x6f5868, 0x6f586c, 0x6f5874), Player:GetData đọc ra bằng
    // "IsPKServer_JD", "IsOriginalJD", "Is2606S". Máy chủ ghi; hàm dựng của gốc đặt 0 (Game.exe 0x1400d1120 vùng khởi tạo).
    struct ServerFlags {
        std::int32_t pk_jd = 0;
        std::int32_t original_jd = 0;
        std::int32_t s2606 = 0;
    };
    ServerFlags server;
};

struct Context {
    // Bản ghi XSCRIPT đang soạn và hàng đợi ra (Send_XSCRIPT).
    XScript xscript;
    // Bản ghi XParam của sự kiện đang chạy; nullptr khi sự kiện không mang. Bên đưa sự kiện vào host đặt trước khi post và
    // trả về nullptr sau đó; con trỏ phải sống suốt lời gọi.
    const XParamRecord* xparam = nullptr;
    Facts facts;
    // Bảng biến toàn cục (Variable:GetVariable / SetVariable).
    VariableSystem variables;
    // Việc native nhờ game (PushEvent của hàm nào đó): chủ host lấy ra bằng take_calls cùng chỗ với Host::take_calls.
    std::vector<panel::Call> calls;
    std::size_t dropped_calls = 0;

    // Đẩy sự kiện lên hàng đợi của game, đối số cách nhau bằng tab (ui/panel/call.hpp; Khác gốc: đối số chứa tab bị tách làm nhiều).
    // Quá kCallLimit việc chưa lấy thì bỏ và đếm dropped_calls. noexcept: chạy dưới hàm C mà Lua gọi nên ngoại lệ C++ không được
    // thoát; cấp phát thất bại thì dừng tiến trình.
    void push_event(std::string_view event, std::span<const std::string_view> args) noexcept;
    [[nodiscard]] std::vector<panel::Call> take_calls() noexcept { return std::exchange(calls, {}); }
};

} // namespace game::ui::script
