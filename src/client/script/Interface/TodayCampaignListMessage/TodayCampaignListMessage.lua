local	campaign_today = 0	--当天所有活动

function TodayCampaignListMessage_PreLoad()
	this:RegisterEvent("CAMPAIGN_TIPS_MESSAGE")
	this:RegisterEvent("CAMPAIGN_TIPS_MESSAGE_CLOSE")
end

function TodayCampaignListMessage_OnLoad()
end

function TodayCampaignListMessage_OnEvent(event)
	if event == "CAMPAIGN_TIPS_MESSAGE" then
		TodayCampaignListMessage_ListShow(arg0)
	end
	if event == "CAMPAIGN_TIPS_MESSAGE_CLOSE" then
		TodayCampaignListMessage_ListHide()
	end
end

function TodayCampaignListMessage_ListShow( TipsID )
	local tempID = tonumber( TipsID )
	if tempID == 10000 then
		--TodayCampaignListMessage_Window:SetText("#{HDRC_TIPS_01}")
		--TodayCampaignListMessage_UpdateRect()
		--this:Show()
	else
		local g_TodayCampaignCount = GetCampaignCount( tonumber(campaign_today) )
		for i = 0, g_TodayCampaignCount - 1 do
			if tempID == EnumCampaign( tonumber(campaign_today), i, "id" ) then
				local tmpStr = EnumCampaign( tonumber(campaign_today), i, "TipsStr" )
				TodayCampaignListMessage_Window:SetText(tmpStr)
				TodayCampaignListMessage_UpdateRect()
				this:Show()
				break
			end
		end
	end
	
end

function TodayCampaignListMessage_ListHide()
	this:Hide()
end

function TodayCampaignListMessage_UpdateRect()
	local nWidth, nHeight = TodayCampaignListMessage_Window:GetWindowSize()
	local nTitleHeight = 5
	local nBottomHeight = 5
	local nWindowHeight = nTitleHeight + nBottomHeight + nHeight
	TodayCampaignListMessage_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) )
end


