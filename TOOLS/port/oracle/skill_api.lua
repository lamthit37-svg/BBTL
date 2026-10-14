-- Hàm của game mà bốn script sách võ công (CommonSkill, LifeSkill, ActionSkill, ZhenfaSkill) gọi,
-- viết lại bằng Lua theo điều đã đọc từ mã máy Game.exe 2026 (docs/NHIEM-VU-VO-CONG-2026.md; địa chỉ
-- hàm gốc ghi ở từng hàm). Bản C++ của cùng các hàm là module skill (SRC/skill) và phần mở sách của
-- SRC/ui/panel/skill_tabs.cpp; hai bản phải cho cùng kết quả trên cùng dữ liệu.
-- Kịch bản nạp tệp này bằng --lib, điền bảng vào __tables và người chơi vào __hero, rồi ghi sách
-- bằng __skill_list, __set_skill_class, __set_life_ability như máy chủ gửi gói.

-- Bảng của client. skills[id] = { sect=, name=, icon=, inner_art=, inner_art_level=, level_offset=,
-- user_class=, passivity=, must_learn=, column_101=, explain=, data={[0]=..,[1]=..} (thiếu là -1) };
-- levels[id] = mô tả theo bậc; arts[id] = { sect=, name=, explain=, icon=, need_level= };
-- costs = { { level=, [id tâm pháp] = { tiền, kinh nghiệm } }, ... } theo thứ tự của bảng;
-- life[id] = { name=, max_level=, level_table=, icon=, explain=, popup=, consume= };
-- life_levels[tên bảng][cấp] = trần độ thuần thục nhân 100.
__tables = { skills = {}, levels = {}, arts = {}, costs = {}, life = {}, life_levels = {} }
-- Người chơi: các khoá của Player:GetData mà bốn script hỏi.
__hero = { LEVEL = 1, MEMPAI = 9, XINFASCORE = 0, XIULIANSCORE = 0, EQUIPGEMXIULIANSCORE = 0, Is2606S = 0 }
-- Sách kỹ năng (ba std::map của SDATA_PLAYER_MYSELF): id sang mục, và số mục để tính PosIndex.
__book = { skills = {}, skill_count = 0, arts = {}, art_count = 0, life = {}, life_count = 0 }
-- Trang sách cuối ([data pool + 0x1f8], bộ dựng đặt -1) và id cảnh đang chơi (-1 là không có).
__last_skill_ui = -1
__scene = -1

-- Hệ action -----------------------------------------------------------------------------------

-- Số loại theo bảng tên của Game.exe (0x140ed88d0); tên không có trong bảng là 0.
local type_numbers = { skill = 1, life = 2, packageitem = 3, bankitem = 4, boothitem = 5, lootitem = 6,
    xinfa = 7, xiulianbook = 8, xiulianmiji = 9, petskill = 10, virtualitem = 11, equip = 12 }

-- Mọi action theo id (m_mapAllAction) và bộ đếm id chung (0x140ed8218).
__actions = {}
__next_action = 1

local methods = {}
local action_meta = { __index = methods }

local function new_action(kind, define)
    local id = __next_action
    if id < 0 then id = 1 end
    __next_action = id + 1
    local item = { id = id, kind = kind, define = define }
    setmetatable(item, action_meta)
    __actions[id] = item
    return item
end

-- Get_Skill (0x140193c20): kỹ năng không cần học trước thì nhân vật nào cũng có, PosIndex -1.
local function get_skill(id)
    local row = __tables.skills[id]
    if row ~= nil and (row.must_learn <= 0 or row.column_101 == 2) then
        return { row = row, id = id, pos = -1, learned = true }
    end
    return __book.skills[id]
end

-- Mục mà một action trỏ tới (GetImpl); nil khi không còn.
local function impl_of(item)
    if item.kind == "skill" then return get_skill(item.define) end
    if item.kind == "xinfa" then return __book.arts[item.define] end
    if item.kind == "life" then return __book.life[item.define] end
    return nil
end

local function type_number(item)
    if item.kind == "pet" or item.kind == "empty" then return 0 end
    return type_numbers[item.kind]
end

-- Các id action theo thứ tự tăng dần.
local function action_ids()
    local ids = {}
    for id in pairs(__actions) do table.insert(ids, id) end
    table.sort(ids)
    return ids
end

function methods.GetID(self) return self.id end
function methods.GetName(self) return self.name end
function methods.GetDefineID(self)
    if impl_of(self) == nil then return -1 end
    return self.define
end

