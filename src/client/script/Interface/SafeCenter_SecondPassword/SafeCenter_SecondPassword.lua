--安全中心-二级密码--Manda2013-8-10

-- 界面默认相对位置
local g_SafeCenter_SecondPassword_Frame_UnifiedXPosition;
local g_SafeCenter_SecondPassword_Frame_UnifiedYPosition;

function SafeCenter_SecondPassword_PreLoad()

	this:RegisterEvent("OPEN_SAFECENTER_SECONDPASSWORD");
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变换
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 二级密码设置的相关事件
	this:RegisterEvent("MINORPASSWORD_OPEN_SET");
	-- 二级密码修改的相关事件
	this:RegisterEvent("MINORPASSWORD_OPEN_CHANGE");

end	

function SafeCenter_SecondPassword_OnLoad()

	-- 保存界面的默认相对位置
	g_SafeCenter_SecondPassword_Frame_UnifiedXPosition	= SafeCenter_SecondPassword_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_SecondPassword_Frame_UnifiedYPosition	= SafeCenter_SecondPassword_Frame : GetProperty("UnifiedYPosition");

end

function SafeCenter_SecondPassword_OnEvent(event)

	--打开界面 一个是从安全中心打开界面，另一个是其他途径打开界面(修改安全密码的情况)
	if  (event == "OPEN_SAFECENTER_SECONDPASSWORD" ) or 
		(event == 'MINORPASSWORD_OPEN_SET') or
		(event == 'MINORPASSWORD_OPEN_CHANGE') then 
		
		if( this:IsVisible() ) then
			return;
		else
			SafeCenter_SecondPassword_Open();
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
	-- 更新背包界面位置
	    SafeCenter_SecondPassword_Frame_On_ResetPos();
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
	-- 游戏分辨率发生了变化
		SafeCenter_SecondPassword_Frame_On_ResetPos();
	end

