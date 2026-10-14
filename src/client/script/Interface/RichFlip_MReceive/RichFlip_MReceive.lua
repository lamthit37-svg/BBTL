--RichFlip_MReceive

local g_RichFlip_MReceive_Frame_UnifiedPosition
local g_RichFlip_MReceive_TableId = -1
local g_RichFlip_MReceive_CanGetItemCount = 0
local g_RichFlip_MReceive_page = 1

function RichFlip_MReceive_PreLoad()
	this:RegisterEvent("LUCKYLINE_OPEN_MULIT_GET",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function RichFlip_MReceive_OnLoad()
	g_RichFlip_MReceive_Frame_UnifiedPosition = RichFlip_MReceive_Frame:GetProperty("UnifiedPosition")

end

function RichFlip_MReceive_OnEvent(event)
	if event == "LUCKYLINE_OPEN_MULIT_GET" then
		g_RichFlip_MReceive_TableId = arg0
		g_RichFlip_MReceive_CanGetItemCount = arg1
		g_RichFlip_MReceive_page = tonumber(arg2)
		if g_RichFlip_MReceive_TableId ~= nil and g_RichFlip_MReceive_CanGetItemCount ~=nil then
			this:Show()
			RichFlip_MReceive_Open()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
			RichFlip_MReceive_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		RichFlip_MReceive_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		RichFlip_MReceive_Close_Clicked()
	end
	
end

function RichFlip_MReceive_Open()
	local nShowItemId,nItemNum,nIsBind,nFenjie = DataPool:LuaFnGetLuckyLineChoujiangItemInfo(tonumber(g_RichFlip_MReceive_TableId))
	if nShowItemId ~= nil and nShowItemId > 0 then
		local theAction = nil
		if nIsBind == 1 then
			theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
		else
			theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
		end		
		if theAction ~= nil then
			RichFlip_MReceive_Item:SetActionItem(theAction:GetID())
		end
		RichFlip_MReceive_ItemInfo_Name:SetText("#L"..theAction:GetName())
		RichFlip_MReceive_Item_BuyLimitNum:SetText(g_RichFlip_MReceive_CanGetItemCount)
	end

	RichFlip_MReceive_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	RichFlip_MReceive_InputNum:SetText(g_RichFlip_MReceive_CanGetItemCount)					--默认输入为1   
	-- RichFlip_MReceive_InputNum:SetSelected( 0, -1 )
end

function RichFlip_MReceive_OK_Clicked()
	local count = tonumber(RichFlip_MReceive_InputNum:GetText())
	-- PushDebugMessage("count:"..RichFlip_MReceive_InputNum:GetText())
	if count == nil then
		PushDebugMessage("#{FPLS_240715_75}")
		return
	end
	if count <= 0 or count>tonumber(g_RichFlip_MReceive_CanGetItemCount) then
		PushDebugMessage("#{FPLS_240715_75}")
		return
	end 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetStorageItem" )
		Set_XSCRIPT_ScriptID( 999441 )
    	Set_XSCRIPT_Parameter(0,tonumber(g_RichFlip_MReceive_TableId))
		Set_XSCRIPT_Parameter(1,tonumber(count))
		Set_XSCRIPT_Parameter(2,g_RichFlip_MReceive_page)
    	Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()		
end

function RichFlip_MReceive_TextChanged()
	local num = tonumber(RichFlip_MReceive_InputNum:GetText())
	-- if(num == nil or num <= 0) then
	-- 	num = 1
	-- 	RichFlip_MReceive_InputNum:SetText(tostring( num ))
	-- end
	if num ~= nil then
		if(num > tonumber(g_RichFlip_MReceive_CanGetItemCount)) then
			num = tonumber(g_RichFlip_MReceive_CanGetItemCount)
			RichFlip_MReceive_InputNum:SetText(tostring( num ))
		end
	end

end

function RichFlip_MReceive_CalMax()
	RichFlip_MReceive_InputNum:SetText(g_RichFlip_MReceive_CanGetItemCount)
end

function RichFlip_MReceive_On_ResetPos()
	RichFlip_MReceive_Frame:SetProperty("UnifiedPosition", g_RichFlip_MReceive_Frame_UnifiedPosition)

end

function RichFlip_MReceive_OnHidden()
end

function RichFlip_MReceive_Close_Clicked()
	this:Hide()
end

