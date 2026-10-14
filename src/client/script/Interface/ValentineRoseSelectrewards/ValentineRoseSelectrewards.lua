----------------------
-- ValentineRoseSelectrewards ---
----------------------
local g_ValentineRoseSelectrewards_UnifiedPosition = nil
local g_ValentineRoseSelectrewards_CurIndex = 0
--礼盒信息
local g_ValentineRoseSelectrewards_Gift =
{
	[1] = {title = "#{MGCQ_151230_134}", info = "#{MGCQ_151230_135}"},
	[2] = {title = "#{MGCQ_151230_141}", info = "#{MGCQ_151230_142}"},
}

local g_IsNewLihe = 0  --是否是2017新礼盒

local g_Tips =
{
	[0] = {str0="#{MGCQ_151230_141}",str1="#{MGCQ_151230_142}",str2="#{MGCQ_151230_137}",str3="#{MGCQ_151230_138}"},
	[1] = {str0="#{MGCQ_151230_183}",str1="#{MGCQ_151230_186}",str2="#{MGCQ_151230_181}",str3="#{MGCQ_151230_182}"},
}

function ValentineRoseSelectrewards_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function ValentineRoseSelectrewards_OnLoad()
	g_ValentineRoseSelectrewards_UnifiedPosition = ValentineRoseSelectrewards_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function ValentineRoseSelectrewards_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 891050) then
		g_IsNewLihe = 0
		local index =Get_XParam_INT(0)
		if (index == nil) or (index <= 0 or index > 2) then
			return
		end
		if this:IsVisible() then
			if g_ValentineRoseSelectrewards_CurIndex == index then
				ValentineRoseSelectrewards_Show(index)
				ValentineRoseSelectrewards_OnHiden()
				return
			end
		end
		g_ValentineRoseSelectrewards_CurIndex = index
		ValentineRoseSelectrewards_Show(index)
		this:Show()
	elseif (event  == "UI_COMMAND") and (tonumber(arg0) == 892418) then
		g_IsNewLihe = 1
		local index =Get_XParam_INT(0)
		if (index == nil) or (index <= 0 or index > 2) then
			return
		end
		if this:IsVisible() then
			if g_ValentineRoseSelectrewards_CurIndex == index then
				ValentineRoseSelectrewards_Show(index)
				ValentineRoseSelectrewards_OnHiden()
				return
			end
		end
		g_ValentineRoseSelectrewards_CurIndex = index
		ValentineRoseSelectrewards_Show(index)		
		this:Show()		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		ValentineRoseSelectrewards_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		ValentineRoseSelectrewards_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		ValentineRoseSelectrewards_OnHiden()
	end
end

function ValentineRoseSelectrewards_ResetPos()
		ValentineRoseSelectrewards_Frame:SetProperty("UnifiedPosition",g_ValentineRoseSelectrewards_UnifiedPosition)
end

function ValentineRoseSelectrewards_OnHiden()
	g_ValentineRoseSelectrewards_CurIndex = 0
	this:Hide()
end

function ValentineRoseSelectrewards_Show(index)
	if (index == nil) or (index <= 0 or index > 2) then
		return
	end
	ValentineRoseSelectrewards_DragTitle:SetText(g_ValentineRoseSelectrewards_Gift[index].title)
	ValentineRoseSelectrewards_Info:SetText(g_ValentineRoseSelectrewards_Gift[index].info)
	if index == 1 then
		ValentineRoseSelectrewards_Select02:SetProperty("UnifiedPosition","{{0.500000,-60.000000},{1.000000,-35.000000}}")
		ValentineRoseSelectrewards_Select03:SetProperty("UnifiedPosition","{{1.000000,-140.000000},{1.000000,-35.000000}}")
		ValentineRoseSelectrewards_Select01:Show()
	elseif index == 2 then
		ValentineRoseSelectrewards_Select01:Hide()
		ValentineRoseSelectrewards_Select02:SetProperty("UnifiedPosition","{{0.500000,-160.000000},{1.000000,-35.000000}}")
		ValentineRoseSelectrewards_Select03:SetProperty("UnifiedPosition","{{0.500000,40.000000},{1.000000,-35.000000}}")
		
		ValentineRoseSelectrewards_DragTitle:SetText(g_Tips[g_IsNewLihe].str0)
		ValentineRoseSelectrewards_Info:SetText(g_Tips[g_IsNewLihe].str1)
		ValentineRoseSelectrewards_Select02:SetText(g_Tips[g_IsNewLihe].str2)
		ValentineRoseSelectrewards_Select03:SetText(g_Tips[g_IsNewLihe].str3)

	end
end

function ValentineRoseSelectrewards_Select(index)
	if index <= 0 or index > 3 then
		return
	end
	
	if g_ValentineRoseSelectrewards_CurIndex == 2 then
		if index <= 1 then
			return
		end
	end
	
	if g_IsNewLihe == 0 then
		--领奖
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
			Set_XSCRIPT_ScriptID( 891050 )
			Set_XSCRIPT_Parameter(0,g_ValentineRoseSelectrewards_CurIndex)
			Set_XSCRIPT_Parameter(1,index)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif g_IsNewLihe == 1 then
		--领奖
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
			Set_XSCRIPT_ScriptID( 892418 )
			Set_XSCRIPT_Parameter(0,g_ValentineRoseSelectrewards_CurIndex)
			Set_XSCRIPT_Parameter(1,index)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()		
	end
		
	ValentineRoseSelectrewards_OnHiden()
end