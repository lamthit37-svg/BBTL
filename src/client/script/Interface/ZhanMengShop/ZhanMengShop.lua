local	g_ZhanMengShop_CurPage		=	0		--当前所在的页面
local	g_ZhanMengShop_CommodityNums_PerPage	=	15	--每个页面展示的商品的数量
local	g_ZhanMengShop_ControlsTable	=	{}		--界面上的控件表
local	g_ZhanMengShop_MaxCommodityType	=	32		--最多商品的数量
local	g_ZhanMengShop_IfBuyConfirm	=	1		
local	g_ZhanMengShop_Frame_UnifiedPosition


--===============================================
-- OnLoad()
--===============================================
function ZhanMengShop_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
	this:RegisterEvent("OPEN_KALLIANCE_SHOP")
end

function ZhanMengShop_CanUse()
	-- 活动时间
		return 1
end

function ZhanMengShop_OnLoad()
	g_ZhanMengShop_ControlsTable	=	{
		[0]={ ActionItem = ZhanMengShop_Item1, Mask = ZhanMengShop_Item1_Mask, SellOutIcon = ZhanMengShop_ItemIcon_1,CommodityName = ZhanMengShop_ItemInfo1_Text, CommodityPrize = ZhanMengShop_ItemInfo1_MG },
		[1]={ ActionItem = ZhanMengShop_Item2, Mask = ZhanMengShop_Item2_Mask, SellOutIcon = ZhanMengShop_ItemIcon_2,CommodityName = ZhanMengShop_ItemInfo2_Text, CommodityPrize = ZhanMengShop_ItemInfo2_MG },
		[2]={ ActionItem = ZhanMengShop_Item3, Mask = ZhanMengShop_Item3_Mask, SellOutIcon = ZhanMengShop_ItemIcon_3,CommodityName = ZhanMengShop_ItemInfo3_Text, CommodityPrize = ZhanMengShop_ItemInfo3_MG },
		[3]={ ActionItem = ZhanMengShop_Item4, Mask = ZhanMengShop_Item4_Mask, SellOutIcon = ZhanMengShop_ItemIcon_4,CommodityName = ZhanMengShop_ItemInfo4_Text, CommodityPrize = ZhanMengShop_ItemInfo4_MG },
		[4]={ ActionItem = ZhanMengShop_Item5, Mask = ZhanMengShop_Item5_Mask, SellOutIcon = ZhanMengShop_ItemIcon_5,CommodityName = ZhanMengShop_ItemInfo5_Text, CommodityPrize = ZhanMengShop_ItemInfo5_MG },
		[5]={ ActionItem = ZhanMengShop_Item6, Mask = ZhanMengShop_Item6_Mask, SellOutIcon = ZhanMengShop_ItemIcon_6,CommodityName = ZhanMengShop_ItemInfo6_Text, CommodityPrize = ZhanMengShop_ItemInfo6_MG },
		[6]={ ActionItem = ZhanMengShop_Item7, Mask = ZhanMengShop_Item7_Mask, SellOutIcon = ZhanMengShop_ItemIcon_7,CommodityName = ZhanMengShop_ItemInfo7_Text, CommodityPrize = ZhanMengShop_ItemInfo7_MG },
		[7]={ ActionItem = ZhanMengShop_Item8, Mask = ZhanMengShop_Item8_Mask, SellOutIcon = ZhanMengShop_ItemIcon_8,CommodityName = ZhanMengShop_ItemInfo8_Text, CommodityPrize = ZhanMengShop_ItemInfo8_MG },
		[8]={ ActionItem = ZhanMengShop_Item9, Mask = ZhanMengShop_Item9_Mask, SellOutIcon = ZhanMengShop_ItemIcon_9,CommodityName = ZhanMengShop_ItemInfo9_Text, CommodityPrize = ZhanMengShop_ItemInfo9_MG },
		[9]={ ActionItem = ZhanMengShop_Item10, Mask = ZhanMengShop_Item10_Mask, SellOutIcon = ZhanMengShop_ItemIcon_10,CommodityName = ZhanMengShop_ItemInfo10_Text, CommodityPrize = ZhanMengShop_ItemInfo10_MG },
		[10]={ ActionItem = ZhanMengShop_Item11, Mask = ZhanMengShop_Item11_Mask, SellOutIcon = ZhanMengShop_ItemIcon_11,CommodityName = ZhanMengShop_ItemInfo11_Text, CommodityPrize = ZhanMengShop_ItemInfo11_MG },
		[11]={ ActionItem = ZhanMengShop_Item12, Mask = ZhanMengShop_Item12_Mask, SellOutIcon = ZhanMengShop_ItemIcon_12,CommodityName = ZhanMengShop_ItemInfo12_Text, CommodityPrize = ZhanMengShop_ItemInfo12_MG },
		[12]={ ActionItem = ZhanMengShop_Item13, Mask = ZhanMengShop_Item13_Mask, SellOutIcon = ZhanMengShop_ItemIcon_13,CommodityName = ZhanMengShop_ItemInfo13_Text, CommodityPrize = ZhanMengShop_ItemInfo13_MG },
		[13]={ ActionItem = ZhanMengShop_Item14, Mask = ZhanMengShop_Item14_Mask, SellOutIcon = ZhanMengShop_ItemIcon_14,CommodityName = ZhanMengShop_ItemInfo14_Text, CommodityPrize = ZhanMengShop_ItemInfo14_MG },
		[14]={ ActionItem = ZhanMengShop_Item15, Mask = ZhanMengShop_Item15_Mask, SellOutIcon = ZhanMengShop_ItemIcon_15,CommodityName = ZhanMengShop_ItemInfo15_Text, CommodityPrize = ZhanMengShop_ItemInfo15_MG },
	}
	g_ZhanMengShop_Frame_UnifiedPosition = ZhanMengShop_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function ZhanMengShop_OnEvent( event )
	if event == "OPEN_KALLIANCE_SHOP" then
		ZhanMengShop_FreshWindow()
		this:Show()
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ZhanMengShop_Frame_On_ResetPos()
	end
