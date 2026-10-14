--!!!reloadscript =BianJing_Auction

local g_BianJing_Auction_UnifiedPosition = ""

local g_ListDataDate = 0

local g_BarList = {}

local g_ListTimeFlag = 0

local g_CaredObjServerID = -1

local g_MaxItem = 0

local g_CurSection = 0
local g_CurPage = 0

local g_MaxPageItem = 10
local g_MaxSectionPage = 10

local g_CurInputNum = 0

local g_CurrentFilter = -1
local g_CurrentWarZone = -1
--1,	//竞拍日之前展示期
--2,	//竞拍日竞拍未开始
--3,	//竞拍日竞拍进行中
--4,	//竞拍结束等待结算
--5,	//竞拍日竞拍结束
--6,	//竞拍日之后公示期

local g_MaxWarZoneNum = 14
local g_WarZoneText = {
	"#{BJPM_200804_219}",
	"#{BJPM_200804_220}",
	"#{BJPM_200804_221}",
	"#{BJPM_200804_222}",
	"#{BJPM_200804_223}",
	"#{BJPM_200804_224}",
	"#{BJPM_200804_225}",
	"#{BJPM_200804_240}",
	"#{BJPM_200804_253}",
	"#{BJPM_200804_254}",
	"#{BJPM_200804_255}",
	"#{BJPM_200804_256}",
	"#{BJPM_200804_257}",
	"#{BJPM_200804_258}",
}

--===============================================
-- PreLoad
--===============================================
function BianJing_Auction_PreLoad()
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BIANJING_BIDDING_SHOWLIST")
	--游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	--游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
end

--===============================================
-- OnLoad
--===============================================
function BianJing_Auction_OnLoad()
	g_BianJing_Auction_UnifiedPosition = BianJing_Auction_Frame:GetProperty("UnifiedPosition")
	
	BianJing_Auction_SearchMode:AddTextItem("#{BJPM_200804_199}" ,-1)
	BianJing_Auction_SearchMode:AddTextItem("#{BJPM_200804_193}" ,0)
	--BianJing_Auction_SearchMode:AddTextItem("#{BJPM_200804_194}" ,1)
	BianJing_Auction_SearchMode:AddTextItem("#{BJPM_200804_195}" ,2)
	--BianJing_Auction_SearchMode:AddTextItem("#{BJPM_200804_196}" ,99)
	BianJing_Auction_SearchMode:AddTextItem("#{BJPM_200804_197}" ,100)
	BianJing_Auction_SearchMode:AddTextItem("#{BJPM_200804_198}" ,101)
	
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_219}", 1)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_220}", 2)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_221}", 3)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_222}", 4)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_223}", 5)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_224}", 6)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_225}", 7)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_240}", 8)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_253}", 9)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_254}", 10)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_255}", 11)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_256}", 12)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_257}", 13)
	BianJing_Auction_SearchMode2:AddTextItem("#{BJPM_200804_258}", 14)
end

