--安全中心起始界面(安全评分界面)--Manda 2013-8-1

-- 界面的默认相对位置

local g_SafeCenter_SafeScore_Frame_UnifiedXPosition;

local g_SafeCenter_SafeScore_Frame_UnifiedYPosition;

local Total_Score

local ScoreStr
local g_SafeCenter_SafeScore_SecurityCodeTime = 0;

-----------各个模块的得分 begin-------

local Zero_Score
local SafePattern_Score
local SafePattern_Score_NoMobilePhone 
local MobilePhone_Score  
local SecondPassword_Score   
local SecondPassword_Score_NoMobilePhone

--账号密保得分
local AccountProtection_Score    

--账号密保的子项
local PhoneMibao_Score  		
local HardMibao_Score    
local PhoneMibao_Score_NoMobilePhone 
local HardMibao_Score_NoMobilePhone 

--------------------------------------

local g_ActionButton = {}

local SafeScore_Mask = {}

local SafeScore_Star = {}

local g_StarStatus = {
						[1] = "set:SafeCenter_01 image:SafeCenter_EmptyStar",
						[2] = "set:SafeCenter_01 image:SafeCenter_OneStar",
						[3] = "set:SafeCenter_01 image:SafeCenter_HalfStar",
																}

local g_SafeScore = {
						[1] = "set:SafeCenter_01 image:SafeCenter_Score0",
						[2] = "set:SafeCenter_01 image:SafeCenter_Score10",
						[3] = "set:SafeCenter_01 image:SafeCenter_Score20",
						[4] = "set:SafeCenter_01 image:SafeCenter_Score30",
						[5] = "set:SafeCenter_01 image:SafeCenter_Score40",
						[6] = "set:SafeCenter_01 image:SafeCenter_Score50",
						[7] = "set:SafeCenter_01 image:SafeCenter_Score60",
						[8] = "set:SafeCenter_01 image:SafeCenter_Score70",
						[9] = "set:SafeCenter_01 image:SafeCenter_Score80",
						[10] = "set:SafeCenter_01 image:SafeCenter_Score90",
						[11] = "set:SafeCenter_01 image:SafeCenter_Score100",											
																}

function SafeCenter_SafeScore_PreLoad()
	--开启界面
	this:RegisterEvent("OPEN_SAFECENTER_SAFESCORE");

	-- 安全模式 状态更新
	this:RegisterEvent("UPDATE_AUTHORIZEDSAFEFLAG")
	-- 响应刷新评分
 	this:RegisterEvent("UPDATE_ASKSCORE")

 	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MOBILEAPPROVE_SECURITYCODE",false)
	this:RegisterEvent("MOBILEAPPROVE_APPROVE",false)
	this:RegisterEvent("MOBILEAPPROVE_GETPRIZE",false)
end	

function SafeCenter_SafeScore_OnLoad()

	-- 保存界面的默认相对位置
	g_SafeCenter_SafeScore_Frame_UnifiedXPosition	= SafeCenter_SafeScore_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_SafeScore_Frame_UnifiedYPosition	= SafeCenter_SafeScore_Frame : GetProperty("UnifiedYPosition");

	Total_Score 			 =  0 
	Zero_Score        		 =  0
	SafePattern_Score  		 = 10
	MobilePhone_Score  	     = 40
	SecondPassword_Score     = 10

	SafePattern_Score_NoMobilePhone = 20 
 	SecondPassword_Score_NoMobilePhone = 20	

	-------账号密保的子项--------
	PhoneMibao_Score  		 = 30
	HardMibao_Score          = 40

	PhoneMibao_Score_NoMobilePhone = 50
	HardMibao_Score_NoMobilePhone = 60
	------------------------------

	--账号密保得分
	--计算方式:MIN(40,HardMibao_Score*贴身密保绑定状态+PhoneMibao_Score*电话密保绑定状态)
	AccountProtection_Score  =  0 
	--领奖框
	g_ActionButton[0] =  SafeCenter_SafeScore_ActionButton1
	g_ActionButton[1] =  SafeCenter_SafeScore_ActionButton2
	g_ActionButton[2] =  SafeCenter_SafeScore_ActionButton3
	g_ActionButton[3] =  SafeCenter_SafeScore_ActionButton4

	SafeScore_Mask[0] = SafeCenter_SafeScore_Item1_Mask
	SafeScore_Mask[1] = SafeCenter_SafeScore_Item2_Mask
	SafeScore_Mask[2] = SafeCenter_SafeScore_Item3_Mask
	SafeScore_Mask[3] = SafeCenter_SafeScore_Item4_Mask

	--星星初始化
	SafeScore_Star[0] = SafeCenter_SafeScore_Star1
	SafeScore_Star[1] = SafeCenter_SafeScore_Star2
	SafeScore_Star[2] = SafeCenter_SafeScore_Star3
	SafeScore_Star[3] = SafeCenter_SafeScore_Star4
	SafeScore_Star[4] = SafeCenter_SafeScore_Star5

end

