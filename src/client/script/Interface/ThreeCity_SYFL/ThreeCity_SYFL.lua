local g_UnifiedPosition = ""
local g_SceneId = 0
local g_PosX = 0
local g_PosZ = 0
local g_SourceName = ""
local g_SceneName = ""
--===============================================
-- OnLoad()
--===============================================
function ThreeCity_SYFL_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent( "HIDE_ON_SCENE_TRANSED" , false);		-- 离开场景
end

function ThreeCity_SYFL_OnLoad()

	g_UnifiedPosition = ThreeCity_SYFL_Frame:GetProperty("UnifiedPosition")

end

--===============================================
-- OnEvent
--===============================================
function ThreeCity_SYFL_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99820302) then 
		g_SceneId = Get_XParam_INT(0)
		g_PosX = Get_XParam_INT(1)
		g_PosZ = Get_XParam_INT(2)
		g_SourceName = Get_XParam_STR(0);
		g_SceneName = Get_XParam_STR(1);
		ThreeCity_SYFL_UpdateFrame()
		this:Show()

	elseif (event == "ADJEST_UI_POS" ) then
		ThreeCity_SYFL_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCity_SYFL_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		ThreeCity_SYFL_CloseWindow()
	end
end

function ThreeCity_SYFL_UpdateFrame()
	
	
	local str = ScriptGlobal_Format("#{FFZQ_220803_30}", g_SourceName, g_SceneName)
	ThreeCity_SYFL_Info:SetText(str)
	ThreeCity_SYFL_SJ:SetProperty("Timer",tostring( 30 ));

end

function ThreeCity_SYFL_OK_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Trans")
		Set_XSCRIPT_ScriptID(998203)
		Set_XSCRIPT_Parameter(0, g_SceneId)
		Set_XSCRIPT_Parameter(1, g_PosX)
		Set_XSCRIPT_Parameter(2, g_PosZ)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	ThreeCity_SYFL_CloseWindow()
end

function ThreeCity_SYFL_CloseWindow()
	g_SceneId = 0
	g_PosX = 0
	g_PosZ = 0
	g_SourceName = ""
	g_SceneName = ""
	this:Hide()
end

function ThreeCity_SYFL_ResetPos()
	ThreeCity_SYFL_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition);
end

function ThreeCity_SYFL_TimeToZero()

	ThreeCity_SYFL_CloseWindow()
end
