--!!!reloadscript =Fashion_Auction

local g_Fashion_Auction_Frame_UnifiedPosition

local g_CurSection = 0
local g_MaxPageCount = 5
local g_PageButtons = {}
local g_MaxPageItem = 20
local g_BarList = {}

local g_CurSectionTimeFlag = 0

local g_SectionTip = {
	"#{WHTJ_240117_115}",
	"#{WHTJ_240117_116}",
	"#{WHTJ_240117_117}",
	"#{WHTJ_240117_118}",
	"#{WHTJ_240117_119}",
}

local g_SectionStateText = {
	"#{WHTJ_240117_35}",
	"#{WHTJ_240117_36}",
	"#{WHTJ_240117_37}",
	"#{WHTJ_240117_38}",
	"#{WHTJ_240117_39}",
}


local g_Follow_Img = {
	normal = "set:Button1 image:BtnHelp_Normal",
	hover = "set:Button1 image:BtnHelp_Hover",
	pushed = "set:Button1 image:BtnHelp_Pushed",
}

local g_Not_Follow_Img = {
	normal = "set:Button1 image:BtnClose_Normal",
	hover = "set:Button1 image:BtnClose_Hover",
	pushed = "set:Button1 image:BtnClose_Pushed",
}

local g_TodaySection = -1
local g_TodaySectionStart = 0

local g_FashionCloth = 10127691

function Fashion_Auction_PreLoad()
	this:RegisterEvent("OPEN_FASHION_AUCTION_LIST")
	this:RegisterEvent("UPDATE_FASHION_AUCTION_CURRENT_LIST")
	this:RegisterEvent("UPDATE_FASHION_AUCTION_CERTAIN_LIST")
	--player quit game
	this:RegisterEvent("PLAYER_LEAVE_WORLD")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("UPDATE_YUANBAO")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REFRESH_FASHION_AUCTION_FOLLOW")
end

function Fashion_Auction_OnLoad()
	g_Fashion_Auction_Frame_UnifiedPosition = Fashion_Auction_Frame:GetProperty("UnifiedPosition")
	
	g_PageButtons[1] = Fashion_Auction_Page1_Sift1
	g_PageButtons[2] = Fashion_Auction_Page1_Sift2
	g_PageButtons[3] = Fashion_Auction_Page1_Sift3
	g_PageButtons[4] = Fashion_Auction_Page1_Sift4
	g_PageButtons[5] = Fashion_Auction_Page1_Sift5
end

function Fashion_Auction_OnEvent(event)

	if event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
		return
	end
	
	if event == "OPEN_FASHION_AUCTION_LIST" then
		if this:IsVisible() then
			this:Hide()
			return
		end
		local section = tonumber(arg0)
		g_TodaySection = tonumber(arg1)
		g_TodaySectionStart = tonumber(arg2)
		this:Show()
		Fashion_Auction_OnShown()
		g_CurSection = section
		Fashion_Auction_UpdatePageButton()
		Fashion_Auction_Update()
		return
	end
	
	if event == "UPDATE_FASHION_AUCTION_CURRENT_LIST" and this:IsVisible() then
		g_CurSection = tonumber(arg0)
		g_TodaySection = tonumber(arg1)
		g_TodaySectionStart = tonumber(arg2)
		Fashion_Auction_UpdatePageButton()
		Fashion_Auction_Update()
		return
	end
	
	if event == "UPDATE_FASHION_AUCTION_CERTAIN_LIST" and this:IsVisible() then
		local today_section = tonumber(arg1)
		local bStart = tonumber(arg2)
		if today_section ~= g_TodaySection or bStart ~= g_TodaySectionStart then
			Fashion_Auction_UpdatePageButton()
		end
		if g_CurSection == tonumber(arg0) then
			Fashion_Auction_Update()
		end
		return
	end
	
	if event == "REFRESH_FASHION_AUCTION_FOLLOW" and this:IsVisible() then
		if g_CurSection == tonumber(arg0) then
			Fashion_Auction_Update()
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		-- 更新背包界面位置
		Fashion_Auction_Frame_On_ResetPos()
	end
	
	if event == "UPDATE_YUANBAO" and this:IsVisible() then
		local strYuanBao = ScriptGlobal_Format("#{WHTJ_240117_34}", tostring(Player:GetData("YUANBAO")))
		Fashion_Auction_Page1_YuanbaoText:SetText(strYuanBao)
	end

	if event == "UI_COMMAND" and tonumber(arg0) == 77788801 then
		local have_yb = Get_XParam_INT(0)
		local have_bonus = Get_XParam_INT(1)
		
		if have_yb == 1 then
			Fashion_Auction_Page1_ReceiveYuanbaoTip:Show()
		else
			Fashion_Auction_Page1_ReceiveYuanbaoTip:Hide()
		end
		
		if have_bonus == 1 then
			Fashion_Auction_Page1_ReceivePropTip:Show()
		else
			Fashion_Auction_Page1_ReceivePropTip:Hide()
		end
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 77788802 then
		this:Hide()
	end
	
