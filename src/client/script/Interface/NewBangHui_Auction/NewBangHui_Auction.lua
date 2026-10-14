--NewBangHui_Auction

local g_NewBangHui_Auction_UnifiedPosition = ""

local g_NewBangHui_Auction_Page1_Filter = {}
local g_NewBangHui_Auction_Page2_Filter = {}

local g_ListDataDate = 0

local g_BarList = {}
local g_BarList2 = {}

local g_CaredObjServerID = -1

local g_CurPage1 = 0
local g_CurPage2 = 0

local g_CurFenYe = 0

local g_MaxPageItem = 8

local g_CurrentFilter = 100

local g_MyFavoriteNum = 0

local g_IsHaveChongLou = 0

-- 城战轮换（霸者天下）助战操作时间
local NewBangHui_Auction_AssistOpTime =
{
    [1] = {weekday = 5, begintime = 213000},
    [2] = {weekday = 6, endtime = 202000},
} -- end NewBangHui_Auction_AssistOpTime

--阶段 0：无拍卖 1：公示期 2：拍卖中 3：结果展示期 4:展示结束至领奖结束期间

local g_IsZhanTuan = 0  -- 是否是 暂时屏蔽了。不会赋值

--===============================================
-- PreLoad
--===============================================
function NewBangHui_Auction_PreLoad()

	this:RegisterEvent("GUILD_BIDDING_SHOWLIST")
	--游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	--游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO")
	this:RegisterEvent("GUILD_SHOW_DETAILINFO")
	this:RegisterEvent("ZHANTUAN_LIST_DATA")
	this:RegisterEvent("OPEN_BUILD_INTRODUCE")
	this:RegisterEvent("GUILD_LEAGUE_INFO")
	this:RegisterEvent("GUILD_SHOW_ENEMYLIST")
	this:RegisterEvent("OPEN_GUILD_GIFT")
	this:RegisterEvent("GUILD_ZHANTUAN_OP")
	--this:RegisterEvent("TCITYWARLIMIT_OPENCANDIDATE")
end

--===============================================
-- OnLoad
--===============================================
function NewBangHui_Auction_OnLoad()
	g_NewBangHui_Auction_UnifiedPosition = NewBangHui_Auction_Frame:GetProperty("UnifiedPosition")

	g_NewBangHui_Auction_Page1_Filter[0] = NewBangHui_Auction_Page1_Sift1
	g_NewBangHui_Auction_Page1_Filter[1] = NewBangHui_Auction_Page1_Sift2
	g_NewBangHui_Auction_Page1_Filter[2] = NewBangHui_Auction_Page1_Sift3
	g_NewBangHui_Auction_Page1_Filter[3] = NewBangHui_Auction_Page1_Sift4

	g_NewBangHui_Auction_Page2_Filter[0] = NewBangHui_Auction_Page2_Sift1
	g_NewBangHui_Auction_Page2_Filter[1] = NewBangHui_Auction_Page2_Sift2
	g_NewBangHui_Auction_Page2_Filter[2] = NewBangHui_Auction_Page2_Sift3
	g_NewBangHui_Auction_Page2_Filter[3] = NewBangHui_Auction_Page2_Sift4
end

--===============================================
-- OnEvent
--===============================================
function NewBangHui_Auction_OnEvent(event)

	if event == "GUILD_BIDDING_SHOWLIST" then
		local nOperation = tonumber(arg0)
		g_CurFenYe = tonumber(arg1) -- 0：世界 1：帮会
		g_CurrentFilter = tonumber(arg2)
		g_MyFavoriteNum = tonumber(arg3)
		g_IsHaveChongLou = tonumber(arg4)
--		g_IsZhanTuan = tonumber(arg5) -- 暂时没有了

		if g_CurrentFilter == -1 then
			g_CurrentFilter = 100
		end

		if nOperation == 0 then	--开启
			g_CurPage1 = 0
			g_CurPage2 = 0

			local selfGuildClanUnionPos = Variable:GetVariable("SelfGuildClanUnionPos")
			if( selfGuildClanUnionPos ~= nil) then
	    		NewBangHui_Auction_Frame:SetProperty("UnifiedPosition", selfGuildClanUnionPos )
			end
			NewBangHui_Auction_Auction:SetCheck(1)
			NewBangHui_Auction_SetTitle()
--			PushDebugMessage("TESTshowlist:"..g_CurFenYe.."-"..g_CurrentFilter.."-"..g_IsZhanTuan)
			if g_IsZhanTuan == 1 then
				NewBangHui_Auction_Update_Fenye3()
			elseif g_CurFenYe == 1 then
				NewBangHui_Auction_Update_Fenye1()
			elseif g_CurFenYe == 0 then
				NewBangHui_Auction_Update_Fenye2()
			end
			this:Show()

			-- -- 霸者天下小红点
			-- local bztxApplyNum = DataPool:TCWLGetAssistApplyNum()
			-- local bztxIsInTime = NewBangHui_Auction_Check_BZTXAssistEnrollTime()
			-- if (bztxIsInTime > 0) then
			-- 	if (bztxApplyNum <= 0) then
			-- 		NewBangHui_Auction_BZTX_Tips:Hide()
			-- 	else
			-- 		local isChiefOrAss = Guild:IsChieforAss()
			-- 		if (isChiefOrAss ~= 1) then
			-- 			NewBangHui_Auction_BZTX_Tips:Hide()
			-- 		else
			-- 			NewBangHui_Auction_BZTX_Tips:Show()
			-- 		end
			-- 	end
			-- else
			-- 	NewBangHui_Auction_BZTX_Tips:Hide()
			-- end
		elseif nOperation == 1 then --刷新
			if this:IsVisible() then
