-- bxjgecaoinfo


-- 保存UI默认位置
local Frozen_Dance_ZhanKuang_Frame_UnifiedPosition = nil

local g_TeamNameStr = {
	[0] = "--",
	[1] = "#{JMWH_251017_162}",
	[2] = "#{JMWH_251017_163}",
	[3] = "#{JMWH_251017_164}",
	[4] = "#{JMWH_251017_165}",
	[5] = "#{JMWH_251017_166}",
}

local g_TeamImage = {
	[0] = "set:Frozen_Dance2 image:Frozen_Dance2_Tou",
	[1] = "set:Frozen_Dance2 image:Frozen_Dance2_Tou",
	[2] = "set:Frozen_Dance2 image:Frozen_Dance2_Tou",
	[3] = "set:Frozen_Dance2 image:Frozen_Dance2_Tou",
	[4] = "set:Frozen_Dance2 image:Frozen_Dance2_Zhua",
	[5] = "set:Frozen_Dance2 image:Frozen_Dance2_Zhua",
}


local g_AllCound = 2


local g_Rank = {
}

local g_TeamName = {
}

local g_TeamPoint = {
}

local g_MyIcon = {
}

local g_MyBackIcon = {
}

function Frozen_Dance_ZhanKuang_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BXJWUHUI_BIG")     -- 窗口分辨率发生变化

end -- end func Frozen_Dance_ZhanKuang_Frame_PreLoad()

function Frozen_Dance_ZhanKuang_OnLoad()
    Frozen_Dance_ZhanKuang_Frame_UnifiedPosition = Frozen_Dance_ZhanKuang_Frame:GetProperty("UnifiedPosition")
	
	g_Rank[1] = Frozen_Dance_ZhanKuang_TopList_AItem1_Rank
	g_Rank[2] = Frozen_Dance_ZhanKuang_TopList_AItem2_Rank
	g_Rank[3] = Frozen_Dance_ZhanKuang_TopList_AItem3_Rank
	g_Rank[4] = Frozen_Dance_ZhanKuang_TopList_AItem4_Rank
	g_Rank[5] = Frozen_Dance_ZhanKuang_TopList_AItem5_Rank
	
	g_TeamName[1] = Frozen_Dance_ZhanKuang_TopList_AItem1_Name
	g_TeamName[2] = Frozen_Dance_ZhanKuang_TopList_AItem2_Name
	g_TeamName[3] = Frozen_Dance_ZhanKuang_TopList_AItem3_Name
	g_TeamName[4] = Frozen_Dance_ZhanKuang_TopList_AItem4_Name
	g_TeamName[5] = Frozen_Dance_ZhanKuang_TopList_AItem5_Name
	
	g_TeamPoint[1] = Frozen_Dance_ZhanKuang_TopList_AItem1_AllScore
	g_TeamPoint[2] = Frozen_Dance_ZhanKuang_TopList_AItem2_AllScore
	g_TeamPoint[3] = Frozen_Dance_ZhanKuang_TopList_AItem3_AllScore
	g_TeamPoint[4] = Frozen_Dance_ZhanKuang_TopList_AItem4_AllScore
	g_TeamPoint[5] = Frozen_Dance_ZhanKuang_TopList_AItem5_AllScore
	
	g_MyIcon[1] = Frozen_Dance_ZhanKuang_TopList_AItem1_My
	g_MyIcon[2] = Frozen_Dance_ZhanKuang_TopList_AItem2_My
	g_MyIcon[3] = Frozen_Dance_ZhanKuang_TopList_AItem3_My
	g_MyIcon[4] = Frozen_Dance_ZhanKuang_TopList_AItem4_My
	g_MyIcon[5] = Frozen_Dance_ZhanKuang_TopList_AItem5_My
	
	g_MyBackIcon[1] = Frozen_Dance_ZhanKuang_TopList_AItem1BK
	g_MyBackIcon[2] = Frozen_Dance_ZhanKuang_TopList_AItem2BK
	g_MyBackIcon[3] = Frozen_Dance_ZhanKuang_TopList_AItem3BK
	g_MyBackIcon[4] = Frozen_Dance_ZhanKuang_TopList_AItem4BK
	g_MyBackIcon[5] = Frozen_Dance_ZhanKuang_TopList_AItem5BK
	
end -- end func Frozen_Dance_ZhanKuang_Frame_OnLoad()

function Frozen_Dance_ZhanKuang_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_Dance_ZhanKuang_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_Dance_ZhanKuang_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_Dance_ZhanKuang_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331180004) then	--服务端传数据
	
		local teampoint1 = Get_XParam_INT(0)	
		local teampoint2  = Get_XParam_INT(1) 
		local teampoint3  = Get_XParam_INT(2) 
		local teampoint4  = Get_XParam_INT(3) 
		local teampoint5 = Get_XParam_INT(4) 
		local nTeamIndex  = Get_XParam_INT(5) 
		local nLeaveTime  = Get_XParam_INT(6) 
		local nRound  = Get_XParam_INT(7) 
		local nSelfPoint  = Get_XParam_INT(8) 
		local nLeaveGhostNum  = Get_XParam_INT(9) 
		local nLeaveCatchGhostNum  = Get_XParam_INT(10) 
		local nGhostPoint  = Get_XParam_INT(11) 
		local nCatchGhostPoint  = Get_XParam_INT(12) 
		local nNowGameState  = Get_XParam_INT(13) 
	
		Frozen_Dance_ZhanKuang_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nLeaveTime, nRound, nSelfPoint, nLeaveGhostNum, nLeaveCatchGhostNum, nGhostPoint, nCatchGhostPoint,nNowGameState)
		--打开界面
		if(IsWindowShow("Frozen_Dance_Mini")) then
			
		else
			this:Show()
		end 
		
	 elseif (event == "BXJWUHUI_BIG") then
		this:Show()
	end