end

function Fashion_Auction_OnShown()
	local strYuanBao = ScriptGlobal_Format("#{WHTJ_240117_34}", tostring(Player:GetData("YUANBAO")))
	Fashion_Auction_Page1_YuanbaoText:SetText(strYuanBao)
	
	Fashion_Auction_Page2_ListItem_Icon:SetActionItem(-1)
	local theAction = DataPool:CreateActionItemForShow(g_FashionCloth, 1)
	if theAction:GetID() ~= 0 then
		Fashion_Auction_Page2_ListItem_Icon:SetActionItem(theAction:GetID())
	end
end

--Update
function Fashion_Auction_Update()
	Fashion_Auction_List_CleanUp()
	
	local all_set = 1
	local bid_start = 0
	
	for i = 1, g_MaxPageItem do	
		local group_index = DataPool:LuaFnGetFashionAuctionGroupIndexFromList(g_CurSection, i - 1)
		if tonumber(group_index) < 0 then
			break
		end
		
		Fashion_Auction_AddItem(i)
		
		local nTimeFlag = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "TIMEFLAG")
		
		if nTimeFlag ~= 1 and nTimeFlag ~= 2 then
			bid_start = 1
		end
		
		if nTimeFlag ~= 4 and nTimeFlag ~= 5 then
			all_set = 0
		end
	end
	
	if bid_start == 0 then
		if g_SectionStateText[g_CurSection + 1] ~= nil then
			Fashion_Auction_Page1_TipText:SetText(tostring(g_SectionStateText[g_CurSection + 1]))
		else
			Fashion_Auction_Page1_TipText:SetText("")
		end
	else
		if all_set == 0 then
			Fashion_Auction_Page1_TipText:SetText("#{WHTJ_240117_40}")
		else
			Fashion_Auction_Page1_TipText:SetText("#{WHTJ_240117_41}")
		end
	end
end