--				PushDebugMessage("TESTshuaxin:"..g_CurFenYe.."-"..g_CurrentFilter.."-"..g_IsZhanTuan)
				if g_IsZhanTuan == 1 then
					NewBangHui_Auction_Update_Fenye3()
				elseif g_CurFenYe == 1 then
					NewBangHui_Auction_Update_Fenye1()
				elseif g_CurFenYe == 0 then
					NewBangHui_Auction_Update_Fenye2()
				end
			end
		end
	end

	--刷新元宝
	if event == "UPDATE_YUANBAO" then
		if this:IsVisible() then
			if g_IsZhanTuan == 1 then
				NewBangHui_Auction_Update_Fenye3()			
			elseif g_CurFenYe == 0 then
				NewBangHui_Auction_Update_Fenye2()
			elseif g_CurFenYe == 1 then
				NewBangHui_Auction_Update_Fenye1()
			end
		end
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NewBangHui_Auction_Frame_On_ResetPos()
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	if event == "GUILD_SHOW_MEMBERINFO" then
		this:Hide()
	end
	if event == "GUILD_SHOW_DETAILINFO" then
		this:Hide()
	end
	if event == "GUILD_LEAGUE_INFO" then
		this:Hide()
	end
	if event == "GUILD_SHOW_ENEMYLIST" then
		this:Hide()
	end
	if event == "ZHANTUAN_LIST_DATA" then
		this:Hide()
	end
	if event == "OPEN_BUILD_INTRODUCE" then
		this:Hide()
	end
	if event == "OPEN_GUILD_GIFT" then
		this:Hide()
	end
	if event == "TCITYWARLIMIT_OPENCANDIDATE" then
		this:Hide()
	end
	if event == "GUILD_ZHANTUAN_OP" then
		this:Hide()
	end
end

--**********************************
--帮会拍卖--刷新界面
--**********************************
function NewBangHui_Auction_Update_Fenye1()
	NewBangHui_Auction_Frame2_PageBtn1:SetCheck(1)
	NewBangHui_Auction_Frame2_PageBtn2:SetCheck(0)
--	NewBangHui_Auction_Frame2_PageBtn3:SetCheck(0)
	NewBangHui_Auction_Page1:Show()
	NewBangHui_Auction_Page2:Hide()
	NewBangHui_Auction_Page1_AuctionShelve:Show()

	--子页签
	if g_CurrentFilter < 0 or (g_CurrentFilter > 3 and g_CurrentFilter ~= 100) then
		g_CurrentFilter = 100
	end	
	--是否显示重楼
	for i = 0, 3 do
		if i == 1 and g_IsHaveChongLou == 0 then
			g_NewBangHui_Auction_Page1_Filter[i]:Hide()
		else
			g_NewBangHui_Auction_Page1_Filter[i]:Show()
			if g_CurrentFilter == i-1 then
				g_NewBangHui_Auction_Page1_Filter[i]:SetCheck(1)
			else
				g_NewBangHui_Auction_Page1_Filter[i]:SetCheck(0)
			end
		end
	end

	if g_CurrentFilter == 100 then
		g_NewBangHui_Auction_Page1_Filter[0]:SetCheck(1)
	end

	local nTimeStage = DataPool:LuaFnGetGuildBiddingStage()

	--界面上方文字
	if nTimeStage == 0 or nTimeStage == 4 then --休业期
		NewBangHui_Auction_Page1_List:Hide()
		NewBangHui_Auction_Page1_NoList:Show()
		NewBangHui_Auction_Page1_NoList:SetText("#{SCBHPM_20220815_153}")

		NewBangHui_Auction_Page1_UpPage:Disable()
		NewBangHui_Auction_Page1_DownPage:Disable()
		NewBangHui_Auction_Page1_CurrentlyPage:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_32}", 1, 1))
	else
		NewBangHui_Auction_Page1_NoList:Hide()

		local g_MaxItem = DataPool:LuaFnGetGuildBiddingItemCount()

		if g_MaxItem == 0 then
			--道具列表
			NewBangHui_Auction_Page1_List:Hide()
			--无竞拍文字
			NewBangHui_Auction_Page1_NoList:Show()
			NewBangHui_Auction_Page1_NoList:SetText("#{SCBHPM_20220815_152}")

			NewBangHui_Auction_Page1_UpPage:Disable()
			NewBangHui_Auction_Page1_DownPage:Disable()
			NewBangHui_Auction_Page1_CurrentlyPage:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_32}", 1, 1))
		else
			--道具列表
			NewBangHui_Auction_Page1_List:Show()

			NewBangHui_Auction_CleanUp_Fenye1()

			for i = 1, g_MaxPageItem do

				local index = i + g_CurPage1 * g_MaxPageItem
				local nBonusItemIndex = DataPool:LuaFnGetGuildBiddingInfo(index - 1, "ITEMID")

				if tonumber(nBonusItemIndex) <= 0 then
					break
				end

				NewBangHui_Auction_AddItem_Fenye1(index)

			end

			local realPage = g_CurPage1 + 1
			local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
			if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
				nMaxPage = nMaxPage + 1
			end

			if g_CurPage1 == 0 then
				NewBangHui_Auction_Page1_UpPage:Disable()
			else
				NewBangHui_Auction_Page1_UpPage:Enable()
			end

			if realPage >= nMaxPage then
				NewBangHui_Auction_Page1_DownPage:Disable()
			else
				NewBangHui_Auction_Page1_DownPage:Enable()
			end

			local strTemp = ScriptGlobal_Format("#{SCBHPM_20220815_32}", tostring(realPage), tostring(nMaxPage))
			NewBangHui_Auction_Page1_CurrentlyPage:SetText(strTemp)

		end
	end

	--帮会分红
	--local nLijin = DataPool:LuaFnGetGuildBiddingLijin()
	--if nTimeStage == 3 or nTimeStage == 4 then --拍卖结束到奖励可领取
	--	NewBangHui_Auction_Page1_BonusText_1:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_44}", tostring(nLijin)))
	--else
	--	NewBangHui_Auction_Page1_BonusText_1:SetText("#{SCBHPM_20220815_43}")
	--end

	--显示文字
	if nTimeStage == 1 then --公示期
		NewBangHui_Auction_Page1_BeginTips:SetText("#{SCBHPM_20220815_30}")
	else
		NewBangHui_Auction_Page1_BeginTips:SetText("")
	end

	--拥有元宝
	local nHaveYB = Player:GetData("YUANBAO")
	NewBangHui_Auction_Page1_YuanbaoText_1:SetText(ScriptGlobal_Format("#{FMPM_220815_25}",nHaveYB))