-- GetOwnerXinfa (0x1400136d0). Nhánh -8888 (vật phẩm ở ô trang bị 18) không có: chưa có trang bị.
function methods.GetOwnerXinfa(self)
    if self.kind ~= "skill" then return -1 end
    local skill = impl_of(self)
    if skill == nil or skill.row.user_class ~= 0 then return -1 end
    for _, id in ipairs(action_ids()) do
        local item = __actions[id]
        if item.kind == "xinfa" and item.define == skill.row.inner_art then return item.id end
    end
    return -9999
end

-- Action rỗng (đối tượng tĩnh 0x140ed8180): id 0, tên rỗng.
local empty_action = { id = 0, kind = "empty", define = -1, name = "" }
setmetatable(empty_action, action_meta)

-- Gỡ action của một loại mà dữ liệu không còn, rồi tạo action cho mục chưa có theo id tăng dần
-- (UserSkill_Update 0x14001bc50, SkillClass_Update 0x14001d6a0, UserLifeAbility_Update 0x14001c770).
local function sync(kind, owned, name_of)
    for _, id in ipairs(action_ids()) do
        local item = __actions[id]
        if item.kind == kind and impl_of(item) == nil then __actions[id] = nil end
    end
    local wanted = {}
    for define in pairs(owned) do table.insert(wanted, define) end
    table.sort(wanted)
    for _, define in ipairs(wanted) do
        local has = false
        for _, item in pairs(__actions) do
            if item.kind == kind and item.define == define then has = true end
        end
        if not has then new_action(kind, define).name = name_of(define) end
    end
end

-- Bốn action thú cưng do CActionSystem::Initial (0x140018750) tạo; tên là chữ của khoá từ điển.
__pets = {}
function __init_actions(pet_names)
    __actions = {}
    __next_action = 17
    for index = 1, 4 do
        local item = new_action("pet", index - 1)
        item.name = pet_names[index]
        __pets[index] = item
    end
end

-- CCharacterData::Set_SkillClass (0x140191320) rồi SkillClass_Update.
function __set_skill_class(id, level)
    local own = __book.arts[id]
    if own == nil then
        if __tables.arts[id] == nil then return end
        __book.arts[id] = { id = id, pos = __book.art_count, level = level, learned = level > 0 }
        __book.art_count = __book.art_count + 1
    else
        own.level = level
        own.learned = level > 0
    end
    sync("xinfa", __book.arts, function(define) return __tables.arts[define].name end)
end

-- Bộ xử lý gói danh sách kỹ năng (0x14058d920): xoá sạch, Set_Skill (0x140193f30) từng id theo thứ
-- tự trong gói, rồi một lần UserSkill_Update.
function __skill_list(ids)
    __book.skills = {}
    __book.skill_count = 0
    for _, id in ipairs(ids) do
        local row = __tables.skills[id]
        local is_taken = row ~= nil and (row.inner_art == -1 or row.sect == __hero.MEMPAI)
        if is_taken and __book.skills[id] == nil then
            __book.skills[id] = { row = row, id = id, pos = __book.skill_count, learned = true }
            __book.skill_count = __book.skill_count + 1
        end
    end
    sync("skill", __book.skills, function(define) return __tables.skills[define].name end)
end

-- CCharacterData::Set_LifeAbility (0x140194d10) rồi UserLifeAbility_Update.
function __set_life_ability(id, level, exp, zhuanjing)
    if exp > 0 then exp = math.floor(exp / 100) end
    local own = __book.life[id]
    if own == nil then
        if __tables.life[id] == nil then return end
        __book.life[id] = { id = id, pos = __book.life_count, level = level, exp = math.max(exp, 0),
            zhuanjing = math.max(zhuanjing, 0) }
        __book.life_count = __book.life_count + 1
    else
        if level >= 0 then own.level = level end
        if exp >= 0 then own.exp = exp end
        if zhuanjing >= 0 then own.zhuanjing = zhuanjing end
    end
    sync("life", __book.life, function(define) return __tables.life[define].name end)
end

-- GetActionNum (0x140017280): đếm mọi action có số loại khớp; "packageitem" luôn 240.
function GetActionNum(kind)
    local wanted = type_numbers[kind] or 0
    if wanted == 3 then return 240 end
    local count = 0
    for _, item in pairs(__actions) do
        if type_number(item) == wanted then count = count + 1 end
    end
    return count
end

-- PosIndex của mục mà action trỏ tới (vtbl+0x60); lớp gốc chưa đọc, coi là -1.
local function pos_of(item)
    local impl = impl_of(item)
    if impl == nil then return -1 end
    return impl.pos
