-- 城战记录编年史
--      3.1.2霸者天下英雄榜

-- 打开界面等级限制
local g_NewBangHui_HeroesList_LimitLevel = 85
-- 连胜显示最小限制
local g_NewBangHui_HeroesList_ConWin = 5
-- 连杀显示最小限制
local g_NewBangHui_HeroesList_ConKill = 50
-- 快速夺旗显示分钟限制 10 * 60   [10分钟]
local g_NewBangHui_HeroesList_FastFlag = 600
-- 总杀
local g_NewBangHui_HeroesList_SumKillNum = 500

-- UI
local g_NewBangHui_HeroesList_UI

-- 图片资源
local g_NewBangHui_HeroesList_Icons = {
    "set:Frozen_Answer image:Frozen_Answer_NumOne",
    "set:Frozen_Answer image:Frozen_Answer_NumTwo",
    "set:Frozen_Answer image:Frozen_Answer_NumThree",
    "set:Frozen_Answer image:Frozen_Answer_Right"
}

function NewBangHui_HeroesList_PreLoad()
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("OPEN_TCW_RECORD")
    -- this:RegisterEvent("UPDATE_YUANBAO")
end

function NewBangHui_HeroesList_OnLoad()
	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if curWorldBank_UIPos ~= nil then
        NewBangHui_HeroesList_Frame:SetProperty("UnifiedPosition", curWorldBank_UIPos )
    else
        Variable:SetVariable("WorldBank_UIPos", NewBangHui_HeroesList_Frame:GetProperty("UnifiedPosition"), 1)
	end

    -- NewBangHui_HeroesList_DragTitle:SetText ("#{CZJL_250512_05}")
    -- NewBangHui_HeroesList_RecordListButton:SetText("#{CZJL_250512_06}")
    local szName = Guild:GetMyGuildInfo("Name")
    if szName == "" then
        szName = "Unknow"
    end
    local guildName = ScriptGlobal_Format("#{CZJL_250512_47}", szName)
    NewBangHui_HeroesList_BanghuiText:SetText (guildName)

    g_NewBangHui_HeroesList_UI = {
        {
            Lock = NewBangHui_HeroesList_TextBK1_Locked,
            Hero = NewBangHui_HeroesList_TextBK1_Info1,
            Info = NewBangHui_HeroesList_TextBK1_Info2,
            Date = NewBangHui_HeroesList_TextBK1_Info3
        },
        {
            Lock = NewBangHui_HeroesList_TextBK2_Locked,
            Hero = NewBangHui_HeroesList_TextBK2_Info1,
            Info = NewBangHui_HeroesList_TextBK2_Info2,
            Date = NewBangHui_HeroesList_TextBK2_Info3
        },
        {
            Lock = NewBangHui_HeroesList_TextBK3_Locked,
            Hero = NewBangHui_HeroesList_TextBK3_Info1,
            Info = NewBangHui_HeroesList_TextBK3_Info2,
            Date = NewBangHui_HeroesList_TextBK3_Info3
        },
        {
            Lock = NewBangHui_HeroesList_TextBK4_Locked,
            Hero = NewBangHui_HeroesList_TextBK4_Info1,
            Info = NewBangHui_HeroesList_TextBK4_Info2,
            Date = NewBangHui_HeroesList_TextBK4_Info3
        }
    }
end

--=========
-- Event
--=========
---   !!!reloadscript =NewBangHui_HeroesList
function NewBangHui_HeroesList_OnEvent(event) 
    if event == "OPEN_TCW_RECORD" and arg0 ~= nil and tonumber(arg0) == 0 then
        local clevel = Player:GetData("LEVEL")
        if clevel < g_NewBangHui_HeroesList_LimitLevel then
            PushDebugMessage("#{CZJL_250512_04}")
            return
        end

        NewBangHui_HeroesList_Update()
        this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		NewBangHui_HeroesList_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		NewBangHui_HeroesList_OnHiden()
	elseif event == "ADJEST_UI_POS" then
        NewBangHui_HeroesList_On_ResetPos()
	end

end
 
--=========
-- 重置
--=========
function NewBangHui_HeroesList_On_ResetPos()
	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if curWorldBank_UIPos then
        NewBangHui_HeroesList_Frame:SetProperty("UnifiedPosition", curWorldBank_UIPos)
	end
end

function NewBangHui_HeroesList_OnHiden()
    this:Hide()
end

function NewBangHui_HeroesList_Clear ()
    for _, one in ipairs (g_NewBangHui_HeroesList_UI) do
        one.Lock:Show()
        one.Hero:Hide()
        one.Info:Hide()
        one.Date:Hide()
    end
end

function NewBangHui_HeroesList_AddMsg (index, hero, info, date)
    if index < 1 or index > table.getn (g_NewBangHui_HeroesList_UI) then
        return
    end

    local one = g_NewBangHui_HeroesList_UI[index]
    one.Lock:Hide()
    one.Hero:Show()
    one.Info:Show()
    one.Date:Show()

    one.Hero:SetText (hero)
    one.Info:SetText (info)
    one.Date:SetText (date)
