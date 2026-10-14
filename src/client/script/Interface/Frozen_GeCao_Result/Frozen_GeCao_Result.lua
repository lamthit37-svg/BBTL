-- bxjgecaoresult


-- 保存UI默认位置
local Frozen_GeCao_Result_Frame_UnifiedPosition = nil

local g_TeamNameStr = {
	[1] = "#{BXDR_20240920_214}",
	[2] = "#{BXDR_20240920_215}",
	[3] = "#{BXDR_20240920_216}",
	[4] = "#{BXDR_20240920_217}",
	[5] = "#{BXDR_20240920_218}",
}
local g_TeamNameImage = {
	[1] = "set:DaHua_PVP image:DaHua_PVP_Niu",
	[2] = "set:DaHua_PVP image:DaHua_PVP_Niu",
	[3] = "set:DaHua_PVP image:DaHua_PVP_Niu",
	[4] = "set:DaHua_PVP image:DaHua_PVP_Niu",
	[5] = "set:DaHua_PVP image:DaHua_PVP_Niu",
}

local g_TeamItemList = {
	[1] = 39924846,
	[2] = 39924847,
	[3] = 39924848,
	[4] = 39924849,
	[5] = 39924850,
}

local g_TeamPoint = -1
local g_SelfPoint = -1
local g_Timer = -1

local g_TeamImage
local g_TeamImage = {
}

local g_TeamName = {
}

local g_TeamPointKongJian = {
}

local g_MyTeamImage = {
}

local g_MyTeamItem = {
}

function Frozen_GeCao_Result_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	

end -- end func Frozen_GeCao_Result_Frame_PreLoad()

function Frozen_GeCao_Result_OnLoad()
    Frozen_GeCao_Result_Frame_UnifiedPosition = Frozen_GeCao_Result_Frame:GetProperty("UnifiedPosition")
	
	
	g_TeamName[1] = Frozen_GeCao_Result_Camp1_Text1
	g_TeamName[2] = Frozen_GeCao_Result_Camp2_Text1
	g_TeamName[3] = Frozen_GeCao_Result_Camp3_Text1
	g_TeamName[4] = Frozen_GeCao_Result_Camp4_Text1
	g_TeamName[5] = Frozen_GeCao_Result_Camp5_Text1
	
	g_TeamPointKongJian[1] = Frozen_GeCao_Result_Camp1_Text2
	g_TeamPointKongJian[2] = Frozen_GeCao_Result_Camp2_Text2
	g_TeamPointKongJian[3] = Frozen_GeCao_Result_Camp3_Text2
	g_TeamPointKongJian[4] = Frozen_GeCao_Result_Camp4_Text2
	g_TeamPointKongJian[5] = Frozen_GeCao_Result_Camp5_Text2
	
	-- g_TeamImage[1] = Frozen_GeCao_Result_Camp1_Title
	-- g_TeamImage[2] = Frozen_GeCao_Result_Camp2_Title
	-- g_TeamImage[3] = Frozen_GeCao_Result_Camp3_Title
	-- g_TeamImage[4] = Frozen_GeCao_Result_Camp4_Title
	-- g_TeamImage[5] = Frozen_GeCao_Result_Camp5_Title
	
	g_MyTeamImage[1] = Frozen_GeCao_Result_Camp1_My
	g_MyTeamImage[2] = Frozen_GeCao_Result_Camp2_My
	g_MyTeamImage[3] = Frozen_GeCao_Result_Camp3_My
	g_MyTeamImage[4] = Frozen_GeCao_Result_Camp4_My
	g_MyTeamImage[5] = Frozen_GeCao_Result_Camp5_My
	
	g_MyTeamItem[1] = Frozen_GeCao_Result_Camp1_Icon
	g_MyTeamItem[2] = Frozen_GeCao_Result_Camp2_Icon
	g_MyTeamItem[3] = Frozen_GeCao_Result_Camp3_Icon
	g_MyTeamItem[4] = Frozen_GeCao_Result_Camp4_Icon
	g_MyTeamItem[5] = Frozen_GeCao_Result_Camp5_Icon
	
	g_Timer = 30
	
end -- end func Frozen_GeCao_Result_Frame_OnLoad()

function Frozen_GeCao_Result_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_GeCao_Result_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_GeCao_Result_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_GeCao_Result_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331141007) then	--服务端传数据
	
		local teampoint1 = Get_XParam_INT(0)	
		local teampoint2  = Get_XParam_INT(1) 
		local teampoint3  = Get_XParam_INT(2) 
		local teampoint4  = Get_XParam_INT(3) 
		local teampoint5 = Get_XParam_INT(4) 
		local nTeamIndex  = Get_XParam_INT(5) 
		local nSelfPoint  = Get_XParam_INT(6) 
		
			
		Frozen_GeCao_Result_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nSelfPoint)
		
	end
end -- end func Frozen_GeCao_Result_Frame_OnEvent()

function Frozen_GeCao_Result_Frame_Updata(teampoint1, teampoint2, teampoint3, teampoint4, teampoint5, nTeamIndex, nSelfPoint)


	
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
	for i = 1, table.getn(g_TeamName) do
		g_TeamName[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",g_TeamNameStr[nTeamRankList[i].teamindex]))
		g_TeamPointKongJian[i]:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",nTeamRankList[i].teampoint))
		--g_TeamImage[i]:SetProperty("Image", g_TeamNameImage[nTeamRankList[i].teamindex])
		if nTeamRankList[i].teamindex == nTeamIndex then
			g_MyTeamImage[i]:Show()
			g_TeamPoint = i
			g_SelfPoint = nSelfPoint
			if g_Timer > 0 then
				KillTimer("Frozen_GeCao_Result_Timer()")
			end
			g_Timer = 30
			Frozen_GeCao_Result_TopList_info:SetText(ScriptGlobal_Format("#{BXDR_20240920_145}",g_TeamPoint, g_SelfPoint, g_Timer))
			SetTimer("Frozen_GeCao_Result","Frozen_GeCao_Result_Timer()", 1*1000)
		else
			g_MyTeamImage[i]:Hide()
		end
		local theAction = DataPool:CreateActionItemForShow(g_TeamItemList[i], 1)
		if theAction:GetID() ~= 0 then
			g_MyTeamItem[i]:SetActionItem(theAction:GetID());	
		end
	end
	this:Show()
	
	
end -- end func Frozen_GeCao_Result_Frame_Updata()


-- 界面默认位置
function Frozen_GeCao_Result_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_GeCao_Result_Frame_UnifiedPosition ~= nil) then
            Frozen_GeCao_Result_Frame:SetProperty("UnifiedPosition", Frozen_GeCao_Result_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_GeCao_Result_Frame_UnifiedPos()

function Frozen_GeCao_Result_Frame_Hide()
    this:Hide()
end -- end func Frozen_GeCao_Result_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_GeCao_Result_Frame_Close_Clicked()
	Frozen_GeCao_Result_Frame_Hide()
end  -- end func Frozen_GeCao_Result_Frame_Close_Clicked()

function Frozen_GeCao_Result_Help_Clicked()
    PushEvent("CCSHOP_HELP", 223)
end -- end func Frozen_GeCao_Result_Frame_Help()

function Frozen_GeCao_Result_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("Frozen_GeCao_Result_Timer()")
		this:Hide()
	end

	Frozen_GeCao_Result_TopList_info:SetText(ScriptGlobal_Format("#{BXDR_20240920_145}",g_TeamPoint, g_SelfPoint, g_Timer))
end
