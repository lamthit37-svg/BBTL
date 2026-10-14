local g_MingshiShop_MBuy_Frame_UnifiedPosition
local g_MingshiShop_MBuy_ItemIndex = 0
local g_MSD_MD = 1595
--===============================================
-- OnLoad()
--===============================================
function MingshiShop_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	--逻辑相关的事件
	this:RegisterEvent("OPEN_MSDSHOP_MULTIBUY")
end

function MingshiShop_MBuy_OnLoad()
	g_MingshiShop_MBuy_Frame_UnifiedPosition	=	MingshiShop_MBuy_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function MingshiShop_MBuy_OnEvent( event )
	if event == "OPEN_MSDSHOP_MULTIBUY" then
		g_MingshiShop_MBuy_ItemIndex = tonumber(arg0)
		MingshiShop_MBuy_FreshWindow(tonumber(arg0))
		local careObjId = DataPool:GetNPCIDByServerID(tonumber(arg1))
		this:CareObject(careObjId, 1, "MingshiShop_MBuy")
		MingshiShop_MBuy_InputNum:SetText("1")		--打开界面默认购买领取数值为1
		SetDefaultMouse()
		this:Show()
	end
end

--===============================================
--刷新界面信息
--===============================================
function MingshiShop_MBuy_FreshWindow( index )
	local	nItemType, nMaxNum, nPrize, CommodityName =  KMSDShop:EnumKMSDShopCommodityInfo(index)
	local	theAction = DataPool:CreateActionItemForShowWithMaxNum(nItemType, 1, nMaxNum)
	if theAction:GetID() ~= 0 then
		MingshiShop_MBuy_Item:SetActionItem(theAction:GetID())
		MingshiShop_MBuy_Item:Show()
	end
	MingshiShop_MBuy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	MingshiShop_MBuy_InputNum:SetText("1")					--默认输入为1
	MingshiShop_MBuy_ItemInfo_Text:SetText("#cfff263"..CommodityName)
	MingshiShop_MBuy_ItemInfo_MSZ:SetText(ScriptGlobal_Format("#{MSSD_180529_22}", nPrize))
	MingshiShop_MBuy_shuliang1:SetText("#cfff263"..tostring(DataPool:GetPlayerMission_DataRound(g_MSD_MD)))
	if nPrize > DataPool:GetPlayerMission_DataRound(g_MSD_MD) then
		MingshiShop_MBuy_shuliang:SetText("#cFF0000"..nPrize)
	else
		MingshiShop_MBuy_shuliang:SetText("#cfff263"..nPrize)
	end
end

--===============================================
--关闭界面
--===============================================
function MingshiShop_MBuy_Closed()
	this:Hide()
end

--===============================================
--取出相应的物资
--===============================================
function MingshiShop_MBuy_BuyClicked()
	local count = tonumber(MingshiShop_MBuy_InputNum:GetText())
	if count <= 0 then
		return
	end	
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("BuyItem")
				Set_XSCRIPT_ScriptID(892850)
				Set_XSCRIPT_Parameter(0,g_MingshiShop_MBuy_ItemIndex);
				Set_XSCRIPT_Parameter(1,count);				
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()	
	
	--隐藏界面
	this:Hide()					
end

function MingshiShop_MBuy_CalMax()
	--计算最大能领取数量
	local	nItemType, nMaxNum, nPrize, CommodityName =  KMSDShop:EnumKMSDShopCommodityInfo(g_MingshiShop_MBuy_ItemIndex)
	local nXiaYiValue = DataPool:GetPlayerMission_DataRound(g_MSD_MD)
	
	local nMaxNum = math.floor(nXiaYiValue/nPrize)
	
	MingshiShop_MBuy_InputNum : SetText(tostring(nMaxNum))
end

function MingshiShop_MBuy_OnBuyNumChanged()
	local	nBuyNum	=	0
	if MingshiShop_MBuy_InputNum:GetText() ~= '' then
		nBuyNum	=	tonumber(MingshiShop_MBuy_InputNum:GetText())
	end
	if nBuyNum > 250 then
		--一次性购买数目不能超过250
		nBuyNum = 250
		MingshiShop_MBuy_InputNum:SetText(tostring(nBuyNum))
		return
	end
	local nXiaYiValue = DataPool:GetPlayerMission_DataRound(g_MSD_MD)
	local	nItemType, nMaxNum, nPrize, CommodityName = KMSDShop:EnumKMSDShopCommodityInfo(g_MingshiShop_MBuy_ItemIndex)
	if nBuyNum*nPrize > nXiaYiValue then
		MingshiShop_MBuy_shuliang:SetText("#cFF0000"..nBuyNum*nPrize)
	else
		MingshiShop_MBuy_shuliang:SetText("#cfff263"..nBuyNum*nPrize)
	end
	if nBuyNum > math.floor(nXiaYiValue/nPrize) or nBuyNum == 0 then
		MingshiShop_MBuy_Buy:Disable()
	else
		MingshiShop_MBuy_Buy:Enable()
	end
end

function MingshiShop_MBuy_CancelClicked()
	this:Hide()
end

function MingshiShop_MBuy_Frame_On_ResetPos()
	 MingshiShop_MBuy_Frame:SetProperty("UnifiedPosition", g_MingshiShop_MBuy_Frame_UnifiedPosition)
end
