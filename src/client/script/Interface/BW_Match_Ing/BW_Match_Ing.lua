-- 新比武大会匹配提示
local g_TimerTick = -1
local g_TimerId = -1
local g_BW_Match_Ing_Animate = {};

function BW_Match_Ing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end


function BW_Match_Ing_OnLoad()
	g_BW_Match_Ing_Animate[1] = BW_Match_Ing_Animate1
	g_BW_Match_Ing_Animate[2] = BW_Match_Ing_Animate2
	g_BW_Match_Ing_Animate[3] = BW_Match_Ing_Animate3
end

function BW_Match_Ing_OnEvent(event)

	if event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 20180912 then
	        return
	    end
		local nIndex = Get_XParam_INT(0);
		if nIndex < 2 or nIndex > 3 then
			return
		end


		g_BW_Match_Ing_Animate[1]:Show()
		for i=2,3 do
			if i == nIndex then
				g_BW_Match_Ing_Animate[i]:Show()
			else
				g_BW_Match_Ing_Animate[i]:Hide()
			end
		end

		if g_TimerId > 0 then
			KillTimer("BW_Match_Ing_Timer()")
			g_TimerId = -1
		end

		g_TimerTick = 6
		g_TimerId = SetTimer("BW_Match_Ing","BW_Match_Ing_Timer()", 1*1000)
		this:Show()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		KillTimer("BW_Match_Ing_Timer()")
		g_TimerId = -1
		this:Hide()
	end
end

function BW_Match_Ing_Timer()
	g_TimerTick = g_TimerTick - 1
	--PushDebugMessage(g_TimerTick)
	if g_TimerTick <= 0 then
		KillTimer("BW_Match_Ing_Timer()")
		g_TimerId = -1
		this:Hide()
	end
end
