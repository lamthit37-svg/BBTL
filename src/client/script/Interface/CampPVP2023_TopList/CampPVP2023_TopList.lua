-- 排行榜界面
local CampPVP2023_TopList_ServerScriptId = 998429

local CampPVP2023_TopList_Camp_Red = 1               -- red 阵营ID
local CampPVP2023_TopList_Camp_Blue = 2               -- blue 阵营ID
local CampPVP2023_TopList_CampPlayerNum_Max = 30        -- 阵营最大人数
local CampPVP2023_TopList_CurCamp = 0                   -- 排行榜当前显示的阵营
local CampPVP2023_TopList_LastUpdateTime = 0            -- 上次刷新排行榜事件
local CampPVP2023_TopList_Ranklist_UpdateInterval = 3   -- 排行榜刷新间隔
local CampPVP2023_TopList_Ranklist_ScoreLimit = 30   -- 排行榜上榜最低分

-- 保存UI默认位置
local CampPVP2023_TopList_UnifiedPosition = nil
local g_RedFlagList = {}
local g_BlueFlagList = {}

local g_NowRedFlagList = {}
local g_NowBlueFlagList = {}

local g_RankImage =
{ 
	[1] = "set:CampPVP2023_1 image:CampPVP2023_No1",
	[2] = "set:CampPVP2023_1 image:CampPVP2023_No2",
	[3] = "set:CampPVP2023_1 image:CampPVP2023_No3",		
}

local g_ResultImage =
{ 
	[1] = "set:CampPVP2023_1 image:CampPVP2023_Win",
	[2] = "set:CampPVP2023_1 image:CampPVP2023_Fail",
	[3] = "set:CampPVP2023_1 image:CampPVP2023_Ping",		
}

local g_RedScoreImage =
{ 
	[0] = "set:CampPVP2023_1 image:CampPVP2023_TopList_White_0",
	[1] = "set:CampPVP2023_1 image:CampPVP2023_TopList_White_1",
	[2] = "set:CampPVP2023_1 image:CampPVP2023_TopList_White_2",
	[3] = "set:CampPVP2023_1 image:CampPVP2023_TopList_White_3",
	[4] = "set:CampPVP2023_1 image:CampPVP2023_TopList_White_4",
	[5] = "set:CampPVP2023_1 image:CampPVP2023_TopList_White_5",		
}

local g_BlueScoreImage =
{ 
	[0] = "set:CampPVP2023_1 image:CampPVP2023_TopList_Black_0",
	[1] = "set:CampPVP2023_1 image:CampPVP2023_TopList_Black_1",
	[2] = "set:CampPVP2023_1 image:CampPVP2023_TopList_Black_2",
	[3] = "set:CampPVP2023_1 image:CampPVP2023_TopList_Black_3",
	[4] = "set:CampPVP2023_1 image:CampPVP2023_TopList_Black_4",
	[5] = "set:CampPVP2023_1 image:CampPVP2023_TopList_Black_5",		
}