end

--===============================================
--刷新界面信息
--===============================================
function ZhanMengShop_FreshWindow()
	g_ZhanMengShop_MaxCommodityType = KAllianceShop:GetCommodityTypesNum()
	for i = 0, g_ZhanMengShop_CommodityNums_PerPage - 1 do
		local	index = i + g_ZhanMengShop_CommodityNums_PerPage * g_ZhanMengShop_CurPage 
		if index >= g_ZhanMengShop_MaxCommodityType then
			g_ZhanMengShop_ControlsTable[i].Mask:Hide()
			g_ZhanMengShop_ControlsTable[i].SellOutIcon:Hide()
			g_ZhanMengShop_ControlsTable[i].CommodityName:Hide()
			g_ZhanMengShop_ControlsTable[i].CommodityPrize:Hide()
			g_ZhanMengShop_ControlsTable[i].ActionItem:SetActionItem(-1)
			g_ZhanMengShop_ControlsTable[i].ActionItem:Disable()

		else
			local	nItemType, nMaxNum, nPrize, CommodityName = KAllianceShop:EnumKAllianceShopCommodityInfo(index)
			if nMaxNum > 0 then	
				g_ZhanMengShop_ControlsTable[i].Mask:Hide()
				g_ZhanMengShop_ControlsTable[i].SellOutIcon:Hide()
			elseif nMaxNum == 0 then	--蒙红,显示售罄
				g_ZhanMengShop_ControlsTable[i].Mask:Show()
				g_ZhanMengShop_ControlsTable[i].SellOutIcon:Show()
				nMaxNum = 1
			elseif nMaxNum == -1 then	--没有购买上限限制
				g_ZhanMengShop_ControlsTable[i].Mask:Hide()
				nMaxNum = 1
			end
			local theAction = DataPool:CreateActionItemForShowWithMaxNum(nItemType, 1, nMaxNum)
			if theAction:GetID() ~= 0 then
				g_ZhanMengShop_ControlsTable[i].ActionItem:SetActionItem(theAction:GetID())
			end
			g_ZhanMengShop_ControlsTable[i].CommodityName:SetText("#cfff263"..CommodityName)
			g_ZhanMengShop_ControlsTable[i].CommodityPrize:SetText("#{ZMSD_150811_45}".."#cfff263"..nPrize)
			g_ZhanMengShop_ControlsTable[i].CommodityName:Show()
			g_ZhanMengShop_ControlsTable[i].CommodityPrize:Show()
		end
	end
	ZhanMengShop_Text1:SetText("#{ZMSD_150811_48}"..tostring(KAllianceShop:GetAllianceContributionRate()))
	ZhanMengShop_CurrentlyPage:SetText(tostring(g_ZhanMengShop_CurPage + 1)..'/'..ZhanMengShop_GetMaxPages())
	if g_ZhanMengShop_CurPage <= 0 then
		ZhanMengShop_UpPage:Disable()
	else
		ZhanMengShop_UpPage:Enable()
	end
	if (g_ZhanMengShop_CurPage + 1) >= ZhanMengShop_GetMaxPages() then
		ZhanMengShop_DownPage:Disable()
	else
		ZhanMengShop_DownPage:Enable()
	end
	ZhanMengShop_querengoumaiBind:SetCheck(g_ZhanMengShop_IfBuyConfirm)
