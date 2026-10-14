
local g_DaHua_Yure_Letter_Frame_UnifiedPosition
local g_DaHua_Yure_Letter_NPCPosX = 263
local g_DaHua_Yure_Letter_NPCPosZ = 253
local g_DaHua_Yure_Letter_Name = "菩提老祖"

function DaHua_Yure_Letter_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function DaHua_Yure_Letter_OnLoad()
	g_DaHua_Yure_Letter_Frame_UnifiedPosition = DaHua_Yure_Letter_Frame:GetProperty("UnifiedPosition")

end

function DaHua_Yure_Letter_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 2024060302 then
		this:Show()
		DaHua_Yure_Letter_Open()
	-- elseif event == "UI_COMMAND" and tonumber(arg0) == 2024060301 then
	-- 	local param = Get_XParam_INT(0)
	-- 	if param == 2 then
	-- 		DaHua_Yure_Letter_FindNPC()
	-- 	end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DaHua_Yure_Letter_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DaHua_Yure_Letter_OnClose()
	elseif event == "ADJEST_UI_POS" then
		DaHua_Yure_Letter_On_ResetPos()
	end
end

function DaHua_Yure_Letter_Open()
end

-- function DaHua_Yure_Letter_FindNPC()
-- 	AutoRuntoTargetExWithName(g_DaHua_Yure_Letter_NPCPosX, g_DaHua_Yure_Letter_NPCPosZ, 0, g_DaHua_Yure_Letter_Name)
-- end

function DaHua_Yure_Letter_OnGoButtonClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGuideGoto")
		Set_XSCRIPT_ScriptID(999112)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DaHua_Yure_Letter_OnClose()
	this:Hide()
end

function DaHua_Yure_Letter_On_ResetPos()
	DaHua_Yure_Letter_Frame:SetProperty("UnifiedPosition", g_DaHua_Yure_Letter_Frame_UnifiedPosition)

end
