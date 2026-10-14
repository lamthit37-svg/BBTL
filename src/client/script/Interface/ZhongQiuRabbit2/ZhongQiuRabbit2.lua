
local g_Frame_UnifiedPosition
local g_ZhongQiuRabbit_PastWalkNum 
local g_ZhongQiuRabbit_WalkTime

--预加载函数，可以而且只能在这里注册脚本关心的事件
function ZhongQiuRabbit2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ZhongQiuRabbit2_OnLoad()
	g_Frame_UnifiedPosition = ZhongQiuRabbit2_Frame:GetProperty("UnifiedPosition")
end

--响应事件的函数，当注册的事件发生时会调用的函数
function ZhongQiuRabbit2_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		ZhongQiuRabbit2_On_ResetPos()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89290407 ) then
		local bForceOpen = Get_XParam_INT( 0 );
		g_ZhongQiuRabbit_PastWalkNum = Get_XParam_INT( 1 );
		g_ZhongQiuRabbit_WalkTime = Get_XParam_INT( 2 );

		if bForceOpen == 1 and ( not this:IsVisible()) then 
			this:Show()
		end
		ZhongQiuRabbit2_UpdateData();
	end
end

--以下是用户自定义的函数
function ZhongQiuRabbit2_On_ResetPos()
	ZhongQiuRabbit2_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function ZhongQiuRabbit2_Close()
	this:Hide()
end

function ZhongQiuRabbit2_UpdateData()
	ZhongQiuRabbit2_GameNum:SetText(ScriptGlobal_Format("#{QLGCJ_180810_97}", 1, 1))
	local huaNum = g_ZhongQiuRabbit_PastWalkNum - 1
	if g_ZhongQiuRabbit_WalkTime == 0 then 
		ZhongQiuRabbit2_TimeText:Hide()
		ZhongQiuRabbit2_TimeUpText:Hide()
		huaNum = g_ZhongQiuRabbit_PastWalkNum - 2
		ZhongQiuRabbit2_TimeUpNum:SetText(ScriptGlobal_Format("#{QLGCJ_180810_97}", 1, 1))
	else
		ZhongQiuRabbit2_TimeText:Show()
		ZhongQiuRabbit2_TimeUpText:Show()
		ZhongQiuRabbit2_TimeUpText:SetProperty("Timer", tostring(g_ZhongQiuRabbit_WalkTime))
		ZhongQiuRabbit2_TimeUpNum:SetText(ScriptGlobal_Format("#{QLGCJ_180810_98}", 0, 1))
	end
	if huaNum == 0 then 
		ZhongQiuRabbit2_ActNum:SetText(ScriptGlobal_Format("#{QLGCJ_180810_98}", huaNum, 2))
	else
		ZhongQiuRabbit2_ActNum:SetText(ScriptGlobal_Format("#{QLGCJ_180810_97}", huaNum, 2))
	end
end