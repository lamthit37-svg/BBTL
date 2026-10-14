--认证手机界面--

-- 界面的默认相对位置
local g_SafeCenter_MobilePhone_Frame_UnifiedXPosition;
local g_SafeCenter_MobilePhone_Frame_UnifiedYPosition;
local g_SafeCenter_MobilePhone_SecurityCodeTime = 0;

function SafeCenter_MobilePhone_PreLoad()

	this:RegisterEvent("OPEN_SAFECENTER_MOBILEPHONE");
	this:RegisterEvent("OPEN_SAFECENTER_SAFESCORE");
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--更新认证手机状态
	this:RegisterEvent("UPDATE_ASKSCORE")
	this:RegisterEvent("MOBILEAPPROVE_SECURITYCODE",false)
	this:RegisterEvent("MOBILEAPPROVE_APPROVE",false)
	this:RegisterEvent("MOBILEAPPROVE_GETPRIZE",false)
	this:RegisterEvent("WEGAME_SAFECENTER_PHONE_UPDATE",false)

end	

function SafeCenter_MobilePhone_OnLoad()

	-- 保存界面的默认相对位置
	g_SafeCenter_MobilePhone_Frame_UnifiedXPosition	= SafeCenter_MobilePhone_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_MobilePhone_Frame_UnifiedYPosition	= SafeCenter_MobilePhone_Frame : GetProperty("UnifiedYPosition");
	
end

function SafeCenter_MobilePhone_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_MOBILEPHONE") then
		if( this:IsVisible() ) then
			return;
		else
			SafeCenter_MobilePhone_Open();
		end
	elseif ( event == "OPEN_SAFECENTER_SAFESCORE") then
		if GameProduceLogin:IsWeGameClient() <= 0 then
			return
		end
		if( this:IsVisible() ) then
			return;
		else
			local FirstOpenSafeCenterFlag = DataPool:GetFirstOpenSafeCenterFlag()
	    if( FirstOpenSafeCenterFlag  == 0 ) then
  	  	PushEvent("OPEN_SAFECENTER_MESSAGEBOX")
    		return
	    end
			SafeCenter_MobilePhone_Open();
		end
	
	elseif ( event == "WEGAME_SAFECENTER_PHONE_UPDATE") then
		if GameProduceLogin:IsWeGameClient() <= 0 then
			return
		end
		if( this:IsVisible() ) then
			SafeCenter_MobilePhone_Mobile_Show();
			return;
		end
		
	--手机认证-获取验证码
	elseif (event == "MOBILEAPPROVE_SECURITYCODE" ) then
		if GameProduceLogin:IsWeGameClient() > 0 then
			if ( tonumber(arg0) == 1 ) then
				PushDebugMessage("#{SJRZ_180827_16}");
				SafeCenter_MobilePhone_Mobile_Show();
			else
				SafeCenter_MobilePhone_SecurityCode_Msg(tonumber(arg1));
			end
		end		
	
	--手机认证-认证
	elseif (event == "MOBILEAPPROVE_APPROVE" ) then
		if GameProduceLogin:IsWeGameClient() > 0 then
			if ( tonumber(arg0) == 1 ) then
				PushDebugMessage("#{SJRZ_180827_24}");
				SafeCenter_MobilePhone_Mobile_Show();
			else
				PushDebugMessage("#{SJRZ_180827_18}");
			end
		end
		
	--手机认证-领奖
	elseif (event == "MOBILEAPPROVE_GETPRIZE" ) then
		if GameProduceLogin:IsWeGameClient() > 0 then
			if ( tonumber(arg0) == 1 ) then
				SafeCenter_MobilePhone_Mobile_Show();
			end
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then

	-- 更新背包界面位置
	    SafeCenter_MobilePhone_Frame_On_ResetPos();
    elseif (event == "UPDATE_ASKSCORE") then
    		--初始化手机认证按钮上的文字
  		if(GetApprovedPhoneFlag() == 1 ) then
    		SafeCenter_MobilePhone_HaveApprovePhone()
		elseif(GetApprovedPhoneFlag() == 0 ) then
			SafeCenter_MobilePhone_HaveModifyPhone()
		end

	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then

	-- 游戏分辨率发生了变化
		SafeCenter_MobilePhone_Frame_On_ResetPos();
	end

