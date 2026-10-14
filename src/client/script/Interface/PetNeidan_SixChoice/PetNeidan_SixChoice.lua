local g_PetNeidan_SixChoice_UnifiedPosition
local g_PetNeidan_SixChoice_BagPos
local g_PetNeidan_SixChoice_LiheType
local g_PetNeidan_SixChoice_ItemChoice

local g_PetNeidan_SixChoice_Page_Item = {} --ActionButton
local g_PetNeidan_SixChoice_Page_Text = {}
local g_PetNeidan_SixChoice_Page_Item_Mask = {} --对钩
local g_PetNeidan_SixChoice_Page_Item_Mark = {} --左上已拥有标记

g_PetNeidan_SixChoice_ZhanShiItemId = {
	[1] = {39924370, 39924371, 39924372, 39924373, 39924374, 39924375}, --珍品增益元丹礼盒
	[2] = {39924355, 39924356, 39924357, 39924358, 39924359, 39924360}, --神品增益元丹礼盒
}

function PetNeidan_SixChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function PetNeidan_SixChoice_OnLoad()	
	g_PetNeidan_SixChoice_UnifiedPosition = PetNeidan_SixChoice_Frame_BK:GetProperty("UnifiedPosition")
	g_PetNeidan_SixChoice_BagPos = -1
	g_PetNeidan_SixChoice_ItemChoice = 0

	-- PetNeidan_SixChoice_Page_Info:SetText("#{MHSD_191203_63}")
	local str_pre = "PetNeidan_SixChoice_Page_Lace"
	for i = 1, 6 do
		g_PetNeidan_SixChoice_Page_Item[i] = _G[str_pre..i.."Item"]
		g_PetNeidan_SixChoice_Page_Text[i] = _G[str_pre..i.."Item_Tip"]
		g_PetNeidan_SixChoice_Page_Item_Mask[i] = _G[str_pre..i.."Item_Mask"]
		g_PetNeidan_SixChoice_Page_Item_Mark[i] = _G[str_pre..i.."Item_Conermark"]
		g_PetNeidan_SixChoice_Page_Item_Mark[i]:Hide()
	end
end

function PetNeidan_SixChoice_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 50511201 ) then
		if this:IsVisible() then
			if g_PetNeidan_SixChoice_BagPos >= 0 then
				LifeAbility:Lock_Packet_Item(g_PetNeidan_SixChoice_BagPos, 0)
			end
			g_PetNeidan_SixChoice_ItemChoice = 0
		end
		g_PetNeidan_SixChoice_BagPos = Get_XParam_INT(0)
		g_PetNeidan_SixChoice_LiheType = Get_XParam_INT(1)
		PetNeidan_SixChoice_On_Update()

	elseif (event == "ADJEST_UI_POS" ) then
		PetNeidan_SixChoice_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetNeidan_SixChoice_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		PetNeidan_SixChoice_OnHidden()
	end
end

function PetNeidan_SixChoice_On_ResetPos()
	PetNeidan_SixChoice_Frame_BK:SetProperty("UnifiedPosition", g_PetNeidan_SixChoice_UnifiedPosition)
end

function PetNeidan_SixChoice_On_Update()
	if not g_PetNeidan_SixChoice_ZhanShiItemId[g_PetNeidan_SixChoice_LiheType] then
		return
	end
	for i = 1, table.getn(g_PetNeidan_SixChoice_Page_Item) do
		local nItemID = g_PetNeidan_SixChoice_ZhanShiItemId[g_PetNeidan_SixChoice_LiheType][i]
		local theAction = DataPool:CreateActionItemForShow( nItemID, 1 )
		g_PetNeidan_SixChoice_Page_Item[i]:SetActionItem(theAction:GetID())
		g_PetNeidan_SixChoice_Page_Text[i]:SetText("#L"..theAction:GetName())
		g_PetNeidan_SixChoice_Page_Item_Mask[i]:Hide()
	end
	g_PetNeidan_SixChoice_ItemChoice = 0
	LifeAbility:Lock_Packet_Item(g_PetNeidan_SixChoice_BagPos, 1) --背包格子蒙红锁定
	this:Show()
end

function PetNeidan_SixChoice_OnActionItemClicked(nIndex)
	for i = 1, table.getn(g_PetNeidan_SixChoice_Page_Item_Mask) do
		if i == nIndex then
			g_PetNeidan_SixChoice_Page_Item_Mask[i]:Show()
		else
			g_PetNeidan_SixChoice_Page_Item_Mask[i]:Hide()
		end
	end
	g_PetNeidan_SixChoice_ItemChoice = nIndex
end

function PetNeidan_SixChoice_OKClicked()
	if g_PetNeidan_SixChoice_ItemChoice == 0 then
		PushDebugMessage("#{RCLS_200731_126}")
		return
	end
	if g_PetNeidan_SixChoice_BagPos == -1 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetSelectedItem")
		Set_XSCRIPT_ScriptID(505112)
		Set_XSCRIPT_Parameter(0, g_PetNeidan_SixChoice_LiheType)
		Set_XSCRIPT_Parameter(1, g_PetNeidan_SixChoice_BagPos)
		Set_XSCRIPT_Parameter(2, g_PetNeidan_SixChoice_ItemChoice)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	PetNeidan_SixChoice_OnHidden()
end

function PetNeidan_SixChoice_OnHidden()
	if g_PetNeidan_SixChoice_BagPos >= 0 then
		LifeAbility:Lock_Packet_Item(g_PetNeidan_SixChoice_BagPos, 0)
	end
	g_PetNeidan_SixChoice_BagPos = -1
	g_PetNeidan_SixChoice_ItemChoice = 0
	this:Hide()
end