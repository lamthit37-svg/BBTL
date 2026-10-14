-- bxjgecaoinfomini


-- 保存UI默认位置
local Frozen_Dance_Mini_Frame_UnifiedPosition = nil

local g_TeamNameStr = {
	[0] = "--",
	[1] = "#{JMWH_251017_162}",
	[2] = "#{JMWH_251017_163}",
	[3] = "#{JMWH_251017_164}",
	[4] = "#{JMWH_251017_165}",
	[5] = "#{JMWH_251017_166}",
}

local g_LevelMax = {
	[1] = 10,
	[2] = 25,
	[3] = 100,
	[4] = 200,
}

local g_AllCound = 2


function Frozen_Dance_Mini_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BXJWUHUI_SMALL")     -- 窗口分辨率发生变化

end -- end func Frozen_Dance_Mini_Frame_PreLoad()

function Frozen_Dance_Mini_OnLoad()
    Frozen_Dance_Mini_Frame_UnifiedPosition = Frozen_Dance_Mini_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func Frozen_Dance_Mini_Frame_OnLoad()

function Frozen_Dance_Mini_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_Dance_Mini_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_Dance_Mini_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_Dance_Mini_Frame_UnifiedPos()
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
		
		Frozen_Dance_Mini_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nLeaveTime, nRound, nSelfPoint, nLeaveGhostNum, nLeaveCatchGhostNum, nGhostPoint, nCatchGhostPoint,nNowGameState)
		
	 elseif (event == "BXJWUHUI_SMALL") then
		this:Show()
	end
end -- end func Frozen_Dance_Mini_Frame_OnEvent()

function Frozen_Dance_Mini_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nLeaveTime, nRound, nSelfPoint, nLeaveGhostNum, nLeaveCatchGhostNum, nGhostPoint, nCatchGhostPoint,nNowGameState)

	if nNowGameState == 0 then
		Frozen_Dance_Mini_Countdown:SetText("#{JMWH_251017_189}")
	elseif nNowGameState == 1 then
		Frozen_Dance_Mini_Countdown:SetText("#{JMWH_251017_190}")
	else
		Frozen_Dance_Mini_Countdown:SetText("#{JMWH_251017_109}")
	end
	
	Frozen_Dance_Mini_Countdown_Time:SetProperty("Timer", nLeaveTime)
	Frozen_Dance_Mini_Countdown_Lunci_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_112}",nRound+1, g_AllCound))
	
	Frozen_Dance_Mini_Bifen_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_114}",nGhostPoint, nCatchGhostPoint))
	Frozen_Dance_Mini_Cunhuo_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_204}",nLeaveGhostNum))
	
	
	
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
	for i = 1, table.getn(nTeamRankList) do
		if nTeamRankList[i].teamindex == nTeamIndex then
			myRank = i
			myteamPoint = nTeamRankList[i].teampoint
		end
	end
	
	Frozen_Dance_Mini_TeamRank2:SetText(ScriptGlobal_Format("#{BXDR_20240920_134}",myRank))
	--Frozen_Dance_Mini_TeamInfo_Name:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myTeamName))
	Frozen_Dance_Mini_TeamNum2:SetText(ScriptGlobal_Format("#{BXDR_20240920_133}",myteamPoint))
	
end -- end func Frozen_Dance_Mini_Frame_Updata()


-- 界面默认位置
function Frozen_Dance_Mini_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_Dance_Mini_Frame_UnifiedPosition ~= nil) then
            Frozen_Dance_Mini_Frame:SetProperty("UnifiedPosition", Frozen_Dance_Mini_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_Dance_Mini_Frame_UnifiedPos()

function Frozen_Dance_Mini_Frame_Hide()
    this:Hide()
end -- end func Frozen_Dance_Mini_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_Dance_Mini_Frame_Close_Clicked()
	Frozen_Dance_Mini_Frame_Hide()
	PushEvent("BXJWUHUI_BIG")
end  -- end func Frozen_Dance_Mini_Frame_Close_Clicked()

function Frozen_Dance_Mini_Help_Clicked()
    PushEvent("CCSHOP_HELP", 32)
end -- end func Frozen_Dance_Mini_Frame_Help()

function Frozen_Dance_Mini_Frame_Leave()
  	
end -- end func Frozen_Dance_Mini_Frame_OpenMap()

function Frozen_Dance_Mini_Frame_OpenSelf()
    
end -- end func Frozen_Dance_Mini_Frame_OpenAward()
