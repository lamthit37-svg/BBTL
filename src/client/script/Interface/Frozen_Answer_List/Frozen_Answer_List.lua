-- 冰雪节答题排行榜
--每日结算时间
local g_SettleTime = 211500

local g_Frozen_Answer_List_Frame_UnifiedPosition = nil

local g_NpcId = -1
local g_nType = 0
local g_RankingListDailyType = 38
local g_RankStrList = { "#{DXDT_240920_66}", "#{DXDT_240920_67}", "#{DXDT_240920_68}", "#{DXDT_240920_69}",
    "#{DXDT_240920_70}", "#{DXDT_240920_71}", "#{DXDT_240920_72}", "#{DXDT_240920_73}", "#{DXDT_240920_74}",
    "#{DXDT_240920_75}" }
local g_RankingListState
local g_MyRank = -1
local g_MyRewardFlag = 0
local g_objCared = -1

function Frozen_Answer_List_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("OPEN_FROZEN_ANSWER_LIST", true)
    this:RegisterEvent("UPDATE_FROZEN_ANSWER_LIST", true)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end

function Frozen_Answer_List_OnLoad()
    g_Frozen_Answer_List_Frame_UnifiedPosition = Frozen_Answer_List_Frame:GetProperty("UnifiedPosition")
end

function Frozen_Answer_List_OnEvent(event)
    if event == "OPEN_FROZEN_ANSWER_LIST" then
        -- if this:IsVisible() then -- 如果界面开着，则不处理
        --     return
        -- end
        g_nType = tonumber(arg0)
        g_NpcId = tonumber(arg1)

        g_objCared = DataPool:GetNPCIDByServerID(g_NpcId)
        Frozen_Answer_List_BeginCareObject(g_objCared)
        Frozen_Answer_List_OnShow()
    elseif event == "UPDATE_FROZEN_ANSWER_LIST" and this:IsVisible() then
        g_nType = tonumber(arg0)
        Frozen_Answer_List_OnShow()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_Answer_List_On_ResetPos()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_Answer_List_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_Answer_List_Close()
    end
end

function Frozen_Answer_List_On_ResetPos()
    Frozen_Answer_List_Frame:SetProperty("UnifiedPosition", g_Frozen_Answer_List_Frame_UnifiedPosition)
end

function Frozen_Answer_List_OnShow()
    Frozen_Answer_List_Lace:Clear()

    -- 显示我的成绩
    Frozen_Answer_List_Self_Name:SetText(Player:GetName())
    local myScore, myRewardFlag = DataPool:lua_GetJSRankingListMyInfo(g_RankingListDailyType)
    g_MyRewardFlag = myRewardFlag
    Frozen_Answer_List_Self_Num:SetText(myScore)

    -- 显示每日排名
    local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_RankingListDailyType)
    local nRank, name, score, state = DataPool:lua_GetJSRankingListInfo(g_RankingListDailyType, 0)
    local rankingListDailyState = state
    -- PushDebugMessage("rankingListDailyState:" .. rankingListDailyState)
    if rankingListDailyState == 0 then
        -- 没有排名
        if DataPool:GetServerMinuteTime() < g_SettleTime then
            rankingListDailyState = 1
        else
            rankingListDailyState = 2
        end
    end
    g_RankingListState = rankingListDailyState
    local myRankInDaily = -1
    for i = 0, nDataCount - 1 do
        local nRank, name, usetime, state = DataPool:lua_GetJSRankingListInfo(g_RankingListDailyType, i)
        local bValid, memguid, membname, menpai, level, score = DataPool:lua_GetJSRankingListMemberInfo(
            g_RankingListDailyType, i, 0)
        if bValid == 1 and myRankInDaily < 0 then
            if memguid == Player:GetGUID() then
                myRankInDaily = nRank + 1
            end
        end
        local bonus = DataPool:lua_GetJSRankingListRewardInfo(g_RankingListDailyType, nRank * 3 + 2)
        local r_rank = nRank + 1
        if r_rank > 4 then
            r_rank = 4
        end
        local ItemBar = Frozen_Answer_List_Lace:AddChild("Frozen_Answer_List_Info" .. r_rank)
        ItemBar:GetSubItem("Frozen_Answer_List_Rank" .. r_rank):SetText(g_RankStrList[nRank + 1])
        ItemBar:GetSubItem("Frozen_Answer_List_Name" .. r_rank):SetText(name)
        ItemBar:GetSubItem("Frozen_Answer_List_Num" .. r_rank):SetText(usetime)
        local theAction = DataPool:CreateBindActionItemForShow(bonus, 1)
        ItemBar:GetSubItem("Frozen_Answer_List_Reward" .. r_rank):SetActionItem(theAction:GetID())
    end
    g_MyRank = myRankInDaily

    -- 我的奖励区
    if myRankInDaily ~= -1 then
        local bonus = DataPool:lua_GetJSRankingListRewardInfo(g_RankingListDailyType, (myRankInDaily - 1) * 3 + 2)
        local theAction = DataPool:CreateBindActionItemForShow(bonus, 1)
        Frozen_Answer_Self_Reward:SetActionItem(theAction:GetID())
    else
        Frozen_Answer_Self_Reward:SetActionItem(-1)
    end
    this:Show()
end

--领奖
function Frozen_Answer_List_GetClick()
    if Player:GetLevel() < 30 then
        -- 等级判断
        PushDebugMessage("#{DXDT_240920_51}")
        return
    end
    if g_RankingListState == 1 then
        -- 奖励结算
        PushDebugMessage("#{DXDT_240920_87}")
        return
    end
    if g_MyRank == -1 then
        -- 未上榜
        PushDebugMessage("#{DXDT_240920_88}")
        return
    end
    if g_MyRewardFlag ~= 0 then
        -- 奖励结算
        PushDebugMessage("#{DXDT_240920_56}")
        return
    end
    -- 每日排行榜领奖
    DataPool:lua_GetJSRankingListGetReward(g_RankingListDailyType)
end

function Frozen_Answer_List_Close()
    Frozen_Answer_List_StopCareObject()
    this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function Frozen_Answer_List_BeginCareObject(objCaredId)
    if g_objCared ~= -1 then
        this:CareObject(objCaredId, 0, "Frozen_Answer_List");
    end
    g_objCared = objCaredId
    this:CareObject(g_objCared, 1, "Frozen_Answer_List")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function Frozen_Answer_List_StopCareObject()
    if g_objCared ~= -1 then
        this:CareObject(g_objCared, 0, "Frozen_Answer_List");
        g_objCared = -1
    end
end
