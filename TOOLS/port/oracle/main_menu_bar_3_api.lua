-- Hàm của game mà MainMenuBar_3.lua (thanh kỹ năng thú cưng) gọi, viết lại bằng Lua theo điều đã đọc từ
-- mã máy Game.exe 2026 (TAILIEU/GAME-EXE-2026/decompile.zip, xem lua_api.tsv): Pet:GetPetSkillBarItemCount
-- 0x14037bcf0 đếm phần tử của vector action thanh kỹ năng thú cưng, Pet:EnumPetSkillBarItem 0x14037bb90 trả
-- action thứ i (ngoài dải trả action rỗng có GetID() bằng 0), DataPool:IsCanDoAction 0x1402e7d70. Dữ liệu do
-- kịch bản đặt vào __pet_bar (dãy id action, chỉ số Lua từ 1) và __blocking (cửa sổ đang hiện trong tám cửa
-- sổ chặn hành động).

__pet_bar = {}
__blocking = {}

Pet = {}

function Pet:GetPetSkillBarItemCount()
    return table.getn(__pet_bar)
end

-- Action rỗng của mã gốc (bảng ảo PTR_vftable_140ed9180): GetID() trả 0.
local function action_of(id)
    return { GetID = function() return id end }
end

function Pet:EnumPetSkillBarItem(index)
    if index < 0 or index >= table.getn(__pet_bar) then return action_of(0) end
    return action_of(__pet_bar[index + 1])
end

-- Tám cửa sổ mà IsCanDoAction hỏi IsWindowShow (tên đọc từ chuỗi trong Game.exe: PS_ShopMag, StallSale,
-- MissionReply, Bank, BigBank, Exchange, Shop, CityShop); một cái hiện là không làm được.
local BLOCKERS = { "PS_ShopMag", "StallSale", "MissionReply", "Bank", "BigBank", "Exchange", "Shop", "CityShop" }

DataPool = {}

function DataPool:IsCanDoAction()
    for _, name in ipairs(BLOCKERS) do
        if __blocking[name] then return false end
    end
    return true
end

function PushDebugMessage(text) __note("PushDebugMessage", text) end
