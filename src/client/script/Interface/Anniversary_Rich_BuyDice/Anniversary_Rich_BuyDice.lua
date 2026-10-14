
--大富翁活动购买骰子
local g_Anniversary_Rich_BuyDice_Frame_UnifiedPosition
local g_Anniversary_Rich_BuyDice_RequireYB = 200  --一个骰子需要的元宝
local g_Anniversary_Rich_BuyDice_DiceShowItemId = 39924231
local g_Anniversary_Rich_BuyDice100_RequireYBDisCount = 14000  --100个骰子的折扣价
local g_Anniversary_Rich_BuyDice100_RequireYB = 20000  --100个骰子的原价
local g_Anniversary_Rich_BuyDice100_LimitBuyCount = 1

function Anniversary_Rich_BuyDice_PreLoad()
	this:RegisterEvent("DAFUWENG_OPEN_BUYDICE",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("DAFUWENG_CLOSE_BUYDICEPOPUI",false)
end

function Anniversary_Rich_BuyDice_OnLoad()
	g_Anniversary_Rich_BuyDice_Frame_UnifiedPosition = Anniversary_Rich_BuyDice_Frame:GetProperty("UnifiedPosition")

end

function Anniversary_Rich_BuyDice_OnEvent(event)
	if event == "DAFUWENG_OPEN_BUYDICE" then
		if this:IsVisible() then
			Anniversary_Rich_BuyDice_Close()
			return
		end
		this:Show()
		Anniversary_Rich_BuyDice_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_Rich_BuyDice_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_Rich_BuyDice_Close()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Rich_BuyDice_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Rich_BuyDice_Close()
	elseif event == "DAFUWENG_CLOSE_BUYDICEPOPUI" then
		Anniversary_Rich_BuyDice_Close()
	elseif event == "UPDATE_YUANBAO" then
		Anniversary_Rich_BuyDice_CashNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_159}", Player:GetData("YUANBAO")))
	end
	
end

function Anniversary_Rich_BuyDice_Open()
	
	Anniversary_Rich_BuyDice_CashNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_159}", Player:GetData("YUANBAO")))
	-- Anniversary_Rich_BuyDice_Item2_Price:SetText(ScriptGlobal_Format("#{ZNLSG_230215_48}",g_Anniversary_Rich_BuyDice100_RequireYB))
	-- Anniversary_Rich_BuyDice_Item2_Cash:SetText(ScriptGlobal_Format("#{ZNLSG_230215_49}",g_Anniversary_Rich_BuyDice100_RequireYBDisCount))

	Anniversary_Rich_BuyDice_Item1_Cash:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	Anniversary_Rich_BuyDice_Item1_Cash:SetText("1")					--默认输入为1   
	-- Anniversary_Rich_BuyDice_Item1_Cash:SetSelected( 0, -1 ); 
	-- Anniversary_Rich_BuyDice_Item1_Cash:SetProperty("NormalTextColour", "#M")
	-- Anniversary_Rich_BuyDice_PriceNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_159}", g_Anniversary_Rich_BuyDice_RequireYB))

	-- local limitBuy = DaFuWeng:GetDataByUI("BuyDice")
	-- Anniversary_Rich_BuyDice_ItemInfo_Text:SetText(ScriptGlobal_Format("#{ZNLSG_230215_47}",limitBuy,g_Anniversary_Rich_BuyDice100_LimitBuyCount))
	local theAction = DataPool:CreateActionItemForShow(g_Anniversary_Rich_BuyDice_DiceShowItemId, 1)
	if theAction:GetID() ~= 0 then
		Anniversary_Rich_BuyDice_Item1:SetActionItem(theAction:GetID())
	end
	-- theAction = DataPool:CreateActionItemForShow(g_Anniversary_Rich_BuyDice_DiceShowItemId, 100)
	-- if theAction:GetID() ~= 0 then
	-- 	Anniversary_Rich_BuyDice_Item2:SetActionItem(theAction:GetID())
	-- end
end

function Anniversary_Rich_BuyDice_GetClick(count)
	if count == 1 then
		--购买一个骰子
		local count = tonumber(Anniversary_Rich_BuyDice_Item1_Cash:GetText())
		if count == nil then
			PushDebugMessage("#{ZNLSG_230215_43}")
			return
		end
		if count <= 0 or count > 100 then
			PushDebugMessage("#{ZNLSG_230215_43}")
			return
		end 
		DaFuWeng:BuyDice(count,0)
--	else
		--购买100个折扣骰子
		--DaFuWeng:BuyDiceOneHundred(0)
	end
end

function Anniversary_Rich_BuyDice_CalMax()
	local ybNum = Player:GetData("YUANBAO")
	local MaxCount =  math.floor(ybNum / g_Anniversary_Rich_BuyDice_RequireYB)
	if MaxCount>100 then
		MaxCount = 100
	end
	Anniversary_Rich_BuyDice_PriceNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_159}", MaxCount*g_Anniversary_Rich_BuyDice_RequireYB))

	-- Anniversary_Rich_BuyDice_Item1_Cash:SetTextOriginal(tostring(MaxCount))
	Anniversary_Rich_BuyDice_Item1_Cash:SetText(tostring(MaxCount))
end

function Anniversary_Rich_BuyDice_TextChanged()

	local num = tonumber(Anniversary_Rich_BuyDice_Item1_Cash:GetText())
	-- if(num == nil or num < 0) then
	-- 	num = 1
	-- 	Anniversary_Rich_BuyDice_Item1_Cash:SetText( tostring( num ) )
	-- end
	local ybNum = Player:GetData("YUANBAO")
	local MaxCount =  math.floor(ybNum / g_Anniversary_Rich_BuyDice_RequireYB)
	if MaxCount>100 then
		MaxCount = 100
	end
	if num ~= nil then
		if(num > MaxCount) then
			num = MaxCount
			Anniversary_Rich_BuyDice_Item1_Cash:SetText( tostring( num ) )
		end
		-- PushDebugMessage("num:"..tostring(num*g_Anniversary_Rich_BuyDice_RequireYB))
		Anniversary_Rich_BuyDice_PriceNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_159}", tostring(num*g_Anniversary_Rich_BuyDice_RequireYB)))
		-- str = tostring( num );
		-- Anniversary_Rich_BuyDice_Item1_Cash:SetTextOriginal( str );
		-- Anniversary_Rich_BuyDice_Item1_Cash:SetText( str );
	else
		Anniversary_Rich_BuyDice_PriceNum:SetText("#L0")
	end
	
end

function Anniversary_Rich_BuyDice_On_ResetPos()
	Anniversary_Rich_BuyDice_Frame:SetProperty("UnifiedPosition", g_Anniversary_Rich_BuyDice_Frame_UnifiedPosition)

end

function Anniversary_Rich_BuyDice_Close()
	this:Hide()
end

function Anniversary_Rich_BuyDice_Close_Clicked()
	this:Hide()
end

function Anniversary_Rich_BuyDice_OnHidden()
end