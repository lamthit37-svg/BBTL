--安全模式界面-- Manda 2013-8-3

-- 界面的默认相对位置
local g_SafeCenter_SafePattern_Frame_UnifiedXPosition;
local g_SafeCenter_SafePattern_Frame_UnifiedYPosition;

function SafeCenter_SafePattern_PreLoad()

	this:RegisterEvent("OPEN_SAFECENTER_SAFEPATTERN");
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 按钮刷新
	this:RegisterEvent("UPDATE_AUTHORIZEDSAFEFLAG")

end	

function SafeCenter_SafePattern_OnLoad()

	-- 得到界面相对位置
	g_SafeCenter_SafePattern_Frame_UnifiedXPosition	= SafeCenter_SafePattern_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_SafePattern_Frame_UnifiedYPosition	= SafeCenter_SafePattern_Frame : GetProperty("UnifiedYPosition");

end

function SafeCenter_SafePattern_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_SAFEPATTERN") then
		if( this:IsVisible() ) then
			return;
		else
			SafeCenter_SafePattern_Open();
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
	SafeCenter_SafePattern_Frame_On_ResetPos();

	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
    SafeCenter_SafePattern_Frame_On_ResetPos();

	elseif (event == "UPDATE_AUTHORIZEDSAFEFLAG" ) then	

		if (arg0 == "1") then
		SafeCenter_SafePattern_Update_StatusIsOpen();
		elseif(arg0 == "0") then
		SafeCenter_SafePattern_Update_StatusIsClose();
		end

	end

end	
--===============================================
-- 					界面切换
--===============================================
function SafeCenter_SafePattern_OpenSafeScore()  --安全中心的起始界面(也就是安全评分界面)
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeScore();
end

function SafeCenter_SafePattern_Open() --安全模式界面

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
	CloseWindow("SafeCenter_MessageBox", true)	  
	
	if GameProduceLogin:IsWeGameClient() > 0 then
		SafeCenter_SafePattern_WeGame_BackgroundRight_Frame:Show()
		SafeCenter_SafePattern_BackgroundRight_Frame:Hide();
	else
		SafeCenter_SafePattern_WeGame_BackgroundRight_Frame:Hide()
		SafeCenter_SafePattern_BackgroundRight_Frame:Show();
	end
	
	SafeCenter_SafePattern_Update()
	SafeCenter_SafePattern_UpdateFrame();
	SafeCenter_SafePattern_MainButton_SafePattern:SetProperty("Selected", "True");
	SafeCenter_SafePattern_MainButton_SafePattern:SetProperty("RiseOnClick", "Flase");
	this:Show();

end
function SafeCenter_SafePattern_OpenMobilePhone()  --手机验证界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
      OpenMobilePhone();
end
function SafeCenter_SafePattern_OpenSafeTime()  --安全时间界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeTime();
end

function SafeCenter_SafePattern_OpenAccountProtection()  --账号密保界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
      OpenAccountProtection();
end
function SafeCenter_SafePattern_OpenSecondPassword()  --二级密码
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSecondPassword();
end
function SafeCenter_SafePattern_OpenSafeCheck()  --安全验证
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeCheck();
end
function SafeCenter_SafePattern_OpenLockUnlock()  --加锁解锁
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
      OpenLockUnlock();
end
----------------------------------------

--得到当前UI位置
function SafeCenter_SafePattern_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_SafePattern_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end

--按键更新
function SafeCenter_SafePattern_UpdateFrame()

	 SafeCenter_SafePattern_MainButton_SafeScore:SetProperty("Selected", "False");
	 SafeCenter_SafePattern_MainButton_SafePattern:SetProperty("Selected", "False");
	 SafeCenter_SafePattern_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_SafePattern_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_SafePattern_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_SafePattern_MainButton_SecondPassword:SetProperty("Selected", "False");
	 SafeCenter_SafePattern_MainButton_SafeCheck:SetProperty("Selected", "False");
	 SafeCenter_SafePattern_MainButton_LockUnlock:SetProperty("Selected", "False");	 

	 --设置 Open/Close_Button 状态
	 if(GetAuthorizedSafeFlag() == 1) then
	 	SafeCenter_SafePattern_Update_StatusIsOpen()
	 elseif(GetAuthorizedSafeFlag() == 0) then
	 	SafeCenter_SafePattern_Update_StatusIsClose()
	 end

end

--更新主界面位置
function SafeCenter_SafePattern_Frame_On_ResetPos()

	SafeCenter_SafePattern_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_SafePattern_Frame_UnifiedXPosition);
	SafeCenter_SafePattern_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_SafePattern_Frame_UnifiedYPosition);

end

--点击开启/关闭
function SafeCenter_SafePattern_StateOfSafeIsOk()
    
    -- 判断是否为安全时间内
	local dblefttime =DataPool:GetLeftProtectTime();
	if(tonumber(dblefttime)>0) then
		 PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	--存储当前页面位置
	Variable:SetVariable("SelfUnionPos", SafeCenter_SafePattern_Frame:GetProperty("UnifiedPosition"), 1);
	
	local g_SafeCheckIsOK = 1

	--手机密保、电话密保判断
	g_SafeCheckIsOK = CheckPlayerAccountSafety()

	if(g_SafeCheckIsOK == 1) then
		--关闭->开启 
		if(GetAuthorizedSafeFlag() == 0) then
			--调用二次确认框
			PushEvent( "ATHORSECFRAME",1)
			return
		end

		--开启->关闭
		if(GetAuthorizedSafeFlag() == 1) then
			SetAuthorizedSafeFlag(0);
		--如果没开
		end

	end
end

function SafeCenter_SafePattern_Update_StatusIsOpen( )

	SafeCenter_SafePattern_Frame2_Button:SetText("#{AQZX_130812_139}")
	SafeCenter_SafePattern_Frame2_Lace2_Text:SetText("#{AQZX_130812_29}")

end

function SafeCenter_SafePattern_Update_StatusIsClose( )

	SafeCenter_SafePattern_Frame2_Button:SetText("#{AQZX_130812_138}")
	SafeCenter_SafePattern_Frame2_Lace2_Text:SetText("#{AQZX_130812_30}")	
	
end


-- 超链 安全中心官网
function SafeCenter_SafePattern_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_SafePattern_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_SafePattern_KFZX_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
end
