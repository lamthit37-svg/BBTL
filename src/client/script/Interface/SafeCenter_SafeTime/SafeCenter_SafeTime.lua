--安全时间界面--

-- 界面的默认相对位置
local g_SafeCenter_SafeTime_Frame_UnifiedXPosition;
local g_SafeCenter_SafeTime_Frame_UnifiedYPosition;

function SafeCenter_SafeTime_PreLoad()

	this:RegisterEvent("OPEN_SAFECENTER_SAFETIME");
	this:RegisterEvent("OPENDLG_FOR_SETPROTECTTIME");
	
	--更新倒计时时间
	this:RegisterEvent("LEFTPROTECTTIME_CHANGE");
	--更新已设置的安全时间
	this:RegisterEvent("DBLEFTPROTECTTIME_CHANGE");
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);

end	

function SafeCenter_SafeTime_OnLoad()

	-- 保存界面的默认相对位置
	g_SafeCenter_SafeTime_Frame_UnifiedXPosition	= SafeCenter_SafeTime_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_SafeTime_Frame_UnifiedYPosition	= SafeCenter_SafeTime_Frame : GetProperty("UnifiedYPosition");

end

function SafeCenter_SafeTime_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_SAFETIME") or ( event == "OPENDLG_FOR_SETPROTECTTIME")then
		if( this:IsVisible() ) then
			return;
		else
			SafeCenter_SafeTime_Open();
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
	-- 游戏分辨率发生了变化
		SafeCenter_SafeTime_Frame_On_ResetPos();

    -- 更新倒计时时间
	elseif(event == "LEFTPROTECTTIME_CHANGE")then
		if( this:IsVisible() ) then
			SafeCenter_SafeTime_UpdateLeftSafeTime(tonumber(arg0));
		end

    -- 更新已设置时间		
	elseif(event == "DBLEFTPROTECTTIME_CHANGE")then
		if( this:IsVisible() ) then
			SafeCenter_SafeTime_DBUpdateLeftSafeTime(tonumber(arg0));
			PushDebugMessage("#{AQZX_130812_51}")
		end

   	-- 更新背包界面位置		
	elseif (event == "ADJEST_UI_POS" ) then
	    SafeCenter_SafeTime_Frame_On_ResetPos();
	end

end	
--===============================================
-- 					界面切换
--===============================================
function SafeCenter_SafeTime_OpenSafeScore()  --安全中心的起始界面(也就是安全模式界面)
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeTime_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeScore();
end

function SafeCenter_SafeTime_Open() --安全时间界面
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
		SafeCenter_SafeTime_WeGame_BackgroundRight_Frame:Show()
		SafeCenter_SafeTime_BackgroundRight_Frame:Hide();
		SafeCenter_SafeTime_MainButton_SafeScore:Disable();
		SafeCenter_SafeTime_MainButton_SafePattern:Disable();
		SafeCenter_SafeTime_MainButton_AccountProtection:Disable();
		SafeCenter_SafeTime_MainButton_SafeCheck:Disable();
	else
		SafeCenter_SafeTime_WeGame_BackgroundRight_Frame:Hide()
		SafeCenter_SafeTime_BackgroundRight_Frame:Show();
	end

	     SafeCenter_SafeTime_Update();
	     SafeCenter_SafeTime_UpdateFrame();
	     SafeCenter_SafeTime_MainButton_SafeTime:SetProperty("Selected", "True");
	     SafeCenter_SafeTime_MainButton_SafeTime:SetProperty("RiseOnClick", "Flase");
	     SafeCenter_SafeTime_InitDlg();
	     this:Show();
end

function SafeCenter_SafeTime_OpenMobilePhone()  --手机验证
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeTime_Frame:GetProperty("UnifiedPosition"), 1);
      OpenMobilePhone();
end

