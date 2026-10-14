local g_BieYeFurnitureShop_UnifiedPosition = 0
local g_FurnitureShop_ItemNum = 12
local g_ItemIcon = {}
local g_ItemName = {}
local g_ItemNeedMoney = {}
local g_MaxBuyNum = 10;

local g_CaredNpc = -1
local g_curPage = 1
local g_maxPage = 1
local g_curBuyNum = 0
local g_AreaType =-1
local g_ItemIndex = {}
local g_curItemNum = 0

local g_CallBackButtonNum = 7
local g_CallBack_Button = {};


function BieYe_FurnitureShop_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	--this:RegisterEvent("UPDATE_BOOTH");
end

function BieYe_FurnitureShop_OnLoad()
	g_ItemIcon[1] = BieYe_FurnitureShop_Item1
	g_ItemIcon[2] = BieYe_FurnitureShop_Item2
	g_ItemIcon[3] = BieYe_FurnitureShop_Item3
	g_ItemIcon[4] = BieYe_FurnitureShop_Item4
	g_ItemIcon[5] = BieYe_FurnitureShop_Item5
	g_ItemIcon[6] = BieYe_FurnitureShop_Item6
	g_ItemIcon[7] = BieYe_FurnitureShop_Item7
	g_ItemIcon[8] = BieYe_FurnitureShop_Item8
	g_ItemIcon[9] = BieYe_FurnitureShop_Item9
	g_ItemIcon[10] = BieYe_FurnitureShop_Item10
	g_ItemIcon[11] = BieYe_FurnitureShop_Item11
	g_ItemIcon[12] = BieYe_FurnitureShop_Item12
	
	g_ItemName[1] = BieYe_FurnitureShop_ItemInfo1_Text
	g_ItemName[2] = BieYe_FurnitureShop_ItemInfo2_Text
	g_ItemName[3] = BieYe_FurnitureShop_ItemInfo3_Text
	g_ItemName[4] = BieYe_FurnitureShop_ItemInfo4_Text
	g_ItemName[5] = BieYe_FurnitureShop_ItemInfo5_Text
	g_ItemName[6] = BieYe_FurnitureShop_ItemInfo6_Text
	g_ItemName[7] = BieYe_FurnitureShop_ItemInfo7_Text
	g_ItemName[8] = BieYe_FurnitureShop_ItemInfo8_Text
	g_ItemName[9] = BieYe_FurnitureShop_ItemInfo9_Text
	g_ItemName[10] = BieYe_FurnitureShop_ItemInfo10_Text
	g_ItemName[11] = BieYe_FurnitureShop_ItemInfo11_Text
	g_ItemName[12] = BieYe_FurnitureShop_ItemInfo12_Text
	
	g_ItemNeedMoney[1] = BieYe_FurnitureShop_ItemInfo1_Price
	g_ItemNeedMoney[2] = BieYe_FurnitureShop_ItemInfo2_Price
	g_ItemNeedMoney[3] = BieYe_FurnitureShop_ItemInfo3_Price
	g_ItemNeedMoney[4] = BieYe_FurnitureShop_ItemInfo4_Price
	g_ItemNeedMoney[5] = BieYe_FurnitureShop_ItemInfo5_Price
	g_ItemNeedMoney[6] = BieYe_FurnitureShop_ItemInfo6_Price
	g_ItemNeedMoney[7] = BieYe_FurnitureShop_ItemInfo7_Price
	g_ItemNeedMoney[8] = BieYe_FurnitureShop_ItemInfo8_Price
	g_ItemNeedMoney[9] = BieYe_FurnitureShop_ItemInfo9_Price
	g_ItemNeedMoney[10] = BieYe_FurnitureShop_ItemInfo10_Price
	g_ItemNeedMoney[11] = BieYe_FurnitureShop_ItemInfo11_Price
	g_ItemNeedMoney[12] = BieYe_FurnitureShop_ItemInfo12_Price
	
	g_CallBack_Button[1] = BieYe_FurnitureShop_Callback1
	g_CallBack_Button[2] = BieYe_FurnitureShop_Callback2
	g_CallBack_Button[3] = BieYe_FurnitureShop_Callback3
	g_CallBack_Button[4] = BieYe_FurnitureShop_Callback4
	g_CallBack_Button[5] = BieYe_FurnitureShop_Callback5
	g_CallBack_Button[6] = BieYe_FurnitureShop_Callback6
	g_CallBack_Button[7] = BieYe_FurnitureShop_Callback7
	
	BieYe_FurnitureShop_Repair_SaleBack:Hide()
	BieYe_FurnitureShop_Sell:Hide()
	
	g_BieYeFurnitureShop_UnifiedPosition = BieYe_FurnitureShop_Frame:GetProperty("UnifiedPosition")
