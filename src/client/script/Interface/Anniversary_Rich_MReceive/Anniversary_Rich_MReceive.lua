
--大富翁活动物品箱批量领取某个道具的界面
local g_Anniversary_Rich_MReceive_Frame_UnifiedPosition
local g_Anniversary_Rich_MReceive_TableId = -1
local g_Anniversary_Rich_MReceive_CanGetItemCount = 0
function Anniversary_Rich_MReceive_PreLoad()
	this:RegisterEvent("DAFUWENG_OPEN_GOTITEM",true)
	this:RegisterEvent("DAFUWENG_CLOSE_POPUI",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
end

function Anniversary_Rich_MReceive_OnLoad()
	g_Anniversary_Rich_MReceive_Frame_UnifiedPosition = Anniversary_Rich_MReceive_Frame:GetProperty("UnifiedPosition")

end

function Anniversary_Rich_MReceive_OnEvent(event)
	if event == "DAFUWENG_OPEN_GOTITEM" then
		-- if this:IsVisible() then
		-- 	Anniversary_Rich_MReceive_Close_Clicked()
		-- 	return
		-- end
		if Player:GetData("IsOriginalJD") == 1 and IsInTServer() == 1 then
			PushDebugMessage("无法在当前场景进行该操作。")
			return 
		end
		g_Anniversary_Rich_MReceive_TableId = arg0
		g_Anniversary_Rich_MReceive_CanGetItemCount = arg1
		if g_Anniversary_Rich_MReceive_TableId ~= nil and g_Anniversary_Rich_MReceive_CanGetItemCount ~=nil then
			this:Show()
			Anniversary_Rich_MReceive_Open()
		end
	elseif event == "DAFUWENG_CLOSE_POPUI" then
		Anniversary_Rich_MReceive_Close_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
			Anniversary_Rich_MReceive_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_Rich_MReceive_Close_Clicked()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_Rich_MReceive_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_Rich_MReceive_Close_Clicked()
	end
	
end


function Anniversary_Rich_MReceive_GetTable(tableId)
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

function Anniversary_Rich_MReceive_Open()
	-- PushDebugMessage("g_Anniversary_Rich_MReceive_TableId:"..g_Anniversary_Rich_MReceive_TableId)
	-- PushDebugMessage("g_Anniversary_Rich_MReceive_CanGetItemCount:"..g_Anniversary_Rich_MReceive_CanGetItemCount)
	-- PushDebugMessage("g_Anniversary_Rich_MReceive_TableId:"..tostring(g_Anniversary_Rich_MReceive_TableId))


	local iteminfo = Anniversary_Rich_MReceive_GetTable(g_Anniversary_Rich_MReceive_TableId)

	if iteminfo then
		local theAction = DataPool:CreateActionItemForShow(iteminfo.nItemID, iteminfo.nItemCount)
		if theAction:GetID() ~= 0 then
			Anniversary_Rich_MReceive_Item:SetActionItem(theAction:GetID())
		end
		Anniversary_Rich_MReceive_ItemInfo_Text:SetText("#L"..DataPool:Lua_GetItemNameByIndex(iteminfo.nItemID))
		Anniversary_Rich_MReceive_Item_BuyLimitNum:SetText(g_Anniversary_Rich_MReceive_CanGetItemCount)
	end

	Anniversary_Rich_MReceive_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	Anniversary_Rich_MReceive_InputNum:SetText(g_Anniversary_Rich_MReceive_CanGetItemCount)					--默认输入为1   
	-- Anniversary_Rich_MReceive_InputNum:SetSelected( 0, -1 )
end

function Anniversary_Rich_MReceive_OK_Clicked()
	local count = tonumber(Anniversary_Rich_MReceive_InputNum:GetText())
	-- PushDebugMessage("count:"..Anniversary_Rich_MReceive_InputNum:GetText())
	if count == nil then
		PushDebugMessage("#{ZNLSG_230215_114}")
		return
	end
	if count <= 0 or count>tonumber(g_Anniversary_Rich_MReceive_CanGetItemCount) then
		PushDebugMessage("#{ZNLSG_230215_114}")
		return
	end 
	
	DaFuWeng:AskToReceiveItem(tonumber(g_Anniversary_Rich_MReceive_TableId),count)
end

function Anniversary_Rich_MReceive_TextChanged()
	local num = tonumber(Anniversary_Rich_MReceive_InputNum:GetText())
	-- if(num == nil or num <= 0) then
	-- 	num = 1
	-- 	Anniversary_Rich_MReceive_InputNum:SetText(tostring( num ))
	-- end
	if num ~= nil then
		if(num > tonumber(g_Anniversary_Rich_MReceive_CanGetItemCount)) then
			num = tonumber(g_Anniversary_Rich_MReceive_CanGetItemCount)
			Anniversary_Rich_MReceive_InputNum:SetText(tostring( num ))
		end
	end

end

function Anniversary_Rich_MReceive_CalMax()
	Anniversary_Rich_MReceive_InputNum:SetText(g_Anniversary_Rich_MReceive_CanGetItemCount)
end

function Anniversary_Rich_MReceive_On_ResetPos()
	Anniversary_Rich_MReceive_Frame:SetProperty("UnifiedPosition", g_Anniversary_Rich_MReceive_Frame_UnifiedPosition)

end

function Anniversary_Rich_MReceive_OnHidden()
end

function Anniversary_Rich_MReceive_Close_Clicked()
	this:Hide()
end