end -- end func Frozen_Dance_ZhanKuang_Frame_OnEvent()

function Frozen_Dance_ZhanKuang_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nLeaveTime, nRound, nSelfPoint, nLeaveGhostNum, nLeaveCatchGhostNum, nGhostPoint, nCatchGhostPoint,nNowGameState)
	
	if nNowGameState == 0 then
		Frozen_Dance_ZhanKuang_Countdown:SetText("#{JMWH_251017_189}")
	elseif nNowGameState == 1 then
		Frozen_Dance_ZhanKuang_Countdown:SetText("#{JMWH_251017_190}")
	else
		Frozen_Dance_ZhanKuang_Countdown:SetText("#{JMWH_251017_109}")
	end
	
	Frozen_Dance_ZhanKuang_Countdown_Time:SetProperty("Timer", nLeaveTime)
	Frozen_Dance_ZhanKuang_Countdown_Lunci_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_112}",nRound+1, g_AllCound))
	Frozen_Dance_ZhanKuang_PersonalInfo_Bifen_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_114}",nGhostPoint, nCatchGhostPoint))
	Frozen_Dance_ZhanKuang_PersonalInfo_Cunhuo_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_204}",nLeaveGhostNum))
	
	local nTeamRankList = {}
	
	nTeamRankList[1] = {}
	nTeamRankList[1].teamcamp = math.mod(teampoint1, 10)
	nTeamRankList[1].teamindex = math.floor(math.mod(teampoint1, 100)/10)
	nTeamRankList[1].teampoint = math.floor(teampoint1/100)
	nTeamRankList[2] = {}
	nTeamRankList[2].teamcamp = math.mod(teampoint2, 10)
	nTeamRankList[2].teamindex = math.floor(math.mod(teampoint2, 100)/10)
	nTeamRankList[2].teampoint = math.floor(teampoint2/100)
	nTeamRankList[3] = {}
	nTeamRankList[3].teamcamp = math.mod(teampoint3, 10)
	nTeamRankList[3].teamindex = math.floor(math.mod(teampoint3, 100)/10)
	nTeamRankList[3].teampoint = math.floor(teampoint3/100)
	nTeamRankList[4] = {}
	nTeamRankList[4].teamcamp = math.mod(teampoint4, 10)
	nTeamRankList[4].teamindex = math.floor(math.mod(teampoint4, 100)/10)
	nTeamRankList[4].teampoint = math.floor(teampoint4/100)
	nTeamRankList[5] = {}
	nTeamRankList[5].teamcamp = math.mod(teampoint5, 10)
	nTeamRankList[5].teamindex = math.floor(math.mod(teampoint5, 100)/10)
	nTeamRankList[5].teampoint = math.floor(teampoint5/100)
	
	
	
	local myRank = -1
	local myTeamName = -1
	local myteamPoint = -1
	for i = 1, table.getn(g_Rank) do
		g_Rank[i]:SetText(i)
		g_TeamName[i]:SetText(g_TeamNameStr[nTeamRankList[i].teamcamp])
		g_MyBackIcon[i]:SetProperty("Image", g_TeamImage[nTeamRankList[i].teamcamp])
		g_TeamPoint[i]:SetText(nTeamRankList[i].teampoint)
		if nTeamRankList[i].teamindex == nTeamIndex then
			myRank = i
			myTeamName = g_TeamNameStr[nTeamRankList[i].teamindex]
			myteamPoint = nTeamRankList[i].teampoint
			g_MyIcon[i]:Show()
		else
			g_MyIcon[i]:Hide()
		end
	end
	
	Frozen_Dance_ZhanKuang_PersonalInfo_Jifen_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_124}",nSelfPoint))
	
end -- end func Frozen_Dance_ZhanKuang_Frame_Updata()


-- 界面默认位置
function Frozen_Dance_ZhanKuang_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_Dance_ZhanKuang_Frame_UnifiedPosition ~= nil) then
            Frozen_Dance_ZhanKuang_Frame:SetProperty("UnifiedPosition", Frozen_Dance_ZhanKuang_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_Dance_ZhanKuang_Frame_UnifiedPos()

function Frozen_Dance_ZhanKuang_Frame_Hide()
    this:Hide()
end -- end func Frozen_Dance_ZhanKuang_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_Dance_ZhanKuang_Frame_Close_Clicked()
	Frozen_Dance_ZhanKuang_Frame_Hide()
	PushEvent("BXJWUHUI_SMALL")
end  -- end func Frozen_Dance_ZhanKuang_Frame_Close_Clicked()

function Frozen_Dance_ZhanKuang_Help_Clicked()
    PushEvent("CCSHOP_HELP", 32)
end -- end func ()

function Frozen_Dance_ZhanKuang_Frame_Leave()
   Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGoBackToCityConfirem" )
		Set_XSCRIPT_ScriptID(331180)
		Set_XSCRIPT_Parameter(0, 0);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end -- end func ()

function Frozen_Dance_ZhanKuang_Frame_OpenSelf()
   
end -- end func ()

function Frozen_Dance_ZhanKuang_Frame_ActBook()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenActBook")
		Set_XSCRIPT_ScriptID(331180)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func ()
