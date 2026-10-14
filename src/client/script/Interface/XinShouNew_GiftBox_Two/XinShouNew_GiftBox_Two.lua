--配表通用2选礼包

--变量
local g_XinShouNew_GiftBox_Two_Frame_UnifiedPosition = ""
local g_XinShouNew_GiftBox_Two_CurBagPos = -1

--UI
local g_XinShouNew_GiftBox_Two_UI_ActionItem = {}
local g_XinShouNew_GiftBox_Two_UI_ItemName = {}
local g_XinShouNew_GiftBox_Two_UI_DragTitle = ""
local g_XinShouNew_GiftBox_Two_UI_Info = ""
local g_XinShouNew_GiftBox_Two_UI_CostButton = ""


--常量
local g_XinShouNew_GiftBox_Two_MainScript = 998463
local g_XinShouNew_GiftBox_Two_UIC = 99846301
local g_XinShouNew_GiftBox_Two_TotalNum = 2
local g_XinShouNew_GiftBox_Two_MaxItemNum = 5

local g_XinShouNew_GiftBox_Two_ItemId = 38006286

local g_XinShouNew_GiftBox_Two_Price = 6666

local g_XinShouNew_GiftBox_Two_Award = 
{
	[1] = {itemid = 30505817, num = 1},
	[2] = {itemid = 30505908, num = 1},
}

function XinShouNew_GiftBox_Two_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function XinShouNew_GiftBox_Two_OnLoad()

	g_XinShouNew_GiftBox_Two_Frame_UnifiedPosition = XinShouNew_GiftBox_Two_Frame_BK:GetProperty("UnifiedPosition")
	
	g_XinShouNew_GiftBox_Two_UI_DragTitle = XinShouNew_GiftBox_Two_DragTitle		
	g_XinShouNew_GiftBox_Two_UI_Info = XinShouNew_GiftBox_Two_Info
	
	g_XinShouNew_GiftBox_Two_UI_ActionItem[1] = XinShouNew_GiftBox_Two_Item1
	g_XinShouNew_GiftBox_Two_UI_ActionItem[2] = XinShouNew_GiftBox_Two_Item2
	
	g_XinShouNew_GiftBox_Two_UI_ItemName[1] = XinShouNew_GiftBox_Two_Item1_Name
	g_XinShouNew_GiftBox_Two_UI_ItemName[2] = XinShouNew_GiftBox_Two_Item2_Name
	
	g_XinShouNew_GiftBox_Two_UI_CostButton = XinShouNew_GiftBox_Two_LookButton2
	
end										

function XinShouNew_GiftBox_Two_OnEvent(event)
	
	if event == "UI_COMMAND" and (tonumber(arg0) == g_XinShouNew_GiftBox_Two_UIC) then		

		XinShouNew_GiftBox_Two_CleanUp()
		g_XinShouNew_GiftBox_Two_CurBagPos = Get_XParam_INT(0)
		LifeAbility:Lock_Packet_Item(g_XinShouNew_GiftBox_Two_CurBagPos,1)
		this:Show()		
		XinShouNew_GiftBox_Two_Update()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		XinShouNew_GiftBox_Two_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "PACKAGE_ITEM_CHANGED_EX" and tonumber(arg0) == g_XinShouNew_GiftBox_Two_CurBagPos then
		this:Hide()
		return
	end
	
end

function XinShouNew_GiftBox_Two_Update()

	if g_XinShouNew_GiftBox_Two_CurBagPos < 0 then
		return
	end
	
	--当前打开的礼包id
	local item_table_index = PlayerPackage:GetItemTableIndex(g_XinShouNew_GiftBox_Two_CurBagPos)	
	
	if item_table_index ~= g_XinShouNew_GiftBox_Two_ItemId then
		return
	end
	
	for i = 1, g_XinShouNew_GiftBox_Two_TotalNum do
		local itemAction
		itemAction = DataPool:CreateBindActionItemForShow(g_XinShouNew_GiftBox_Two_Award[i].itemid, g_XinShouNew_GiftBox_Two_Award[i].num)

		if itemAction:GetID() ~= 0 then
			g_XinShouNew_GiftBox_Two_UI_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(g_XinShouNew_GiftBox_Two_Award[i].itemid)
		g_XinShouNew_GiftBox_Two_UI_ItemName[i]:SetText("#L"..strName)
	end
	
	g_XinShouNew_GiftBox_Two_UI_CostButton:SetText(ScriptGlobal_Format("#{XSJNH_230209_68}",g_XinShouNew_GiftBox_Two_Price ))
	

end

function XinShouNew_GiftBox_Two_View(index)
	
	if index < 1 or index > g_XinShouNew_GiftBox_Two_TotalNum then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnClientGetGift")
		Set_XSCRIPT_ScriptID(g_XinShouNew_GiftBox_Two_MainScript)
		Set_XSCRIPT_Parameter(0, g_XinShouNew_GiftBox_Two_CurBagPos)
		Set_XSCRIPT_Parameter(1, index)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	this:Hide()

end

function XinShouNew_GiftBox_Two_CleanUp()	
	
	for i = 1, g_XinShouNew_GiftBox_Two_TotalNum do	
		g_XinShouNew_GiftBox_Two_UI_ActionItem[i]:SetActionItem(-1)
		g_XinShouNew_GiftBox_Two_UI_ItemName[i]:SetText("")
	end 
	
	if g_XinShouNew_GiftBox_Two_CurBagPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_XinShouNew_GiftBox_Two_CurBagPos,0)
	end
	
	g_XinShouNew_GiftBox_Two_CurBagPos = -1

end

function XinShouNew_GiftBox_Two_Close()
	XinShouNew_GiftBox_Two_CleanUp()
	this:Hide()
end

function XinShouNew_GiftBox_Two_Frame_On_ResetPos()
	if g_XinShouNew_GiftBox_Two_Frame_UnifiedPosition ~= nil then
		XinShouNew_GiftBox_Two_Frame_BK:SetProperty("UnifiedPosition", g_XinShouNew_GiftBox_Two_Frame_UnifiedPosition)
	end
end