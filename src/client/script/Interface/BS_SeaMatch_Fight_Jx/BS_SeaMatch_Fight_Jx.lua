--试剑天下战斗
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition
local m_MenPaiNameList =
{
	[0]  ={Name="#{SCGZ_180816_30}" , Color="#cff6600", }, --少林
	[1]  ={Name="#{SCGZ_180816_36}" , Color="#cffcc00", }, --明教
	[2]  ={Name="#{SCGZ_180816_37}" , Color="#c00ff00", }, --丐帮
	[3]  ={Name="#{SCGZ_180816_31}" , Color="#c0000ff", }, --武当
	[4]  ={Name="#{SCGZ_180816_33}" , Color="#cff99cc", }, --峨嵋
	[5]  ={Name="#{SCGZ_180816_32}" , Color="#c007700", }, --星宿
	[6]  ={Name="#{SCGZ_180816_41}" , Color="#cffff00", }, --天龙
	[7]  ={Name="#{SCGZ_180816_35}" , Color="#cffffff", }, --天山
	[8]  ={Name="#{SCGZ_180816_34}" , Color="#c7700ff", }, --逍遥
	[9]  ={Name="无门派"     , Color="#c999999", },	
	[10] ={Name="#{SCGZ_180816_40}", Color="#c007fff", }, --慕容
	[11] ={Name="#{SCGZ_180816_38}", Color="#ccc00ff", }, --唐门
	[12] ={Name="#{SCGZ_180816_39}", Color="#c24dec6", },   --鬼谷
	[13] ={Name="#{SCGZ_180816_119}", Color="#ca1d6da", },   --桃花岛
	[14] ={Name="#{XMPHM_210604_01}", Color="#cd61313", }, 
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", Color="#c656ab4", }, --menpai15
}

local g_DieColor = "#cff0000"
local g_DiaoXianColoer = "#ccccccc"

local m_teamAList = {}
local m_teamBList = {}

