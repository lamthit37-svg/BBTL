-- Hàm của game mà FunctionBarRight_2.lua gọi ngoài bộ dùng chung ui_common_api.lua và action_bar_api.lua:
-- DataPool:GetTrans 0x1402fb940 (trạng thái biến hình của người chơi, 1 là đang biến hình; kịch bản đặt vào __trans).
__trans = 0

DataPool = rawget(_G, "DataPool") or {}
function DataPool:GetTrans() return __trans end
