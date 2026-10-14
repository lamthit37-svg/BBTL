local g_Frozen_GeCao_Countdown_Frame_UnifiedPosition = nil 
local g_Timer = -1
function Frozen_GeCao_Countdown_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
end 

-- Frozen_GeCao_Countdown_End => TLBB_StaticImageNULL
-- Frozen_GeCao_Countdown_Animate => TLBB_Animate
-- Frozen_GeCao_Countdown_Start => TLBB_StaticImageNULL
function Frozen_GeCao_Countdown_OnLoad()
	g_Frozen_GeCao_Countdown_Frame_UnifiedPosition = Frozen_GeCao_Countdown_Frame:GetProperty("UnifiedPosition");
end

function Frozen_GeCao_Countdown_OnEvent(event)

	if(event == "ADJEST_UI_POS") then
		Frozen_GeCao_Countdown_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_GeCao_Countdown_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_GeCao_Countdown_On_Hide()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 331141001) then
	
			Frozen_GeCao_Countdown_Animate:Show()
			Frozen_GeCao_Countdown_Animate:Play(true)
			Frozen_GeCao_Countdown_Start:Hide()
			Frozen_GeCao_Countdown_End:Hide()
			this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 331141002) then
			if g_Timer > 0 then
				KillTimer("Frozen_GeCao_Countdown_Timer()")
			end
			g_Timer = 3
			SetTimer("Frozen_GeCao_Countdown","Frozen_GeCao_Countdown_Timer()", 1*1000)
			Frozen_GeCao_Countdown_Animate:Hide()
			Frozen_GeCao_Countdown_Animate:Play(false)
			Frozen_GeCao_Countdown_Start:Show()
			Frozen_GeCao_Countdown_End:Hide()
			this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 331141003) then
			if g_Timer > 0 then
				KillTimer("Frozen_GeCao_Countdown_Timer()")
			end
			g_Timer = 3
			SetTimer("Frozen_GeCao_Countdown","Frozen_GeCao_Countdown_Timer()", 1*1000)
			Frozen_GeCao_Countdown_Animate:Hide()
			Frozen_GeCao_Countdown_Animate:Play(false)
			Frozen_GeCao_Countdown_Start:Hide()
			Frozen_GeCao_Countdown_End:Show()
			this:Show()
	end
end


function Frozen_GeCao_Countdown_On_ResetPos()
	Frozen_GeCao_Countdown_Frame:SetProperty("UnifiedPosition", g_Frozen_GeCao_Countdown_Frame_UnifiedPosition)
end

function Frozen_GeCao_Countdown_On_Hide()
	this:Hide()
end

function Frozen_GeCao_Countdown_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("Frozen_GeCao_Countdown_Timer()")
		this:Hide()
	end
end
