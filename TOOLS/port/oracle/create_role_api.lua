-- Hàm của game mà CreateRole.lua của client 2026 gọi, viết lại theo mã máy Game.exe
-- (docs/TAO-NHAN-VAT-2026.md nêu địa chỉ từng hàm). Dữ liệu là bảng thật của client, đưa vào bằng
-- --table: portraits (portraits.tsv), faces (faces.tsv), hairs (hairs.tsv), outfits
-- (newbie_outfits.tsv) của CLIENT/data/Table. Giới 0 là nữ, 1 là nam; chỉ số bắt đầu từ 0 như
-- script gọi.
-- Hàm đổi trạng thái của game (SetFaceId, SetFaceModelId, ShowModel...) ghi lại bằng __note, kèm
-- id mà game sẽ nhận, để số vàng nêu được script đã chọn gì.

-- choice 1 hay 3 là chọn được lúc tạo: mã máy viết (choice - 1) & ~2 == 0.
local function creatable(choice)
    return choice == 1 or choice == 3
end

-- Sắp ổn định tăng dần theo order (std::stable_sort với phép so a.order < b.order).
local function stable_sort(list)
    for index = 2, table.getn(list) do
        local item = list[index]
        local at = index - 1
        while at >= 1 and item.order < list[at].order do
            list[at + 1] = list[at]
            at = at - 1
        end
        list[at + 1] = item
    end
end

-- CharacterFaceMng (nạp ở 0x14063df70): mỗi giới một dãy MỌI dòng của giới đó theo thứ tự tệp, sắp
-- ổn định theo cột order; số ảnh "cho màn tạo" là số dòng có choice 1 hay 3.
local portraits = { [0] = {}, [1] = {} }
local portrait_counts = { [0] = 0, [1] = 0 }
for _, row in ipairs(__tables.portraits) do
    local race = tonumber(row.race)
    if race == 0 or race == 1 then
        local item = {
            id = tonumber(row.id), image = row.image, choice = tonumber(row.choice), order = tonumber(row.order),
        }
        table.insert(portraits[race], item)
        if creatable(item.choice) then portrait_counts[race] = portrait_counts[race] + 1 end
    end
end
stable_sort(portraits[0])
stable_sort(portraits[1])

-- FaceModelMng (nạp ở 0x14063fa20): mỗi giới một dãy mọi dòng theo thứ tự tệp, không lọc.
local faces = { [0] = {}, [1] = {} }
for _, row in ipairs(__tables.faces) do
    local race = tonumber(row.race)
    if race == 0 or race == 1 then
        table.insert(faces[race], { id = tonumber(row.id), name = row.name, choice = tonumber(row.choice) })
    end
end

-- HairModelMng (nạp ở 0x140642d20) của thủ tục tạo nhân vật: cờ chế độ bằng 0 nên chỉ giữ dòng có
-- choice 1 hay 3, theo thứ tự tệp.
local hairs = { [0] = {}, [1] = {} }
for _, row in ipairs(__tables.hairs) do
    local race = tonumber(row.race)
    if (race == 0 or race == 1) and creatable(tonumber(row.choice)) then
        table.insert(hairs[race], { id = tonumber(row.id), name = row.name })
    end
end

-- Bộ đồ tân thủ (nạp ở 0x140640ec0): mọi dòng theo thứ tự tệp.
local outfits = {}
for _, row in ipairs(__tables.outfits) do
    table.insert(outfits, { id = tonumber(row.id), name = row.name })
end

-- Phần tử thứ index (từ 0) của list[sex]; nil khi giới lạ hay chỉ số ngoài dãy.
local function pick(list, sex, index)
    local own = list[sex]
    if own == nil or index < 0 then return nil end
    return own[index + 1]
end

-- Id mà game ghi nhận: bộ quản trả 0 khi chỉ số ngoài dãy (0x14063fb90, 0x140642ea0).
local function id_of(item)
    if item == nil then return 0 end
    return item.id
end

-- Script gọi hàm của game bằng số; đối số không phải số thì mã máy ném lỗi.
local function number(value, where)
    if type(value) ~= "number" then error("LUA:" .. where .. " param parameter error", 3) end
    return value
end

GameProduceLogin = {}

function GameProduceLogin:GetWomanFaceCountForCreate() return portrait_counts[0] end
function GameProduceLogin:GetManFaceCountForCreate() return portrait_counts[1] end

-- 0x140342850: ảnh chỉ trả khi dòng đó chọn được lúc tạo; không thì chuỗi rỗng.
function GameProduceLogin:GetFaceName(sex, index)
    local item = pick(portraits, number(sex, "GetFaceName"), number(index, "GetFaceName"))
    if item == nil or not creatable(item.choice) then return "" end
    return item.image
