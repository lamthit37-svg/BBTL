-- Hàm của game mà bốn thanh action (MainMenuBar_2, FunctionBarRight, FunctionBarRight_2, MainMenuBar_4) gọi, ngoài
-- bộ dùng chung ui_common_api.lua, viết lại bằng Lua theo điều đã đọc từ mã máy Game.exe 2026 (lua_api.tsv):
-- - Pet:IsPresent 0x14036e850 và Pet:GetIsFighting 0x140372ff0: dữ liệu ở __pets.present và __pets.fighting.
-- - Target:UpdateActionButton 0x140687a74 chuyển tiếp sang ô ảo 15 của đối tượng đang chọn: ghi một việc nhờ.
-- - DataPool:Get_RMB_ChatActionInfo 0x1402f2bf0 trả (id gói, chữ hạn dùng, số hành động, chỉ số đầu, loại); ba số
--   cuối là cột của dòng DBC 0xfd ứng id gói. Get_RMB_ChatActionRealID 0x1402f2ff0 trả cột +4 của dòng đó.
--   Dữ liệu ở __chat_packs[ô] = { id, count, min, kind } và __real_ids[id]; gói chưa cài trả toàn số 0.
-- - Talk:EnumChatMood 0x14047e8a0 và Talk:EnumDoubleChatMood 0x14047ea30 trả action thứ i của danh sách
--   "chatmood" / "double_chatmood" của hệ action; ngoài dải trả action rỗng (GetID() bằng 0). Dữ liệu ở __moods
--   và __double_moods (chỉ số Lua từ 1, ứng i từ 0).
-- - DataPool:UnInstall_RMB_ChatAction_BarItem 0x1402f3270, UnInstall_RMB_ChatAction 0x1402f30d0,
--   Set_RMB_ChatAction 0x1402f3440, Clear_ChatAction_Bar 0x1402f32d0: chỉ ghi việc nhờ (đổi trạng thái hay đẩy
--   sự kiện, gói tin do game làm).
-- Mọi hàm kiểm kiểu đối số như bản gốc (tThrowStringException khi sai) nên script gọi sai thì dừng với lỗi.

__pets = { present = {}, fighting = {} }
__chat_packs = {}
__real_ids = {}
__moods = {}
__double_moods = {}

Pet = rawget(_G, "Pet") or {}
Target = rawget(_G, "Target") or {}
Talk = rawget(_G, "Talk") or {}
DataPool = rawget(_G, "DataPool") or {}

function Pet:IsPresent(index) return __pets.present[index] == true end
function Pet:GetIsFighting(index) return __pets.fighting[index] == true end

function Target:UpdateActionButton() __note("UpdateActionButton") end

local function need_numbers(name, ...)
    for index = 1, arg.n do
        if type(arg[index]) ~= "number" then
            error("Lua Interface<DataPool> : " .. name .. " parameter error!", 3)
        end
    end
end

function DataPool:Get_RMB_ChatActionInfo(index)
    need_numbers("Get_RMB_ChatActionInfo", index)
    local pack = __chat_packs[index]
    if pack == nil then return 0, "", 0, 0, 0 end
    return pack.id, pack.date or "", pack.count, pack.min, pack.kind
end

function DataPool:Get_RMB_ChatActionRealID(id)
    need_numbers("Get_RMB_ChatActionRealID", id)
    return __real_ids[id] or 0
end

-- Action rỗng của mã gốc (bảng ảo PTR_vftable_140ed9180): GetID() trả 0.
local function action_of(id)
    return { GetID = function() return id end }
end

function Talk:EnumChatMood(index)
    if type(index) ~= "number" then error("LUA: EnumChatMood Wrong Param1", 2) end
    if index < 0 then return action_of(0) end
    return action_of(__moods[index + 1] or 0)
end

function Talk:EnumDoubleChatMood(index)
    if type(index) ~= "number" then error("LUA: EnumDoubleChatMood Wrong Param", 2) end
    if index < 0 then return action_of(0) end
    return action_of(__double_moods[index + 1] or 0)
end

function DataPool:UnInstall_RMB_ChatAction_BarItem(position)
    need_numbers("UnInstall_RMB_ChatAction", position)
    __note("UnInstall_RMB_ChatAction_BarItem", position)
end

function DataPool:UnInstall_RMB_ChatAction(index, kind)
    need_numbers("UnInstall_RMB_ChatAction", index, kind)
    __note("UnInstall_RMB_ChatAction", index, kind)
end

function DataPool:Set_RMB_ChatAction(index, id, data)
    need_numbers("Set_RMB_ChatAction", index, id, data)
    __note("Set_RMB_ChatAction", index, id, data)
end

function DataPool:Clear_ChatAction_Bar(name, index, id, data)
    if type(name) ~= "string" and type(name) ~= "number" then
        error("Lua Interface<DataPool> : Clear_ChatAction_Bar parameter error!", 2)
    end
    need_numbers("Clear_ChatAction_Bar", index, id, data)
    __note("Clear_ChatAction_Bar", name, index, id, data)
end
