local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_ShopIndex = -1
local g_XiGua_FashionShop_curPage = 1
local g_XiGua_FashionShop_num4Page = 15
local g_XiGua_FashionShop_TotalPageNum = 0
local g_XiGua_FashionShop_CurYuLianZi = 0

local g_GoodsList = {}
local g_GoodsLimitedNum = {}
local g_GoodsLimitedNumBK = {}
local g_GoodsNameList = {}
local g_GoodsPrizeList = {}
local g_GoodsMask = {}

local g_ShopItemList = {
[1] = {id = 10126161, num = 1, limit = -1, cost = 1000, },
[2] = {id = 38004274, num = 1, limit = 40, cost = 60, },
[3] = {id = 38004275, num = 1, limit = 40, cost = 61, },
[4] = {id = 38004276, num = 1, limit = 40, cost = 62, },
[5] = {id = 38004277, num = 1, limit = 40, cost = 63, },
}

local g_ShopItemLimitNum = {0, 0, 0, 0, 0}

function XiGua_FashionShop_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("XZ_ONBUY")
	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)		
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function XiGua_FashionShop_OnLoad()

	g_Frame_UnifiedXPosition	= XiGua_FashionShop_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= XiGua_FashionShop_Frame:GetProperty("UnifiedYPosition");
	
	for i = 1, g_XiGua_FashionShop_num4Page do
		g_GoodsList[i] = _G["XiGua_FashionShop_Item"..i]
		g_GoodsNameList[i] = _G["XiGua_FashionShop_ItemInfo"..i.."_Text"]
		g_GoodsPrizeList[i] = _G["XiGua_FashionShop_ItemInfo"..i.."_GB"]
		g_GoodsLimitedNum[i] = _G["XiGua_FashionShop_Item"..i.."LimitNumber"]
		g_GoodsMask[i] = _G["XiGua_FashionShop_ItemIcon_"..i.."Mask"]
		g_GoodsLimitedNumBK[i] = _G["XiGua_FashionShop_Item"..i.."LimitNumberBK"]
	end
	
end

function XiGua_FashionShop_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88808202) then

		if 1 == 1 then
			XiGua_FashionShop_OnClose()
			return
		end
	
		if Get_XParam_INT(0) == 1 then
			local index = 1
			for i = 1, table.getn(g_ShopItemList) do
				if g_ShopItemList[i].limit > 0 and g_ShopItemLimitNum[i] ~= nil then
					g_ShopItemLimitNum[i] = Get_XParam_INT(index)
					index = index + 1
				end
			end
			
			this:Show()
			XiGua_FashionShop_OnInit()
		elseif Get_XParam_INT(0) == 2 then
			
			if this:IsVisible() then
				local nIdx = Get_XParam_INT(1)
				local nLastNum = Get_XParam_INT(2)
				if g_ShopItemList[nIdx] ~= nil and g_ShopItemLimitNum[nIdx] ~= nil and g_GoodsLimitedNum[nIdx] ~= nil then
					if g_ShopItemList[nIdx].limit > 0 then
						g_ShopItemLimitNum[nIdx] = nLastNum
						
						g_GoodsLimitedNum[nIdx]:SetText(tostring(nLastNum))
					
						if nLastNum <= 0 then
							g_GoodsMask[nIdx]:Show()
						end
					end
				end
			end

		end
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		XiGua_FashionShop_OnClose()
		
	elseif event == "ADJEST_UI_POS" then
		XiGua_FashionShop_ResetPos()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		XiGua_FashionShop_ResetPos()
		
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		XiGua_FashionShop_UpdateYLZ()
	end
end

function XiGua_FashionShop_OnInit()

	XiGua_FashionShop_UpPage:Disable()
	XiGua_FashionShop_DownPage:Disable()
	XiGua_FashionShop_CurrentlyPage:SetText(ScriptGlobal_Format("#{MZXB_200609_83}", 1, 1))
		
	XiGua_FashionShop_Reset()
		
	local goodsNum = table.getn(g_ShopItemList)		
	g_XiGua_FashionShop_TotalPageNum = math.floor(( goodsNum - 1 ) / g_XiGua_FashionShop_num4Page) + 1
	if g_XiGua_FashionShop_TotalPageNum < 1 then
		g_XiGua_FashionShop_TotalPageNum = 1
	end
		
	g_XiGua_FashionShop_curPage = 1
	XiGua_FashionShop_UpdateGoods(g_XiGua_FashionShop_curPage)
	XiGua_FashionShop_UpdateYLZ()
	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function XiGua_FashionShop_ResetPos()
	XiGua_FashionShop_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	XiGua_FashionShop_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function XiGua_FashionShop_Reset()
	g_XiGua_FashionShop_curPage = 1
	g_XiGua_FashionShop_TotalPageNum = 0
end

function XiGua_FashionShop_UpdateYLZ()

	g_XiGua_FashionShop_CurYuLianZi = PlayerPackage:CountAvailableItemByIDTable(38004800)
	XiGua_FashionShop_Text1:SetText(ScriptGlobal_Format("#{MZXB_200609_80}", tostring(g_XiGua_FashionShop_CurYuLianZi)) )
	
end

function XiGua_FashionShop_RestGoods()
	for i = 1, g_XiGua_FashionShop_num4Page do
		g_GoodsList[i]:SetActionItem(-1)
		g_GoodsList[i]:ActionDisable()
		g_GoodsNameList[i]:SetText("")
		g_GoodsPrizeList[i]:SetText("")
		g_GoodsLimitedNum[i]:SetText("")
		g_GoodsMask[i]:Hide()
		g_GoodsLimitedNumBK[i]:Hide()
	end
