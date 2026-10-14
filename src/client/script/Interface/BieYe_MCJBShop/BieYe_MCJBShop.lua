local TOTALFITTINGKIND_NUM = 10;
local g_BieYeMCJBShop_UnifiedPosition = 0
local g_MCJBShop_ItemNum = 12
local g_ItemIcon = {}
local g_ItemName = {}
local g_ItemNeedMoney = {}
local g_ItemDiscount = {}
local g_MaxBuyNum = 3;

local g_CaredNpc = -1
local g_curPage = 1
local g_maxPage = 1
local g_curBuyNum = -1	--该家园今日已购买次数
local g_curItemNum = 0

--当前商店的商品数量
local g_nTotalNum = 0
local g_ItemId = {}
local g_ItemConIndex = {}

function BieYe_MCJBShop_PreLoad()
	this:RegisterEvent("OPEN_MCJBBOOTH")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BieYe_MCJBShop_OnLoad()
	g_ItemIcon[1] = BieYe_MCJBShop_Item1
	g_ItemIcon[2] = BieYe_MCJBShop_Item2
	g_ItemIcon[3] = BieYe_MCJBShop_Item3
	g_ItemIcon[4] = BieYe_MCJBShop_Item4
	g_ItemIcon[5] = BieYe_MCJBShop_Item5
	g_ItemIcon[6] = BieYe_MCJBShop_Item6
	g_ItemIcon[7] = BieYe_MCJBShop_Item7
	g_ItemIcon[8] = BieYe_MCJBShop_Item8
	g_ItemIcon[9] = BieYe_MCJBShop_Item9
	g_ItemIcon[10] = BieYe_MCJBShop_Item10
	g_ItemIcon[11] = BieYe_MCJBShop_Item11
	g_ItemIcon[12] = BieYe_MCJBShop_Item12
	
	g_ItemName[1] = BieYe_MCJBShop_ItemInfo1_Text
	g_ItemName[2] = BieYe_MCJBShop_ItemInfo2_Text
	g_ItemName[3] = BieYe_MCJBShop_ItemInfo3_Text
	g_ItemName[4] = BieYe_MCJBShop_ItemInfo4_Text
	g_ItemName[5] = BieYe_MCJBShop_ItemInfo5_Text
	g_ItemName[6] = BieYe_MCJBShop_ItemInfo6_Text
	g_ItemName[7] = BieYe_MCJBShop_ItemInfo7_Text
	g_ItemName[8] = BieYe_MCJBShop_ItemInfo8_Text
	g_ItemName[9] = BieYe_MCJBShop_ItemInfo9_Text
	g_ItemName[10] = BieYe_MCJBShop_ItemInfo10_Text
	g_ItemName[11] = BieYe_MCJBShop_ItemInfo11_Text
	g_ItemName[12] = BieYe_MCJBShop_ItemInfo12_Text
	
	g_ItemNeedMoney[1] = BieYe_MCJBShop_ItemInfo1_Price
	g_ItemNeedMoney[2] = BieYe_MCJBShop_ItemInfo2_Price
	g_ItemNeedMoney[3] = BieYe_MCJBShop_ItemInfo3_Price
	g_ItemNeedMoney[4] = BieYe_MCJBShop_ItemInfo4_Price
	g_ItemNeedMoney[5] = BieYe_MCJBShop_ItemInfo5_Price
	g_ItemNeedMoney[6] = BieYe_MCJBShop_ItemInfo6_Price
	g_ItemNeedMoney[7] = BieYe_MCJBShop_ItemInfo7_Price
	g_ItemNeedMoney[8] = BieYe_MCJBShop_ItemInfo8_Price
	g_ItemNeedMoney[9] = BieYe_MCJBShop_ItemInfo9_Price
	g_ItemNeedMoney[10] = BieYe_MCJBShop_ItemInfo10_Price
	g_ItemNeedMoney[11] = BieYe_MCJBShop_ItemInfo11_Price
	g_ItemNeedMoney[12] = BieYe_MCJBShop_ItemInfo12_Price

	g_ItemDiscount[1] = BieYe_MCJBShop_Item1_Discount
	g_ItemDiscount[2] = BieYe_MCJBShop_Item2_Discount
	g_ItemDiscount[3] = BieYe_MCJBShop_Item3_Discount
	g_ItemDiscount[4] = BieYe_MCJBShop_Item4_Discount
	g_ItemDiscount[5] = BieYe_MCJBShop_Item5_Discount
	g_ItemDiscount[6] = BieYe_MCJBShop_Item6_Discount
	g_ItemDiscount[7] = BieYe_MCJBShop_Item7_Discount
	g_ItemDiscount[8] = BieYe_MCJBShop_Item8_Discount
	g_ItemDiscount[9] = BieYe_MCJBShop_Item9_Discount
	g_ItemDiscount[10] = BieYe_MCJBShop_Item10_Discount
	g_ItemDiscount[11] = BieYe_MCJBShop_Item11_Discount
	g_ItemDiscount[12] = BieYe_MCJBShop_Item12_Discount
	
	g_BieYeMCJBShop_UnifiedPosition = BieYe_MCJBShop_Frame:GetProperty("UnifiedPosition")
