
local g_CaredObjectId = -1
local g_ServerTargetId = -1

function BieYeRankingList_ShowWinPrize_PreLoad()
	this:RegisterEvent("BIEYE_SHOW_WIN_PRIZE")
end

function BieYeRankingList_ShowWinPrize_OnLoad()
end

function BieYeRankingList_ShowWinPrize_BeginCareObject( serverId )
	BieYeRankingList_ShowWinPrize_StopCareObject()
	local clientId = DataPool:GetNPCIDByServerID(serverId)
	if clientId == -1 then
		return 0
	end
	this:CareObject( clientId, 1, "BieYeRankingList_ShowWinPrize" )
	g_ServerTargetId = serverId
	g_CaredObjectId = clientId
end

function BieYeRankingList_ShowWinPrize_StopCareObject()
	if g_CaredObjectId ~= -1 then
		this:CareObject(g_CaredObjectId, 0, "BieYeRankingList_ShowWinPrize")
		g_CaredObjectId = -1
	end
	g_ServerTargetId = -1
end								

function BieYeRankingList_ShowWinPrize_OnEvent(event)
	if event == "BIEYE_SHOW_WIN_PRIZE" then
		BieYeRankingList_ShowWinPrize_BeginCareObject( tonumber(arg0) )
		BieYeRankingList_ShowWinPrize_Show()
	end
end

function BieYeRankingList_ShowWinPrize_OnHide()
end

function BieYeRankingList_ShowWinPrize_OnClose()
	this:Hide()
end

function BieYeRankingList_ShowWinPrize_Show()
	this:Show()
end

function BieYeRankingList_ShowWinPrize_Ok()
end
