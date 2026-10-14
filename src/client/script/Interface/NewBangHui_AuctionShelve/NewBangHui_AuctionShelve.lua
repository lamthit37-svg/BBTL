local g_NewBangHui_AuctionShelve_Frame_UnifiedPosition
local g_auctionListCount = 0
local g_aucitonBiddingListCount = 0
local g_BarList = {}
local g_BarBiddingList = {}
-----------------------------------------------------------------------
-- OnGameEvent
-----------------------------------------------------------------------
function NewBangHui_AuctionShelve_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("UPDATE_GUID_AUCITON_ITEM",true)
	this:RegisterEvent("UPDATE_GUID_AUCITON_ITEM_BIDDING",true)

end

function NewBangHui_AuctionShelve_OnLoad()
	g_NewBangHui_AuctionShelve_Frame_UnifiedPosition = NewBangHui_AuctionShelve_Frame:GetProperty("UnifiedPosition")
end

function NewBangHui_AuctionShelve_OnEvent(event)
	if (event == "PLAYER_LEAVE_WORLD") then
		NewBangHui_AuctionShelve_OnHiden()
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_AuctionShelve_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_AuctionShelve_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD" ) then	
		NewBangHui_AuctionShelve_On_ResetPos()
	elseif event == "UPDATE_GUID_AUCITON_ITEM" then -- 更新缓存上架信息
		local nShow = tonumber(arg0)
		if this:IsVisible() then 
			NewBangHui_AuctionShelve_Update()
		else
			if nShow == 1 then
				NewBangHui_AuctionShelve_Update()
				this:Show()
			end
		end
	elseif event == "UPDATE_GUID_AUCITON_ITEM_BIDDING" then --更新竞价信息
		NewBangHui_AuctionShelve_Update()
		this:Show()
	end
end

function NewBangHui_AuctionShelve_On_ResetPos()
	NewBangHui_AuctionShelve_Frame:SetProperty("UnifiedPosition", g_NewBangHui_AuctionShelve_Frame_UnifiedPosition)

end

function NewBangHui_AuctionShelve_CleanUp()

	g_BarList = {}
	g_BarBiddingList={}

	g_auctionListCount = 0
	g_aucitonBiddingListCount = 0
	NewBangHui_AuctionShelve_List:Clear()
end

--Update
function NewBangHui_AuctionShelve_Update()

	NewBangHui_AuctionShelve_CleanUp()

	-- 设置当前列数
	local aucitonList = DataPool:Lua_GetGuildAuctionCount(1)
	for i = 1, aucitonList do	
		NewBangHui_AuctionShelve_AddItem(i,0)
	end
	g_auctionListCount = aucitonList


	local auctionBidding = DataPool:Lua_GetGuildAuctionBiddingCount()
	for i = 1, auctionBidding do	
		NewBangHui_AuctionShelve_AddItem(i,1)
	end
	g_aucitonBiddingListCount = auctionBidding

end

function NewBangHui_AuctionShelve_AddItem(idx,nType)
	local new_bar = NewBangHui_AuctionShelve_List:AddChild("NewBangHui_AuctionShelve_ListItem")	
	if nType == 0 then
		g_BarList[idx] = new_bar
		local nId, itemid,ncount,ntype,nstate = DataPool:Lua_GetGuildAuctionItemInfo(1,idx-1)
		if nId >= 0  then

			local theAction = DataPool:CreateBindActionItemForShow(itemid, ncount)
			if theAction:GetID() ~= 0 then
				local ctrlAction = new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Icon")
				if ctrlAction ~= nil then
					ctrlAction:SetActionItem(theAction:GetID())
				end
			end

			-- 名字
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Text1"):SetText(DataPool:Lua_GetItemNameByIndex(itemid))
			-- 阶段
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Text2"):SetText("#{SCBHPM_20220815_208}")
			
			--竞拍按钮
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Cancel"):SetText("#{SCBHPM_20220815_187}")
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Cancel"):SetToolTip("#{SCBHPM_20220815_188}")
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Cancel"):SetEvent( "Clicked", string.format("NewBangHui_AuctionShelve_UnderItem(%d)", idx-1))
		end
	else
		g_BarBiddingList[idx] = new_bar
		local nId, itemid,ncount,ntype,nstate = DataPool:Lua_GetGuildAuctionBiddingItemInfo(idx-1)
		if nId >= 0  then
			local theAction = DataPool:CreateBindActionItemForShow(itemid, ncount)
			if theAction:GetID() ~= 0 then
				local ctrlAction = new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Icon")
				if ctrlAction ~= nil then
					ctrlAction:SetActionItem(theAction:GetID())
				end
			end

			-- 名字
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Text1"):SetText(DataPool:Lua_GetItemNameByIndex(itemid))

			-- 阶段
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Text2"):SetText("#{SCBHPM_20220815_209}")
			
			--竞拍按钮
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Cancel"):SetText("#{SCBHPM_20220815_187}")
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Cancel"):SetToolTip("#{SCBHPM_20220815_188}")
			new_bar:GetSubItem("NewBangHui_AuctionShelve_ListItem_Cancel"):Disable()
		end

	end
	
end

function NewBangHui_AuctionShelve_UnderItem(idx)

	local nId, itemid,ncount,ntype,nstate = DataPool:Lua_GetGuildAuctionItemInfo(1,idx)
	if nId >= 0 then
		--请求缓存数据
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GuildAuctionUnderItem")
			Set_XSCRIPT_ScriptID(999710)
			Set_XSCRIPT_Parameter(0, nId)	
			Set_XSCRIPT_Parameter(1, itemid)	
			Set_XSCRIPT_Parameter(2, ncount)
			Set_XSCRIPT_Parameter(3, ntype)	
			Set_XSCRIPT_Parameter(4, 0)	
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	end
end

function NewBangHui_AuctionShelve_Close_Clicked()
	NewBangHui_AuctionShelve_CleanUp()
	this:Hide()
end

function NewBangHui_AuctionShelve_OnHiden()
	this:Hide()
end 