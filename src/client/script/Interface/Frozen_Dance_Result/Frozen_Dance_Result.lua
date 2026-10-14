-- bxjgecaoresult


-- 保存UI默认位置
local Frozen_Dance_Result_Frame_UnifiedPosition = nil

local g_TeamNameStr = {
	[0] = "--",
	[1] = "#{JMWH_251017_162}",
	[2] = "#{JMWH_251017_163}",
	[3] = "#{JMWH_251017_164}",
	[4] = "#{JMWH_251017_165}",
	[5] = "#{JMWH_251017_166}",
}

local g_CampNameStr = {
	[0] = "#{JMWH_251017_173}",
	[1] = "#{JMWH_251017_171}",
	[2] = "#{JMWH_251017_172}",
	
}

local g_TeamItemList = {
	[1] = 39925101,
	[2] = 39925102,
	[3] = 39925103,
	[4] = 39925104,
	[5] = 39925105,
}

local g_TeamPoint = -1
local g_SelfPoint = -1
local g_Timer = -1
local g_CampWinPoint = 100


local g_TeamImage = {
}

local g_TeamName = {
}

local g_TeamPointKongJian = {
}

local g_TeamCampPointKongJian = {
}

local g_TeamAllPointKongJian = {
}


local g_MyTeamImage = {
}

local g_MyTeamItem = {
}
local g_TeamRank = {
}

local g_WinCount = {
}


function Frozen_Dance_Result_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	

end -- end func Frozen_Dance_Result_Frame_PreLoad()

function Frozen_Dance_Result_OnLoad()
    Frozen_Dance_Result_Frame_UnifiedPosition = Frozen_Dance_Result_Frame:GetProperty("UnifiedPosition")
	
	g_TeamRank[1] = Frozen_Dance_Result_Camp1_Rank
	g_TeamRank[2] = Frozen_Dance_Result_Camp2_Rank
	g_TeamRank[3] = Frozen_Dance_Result_Camp3_Rank
	g_TeamRank[4] = Frozen_Dance_Result_Camp4_Rank
	g_TeamRank[5] = Frozen_Dance_Result_Camp5_Rank
	
	g_TeamName[1] = Frozen_Dance_Result_Camp1_Text1
	g_TeamName[2] = Frozen_Dance_Result_Camp2_Text1
	g_TeamName[3] = Frozen_Dance_Result_Camp3_Text1
	g_TeamName[4] = Frozen_Dance_Result_Camp4_Text1
	g_TeamName[5] = Frozen_Dance_Result_Camp5_Text1
	
	g_TeamPointKongJian[1] = Frozen_Dance_Result_Camp1_Text2
	g_TeamPointKongJian[2] = Frozen_Dance_Result_Camp2_Text2
	g_TeamPointKongJian[3] = Frozen_Dance_Result_Camp3_Text2
	g_TeamPointKongJian[4] = Frozen_Dance_Result_Camp4_Text2
	g_TeamPointKongJian[5] = Frozen_Dance_Result_Camp5_Text2
	
	g_TeamCampPointKongJian[1] = Frozen_Dance_Result_Camp1_Text3
	g_TeamCampPointKongJian[2] = Frozen_Dance_Result_Camp2_Text3
	g_TeamCampPointKongJian[3] = Frozen_Dance_Result_Camp3_Text3
	g_TeamCampPointKongJian[4] = Frozen_Dance_Result_Camp4_Text3
	g_TeamCampPointKongJian[5] = Frozen_Dance_Result_Camp5_Text3
	
	g_TeamAllPointKongJian[1] = Frozen_Dance_Result_Camp1_Text4
	g_TeamAllPointKongJian[2] = Frozen_Dance_Result_Camp2_Text4
	g_TeamAllPointKongJian[3] = Frozen_Dance_Result_Camp3_Text4
	g_TeamAllPointKongJian[4] = Frozen_Dance_Result_Camp4_Text4
	g_TeamAllPointKongJian[5] = Frozen_Dance_Result_Camp5_Text4
	
	g_WinCount[1] = Frozen_Dance_Result_Camp1_Text5
	g_WinCount[2] = Frozen_Dance_Result_Camp2_Text5
	g_WinCount[3] = Frozen_Dance_Result_Camp3_Text5
	g_WinCount[4] = Frozen_Dance_Result_Camp4_Text5
	g_WinCount[5] = Frozen_Dance_Result_Camp5_Text5
	
	-- g_TeamImage[1] = Frozen_Dance_Result_Camp1_Title
	-- g_TeamImage[2] = Frozen_Dance_Result_Camp2_Title
	-- g_TeamImage[3] = Frozen_Dance_Result_Camp3_Title
	-- g_TeamImage[4] = Frozen_Dance_Result_Camp4_Title
	-- g_TeamImage[5] = Frozen_Dance_Result_Camp5_Title
	
	g_MyTeamImage[1] = Frozen_Dance_Result_Camp1_My
	g_MyTeamImage[2] = Frozen_Dance_Result_Camp2_My
	g_MyTeamImage[3] = Frozen_Dance_Result_Camp3_My
	g_MyTeamImage[4] = Frozen_Dance_Result_Camp4_My
	g_MyTeamImage[5] = Frozen_Dance_Result_Camp5_My
	
	g_MyTeamItem[1] = Frozen_Dance_Result_Camp1_Icon
	g_MyTeamItem[2] = Frozen_Dance_Result_Camp2_Icon
	g_MyTeamItem[3] = Frozen_Dance_Result_Camp3_Icon
	g_MyTeamItem[4] = Frozen_Dance_Result_Camp4_Icon
	g_MyTeamItem[5] = Frozen_Dance_Result_Camp5_Icon
	
	g_Timer = 30
	
