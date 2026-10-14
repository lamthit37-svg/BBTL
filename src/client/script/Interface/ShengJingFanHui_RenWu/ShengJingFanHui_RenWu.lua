
--盛景繁绘 每日任务
local g_ShengJingFanHui_RenWu_Frame_UnifiedPosition
local g_ShengJingFanHui_RenWu_IsShowPoint1 = 0
local g_ShengJingFanHui_RenWu_IsShowPoint2 = 0
local g_ShengJingFanHui_RenWu_Condition3 = 0
local g_ShengJingFanHui_RenWu_IsGotReward1 = 0
local g_ShengJingFanHui_RenWu_IsGotReward2 = 0
local g_ShengJingFanHui_RenWu_IsGotReward3 = 0
function ShengJingFanHui_RenWu_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	
end

function ShengJingFanHui_RenWu_OnLoad()
	g_ShengJingFanHui_RenWu_Frame_UnifiedPosition = ShengJingFanHui_RenWu:GetProperty("UnifiedPosition")
end

function ShengJingFanHui_RenWu_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2023051102) then
		-- if this:IsVisible() then
		-- 	ShengJingFanHui_RenWu_Close()
		-- 	return
		-- end
		this:Show()

		g_ShengJingFanHui_RenWu_IsShowPoint1 = Get_XParam_INT(0)
		g_ShengJingFanHui_RenWu_IsShowPoint2 = Get_XParam_INT(1)
		g_ShengJingFanHui_RenWu_Condition3 = Get_XParam_INT(2)
		g_ShengJingFanHui_RenWu_IsGotReward1 = Get_XParam_INT(3)
		g_ShengJingFanHui_RenWu_IsGotReward2 = Get_XParam_INT(4)
		g_ShengJingFanHui_RenWu_IsGotReward3 = Get_XParam_INT(5)
		ShengJingFanHui_RenWu_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ShengJingFanHui_RenWu_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		ShengJingFanHui_RenWu_Close()
	elseif event == "ADJEST_UI_POS" then
		ShengJingFanHui_RenWu_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ShengJingFanHui_RenWu_Close()
	end
	
end

function ShengJingFanHui_RenWu_Open()
	if g_ShengJingFanHui_RenWu_Condition3 == 1 then
		ShengJingFanHui_RenWu_Btn03:SetText("#{SJFH_230425_20}")
	else
		ShengJingFanHui_RenWu_Btn03:SetText("#{SJFH_230425_32}")
	end

	local kajiType = KaJi:LuaFnGetKaJiType(135)
	if kajiType == 1 then
		ShengJingFanHui_RenWu_Text02:SetText("#{SJFH_230425_140}")
	else
		ShengJingFanHui_RenWu_Text02:SetText("#{SJFH_230425_18}")
	end

	if g_ShengJingFanHui_RenWu_IsShowPoint1 == 1 then
		ShengJingFanHui_RenWu_Btn01_Tips:Show()
	else
		ShengJingFanHui_RenWu_Btn01_Tips:Hide()
	end
	if g_ShengJingFanHui_RenWu_IsShowPoint2 == 1 then
		ShengJingFanHui_RenWu_Btn02_Tips:Show()
	else
		ShengJingFanHui_RenWu_Btn02_Tips:Hide()
	end
	if g_ShengJingFanHui_RenWu_IsGotReward3 == 0 and g_ShengJingFanHui_RenWu_Condition3 == 1 then
		ShengJingFanHui_RenWu_Btn03_Tips:Show()
	else
		ShengJingFanHui_RenWu_Btn03_Tips:Hide()
	end

	if g_ShengJingFanHui_RenWu_IsGotReward1 == 1 then
		ShengJingFanHui_RenWu_Btn01:SetText("#{SJFH_230425_173}")
		ShengJingFanHui_RenWu_Btn01:Disable()
	else
		ShengJingFanHui_RenWu_Btn01:SetText("#{SJFH_230425_20}")
		ShengJingFanHui_RenWu_Btn01:Enable()
	end

	if g_ShengJingFanHui_RenWu_IsGotReward2 == 1 then
		ShengJingFanHui_RenWu_Btn02:SetText("#{SJFH_230425_173}")
		ShengJingFanHui_RenWu_Btn02:Disable()
	else
		ShengJingFanHui_RenWu_Btn02:SetText("#{SJFH_230425_20}")
		ShengJingFanHui_RenWu_Btn02:Enable()
	end

	if g_ShengJingFanHui_RenWu_IsGotReward3 == 1 then
		ShengJingFanHui_RenWu_Btn03:SetText("#{SJFH_230425_173}")
		ShengJingFanHui_RenWu_Btn03:Disable()
	else
		ShengJingFanHui_RenWu_Btn03:SetText("#{SJFH_230425_20}")
		ShengJingFanHui_RenWu_Btn03:Enable()
	end


	local strTemp = ScriptGlobal_Format("#{SJFH_230425_21}",1)
	-- local strTemp2 = ScriptGlobal_Format("#{SJFH_230425_21}",2)
	ShengJingFanHui_RenWu_Btn01:SetToolTip(strTemp)
	ShengJingFanHui_RenWu_Btn03:SetToolTip(strTemp)
	ShengJingFanHui_RenWu_Btn02:SetToolTip(strTemp)
end

function ShengJingFanHui_RenWu_GetReward(index)
	--index = 1 为领取在线时长奖励 2为领取活跃值奖励 3为收集绘图奖励
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GetPaintbrushReward")
	Set_XSCRIPT_ScriptID(998544)
	Set_XSCRIPT_Parameter( 0, index )
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function ShengJingFanHui_RenWu_On_ResetPos()
	ShengJingFanHui_RenWu:SetProperty("UnifiedPosition", g_ShengJingFanHui_RenWu_Frame_UnifiedPosition)
end

function ShengJingFanHui_RenWu_OnHide()
	
end

function ShengJingFanHui_RenWu_Close()
	this:Hide()
end
