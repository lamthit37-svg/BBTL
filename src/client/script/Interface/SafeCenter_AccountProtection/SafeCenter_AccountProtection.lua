--安全中心-账号密保界面-- Manda 2013-8-10

-- 界面的默认相对位置
local g_SafeCenter_AccountProtection_Frame_UnifiedXPosition;
local g_SafeCenter_AccountProtection_Frame_UnifiedYPosition;

function SafeCenter_AccountProtection_PreLoad()
	-- 新的打开安全中心界面
	this:RegisterEvent("OPEN_SAFECENTER_ACCOUNTPROTECTION");
	-- 老的密保响应事件
	this:RegisterEvent("OPEN_MINBAO_STATUS");	
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end	

function SafeCenter_AccountProtection_OnLoad()
	-- 保存界面的默认相对位置
	g_SafeCenter_AccountProtection_Frame_UnifiedXPosition	= SafeCenter_AccountProtection_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_AccountProtection_Frame_UnifiedYPosition	= SafeCenter_AccountProtection_Frame : GetProperty("UnifiedYPosition");
end

function SafeCenter_AccountProtection_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_ACCOUNTPROTECTION") or
	   ( event == "OPEN_MINBAO_STATUS") then
		if( this:IsVisible() ) then
			return;
		else
			SafeCenter_AccountProtection_Open();
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
	-- 更新背包界面位置
	    SafeCenter_AccountProtection_Frame_On_ResetPos();
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
	-- 游戏分辨率发生了变化
		SafeCenter_AccountProtection_Frame_On_ResetPos();
	end

end	

--===============================================
-- 					界面切换
--===============================================
function SafeCenter_AccountProtection_OpenSafeScore()  --安全中心的起始界面(也就是安全评分界面)
      Variable:SetVariable("SelfUnionPos", SafeCenter_AccountProtection_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeScore();
end

function SafeCenter_AccountProtection_OpenSafePattern()  --安全模式界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_AccountProtection_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafePattern();
end

function SafeCenter_AccountProtection_OpenMobilePhone()  --手机认证
      Variable:SetVariable("SelfUnionPos", SafeCenter_AccountProtection_Frame:GetProperty("UnifiedPosition"), 1);
      OpenMobilePhone();
end

function SafeCenter_AccountProtection_OpenSafeTime()  --安全时间
      Variable:SetVariable("SelfUnionPos", SafeCenter_AccountProtection_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeTime();
end

function SafeCenter_AccountProtection_Open() --账号密保

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
		SafeCenter_AccountProtection_WeGame_BackgroundRight_Frame:Show()
		SafeCenter_AccountProtection_BackgroundRight_Frame:Hide();
	else
		SafeCenter_AccountProtection_WeGame_BackgroundRight_Frame:Hide()
		SafeCenter_AccountProtection_BackgroundRight_Frame:Show();
	end

	     SafeCenter_AccountProtection_Update();
	     SafeCenter_AccountProtection_UpdateFrame();
	     SafeCenter_AccountProtection_MainButton_AccountProtection:SetProperty("Selected", "True");
	     SafeCenter_AccountProtection_MainButton_AccountProtection:SetProperty("RiseOnClick", "Flase");
	     SafeCenter_AccountProtection_ProtectionMibao_InitDlg();

	     this:Show();
end
function SafeCenter_AccountProtection_OpenSecondPassword()  --二级密码
      Variable:SetVariable("SelfUnionPos", SafeCenter_AccountProtection_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSecondPassword();
end

function SafeCenter_AccountProtection_OpenSafeCheck()  --安全验证
      Variable:SetVariable("SelfUnionPos", SafeCenter_AccountProtection_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeCheck();
end

function SafeCenter_AccountProtection_OpenLockUnlock()  --加锁解锁
      Variable:SetVariable("SelfUnionPos", SafeCenter_AccountProtection_Frame:GetProperty("UnifiedPosition"), 1);
      OpenLockUnlock();
end

------------------------------------------------

--更新界面按钮
function SafeCenter_AccountProtection_UpdateFrame()
	 SafeCenter_AccountProtection_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_AccountProtection_MainButton_SafePattern:SetProperty("Selected", "False");
	 SafeCenter_AccountProtection_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_AccountProtection_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_AccountProtection_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_AccountProtection_MainButton_SecondPassword:SetProperty("Selected", "False");
	 SafeCenter_AccountProtection_MainButton_SafeCheck:SetProperty("Selected", "False");
	 SafeCenter_AccountProtection_MainButton_LockUnlock:SetProperty("Selected", "False");	 
end

--更新主界面位置
function SafeCenter_AccountProtection_Frame_On_ResetPos()
	-- body
	SafeCenter_AccountProtection_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_AccountProtection_Frame_UnifiedXPosition);
	SafeCenter_AccountProtection_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_AccountProtection_Frame_UnifiedYPosition);
end

--得到当前UI位置
function SafeCenter_AccountProtection_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_AccountProtection_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end

--界面初始化
function SafeCenter_AccountProtection_ProtectionMibao_InitDlg()
	-- body
	local isHaveAppProtected = IsAppWareProtectSetup();


	SafeCenter_AccountProtection_Frame5_Lace3:SetProperty("Visible", "False");
	SafeCenter_AccountProtection_Frame5_Button2:SetProperty("Visible", "False");
	SafeCenter_AccountProtection_Frame5_Notice:SetProperty("Visible", "False");

	if(tonumber(isHaveAppProtected) == 1) then
		SafeCenter_AccountProtection_Frame5_ZZB_Button:SetText("#{DHMB_90417_4}");
		SafeCenter_AccountProtection_Frame5_ZZB_Lace_Text:SetText("#{ZZB_131213_03}");
	else
		SafeCenter_AccountProtection_Frame5_ZZB_Button:SetText("#{DHMB_90417_3}");
		SafeCenter_AccountProtection_Frame5_ZZB_Lace_Text:SetText("#{ZZB_131213_04}" )
	end	


end

--电话密保点击 绑定/解绑 按钮
function SafeCenter_AccountProtection_DianHuaMiBao_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_DIANHUAMIBAO"))
end
--掌中宝点击 绑定/解绑 按钮 
function SafeCenter_AccountProtection_ZhangZhongBao_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZZB"))
end



-- 超链 安全中心官网
function SafeCenter_AccountProtection_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_AccountProtection_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_AccountProtection_KFZX_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
end
