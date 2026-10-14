local g_XiGuaDraw_ShopPreview_UnifiedPosition

local g_XiGuaDraw_ShopPreview_Page_Item = {}
local g_XiGuaDraw_ShopPreview_Page_Text = {}

local g_XiGuaDraw_ShopPreview_ItemId = {
[1] = 39910135, [2] = 39910132,
}

local g_XiGuaDraw_ShopPreview_pet = {
[1] = 35858, [2] = 35718,
}

function XiGuaDraw_ShopPreview_PreLoad()
	this:RegisterEvent("XIGUADRAW_SHOP_PET_PREVIEW",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function XiGuaDraw_ShopPreview_OnLoad()	
	g_XiGuaDraw_ShopPreview_UnifiedPosition = XiGuaDraw_ShopPreview_Frame_BK:GetProperty("UnifiedPosition")

	g_XiGuaDraw_ShopPreview_Page_Item[1] = XiGuaDraw_ShopPreview_Item1
	g_XiGuaDraw_ShopPreview_Page_Item[2] = XiGuaDraw_ShopPreview_Item2
	
	
	g_XiGuaDraw_ShopPreview_Page_Text[1] = XiGuaDraw_ShopPreview_Item1_Name
	g_XiGuaDraw_ShopPreview_Page_Text[2] = XiGuaDraw_ShopPreview_Item2_Name

	
end

function XiGuaDraw_ShopPreview_OnEvent(event)
	if ( event == "XIGUADRAW_SHOP_PET_PREVIEW" ) then
		XiGuaDraw_ShopPreview_OnShow()
	elseif (event == "ADJEST_UI_POS" ) then
		XiGuaDraw_ShopPreview_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGuaDraw_ShopPreview_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function XiGuaDraw_ShopPreview_On_ResetPos()
	XiGuaDraw_ShopPreview_Frame_BK:SetProperty("UnifiedPosition", g_XiGuaDraw_ShopPreview_UnifiedPosition);
end

function XiGuaDraw_ShopPreview_OnShow()

	for i = 1, table.getn(g_XiGuaDraw_ShopPreview_ItemId) do
		local theAction = DataPool:CreateBindActionItemForShow( g_XiGuaDraw_ShopPreview_ItemId[i], 1 )
		g_XiGuaDraw_ShopPreview_Page_Item[i]:SetActionItem(theAction:GetID())
		g_XiGuaDraw_ShopPreview_Page_Text[i]:SetText("#L"..theAction:GetName())
	end

	this:Show()
end

function XiGuaDraw_ShopPreview_View(index)
	Pet:AnniversaryOpenPetJian( g_XiGuaDraw_ShopPreview_pet[index] );
end

function XiGuaDraw_ShopPreview_Close()
	this:Hide()
end