end

-- 0x140342950: chỉ nhận dòng chọn được lúc tạo.
function GameProduceLogin:SetFaceId(sex, index)
    local item = pick(portraits, number(sex, "SetFaceId"), number(index, "SetFaceId"))
    if item == nil or not creatable(item.choice) then return end
    __note("SetFaceId", sex, index, item.id)
end

function GameProduceLogin:GetFaceModelCount(sex)
    local own = faces[number(sex, "GetFaceModelCount")]
    if own == nil then return 0 end
    return table.getn(own)
end

-- 0x14063fe40: cột choice của dòng; -1 khi không có dòng.
function GameProduceLogin:GetFaceModelInfo(sex, index)
    local item = pick(faces, number(sex, "GetFaceModelInfo"), number(index, "GetFaceModelInfo"))
    if item == nil then return -1 end
    return item.choice
end

function GameProduceLogin:GetFaceModelName(sex, index)
    local item = pick(faces, number(sex, "GetFaceModelName"), number(index, "GetFaceModelName"))
    if item == nil then return "" end
    return item.name
end

function GameProduceLogin:SetFaceModelId(sex, index)
    local item = pick(faces, number(sex, "SetFaceModelId"), number(index, "SetFaceModelId"))
    __note("SetFaceModelId", sex, index, id_of(item))
end

function GameProduceLogin:GetHairModelCount(sex)
    local own = hairs[number(sex, "GetHairModelCount")]
    if own == nil then return 0 end
    return table.getn(own)
end

function GameProduceLogin:GetHairModelName(sex, index)
    local item = pick(hairs, number(sex, "GetHairModelName"), number(index, "GetHairModelName"))
    if item == nil then return "" end
    return item.name
end

function GameProduceLogin:SetHairModelId(sex, index)
    local item = pick(hairs, number(sex, "SetHairModelId"), number(index, "SetHairModelId"))
    __note("SetHairModelId", sex, index, id_of(item))
end

function GameProduceLogin:GetEquipSetCount() return table.getn(outfits) end

function GameProduceLogin:GetEquipSetName(index)
    number(index, "GetEquipSetName")
    if index < 0 then return "" end
    local item = outfits[index + 1]
    if item == nil then return "" end
    return item.name
end

-- 0x140641210: nhớ giới và chỉ số trước, rồi mới tra dòng; không có dòng thì id bộ đồ giữ nguyên
-- (ở đây ghi thiếu cột id).
function GameProduceLogin:ChangeNewRoleEquipSet(sex, index)
    number(sex, "ChangeNewRoleEquipSet")
    number(index, "ChangeNewRoleEquipSet")
    local item = outfits[index + 1]
    if index < 0 or item == nil then
        __note("ChangeNewRoleEquipSet", sex, index)
        return
    end
    __note("ChangeNewRoleEquipSet", sex, index, item.id)
end

function GameProduceLogin:ShowModel(menpai) __note("ShowModel", number(menpai, "ShowModel")) end
function GameProduceLogin:ModelRotBegin(spin) __note("ModelRotBegin", spin) end
function GameProduceLogin:ModelRotEnd(spin) __note("ModelRotEnd", spin) end
function GameProduceLogin:ModelZoom(speed) __note("ModelZoom", speed) end

-- 0x1403432b0: cờ "chỉ được dùng tên ngẫu nhiên" do máy chủ đặt; chưa nối máy chủ nào thì 0.
function GameProduceLogin:GetIsForbidName() return 0 end

-- 0x14033fcb0: chưa chọn máy chủ nào thì -1.
function GameProduceLogin:GetSelectLoginServerZWID() return -1 end

function GameProduceLogin:CreateRole(name, sex, first, last) __note("CreateRole", name, sex, first, last) end
function GameProduceLogin:ChangeToSelectRoleDlgFromCreateRole() __note("ChangeToSelectRoleDlgFromCreateRole") end
function GameProduceLogin:GameLoginShowSystemInfo(text) __note("GameLoginShowSystemInfo", text) end

-- 0x14045fbb0: bản 2026 luôn trả 1 (giao diện cổ điển).
SystemSetup = {}
function SystemSetup:IsClassic() return 1 end

-- 0x140301630: máy chủ mang mã zwid có phải "máy chủ mới" không; không có dòng cho -1 nên 0.
DataPool = {}
function DataPool:Lua_IsNewServerPlayerByZWID(zwid) return 0 end
