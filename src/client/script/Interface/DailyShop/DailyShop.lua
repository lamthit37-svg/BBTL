--DailyShop
local g_DailyShop_UnifiedPosition;

local DailyShop_ActionButton = {}
local g_DailyShop_pagebuttonleft = {}
local g_nGroup = 1
local g_Sort = {}

local g_ShopItem = {
	[1] = "DailyShop_Item1",
	[2] = "DailyShop_Item2",
	[3] = "DailyShop_Item3",
	[4] = "DailyShop_Item4",
}

local g_ShopPlusIcon = {
	[1] = "DailyShop_Item1_TipsIcon",
	[2] = "DailyShop_Item2_TipsIcon",
	[3] = "DailyShop_Item3_TipsIcon",
	[4] = "DailyShop_Item4_TipsIcon",
}

local g_PlusIcon = {
	[1] = "DailyShop_JiaHao1",
	[2] = "DailyShop_JiaHao2",
	[3] = "DailyShop_JiaHao3",
}

local g_ExItemNumForLicheng = {
	[1] = {usecount = 10, itemid= 39923665, num = 2, itemcount = 0},
	[2] = {usecount = 25, itemid= 39923665, num = 4, itemcount = 0},
	[3] = {usecount = 50, itemid= 39923665, num = 8, itemcount = 0},
	[4] = {usecount = 100, itemid= 39923665, num = 15, itemcount = 0},
	[5] = {usecount = 250, itemid= 39923665, num = 30, itemcount = 0},
	[6] = {usecount = 400, itemid= 39923665, num = 60, itemcount = 0},
}

function DailyShop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_DAILYSHOP",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

function DailyShop_OnLoad()	

	g_DailyShop_UnifiedPosition = DailyShop_Frame:GetProperty("UnifiedPosition")
	
end

function DailyShop_OnEvent(event)

	if (event == "OPEN_DAILYSHOP" ) then
		local operator = tonumber(arg0)
		g_nGroup = tonumber(arg1)
		if operator == 1 then
			DailyShop_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				DailyShop_Update()
			end
		end 
		
		
	elseif (event == "ADJEST_UI_POS" ) then
		DailyShop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DailyShop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--更新界面
--=========================================================
function DailyShop_Update()

	DailyShop_Shop_ClientList:Clear()
	DailyShop_Sort()

	local nPoolNum = DataPool:LuaFnGetDailyShopPoolNum(g_nGroup)
	
	local j = 0
	for i = 1, nPoolNum do

		local idx = g_Sort[i]

		if idx <= 0 or idx > nPoolNum then
			return
		end

		local bar1 = DailyShop_Shop_ClientList:AddChild("DailyShop_Shop_ListContent")
		if not bar1 then
    		break
  		end		
		 
		local textstr = ScriptGlobal_Format("#{RXLB_240709_06}", idx)
		bar1:GetSubItem("DailyShop_Shop_Title"):SetText(textstr)
		
		local nSelectNum = DataPool:LuaFnGetDailyShopSelectNum(g_nGroup, idx)
	
		if nSelectNum <= 0 then

			return
		end

		for z = 1, 4 do
			bar1:GetSubItem(g_ShopItem[z]):Hide()
			bar1:GetSubItem(g_ShopPlusIcon[z]):Hide()
		end
		bar1:GetSubItem(g_PlusIcon[1]):Hide()
		bar1:GetSubItem(g_PlusIcon[2]):Hide()
		bar1:GetSubItem(g_PlusIcon[3]):Hide()

		for x = 1, nSelectNum do
			
			bar1:GetSubItem(g_ShopItem[x]):Show()
			bar1:GetSubItem(g_ShopPlusIcon[x]):Show()
			local oButton = bar1:GetSubItem(g_ShopItem[x])
			if oButton ~= nil then
				oButton:SetEvent( "Clicked", string.format("DailyShop_ItemClicked(%d)",idx) )
				oButton:SetToolTip("#{RXLB_240709_07}")
			end

			if x > 1 then
				bar1:GetSubItem(g_PlusIcon[x - 1]):Show()
			end
			local itemId, itemNum = DataPool:LuaFnGetDailyShopSelectItem(g_nGroup, idx, x)
			if itemId ~= nil then
				local theAction = DataPool:CreateActionItemForShow(itemId, itemNum)
				oButton:SetActionItem( theAction:GetID() );
				
				bar1:GetSubItem(g_ShopPlusIcon[x]):Hide()
			end
		end

        --购买按钮
		local nBuyCount = DataPool:LuaFnGetDailyShopBuyCount(idx)
		local nCanBuyCount = DataPool:LuaFnGetDailyShopCanBuyCount(g_nGroup, idx)
		local nRest = nCanBuyCount - nBuyCount
		bar1:GetSubItem("DailyShop_PurchaseBtn_Tips"):SetText(ScriptGlobal_Format("#{RXLB_240709_17}", nRest))
		local oButtonBuy = bar1:GetSubItem("DailyShop_PurchaseBtn")
		if oButtonBuy ~= nil then
			oButtonBuy:SetEvent( "Clicked", string.format("DailyShop_BuyClicked(%d)",idx) )
			oButtonBuy:Show();
			if nRest > 0 then
			    oButtonBuy:Enable()
		    else
			    oButtonBuy:Disable()
		    end
		end
	end
	
	this:Show()
	this:Activate()