end

function BieYe_MCJBShop_OnHidden()
	this:CareObject(g_CaredNpc, 0, "BieYe_MCJBShop")
	g_CaredNpc = -1
	g_curPage = 1
	g_curBuyNum = 0 
	g_maxPage = 1
	g_ItemId = {}
	g_ItemConIndex = {}
	g_curItemNum = 0
end

function BieYe_MCJBShop_OnEvent(event)

	if (event == "ADJEST_UI_POS") then
		BieYe_MCJBShop_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYe_MCJBShop_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BieYe_MCJBShop_OnClose()
	elseif (event == "OPEN_MCJBBOOTH") then
		this:Show();
		-- 在先打开元宝商店，后打开NPC商店的时候，存在一个问题
		-- 元宝商店在打开时会关闭已经打开的商店，而关闭这个操作会将是否打开商店这个状态只为假，从而导致购买相关的逻辑出现错误
		-- 目前的解决办法是在Show的地方，设置是否打开商店的状态为真。
		OpenBooth();
		BieYe_MCJBShop_UpdateFrame()
		if(IsWindowShow("Shop_Fitting")) then
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			--CloseShopFitting();
			CloseWindow("Shop_Fitting", true);
		end
		if(IsWindowShow("Shop_Fitting2")) then
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			CloseWindow("Shop_Fitting2", true);
		end
		SetDefaultMouse();

		if IsWindowShow("VIP_Shop") then
			CloseWindow("VIP_Shop", true)
		end
		
		if(IsWindowShow("Bank")) then
		  CloseWindow("Bank", true);
		end

		if(IsWindowShow("BigBank")) then
		  CloseWindow("BigBank", true);
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 891838 then
		
		local Type = Get_XParam_INT(0)
		if Type == 0 then    				--发送NPCid
			local npcServerId = Get_XParam_INT(1)
			g_CaredNpc = DataPool:GetNPCIDByServerID(npcServerId)
			if g_CaredNpc == -1 then
				PushDebugMessage("server传过来的数据有问题。")
				return
			end
			
			this:CareObject(g_CaredNpc, 1, "BieYe_MCJBShop")		
		elseif Type == 1 then				--刷新界面
			g_curBuyNum = Get_XParam_INT(1)
			
			if g_CaredNpc == -1 then
				return
			end
			if(this:IsVisible()) then
				local str = ScriptGlobal_Format("#{MCSD_170727_08}",tostring(g_MaxBuyNum-g_curBuyNum))
				BieYe_MCJBShop_Show_Info:SetText(str)
			end
		end
	end
end

function BieYe_MCJBShop_OnClose()
	this:Hide()
end

function BieYe_MCJBShop_ResetPos()
	BieYe_MCJBShop_Frame:SetProperty("UnifiedPosition", g_BieYeMCJBShop_UnifiedPosition)
