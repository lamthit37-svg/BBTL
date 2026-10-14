--紫薇星落提交数量确认界面

local g_ThreeCity_ZiWei_Change_Frame_UnifiedPosition
local g_ZWlevel = 1
local g_isHaveTeam = 0
local g_MaxNum = 1	--求出的能放入的最大数
local g_TargetId = -1
local g_NpcType = 1
local g_ThreeCity_ZiWei_Change_ZWXLItem =
{
	[1] = 20700080,  --初级的紫微星落id
	[2] = 20700079,  --中级的紫微星落id
	[3] = 20700078,  --高级的紫微星落id
}

function ThreeCity_ZiWei_Change_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
end

function ThreeCity_ZiWei_Change_OnLoad()
	g_ThreeCity_ZiWei_Change_Frame_UnifiedPosition = ThreeCity_ZiWei_Change_Frame:GetProperty("UnifiedPosition")

end

function ThreeCity_ZiWei_Change_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2022080501) then
		g_TargetId = Get_XParam_INT( 0 )
		g_ZWlevel = Get_XParam_INT( 1 )
		g_isHaveTeam = Get_XParam_INT( 2 )
		g_NpcType = Get_XParam_INT( 3 )
		ThreeCity_ZiWei_Change_OnShown()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ThreeCity_ZiWei_Change_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ThreeCity_ZiWei_Change_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ThreeCity_ZiWei_Change_Close()
	elseif(event == "PACKAGE_ITEM_CHANGED_EX") then	
		local itemTableIndex = g_ThreeCity_ZiWei_Change_ZWXLItem[g_ZWlevel]
		g_MaxNum = PlayerPackage:CountAvailableItemByIDTable( itemTableIndex )

		if g_MaxNum < 1 then
			g_MaxNum = 1
		end
		
		if g_MaxNum > 999 then
			g_MaxNum = 999
		end
		local strTemp3 = ScriptGlobal_Format("#{ZJSJ_220708_26}", tostring(g_MaxNum))	
		ThreeCity_ZiWei_Change_ItemInfo_Max:SetText(strTemp3)
	end
	
end


function ThreeCity_ZiWei_Change_OnMax()
	ThreeCity_ZiWei_Change_InputNum:SetText(g_MaxNum)
end

function ThreeCity_ZiWei_Change_TextChanged()
	local nString = ThreeCity_ZiWei_Change_InputNum:GetText()
	if nString == nil or nString == "" then
		return
	end
	local nChangNum = tonumber(nString)
	if nChangNum == nil then
		return
	end

	if nChangNum > g_MaxNum then
		ThreeCity_ZiWei_Change_InputNum:SetText(tostring(g_MaxNum))
		
	elseif nChangNum < 1 then
		ThreeCity_ZiWei_Change_InputNum:SetText(tostring("1"))
	end

end

function ThreeCity_ZiWei_Change_Confirm()
	local nString = ThreeCity_ZiWei_Change_InputNum:GetText()
	if nString == nil or nString == "" then
		PushDebugMessage("#{ZJSJ_220708_29}")
		return
	end
	local nNum = tonumber(nString)
	if nNum == nil then
		-- 请输入使用数量
		PushDebugMessage("#{ZJSJ_220708_29}")
		return
	end
	if nNum <= 0 then
		PushDebugMessage("#{ZJSJ_220708_29}")
		return
	end
	-- PushDebugMessage("g_isHaveTeam:"..tostring(g_isHaveTeam))
	-- PushDebugMessage("nNum:"..tostring(nNum))
	if g_NpcType == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(998215)
			Set_XSCRIPT_Function_Name("DoSubmit")
			Set_XSCRIPT_Parameter(0, g_TargetId)
			Set_XSCRIPT_Parameter(1, g_ZWlevel)
			Set_XSCRIPT_Parameter(2, g_isHaveTeam)
			Set_XSCRIPT_Parameter(3, nNum)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif g_NpcType == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(998254)
			Set_XSCRIPT_Function_Name("DoSubmit")
			Set_XSCRIPT_Parameter(0, g_TargetId)
			Set_XSCRIPT_Parameter(1, g_ZWlevel)
			Set_XSCRIPT_Parameter(2, g_isHaveTeam)
			Set_XSCRIPT_Parameter(3, nNum)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end
	  
	ThreeCity_ZiWei_Change_Close()
end


function ThreeCity_ZiWei_Change_OnShown()
	local itemTableIndex = g_ThreeCity_ZiWei_Change_ZWXLItem[g_ZWlevel]
	local theAction = DataPool:CreateBindActionItemForShow(itemTableIndex, 1)
	if theAction:GetID() ~= 0 then
		ThreeCity_ZiWei_Change_Item:SetActionItem(theAction:GetID())
		ThreeCity_ZiWei_Change_Item:Show()
	end
	local item_name = DataPool:Lua_GetItemNameByIndex(itemTableIndex)
	local strTemp = ScriptGlobal_Format("#{ZJSJ_220708_25}", tostring(item_name))	
	ThreeCity_ZiWei_Change_ItemInfo_Text:SetText(strTemp)
	local strTemp2 = ScriptGlobal_Format("#{ZJSJ_220708_24}", tostring(item_name))	
	ThreeCity_ZiWei_Change_PageHeader:SetText(strTemp2)

	
	g_MaxNum = PlayerPackage:CountAvailableItemByIDTable( itemTableIndex )

	if g_MaxNum < 1 then
		g_MaxNum = 1
	end
	
	if g_MaxNum > 999 then
		g_MaxNum = 999
	end
	local strTemp3 = ScriptGlobal_Format("#{ZJSJ_220708_26}", tostring(g_MaxNum))	
	ThreeCity_ZiWei_Change_ItemInfo_Max:SetText(strTemp3)
	ThreeCity_ZiWei_Change_InputNum:SetText(tostring(g_MaxNum))
	this:Show()
	
end

function ThreeCity_ZiWei_Change_On_ResetPos()
	ThreeCity_ZiWei_Change_Frame:SetProperty("UnifiedPosition", g_ThreeCity_ZiWei_Change_Frame_UnifiedPosition)

end

function ThreeCity_ZiWei_Change_Close()
	this:Hide()
end

function ThreeCity_ZiWei_Change_OnHiden()
	g_MaxNum = 1
	ThreeCity_ZiWei_Change_InputNum:SetText(1)
end