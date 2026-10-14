
local g_Qixi_Yure_Frame_UnifiedPosition

local g_Qixi_Yure_AutoRun =
{
	[0] = {posX = 226 ,posZ = 306, npcName = "白颖中"},
	[1] = {posX = 234, posZ = 297, npcName = "蔷薇"},
	[2] = {posX = 225, posZ = 302, npcName = "卢氏女"},
	[3] = {posX = 225, posZ = 302, npcName = "卢氏女"},
	[4] = {posX = 225, posZ = 302, npcName = "卢氏女"},
}
local g_Qixi_Yure_RewardInfo =
{
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
}

local g_Qixi_Yure_UITableList = {}

function Qixi_Yure_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function Qixi_Yure_OnLoad()
	g_Qixi_Yure_Frame_UnifiedPosition = Qixi_Yure_Frame:GetProperty("UnifiedPosition")
	
	g_Qixi_Yure_UITableList = 
	{
		BG = 
		{
			[1] = Qixi_Yure_Gift1BK,
			[2] = Qixi_Yure_Gift2BK,
			[3] = Qixi_Yure_Gift3BK,
			[4] = Qixi_Yure_Gift4BK,
			[5] = Qixi_Yure_Gift5BK,
		},
		RedPoint = 
		{
			[1]=Qixi_Yure_Gift1_IconTips,
			[2]=Qixi_Yure_Gift2_IconTips,
			[3]=Qixi_Yure_Gift3_IconTips,
			[4]=Qixi_Yure_Gift4_IconTips,
			[5]=Qixi_Yure_Gift5_IconTips,
		},
		RewardBtn = 
		{
			[1]=Qixi_Yure_Gift1_Icon,
			[2]=Qixi_Yure_Gift2_Icon,
			[3]=Qixi_Yure_Gift3_Icon,
			[4]=Qixi_Yure_Gift4_Icon,
			[5]=Qixi_Yure_Gift5_Icon,
		},
		GotoBtn = 
		{
			[1]=Qixi_Yure_GoBtn1,
			[2]=Qixi_Yure_GoBtn2,
			[3]=Qixi_Yure_GoBtn3,
			[4]=Qixi_Yure_GoBtn4,
			[5]=Qixi_Yure_GoBtn5,
		},
		DoneImg = 
		{
			[1]=Qixi_Yure_GoBtn1_Image,
			[2]=Qixi_Yure_GoBtn2_Image,
			[3]=Qixi_Yure_GoBtn3_Image,
			[4]=Qixi_Yure_GoBtn4_Image,
			[5]=Qixi_Yure_GoBtn5_Image,
		},
	}
end

function Qixi_Yure_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 2026062201 then
		local isOpen = Get_XParam_INT(0)
		if isOpen == 1 then
			this:Show()
		end
		for i=1, 5 do
			g_Qixi_Yure_RewardInfo[i] = Get_XParam_INT(i)
		end
		Qixi_Yure_Refresh()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2026062202) then
		local missionIndex = Get_XParam_INT(0)
		AutoRuntoTargetExWithName(g_Qixi_Yure_AutoRun[missionIndex].posX, g_Qixi_Yure_AutoRun[missionIndex].posZ, 0, g_Qixi_Yure_AutoRun[missionIndex].npcName)
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Qixi_Yure_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Qixi_Yure_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Qixi_Yure_Close()
	end
end

