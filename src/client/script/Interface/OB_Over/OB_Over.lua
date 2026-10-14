--数据统计面板
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
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", Color="#c656ab4", },--menpai15
}

local g_DieColor = "#cff0000"

local g_teamAList = {}
local g_teamBList = {}

local g_WinList = {}

local g_MaxTeamMember = 6
local g_TeamA = 1
local g_TeamB = 2

--全局可改变的变量
local g_OpenSingle = 1
local g_SingleShowType = 2 --显示血条1 /文字2
local g_RoundOver = 0	--本轮比赛是否结束
local g_bShowFirstKiller = 0 --是否显示首杀


--预加载函数，可以而且只能在这里注册脚本关心的事件
function OB_Over_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("GMVISIBLE_CHANGEDATA",false) --变化的数据

	this:RegisterEvent("SJTX_JIESUAN")
	this:RegisterEvent("DFS_JIESUAN")
	this:RegisterEvent("SHOW_PK_RESULT_2018") --比赛结果
	this:RegisterEvent("ZBS_BATTLE_RESULT")
	
	this:RegisterEvent("OPEN_GMVISIBLE_DATA")

	this:RegisterEvent("DFS_FIGHTDATAUPDATE", false)
	this:RegisterEvent("SJTX_FIGHTDATAUPDATE", false)
	this:RegisterEvent("CORPS_COPYDATA_REFRESH_2018", false) --首杀
	this:RegisterEvent("ZBS_BATTLE_REFRESH", false)

	--this:RegisterEvent("DFS_CLOSEUI")
	--this:RegisterEvent("SJTX_CLOSEUI")
	
	this:RegisterEvent("GMVISIBLE_OPEN")
	this:RegisterEvent("GMVISIBLE_CLOSE", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function OB_Over_ResetPos()
	OB_Over_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	OB_Over_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end


--加载窗口的时候调用的函数，加载窗口时调用一次
function OB_Over_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= OB_Over_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= OB_Over_Frame:GetProperty("UnifiedYPosition");

	g_teamAList[1] = {player=OB_Over_Single_Team1_Player1, name=OB_Over_Single_Team1_Player1_Name, menpai=OB_Over_Single_Team1_Player1_MenPai,
		kill=OB_Over_Single_Team1_Player1_Kill, damage=OB_Over_Single_Team1_Player1_Damage, chengshang=OB_Over_Single_Team1_Player1_Tank,
		cure=OB_Over_Single_Team1_Player1_Heal, damageText=OB_Over_Single_Team1_Player1_DamageText, chengshangText=OB_Over_Single_Team1_Player1_TankText,
		cureText=OB_Over_Single_Team1_Player1_HealText}

	g_teamAList[2] = {player=OB_Over_Single_Team1_Player2, name=OB_Over_Single_Team1_Player2_Name, menpai=OB_Over_Single_Team1_Player2_MenPai, kill=OB_Over_Single_Team1_Player2_Kill,
		damage=OB_Over_Single_Team1_Player2_Damage, chengshang=OB_Over_Single_Team1_Player2_Tank, cure=OB_Over_Single_Team1_Player2_Heal,
		damageText=OB_Over_Single_Team1_Player2_DamageText, chengshangText=OB_Over_Single_Team1_Player2_TankText, cureText=OB_Over_Single_Team1_Player2_HealText}

	g_teamAList[3] = {player=OB_Over_Single_Team1_Player3, name=OB_Over_Single_Team1_Player3_Name, menpai=OB_Over_Single_Team1_Player3_MenPai, kill=OB_Over_Single_Team1_Player3_Kill,
		damage=OB_Over_Single_Team1_Player3_Damage, chengshang=OB_Over_Single_Team1_Player3_Tank, cure=OB_Over_Single_Team1_Player3_Heal,
		damageText=OB_Over_Single_Team1_Player3_DamageText, chengshangText=OB_Over_Single_Team1_Player3_TankText, cureText=OB_Over_Single_Team1_Player3_HealText}

	g_teamAList[4] = {player=OB_Over_Single_Team1_Player4, name=OB_Over_Single_Team1_Player4_Name, menpai=OB_Over_Single_Team1_Player4_MenPai, kill=OB_Over_Single_Team1_Player4_Kill,
		damage=OB_Over_Single_Team1_Player4_Damage, chengshang=OB_Over_Single_Team1_Player4_Tank, cure=OB_Over_Single_Team1_Player4_Heal,
		damageText=OB_Over_Single_Team1_Player4_DamageText, chengshangText=OB_Over_Single_Team1_Player4_TankText, cureText=OB_Over_Single_Team1_Player4_HealText}

	g_teamAList[5] = {player=OB_Over_Single_Team1_Player5, name=OB_Over_Single_Team1_Player5_Name, menpai=OB_Over_Single_Team1_Player5_MenPai, kill=OB_Over_Single_Team1_Player5_Kill,
		damage=OB_Over_Single_Team1_Player5_Damage, chengshang=OB_Over_Single_Team1_Player5_Tank, cure=OB_Over_Single_Team1_Player5_Heal,
		damageText=OB_Over_Single_Team1_Player5_DamageText, chengshangText=OB_Over_Single_Team1_Player5_TankText, cureText=OB_Over_Single_Team1_Player5_HealText}

	g_teamAList[6] = {player=OB_Over_Single_Team1_Player6, name=OB_Over_Single_Team1_Player6_Name, menpai=OB_Over_Single_Team1_Player6_MenPai, kill=OB_Over_Single_Team1_Player6_Kill,
		damage=OB_Over_Single_Team1_Player6_Damage, chengshang=OB_Over_Single_Team1_Player6_Tank, cure=OB_Over_Single_Team1_Player6_Heal,
		damageText=OB_Over_Single_Team1_Player6_DamageText, chengshangText=OB_Over_Single_Team1_Player6_TankText, cureText=OB_Over_Single_Team1_Player6_HealText}

	g_teamBList[1] = {player=OB_Over_Single_Team2_Player1, name=OB_Over_Single_Team2_Player1_Name, menpai=OB_Over_Single_Team2_Player1_MenPai, kill=OB_Over_Single_Team2_Player1_Kill,
		damage=OB_Over_Single_Team2_Player1_Damage, chengshang=OB_Over_Single_Team2_Player1_Tank, cure=OB_Over_Single_Team2_Player1_Heal,
		damageText=OB_Over_Single_Team2_Player1_DamageText, chengshangText=OB_Over_Single_Team2_Player1_TankText, cureText=OB_Over_Single_Team2_Player1_HealText}

	g_teamBList[2] = {player=OB_Over_Single_Team2_Player2, name=OB_Over_Single_Team2_Player2_Name, menpai=OB_Over_Single_Team2_Player2_MenPai, kill=OB_Over_Single_Team2_Player2_Kill,
		damage=OB_Over_Single_Team2_Player2_Damage, chengshang=OB_Over_Single_Team2_Player2_Tank, cure=OB_Over_Single_Team2_Player2_Heal,
		damageText=OB_Over_Single_Team2_Player2_DamageText, chengshangText=OB_Over_Single_Team2_Player2_TankText, cureText=OB_Over_Single_Team2_Player2_HealText}

	g_teamBList[3] = {player=OB_Over_Single_Team2_Player3, name=OB_Over_Single_Team2_Player3_Name, menpai=OB_Over_Single_Team2_Player3_MenPai, kill=OB_Over_Single_Team2_Player3_Kill,
		damage=OB_Over_Single_Team2_Player3_Damage, chengshang=OB_Over_Single_Team2_Player3_Tank, cure=OB_Over_Single_Team2_Player3_Heal,
		damageText=OB_Over_Single_Team2_Player3_DamageText, chengshangText=OB_Over_Single_Team2_Player3_TankText, cureText=OB_Over_Single_Team2_Player3_HealText}

	g_teamBList[4] = {player=OB_Over_Single_Team2_Player4, name=OB_Over_Single_Team2_Player4_Name, menpai=OB_Over_Single_Team2_Player4_MenPai, kill=OB_Over_Single_Team2_Player4_Kill,
		damage=OB_Over_Single_Team2_Player4_Damage, chengshang=OB_Over_Single_Team2_Player4_Tank, cure=OB_Over_Single_Team2_Player4_Heal,
		damageText=OB_Over_Single_Team2_Player4_DamageText, chengshangText=OB_Over_Single_Team2_Player4_TankText, cureText=OB_Over_Single_Team2_Player4_HealText}

	g_teamBList[5] = {player=OB_Over_Single_Team2_Player5, name=OB_Over_Single_Team2_Player5_Name, menpai=OB_Over_Single_Team2_Player5_MenPai, kill=OB_Over_Single_Team2_Player5_Kill,
		damage=OB_Over_Single_Team2_Player5_Damage, chengshang=OB_Over_Single_Team2_Player5_Tank, cure=OB_Over_Single_Team2_Player5_Heal,
		damageText=OB_Over_Single_Team2_Player5_DamageText, chengshangText=OB_Over_Single_Team2_Player5_TankText, cureText=OB_Over_Single_Team2_Player5_HealText}

	g_teamBList[6] = {player=OB_Over_Single_Team2_Player6, name=OB_Over_Single_Team2_Player6_Name, menpai=OB_Over_Single_Team2_Player6_MenPai, kill=OB_Over_Single_Team2_Player6_Kill,
		damage=OB_Over_Single_Team2_Player6_Damage, chengshang=OB_Over_Single_Team2_Player6_Tank, cure=OB_Over_Single_Team2_Player6_Heal,
		damageText=OB_Over_Single_Team2_Player6_DamageText, chengshangText=OB_Over_Single_Team2_Player6_TankText, cureText=OB_Over_Single_Team2_Player6_HealText}

	g_WinList[0] = {OB_Over_Team_Team1_Win, OB_Over_Team_Team2_Win}
	g_WinList[1] = {OB_Over_Single_Team1_Win, OB_Over_Single_Team2_Win}

end


--响应事件的函数，当注册的事件发生时会调用的函数
function OB_Over_OnEvent(event)
	if( event == "GMVISIBLE_CLOSE" ) then
		OB_Over_Hide()
	end
	if DataPool:LuaFnGetGMVisibleType() == 0 then
		return
	end

	if event == "GMVISIBLE_CHANGEDATA" then
		--下一局开始
		if g_RoundOver == 1 then
			OB_Over_RoundBegin()
		end
		
		OB_Over_Update_Member() --更新承伤、伤害、治疗

	elseif event == "SJTX_JIESUAN" then
		local  opType = tonumber(arg0)
		if opType == 2 then --季后赛决赛
			
			OB_Over_RoundEnd()
			OB_Over_Show(1)
		end

	elseif event == "DFS_JIESUAN" then
		local  opType = tonumber(arg0)
		if opType == 3 then --巅峰赛
		
			OB_Over_RoundEnd()
			OB_Over_Show(2)
		end
	elseif event == "SHOW_PK_RESULT_2018" then
		OB_Over_RoundEnd()
		OB_Over_Show(4)
	elseif event == "ZBS_BATTLE_RESULT" then
		OB_Over_RoundEnd()
		OB_Over_Show(5)
	elseif event == "OPEN_GMVISIBLE_DATA" then
		if this:IsVisible() then
			OB_Over_Hide()
		else
			OB_Over_Show(3)
		end
	elseif event == "SJTX_FIGHTDATAUPDATE" or event == "DFS_FIGHTDATAUPDATE" then
		local opType = tonumber(arg0)
		if opType == 4 then --更新玩家击杀数量
			OB_Over_Update_Member()
		elseif opType == 2 then --更新首杀
			g_bShowFirstKiller = 1
			OB_Over_Update_FirstKiller()
		else
			return
		end
		
	elseif event == "CORPS_COPYDATA_SYNC_KILL_2018" then
		OB_Over_Update_Member() --更新玩家击杀数量
		
	elseif event == "CORPS_COPYDATA_REFRESH_2018" then
		g_bShowFirstKiller = 1
		OB_Over_Update_FirstKiller()
	elseif event == "ZBS_BATTLE_REFRESH" then
		g_bShowFirstKiller = 1
		OB_Over_Update_FirstKiller()
		OB_Over_Update_Member()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		OB_Over_Hide()

	elseif event == "ADJEST_UI_POS" then
		OB_Over_ResetPos()

	elseif event == "GMVISIBLE_OPEN" then
		OB_Over_Init()
	end
end


--每局只初始化一次的值
function OB_Over_Init()
	g_OpenSingle = 1
	g_SingleShowType = 2
	g_bShowFirstKiller = 0
	
end

--下局开始
function OB_Over_RoundBegin()
	g_RoundOver = 0
	
	g_bShowFirstKiller = 0
	OB_Over_Update_FirstKiller()
	OB_Over_Update_JieSuan()
end

--每局结束
function OB_Over_RoundEnd()
	g_RoundOver = 1
	
end


--显示UI
function OB_Over_Show(aa)
	--PushDebugMessage("OB_Over_Show="..aa)
	if g_OpenSingle == 1 then
		OB_Over_Switch_Show_Single()
	else
		OB_Over_Switch_Show_Team()
	end
	
	this:Show()
end

--隐藏UI
function OB_Over_Hide()
	this:Hide()
end

--结算数据更新
function OB_Over_Update_JieSuan()
	local winButton = g_WinList[g_OpenSingle]
	
	winButton[1]:Hide()
	winButton[2]:Hide()

	if g_RoundOver ~= 1 then
		return
	end
	
	local matchResult = -1
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		matchResult = SJTX:LuaFnGetSJTXSceneMatchResult()
	elseif matchType == 2 then
		matchResult = DFS:LuaFnGetDfsSceneMatchResult()
	elseif matchType == 3 then
		matchResult = CorpsUI_2018:GetCorpsPK_Result_Info()
	elseif matchType == 4 then
		matchResult = ZBS:GetBattleVisiableInfo("Result")
	end
	
	if matchResult == -1 then
		return
	end
	
	--胜负
	if matchResult == 1 then
		winButton[1]:Show()
		
	elseif matchResult == 2 then
		winButton[2]:Show()
		
	end

end


--首杀
function OB_Over_Update_FirstKiller()
	OB_Over_Single_Team1Title_FB : Hide()
	OB_Over_Single_Team2Title_FB : Hide()
	OB_Over_Team_Team1_FB : Hide()
	OB_Over_Team_Team2_FB : Hide()
		
	if g_bShowFirstKiller == 0 then
		return
	end
	
	local firstKillerResult = 0

	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		firstKillerResult = SJTX:LuaFnGetSJTXSceneFirstKillerResult()
	elseif matchType == 2 then
		firstKillerResult = DFS:LuaFnGetDfsSceneFirstKillerResult()
	elseif matchType == 3 then
		firstKillerResult = CorpsUI_2018:GetCopySceneFirstKillerType()
	elseif matchType == 4 then
		firstKillerResult = ZBS:GetBattleVisiableInfo("FirstBlood")
	end
	
	if g_OpenSingle == 1 then
		if firstKillerResult == 1 then
			OB_Over_Single_Team1Title_FB : Show()

		elseif firstKillerResult == 2 then
			OB_Over_Single_Team2Title_FB : Show()
		end

	else		
		if firstKillerResult == 1 then
			OB_Over_Team_Team1_FB : Show()

		elseif firstKillerResult == 2 then
			OB_Over_Team_Team2_FB : Show()
		end
	end

end

--切换ui
function OB_Over_Switch_Show_Team()
	g_OpenSingle = 0
	
	OB_Over_Single_ClientBK : Hide()
	OB_Over_Team_ClientBK : Show()
	
	OB_Over_Update_JieSuan()
	OB_Over_Update_FirstKiller()
	OB_Over_Update_Member()
end

function OB_Over_Switch_Show_Single()
	g_OpenSingle = 1
	
	OB_Over_Single_ClientBK : Show()
	OB_Over_Team_ClientBK : Hide()
	
	OB_Over_Update_JieSuan()
	OB_Over_Update_FirstKiller()
	OB_Over_Update_Member()
end

--切换数据
function OB_Over_Switch_Data_Click()

	if g_SingleShowType == 1 then
		g_SingleShowType = 2
	else
		g_SingleShowType = 1
	end

	OB_Over_Update_Member()
end

--清除数据
function OB_Over_ClearData_Single()
	for i=1, table.getn(g_teamAList) do
		g_teamAList[i].player : Hide()
	end

	for i=1, table.getn(g_teamBList) do
		g_teamBList[i].player : Hide()
	end

	OB_Over_Team_Client : Hide()
	OB_Over_Single_Client : Show()
end

--清除数据
function OB_Over_ClearData_Team()

	OB_Over_Team_Client : Show()
	OB_Over_Single_Client : Hide()
end


--更新
function OB_Over_Update_Member()

	if g_OpenSingle == 1 then
		OB_Over_Update_Single()
	else
		OB_Over_Update_Team()
	end
end

--更新团队数据
function OB_Over_Update_Team()
	OB_Over_ClearData_Team()

	OB_Over_Single_Title_Tab:SetCheck(0)
	OB_Over_Team_Title_Tab:SetCheck(1)
	OB_Over_Change_Title_Tab:Hide()
	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		OB_Over_Update_SJTX_Team()
	elseif  matchType == 2 then
		OB_Over_Update_DFS_Team()
	elseif  matchType == 3 then
		OB_Over_Update_ZBS_Team()
	elseif  matchType == 4 then
		OB_Over_Update_ZBS2023_Team()
	end
end

function OB_Over_Update_SJTX_Team()
	local teamAName, teamBName = SJTX:LuaFnGetSJTXTeamName()
	if "" == teamAName or "" == teamBName then
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

	if teamAServerName ~= "" then
		teamAName = teamAName.."@"..teamAServerName
	end
	if teamBServerName ~= "" then
		teamBName = teamBName.."@"..teamBServerName
	end

	--名字
	OB_Over_Team_Team1_Name:SetText(teamAName)
	OB_Over_Team_Team2_Name:SetText(teamBName)

	--伤害 承伤 治疗
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0
	local total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamA, i - 1 )

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			total_kill = total_kill + math.mod(score, 10)
		end
	end

	OB_Over_Team_Team1_Damage:SetText(total_damage)
	OB_Over_Team_Team1_Tank:SetText(total_chengshang)
	OB_Over_Team_Team1_Heal:SetText(total_cure)
	OB_Over_Team_Team1_Kill:SetText(total_kill)

	--伤害 承伤 治疗
	total_damage = 0
	total_chengshang = 0
	total_cure = 0
	total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamB, i - 1 )

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			total_kill = total_kill + math.mod(score, 10)
		end
	end

	OB_Over_Team_Team2_Damage:SetText(total_damage)
	OB_Over_Team_Team2_Tank:SetText(total_chengshang)
	OB_Over_Team_Team2_Heal:SetText(total_cure)
	OB_Over_Team_Team2_Kill:SetText(total_kill)