end

--**********************************
--战团逻辑修改
--**********************************
function NewBangHui_Auction_Update_Fenye3()
	-- 暂时屏蔽
	if g_IsZhanTuan == 0 then
		return
	end

	NewBangHui_Auction_Frame2_PageBtn1:SetCheck(0)
	NewBangHui_Auction_Frame2_PageBtn2:SetCheck(0)
--	NewBangHui_Auction_Frame2_PageBtn3:SetCheck(1)
	NewBangHui_Auction_Page1:Show()
	NewBangHui_Auction_Page2:Hide()
	NewBangHui_Auction_Page1_AuctionShelve:Show()

	--子页签
	if g_CurrentFilter < 0 or (g_CurrentFilter > 3 and g_CurrentFilter ~= 100) then
		g_CurrentFilter = 100
	end	
	--是否显示重楼
	for i = 0, 3 do
		if i == 1 and g_IsHaveChongLou == 0 then
			g_NewBangHui_Auction_Page1_Filter[i]:Hide()
		else
			g_NewBangHui_Auction_Page1_Filter[i]:Show()
			if g_CurrentFilter == i-1 then
				g_NewBangHui_Auction_Page1_Filter[i]:SetCheck(1)
			else
				g_NewBangHui_Auction_Page1_Filter[i]:SetCheck(0)
			end
		end
	end

	if g_CurrentFilter == 100 then
		g_NewBangHui_Auction_Page1_Filter[0]:SetCheck(1)
	end


	local nTimeStage = DataPool:LuaFnGetGuildBiddingStage()

	--界面上方文字
	if nTimeStage == 0 or nTimeStage == 4 then --休业期
		NewBangHui_Auction_Page1_List:Hide()
		NewBangHui_Auction_Page1_NoList:Show()
		NewBangHui_Auction_Page1_NoList:SetText("#{SCBHPM_20220815_153}")

		NewBangHui_Auction_Page1_UpPage:Disable()
		NewBangHui_Auction_Page1_DownPage:Disable()
		NewBangHui_Auction_Page1_CurrentlyPage:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_32}", 1, 1))
	else
		NewBangHui_Auction_Page1_NoList:Hide()

		local g_MaxItem = DataPool:LuaFnGetGuildBiddingItemCount()

		if g_MaxItem == 0 then
			--道具列表
			NewBangHui_Auction_Page1_List:Hide()
			--无竞拍文字
			NewBangHui_Auction_Page1_NoList:Show()
			NewBangHui_Auction_Page1_NoList:SetText("#{SCBHPM_20220815_152}")

			NewBangHui_Auction_Page1_UpPage:Disable()
			NewBangHui_Auction_Page1_DownPage:Disable()
			NewBangHui_Auction_Page1_CurrentlyPage:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_32}", 1, 1))
		else
			--道具列表
			NewBangHui_Auction_Page1_List:Show()

			NewBangHui_Auction_CleanUp_Fenye1()

			for i = 1, g_MaxPageItem do

				local index = i + g_CurPage1 * g_MaxPageItem
				local nBonusItemIndex = DataPool:LuaFnGetGuildBiddingInfo(index - 1, "ITEMID")

				if tonumber(nBonusItemIndex) <= 0 then
					break
				end

				NewBangHui_Auction_AddItem_Fenye1(index)

			end

			local realPage = g_CurPage1 + 1
			local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
			if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
				nMaxPage = nMaxPage + 1
			end

			if g_CurPage1 == 0 then
				NewBangHui_Auction_Page1_UpPage:Disable()
			else
				NewBangHui_Auction_Page1_UpPage:Enable()
			end

			if realPage >= nMaxPage then
				NewBangHui_Auction_Page1_DownPage:Disable()
			else
				NewBangHui_Auction_Page1_DownPage:Enable()
			end

			local strTemp = ScriptGlobal_Format("#{SCBHPM_20220815_32}", tostring(realPage), tostring(nMaxPage))
			NewBangHui_Auction_Page1_CurrentlyPage:SetText(strTemp)

		end
	end

	--帮会分红
	--local nLijin = DataPool:LuaFnGetGuildBiddingLijin()
	--if nTimeStage == 3 or nTimeStage == 4 then --拍卖结束到奖励可领取
	--	NewBangHui_Auction_Page1_BonusText_1:SetText(ScriptGlobal_Format("#{SCBHPM_20220815_44}", tostring(nLijin)))
	--else
	--	NewBangHui_Auction_Page1_BonusText_1:SetText("#{SCBHPM_20220815_43}")
	--end

	--显示文字
	if nTimeStage == 1 then --公示期
		NewBangHui_Auction_Page1_BeginTips:SetText("#{SCBHPM_20220815_30}")
	else
		NewBangHui_Auction_Page1_BeginTips:SetText("")
	end

	--拥有元宝
	local nHaveYB = Player:GetData("YUANBAO")
	NewBangHui_Auction_Page1_YuanbaoText_1:SetText(ScriptGlobal_Format("#{FMPM_220815_25}",nHaveYB))
end