end	
--===============================================
-- 					界面切换
--===============================================
function SafeCenter_MobilePhone_OpenSafeScore()  --安全中心的起始界面(也就是安全模式界面)
      Variable:SetVariable("SelfUnionPos", SafeCenter_MobilePhone_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeScore();
end
function SafeCenter_MobilePhone_OpenSafePattern()
      Variable:SetVariable("SelfUnionPos", SafeCenter_MobilePhone_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafePattern();
end
function SafeCenter_MobilePhone_Open()

	CloseWindow("SafeCenter_SafeScore", true) 	 
	CloseWindow("SafeCenter_MobilePhone", true) 	 
	CloseWindow("SafeCenter_SafePattern", true) 
	CloseWindow("SafeCenter_MobilePhone", true)
	CloseWindow("SafeCenter_SafeTime", true)
	CloseWindow("SafeCenter_AccountProtection", true)
	CloseWindow("SafeCenter_SecondPassword", true)
	CloseWindow("SafeCenter_SafeCheck", true)
	CloseWindow("SafeCenter_LockUnlock", true)	  
	CloseWindow("SafeCenter_MessageBox", true) 
	
	if GameProduceLogin:IsWeGameClient() > 0 then
		SafeCenter_MobilePhone_WeGame_BackgroundRight_Frame:Show()
		SafeCenter_MobilePhone_BackgroundRight_Frame:Hide();
		SafeCenter_MobilePhone_MainButton_SafeScore:Disable();
		SafeCenter_MobilePhone_MainButton_SafePattern:Disable();
		SafeCenter_MobilePhone_MainButton_AccountProtection:Disable();
		SafeCenter_MobilePhone_MainButton_SafeCheck:Disable();
		SafeCenter_MobilePhone_BackgroundDown_Frame3:Hide()
		SafeCenter_MobilePhone_WeGame_BackgroundDown_Frame3:Show();
		
		DataPool:Lua_ClearPhoneApproveActionItem();
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(42) > 0 then
			DataPool:Lua_SetPhoneApproveActionItem( 0, 39923668 );
		elseif Player:GetData("IsOriginalJD") == 1 then
			DataPool:Lua_SetPhoneApproveActionItem( 0, 39924547 );
		elseif Player:GetData("Is2606S") == 1 then
			DataPool:Lua_SetPhoneApproveActionItem( 0, 39925289 );
		else
			DataPool:Lua_SetPhoneApproveActionItem( 0, 39921577 );
		end
		DataPool:Lua_UpdatePhoneApproveActionItem();
	
		SafeCenter_MobilePhone_Mobile_Show();
	else
		SafeCenter_MobilePhone_WeGame_BackgroundRight_Frame:Hide()
		SafeCenter_MobilePhone_BackgroundRight_Frame:Show();
		SafeCenter_MobilePhone_BackgroundDown_Frame3:Show()
		SafeCenter_MobilePhone_WeGame_BackgroundDown_Frame3:Hide();
	end
	     
	     SafeCenter_MobilePhone_Update()
	     SafeCenter_MobilePhone_UpdateFrame();
	     SafeCenter_MobilePhone_MainButton_MobilePhone:SetProperty("Selected", "True");
	     SafeCenter_MobilePhone_MainButton_MobilePhone:SetProperty("RiseOnClick", "Flase");
	     this:Show();

end
function SafeCenter_MobilePhone_OpenSafeTime()
      Variable:SetVariable("SelfUnionPos", SafeCenter_MobilePhone_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeTime();
end
function SafeCenter_MobilePhone_OpenAccountProtection()
      Variable:SetVariable("SelfUnionPos", SafeCenter_MobilePhone_Frame:GetProperty("UnifiedPosition"), 1);
      OpenAccountProtection();
end
function SafeCenter_MobilePhone_OpenSecondPassword()
      Variable:SetVariable("SelfUnionPos", SafeCenter_MobilePhone_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSecondPassword();
end
function SafeCenter_MobilePhone_OpenSafeCheck()
      Variable:SetVariable("SelfUnionPos", SafeCenter_MobilePhone_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeCheck();
end
function SafeCenter_MobilePhone_OpenLockUnlock()
      Variable:SetVariable("SelfUnionPos", SafeCenter_MobilePhone_Frame:GetProperty("UnifiedPosition"), 1);
      OpenLockUnlock();
end

----------------------------------------------
function SafeCenter_MobilePhone_UpdateFrame()
	 SafeCenter_MobilePhone_MainButton_SafeScore:SetProperty("Selected", "False");
	 SafeCenter_MobilePhone_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_MobilePhone_MainButton_SafePattern:SetProperty("Selected", "False");
	 SafeCenter_MobilePhone_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_MobilePhone_MainButton_AccountProtection:SetProperty("Selected", "False");	 
	 SafeCenter_MobilePhone_MainButton_SecondPassword:SetProperty("Selected", "False");
	 SafeCenter_MobilePhone_MainButton_SafeCheck:SetProperty("Selected", "False");
	 SafeCenter_MobilePhone_MainButton_LockUnlock:SetProperty("Selected", "False");	 	 
end

--得到当前UI位置
function SafeCenter_MobilePhone_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_MobilePhone_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end

--更新主界面位置
function SafeCenter_MobilePhone_Frame_On_ResetPos()
	-- body
	SafeCenter_MobilePhone_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_MobilePhone_Frame_UnifiedXPosition);
	SafeCenter_MobilePhone_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_MobilePhone_Frame_UnifiedYPosition);
end

--得到当前UI位置
function SafeCenter_MobilePhone_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_MobilePhone_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end


function SafeCenter_MobilePhone_ComfirmPhoneNumber_Clicked()
	
	if GameProduceLogin:IsWeGameClient() > 0 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_SJRZ"))
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_RZSJ"))
	end
end

-- 超链 安全中心官网
function SafeCenter_MobilePhone_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_MobilePhone_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_MobilePhone_KFZX_Clicked()
	if GameProduceLogin:IsWeGameClient() > 0 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_ANQUANZHONGXIN_KFZX"))
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
	end
end
--已认证手机
function SafeCenter_MobilePhone_HaveApprovePhone()
	SafeCenter_MobilePhone_Frame3_Lace2_Text:SetText("#{AQZX_130812_39}")
	SafeCenter_MobilePhone_Frame3_Button:SetText("#{AQZX_130812_141}")
end
--尚未认证
function SafeCenter_MobilePhone_HaveModifyPhone()
	SafeCenter_MobilePhone_Frame3_Lace2_Text:SetText("#{AQZX_130812_38}")
	SafeCenter_MobilePhone_Frame3_Button:SetText("#{AQZX_130812_140}")
end

-- 超链 认证手机
function SafeCenter_MobilePhone_WeGame_ApprovedPhoneNumber_Clicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then		--未绑定手机
		GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_SJRZ"))
	elseif nMobileApproveStatus == 1 then	--需要认证手机
		PushDebugMessage("需要认证手机")
	else  --已认证手机
		PushDebugMessage("已认证手机")
	end
end

--显示手机认证奖励界面
function SafeCenter_MobilePhone_Mobile_Show()
	SafeCenter_MobilePhone_WeGame_Frame1:Hide();
	SafeCenter_MobilePhone_WeGame_Frame2:Hide();
	SafeCenter_MobilePhone_WeGame_Frame3:Hide();
	if GameProduceLogin:IsWeGameClient() == 0 then
		return
	end
	
	local theAction = EnumAction(0, "phoneapprove_item");
	
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then		--未绑定手机
		SafeCenter_MobilePhone_WeGame_GetButton1:SetActionItem(theAction:GetID());
		SafeCenter_MobilePhone_WeGame_Frame1:Show();
	elseif nMobileApproveStatus == 1 then	--需要认证手机
		local szPhoneNumber = DataPool:GetMobilePhoneNumber();
		SafeCenter_MobilePhone_WeGame_ShouJiHaoNum2_2:SetText(szPhoneNumber);
		SafeCenter_MobilePhone_WeGame_GetButton2:SetActionItem(theAction:GetID());
		SafeCenter_MobilePhone_WeGame_Frame2:Show();
		
		local szText = SafeCenter_MobilePhone_WeGame_RenzhengNum2_2:GetText();
		if szText == nil or szText == "" then
			SafeCenter_MobilePhone_WeGame_RenzhengNum2_2:SetProperty("DefaultEditBox", "True");
		end
	else  --已认证手机
		SafeCenter_MobilePhone_WeGame_GetButton3:SetActionItem(theAction:GetID());
		SafeCenter_MobilePhone_WeGame_Frame3:Show();
		if nMobileApproveStatus == 2 then	--可领奖
			SafeCenter_MobilePhone_WeGame_Text:SetText("#{SJRZ_180827_25}");
			SafeCenter_MobilePhone_WeGame_Mask3:Hide();
		else
			SafeCenter_MobilePhone_WeGame_Text:SetText("#{SJRZ_180827_26}");
			SafeCenter_MobilePhone_WeGame_Mask3:Show();
		end
	end
end

--得到短信验证码
function SafeCenter_MobilePhone_WeGame_GetPhoneText_Clicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then   --未绑定状态
		PushDebugMessage("#{SJRZ_180827_13}")
		return
	end
	if nMobileApproveStatus > 1 then 	--已认证
		PushDebugMessage("#{SJRZ_180827_14}")
		return
	end

	DataPool:GetMobileApproveSecurityCode()
	
	SafeCenter_MobilePhone_WeGame_RenzhengNum2_2:SetProperty("DefaultEditBox", "True");
	SafeCenter_MobilePhone_WeGame_InputCode_OnActived();
	SafeCenter_MobilePhone_WeGame_Button2_1:Disable();
	g_SafeCenter_MobilePhone_SecurityCodeTime = 60;
	SafeCenter_MobilePhone_ApproveTimerProc();
	KillTimer( "SafeCenter_MobilePhone_ApproveTimerProc()" );
	SetTimer("SafeCenter_MobilePhone","SafeCenter_MobilePhone_ApproveTimerProc()", 1000)
end

--认证
function SafeCenter_MobilePhone_WeGame_RenZheng_Clicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then   --未绑定状态
		PushDebugMessage("#{SJRZ_180827_13}")
		return
	end
	if nMobileApproveStatus > 1 then 	--已认证
		PushDebugMessage("#{SJRZ_180827_14}")
		return
	end
	
	local szText = SafeCenter_MobilePhone_WeGame_RenzhengNum2_2:GetText();
	local nCode = tonumber(szText);
	if nCode == nil then
		PushDebugMessage("#{SJRZ_180827_17}")
		return
	end
	DataPool:DoMobileApprove( tostring(szText) )
end

--领奖
function SafeCenter_MobilePhone_WeGame_GetPrize_Clicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then   --未绑定状态
		PushDebugMessage("#{SJRZ_180827_19}")
		return
	end
	if nMobileApproveStatus == 1 then 	--未认证
		PushDebugMessage("#{SJRZ_180827_20}")
		return
	end
	if nMobileApproveStatus == 3 then 	--已领奖
		PushDebugMessage("#{SJRZ_180827_21}")
		return
	end
	DataPool:GetMobileApprovePrize()
end

function SafeCenter_MobilePhone_ApproveTimerProc()
	local strBtnText = ScriptGlobal_Format( "#{SJRZ_180827_08}", g_SafeCenter_MobilePhone_SecurityCodeTime )
	g_SafeCenter_MobilePhone_SecurityCodeTime = g_SafeCenter_MobilePhone_SecurityCodeTime -1;
	if g_SafeCenter_MobilePhone_SecurityCodeTime < 0 then
		SafeCenter_MobilePhone_WeGame_Button2_1:SetText( "#{SJRZ_180827_07}" )
		SafeCenter_MobilePhone_WeGame_Button2_1:Enable();
		KillTimer( "SafeCenter_MobilePhone_ApproveTimerProc()" );
		return
	end
	SafeCenter_MobilePhone_WeGame_Button2_1:SetText( strBtnText )
end

function SafeCenter_MobilePhone_WeGame_InputCode_OnActived()
	local szText = SafeCenter_MobilePhone_WeGame_RenzhengNum2_2:GetText();
	if tonumber(szText) == nil then
		SafeCenter_MobilePhone_WeGame_RenzhengNum2_2:SetText("");
		SafeCenter_MobilePhone_WeGame_RenzhengNum2_2:SetProperty("MaxTextLength", "6")
	end
end

function SafeCenter_MobilePhone_OnHiden()
	KillTimer( "SafeCenter_MobilePhone_ApproveTimerProc()" );
end

function SafeCenter_MobilePhone_SecurityCode_Msg( nErrCode )

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

function SafeCenter_MobilePhone_WeGame_Refresh_Clicked()
	AskMibaoStatus();
end
