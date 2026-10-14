--T3WarmUp_Memorial.lua
--2020 新天外预热-汴京八景道具界面
local g_Frame_UnifiedPosition
local g_HuoDongInfo = {}
--===============================================
-- OnLoad()
--===============================================
function T3WarmUp_Memorial_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end
function T3WarmUp_Memorial_OnLoad()
	g_Frame_UnifiedPosition = T3WarmUp_Memorial_Frame:GetProperty("UnifiedPosition")
	g_HuoDongInfo = {
		{uiName=T3WarmUp_Memorial_Landscape_Btn1, szName="#{TWYR_200908_154}"},
		{uiName=T3WarmUp_Memorial_Landscape_Btn2, szName="#{TWYR_200908_155}"},
		{uiName=T3WarmUp_Memorial_Landscape_Btn3, szName="#{TWYR_200908_156}"},
		{uiName=T3WarmUp_Memorial_Landscape_Btn4, szName="#{TWYR_200908_157}"},
		{uiName=T3WarmUp_Memorial_Landscape_Btn5, szName="#{TWYR_200908_158}"},
		{uiName=T3WarmUp_Memorial_Landscape_Btn6, szName="#{TWYR_200908_159}"},
		{uiName=T3WarmUp_Memorial_Landscape_Btn7, szName="#{TWYR_200908_160}"},
		{uiName=T3WarmUp_Memorial_Landscape_Btn8, szName="#{TWYR_200908_161}"},
	}
	for i, v in ipairs(g_HuoDongInfo) do 
		v.uiName:SetToolTip(ScriptGlobal_Format("#{TWYR_200908_06}", v.szName))
	end
end

--===============================================
-- OnEvent()
--===============================================
function T3WarmUp_Memorial_OnEvent(event)
if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		T3WarmUp_Memorial_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		T3WarmUp_Memorial_Close()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15540001 ) then
		if Get_XParam_INT( 0 ) == 0 then 
			T3WarmUp_Memorial_Close()
			return
		end
		T3WarmUp_Memorial_UpdateInfo()
		this:Show()
	end
end
function T3WarmUp_Memorial_Close()
	this:Hide()
end
--===============================================
--===============================================
function T3WarmUp_Memorial_UpdateInfo()

end
-- 八景按钮
function T3WarmUp_Memorial_Landscape_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenT300BaJing")
		Set_XSCRIPT_ScriptID(888228)
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_Parameter( 1, 0 )
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