--===============================================
-- OnEvent
--===============================================
function BianJing_Auction_OnEvent(event)
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004411 then
		if this:IsVisible() then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("RefreshBJBList")
				Set_XSCRIPT_ScriptID(440044)
				Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
				Set_XSCRIPT_Parameter(1, g_CurrentFilter)
				Set_XSCRIPT_Parameter(2, g_CurSection)
				Set_XSCRIPT_Parameter(3, g_CurPage)
				Set_XSCRIPT_Parameter(4, 0)
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()
		end
		return
	end
	
	--刷新红点
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004410 then
	--	PushDebugMessage(tostring(Get_XParam_INT(0))..":"..tostring(Get_XParam_INT(1)))
		if Get_XParam_INT(0) == 1 then
		--	BianJing_Auction_WuPintips:Show()
		else
		--	BianJing_Auction_WuPintips:Hide()
		end
		
		if Get_XParam_INT(1) == 1 then
			BianJing_Auction_DaiBitips:Show()
		else
			BianJing_Auction_DaiBitips:Hide()
		end
		
		--重刷界面
		if Get_XParam_INT(2) == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("RefreshBJBList")
				Set_XSCRIPT_ScriptID(440044)
				Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
				Set_XSCRIPT_Parameter(1, g_CurrentFilter)
				Set_XSCRIPT_Parameter(2, g_CurSection)
				Set_XSCRIPT_Parameter(3, g_CurPage)
				Set_XSCRIPT_Parameter(4, 0)
				Set_XSCRIPT_ParamCount(5)
			Send_XSCRIPT()	
		end
		return
	end
	
	if event == "BIANJING_BIDDING_SHOWLIST" then
		local bShowOrRefresh 	= tonumber(arg0)
		g_ListDataDate			= tonumber(arg1)
		g_ListTimeFlag			= tonumber(arg2)		
		local nObjID			= tonumber(arg3)
		g_MaxItem				= tonumber(arg4)
		g_CurSection			= tonumber(arg5)
		g_CurPage				= tonumber(arg6)

	--	PushDebugMessage(tostring(g_ListDataDate)..":"..tostring(bShowOrRefresh))
		
		if bShowOrRefresh == 0 then			
			BianJing_Auction_CleanUp(1)
			this:Show()
			g_CurrentFilter = -1
			BianJing_Auction_Update(1)			
			BianJing_Auction_SearchMode:SetText("#{BJPM_200804_199}")
			BianJing_Auction_SearchMode:ResetLastSelectIndex()
			BianJing_Auction_SearchMode:ClearAllSelections()
			
			for i = 1, g_MaxWarZoneNum do
				BianJing_Auction_SearchMode2:SetTextItemText(i - 1, g_WarZoneText[i])
			end
			
			g_CurrentWarZone = -1 --DataPool:GetSelfT300WarZoneID()
			if g_WarZoneText[g_CurrentWarZone] then
				BianJing_Auction_SearchMode2:SetTextItemText(g_CurrentWarZone - 1, g_WarZoneText[g_CurrentWarZone].."#{BJPM_200804_226}")
			end
			
			BianJing_Auction_SearchMode2:SetCurrentSelect(g_CurrentWarZone - 1)
			
			if nObjID and nObjID >= 0 then
				g_CaredObjServerID = nObjID
				local nObjCared = DataPool:GetNPCIDByServerID(g_CaredObjServerID)
				this:CareObject(nObjCared, 1)
			end
		
		elseif bShowOrRefresh == 1 then
			if this:IsVisible() then
				BianJing_Auction_Update(1)
			end
		end
		
		local nHaveYB = Player:GetData("YUANBAO")
		BianJing_Auction_GetNumText03:SetText("#G"..tostring(nHaveYB))
		
		return
	end
	
	--刷新元宝
	if event == "UPDATE_YUANBAO" then
		local nHaveYB = Player:GetData("YUANBAO")
		BianJing_Auction_GetNumText03:SetText("#G"..tostring(nHaveYB))
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		BianJing_Auction_Frame_On_ResetPos()
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44004412 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
end