end -- end func Frozen_Dance_Result_Frame_OnLoad()

function Frozen_Dance_Result_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_Dance_Result_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_Dance_Result_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_Dance_Result_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331180007) then	--服务端传数据
	
		local teampoint1 = Get_XParam_INT(0)	
		local teampoint2  = Get_XParam_INT(1) 
		local teampoint3  = Get_XParam_INT(2) 
		local teampoint4  = Get_XParam_INT(3) 
		local teampoint5 = Get_XParam_INT(4) 
		
		local teamcamppoint1 = Get_XParam_INT(5)	
		local teamcamppoint2  = Get_XParam_INT(6) 
		local teamcamppoint3  = Get_XParam_INT(7) 
		local teamcamppoint4  = Get_XParam_INT(8) 
		local teamcamppoint5 = Get_XParam_INT(9) 
		
		local nTeamIndex  = Get_XParam_INT(10) 
		local nSelfPoint  = Get_XParam_INT(11) 
		local nResult1AndResult2  = Get_XParam_INT(12) 
		local nSelfRank  = Get_XParam_INT(13) 
		
			
		Frozen_Dance_Result_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, teamcamppoint1, teamcamppoint2, teamcamppoint3, teamcamppoint4, teamcamppoint5, nTeamIndex, nSelfPoint, nResult1AndResult2, nSelfRank)
		
	end
end -- end func Frozen_Dance_Result_Frame_OnEvent()

