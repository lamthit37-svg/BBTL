local g_TreasureBox_AwardPreview_UnifiedPosition
local g_TreasureBox_AwardPreview_ActionButton_Page1 = {}
local g_TreasureBox_AwardPreview_ActionButton_Page2 = {}

local g_TreasureBox_AwardPreview_ItemList1 = {
	[1] = 39922841,
	[2] = 39922841,
	[3] = 39922841,
}

local g_TreasureBox_AwardPreview_ItemListNum1 = {
	[1] = 6,
	[2] = 4,
	[3] = 2,
}

local g_TreasureBox_AwardPreview_ItemList2 = {
	[1] = 39922840,
	[2] = 39922840,
	[3] = 39922840,

	[4] = 39922742,
	[5] = 39922741,

	[6] = 39922740,
	[7] = 39922739,
	[8] = 39922180,
	[9] = 39922155,

	[10] = 39925278,
	[11] = 39925276,
	[12] = 39922738,
	[13] = 39923145,
}

local g_TreasureBox_AwardPreview_ItemListNum2 = {
	[1] = 3,
	[2] = 2,
	[3] = 1,

	[4] = 1,
	[5] = 1,

	[6] = 1,
	[7] = 1,
	[8] = 1,
	[9] = 1,

	[10] = 1,
	[11] = 1,
	[12] = 1,
	[13] = 1,
}

function TreasureBox_AwardPreview_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function TreasureBox_AwardPreview_OnLoad()
	g_TreasureBox_AwardPreview_ActionButton_Page1[1] = TreasureBox_AwardPreview_Page1_Icon1
	g_TreasureBox_AwardPreview_ActionButton_Page1[2] = TreasureBox_AwardPreview_Page1_Icon2
	g_TreasureBox_AwardPreview_ActionButton_Page1[3] = TreasureBox_AwardPreview_Page1_Icon3

	g_TreasureBox_AwardPreview_ActionButton_Page2[1] = TreasureBox_AwardPreview_Page2_Item1_Icon1
	g_TreasureBox_AwardPreview_ActionButton_Page2[2] = TreasureBox_AwardPreview_Page2_Item1_Icon2
	g_TreasureBox_AwardPreview_ActionButton_Page2[3] = TreasureBox_AwardPreview_Page2_Item1_Icon3

	g_TreasureBox_AwardPreview_ActionButton_Page2[4] = TreasureBox_AwardPreview_Page2_Item2_Icon1
	g_TreasureBox_AwardPreview_ActionButton_Page2[5] = TreasureBox_AwardPreview_Page2_Item2_Icon2

	g_TreasureBox_AwardPreview_ActionButton_Page2[6] = TreasureBox_AwardPreview_Page2_Item3_Icon1
	g_TreasureBox_AwardPreview_ActionButton_Page2[7] = TreasureBox_AwardPreview_Page2_Item3_Icon2
	g_TreasureBox_AwardPreview_ActionButton_Page2[8] = TreasureBox_AwardPreview_Page2_Item3_Icon3
	g_TreasureBox_AwardPreview_ActionButton_Page2[9] = TreasureBox_AwardPreview_Page2_Item3_Icon4

	g_TreasureBox_AwardPreview_ActionButton_Page2[10] = TreasureBox_AwardPreview_Page2_Item4_Icon1
	g_TreasureBox_AwardPreview_ActionButton_Page2[11] = TreasureBox_AwardPreview_Page2_Item4_Icon2
	g_TreasureBox_AwardPreview_ActionButton_Page2[12] = TreasureBox_AwardPreview_Page2_Item4_Icon3
	g_TreasureBox_AwardPreview_ActionButton_Page2[13] = TreasureBox_AwardPreview_Page2_Item4_Icon4
	
	g_TreasureBox_AwardPreview_UnifiedPosition = TreasureBox_AwardPreview_Frame:GetProperty("UnifiedPosition")
end

function TreasureBox_AwardPreview_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88819005 ) then
		TreasureBox_AwardPreview_Update()
		this:Show()
		this:Activate()
	elseif (event == "ADJEST_UI_POS" ) then
		TreasureBox_AwardPreview_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TreasureBox_AwardPreview_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function TreasureBox_AwardPreview_Update()
	for i = 1, table.getn(g_TreasureBox_AwardPreview_ActionButton_Page1) do
		local theAction = DataPool:CreateActionItemForShow( g_TreasureBox_AwardPreview_ItemList1[i], g_TreasureBox_AwardPreview_ItemListNum1[i] )
		g_TreasureBox_AwardPreview_ActionButton_Page1[i]:SetActionItem(theAction:GetID())
	end

	for i = 1, table.getn(g_TreasureBox_AwardPreview_ActionButton_Page2) do
		local theAction = DataPool:CreateActionItemForShow( g_TreasureBox_AwardPreview_ItemList2[i], g_TreasureBox_AwardPreview_ItemListNum2[i] )
		g_TreasureBox_AwardPreview_ActionButton_Page2[i]:SetActionItem(theAction:GetID())
	end
end

function TreasureBox_AwardPreview_On_ResetPos()
	TreasureBox_AwardPreview_Frame:SetProperty("UnifiedPosition", g_TreasureBox_AwardPreview_UnifiedPosition);
end

function TreasureBox_AwardPreview_OnClose()
	this:Hide()
end

function TreasureBox_AwardPreview_OnHiden()
	this:Hide()
end

function TreasureBox_AwardPreview_ButtonClick(nIndex)
	if nIndex == 1 then
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10128642)
		Set_XSCRIPT_Parameter(1, 288)
		Set_XSCRIPT_Parameter(2, 210)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	--elseif nIndex == 2 then
	--	PushEvent( "UI_COMMAND", 88819006 )
	--	this:Show()
	end
end