function SafeCenter_SafeScore_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_SAFESCORE") then
		if( this:IsVisible() ) then
			return
		else
			--同步客户端时间 for safecheck界面
			--二级密码验证的时候会用到 
			AskServerTimeAgain()

			SafeCenter_SafeScore_Open();
		end

	-- 刷新评分、刷新界面绑定状态
	elseif( event == "UPDATE_ASKSCORE")then
		Total_Score = tonumber(arg0);
		SafeCenter_SafeScore_UpdateFrame();

	-- 刷新领取周奖励显示(点击领取之后，刷新状态)
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 890643) then
		SafeCenter_SafeScore_UpdateFrame();
		
	--点击分页畅游+时候显示
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 2014090301) then
		local IsGetAward = tonumber(Get_XParam_INT(0))
		SafeCenter_SafeScore_CYJCONTENT_SHOW(IsGetAward)
	
	--领取奖励后刷新
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 2014090302) then
		local IsGetAward = tonumber(Get_XParam_INT(0))
		SafeCenter_SafeScore_CYJCONTENT_SHOW(IsGetAward)

	-- 授权模式 状态更新
	elseif (event == "UPDATE_AUTHORIZEDSAFEFLAG" ) then		
		if (arg0 == "1") then
			SafeCenter_SafeScore_SafePattenSatusIsOpened();
		elseif(arg0 == "0") then
			SafeCenter_SafeScore_SafePattenButtonIsClosed();		
		end
		
	--手机认证-获取验证码
	elseif (event == "MOBILEAPPROVE_SECURITYCODE" ) then
		if ( tonumber(arg0) == 1 ) then
			PushDebugMessage("#{SJRZ_180827_16}");
			SafeCenter_SafeScore_Mobile_Show();
		else
			SafeCenter_SafeScore_SecurityCode_Msg(tonumber(arg1));
		end		
	
	--手机认证-认证
	elseif (event == "MOBILEAPPROVE_APPROVE" ) then
		if ( tonumber(arg0) == 1 ) then
			PushDebugMessage("#{SJRZ_180827_24}");
			SafeCenter_SafeScore_Mobile_Show();
		else
			PushDebugMessage("#{SJRZ_180827_18}");
		end
	
	--手机认证-领奖
	elseif (event == "MOBILEAPPROVE_GETPRIZE" ) then
		if ( tonumber(arg0) == 1 ) then
			SafeCenter_SafeScore_Mobile_Show();
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		SafeCenter_SafeScore_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		SafeCenter_SafeScore_Frame_On_ResetPos();
	end
	
end	

--===============================================
-- 					切换界面
--===============================================
--打开评分界面 也就是主界面--
function SafeCenter_SafeScore_Open()

	if GameProduceLogin:IsWeGameClient() > 0 then
		return
	end

	CloseWindow("SafeCenter_SafeScore", true) 	 
	CloseWindow("SafeCenter_SafePattern", true) 
	CloseWindow("SafeCenter_MobilePhone", true)
	CloseWindow("SafeCenter_SafeTime", true)
	CloseWindow("SafeCenter_AccountProtection", true)
	CloseWindow("SafeCenter_SecondPassword", true)
	CloseWindow("SafeCenter_SafeCheck", true)
	CloseWindow("SafeCenter_LockUnlock", true)	  
	
	if GameProduceLogin:IsWeGameClient() > 0 then
		SafeCenter_SafeScore_WeGame_BackgroundRight_Frame:Show();
		SafeCenter_SafeScore_BackgroundRight_Frame:Hide();
	else
		SafeCenter_SafeScore_WeGame_BackgroundRight_Frame:Hide();
		SafeCenter_SafeScore_BackgroundRight_Frame:Show();
		
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
	end
		
	SafeCenter_SafeScore_RenzhengNum2_2:SetProperty("MaxTextLength", "20")
	SafeCenter_SafeScore_RenzhengNum2_2:SetText("请输入短信验证码");


	--判断是否是登陆后第一次开启 如果是则申请认证手机状态 调用
    --SafeCenterMessagebox窗口
    local FirstOpenSafeCenterFlag = DataPool:GetFirstOpenSafeCenterFlag()

    if( FirstOpenSafeCenterFlag  == 0 ) then
    	PushEvent("OPEN_SAFECENTER_MESSAGEBOX")
    	return
    end

	AskSafeScore()

    SafeCenter_SafeScore_Update()

	SafeCenter_SafeScore_UpdateFrame() 

    --Add by Manda 2013-12-26 
	--掌中宝

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()

	if IsApprovePhoneIsOpenFlag == 0 then
	   SafeCenter_SafeScore_BackgroundDown2_Frame:SetProperty("Visible","False")
	   SafeCenter_SafeScore_BackgroundDown2_Frame_NoMobile:SetProperty("Visible","True")
           SafeCenter_SafeScore_BackgroundDown3_Text2:SetText("#{AQZX140304_02}")	   
   	else
	   SafeCenter_SafeScore_BackgroundDown2_Frame:SetProperty("Visible","True")
	   SafeCenter_SafeScore_BackgroundDown2_Frame_NoMobile:SetProperty("Visible","False")	
	   SafeCenter_SafeScore_BackgroundDown3_Text2:SetText("#{AQZX_130812_132}")
	end
	
	--初始化电话密保 -----------------------Modify by s 2014-8-22
	--if(IsPhoneProtectSetup() == 0) then
		SafeCenter_SafeScore_BackgroundDown2_Frame_NoMSafe:SetProperty("Visible","True")
		SafeCenter_SafeScore_BackgroundDown2_Frame:SetProperty("Visible","False")
	--else
	--	SafeCenter_SafeScore_BackgroundDown2_Frame_NoMSafe:SetProperty("Visible","False")
	--	SafeCenter_SafeScore_BackgroundDown2_Frame:SetProperty("Visible","True")
	--end
	
	--畅游+周奖励初始化
	SafeCenter_SafeScore_CYJReward_Flag()
	if ( IsAppWareProtectSetup() ~= 1) then
		SafeCenter_SafeScore_CYJ_GetButton:Disable()
		SafeCenter_SafeScore_CYJ_Text2:SetText("#{CY+ZJ_140820_07}")
	end

	if Player:GetData("Is2606S") == 1 then
		SafeCenter_SafeScore_CYJ_Text3:SetText("#{QXF_260623_105}")
		SafeCenter_SafeScore_CYJ_GetButton_tips1:SetToolTip("#{QXF_260623_123}")
	else
		SafeCenter_SafeScore_CYJ_Text3:SetText("#{CY+ZJ_140820_06}")
		SafeCenter_SafeScore_CYJ_GetButton_tips1:SetToolTip("#{CY+ZJ_140820_17}")
	end
	
	this:Show()

