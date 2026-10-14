
local g_unifiedposistion
local g_BuLaoDianTime_Mini_SceneId = 0
local g_BuLaoDianTime_Mini_opType = {
	show = 1,						-- 显示UI
	init = 2,						-- 初始化UI
	close = 1000,					-- 关闭UI
}
local g_scene_res_id = 878

function BuLaoDianTime_Mini_PreLoad()
	this:RegisterEvent("OPEN_TJC_PVP_MINI")
	this:RegisterEvent("UI_COMMAND", false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)	
end

function BuLaoDianTime_Mini_OnLoad()	
	g_unifiedposistion = BuLaoDianTime_Mini_Frame:GetProperty("UnifiedPosition")
end

function BuLaoDianTime_Mini_OnEvent(event)
	if event == "OPEN_TJC_PVP_MINI" then
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99853001 then
		local opType =  Get_XParam_INT( 0 )
		if opType == g_BuLaoDianTime_Mini_opType.close then
			this:Hide()
		end
	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		BuLaoDianTime_Mini_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		BuLaoDianTime_Mini_ResetPos()
	end
end

function BuLaoDianTime_Mini_ResetPos()
	BuLaoDianTime_Mini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function BuLaoDianTime_Mini_Open()
	if g_scene_res_id == GetSceneID() then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenFlashUI")
		Set_XSCRIPT_ScriptID(998530)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end