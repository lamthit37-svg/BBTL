local g_TodayCampaignListNewTime_Frame_UnifiedXPosition
local g_TodayCampaignListNewTime_Frame_UnifiedYPosition
local g_TodayCampaignListNewTime_Week =
{ 
	[0] = "#G星期日",
	[1] = "#G星期一",
	[2] = "#G星期二",
	[3] = "#G星期三",
	[4] = "#G星期四",
	[5] = "#G星期五",
	[6] = "#G星期六",
}
--===============================================
-- OnLoad()
--===============================================
function TodayCampaignListNewTime_PreLoad() 
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面 
	this:RegisterEvent("OPEN_CAMPAIGN_TIMENEW",true)	--  
	this:RegisterEvent("CLOSE_CAMPAIGN_TIMENEW",false)	--  
	
end
	
function TodayCampaignListNewTime_OnLoad()
	g_TodayCampaignListNewTime_Frame_UnifiedXPosition	= TodayCampaignListNewTime_Frame : GetProperty("UnifiedXPosition");
	g_TodayCampaignListNewTime_Frame_UnifiedYPosition	= TodayCampaignListNewTime_Frame : GetProperty("UnifiedYPosition");
end										


--===============================================
-- OnEvent
--===============================================
function TodayCampaignListNewTime_OnEvent(event)

	if(event == "OPEN_CAMPAIGN_TIMENEW") then 
		if this:IsVisible() then
			this:Hide()
			return
		end
		local strInfo 	= tostring( arg0 ); 
		local strName 	= tostring( arg1 ); 
		TodayCampaignListNewTime_DragTitle:SetText("#cfff263"..strName);
		TodayCampaignListNewTime_UpdateFrame(strInfo)
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		TodayCampaignListNewTime_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TodayCampaignListNewTime_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then  
		this:Hide()
	elseif (event == "CLOSE_CAMPAIGN_TIMENEW") then  
		this:Hide()
	end 
end

function TodayCampaignListNewTime_Frame_On_ResetPos() 
	TodayCampaignListNewTime_Frame : SetProperty("UnifiedXPosition", g_TodayCampaignListNewTime_Frame_UnifiedXPosition);
	TodayCampaignListNewTime_Frame : SetProperty("UnifiedYPosition", g_TodayCampaignListNewTime_Frame_UnifiedYPosition);
end

function TodayCampaignListNewTime_UpdateFrame(StrInfo) 
	--local nCount,TimeType,CampaignType = GetCampaignCountByClass(nClass) 
	--local StrInfo = ""
	--for i = 1 , nCount do
	--	local nBegDay,nBegTime,nEndDay,nEndTime = GetCampaignInfoByClass(nClass,i)  
	--	local nBeghour = math.floor(nBegTime/100)
	--	local nBegMin	 = math.mod( nBegTime, 100); 
	--	----------------------------------------------------------------------------
	--	local strBeghour = tostring(nBeghour)
	--	if nBeghour == 0 then
	--		strBeghour = "00"
	--	end
	--	local strBegMin = tostring(nBegMin)
	--	if nBegMin == 0 then
	--		strBegMin = "00"
	--	end
	--	local strBegTime  = strBeghour..":"..strBegMin
	--	----------------------------------------------------------------------------
	--	local nEndhour = math.floor(nEndTime/100)
	--	local nEndMin	 = math.mod( nEndTime, 100); 
	--	local strEndhour = tostring(nEndhour)
	--	if nEndhour == 0 then
	--		strEndhour = "00"
	--	end
	--	local strEndMin = tostring(nEndMin)
	--	if nEndMin == 0 then
	--		strEndMin = "00"
	--	end
	--	----------------------------------------------------------------------------
	--	local strEndTime  = strEndhour..":"..strEndMin
	--	if TimeType == 1 then -- 每天
	--		StrInfo = StrInfo..ScriptGlobal_Format("#{HDRC_170722_36}", tostring(strBegTime),tostring(strEndTime))
	--	end 
	--	if TimeType == 2 then -- 星期
	--		StrInfo = StrInfo..g_TodayCampaignListNewTime_Week[nBegDay]..ScriptGlobal_Format("#{HDRC_170722_37}", tostring(strBegTime),tostring(strEndTime))
	--	end 
	--	if i ~= nCount then
	--		StrInfo = StrInfo.."#cfff263、"
	--	end
	--end
	TodayCampaignListNewTime_Text1:SetText(StrInfo)
end
