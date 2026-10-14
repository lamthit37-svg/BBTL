local g_QiXi_PVPTime_Frame_UnifiedXPosition;
local g_QiXi_PVPTime_Frame_UnifiedYPosition;

local g_QiXi_PVPTime_index = 0
local g_QiXi_PVPTime_time = 0
local g_QiXi_PVPTime_memcount = 0
local g_QiXi_PVPTime_HaveDate = 0

local g_Qixi_PVPTime_EndTime=
{
	[0] = 16,
	[1] = 21,
}

function QiXi_PVPTime_PreLoad()
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("QIXI_PVP_MINI");
	this:RegisterEvent("ADJEST_UI_POS");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED");
end

function QiXi_PVPTime_OnLoad()
	g_QiXi_PVPTime_Frame_UnifiedXPosition	= QiXi_PVPTime : GetProperty("UnifiedXPosition");
	g_QiXi_PVPTime_Frame_UnifiedYPosition	= QiXi_PVPTime : GetProperty("UnifiedYPosition");
end

function QiXi_PVPTime_On_ResetPos()

	
	QiXi_PVPTime : SetProperty("UnifiedXPosition", g_QiXi_PVPTime_Frame_UnifiedXPosition);
	QiXi_PVPTime : SetProperty("UnifiedYPosition", g_QiXi_PVPTime_Frame_UnifiedYPosition);

end

function QiXi_PVPTime_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		if arg0 ~="XBWDH_Rest_Qipvp" then
			if( this:IsVisible() ) then
				this:Hide()
			end
		end
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif (event=="QIXI_PVP_MINI") then
		if arg0=="1" then
			QiXi_PVPTime_UpDateInfo()
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50714301 ) then
		g_QiXi_PVPTime_HaveDate = 1
		g_QiXi_PVPTime_index = Get_XParam_INT(0)
		g_QiXi_PVPTime_time = Get_XParam_INT(1)
		g_QiXi_PVPTime_memcount = Get_XParam_INT(2)

		if( this:IsVisible() ) then
			QiXi_PVPTime_UpDateInfo()
		end	
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50714302 ) then
		QiXi_PVPTime_Time:SetProperty("Timer", tonumber(0));
		QiXi_PVPTime_Time2:SetProperty("Timer", tonumber(0));
		QiXi_PVPTime_Time3Text:SetText("")
		QiXi_PVPTime_Time2Text:SetText("")
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		
		QiXi_PVPTime_On_ResetPos();
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		
		QiXi_PVPTime_On_ResetPos();
	end
end

function QiXi_PVPTime_Open()

end

function QiXi_PVPTime_TimeOut()
	QiXi_PVPTime_Time2:SetProperty("Timer", tonumber(0));
	QiXi_PVPTime_Time:SetProperty("Timer", tonumber(0));
	QiXi_PVPTime_Time3Text:SetText("")
	QiXi_PVPTime_Time2Text:SetText("#{QXPVE_240522_140}")
end

function QiXi_PVPTime_OpenMini()

	this:Hide()
	PushEvent("QIXI_PVP_MINI",0)
end

function QiXi_PVPTime_Image()

	this:Hide()
	PushEvent("QIXI_PVP_MINI",0)
end

function QiXi_PVPTime_UpDateInfo()
	--QiXi_PVPTime_Text:SetText("#{XSLDZ_180521_292}")

	if g_QiXi_PVPTime_HaveDate == 1 then
		local sec  = 0
		if g_QiXi_PVPTime_index>= 0 and  g_Qixi_PVPTime_EndTime[g_QiXi_PVPTime_index] ~= nil  then
			sec = Lua_GetDiffTime_InSecond_ServerTime(g_Qixi_PVPTime_EndTime[g_QiXi_PVPTime_index],0,0)
		end
		
		if sec == 0  then
			QiXi_PVPTime_Time2:SetProperty("Timer", tonumber(0));
			QiXi_PVPTime_Time:SetProperty("Timer", tonumber(0));
			QiXi_PVPTime_Time3Text:SetText("")
			QiXi_PVPTime_Time2Text:SetText("#{QXPVE_240522_140}")
		else
			QiXi_PVPTime_Time:SetProperty("Timer", tonumber(g_QiXi_PVPTime_time));
			QiXi_PVPTime_Time2:SetProperty("Timer", tonumber(sec));
			QiXi_PVPTime_Time3Text:SetText(g_QiXi_PVPTime_memcount)
			QiXi_PVPTime_Time2Text:SetText("")
	
		end
	else
		QiXi_PVPTime_Time:SetProperty("Timer", tonumber(0));
		QiXi_PVPTime_Time2:SetProperty("Timer", tonumber(0));
		QiXi_PVPTime_Time3Text:SetText("")
		QiXi_PVPTime_Time2Text:SetText("")
	end
end