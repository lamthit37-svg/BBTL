local g_Frozen_PVPCountdown_Frame_UnifiedPosition = nil 

function Frozen_PVPCountdown_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end 


function Frozen_PVPCountdown_OnLoad()
	g_Frozen_PVPCountdown_Frame_UnifiedPosition = Frozen_PVPCountdown_Frame:GetProperty("UnifiedPosition");
end

function Frozen_PVPCountdown_OnEvent(event)

	if(event == "ADJEST_UI_POS") then
		Frozen_PVPCountdown_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_PVPCountdown_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_PVPCountdown_On_Hide()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 80030603) then
		local type = Get_XParam_INT( 0 )
		if type == 1 then
			Frozen_PVPCountdown_Animate:Show()
			Frozen_PVPCountdown_Animate:Play(true)
			Frozen_PVPCountdown_Start:Hide()
			Frozen_PVPCountdown_End:Hide()
			this:Show()
		elseif type == 2 then
			Frozen_PVPCountdown_Animate:Hide()
			Frozen_PVPCountdown_Start:Hide()
			Frozen_PVPCountdown_End:Show()
			this:Show()
			SetTimer("Frozen_PVPCountdown","Frozen_PVPCountdown_Timer()", 1000)
		end

	end
end


function Frozen_PVPCountdown_On_ResetPos()
	Frozen_PVPCountdown_Frame:SetProperty("UnifiedPosition", g_Frozen_PVPCountdown_Frame_UnifiedPosition)
end

function Frozen_PVPCountdown_On_Hide()
	this:Hide()
end

function Frozen_PVPCountdown_PlayEnd()
	Frozen_PVPCountdown_Start:Show()
	SetTimer("Frozen_PVPCountdown","Frozen_PVPCountdown_Timer()", 1000)

end

function Frozen_PVPCountdown_Timer()

	KillTimer("Frozen_PVPCountdown_Timer()")
	this:Hide()
end