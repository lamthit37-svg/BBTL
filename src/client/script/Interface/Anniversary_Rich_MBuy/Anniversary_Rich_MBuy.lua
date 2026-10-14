
--大富翁活动碎片商店批量兑换某个道具的界面
local g_Anniversary_Rich_MBuy_Frame_UnifiedPosition
local g_Anniversary_Rich_MBuy_TableId = -1
local g_Anniversary_Rich_MBuy_Price = 1
local g_Anniversary_Rich_MBuy_JiFen = 0
function Anniversary_Rich_MBuy_PreLoad()
	this:RegisterEvent("DAFUWENG_OPEN_EXCHANGEITEM",true)
	this:RegisterEvent("DAFUWENG_CLOSE_POPUI",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
end

function Anniversary_Rich_MBuy_OnLoad()
	g_Anniversary_Rich_MBuy_Frame_UnifiedPosition = Anniversary_Rich_MBuy_Frame:GetProperty("UnifiedPosition")

end

function Anniversary_Rich_MBuy_OnEvent(event)
	if event == "DAFUWENG_OPEN_EXCHANGEITEM" then
		-- if this:IsVisible() then
		-- 	Anniversary_Rich_MBuy_Close_Clicked()
		-- 	return
		-- end
		if Player:GetData("IsOriginalJD") == 1 and IsInTServer() == 1 then
			PushDebugMessage("无法在当前场景进行该操作。")
			return 
		end		
		g_Anniversary_Rich_MBuy_TableId = tonumber(arg0)
		if g_Anniversary_Rich_MBuy_TableId ~= nil then
			this:Show()
		
		-- PushDebugMessage("g_Anniversary_Rich_MBuy_TableId:"..tostring(g_Anniversary_Rich_MBuy_TableId))
			Anniversary_Rich_MBuy_Open()
		end
	elseif event == "DAFUWENG_CLOSE_POPUI" then
		Anniversary_Rich_MBuy_Close_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_Rich_MBuy_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_Rich_MBuy_Close_Clicked()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Rich_MBuy_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Rich_MBuy_Close_Clicked()
	end
	
end


function Anniversary_Rich_MBuy_GetShopTable(tableId)
	local iteminfo = nil
	if Player:GetData("IsOriginalJD") == 1 then
		iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANSHOP_ORI",tableId)
	else
		local kjtype   = KaJi:LuaFnGetKaJiType(127)			
		if kjtype == 1 then
			iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANSHOP_KAJI_1",tableId)
		else
			iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANSHOP",tableId)
		end
	end	

	return iteminfo
end
function Anniversary_Rich_MBuy_Open()
	local iteminfo = Anniversary_Rich_MBuy_GetShopTable(g_Anniversary_Rich_MBuy_TableId)




	if iteminfo then
		local theAction = DataPool:CreateActionItemForShow(iteminfo.nItemID, iteminfo.nSaleCount)
		if theAction:GetID() ~= 0 then
			Anniversary_Rich_MBuy_Item:SetActionItem(theAction:GetID())
		end
		Anniversary_Rich_MBuy_ItemInfo_Text:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
		Anniversary_Rich_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{ZNLSG_230215_154}",iteminfo.nPrice))
		g_Anniversary_Rich_MBuy_Price = iteminfo.nPrice
		if iteminfo.nLimit > 0 then
			Anniversary_Rich_MBuy_Item_BuyLimit:Show()
			local buyTimes = DaFuWeng:GetItemBuyTimes(g_Anniversary_Rich_MBuy_TableId-1)
			if iteminfo.nLimit-buyTimes > 0 then
				Anniversary_Rich_MBuy_Item_BuyLimitNumBK:Show()
				Anniversary_Rich_MBuy_Item_BuyLimitNum:SetText(tostring(iteminfo.nLimit-buyTimes))
			else
				Anniversary_Rich_MBuy_Item_BuyLimitNumBK:Hide()
			end
		else
			Anniversary_Rich_MBuy_Item_BuyLimit:Hide()
			Anniversary_Rich_MBuy_Item_BuyLimitNumBK:Hide()
		end
	end
	

	local Jifen,DiceCount,CurPos,Round,selfRoundReward = DaFuWeng:GetDataByUI("Rich")
	g_Anniversary_Rich_MBuy_JiFen = Jifen
	Anniversary_Rich_MBuy_CashNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_106}",g_Anniversary_Rich_MBuy_JiFen))

	Anniversary_Rich_MBuy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	Anniversary_Rich_MBuy_InputNum:SetText("1")					   
	-- Anniversary_Rich_MBuy_InputNum:SetSelected( 0, -1 )

	
