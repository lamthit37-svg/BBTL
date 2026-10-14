----------------------
-- ValentineRoseTopList_Selectrewards ---
----------------------
local g_ValentineRoseTopList_Selectrewards_UnifiedPosition = nil
local g_ValentineRoseTopList_Selectrewards_CurIndex = -1
--礼盒信息
local g_ValentineRoseTopList_Selectrewards_Gift =
{
	[38005670] = {info="#{MGCQ_211130_61}", id1=39910122, id2=39910121},
}

function ValentineRoseTopList_Selectrewards_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function ValentineRoseTopList_Selectrewards_OnLoad()
	g_ValentineRoseTopList_Selectrewards_UnifiedPosition = ValentineRoseTopList_Selectrewards_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function ValentineRoseTopList_Selectrewards_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 892755) then
		local nBagPos = Get_XParam_INT(0)
		local nItemId = Get_XParam_INT(1)
		if this:IsVisible() then
			if g_ValentineRoseTopList_Selectrewards_CurIndex == index then
				ValentineRoseTopList_Selectrewards_OnHiden()
				return
			end
		end
		g_ValentineRoseTopList_Selectrewards_CurIndex = nItemId
		ValentineRoseTopList_Selectrewards_Show(nItemId)
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		ValentineRoseTopList_Selectrewards_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		ValentineRoseTopList_Selectrewards_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		ValentineRoseTopList_Selectrewards_OnHiden()
	end
end

function ValentineRoseTopList_Selectrewards_ResetPos()
		ValentineRoseTopList_Selectrewards_Frame:SetProperty("UnifiedPosition",g_ValentineRoseTopList_Selectrewards_UnifiedPosition)
end

function ValentineRoseTopList_Selectrewards_OnHiden()
	g_ValentineRoseTopList_Selectrewards_CurIndex = -1
	this:Hide()
end

function ValentineRoseTopList_Selectrewards_Show(itemId)
	if itemId == nil or g_ValentineRoseTopList_Selectrewards_Gift[itemId] == nil then
		return
	end
	ValentineRoseTopList_Selectrewards_DragTitle:SetText("#gFF0FA0"..PlayerPackage:GetItemName(itemId))
	ValentineRoseTopList_Selectrewards_Info:SetText(g_ValentineRoseTopList_Selectrewards_Gift[itemId].info)
	
	ValentineRoseTopList_Selectrewards_Select01:SetText( PlayerPackage:GetItemName(g_ValentineRoseTopList_Selectrewards_Gift[itemId].id1) )
	ValentineRoseTopList_Selectrewards_Select02:SetText( PlayerPackage:GetItemName(g_ValentineRoseTopList_Selectrewards_Gift[itemId].id2) )
end

function ValentineRoseTopList_Selectrewards_Select(index)
	if index <= 0 or index > 2 then
		return
	end
		
	--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID( 892755 )
		Set_XSCRIPT_Parameter(0,g_ValentineRoseTopList_Selectrewards_CurIndex)
		Set_XSCRIPT_Parameter(1,index)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
	ValentineRoseTopList_Selectrewards_OnHiden()
end