end


function OB_Over_Update_DFS_Team()
	local teamAName, teamBName = DFS:LuaFnGetDfsTeamName()
	if "" == teamAName or "" == teamBName then
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

	if teamAServerName ~= "" then
		teamAName = teamAName.."@"..teamAServerName
	end
	if teamBServerName ~= "" then
		teamBName = teamBName.."@"..teamBServerName
	end

	--名字
	OB_Over_Team_Team1_Name:SetText(teamAName)
	OB_Over_Team_Team2_Name:SetText(teamBName)

	--伤害 承伤 治疗
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0
	local total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamA, i - 1 )

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			total_kill = total_kill + math.mod(score, 10)
		end
	end

	OB_Over_Team_Team1_Damage:SetText(total_damage)
	OB_Over_Team_Team1_Tank:SetText(total_chengshang)
	OB_Over_Team_Team1_Heal:SetText(total_cure)
	OB_Over_Team_Team1_Kill:SetText(total_kill)

	--伤害 承伤 治疗
	total_damage = 0
	total_chengshang = 0
	total_cure = 0
	total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamB, i - 1 )

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			total_kill = total_kill + math.mod(score, 10)
		end
	end

	OB_Over_Team_Team2_Damage:SetText(total_damage)
	OB_Over_Team_Team2_Tank:SetText(total_chengshang)
	OB_Over_Team_Team2_Heal:SetText(total_cure)
	OB_Over_Team_Team2_Kill:SetText(total_kill)

