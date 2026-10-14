--认证手机界面--

local g_SafeCenter_login = 1;
-- 界面的默认相对位置
local g_SafeCenter_MessageBox_Frame_UnifiedXPosition;
local g_SafeCenter_MessageBox_Frame_UnifiedYPosition;
local ApproveResult
function SafeCenter_MessageBox_PreLoad()

	this:RegisterEvent("OPEN_SAFECENTER_MESSAGEBOX");
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 打开获取认证手机失败的界面
	this:RegisterEvent("OPEN_SAFECENTER_FAILASKMOBILEPHONE")
	this:RegisterEvent("CLOSE_SAFECENTER_MESSAGEBOX")
	this:RegisterEvent("GAMELOGIN_SELECTCHARACTER")
end	

function SafeCenter_MessageBox_OnLoad()

	-- 保存界面的默认相对位置
	g_SafeCenter_MessageBox_Frame_UnifiedXPosition	= SafeCenter_MessageBox_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_MessageBox_Frame_UnifiedYPosition	= SafeCenter_MessageBox_Frame : GetProperty("UnifiedYPosition");
	
end

function SafeCenter_MessageBox_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_MESSAGEBOX") then
		if( this:IsVisible() ) then
			return
		else
			SafeCenter_MessageBox_Open();
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then

	-- 更新背包界面位置
	    SafeCenter_MessageBox_Frame_On_ResetPos();
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then

	-- 游戏分辨率发生了变化
		SafeCenter_MessageBox_Frame_On_ResetPos();
	elseif (event == "GAMELOGIN_SELECTCHARACTER") then
		-- PushDebugMessage("bababaff")
		g_SafeCenter_login = 1		
	elseif (event == "OPEN_SAFECENTER_FAILASKMOBILEPHONE" ) then
			SafeCenter_MessageBox_FailAskMobilePhone_Open()
	elseif(event == "CLOSE_SAFECENTER_MESSAGEBOX") then
			this:Hide()
	end

end	
--===============================================
-- 					打开缓冲界面
--===============================================
function SafeCenter_MessageBox_Open()
	     
	     SafeCenter_MessageBox_Update()
	     SafeCenter_MessageBox_UpdateFrame();
	     this:Show();	    
 	     PushEvent("OPEN_SAFECENTER_ALLSCREEN")    
	     AskMobiePhoneStatus(1)
end

function SafeCenter_MessageBox_UpdateFrame()
	 SafeCenter_MessageBox_Info:SetText("#{AQZX_130812_158}");
	 SafeCenter_MessageBox_Close:SetProperty("Visible", "False");
end

--===============================================
-- 					打开获取失败界面
--===============================================
function SafeCenter_MessageBox_FailAskMobilePhone_Open()
	-- body
	SafeCenter_MessageBox_Update()
	SafeCenter_MessageBox_FailAskMobilePhone_UpdateFrame()
	this:Show()
end
function SafeCenter_MessageBox_FailAskMobilePhone_UpdateFrame()
	 SafeCenter_MessageBox_Info:SetText("#{AQZX_130812_159}");
	 SafeCenter_MessageBox_Close:SetProperty("Visible", "True");

end
--更新主界面位置
function SafeCenter_MessageBox_Frame_On_ResetPos()
	-- body
	SafeCenter_MessageBox_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_MessageBox_Frame_UnifiedXPosition);
	SafeCenter_MessageBox_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_MessageBox_Frame_UnifiedYPosition);
end

--得到当前UI位置
function SafeCenter_MessageBox_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_MessageBox_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end


function SafeCenter_MessageBox_TimerAskMobiePhoneStatus()

	AskMobiePhoneStatus(0)
	KillTimer("SafeCenter_MessageBox_TimerAskMobiePhoneStatus()")
end