function CampPVP2023_TopList_PreLoad()
    this:RegisterEvent("ZYPVP_UPDATA_RANKLIST", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
end -- end func CampPVP2023_TopList_PreLoad()

function CampPVP2023_TopList_OnLoad()
    CampPVP2023_TopList_UnifiedPosition = CampPVP2023_TopList_Frame:GetProperty("UnifiedPosition")
	
	g_RedFlagList[1] = CampPVP2023_TopList_PlayerA_Flag1
	g_RedFlagList[2] = CampPVP2023_TopList_PlayerA_Flag2
	g_RedFlagList[3] = CampPVP2023_TopList_PlayerA_Flag3
	g_RedFlagList[4] = CampPVP2023_TopList_PlayerA_Flag4
	g_RedFlagList[5] = CampPVP2023_TopList_PlayerA_Flag5
	
	g_BlueFlagList[1] = CampPVP2023_TopList_PlayerB_Flag1
	g_BlueFlagList[2] = CampPVP2023_TopList_PlayerB_Flag2
	g_BlueFlagList[3] = CampPVP2023_TopList_PlayerB_Flag3
	g_BlueFlagList[4] = CampPVP2023_TopList_PlayerB_Flag4
	g_BlueFlagList[5] = CampPVP2023_TopList_PlayerB_Flag5
	
	g_NowRedFlagList[1] = CampPVP2023_TopList_PlayerA_GetFlag1
	g_NowRedFlagList[2] = CampPVP2023_TopList_PlayerA_GetFlag2
	g_NowRedFlagList[3] = CampPVP2023_TopList_PlayerA_GetFlag3
	g_NowRedFlagList[4] = CampPVP2023_TopList_PlayerA_GetFlag4
	g_NowRedFlagList[5] = CampPVP2023_TopList_PlayerA_GetFlag5
	
	g_NowBlueFlagList[1] = CampPVP2023_TopList_PlayerB_GetFlag1
	g_NowBlueFlagList[2] = CampPVP2023_TopList_PlayerB_GetFlag2
	g_NowBlueFlagList[3] = CampPVP2023_TopList_PlayerB_GetFlag3
	g_NowBlueFlagList[4] = CampPVP2023_TopList_PlayerB_GetFlag4
	g_NowBlueFlagList[5] = CampPVP2023_TopList_PlayerB_GetFlag5
	
	for i = 1, 5 do 
		g_RedFlagList[i]:Hide()
		g_BlueFlagList[i]:Hide()
		g_NowRedFlagList[i]:Hide()
		g_NowBlueFlagList[i]:Hide()
	end
	
	CampPVP2023_TopList_PlayerA_Win:Hide()
	CampPVP2023_TopList_PlayerB_Win:Hide()
	CampPVP2023_TopList_Quit:Hide()
	CampPVP2023_White_IsEnemy:Hide()
	CampPVP2023_Black_IsEnemy:Hide()
	CampPVP2023_White_IsMe:Hide()
	CampPVP2023_Black_IsMe:Hide()
	
end -- end func CampPVP2023_TopList_OnLoad()

function CampPVP2023_TopList_OnEvent(event)
    if (event == "ZYPVP_UPDATA_RANKLIST") then
	
		
        CampPVP2023_TopList_Show()
        CampPVP2023_TopList_ShowRankList()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        CampPVP2023_TopList_Hide()
		for i = 1, 5 do 
			g_RedFlagList[i]:Hide()
			g_BlueFlagList[i]:Hide()
			g_NowRedFlagList[i]:Hide()
			g_NowBlueFlagList[i]:Hide()
		end
		CampPVP2023_TopList_PlayerA_Win:Hide()
		CampPVP2023_TopList_PlayerB_Win:Hide()
		CampPVP2023_TopList_Quit:Hide()
		CampPVP2023_White_IsEnemy:Hide()
		CampPVP2023_Black_IsEnemy:Hide()
		CampPVP2023_White_IsMe:Hide()
		CampPVP2023_Black_IsMe:Hide()
		CampPVP2023_TopList_Close:Show()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        CampPVP2023_TopList_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        CampPVP2023_TopList_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998429004) then	--服务端传数据
		local nRedScore = Get_XParam_INT(9)	
		local nBlueScore = Get_XParam_INT(10)	
		for i = 1, nRedScore do 
			g_RedFlagList[i]:Show()
		end
		for i = 1, nBlueScore do 
			g_BlueFlagList[i]:Show()
		end
		CampPVP2023_TopList_ResultA:SetProperty("Image", g_RedScoreImage[nRedScore])
		CampPVP2023_TopList_ResultB:SetProperty("Image", g_BlueScoreImage[nBlueScore])
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998429006) then	--服务端传数据
		local nRedScore = Get_XParam_INT(0)	
		local nBlueScore = Get_XParam_INT(1)	
		local nGameOverHaveFlagCamp = Get_XParam_INT(2)
		for i = 1, nRedScore do 
			g_RedFlagList[i]:Show()
		end
		for i = 1, nBlueScore do 
			g_BlueFlagList[i]:Show()
		end
		CampPVP2023_TopList_ResultA:SetProperty("Image", g_RedScoreImage[nRedScore])
		CampPVP2023_TopList_ResultB:SetProperty("Image", g_BlueScoreImage[nBlueScore])
		if nRedScore > nBlueScore then
			CampPVP2023_TopList_PlayerA_Win:Show()
			CampPVP2023_TopList_PlayerB_Win:Show()
			CampPVP2023_TopList_PlayerA_Win:SetProperty("Image", g_ResultImage[1])
			CampPVP2023_TopList_PlayerB_Win:SetProperty("Image", g_ResultImage[2])
		elseif nBlueScore > nRedScore then
			CampPVP2023_TopList_PlayerA_Win:Show()
			CampPVP2023_TopList_PlayerB_Win:Show()
			CampPVP2023_TopList_PlayerA_Win:SetProperty("Image", g_ResultImage[2])
			CampPVP2023_TopList_PlayerB_Win:SetProperty("Image", g_ResultImage[1])
		elseif nRedScore == nBlueScore and (nGameOverHaveFlagCamp == 1 or nGameOverHaveFlagCamp == 2) then
			if nGameOverHaveFlagCamp == 1 then
				CampPVP2023_TopList_PlayerA_Win:Show()
				CampPVP2023_TopList_PlayerB_Win:Show()
				CampPVP2023_TopList_PlayerA_Win:SetProperty("Image", g_ResultImage[1])
				CampPVP2023_TopList_PlayerB_Win:SetProperty("Image", g_ResultImage[2])
				g_NowRedFlagList[nRedScore+1]:Show()
			else
				CampPVP2023_TopList_PlayerA_Win:Show()
				CampPVP2023_TopList_PlayerB_Win:Show()
				CampPVP2023_TopList_PlayerA_Win:SetProperty("Image", g_ResultImage[2])
				CampPVP2023_TopList_PlayerB_Win:SetProperty("Image", g_ResultImage[1])
				g_NowBlueFlagList[nBlueScore+1]:Show()
			end
		else
			CampPVP2023_TopList_PlayerA_Win:Show()
			CampPVP2023_TopList_PlayerB_Win:Show()
			CampPVP2023_TopList_PlayerA_Win:SetProperty("Image", g_ResultImage[3])
			CampPVP2023_TopList_PlayerB_Win:SetProperty("Image", g_ResultImage[3])
		end
		CampPVP2023_TopList_Quit:Show()
		CampPVP2023_TopList_Show()
		CampPVP2023_TopList_Close:Hide()
    end