function NewBangHui_Auction_AddItem_Fenye1(idx)
	local bar1 = NewBangHui_Auction_Page1_List:AddChild("NewBangHui_Auction_Page1_ListItem")

	g_BarList[idx] = bar1

	local nItemTableIndex = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMID")
	local nHighPrice = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "TOPBID")
	local nMyPrice = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "MYBID")
	local uItemNum = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMNUM")
	local nMyFavorite = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "FAVORITER")
	local nSourceType = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "SOURCETYPE")

	local nTimeStage = DataPool:LuaFnGetGuildBiddingStage()
	--我的关注
	if g_MyFavoriteNum >= 20 or (nTimeStage ~= 1 and nTimeStage ~= 2 )then --关注到上限
		if nMyFavorite > 0 then
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Collect"):Enable()
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Collect"):SetCheck(1)
		else
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Collect"):Disable()
		end
	else
		bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Collect"):Enable()
		if nMyFavorite > 0 then
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Collect"):SetCheck(1)
		else
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Collect"):SetCheck(0)
		end
	end

	bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Collect"):SetEvent( "Clicked", string.format("NewBangHui_Auction_Page1_CollectClicked(%d)", idx))

	local nShowItemTableIndex = DataPool:LuaFnGetGuildBiddingBonusInfo(nItemTableIndex, "SHOWITEMID")

	local theAction = DataPool:CreateActionItemForShow(nShowItemTableIndex, uItemNum)
	if theAction:GetID() ~= 0 then
		local ctrlAction = bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Icon")
		if ctrlAction ~= nil then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	end

	local item_name = DataPool:Lua_GetItemNameByIndex(nItemTableIndex)
	local strTemp = ScriptGlobal_Format("#{FMPM_220815_25}", tostring(item_name))
	bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text1"):SetText(strTemp)

	--最高价
	local nBasePrice = DataPool:LuaFnGetGuildBiddingBonusInfo(nItemTableIndex, "BASEPRICE",nSourceType)
	if nHighPrice >= nBasePrice then
		bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text2"):SetText(ScriptGlobal_Format("#{FMPM_220815_26}", tostring(nHighPrice)))
	else
		bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text2"):SetText(tostring(nBasePrice * uItemNum))
	end

	--我的出价
	if nMyPrice == 1 then
		bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text3"):SetText("#{SCBHPM_20220815_136}")
	elseif nMyPrice == 2 then --他人出价
		bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text3"):SetText("#{SCBHPM_20220815_156}")
	elseif nMyPrice == 999 then --自己上架的物品
		bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text3"):SetText("#{SCBHPM_20220815_159}") --我的物品
	else --未出价
		bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text3"):SetText("#{SCBHPM_20220815_137}")
	end

	--竞拍状态
	local nDownTime = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "DOWNTIME")
	local nTimeStage = DataPool:LuaFnGetGuildBiddingStage()
	local nIsMySellItem = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ISMYSELLITEM")

	local isShow = 0
	--公示期和竞拍期
	if nTimeStage == 1 then
		isShow = 1
	elseif nTimeStage == 2 then
		isShow = 1
	end

	if nIsMySellItem == 1 then -- 自己上架的
		if isShow == 1 then
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Button"):Disable()
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Button"):Show()
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text4"):SetText("#{SCBHPM_20220815_159}") --我的物品
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text4"):Hide()
		else
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Button"):Hide()
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text4"):SetText("#{SCBHPM_20220815_27}") --已结束
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text4"):Show()
		end
	else
		if isShow == 1 then
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text4"):Hide()
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Button"):Show()
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Button"):SetEvent( "Clicked", string.format("NewBangHui_Auction_OpenBidUI_Fenye1(%d)", idx))
		else
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Button"):Hide()
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text4"):SetText("#{SCBHPM_20220815_27}") --已结束
			bar1:GetSubItem("NewBangHui_Auction_Page1_ListItem_Text4"):Show()
		end
	end
end
--**********************************
--打开帮会竞拍
--**********************************
function NewBangHui_Auction_OpenBidUI_Fenye1(idx)
	local nPoolId = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "BIDINDEX")
	local nItemTableIndex = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMID")
	local uItemNum = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMNUM")
	local uSaleTime = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "SALETIME")

	Guild:AskGuildBiddingAuctionItem(2,g_CurFenYe,nPoolId,nItemTableIndex,uItemNum,uSaleTime,g_CurrentFilter,g_IsZhanTuan) --操作类型2，表类型:0：世界 1:帮会
end

--**********************************
--帮会竞拍--关注
--**********************************
function NewBangHui_Auction_Page1_CollectClicked(idx)
	local nPoolId = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "BIDINDEX")
	local nMyFavorite = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "FAVORITER")
	local nItemTableIndex = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMID")
	local uItemNum = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMNUM")
	local uSaleTime = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "SALETIME")

	if nMyFavorite > 0 then --取消关注
		Guild:AskGuildBiddingAuctionItem(1,g_CurFenYe,nPoolId,nItemTableIndex,uItemNum,uSaleTime,g_CurrentFilter,g_IsZhanTuan) --操作类型0：关注 1：取消关注 表类型:0：世界 1:帮会
	else --关注
		Guild:AskGuildBiddingAuctionItem(0,g_CurFenYe,nPoolId,nItemTableIndex,uItemNum,uSaleTime,g_CurrentFilter,g_IsZhanTuan)
	end
end

--**********************************
--帮会竞拍--取回物品
--**********************************
function NewBangHui_Auction_Page1_ReceiveItem()
	if g_IsZhanTuan == 1 then
		Guild:GetGuildBiddingBonus(1, 2) --0：世界 1:帮会；0：获取物品 1：获取分红 2战团物品
	else
		Guild:GetGuildBiddingBonus(1, 0) --0：世界 1:帮会；0：获取物品 1：获取分红
	end
