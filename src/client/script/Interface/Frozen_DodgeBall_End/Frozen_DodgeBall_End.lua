local g_Frozen_DodgeBall_End_Frame_UnifiedPosition

function Frozen_DodgeBall_End_PreLoad()
	this:RegisterEvent("BXDBZ_OPEN_RESULT", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)

end

function Frozen_DodgeBall_End_OnLoad()
	g_Frozen_DodgeBall_End_Frame_UnifiedPosition = Frozen_DodgeBall_End_Frame:GetProperty("UnifiedPosition")

end

function Frozen_DodgeBall_End_OnEvent(event)
	if event == "BXDBZ_OPEN_RESULT" then
		this:Show()
		SetTimer("Frozen_DodgeBall_End","Frozen_DodgeBall_End_TimerProc()", 6000)
		local result = tonumber(arg0) 
		if result == 1 then
			Frozen_DodgeBall_End_Success:Show()
			Frozen_DodgeBall_End_Fail:Hide()
		else
			Frozen_DodgeBall_End_Success:Hide()
			Frozen_DodgeBall_End_Fail:Show()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_DodgeBall_End_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_DodgeBall_End_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_DodgeBall_End_CloseFun()
	end
	
end


function Frozen_DodgeBall_End_TimerProc()
	Frozen_DodgeBall_End_CloseFun()
end

function Frozen_DodgeBall_End_On_ResetPos()
	Frozen_DodgeBall_End_Frame:SetProperty("UnifiedPosition", g_Frozen_DodgeBall_End_Frame_UnifiedPosition)
end

function Frozen_DodgeBall_End_CloseFun()
	KillTimer("Frozen_DodgeBall_End_TimerProc()")
	this:Hide()
end
