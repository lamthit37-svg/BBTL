-- 复活界面

local g_unifiedposistion
local g_ui_command = 99932107

function CJ_Relive_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("RELIVE_HIDE",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CJ_Relive_OnLoad()
	g_unifiedposistion = CJ_Relive_Frame:GetProperty("UnifiedPosition")
end

function CJ_Relive_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then
		CJ_Relive_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		CJ_Relive_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_Relive_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CJ_Relive_CloseClicked()
	elseif (event == "RELIVE_HIDE") then
		CJ_Relive_CloseClicked()
	end

end

function CJ_Relive_OnShow()

	this:Show()
end

function CJ_Relive_FuHuo_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPlayerSelectRelive" )
		Set_XSCRIPT_ScriptID(999321)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function CJ_Relive_AnQuanQu_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPlayerSelectBackSafeArea" )
		Set_XSCRIPT_ScriptID(999321)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--================================================
-- 关闭
--================================================
function CJ_Relive_CloseClicked()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function CJ_Relive_OnHide()
	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_Relive_ResetPos()
	CJ_Relive_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

