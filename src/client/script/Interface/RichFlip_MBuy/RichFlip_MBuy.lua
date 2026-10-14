--RichFlip_MBuy

local g_RichFlip_MBuy_Frame_UnifiedPosition
local g_RichFlip_MBuy_TableId = -1
local g_RichFlip_MBuy_CanGetItemCount = 0
local g_RichFlip_MBuy_daibi = 0

function RichFlip_MBuy_PreLoad()
	this:RegisterEvent("LUCKYLINE_OPEN_MULIT_BUY",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function RichFlip_MBuy_OnLoad()
	g_RichFlip_MBuy_Frame_UnifiedPosition = RichFlip_MBuy_Frame:GetProperty("UnifiedPosition")

end

function RichFlip_MBuy_OnEvent(event)
	if event == "LUCKYLINE_OPEN_MULIT_BUY" then
		g_RichFlip_MBuy_TableId = tonumber(arg0)
		g_RichFlip_MBuy_CanGetItemCount = tonumber(arg1)
		g_RichFlip_MBuy_daibi = tonumber(arg2)
		
		if g_RichFlip_MBuy_TableId ~= nil and g_RichFlip_MBuy_CanGetItemCount ~=nil then
			this:Show()
			RichFlip_MBuy_Open()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
			RichFlip_MBuy_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		RichFlip_MBuy_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		RichFlip_MBuy_Close_Clicked()
	end
	
end

function RichFlip_MBuy_Open()
	local nShowItemId,nItemNum,nIsBind,nMaxnum,nNeedDaibi = DataPool:LuaFnGetLuckyLineShopItemInfo(g_RichFlip_MBuy_TableId)
	if nShowItemId ~= nil and nShowItemId > 0 then
		local theAction = nil
		if nIsBind == 1 then
			theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
		else
			theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
		end		
		if theAction ~= nil then
			RichFlip_MBuy_Item:SetActionItem(theAction:GetID())
		end
		RichFlip_MBuy_ItemInfo_Name:SetText("#L"..theAction:GetName())
		RichFlip_MBuy_ItemInfo_Price:SetText("#L"..ScriptGlobal_Format("#{FPLS_240715_102}",nNeedDaibi))
		if nMaxnum > 0 then
			RichFlip_MBuy_Item_BuyLimitNumBK:Show()
			RichFlip_MBuy_Item_BuyLimitNum:SetText(g_RichFlip_MBuy_CanGetItemCount)
			RichFlip_MBuy_Item_BuyLimit:Show()
		else
			RichFlip_MBuy_Item_BuyLimitNumBK:Hide()
			RichFlip_MBuy_Item_BuyLimit:Hide()
		end
		RichFlip_MBuy_Item_BuyLimitNum:SetText(g_RichFlip_MBuy_CanGetItemCount)
	end

	RichFlip_MBuy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	RichFlip_MBuy_InputNum:SetText(1)					--默认输入为1
	
	local count = tonumber(RichFlip_MBuy_InputNum:GetText())
	if count ~= nil and count >= 0 then
		RichFlip_MBuy_PriceNum:SetText("#L"..ScriptGlobal_Format("#{FPLS_240715_105}",nNeedDaibi*count))
	end
	RichFlip_MBuy_CashNum:SetText("#L"..g_RichFlip_MBuy_daibi)   
	-- RichFlip_MBuy_InputNum:SetSelected( 0, -1 )
end

function RichFlip_MBuy_OK_Clicked()
	local count = tonumber(RichFlip_MBuy_InputNum:GetText())
	-- PushDebugMessage("count:"..RichFlip_MBuy_InputNum:GetText())
	if count == nil then
		PushDebugMessage("#{FPLS_240715_108}")
		return
	end
	if count <= 0 then
		PushDebugMessage("#{FPLS_240715_108}")
		return
	end 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyItem" )
		Set_XSCRIPT_ScriptID( 999441 )
    	Set_XSCRIPT_Parameter(0,tonumber(g_RichFlip_MBuy_TableId))
		Set_XSCRIPT_Parameter(1,tonumber(count))
    	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()		
end

function RichFlip_MBuy_TextChanged()
	local num = tonumber(RichFlip_MBuy_InputNum:GetText())
	-- if(num == nil or num <= 0) then
	-- 	num = 1
	-- 	RichFlip_MBuy_InputNum:SetText(tostring( num ))
	-- end
	if num ~= nil then
		local _,_,_,nMaxnum,nNeedDaibi = DataPool:LuaFnGetLuckyLineShopItemInfo(g_RichFlip_MBuy_TableId)
		local canbuynum = math.floor(g_RichFlip_MBuy_daibi/nNeedDaibi)
		
		if(nMaxnum > 0 ) then
			if canbuynum > g_RichFlip_MBuy_CanGetItemCount then
				canbuynum = g_RichFlip_MBuy_CanGetItemCount
			end
		end
		
		if num > canbuynum then
			num = canbuynum
			RichFlip_MBuy_InputNum:SetText(tostring( num ))
		end

		if num >= 0 then
			RichFlip_MBuy_PriceNum:SetText("#L"..ScriptGlobal_Format("#{FPLS_240715_105}",nNeedDaibi*num))
		end
	else
		RichFlip_MBuy_PriceNum:SetText("#L0")
	end

end

function RichFlip_MBuy_CalMax()
	local _,_,_,nMaxnum,nNeedDaibi = DataPool:LuaFnGetLuckyLineShopItemInfo(g_RichFlip_MBuy_TableId)
	local canbuynum = math.floor(g_RichFlip_MBuy_daibi/nNeedDaibi)
		
	if(nMaxnum > 0 ) then
		if canbuynum > g_RichFlip_MBuy_CanGetItemCount then
			canbuynum = g_RichFlip_MBuy_CanGetItemCount
		end
	end
	RichFlip_MBuy_InputNum:SetText(tostring(canbuynum))
end

function RichFlip_MBuy_On_ResetPos()
	RichFlip_MBuy_Frame:SetProperty("UnifiedPosition", g_RichFlip_MBuy_Frame_UnifiedPosition)

end

function RichFlip_MBuy_OnHidden()
end

function RichFlip_MBuy_Close_Clicked()
	this:Hide()
end

