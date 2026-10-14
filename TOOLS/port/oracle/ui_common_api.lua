-- Hàm toàn cục của game mà nhiều cửa sổ HUD cùng gọi, viết lại bằng Lua theo điều đã đọc từ mã máy Game.exe 2026
-- (TAILIEU/GAME-EXE-2026/decompile.zip, lua_api.tsv): DataPool:IsCanDoAction 0x1402e7d70, PushDebugMessage,
-- PushEvent. Dữ liệu do kịch bản đặt vào __blocking (cửa sổ đang hiện trong tám cửa sổ chặn hành động).

__blocking = {}

-- Tám cửa sổ mà IsCanDoAction hỏi IsWindowShow (tên đọc từ chuỗi trong Game.exe: PS_ShopMag, StallSale,
-- MissionReply, Bank, BigBank, Exchange, Shop, CityShop); một cái hiện là không làm được.
local BLOCKERS = { "PS_ShopMag", "StallSale", "MissionReply", "Bank", "BigBank", "Exchange", "Shop", "CityShop" }

DataPool = rawget(_G, "DataPool") or {}

function DataPool:IsCanDoAction()
    for _, name in ipairs(BLOCKERS) do
        if __blocking[name] then return false end
    end
    return true
end

function PushDebugMessage(text) __note("PushDebugMessage", text) end
function PushEvent(...) __note("PushEvent", unpack(arg)) end
