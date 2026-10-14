-- 倒计时

function CampPVP2023_CountDown_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
local g_Timer = -1
function CampPVP2023_CountDown_OnLoad()
	g_Timer = 5
	CampPVP2023_CountDown_Animate:Play(false)
end

function CampPVP2023_CountDown_OnEvent(event)

	if event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 998429001 then
	        return
	    end
		g_Timer = 5
		--SetTimer("CampPVP2023_CountDown","CampPVP2023_CountDown_Timer()", 1*1000)
		CampPVP2023_CountDown_Animate:Play(true)
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function CampPVP2023_CountDown_Timer()
	-- g_Timer = g_Timer - 1 
	-- --PushDebugMessage(g_Timer)
	-- if g_Timer == 0 then
		-- KillTimer("CampPVP2023_CountDown_Timer()")
		-- CampPVP2023_CountDown_Animate:Play(false)
		-- Clear_XSCRIPT();
			-- Set_XSCRIPT_Function_Name("Boom")
			-- Set_XSCRIPT_ScriptID( 888944)
			-- Set_XSCRIPT_ParamCount(0)
		-- Send_XSCRIPT();
		-- this:Hide()
	-- end
end