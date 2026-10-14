-- 2024Q4冰雪节答题活动
--答题界面
--!!!reloadscript =Frozen_Answer_End

local g_UnifiedPosition = nil

function Frozen_Answer_End_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function Frozen_Answer_End_OnLoad()
	g_UnifiedPosition = Frozen_Answer_End_Frame:GetProperty("UnifiedPosition")
end

function Frozen_Answer_End_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99947901 )  then
		local result = Get_XParam_INT(0)
		if result > 0 then
			this:Show()
			SetTimer("Frozen_Answer_End","Frozen_Answer_End_TimerProc()", 3000)
			if result == 1 then
				Frozen_Answer_End_Success:Show()
				Frozen_Answer_End_Fail:Hide()
			else
				Frozen_Answer_End_Success:Hide()
				Frozen_Answer_End_Fail:Show()
			end
		else
			Frozen_Answer_End_CloseFun()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_Answer_End_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_Answer_End_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_Answer_End_CloseFun()
	end	
end

function Frozen_Answer_End_TimerProc()
	Frozen_Answer_End_CloseFun()
end

function Frozen_Answer_End_On_ResetPos()
	Frozen_Answer_End_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
end

function Frozen_Answer_End_CloseFun()
	KillTimer("Frozen_Answer_End_TimerProc()")
	this:Hide()
end