function BianJing_Auction_Update(update_red_tip)
	
	local nHaveYB = Player:GetData("YUANBAO")
	BianJing_Auction_GetNumText03:SetText("#G"..tostring(nHaveYB))
	
	--界面上方文字
	if g_ListTimeFlag == 1 then
		BianJing_Auction_Intro:SetText("#{BJPM_200804_43}")
	elseif g_ListTimeFlag == 2 then
		BianJing_Auction_Intro:SetText("#{BJPM_200804_44}")
	elseif g_ListTimeFlag == 3 then
		BianJing_Auction_Intro:SetText("#{BJPM_200804_42}")
	else
		BianJing_Auction_Intro:SetText("")
	end	
	
	if g_MaxItem == 0 then		
		--道具列表
		BianJing_Auction_Lace:Hide()
		--无竞拍文字
		BianJing_Auction_Text:Show()
		BianJing_Auction_Text:SetText("#{BJPM_200804_59}")
		
	--	BianJing_Auction_FanYe:Hide()
		BianJing_Auction_UpDown:Hide()
	else
		--道具列表
		BianJing_Auction_Lace:Show()
		--无竞拍文字
		BianJing_Auction_Text:Hide()
			
	--	BianJing_Auction_FanYe:Show()
		BianJing_Auction_UpDown:Show()
		
		local bFinish = 1
		local bPreTime = 0
		
		BianJing_Auction_CleanUp(update_red_tip)
		
		for i = 1, g_MaxPageItem do
			
			local index = i + g_CurPage * g_MaxPageItem
			
			local nBonusItemIndex = DataPool:LuaFnGetBianJingBiddingInfo(index - 1, "ITEMID")
			if tonumber(nBonusItemIndex) <= 0 then
				break
			end
			
			BianJing_Auction_AddItem(index)
			
			local nTimeFlag = DataPool:LuaFnGetBianJingBiddingInfo(index - 1, "TIMEFLAG")
			if nTimeFlag == 1 then
				bPreTime = 1
			elseif nTimeFlag == 2 then
				bFinish = 0
			end			
		end
		
		local realPage = g_CurSection * g_MaxSectionPage + g_CurPage + 1
		local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
		if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
			nMaxPage = nMaxPage + 1
	end	

		if g_CurSection == 0 and g_CurPage == 0 then
			BianJing_Auction_UpPage:Disable()
		else
			BianJing_Auction_UpPage:Enable()
end

		if realPage >= nMaxPage then
			BianJing_Auction_DownPage:Disable()
		else
			BianJing_Auction_DownPage:Enable()
		end
		
		--local strTemp = ScriptGlobal_Format("#{LDSD_200805_42}", tostring(nMaxPage), tostring(nMaxPage))		
		BianJing_Auction_CurrentlyPage:SetText(tostring(realPage).."/"..tostring(nMaxPage))
		
		if g_CurInputNum == 0 then
			BianJing_Auction_FanYeTextNum:SetText("")
		else
			BianJing_Auction_FanYeTextNum:SetText(tostring(g_CurInputNum))
		end
			
	end	

end