end -- end func CampPVP2023_TopList_OnEvent()

-- 界面默认位置
function CampPVP2023_TopList_UnifiedPos()
    if (this:IsVisible()) then
        if (CampPVP2023_TopList_UnifiedPosition ~= nil) then
            CampPVP2023_TopList_Frame:SetProperty("UnifiedPosition", CampPVP2023_TopList_UnifiedPosition)
        end
    end
end -- end func CampPVP2023_TopList_UnifiedPos()

function CampPVP2023_TopList_Show()
    if (not this:IsVisible()) then
        this:Show()
    end
end -- end func CampPVP2023_TopList_Show()

function CampPVP2023_TopList_Hide()
    this:Hide()
end -- end func CampPVP2023_TopList_Hide()

-- 关闭按钮点击事件
function CampPVP2023_TopList_Close_Clicked()
    CampPVP2023_TopList_Hide()
end  -- end func CampPVP2023_TopList_Close_Clicked()

-- 宋、辽阵营按钮点击事件
-- 参数： 1：宋 2：辽
function CampPVP2023_TopList_Icon_Clicked(songliaoCamp)
    local campId = -1
    if (songliaoCamp == 1) then
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(1)
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(0)

        if (CampPVP2023_TopList_CurCamp == CampPVP2023_TopList_Camp_Red) then
            -- 当前显示的就是宋阵营
            return
        end

        campId = CampPVP2023_TopList_Camp_Red
    elseif (songliaoCamp == 2) then
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(1)
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(0)

        if (CampPVP2023_TopList_CurCamp == CampPVP2023_TopList_Camp_Blue) then
            -- 当前显示的就是辽阵营
            return
        end

        campId = CampPVP2023_TopList_Camp_Blue
    else
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(0)
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(0)

        -- 参数阵营不对
        return
    end

    if (campId == CampPVP2023_TopList_Camp_Red or campId == CampPVP2023_TopList_Camp_Blue) then
        CampPVP2023_TopList_UpdateRankList(campId)
    end
