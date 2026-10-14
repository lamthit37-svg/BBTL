--RichFlip_MSplit

local g_RichFlip_MSplit_Frame_UnifiedPosition
local g_RichFlip_MSplit_TableId = -1
local g_RichFlip_MSplit_CanGetItemCount = 0
local g_RichFlip_MSplit_page = 1

function RichFlip_MSplit_PreLoad()
	this:RegisterEvent("LUCKYLINE_OPEN_MULIT_RESOLVE",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function RichFlip_MSplit_OnLoad()
	g_RichFlip_MSplit_Frame_UnifiedPosition = RichFlip_MSplit_Frame:GetProperty("UnifiedPosition")

end

function RichFlip_MSplit_OnEvent(event)
	if event == "LUCKYLINE_OPEN_MULIT_RESOLVE" then

		g_RichFlip_MSplit_TableId = tonumber(arg0)
		g_RichFlip_MSplit_CanGetItemCount = tonumber(arg1)
		g_RichFlip_MSplit_page = tonumber(arg2)
		if g_RichFlip_MSplit_TableId ~= nil and g_RichFlip_MSplit_CanGetItemCount ~= nil then
			this:Show()
			RichFlip_MSplit_Open()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		RichFlip_MSplit_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		RichFlip_MSplit_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		RichFlip_MSplit_Close_Clicked()
	end
	
end

function RichFlip_MSplit_Open()
	local nShowItemId,nItemNum,nIsBind,nFenjie = DataPool:LuaFnGetLuckyLineChoujiangItemInfo(g_RichFlip_MSplit_TableId)
	if nShowItemId ~= nil and nShowItemId > 0 then
		local theAction = nil
		if nIsBind == 1 then
			theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
		else
			theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
		end		
		if theAction ~= nil then
			RichFlip_MSplit_Item:SetActionItem(theAction:GetID())
		end
		RichFlip_MSplit_ItemInfo_Name:SetText("#L"..theAction:GetName())
		RichFlip_MSplit_Item_BuyLimitNum:SetText(g_RichFlip_MSplit_CanGetItemCount)
		RichFlip_MSplit_ItemInfo_Price:SetText(ScriptGlobal_Format("#{FPLS_240715_87}", tostring(nFenjie)))
	end

	RichFlip_MSplit_InputNum:SetProperty("DefaultEditBox", "True")	--设置输入框为默认输入框
	RichFlip_MSplit_InputNum:SetText(tostring(g_RichFlip_MSplit_CanGetItemCount))					   
	-- RichFlip_MSplit_InputNum:SetSelected( 0, -1 )
end

function RichFlip_MSplit_OK_Clicked()
	local count = tonumber(RichFlip_MSplit_InputNum:GetText())
	if count == nil then
		PushDebugMessage("#{FPLS_240715_91}")
		return
	end
	if count <= 0 or count>tonumber(g_RichFlip_MSplit_CanGetItemCount) then
		PushDebugMessage("#{FPLS_240715_91}")
		return
	end 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FenjieStorageItem" )
		Set_XSCRIPT_ScriptID( 999441 )
    	Set_XSCRIPT_Parameter(0,g_RichFlip_MSplit_TableId)
		Set_XSCRIPT_Parameter(1,count)
		Set_XSCRIPT_Parameter(2,g_RichFlip_MSplit_page)
    	Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

function RichFlip_MSplit_TextChanged()
	local num = tonumber(RichFlip_MSplit_InputNum:GetText())
	-- if(num == nil or num <= 0) then
	-- 	num = 1
	-- 	RichFlip_MSplit_InputNum:SetText(tostring( num ))
	-- end
	if num ~= nil then
		if(num > g_RichFlip_MSplit_CanGetItemCount) then
			num = g_RichFlip_MSplit_CanGetItemCount
			RichFlip_MSplit_InputNum:SetText(tostring( num ))
		end

		local nShowItemId,nItemNum,nIsBind,nFenjie = DataPool:LuaFnGetLuckyLineChoujiangItemInfo(g_RichFlip_MSplit_TableId)

		if nShowItemId ~= nil and nShowItemId > 0 then
			RichFlip_MSplit_PriceNum:SetText("#L"..ScriptGlobal_Format("#{FPLS_240715_89}", tostring(nFenjie*num)))
			-- PushDebugMessage("suipian:"..tostring(iteminfo.nSuiPianNum*num))
		end
	else
		RichFlip_MSplit_PriceNum:SetText("#L0")
	end
end

function RichFlip_MSplit_CalMax()
	RichFlip_MSplit_InputNum:SetText(g_RichFlip_MSplit_CanGetItemCount)
end

function RichFlip_MSplit_On_ResetPos()
	RichFlip_MSplit_Frame:SetProperty("UnifiedPosition", g_RichFlip_MSplit_Frame_UnifiedPosition)

end

function RichFlip_MSplit_OnHidden()
end

function RichFlip_MSplit_Close_Clicked()
	this:Hide()
end