end
--打开安全模式界面--
function SafeCenter_SafeScore_OpenPattern()
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafePattern();
end
--打开手机认证界面--
function SafeCenter_SafeScore_OpenMobilePhone()
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1);
      OpenMobilePhone();
end
--打开安全时间界面--
function SafeCenter_SafeScore_OpenSafeTime()
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeTime();
end
function SafeCenter_SafeScore_OpenAccountProtection()
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1);
      OpenAccountProtection();
end
function SafeCenter_SafeScore_OpenSecondPassword()
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSecondPassword();
end
function SafeCenter_SafeScore_OpenSafeCheck()
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeCheck();
end
function SafeCenter_SafeScore_OpenLockUnlock()
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1);
      OpenLockUnlock();
end
----------------------------------
--更新selected按键 在选择安全评分界面的时候调用--
function SafeCenter_SafeScore_UpdateFrame()

	 SafeCenter_SafeScore_MainButton_SafeScore:SetProperty("Selected", "True");  
	 SafeCenter_SafeScore_MainButton_SafeScore:SetProperty("RiseOnClick", "False");
	 SafeCenter_SafeScore_MainButton_SafePattern:SetProperty("Selected", "False");
	 SafeCenter_SafeScore_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_SafeScore_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_SafeScore_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_SafeScore_MainButton_SecondPassword:SetProperty("Selected", "False");
	 SafeCenter_SafeScore_MainButton_SafeCheck:SetProperty("Selected", "False");	 	 
	 SafeCenter_SafeScore_MainButton_LockUnlock:SetProperty("Selected", "False");

	 --设置 SafePattern Open/Close_Button 状态
	 if(GetAuthorizedSafeFlag() == 1) then
	 	SafeCenter_SafeScore_SafePattenSatusIsOpened()
	 elseif(GetAuthorizedSafeFlag() == 0) then
	 	SafeCenter_SafeScore_SafePattenButtonIsClosed()
	 end	 

	--初始化手机认证按钮上的文字
  	if(GetApprovedPhoneFlag() == 1) then
    	SafeCenter_SafeScore_ModificationPhoneNumber()
	elseif(GetApprovedPhoneFlag() == 0) then
		SafeCenter_SafeScore_ApprovedPhoneNumber()
	end

	--计算账号密保得分(账号密保包括硬件密保和电话密保，具体计算方法见TOP)
	SafeCenter_SafeScore_CalculateProMibaoScore()

	--Add by Manda 2013-12-26 
	--初始化掌中宝按钮上的文字
	if(IsAppWareProtectSetup() == 1) then
		SafeCenter_SafeScore_HaveAppWareProtected()
	else
	    SafeCenter_SafeScore_NotHaveAppWareProtected()
	end

	--初始化电话密保按钮上的文字
	--if(IsPhoneProtectSetup() == 0) then
		SafeCenter_SafeScore_BindPhoneMibao()
	--else
	--	SafeCenter_SafeScore_UnlockBindPhoneMibao()		
	--end	

	--初始化二级密码按钮上的文字
    local isSetMinorPwd = IsMinorPwdSetup();

    if(tonumber(isSetMinorPwd) == 1) then
    	SafeCenter_SafeScore_ModifySecondPwd()
	else
        SafeCenter_SafeScore_SettingSecondPwd()
	end

	--A区 星星上的悬空tips
	ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_04}", Total_Score)
	SafeCenter_SafeScore_BackgroundDown_Frame1_DefaultWindow1:SetToolTip(ScoreStr)	
	SafeCenter_SafeScore_ScorePhoto:SetToolTip(ScoreStr)	
	SafeCenter_SafeScore_BackgroundDown_ShowScoreTip:SetToolTip(ScoreStr)	
	--星星初始化
	for i=0,4 do
		SafeScore_Star[i]:SetProperty("Image",g_StarStatus[1])
	end

	--分数/星星 显示
	if(Total_Score == 0) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[1])
	elseif(Total_Score == 10) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[2])
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[3])
	elseif(Total_Score == 20) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[3])	
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	elseif(Total_Score == 30) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[4])	
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[3])	
	elseif(Total_Score == 40) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[5])	
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[2])		
	elseif(Total_Score == 50) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[6])	
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star3:SetProperty("Image",g_StarStatus[3])		
	elseif(Total_Score == 60) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[7])		
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star3:SetProperty("Image",g_StarStatus[2])			
	elseif(Total_Score == 70) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[8])	
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star3:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star4:SetProperty("Image",g_StarStatus[3])			
	elseif(Total_Score == 80) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[9])	
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star3:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star4:SetProperty("Image",g_StarStatus[2])		
	elseif(Total_Score == 90) then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[10])
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star3:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star4:SetProperty("Image",g_StarStatus[2])	
    SafeCenter_SafeScore_Star5:SetProperty("Image",g_StarStatus[3])	
	elseif(Total_Score == 100)then
	SafeCenter_SafeScore_ScorePhoto:SetProperty("Image",g_SafeScore[11])
	SafeCenter_SafeScore_Star1:SetProperty("Image",g_StarStatus[2])
	SafeCenter_SafeScore_Star2:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star3:SetProperty("Image",g_StarStatus[2])	
	SafeCenter_SafeScore_Star4:SetProperty("Image",g_StarStatus[2])	
    SafeCenter_SafeScore_Star5:SetProperty("Image",g_StarStatus[2])			
	end	

	
	SafeCenter_SafeScore_CYJ_Hide()
	SafeCenter_SafeScore_Show()
	SafeCenter_SafeScore_Mobile_Hide();
		
	--领奖物品更新
	--Ps:代表的SafeScore.txt中的行数。就一行所以为0.
	DataPool:Lua_UpdateSafeScoreBonusItem(0)

	for i = 0 , 3 do
		local theAction = EnumAction(i, "safescore_item");
		g_ActionButton[i]:SetActionItem(theAction:GetID());
	end

	--是否领过奖品
	local ret = DataPool:Lua_IsHaveGot_SafeScore_BonusItem()
	
	if (ret == 1) then		
		for i=0,3 do
			SafeScore_Mask[i]:SetProperty("Visible","true")	
		end
		SafeCenter_SafeScore_GetButton:Disable()
	else 	
		for i=0,3 do
			SafeScore_Mask[i]:SetProperty("Visible","False")	
		end
		SafeCenter_SafeScore_GetButton:Enable()		
	end
