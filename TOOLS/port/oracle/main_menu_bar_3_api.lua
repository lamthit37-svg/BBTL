-- Hàm của game mà MainMenuBar_3.lua (thanh kỹ năng thú cưng) gọi, ngoài bộ dùng chung ui_common_api.lua:
-- Pet:GetPetSkillBarItemCount 0x14037bcf0 đếm phần tử của vector action thanh kỹ năng thú cưng,
-- Pet:EnumPetSkillBarItem 0x14037bb90 trả action thứ i (ngoài dải trả action rỗng có GetID() bằng 0).
-- Dữ liệu do kịch bản đặt vào __pet_bar (dãy id action, chỉ số Lua từ 1).

__pet_bar = {}

Pet = rawget(_G, "Pet") or {}

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