--打开安全模式界面--
function SafeCenter_SafeTime_OpenSafePattern() --安全模式
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeTime_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafePattern();
end
--打开账号安全界面--
function SafeCenter_SafeTime_OpenAccountProtection() --账号密保
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeTime_Frame:GetProperty("UnifiedPosition"), 1);
      OpenAccountProtection();
end
--打开二级密码--
function SafeCenter_SafeTime_OpenSecondPassword() --二级密码
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeTime_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSecondPassword();
end
--打开安全验证--
function SafeCenter_SafeTime_OpenSafeCheck() --安全验证
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeTime_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeCheck();
end
--打开加锁解锁--
function SafeCenter_SafeTime_OpenLockUnlock() --加锁解锁
	  Variable:SetVariable("SelfUnionPos", SafeCenter_SafeTime_Frame:GetProperty("UnifiedPosition"), 1);
      OpenLockUnlock();
end
---------------------------------------------
--初始化
function SafeCenter_SafeTime_InitDlg()

	SafeCenter_SafeTime_SetMin:SetText(10);
	SafeCenter_SafeTime_SetMin:SetProperty("DefaultEditBox", "True");
	SafeCenter_SafeTime_SetMin:SetSelected( "True" );
    SafeCenter_SafeTime_StopTime_Text:SetText("00:00:00");	
	--被盗判定和#{BDPD_110107_1}安全时间
	local ret = DataPool:GetForeverLock()
	if ret == true then
         SafeCenter_SafeTime_OpenForeverControl();
	else
        SafeCenter_SafeTime_CloseForeverControl();
		local dblefttime = DataPool:GetDBLeftProtectTime();
		if(tonumber(dblefttime) <= 0) then
			--当玩家没有设置安全时间的时候，设置成默认3分钟
			SafeCenter_SafeTime_Frame4_Time1:SetText("3"); 
		else
			SafeCenter_SafeTime_DBUpdateLeftSafeTime(tonumber(dblefttime));
			lefttime =DataPool:GetLeftProtectTime();
			SafeCenter_SafeTime_UpdateLeftSafeTime(tonumber(lefttime));
		end
	end

end
--更新已设置安全时间
function SafeCenter_SafeTime_DBUpdateLeftSafeTime(time)
		--被盗判定和#{BDPD_110107_1}安全时间
	    if (tonumber(time) <= 0) then
		    return
	    end

	    local iTime = math.floor( time / 1000 )
	    local iMin = math.floor( iTime / 60 )
	    local strTime="";
	    if(iMin>0)then
		strTime = iMin;
	    end
	    SafeCenter_SafeTime_Frame4_Time1:SetText(strTime); 
end
--更新倒计时时间
function SafeCenter_SafeTime_UpdateLeftSafeTime(time)

		--被盗判定和#{BDPD_110107_1}安全时间
		local ret = DataPool:GetForeverLock()
		if ret == true then
			return
		end
	    local iTime = math.floor( time / 1000 )
	    local iHor = math.floor( iTime / 3600 )
	    iTime = math.mod( iTime, 3600 )
	    local iSec = math.mod( iTime, 60 )
	    local iMin = math.floor( iTime / 60 )
	    local strHor ,strMin,strSec;
	    if(iHor<10)then
		strHor="0"..iHor;
	    else
		strHor=""..iHor;
	    end
	    if(iMin<10)then
		strMin="0"..iMin;
	    else
		strMin=""..iMin;
	    end
	    if(iSec<10)then
		strSec ="0"..iSec;
	    else
		strSec = ""..iSec;
	    end
	    SafeCenter_SafeTime_StopTime_Text:SetText(strHor..":"..strMin..":"..strSec);

end

function SafeCenter_SafeTime_ResetSelect(idx)
	if(idx~=0) then
		SafeCenter_SafeTime_SetMin:SetSelected( 0, -1 );
	end
end

--得到当前UI位置
function SafeCenter_SafeTime_Update()

	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_SafeTime_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end

end