function Frozen_Dance_Result_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, teamcamppoint1, teamcamppoint2, teamcamppoint3, teamcamppoint4, teamcamppoint5, nTeamIndex, nSelfPoint, nResult1AndResult2, nSelfRank)


	
	local nTeamRankList = {}
	
	nTeamRankList[1] = {}
	nTeamRankList[1].teamcamp = math.mod(teampoint1, 10)
	nTeamRankList[1].teamindex = math.floor(math.mod(teampoint1, 100)/10)
	nTeamRankList[1].teampoint = math.floor(teampoint1/100)
	nTeamRankList[1].teamcamppoint = teamcamppoint1
	nTeamRankList[1].teamallpoint = nTeamRankList[1].teamcamppoint + nTeamRankList[1].teampoint
	
	nTeamRankList[2] = {}
	nTeamRankList[2].teamcamp = math.mod(teampoint2, 10)
	nTeamRankList[2].teamindex = math.floor(math.mod(teampoint2, 100)/10)
	nTeamRankList[2].teampoint = math.floor(teampoint2/100)
	nTeamRankList[2].teamcamppoint = teamcamppoint2
	nTeamRankList[2].teamallpoint = nTeamRankList[2].teamcamppoint + nTeamRankList[2].teampoint
	
	nTeamRankList[3] = {}
	nTeamRankList[3].teamcamp = math.mod(teampoint3, 10)
	nTeamRankList[3].teamindex = math.floor(math.mod(teampoint3, 100)/10)
	nTeamRankList[3].teampoint = math.floor(teampoint3/100)
	nTeamRankList[3].teamcamppoint = teamcamppoint3
	nTeamRankList[3].teamallpoint = nTeamRankList[3].teamcamppoint + nTeamRankList[3].teampoint
	
	nTeamRankList[4] = {}
	nTeamRankList[4].teamcamp = math.mod(teampoint4, 10)
	nTeamRankList[4].teamindex = math.floor(math.mod(teampoint4, 100)/10)
	nTeamRankList[4].teampoint = math.floor(teampoint4/100)
	nTeamRankList[4].teamcamppoint = teamcamppoint4
	nTeamRankList[4].teamallpoint = nTeamRankList[4].teamcamppoint + nTeamRankList[4].teampoint
	
	nTeamRankList[5] = {}
	nTeamRankList[5].teamcamp = math.mod(teampoint5, 10)
	nTeamRankList[5].teamindex = math.floor(math.mod(teampoint5, 100)/10)
	nTeamRankList[5].teampoint = math.floor(teampoint5/100)
	nTeamRankList[5].teamcamppoint = teamcamppoint5
	nTeamRankList[5].teamallpoint = nTeamRankList[5].teamcamppoint + nTeamRankList[5].teampoint
	local nTeamWinCount = {0,0,0,0,0}
	
	
	local nSecondWinCamp = math.mod(nResult1AndResult2, 10)
	local nFirstWinCamp = math.floor(nResult1AndResult2/10)
	if nFirstWinCamp == 0 and nSecondWinCamp == 0 then
	
	else
		for i = 1, table.getn(nTeamWinCount) do
			nTeamWinCount[i] = math.floor(nTeamRankList[i].teamcamppoint/g_CampWinPoint)
		end
	end
	
	-- if g_CampNameStr[nFirstWinCamp] ~= nil then
		-- if nFirstWinCamp ~= 0 then
			-- Frozen_Dance_Result_UPBK_Text2:SetText(ScriptGlobal_Format("#{JMWH_251017_128}",g_CampNameStr[nFirstWinCamp]))
		-- else
			-- Frozen_Dance_Result_UPBK_Text2:SetText(g_CampNameStr[nFirstWinCamp])
		-- end
	-- end
	
	-- if g_CampNameStr[nSecondWinCamp] ~= nil then
		-- if nSecondWinCamp ~= 0 then
			-- Frozen_Dance_Result_UPBK_Text4:SetText(ScriptGlobal_Format("#{JMWH_251017_128}",g_CampNameStr[nSecondWinCamp]))
		-- else
			-- Frozen_Dance_Result_UPBK_Text4:SetText(g_CampNameStr[nSecondWinCamp])
		-- end
	-- end
	
	local myRank = -1
	local myTeamName = -1
	local myteamPoint = -1
	for i = 1, table.getn(g_TeamName) do
		g_TeamRank[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",i))
		g_TeamName[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",g_TeamNameStr[nTeamRankList[i].teamcamp]))
		g_TeamPointKongJian[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",nTeamRankList[i].teampoint))
		g_TeamCampPointKongJian[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",nTeamRankList[i].teamcamppoint))
		g_TeamAllPointKongJian[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",nTeamRankList[i].teamallpoint))
		g_WinCount[i]:SetText(ScriptGlobal_Format("#{JMWH_251017_186}",nTeamWinCount[i]))
		if nTeamRankList[i].teamindex == nTeamIndex then
			g_MyTeamImage[i]:Show()
			g_TeamPoint = i
			g_SelfPoint = nSelfPoint
		else
			g_MyTeamImage[i]:Hide()
		end
		local theAction = DataPool:CreateActionItemForShow(g_TeamItemList[i], 1)
		if theAction:GetID() ~= 0 then
			g_MyTeamItem[i]:SetActionItem(theAction:GetID());	
		end
	end
	Frozen_Dance_Result_PersonalScore_Text2:SetText(nSelfPoint)
	Frozen_Dance_Result_PersonalRank_Text2:SetText(nSelfRank)
	this:Show()
	
	
end -- end func Frozen_Dance_Result_Frame_Updata()


-- 界面默认位置
function Frozen_Dance_Result_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_Dance_Result_Frame_UnifiedPosition ~= nil) then
            Frozen_Dance_Result_Frame:SetProperty("UnifiedPosition", Frozen_Dance_Result_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_Dance_Result_Frame_UnifiedPos()

function Frozen_Dance_Result_Frame_Hide()
    this:Hide()
end -- end func Frozen_Dance_Result_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_Dance_Result_Frame_Close_Clicked()
	Frozen_Dance_Result_Frame_Hide()
end  -- end func Frozen_Dance_Result_Frame_Close_Clicked()

function Frozen_Dance_Result_Help_Clicked()
    PushEvent("CCSHOP_HELP", 32)
end -- end func Frozen_Dance_Result_Frame_Help()

function Frozen_Dance_Result_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("Frozen_Dance_Result_Timer()")
		this:Hide()
	end

	--Frozen_Dance_Result_TopList_info:SetText(ScriptGlobal_Format("#{BXDR_20240920_145}",g_TeamPoint, g_SelfPoint, g_Timer))
end
