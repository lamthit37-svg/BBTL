--冰雪躲避战 活动中ui

local g_Frozen_DodgeBall_Frame_UnifiedPosition
local g_Frozen_DodgeBall_CountTime = 0
local g_Frozen_DodgeBall_SurviveTime = 0
local g_Frozen_DodgeBall_TeamMemCount = 0

function Frozen_DodgeBall_PreLoad()
	this:RegisterEvent("BXDBZ_OPEN_COUNTDOWNUI", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("BXDBZ_CLOSE_COUNTDOWNUI",false)
	this:RegisterEvent("BXDBZ_SYN_COUNTDOWNTIME",false)
	this:RegisterEvent("BXDBZ_SYN_SURVIVETIME",false)
	--this:RegisterEvent("BXDBZ_SYN_TEAMMEMCOUNT",false)
end

function Frozen_DodgeBall_OnLoad()
	g_Frozen_DodgeBall_Frame_UnifiedPosition = Frozen_DodgeBall_Frame:GetProperty("UnifiedPosition")

end

function Frozen_DodgeBall_OnEvent(event)
	if event == "BXDBZ_OPEN_COUNTDOWNUI" then
		this:Show()
		g_Frozen_DodgeBall_CountTime = tonumber(arg0) 
		g_Frozen_DodgeBall_SurviveTime = tonumber(arg1)
		g_Frozen_DodgeBall_TeamMemCount = tonumber(arg2)
		
		Frozen_DodgeBall_Refresh(1)
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_DodgeBall_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_DodgeBall_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_DodgeBall_CloseFun()
	elseif event == "BXDBZ_CLOSE_COUNTDOWNUI" then
		local result = tonumber(arg0) 
		Frozen_DodgeBall_Refresh(result)
	elseif event == "BXDBZ_SYN_COUNTDOWNTIME" then
		g_Frozen_DodgeBall_CountTime = tonumber(arg0) 
		g_Frozen_DodgeBall_TeamMemCount = tonumber(arg1) 
		Frozen_DodgeBall_Refresh(2)
	elseif event == "BXDBZ_SYN_SURVIVETIME" then
		g_Frozen_DodgeBall_SurviveTime = tonumber(arg0) 
		Frozen_DodgeBall_Refresh(2)

	end
	
end

function Frozen_DodgeBall_Close_Clicked()

	PushEvent("BXDBZ_COLSE_CONFIRM")
end


function Frozen_DodgeBall_Refresh(operate)
	if operate <=2 then
		
		KillTimer("Frozen_DodgeBall_TimerProc()")
		if operate == 1 then
			Frozen_DodgeBall_GameInfoBK:Show()
			Frozen_DodgeBall_Success:Hide()
			Frozen_DodgeBall_Fail:Hide()
		end
		Frozen_DodgeBall_CountdownTime:SetText(ScriptGlobal_Format("#{BXDK_240909_45}",g_Frozen_DodgeBall_CountTime))
		Frozen_DodgeBall_Health:SetText(ScriptGlobal_Format("#{BXDK_240909_44}",g_Frozen_DodgeBall_SurviveTime))
		if g_Frozen_DodgeBall_TeamMemCount < 0 then
			Frozen_DodgeBall_TeamMember:Hide()
		else
			Frozen_DodgeBall_TeamMember:Show()
		end
		Frozen_DodgeBall_TeamMember:SetText(ScriptGlobal_Format("#{BXDK_240909_46}",g_Frozen_DodgeBall_TeamMemCount))
		Frozen_DodgeBall_Close:Show()
	else
		
		SetTimer("Frozen_DodgeBall","Frozen_DodgeBall_TimerProc()", 10000)
		Frozen_DodgeBall_GameInfoBK:Hide()
		if operate == 3 then
			--PushEvent("BXDBZ_OPEN_RESULT",1)
			Frozen_DodgeBall_Success:Show()
			Frozen_DodgeBall_Fail:Hide()
		elseif operate == 4 then
			--PushEvent("BXDBZ_OPEN_RESULT",0)
			Frozen_DodgeBall_Success:Hide()
			Frozen_DodgeBall_Fail:Show()
		end
		Frozen_DodgeBall_Close:Hide()
		PushEvent("BXDBZ_HIDE_CONFIRM")
	end

end

function Frozen_DodgeBall_TimerProc()
	Frozen_DodgeBall_CloseFun()
end

function Frozen_DodgeBall_On_ResetPos()
	Frozen_DodgeBall_Frame:SetProperty("UnifiedPosition", g_Frozen_DodgeBall_Frame_UnifiedPosition)
end

function Frozen_DodgeBall_CloseFun()
	KillTimer("Frozen_DodgeBall_TimerProc()")
	g_Frozen_DodgeBall_CountTime = 0
	this:Hide()
end
