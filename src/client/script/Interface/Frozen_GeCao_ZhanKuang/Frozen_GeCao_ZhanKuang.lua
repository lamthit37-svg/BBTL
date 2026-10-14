-- bxjgecaoinfo


-- 保存UI默认位置
local Frozen_GeCao_ZhanKuang_Frame_UnifiedPosition = nil

local g_TeamNameStr = {
	[1] = "#{BXDR_20240920_214}",
	[2] = "#{BXDR_20240920_215}",
	[3] = "#{BXDR_20240920_216}",
	[4] = "#{BXDR_20240920_217}",
	[5] = "#{BXDR_20240920_218}",
}

local g_LevelMax = {
	[1] = 10,
	[2] = 25,
	[3] = 100,
	[4] = 200,
}


local g_Rank = {
}

local g_TeamName = {
}

local g_TeamPoint = {
}

function Frozen_GeCao_ZhanKuang_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BXJGECAO_BIG",false)     -- 窗口分辨率发生变化

end -- end func Frozen_GeCao_ZhanKuang_Frame_PreLoad()

function Frozen_GeCao_ZhanKuang_OnLoad()
    Frozen_GeCao_ZhanKuang_Frame_UnifiedPosition = Frozen_GeCao_ZhanKuang_Frame:GetProperty("UnifiedPosition")
	
	g_Rank[1] = Frozen_GeCao_ZhanKuang_TopList_AItem1_Rank
	g_Rank[2] = Frozen_GeCao_ZhanKuang_TopList_AItem2_Rank
	g_Rank[3] = Frozen_GeCao_ZhanKuang_TopList_AItem3_Rank
	g_Rank[4] = Frozen_GeCao_ZhanKuang_TopList_AItem4_Rank
	g_Rank[5] = Frozen_GeCao_ZhanKuang_TopList_AItem5_Rank
	
	g_TeamName[1] = Frozen_GeCao_ZhanKuang_TopList_AItem1_Name
	g_TeamName[2] = Frozen_GeCao_ZhanKuang_TopList_AItem2_Name
	g_TeamName[3] = Frozen_GeCao_ZhanKuang_TopList_AItem3_Name
	g_TeamName[4] = Frozen_GeCao_ZhanKuang_TopList_AItem4_Name
	g_TeamName[5] = Frozen_GeCao_ZhanKuang_TopList_AItem5_Name
	
	g_TeamPoint[1] = Frozen_GeCao_ZhanKuang_TopList_AItem1_AllScore
	g_TeamPoint[2] = Frozen_GeCao_ZhanKuang_TopList_AItem2_AllScore
	g_TeamPoint[3] = Frozen_GeCao_ZhanKuang_TopList_AItem3_AllScore
	g_TeamPoint[4] = Frozen_GeCao_ZhanKuang_TopList_AItem4_AllScore
	g_TeamPoint[5] = Frozen_GeCao_ZhanKuang_TopList_AItem5_AllScore
	
end -- end func Frozen_GeCao_ZhanKuang_Frame_OnLoad()

function Frozen_GeCao_ZhanKuang_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_GeCao_ZhanKuang_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_GeCao_ZhanKuang_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_GeCao_ZhanKuang_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331141004) then	--服务端传数据
	
		local teampoint1 = Get_XParam_INT(0)	
		local teampoint2  = Get_XParam_INT(1) 
		local teampoint3  = Get_XParam_INT(2) 
		local teampoint4  = Get_XParam_INT(3) 
		local teampoint5 = Get_XParam_INT(4) 
		local nTeamIndex  = Get_XParam_INT(5) 
		local nLeaveTime  = Get_XParam_INT(6) 
		local nOldEXP  = Get_XParam_INT(7) 
		local nOldGameLevel =  Get_XParam_INT(8) 
		
		Frozen_GeCao_ZhanKuang_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nLeaveTime, nOldEXP, nOldGameLevel)
		--打开界面
		if(IsWindowShow("Frozen_GeCao_Mini")) then
			
		else
			this:Show()
		end 
		
	 elseif (event == "BXJGECAO_BIG") then
		this:Show()
	end
end -- end func Frozen_GeCao_ZhanKuang_Frame_OnEvent()

