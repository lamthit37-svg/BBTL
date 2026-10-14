-- 城战记录编年史
--      3.1.3霸者天下记录榜

-- 打开界面等级限制
local g_NewBangHui_RecordList_LimitLevel = 85
-- 连胜显示最小限制
local g_NewBangHui_RecordList_ConWin = 5
-- 连杀显示最小限制
local g_NewBangHui_RecordList_ConKill = 50
-- 快速夺旗显示分钟限制
local g_NewBangHui_RecordList_FastFlag = 10
-- 击杀/死亡
local g_NewBangHui_RecordList_KillNum = 2500
-- ?极限拉扯/一次城战多次夺旗和被夺旗
local g_NewBangHui_RecordList_CFlagOnce = 5
-- 个人多次夺旗
local g_NewBangHui_RecordList_CFlagPersonal = 5
-- 个人连杀次数
local g_NewBangHui_RecordList_CKillPersonal = 50
-- 个人总击杀数
local g_NewBangHui_RecordList_SKillPersonal = 500
-- 个人单场输出
local g_NewBangHui_RecordList_DmgPersonal = 50000000
-- 个人单场承伤
local g_NewBangHui_RecordList_HrtPersonal = 50000000
-- 个人单场治疗
local g_NewBangHui_RecordList_HealthPersonal = 50000000

-- 分页UI
local g_NewBangHui_RecordList_UIPages = {}
-- tag
local g_NewBangHui_RecordList_PageTag = 1
-- ui time tag
local g_NewBangHui_RecordList_UITimeTag = {}
-- 当前有N个 time tag 显示
local g_NewBangHui_RecordList_TimeTagNum = 0
-- time tag 最大数量
local g_NewBangHui_RecordList_TimeTagMax = 12
-- ui cont tag
local g_NewBangHui_RecordList_UIContTag = {}
-- 当前有N个 Cont Tag 显示
local g_NewBangHui_RecordList_ContTagNum = 0
-- Cont Tag 最大数量
local g_NewBangHui_RecordList_ContTagMax = 10
-- 内容页数
local g_NewBangHui_RecordList_ContPage = 1

-- cont info
local g_NewBangHui_RecordList_Contant = {}
-- 时间戳Id 到 数据Id 索引
local g_NewBangHui_RecordList_IdConv = {}


function NewBangHui_RecordList_PreLoad()
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("OPEN_TCW_RECORD")
    -- this:RegisterEvent("UPDATE_YUANBAO")
end

function NewBangHui_RecordList_OnLoad()
	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if curWorldBank_UIPos ~= nil then
        NewBangHui_RecordList_Frame:SetProperty("UnifiedPosition", curWorldBank_UIPos )
    else
        Variable:SetVariable("WorldBank_UIPos", NewBangHui_RecordList_Frame:GetProperty("UnifiedPosition"), 1)
	end

    NewBangHui_RecordList_DragTitle:SetText ("#{CZJL_250512_07}")

    NewBangHui_RecordList_FenYe1:SetText ("#{CZJL_250512_08}")
    NewBangHui_RecordList_FenYe2:SetText ("#{CZJL_250512_10}")
    NewBangHui_RecordList_FenYe3:SetText ("#{CZJL_250512_12}")
end