end

function BieYe_FurnitureShop_OnHidden()
	this:CareObject(g_CaredNpc, 0, "BieYe_FurnitureShop")
	g_CaredNpc = -1
	g_curPage = 1
	g_curBuyNum = 0 
	g_AreaType = -1
	g_maxPage = 1
	g_ItemIndex = {}
	g_curItemNum = 0
end

function BieYe_FurnitureShop_OnEvent(event)

	if (event == "ADJEST_UI_POS") then
		BieYe_FurnitureShop_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYe_FurnitureShop_ResetPos()
		
	elseif (even == "HIDE_ON_SCENE_TRANSED") then
		BieYe_FurnitureShop_OnClose()
		
	--elseif (even == "UPDATE_BOOTH") then
		--BieYe_FurnitureShop_ShowCallBack()
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 891837) then
		local Type = Get_XParam_INT(0)
		if Type == 0 then    				--发送NPCid
			local npcServerId = Get_XParam_INT(1)
			g_CaredNpc = DataPool:GetNPCIDByServerID(npcServerId)
			
			if g_CaredNpc == -1 then
				PushDebugMessage("server传过来的数据有问题。")
				return
			end
			
			this:CareObject(g_CaredNpc, 1, "BieYe_FurnitureShop")
			
		elseif Type == 1 then		 		--打开界面
			if g_CaredNpc == -1 then
				return
			end
			
			local Type = Get_XParam_INT(2)
			if(this:IsVisible()) then
				if g_AreaType ~= Type then
					BieYe_FurnitureShop_OnClose()
				else
					return
				end
			end
			
			g_curBuyNum = Get_XParam_INT(1)
			g_AreaType = Type 
			if g_AreaType == 0 then
				BieYe_FurnitureShop_Text:SetText("#{JJSD_160912_08}")
			else
				BieYe_FurnitureShop_Text:SetText("#{JJSD_160912_09}")
			end
			
			local str = ScriptGlobal_Format("#{JJSD_160912_10}",tostring(g_MaxBuyNum-g_curBuyNum))
			BieYe_FurnitureShop_Show_Info:SetText(str)
			
			BieYeUI:PrepareFurnitureShopItem(g_AreaType)
			local ItemNum = BieYeUI:GetFurnitureShopItemNum()
			if ItemNum > 0 then
				ItemNum = ItemNum - 1
			end
			g_maxPage = math.floor(ItemNum / g_FurnitureShop_ItemNum) + 1
			
			BieYe_FurnitureShop_UpdateFrame()
			--BieYe_FurnitureShop_ShowCallBack()
			this:Show()
			
		elseif Type == 2 then				--刷新界面
			if g_CareNpc == -1 then
				return
			end
			
			if(this:IsVisible()) then
				g_curBuyNum = Get_XParam_INT(1)
				local str = ScriptGlobal_Format("#{JJSD_160912_10}",tostring(g_MaxBuyNum-g_curBuyNum))
				BieYe_FurnitureShop_Show_Info:SetText(str)
			end
		end
	end
end

function BieYe_FurnitureShop_OnClose()
	this:Hide()
end

function BieYe_FurnitureShop_ResetPos()
	BieYe_FurnitureShop_Frame:SetProperty("UnifiedPosition", g_BieYeFurnitureShop_UnifiedPosition)
end