end

function OB_Over_Update_ZBS_Team()
	local teamAName, teamBName = CorpsUI_2018:GetTwoCorpsNameInCopyScene()
	if "" == teamAName or "" == teamBName then
		return
	end

	--名字
	OB_Over_Team_Team1_Name:SetText(teamAName)
	OB_Over_Team_Team2_Name:SetText(teamBName)

	--伤害 承伤 治疗
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0
	local total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i - 1)
		if guid ~= nil and guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			total_kill = total_kill + nKillCnt
		end
	end

	OB_Over_Team_Team1_Damage:SetText(total_damage)
	OB_Over_Team_Team1_Tank:SetText(total_chengshang)
	OB_Over_Team_Team1_Heal:SetText(total_cure)
	OB_Over_Team_Team1_Kill:SetText(total_kill)

	--伤害 承伤 治疗
	total_damage = 0
	total_chengshang = 0
	total_cure = 0
	total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(g_MaxTeamMember + i - 1)
		if guid ~= nil and guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			total_kill = total_kill + nKillCnt
		end
	end

	OB_Over_Team_Team2_Damage:SetText(total_damage)
	OB_Over_Team_Team2_Tank:SetText(total_chengshang)
	OB_Over_Team_Team2_Heal:SetText(total_cure)
	OB_Over_Team_Team2_Kill:SetText(total_kill)