end

function XiGua_FashionShop_UpdateGoods(pageNum)
	if not this:IsVisible() then 
		return 
	end
	
	XiGua_FashionShop_CurrentlyPage:SetText(ScriptGlobal_Format("#{MZXB_200609_83}", pageNum, g_XiGua_FashionShop_TotalPageNum))
	if pageNum == 1 then
		XiGua_FashionShop_UpPage:Disable()
	else
		XiGua_FashionShop_UpPage:Enable()
	end
	
	if pageNum == g_XiGua_FashionShop_TotalPageNum then
		XiGua_FashionShop_DownPage:Disable()
	else
		XiGua_FashionShop_DownPage:Enable()
	end
	
	XiGua_FashionShop_RestGoods()
	
	local goodsNum = table.getn(g_ShopItemList)
	if goodsNum <= 0 then
		return
	end
	
	local startIndex = pageNum * g_XiGua_FashionShop_num4Page - g_XiGua_FashionShop_num4Page
	local endIndex = startIndex + g_XiGua_FashionShop_num4Page
	if endIndex > goodsNum then
		endIndex = goodsNum
	end	
	
	local index = 1
	for i = startIndex + 1, endIndex do
		if g_ShopItemList[i] ~= nil then 				
			local itemId = g_ShopItemList[i].id
			local itemnum = g_ShopItemList[i].num
			if itemId < 0 then
				continue
			end
			
			if itemnum <= 0 then
				continue
			end
			
			local name = DataPool:Lua_GetItemNameByIndex(itemId)
			if name == nil then
				continue
			end
			
			local limitType = g_ShopItemList[i].limit
			local moneyNum = g_ShopItemList[i].cost
			
			local theAction = DataPool:CreateActionItemForShow(itemId, itemnum)
			if theAction:GetID() == 0 then
				continue
			end
			
			g_GoodsList[index]:SetActionItem(theAction:GetID())
			g_GoodsNameList[index]:SetText("#L"..name)
					
			g_GoodsPrizeList[index]:SetText(ScriptGlobal_Format("#{MZXB_200609_78}", moneyNum))
			if limitType > 0 then
				g_GoodsLimitedNumBK[index]:Show()
				
				if g_ShopItemLimitNum[index] ~= nil then
					local lastNum = g_ShopItemLimitNum[index]
					g_GoodsLimitedNum[index]:SetText(tostring(lastNum))
					
					if lastNum <= 0 then
						g_GoodsMask[index]:Show()
					end
				end
			end
			index = index + 1
		end		
	end
end

function XiGua_FashionShop_onGoods(index)
	if index < 1 or index > g_XiGua_FashionShop_num4Page then
		return
	end
	
	if g_ShopItemList[index] == nil or g_ShopItemLimitNum[index] == nil then
		return
	end
	
	if CheckBuyMult() == 1 then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnMultDuiHuanItem" )
			Set_XSCRIPT_ScriptID(888082)
			Set_XSCRIPT_Parameter(0, index) 
			Set_XSCRIPT_Parameter(1, g_ShopItemList[index].id) 
			Set_XSCRIPT_Parameter(2, 1)
			Set_XSCRIPT_Parameter(3, 1) 
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDuiHuanItem" )
			Set_XSCRIPT_ScriptID(888082)
			Set_XSCRIPT_Parameter(0, index) 
			Set_XSCRIPT_Parameter(1, g_ShopItemList[index].id) 
			Set_XSCRIPT_Parameter(2, 1) 
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
			
		if(IsWindowShow("XiGua_BatchBuy")) then
			CloseWindow("XiGua_BatchBuy", true)
		end
	end
end

function XiGua_FashionShop_BuyMult()

	PrepearBuyMult()
	
end

function XiGua_FashionShop_onPageUp()
	if g_XiGua_FashionShop_curPage <= 1 then
		return
	end
	
	g_XiGua_FashionShop_curPage = g_XiGua_FashionShop_curPage - 1
	XiGua_FashionShop_UpdateGoods(g_XiGua_FashionShop_curPage)
end

function XiGua_FashionShop_onPageDown()
	if g_XiGua_FashionShop_curPage >= g_XiGua_FashionShop_TotalPageNum then
		return
	end
	
	g_XiGua_FashionShop_curPage = g_XiGua_FashionShop_curPage + 1
	XiGua_FashionShop_UpdateGoods(g_XiGua_FashionShop_curPage)
end

function XiGua_FashionShop_OnClose()
	
	if(IsWindowShow("XiGua_BatchBuy")) then
		CloseWindow("XiGua_BatchBuy", true)
	end
	
	if(IsWindowShow("XiGua_FashionShow")) then
		CloseWindow("XiGua_FashionShow", true)
	end
	
	this:Hide()
end

function XiGua_FashionShop_OnHidden()
	SetDefaultMouse()
	
	if(IsWindowShow("XiGua_BatchBuy")) then
		CloseWindow("XiGua_BatchBuy", true)
	end
	
	if(IsWindowShow("XiGua_FashionShow")) then
		CloseWindow("XiGua_FashionShow", true)
	end
end

function XiGua_FashionShop_ShowHelp()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")
		Set_XSCRIPT_ScriptID(888082)
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

function XiGua_FashionShop_ShowFashion()

	PushEvent("UI_COMMAND", 88808204, 1)
	
end


