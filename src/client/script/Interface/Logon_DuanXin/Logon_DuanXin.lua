--Logon_DuanXin
local g_Logon_DuanXin_SecurityCodeTime = 0;
local g_Logon_DuanXin_BindPhone = 0;
local g_Logon_DuanXin_TipOverTime = 180;

function Logon_DuanXin_PreLoad()
	this:RegisterEvent("CREATECHAR_SMSCODE_UI");
	this:RegisterEvent("CREATECHAR_SMSCODE_GETCODE",false)
	this:RegisterEvent("CREATECHAR_SMSCODE_APPROVE",false)
end

function Logon_DuanXin_OnLoad()
end

function Logon_DuanXin_OnEvent(event)
	if (event == "CREATECHAR_SMSCODE_UI") then
		if ( tonumber(arg0) == 1 ) then
			Logon_DuanXin_Show( tonumber(arg1) )
		else
			Logon_DuanXin_Close()
		end
		return 
	
	--手机认证-获取验证码
	elseif (event == "CREATECHAR_SMSCODE_GETCODE" ) then
		if ( tonumber(arg0) == 1 ) then
			PushDebugMessage("#{CJYZ_20231214_12}");
		else
			Logon_DuanXin_GetCode_Msg(tonumber(arg1));
		end		
	
	--手机认证-认证
	elseif (event == "CREATECHAR_SMSCODE_APPROVE" ) then
		if ( tonumber(arg0) == 1 ) then
			Logon_DuanXin_Close();
		else
			Logon_DuanXin_Approve_Msg(tonumber(arg1));
		end
	end
		
end

function Logon_DuanXin_Show( bBindPhone )
	g_Logon_DuanXin_BindPhone = bBindPhone
	if g_Logon_DuanXin_BindPhone == 0 then
		Logon_DuanXin_Edit:SetProperty("MaxTextLength", "20")
		Logon_DuanXin_Edit:SetText("游戏账号尚未认证手机");
		Logon_DuanXin_Edit:Disable();
		Logon_DuanXin_Get:Disable();
	elseif g_Logon_DuanXin_BindPhone == 1 then
		Logon_DuanXin_Edit:SetProperty("MaxTextLength", "20")
		Logon_DuanXin_Edit:SetText("请输入短信验证码");
		Logon_DuanXin_Edit:Enable();
		Logon_DuanXin_Get:Enable();
	end
	
	Logon_DuanXin_Get:SetText("#{CJYZ_20231214_4}")
	Logon_DuanXin_Time_Text:Hide();
	Logon_DuanXin_Check:Disable();
	
	g_Logon_DuanXin_TipOverTime = 180;
	Logon_DuanXin_TipTimerProc();
	Logon_DuanXin_Tips_Text:Show();
	KillTimer( "Logon_DuanXin_TipTimerProc()" );
	SetTimer("Logon_DuanXin","Logon_DuanXin_TipTimerProc()", 1000)
	
	this:Show()
	PushEvent("LOGIN_COUNTDOWN_CLOSE");
end

function Logon_DuanXin_Close()
	KillTimer( "Logon_DuanXin_TipTimerProc()" );
	KillTimer( "Logon_DuanXin_ApproveTimerProc()" );
	this:Hide()
end

--得到验证码
function Logon_DuanXin_GetCode()
	if g_Logon_DuanXin_BindPhone == 0 then   --未绑定状态
		PushDebugMessage("#{CJYZ_20231214_7}");
		return
	end
	
	GameProduceLogin:LoginSMSCodeGetCode();
	
	Logon_DuanXin_Edit:SetProperty("DefaultEditBox", "True");
	Logon_DuanXin_OnActive();
	Logon_DuanXin_Get:Disable();
	g_Logon_DuanXin_SecurityCodeTime = 60;
	Logon_DuanXin_ApproveTimerProc();
	Logon_DuanXin_Time_Text:Show();
	KillTimer( "Logon_DuanXin_ApproveTimerProc()" );
	SetTimer("Logon_DuanXin","Logon_DuanXin_ApproveTimerProc()", 1000)
end