--=========
-- Event
--=========
---   !!!reloadscript =NewBangHui_RecordList
function NewBangHui_RecordList_OnEvent(event) 
    if event == "OPEN_TCW_RECORD" and arg0 ~= nil and tonumber(arg0) == 1 then
        local clevel = Player:GetData("LEVEL")
        if clevel < g_NewBangHui_RecordList_LimitLevel then
            PushDebugMessage("#{CZJL_250512_04}")
            return
        end

        g_NewBangHui_RecordList_UITimeTag = {
            NewBangHui_RecordList_LeftFenYe1,
            NewBangHui_RecordList_LeftFenYe2,
            NewBangHui_RecordList_LeftFenYe3,
            NewBangHui_RecordList_LeftFenYe4,
            NewBangHui_RecordList_LeftFenYe5,
            NewBangHui_RecordList_LeftFenYe6,
            NewBangHui_RecordList_LeftFenYe7,
            NewBangHui_RecordList_LeftFenYe8,
            NewBangHui_RecordList_LeftFenYe9,
            NewBangHui_RecordList_LeftFenYe10,
            NewBangHui_RecordList_LeftFenYe11,
            NewBangHui_RecordList_LeftFenYe12,
        }
    
        g_NewBangHui_RecordList_UIContTag = {
            { bgi = NewBangHui_RecordList_Frame1_Text1BK, txt = NewBangHui_RecordList_Frame1_Text1 },
            { bgi = NewBangHui_RecordList_Frame1_Text2BK, txt = NewBangHui_RecordList_Frame1_Text2 },
            { bgi = NewBangHui_RecordList_Frame1_Text3BK, txt = NewBangHui_RecordList_Frame1_Text3 },
            { bgi = NewBangHui_RecordList_Frame1_Text4BK, txt = NewBangHui_RecordList_Frame1_Text4 },
            { bgi = NewBangHui_RecordList_Frame1_Text5BK, txt = NewBangHui_RecordList_Frame1_Text5 },
            { bgi = NewBangHui_RecordList_Frame1_Text6BK, txt = NewBangHui_RecordList_Frame1_Text6 },
            { bgi = NewBangHui_RecordList_Frame1_Text7BK, txt = NewBangHui_RecordList_Frame1_Text7 },
            { bgi = NewBangHui_RecordList_Frame1_Text8BK, txt = NewBangHui_RecordList_Frame1_Text8 },
            { bgi = NewBangHui_RecordList_Frame1_Text9BK, txt = NewBangHui_RecordList_Frame1_Text9 },
            { bgi = NewBangHui_RecordList_Frame1_Text10BK, txt = NewBangHui_RecordList_Frame1_Text10 },
        }

        g_NewBangHui_RecordList_UIPages = {
            NewBangHui_RecordList_FenYe1,
            NewBangHui_RecordList_FenYe2,
            NewBangHui_RecordList_FenYe3
        }

        NewBangHui_RecordList_ChangeWorldBankPage(1)
        this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		NewBangHui_RecordList_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		NewBangHui_RecordList_OnClose()
	elseif event == "ADJEST_UI_POS" then
        NewBangHui_RecordList_On_ResetPos()
	end
end
 
--=========
-- 重置
--=========
function NewBangHui_RecordList_On_ResetPos()
	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if curWorldBank_UIPos then
        NewBangHui_RecordList_Frame:SetProperty("UnifiedPosition", curWorldBank_UIPos)
	end
end

-- 关闭
function NewBangHui_RecordList_OnClose()
    this:Hide()
end

-- 清空左侧时间 tag
function NewBangHui_RecordList_ClearTimeTag ()
    g_NewBangHui_RecordList_TimeTagNum = 0
    g_NewBangHui_RecordList_IdConv = {}
    for _, v in ipairs (g_NewBangHui_RecordList_UITimeTag) do
        v:Hide()
    end
end

-- 清空右侧内容 tag
function NewBangHui_RecordList_ClearContTag ()
    g_NewBangHui_RecordList_ContTagNum = 0
    for _, v in ipairs (g_NewBangHui_RecordList_UIContTag) do
        v.bgi:Hide()
    end
end

-- 显示一个时间 tag
function NewBangHui_RecordList_AddTimeTag (id, month, day)
    if g_NewBangHui_RecordList_TimeTagNum >= g_NewBangHui_RecordList_TimeTagMax then
        return
    end
    g_NewBangHui_RecordList_TimeTagNum = g_NewBangHui_RecordList_TimeTagNum + 1
    local node = g_NewBangHui_RecordList_UITimeTag[g_NewBangHui_RecordList_TimeTagNum]

    local msg = ScriptGlobal_Format ("#{CZJL_250512_14}", month, day)
    node:SetText (msg)
    g_NewBangHui_RecordList_IdConv[g_NewBangHui_RecordList_TimeTagNum] = id
    -- node:SetEvent ("Clicked", string.format("NewBangHui_RecordList_Visible(%d)", id))

    node:Show ()
    return node
end

