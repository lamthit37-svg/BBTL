local g_XiGuaDraw_Shop_Award_UnifiedPosition

local g_XiGuaDraw_Shop_Award_Page_Item = {}
local g_XiGuaDraw_Shop_Award_Page_Text = {}

local g_XiGuaDraw_Shop_Award_ItemId = {
[1] = 38007160, [2] = 38007187, [3] = 38007191,
}

function XiGuaDraw_Shop_Award_PreLoad()
	this:RegisterEvent("XIGUADRAW_SHOP_REWARD_PREVIEW",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function XiGuaDraw_Shop_Award_OnLoad()	
	g_XiGuaDraw_Shop_Award_UnifiedPosition = XiGuaDraw_Shop_Award_Frame:GetProperty("UnifiedPosition")

	g_XiGuaDraw_Shop_Award_Page_Item[1] = XiGuaDraw_Shop_Award_Page_Lace1Item
	g_XiGuaDraw_Shop_Award_Page_Item[2] = XiGuaDraw_Shop_Award_Page_Lace2Item
	g_XiGuaDraw_Shop_Award_Page_Item[3] = XiGuaDraw_Shop_Award_Page_Lace3Item
	
	
	g_XiGuaDraw_Shop_Award_Page_Text[1] = XiGuaDraw_Shop_Award_Page_Lace1Item_Tip
	g_XiGuaDraw_Shop_Award_Page_Text[2] = XiGuaDraw_Shop_Award_Page_Lace2Item_Tip
	g_XiGuaDraw_Shop_Award_Page_Text[3] = XiGuaDraw_Shop_Award_Page_Lace3Item_Tip

	
end

function XiGuaDraw_Shop_Award_OnEvent(event)
	if ( event == "XIGUADRAW_SHOP_REWARD_PREVIEW" ) then
		XiGuaDraw_Shop_Award_OnShow()
	elseif (event == "ADJEST_UI_POS" ) then
		XiGuaDraw_Shop_Award_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGuaDraw_Shop_Award_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function XiGuaDraw_Shop_Award_On_ResetPos()
	XiGuaDraw_Shop_Award_Frame:SetProperty("UnifiedPosition", g_XiGuaDraw_Shop_Award_UnifiedPosition);
end

function XiGuaDraw_Shop_Award_OnShow()

	for i = 1, table.getn(g_XiGuaDraw_Shop_Award_ItemId) do
		local theAction = DataPool:CreateBindActionItemForShow( g_XiGuaDraw_Shop_Award_ItemId[i], 1 )
		g_XiGuaDraw_Shop_Award_Page_Item[i]:SetActionItem(theAction:GetID())
		g_XiGuaDraw_Shop_Award_Page_Text[i]:SetText("#L"..theAction:GetName())
	end

	this:Show()
end

function XiGuaDraw_Shop_Award_Close()
	this:Hide()
end