end

-- EnumAction (0x140017360): action đầu tiên theo id có đúng số loại và PosIndex bằng index.
function EnumAction(index, kind)
    local wanted = type_numbers[kind] or 0
    index = math.floor(index)
    for _, id in ipairs(action_ids()) do
        local item = __actions[id]
        if type_number(item) == wanted and pos_of(item) == index then return item end
    end
    return empty_action
end

Pet = {}
function Pet:GetPetFightAction() return __pets[1] or empty_action end
function Pet:GetPetRelaxAction() return __pets[2] or empty_action end
function Pet:GetPetPossessionAction() return __pets[3] or empty_action end
function Pet:GetPetRestoreAction() return __pets[4] or empty_action end

LifeAbility = {}

-- GetLifeAbility_Number (0x140346dc0): id định nghĩa của action; không có thì không trả gì.
function LifeAbility:GetLifeAbility_Number(action_id)
    if type(action_id) ~= "number" then return end
    local item = __actions[math.floor(action_id)]
    if item == nil or item:GetDefineID() == -1 then return end
    return item:GetDefineID()
end

-- Chia số nguyên có dấu như idiv: bỏ phần lẻ về phía 0.
local function quotient(value, by)
    local result = value / by
    if result < 0 then return math.ceil(result) end
    return math.floor(result)
end

-- GetLifeAbility_LimitExp (0x14034d6a0).
function LifeAbility:GetLifeAbility_LimitExp(id, level)
    local row = __tables.life[id]
    if row == nil then return -1 end
    local levels = __tables.life_levels[row.level_table]
    if levels == nil or levels[level] == nil then return -1 end
    return quotient(levels[level], 100)
end

-- Người chơi -------------------------------------------------------------------------------------

Player = {}

-- Player:GetData (0x140386780).
function Player:GetData(key)
    local value = __hero[key]
    if value == nil then error("Player:GetData chưa mô phỏng: " .. tostring(key), 2) end
    if type(value) == "table" then return unpack(value) end
    return value
end

function Player:GetDefineHumanMaxLevel() return 129 end

-- Dòng số liệu theo bậc tâm pháp (0x1401ec780).
local function skill_data_text(skill)
    local row = skill.row
    local tier = 0
    local art = __book.arts[row.inner_art]
    if art ~= nil then tier = math.mod(quotient(art.level + row.level_offset, 10), 31) end
    local data = -1
    if tier >= 0 and row.data ~= nil and row.data[tier] ~= nil then data = row.data[tier] end
    return __tables.levels[data] or row.explain
end

-- Player:GetSkillInfo (0x140389a50). Khoá lạ, và "passivity" khi không có kỹ năng: hàm gốc trả 1
-- mà không đẩy gì, script nhận lại chính chuỗi khoá.
function Player:GetSkillInfo(id, key)
    if type(id) ~= "number" or type(key) ~= "string" then return end
    local skill = get_skill(math.floor(id))
    if key == "name" then return skill and skill.row.name or "" end
    if key == "learn" then return skill ~= nil and skill.learned end
    if key == "iconname" then return skill and skill.row.icon or "" end
    if key == "passivity" then
        if skill == nil then return key end
        return skill.row.passivity
    end
    if key == "explain" then return skill and skill.row.explain or "" end
    if key == "skilldata" then return skill and skill_data_text(skill) or "" end
    if key == "skillnIndex" then return skill and skill.pos or -1 end
    if key == "isequirement" then
        local art = skill and __book.arts[skill.row.inner_art]
        return art ~= nil and art ~= false and art.level >= skill.row.inner_art_level
    end
    return key
end

-- Player:GetXinfaInfo (0x140389fc0); không có tâm pháp thì không trả gì.
function Player:GetXinfaInfo(id, key)
    if type(id) ~= "number" or type(key) ~= "string" then return end
    local own = __book.arts[math.floor(id)]
    if own == nil then return end
    local row = __tables.arts[own.id]
    if key == "name" then return row.name end
    if key == "level" then return own.level end
    if key == "iconname" then return row.icon end
    if key == "needlevel" then return row.need_level end
    if key == "explain" then
        local cap = 119
        if __hero.LEVEL > 119 then cap = 129 end
        if own.pos == 7 then
            cap = 250
            if __hero.LEVEL > 119 then cap = 300 end
            if __hero.Is2606S ~= 0 then cap = 119 end
        end
        return (string.gsub(row.explain, "%%d", tostring(cap), 1))
    end
    return key
end

