-- fengyunranklist


-- 保存UI默认位置
local FengYun_JianJiTeamInfo2_Frame_UnifiedPosition = nil

local g_TeamNameStr = {
	[0] = "--",
	[1] = "#{FYPVP_260106_278}",
	[2] = "#{FYPVP_260106_279}",
	[3] = "#{FYPVP_260106_280}",
	[4] = "#{FYPVP_260106_281}",
	[5] = "#{FYPVP_260106_282}",
	[6] = "#{FYPVP_260106_283}",
	[7] = "#{FYPVP_260106_284}",
	[8] = "#{FYPVP_260106_285}",
	[9] = "#{FYPVP_260106_286}",
	[10] = "#{FYPVP_260106_287}",
	[11] = "#{FYPVP_260106_288}",
	[12] = "#{FYPVP_260106_289}",
	
}





local g_Rank = {
}

local g_TeamName = {
}

local g_TeamPoint = {
}

local g_MyIcon = {
}

local g_OutIcon = {
}

function FengYun_JianJiTeamInfo2_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BXJWUHUI_BIG")     -- 窗口分辨率发生变化

end -- end func FengYun_JianJiTeamInfo2_Frame_PreLoad()

function FengYun_JianJiTeamInfo2_OnLoad()
    FengYun_JianJiTeamInfo2_Frame_UnifiedPosition = FengYun_JianJiTeamInfo2_Frame:GetProperty("UnifiedPosition")
	
	g_Rank[1] = FengYun_JianJiTeamInfo2_Team_List1_1
	g_Rank[2] = FengYun_JianJiTeamInfo2_Team_List2_1
	g_Rank[3] = FengYun_JianJiTeamInfo2_Team_List3_1
	g_Rank[4] = FengYun_JianJiTeamInfo2_Team_List4_1
	g_Rank[5] = FengYun_JianJiTeamInfo2_Team_List5_1
	g_Rank[6] = FengYun_JianJiTeamInfo2_Team_List6_1
	g_Rank[7] = FengYun_JianJiTeamInfo2_Team_List7_1
	g_Rank[8] = FengYun_JianJiTeamInfo2_Team_List8_1
	g_Rank[9] = FengYun_JianJiTeamInfo2_Team_List9_1
	g_Rank[10] = FengYun_JianJiTeamInfo2_Team_List10_1
	g_Rank[11] = FengYun_JianJiTeamInfo2_Team_List11_1
	g_Rank[12] = FengYun_JianJiTeamInfo2_Team_List12_1

	
	g_TeamName[1] = FengYun_JianJiTeamInfo2_Team_List1_2
	g_TeamName[2] = FengYun_JianJiTeamInfo2_Team_List2_2
	g_TeamName[3] = FengYun_JianJiTeamInfo2_Team_List3_2
	g_TeamName[4] = FengYun_JianJiTeamInfo2_Team_List4_2
	g_TeamName[5] = FengYun_JianJiTeamInfo2_Team_List5_2
	g_TeamName[6] = FengYun_JianJiTeamInfo2_Team_List6_2
	g_TeamName[7] = FengYun_JianJiTeamInfo2_Team_List7_2
	g_TeamName[8] = FengYun_JianJiTeamInfo2_Team_List8_2
	g_TeamName[9] = FengYun_JianJiTeamInfo2_Team_List9_2
	g_TeamName[10] = FengYun_JianJiTeamInfo2_Team_List10_2
	g_TeamName[11] = FengYun_JianJiTeamInfo2_Team_List11_2
	g_TeamName[12] = FengYun_JianJiTeamInfo2_Team_List12_2
	
	g_TeamPoint[1] = FengYun_JianJiTeamInfo2_Team_List1_3
	g_TeamPoint[2] = FengYun_JianJiTeamInfo2_Team_List2_3
	g_TeamPoint[3] = FengYun_JianJiTeamInfo2_Team_List3_3
	g_TeamPoint[4] = FengYun_JianJiTeamInfo2_Team_List4_3
	g_TeamPoint[5] = FengYun_JianJiTeamInfo2_Team_List5_3
	g_TeamPoint[6] = FengYun_JianJiTeamInfo2_Team_List6_3
	g_TeamPoint[7] = FengYun_JianJiTeamInfo2_Team_List7_3
	g_TeamPoint[8] = FengYun_JianJiTeamInfo2_Team_List8_3
	g_TeamPoint[9] = FengYun_JianJiTeamInfo2_Team_List9_3
	g_TeamPoint[10] = FengYun_JianJiTeamInfo2_Team_List10_3
	g_TeamPoint[11] = FengYun_JianJiTeamInfo2_Team_List11_3
	g_TeamPoint[12] = FengYun_JianJiTeamInfo2_Team_List12_3
	
	g_MyIcon[1] = FengYun_JianJiTeamInfo2_Team_List1_4
	g_MyIcon[2] = FengYun_JianJiTeamInfo2_Team_List2_4
	g_MyIcon[3] = FengYun_JianJiTeamInfo2_Team_List3_4
	g_MyIcon[4] = FengYun_JianJiTeamInfo2_Team_List4_4
	g_MyIcon[5] = FengYun_JianJiTeamInfo2_Team_List5_4
	g_MyIcon[6] = FengYun_JianJiTeamInfo2_Team_List6_4
	g_MyIcon[7] = FengYun_JianJiTeamInfo2_Team_List7_4
	g_MyIcon[8] = FengYun_JianJiTeamInfo2_Team_List8_4
	g_MyIcon[9] = FengYun_JianJiTeamInfo2_Team_List9_4
	g_MyIcon[10] = FengYun_JianJiTeamInfo2_Team_List10_4
	g_MyIcon[11] = FengYun_JianJiTeamInfo2_Team_List11_4
	g_MyIcon[12] = FengYun_JianJiTeamInfo2_Team_List12_4
	
	g_OutIcon[1] = FengYun_JianJiTeamInfo2_Team_List1_5
	g_OutIcon[2] = FengYun_JianJiTeamInfo2_Team_List2_5
	g_OutIcon[3] = FengYun_JianJiTeamInfo2_Team_List3_5
	g_OutIcon[4] = FengYun_JianJiTeamInfo2_Team_List4_5
	g_OutIcon[5] = FengYun_JianJiTeamInfo2_Team_List5_5
	g_OutIcon[6] = FengYun_JianJiTeamInfo2_Team_List6_5
	g_OutIcon[7] = FengYun_JianJiTeamInfo2_Team_List7_5
	g_OutIcon[8] = FengYun_JianJiTeamInfo2_Team_List8_5
	g_OutIcon[9] = FengYun_JianJiTeamInfo2_Team_List9_5
	g_OutIcon[10] = FengYun_JianJiTeamInfo2_Team_List10_5
	g_OutIcon[11] = FengYun_JianJiTeamInfo2_Team_List11_5
	g_OutIcon[12] = FengYun_JianJiTeamInfo2_Team_List12_5
	