function Frozen_GeCao_ZhanKuang_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nLeaveTime, nOldEXP, nOldGameLevel)

	if nLeaveTime <= 30 then
		Frozen_GeCao_ZhanKuang_Countdown:SetText("#{BXDR_20240920_79}")
		Frozen_GeCao_ZhanKuang_Countdown_Time:SetProperty("Timer", 30-nLeaveTime)
	elseif nLeaveTime > 30 and nLeaveTime <= 510 then
		Frozen_GeCao_ZhanKuang_Countdown:SetText("#{BXDR_20240920_80}")
		Frozen_GeCao_ZhanKuang_Countdown_Time:SetProperty("Timer", 510 - nLeaveTime)
	elseif nLeaveTime > 510 then
		Frozen_GeCao_ZhanKuang_Countdown:SetText("#{BXDR_20240920_81}")
		Frozen_GeCao_ZhanKuang_Countdown_Time:SetProperty("Timer", 30 - (nLeaveTime - 510))
	end
	Frozen_GeCao_ZhanKuang_PersonalInfo_Level:SetText(ScriptGlobal_Format("#{BXDR_20240920_82}",nOldGameLevel))
	
	for i = 1, table.getn(g_LevelMax) do
		if nOldEXP < g_LevelMax[i] then
			Frozen_GeCao_ZhanKuang_PersonalInfo_EXP:SetText(ScriptGlobal_Format("#{BXDR_20240920_83}",nOldEXP, g_LevelMax[i]))
			break
		end
		
		Frozen_GeCao_ZhanKuang_PersonalInfo_EXP:SetText("#{BXDR_20240920_195}")
	end
	
	local nTeamRankList = {}
	
	nTeamRankList[1] = {}
	nTeamRankList[1].teamindex = math.mod(teampoint1, 10)
	nTeamRankList[1].teampoint = math.floor(teampoint1/10)
	nTeamRankList[2] = {}
	nTeamRankList[2].teamindex = math.mod(teampoint2, 10)
	nTeamRankList[2].teampoint = math.floor(teampoint2/10)
	nTeamRankList[3] = {}
	nTeamRankList[3].teamindex = math.mod(teampoint3, 10)
	nTeamRankList[3].teampoint = math.floor(teampoint3/10)
	nTeamRankList[4] = {}
	nTeamRankList[4].teamindex = math.mod(teampoint4, 10)
	nTeamRankList[4].teampoint = math.floor(teampoint4/10)
	nTeamRankList[5] = {}
	nTeamRankList[5].teamindex = math.mod(teampoint5, 10)
	nTeamRankList[5].teampoint = math.floor(teampoint5/10)
	
	
	
	local myRank = -1
	local myTeamName = -1
	local myteamPoint = -1
	for i = 1, table.getn(g_Rank) do
		g_Rank[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",i))
		g_TeamName[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",g_TeamNameStr[nTeamRankList[i].teamindex]))
		g_TeamPoint[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",nTeamRankList[i].teampoint))
		if nTeamRankList[i].teamindex == nTeamIndex then
			myRank = i
			myTeamName = g_TeamNameStr[nTeamRankList[i].teamindex]
			myteamPoint = nTeamRankList[i].teampoint
		end
	end
	
	Frozen_GeCao_ZhanKuang_TeamInfo_Rank:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myRank))
	Frozen_GeCao_ZhanKuang_TeamInfo_Name:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myTeamName))
	Frozen_GeCao_ZhanKuang_TeamInfo_Score:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myteamPoint))
	
end -- end func Frozen_GeCao_ZhanKuang_Frame_Updata()


-- 界面默认位置
function Frozen_GeCao_ZhanKuang_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_GeCao_ZhanKuang_Frame_UnifiedPosition ~= nil) then
            Frozen_GeCao_ZhanKuang_Frame:SetProperty("UnifiedPosition", Frozen_GeCao_ZhanKuang_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_GeCao_ZhanKuang_Frame_UnifiedPos()

function Frozen_GeCao_ZhanKuang_Frame_Hide()
    this:Hide()
end -- end func Frozen_GeCao_ZhanKuang_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_GeCao_ZhanKuang_Frame_Close_Clicked()
	Frozen_GeCao_ZhanKuang_Frame_Hide()
	PushEvent("BXJGECAO_SMALL")
end  -- end func Frozen_GeCao_ZhanKuang_Frame_Close_Clicked()

function Frozen_GeCao_ZhanKuang_Help_Clicked()
    PushEvent("CCSHOP_HELP", 228)
end -- end func Frozen_GeCao_ZhanKuang_Frame_Help()

function Frozen_GeCao_ZhanKuang_Frame_Leave()
   Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGoBackToCityConfirem" )
		Set_XSCRIPT_ScriptID(331141)
		Set_XSCRIPT_Parameter(0, 0);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end -- end func Frozen_GeCao_ZhanKuang_Frame_OpenMap()

function Frozen_GeCao_ZhanKuang_Frame_OpenSelf()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenSelfInfo")
		Set_XSCRIPT_ScriptID(331141)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func Frozen_GeCao_ZhanKuang_Frame_OpenAward()