end

function OB_Over_Update_ZBS2023_Team()
	local teamAName,teamBName = ZBS:GetBattleVisiableInfo("TeamName")
	local teamAZoneWorldID, teamBZoneWorldID = ZBS:GetBattleTeamZoneID()
	local teamAServerName = DataPool:GetServerName(teamAZoneWorldID)
	local teamBServerName = DataPool:GetServerName(teamBZoneWorldID)
	if teamAServerName == nil then
		teamAServerName = ""
	end
	if teamBServerName == nil then
		teamBServerName = ""
	end

	if teamAServerName ~= "" then
		--teamAName = teamAName.."@"..teamAServerName
	end
	if teamBServerName ~= "" then
		--teamBName = teamBName.."@"..teamBServerName
	end

	--名字
	OB_Over_Team_Team1_Name:SetText(teamAName)
	OB_Over_Team_Team2_Name:SetText(teamBName)

	--伤害 承伤 治疗
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0
	local total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(i - 1)
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local lv,_,_,killnum,_,_ = ZBS:GetBattleMemberInfo(i - 1)

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			if lv > 0 then
				total_kill = total_kill + killnum
			end
		end
	end

	OB_Over_Team_Team1_Damage:SetText(total_damage)
	OB_Over_Team_Team1_Tank:SetText(total_chengshang)
	OB_Over_Team_Team1_Heal:SetText(total_cure)
	OB_Over_Team_Team1_Kill:SetText(total_kill)

	--伤害 承伤 治疗
	total_damage = 0
	total_chengshang = 0
	total_cure = 0
	total_kill = 0

	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(g_MaxTeamMember + i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local lv,_,_,killnum,_,_ = ZBS:GetBattleMemberInfo(g_MaxTeamMember+ i - 1)

			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
			if lv > 0 then
				total_kill = total_kill + killnum
			end
		end
	end

	OB_Over_Team_Team2_Damage:SetText(total_damage)
	OB_Over_Team_Team2_Tank:SetText(total_chengshang)
	OB_Over_Team_Team2_Heal:SetText(total_cure)
	OB_Over_Team_Team2_Kill:SetText(total_kill)

end

--更新个人数据
function OB_Over_Update_Single()
	OB_Over_ClearData_Single()
	
	OB_Over_Single_Title_Tab:SetCheck(1)
	OB_Over_Team_Title_Tab:SetCheck(0)
	OB_Over_Change_Title_Tab:Show()
	
	OB_Over_Update_Name()
	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		OB_Over_Update_SJTX_Single()
	elseif  matchType == 2 then
		OB_Over_Update_DFS_Single()
	elseif  matchType == 3 then
		OB_Over_Update_ZBS_Single()
	elseif  matchType == 4 then
		OB_Over_Update_ZBS2023_Single()
	end
end

function OB_Over_Update_Name()
	local teamAName = ""
	local teamBName = ""
	local teamAZoneWorldID = -1
	local teamBZoneWorldID = -1
	
	local matchType = DataPool:LuaFnGetGMMathcType()
	if matchType == 1 then
		teamAName, teamBName = SJTX:LuaFnGetSJTXTeamName()
		teamAZoneWorldID, teamBZoneWorldID = SJTX:LuaFnGetSJTXTeamZoneWorldID()
		
	elseif matchType == 2 then
		teamAName, teamBName = DFS:LuaFnGetDfsTeamName()
		teamAZoneWorldID, teamBZoneWorldID = DFS:LuaFnGetDfsTeamZoneWorldID()
		
	elseif matchType == 3 then
		teamAName, teamBName = CorpsUI_2018:GetTwoCorpsNameInCopyScene()

	elseif matchType == 4 then
		teamAName,teamBName = ZBS:GetBattleVisiableInfo("TeamName")
	end
	
	if "" == teamAName or "" == teamBName then
		return
	end
	
	local teamAServerName = DataPool:GetServerName(teamAZoneWorldID)
	local teamBServerName = DataPool:GetServerName(teamBZoneWorldID)
	if teamAServerName == nil then
		teamAServerName = ""
	end
	if teamBServerName == nil then
		teamBServerName = ""
	end
 
	if teamAServerName ~= "" then
		teamAName = teamAName.."@"..teamAServerName
	end
	if teamBServerName ~= "" then
		teamBName = teamBName.."@"..teamBServerName
	end
	
	OB_Over_Single_Team1Title_Name : SetText(teamAName)
	OB_Over_Single_Team2Title_Name : SetText(teamBName)
	
end

function OB_Over_Update_SJTX_Single()

	--A对信息
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamA, i - 1 )
			local killNum = math.mod(score, 10)
			
			OB_Over_ShowMember(g_TeamA, i, name, menPai, killNum, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end

	--B对信息
	total_damage = 0
	total_chengshang = 0
	total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid = SJTX:LuaFnGetSJTXScenePlayerGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local menPai, level, name, duanWei1, duanWei2, duanWei3, hp, state, score= SJTX:LuaFnGetSJTXScenePlayerData(g_TeamB, i - 1 )
			local killNum = math.mod(score, 10)
			
			OB_Over_ShowMember(g_TeamB, i, name, menPai, killNum, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end

end

function OB_Over_Update_DFS_Single()

	--A对信息
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamA, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamA, i - 1 )	
			local killNum = math.mod(score, 10)
			
			OB_Over_ShowMember(g_TeamA, i, name, menPai, killNum, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end

	--B对信息
	total_damage = 0
	total_chengshang = 0
	total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid = DFS:LuaFnGetDfsScenePlayerGuid(g_TeamB, i - 1 )
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local menPai, level, name, hp, state, score= DFS:LuaFnGetDfsScenePlayerData(g_TeamB, i - 1 )
			local killNum = math.mod(score, 10)
			
			OB_Over_ShowMember(g_TeamB, i, name, menPai, killNum, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end

end

function OB_Over_Update_ZBS_Single()
	--A对信息
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i - 1)
		if guid ~= nil and guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(i - 1)
		if guid ~= nil and guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			
			OB_Over_ShowMember(g_TeamA, i, name, menPai, nKillCnt, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end

	--B对信息
	total_damage = 0
	total_chengshang = 0
	total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(g_MaxTeamMember + i - 1)
		if guid ~= nil and guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid, hp, level, menPai, pos, name, nKillCnt = CorpsUI_2018:GetCopyScenePlayerInfoByIdx(g_MaxTeamMember + i - 1)
		if guid ~= nil and guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)

			OB_Over_ShowMember(g_TeamB, i, name, menPai, nKillCnt, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end
end

function OB_Over_Update_ZBS2023_Single()

	--A对信息
	local total_damage = 0
	local total_chengshang = 0
	local total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(i - 1)
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(i - 1)
		local lv,_,menPai,killnum,post,name = ZBS:GetBattleMemberInfo(i-1)
		if guid ~= "" and lv > 0 then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamA, guid)
			local score = 0
			--local killNum = math.mod(score, 10)
			
			OB_Over_ShowMember(g_TeamA, i, name, menPai, killnum, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end

	--B对信息
	total_damage = 0
	total_chengshang = 0
	total_cure = 0

	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(g_MaxTeamMember + i - 1)
		if guid ~= "" then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			total_damage =  total_damage + damage
			total_chengshang = total_chengshang + chengshang
			total_cure = total_cure + cure
		end
	end

	for i=1, g_MaxTeamMember do
		local guid = ZBS:GetBattleMemberGuid(g_MaxTeamMember + i - 1)
		local lv,_,menPai,killnum,post,name = ZBS:GetBattleMemberInfo(g_MaxTeamMember+i-1)
		if guid ~= "" and lv > 0 then
			local mp, rage, eng, cure, damage, chengshang = DataPool:LuaFnGetGMVisibleChangeData(g_TeamB, guid)
			local score = 0
			--local killNum = math.mod(score, 10)
			OB_Over_ShowMember(g_TeamB, i, name, menPai, killnum, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
		end
	end

end

function OB_Over_ShowMember(teamId, i, name, menPai, killNum, damage, total_damage, chengshang, total_chengshang, cure, total_cure)
	if i <= 0 or i > g_MaxTeamMember then
		return
	end
	
	if teamId == g_TeamA then
		g_teamAList[i].player : Show()
		g_teamAList[i].name:SetText(m_MenPaiNameList[menPai].Color .. name)
		g_teamAList[i].menpai:SetText(m_MenPaiNameList[menPai].Color .. m_MenPaiNameList[menPai].Name)
		g_teamAList[i].kill:SetText( killNum )
		
		if g_SingleShowType == 1 then
			g_teamAList[i].damage:SetProgress(damage, total_damage)
			if total_damage == 0 then
				g_teamAList[i].damage:SetText( "0%" )
			else
				g_teamAList[i].damage:SetText( math.floor(damage / total_damage * 100).."%" )
			end
			
			g_teamAList[i].chengshang:SetProgress(chengshang, total_chengshang)		
			if total_chengshang == 0 then
				g_teamAList[i].chengshang:SetText( "0%" )
			else
				g_teamAList[i].chengshang:SetText( math.floor(chengshang / total_chengshang * 100).."%" )
			end
			
			g_teamAList[i].cure:SetProgress(cure, total_cure)			
			if total_cure == 0 then
				g_teamAList[i].cure:SetText( "0%" )
			else
				g_teamAList[i].cure:SetText( math.floor(cure / total_cure * 100).."%" )
			end
			
			g_teamAList[i].damage : Show()
			g_teamAList[i].chengshang : Show()
			g_teamAList[i].cure : Show()
			g_teamAList[i].damageText : Hide()
			g_teamAList[i].chengshangText : Hide()
			g_teamAList[i].cureText : Hide()
		else
			g_teamAList[i].damageText:SetText(damage)
			g_teamAList[i].chengshangText:SetText(chengshang)
			g_teamAList[i].cureText:SetText(cure)
			
			g_teamAList[i].damage : Hide()
			g_teamAList[i].chengshang : Hide()
			g_teamAList[i].cure : Hide()
			g_teamAList[i].damageText : Show()
			g_teamAList[i].chengshangText : Show()
			g_teamAList[i].cureText : Show()
		end
		
	elseif teamId == g_TeamB then
		g_teamBList[i].player : Show()
		g_teamBList[i].name:SetText(m_MenPaiNameList[menPai].Color .. name)
		g_teamBList[i].menpai:SetText(m_MenPaiNameList[menPai].Color .. m_MenPaiNameList[menPai].Name)
		g_teamBList[i].kill:SetText( killNum )
		
		if g_SingleShowType == 1 then
			g_teamBList[i].damage:SetProgress(damage, total_damage)
			if total_damage == 0 then
				g_teamBList[i].damage:SetText( "0%" )
			else
				g_teamBList[i].damage:SetText( math.floor(damage / total_damage * 100).."%" )
			end
			
			g_teamBList[i].chengshang:SetProgress(chengshang, total_chengshang)
			if total_chengshang == 0 then
				g_teamBList[i].chengshang:SetText( "0%" )
			else
				g_teamBList[i].chengshang:SetText( math.floor(chengshang / total_chengshang * 100).."%" )
			end
			
			g_teamBList[i].cure:SetProgress(cure, total_cure)
			if total_cure == 0 then
				g_teamBList[i].cure:SetText( "0%" )
			else
				g_teamBList[i].cure:SetText( math.floor(cure / total_cure * 100).."%" )
			end
			
			g_teamBList[i].damage : Show()
			g_teamBList[i].chengshang : Show()
			g_teamBList[i].cure : Show()
			g_teamBList[i].damageText : Hide()
			g_teamBList[i].chengshangText : Hide()
			g_teamBList[i].cureText : Hide()
		else
			g_teamBList[i].damageText:SetText(damage)
			g_teamBList[i].chengshangText:SetText(chengshang)
			g_teamBList[i].cureText:SetText(cure)
			
			g_teamBList[i].damage : Hide()
			g_teamBList[i].chengshang : Hide()
			g_teamBList[i].cure : Hide()
			g_teamBList[i].damageText : Show()
			g_teamBList[i].chengshangText : Show()
			g_teamBList[i].cureText : Show()
		end
	end
end

--打开数据统计界面
function OB_Over_OpenMember_Click()
	OB_Over_Hide()
end

--##############点击事件##############
--####################################
