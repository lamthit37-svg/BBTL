local g_DaHua_Time_Frame_UnifiedXPosition;
local g_DaHua_Time_Frame_UnifiedYPosition;

function DaHua_Time_PreLoad()
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("QIXIPVE_XXS_MINI");
	this:RegisterEvent("ADJEST_UI_POS");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED");
	
end

function DaHua_Time_OnLoad()
	g_DaHua_Time_Frame_UnifiedXPosition	= DaHua_Time : GetProperty("UnifiedXPosition");
	g_DaHua_Time_Frame_UnifiedYPosition	= DaHua_Time : GetProperty("UnifiedYPosition");
end

function DaHua_Time_On_ResetPos()
	
	DaHua_Time : SetProperty("UnifiedXPosition", g_DaHua_Time_Frame_UnifiedXPosition);
	DaHua_Time : SetProperty("UnifiedYPosition", g_DaHua_Time_Frame_UnifiedYPosition);

end

function DaHua_Time_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		if arg0=="XBWDH_Rest_QNYH" then
			this:Show()
		else
			this:Hide()
		end
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif (event=="QIXIPVE_XXS_MINI") then
		if arg0=="1" then
			--DaHua_Time_DragTitle:SetToolTip("#{XSLDZ_180424_16}")
			-- DaHua_Time_Time:SetProperty("Timer", tonumber(0));
			-- DaHua_Time_Time2:SetProperty("Timer", tonumber(0));
            -- DaHua_Time_Time3Text:SetText("")
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20240606 ) then

		DaHua_Time_Text:SetText("#{QXPVE_240522_39}")
		local time = Get_XParam_INT(0)
		local memcount = Get_XParam_INT(1)
		local isActTime = Get_XParam_INT(2)
		local sec = 0;
		if(isActTime == 1 ) then
			sec = Lua_GetDiffTime_InSecond_ServerTime(10,30,0)
		elseif(isActTime == 2 ) then
			sec = Lua_GetDiffTime_InSecond_ServerTime(17,30,0)
		elseif(isActTime == 3 ) then
			sec = Lua_GetDiffTime_InSecond_ServerTime(19,30,0)
		end
		if sec == 0  then
			DaHua_Time_Time:SetProperty("Timer", tonumber(0));
			DaHua_Time_Time2:SetProperty("Timer", tonumber(0));
			DaHua_Time_Time3Text:SetText("")
			DaHua_Time_Time2Text:SetText("#{QXPVE_240522_140}")
		else
			DaHua_Time_Time:SetProperty("Timer", tonumber(time));
			DaHua_Time_Time2:SetProperty("Timer", tonumber(sec));
			DaHua_Time_Time3Text:SetText(memcount)
			DaHua_Time_Time2Text:SetText("")
		end

	elseif (event == "ADJEST_UI_POS" ) then
		
		DaHua_Time_On_ResetPos();
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		
		DaHua_Time_On_ResetPos();
	end
end

function DaHua_Time_Open()

end

function DaHua_Time_TimeOut()
	DaHua_Time_Time:SetProperty("Timer", tonumber(0));
	DaHua_Time_Time2:SetProperty("Timer", tonumber(0));
	DaHua_Time_Text:SetText("#{QXPVE_240522_39}")
	DaHua_Time_Time3Text:SetText("")
	DaHua_Time_Time2Text:SetText("活动已结束")
end

function DaHua_Time_OpenMini()

	this:Hide()
	PushEvent("QIXIPVE_XXS_MINI",0)
end