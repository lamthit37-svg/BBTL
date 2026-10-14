local g_unifiedposistion
local g_QiXi_PVE_StageMini_SceneId = 0
local g_QiXi_PVE_StageMini_opType = {
	close = 999,					-- 关闭UI
}
local g_QiXi_PVE_StageMini_UICommand = 05123807


function QiXi_PVE_StageMini_PreLoad()
	this:RegisterEvent("OPEN_QiXi_PVE_StageMini")
	this:RegisterEvent("UI_COMMAND", false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)	
end

function QiXi_PVE_StageMini_OnLoad()	
	g_unifiedposistion = QiXi_PVE_StageMini_Frame:GetProperty("UnifiedPosition")
end

function QiXi_PVE_StageMini_OnEvent(event)
	if event == "OPEN_QiXi_PVE_StageMini" then
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_QiXi_PVE_StageMini_UICommand then
		local opType =  Get_XParam_INT( 0 )
		if opType == g_QiXi_PVE_StageMini_opType.close then
			this:Hide()
		end

	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		QiXi_PVE_StageMini_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_PVE_StageMini_ResetPos()
	end
end

function QiXi_PVE_StageMini_ResetPos()
	QiXi_PVE_StageMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function QiXi_PVE_StageMini_OnHide()
	
end
	

function QiXi_PVE_StageMini_Clicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OpenStageUI")
    Set_XSCRIPT_ScriptID(051238)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end
