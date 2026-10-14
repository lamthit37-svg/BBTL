local g_BankLockFast_Frame_UnifiedPosition;
--最多显示的效果数量
function BankLockFast_PreLoad()
	this:RegisterEvent("BANK_LOCKFAST_UPDATE",true);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BankLockFast_OnLoad()
  g_BankLockFast_Frame_UnifiedPosition=BankLockFast_Frame:GetProperty("UnifiedPosition");
end

function BankLockFast_OnEvent(event)
	if ( event == "BANK_LOCKFAST_UPDATE" ) then
		local careobjid = Target:GetServerId2ClientId(tonumber(arg0));
		this:CareObject(careobjid, 1, "BankLockFast");
		BankLockFast_update();
		this:Show();
	end
		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		BankLockFast_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BankLockFast_Frame_On_ResetPos()
	end	
end

function BankLockFast_tiqu_Clicked()
	SafeBox("getmoney");
end

function BankLockFast_cunru_Clicked()
	SafeBox("savemoney");
end

function BankLockFast_kaiqi_Clicked()
	SafeBox("unlock");
end

function BankLockFast_suoding_Clicked()
	SafeBox("lock");
end

function BankLockFast_update()
	local boxstatus = SafeBox("getstatus");
	local statusmsg;
	local finalmsg;
	if(boxstatus == "locked") then
		BankLockFast_Save:Enable();
		BankLockFast_Lock:Disable();
		BankLockFast_Get:Disable();
		BankLockFast_Unlock:Enable();
		statusmsg = "当前保险箱状态：#G锁定#W#r"
		finalmsg = statusmsg.."#{YHBXX_20071220_14}";
	elseif(boxstatus == "freezed") then
		BankLockFast_Save:Enable();
		BankLockFast_Lock:Enable();
		BankLockFast_Get:Disable();
		BankLockFast_Unlock:Disable();
		local leftday  = SafeBox("getleftday");
		local lefthour = SafeBox("getlefthour");
        statusmsg = string.format("当前保险箱状态：#G解锁保护期#W（剩余#G%d#W天#G%d#W小时）#r",leftday,lefthour);
		finalmsg = statusmsg.."#{YHBXX_20071220_15}";
	elseif(boxstatus == "unfreezed") then
		BankLockFast_Save:Enable();
		BankLockFast_Lock:Enable();
		BankLockFast_Get:Enable();
		BankLockFast_Unlock:Disable();
		statusmsg = "当前保险箱状态：#G解锁#W#r"
		finalmsg = statusmsg.."#{YHBXX_20071220_16}";
	end
	BankLockFast_WarningText:SetText(finalmsg);
	
	local safeboxmoney = SafeBox("getsafeboxmoney");
	BankLockFast_Money:SetProperty("MoneyNumber", safeboxmoney);	

end

function BankLockFast_Close()
	SafeBox("onclose");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BankLockFast_Frame_On_ResetPos()
  BankLockFast_Frame:SetProperty("UnifiedPosition", g_BankLockFast_Frame_UnifiedPosition);
end