end -- end func FengYun_JianJiTeamInfo2_Frame_OnLoad()

function FengYun_JianJiTeamInfo2_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        FengYun_JianJiTeamInfo2_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FengYun_JianJiTeamInfo2_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        FengYun_JianJiTeamInfo2_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331200002) then	--服务端传数据
	
		local teampoint1  = Get_XParam_INT(0)	
		local teampoint2  = Get_XParam_INT(1) 
		local teampoint3  = Get_XParam_INT(2) 
		local teampoint4  = Get_XParam_INT(3) 
		local teampoint5  = Get_XParam_INT(4) 
		local teampoint6  = Get_XParam_INT(5)	
		local teampoint7  = Get_XParam_INT(6) 
		local teampoint8  = Get_XParam_INT(7) 
		local teampoint9  = Get_XParam_INT(8) 
		local teampoint10 = Get_XParam_INT(9) 
		local teampoint11 = Get_XParam_INT(10)	
		local teampoint12  = Get_XParam_INT(11) 
		
		local nTeamIndex  = Get_XParam_INT(12) 
		
	
		FengYun_JianJiTeamInfo2_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, teampoint6, teampoint7, teampoint8, teampoint9, teampoint10, teampoint11, teampoint12, nTeamIndex)
		
		this:Show()
	end
end -- end func FengYun_JianJiTeamInfo2_Frame_OnEvent()