end -- end func CampPVP2023_TopList_Icon_Clicked()

-- 排行榜刷新按钮事件
function CampPVP2023_TopList_FreshButtonClicked()
    local curTime = GetTime2Second()
    local timeDiff = curTime - CampPVP2023_TopList_LastUpdateTime
    if (timeDiff >= 0 and timeDiff < CampPVP2023_TopList_Ranklist_UpdateInterval) then
        -- 刷新间隔不够
        return
    end

    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SyncRankList")
		Set_XSCRIPT_ScriptID(CampPVP2023_TopList_ServerScriptId)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func CampPVP2023_TopList_FreshButtonClicked()

-- 离开按钮事件
function CampPVP2023_TopList_LeaveButtonClicked()

    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGoBackToRestRoom")
		Set_XSCRIPT_ScriptID(CampPVP2023_TopList_ServerScriptId)
		Set_XSCRIPT_Parameter(0,1) 
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func CampPVP2023_TopList_FreshButtonClicked()

-- 奖励展示按钮
function CampPVP2023_TopList_Prize_Clicked()
    PushEvent("ZYPVP_SHOW_AWARD")
end -- end func CampPVP2023_TopList_Prize_Clicked()

-- 显示排行榜
function CampPVP2023_TopList_ShowRankList()
    local myCamp = ZYPVP_RankList:Lua_ZYPVPVGetMyCamp()
    if (myCamp <= 0) then
        return
    end
    if (myCamp ~= CampPVP2023_TopList_Camp_Red and myCamp ~= CampPVP2023_TopList_Camp_Blue) then
        return
    end
	
	

    if (myCamp == CampPVP2023_TopList_Camp_Red) then
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(1)
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(0)
		
		CampPVP2023_White_IsEnemy:Hide()
		CampPVP2023_Black_IsEnemy:Show()
		CampPVP2023_White_IsMe:Show()
		CampPVP2023_Black_IsMe:Hide()
		
    elseif (myCamp == CampPVP2023_TopList_Camp_Blue) then
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(0)
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(1)
		CampPVP2023_White_IsEnemy:Show()
		CampPVP2023_Black_IsEnemy:Hide()
		CampPVP2023_White_IsMe:Hide()
		CampPVP2023_Black_IsMe:Show()
    end

    CampPVP2023_TopList_UpdateRankList(myCamp)
end -- end CampPVP2023_TopList_ShowRankList()

