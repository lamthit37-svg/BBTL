-- T300宋辽 排行榜界面
local SongliaoKuafu_Score_ServerScriptId = 502011

local SongliaoKuafu_Score_Camp_Song = 156               -- 宋 阵营ID
local SongliaoKuafu_Score_Camp_Liao = 157               -- 辽 阵营ID
local SongliaoKuafu_Score_CampPlayerNum_Max = 30        -- 阵营最大人数
local SongliaoKuafu_Score_CurCamp = 0                   -- 排行榜当前显示的阵营
local SongliaoKuafu_Score_LastUpdateTime = 0            -- 上次刷新排行榜事件
local SongliaoKuafu_Score_Ranklist_UpdateInterval = 3   -- 排行榜刷新间隔

-- 保存UI默认位置
local SongliaoKuafu_Score_UnifiedPosition = nil



function SongliaoKuafu_Score_PreLoad()
    this:RegisterEvent("TSL_RANKLIST", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func SongliaoKuafu_Score_PreLoad()

function SongliaoKuafu_Score_OnLoad()
    SongliaoKuafu_Score_UnifiedPosition = SongliaoKuafu_Score_Frame:GetProperty("UnifiedPosition")
end -- end func SongliaoKuafu_Score_OnLoad()

function SongliaoKuafu_Score_OnEvent(event)
    if (event == "TSL_RANKLIST") then
        SongliaoKuafu_Score_Show()
        SongliaoKuafu_Score_ShowRankList()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        SongliaoKuafu_Score_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        SongliaoKuafu_Score_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        SongliaoKuafu_Score_UnifiedPos()
    end
end -- end func SongliaoKuafu_Score_OnEvent()

-- 界面默认位置
function SongliaoKuafu_Score_UnifiedPos()
    if (this:IsVisible()) then
        if (SongliaoKuafu_Score_UnifiedPosition ~= nil) then
            SongliaoKuafu_Score_Frame:SetProperty("UnifiedPosition", SongliaoKuafu_Score_UnifiedPosition)
        end
    end
end -- end func SongliaoKuafu_Score_UnifiedPos()

function SongliaoKuafu_Score_Show()
    if (not this:IsVisible()) then
        this:Show()
    end
end -- end func SongliaoKuafu_Score_Show()

function SongliaoKuafu_Score_Hide()
    this:Hide()
end -- end func SongliaoKuafu_Score_Hide()

-- 关闭按钮点击事件
function SongliaoKuafu_Score_Close_Clicked()
    SongliaoKuafu_Score_Hide()
end  -- end func SongliaoKuafu_Score_Close_Clicked()

-- 宋、辽阵营按钮点击事件
-- 参数： 1：宋 2：辽
function SongliaoKuafu_Score_Icon_Clicked(songliaoCamp)
    local campId = -1
    if (songliaoCamp == 1) then
        SongliaoKuafu_Score_Song_Icon:SetCheck(1)
        SongliaoKuafu_Score_Liao_Icon:SetCheck(0)

        if (SongliaoKuafu_Score_CurCamp == SongliaoKuafu_Score_Camp_Song) then
            -- 当前显示的就是宋阵营
            return
        end

        campId = SongliaoKuafu_Score_Camp_Song
    elseif (songliaoCamp == 2) then
        SongliaoKuafu_Score_Liao_Icon:SetCheck(1)
        SongliaoKuafu_Score_Song_Icon:SetCheck(0)

        if (SongliaoKuafu_Score_CurCamp == SongliaoKuafu_Score_Camp_Liao) then
            -- 当前显示的就是辽阵营
            return
        end

        campId = SongliaoKuafu_Score_Camp_Liao
    else
        SongliaoKuafu_Score_Song_Icon:SetCheck(0)
        SongliaoKuafu_Score_Liao_Icon:SetCheck(0)

        -- 参数阵营不对
        return
    end 

    if (campId == SongliaoKuafu_Score_Camp_Song or campId == SongliaoKuafu_Score_Camp_Liao) then
        SongliaoKuafu_Score_UpdateRankList(campId)
    end
end -- end func SongliaoKuafu_Score_Icon_Clicked()

-- 排行榜刷新按钮事件
function SongliaoKuafu_Score_FreshButtonClicked()
    local curTime = GetTime2Second()
    local timeDiff = curTime - SongliaoKuafu_Score_LastUpdateTime
    if (timeDiff >= 0 and timeDiff < SongliaoKuafu_Score_Ranklist_UpdateInterval) then
        -- 刷新间隔不够
        return
    end

    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SyncRankList")
		Set_XSCRIPT_ScriptID(SongliaoKuafu_Score_ServerScriptId)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func SongliaoKuafu_Score_FreshButtonClicked()

-- 奖励展示按钮
function SongliaoKuafu_Score_Prize_Clicked()
    PushEvent("TSL_SHOWAWARD")
end -- end func SongliaoKuafu_Score_Prize_Clicked()

-- 显示排行榜
function SongliaoKuafu_Score_ShowRankList()
    local myCamp = CSongliaoWarData:TSLGetMyCamp()
    if (myCamp <= 0) then
        return
    end
    if (myCamp ~= SongliaoKuafu_Score_Camp_Song and myCamp ~= SongliaoKuafu_Score_Camp_Liao) then
        return
    end

    if (myCamp == SongliaoKuafu_Score_Camp_Song) then
        SongliaoKuafu_Score_Song_Icon:SetCheck(1)
        SongliaoKuafu_Score_Liao_Icon:SetCheck(0)
    elseif (myCamp == SongliaoKuafu_Score_Camp_Liao) then
        SongliaoKuafu_Score_Liao_Icon:SetCheck(1)
        SongliaoKuafu_Score_Song_Icon:SetCheck(0)
    end

    SongliaoKuafu_Score_UpdateRankList(myCamp)
end -- end SongliaoKuafu_Score_ShowRankList()

-- 刷新排行榜
function SongliaoKuafu_Score_UpdateRankList(campId)
    if (not this:IsVisible()) then
        return
    end

    if (campId == SongliaoKuafu_Score_Camp_Song) then
        SongliaoKuafu_Score_Song_Icon:SetCheck(1)
        SongliaoKuafu_Score_Liao_Icon:SetCheck(0)
    elseif (campId == SongliaoKuafu_Score_Camp_Liao) then
        SongliaoKuafu_Score_Liao_Icon:SetCheck(1)
        SongliaoKuafu_Score_Song_Icon:SetCheck(0)
    else
        SongliaoKuafu_Score_Song_Icon:SetCheck(0)
        SongliaoKuafu_Score_Liao_Icon:SetCheck(0)

        -- 参数阵营不对
        return
    end

    -- 记录当前显示的阵营
    SongliaoKuafu_Score_CurCamp = campId

    -- 刷新胜利标志
    local winner = CSongliaoWarData:TSLGetWinner()
    if (winner < 0) then
        -- 没有胜利方
        SongliaoKuafu_Score_Song_Win:Hide()
        SongliaoKuafu_Score_Liao_Win:Hide()
    elseif (winner == 0 or winner == SongliaoKuafu_Score_Camp_Song) then
        -- 宋 胜利
        SongliaoKuafu_Score_Song_Win:Show()
        SongliaoKuafu_Score_Liao_Win:Hide()
    elseif (winner == 1 or winner == SongliaoKuafu_Score_Camp_Liao) then
        -- 辽 胜利
        SongliaoKuafu_Score_Song_Win:Hide()
        SongliaoKuafu_Score_Liao_Win:Show()
    else
        -- 有问题
        SongliaoKuafu_Score_Song_Win:Hide()
        SongliaoKuafu_Score_Liao_Win:Hide()
    end

    local myGuid = Player:GetGUID()
    local myRank = -1

    -- 获取阵营排行榜
    local listCount = 0
    local rankList = {}
    for i=1, SongliaoKuafu_Score_CampPlayerNum_Max, 1 do
        local ret, guid, name, score, towerScore, damage, damageAfford, damageDefend, cure, kill, camp = CSongliaoWarData:TSLGetScoreData(campId, listCount)
        if (ret > 0) then
            listCount = listCount + 1
            rankList[listCount] = {}
            rankList[listCount].name = name
            rankList[listCount].score = score
            rankList[listCount].towerscore = towerScore
            rankList[listCount].damage = damage
            rankList[listCount].damageafford = damageAfford
            rankList[listCount].damagedefend = damageDefend
            rankList[listCount].cure = cure
            rankList[listCount].kill = kill
            rankList[listCount].rank = listCount

            if (guid == myGuid) then
                myRank = listCount
            end
        end
    end -- end for

    -- 更新排行榜
    SongliaoKuafu_Score_ListFrame:Clear()
    if (listCount > 0) then
        for i=1, listCount, 1 do
            -- 添加排行榜表项
            local child = SongliaoKuafu_Score_ListFrame:AddChild("SongliaoKuafu_Score_AItem")
            if (child ~= nil) then
                local totalScore = rankList[i].score + rankList[i].towerscore
                child:GetSubItem("SongliaoKuafu_Score_AItem_Rank"):SetText(tostring(rankList[i].rank))                  -- 排名
                child:GetSubItem("SongliaoKuafu_Score_AItem_Name"):SetText(rankList[i].name)                            -- 角色名
                child:GetSubItem("SongliaoKuafu_Score_AItem_Kill"):SetText(tostring(rankList[i].kill))                  -- 击杀
                child:GetSubItem("SongliaoKuafu_Score_AItem_Damage"):SetText(tostring(rankList[i].damage))              -- 伤害
                child:GetSubItem("SongliaoKuafu_Score_AItem_Treat"):SetText(tostring(rankList[i].cure))                 -- 治疗
                child:GetSubItem("SongliaoKuafu_Score_AItem_Hurt"):SetText(tostring(rankList[i].damageafford))          -- 承伤
                child:GetSubItem("SongliaoKuafu_Score_AItem_AvoidInjury"):SetText(tostring(rankList[i].damagedefend))   -- 减免伤害
                child:GetSubItem("SongliaoKuafu_Score_AItem_Score"):SetText(tostring(rankList[i].score))                -- 战斗积分
                child:GetSubItem("SongliaoKuafu_Score_AItem_BuildingScore"):SetText(tostring(rankList[i].towerscore))   -- 推塔积分
                child:GetSubItem("SongliaoKuafu_Score_AItem_AllScore"):SetText(tostring(totalScore))                    -- 总积分
            end
        end -- end for
    end

    -- 自己的积分数据
    local ret, name, score, towerScore, damage, damageAfford, damageDefend, cure, kill, camp = CSongliaoWarData:TSLGetMyScoreData()
    if (camp ~= campId) then
        -- 不是自己的阵营 不显示自己的数据
        SongliaoKuafu_Score_AItem_MyClient:Hide()
    else
        -- 是自己的阵营 显示自己的数据
        SongliaoKuafu_Score_AItem_MyClient:Show()
        
        if (myRank > 0) then
            SongliaoKuafu_Score_AItem_MyRank:SetText(tostring(myRank))
        else
            SongliaoKuafu_Score_AItem_MyRank:SetText("")
        end
        SongliaoKuafu_Score_AItem_MyName:SetText(name)
        SongliaoKuafu_Score_AItem_MyKill:SetText(tostring(kill))
        SongliaoKuafu_Score_AItem_MyDamage:SetText(tostring(damage))
        SongliaoKuafu_Score_AItem_MyTreat:SetText(tostring(cure))
        SongliaoKuafu_Score_AItem_MyHurt:SetText(tostring(damageAfford))
        SongliaoKuafu_Score_AItem_MyAvoidInjury:SetText(tostring(damageDefend))
        SongliaoKuafu_Score_AItem_MyScore:SetText(tostring(score))
        SongliaoKuafu_Score_AItem_MyBuildingScore:SetText(tostring(towerScore))
        SongliaoKuafu_Score_AItem_MyAllScore:SetText(tostring(score+towerScore))
    end
end -- end func SongliaoKuafu_Score_UpdateRankList()