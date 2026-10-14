-- 吃鸡赛季排行榜展示UI
local CJ_Rank_RankListMaxCount = 50     -- 排行榜最大数量
-- NPC关注
local CJ_Rank_CareObjId = -1
local CJ_Rank_CareObjSvrId = -1
-- 保存UI默认位置
local CJ_Rank_UnifiedPosition = nil

-- 门派
local CJ_Rank_MenPaiNameList =
{
	[0] = "#{XQ_MP_1}",    		--少林
	[1] = "#{XQ_MP_2}",    		--明教
	[2] = "#{XQ_MP_3}",    		--丐帮
	[3] = "#{XQ_MP_4}",    		--武当
	[4] = "#{XQ_MP_5}",    		--峨眉
	[5] = "#{XQ_MP_6}",    		--星宿
	[6] = "#{XQ_MP_7}",    		--天龙
	[7] = "#{XQ_MP_8}",    		--天山
	[8] = "#{XQ_MP_9}",    		--逍遥
	[9] = "#{GCQH_240429_141}", --无门派
	[10] = "#{XQ_MP_10}",		--慕容
	[11] = "#{XQ_MP_13}",  		--唐门
	[12] = "#{XQ_MP_14}",  		--鬼谷
    [13] = "#{XQ_MP_15}",  		--桃花岛
	[14] = "#{XQ_MP_16}", 		--绝情谷
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",	-- 恶人谷
} -- endCJ_Rank_MenPaiNameList



