
local g_ServerTargetId = -1
local g_CaredObjectId = -1
local g_max = 50
local g_last_num = "0"
local g_box_prize = 50000
local g_block = false


function BieYeRankingList_SetPrize_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

function BieYeRankingList_SetPrize_OnLoad()

end

function BieYeRankingList_SetPrize_BeginCareObject( serverId )
	BieYeRankingList_SetPrize_StopCareObject()
	local clientId = DataPool:GetNPCIDByServerID(serverId)
	if clientId == -1 then
		return 0
	end
	this:CareObject( clientId, 1, "BieYeRankingList_SetPrize" )
	g_ServerTargetId = serverId
	g_CaredObjectId = clientId
end

function BieYeRankingList_SetPrize_StopCareObject()
	if g_CaredObjectId ~= -1 then
		this:CareObject(g_CaredObjectId, 0, "BieYeRankingList_SetPrize")
		g_CaredObjectId = -1
	end
	g_ServerTargetId = -1
end							

function BieYeRankingList_SetPrize_OnEvent(event)
	if event  == "UI_COMMAND" and tonumber(arg0) == 89187704 then
		BieYeRankingList_SetPrize_Show()
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		BieYeRankingList_SetPrize_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	end
end

function BieYeRankingList_SetPrize_OnHide()
	BieYeRankingList_SetPrize_StopCareObject()
end

function BieYeRankingList_SetPrize_OnClose()
	this:Hide()
end

function BieYeRankingList_SetPrize_Show()
	BieYeRankingList_SetPrize_BeginCareObject(Get_XParam_INT(0))
	BieYeRankingList_SetPrize_Desc_Text:SetText(ScriptGlobal_Format("#{BYRACE_170214_133}",""..Get_XParam_INT(1),""..Get_XParam_INT(2)))
	g_max = Get_XParam_INT(2)
	BieYeRankingList_SetPrize_Num:SetText("0")
	g_last_num = "0"
	BieYeRankingList_SetPrize_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	this:Show()
end

function BieYeRankingList_SetPrize_OnAdd()
	local cur = BieYeRankingList_SetPrize_Num:GetText()
	BieYeRankingList_SetPrize_Num:SetText(string.format("%d",tonumber(cur)+1))
end

function BieYeRankingList_SetPrize_OnDec()
	local cur = BieYeRankingList_SetPrize_Num:GetText()
	BieYeRankingList_SetPrize_Num:SetText(string.format("%d",tonumber(cur)-1))
end

function BieYeRankingList_SetPrize_OnTimer()
	g_block = false
end

function BieYeRankingList_SetPrize_OnOk()
	if g_block then
		return
	end
	local num = BieYeRankingList_SetPrize_Num:GetText()
	if tonumber(num) <= 0 then
		return
	end
	BieYeUI:SetCplVoteGift( 0, tonumber(num) )
	this:Hide()
	KillTimer("BieYeRankingList_SetPrize_OnTimer()")
	SetTimer("BieYeRankingList","BieYeRankingList_SetPrize_OnTimer()", 2000)
	g_block = true
end

function BieYeRankingList_SetPrize_OnNumChanged()
	local cur = BieYeRankingList_SetPrize_Num:GetText()
	if not cur or cur == "" then
		BieYeRankingList_SetPrize_Num:SetText("0")
	elseif tonumber(cur) > g_max or tonumber(cur) < 0 then
		BieYeRankingList_SetPrize_Num:SetText(g_last_num)
	elseif g_box_prize * tonumber(cur) > Player:GetData("MONEY") then
		BieYeRankingList_SetPrize_Num:SetText(g_last_num)
	else
		BieYeRankingList_SetPrize_DemandMoney:SetProperty("MoneyNumber", tostring(g_box_prize * tonumber(cur)) )
		g_last_num = cur
	end
end