end

--得到当前UI位置
function SafeCenter_SafeScore_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_SafeScore_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end

--更新主界面位置
function SafeCenter_SafeScore_Frame_On_ResetPos()

	SafeCenter_SafeScore_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_SafeScore_Frame_UnifiedXPosition);
	SafeCenter_SafeScore_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_SafeScore_Frame_UnifiedYPosition);

end


--===============================================
-- 					安全评分
--===============================================
--A区域(评分区域)

function SafeCenter_SafeScore_FreshSafeScore()

	AskMibaoStatus();

end

--B区域

--授权模式 点击开启/关闭按钮
function SafeCenter_SafeScore_SafePattern_OpenOrClose_Click(  )
    
	--检查账号安全状态
	local g_SafeCheckIsOK = 1

	Variable:SetVariable("SelfUnionPos", SafeCenter_SafeScore_Frame:GetProperty("UnifiedPosition"), 1)

	g_SafeCheckIsOK = CheckPlayerAccountSafety()

	if(g_SafeCheckIsOK == 1) then

		--关闭->开启 
		if(GetAuthorizedSafeFlag() == 0) then
			--调用二次确认框
			PushEvent( "ATHORSECFRAME",0)
			return
		end

		--开启->关闭
		if(GetAuthorizedSafeFlag() == 1) then
			SetAuthorizedSafeFlag(0);		
			return
		end

	end
end

-- 二级密码 设置/修改
function SafeCenter_SafeScore_SettingMonitorPassword_Clicked( )
	SafeCenter_SafeScore_OpenSecondPassword()
end

-- 超链 认证手机
function SafeCenter_SafeScore_ApprovedPhoneNumber_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_RZSJ"))
end

-- 超链 电话密保
function SafeCenter_SafeScore_PhoneNumberMibao_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_DHMB"))
end
-- 超链 安全中心官网
function SafeCenter_SafeScore_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_SafeScore_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_SafeScore_KFZX_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
end

--超链 掌中宝
function SafeCenter_SafeScore_ZZB_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZZB"))
end


--分页显示安全评分、畅游+
function SafeCenter_SafeScore_BackgroundDown3Xin_GetClick(nIndex)
	if nIndex == 1 then
		--显示安全评分
		--隐藏畅游+领奖
		--隐藏手机认证界面
		SafeCenter_SafeScore_CYJ_Hide()
		SafeCenter_SafeScore_Show()
		SafeCenter_SafeScore_Mobile_Hide();
				
		DataPool:Lua_UpdateSafeScoreBonusItem(0)

		for i = 0 , 3 do
			local theAction = EnumAction(i, "safescore_item");
			g_ActionButton[i]:SetActionItem(theAction:GetID());
		end

		--是否领过奖品
		local ret = DataPool:Lua_IsHaveGot_SafeScore_BonusItem()
		
		if (ret == 1) then		
			for i=0,3 do
				SafeScore_Mask[i]:SetProperty("Visible","true")	
			end
			SafeCenter_SafeScore_GetButton:Disable()
		else 	
			for i=0,3 do
				SafeScore_Mask[i]:SetProperty("Visible","False")	
			end
			SafeCenter_SafeScore_GetButton:Enable()		
		end
	end
	
	if nIndex == 2 then

		--是否领过奖品		
		SafeCenter_SafeScore_Hide()		
		SafeCenter_SafeScore_CYJ_Show()
		SafeCenter_SafeScore_Mobile_Hide();
	end	
	
	if nIndex == 3 then
		SafeCenter_SafeScore_Hide()		
		SafeCenter_SafeScore_CYJ_Hide()
		SafeCenter_SafeScore_Mobile_Show();
	end
end

--C区 领奖
function SafeCenter_SafeScore_GetClick()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SafeScoreGetBonus")  --脚本接口
		Set_XSCRIPT_ScriptID(890643) --脚本编号 g_CurrentSelect
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--畅游+领奖
function SafeCenter_SafeScore_CYJ_GetClick()
	if ( IsAppWareProtectSetup() ~= 1) then
		PushDebugMessage("#{CY+ZJ_140820_11}")
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SafeScoreCyjBonus")  --脚本接口
			Set_XSCRIPT_ScriptID(890910) --脚本编号 g_CurrentSelect
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--畅游+已经领奖
function SafeCenter_SafeScore_CYJYiLing_GetClick()
	PushDebugMessage("#{CY+ZJ_140820_10}")
end