--验证
function Logon_DuanXin_CheckCode()
	if g_Logon_DuanXin_BindPhone == 0 then   --未绑定状态
		PushDebugMessage("#{CJYZ_20231214_28}")
		return
	end
	
	local szText = Logon_DuanXin_Edit:GetText();
	local nCode = tonumber(szText);
	if nCode == nil then
		PushDebugMessage("#{CJYZ_20231214_13}")
		return
	end
	
	local nCodeLen = string.len(szText)
	if nCodeLen ~= 6 then
		PushDebugMessage("#{CJYZ_20231214_14}")
		return
	end
	
	GameProduceLogin:LoginSMSCodeApprove( tostring(szText) );
end

function Logon_DuanXin_OnActive()
	if g_Logon_DuanXin_BindPhone == 0 then   --未绑定状
		return
	end
	
	local szText = Logon_DuanXin_Edit:GetText();
	if tonumber(szText) == nil then
		Logon_DuanXin_Edit:SetText("");
		Logon_DuanXin_Edit:SetProperty("MaxTextLength", "6")
	end
end

function Logon_DuanXin_OnInputTextChanged()
	if g_Logon_DuanXin_BindPhone == 0 then   --未绑定状态
		return
	end
	
	local szText = Logon_DuanXin_Edit:GetText();
	if tonumber(szText) ~= nil then
		Logon_DuanXin_Check:Enable();
	end
end

function Logon_DuanXin_ChangePhoneNo()
	GameProduceLogin:OpenURL(GetWeblink("WEB_JSCJYZ"))
end

function Logon_DuanXin_ApproveTimerProc()
	local strBtnText = ScriptGlobal_Format( "#{CJYZ_20231214_5}", g_Logon_DuanXin_SecurityCodeTime )
	g_Logon_DuanXin_SecurityCodeTime = g_Logon_DuanXin_SecurityCodeTime -1;
	if g_Logon_DuanXin_SecurityCodeTime < 0 then
		Logon_DuanXin_Get:SetText( "#{CJYZ_20231214_4}" )
		Logon_DuanXin_Get:Enable();
		Logon_DuanXin_Time_Text:Hide();
		KillTimer( "Logon_DuanXin_ApproveTimerProc()" );
		return
	end
	Logon_DuanXin_Time_Text:SetText( strBtnText )
end

function Logon_DuanXin_TipTimerProc()
	local strTipText = ScriptGlobal_Format( "#{CJYZ_20231214_29}", g_Logon_DuanXin_TipOverTime )
	g_Logon_DuanXin_TipOverTime = g_Logon_DuanXin_TipOverTime -1;
	if g_Logon_DuanXin_TipOverTime < 0 then
		GameProduceLogin:DisconnectServer();
		PushEvent("LOGIN_OVER_TIME")	
		Logon_DuanXin_Close()
		return
	end
	Logon_DuanXin_Tips_Text:SetText( strTipText )
end

function Logon_DuanXin_GetCode_Msg( nErrCode )

	if nErrCode == 3 then
		PushDebugMessage( "#{CJYZ_20231214_7}");
	elseif nErrCode == 8 then
		PushDebugMessage( "#{CJYZ_20231214_25}");
	elseif nErrCode == 7 then
		PushDebugMessage( "#{CJYZ_20231214_27}");
	elseif nErrCode == 5 then
		PushDebugMessage( "#{CJYZ_20231214_11}");
	elseif nErrCode == 4 then
		PushDebugMessage( "#{CJYZ_20231214_26}");	
	else
		local strMsg =	ScriptGlobal_Format( "#{CJYZ_20231214_17}", nErrCode)	
		PushDebugMessage(strMsg);
	end
		
end

function Logon_DuanXin_Approve_Msg( nErrCode )

	if nErrCode == 6 then
		PushDebugMessage( "#{CJYZ_20231214_14}");
	elseif nErrCode == 9 then
		PushDebugMessage( "#{CJYZ_20231214_15}");
	elseif nErrCode == 5 then
		PushDebugMessage( "#{CJYZ_20231214_11}");
	end
	
end
