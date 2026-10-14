local g_Phony_InfoBrowser_Frame_UnifiedXPosition = 0
local g_Phony_InfoBrowser_Frame_UnifiedYPosition = 0
local g_Timers = 0
local g_Seconds = 3
local g_Type = 0
local g_Date = 0;
local g_GUIDH = 0;
local g_GUIDL = 0;
local g_Name = "";

function Phony_InfoBrowser_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("PHONY_INFOBROWSER_OPEN");
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Phony_InfoBrowser_OnLoad()
	--PushDebugMessage("Phony_InfoBrowser_OnLoad...");
	--g_Phony_InfoBrowser_Frame_UnifiedXPosition = Phony_InfoBrowser_Frame:GetProperty("UnifiedXPosition")
	--g_Phony_InfoBrowser_Frame_UnifiedYPosition = Phony_InfoBrowser_Frame:GetProperty("UnifiedYPosition")
end

function Phony_InfoBrowser_ResetPos()
	--Phony_InfoBrowser_Frame:SetProperty("UnifiedXPosition", g_Phony_InfoBrowser_Frame_UnifiedXPosition);
	--Phony_InfoBrowser_Frame:SetProperty("UnifiedYPosition", g_Phony_InfoBrowser_Frame_UnifiedYPosition);
end

function Phony_InfoBrowser_OnEvent(event)
	
	--PushDebugMessage("Phony_InfoBrowser_OnEvent...");
	if ( event == "PHONY_INFOBROWSER_OPEN" ) then
		g_Date = tonumber( arg0 )
		g_GUIDH = tonumber( arg1 )
		g_GUIDL = tonumber( arg2 )
		g_Name = tostring( arg3 )
		--PushDebugMessage( g_Date..","..g_GUIDH..","..g_GUIDL..","..g_Name )
		if(g_Name ~= "") then
			Phony_InfoBrowser_Show();
			this:Show();
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		Phony_InfoBrowser_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Phony_InfoBrowser_ResetPos()
	end
end

function Phony_InfoBrowser_Show()
	--PushDebugMessage(g_Date.."Phony_InfoBrowser_Show..."..g_Name);
	--g_GUIDH = 6619649;
	--g_GUIDL = 1010000002;
	--g_Date = 1451987057;
	--PushDebugMessage(g_Date.."..."..g_GUIDH.."..."..g_GUIDL);
	--local szName = DataPool:GetUserNameByGuid(tonumber(g_GUIDH), tonumber(g_GUIDL));
	--if (szName == "") then
	--	return 0;
	--end
	local year, month, day, hour, minute, second = ZhanTuanInterface:GetConvertUT(tonumber(g_Date), 1);
	if( tonumber(month) < 10) then
		month = "0"..month;
	end
	if( tonumber(day) < 10) then
		day = "0"..day;
	end
	if( tonumber(hour) < 10) then
		hour = "0"..hour;
	end
	if( tonumber(minute) < 10) then
		minute = "0"..minute;
	end
	if( tonumber(second) < 10) then
		second = "0"..second;
	end
	local msg = ScriptGlobal_Format("#{CYG_130527_90}", tostring(g_Name), tostring(year), tostring(month), 
								tostring(day), tostring(hour), tostring(minute));
	local msgTimeText = tostring(year).."-"..tostring(month).."-"..tostring(day).." "..tostring(hour)..":"..tostring(minute)..":"..tostring(second);
	
	Phony_InfoBrowser_Context:SetText(msg);
	Phony_InfoBrowser_TimeText:SetText(msgTimeText);
	--PushDebugMessage(msgDate..g_Name..":"..year..","..month..","..day..","..hour..","..minute..","..second);
end

function Phony_InfoBrowser_Buttoned()
	DataPool:AskSaleUserNotification(g_GUIDH, g_GUIDL, g_Date);
	PushDebugMessage("#{CYG_160315_135}");
	this:Hide();
end

function Phony_InfoBrowser_Close()
	this:Hide();
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
