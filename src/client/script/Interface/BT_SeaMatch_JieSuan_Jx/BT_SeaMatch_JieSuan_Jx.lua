--试剑天下结算
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
	[13] ={Name="#{SCGZ_180816_119}", Color="#c24dec6", },   --桃花岛
	[14] ={Name="#{XMPHM_210604_01}", Color="#c24dec6", },
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", Color="#c656ab4", },--menpai15
}

local g_DieColor = "#cff0000"
local g_DiaoXianColoer = "#ccccccc"

local m_matchScoreImage = 
{
	[1] = "set:BW_Match17 image:+1",
	[2] = "set:BW_Match17 image:+2",
}

local m_teamAList = {}
local m_teamBList = {}


local m_isCanCloseUI = 1
--预加载函数，可以而且只能在这里注册脚本关心的事件
function BT_SeaMatch_JieSuan_Jx_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("DFS_JIESUAN")
	this:RegisterEvent("DFS_FIGHTUI_OP")
	this:RegisterEvent("DFS_FIGHTDATAUPDATE", false)
	this:RegisterEvent("DFS_CLOSEUI", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_SeaMatch_JieSuan_Jx_ResetPos()
	BT_SeaMatch_JieSuan_Jx_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_SeaMatch_JieSuan_Jx_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end


--加载窗口的时候调用的函数，加载窗口时调用一次
function BT_SeaMatch_JieSuan_Jx_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= BT_SeaMatch_JieSuan_Jx_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= BT_SeaMatch_JieSuan_Jx_Frame:GetProperty("UnifiedYPosition");
	m_teamAList[1] = {Hp=BT_SeaMatch_JieSuan_Jx_Left_PlayerHP1,Name=BT_SeaMatch_JieSuan_Jx_Left_1_name,MenPai=BT_SeaMatch_JieSuan_Jx_Left_1_Career,Level=BT_SeaMatch_JieSuan_Jx_Left_1_Level,Number=BT_SeaMatch_JieSuan_Jx_Left_1_Number}
	m_teamAList[2] = {Hp=BT_SeaMatch_JieSuan_Jx_Left_PlayerHP2,Name=BT_SeaMatch_JieSuan_Jx_Left_2_name,MenPai=BT_SeaMatch_JieSuan_Jx_Left_2_Career,Level=BT_SeaMatch_JieSuan_Jx_Left_2_Level,Number=BT_SeaMatch_JieSuan_Jx_Left_2_Number}
	m_teamAList[3] = {Hp=BT_SeaMatch_JieSuan_Jx_Left_PlayerHP3,Name=BT_SeaMatch_JieSuan_Jx_Left_3_name,MenPai=BT_SeaMatch_JieSuan_Jx_Left_3_Career,Level=BT_SeaMatch_JieSuan_Jx_Left_3_Level,Number=BT_SeaMatch_JieSuan_Jx_Left_3_Number}
	m_teamAList[4] = {Hp=BT_SeaMatch_JieSuan_Jx_Left_PlayerHP4,Name=BT_SeaMatch_JieSuan_Jx_Left_4_name,MenPai=BT_SeaMatch_JieSuan_Jx_Left_4_Career,Level=BT_SeaMatch_JieSuan_Jx_Left_4_Level,Number=BT_SeaMatch_JieSuan_Jx_Left_4_Number}
	m_teamAList[5] = {Hp=BT_SeaMatch_JieSuan_Jx_Left_PlayerHP5,Name=BT_SeaMatch_JieSuan_Jx_Left_5_name,MenPai=BT_SeaMatch_JieSuan_Jx_Left_5_Career,Level=BT_SeaMatch_JieSuan_Jx_Left_5_Level,Number=BT_SeaMatch_JieSuan_Jx_Left_5_Number}
	m_teamAList[6] = {Hp=BT_SeaMatch_JieSuan_Jx_Left_PlayerHP6,Name=BT_SeaMatch_JieSuan_Jx_Left_6_name,MenPai=BT_SeaMatch_JieSuan_Jx_Left_6_Career,Level=BT_SeaMatch_JieSuan_Jx_Left_6_Level,Number=BT_SeaMatch_JieSuan_Jx_Left_6_Number}

	m_teamBList[1] = {Hp=BT_SeaMatch_JieSuan_Jx_Right_PlayerHP1,Name=BT_SeaMatch_JieSuan_Jx_Right_1_name,MenPai=BT_SeaMatch_JieSuan_Jx_Right_1_Career,Level=BT_SeaMatch_JieSuan_Jx_Right_1_Level,Number=BT_SeaMatch_JieSuan_Jx_Right_1_Number}
	m_teamBList[2] = {Hp=BT_SeaMatch_JieSuan_Jx_Right_PlayerHP2,Name=BT_SeaMatch_JieSuan_Jx_Right_2_name,MenPai=BT_SeaMatch_JieSuan_Jx_Right_2_Career,Level=BT_SeaMatch_JieSuan_Jx_Right_2_Level,Number=BT_SeaMatch_JieSuan_Jx_Right_2_Number}
	m_teamBList[3] = {Hp=BT_SeaMatch_JieSuan_Jx_Right_PlayerHP3,Name=BT_SeaMatch_JieSuan_Jx_Right_3_name,MenPai=BT_SeaMatch_JieSuan_Jx_Right_3_Career,Level=BT_SeaMatch_JieSuan_Jx_Right_3_Level,Number=BT_SeaMatch_JieSuan_Jx_Right_3_Number}
	m_teamBList[4] = {Hp=BT_SeaMatch_JieSuan_Jx_Right_PlayerHP4,Name=BT_SeaMatch_JieSuan_Jx_Right_4_name,MenPai=BT_SeaMatch_JieSuan_Jx_Right_4_Career,Level=BT_SeaMatch_JieSuan_Jx_Right_4_Level,Number=BT_SeaMatch_JieSuan_Jx_Right_4_Number}
	m_teamBList[5] = {Hp=BT_SeaMatch_JieSuan_Jx_Right_PlayerHP5,Name=BT_SeaMatch_JieSuan_Jx_Right_5_name,MenPai=BT_SeaMatch_JieSuan_Jx_Right_5_Career,Level=BT_SeaMatch_JieSuan_Jx_Right_5_Level,Number=BT_SeaMatch_JieSuan_Jx_Right_5_Number}
	m_teamBList[6] = {Hp=BT_SeaMatch_JieSuan_Jx_Right_PlayerHP6,Name=BT_SeaMatch_JieSuan_Jx_Right_6_name,MenPai=BT_SeaMatch_JieSuan_Jx_Right_6_Career,Level=BT_SeaMatch_JieSuan_Jx_Right_6_Level,Number=BT_SeaMatch_JieSuan_Jx_Right_6_Number}
end


--响应事件的函数，当注册的事件发生时会调用的函数
function BT_SeaMatch_JieSuan_Jx_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		return
	end
	
	if event == "DFS_JIESUAN" then
		local  opType = tonumber(arg0)
		if opType == 3 then
			if (this:IsVisible()) then
				BT_SeaMatch_JieSuan_Jx_Update()
				return
			end
			BT_SeaMatch_JieSuan_Jx_Show()
			BT_SeaMatch_JieSuan_Jx_Update()
		end
	elseif event == "DFS_FIGHTUI_OP" then
		local  opType = tonumber(arg0)
		if opType == 9 then --打开界面

			local sceneState = DFS:LuaFnGetDfsSceneSceneState()
			if sceneState ~= 3 then
				return
			end
			if (this:IsVisible()) then
				BT_SeaMatch_JieSuan_Jx_Update()
				return
			end
			m_isCanCloseUI = 0
			BT_SeaMatch_JieSuan_Jx_Show()
			BT_SeaMatch_JieSuan_Jx_Update()
		end
	elseif event == "DFS_FIGHTDATAUPDATE" then
		local opType = tonumber(arg0)
		if opType == 4 then --更新玩家状态
			BT_SeaMatch_JieSuan_Jx_Update()
		elseif opType == 1 then
			BT_SeaMatch_JieSuan_Jx_Update()
		end
	elseif (event == "DFS_CLOSEUI") then
		BT_SeaMatch_JieSuan_Jx_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if m_isCanCloseUI == 0 then
			m_isCanCloseUI = 1
			return
		end
		BT_SeaMatch_JieSuan_Jx_Hide()
	elseif event == "ADJEST_UI_POS" then
		BT_SeaMatch_JieSuan_Jx_ResetPos()
	end
end

--显示UI
function BT_SeaMatch_JieSuan_Jx_Show()
	BT_SeaMatch_JieSuan_Jx_ClearData()

	this:Show()
	
end
--隐藏UI
function BT_SeaMatch_JieSuan_Jx_Hide()
	BT_SeaMatch_JieSuan_Jx_ClearData()
	m_isCanCloseUI = 1
	this:Hide()
end

--清除数据
function BT_SeaMatch_JieSuan_Jx_ClearData()

end
--更新
function BT_SeaMatch_JieSuan_Jx_Update()
	BT_SeaMatch_JieSuan_Jx_Team1FirstKill:Hide()
	BT_SeaMatch_JieSuan_Jx_Team2FirstKill:Hide()
	local teamAName, teamBName = DFS:LuaFnGetDfsTeamName()
	if "" == teamAName or "" == teamBName then
		BT_SeaMatch_JieSuan_Jx_Hide()
		return
	end
	local teamAZoneWorldID, teamBZoneWorldID = DFS:LuaFnGetDfsTeamZoneWorldID()
	local teamAServerName = DataPool:GetServerName(teamAZoneWorldID)
	local teamBServerName = DataPool:GetServerName(teamBZoneWorldID)
	if teamAServerName == nil then
		teamAServerName = ""
	end
	if teamBServerName == nil then
		teamBServerName = ""
	end
	
	BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK:Hide()
	BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK1:Hide()
	local ajiFen, bjiFen, teamFlag, addScore = DFS:LuaFnGetDfsSceneJiFen()
	local firstKillerResult = DFS:LuaFnGetDfsSceneFirstKillerResult()
	local matchResult = DFS:LuaFnGetDfsSceneMatchResult()

	local selfSuoShu = DFS:LuaFnGetDfsSceneSelfSuoShu()
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
		BT_SeaMatch_JieSuan_Jx_LeftList_TitleBK:SetText(teamAName)
		BT_SeaMatch_JieSuan_Jx_RightList_TitleBK:SetText(teamBName)
		BT_SeaMatch_JieSuan_Jx_BiFen_TitleBK:SetText("#c6a3906"..ajiFen..":"..bjiFen)
		if teamFlag == 1 and nil ~= m_matchScoreImage[addScore] then
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK:Show()
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK:SetProperty("Image",m_matchScoreImage[addScore])
		elseif teamFlag == 2 and nil ~= m_matchScoreImage[addScore] then
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK1:Show()
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK1:SetProperty("Image",m_matchScoreImage[addScore])
		end
		if firstKillerResult == 1 then
			BT_SeaMatch_JieSuan_Jx_Team1FirstKill:Show()
		elseif firstKillerResult == 2 then
			BT_SeaMatch_JieSuan_Jx_Team2FirstKill:Show()
		end
		if matchResult == 1 then
			BT_SeaMatch_JieSuan_Jx_Team_Left:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
			BT_SeaMatch_JieSuan_Jx_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		elseif matchResult == 2 then
			BT_SeaMatch_JieSuan_Jx_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BT_SeaMatch_JieSuan_Jx_Team_Right:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
		else
			BT_SeaMatch_JieSuan_Jx_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BT_SeaMatch_JieSuan_Jx_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		end
	else
		BT_SeaMatch_JieSuan_Jx_LeftList_TitleBK:SetText(teamBName)
		BT_SeaMatch_JieSuan_Jx_RightList_TitleBK:SetText(teamAName)
		BT_SeaMatch_JieSuan_Jx_BiFen_TitleBK:SetText(bjiFen..":"..ajiFen)
		if teamFlag == 1 and nil ~= m_matchScoreImage[addScore] then
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK1:Show()
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK1:SetProperty("Image",m_matchScoreImage[addScore])
		elseif teamFlag == 2 and nil ~= m_matchScoreImage[addScore] then
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK:Show()
			BT_SeaMatch_JieSuan_Jx_jiacheng_TitleBK:SetProperty("Image",m_matchScoreImage[addScore])
		end
		if firstKillerResult == 1 then
			BT_SeaMatch_JieSuan_Jx_Team2FirstKill:Show()
		elseif firstKillerResult == 2 then
			BT_SeaMatch_JieSuan_Jx_Team1FirstKill:Show()
		end
		if matchResult == 1 then
			BT_SeaMatch_JieSuan_Jx_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BT_SeaMatch_JieSuan_Jx_Team_Right:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
		elseif matchResult == 2 then
			BT_SeaMatch_JieSuan_Jx_Team_Left:SetProperty("Image", "set:Wangzhe1 image:Wangzhe_sheng")
			BT_SeaMatch_JieSuan_Jx_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		else
			BT_SeaMatch_JieSuan_Jx_Team_Left:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
			BT_SeaMatch_JieSuan_Jx_Team_Right:SetProperty("Image","set:Wangzhe2 image:Wangzhe_fu")
		end
	end
	--A对信息
	for index=1, 6 do
		m_teamAList[index].Hp:SetProgress(0, 100)
		m_teamAList[index].Name:SetText("")
		m_teamAList[index].MenPai:SetText("")
		m_teamAList[index].Level:SetText("")
		m_teamAList[index].Number:SetText("")
		local menPai, level, name, hp, state, score = DFS:LuaFnGetDfsScenePlayerData(selfSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamAList[index].Hp:SetProgress(hp, 100)
			m_teamAList[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamAList[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamAList[index].Level:SetText(m_MenPaiNameList[menPai].Color..level)
			m_teamAList[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
		end
	end

	--B对信息
	for index=1, 6 do
		m_teamBList[index].Hp:SetProgress(0, 100)
		m_teamBList[index].Name:SetText("")
		m_teamBList[index].MenPai:SetText("")
		m_teamBList[index].Level:SetText("")
		m_teamBList[index].Number:SetText("")
		local menPai, level, name, hp, state, score = DFS:LuaFnGetDfsScenePlayerData(otherSuoShu, index - 1)
		if nil ~= name and ""~=name and nil ~= m_MenPaiNameList[menPai] then
			m_teamBList[index].Hp:SetProgress(hp, 100)
			m_teamBList[index].Name:SetText(m_MenPaiNameList[menPai].Color..name)
			m_teamBList[index].MenPai:SetText(m_MenPaiNameList[menPai].Color..m_MenPaiNameList[menPai].Name)
			m_teamBList[index].Level:SetText(m_MenPaiNameList[menPai].Color..level)
			m_teamBList[index].Number:SetText(m_MenPaiNameList[menPai].Color..math.mod(score,10))
			
		end
	end
end

--##############点击事件##############
--####################################