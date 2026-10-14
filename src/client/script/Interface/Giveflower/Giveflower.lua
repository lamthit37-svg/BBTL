
local g_tIndex = -1
local g_ServerTargetId = -1
local g_CaredObjectId = -1
local g_selected = -1
local g_item_rpc = { 38001983, 38001991 }

local g_item_check = {
	38001983, 38001988, 38001989, 38001990, 38001991,
}

function Giveflower_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BIEYE_COMFORT_TOPLIST_UPDATE_FLOWER")
end
	
function Giveflower_OnLoad()
	Giveflower_Desc_Text:SetText( ScriptGlobal_Format("#{BYRACE_170214_83}","1","29") )
end										

function Giveflower_OnEvent(event)
	if event  == "UI_COMMAND" and tonumber(arg0) == 89187703 then
		if Get_XParam_INT(4) == 1 then
			Giveflower_Show()
		else
			Giveflower_Update()
		end
	end
end

function Giveflower_BeginCareObject( serverId )
	Giveflower_StopCareObject()
	local clientId = DataPool:GetNPCIDByServerID(serverId)
	if clientId == -1 then
		return 0
	end
	this:CareObject( clientId, 1, "Giveflower" )
	g_ServerTargetId = serverId
	g_CaredObjectId = clientId
end

function Giveflower_StopCareObject()
	if g_CaredObjectId ~= -1 then
		this:CareObject(g_CaredObjectId, 0, "Giveflower")
		g_CaredObjectId = -1
	end
	g_ServerTargetId = -1
end

function Giveflower_RightItem()
end

function Giveflower_OnSelect(n)
	if n == 1 then
		Giveflower_NeedItem:SetPushed(1)
		Giveflower_NeedItem2:SetPushed(0)
	else
		Giveflower_NeedItem:SetPushed(0)
		Giveflower_NeedItem2:SetPushed(1)
	end
	g_selected = n
end

function Giveflower_Clear()
	Giveflower_NeedItem:SetPushed(0)
	Giveflower_NeedItem2:SetPushed(0)
	g_selected = -1
end

function Giveflower_Ok()
	if g_selected <= 0 then
		PushDebugMessage("#{BYRACE_170214_157}")
		return
	end
	local itemId = g_item_rpc[g_selected]
	BieYeUI:VoteComfortTopList( g_tIndex, g_ServerTargetId, itemId )
end

function Giveflower_OnClose()
	this:Hide()
end

function Giveflower_OnHide()
	Giveflower_Clear()
	Giveflower_StopCareObject()
end

function Giveflower_Update()
	g_tIndex = Get_XParam_INT(0)
	Giveflower_BeginCareObject(Get_XParam_INT(1))
	if Get_XParam_INT(2) > 0 then
		Giveflower_NeedItem:SetProperty("CornerChar","BotRight "..Get_XParam_INT(2) )
		Giveflower_NeedItem:SetProperty("BackImage","set:CircularTaskTool85 image:CircularTaskTool85_5")
		Giveflower_NeedItem_Mask:Hide()
		Giveflower_NeedItem_Mask:SetProperty("MouseHollow","True")
	else
		if g_selected == 1 then
			Giveflower_Clear()
		end
		Giveflower_NeedItem:SetProperty("CornerChar","BotRight 0" )
		Giveflower_NeedItem:SetProperty("BackImage","set:CircularTaskTool85 image:CircularTaskTool85_5")
		Giveflower_NeedItem_Mask:Show()
		Giveflower_NeedItem_Mask:SetProperty("MouseHollow","False")
	end
	if Get_XParam_INT(3) > 0 then
		Giveflower_NeedItem2:SetProperty("CornerChar","BotRight "..Get_XParam_INT(3) )
		Giveflower_NeedItem2:SetProperty("BackImage","set:CircularTaskTool85 image:CircularTaskTool85_6")
		Giveflower_NeedItem2_Mask:Hide()
		Giveflower_NeedItem2_Mask:SetProperty("MouseHollow","True")
	else
		if g_selected == 2 then
			Giveflower_Clear()
		end
		Giveflower_NeedItem2:SetProperty("CornerChar","BotRight 0" )
		Giveflower_NeedItem2:SetProperty("BackImage","set:CircularTaskTool85 image:CircularTaskTool85_6")
		Giveflower_NeedItem2_Mask:Show()
		Giveflower_NeedItem2_Mask:SetProperty("MouseHollow","False")
	end
	
	local d = BieYeUI:GetBieyeComfortToplistData(0)
	local name = d[g_tIndex+1][2]
	Giveflower_PageHeader_Name:SetText( ScriptGlobal_Format("#{BYRACE_170214_82}", name ) )
end

function Giveflower_Show()
	this:Show()
	Giveflower_Update()
end
