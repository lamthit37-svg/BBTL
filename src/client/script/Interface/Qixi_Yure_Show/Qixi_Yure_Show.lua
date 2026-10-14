
local g_Qixi_Yure_Show_Frame_UnifiedPosition
local g_Qixi_Yure_Show_TargetId = 0

function Qixi_Yure_Show_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function Qixi_Yure_Show_OnLoad()
	g_Qixi_Yure_Show_Frame_UnifiedPosition = Qixi_Yure_Show_Frame:GetProperty("UnifiedPosition")
	
end

function Qixi_Yure_Show_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 90006101 then
		g_Qixi_Yure_Show_TargetId =  Get_XParam_INT( 0 )
		Qixi_Yure_Show_Refresh()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Qixi_Yure_Show_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Qixi_Yure_Show_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Qixi_Yure_Show_Close()
	end
end

function Qixi_Yure_Show_Refresh()
	
	this:Show()
	
end

function Qixi_Yure_Show_On_ResetPos()
	Qixi_Yure_Show_Frame:SetProperty("UnifiedPosition", g_Qixi_Yure_Show_Frame_UnifiedPosition)
end

function Qixi_Yure_Show_Close()
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name("OnComplete")
--		Set_XSCRIPT_ScriptID(900061)
--		Set_XSCRIPT_Parameter(0, g_Qixi_Yure_Show_TargetId);
--		Set_XSCRIPT_ParamCount(1)
--   Send_XSCRIPT()
	this:Hide()
end