-- Player:GetAbilityInfo (0x140389590); không có kỹ năng sống thì không trả gì.
function Player:GetAbilityInfo(id, key)
    if type(id) ~= "number" or type(key) ~= "string" then return end
    local own = __book.life[math.floor(id)]
    if own == nil then return end
    local row = __tables.life[own.id]
    if key == "name" then return row.name end
    if key == "level" then return own.level end
    if key == "maxlevel" then return row.max_level end
    if key == "skillexp" then return own.exp end
    if key == "iconname" then return row.icon end
    if key == "explain" then return row.explain end
    if key == "popup" then return row.popup end
    if key == "consume" then return row.consume end
    if key == "zhuanjing" then return own.zhuanjing end
    return key
end

-- GetXinfaLevel (0x1402340c0).
function GetXinfaLevel(id)
    local own = __book.arts[id]
    if own == nil then return -1 end
    return own.level
end

-- Dòng đầu tiên của bảng giá có cấp level; nil khi không có hay id tâm pháp ngoài bảng.
local function cost_of(id, level)
    for _, row in ipairs(__tables.costs) do
        if row.level == level then return row[id] end
    end
    return nil
end

-- GetUplevelXinfaSpendMoney (0x140233d00): tiền, rồi vàng, bạc, đồng.
function GetUplevelXinfaSpendMoney(id, level)
    local cost = cost_of(id, level)
    if cost == nil then return -1, -1, -1, -1 end
    local money = cost[1]
    local copper = math.mod(money, 100)
    local silver = 0
    local gold = 0
    if money >= 100 then silver = math.mod(quotient(money - copper, 100), 100) end
    if money >= 10000 then gold = quotient(quotient(money - copper, 100) - silver, 100) end
    return money, gold, silver, copper
end

-- GetUplevelXinfaSpendExp (0x140233f60).
function GetUplevelXinfaSpendExp(id, level)
    local cost = cost_of(id, level)
    if cost == nil then return -1 end
    return cost[2]
end

local function one_of(id, low, high)
    if id >= low and id <= high then return 1 end
    return 0
end

-- IsLMSJSecond (0x14023fdf0), IsJYJYSecond (0x14023fe80), IsWJQFSecond (0x14023ff10).
function IsLMSJSecond(id) return one_of(id, 821, 826) end
function IsJYJYSecond(id) return one_of(id, 827, 834) end
function IsWJQFSecond(id) return one_of(id, 4465, 4466) end

BattleAssist = {}
-- Farm_GetLimitLevel (0x1403d1960).
function BattleAssist:Farm_GetLimitLevel()
    if __hero.Is2606S == 1 then return 30 end
    return 50
end

SystemSetup = {}
-- Game.exe 2026 luôn trả 1 (0x14045fbb0).
function SystemSetup:IsClassic() return 1 end

TLCJ = {}
-- Chưa có cảnh đó: coi như 0.
function TLCJ:IsInTLCJScene() return 0 end

-- Chưa có chỉ dẫn tân thủ.
function GetFreshManGuideOwner() return "" end
function CloseFreshManGuide() end

Helper = {}
function Helper:GotoHelper(topic) __note("GotoHelper", topic) end

function PushEvent(...) __note("PushEvent", unpack(arg)) end
function PushDebugMessage(text) __note("PushDebugMessage", text) end

-- Mở sách -----------------------------------------------------------------------------------------

-- Ba cảnh "địa phủ" (0x1402297a0): ở đó không mở được sách.
local function in_underworld_scene()
    return __scene == 77 or __scene == 578 or __scene == 823
end

-- Năm hàm mở trang (0x1402323e0, 0x140233230, 0x1402331e0, 0x140232430, 0x140232500): đẩy sự kiện
-- rồi ghi trang cuối.
local function opener(event, code)
    return function()
        if in_underworld_scene() then return end
        __note("PushEvent", event)
        __last_skill_ui = code
    end
end

OpenSkillBook = opener("TOGLE_SKILL_BOOK", 2)
OpenCommonSkillPage = opener("TOGLE_COMMONSKILL_PAGE", 1)
OpenLifePage = opener("TOGLE_LIFE_PAGE", 3)
OpenZhenfaFream = opener("OPEN_ZHENFAFREAM", 4)
ToggleTalentPage = opener("TOGGLE_SECT_PAGE", 5)

DataPool = {}

-- DataPool:Lua_SetLastSkill_UI (0x14030e740).
function DataPool:Lua_SetLastSkill_UI(code)
    if type(code) == "number" then __last_skill_ui = math.floor(code) end
end

function GetLastSkill_UI() return __last_skill_ui end
