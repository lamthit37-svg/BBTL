
local g_Fuli_SanShen_BaoXiang_UnifiedPosition = nil
local g_Fuli_SanShen_BaoXiangIndex = -1


function Fuli_SanShen_BaoXiang_PreLoad()
	this:RegisterEvent("SECKILL_OPENSANSHENITEM_ZHAOHUI")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function Fuli_SanShen_BaoXiang_OnLoad()
	g_Fuli_SanShen_BaoXiang_UnifiedPosition = Fuli_SanShen_BaoXiang_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function Fuli_SanShen_BaoXiang_OnEvent(event)
	if (event  == "SECKILL_OPENSANSHENITEM_ZHAOHUI") then
		g_Fuli_SanShen_BaoXiangIndex = tonumber(arg0)
		Fuli_SanShen_BaoXiang_Show()
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Fuli_SanShen_BaoXiang_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		Fuli_SanShen_BaoXiang_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Fuli_SanShen_BaoXiang_OnHiden()
	end
end

function Fuli_SanShen_BaoXiang_ResetPos()
		Fuli_SanShen_BaoXiang_Frame:SetProperty("UnifiedPosition",g_Fuli_SanShen_BaoXiang_UnifiedPosition)
end


function Fuli_SanShen_BaoXiang_Show()
	if g_Fuli_SanShen_BaoXiangIndex < 4 or g_Fuli_SanShen_BaoXiangIndex > 6  then
		return
	end
	
	Fuli_SanShen_BaoXiang_Open:SetText("#{FBSD_130127_31}")
	if g_Fuli_SanShen_BaoXiangIndex  == 4 then
		Fuli_SanShen_BaoXiang_Frame_Title:SetText("#{FBSD_130127_29}")
		Fuli_SanShen_BaoXiang_Info:SetText("#{XTZY_171213_125}") 
	elseif g_Fuli_SanShen_BaoXiangIndex == 5 then
		Fuli_SanShen_BaoXiang_Frame_Title:SetText("#{FBSD_130127_33}")
		Fuli_SanShen_BaoXiang_Info:SetText("#{XTZY_171213_126}") 
	elseif g_Fuli_SanShen_BaoXiangIndex == 6 then
		Fuli_SanShen_BaoXiang_Frame_Title:SetText("#{FBSD_130127_36}")
		Fuli_SanShen_BaoXiang_Info:SetText("#{XTZY_171213_127}") 
	end
end

function Fuli_SanShen_BaoXiang_OpenFree()
	if g_Fuli_SanShen_BaoXiangIndex < 4 or g_Fuli_SanShen_BaoXiangIndex > 6  then
		return
	end
	
	PushEvent("SEND_SECKILL_ZHAOHUI", 1, g_Fuli_SanShen_BaoXiangIndex, 0)
	Fuli_SanShen_BaoXiang_OnHiden()
end
 
function Fuli_SanShen_BaoXiang_OnHiden()
	this:Hide()
	g_Fuli_SanShen_BaoXiangIndex = -1
end