end

function NewBangHui_HeroesList_GetDate (node)
    local year = math.floor(node.mRecordTime2Day / 10000)
    local month = math.floor ((node.mRecordTime2Day - year * 10000) / 100)
    local day = math.mod (node.mRecordTime2Day, 100)
    return year, month, day
end

--=========
-- 更新界面数据
--=========
function NewBangHui_HeroesList_Update ()
    NewBangHui_HeroesList_Clear ()
    local record = TCWL:GetCityWarRecordList()
    -- 连胜
    local sumkillNode
    local sumkillOne
    -- 连杀
    local conkillNode
    local conkillNumNode
    -- 快速夺旗
    local fastNode
    -- 极限夺旗
    local slowNode

    for _, node in ipairs(record.Guild) do
        -- 总杀
        for _, sumkillinfo in ipairs (node.mSKInfos) do
            if sumkillinfo.mNum >= g_NewBangHui_HeroesList_SumKillNum then
                if sumkillNode and sumkillOne then
                    if sumkillinfo.mNum > sumkillOne.mNum then
                        sumkillNode = node
                        sumkillOne = sumkillinfo
                    end
                else
                    sumkillNode = node
                    sumkillOne = sumkillinfo
                end
            end
        end

        -- 连杀
        for _, ckillinfo in ipairs (node.mCKInfos) do
            if ckillinfo.mNum >= g_NewBangHui_HeroesList_ConKill then
                if conkillNode and conkillNumNode then
                    if ckillinfo.mNum > conkillNumNode.mNum then
                        conkillNode = node
                        conkillNumNode = ckillinfo
                    end
                else
                    conkillNode = node
                    conkillNumNode = ckillinfo
                end
            end
        end

        if node.mQuickTime ~= 0 and node.mQuickTime <= g_NewBangHui_HeroesList_FastFlag then
            if fastNode then
                if node.mQuickTime < fastNode.mQuickTime then
                    fastNode = node
                end
            else
                fastNode = node
            end
        end

        if node.mSlowTime ~= 0 then
            if slowNode then
                if node.mSlowTime > slowNode.mSlowTime then
                    slowNode = node
                end
            else
                slowNode = node
            end
        end
    end

    local szName = Guild:GetMyGuildInfo("Name")
    if szName == "" then
        szName = "Unknow"
    end
    if sumkillNode and sumkillOne then
        local year, month, day = NewBangHui_HeroesList_GetDate (sumkillNode)
        local date = ScriptGlobal_Format("#{CZJL_250512_41}", year, month, day)
        local info = ScriptGlobal_Format("#{CZJL_250512_42}", sumkillOne.mNum)
        local hero = ScriptGlobal_Format("#{CZJL_250512_43}", sumkillOne.mName)
        NewBangHui_HeroesList_AddMsg (1, hero, info, date)
    end

    if conkillNode and conkillNumNode then
        local year, month, day = NewBangHui_HeroesList_GetDate (conkillNode)
        local date = ScriptGlobal_Format("#{CZJL_250512_44}", year, month, day)
        local info = ScriptGlobal_Format("#{CZJL_250512_42}", conkillNumNode.mNum)
        local hero = ScriptGlobal_Format("#{CZJL_250512_43}", conkillNumNode.mName)
        NewBangHui_HeroesList_AddMsg (2, hero, info, date)
    end

    if fastNode then
        local year, month, day = NewBangHui_HeroesList_GetDate (fastNode)
        local date = ScriptGlobal_Format("#{CZJL_250512_44}", year, month, day)
        local minute = math.floor (fastNode.mQuickTime / 60)
        local second = math.mod (fastNode.mQuickTime, 60)
        local info = ScriptGlobal_Format("#{CZJL_250512_45}", minute, second)
        local hero = ScriptGlobal_Format("#{CZJL_250512_43}", fastNode.mQuickCFHumanName)
        NewBangHui_HeroesList_AddMsg (3, hero, info, date)
    end

    if slowNode then
        local year, month, day = NewBangHui_HeroesList_GetDate (slowNode)
        local date = ScriptGlobal_Format("#{CZJL_250512_44}", year, month, day)
        local sec = 3600 - slowNode.mSlowTime
        if sec <= 0 then
            sec = 1
        end
        local info = ScriptGlobal_Format("#{CZJL_250512_46}", sec)
        local hero = ScriptGlobal_Format("#{CZJL_250512_43}", slowNode.mSlowCFHumanName)
        NewBangHui_HeroesList_AddMsg (4, hero, info, date)
    end
end

function NewBangHui_HeroesList_RecordListClicked ()
    PushEvent("OPEN_TCW_RECORD", 1)
end