function Fashion_Auction_AddItem(idx)

	local new_bar = Fashion_Auction_Page1_List:AddChild("Fashion_Auction_Page1_ListItem")	
	g_BarList[idx] = new_bar
	
	local group_index = DataPool:LuaFnGetFashionAuctionGroupIndexFromList(g_CurSection, idx - 1)
	--道具ID
	local nItemTableIndex = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "ITEMID")
	--道具数量
	local uItemNum = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "ITEMNUM")
	--最高出价
	local nHighPrice = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "TOPBID")
	--最高出价人姓名
	local nHighName = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "NAME")
	--最高出价人的世界号
	local nHighZoneWorld = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "TOPWORLD")
	--当前时间标志
	local nTimeFlag = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "TIMEFLAG")
	--底价
	local nBaseValue = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "BASEPRICE")
	--是否有人出价
	local nHaveBid = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "HAVEBID")
	--当前是否是最高出价人
	local bIsTop = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "ISTOP")
	--是否关注
	local bFollowed = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "FOLLOW")

	new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Collect"):SetEvent("MouseButtonUp", string.format("Fashion_Auction_Follow(%d)", idx))
	
	new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Icon_Tips"):SetEvent("Clicked", string.format("Fashion_Auction_Preview(%d)", idx))

	if bFollowed == 1 then
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Collect"):SetCheck(1)
	else
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Collect"):SetCheck(0)
	end

	local theAction = DataPool:CreateActionItemForShow(nItemTableIndex, uItemNum)
	if theAction:GetID() ~= 0 then
		local ctrlAction = new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Icon")
		if ctrlAction ~= nil then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	end

	local item_name = DataPool:Lua_GetItemNameByIndex(nItemTableIndex)
	local strTemp = tostring(item_name)
	new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text1"):SetText(strTemp)
	
	local nFashionNumber = Exterior:LuaFnGetNumberingFashionInfo(nItemTableIndex, "NumberStr")
	new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text1Num"):SetText(tostring(nFashionNumber))

	if nHaveBid == 0 then
		local strNum = tostring(nBaseValue)
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text2"):SetText(strNum)
	else
		if bIsTop == 1 then
			local strNum = "#Y" .. tostring(nHighPrice)
			new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text2"):SetText(strNum)
		else
			local strNum = "#G" .. tostring(nHighPrice)
			new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text2"):SetText(strNum)
		end
	end
	
	if nTimeFlag == 1 or nTimeFlag == 2 then
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text3"):SetText("#{WHTJ_240117_26}")
	else
		if nHaveBid == 0 then
			new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text3"):SetText("#{WHTJ_240117_27}")
		else
			if bIsTop == 1 then
				new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text3"):SetText("#{WHTJ_240117_28}")
			else
				new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text3"):SetText("#{WHTJ_240117_29}")
			end
		end
	end
	
	if nTimeFlag == 1 or nTimeFlag == 2 then
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Name"):SetText("#{WHTJ_240117_26}")
	else
		if nHaveBid == 0 then
			new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Name"):SetText("#{WHTJ_240117_26}")
		else
			if nTimeFlag == 3 then
				if bIsTop == 1 then
					local my_name = Player:GetName()
					new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Name"):SetText(tostring(my_name))
				else
					new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Name"):SetText("#{WHTJ_240117_33}")
				end
			elseif nTimeFlag == 4 or nTimeFlag == 5 then
				if tonumber(nHighZoneWorld) ~= nil and tonumber(nHighZoneWorld) >= 0 then
					local myZoneWorld = DataPool:GetSelfZoneWorldID()
					if myZoneWorld ~= nHighZoneWorld then
						local strHighZoneWorldName = DataPool:GetServerName(tonumber(nHighZoneWorld))
						nHighName = nHighName.."@"..tostring(strHighZoneWorldName)
					end
				end
				local strHightName = tostring(nHighName)
				new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Name"):SetText(strHightName)
			else
				new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Name"):SetText("#{WHTJ_240117_26}")
			end
		end
	end
	
	new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Button"):Hide()
	new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Button"):SetEvent( "Clicked", string.format("Fashion_Auction_OpenBidUI(%d)", idx))
	
	--PushDebugMessage(tostring(nTimeFlag))
	if nTimeFlag == 1 or nTimeFlag == 2 then
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_BeforeText"):Show()
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_BeforeText"):SetText("#{WHTJ_240117_26}")
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text4"):Hide()
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Button"):Hide()
	elseif nTimeFlag == 3 then
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_BeforeText"):Hide()
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text4"):Hide()
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Button"):Show()
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Button"):SetText("#{WHTJ_240117_30}")
	elseif nTimeFlag == 4 or nTimeFlag == 5 then
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_BeforeText"):Hide()
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Text4"):Show()
		new_bar:GetSubItem("Fashion_Auction_Page1_ListItem_Button"):Hide()
	end
end

function Fashion_Auction_OpenBidUI(idx)

	local section = g_CurSection
	local group_index = DataPool:LuaFnGetFashionAuctionGroupIndexFromList(g_CurSection, idx - 1)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenBidUI")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_Parameter(0, 0)				--打开
		Set_XSCRIPT_Parameter(1, section)		--索引
		Set_XSCRIPT_Parameter(2, group_index)	--索引
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function Fashion_Auction_Follow(idx)
	local group_index = DataPool:LuaFnGetFashionAuctionGroupIndexFromList(g_CurSection, idx - 1)
	local bid_id = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "BIDINDEX")
	local bFollowed = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "FOLLOW")

	--PushDebugMessage("关注 - " .. tostring(bid_id))
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Follow")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_Parameter(0, bid_id)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	if g_BarList[idx] ~= nil then
		if bFollowed == 1 then
			g_BarList[idx]:GetSubItem("Fashion_Auction_Page1_ListItem_Collect"):SetCheck(1)
		else
			g_BarList[idx]:GetSubItem("Fashion_Auction_Page1_ListItem_Collect"):SetCheck(0)
		end
	end
end

function Fashion_Auction_Preview(idx)
	local group_index = DataPool:LuaFnGetFashionAuctionGroupIndexFromList(g_CurSection, idx - 1)
	local nItemTableIndex = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "ITEMID")
--	PushDebugMessage("试穿时装 - " .. tostring(nItemTableIndex))
--	DataPool:LuaFnFittingFashion(tonumber(nItemTableIndex))
--	PushEvent("OPEN_DRESSPREVIEW", 10125233, 74, 46)
	if tonumber(nItemTableIndex) ~= nil then
		PushEvent("OPEN_DRESSPREVIEW", tonumber(nItemTableIndex), 230, 170) --时装\发型\脸型
	end