end	
--===============================================
-- 					界面切换
--===============================================
function SafeCenter_SecondPassword_OpenSafeScore()  --安全中心的起始界面(也就是安全评分界面)
     Variable:SetVariable("SelfUnionPos", SafeCenter_SecondPassword_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeScore();
end
function SafeCenter_SecondPassword_OpenSafePattern()  --安全模式界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SecondPassword_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafePattern();
end

function SafeCenter_SecondPassword_OpenMobilePhone()  --手机认证
      Variable:SetVariable("SelfUnionPos", SafeCenter_SecondPassword_Frame:GetProperty("UnifiedPosition"), 1);
      OpenMobilePhone();
end
function SafeCenter_SecondPassword_OpenSafeTime()  --安全时间
      Variable:SetVariable("SelfUnionPos", SafeCenter_SecondPassword_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeTime();
end
function SafeCenter_SecondPassword_OpenAccountProtection() --账号密保
      Variable:SetVariable("SelfUnionPos", SafeCenter_SecondPassword_Frame:GetProperty("UnifiedPosition"), 1);
      OpenAccountProtection();
end
function SafeCenter_SecondPassword_Open() --二级密码
	
	CloseWindow("SafeCenter_SafeScore", true) 	 
	CloseWindow("SafeCenter_SafePattern", true) 
	CloseWindow("SafeCenter_MobilePhone", true)
	CloseWindow("SafeCenter_SafeTime", true)
	CloseWindow("SafeCenter_AccountProtection", true)
	CloseWindow("SafeCenter_SecondPassword", true)
	CloseWindow("SafeCenter_SafeCheck", true)
	CloseWindow("SafeCenter_LockUnlock", true)	  
	CloseWindow("SafeCenter_MessageBox", true)
	
	if GameProduceLogin:IsWeGameClient() > 0 then
		SafeCenter_SecondPassword_WeGame_BackgroundRight_Frame:Show()
		SafeCenter_SecondPassword_BackgroundRight_Frame:Hide();
		SafeCenter_SecondPassword_MainButton_SafeScore:Disable();
		SafeCenter_SecondPassword_MainButton_SafePattern:Disable();
		SafeCenter_SecondPassword_MainButton_AccountProtection:Disable();
		SafeCenter_SecondPassword_MainButton_SafeCheck:Disable();
	else
		SafeCenter_SecondPassword_WeGame_BackgroundRight_Frame:Hide()
		SafeCenter_SecondPassword_BackgroundRight_Frame:Show();
	end

	SafeCenter_SecondPassword_Update();
	SafeCenter_SecondPassword_UpdateButtonSelected();
	SafeCenter_SecondPassword_MainButton_SecondPassword:SetProperty("Selected", "True");
	SafeCenter_SecondPassword_MainButton_SecondPassword:SetProperty("RiseOnClick", "Flase");
	SafeCenter_SecondPassword_InitDlg();
	this:Show();
end
function SafeCenter_SecondPassword_OpenSafeCheck() --安全验证
      Variable:SetVariable("SelfUnionPos", SafeCenter_SecondPassword_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeCheck();
end
function SafeCenter_SecondPassword_OpenLockUnlock() --加锁解锁
      Variable:SetVariable("SelfUnionPos", SafeCenter_SecondPassword_Frame:GetProperty("UnifiedPosition"), 1);
      OpenLockUnlock();
end

-----------------------------------------------

function SafeCenter_SecondPassword_InitDlg()

    local isSetMinorPwd = IsMinorPwdSetup();

    if(tonumber(isSetMinorPwd) == 1) then
        SafeCenter_SecondPassword_Change_Frame()
	else
		SafeCenter_SecondPassword_Setting_Frame()
	end

	SafeCenter_SecondPassword_Lace1_SimpleText:SetText( "#{AQZX_130812_95}"  );
	SafeCenter_SecondPassword_Frame7_2_Lace1_SimpleText:SetText( "#{AQZX_130812_95}"  );

end
--更新界面按钮
function SafeCenter_SecondPassword_UpdateButtonSelected()

	 SafeCenter_SecondPassword_MainButton_SecondPassword:SetProperty("Selected", "False");
	 SafeCenter_SecondPassword_MainButton_SafePattern:SetProperty("Selected", "False");
	 SafeCenter_SecondPassword_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_SecondPassword_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_SecondPassword_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_SecondPassword_MainButton_SecondPassword:SetProperty("Selected", "False");	 
	 SafeCenter_SecondPassword_MainButton_SafeCheck:SetProperty("Selected", "False");
	 SafeCenter_SecondPassword_MainButton_LockUnlock:SetProperty("Selected", "False");	

end

--更新主界面位置
function SafeCenter_SecondPassword_Frame_On_ResetPos()

	SafeCenter_SecondPassword_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_SecondPassword_Frame_UnifiedXPosition);
	SafeCenter_SecondPassword_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_SecondPassword_Frame_UnifiedYPosition);

end

--得到当前UI位置
function SafeCenter_SecondPassword_Update()

	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_SecondPassword_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end

end
----------------------二级密码设置相关----------------------------
--二级密码设置界面
function SafeCenter_SecondPassword_Setting_Frame()

    --设置处理
    SafeCenter_SecondPassword_BackgroundDown_Frame7_2:SetProperty("Visible" , "False" )
    SafeCenter_SecondPassword_BackgroundDown_Frame7:SetProperty("Visible" , "True" )

    SafeCenter_SecondPassword_Frame7_Text1:SetProperty("Visible" , "True" )
    SafeCenter_SecondPassword_Frame7_Text2:SetProperty("Visible" , "True" )

    SafeCenter_SecondPassword_Frame7_EditText1:SetProperty("Visible" , "True" )
    SafeCenter_SecondPassword_Frame7_EditText2:SetProperty("Visible" , "True" )

    SafeCenter_SecondPassword_Frame7_Button1:SetProperty("Visible" , "True" )

    SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey_Client:SetProperty("Visible" , "True");
    SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey:SetProperty("Visible" , "True");
    --解锁处理
	SafeCenter_SecondPassword_Frame7_2_Text1:SetProperty("Visible" , "False" )
	SafeCenter_SecondPassword_Frame7_2_Text2:SetProperty("Visible" , "False" )
	SafeCenter_SecondPassword_Frame7_2_Text3:SetProperty("Visible" , "False" )	

	SafeCenter_SecondPassword_Frame7_2_Button1:SetProperty("Visible" , "False" )	
	SafeCenter_SecondPassword_Frame7_2_Button2:SetProperty("Visible" , "False" )	

	SafeCenter_SecondPassword_Frame7_2_EditText1:SetProperty("Visible" , "False" )	
	SafeCenter_SecondPassword_Frame7_2_EditText2:SetProperty("Visible" , "False" )	
	SafeCenter_SecondPassword_Frame7_2_EditText3:SetProperty("Visible" , "False" )	

    SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey_Client:SetProperty("Visible" , "False" )
    SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey:SetProperty("Visible" , "False" )

                                                                              
    SafeCenter_SecondPassword_Frame7_EditText1:SetText( "" );
	SafeCenter_SecondPassword_Frame7_EditText2:SetText( "" );

	SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_EditText1" );

end

--设置按钮
function SafeCenter_SecondPassword_OK_Click()
	
	local strPassword1 = SafeCenter_SecondPassword_Frame7_EditText1:GetText();
	local strPassword2 = SafeCenter_SecondPassword_Frame7_EditText2:GetText();
	
	-- 如果密码不一致
	if(strPassword1 ~= strPassword2) then
		PushDebugMessage("#{AQZX_130812_101}")
		SafeCenter_SecondPassword_Frame7_EditText1:SetText( "" );
		SafeCenter_SecondPassword_Frame7_EditText2:SetText( "" );

		--设置光标位置
		SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_EditText1" );
		return
	end
	
	local iLen = string.len(strPassword1);
	if(iLen < 4) then
		ShowSystemTipInfo("新密码不能少于4个字符！");
		return;
	end;
	
	-- 如果密码不一致。发送改变密码消息。
	SendSetMinorPassword(tostring(strPassword1));
	this:Hide();

end

--输入时触发
function SafeCenter_SecondPassword_Input_OnActive()
	SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_EditText1" );
end
--确认时触发
function SafeCenter_SecondPassword_Confirm_OnActive()
	SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_EditText2" );
end

----------------------二级密码修改相关----------------------------
--调用二级密码解锁界面
function SafeCenter_SecondPassword_Change_Frame()

	SafeCenter_SecondPassword_BackgroundDown_Frame7_2:SetProperty("Visible" , "true" )
    SafeCenter_SecondPassword_BackgroundDown_Frame7:SetProperty("Visible" , "False" )

	SafeCenter_SecondPassword_Frame7_Text1:SetProperty("Visible" , "False" )
    SafeCenter_SecondPassword_Frame7_Text2:SetProperty("Visible" , "False" )

    SafeCenter_SecondPassword_Frame7_EditText1:SetProperty("Visible" , "False" )
    SafeCenter_SecondPassword_Frame7_EditText2:SetProperty("Visible" , "False" )

    SafeCenter_SecondPassword_Frame7_Button1:SetProperty("Visible" , "False" )

    SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey_Client:SetProperty("Visible" , "False");
    SafeCenter_SecondPassword_Frame7_SoftKeyBoard_SoftKey:SetProperty("Visible" , "False");

	SafeCenter_SecondPassword_Frame7_2_Text1:SetProperty("Visible" , "True" )
	SafeCenter_SecondPassword_Frame7_2_Text2:SetProperty("Visible" , "True" )
	SafeCenter_SecondPassword_Frame7_2_Text3:SetProperty("Visible" , "True" )	

	SafeCenter_SecondPassword_Frame7_2_Button1:SetProperty("Visible" , "True" )	
	SafeCenter_SecondPassword_Frame7_2_Button2:SetProperty("Visible" , "True" )	

	SafeCenter_SecondPassword_Frame7_2_EditText1:SetProperty("Visible" , "True" )	
	SafeCenter_SecondPassword_Frame7_2_EditText2:SetProperty("Visible" , "True" )	
	SafeCenter_SecondPassword_Frame7_2_EditText3:SetProperty("Visible" , "True" )	

    SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey_Client:SetProperty("Visible" , "True" )
    SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey:SetProperty("Visible" , "True" )

    SafeCenter_SecondPassword_Frame7_2_EditText3:SetText( "" );
	SafeCenter_SecondPassword_Frame7_2_EditText2:SetText( "" );
	SafeCenter_SecondPassword_Frame7_2_EditText1:SetText( "" );	

	SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_2_EditText1" );

end

function SafeCenter_SecondPassword_Before_OnActive()
	SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_2_EditText1" );
end
function SafeCenter_SecondPassword_After_OnActive()
	SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_2_EditText2" );
end
function SafeCenter_SecondPassword_After_Confirm_OnActive()
	SafeCenter_SecondPassword_Frame7_2_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SecondPassword_Frame7_2_EditText3" );
end




function SafeCenter_SecondPassword_Change_Click()

	-- 旧的密码
	local strPasswordOld = SafeCenter_SecondPassword_Frame7_2_EditText1:GetText();
	
	-- 新的密码
	local strPassword1 = SafeCenter_SecondPassword_Frame7_2_EditText2:GetText(); 
	local strPassword2 = SafeCenter_SecondPassword_Frame7_2_EditText3:GetText();

	
	if(strPassword1 ~= strPassword2) then
	
		PushDebugMessage("#{AQZX_130812_101}")
		SafeCenter_SecondPassword_Frame7_2_EditText3:SetText( "" );
		SafeCenter_SecondPassword_Frame7_2_EditText2:SetText( "" );
		SafeCenter_SecondPassword_Frame7_2_EditText1:SetText( "" );
		return
	end
	
	
	local iLenOld = string.len(strPasswordOld);
	local iLenNew = string.len(strPassword1);

	if(iLenOld < 4) then
		ShowSystemTipInfo("旧密码不能少于4个字符");
		return;
	end
	
	if(iLenNew < 4) then
		ShowSystemTipInfo("新密码不能少于4个字符！");
		return;
	end

	-- 如果密码一致。发送改变密码消息。
	ModifyMinorPassword(strPasswordOld, strPassword1);
	
	SafeCenter_SecondPassword_Frame7_2_EditText3:SetText( "" );
	SafeCenter_SecondPassword_Frame7_2_EditText2:SetText( "" );
	SafeCenter_SecondPassword_Frame7_2_EditText1:SetText( "" );
end

--强制解除
function SafeCenter_SecondPassword_Jiechu()

	-- 强制解除密码
	ForceUnLockMinorPassword();
	
	-- 隐藏窗口
	this:Hide();

end


-- 超链 安全中心官网
function SafeCenter_SecondPassword_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_SecondPassword_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_SecondPassword_KFZX_Clicked()
	if GameProduceLogin:IsWeGameClient() > 0 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_ANQUANZHONGXIN_KFZX"))
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
	end
end
