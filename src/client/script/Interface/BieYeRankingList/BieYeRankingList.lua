
local g_listItems = {}
local g_ServerTargetId = -1
local g_CaredObjectId = -1
local g_myRanking = -1
local g_data = {}
local g_viewmode = -1

local g_menpaiName = {
	[0] = "少林", [1] = "明教", [2] = "丐帮", [3] = "武当", [4] = "峨嵋", [5] = "星宿", [6] = "天龙",
	[7] = "天山", [8] = "逍遥", [9] = "无门派", [10] = "慕容", [11] = "唐门", [12] = "鬼谷", [13] = "#{XQ_MP_15}", [14] = "#{XMPHM_210604_01}", --桃花岛
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}" --menpai15 mptodo
}

local g_styleimages = {
	{ "CircularTaskTool84", "CircularTaskTool84_16" },
	{ "CircularTaskTool85", "CircularTaskTool85_1" },
	{ "CircularTaskTool85", "CircularTaskTool85_2" },
	{ "CircularTaskTool84", "CircularTaskTool84_15" },
}

function BieYeRankingList_PreLoad()
	this:RegisterEvent("BIEYE_COMFORT_TOPLIST_DATA")
end
	
function BieYeRankingList_OnLoad()

end										

function BieYeRankingList_OnEvent(event)
	if event == "BIEYE_COMFORT_TOPLIST_DATA" then
		local tid = tonumber(arg0)
		if tid >= 0 then
			BieYeRankingList_BeginCareObject( tid )
			BieYeRankingList_OnShow()
		elseif this:IsVisible() then
			BieYeRankingList_UpdateData()
		end
	end
end

function BieYeRankingList_BeginCareObject( serverId )
	BieYeRankingList_StopCareObject()
	local clientId = DataPool:GetNPCIDByServerID(serverId)
	if clientId == -1 then
		return 0
	end
	this:CareObject( clientId, 1, "BieYeRankingList" )
	g_ServerTargetId = serverId
	g_CaredObjectId = clientId
end

function BieYeRankingList_StopCareObject()
	if g_CaredObjectId ~= -1 then
		this:CareObject(g_CaredObjectId, 0, "BieYeRankingList")
		g_CaredObjectId = -1
	end
	g_ServerTargetId = -1
end

function BieYeRankingList_OnHide()
	BieYeRankingList_StopCareObject()
	BieYeRankingList_List1:CleanAllElement("BieYeRankingList")
	g_data = {}
	g_listItems = {}
	g_viewmode = -1
	g_myRanking = -1
end

function BieYeRankingList_OnClose()
	this:Hide()
end

function BieYeRankingList_OnShow()
	this:Show()
	BieYeRankingList_UpdateData()
end

