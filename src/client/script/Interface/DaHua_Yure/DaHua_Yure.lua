
local g_DaHua_Yure_Frame_UnifiedPosition
local g_DaHua_Yure_NPCPosX = 263
local g_DaHua_Yure_NPCPosZ = 253
local g_DaHua_Yure_Name = "菩提老祖"

local g_DaHua_Yure_IsHaveDone3029 = 0
local g_DaHua_Yure_IsHaveDone3030 = 0
local g_DaHua_Yure_IsHaveDone3031 = 0
local g_DaHua_Yure_IsHaveDoneEveryDayTask = 0
local g_DaHua_Yure_Progress = 0
local g_DaHua_Yure_IsShowRedPoint1 = 0
local g_DaHua_Yure_IsShowRedPoint2 = 0
local g_DaHua_Yure_IsShowRedPoint3 = 0
function DaHua_Yure_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function DaHua_Yure_OnLoad()
	g_DaHua_Yure_Frame_UnifiedPosition = DaHua_Yure_FrameNULL:GetProperty("UnifiedPosition")

end

function DaHua_Yure_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 2024060301 then
		local param = Get_XParam_INT(0)
		if param == 1 then
			if this:IsVisible() then
				DaHua_Yure_OnClose()
				return
			end
	
			this:Show()
			g_DaHua_Yure_IsHaveDone3029 = Get_XParam_INT(1)
			g_DaHua_Yure_IsHaveDone3030 = Get_XParam_INT(2)
			g_DaHua_Yure_IsHaveDone3031 = Get_XParam_INT(3)
			g_DaHua_Yure_IsHaveDoneEveryDayTask = Get_XParam_INT(4)
			g_DaHua_Yure_Progress = Get_XParam_INT(5)
			g_DaHua_Yure_IsShowRedPoint1 = Get_XParam_INT(6)
			g_DaHua_Yure_IsShowRedPoint2 = Get_XParam_INT(7)
			g_DaHua_Yure_IsShowRedPoint3 = Get_XParam_INT(8)
			DaHua_Yure_Open()
		elseif param == 2 then
			DaHua_Yure_FindNPC()
		elseif param == 3 then
			if this:IsVisible() then
				g_DaHua_Yure_IsHaveDone3029 = Get_XParam_INT(1)
				g_DaHua_Yure_IsHaveDone3030 = Get_XParam_INT(2)
				g_DaHua_Yure_IsHaveDone3031 = Get_XParam_INT(3)
				g_DaHua_Yure_IsHaveDoneEveryDayTask = Get_XParam_INT(4)
				g_DaHua_Yure_Progress = Get_XParam_INT(5)
				g_DaHua_Yure_IsShowRedPoint1 = Get_XParam_INT(6)
				g_DaHua_Yure_IsShowRedPoint2 = Get_XParam_INT(7)
				g_DaHua_Yure_IsShowRedPoint3 = Get_XParam_INT(8)
				DaHua_Yure_Open()
			end
		end
	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DaHua_Yure_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DaHua_Yure_OnClose()
	elseif event == "ADJEST_UI_POS" then
		DaHua_Yure_On_ResetPos()
	end
	
end

function DaHua_Yure_GetReward(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGetReward")
		Set_XSCRIPT_ScriptID(999112)
		Set_XSCRIPT_Parameter( 0, index ) 
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function DaHua_Yure_Open()
	if g_DaHua_Yure_IsHaveDone3029 == 1 then
		DaHua_Yure_List_Icon1:Show()
		-- DaHua_Yure_List_Icon1_ToDo:Hide()
	else
		DaHua_Yure_List_Icon1:Hide()
		-- DaHua_Yure_List_Icon1_ToDo:Show()
	end

	if g_DaHua_Yure_IsHaveDone3030 == 1 then
		DaHua_Yure_List_Icon2:Show()
		--DaHua_Yure_List_Icon2_ToDo:Hide()
	else
		DaHua_Yure_List_Icon2:Hide()
		--DaHua_Yure_List_Icon2_ToDo:Show()
	end

	if g_DaHua_Yure_IsHaveDone3031 == 1 then
		DaHua_Yure_List_Icon3:Show()
		--DaHua_Yure_List_Icon3_ToDo:Hide()
	else
		DaHua_Yure_List_Icon3:Hide()
		--DaHua_Yure_List_Icon3_ToDo:Show()
	end

	if g_DaHua_Yure_IsHaveDoneEveryDayTask == 1 then
		DaHua_Yure_List_Icon4:Show()
		--DaHua_Yure_List_Icon4_ToDo:Hide()
	else
		DaHua_Yure_List_Icon4:Hide()
		--DaHua_Yure_List_Icon4_ToDo:Show()
	end

	if g_DaHua_Yure_IsShowRedPoint1 == 1 then
		DaHua_Yure_Icon1Tip:Show()
		DaHua_Yure_Icon1Disabled:Hide()
		DaHua_Yure_Icon1:Enable()
	else
		DaHua_Yure_Icon1Tip:Hide()
		if g_DaHua_Yure_IsShowRedPoint1 == 2 then
			DaHua_Yure_Icon1Disabled:Show()
			DaHua_Yure_Icon1:Disable()
		else
			DaHua_Yure_Icon1Disabled:Hide()
		end
	end

	if g_DaHua_Yure_IsShowRedPoint2 == 1 then
		DaHua_Yure_Icon2Tip:Show()
		DaHua_Yure_Icon2Disabled:Hide()
		DaHua_Yure_Icon2:Enable()
	else
		DaHua_Yure_Icon2Tip:Hide()
		if g_DaHua_Yure_IsShowRedPoint2 == 2 then
			DaHua_Yure_Icon2Disabled:Show()
			DaHua_Yure_Icon2:Disable()
		else
			DaHua_Yure_Icon2Disabled:Hide()
		end
	end

	if g_DaHua_Yure_IsShowRedPoint3 == 1 then
		DaHua_Yure_Icon3Tip:Show()
		DaHua_Yure_Icon3Disabled:Hide()
		DaHua_Yure_Icon3:Enable()
	else
		DaHua_Yure_Icon3Tip:Hide()
		if g_DaHua_Yure_IsShowRedPoint3 == 2 then
			DaHua_Yure_Icon3Disabled:Show()
			DaHua_Yure_Icon3:Disable()
		else
			DaHua_Yure_Icon3Disabled:Hide()
		end
	end

	--DaHua_Yure_TextNUM:SetText(ScriptGlobal_Format("#{DHYR_240515_10}",g_DaHua_Yure_Progress))
	DaHua_Yure_Score_ProgressBar:SetProgress(tonumber(g_DaHua_Yure_Progress), 100)

	
end

function DaHua_Yure_FindNPC()
	AutoRuntoTargetExWithName(g_DaHua_Yure_NPCPosX, g_DaHua_Yure_NPCPosZ, 0, g_DaHua_Yure_Name)
	
end

function DaHua_Yure_OnHelpButtonClicked()
	PushEvent("CCSHOP_HELP", 212)
end

function DaHua_Yure_OnGoButtonClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGuideGoto")
		Set_XSCRIPT_ScriptID(999112)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DaHua_Yure_OnHidden()
end

function DaHua_Yure_OnClose()
	this:Hide()
end

function DaHua_Yure_On_ResetPos()
	DaHua_Yure_FrameNULL:SetProperty("UnifiedPosition", g_DaHua_Yure_Frame_UnifiedPosition)
end