end
--**********************************
--帮会竞拍--刷新
--**********************************
function NewBangHui_Auction_Page1_RefreshClicked()
	if GetSceneID() ~= 850 then
		PushDebugMessage("#{SCBHPM_20220815_35}")
		return
	end

	if Player:GetLevel() < 85 then
		PushDebugMessage("#{SCBHPM_20220815_36}")
		return
	end

	if( -1 == Player:GetData("GUILD")) then
		PushDebugMessage("#{SCBHPM_20220815_37}")
		return
	end

	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:AskGuildBiddingInfo(1,1,g_CurrentFilter,g_IsZhanTuan) --操作类型1，,表类型:0：世界 1:帮会， 筛选类型
end

--**********************************
--帮会竞拍--取回红利
--**********************************
function NewBangHui_Auction_Page1_ReceiveLijin()
	Guild:GetGuildBiddingBonus(1, 1) --0：世界 1:帮会；0：获取物品 1：获取分红
end

--**********************************
--世界拍卖--刷新界面
--**********************************
function NewBangHui_Auction_Update_Fenye2()
	NewBangHui_Auction_Frame2_PageBtn1:SetCheck(0)
	NewBangHui_Auction_Frame2_PageBtn2:SetCheck(1)
--	NewBangHui_Auction_Frame2_PageBtn3:SetCheck(0)
	NewBangHui_Auction_Page1:Hide()
	NewBangHui_Auction_Page2:Show()
	NewBangHui_Auction_Page1_AuctionShelve:Hide()

	--子页签
	if g_CurrentFilter < 0 or (g_CurrentFilter > 3 and g_CurrentFilter ~= 100) then
		g_CurrentFilter = 100
	end	

	for i = 0, 3 do
		if g_CurrentFilter == i-1 then
			g_NewBangHui_Auction_Page2_Filter[i]:SetCheck(1)
		else
			g_NewBangHui_Auction_Page2_Filter[i]:SetCheck(0)
		end
	end

	if g_CurrentFilter == 100 then
		g_NewBangHui_Auction_Page2_Filter[0]:SetCheck(1)
	end

	local nTimeStage = DataPool:LuaFnGetGuildBiddingStage()

	--界面上方文字
	if nTimeStage == 0 or nTimeStage == 4 then --休业期
		NewBangHui_Auction_Page2_List:Hide()
		NewBangHui_Auction_Page2_NoList:Show()
		NewBangHui_Auction_Page2_NoList:SetText("#{FMPM_220815_08}")

		NewBangHui_Auction_Page2_UpPage:Disable()
		NewBangHui_Auction_Page2_DownPage:Disable()
		NewBangHui_Auction_Page2_CurrentlyPage:SetText(ScriptGlobal_Format("#{FMPM_220815_35}", 1, 1))
	else
		NewBangHui_Auction_Page2_NoList:Hide()

		local g_MaxItem = DataPool:LuaFnGetGuildBiddingItemCount()
		if g_MaxItem == 0 then
			--道具列表
			NewBangHui_Auction_Page2_List:Hide()
			--无竞拍文字
			NewBangHui_Auction_Page2_NoList:Show()
			NewBangHui_Auction_Page2_NoList:SetText("")

			NewBangHui_Auction_Page2_UpPage:Disable()
			NewBangHui_Auction_Page2_DownPage:Disable()
			NewBangHui_Auction_Page2_CurrentlyPage:SetText(ScriptGlobal_Format("#{FMPM_220815_35}", 1, 1))
		else
			--道具列表
			NewBangHui_Auction_Page2_List:Show()

			NewBangHui_Auction_CleanUp_Fenye2()

			for i = 1, g_MaxPageItem do

				local index = i + g_CurPage2 * g_MaxPageItem

				local nBonusItemIndex = DataPool:LuaFnGetGuildBiddingInfo(index - 1, "ITEMID")
				if tonumber(nBonusItemIndex) <= 0 then
					break
				end
				NewBangHui_Auction_AddItem_Fenye2(index)

			end

			local realPage = g_CurPage2 + 1
			local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
			if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
				nMaxPage = nMaxPage + 1
			end

			if g_CurPage2 == 0 then
				NewBangHui_Auction_Page2_UpPage:Disable()
			else
				NewBangHui_Auction_Page2_UpPage:Enable()
			end

			if realPage >= nMaxPage then
				NewBangHui_Auction_Page2_DownPage:Disable()
			else
				NewBangHui_Auction_Page2_DownPage:Enable()
			end

			local strTemp = ScriptGlobal_Format("#{FMPM_220815_35}", tostring(realPage), tostring(nMaxPage))
			NewBangHui_Auction_Page2_CurrentlyPage:SetText(strTemp)

		end
	end

	if nTimeStage == 1 then --展示期
		NewBangHui_Auction_Page2_BeginTips:SetText("#{FMPM_220815_30}")
	else
		NewBangHui_Auction_Page2_BeginTips:SetText("")
	end
	--拥有元宝
	local nHaveYB = Player:GetData("YUANBAO")
	NewBangHui_Auction_Page2_YuanbaoText_1:SetText(ScriptGlobal_Format("#{FMPM_220815_25}",nHaveYB))

end

