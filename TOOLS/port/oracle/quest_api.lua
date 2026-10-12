-- Hàm của game mà QuestLog.lua gọi, viết lại bằng Lua theo điều đã đọc từ mã máy Game.exe 2026
-- (docs/NHIEM-VU-VO-CONG-2026.md), trên dữ liệu do kịch bản đặt vào các bảng __hero, __slots,
-- __offers, __kinds, __track. Kịch bản nạp tệp này bằng --lib rồi điền dữ liệu.

-- Người chơi: các khoá của Player:GetData mà script hỏi.
__hero = { LEVEL = 1, MEMPAI = 9, IsPKServer_JD = 0, LEVEL_CompatPKLV = 1, IsXiaKe = 0, IsOriginalJD = 0 }
-- 20 ô nhiệm vụ đang giữ, chỉ số 0..19; ô trống là nil.
__slots = {}
-- Nhiệm vụ nhận được theo loại: __offers[loại] = { {level=, min=, max=, npc=, scene=, name=, x=, z=,
-- scene_id=}, ... } (đã qua bộ lọc của CollectMissionOutline).
__offers = {}
-- Tên loại nhiệm vụ theo id.
__kinds = {}
-- Trạng thái theo dõi: State_1, State_2 của tệp .trk; nil là chưa có khoá.
__track = {}

Player = {}
function Player:GetData(key)
    local value = __hero[key]
    if value == nil then error("Player:GetData chưa mô phỏng: " .. tostring(key), 2) end
    return value
end

SystemSetup = {}
-- Game.exe 2026 luôn trả 1 (docs/TIEN-DO.md, mục màn đăng nhập).
function SystemSetup:IsClassic() return 1 end

TLCJ = {}
function TLCJ:IsInTLCJScene() return 0 end

function PushEvent(...) __note("PushEvent", unpack(arg)) end
function PushDebugMessage(text) __note("PushDebugMessage", text) end
function CloseFreshManGuide() end
function GetFreshManGuideOwner() return "" end
function OpenWindow(name) __note("OpenWindow", name) end
function CloseWindow(name) __note("CloseWindow", name) end
function CollectMissionOutline() end

function GetMissionOutlineNum(kind)
    local list = __offers[kind]
    if list == nil then return 0 end
    return table.getn(list)
end

function GetMissionOutlineInfo(kind, number)
    local offer = __offers[kind][number]
    local level = offer.level
    if level == -1 then level = __hero.LEVEL end
    return level, offer.min, offer.max, offer.npc, "(,)", offer.scene, offer.name, offer.x, offer.z, offer.scene_id
end

DataPool = {}

-- kind ngoài 0..199 trả số 0 (script nối thành chữ "0"); không có dòng thì mã gốc ném ngoại lệ.
function DataPool:GetMissionInfo_Kind(kind)
    if kind < 0 or kind > 199 then return 0 end
    local name = __kinds[kind]
    if name == nil then error("LUA:GetMissionInfo_Kind index error", 2) end
    return name
end

local function in_use(index)
    return index >= 0 and index <= 19 and __slots[index] ~= nil
end

function DataPool:GetPlayerMission_InUse(index)
    if in_use(index) then return 1 end
    return 0
end

-- Ô sai hay ô trống: _MISSION_INFO mặc định, loại -1; chỉ số ngoài 0..19 trả 0.
function DataPool:GetPlayerMission_Kind(index)
    if index < 0 or index > 19 then return 0 end
    if not in_use(index) then return -1 end
    return __slots[index].kind
end

function DataPool:GetPlayerMission_Description(index) return "" end

-- Chỉ số ngoài 0..19 trả 0; ô trống mang idScript -1, không có dòng theo dõi nào.
function DataPool:GetPlayerMissionTrackType(index)
    if not in_use(index) then return 0 end
    return __slots[index].track_type or 0
end

-- Chưa có khoá State_n trong .trk: theo dõi nhiệm vụ (1) bật, theo dõi hoạt động (2) tắt.
function DataPool:IsTrackFuncShow(which)
    local value = __track["State_" .. which]
    if value == nil then
        if which == 1 then return 1 end
        return 0
    end
    if value > 0 then return 1 end
    return 0
end

function DataPool:SetTrackFuncShow(which, value)
    if which ~= 1 and which ~= 2 then return end
    if value > 0 then __track["State_" .. which] = 1 else __track["State_" .. which] = 0 end
end
