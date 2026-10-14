
--周年庆 国韵袖场购买 二选一界面
local g_Anniversary_PickOne_Frame_UnifiedPosition


local g_Anniversary_PickOne_Index = 1
local g_Anniversary_PickOne_DataTable = {
	[1] = { 10125217, 38004119 },
	[2] = { 10126073, 38004120 },
}

local g_Anniversary_PickOne_YuanbaoCostTable = {
	[1] = { 25000, 47500 },
	[2] = { 20000, 38000 },
	-- [1] = 999,
	-- [2] = 1888,
}

function Anniversary_PickOne_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_ANNIVERSARY_BEFORE",false)	
end

function Anniversary_PickOne_OnLoad()
	g_Anniversary_PickOne_Frame_UnifiedPosition = Anniversary_PickOne:GetProperty("UnifiedPosition")

end

function Anniversary_PickOne_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 20200330) then
		if this:IsVisible() then
			Anniversary_PickOne_Close()
			return
		end
		g_Anniversary_PickOne_Index = Get_XParam_INT(0)
		-- PushEvent("OPEN_ANNIVERSARY_SHOW") 
		--PushEvent("UI_COMMAND", 2020032604)
		this:Show()
		Anniversary_PickOne_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_PickOne_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		Anniversary_PickOne_Close()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_PickOne_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Anniversary_PickOne_Close()
	end
	
end

function Anniversary_PickOne_Open()

	local theAction1 = DataPool:CreateActionItemForShow(g_Anniversary_PickOne_DataTable[g_Anniversary_PickOne_Index][1], 1) 
	if (theAction1:GetID() ~= 0) then
		Anniversary_PickOne_Yuanbao_Icon:SetActionItem(theAction1:GetID())  
	end 
	local theAction2 = DataPool:CreateActionItemForShow(g_Anniversary_PickOne_DataTable[g_Anniversary_PickOne_Index][2], 1) 
	if (theAction2:GetID() ~= 0) then
		Anniversary_PickOne_Yuanbao2_Icon:SetActionItem(theAction2:GetID())  
	end 
	local shizhuang_ItemName = DataPool:Lua_GetItemNameByIndex(g_Anniversary_PickOne_DataTable[g_Anniversary_PickOne_Index][1])
	local lihe_ItemName = DataPool:Lua_GetItemNameByIndex(g_Anniversary_PickOne_DataTable[g_Anniversary_PickOne_Index][2])

	Anniversary_PickOne_DragTitle:SetText(ScriptGlobal_Format("#{XGSZ_200317_09}",shizhuang_ItemName))
	Anniversary_PickOne_Refresh1_Text:SetText(ScriptGlobal_Format("#{XGSZ_200317_13}",shizhuang_ItemName))
	
	Anniversary_PickOne_Jinfen_text:SetText(ScriptGlobal_Format("#{XGSZ_200317_36}",shizhuang_ItemName))
	Anniversary_PickOne_Giftbox_text:SetText(ScriptGlobal_Format("#{XGSZ_200317_36}",lihe_ItemName))
	Anniversary_PickOne_Yuanbao_text:SetText(ScriptGlobal_Format("#{XGSZ_200317_10}",tostring(g_Anniversary_PickOne_YuanbaoCostTable[g_Anniversary_PickOne_Index][1]) ))
	Anniversary_PickOne_Yuanbao2_text:SetText(ScriptGlobal_Format("#{XGSZ_200317_10}",tostring(g_Anniversary_PickOne_YuanbaoCostTable[g_Anniversary_PickOne_Index][2]) ))

end

function Anniversary_PickOne_On_ResetPos()
	Anniversary_PickOne:SetProperty("UnifiedPosition", g_Anniversary_PickOne_Frame_UnifiedPosition)

end

function Anniversary_PickOne_Close()
	g_Anniversary_PickOne_Index =1
	this:Hide()
end

--点击购买时装
function Anniversary_PickOne_FashionBuy()
	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("BuyFashion")
    Set_XSCRIPT_ScriptID(892595)
    Set_XSCRIPT_Parameter(0, g_Anniversary_PickOne_Index)
	Set_XSCRIPT_Parameter(1, 1)
	Set_XSCRIPT_Parameter(2, g_Anniversary_PickOne_DataTable[g_Anniversary_PickOne_Index][1])
	Set_XSCRIPT_Parameter(3, 0)
    Set_XSCRIPT_ParamCount(4)
    Send_XSCRIPT()
end

--点击购买礼盒
function Anniversary_PickOne_FashionLiHeBuy()
	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("BuyFashion")
    Set_XSCRIPT_ScriptID(892595)
    Set_XSCRIPT_Parameter(0, g_Anniversary_PickOne_Index)
	Set_XSCRIPT_Parameter(1, 2)
	Set_XSCRIPT_Parameter(2, g_Anniversary_PickOne_DataTable[g_Anniversary_PickOne_Index][2])
	Set_XSCRIPT_Parameter(3, 0)
    Set_XSCRIPT_ParamCount(4)
    Send_XSCRIPT()
end