-- 刷新排行榜
function CampPVP2023_TopList_UpdateRankList(campId)
    if (not this:IsVisible()) then
        return
    end

    if (campId == CampPVP2023_TopList_Camp_Red) then
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(1)
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(0)
    elseif (campId == CampPVP2023_TopList_Camp_Blue) then
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(1)
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(0)
    else
        CampPVP2023_TopList_PlayerA_Icon:SetCheck(0)
        CampPVP2023_TopList_PlayerB_Icon:SetCheck(0)

        -- 参数阵营不对
        return
    end

    -- 记录当前显示的阵营
    CampPVP2023_TopList_CurCamp = campId

    local myGuid = Player:GetGUID()
    local myRank = -1

    -- 获取阵营排行榜
    local listCount = 0
    local rankList = {}
    for i=1, CampPVP2023_TopList_CampPlayerNum_Max, 1 do
        local ret, guid, name, score, damage, damageAfford, damageDefend, cure, kill, continuityKillNum, stopContinuityKillScore, flagNum = ZYPVP_RankList:ZYPVPGetScoreData(campId, i-1)
        if (ret > 0) then
            listCount = listCount + 1
            rankList[listCount] = {}
			rankList[listCount].guid = guid
            rankList[listCount].name = name
            rankList[listCount].score = score
            rankList[listCount].damage = damage
            rankList[listCount].damageafford = damageAfford
            rankList[listCount].damagedefend = damageDefend
            rankList[listCount].cure = cure
            rankList[listCount].kill = kill
			rankList[listCount].continuityKillNum = continuityKillNum
            rankList[listCount].stopContinuityKillScore = stopContinuityKillScore
			rankList[listCount].flagNum = flagNum
        end
    end -- end for
	
	for i = 1, listCount do
		for j = 1, listCount-i do
			local bIsExChange = 0
			if (rankList[j].score < rankList[j+1].score) then
				bIsExChange = 1
			elseif (rankList[j].score == rankList[j+1].score and rankList[j].kill < rankList[j+1].kill) then
				bIsExChange = 1
			elseif (rankList[j].score == rankList[j+1].score and rankList[j].kill == rankList[j+1].kill and rankList[j].damage < rankList[j+1].damage) then
				bIsExChange = 1
			end
			if bIsExChange == 1 then
				local tempguid = rankList[j].guid
				local tempname = rankList[j].name
				local tempscore = rankList[j].score
				local tempdamage = rankList[j].damage
				local tempdamageafford = rankList[j].damageafford
				local tempdamagedefend = rankList[j].damagedefend
				local tempcure = rankList[j].cure
				local tempkill = rankList[j].kill
				local tempcontinuityKillNum = rankList[j].continuityKillNum
				local tempstopContinuityKillScore = rankList[j].stopContinuityKillScore
				local tempflagNum = rankList[j].flagNum
				
				rankList[j].guid = rankList[j+1].guid
				rankList[j].name = rankList[j+1].name
				rankList[j].score = rankList[j+1].score
				rankList[j].damage = rankList[j+1].damage
				rankList[j].damageafford = rankList[j+1].damageafford
				rankList[j].damagedefend = rankList[j+1].damagedefend
				rankList[j].cure = rankList[j+1].cure
				rankList[j].kill = rankList[j+1].kill
				rankList[j].continuityKillNum = rankList[j+1].continuityKillNum
				rankList[j].stopContinuityKillScore = rankList[j+1].stopContinuityKillScore
				rankList[j].flagNum = rankList[j+1].flagNum	
				
				rankList[j+1].guid = tempguid
				rankList[j+1].name = tempname
				rankList[j+1].score = tempscore
				rankList[j+1].damage = tempdamage
				rankList[j+1].damageafford = tempdamageafford
				rankList[j+1].damagedefend = tempdamagedefend
				rankList[j+1].cure = tempcure
				rankList[j+1].kill = tempkill
				rankList[j+1].continuityKillNum = tempcontinuityKillNum
				rankList[j+1].stopContinuityKillScore = tempstopContinuityKillScore
				rankList[j+1].flagNum = tempflagNum
			end
		end	
	end
	
	

    -- 更新排行榜
    CampPVP2023_TopList_ListFrame:Clear()
    if (listCount > 0) then
        for i=1, listCount, 1 do
			if rankList[i].score >= CampPVP2023_TopList_Ranklist_ScoreLimit then
				-- 添加排行榜表项
				local child = CampPVP2023_TopList_ListFrame:AddChild("CampPVP2023_TopList_AItem")
				if (child ~= nil ) then
					if i >= 1 and i <= 3 then
						child:GetSubItem("CampPVP2023_TopList_AItem_Rank"):Hide()              -- 排名
						child:GetSubItem("CampPVP2023_TopList_AItem_RankImg"):Show()                  -- 排名
						child:GetSubItem("CampPVP2023_TopList_AItem_RankImg"):SetProperty("Image", g_RankImage[i])
					else
						child:GetSubItem("CampPVP2023_TopList_AItem_Rank"):Show()                -- 排名
						child:GetSubItem("CampPVP2023_TopList_AItem_Rank"):SetText(i)                  -- 排名
						child:GetSubItem("CampPVP2023_TopList_AItem_RankImg"):Hide()                  -- 排名
					end
					child:GetSubItem("CampPVP2023_TopList_AItem_Name"):SetText(rankList[i].name)                            -- 角色名
					child:GetSubItem("CampPVP2023_TopList_AItem_Kill"):SetText(tostring(rankList[i].kill))                  -- 击杀
					child:GetSubItem("CampPVP2023_TopList_AItem_Damage"):SetText(tostring(rankList[i].damage))              -- 伤害
					child:GetSubItem("CampPVP2023_TopList_AItem_Treat"):SetText(tostring(rankList[i].cure))                 -- 治疗
					child:GetSubItem("CampPVP2023_TopList_AItem_Hurt"):SetText(tostring(rankList[i].damageafford))          -- 承伤
					child:GetSubItem("CampPVP2023_TopList_AItem_AvoidInjury"):SetText(tostring(rankList[i].damagedefend))   -- 减免伤害
					child:GetSubItem("CampPVP2023_TopList_AItem_OtherScore"):SetText(tostring(rankList[i].flagNum))   -- 
					child:GetSubItem("CampPVP2023_TopList_AItem_AllScore"):SetText(tostring(rankList[i].score))                    -- 总积分
				end
			end
        end -- end for
    end
	
	local myCamp = ZYPVP_RankList:Lua_ZYPVPVGetMyCamp()
	local myname = ""
	local myscore = 0
	local mydamage = 0
	local mydamageAfford = 0
	local mydamageDefend = 0
	local mycure = 0
	local mykill = 0
	local mycontinuityKillNum = 0
	local mystopContinuityKillScore = 0
	local myflagNum = 0
	local myrank = 0
	-- if myCamp == campId then
	for i = 1, listCount do 
		if rankList[i].guid == myGuid then
			myname = rankList[i].name
			myscore = rankList[i].score
			mydamage = rankList[i].damage
			mydamageAfford = rankList[i].damageafford
			mydamageDefend = rankList[i].damagedefend
			mycure = rankList[i].cure
			mykill = rankList[i].kill
			mycontinuityKillNum = rankList[i].continuityKillNum
			mystopContinuityKillScore = rankList[i].stopContinuityKillScore
			myflagNum = rankList[i].flagNum
			myrank = i
			break
		end
	end

    -- 自己的积分数据
    --local ret, name, score, towerScore, damage, damageAfford, damageDefend, cure, kill, camp = CSongliaoWarData:TSLGetMyScoreData()
    if (myCamp ~= campId) then
        -- 不是自己的阵营 不显示自己的数据
        CampPVP2023_TopList_AItem_MyClient:Hide()
    else
        -- 是自己的阵营 显示自己的数据
        CampPVP2023_TopList_AItem_MyClient:Show()

        if (myrank > 0 and myscore >= CampPVP2023_TopList_Ranklist_ScoreLimit ) then
			if myrank > 3 then
				CampPVP2023_TopList_AItem_MyRank:SetText(tostring(myrank))
				CampPVP2023_TopList_AItem_MyRank:Show()
				CampPVP2023_TopList_AItem_MyRankImg:Hide()
			else
				CampPVP2023_TopList_AItem_MyRankImg:SetProperty("Image", g_RankImage[myrank])
				CampPVP2023_TopList_AItem_MyRank:Hide()
				CampPVP2023_TopList_AItem_MyRankImg:Show()
			end
        else
            CampPVP2023_TopList_AItem_MyRank:SetText("-")
			CampPVP2023_TopList_AItem_MyRank:Show()
			CampPVP2023_TopList_AItem_MyRankImg:Hide()
        end
        CampPVP2023_TopList_AItem_MyName:SetText(myname)
        CampPVP2023_TopList_AItem_MyKill:SetText(tostring(mykill))
        CampPVP2023_TopList_AItem_MyDamage:SetText(tostring(mydamage))
        CampPVP2023_TopList_AItem_MyTreat:SetText(tostring(mycure))
        CampPVP2023_TopList_AItem_MyHurt:SetText(tostring(mydamageAfford))
        CampPVP2023_TopList_AItem_MyAvoidInjury:SetText(tostring(mydamageDefend))
        CampPVP2023_TopList_AItem_MyOtherScore:SetText(tostring(myflagNum))
        CampPVP2023_TopList_AItem_MyAllScore:SetText(tostring(myscore))
    end
end -- end func CampPVP2023_TopList_UpdateRankList()