local g_ZhanMengShop_MBuy_Frame_UnifiedPosition
local g_ZhanMengShop_MBuy_ItemIndex = 0
--===============================================
-- OnLoad()
--===============================================
function ZhanMengShop_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	--逻辑相关的事件
	this:RegisterEvent("OPEN_KALLIANCESHOP_MULTIBUY")
end

function ZhanMengShop_MBuy_OnLoad()
	g_ZhanMengShop_MBuy_Frame_UnifiedPosition	=	ZhanMengShop_MBuy_Frame:GetProperty("UnifiedPosition")
end


function ZhanMengShop_MBuy_CanUse()

		return 1	


end
--===============================================
-- OnEvent()
--===============================================
function ZhanMengShop_MBuy_OnEvent( event )
	if event == "OPEN_KALLIANCESHOP_MULTIBUY" then
		g_ZhanMengShop_MBuy_ItemIndex = tonumber(arg0)
		ZhanMengShop_MBuy_FreshWindow(tonumber(arg0))
		local careObjId = DataPool:GetNPCIDByServerID(tonumber(arg1))
		this:CareObject(careObjId, 1, "ZhanMengShop_MBuy")
		ZhanMengShop_MBuy_InputNum:SetText("1")		--打开界面默认购买领取数值为1
		this:Show()
	end
end

--===============================================
--刷新界面信息
--===============================================
function ZhanMengShop_MBuy_FreshWindow( index )
	local	nItemType, nMaxNum, nPrize, CommodityName = KAllianceShop:EnumKAllianceShopCommodityInfo(index)
	local	theAction = DataPool:CreateActionItemForShowWithMaxNum(nItemType, 1, nMaxNum)
	if theAction:GetID() ~= 0 then
		ZhanMengShop_MBuy_Item:SetActionItem(theAction:GetID())
		ZhanMengShop_MBuy_Item:Show()
	end
	ZhanMengShop_MBuy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	ZhanMengShop_MBuy_InputNum:SetText("1")					--默认输入为1
	ZhanMengShop_MBuy_ItemInfo_Text:SetText("#cfff263"..CommodityName)
	ZhanMengShop_MBuy_ItemInfo_GB:SetText("#{ZMSD_150811_45}#cfff263"..tostring(nPrize))
	ZhanMengShop_MBuy_Cash_Yuanbao:SetText("#cfff263"..tostring(KAllianceShop:GetAllianceContributionRate()))
	if nPrize > KAllianceShop:GetAllianceContributionRate() then
		ZhanMengShop_MBuy_Price_Yuanbao:SetText("#cFF0000"..nPrize)
	else
		ZhanMengShop_MBuy_Price_Yuanbao:SetText("#cfff263"..nPrize)
	end
end

--===============================================
--关闭界面
--===============================================
function ZhanMengShop_MBuy_Closed()
	this:Hide()
end

--===============================================
--取出相应的物资
--===============================================
function ZhanMengShop_MBuy_BuyClicked()

	if ZhanMengShop_MBuy_CanUse() == 0 then
		PushDebugMessage("#{TWSC_200817_15}")
		return 
	end
	
	local count = tonumber(ZhanMengShop_MBuy_InputNum:GetText())
	if count <= 0 or count > KAllianceShop:CalcMaxNumCanBuy(g_ZhanMengShop_MBuy_ItemIndex,0) then
		return
	end
	KAllianceShop:BuyItem(g_ZhanMengShop_MBuy_ItemIndex, count)
	--隐藏界面
	this:Hide()					
end

function ZhanMengShop_MBuy_CalMax()
	--计算最大能领取数量
	local nMaxNum = KAllianceShop:CalcMaxNumCanBuy( g_ZhanMengShop_MBuy_ItemIndex,1)
	ZhanMengShop_MBuy_InputNum : SetText(tostring(nMaxNum))
end

function ZhanMengShop_MBuy_OnBuyNumChanged()
	local	nBuyNum	=	0
	if ZhanMengShop_MBuy_InputNum:GetText() ~= '' then
		nBuyNum	=	tonumber(ZhanMengShop_MBuy_InputNum:GetText())
	end
	if nBuyNum > 250 then
		--一次性购买数目不能超过250
		nBuyNum = 250
		ZhanMengShop_MBuy_InputNum:SetText(tostring(nBuyNum))
		return
	end
	local	nItemType, nMaxNum, nPrize, CommodityName = KAllianceShop:EnumKAllianceShopCommodityInfo(g_ZhanMengShop_MBuy_ItemIndex)
	if nBuyNum*nPrize > KAllianceShop:GetAllianceContributionRate() then
		ZhanMengShop_MBuy_Price_Yuanbao:SetText("#cFF0000"..nBuyNum*nPrize)
	else
		ZhanMengShop_MBuy_Price_Yuanbao:SetText("#cfff263"..nBuyNum*nPrize)
	end
	if nBuyNum > KAllianceShop:CalcMaxNumCanBuy(g_ZhanMengShop_MBuy_ItemIndex,0) or nBuyNum == 0 then
		ZhanMengShop_MBuy_Buy:Disable()
	else
		ZhanMengShop_MBuy_Buy:Enable()
	end
end

function ZhanMengShop_MBuy_CancelClicked()
	this:Hide()
end

function ZhanMengShop_MBuy_Frame_On_ResetPos()
	 ZhanMengShop_MBuy_Frame:SetProperty("UnifiedPosition", g_ZhanMengShop_MBuy_Frame_UnifiedPosition)
end