function BianJing_Auction_AddItem(idx)

	local bar1 = BianJing_Auction_Lace:AddChild("BianJing_Auction_CoinAItem")	
	g_BarList[idx] = bar1
	
	local nItemTableIndex = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "ITEMID")
	local nHighPrice = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "TOPBID")
	local nHighName = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "NAME")
	local nMyPrice = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "MYBID")
	local nTimeFlag = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "TIMEFLAG")
	local top_world = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "TOPWORLD")	
	
	local uItemNum = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "ITEMNUM")
	local bNobody = 0
	if nHighName == "" then
		nHighPrice = DataPool:LuaFnGetBianJingBiddingBonusInfo(nItemTableIndex, "BASEPRICE")
		nHighPrice = nHighPrice * uItemNum
		nHighName = "#{BJPM_200804_48}"
		bNobody = 1
	else
		if top_world and tonumber(top_world) >= 0 then
			local top_world_name = DataPool:GetServerName(tonumber(top_world))
			nHighName = nHighName.."@"..tostring(top_world_name)
		end
	end
	
	local nShowItemTableIndex = DataPool:LuaFnGetBianJingBiddingBonusInfo(nItemTableIndex, "SHOWITEMID")
	
	local theAction = DataPool:CreateActionItemForShow(nShowItemTableIndex, uItemNum)
	if theAction:GetID() ~= 0 then
		local ctrlAction = bar1:GetSubItem("BianJing_Auction_CoinAItem_Icon")
		if ctrlAction ~= nil then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	end
	
	local item_name = DataPool:Lua_GetItemNameByIndex(nItemTableIndex)
	local strTemp = ScriptGlobal_Format("#{BJPM_200804_239}", tostring(item_name), tostring(uItemNum))	
	bar1:GetSubItem("BianJing_Auction_CoinAItem_Art"):SetText(strTemp)	
	
	if nMyPrice > 0 then
		if nMyPrice >= nHighPrice then
			local strNum = ScriptGlobal_Format("#{BJPM_200804_246}", tostring(nHighPrice))	
			bar1:GetSubItem("BianJing_Auction_CoinAItem_Price"):SetText(strNum)
			
			local strHightName = ScriptGlobal_Format("#{BJPM_200804_47}", tostring(nHighName))
			bar1:GetSubItem("BianJing_Auction_CoinAItem_Name"):SetText(strHightName)
			
			strNum = ScriptGlobal_Format("#{BJPM_200804_246}", tostring(nMyPrice))	
			bar1:GetSubItem("BianJing_Auction_CoinAItem_Self"):SetText(strNum)
		else
			local strNum = ScriptGlobal_Format("#{BJPM_200804_46}", tostring(nHighPrice))	
			bar1:GetSubItem("BianJing_Auction_CoinAItem_Price"):SetText(strNum)
			
			local strHightName = ScriptGlobal_Format("#{BJPM_200804_47}", tostring(nHighName))
			bar1:GetSubItem("BianJing_Auction_CoinAItem_Name"):SetText(strHightName)
			
			strNum = ScriptGlobal_Format("#{BJPM_200804_250}", tostring(nMyPrice))	
			bar1:GetSubItem("BianJing_Auction_CoinAItem_Self"):SetText(strNum)
		end		
	else
		local strNum = ScriptGlobal_Format("#{BJPM_200804_46}", tostring(nHighPrice))	
		bar1:GetSubItem("BianJing_Auction_CoinAItem_Price"):SetText(strNum)
		
		local strHightName = ScriptGlobal_Format("#{BJPM_200804_47}", tostring(nHighName))
		bar1:GetSubItem("BianJing_Auction_CoinAItem_Name"):SetText(strHightName)
		
		bar1:GetSubItem("BianJing_Auction_CoinAItem_Self"):SetText("#{BJPM_200804_50}")
	end
	
	bar1:GetSubItem("BianJing_Auction_CoinAItem_ZhuangTai"):Hide()
	bar1:GetSubItem("BianJing_Auction_CoinAItem_Button"):SetEvent( "Clicked", string.format("BianJing_Auction_OpenBidUI(%d)", idx))
	
	if nTimeFlag == 1 or nTimeFlag == 2 then
		bar1:GetSubItem("BianJing_Auction_CoinAItem_ZhuangTai"):Show()
		bar1:GetSubItem("BianJing_Auction_CoinAItem_ZhuangTai"):SetProperty("Image","set:T3Basice image:T3BJJP_DengDai")
		bar1:GetSubItem("BianJing_Auction_CoinAItem_Button"):Hide()
	elseif nTimeFlag == 3 then
		bar1:GetSubItem("BianJing_Auction_CoinAItem_ZhuangTai"):Hide()
		bar1:GetSubItem("BianJing_Auction_CoinAItem_Button"):Show()
	elseif nTimeFlag == 4 or nTimeFlag == 5 or nTimeFlag == 6 then
		bar1:GetSubItem("BianJing_Auction_CoinAItem_ZhuangTai"):Show()
		bar1:GetSubItem("BianJing_Auction_CoinAItem_Button"):Hide()
		if bNobody == 1 then
			bar1:GetSubItem("BianJing_Auction_CoinAItem_ZhuangTai"):SetProperty("Image","set:T3Basice image:T3BJJP_YiLiuPai")
		else
			bar1:GetSubItem("BianJing_Auction_CoinAItem_ZhuangTai"):SetProperty("Image","set:T3Basice image:T3BJJP_YiChengJiao")
		end
	end
	
	bar1:GetSubItem("BianJing_Auction_CoinAItem_Look"):SetEvent("Clicked", string.format("BianJing_Auction_OpenLook(%d)", idx))
	
	local nSkillCardID, _, _ = DataPool:LuaFnGetSkillCardRecycleInfo(nItemTableIndex)
	if nSkillCardID == 0 then
		bar1:GetSubItem("BianJing_Auction_CoinAItem_Look"):Hide()
	end
	
end