end	

function DailyShop_Sort()
	local nPoolNum = DataPool:LuaFnGetDailyShopPoolNum(g_nGroup)
	local z = 1
	local x = 1
	local nlistSoldout = {}
	local nlistOnSale = {}
	for i = 1, nPoolNum do
		local nBuyCount = DataPool:LuaFnGetDailyShopBuyCount(i)
		local nCanBuyCount = DataPool:LuaFnGetDailyShopCanBuyCount(g_nGroup, i)
		local nRest = nCanBuyCount - nBuyCount
		if nRest <= 0 then
			nlistSoldout[z] = i
			z = z + 1
		else
			nlistOnSale[x] = i
			x = x + 1
		end
	end
	local nidx = 1
	for y = 1,table.getn(nlistOnSale) do
		g_Sort[y] = nlistOnSale[y]
		nidx = nidx + 1
		
	end

	for y = 1, table.getn(nlistSoldout) do
		g_Sort[nidx] = nlistSoldout[y]
		nidx = nidx + 1
	end
end
--=========================================================
--商店说明
--=========================================================
function DailyShop_HelpClick()
	PushEvent("CCSHOP_HELP", 217)
end

--=========================================================
--关闭
--=========================================================
function DailyShop_Close_Clicked()

	g_Sort = {}

	DailyShop_Shop_ClientList:Clear()
	
	this:Hide()
end

function DailyShop_OnHiden()
	DailyShop_Close_Clicked()
end


--=========================================================
--刷新位置
--=========================================================
function DailyShop_On_ResetPos()
	DailyShop_Frame:SetProperty("UnifiedPosition", g_DailyShop_UnifiedPosition);
end
--===============================================
-- 设置共享位置信息
--===============================================
function DailyShop_On_SetLastPos()
	local CurUIPos = Variable:GetVariable("TreasureBoxUIPos")
	if( CurUIPos ~= nil) then
	    DailyShop_FrameNULL:SetProperty("UnifiedPosition", CurUIPos )
	end
end

function DailyShop_BuyClicked(nIndex)
	local nPoolNum = DataPool:LuaFnGetDailyShopPoolNum(g_nGroup)
	if nIndex < 1 or nIndex > nPoolNum then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyDailyShopLiBao" )
		Set_XSCRIPT_ScriptID(999360)
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function DailyShop_ItemClicked(nIndex)
	PushEvent("OPEN_DAILYSHOP_LIBAO", g_nGroup, nIndex )
end