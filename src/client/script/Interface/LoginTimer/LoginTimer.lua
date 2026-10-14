--登录流程倒计时

--local timer = 60 * 4	--整个登录过程允许5分钟，4分钟时开始显示提示信息
local timer = 60 * 2	--整个登录过程允许10分钟，9分钟时开始显示提示信息
local g_LoginTimer_TipOverTime=0;
function LoginTimer_PreLoad()
	this:RegisterEvent("LOGIN_COUNTDOWN");
	this:RegisterEvent("LOGIN_COUNTDOWN_CLOSE");
end

function LoginTimer_OnLoad()
end

function LoginTimer_OnEvent(event)
	if event == "LOGIN_COUNTDOWN" then
		if this:IsVisible() then
			return
		end
			
		g_LoginTimer_TipOverTime = timer;
		LoginTimer_TipTimerProc();
		KillTimer( "LoginTimer_TipTimerProc()" );
		SetTimer("LoginTimer","LoginTimer_TipTimerProc()", 1000)
	
		Login_Timer_Frame:Show()
		this:Show()
	elseif event == "LOGIN_COUNTDOWN_CLOSE" then
		--Login_Time_StopWatch:SetProperty("Timer", tostring(0))
		KillTimer( "LoginTimer_TipTimerProc()" );
		Login_Timer_Frame:Hide()
		this:Hide()
	end
end

function LoginTimer_TipTimerProc()
	local strTipText = ScriptGlobal_Format( "#{CJYZ_20231214_29}", g_LoginTimer_TipOverTime )
	g_LoginTimer_TipOverTime = g_LoginTimer_TipOverTime -1;
	if g_LoginTimer_TipOverTime < 0 then
		LoginTimer_TimeOut()
		return
	end
	Login_Timer_Frame:SetText( strTipText );
end

function LoginTimer_TimeOut()
	KillTimer( "LoginTimer_TipTimerProc()" );
	GameProduceLogin:DisconnectServer();
	PushEvent("LOGIN_OVER_TIME")	
end
