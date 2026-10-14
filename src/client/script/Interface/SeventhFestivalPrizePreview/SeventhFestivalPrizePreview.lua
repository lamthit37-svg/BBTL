----------------------
-- SeventhFestivalPrizePreview ---
----------------------
local g_SeventhFestivalPrizePreview_UnifiedPosition = nil
local g_SeventhFestivalPrizePreview_CurIndex = 0
local g_SeventhFestivalPrizePreview_CurPage = 0
--礼盒信息
local g_SeventhFestivalPrizePreview_Gift =
{
	[1] = {title = "", icon = "set:SeventhFestivalPrizePreview04 image:Qixi_Show1"}, --前世仙缘榜的预览
	[2] = {title = "", icon = "set:SeventhFestivalPrizePreview05 image:Qixi_Show2"}, --七夕送
	[3] = {title = "", icon = "set:SeventhFestivalPrizePreview06 image:Qixi_Show3"}, --七夕收
}

function SeventhFestivalPrizePreview_PreLoad()
	this:RegisterEvent("OPEN_QIXITOPLIST_ZHANSHI")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function SeventhFestivalPrizePreview_OnLoad()
	g_SeventhFestivalPrizePreview_UnifiedPosition = SeventhFestivalPrizePreview_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function SeventhFestivalPrizePreview_OnEvent(event)
	if (event == "OPEN_QIXITOPLIST_ZHANSHI") then
		local index = tonumber(arg0)
		local ipage = tonumber(arg1)
		local iS_R = tonumber(arg2)
		if index == nil or index <= 0 or index > 3 then
			return
		end
		
		if ipage <= 0 or ipage > 3 then
			return
		end
		if this:IsVisible() then
			if g_SeventhFestivalPrizePreview_CurIndex == index  and g_SeventhFestivalPrizePreview_CurPage == ipage then
				SeventhFestivalPrizePreview_OnHiden()
				return
			end
		end
		g_SeventhFestivalPrizePreview_CurIndex = index
		g_SeventhFestivalPrizePreview_CurPage = ipage
		--local strTitle = g_SeventhFestivalPrizePreview_Gift[index].title
		if g_SeventhFestivalPrizePreview_CurPage == 1 then
			local strIcon = g_SeventhFestivalPrizePreview_Gift[1].icon
			--SeventhFestivalPrizePreview_Client:SetText(strTitle)
			SeventhFestivalPrizePreview_Pic:SetProperty("Image",strIcon)--显示指定图片
		else		
			if iS_R == 1 then -- 送
				local strIcon = g_SeventhFestivalPrizePreview_Gift[2].icon
				--SeventhFestivalPrizePreview_Client:SetText(strTitle)
				SeventhFestivalPrizePreview_Pic:SetProperty("Image",strIcon)--显示指定图片
			elseif iS_R == 2 then --收
				local strIcon = g_SeventhFestivalPrizePreview_Gift[3].icon
				--SeventhFestivalPrizePreview_Client:SetText(strTitle)
				SeventhFestivalPrizePreview_Pic:SetProperty("Image",strIcon)--显示指定图片
			end
		end
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		SeventhFestivalPrizePreview_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		SeventhFestivalPrizePreview_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		SeventhFestivalPrizePreview_OnHiden()
	end
end

function SeventhFestivalPrizePreview_ResetPos()
		SeventhFestivalPrizePreview_Frame:SetProperty("UnifiedPosition",g_SeventhFestivalPrizePreview_UnifiedPosition)
end

function SeventhFestivalPrizePreview_OnHiden()
	g_SeventhFestivalPrizePreview_CurIndex = 0
	g_SeventhFestivalPrizePreview_CurPage = 0
	this:Hide()
end