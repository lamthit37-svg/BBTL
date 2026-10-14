--!!!reloadscript =SpecialGift_DoubleLook
--物品 2选1

local g_SpecialGift_DoubleLook_Frame_UnifiedPosition = ""

local g_ActionItem = {}
local g_ItemNameText = {}

local g_Count = 2
local g_ItemToChoose = {
	[1] = {{cloth = 10127152, face = 144, hair = 181}, {cloth = 10127153, face = 145, hair = 182}},
}

local g_ItemGroupIndex = 0


function SpecialGift_DoubleLook_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("DRESS_PREVIEW_CHOICE_2", true)
end

function SpecialGift_DoubleLook_OnLoad()

	g_SpecialGift_DoubleLook_Frame_UnifiedPosition = SpecialGift_DoubleLook_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = SpecialGift_DoubleLook_Item1
	g_ActionItem[2] = SpecialGift_DoubleLook_Item2
	
	g_ItemNameText[1] = SpecialGift_DoubleLook_Item1_Name
	g_ItemNameText[2] = SpecialGift_DoubleLook_Item2_Name
end										

function SpecialGift_DoubleLook_OnEvent(event)
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpecialGift_DoubleLook_Frame_On_ResetPos()
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		SpecialGift_DoubleLook_Close()
		return
	end
	
	if event == "DRESS_PREVIEW_CHOICE_2" then
		SpecialGift_DoubleLook_CleanUp()
		g_ItemGroupIndex = tonumber(arg0)
		SpecialGift_DoubleLook_Update()
		this:Show()
	end
end

function SpecialGift_DoubleLook_Update()

	for i = 1, g_Count do
		local awardItemId = g_ItemToChoose[g_ItemGroupIndex][i].cloth
		local awardItemNum = 1
		
		local itemAction = DataPool:CreateActionItemForShow(awardItemId, awardItemNum)
		if itemAction:GetID() ~= 0 then
			g_ActionItem[i]:SetActionItem(itemAction:GetID())
		end
		
		local strName = DataPool:Lua_GetItemNameByIndex(awardItemId)
		g_ItemNameText[i]:SetText("#L"..strName)
	end
end

function SpecialGift_DoubleLook_Choose(index)

end

function SpecialGift_DoubleLook_Close()
	SpecialGift_DoubleLook_CleanUp()
	this:Hide()
end

function SpecialGift_DoubleLook_CleanUp()	
	for i = 1, g_Count do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
	end
end

function SpecialGift_DoubleLook_View(index)
	
	local nExteriorHairId = g_ItemToChoose[g_ItemGroupIndex][index].hair
	local nExteriorFaceId = g_ItemToChoose[g_ItemGroupIndex][index].face
	
	if nExteriorHairId < 0 then
		nExteriorHairId = Exterior:LuaFnGetExteriorInUse(4)
	end
	
	if nExteriorFaceId < 0 then
		nExteriorFaceId = Exterior:LuaFnGetExteriorInUse(3)
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, g_ItemToChoose[g_ItemGroupIndex][index].cloth)
		Set_XSCRIPT_Parameter(1, nExteriorHairId)
		Set_XSCRIPT_Parameter(2, nExteriorFaceId)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	this:Hide()
end

function SpecialGift_DoubleLook_Frame_On_ResetPos()
	if g_SpecialGift_DoubleLook_Frame_UnifiedPosition == nil then
		return
	end
	
	SpecialGift_DoubleLook_Frame_BK:SetProperty("UnifiedPosition", g_SpecialGift_DoubleLook_Frame_UnifiedPosition)
end