end

function ZhanMengShop_PageUp_Clicked()
	g_ZhanMengShop_CurPage	=	g_ZhanMengShop_CurPage - 1
	ZhanMengShop_FreshWindow()
end

function ZhanMengShop_PageDown_Clicked()
	g_ZhanMengShop_CurPage	=	g_ZhanMengShop_CurPage	+ 1
	ZhanMengShop_FreshWindow()
end

function ZhanMengShop_BuyItem_Clicked(nPos)

	if ZhanMengShop_CanUse() == 0 then
		PushDebugMessage("#{TWSC_200817_15}")
		return 
	end
	local	nIndex = nPos + g_ZhanMengShop_CommodityNums_PerPage * g_ZhanMengShop_CurPage 
	local	nItemType, nMaxNum, nPrize, CommodityName = KAllianceShop:EnumKAllianceShopCommodityInfo(nIndex)
	if nMaxNum == 0 then
		--处于售罄状态
		PushDebugMessage("#{PLGM_150306_04}")
		return
	end
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	if KAllianceShop:CheckIsMultiBuy(nIndex) >= 1 then
		return
	else
		--处理购买
		if KAllianceShop:GetAllianceContributionRate() < nPrize then
			--战盟贡献度不够
			PushDebugMessage("#{ZMSD_150811_67}")
			return
		end
		if g_ZhanMengShop_IfBuyConfirm ~=  1 then
			KAllianceShop:BuyItem(nIndex,1)
		else
			KAllianceShop:OpenBuyConfirmMessageBox(nIndex)
		end
	end
end

function ZhanMengShop_Closed()
	this:Hide()
end

function ZhanMengShop_MultiBuyClicked()

	if ZhanMengShop_CanUse() == 0 then
		PushDebugMessage("#{TWSC_200817_15}")
		return 
	end
	if IsWindowShow("ZhanMengShop_MBuy") then
		CloseWindow("ZhanMengShop_MBuy",true)
	end
	PrepearBuyMult()
end

function ZhanMengShop_OnHiden()
	if IsWindowShow("ZhanMengShop_MBuy") then
		CloseWindow("ZhanMengShop_MBuy",true)
	end

	--重新打开界面,默认显示第一页
	--默认选中购买确认
	ZhanMengShop_querengoumaiBind:SetCheck(1)
	g_ZhanMengShop_CurPage	=	0
	SetDefaultMouse()
	this:Hide()
end

function ZhanMengShop_BuyConfirm_Clicked()
	g_ZhanMengShop_IfBuyConfirm = ZhanMengShop_querengoumaiBind:GetCheck()
end

--获取商品最多有多少页
function ZhanMengShop_GetMaxPages()
	return	math.ceil(g_ZhanMengShop_MaxCommodityType/g_ZhanMengShop_CommodityNums_PerPage)
end

function ZhanMengShop_Frame_On_ResetPos()
	 ZhanMengShop_Frame:SetProperty("UnifiedPosition", g_ZhanMengShop_Frame_UnifiedPosition)
end

