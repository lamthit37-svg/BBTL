--Captcha
local g_Captcha_UnifiedPosition;
local g_Captcha_SecurityCodeTime = 0;

function Captcha_PreLoad()
	this:RegisterEvent("OPEN_RENZHENG_PHONE");
	this:RegisterEvent("RENZHENG_PHONE_SECURITYCODE",false)
	this:RegisterEvent("RENZHENG_PHONE_APPROVE",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Captcha_OnLoad()
	g_Captcha_UnifiedPosition=Captcha_Frame:GetProperty("UnifiedPosition")
	
end

function Captcha_OnEvent(event)
	if (event == "OPEN_RENZHENG_PHONE") then
		Captcha_Show()
		return 
	
	--手机认证-获取验证码
	elseif (event == "RENZHENG_PHONE_SECURITYCODE" ) then
		if ( tonumber(arg0) == 1 ) then
			PushDebugMessage("#{GZSZH_230427_09}");
		else
			Captcha_SecurityCode_Msg(tonumber(arg1));
		end		
	
	--手机认证-认证
	elseif (event == "RENZHENG_PHONE_APPROVE" ) then
		if ( tonumber(arg0) == 1 ) then
			PushDebugMessage("#{GZSZH_230427_12}");
			this:Hide();
		else
			PushDebugMessage("#{GZSZH_230427_11}");
		end
	end
		
	if (event == "ADJEST_UI_POS") then
		Captcha_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		Captcha_On_ResetPos()
		return
	end

end

function Captcha_Show()

	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then
		Captcha_Frame1:Show();
		Captcha_Frame2:Hide();
	else
		local szPhoneNumber = DataPool:GetMobilePhoneNumber();
		Captcha_ShouJiHaoNum2_2:SetText(szPhoneNumber);
		
		Captcha_RenzhengNum2_2:SetProperty("MaxTextLength", "20")
		Captcha_RenzhengNum2_2:SetText("请输入短信验证码");
		
		Captcha_Frame1:Hide();
		Captcha_Frame2:Show();
	end
	
	PushDebugMessage("#{GZSZH_230427_01}")

	this:Show()
end

--绑定手机
function Captcha_OnApprovedPhoneNumberClicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_RZSJ"))
	end
end

--得到验证码
function Captcha_OnGetPhoneTextClicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then   --未绑定状态
		PushDebugMessage("#{GZSZH_230427_07}")
		return
	end

	DataPool:GetFlagASecurityCode()
	
	Captcha_RenzhengNum2_2:SetProperty("DefaultEditBox", "True");
	Captcha_InputCode_OnActived();
	Captcha_Button2_1:Disable();
	g_Captcha_SecurityCodeTime = 60;
	Captcha_ApproveTimerProc();
	KillTimer( "Captcha_ApproveTimerProc()" );
	SetTimer("Captcha","Captcha_ApproveTimerProc()", 1000)
end

function Captcha_OnRenZhengClicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then   --未绑定状态
		return
	end
		
	local szText = Captcha_RenzhengNum2_2:GetText();
	local nCode = tonumber(szText);
	if nCode == nil then
		PushDebugMessage("#{GZSZH_230427_11}")
		return
	end
	DataPool:DoFlagAMobileApprove( tostring(szText) )
end

function Captcha_InputCode_OnActived()
	local szText = Captcha_RenzhengNum2_2:GetText();
	if tonumber(szText) == nil then
		Captcha_RenzhengNum2_2:SetText("");
		Captcha_RenzhengNum2_2:SetProperty("MaxTextLength", "6")
	end
end

function Captcha_ApproveTimerProc()
	local strBtnText = ScriptGlobal_Format( "#{GZSZH_230427_06}", g_Captcha_SecurityCodeTime )
	g_Captcha_SecurityCodeTime = g_Captcha_SecurityCodeTime -1;
	if g_Captcha_SecurityCodeTime < 0 then
		Captcha_Button2_1:SetText( "#{GZSZH_230427_05}" )
		Captcha_Button2_1:Enable();
		KillTimer( "Captcha_ApproveTimerProc()" );
		return
	end
	Captcha_Button2_1:SetText( strBtnText )
end

function Captcha_SecurityCode_Msg( nErrCode )

	if nErrCode == 6 then		--一天50次超限制
		PushDebugMessage( "#{SJRZ_180827_29}");
	elseif nErrCode == 88 then --海外短信发送功能被关闭
		PushDebugMessage( "#{SJRZ_180827_30}")
	elseif nErrCode == 90 then --手机号处于黑名单
		PushDebugMessage( "#{SJRZ_180827_31}")
	elseif nErrCode == 98 then --服务器IP不在白名单中或者发送短信的IP受限
		PushDebugMessage( "#{SJRZ_180827_32}")
	else
		local strMsg =	ScriptGlobal_Format( "#{SJRZ_180827_28}", nErrCode)	
		PushDebugMessage(strMsg);
	end
	
end

function Captcha_On_ResetPos()
  Captcha_Frame:SetProperty("UnifiedPosition", g_Captcha_UnifiedPosition);
end

function Captcha_OnHide()
	--KillTimer( "Captcha_ApproveTimerProc()" );
end