function NewBangHui_Auction_AddItem_Fenye2(idx)
	local bar1 = NewBangHui_Auction_Page2_List:AddChild("NewBangHui_Auction_Page2_ListItem")
	g_BarList2[idx] = bar1

	local nItemTableIndex = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMID")
	local nHighPrice = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "TOPBID")
	local nMyPrice = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "MYBID")
	local uItemNum = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMNUM")
	local nMyFavorite = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "FAVORITER")
	local nSourceType = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "SOURCETYPE")

	--我的关注
	local nTimeStage = DataPool:LuaFnGetGuildBiddingStage()
	if g_MyFavoriteNum >= 20 or (nTimeStage ~= 1 and nTimeStage ~= 2 ) then --关注到上限
		if nMyFavorite > 0 then
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Collect"):Enable()
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Collect"):SetCheck(1)
		else
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Collect"):Disable()
		end
	else
		bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Collect"):Enable()
		if nMyFavorite > 0 then
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Collect"):SetCheck(1)
		else
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Collect"):SetCheck(0)
		end
	end
	bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Collect"):SetEvent( "Clicked", string.format("NewBangHui_Auction_Page2_CollectClicked(%d)", idx))

	local nShowItemTableIndex = DataPool:LuaFnGetGuildBiddingBonusInfo(nItemTableIndex, "SHOWITEMID")

	local theAction = DataPool:CreateActionItemForShow(nShowItemTableIndex, uItemNum)
	if theAction:GetID() ~= 0 then
		local ctrlAction = bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Icon")
		if ctrlAction ~= nil then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	end

	local item_name = DataPool:Lua_GetItemNameByIndex(nItemTableIndex)
	local strTemp = ScriptGlobal_Format("#{FMPM_220815_25}", tostring(item_name), tostring(uItemNum))
	bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text1"):SetText(strTemp)

	--最高价
	local nBasePrice = DataPool:LuaFnGetGuildBiddingBonusInfo(nItemTableIndex, "BASEPRICE",nSourceType)
	if nHighPrice >= nBasePrice then
		bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text2"):SetText(ScriptGlobal_Format("#{FMPM_220815_26}", tostring(nHighPrice)))
	else
		bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text2"):SetText(tostring(nBasePrice * uItemNum))
	end

	--我的出价
	if nMyPrice == 1 then
		bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text3"):SetText("#{FMPM_220815_134}")
	elseif nMyPrice == 2 then --他人出价
		bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text3"):SetText("#{FMPM_220815_169}")
	elseif nMyPrice == 999 then --自己上架的物品
		bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text3"):SetText("#{SCBHPM_20220815_159}") --我的物品
	else
		--未出价
		bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text3"):SetText("#{FMPM_220815_29}")
	end

	--竞拍状态
	local nDownTime = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "DOWNTIME")
	local nTimeStage = DataPool:LuaFnGetGuildBiddingStage()
	local nIsMySellItem = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ISMYSELLITEM")

	local isShow = 0
	--公示期和竞拍期
	if nTimeStage == 1 then
		isShow = 1
	elseif nTimeStage == 2 then
		isShow = 1
	end

	if nIsMySellItem == 1 then -- 自己上架的
		if isShow == 1 then
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Button"):Disable()
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Button"):Show()
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text4"):SetText("#{SCBHPM_20220815_159}") --我的物品
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text4"):Hide()
		else
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Button"):Hide()
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text4"):SetText("#{SCBHPM_20220815_27}") --已结束
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text4"):Show()
		end
	else
		if isShow == 1 then
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text4"):Hide()
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Button"):Show()
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Button"):SetEvent( "Clicked", string.format("NewBangHui_Auction_OpenBidUI_Fenye2(%d)", idx))
		else
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Button"):Hide()
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text4"):SetText("#{SCBHPM_20220815_27}") -- 已结束
			bar1:GetSubItem("NewBangHui_Auction_Page2_ListItem_Text4"):Show()
		end
	end
end
--**********************************
--打开世界竞拍
--**********************************
function NewBangHui_Auction_OpenBidUI_Fenye2(idx)

	local nPoolId = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "BIDINDEX")
	local nItemTableIndex = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMID")
	local uItemNum = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMNUM")
	local uSaleTime = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "SALETIME")

	Guild:AskGuildBiddingAuctionItem(2,g_CurFenYe,nPoolId,nItemTableIndex,uItemNum,uSaleTime,g_CurrentFilter,g_IsZhanTuan) --操作类型2:开启竞拍界面 表类型:0：世界 1:帮会
end

--**********************************
--世界竞拍--关注
--**********************************
function NewBangHui_Auction_Page2_CollectClicked(idx)
	local nPoolId = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "BIDINDEX")
	local nMyFavorite = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "FAVORITER")
	local nItemTableIndex = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMID")
	local uItemNum = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "ITEMNUM")
	local uSaleTime = DataPool:LuaFnGetGuildBiddingInfo(idx - 1, "SALETIME")

	if nMyFavorite > 0 then --取消关注
		Guild:AskGuildBiddingAuctionItem(1,g_CurFenYe,nPoolId,nItemTableIndex,uItemNum,uSaleTime,g_CurrentFilter,g_IsZhanTuan) --操作类型0：关注 1：取消关注 表类型:0：世界 1:帮会
	else --关注
		Guild:AskGuildBiddingAuctionItem(0,g_CurFenYe,nPoolId,nItemTableIndex,uItemNum,uSaleTime,g_CurrentFilter,g_IsZhanTuan)
	end
end

--**********************************
--世界竞拍--取回物品
--**********************************
function NewBangHui_Auction_Page2_ReceiveItem()
	Guild:GetGuildBiddingBonus(0, 0) --0：世界 1:帮会；0：获取物品 1：获取分红
end

--**********************************
--世界竞拍--刷新
--**********************************
function NewBangHui_Auction_Page2_RefreshClicked()
	if GetSceneID() ~= 850 then
		PushDebugMessage("#{FMPM_220815_42}")
		return
	end

	if Player:GetLevel() < 85 then
		PushDebugMessage("#{FMPM_220815_43}")
		return
	end

	if( -1 == Player:GetData("GUILD")) then
		PushDebugMessage("#{FMPM_220815_44}")
		return
	end

	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:AskGuildBiddingInfo(0,0,g_CurrentFilter,g_IsZhanTuan) --操作类型1，表类型:0：世界 1:帮会， 筛选类型