end

--最大按钮点击
function Anniversary_Rich_MBuy_CalMax()
	local MaxCount = Anniversary_Rich_MBuy_GetMax()
	Anniversary_Rich_MBuy_InputNum:SetText(tostring(MaxCount))
	
end

function Anniversary_Rich_MBuy_GetMax()

	local iteminfo = Anniversary_Rich_MBuy_GetShopTable(g_Anniversary_Rich_MBuy_TableId)


	if g_Anniversary_Rich_MBuy_Price > 0 and iteminfo then
		local MaxCount =  math.floor(g_Anniversary_Rich_MBuy_JiFen / g_Anniversary_Rich_MBuy_Price)
		local buyTimes = DaFuWeng:GetItemBuyTimes(g_Anniversary_Rich_MBuy_TableId-1)
		if iteminfo.nLimit > 0 and MaxCount > iteminfo.nLimit-buyTimes then
			MaxCount = iteminfo.nLimit-buyTimes
		end
		return MaxCount
	end
	return 0
end

--确认购买
function Anniversary_Rich_MBuy_OK_Clicked()
	local count = tonumber(Anniversary_Rich_MBuy_InputNum:GetText())
	if g_Anniversary_Rich_MBuy_Price <= 0 then
		return 
	end
	local MaxCount = Anniversary_Rich_MBuy_GetMax()
	-- local MaxCount =  math.floor(g_Anniversary_Rich_MBuy_JiFen / g_Anniversary_Rich_MBuy_Price)
	if count == nil then
		PushDebugMessage("#{ZNLSG_230215_164}")
		return
	end
	if count <= 0 or count > MaxCount then
		PushDebugMessage("#{ZNLSG_230215_164}")
		return
	end 
	DaFuWeng:AskToBuyItem(tonumber(g_Anniversary_Rich_MBuy_TableId)-1,count)
end

function Anniversary_Rich_MBuy_TextChanged()
	local num = tonumber(Anniversary_Rich_MBuy_InputNum:GetText())
	-- if(num == nil or num < 0) then
	-- 	num = 1
	-- 	Anniversary_Rich_MBuy_InputNum:SetText( tostring( num ) )
	-- end
	if g_Anniversary_Rich_MBuy_Price <= 0 then
		return 
	end
	local MaxCount = Anniversary_Rich_MBuy_GetMax()
	-- PushDebugMessage("MaxCount:"..tostring(MaxCount))
	-- local MaxCount =  math.floor(g_Anniversary_Rich_MBuy_JiFen / g_Anniversary_Rich_MBuy_Price)
	if num ~= nil then
	
		if num > MaxCount then
			num = MaxCount
			Anniversary_Rich_MBuy_InputNum:SetText(tostring(num))
		end
		Anniversary_Rich_MBuy_PriceNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_153}", num*g_Anniversary_Rich_MBuy_Price))
	-- str = tostring( num );
	-- Anniversary_Rich_MBuy_InputNum:SetText( str )
	else
		Anniversary_Rich_MBuy_PriceNum:SetText("#L0")
	end
end

function Anniversary_Rich_MBuy_On_ResetPos()
	Anniversary_Rich_MBuy_Frame:SetProperty("UnifiedPosition", g_Anniversary_Rich_MBuy_Frame_UnifiedPosition)

end

function Anniversary_Rich_MBuy_OnHidden()
	g_Anniversary_Rich_MBuy_Price = 1

end

function Anniversary_Rich_MBuy_Close_Clicked()
	this:Hide()
end

