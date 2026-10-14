local g_BingSheng_StartTime = 0
local g_BingSheng_CountTime = 0
local BingSheng_Timing_NumImageInfo =
{
	[0] = "set:GuanShanHai03 image:Ceng0",
	[1] = "set:GuanShanHai03 image:Ceng1",
	[2] = "set:GuanShanHai03 image:Ceng2",
	[3] = "set:GuanShanHai03 image:Ceng3",
	[4] = "set:GuanShanHai03 image:Ceng4",
	[5] = "set:GuanShanHai03 image:Ceng5",
	[6] = "set:GuanShanHai03 image:Ceng6",
	[7] = "set:GuanShanHai03 image:Ceng7",
	[8] = "set:GuanShanHai03 image:Ceng8",
	[9] = "set:GuanShanHai03 image:Ceng9",
}


function BingSheng_Timing_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end



function BingSheng_Timing_OnLoad()
	g_BingSheng_StartTime = 0
	g_BingSheng_CountTime = 0
end



function BingSheng_Timing_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 50505501) then		
		local startTime = Get_XParam_INT( 0 )
		if startTime <= 0 then
			return
		end
		g_BingSheng_StartTime = startTime
		if this : IsVisible() then
			return
		end
		
		KillTimer("BingSheng_Timing_TimerProc()")
		SetTimer("BingSheng_Timing","BingSheng_Timing_TimerProc()", 1000)
		BingSheng_Timing_TimeText:SetText( ScriptGlobal_Format( "#{BSQZ_210714_100}", "00","00" ) )
		this:Show()
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50505502) then
		KillTimer("BingSheng_Timing_TimerProc()")
		g_BingSheng_CountTime = Get_XParam_INT( 0 )
		BingSheng_Timing_TimerProc()
	elseif event=="HIDE_ON_SCENE_TRANSED"  then
		BingSheng_Timing_TimeText:SetText( ScriptGlobal_Format( "#{BSQZ_210714_100}", "00","00" ) )
		g_BingSheng_CountTime = 0
		this:Hide()
	end
end


function BingSheng_Timing_TimerProc()
	local countTime = DataPool:GetCurrentServerTime() - g_BingSheng_StartTime
	if g_BingSheng_CountTime > 0 then
		countTime = g_BingSheng_CountTime
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

	
	BingSheng_Timing_TimeText:SetText( ScriptGlobal_Format( "#{BSQZ_210714_100}", strMinute,strSec ) )
end