-- 显示一个内容 tag
function NewBangHui_RecordList_AddContTag (msg)
    if g_NewBangHui_RecordList_ContTagNum >= g_NewBangHui_RecordList_ContTagMax then
        return
    end
    g_NewBangHui_RecordList_ContTagNum = g_NewBangHui_RecordList_ContTagNum + 1
    local node = g_NewBangHui_RecordList_UIContTag[g_NewBangHui_RecordList_ContTagNum]
    node.txt:SetText (msg)
    node.bgi:Show()
end

-- 填充 Guild 分页的内容
function NewBangHui_RecordList_FillGuild (node)
    -- local szName = Guild:GetMyGuildName("Name")
    local szName = Guild:GetMyGuildInfo("Name")
    if szName == "" then
        szName = "Unknow"
    end

    local year = math.floor(node.mRecordTime2Day / 10000)
    local month = math.floor ((node.mRecordTime2Day - year * 10000) / 100)
    local day = math.mod (node.mRecordTime2Day, 100)

    -- ?快速夺旗
    if node.mQuickTime > 0 then
        local minute = math.floor (node.mQuickTime / 60)
        local second = math.mod (node.mQuickTime, 60)
        local str = ScriptGlobal_Format ("#{CZJL_250512_17}", year, month, day, szName, minute, second)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?极限夺旗
    if node.mSlowTime > 0 then
        local sec = 3600 - node.mSlowTime
        if sec <= 0 then
            sec = 1
        end
        local str = ScriptGlobal_Format ("#{CZJL_250512_18}", year, month, day, szName, sec)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?击杀数/被击杀数/输赢
    -- PushDebugMessage(tostring (node.mKillNum) .. "|" .. tostring (node.mConsecutiveVictories))
    if node.mKillNum >= g_NewBangHui_RecordList_KillNum and node.mConsecutiveVictories > 0 then
        local str = ScriptGlobal_Format ("#{CZJL_250512_19}", year, month, day, szName, node.mKillNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?连续夺取罗浮
    if node.mConsecutiveVictories >= g_NewBangHui_RecordList_ConWin then
        local str = ScriptGlobal_Format ("#{CZJL_250512_20}", year, month, day, szName, node.mConsecutiveVictories)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?极限拉扯/一次城战多次夺旗和被夺旗
    if node.mCaptureFlagMultiNum >= g_NewBangHui_RecordList_CFlagOnce then
        local str = ScriptGlobal_Format ("#{CZJL_250512_23}", year, month, day, szName, node.mCaptureFlagMultiNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
end

-- 填充 Hero 分页的内容
function NewBangHui_RecordList_FillHero (node)
    local year = math.floor(node.mRecordTime2Day / 10000)
    local month = math.floor ((node.mRecordTime2Day - year * 10000) / 100)
    local day = math.mod (node.mRecordTime2Day, 100)

    -- ?快速夺旗
    if node.mQuickTime > 0 then
        local minute = math.floor (node.mQuickTime / 60)
        local second = math.mod (node.mQuickTime, 60)
        local str = ScriptGlobal_Format ("#{CZJL_250512_33}", year, month, day, node.mQuickCFHumanName, minute, second)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?极限夺旗
    if node.mSlowTime > 0 then
        local sec = 3600 - node.mSlowTime
        if sec <= 0 then
            sec = 1
        end
        local str = ScriptGlobal_Format ("#{CZJL_250512_34}", year, month, day, node.mSlowCFHumanName, sec)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- PushDebugMessage ("Heros: " .. tostring (node.mMonth) .. " " .. tostring (node.mDay) .. " " .. tostring (node.mCFInfos) .. " " .. tostring (table.getn(node.mCFInfos)))
    -- ?多次夺旗
    for _, one in ipairs (node.mCFInfos) do
        local str = ScriptGlobal_Format ("#{CZJL_250512_24}", year, month, day, one.mName, one.mNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?连杀
    for _, one in ipairs (node.mCKInfos) do
        -- PushDebugMessage ("CK: " .. tostring (node.mMonth) .. "|" .. tostring(node.mDay) .. "|" .. tostring(one.mName) .. "|" .. tostring(one.mNum))
        local str = ScriptGlobal_Format ("#{CZJL_250512_25}", year, month, day, one.mName, one.mNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?总击杀数
    for _, one in ipairs (node.mSKInfos) do
        -- PushDebugMessage ("SK: " .. tostring (node.mMonth) .. "|" .. tostring(node.mDay) .. "|" .. tostring(one.mName) .. "|" .. tostring(one.mNum))
        local str = ScriptGlobal_Format ("#{CZJL_250512_26}", year, month, day, one.mName, one.mNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
end

-- 填充 Personal 分页的内容
function NewBangHui_RecordList_FillPersonal (node)
    local szName = Player:GetName()
    local year = math.floor(node.mRecordTime2Day / 10000)
    local month = math.floor ((node.mRecordTime2Day - year * 10000) / 100)
    local day = math.mod (node.mRecordTime2Day, 100)
    -- ?快速夺旗
    if node.mQuickCF > 0 then
        local minute = math.floor (node.mQuickCF / 60)
        local second = math.mod (node.mQuickCF, 60)
        local str = ScriptGlobal_Format ("#{CZJL_250512_48}", year, month, day, szName, minute, second)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?极限夺旗
    if node.mSlowCF > 0 then
        local sec = 3600 - node.mSlowCF
        if sec <= 0 then
            sec = 1
        end
        local str = ScriptGlobal_Format ("#{CZJL_250512_49}", year, month, day, szName, sec)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- PushDebugMessage ("cf: " .. tostring (node.mCaptureFlagNum) .. "  ck: " .. tostring (node.mConKillNums))
    -- ?多次夺旗
    if node.mCaptureFlagNum > g_NewBangHui_RecordList_CFlagPersonal then
        -- PushDebugMessage ("cf --- " .. tostring (node.mCaptureFlagNum))
        local str = ScriptGlobal_Format ("#{CZJL_250512_24}", year, month, day, szName, node.mCaptureFlagNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?连杀
    if node.mConKillNums >= g_NewBangHui_RecordList_CKillPersonal then
        -- PushDebugMessage ("ck --- " .. tostring (node.mConKillNums))
        local str = ScriptGlobal_Format ("#{CZJL_250512_25}", year, month, day, szName, node.mConKillNums)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?总击杀数
    if node.mSumKillNum >= g_NewBangHui_RecordList_SKillPersonal then
        local str = ScriptGlobal_Format ("#{CZJL_250512_26}", year, month, day, szName, node.mSumKillNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- PushDebugMessage (tostring(node.mDmgNum) .. "|" .. tostring (node.mHurtNum) .. "|" .. tostring(node.mHealthNum))
    -- ?输出量
    if node.mDmgNum >= g_NewBangHui_RecordList_DmgPersonal then
        local str = ScriptGlobal_Format ("#{CZJL_250512_27}", year, month, day, szName, node.mDmgNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?承伤量
    if node.mHurtNum >= g_NewBangHui_RecordList_HrtPersonal then
        local str = ScriptGlobal_Format ("#{CZJL_250512_28}", year, month, day, szName, node.mHurtNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
    -- ?治疗量
    if node.mHealthNum >= g_NewBangHui_RecordList_HealthPersonal then
        local str = ScriptGlobal_Format ("#{CZJL_250512_29}", year, month, day, szName, node.mHealthNum)
        table.insert (g_NewBangHui_RecordList_Contant, str)
    end
end

-- 更新内容页数信息
function NewBangHui_RecordList_PageUpdate ()
    local notenum = table.getn (g_NewBangHui_RecordList_Contant)
    local maxnum = math.floor (notenum / g_NewBangHui_RecordList_ContTagMax)
    if math.mod (notenum, g_NewBangHui_RecordList_ContTagMax) > 0 then
        maxnum = maxnum + 1
    end
    if g_NewBangHui_RecordList_ContPage <= 0 then
        g_NewBangHui_RecordList_ContPage = 1
    end
    if g_NewBangHui_RecordList_ContPage > maxnum then
        g_NewBangHui_RecordList_ContPage = maxnum
    end
    local str = ScriptGlobal_Format ("#{CZJL_250512_30}", g_NewBangHui_RecordList_ContPage, maxnum)
    -- PushDebugMessage ("111  " .. tostring(g_NewBangHui_RecordList_ContPage) .. "|" .. tostring (maxnum) .. "|" .. tostring(str))
    NewBangHui_RecordList_Bottom_CurrentlyPage:SetText (str)

    if g_NewBangHui_RecordList_ContPage <= 1 then
        NewBangHui_RecordList_Bottom_UpPage:Disable ()
    else
        NewBangHui_RecordList_Bottom_UpPage:Enable ()
    end

    if g_NewBangHui_RecordList_ContPage == maxnum then
        NewBangHui_RecordList_Bottom_DownPage:Disable ()
    else
        NewBangHui_RecordList_Bottom_DownPage:Enable ()
    end

    local start = (g_NewBangHui_RecordList_ContPage - 1) * g_NewBangHui_RecordList_ContTagMax + 1
    if start < 0 then
        start = 1
    end
    local finish = start + g_NewBangHui_RecordList_ContTagMax - 1
    if finish > notenum then
        finish = notenum
    end
    -- 返回 content 的索引范围
    return start, finish
end

-- 显示 g_NewBangHui_RecordList_PageTag 分页, 对应内容 Id 的内容
function NewBangHui_RecordList_Visible (id)
    for _, btn in ipairs (g_NewBangHui_RecordList_UITimeTag) do
        btn:SetCheck(0)
    end
    g_NewBangHui_RecordList_UITimeTag[id]:SetCheck (1)
    local readId = g_NewBangHui_RecordList_IdConv[id]
    -- PushDebugMessage ("Visible: " .. tostring (id) .. " " .. tostring (readId))
    -- 清空内容缓存
    g_NewBangHui_RecordList_Contant = {}
    -- 清空内容 tag 下面重新填充
    NewBangHui_RecordList_ClearContTag ()

    local record = TCWL:GetCityWarRecordList()
    if g_NewBangHui_RecordList_PageTag == 1 then
        NewBangHui_RecordList_FillGuild (record.Guild[readId])
    elseif g_NewBangHui_RecordList_PageTag == 2 then
        NewBangHui_RecordList_FillHero (record.Guild[readId])
    elseif g_NewBangHui_RecordList_PageTag == 3 then
        NewBangHui_RecordList_FillPersonal (record.Personal[readId])
    end

    g_NewBangHui_RecordList_ContPage = 1

    local start, finish = NewBangHui_RecordList_PageUpdate ()
    -- PushDebugMessage ("s: " .. tostring (start) .. "  e: " .. tostring (finish))
    for i = start, finish do
        NewBangHui_RecordList_AddContTag (g_NewBangHui_RecordList_Contant[i])
    end
end

-- 显示 Guild 分页
function NewBangHui_RecordList_VisGuild ()
    NewBangHui_RecordList_Info:SetText ("#{CZJL_250512_09}")
    local record = TCWL:GetCityWarRecordList()
    local vis = false
    for i = 0, g_NewBangHui_RecordList_TimeTagMax - 1 do
        local realIndex = math.mod (record.Guild.mCurNode + i, g_NewBangHui_RecordList_TimeTagMax) + 1
        local node = record.Guild[realIndex]

        -- 当前记录有效
        if node.mRecordTime2Day > 0 then
            local year = math.floor(node.mRecordTime2Day / 10000)
            local month = math.floor ((node.mRecordTime2Day - year * 10000) / 100)
            local day = math.mod (node.mRecordTime2Day, 100)
            vis = true
            NewBangHui_RecordList_AddTimeTag (realIndex, month, day)
        end
    end
    if vis then
        NewBangHui_RecordList_SetPageState (1)
        NewBangHui_RecordList_Visible (1)
    else
        NewBangHui_RecordList_SetPageState (0)
    end
end

-- 显示 Hero 分页
function NewBangHui_RecordList_VisHero ()
    NewBangHui_RecordList_Info:SetText ("#{CZJL_250512_11}")
    local record = TCWL:GetCityWarRecordList()
    local vis = false
    for i = 0, g_NewBangHui_RecordList_TimeTagMax - 1 do
        local realIndex = math.mod (record.Guild.mCurNode + i, g_NewBangHui_RecordList_TimeTagMax) + 1
        local node = record.Guild[realIndex]

        -- 当前记录有效
        if node.mRecordTime2Day > 0 then
            local year = math.floor(node.mRecordTime2Day / 10000)
            local month = math.floor ((node.mRecordTime2Day - year * 10000) / 100)
            local day = math.mod (node.mRecordTime2Day, 100)
            vis = true
            NewBangHui_RecordList_AddTimeTag (realIndex, month, day)
        end
    end
    if vis then
        NewBangHui_RecordList_SetPageState (1)
        NewBangHui_RecordList_Visible (1)
    else
        NewBangHui_RecordList_SetPageState (0)
    end
end

-- 显示 Personal 分页
function NewBangHui_RecordList_VisPersonal ()
    NewBangHui_RecordList_Info:SetText ("#{CZJL_250512_13}")
    local record = TCWL:GetCityWarRecordList()
    local vis = false
    for i = 0, g_NewBangHui_RecordList_TimeTagMax - 1 do
        local realIndex = math.mod (record.Personal.mCurNode + i, g_NewBangHui_RecordList_TimeTagMax) + 1
        local node = record.Personal[realIndex]

        -- 当前记录有效
        if node.mRecordTime2Day > 0 then
            local year = math.floor(node.mRecordTime2Day / 10000)
            local month = math.floor ((node.mRecordTime2Day - year * 10000) / 100)
            local day = math.mod (node.mRecordTime2Day, 100)
            vis = true
            NewBangHui_RecordList_AddTimeTag (realIndex, month, day)
        end
    end
    if vis then
        NewBangHui_RecordList_SetPageState (1)
        NewBangHui_RecordList_Visible (1)
    else
        NewBangHui_RecordList_SetPageState (0)
    end
end

-- 更新界面
function NewBangHui_RecordList_Update (tag)
    g_NewBangHui_RecordList_PageTag = tag
    NewBangHui_RecordList_ClearTimeTag ()
    NewBangHui_RecordList_ClearContTag ()
    if tag == 1 then
        NewBangHui_RecordList_VisGuild ()
    elseif tag == 2 then
        NewBangHui_RecordList_VisHero ()
    elseif tag == 3 then
        NewBangHui_RecordList_VisPersonal ()
    end
end

-- 分页函数
function NewBangHui_RecordList_ChangeWorldBankPage (page)
    for _, btn in ipairs (g_NewBangHui_RecordList_UIPages) do
        btn:SetCheck (0)
    end
    g_NewBangHui_RecordList_UIPages[page]:SetCheck (1)
    NewBangHui_RecordList_Update (page)
end

-- 上一页
function NewBangHui_RecordList_Right_UpPage_Clicked ()
    g_NewBangHui_RecordList_ContPage = g_NewBangHui_RecordList_ContPage - 1

    NewBangHui_RecordList_ClearContTag ()
    local start, finish = NewBangHui_RecordList_PageUpdate ()
    for i = start, finish do
        NewBangHui_RecordList_AddContTag (g_NewBangHui_RecordList_Contant[i])
    end
end

-- 下一页
function NewBangHui_RecordList_Right_DownPage_Clicked ()
    g_NewBangHui_RecordList_ContPage = g_NewBangHui_RecordList_ContPage + 1

    NewBangHui_RecordList_ClearContTag ()
    local start, finish = NewBangHui_RecordList_PageUpdate ()
    for i = start, finish do
        NewBangHui_RecordList_AddContTag (g_NewBangHui_RecordList_Contant[i])
    end
end

-- 点击时间戳
function NewBangHui_RecordList_LeftFenYe_Clicked (id)
    -- PushDebugMessage ("NewBangHui_RecordList_LeftFenYe_Clicked  " .. tostring (id))
    NewBangHui_RecordList_Visible(id)
end

-- 上一页/页码/下一页 设置状态
function NewBangHui_RecordList_SetPageState (state)
    if state == 0 then
        NewBangHui_RecordList_Bottom_UpPage:Disable ()
        NewBangHui_RecordList_Bottom_CurrentlyPage:SetText ("")
        NewBangHui_RecordList_Bottom_DownPage:Disable ()
    else
        NewBangHui_RecordList_Bottom_UpPage:Enable ()
        NewBangHui_RecordList_Bottom_CurrentlyPage:SetText ("")
        NewBangHui_RecordList_Bottom_DownPage:Enable ()
    end
end
