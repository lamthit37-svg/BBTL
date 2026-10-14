
local g_SanShen_BaoXiang_UnifiedPosition = nil
local g_SanShen_BaoXiangIndex = -1


function SanShen_BaoXiang_PreLoad()
	this:RegisterEvent("SECKILL_OPENSANSHENITEM")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function SanShen_BaoXiang_OnLoad()
	g_SanShen_BaoXiang_UnifiedPosition = SanShen_BaoXiang_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function SanShen_BaoXiang_OnEvent(event)
	if (event  == "SECKILL_OPENSANSHENITEM") then
		g_SanShen_BaoXiangIndex = tonumber(arg0)
		SanShen_BaoXiang_Show()
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		SanShen_BaoXiang_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		SanShen_BaoXiang_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		SanShen_BaoXiang_OnHiden()
	end
end

function SanShen_BaoXiang_ResetPos()
		SanShen_BaoXiang_Frame:SetProperty("UnifiedPosition",g_SanShen_BaoXiang_UnifiedPosition)
end


function SanShen_BaoXiang_Show()
	if g_SanShen_BaoXiangIndex < 4 or g_SanShen_BaoXiangIndex > 6  then
		return
	end
	
	SanShen_BaoXiang_Open:SetText("#{FBSD_130127_31}")
	SanShen_BaoXiang_LingfuOpen:SetText("#{FBSD_201105_2}")
	if g_SanShen_BaoXiangIndex  == 4 then
		SanShen_BaoXiang_Frame_Title:SetText("#{FBSD_130127_29}")
		SanShen_BaoXiang_Info:SetText("#{FBSD_130127_30}")
		SanShen_BaoXiang_YuanbaoOpen:SetText("#{FBSD_130127_32}")
	elseif g_SanShen_BaoXiangIndex == 5 then
		SanShen_BaoXiang_Frame_Title:SetText("#{FBSD_130127_33}")
		SanShen_BaoXiang_Info:SetText("#{FBSD_130127_34}")
		SanShen_BaoXiang_YuanbaoOpen:SetText("#{FBSD_130127_35}")
	elseif g_SanShen_BaoXiangIndex == 6 then
		SanShen_BaoXiang_Frame_Title:SetText("#{FBSD_130127_36}")
		SanShen_BaoXiang_Info:SetText("#{FBSD_130127_37}")
		SanShen_BaoXiang_YuanbaoOpen:SetText("#{FBSD_130127_38}")
	end
end

function SanShen_BaoXiang_OpenFree()
	if g_SanShen_BaoXiangIndex < 4 or g_SanShen_BaoXiangIndex > 6  then
		return
	end
	
	PushEvent("SEND_SECKILL", 1, g_SanShen_BaoXiangIndex, 0)
	SanShen_BaoXiang_OnHiden()
end

function SanShen_BaoXiang_OpenLingfu()
	if g_SanShen_BaoXiangIndex < 4 or g_SanShen_BaoXiangIndex > 6  then
		return
	end
	
	PushEvent("SEND_SECKILL", 1, g_SanShen_BaoXiangIndex, 2)
	SanShen_BaoXiang_OnHiden()
end

function SanShen_BaoXiang_OpenYuanbao()
	if g_SanShen_BaoXiangIndex < 4 or g_SanShen_BaoXiangIndex > 6  then
		return
	end
	
	PushEvent("SEND_SECKILL", 1, g_SanShen_BaoXiangIndex, 1)
	SanShen_BaoXiang_OnHiden()
end

function SanShen_BaoXiang_OnHiden()
	this:Hide()
	g_SanShen_BaoXiangIndex = -1
end