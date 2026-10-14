-- Hàm của game mà FunctionBarRight.lua gọi ngoài bộ dùng chung ui_common_api.lua và action_bar_api.lua:
-- DataPool:LuaFnGetGMVisibleType 0x14031b6b0 (byte kiểu hiện của GM, đẩy thành số; 0 là người chơi thường) và
-- ZBS:IsViewerWatching 0x1403ca720 (số; lớn hơn 0 là đang ở chế độ xem trận). Kịch bản đặt vào __gm_visible và __viewer.
__gm_visible = 0
__viewer = 0

DataPool = rawget(_G, "DataPool") or {}
function DataPool:LuaFnGetGMVisibleType() return __gm_visible end

ZBS = rawget(_G, "ZBS") or {}
function ZBS:IsViewerWatching() return __viewer end
