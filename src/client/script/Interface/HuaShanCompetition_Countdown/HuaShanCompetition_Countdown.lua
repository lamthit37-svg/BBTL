local g_HuaShanCompetition_Countdown_Frame_UnifiedPosition = nil 

function HuaShanCompetition_Countdown_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
end 

-- HuaShanCompetition_Countdown_End => TLBB_StaticImageNULL
-- HuaShanCompetition_Countdown_Animate => TLBB_Animate
-- HuaShanCompetition_Countdown_Start => TLBB_StaticImageNULL
function HuaShanCompetition_Countdown_OnLoad()
	g_HuaShanCompetition_Countdown_Frame_UnifiedPosition = HuaShanCompetition_Countdown_Frame:GetProperty("UnifiedPosition");
end

function HuaShanCompetition_Countdown_OnEvent(event)

	if(event == "ADJEST_UI_POS") then
		HuaShanCompetition_Countdown_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanCompetition_Countdown_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanCompetition_Countdown_On_Hide()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 20230810) then
		local type = Get_XParam_INT( 0 )
		if type == 1 then
			HuaShanCompetition_Countdown_Animate:Show()
			HuaShanCompetition_Countdown_Animate:Play(true)
			HuaShanCompetition_Countdown_Start:Hide()
			HuaShanCompetition_Countdown_End:Hide()
			this:Show()
		elseif type == 2 then
			HuaShanCompetition_Countdown_Animate:Hide()
			HuaShanCompetition_Countdown_Start:Hide()
			HuaShanCompetition_Countdown_End:Show()
			this:Show()
			SetTimer("HuaShanCompetition_Countdown","HuaShanCompetition_Countdown_Timer()", 1000)
		end

	end
end


function HuaShanCompetition_Countdown_On_ResetPos()
	HuaShanCompetition_Countdown_Frame:SetProperty("UnifiedPosition", g_HuaShanCompetition_Countdown_Frame_UnifiedPosition)
end

function HuaShanCompetition_Countdown_On_Hide()
	this:Hide()
end

function HuaShanCompetition_Countdown_PlayEnd()
	HuaShanCompetition_Countdown_Start:Show()
	SetTimer("HuaShanCompetition_Countdown","HuaShanCompetition_Countdown_Timer()", 1000)

end

function HuaShanCompetition_Countdown_Timer()

	KillTimer("HuaShanCompetition_Countdown_Timer()")
	this:Hide()
end