function BieYeRankingList_UpdateData()
	BieYeRankingList_List1:CleanAllElement("BieYeRankingList")
	g_nContentButton = {}
	local viewmode = tonumber(arg2)
	g_viewmode = viewmode
	g_data = BieYeUI:GetBieyeComfortToplistData(viewmode)
	g_myRanking = -1
	local myScore, myComfort = -1, -1
	for i,v in ipairs(g_data) do
		if v[2] == "" then
			break
		end
		if v[1] == tonumber(arg1) then
			myScore, myComfort = v[4], v[3]
			g_myRanking = tonumber(arg1)
		end
		local ItemBar = BieYeRankingList_List1:AddItemElement( "BieYeRankingList", "LEFT", "BieYeRankingList","" ,"")
		ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
		
		local childBtn1 = ItemBar:GetChildItem("BieYeRankingList","__auto_SuperBarButton1__")
		if childBtn1 then
			childBtn1:SetProperty("MouseMoveHollow","False")
			childBtn1:SetText("#{BYRACE_170214_63}")
			childBtn1:SetToolTip( ScriptGlobal_Format( "#{BYRACE_170214_64}", ""..v[2] ) )
		end
		local childBtn2 = ItemBar:GetChildItem("BieYeRankingList","__auto_SuperBarButton2__")
		if childBtn2 then
			childBtn2:SetProperty("MouseMoveHollow","False")
			childBtn2:SetText("#{BYRACE_170214_65}")
			childBtn2:SetToolTip("#{BYRACE_170214_66}")
		end
		local childBtn3 = ItemBar:GetChildItem("BieYeRankingList","__auto_SuperBarButton3__")
		if childBtn3 then
			if v[10] > 0 then
				childBtn3:Show()
				childBtn3:SetToolTip("#{BYRACE_170214_127}")
			else
				childBtn3:Hide()
			end
		end
		ItemBar:SetText1( ScriptGlobal_Format( "#{BYRACE_170214_126}", v[2] ) )
		ItemBar:SetText2( ScriptGlobal_Format( "#{BYRACE_170214_105}", ""..v[3] ) )

		local childImg2 = ItemBar:GetChildItem("BieYeRankingList","__auto_SuperBarImage2__")
		local childText3 = ItemBar:GetChildItem("BieYeRankingList","__auto_SuperBarText3__")
		if childText3 then
			childText3:SetProperty("HorzFormatting","RightAligned")
			if viewmode == 0 then
				childText3:SetText( "#{BYRACE_170214_128}" )
				if childImg2 then
					childImg2:Hide()
				end
			else
				childText3:SetText( string.format("%d",v[4]) )
				childText3:SetToolTip( "#{BYRACE_170214_129}" )
				if childImg2 then
					childImg2:Show()
				end
			end
		end
		
		local childImg3 = ItemBar:GetChildItem("BieYeRankingList","__auto_SuperBarImage3__")
		if childImg3 then
			childImg3:Show()
			childImg3:SetImage("Ach1",string.format("WDTXPMBtn_%d_Normal",i))
		end
		
		local image = g_styleimages[ v[9] ]
		if image then
			ItemBar:SetImage1( image[1], image[2] )
			ItemBar:SetImage1Show()
		end
		
		table.insert( g_nContentButton, ItemBar )
	end
	if table.getn( g_nContentButton) == 0 then
		BieYeRankingList_List0:Show()
		BieYeRankingList_List1:Hide()
	else
		BieYeRankingList_List0:Hide()
		BieYeRankingList_List1:Show()
		BieYeRankingList_List1:Flash()
	end
	if viewmode == 0 then
		BieYeRankingList_SetPrize:Hide()
		BieYeRankingList_Explain2_btntext:SetText("#{BYRACE_170214_57}")
	elseif viewmode == 1 then
		BieYeRankingList_SetPrize:Show()
		if myScore >= 0 then
			BieYeRankingList_Explain2_btntext:SetText("#{BYRACE_170214_123}")
			BieYeRankingList_SetPrize:Enable()
		else
			BieYeRankingList_Explain2_btntext:SetText("#{BYRACE_170214_124}")
			BieYeRankingList_SetPrize:Disable()
		end
	end
	if myScore >= 0 then
		if viewmode == 1 then
			BieYeRankingList_Flower_Icon:Show()
			BieYeRankingList_FirstScore:Show()
			BieYeRankingList_FirstScore:SetText("#{BYRACE_170214_58}"..myScore)
			BieYeRankingList_FirstScore:SetToolTip( "#{BYRACE_170214_59}" )
		else
			BieYeRankingList_Flower_Icon:Hide()
			BieYeRankingList_FirstScore:Show()
			BieYeRankingList_FirstScore:SetText( ScriptGlobal_Format( "#{BYRACE_170214_105}", ""..myComfort ) )
			BieYeRankingList_FirstScore:SetToolTip( "#{BYRACE_170214_106}" )
		end
	else
		BieYeRankingList_Flower_Icon:Hide()
		BieYeRankingList_FirstScore:Hide()
	end
	
end

function BieYeRankingList_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if not nIndex then
		return
	end
	for i,v in ipairs(g_nContentButton) do
		v:SetBarButtonSelected(false)
	end
end

function BieYeRankingList_OnItemRClick()
	
end

function BieYeRankingList_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if not nIndex then
		return
	end
	local nRanking = g_data[ nIndex + 1 ] [1]
	BieYeUI:EnterComfortTopList( nRanking )
end

function BieYeRankingList_OnButton2Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if not nIndex then
		return
	end
	local nRanking = g_data[ nIndex + 1 ] [1]
	BieYeUI:VoteComfortTopList( nRanking, g_ServerTargetId, -1 )
	if IsWindowShow( "Giveflower" ) then
		CloseWindow( "Giveflower", true )
	end
end

function BieYeRankingList_OnCheckMe()
	if g_myRanking < 0 then
		PushDebugMessage("#{BYRACE_170214_71}")
		return
	end
	local viewPos = 0
	for i,v in ipairs(g_nContentButton) do
		if g_myRanking == g_data[ i ] [1] then
			v:SetBarButtonSelected(true)
			viewPos = i - 1
		else
			v:SetBarButtonSelected(false)
		end
	end
	BieYeRankingList_List1:SetVertScrollbarPosition(80.0*viewPos)
end

function BieYeRankingList_OnRefresh()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientGetData")
		Set_XSCRIPT_ScriptID(891877)
		Set_XSCRIPT_Parameter(0, g_ServerTargetId )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function BieYeRankingList_OnSetPrize()
	if g_myRanking < 0 then
		PushDebugMessage("#{BYRACE_170214_130}")
		return
	end
	if IsWindowShow( "BieYeRankingList_SetPrize" ) then
		CloseWindow( "BieYeRankingList_SetPrize", true )
	end
	BieYeUI:SetCplVoteGift(1,0)
end

function BieYeRankingList_OnShowPrize()
	if IsWindowShow( "BieYeRankingList_ShowWinPrize" ) then
		CloseWindow( "BieYeRankingList_ShowWinPrize", true )
	end
	PushEvent("BIEYE_SHOW_WIN_PRIZE",g_ServerTargetId)
end

function BieYeRankingList_OnShowHelp()
	local bOnList = 1
	if g_myRanking < 0 then
		bOnList = 0
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientGetHelp")
		Set_XSCRIPT_ScriptID(891877)
		Set_XSCRIPT_Parameter( 0, g_ServerTargetId )
		Set_XSCRIPT_Parameter( 1, g_viewmode )
		Set_XSCRIPT_Parameter( 2, bOnList )
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()
end