end

function BieYe_MCJBShop_UpdateFrame()
	--隐藏出售按钮
	BieYe_MCJBShop_Sell:Hide()
	
	BieYe_MCJBShop_UpPage:Disable()
	BieYe_MCJBShop_DownPage:Disable()
	
	for i = 1, g_MCJBShop_ItemNum do
		g_ItemIcon[i]:SetActionItem(-1)
		g_ItemName[i]:Hide()
		g_ItemNeedMoney[i]:Hide()
		g_ItemDiscount[i]:Hide()
		g_ItemId[i] = -1
		g_ItemConIndex[i] = -1
	end
	g_curItemNum = 0
	
	if g_nTotalNum == 0 or g_nTotalNum ~= GetActionNum("boothitem") then
		g_nTotalNum = GetActionNum("boothitem")
	end
	
	-- 计算总页数
	local	nTotalPage;
	if( g_nTotalNum < 1 ) then
		nTotalPage	= 1;
	else
		nTotalPage	= math.floor((g_nTotalNum - 1)/g_MCJBShop_ItemNum) + 1;
	end
	g_maxPage = nTotalPage
	
	local str = ScriptGlobal_Format("#{HDRCYH_130118_16}",tostring(g_curPage), tostring(g_maxPage))
	BieYe_MCJBShop_CurrentlyPage:SetText(str)
	
	if g_curPage ~= 1 then
		BieYe_MCJBShop_UpPage:Enable()
	end
	
	if g_curPage ~= g_maxPage then
		BieYe_MCJBShop_DownPage:Enable()
	end
	
	local nActIndex = (g_curPage - 1)*g_MCJBShop_ItemNum;
	local id = 1
	while id <= g_MCJBShop_ItemNum do
		local theAction = EnumAction(nActIndex, "boothitem");
		if theAction:GetID() ~= 0 then
			g_ItemIcon[id]:SetActionItem(theAction:GetID());

			if(theAction:GetItemColorInShop()~="") then
				g_ItemName[id]:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				g_ItemName[id]:SetText( theAction:GetName() );
			end
			g_ItemName[id]:Show()

			local	nPrice	= NpcShop:EnumItemPrice(nActIndex)
			local 	nNumber = NpcShop:EnumItemNumber(nActIndex)
			local totalPrice = nPrice * nNumber
			g_ItemNeedMoney[id]:SetProperty("MoneyNumber", tostring(totalPrice))
			g_ItemNeedMoney[id]:Show()
			
			local buyRate = theAction:GetItemBuyRateInShop()
			if buyRate < 100 then
				g_ItemDiscount[id]:Show()
			end
			
			local 	nID = NpcShop:EnumItemID(nActIndex)
			g_ItemId[id] = nID
			g_ItemConIndex[id] = nActIndex
			
			g_curItemNum = g_curItemNum + 1
			id = id+1;
		else
			g_ItemIcon[id]:SetActionItem(-1)
			g_ItemName[id]:SetText("")
			g_ItemNeedMoney[id]:SetText("")

			id = id+1;
		end
		nActIndex = nActIndex+1;
	end
end

function BieYe_MCJBShop_OnBuy(index)
	if g_curBuyNum < 0 then
		--没有初始化购买次数，不允许购买
		return 
	end
	
	if index < 1 or index > g_curItemNum then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnCheckBuyMCJBShop")
		Set_XSCRIPT_ScriptID( 891927 )
		Set_XSCRIPT_Parameter(0, g_ItemConIndex[index])
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function BieYe_MCJBShop_OnPageUp()
	g_curPage = g_curPage - 1
	if g_curPage < 1 then
		g_curPage = g_maxPage
	end
	
	BieYe_MCJBShop_UpdateFrame()
end

function BieYe_MCJBShop_OnPageDown()
	g_curPage = g_curPage + 1
	if g_curPage > g_maxPage then
		g_curPage = 1
	end
	
	BieYe_MCJBShop_UpdateFrame()
end