local m_IsTimerSet = 0
local m_isCanCloseUI = 1
--预加载函数，可以而且只能在这里注册脚本关心的事件
function BS_SeaMatch_Fight_Jx_PreLoad()
	this:RegisterEvent("SJTX_FIGHTUI_OP")
	this:RegisterEvent("SJTX_JIESUAN", false)
	this:RegisterEvent("SJTX_FIGHTDATAUPDATE", false)
	this:RegisterEvent("SJTX_CLOSEUI", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BS_SeaMatch_Fight_Jx_ResetPos()
	BS_SeaMatch_Fight_Jx_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BS_SeaMatch_Fight_Jx_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function BS_SeaMatch_Fight_Jx_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= BS_SeaMatch_Fight_Jx_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= BS_SeaMatch_Fight_Jx_Frame:GetProperty("UnifiedYPosition");
	m_teamAList[1] = {Hp=BS_SeaMatch_Fight_Jx_Left_PlayerHP1,Name=BS_SeaMatch_Fight_Jx_Left_1_name,MenPai=BS_SeaMatch_Fight_Jx_Left_1_Career,Level=BS_SeaMatch_Fight_Jx_Left_1_Level}
	m_teamAList[2] = {Hp=BS_SeaMatch_Fight_Jx_Left_PlayerHP2,Name=BS_SeaMatch_Fight_Jx_Left_2_name,MenPai=BS_SeaMatch_Fight_Jx_Left_2_Career,Level=BS_SeaMatch_Fight_Jx_Left_2_Level}
	m_teamAList[3] = {Hp=BS_SeaMatch_Fight_Jx_Left_PlayerHP3,Name=BS_SeaMatch_Fight_Jx_Left_3_name,MenPai=BS_SeaMatch_Fight_Jx_Left_3_Career,Level=BS_SeaMatch_Fight_Jx_Left_3_Level}
	m_teamAList[4] = {Hp=BS_SeaMatch_Fight_Jx_Left_PlayerHP4,Name=BS_SeaMatch_Fight_Jx_Left_4_name,MenPai=BS_SeaMatch_Fight_Jx_Left_4_Career,Level=BS_SeaMatch_Fight_Jx_Left_4_Level}
	m_teamAList[5] = {Hp=BS_SeaMatch_Fight_Jx_Left_PlayerHP5,Name=BS_SeaMatch_Fight_Jx_Left_5_name,MenPai=BS_SeaMatch_Fight_Jx_Left_5_Career,Level=BS_SeaMatch_Fight_Jx_Left_5_Level}
	m_teamAList[6] = {Hp=BS_SeaMatch_Fight_Jx_Left_PlayerHP6,Name=BS_SeaMatch_Fight_Jx_Left_6_name,MenPai=BS_SeaMatch_Fight_Jx_Left_6_Career,Level=BS_SeaMatch_Fight_Jx_Left_6_Level}

	m_teamBList[1] = {Hp=BS_SeaMatch_Fight_Jx_Right_PlayerHP1,Name=BS_SeaMatch_Fight_Jx_Right_1_name,MenPai=BS_SeaMatch_Fight_Jx_Right_1_Career,Level=BS_SeaMatch_Fight_Jx_Right_1_Level}
	m_teamBList[2] = {Hp=BS_SeaMatch_Fight_Jx_Right_PlayerHP2,Name=BS_SeaMatch_Fight_Jx_Right_2_name,MenPai=BS_SeaMatch_Fight_Jx_Right_2_Career,Level=BS_SeaMatch_Fight_Jx_Right_2_Level}
	m_teamBList[3] = {Hp=BS_SeaMatch_Fight_Jx_Right_PlayerHP3,Name=BS_SeaMatch_Fight_Jx_Right_3_name,MenPai=BS_SeaMatch_Fight_Jx_Right_3_Career,Level=BS_SeaMatch_Fight_Jx_Right_3_Level}
	m_teamBList[4] = {Hp=BS_SeaMatch_Fight_Jx_Right_PlayerHP4,Name=BS_SeaMatch_Fight_Jx_Right_4_name,MenPai=BS_SeaMatch_Fight_Jx_Right_4_Career,Level=BS_SeaMatch_Fight_Jx_Right_4_Level}
	m_teamBList[5] = {Hp=BS_SeaMatch_Fight_Jx_Right_PlayerHP5,Name=BS_SeaMatch_Fight_Jx_Right_5_name,MenPai=BS_SeaMatch_Fight_Jx_Right_5_Career,Level=BS_SeaMatch_Fight_Jx_Right_5_Level}
	m_teamBList[6] = {Hp=BS_SeaMatch_Fight_Jx_Right_PlayerHP6,Name=BS_SeaMatch_Fight_Jx_Right_6_name,MenPai=BS_SeaMatch_Fight_Jx_Right_6_Career,Level=BS_SeaMatch_Fight_Jx_Right_6_Level}
end


--响应事件的函数，当注册的事件发生时会调用的函数
function BS_SeaMatch_Fight_Jx_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	
	if event == "SJTX_FIGHTUI_OP" then
		local  opType = tonumber(arg0)
		if opType == 4 or opType == 6 then --打开界面
			if opType == 6 then
				local sceneState = SJTX:LuaFnGetSJTXSceneSceneState()
				if sceneState ~= 2 then
					return
				end
			end
			if (this:IsVisible()) then
				BS_SeaMatch_Fight_Jx_Update()
				return
			end
			if opType == 6 then
				m_isCanCloseUI = 0
			end
			m_IsTimerSet = 0
			BS_SeaMatch_Fight_Jx_Show()
			BS_SeaMatch_Fight_Jx_Update()

		elseif opType == 5 then --关闭界面
			BS_SeaMatch_Fight_Jx_Hide()
		end
	elseif event == "SJTX_FIGHTDATAUPDATE" then
		local opType = tonumber(arg0)
		if opType == 1 then --更新血量
			BS_SeaMatch_Fight_Jx_Update()
		elseif opType == 2 then --更新首杀
			BS_SeaMatch_Fight_Jx_UpdateFirstKiller()
		elseif opType == 3 then --更新时间
			m_IsTimerSet = 0
			BS_SeaMatch_Fight_Jx_UpdateTime()
		elseif opType == 4 then --更新玩家状态
			BS_SeaMatch_Fight_Jx_Update()
		elseif opType == 5 then --更新比赛积分
			BS_SeaMatch_Fight_Jx_Update()
		end
	elseif (event == "SJTX_JIESUAN") then
		BS_SeaMatch_Fight_Jx_Hide()
	elseif (event == "SJTX_CLOSEUI") then
		BS_SeaMatch_Fight_Jx_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if m_isCanCloseUI == 0 then
			m_isCanCloseUI = 1
			return
		end
		BS_SeaMatch_Fight_Jx_Hide()
	elseif event == "ADJEST_UI_POS" then
		BS_SeaMatch_Fight_Jx_ResetPos()
	end
end

--显示UI
function BS_SeaMatch_Fight_Jx_Show()
	BS_SeaMatch_Fight_Jx_ClearData()

	this:Show()


	
end
--隐藏UI
function BS_SeaMatch_Fight_Jx_Hide()
	BS_SeaMatch_Fight_Jx_ClearData()
	m_isCanCloseUI = 1
	this:Hide()
end
function BS_SeaMatch_Fight_Jx_AutoClick_Timer()
end

--清除数据
function BS_SeaMatch_Fight_Jx_ClearData()

end
--更新
function BS_SeaMatch_Fight_Jx_Update()
	local teamAName, teamBName = SJTX:LuaFnGetSJTXTeamName()
	if "" == teamAName or "" == teamBName then
		BS_SeaMatch_Fight_Jx_Hide()
		return
	end

	local teamAZoneWorldID, teamBZoneWorldID = SJTX:LuaFnGetSJTXTeamZoneWorldID()
	local teamAServerName = DataPool:GetServerName(teamAZoneWorldID)
	local teamBServerName = DataPool:GetServerName(teamBZoneWorldID)
	if teamAServerName == nil then
		teamAServerName = ""
	end
	if teamBServerName == nil then
		teamBServerName = ""
	end

	local selfSuoShu = SJTX:LuaFnGetSJTXSceneSelfSuoShu()
	local otherSuoShu = 1
	if selfSuoShu ~= 1 and selfSuoShu ~= 2 then
		selfSuoShu = 1
	end
	if selfSuoShu == 1 then
		otherSuoShu = 2
	end 
	if teamAServerName ~= "" then
		teamAName = teamAName.."@"..teamAServerName
	end
	if teamBServerName ~= "" then
		teamBName = teamBName.."@"..teamBServerName
	end
	if selfSuoShu == 1 then
		BS_SeaMatch_Fight_Jx_LeftList_TitleBK:SetText(teamAName)
		BS_SeaMatch_Fight_Jx_RightList_TitleBK:SetText(teamBName)
	else
		BS_SeaMatch_Fight_Jx_LeftList_TitleBK:SetText(teamBName)
		BS_SeaMatch_Fight_Jx_RightList_TitleBK:SetText(teamAName)
	end

	BS_SeaMatch_Fight_Jx_UpdateTime()

	BS_SeaMatch_Fight_Jx_UpdateFirstKiller()


	--A对信息
	for index=1, 6 do
		m_teamAList[index].Hp:SetProgress(0, 100)
		m_teamAList[index].Name:SetText("")
		m_teamAList[index].MenPai:SetText("")
		m_teamAList[index].Level:SetText("")
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(selfSuoShu, index - 1 )
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			-- PushDebugMessage("A "..menPai.." "..level.." "..name.." "..duanWei.." "..hp.." "..state.." "..score)
			if state == 0 then      --0-正常
				m_teamAList[index].Hp:SetProgress(hp, 100)
				m_teamAList[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
				m_teamAList[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
				m_teamAList[index].Level:SetText(m_MenPaiNameList[menPai].Color..level)
			elseif state == 1 then --死亡
				m_teamAList[index].Hp:SetProgress(hp, 100)
				m_teamAList[index].Name:SetText(g_DieColor..name)
				m_teamAList[index].MenPai:SetText(g_DieColor..m_MenPaiNameList[menPai].Name)
				m_teamAList[index].Level:SetText(g_DieColor..level)
			elseif state == 2 then --掉线
				m_teamAList[index].Hp:SetProgress(0, 100)
				-- m_teamAList[index].Name:SetText("")
				-- m_teamAList[index].MenPai:SetText("")
				-- m_teamAList[index].Level:SetText("")
				m_teamAList[index].Name:SetText(name)
				m_teamAList[index].MenPai:SetText(m_MenPaiNameList[menPai].Name)
				m_teamAList[index].Level:SetText(level)
			end
		end
	end

	--B对信息
	for index=1, 6 do
		
		m_teamBList[index].Hp:SetProgress(0, 100)
		m_teamBList[index].Name:SetText("")
		m_teamBList[index].MenPai:SetText("")
		m_teamBList[index].Level:SetText("")
		local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score = SJTX:LuaFnGetSJTXScenePlayerData(otherSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			-- PushDebugMessage("B "..menPai.." "..level.." "..name.." "..duanWei.." "..hp.." "..state.." "..score)
			if state == 0 then      --0-正常
				m_teamBList[index].Hp:SetProgress(hp, 100)
				m_teamBList[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
				m_teamBList[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
				m_teamBList[index].Level:SetText(m_MenPaiNameList[menPai].Color..level)
			elseif state == 1 then --死亡
				m_teamBList[index].Hp:SetProgress(hp, 100)
				m_teamBList[index].Name:SetText(g_DieColor..name)
				m_teamBList[index].MenPai:SetText(g_DieColor..m_MenPaiNameList[menPai].Name)
				m_teamBList[index].Level:SetText(g_DieColor..level)
			elseif state == 2 then --掉线
				m_teamBList[index].Hp:SetProgress(0, 100)
				-- m_teamBList[index].Name:SetText("")
				-- m_teamBList[index].MenPai:SetText("")
				-- m_teamBList[index].Level:SetText("")
				m_teamBList[index].Name:SetText(name)
				m_teamBList[index].MenPai:SetText(m_MenPaiNameList[menPai].Name)
				m_teamBList[index].Level:SetText(level)
			end
		end
	end
end

--更新时间
function BS_SeaMatch_Fight_Jx_UpdateTime()
	BS_SeaMatch_Fight_Jx_WatchText:Hide()
	-- if m_IsTimerSet == 0 then
	-- 	m_IsTimerSet = 1
		local remainTime = SJTX:LuaFnGetSJTXSceneRemainTime()
		if remainTime < 0 then
			remainTime = 0
		end
		BS_SeaMatch_Fight_Jx_TimeWatch:SetProperty("Timer", remainTime)
	-- end
end
--更新首杀
function BS_SeaMatch_Fight_Jx_UpdateFirstKiller()
	BS_SeaMatch_Fight_Jx_Team1FirstKill:Hide()
	BS_SeaMatch_Fight_Jx_Team2FirstKill:Hide()
	local firstKillerResult = SJTX:LuaFnGetSJTXSceneFirstKillerResult()

	local selfSuoShu = SJTX:LuaFnGetSJTXSceneSelfSuoShu()
	local otherSuoShu = 1
	if selfSuoShu ~= 1 and selfSuoShu ~= 2 then
		selfSuoShu = 1
	end
	if selfSuoShu == 1 then
		otherSuoShu = 2
	end 
	if selfSuoShu == 1 then
		if firstKillerResult == 1 then
			BS_SeaMatch_Fight_Jx_Team1FirstKill:Show()
		elseif firstKillerResult == 2 then
			BS_SeaMatch_Fight_Jx_Team2FirstKill:Show()
		end
	else
		if firstKillerResult == 1 then
			BS_SeaMatch_Fight_Jx_Team2FirstKill:Show()
		elseif firstKillerResult == 2 then
			BS_SeaMatch_Fight_Jx_Team1FirstKill:Show()
		end
	end
end
--##############点击事件##############
function BS_SeaMatch_Fight_JxFrame_CloseWindow()
	PushEvent("SJTX_FIGHTUI_OP", 5)
end
function BS_SeaMatch_Fight_Jx_OnTimer()
	
end
function BS_SeaMatch_Fight_Jx_Raid_Left_Click(idx)
	local selfSuoShu = SJTX:LuaFnGetSJTXSceneSelfSuoShu()
	if selfSuoShu ~= 1 and selfSuoShu ~= 2 then
		selfSuoShu = 1
	end
	if selfSuoShu == 1 then
		SJTX:LuaFnSetSJTXMainTargetByUIIdx(1, idx)
	else
		SJTX:LuaFnSetSJTXMainTargetByUIIdx(2, idx)
	end
end
function BS_SeaMatch_Fight_Jx_Raid_Right_Click(idx)
	local selfSuoShu = SJTX:LuaFnGetSJTXSceneSelfSuoShu()
	if selfSuoShu ~= 1 and selfSuoShu ~= 2 then
		selfSuoShu = 1
	end
	if selfSuoShu == 1 then
		SJTX:LuaFnSetSJTXMainTargetByUIIdx(2, idx)
	else
		SJTX:LuaFnSetSJTXMainTargetByUIIdx(1, idx)
	end
end
--####################################