function FengYun_JianJiTeamInfo2_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, teampoint6, teampoint7, teampoint8, teampoint9, teampoint10, teampoint11, teampoint12, nTeamIndex)
	
	
	local nTeamRankList = {}
	
	nTeamRankList[1] = {}
	nTeamRankList[1].teamisout = math.mod(teampoint1, 10)
	nTeamRankList[1].teamindex = math.floor(math.mod(teampoint1, 1000)/10)
	nTeamRankList[1].teampoint = math.floor(teampoint1/1000)
	
	nTeamRankList[2] = {}
	nTeamRankList[2].teamisout = math.mod(teampoint2, 10)
	nTeamRankList[2].teamindex = math.floor(math.mod(teampoint2, 1000)/10)
	nTeamRankList[2].teampoint = math.floor(teampoint2/1000)
	
	nTeamRankList[3] = {}
	nTeamRankList[3].teamisout = math.mod(teampoint3, 10)
	nTeamRankList[3].teamindex = math.floor(math.mod(teampoint3, 1000)/10)
	nTeamRankList[3].teampoint = math.floor(teampoint3/1000)
	
	nTeamRankList[4] = {}
	nTeamRankList[4].teamisout = math.mod(teampoint4, 10)
	nTeamRankList[4].teamindex = math.floor(math.mod(teampoint4, 1000)/10)
	nTeamRankList[4].teampoint = math.floor(teampoint4/1000)
	
	nTeamRankList[5] = {}
	nTeamRankList[5].teamisout = math.mod(teampoint5, 10)
	nTeamRankList[5].teamindex = math.floor(math.mod(teampoint5, 1000)/10)
	nTeamRankList[5].teampoint = math.floor(teampoint5/1000)
	
	nTeamRankList[6] = {}
	nTeamRankList[6].teamisout = math.mod(teampoint6, 10)
	nTeamRankList[6].teamindex = math.floor(math.mod(teampoint6, 1000)/10)
	nTeamRankList[6].teampoint = math.floor(teampoint6/1000)
	
	nTeamRankList[7] = {}
	nTeamRankList[7].teamisout = math.mod(teampoint7, 10)
	nTeamRankList[7].teamindex = math.floor(math.mod(teampoint7, 1000)/10)
	nTeamRankList[7].teampoint = math.floor(teampoint7/1000)
	
	nTeamRankList[8] = {}
	nTeamRankList[8].teamisout = math.mod(teampoint8, 10)
	nTeamRankList[8].teamindex = math.floor(math.mod(teampoint8, 1000)/10)
	nTeamRankList[8].teampoint = math.floor(teampoint8/1000)
	
	nTeamRankList[9] = {}
	nTeamRankList[9].teamisout = math.mod(teampoint9, 10)
	nTeamRankList[9].teamindex = math.floor(math.mod(teampoint9, 1000)/10)
	nTeamRankList[9].teampoint = math.floor(teampoint9/1000)
	
	nTeamRankList[10] = {}
	nTeamRankList[10].teamisout = math.mod(teampoint10, 10)
	nTeamRankList[10].teamindex = math.floor(math.mod(teampoint10, 1000)/10)
	nTeamRankList[10].teampoint = math.floor(teampoint10/1000)
	
	nTeamRankList[11] = {}
	nTeamRankList[11].teamisout = math.mod(teampoint11, 10)
	nTeamRankList[11].teamindex = math.floor(math.mod(teampoint11, 1000)/10)
	nTeamRankList[11].teampoint = math.floor(teampoint11/1000)
	
	nTeamRankList[12] = {}
	nTeamRankList[12].teamisout = math.mod(teampoint12, 10)
	nTeamRankList[12].teamindex = math.floor(math.mod(teampoint12, 1000)/10)
	nTeamRankList[12].teampoint = math.floor(teampoint12/1000)
	
	
	
	
	
	
	local myRank = -1
	local myTeamName = -1
	local myteamPoint = -1
	for i = 1, table.getn(g_Rank) do
		g_Rank[i]:SetText(i)
		g_TeamName[i]:SetText(g_TeamNameStr[nTeamRankList[i].teamindex])
		g_TeamPoint[i]:SetText(nTeamRankList[i].teampoint)
		if nTeamRankList[i].teamindex == nTeamIndex+1 then
			myRank = i
			myTeamName = g_TeamNameStr[nTeamRankList[i].teamindex]
			myteamPoint = nTeamRankList[i].teampoint
			g_MyIcon[i]:Show()
		else
			g_MyIcon[i]:Hide()
		end
		
		if nTeamRankList[i].teamisout == 1 then
			g_OutIcon[i]:Show()
		else
			g_OutIcon[i]:Hide()
		end
	end
	
	--FengYun_JianJiTeamInfo2_PersonalInfo_Jifen_NUM:SetText(ScriptGlobal_Format("#{JMWH_251017_124}",nSelfPoint))
	
end -- end func FengYun_JianJiTeamInfo2_Frame_Updata()


-- 界面默认位置
function FengYun_JianJiTeamInfo2_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (FengYun_JianJiTeamInfo2_Frame_UnifiedPosition ~= nil) then
            FengYun_JianJiTeamInfo2_Frame:SetProperty("UnifiedPosition", FengYun_JianJiTeamInfo2_Frame_UnifiedPosition)
        end
    end
end -- end func FengYun_JianJiTeamInfo2_Frame_UnifiedPos()

function FengYun_JianJiTeamInfo2_Frame_Hide()
    this:Hide()
end -- end func FengYun_JianJiTeamInfo2_Frame_Hide()

-- 关闭按钮点击事件
function FengYun_JianJiTeamInfo2_CloseClicked()
	FengYun_JianJiTeamInfo2_Frame_Hide()
end  -- end func FengYun_JianJiTeamInfo2_Frame_Close_Clicked()

function FengYun_JianJiTeamInfo2_Help_Clicked()
    PushEvent("CCSHOP_HELP", 32)
end -- end func ()

function FengYun_JianJiTeamInfo2_Frame_OpenSelf()
   
end -- end func ()


