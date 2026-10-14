--GXHInfantcolorstyle.lua
--!!!reloadscript =GXHInfantcolorstyle
--2020Q4 子女发色确认
local g_Frame_UnifiedPosition
local g_GXHInfantcolorstyle_MaxNum = 20
local g_GXHInfantcolorstyle_Array = {}
--===============================================
-- OnLoad()
--===============================================
function GXHInfantcolorstyle_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REFRESH_INFANT_HAIRCOLOR", false)
end
function GXHInfantcolorstyle_OnLoad()
	g_Frame_UnifiedPosition = GXHInfantcolorstyle_Frame:GetProperty("UnifiedPosition")

	g_GXHInfantcolorstyle_Array = {
		{uiItem = GXHInfantcolorstyle_Item1, uiIcon =GXHInfantcolorstyle_BKG1},
		{uiItem = GXHInfantcolorstyle_Item2, uiIcon =GXHInfantcolorstyle_BKG2},
		{uiItem = GXHInfantcolorstyle_Item3, uiIcon =GXHInfantcolorstyle_BKG3},
		{uiItem = GXHInfantcolorstyle_Item4, uiIcon =GXHInfantcolorstyle_BKG4},
		{uiItem = GXHInfantcolorstyle_Item5, uiIcon =GXHInfantcolorstyle_BKG5},
		{uiItem = GXHInfantcolorstyle_Item6, uiIcon =GXHInfantcolorstyle_BKG6},
		{uiItem = GXHInfantcolorstyle_Item7, uiIcon =GXHInfantcolorstyle_BKG7},
		{uiItem = GXHInfantcolorstyle_Item8, uiIcon =GXHInfantcolorstyle_BKG8},
		{uiItem = GXHInfantcolorstyle_Item9, uiIcon =GXHInfantcolorstyle_BKG9},
		{uiItem = GXHInfantcolorstyle_Item10, uiIcon =GXHInfantcolorstyle_BKG10},
		{uiItem = GXHInfantcolorstyle_Item11, uiIcon =GXHInfantcolorstyle_BKG11},
		{uiItem = GXHInfantcolorstyle_Item12, uiIcon =GXHInfantcolorstyle_BKG12},
		{uiItem = GXHInfantcolorstyle_Item13, uiIcon =GXHInfantcolorstyle_BKG13},
		{uiItem = GXHInfantcolorstyle_Item14, uiIcon =GXHInfantcolorstyle_BKG14},
		{uiItem = GXHInfantcolorstyle_Item15, uiIcon =GXHInfantcolorstyle_BKG15},
		{uiItem = GXHInfantcolorstyle_Item16, uiIcon =GXHInfantcolorstyle_BKG16},
		{uiItem = GXHInfantcolorstyle_Item17, uiIcon =GXHInfantcolorstyle_BKG17},
		{uiItem = GXHInfantcolorstyle_Item18, uiIcon =GXHInfantcolorstyle_BKG18},
		{uiItem = GXHInfantcolorstyle_Item19, uiIcon =GXHInfantcolorstyle_BKG19},
		{uiItem = GXHInfantcolorstyle_Item20, uiIcon =GXHInfantcolorstyle_BKG20},
	}
end

--===============================================
-- OnEvent()
--===============================================
function GXHInfantcolorstyle_OnEvent(event)
if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		GXHInfantcolorstyle_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		GXHInfantcolorstyle_OnHide()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15850001 ) then
		if this:IsVisible() then
			return
		end
		GXHInfantcolorstyle_GXHClicked(0)
		g_Original_Color = Get_XParam_INT(0)
		g_Change_Color = Get_XParam_INT(1)
		g_YuanBao_Pay = Get_XParam_INT(2)
		GXHInfantcolorstyle_OnShow()
	elseif event == "REFRESH_INFANT_HAIRCOLOR" and tonumber(arg0) == 1 then
		GXHInfantcolorstyle_OnHide()
	end
end
function GXHInfantcolorstyle_OnHide()
	if g_Select_Icon ~= -1 then
		Infant:ClearFittingProperty()
	end
	g_Select_Icon =-1
	this:Hide()
end
function GXHInfantcolorstyle_OnShow()
	GXHInfantcolorstyle_Init()
	this:Show()
end
--===============================================
--===============================================
function GXHInfantcolorstyle_Init()
	local nCount, nMaxCount = Exterior:LuaFnGetChildHairColorCount()
	for i=0,g_GXHInfantcolorstyle_MaxNum-1 do 
		if i < nCount then 
			local r,g,b,a = Exterior:LuaFnEnumChildHairColor(i)
			local imageColor = string.format("%02X%02X%02X%02X", 255, r, g, b)
			g_GXHInfantcolorstyle_Array[i+1].uiIcon:SetImageColor(imageColor)
		else
			g_GXHInfantcolorstyle_Array[i+1].uiIcon:SetImageColor("00FFFFFF")
		end
	end
end
function GXHInfantcolorstyle_GXHClicked(nIndex)
	nIndex = nIndex - 1
	-- PushDebugMessage("GXHInfantcolorstyle_GXHClicked:"..nIndex)
	g_Select_Icon = nIndex
	local nCount, nMaxCount = Exterior:LuaFnGetChildHairColorCount()
	for i=1,g_GXHInfantcolorstyle_MaxNum do
		g_GXHInfantcolorstyle_Array[i].uiItem:SetPushed(0)
	end
	if nIndex >= 0 and nIndex < g_GXHInfantcolorstyle_MaxNum then 
		g_GXHInfantcolorstyle_Array[nIndex+1].uiItem:SetPushed(1)
	end
end
function GXHInfantcolorstyle_OnOK()
	if g_Select_Icon == -1 then
		PushDebugMessage("#{GXHDZ_141121_55}")
		return
	end
			
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnUpdateInfantHairColor");
		Set_XSCRIPT_ScriptID(890986);
		Set_XSCRIPT_Parameter(0,g_Change_Color)
		Set_XSCRIPT_Parameter(1,g_Select_Icon)
		Set_XSCRIPT_Parameter(2,g_YuanBao_Pay)
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
end