--畅游+是否领奖
function SafeCenter_SafeScore_CYJReward_Flag()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CheckCyjAward")  --脚本接口
		Set_XSCRIPT_ScriptID(890910) --脚本编号 g_CurrentSelect
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

-----辅助函数：刷新按钮文字、刷新Frame文字 begin

--关闭安全模式
function SafeCenter_SafeScore_SafePattenSatusIsOpened( )

	--认证手机开启的情况
    SafeCenter_SafeScore_Button1:SetText("#{AQZX_130812_139}")
	SafeCenter_SafeScore_Button1_NoMSafe:SetText("#{AQZX_130812_139}")
	SafeCenter_SafeScore_Simpletext1:SetText("#{AQZX_130812_07}")
	SafeCenter_SafeScore_Simpletext1_NoMSafe:SetText("#{AQZX_130812_07}")
	ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_06}", Zero_Score)
	SafeCenter_SafeScore_Text1:SetText(ScoreStr)

	--认证手机关闭的情况
	SafeCenter_SafeScore_Button1_NoMobile:SetText("#{AQZX_130812_139}")
	SafeCenter_SafeScore_Simpletext1_NoMobile:SetText("#{AQZX_130812_164}")
	SafeCenter_SafeScore_Text1_NoMobile:SetText(ScoreStr)

	SafeCenter_SafeScore_Text1_NoMSafe:SetText(ScoreStr)

end

--打开安全模式
function SafeCenter_SafeScore_SafePattenButtonIsClosed( )

    SafeCenter_SafeScore_Button1:SetText("#{AQZX_130812_138}")
	SafeCenter_SafeScore_Button1_NoMSafe:SetText("#{AQZX_130812_138}")
	SafeCenter_SafeScore_Simpletext1:SetText("#{AQZX_130812_08}")
	SafeCenter_SafeScore_Simpletext1_NoMSafe:SetText("#{AQZX_130812_08}")

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()

	--认证手机服务关闭
	if IsApprovePhoneIsOpenFlag == 0 then
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_163}", SafePattern_Score_NoMobilePhone)
	else
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_06}", SafePattern_Score)
	end

	SafeCenter_SafeScore_Text1:SetText(ScoreStr)
	SafeCenter_SafeScore_Button1_NoMobile:SetText("#{AQZX_130812_138}")
	SafeCenter_SafeScore_Simpletext1_NoMobile:SetText("#{AQZX_130812_165}")
	SafeCenter_SafeScore_Text1_NoMobile:SetText(ScoreStr)

	SafeCenter_SafeScore_Text1_NoMSafe:SetText(ScoreStr)

end

--已认证
function SafeCenter_SafeScore_ApprovedPhoneNumber()

	SafeCenter_SafeScore_Button2:SetText("#{AQZX_130812_140}")
	SafeCenter_SafeScore_Button2_NoMSafe:SetText("#{AQZX_130812_140}")
	SafeCenter_SafeScore_Simpletext2:SetText("#{AQZX_130812_13}")
	SafeCenter_SafeScore_Simpletext2_NoMSafe:SetText("#{AQZX_130812_13}")
	ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_12}", Zero_Score)
	SafeCenter_SafeScore_Text2:SetText(ScoreStr)	

	SafeCenter_SafeScore_Text2_NoMSafe:SetText(ScoreStr)
	

end

--未认证
function SafeCenter_SafeScore_ModificationPhoneNumber()

	SafeCenter_SafeScore_Button2:SetText("#{AQZX_130812_141}")
	SafeCenter_SafeScore_Button2_NoMSafe:SetText("#{AQZX_130812_141}")
	SafeCenter_SafeScore_Simpletext2:SetText("#{AQZX_130812_14}")
	SafeCenter_SafeScore_Simpletext2_NoMSafe:SetText("#{AQZX_130812_14}")
	ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_12}", MobilePhone_Score)
	SafeCenter_SafeScore_Text2:SetText(ScoreStr)	

	SafeCenter_SafeScore_Text2_NoMSafe:SetText(ScoreStr)

end



--设置二级密码
function SafeCenter_SafeScore_SettingSecondPwd()

	SafeCenter_SafeScore_Button4:SetText("#{AQZX_130812_142}")
	SafeCenter_SafeScore_Button4_NoMSafe:SetText("#{AQZX_130812_142}")
	SafeCenter_SafeScore_Simpletext5:SetText("#{AQZX_130812_22}")
	SafeCenter_SafeScore_Simpletext5_NoMSafe:SetText("#{AQZX_130812_22}")

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()
	
	if IsApprovePhoneIsOpenFlag == 0 then
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_171}", Zero_Score)
	else
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_20}", Zero_Score)
	end	
	SafeCenter_SafeScore_Text4:SetText(ScoreStr)	

	SafeCenter_SafeScore_Button4_NoMobile:SetText("#{AQZX_130812_142}")	
	SafeCenter_SafeScore_Simpletext5_NoMobile:SetText("#{AQZX_130812_173}")
	SafeCenter_SafeScore_Text4_NoMobile:SetText(ScoreStr)


	SafeCenter_SafeScore_Text4_NoMSafe:SetText(ScoreStr)

end