end

function Fashion_Auction_List_CleanUp()
	for i = 1 , g_MaxPageItem do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("Fashion_Auction_Page1_ListItem_Icon")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end
	
	g_BarList = {}
	Fashion_Auction_Page1_List:Clear()
end

function Fashion_Auction_Equip_Clicked(buttonIn)

end

function Fashion_Auction_SwitchPage(page_index)
	if page_index == g_CurSection + 1 then
		return
	end
	
	g_CurSection = page_index - 1
	Fashion_Auction_UpdatePageButton()
	
	CloseWindow("Fashion_AuctionBidding", true)
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryOpenFashionAuction")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_Parameter(1, g_CurSection)
		Set_XSCRIPT_Parameter(2, 0) --是否收刷新cd限制
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
	for i = 1 , g_MaxPageItem do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("Fashion_Auction_Page1_ListItem_Icon")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end
	
	g_BarList = {}
	Fashion_Auction_Page1_List:Clear()
end

function Fashion_Auction_CloseClicked()
	this:Hide()
end

function Fashion_Auction_OnHidden()
	Fashion_Auction_List_CleanUp()
	Fashion_Auction_Page2_ListItem_Icon:SetActionItem(-1)
	CloseWindow("Fashion_AuctionBidding", true)
end

function Fashion_Auction_Help_Clicked()
	PushEvent("OPEN_SWEEPPAGE_QUEST", "Fashion_Auction_Help")
end

function Fashion_Auction_Shuaxin()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryOpenFashionAuction")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_Parameter(1, g_CurSection)
		Set_XSCRIPT_Parameter(2, 1) --是否收刷新cd限制
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Fashion_Auction_Get_Fashion()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TakeBonusFashion")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Fashion_Auction_Get_YuanBao()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TakeBackYuanBao")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Fashion_Auction_UpdatePageButton()
	for i = 1, g_MaxPageCount do
		g_PageButtons[i]:SetCheck(0)

		local section = i - 1
		if section > g_TodaySection then
			g_PageButtons[i]:SetProperty("NormalImage", "set:Fashion_Auction image:Fashion_Auction_ButtonNow_Disable")	--变灰
			g_PageButtons[i]:SetToolTip(tostring(g_SectionTip[i]))
		elseif section < g_TodaySection then
			g_PageButtons[i]:SetProperty("NormalImage", "set:Fashion_Auction image:Fashion_Auction_Button_Normal")	--正常
			g_PageButtons[i]:SetToolTip("#{WHTJ_240117_121}")
		else
			if g_TodaySectionStart == 1 then
				if g_CurSection == section then
					local all_set = 1
					for j = 1, g_MaxPageItem do	
						local group_index = DataPool:LuaFnGetFashionAuctionGroupIndexFromList(g_CurSection, j - 1)
						if tonumber(group_index) < 0 then
							break
						end
						local nTimeFlag = DataPool:LuaFnGetFashionAuctionBiddingInfo(g_CurSection, group_index, "TIMEFLAG")
						if nTimeFlag ~= 4 and nTimeFlag ~= 5 then
							all_set = 0
							break
						end
					end
					
					if all_set == 1 then
						g_PageButtons[i]:SetToolTip("#{WHTJ_240117_121}")
					else
						g_PageButtons[i]:SetToolTip("#{WHTJ_240117_120}")
					end
				end
				
				g_PageButtons[i]:SetProperty("NormalImage", "set:Fashion_Auction image:Fashion_Auction_Button_Normal")	--正常
			else
				g_PageButtons[i]:SetProperty("NormalImage", "set:Fashion_Auction image:Fashion_Auction_ButtonNow_Disable")	--变灰
				g_PageButtons[i]:SetToolTip(tostring(g_SectionTip[i]))
			end
		end
	end
	
	if g_CurSection >= 0 and g_CurSection < g_MaxPageCount then
		g_PageButtons[g_CurSection + 1]:SetCheck(1)
	end
end

function Fashion_Auction_Buy_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("BuyFashionCloth")
		Set_XSCRIPT_ScriptID(777888)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Fashion_Auction_Preview_Click()
	PushEvent("OPEN_DRESSPREVIEW", g_FashionCloth, 230, 170) --时装\发型\脸型
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function Fashion_Auction_Frame_On_ResetPos()
	Fashion_Auction_Frame:SetProperty("UnifiedPosition", g_Fashion_Auction_Frame_UnifiedPosition)
end