function Qixi_Yure_Refresh()

	g_Qixi_Yure_UITableList.GotoBtn[1]:Show()
	g_Qixi_Yure_UITableList.DoneImg[1]:Hide()

	g_Qixi_Yure_UITableList.GotoBtn[2]:Hide()
	g_Qixi_Yure_UITableList.DoneImg[2]:Hide()

	g_Qixi_Yure_UITableList.GotoBtn[3]:Hide()
	g_Qixi_Yure_UITableList.DoneImg[3]:Hide()

	g_Qixi_Yure_UITableList.GotoBtn[4]:Hide()
	g_Qixi_Yure_UITableList.DoneImg[4]:Hide()

	g_Qixi_Yure_UITableList.GotoBtn[5]:Hide()
	g_Qixi_Yure_UITableList.DoneImg[5]:Hide()

	if g_Qixi_Yure_RewardInfo[1] == 2 then
		g_Qixi_Yure_UITableList.GotoBtn[1]:Hide()
		g_Qixi_Yure_UITableList.DoneImg[1]:Show()
	end

	if g_Qixi_Yure_RewardInfo[2] == 0 and g_Qixi_Yure_RewardInfo[1] ~= 0 then
		g_Qixi_Yure_UITableList.GotoBtn[2]:Show()
		g_Qixi_Yure_UITableList.DoneImg[2]:Hide()
	elseif g_Qixi_Yure_RewardInfo[2] == 2 then
		g_Qixi_Yure_UITableList.GotoBtn[2]:Hide()
		g_Qixi_Yure_UITableList.DoneImg[2]:Show()
	end

	if g_Qixi_Yure_RewardInfo[3] == 0 and g_Qixi_Yure_RewardInfo[2] ~= 0 then
		g_Qixi_Yure_UITableList.GotoBtn[3]:Show()
		g_Qixi_Yure_UITableList.DoneImg[3]:Hide()
	elseif g_Qixi_Yure_RewardInfo[3] == 2 then
		g_Qixi_Yure_UITableList.GotoBtn[3]:Hide()
		g_Qixi_Yure_UITableList.DoneImg[3]:Show()
	end

	if g_Qixi_Yure_RewardInfo[4] == 0 and g_Qixi_Yure_RewardInfo[3] ~= 0 then
		g_Qixi_Yure_UITableList.GotoBtn[4]:Show()
		g_Qixi_Yure_UITableList.DoneImg[4]:Hide()
	elseif g_Qixi_Yure_RewardInfo[4] == 2 then
		g_Qixi_Yure_UITableList.GotoBtn[4]:Hide()
		g_Qixi_Yure_UITableList.DoneImg[4]:Show()
	end

	if g_Qixi_Yure_RewardInfo[5] == 0 and g_Qixi_Yure_RewardInfo[4] ~= 0 then
		g_Qixi_Yure_UITableList.GotoBtn[5]:Show()
		g_Qixi_Yure_UITableList.DoneImg[5]:Hide()
	elseif g_Qixi_Yure_RewardInfo[5] == 2 then
		g_Qixi_Yure_UITableList.GotoBtn[5]:Hide()
		g_Qixi_Yure_UITableList.DoneImg[5]:Show()
	end

	for i=1, 5 do
		if g_Qixi_Yure_RewardInfo[i] == 0 then
			g_Qixi_Yure_UITableList.BG[i]:Show()
			g_Qixi_Yure_UITableList.RedPoint[i]:Hide()
			--g_Qixi_Yure_UITableList.RewardBtn[i]:Enable()
			
		elseif g_Qixi_Yure_RewardInfo[i] == 1 then
			g_Qixi_Yure_UITableList.BG[i]:Hide()
		--	g_Qixi_Yure_UITableList.RedPoint[i]:Hide()
		--	g_Qixi_Yure_UITableList.RewardBtn[i]:Disable()
		
		elseif g_Qixi_Yure_RewardInfo[i] == 2 then
			g_Qixi_Yure_UITableList.BG[i]:Show()
			g_Qixi_Yure_UITableList.RedPoint[i]:Show()
		--	g_Qixi_Yure_UITableList.RewardBtn[i]:Enable()
		
		end
	end
	
	if Player : GetData("IsOriginalJD") == 1 then
		g_Qixi_Yure_UITableList.RewardBtn[1]:SetToolTip("#{QXYR_260601_186}")	
		g_Qixi_Yure_UITableList.RewardBtn[2]:SetToolTip("#{QXYR_260601_187}")
		g_Qixi_Yure_UITableList.RewardBtn[3]:SetToolTip("#{QXYR_260601_188}")
		g_Qixi_Yure_UITableList.RewardBtn[4]:SetToolTip("#{QXYR_260601_189}")
		g_Qixi_Yure_UITableList.RewardBtn[5]:SetToolTip("#{QXYR_260601_190}")
	else
		g_Qixi_Yure_UITableList.RewardBtn[1]:SetToolTip("#{QXYR_260601_15}")	
		g_Qixi_Yure_UITableList.RewardBtn[2]:SetToolTip("#{QXYR_260601_16}")
		g_Qixi_Yure_UITableList.RewardBtn[3]:SetToolTip("#{QXYR_260601_17}")
		g_Qixi_Yure_UITableList.RewardBtn[4]:SetToolTip("#{QXYR_260601_18}")
		g_Qixi_Yure_UITableList.RewardBtn[5]:SetToolTip("#{QXYR_260601_19}")
	end

	
	
end

function Qixi_Yure_GetReward(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetReward")
		Set_XSCRIPT_ScriptID(900052)
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Qixi_Yure_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GoToFindNpc")
		Set_XSCRIPT_ScriptID(900052)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	this:Hide()
end

function Qixi_Yure_Help()
	PushEvent("CCSHOP_HELP", 248)
end


function Qixi_Yure_On_ResetPos()
	Qixi_Yure_Frame:SetProperty("UnifiedPosition", g_Qixi_Yure_Frame_UnifiedPosition)
end

function Qixi_Yure_Close()
	this:Hide()
end