--修改二级密码
function SafeCenter_SafeScore_ModifySecondPwd(  )

	SafeCenter_SafeScore_Button4:SetText("#{AQZX_130812_141}")
	SafeCenter_SafeScore_Button4_NoMSafe:SetText("#{AQZX_130812_141}")
	SafeCenter_SafeScore_Simpletext5:SetText("#{AQZX_130812_21}")
	SafeCenter_SafeScore_Simpletext5_NoMSafe:SetText("#{AQZX_130812_21}")

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()


	--认证手机服务关闭
	if IsApprovePhoneIsOpenFlag == 0 then
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_171}", SecondPassword_Score_NoMobilePhone)
	else
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_20}", SecondPassword_Score)
	end	
	
	SafeCenter_SafeScore_Text4:SetText(ScoreStr)	

	SafeCenter_SafeScore_Button4_NoMobile:SetText("#{AQZX_130812_142}")
	SafeCenter_SafeScore_Simpletext5_NoMobile:SetText("#{AQZX_130812_172}")
	SafeCenter_SafeScore_Text4_NoMobile:SetText(ScoreStr)


	SafeCenter_SafeScore_Text4_NoMSafe:SetText(ScoreStr)

end

--已绑定掌中宝
function SafeCenter_SafeScore_HaveAppWareProtected()

	SafeCenter_SafeScore_Button3_Zhangzhongbao:SetText("#{AQZX_130812_144}")
	SafeCenter_SafeScore_Button3_Zhangzhongbao_NoMSafe:SetText("#{AQZX_130812_144}")
	SafeCenter_SafeScore_Simpletext3_Zhangzhongbao:SetText("#{ZZB_131213_01}")
	SafeCenter_SafeScore_Simpletext3_Zhangzhongbao_NoMSafe:SetText("#{ZZB_131213_01}")

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()

    --认证手机服务关闭
	if IsApprovePhoneIsOpenFlag == 0 then
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_166}", AccountProtection_Score)
	else
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_15}", AccountProtection_Score)
	end
	SafeCenter_SafeScore_Text3:SetText(ScoreStr)	

	SafeCenter_SafeScore_Button3_Zhangzhongbao_NoMobile:SetText("#{AQZX_130812_144}")
	SafeCenter_SafeScore_Simpletext3_Zhangzhongbao_NoMobile:SetText("#{AQZX_130812_174}")
	SafeCenter_SafeScore_Text3_NoMobile:SetText(ScoreStr)



	SafeCenter_SafeScore_Text3_NoMSafe:SetText(ScoreStr)

end

--未绑定绑掌中宝
function SafeCenter_SafeScore_NotHaveAppWareProtected()

	SafeCenter_SafeScore_Button3_Zhangzhongbao:SetText("#{AQZX_130812_143}")
	SafeCenter_SafeScore_Button3_Zhangzhongbao_NoMSafe:SetText("#{AQZX_130812_143}")
	SafeCenter_SafeScore_Simpletext3_Zhangzhongbao:SetText("#{ZZB_131213_02}")
	SafeCenter_SafeScore_Simpletext3_Zhangzhongbao_NoMSafe:SetText("#{ZZB_131213_02}")

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()

    --认证手机服务关闭
	if IsApprovePhoneIsOpenFlag == 0 then
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_166}", AccountProtection_Score)
	else
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_15}", AccountProtection_Score)
	end
	SafeCenter_SafeScore_Text3:SetText(ScoreStr)	

	SafeCenter_SafeScore_Button3_Zhangzhongbao_NoMobile:SetText("#{AQZX_130812_143}")
	SafeCenter_SafeScore_Simpletext3_Zhangzhongbao_NoMobile:SetText("#{AQZX_130812_175}")
	SafeCenter_SafeScore_Text3_NoMobile:SetText(ScoreStr)



	SafeCenter_SafeScore_Text3_NoMSafe:SetText(ScoreStr)

end
--绑定电话密保
function SafeCenter_SafeScore_BindPhoneMibao()

	SafeCenter_SafeScore_Button3_2:SetText("#{AQZX_130812_143}")
	SafeCenter_SafeScore_Simpletext3_2:SetText("#{AQZX_130812_19}")

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()

    --认证手机服务关闭
	if IsApprovePhoneIsOpenFlag == 0 then
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_166}", AccountProtection_Score)
	else
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_15}", AccountProtection_Score)
	end
	SafeCenter_SafeScore_Text3:SetText(ScoreStr)	

	SafeCenter_SafeScore_Button3_2_NoMobile:SetText("#{AQZX_130812_143}")
	SafeCenter_SafeScore_Simpletext3_2_NoMobile:SetText("#{AQZX_140306_02}")	
	SafeCenter_SafeScore_Text3_NoMobile:SetText(ScoreStr)



	SafeCenter_SafeScore_Text3_NoMSafe:SetText(ScoreStr)

end

--解绑电话密保
function SafeCenter_SafeScore_UnlockBindPhoneMibao()

	SafeCenter_SafeScore_Button3_2:SetText("#{AQZX_130812_144}")
	SafeCenter_SafeScore_Simpletext3_2:SetText("#{AQZX_130812_18}")

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()

    --认证手机服务关闭
	if IsApprovePhoneIsOpenFlag == 0 then
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_166}", AccountProtection_Score)
	else
		ScoreStr = ScriptGlobal_Format( "#{AQZX_130812_15}", AccountProtection_Score)
	end
	SafeCenter_SafeScore_Text3:SetText(ScoreStr)	

	SafeCenter_SafeScore_Button3_2_NoMobile:SetText("#{AQZX_130812_144}")
	SafeCenter_SafeScore_Simpletext3_2_NoMobile:SetText("#{AQZX_140306_01}")	
	SafeCenter_SafeScore_Text3_NoMobile:SetText(ScoreStr)



	SafeCenter_SafeScore_Text3_NoMSafe:SetText(ScoreStr)

end