function BianJing_Auction_OpenBidUI(idx)
	
	local bBidIndex = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "BIDINDEX")
	local iWarZone = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "WARZONE")
	
	local myWarZone = -1 --DataPool:GetSelfT300WarZoneID()
	if iWarZone ~= myWarZone then
		local nItemTableIndex = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "ITEMID")
		local wzFlag = DataPool:LuaFnGetBianJingBiddingBonusInfo(nItemTableIndex, "WZFLAG")
		if wzFlag ~= 0 then
			PushDebugMessage("#{BJPM_200804_227}")
		end
	end
	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenBidUI")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, bBidIndex)					--索引
		Set_XSCRIPT_Parameter(1, g_CaredObjServerID)
		Set_XSCRIPT_Parameter(2, g_ListDataDate)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function BianJing_Auction_TakeBonus()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TakeItemOrYuanBao")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function BianJing_Auction_TakeTokens()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TakeItemOrYuanBao")
		Set_XSCRIPT_ScriptID( 440044 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function BianJing_Auction_Refresh()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RefreshBJBList")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
		Set_XSCRIPT_Parameter(1, g_CurrentFilter)						--筛选 -1代表所有
		Set_XSCRIPT_Parameter(2, g_CurSection)
		Set_XSCRIPT_Parameter(3, g_CurPage)
		Set_XSCRIPT_Parameter(4, 1)
		Set_XSCRIPT_ParamCount(5)
	Send_XSCRIPT()
end

function BianJing_Auction_OpenExchange()
	
end

function BianJing_Auction_CleanUp(update_red_tip)
	
	for i = 1 , 10 do		
		if g_BarList[i] then			
			local ctrlAction = g_BarList[i]:GetSubItem("BianJing_Auction_CoinAItem_Icon")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end	
	end
	
	g_BarList = {}
	BianJing_Auction_Lace:Clear()
	if update_red_tip == 1 then
		BianJing_Auction_DaiBitips:Hide()
	end
end

function BianJing_Auction_CloseClicked()
	this:Hide()
end

function BianJing_Auction_GotoPage()
	
	local nString = BianJing_Auction_FanYeTextNum:GetText()
	
	if nString == nil or nString == "" then
		return
	end
	
	local nChangNum = tonumber(nString)

	if nChangNum == nil then
		return
	end
	
	if nChangNum == 0 then
		return
	end
	
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end
	
	if nChangNum > nMaxPage then
		nChangNum = nMaxPage
	end
	
	local realPage = g_CurSection * g_MaxSectionPage + g_CurPage + 1
	if nChangNum == realPage then
		return
	end
	
	local startPage = g_CurSection * g_MaxSectionPage + 1
	local endPage = startPage + g_MaxSectionPage - 1
	
	if nChangNum >= startPage and nChangNum <= endPage then
	
		g_CurPage = nChangNum - startPage
		BianJing_Auction_Update(0)
		
	else
		
		local section = math.floor((nChangNum - 1) / g_MaxSectionPage)
		local page = math.mod(nChangNum - 1, g_MaxSectionPage)
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("RefreshBJBList")
			Set_XSCRIPT_ScriptID(440044)
			Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
			Set_XSCRIPT_Parameter(1, g_CurrentFilter)						--筛选 -1代表所有
			Set_XSCRIPT_Parameter(2, section)
			Set_XSCRIPT_Parameter(3, page)
			Set_XSCRIPT_Parameter(4, 0)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	
	end
end

function BianJing_Auction_TextChanged()
	
	local nString = BianJing_Auction_FanYeTextNum:GetText()
	
	if nString == nil or nString == "" then
		return
	end
		
	local nChangNum = tonumber(nString)

	if nChangNum == nil then
		return
	end
	
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end
	
	if nChangNum > nMaxPage then
		nChangNum = nMaxPage
	end

	if g_CurInputNum ~= tonumber(nString) then
		g_CurInputNum = nChangNum
		BianJing_Auction_FanYeTextNum:SetText(tostring(g_CurInputNum))
	end
end

function BianJing_Auction_PrePage()
	
	local realPage = g_CurSection * g_MaxSectionPage + g_CurPage + 1
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end
	
	if realPage <= 1 then
		return
	end
	
	local startPage = g_CurSection * g_MaxSectionPage + 1
	local endPage = startPage + g_MaxSectionPage - 1
	
	if realPage > startPage then	
		g_CurPage = g_CurPage - 1
		BianJing_Auction_Update(0)		
	else
		
		local section = g_CurSection - 1
		local page = g_MaxSectionPage - 1
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("RefreshBJBList")
			Set_XSCRIPT_ScriptID(440044)
			Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
			Set_XSCRIPT_Parameter(1, g_CurrentFilter)						--筛选 -1代表所有
			Set_XSCRIPT_Parameter(2, section)
			Set_XSCRIPT_Parameter(3, page)
			Set_XSCRIPT_Parameter(4, 0)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	
	end
end

function BianJing_Auction_NextPage()
	
	local realPage = g_CurSection * g_MaxSectionPage + g_CurPage + 1
	local nMaxPage = math.floor(g_MaxItem / g_MaxPageItem)
	if math.mod(g_MaxItem, g_MaxPageItem) ~= 0 then
		nMaxPage = nMaxPage + 1
	end
	
	if realPage >= nMaxPage then
		return
	end
	
	local startPage = g_CurSection * g_MaxSectionPage + 1
	local endPage = startPage + g_MaxSectionPage - 1
	
	if realPage < endPage then	
		g_CurPage = g_CurPage + 1
		BianJing_Auction_Update(0)		
	else
		
		local section = g_CurSection + 1
		local page = 0
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("RefreshBJBList")
			Set_XSCRIPT_ScriptID(440044)
			Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
			Set_XSCRIPT_Parameter(1, g_CurrentFilter)						--筛选 -1代表所有
			Set_XSCRIPT_Parameter(2, section)
			Set_XSCRIPT_Parameter(3, page)
			Set_XSCRIPT_Parameter(4, 0)
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	
	end
end

function BianJing_Auction_OnSelectWarZone()
	
	local _,nIndex = BianJing_Auction_SearchMode2:GetCurrentSelect()
	if g_CurrentWarZone == nIndex then
		return
	end
	
--	PushDebugMessage(tostring(g_CurrentFilter))
	g_CurrentWarZone = nIndex
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RefreshBJBList")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
		Set_XSCRIPT_Parameter(1, g_CurrentFilter)						--筛选 -1代表所有
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_Parameter(4, 0)
		Set_XSCRIPT_ParamCount(5)
	Send_XSCRIPT()
	
end

function BianJing_Auction_OnSelectFilter()
	
	local _,nIndex = BianJing_Auction_SearchMode:GetCurrentSelect()
	if g_CurrentFilter == nIndex then
		return
	end
	
--	PushDebugMessage(tostring(g_CurrentFilter))
	g_CurrentFilter = nIndex
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("RefreshBJBList")
		Set_XSCRIPT_ScriptID(440044)
		Set_XSCRIPT_Parameter(0, g_CurrentWarZone)
		Set_XSCRIPT_Parameter(1, g_CurrentFilter)						--筛选 -1代表所有
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_Parameter(4, 0)
		Set_XSCRIPT_ParamCount(5)
	Send_XSCRIPT()
	
end

function BianJing_Auction_OnHidden()
	BianJing_Auction_CleanUp(1)
	g_CaredObjServerID = -1
	g_CurrentFilter = -1
	g_CurrentWarZone = -1
end

function BianJing_Auction_HelpClick()
	PushEvent("BIANJING_BIDDINGLIST_HELP")
end

function BianJing_Auction_Frame_On_ResetPos()
	if g_BianJing_Auction_UnifiedPosition ~= nil then
		BianJing_Auction_Frame:SetProperty("UnifiedPosition", g_BianJing_Auction_UnifiedPosition)
	end
end

function BianJing_Auction_OpenLook(idx)
	local nItemTableIndex = DataPool:LuaFnGetBianJingBiddingInfo(idx - 1, "ITEMID")
	local nSkillCardID, _, _ = DataPool:LuaFnGetSkillCardRecycleInfo(nItemTableIndex)
	if nSkillCardID > 0 then
		LuaFnOpenSkillCardDetail(nSkillCardID)	
	end
end