function SafeCenter_SafeTime_UpdateFrame()

	 SafeCenter_SafeTime_MainButton_SafeScore:SetProperty("Selected", "False");
	 SafeCenter_SafeTime_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_SafeTime_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_SafeTime_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_SafeTime_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_SafeTime_MainButton_SecondPassword:SetProperty("Selected", "False");
	 SafeCenter_SafeTime_MainButton_SafeCheck:SetProperty("Selected", "False");
	 SafeCenter_SafeTime_MainButton_LockUnlock:SetProperty("Selected", "False");

end

--检查输入情况
function SafeCenter_SafeTime_CheckIfOK()

	local Min = SafeCenter_SafeTime_SetMin:GetText();
	if(Min~=nil and tonumber(Min)~=nil) then 
		if(tonumber(Min)>60) then
			PushDebugMessage("#{AQZX_130812_46}")
			SafeCenter_SafeTime_SetMin:SetText("10")
		elseif (tonumber(Min)<1) then
			PushDebugMessage("#{AQZX_130812_157}")
			SafeCenter_SafeTime_SetMin:SetText("10")
		end
	end

end

--检查点击确认的情况
function SafeCenter_SafeTime_OK_Click()

	--判断是否为永久安全时间
	local Min = SafeCenter_SafeTime_SetMin:GetText();
	local dblefttime =DataPool:GetLeftProtectTime();

	-- 判断是否为安全时间内
	if(tonumber(dblefttime)>0) then
		PushDebugMessage("#{AQZX_130812_47}")
		return
	end

	--判断是否为空J
	str = tostring(Min);
	ret = string.len(str)
	if(ret <= 0) then
		PushDebugMessage("#{AQZX_130812_48}")  		
  		return
	end

	--判断是否为纯数字
    if( Min~=nil and tonumber(Min)==nil ) then
 		PushDebugMessage("#{AQZX_130812_49}")
        return 
    end

    --输入的数字是否在规定范围内
    if(Min~=nil and tonumber(Min)~=nil) then 
		if(tonumber(Min)>60) then
			PushDebugMessage("#{AQZX_130812_46}")
			SafeCenter_SafeTime_SetMin:SetText("10")
			return
		elseif (tonumber(Min)<1) then
			PushDebugMessage("#{AQZX_130812_157}")
			SafeCenter_SafeTime_SetMin:SetText("10")
			return
		end
	end

    --弹出二次确认框 并进行设置
	if( Min~=nil and tonumber(Min)~=nil) then
		Lua_SetProtectTime(0,tonumber(Min));
	end

end

--更新主界面位置
function SafeCenter_SafeTime_Frame_On_ResetPos()

	SafeCenter_SafeTime_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_SafeTime_Frame_UnifiedXPosition);
	SafeCenter_SafeTime_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_SafeTime_Frame_UnifiedYPosition);

end



function SafeCenter_SafeTime_OpenForeverControl()

	-- 将“永久” 控件打开
	SafeCenter_SafeTime_Frame4_Lace6:SetProperty("Visible", "True");
    SafeCenter_SafeTime_Frame4_Time1:SetProperty("Visible", "False");
    SafeCenter_SafeTime_Frame4_Text1:SetProperty("Visible", "False");
    SafeCenter_SafeTime_StopTime_Text:SetText("#{BDPD_110107_1}");	

end

function SafeCenter_SafeTime_CloseForeverControl()

	SafeCenter_SafeTime_Frame4_Lace6:SetProperty("Visible", "False");
	SafeCenter_SafeTime_Frame4_Time1:SetProperty("Visible", "True");
	SafeCenter_SafeTime_Frame4_Text1:SetProperty("Visible", "True");

end



-- 超链 安全中心官网
function SafeCenter_SafeTime_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_SafeTime_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_SafeTime_KFZX_Clicked()
	if GameProduceLogin:IsWeGameClient() > 0 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_ANQUANZHONGXIN_KFZX"))
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
	end
end



