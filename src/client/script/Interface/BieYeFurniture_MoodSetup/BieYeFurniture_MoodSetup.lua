local g_BieYeFurniture_MoodSetup_UnifiedPosition = 0
local g_CaredNpc = -1

local g_MaxFurnitureType =12
local g_Inner = {}
local g_Outer = {}

local g_InnerButton = {}
local g_OuterButton = {}

function BieYeFurniture_MoodSetup_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
end

function BieYeFurniture_MoodSetup_OnLoad()
	for i = 1, g_MaxFurnitureType do
		g_Inner[i] = 1
		g_Outer[i] = 1
	end
	
	g_OuterButton[1] = BieYeFurniture_MoodSetup_CheckButton1
	g_OuterButton[2] = BieYeFurniture_MoodSetup_CheckButton2
	g_OuterButton[3] = BieYeFurniture_MoodSetup_CheckButton3
	g_OuterButton[4] = BieYeFurniture_MoodSetup_CheckButton4
	g_OuterButton[5] = BieYeFurniture_MoodSetup_CheckButton5
	g_OuterButton[6] = BieYeFurniture_MoodSetup_CheckButton6
	g_OuterButton[7] = BieYeFurniture_MoodSetup_CheckButton7
	g_OuterButton[8] = BieYeFurniture_MoodSetup_CheckButton8
	g_OuterButton[9] = BieYeFurniture_MoodSetup_CheckButton9
	g_OuterButton[10] = BieYeFurniture_MoodSetup_CheckButton10
	g_OuterButton[11] = BieYeFurniture_MoodSetup_CheckButton11
	g_OuterButton[12] = BieYeFurniture_MoodSetup_CheckButton12
	
	g_InnerButton[1] = BieYeFurniture_MoodSetup_CheckButton13
	g_InnerButton[2] = BieYeFurniture_MoodSetup_CheckButton14
	g_InnerButton[3] = BieYeFurniture_MoodSetup_CheckButton15
	g_InnerButton[4] = BieYeFurniture_MoodSetup_CheckButton16
	g_InnerButton[5] = BieYeFurniture_MoodSetup_CheckButton17
	g_InnerButton[6] = BieYeFurniture_MoodSetup_CheckButton18
	g_InnerButton[7] = BieYeFurniture_MoodSetup_CheckButton19
	g_InnerButton[8] = BieYeFurniture_MoodSetup_CheckButton20
	g_InnerButton[9] = BieYeFurniture_MoodSetup_CheckButton21
	g_InnerButton[10] = BieYeFurniture_MoodSetup_CheckButton22
	g_InnerButton[11] = BieYeFurniture_MoodSetup_CheckButton23
	g_InnerButton[12] = BieYeFurniture_MoodSetup_CheckButton24
	
	g_BieYeFurniture_MoodSetup_UnifiedPosition = BieYeFurniture_MoodSetup_Frame:GetProperty("UnifiedPosition")
end

function BieYeFurniture_MoodSetup_OnEvent(event)

	if (event == "ADJEST_UI_POS") then
		BieYeFurniture_MoodSetup_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeFurniture_MoodSetup_ResetPos()
		
	elseif (even == "HIDE_ON_SCENE_TRANSED") then
		BieYeFurniture_MoodSetup_OnClose()
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20170313) then
		local npcServerId = Get_XParam_INT(0)
		g_CaredNpc = DataPool:GetNPCIDByServerID(npcServerId)
			
		if g_CaredNpc == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
			
		this:CareObject(g_CaredNpc, 1, "BieYeFurniture_MoodSetup")
		BieYeFurniture_MoodSetup_onShow(Get_XParam_INT(1), Get_XParam_INT(2))
		this:Show()
	end
end

function BieYeFurniture_MoodSetup_OnClose()
	this:CareObject(g_CaredNpc, 0, "BieYeFurniture_MoodSetup")
	g_CaredNpc = -1
	this:Hide()
end

function BieYeFurniture_MoodSetup_ResetPos()
	BieYeFurniture_MoodSetup_Frame:SetProperty("UnifiedPosition", g_BieYeFurniture_MoodSetup_UnifiedPosition)
end

function BieYeFurniture_MoodSetup_onShow(inner, outer)
	g_Inner[1],g_Inner[2],g_Inner[3],g_Inner[4],g_Inner[5],g_Inner[6],
	g_Inner[7],g_Inner[8],g_Inner[9],g_Inner[10],g_Inner[11],g_Inner[12] = BieYeUI:GetFurtureLimit(inner)
	
	g_Outer[1],g_Outer[2],g_Outer[3],g_Outer[4],g_Outer[5],g_Outer[6],
	g_Outer[7],g_Outer[8],g_Outer[9],g_Outer[10],g_Outer[11],g_Outer[12] = BieYeUI:GetFurtureLimit(outer)
	
	for i = 1, g_MaxFurnitureType do
		g_InnerButton[i]:SetCheck(g_Inner[i])
		g_OuterButton[i]:SetCheck(g_Outer[i])
	end
end

function BieYeFurniture_MoodSetup_OnInnerCheck(index)
	if index > g_MaxFurnitureType or index < 1 then
		return
	end
	
	g_Inner[index] = g_InnerButton[index]:GetCheck()
end

function BieYeFurniture_MoodSetup_OnOuterCheck(index)
	if index > g_MaxFurnitureType or index < 1 then
		return
	end
	
	g_Outer[index] = g_OuterButton[index]:GetCheck()
end

function BieYeFurniture_MoodSetup_OnOk()
	local InnerLimit = BieYeUI:SetFurtureLimit(g_Inner[1],g_Inner[2],g_Inner[3],g_Inner[4],g_Inner[5],g_Inner[6],
																						 g_Inner[7],g_Inner[8],g_Inner[9],g_Inner[10],g_Inner[11],g_Inner[12])
																			
	local OuterLimit =  BieYeUI:SetFurtureLimit(g_Outer[1],g_Outer[2],g_Outer[3],g_Outer[4],g_Outer[5],g_Outer[6],
																							g_Outer[7],g_Outer[8],g_Outer[9],g_Outer[10],g_Outer[11],g_Outer[12])
																							
																							
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ChangeFurnitureLimit");
		Set_XSCRIPT_ScriptID(891872);
		Set_XSCRIPT_Parameter(0,InnerLimit);
		Set_XSCRIPT_Parameter(1,OuterLimit);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();		
	
	BieYeFurniture_MoodSetup_OnClose()												
end