end

function NewBangHui_Auction_CleanUp_Fenye1()
	for i = 1 , g_MaxPageItem do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NewBangHui_Auction_Page1_ListItem_Icon")
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end

	g_BarList = {}
	NewBangHui_Auction_Page1_List:Clear()
end

function NewBangHui_Auction_CleanUp_Fenye2()
	for i = 1 , g_MaxPageItem do
		if g_BarList2[i] then
			local ctrlAction = g_BarList2[i]:GetSubItem("NewBangHui_Auction_Page2_ListItem_Icon")
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end
	g_BarList2 = {}
	NewBangHui_Auction_Page2_List:Clear()

end
--**********************************
--关闭
--**********************************
function NewBangHui_Auction_CloseClicked()
	if IsWindowShow("NewBangHui_AuctionBidding") then
		CloseWindow("NewBangHui_AuctionBidding", true)
	end
	this:Hide()
end


--**********************************
--帮会竞拍--上一页
--**********************************
function NewBangHui_Auction_Page1_PageUp()

	local g_MaxItem = DataPool:LuaFnGetGuildBiddingItemCount()
	local realPage = g_CurPage1 + 1
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end

	if realPage <= 1 then
		return
	end

	g_CurPage1 = g_CurPage1 - 1

	--刷新
	NewBangHui_Auction_Update_Fenye1()
end

--**********************************
--帮会竞拍--下一页
--**********************************
function NewBangHui_Auction_Page1_PageDown()

	local g_MaxItem = DataPool:LuaFnGetGuildBiddingItemCount()
	local realPage = g_CurPage1 + 1
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end

	if realPage >= nMaxPage then
		return
	end

	g_CurPage1 = g_CurPage1 + 1
	--刷新
	NewBangHui_Auction_Update_Fenye1()

end

--**********************************
--世界竞拍--上一页
--**********************************
function NewBangHui_Auction_Page2_PageUp()

	local g_MaxItem = DataPool:LuaFnGetGuildBiddingItemCount()
	local realPage = g_CurPage2 + 1
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end

	if realPage <= 1 then
		return
	end

	g_CurPage2 = g_CurPage2 - 1

	--刷新
	NewBangHui_Auction_Update_Fenye2()
end

--**********************************
--世界竞拍--下一页
--**********************************
function NewBangHui_Auction_Page2_PageDown()

	local g_MaxItem = DataPool:LuaFnGetGuildBiddingItemCount()
	local realPage = g_CurPage2 + 1
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end

	if realPage >= nMaxPage then
		return
	end

	g_CurPage2 = g_CurPage2 + 1
	--刷新
	NewBangHui_Auction_Update_Fenye2()

end
--**********************************
--筛选
--**********************************
function NewBangHui_Auction_OnSelectFilter(nIndex)
	if nIndex == -1 then
		nIndex = 100
	end

	if g_CurrentFilter == nIndex then
		return
	end

	if GetSceneID() ~= 850 then
		PushDebugMessage("#{FMPM_220815_124}")
		return
	end

	if Player:GetLevel() < 85 then
		PushDebugMessage("#{FMPM_220815_125}")
		return
	end

	if( -1 == Player:GetData("GUILD")) then
		PushDebugMessage("#{FMPM_220815_126}")
		return
	end

	g_CurrentFilter = nIndex
--	PushDebugMessage("TESTshaixuan"..g_CurFenYe.."_"..g_CurrentFilter.."_"..g_IsZhanTuan)
	--请求数据
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:AskGuildBiddingInfo(0,g_CurFenYe,g_CurrentFilter,g_IsZhanTuan) --操作类型1，表类型:0：世界 1:帮会， 筛选类型

end

--**********************************
--点击帮会页签
--**********************************
function NewBangHui_Auction_PageBtn1_Clicked()
	if GetSceneID() ~= 850 then
		PushDebugMessage("#{SCBHPM_20220815_02}")
		return
	end

	if Player:GetLevel() < 85 then
		PushDebugMessage("#{SCBHPM_20220815_03}")
		return
	end

	if( -1 == Player:GetData("GUILD")) then
		PushDebugMessage("#{SCBHPM_20220815_04}")
		return
	end

	g_CurFenYe = 1
	g_IsZhanTuan = 0
	 Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:AskGuildBiddingInfo(0,1,100,g_IsZhanTuan) --操作类型1，表类型:0：世界 1:帮会， 筛选类型
end

--**********************************
--点击拍卖
--**********************************
function NewBangHui_Auction_PageBtn3_Clicked()
	-- 暂时，屏蔽掉逻辑
	if g_IsZhanTuan == 0 then
		return
	end
	if GetSceneID() ~= 850 then
		PushDebugMessage("#{SCBHPM_20220815_02}")
		return
	end

	if Player:GetLevel() < 85 then
		PushDebugMessage("#{SCBHPM_20220815_03}")
		return
	end

	if( -1 == Player:GetData("GUILD")) then
		PushDebugMessage("#{SCBHPM_20220815_04}")
		return
	end

	g_CurFenYe = 1
--	g_IsZhanTuan = 1
	 Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:AskGuildBiddingInfo(0,1,100,g_IsZhanTuan) --操作类型1，表类型:0：世界 1:帮会， 筛选类型
end

--**********************************
--点击世界页签
--**********************************
function NewBangHui_Auction_PageBtn2_Clicked()
	if GetSceneID() ~= 850 then
		PushDebugMessage("#{FMPM_220815_05}")
		return
	end

	if Player:GetLevel() < 85 then
		PushDebugMessage("#{FMPM_220815_06}")
		return
	end

	if( -1 == Player:GetData("GUILD")) then
		PushDebugMessage("#{FMPM_220815_07}")
		return
	end

	g_CurFenYe = 0
	g_IsZhanTuan = 0
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
	Guild:AskGuildBiddingInfo(0,0,100,g_IsZhanTuan) --操作类型1，表类型:0：世界 1:帮会， 筛选类型