--计算账号密保得分
function SafeCenter_SafeScore_CalculateProMibaoScore()

	--local bHavePhoneMibao = IsPhoneProtectSetup(); 
	local bHaveAppProtected = IsAppWareProtectSetup();

	local IsApprovePhoneIsOpenFlag = DataPool:GetMobilePhoneConfigFlag()

	--认证手机服务关闭
	if IsApprovePhoneIsOpenFlag == 0 then
		if (bHaveAppProtected == 1) then
			AccountProtection_Score =  HardMibao_Score_NoMobilePhone;
		else
			AccountProtection_Score = Zero_Score
			--if(bHavePhoneMibao == 1) then
			--	AccountProtection_Score = PhoneMibao_Score_NoMobilePhone;
			--end
		end	
	else
	--认证手机服务开启
		if (bHaveAppProtected == 1) then
			AccountProtection_Score =  HardMibao_Score;
		else
			AccountProtection_Score = Zero_Score
			--if(bHavePhoneMibao == 1) then
			--	AccountProtection_Score = PhoneMibao_Score;
			--end
		end	
	end



end
---账号密保部分--end

--显示畅游+领奖账号界面
function SafeCenter_SafeScore_CYJCONTENT_SHOW( IsGetReward )
	local IsBindCyj = IsAppWareProtectSetup()
	if IsBindCyj ~= 1 then
		--没有绑定
		SafeCenter_SafeScore_CYJ_Text2:SetText("#{CY+ZJ_140820_07}")
		SafeCenter_SafeScore_CYJ_GetButton:SetProperty("DisabledImage","set:ButtonGemFQ image:ButtonCYJTGLJ_Disabled")
		SafeCenter_SafeScore_CYJ_GetButton:Disable()	
		SafeCenter_SafeScore_ItemYiLing_Mask:SetProperty("Visible","False")
	elseif IsGetReward ~= 1 and IsBindCyj == 1 then
		--绑定没有领取
		SafeCenter_SafeScore_CYJ_Text2:SetText("#{CY+ZJ_140820_04}")
		SafeCenter_SafeScore_CYJ_GetButton:SetProperty("DisabledImage","set:ButtonGemFQ image:ButtonCYJTGLJ_Disabled")
		SafeCenter_SafeScore_CYJ_GetButton:Enable()
		SafeCenter_SafeScore_ItemYiLing_Mask:SetProperty("Visible","False")
		SafeCenter_SafeScore_CYJ_GetButton:SetToolTip("#{CY+ZJ_140820_05}")
		if Player:GetData("Is2606S") == 1 then
			SafeCenter_SafeScore_CYJ_GetButton:SetToolTip("#{QXF_260623_122}")
		end
		
	elseif IsGetReward == 1 and IsBindCyj == 1 then
		--绑定且领取
		SafeCenter_SafeScore_CYJ_Text2:SetText("#{CY+ZJ_140820_08}")
		SafeCenter_SafeScore_CYJ_GetButton:Disable()
		SafeCenter_SafeScore_CYJ_GetButton:SetProperty("DisabledImage","set:ButtonGemFQ image:ButtonCYJTGLJ_LingJiang")
		SafeCenter_SafeScore_ItemYiLing_Mask:SetProperty("Visible","true")
	end
end

--隐藏安全评分界面
function SafeCenter_SafeScore_Hide()
	SafeCenter_SafeScore_GetButton:Hide()
	SafeCenter_SafeScore_BackgroundDown3_Frame:SetProperty("Visible","False")
	SafeCenter_SafeScore_BackgroundDown3_Text2:SetProperty("Visible","False")
	SafeCenter_SafeScore_ActionButton1:SetProperty("Visible","False")
	SafeCenter_SafeScore_ActionButton2:SetProperty("Visible","False")
	SafeCenter_SafeScore_ActionButton3:SetProperty("Visible","False")
	SafeCenter_SafeScore_ActionButton4:SetProperty("Visible","False")	
end

--显示安全评分界面
function SafeCenter_SafeScore_Show()
	SafeCenter_SafeScore_GetButton:Show()
	SafeCenter_SafeScore_BackgroundDown3_Frame:SetProperty("Visible","true")
	SafeCenter_SafeScore_BackgroundDown3_Text2:SetProperty("Visible","true")
	SafeCenter_SafeScore_ActionButton1:SetProperty("Visible","true")
	SafeCenter_SafeScore_ActionButton2:SetProperty("Visible","true")
	SafeCenter_SafeScore_ActionButton3:SetProperty("Visible","true")
	SafeCenter_SafeScore_ActionButton4:SetProperty("Visible","true")
	
	
end

--隐藏畅游+领奖界面
function SafeCenter_SafeScore_CYJ_Hide()
	SafeCenter_SafeScore_CYJ_GetButton:Hide()
	SafeCenter_SafeScore_CYJ_GetButtonYiLing:Hide()
	SafeCenter_SafeScore_CYJ_Frame:SetProperty("Visible","False")
	SafeCenter_SafeScore_CYJ_Text1:SetProperty("Visible","False")
	SafeCenter_SafeScore_CYJ_Frame2:SetProperty("Visible","False")
	SafeCenter_SafeScore_CYJ_Text2:SetProperty("Visible","False")
	SafeCenter_SafeScore_CYJ_Frame3:SetProperty("Visible","False")
	SafeCenter_SafeScore_CYJ_Text3:SetProperty("Visible","False")
end

--显示畅游+领奖界面
function SafeCenter_SafeScore_CYJ_Show()
	SafeCenter_SafeScore_CYJ_GetButton:Show()
	SafeCenter_SafeScore_CYJ_Frame:SetProperty("Visible","true")
	SafeCenter_SafeScore_CYJ_Text1:SetProperty("Visible","true")
	SafeCenter_SafeScore_CYJ_Frame2:SetProperty("Visible","true")
	SafeCenter_SafeScore_CYJ_Text2:SetProperty("Visible","true")
	SafeCenter_SafeScore_CYJ_Frame3:SetProperty("Visible","true")
	SafeCenter_SafeScore_CYJ_Text3:SetProperty("Visible","true")