function BieYe_FurnitureShop_UpdateFrame()
	BieYe_FurnitureShop_UpPage:Disable()
	BieYe_FurnitureShop_DownPage:Disable()
	
	for i = 1, g_FurnitureShop_ItemNum do
		g_ItemIcon[i]:SetActionItem(-1)
		g_ItemName[i]:Hide()
		g_ItemNeedMoney[i]:Hide()
	end
	
	local str = ScriptGlobal_Format("#{HDRCYH_130118_16}",tostring(g_curPage), tostring(g_maxPage))
	BieYe_FurnitureShop_CurrentlyPage:SetText(str)
	
	if g_curPage ~= 1 then
		BieYe_FurnitureShop_UpPage:Enable()
	end
	
	if g_curPage ~= g_maxPage then
		BieYe_FurnitureShop_DownPage:Enable()
	end
	
	local id = 1
	g_curItemNum = 0
	g_ItemIndex = {}
	for i = (g_curPage - 1) * g_FurnitureShop_ItemNum + 1, g_curPage * g_FurnitureShop_ItemNum do
		local Index, needMoneyNum, Name = BieYeUI:GetFurnitureShopItemInfo(i - 1, g_AreaType)
		if Index == -1 then
			break
		end
		
		local theAction = BieYeUI:EnumFurnitureShopItem(i-1)
		if theAction:GetID() ~= 0 then
			g_ItemIcon[id]:SetActionItem(theAction:GetID())
		else
			g_ItemIcon[id]:SetActionItem(-1)
		end
		
		g_ItemName[id]:SetText(Name)
		g_ItemName[id]:Show()
		--金币
		local nGold = tostring(needMoneyNum)
		g_ItemNeedMoney[id]:SetProperty("MoneyNumber",""..nGold)
		g_ItemNeedMoney[id]:Show()
	
		g_ItemIndex[id] = Index
		
		g_curItemNum = g_curItemNum + 1
		id = id + 1
	end
end

function	BieYe_FurnitureShop_ShowCallBack()
	--回购
	local nCallbackType = NpcShop:GetShopType("callback");
	if( nCallbackType <= 0 ) then
		for i=1, g_CallBackButtonNum do
			g_CallBack_Button[i]:Hide();
			g_CallBack_Button[i]:SetActionItem(-1);
		end
	else
		for i=1, g_CallBackButtonNum do
			g_CallBack_Button[i]:Show();
			g_CallBack_Button[i]:SetActionItem(-1);
		end

		-- 显示回购物品
		local nActIndex = 0;
		local nCallNum = NpcShop:GetCallBackNum();
		local i=1;
		while i<=nCallNum do
			local theAction = NpcShop:EnumCallBackItem(nActIndex);

			if theAction:GetID() ~= 0 then
				g_CallBack_Button[i]:SetActionItem(theAction:GetID());
				i = i+1;
			else
				g_CallBack_Button[i]:SetActionItem(-1);
				i = i+1;
			end

			nActIndex = nActIndex+1;
		end
	end
end

function BieYe_FurnitureShop_OnBuy(index)
	if index < 1 or index > g_curItemNum then
		return
	end
	
	if g_curBuyNum >= g_MaxBuyNum then
		PushDebugMessage("#{JJSD_160912_12}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnCheckBuyFurniture")
		Set_XSCRIPT_ScriptID( 891923 )
		Set_XSCRIPT_Parameter(0,g_ItemIndex[index])
		Set_XSCRIPT_Parameter(1,g_AreaType)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function BieYe_FurnitureShop_OnPageUp()
	g_curPage = g_curPage - 1
	if g_curPage < 1 then
		g_curPage = g_maxPage
	end
	
	BieYe_FurnitureShop_UpdateFrame()
end

function BieYe_FurnitureShop_OnPageDown()
	g_curPage = g_curPage + 1
	if g_curPage > g_maxPage then
		g_curPage = 1
	end
	
	BieYe_FurnitureShop_UpdateFrame()
end

function BieYe_FurnitureShop_Sale()
	if(IsWindowShow("Shop_Fitting")) then
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	PrepearSale();
end

function BieYe_FurnitureShop_CallBackClicked(nIndex)

	if nIndex < 1 or nIndex > g_CallBackButtonNum then
		return
	end
	
	if(IsWindowShow("Shop_Fitting")) then
		CloseShopFitting();
		CloseWindow("Shop_Fitting", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	g_CallBack_Button[nIndex]:DoAction();
end