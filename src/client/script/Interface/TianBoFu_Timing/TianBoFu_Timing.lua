local g_TianBoFu_StartTime = 0
local g_TianBoFu_CountTime = 0

function TianBoFu_Timing_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
    
end


function TianBoFu_Timing_OnLoad()

	g_TianBoFu_StartTime = 0
    g_TianBoFu_CountTime = 0
    
end


function TianBoFu_Timing_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99805001) then		
		local startTime = Get_XParam_INT( 0 )
		if startTime <= 0 then
			return
		end
		g_TianBoFu_StartTime = startTime
		
		if this : IsVisible() then	-- 如果界面开着，则不处理
			return
		end

		KillTimer("TianBoFu_Timing_TimerProc()")
		SetTimer("TianBoFu_Timing","TianBoFu_Timing_TimerProc()", 1000)	
		this:Show()
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99805003) then
		KillTimer("TianBoFu_Timing_TimerProc()")
		g_TianBoFu_CountTime = Get_XParam_INT( 0 )
		TianBoFu_Timing_TimerProc()
	elseif event=="HIDE_ON_SCENE_TRANSED"  then
		KillTimer("TianBoFu_Timing_TimerProc()")
		local strSec = 0
		strSec = "0"..tostring(strSec)
		TianBoFu_Timing_Text:SetText(ScriptGlobal_Format("#{YTTBF_220524_286}",strSec,strSec))
		g_TianBoFu_CountTime = 0
		this:Hide()
    end
    
end


function TianBoFu_Timing_TimerProc()

	local countTime = DataPool:GetCurrentServerTime() - g_TianBoFu_StartTime
	if g_TianBoFu_CountTime > 0 then
		countTime = g_TianBoFu_CountTime
	end
	if countTime < 0 then
		countTime = 0
	end

	local minuteTime = math.floor(countTime/60)
	local secTime = math.mod(countTime,60)

	local strMinute = tostring(minuteTime)
	if minuteTime < 10 then
		strMinute = "0"..tostring(minuteTime)
	end
	
	local strSec = tostring(secTime)
	if secTime < 10 then
		strSec = "0"..tostring(secTime)
	end
	
    --#cfff263副本攻略时间：#G%s0：%s1#cfff263
    TianBoFu_Timing_Text:SetText(ScriptGlobal_Format("#{YTTBF_220524_286}",strMinute,strSec)) 
	
end