end

--隐藏手机认证奖励界面
function SafeCenter_SafeScore_Mobile_Hide()
	SafeCenter_SafeScore_MobilePhone_Frame1:Hide();
	SafeCenter_SafeScore_MobilePhone_Frame2:Hide();
	SafeCenter_SafeScore_MobilePhone_Frame3:Hide();
end

--显示手机认证奖励界面
function SafeCenter_SafeScore_Mobile_Show()
	SafeCenter_SafeScore_MobilePhone_Frame1:Hide();
	SafeCenter_SafeScore_MobilePhone_Frame2:Hide();
	SafeCenter_SafeScore_MobilePhone_Frame3:Hide();
	
	local theAction = EnumAction(0, "phoneapprove_item");
	
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
			
	if nMobileApproveStatus == 0 then		--未绑定手机
		SafeCenter_SafeScore_MobilePhone_GetButton1:SetActionItem(theAction:GetID());
		SafeCenter_SafeScore_MobilePhone_Frame1:Show();
	elseif nMobileApproveStatus == 1 then	--需要认证手机
		local szPhoneNumber = DataPool:GetMobilePhoneNumber();
		SafeCenter_SafeScore_ShouJiHaoNum2_2:SetText(szPhoneNumber);
		SafeCenter_SafeScore_MobilePhone_GetButton2:SetActionItem(theAction:GetID());
		SafeCenter_SafeScore_MobilePhone_Frame2:Show();
		
		local szText = SafeCenter_SafeScore_RenzhengNum2_2:GetText();
		if szText == nil or szText == "" then
			SafeCenter_SafeScore_RenzhengNum2_2:SetProperty("MaxTextLength", "20")
			SafeCenter_SafeScore_RenzhengNum2_2:SetText("请输入短信验证码");
		end
	
	else  --已认证手机
		SafeCenter_SafeScore_MobilePhone_GetButton3:SetActionItem(theAction:GetID());
		SafeCenter_SafeScore_MobilePhone_Frame3:Show();
		if nMobileApproveStatus == 2 then	--可领奖
			SafeCenter_SafeScore_Text:SetText("#{SJRZ_180827_25}");
			SafeCenter_SafeScore_MobilePhone_Mask3:Hide();
		else
			SafeCenter_SafeScore_Text:SetText("#{SJRZ_180827_26}");
			SafeCenter_SafeScore_MobilePhone_Mask3:Show();
		end
	end
	
end

-----辅助函数：刷新按钮文字、刷新Frame文字 end

--得到短信验证码
function SafeCenter_SafeScore_GetPhoneText_Clicked()
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
	
	SafeCenter_SafeScore_RenzhengNum2_2:SetProperty("DefaultEditBox", "True");
	SafeCenter_SafeScore_InputCode_OnActived();
	SafeCenter_SafeScore_MobilePhone_Button2_1:Disable();
	g_SafeCenter_SafeScore_SecurityCodeTime = 60;
	SafeCenter_SafeScore_ApproveTimerProc();
	KillTimer( "SafeCenter_SafeScore_ApproveTimerProc()" );
	SetTimer("SafeCenter_SafeScore","SafeCenter_SafeScore_ApproveTimerProc()", 1000)
end

--认证
function SafeCenter_SafeScore_RenZheng_Clicked()
	local nMobileApproveStatus = DataPool:GetMobileApproveStatus();
	if nMobileApproveStatus == 0 then   --未绑定状态
		PushDebugMessage("#{SJRZ_180827_13}")
		return
	end
	if nMobileApproveStatus > 1 then 	--已认证
		PushDebugMessage("#{SJRZ_180827_14}")
		return
	end
	
	local szText = SafeCenter_SafeScore_RenzhengNum2_2:GetText();
	local nCode = tonumber(szText);
	if nCode == nil then
		PushDebugMessage("#{SJRZ_180827_17}")
		return
	end
	DataPool:DoMobileApprove( tostring(szText) )
end

--领奖
function SafeCenter_SafeScore_Mobile_GetPrize_Clicked()
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

function SafeCenter_SafeScore_ApproveTimerProc()
	local strBtnText = ScriptGlobal_Format( "#{SJRZ_180827_08}", g_SafeCenter_SafeScore_SecurityCodeTime )
	g_SafeCenter_SafeScore_SecurityCodeTime = g_SafeCenter_SafeScore_SecurityCodeTime -1;
	if g_SafeCenter_SafeScore_SecurityCodeTime < 0 then
		SafeCenter_SafeScore_MobilePhone_Button2_1:SetText( "#{SJRZ_180827_07}" )
		SafeCenter_SafeScore_MobilePhone_Button2_1:Enable();
		KillTimer( "SafeCenter_SafeScore_ApproveTimerProc()" );
		return
	end
	SafeCenter_SafeScore_MobilePhone_Button2_1:SetText( strBtnText )
end

function SafeCenter_SafeScore_InputCode_OnActived()
	local szText = SafeCenter_SafeScore_RenzhengNum2_2:GetText();
	if tonumber(szText) == nil then
		SafeCenter_SafeScore_RenzhengNum2_2:SetText("");
		SafeCenter_SafeScore_RenzhengNum2_2:SetProperty("MaxTextLength", "6")
	end
end

function SafeCenter_SafeScore_OnHiden()
	KillTimer( "SafeCenter_SafeScore_ApproveTimerProc()" );
end

function SafeCenter_SafeScore_SecurityCode_Msg( nErrCode )

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