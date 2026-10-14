----------------------
-- SeventhFestivalPrizePreview1 ---
----------------------
local g_SeventhFestivalPrizePreview1_UnifiedPosition = nil
local g_SeventhFestivalPrizePreview1_CurIndex = 0
local g_SeventhFestivalPrizePreview1_CurPage = 0
--礼盒信息
local g_SeventhFestivalPrizePreview1_Gift =
{
	[1] = {title = "", icon = "set:SeventhFestivalPrizePreview02 image:SeventhFestivalPrizePreview_HorseWeapon"}, --七夕送
	[2] = {title = "", icon = "set:SeventhFestivalPrizePreview03 image:SeventhFestivalPrizePreview03_1"}, --七夕收
}

function SeventhFestivalPrizePreview1_PreLoad()
	--this:RegisterEvent("OPEN_QIXITOPLIST_ZHANSHI")
	--this:RegisterEvent("ADJEST_UI_POS",false)
	--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function SeventhFestivalPrizePreview1_OnLoad()
	g_SeventhFestivalPrizePreview1_UnifiedPosition = SeventhFestivalPrizePreview1_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function SeventhFestivalPrizePreview1_OnEvent(event)
	if (event == "OPEN_QIXITOPLIST_ZHANSHI") then
		local index = tonumber(arg0)
		local ipage = tonumber(arg1)
		local iS_R = tonumber(arg2)
		if index == nil or index <= 0 or index > 3 then
			return
		end
		
		if index == nil or ipage ~= 2 then
			return
		end
		if this:IsVisible() then
			if g_SeventhFestivalPrizePreview1_CurIndex == index  and g_SeventhFestivalPrizePreview1_CurPage == ipage then
				SeventhFestivalPrizePreview1_OnHiden()
				return
			end
		end
		g_SeventhFestivalPrizePreview1_CurIndex = index
		g_SeventhFestivalPrizePreview1_CurPage = ipage
		
		if g_SeventhFestivalPrizePreview1_CurPage ~= 1 then		
			if iS_R == 1 then -- 送
				local strIcon = g_SeventhFestivalPrizePreview1_Gift[1].icon
				--SeventhFestivalPrizePreview1_Client:SetText(strTitle)
				SeventhFestivalPrizePreview1_Pic:SetProperty("Image",strIcon)--显示指定图片
			elseif iS_R == 2 then --收
				local strIcon = g_SeventhFestivalPrizePreview1_Gift[2].icon
				--SeventhFestivalPrizePreview1_Client:SetText(strTitle)
				SeventhFestivalPrizePreview1_Pic:SetProperty("Image",strIcon)--显示指定图片
			end
		end
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		SeventhFestivalPrizePreview1_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		SeventhFestivalPrizePreview1_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		SeventhFestivalPrizePreview1_OnHiden()
	end
end

function SeventhFestivalPrizePreview1_ResetPos()
		SeventhFestivalPrizePreview1_Frame:SetProperty("UnifiedPosition",g_SeventhFestivalPrizePreview1_UnifiedPosition)
end

function SeventhFestivalPrizePreview1_OnHiden()
	g_SeventhFestivalPrizePreview1_CurIndex = 0
	g_SeventhFestivalPrizePreview1_CurPage = 0
	this:Hide()
end