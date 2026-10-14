--SMSCode
local g_SMSCode2_UnifiedPosition;
local g_SMSCode2_SecurityCodeTime = 0;
local g_SMSCode2_ButtonCoolDown = 10;
local g_SMSCode2_BindPhone = 0;

function SMSCode2_PreLoad()
	this:RegisterEvent("CTU_OPEN_ASCENDINGCODE");
	this:RegisterEvent("CTU_CLOSE_ASCENDINGCODE")
	this:RegisterEvent("CTU_ASCENDINGCODE_APPROVE");

	this:RegisterEvent("SMSCODE_SECURITYCODE")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

function SMSCode2_OnLoad()
	g_SMSCode_UnifiedPosition=SMSCode2_Frame:GetProperty("UnifiedPosition")
	
end

function SMSCode2_OnEvent(event)
	if (event == "CTU_OPEN_ASCENDINGCODE") then
		SMSCode2_Show( tostring(arg0), tostring(arg1), tostring(arg2), tostring(arg3) )
		return 
		
	elseif (event == "CTU_CLOSE_ASCENDINGCODE") then
		SMSCode2_OnHide()
		return 
	--手机认证-认证
	elseif (event == "CTU_ASCENDINGCODE_APPROVE" ) then
		local nResult = tonumber(arg0)
		if nResult == 0 then
        	PushDebugMessage("#{YZGN_250114_5}")
			SMSCode2_OnHide()
		else
			SMSCode2_SecurityCode_Msg( nResult )
		end
	end
		
	if (event == "ADJEST_UI_POS") then
		SMSCode2_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		SMSCode2_On_ResetPos()
		return
	end

end

function SMSCode2_Show( nCheckCenterNum,nCheckCenterNumBak,PhoneNum,nCode )
	--未绑定则先把界面关了
	if nCheckCenterNum == "0" then
		g_SMSCode2_BindPhone = 0
		return
	end
	g_SMSCode2_BindPhone = PhoneNum
	local strBtnText = ScriptGlobal_Format( "#{YZGN_250114_3}", PhoneNum, string.sub(nCode, 1, 3).."#"..string.sub(nCode, 4, 7), nCheckCenterNum, nCheckCenterNumBak)

	SMSCode2_Result:SetText("")
	SMSCode2_Get:Enable();
	SMSCode2_Info_Des:SetText(strBtnText)
	--倒计时
	g_SMSCode2_SecurityCodeTime = 300;
	SMSCode2_ApproveTimerProc()
	KillTimer( "SMSCode2_ApproveTimerProc()" );
	SetTimer("SMSCode2","SMSCode2_ApproveTimerProc()", 1000)
	
	this:Show()
end

--得到验证码
function SMSCode2_ApproveButton_Click()
	if g_SMSCode2_BindPhone == 0 then   --未绑定状态
		return
	end
	
	DataPool:LuaFnApproveAscendingCode()
	SMSCode2_Result:SetText("#{YZGN_250114_4}")

	--点击验证后按钮进入冷却
	SMSCode2_Get:Disable()
	SMSCode2_ButtonCoolDownTimerProc()
	KillTimer( "SMSCode2_ButtonCoolDownTimerProc()" );
	SetTimer("SMSCode2","SMSCode2_ButtonCoolDownTimerProc()", 1000)
end

function SMSCode2_ApproveTimerProc()
	if g_SMSCode2_SecurityCodeTime >= 0 then
		local strBtnText = ScriptGlobal_Format( "#{YZGN_250114_11}", g_SMSCode2_SecurityCodeTime )
		g_SMSCode2_SecurityCodeTime = g_SMSCode2_SecurityCodeTime -1;
		SMSCode2_TimeLeft:SetText( strBtnText )
	else
		SMSCode2_OnHide()
		return
	end
end
function SMSCode2_ButtonCoolDownTimerProc()
	g_SMSCode2_ButtonCoolDown = g_SMSCode2_ButtonCoolDown -1;
	if g_SMSCode2_ButtonCoolDown < 0 then
		SMSCode2_Get:Enable()
		KillTimer( "SMSCode2_ButtonCoolDownTimerProc()");

		g_SMSCode2_ButtonCoolDown = 10
		return
	end
end

function SMSCode2_SecurityCode_Msg( nErrCode )
	if nErrCode == 1 then		--暂未收到短信
		PushDebugMessage( "#{YZGN_250114_8}");
		SMSCode2_Result:SetText("#{YZGN_250114_9}")
	elseif nErrCode == 2 then 	--验证码错误
		PushDebugMessage( "#{YZGN_250114_6}")
		SMSCode2_Result:SetText("#{YZGN_250114_7}")
	elseif nErrCode == 3 then 	--其他错误
		PushDebugMessage("#{YZGN_250114_8}")
		SMSCode2_Result:SetText("#{YZGN_250114_9}")

		-- PushDebugMessage( "#{SJRZ_180827_31}")
	else
		-- local strMsg =	ScriptGlobal_Format( "#{SJRZ_180827_28}", nErrCode)	
		-- PushDebugMessage(strMsg);
	end
	
end

function SMSCode2_On_ResetPos()
  SMSCode2_Frame:SetProperty("UnifiedPosition", g_SMSCode2_UnifiedPosition);
end

function SMSCode2_OnHide()
	this:Hide()
	KillTimer( "SMSCode2_ApproveTimerProc()" );
	KillTimer( "SMSCode2_ButtonCoolDownTimerProc()");

end

function SMSCode2_OnCustomerClicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGYOU_GM"))
end