end

function NewBangHui_Auction_Frame2_Help_Clicked() 
	if g_IsZhanTuan == 1 then
		PushEvent("CCSHOP_HELP", 173)
	elseif g_CurFenYe == 1 then
		PushEvent("CCSHOP_HELP", 173)
	else
		PushEvent("CCSHOP_HELP", 172)
	end
end

function NewBangHui_Auction_Frame_On_ResetPos()
	if g_NewBangHui_Auction_UnifiedPosition ~= nil then
		NewBangHui_Auction_Frame:SetProperty("UnifiedPosition", g_NewBangHui_Auction_UnifiedPosition)
	end
end

function NewBangHui_Auction_SetTitle()
	local szName = Guild:GetMyGuildName("Name");
	local title = ScriptGlobal_Format("#{BHJM_140520_01}", szName)
	NewBangHui_Auction_PageHeader:SetText(title)
end

function NewBangHui_Auction_Auction_Clicked()
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildBiddingInfo(0, 1, 100,g_IsZhanTuan)
end
function NewBangHui_Auction_BZZT_Clicked()
  local selfzoneid = DataPool:GetSelfZoneWorldID()
  if (KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(181) > 0) or 
	  DataPool:Lua_IsNewServerPlayerByZWID(selfzoneid) == 1 or
	  Player:GetData("IsOriginalJD")  == 1 or
	  Player:GetData("Is2606S")  == 1 or 
	  Player:GetData("SPECKAJI89") > 0 then
	PushDebugMessage("#{ZTXT_260511_151}")
	return
  end
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
  PushEvent("GUILD_ZHANTUAN_OP", 1)
end
--**********************************
--其他帮会页签处理
--**********************************
function NewBangHui_Auction_Bhxx_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:AskGuildDetailInfo();
	Guild:CloseKickGuildBox();
end

function NewBangHui_Auction_Tmxx_Clicked()
	NewBangHui_Auction_Tmxx:SetCheck(1)
	--在K服只有服务器配置保留原服"帮会同盟"信息的时候,才响应相应的按钮事件
	if KVKInterface:IsInKVKServer() == 1 and KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
		PushDebugMessage("#{KVKBH_140124_66}")
		return;
	end
    local id=Player:GetData("GUILDLEAGUE")
	if id == nil or id < 0 then
        PushDebugMessage( "#{KVKSL_110628_305}" )
        return
	end
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
    GuildLeague:ShowInfoWindow()
end

function NewBangHui_Auction_Bhxz_Clicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
    City:OpenNewGuildWarDlg();
	Guild:CloseKickGuildBox();
	NewBangHui_Auction_Bhxz:SetCheck(1)
end

function NewBangHui_Auction_Hygl_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ToggleGuildDetailInfo()
end

function NewBangHui_Auction_YXSS_Clicked()
  Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
  Guild:AskGuildYXSSInfo();
end

function NewBangHui_Auction_JZWJS_Clicked()
    Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1);
    Guild:ShowCityBuildIntroduce()
end

function NewBangHui_Auction_HB_OnClicked()
	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1)
	Guild:OpentGuildGiftUI()
end

function NewBangHui_Auction_BZTX_Clicked()
	-- if (Player:GetData("TCWLSvrOpenFlag") < 0) then
	-- 	NewBangHui_Auction_BZTX:SetCheck(0)
	-- 	NewBangHui_Auction_Auction:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_161}")
	-- elseif (Player:GetData("TCWLSvrOpenFlag") == 0) then
	-- 	NewBangHui_Auction_BZTX:SetCheck(0)
	-- 	NewBangHui_Auction_Auction:SetCheck(1)

	-- 	PushDebugMessage("#{GCQH_240429_154}")
	-- else
	-- 	Variable:SetVariable("SelfGuildClanUnionPos", NewBangHui_Auction_Frame:GetProperty("UnifiedPosition"), 1)
	-- 	Guild:TCWLOpenLCandidateUI()
	-- end
end -- end func NewBangHui_Auction_BZTX_Clicked()

--*****************************************************************************
-- 城战轮换（霸者天下）是否在助战申请时间内
--*****************************************************************************
function NewBangHui_Auction_Check_BZTXAssistEnrollTime()
	local curWeekDay = DataPool:GetServerWeekDay()
	if (curWeekDay == 0) then
		-- 星期天特殊处理一下
		curWeekDay = 7
	end

	local beginDay = NewBangHui_Auction_AssistOpTime[1].weekday
	local beginTime = NewBangHui_Auction_AssistOpTime[1].begintime
	local endDay = NewBangHui_Auction_AssistOpTime[2].weekday
	local endTime = NewBangHui_Auction_AssistOpTime[2].endtime

	if (curWeekDay >= beginDay and curWeekDay <= endDay) then
		local curMinTime = DataPool:GetServerMinuteTime()
		if (curWeekDay == beginDay) then
			if (curMinTime >= beginTime) then
				return 1
			else
				return -1
			end
		elseif (curWeekDay == endDay) then
			if (curMinTime < endTime) then
				return 1
			else
				return -1
			end
		else
			return 1
		end
	end

    return -1
end -- end func NewBangHui_Auction_Check_BZTXAssistEnrollTime()

function NewBangHui_Auction_Page1_AuctionShelve_Clicked()
	--请求缓存数据
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenGuildAucitonList")
		Set_XSCRIPT_ScriptID(999710)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	--请求帮会数据
	Guild:AskGuildBiddingInfoByMyUpItem(0,1) --操作类型1，表类型:0：世界 1:帮会
end
