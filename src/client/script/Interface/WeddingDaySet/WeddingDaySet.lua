
local g_Timers = 0
local g_Seconds = 3
local g_WeddingDaySetOK = 0;
local g_clientNpcId = -1;
local g_WeddingDaySet_Frame_UnifiedXPosition = 0
local g_WeddingDaySet_Frame_UnifiedYPosition = 0

function WeddingDaySet_PreLoad()

	this:RegisterEvent("SET_MARRY_DATE");
	this:RegisterEvent("MARRY_DATE_CONFIRM");
	this:RegisterEvent("SET_MARRY_DATE_WAIT_CONFIRM");
	this:RegisterEvent("CLOSE_MARRY_DATE");
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function WeddingDaySet_OnLoad()
	g_WeddingDaySet_Frame_UnifiedXPosition = WeddingDaySet_Frame:GetProperty("UnifiedXPosition")
	g_WeddingDaySet_Frame_UnifiedYPosition = WeddingDaySet_Frame:GetProperty("UnifiedYPosition")
end

function WeddingDaySet_ResetPos()
	WeddingDaySet_Frame:SetProperty("UnifiedXPosition", g_WeddingDaySet_Frame_UnifiedXPosition);
	WeddingDaySet_Frame:SetProperty("UnifiedYPosition", g_WeddingDaySet_Frame_UnifiedYPosition);
end

function WeddingDaySet_OnEvent(event)
	if ( event == "SET_MARRY_DATE" ) then
		this:Show();
		local g_serverNpcId = arg0
		g_clientNpcId = Target:GetServerId2ClientId(tonumber(g_serverNpcId));
		this:CareObject(g_clientNpcId, 1, "WeddingDaySet");
		WeddingDaySet_Update();
	elseif event == "MARRY_DATE_CONFIRM" then
		--WeddingDaySet_Marry_Date_Confirm();
	elseif event == "SET_MARRY_DATE_WAIT_CONFIRM" then
		if(arg0 == "0") then	-- 修改结婚确定按钮为等待对方确认
			WeddingDaySet_OK:SetText("#{HYGX_150515_25}");
			WeddingDaySet_OK:Disable();
		else
			WeddingDaySet_OK:SetText("#{HYGX_150515_14}");
			WeddingDaySet_OK:Enable();
			this:Hide();
		end
	elseif( event == "CLOSE_MARRY_DATE" ) then
		this:Hide();
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		WeddingDaySet_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WeddingDaySet_ResetPos()
	end
end

function WeddingDaySet_Update()
	WeddingDaySet_Client_Date_Year:SetText("");
	WeddingDaySet_Client_Date_Month:SetText("");
	WeddingDaySet_Client_Date_Day:SetText("");
	WeddingDaySet_Client_Date_Hour:SetText("");
	WeddingDaySet_OK:SetText("#{HYGX_150515_14}");
	WeddingDaySet_OK:Enable();
	--PushDebugMessage("WeddingDaySet_Update...");
	--if (0 == g_WeddingDaySetOK) then
	--	WeddingDaySet_OK:SetText("#{HYGX_150515_14}");
	--else
	--	WeddingDaySet_OK:SetText("#{HYGX_150515_25}");
	--end
end

function WeddingDaySet_Marry_Date_Confirm()
	--PushDebugMessage("WeddingDaySet_Marry_Date_Confirm...");
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MarryDateCallBack")
		Set_XSCRIPT_ScriptID(000093)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--
function WeddingDaySet_OK_Clicked()
	local strYear	= WeddingDaySet_Client_Date_Year:GetText();
	local strMonth	= WeddingDaySet_Client_Date_Month:GetText();
	local strDay	= WeddingDaySet_Client_Date_Day:GetText();
	local strHour	= WeddingDaySet_Client_Date_Hour:GetText();
	if(strYear == 0 or strMonth == 0 or strDay == 0 or strHour == 0) then
		PushDebugMessage("#{HYGX_150515_19}");
		return;
	end
	if(strYear == "" or strMonth == "" or strDay == "" or strHour == "") then
		PushDebugMessage("#{HYGX_150515_19}");
		return;
	end
	local msg = ScriptGlobal_Format("#{HYGX_150515_20}", tostring(strYear), tostring(strMonth), tostring(strDay));
	MessageBoxCommon("", msg, "WeddingDaySet", "OnBtnConfirmOK()", "OnBtnBuyCancel()");
	--MessageBox_Self2
end

--
function WeddingDaySet_OnBtnConfirmOK()
	local strYear	= WeddingDaySet_Client_Date_Year:GetText();
	local strMonth	= WeddingDaySet_Client_Date_Month:GetText();
	local strDay	= WeddingDaySet_Client_Date_Day:GetText();
	local strHour	= WeddingDaySet_Client_Date_Hour:GetText();
	--WeddingDaySet_OK:SetText("#{HYGX_150515_25}");
	--PushDebugMessage("WeddingDaySet_OK_Clicked..."..strYear.."__"..strMonth.."__"..strDay.."__"..strHour);
	if(strYear == 0 or strMonth == 0 or strDay == 0 or strHour == 0) then
		PushDebugMessage("#{HYGX_150515_19}");
		return;
	end
	if(strYear == "" or strMonth == "" or strDay == "" or strHour == "") then
		PushDebugMessage("#{HYGX_150515_19}");
		return;
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MarryDateConfirm")
		Set_XSCRIPT_ScriptID(000093)
		Set_XSCRIPT_Parameter(0, tonumber(strYear))
		Set_XSCRIPT_Parameter(1, tonumber(strMonth))
		Set_XSCRIPT_Parameter(2, tonumber(strDay))
		Set_XSCRIPT_Parameter(3, tonumber(strHour))
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	
end

--取消
function WeddingDaySet_OnBtnBuyCancel()

end

function WeddingDaySet_Closed()
	--PushDebugMessage("WeddingDaySet_Closed...");
	this:Hide();
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "MarryDateCallBack" )
		Set_XSCRIPT_ScriptID( 000093 )
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function ShuaXin_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end
