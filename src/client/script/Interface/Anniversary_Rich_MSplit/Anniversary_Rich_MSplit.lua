
--大富翁活动购买骰子
local g_Anniversary_Rich_MSplit_Frame_UnifiedPosition
local g_Anniversary_Rich_MSplit_TableId = -1
local g_Anniversary_Rich_MSplit_CanGetItemCount = 0

function Anniversary_Rich_MSplit_PreLoad()
	this:RegisterEvent("DAFUWENG_OPEN_DISASSEMBLE",true)
	this:RegisterEvent("DAFUWENG_CLOSE_POPUI",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
end

function Anniversary_Rich_MSplit_OnLoad()
	g_Anniversary_Rich_MSplit_Frame_UnifiedPosition = Anniversary_Rich_MSplit_Frame:GetProperty("UnifiedPosition")

end

function Anniversary_Rich_MSplit_OnEvent(event)
	if event == "DAFUWENG_OPEN_DISASSEMBLE" then
		-- if this:IsVisible() then
		-- 	Anniversary_Rich_MSplit_Close_Clicked()
		-- 	return
		-- end
		g_Anniversary_Rich_MSplit_TableId = tonumber(arg0)
		g_Anniversary_Rich_MSplit_CanGetItemCount = tonumber(arg1)
		if g_Anniversary_Rich_MSplit_TableId ~= nil and g_Anniversary_Rich_MSplit_CanGetItemCount ~= nil then
			this:Show()
			Anniversary_Rich_MSplit_Open()
		end
	elseif event == "DAFUWENG_CLOSE_POPUI" then
		Anniversary_Rich_MSplit_Close_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_Rich_MSplit_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_Rich_MSplit_Close_Clicked()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Rich_MSplit_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Rich_MSplit_Close_Clicked()
	end
	
end


function Anniversary_Rich_MSplit_GetTable(tableId)
	local iteminfo = nil
	if Player:GetData("IsOriginalJD") == 1 then
		iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANCHANGESUIPIAN_ORI",tableId+1)
	else
		local kjtype   = KaJi:LuaFnGetKaJiType(127)

		if kjtype == 1 then
			iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANCHANGESUIPIAN_KAJI_1",tableId+1)
		else
			iteminfo = DataPool:TBSearch_Index_EQU("DBC_RICHMANCHANGESUIPIAN",tableId+1)
		end
	end

	return iteminfo
end


function Anniversary_Rich_MSplit_Open()


	local iteminfo = Anniversary_Rich_MSplit_GetTable(g_Anniversary_Rich_MSplit_TableId)


	if iteminfo then
		local theAction = DataPool:CreateActionItemForShow(iteminfo.nItemID, iteminfo.nItemCount)
		if theAction:GetID() ~= 0 then
			Anniversary_Rich_MSplit_Item:SetActionItem(theAction:GetID())
		end
		Anniversary_Rich_MSplit_ItemInfo_Text:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
		Anniversary_Rich_MSplit_Item_BuyLimitNum:SetText(tostring(g_Anniversary_Rich_MSplit_CanGetItemCount))
		Anniversary_Rich_MSplit_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{ZNLSG_230215_130}", tostring(iteminfo.nSuiPianNum)))
		
	end
	Anniversary_Rich_MSplit_InputNum:SetProperty("DefaultEditBox", "True")	--设置输入框为默认输入框
	Anniversary_Rich_MSplit_InputNum:SetText(tostring(g_Anniversary_Rich_MSplit_CanGetItemCount))					   
	-- Anniversary_Rich_MSplit_InputNum:SetSelected( 0, -1 )
end

function Anniversary_Rich_MSplit_OK_Clicked()
	local count = tonumber(Anniversary_Rich_MSplit_InputNum:GetText())
	if count == nil then
		PushDebugMessage("#{ZNLSG_230215_135}")
		return
	end
	if count <= 0 or count>tonumber(g_Anniversary_Rich_MSplit_CanGetItemCount) then
		PushDebugMessage("#{ZNLSG_230215_135}")
		return
	end 
	-- PushDebugMessage("g_Anniversary_Rich_MSplit_TableId:"..tostring(g_Anniversary_Rich_MSplit_TableId))
	DaFuWeng:AskToDisassembleItem(tonumber(g_Anniversary_Rich_MSplit_TableId),count)
end

function Anniversary_Rich_MSplit_TextChanged()
	local num = tonumber(Anniversary_Rich_MSplit_InputNum:GetText())
	-- if(num == nil or num <= 0) then
	-- 	num = 1
	-- 	Anniversary_Rich_MSplit_InputNum:SetText(tostring( num ))
	-- end
	if num ~= nil then
		if(num > g_Anniversary_Rich_MSplit_CanGetItemCount) then
			num = g_Anniversary_Rich_MSplit_CanGetItemCount
			Anniversary_Rich_MSplit_InputNum:SetText(tostring( num ))
		end


		local iteminfo = Anniversary_Rich_MSplit_GetTable(g_Anniversary_Rich_MSplit_TableId)
	
		if iteminfo then
			Anniversary_Rich_MSplit_PriceNum:SetText(ScriptGlobal_Format("#{ZNLSG_230215_346}", tostring(iteminfo.nSuiPianNum*num)))
			-- PushDebugMessage("suipian:"..tostring(iteminfo.nSuiPianNum*num))
		end
	else
		Anniversary_Rich_MSplit_PriceNum:SetText("#L0")
	end
end

function Anniversary_Rich_MSplit_CalMax()
	Anniversary_Rich_MSplit_InputNum:SetText(g_Anniversary_Rich_MSplit_CanGetItemCount)
end

function Anniversary_Rich_MSplit_On_ResetPos()
	Anniversary_Rich_MSplit_Frame:SetProperty("UnifiedPosition", g_Anniversary_Rich_MSplit_Frame_UnifiedPosition)

end

function Anniversary_Rich_MSplit_OnHidden()
end

function Anniversary_Rich_MSplit_Close_Clicked()
	this:Hide()
end


