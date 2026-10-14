----------------------
-- SeventhFestivalSelectrewards ---
----------------------
local g_SeventhFestivalSelectrewards_UnifiedPosition = nil
local g_SeventhFestivalSelectrewards_CurIndex = 0
--礼盒信息
local g_SeventhFestivalSelectrewards_Gift =
{
	[1] = {title = "#{QXLS_150724_134}", info = "#{QXLS_150724_135}"},
	[2] = {title = "#{QXLS_150724_141}", info = "#{QXLS_150724_142}"},
}

function SeventhFestivalSelectrewards_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function SeventhFestivalSelectrewards_OnLoad()
	g_SeventhFestivalSelectrewards_UnifiedPosition = SeventhFestivalSelectrewards_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function SeventhFestivalSelectrewards_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 891431) then
		local index =Get_XParam_INT(0)
		if (index == nil) or (index <= 0 or index > 2) then
			return
		end
		if this:IsVisible() then
			if g_SeventhFestivalSelectrewards_CurIndex == index then
				SeventhFestivalSelectrewards_OnHiden()
				return
			end
		end
		g_SeventhFestivalSelectrewards_CurIndex = index
		SeventhFestivalSelectrewards_Show(index)
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		SeventhFestivalSelectrewards_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		SeventhFestivalSelectrewards_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		SeventhFestivalSelectrewards_OnHiden()
	end
end

function SeventhFestivalSelectrewards_ResetPos()
		SeventhFestivalSelectrewards_Frame:SetProperty("UnifiedPosition",g_SeventhFestivalSelectrewards_UnifiedPosition)
end

function SeventhFestivalSelectrewards_OnHiden()
	g_SeventhFestivalSelectrewards_CurIndex = 0
	this:Hide()
end

function SeventhFestivalSelectrewards_Show(index)
	if (index == nil) or (index <= 0 or index > 2) then
		return
	end
	SeventhFestivalSelectrewards_DragTitle:SetText(g_SeventhFestivalSelectrewards_Gift[index].title)
	SeventhFestivalSelectrewards_Info:SetText(g_SeventhFestivalSelectrewards_Gift[index].info)
	if index == 1 then
		SeventhFestivalSelectrewards_Select02:SetProperty("UnifiedPosition","{{0.500000,-60.000000},{1.000000,-35.000000}}")
		SeventhFestivalSelectrewards_Select03:SetProperty("UnifiedPosition","{{1.000000,-140.000000},{1.000000,-35.000000}}")
		SeventhFestivalSelectrewards_Select01:Show()
	elseif index == 2 then
		SeventhFestivalSelectrewards_Select01:Hide()
		SeventhFestivalSelectrewards_Select02:SetProperty("UnifiedPosition","{{0.500000,-160.000000},{1.000000,-35.000000}}")
		SeventhFestivalSelectrewards_Select03:SetProperty("UnifiedPosition","{{0.500000,40.000000},{1.000000,-35.000000}}")
	end
end

function SeventhFestivalSelectrewards_Select(index)
	if index <= 0 or index > 3 then
		return
	end
	
	if g_SeventhFestivalSelectrewards_CurIndex == 2 then
		if index <= 1 then
			return
		end
	end
	
	--领奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID( 891431 )
		Set_XSCRIPT_Parameter(0,g_SeventhFestivalSelectrewards_CurIndex)
		Set_XSCRIPT_Parameter(1,index)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
	SeventhFestivalSelectrewards_OnHiden()
end