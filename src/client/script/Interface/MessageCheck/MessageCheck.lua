--MessageCheck
local g_MessageCheck_UnifiedPosition;
local g_MessageCheck_SecurityCodeTime = 0;
local g_MessageCheck_Status = 0;
local g_MessageCheck_BindPhone = 0;

function MessageCheck_PreLoad()
	this:RegisterEvent("CTU_OPEN_SMSCODE");
	this:RegisterEvent("CTU_CLOSE_SMSCODE");
	this:RegisterEvent("CTU_SMSCODE_SECURITYCODE")
	this:RegisterEvent("CTU_SMSCODE_APPROVE")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

function MessageCheck_OnLoad()
	g_MessageCheck_UnifiedPosition=MessageCheck_Frame:GetProperty("UnifiedPosition")
	
end

function MessageCheck_OnEvent(event)
	
	if (event == "CTU_OPEN_SMSCODE") then
		MessageCheck_Show( tonumber(arg0) )
		return 
		
	elseif (event == "CTU_CLOSE_SMSCODE") then
		MessageCheck_OnHide()
		return 
	
	--手机认证-获取验证码
	elseif (event == "CTU_SMSCODE_SECURITYCODE" ) then
		if ( tonumber(arg0) == 1 ) then
			g_MessageCheck_Status = 1
			PushDebugMessage("#{DXYZ_20240103_12}")
			MessageCheck_Text2_2:SetText("#{DXYZ_20240103_7}")
			MessageCheck_Button2:SetText("#{DXYZ_20240103_9}")
			MessageCheck_EditBox:Enable()
			MessageCheck_Button2:Enable()
		else
			PushDebugMessage("#{DXYZ_20240103_19}");
			MessageCheck_OnHide()

		end		
	
	--手机认证-认证
	elseif (event == "CTU_SMSCODE_APPROVE" ) then
		if ( tonumber(arg0) == 1 ) then
			PushDebugMessage("#{DXYZ_20240103_14}")
			MessageCheck_OnHide()
		else
			PushDebugMessage("#{DXYZ_20240103_13}")
			MessageCheck_Button2:SetText("#{DXYZ_20240103_9}")
			MessageCheck_EditBox:Enable()
			MessageCheck_Button2:Enable()
		end
	end
		
	if (event == "ADJEST_UI_POS") then
		MessageCheck_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		MessageCheck_On_ResetPos()
		return
	end

end

function MessageCheck_Show( bBindPhone )
	g_MessageCheck_BindPhone = bBindPhone
	if g_MessageCheck_BindPhone == 0 then
		ChangeBindPhoneWindow("hide")
		ChangeUnbindPhoneWindow("show")
	elseif g_MessageCheck_BindPhone == 1 then
		ChangeBindPhoneWindow("show")
		ChangeUnbindPhoneWindow("hide")
		MessageCheck_Text2_2:SetText("#{DXYZ_20240103_6}")		--请点击按钮获取验证码
		MessageCheck_Button2:SetText("#{DXYZ_20240103_8}")

	end
	g_MessageCheck_Status = 0;
	MessageCheck_EditBox:SetText("");
	MessageCheck_EditBox:Disable()
	MessageCheck_Button2:Enable()
	--倒计时
	g_MessageCheck_SecurityCodeTime = 120;
	MessageCheck_ApproveTimerProc()
	KillTimer( "MessageCheck_ApproveTimerProc()" );
	SetTimer("MessageCheck","MessageCheck_ApproveTimerProc()", 1000)
	
	this:Show()
end

--得到验证码
function MessageCheck_OnGetPhoneTextClicked()
	if g_MessageCheck_BindPhone == 0 then   --未绑定状态
		return
	end
	
	if g_MessageCheck_Status == 0 then
		DataPool:GetSMSCodeSecurityCode()
		MessageCheck_Button2:Disable()
	else
		local szText = MessageCheck_EditBox:GetText();
		local nCode = tonumber(szText);
		if nCode == nil then
			PushDebugMessage("#{DXYZ_20240103_13}")
			return
		end
		if string.len(szText) ~= 6 then
			PushDebugMessage("#{DXYZ_20240103_13}")
			return
		end
		DataPool:DoSMSCodeMobileApprove( tostring(szText) )
		MessageCheck_Button2:Disable()
		--this:Hide()
	end
	
end

function MessageCheck_InputCode_OnActived()
	local szText = MessageCheck_EditBox:GetText();
	MessageCheck_Text2_2:Hide()		--手机绑定文本控件
	if tonumber(szText) == nil then
		MessageCheck_EditBox:SetText("");
		MessageCheck_EditBox:SetProperty("MaxTextLength", "6")
	end
end

function MessageCheck_ApproveTimerProc()
	local strBtnText = ScriptGlobal_Format( "#{DXYZ_20240103_11}", g_MessageCheck_SecurityCodeTime )
	g_MessageCheck_SecurityCodeTime = g_MessageCheck_SecurityCodeTime -1;
	if g_MessageCheck_SecurityCodeTime < 0 then
		this:Hide();
		return
	end
	MessageCheck_Time2:SetText( strBtnText )
end

function MessageCheck_SecurityCode_Msg( nErrCode )

	if nErrCode == 6 then		--一天50次超限制
		PushDebugMessage( "#{DXYZ_20240103_15}");
	elseif nErrCode == 88 then --海外短信发送功能被关闭
		PushDebugMessage( "#{DXYZ_20240103_16}")
	elseif nErrCode == 90 then --手机号处于黑名单
		PushDebugMessage( "#{DXYZ_20240103_17}")
	elseif nErrCode == 98 then --服务器IP不在白名单中或者发送短信的IP受限
		PushDebugMessage( "#{DXYZ_20240103_18}")
	else
		-- local strMsg =	ScriptGlobal_Format( "#{SJRZ_180827_28}", nErrCode)	
		-- PushDebugMessage(strMsg);
	end
	
end

function MessageCheck_On_ResetPos()
  MessageCheck_Frame:SetProperty("UnifiedPosition", g_MessageCheck_UnifiedPosition);
end

function MessageCheck_OnHide()
	KillTimer( "MessageCheck_ApproveTimerProc()" );
	this:Hide()
end

function MessageCheck_OnChangePhoneClicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_CTUYZ"))
end

function ChangeBindPhoneWindow(changeState)
--手机绑定文本控件
	if changeState == "show" then
		MessageCheck_Text2_2:Show()
		MessageCheck_EditBox:Show()
		MessageCheck_Button2:Show()
	elseif changeState == "hide" then

		MessageCheck_Text2_2:Hide()
		MessageCheck_EditBox:Hide()
		MessageCheck_Button2:Hide()
	end
end

function ChangeUnbindPhoneWindow(changeState)
--手机未绑定文本控件
	if changeState == "show" then
		MessageCheck_Text1:Show()
		MessageCheck_Button1:Show()
	elseif changeState == "hide" then
		MessageCheck_Text1:Hide()
		MessageCheck_Button1:Hide()
	end
end