local g_BanChenMiTime = 180 ;  --半沉迷时间3个小时
local g_ChenMiTime = 300;  --沉迷时间5个小时

function FangChenMiInfo_PreLoad()
	this:RegisterEvent("OPEN_FANGCHENMIINFO_DLG");
end

function FangChenMiInfo_OnLoad()
end

-- OnEvent
function FangChenMiInfo_OnEvent(event)
	if( event == "OPEN_FANGCHENMIINFO_DLG" ) then
		local OnlineTime = tonumber(arg0); --Min 为单位
		local OfflineTime = tonumber(arg1);
		if OnlineTime >= g_ChenMiTime then
			FangChenMiInfo_TimeCount_Income_Info:SetText("0%");
			FangChenMiInfo_Text:SetText("#{FCMX_90609_17}");
			FangChenMiInfo_Unhealthy:SetCheck(1);
		elseif OnlineTime >= g_BanChenMiTime then
			FangChenMiInfo_TimeCount_Income_Info:SetText("50%");
			FangChenMiInfo_Text:SetText("#{FCMX_90609_16}");
			FangChenMiInfo_Fatigue:SetCheck(1);
		else
			FangChenMiInfo_TimeCount_Income_Info:SetText("100%");
			FangChenMiInfo_Text:SetText("#{FCMX_90609_15}");
			FangChenMiInfo_Healthy:SetCheck(1);
		end
		
		local OnlineHour = math.floor(OnlineTime/60);
		local OfflineHour = math.floor(OfflineTime/60);
		local OnlineMin = OnlineTime - OnlineHour*60;
		local OfflineMin = OfflineTime - OfflineHour*60;
		
		if (OnlineHour > 100 ) then
			FangChenMiInfo_TimeCount_BigHour:Show();
			FangChenMiInfo_TimeCount_Hour1:Hide();
			FangChenMiInfo_TimeCount_Hour1_Info:Hide();
			FangChenMiInfo_TimeCount_Minute1:Hide();
			FangChenMiInfo_TimeCount_Minute1_Info:Hide();
		else
			FangChenMiInfo_TimeCount_BigHour:Hide();
			FangChenMiInfo_TimeCount_Hour1:Show();
			FangChenMiInfo_TimeCount_Hour1_Info:Show();
			FangChenMiInfo_TimeCount_Minute1:Show();
			FangChenMiInfo_TimeCount_Minute1_Info:Show();
			FangChenMiInfo_TimeCount_Hour1_Info:SetText(tostring(OnlineHour));
			FangChenMiInfo_TimeCount_Minute1_Info:SetText(OnlineMin);	
		end
		
		FangChenMiInfo_TimeCount_Hour2_Info:SetText(tostring(OfflineHour));
		FangChenMiInfo_TimeCount_Minute2_Info:SetText(OfflineMin);
		
		this:Show(); 
	end
end

function FangChenMiInfo_Healthy_Clicked()
	FangChenMiInfo_Text:SetText("#{FCMX_90609_15}")
end

function FangChenMiInfo_Fatigue_Clicked()
	FangChenMiInfo_Text:SetText("#{FCMX_90609_16}")
end

function FangChenMiInfo_UnHealthy_Clicked()
	FangChenMiInfo_Text:SetText("#{FCMX_90609_17}")
end

function FangChenMiInfo_OK_Click()
	this:Hide();
end


function FangChenMiInfo_GotoWeb()
	if(Variable:GetVariable("System_CodePage") == "1258") then
		--do nothing
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_FANGCHENMI"))
	end
end

function FangChenMiInfo_OnHide()
	this:Hide();
end

function FangChenMiInfo_Close()
	this:Hide();
end