function CJ_Rank_PreLoad()
    this:RegisterEvent("TLCJ_RANKLIST", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func CJ_Rank_PreLoad()

function CJ_Rank_OnLoad()
    CJ_Rank_UnifiedPosition = CJ_Rank_Frame:GetProperty("UnifiedPosition")
end -- end func CJ_Rank_OnLoad()

function CJ_Rank_On_ResetPos()
    CJ_Rank_Frame:SetProperty("UnifiedPosition", CJ_Rank_UnifiedPosition)
end -- end func CJ_Rank_On_ResetPos()

function CJ_Rank_OnEvent(event)
    if (event == "TLCJ_RANKLIST") then
        CJ_Rank_BeginCareObject(tonumber(arg0))
        CJ_Rank_UpdateRankList()
        CJ_Rank_Show()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        CJ_Rank_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        CJ_Rank_On_ResetPos()
    elseif (event == "ADJEST_UI_POS") then
        CJ_Rank_On_ResetPos()
    end
end -- end func CJ_Rank_OnEvent()

function CJ_Rank_Show()
    this:Show()
end -- end func CJ_Rank_Show()

function CJ_Rank_Hide()
    CJ_Rank_StopCareObject()

    this:Hide()
end -- end func CJ_Rank_Hide()

function CJ_Rank_Close()
    CJ_Rank_Hide()
end -- end func CJ_Rank_Close()

-- 开启NPC关注
function CJ_Rank_BeginCareObject(objSvrId)
    if (objSvrId ~= nil and objSvrId >= 0) then
        CJ_Rank_CareObjId = DataPool:GetNPCIDByServerID(objSvrId)
        if (CJ_Rank_CareObjId >= 0) then
            CJ_Rank_CareObjSvrId = tonumber(objSvrId)
            this:CareObject(CJ_Rank_CareObjId, 1, "CJ_Rank")
        end
    end
end -- end func CJ_Rank_BeginCareObject()

-- 取消NPC关注
function CJ_Rank_StopCareObject()
	if (CJ_Rank_CareObjId >= 0) then
		this:CareObject(CJ_Rank_CareObjId, 0, "CJ_Rank")
		CJ_Rank_CareObjId = -1
		CJ_Rank_CareObjSvrId = -1
	end
end -- end func CJ_Rank_StopCareObject()

function CJ_Rank_GetAwardInfo(rank)
    return -1, 0, -1, 0, -1, 0
end -- end func CJ_Rank_GetAwardInfo()

-- 更新排行榜
function CJ_Rank_UpdateRankList()
    local myGUID = Player:GetGUID()

    CJ_Rank_List1_Frame:Clear()

    CJ_Rank_MyClient_Rank:SetText("")
    CJ_Rank_MyClient_Name:SetText("#{TLCJ_20240709_357}")
    CJ_Rank_MyClient_MenPai:SetText("")
    CJ_Rank_MyClient_WinNum:SetText("")
    CJ_Rank_MyClient_EnterNum:SetText("")
    CJ_Rank_MyClient_WinRewardItem1_Reward1:SetActionItem(-1)
    CJ_Rank_MyClient_WinRewardItem1_Reward2:SetActionItem(-1)
    CJ_Rank_MyClient_WinRewardItem1_Reward3:SetActionItem(-1)

    local dataCount = TLCJ:GetRankListDataCount()
    for i=1, CJ_Rank_RankListMaxCount, 1 do
        local bar = CJ_Rank_List1_Frame:AddChild("CJ_Rank_List1_Frame_Item1")
        if (bar ~= nil) then
            -- 奖励
            local item1, num1, item2, num2, item3, num3 = CJ_Rank_GetAwardInfo(i)

            if (i <= dataCount) then
                local playerRank, playerMenPai, playerWinCount, playerBattleCount, playerGUID, playerName = TLCJ:GetRankListInfo(i-1)

                -- 排名
                local ctrlRank = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_Rank_Txt")
                if (ctrlRank ~= nil) then
                    ctrlRank:SetText(tostring(i))
                end
                -- 姓名
                local ctrlName = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_Name")
                if (ctrlName ~= nil) then
                    ctrlName:SetText(playerName)
                end
                -- 门派
                local ctrlMenPai = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_MenPai")
                if (ctrlMenPai ~= nil) then
                    if (CJ_Rank_MenPaiNameList[playerMenPai] ~= nil) then
                        ctrlMenPai:SetText(CJ_Rank_MenPaiNameList[playerMenPai])
                    else
                        ctrlMenPai:SetText("")
                    end
                end
                -- 胜场数
                local ctrlWin = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_WinNum")
                if (ctrlWin ~= nil) then
                    ctrlWin:SetText(tostring(playerWinCount))
                end
                -- 参与次数
                local ctrlBattle = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_EnterNum")
                if (ctrlBattle ~= nil) then
                    ctrlBattle:SetText(tostring(playerBattleCount))
                end

                if (playerGUID == myGUID) then
                    -- 自己
                    CJ_Rank_MyClient_Rank:SetText(tostring(i))
                    CJ_Rank_MyClient_Name:SetText(playerName)
                    if (CJ_Rank_MenPaiNameList[playerMenPai] ~= nil) then
                        CJ_Rank_MyClient_MenPai:SetText(CJ_Rank_MenPaiNameList[playerMenPai])
                    else
                        CJ_Rank_MyClient_MenPai:SetText("")
                    end
                    CJ_Rank_MyClient_WinNum:SetText(tostring(playerWinCount))
                    CJ_Rank_MyClient_EnterNum:SetText(tostring(playerBattleCount))

                    -- 奖励展示
                    -- 奖励1
                    if (item1 > 0 and num1 > 0) then
                        local theAction = DataPool:CreateActionItemForShow(item1, num1)
                        if theActio:GetID() ~= 0 then
                            CJ_Rank_MyClient_WinRewardItem1_Reward1:SetActionItem(theAction:GetID())
                        end
                    end
                    -- 奖励2
                    if (item2 > 0 and num2 > 0) then
                        local theAction = DataPool:CreateActionItemForShow(item2, num2)
                        if theActio:GetID() ~= 0 then
                            CJ_Rank_MyClient_WinRewardItem1_Reward2:SetActionItem(theAction:GetID())
                        end
                    end
                    -- 奖励3
                    if (item3 > 0 and num3 > 0) then
                        local theAction = DataPool:CreateActionItemForShow(item3, num3)
                        if theActio:GetID() ~= 0 then
                            CJ_Rank_MyClient_WinRewardItem1_Reward3:SetActionItem(theAction:GetID())
                        end
                    end
                end
            else
                -- 排名
                local ctrlRank = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_Rank_Txt")
                if (ctrlRank ~= nil) then
                    ctrlRank:SetText(tostring(i))
                end
                -- 姓名
                local ctrlName = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_Name")
                if (ctrlName ~= nil) then
                    ctrlName:SetText("#{TLCJ_20240709_357}")
                end
                -- 门派
                local ctrlMenPai = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_MenPai")
                if (ctrlMenPai ~= nil) then
                    if (CJ_Rank_MenPaiNameList[playerMenPai] ~= nil) then
                        ctrlMenPai:SetText("")
                    end
                end
                -- 胜场数
                local ctrlWin = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_WinNum")
                if (ctrlWin ~= nil) then
                    ctrlWin:SetText("")
                end
                -- 参与次数
                local ctrlBattle = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_EnterNum")
                if (ctrlBattle ~= nil) then
                    ctrlBattle:SetText("")
                end
            end

            -- 奖励展示
            -- 奖励1
            if (item1 > 0 and num1 > 0) then
                local theAction = DataPool:CreateActionItemForShow(item1, num1)
                if theActio:GetID() ~= 0 then
                    local ctrlAward = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_Reward1")
                    if (ctrlAward ~= nil) then
                        ctrlAward:SetActionItem(theAction:GetID())
                        ctrlAward:Show()
                    end
                end
            end
            -- 奖励2
            if (item2 > 0 and num2 > 0) then
                local theAction = DataPool:CreateActionItemForShow(item2, num2)
                if theAction:GetID() ~= 0 then
                    local ctrlAward = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_Reward2")
                    if (ctrlAward ~= nil) then
                        ctrlAward:SetActionItem(theAction:GetID())
                        ctrlAward:Show()
                    end
                end
            end
            -- 奖励3
            if (item3 > 0 and num3 > 0) then
                local theAction = DataPool:CreateActionItemForShow(item3, num3)
                if theActio:GetID() ~= 0 then
                    local ctrlAward = bar:GetSubItem("CJ_Rank_List1_Frame_Item1_Reward3")
                    if (ctrlAward ~= nil) then
                        ctrlAward:SetActionItem(theAction:GetID())
                        ctrlAward:Show()
                    end
                end
            end
        end
    end -- end for
end -- end func CJ_Rank_UpdateRankList()
