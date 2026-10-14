----------------------
-- YuanXiao_Shop_Preview ---
----------------------
local g_YuanXiao_Shop_Preview_UnifiedPosition = nil
local g_YuanXiao_Shop_Preview_CurPage = 0

--礼盒信息
local g_YuanXiao_Shop_Preview_Gift =
{
	[1] = {title = "#{MHSD_191203_55}", icon = "set:Spring29 image:ShangYuanQingJiaJing"}, --特殊时装宝石（腰）（肩）（脚）的预览
	[2] = {title = "#{MHSD_191203_54}", icon = "set:Spring30 image:WuYeXiYouJiang"}, --天马的预览
}

function YuanXiao_Shop_Preview_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function YuanXiao_Shop_Preview_OnLoad()
	g_YuanXiao_Shop_Preview_UnifiedPosition = YuanXiao_Shop_Preview:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function YuanXiao_Shop_Preview_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89071312) then
		local ipage = tonumber(arg1)		
		if ipage == nil or g_YuanXiao_Shop_Preview_Gift[ipage] == nil then
			return
		end
		
		if this:IsVisible() then
			if g_YuanXiao_Shop_Preview_CurPage == ipage then
				YuanXiao_Shop_Preview_OnHiden()
				return
			end
		end
		
		g_YuanXiao_Shop_Preview_CurPage = ipage
		local strTitle = g_YuanXiao_Shop_Preview_Gift[ipage].title
		local strIcon = g_YuanXiao_Shop_Preview_Gift[ipage].icon
		--YuanXiao_Shop_Preview_DragTitle:SetText(strTitle)
		YuanXiao_Shop_Preview_FrameImage:SetProperty("Image", strIcon)--显示指定图片
		
		this:Show()
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
	
		YuanXiao_Shop_Preview_ResetPos()
		
	elseif(event == "ADJEST_UI_POS") then
	
		YuanXiao_Shop_Preview_ResetPos()
		
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
	
		YuanXiao_Shop_Preview_OnHiden()
		
	end
end

function YuanXiao_Shop_Preview_ResetPos()

	YuanXiao_Shop_Preview:SetProperty("UnifiedPosition", g_YuanXiao_Shop_Preview_UnifiedPosition)
	
end

function YuanXiao_Shop_Preview_OnHiden()

	g_YuanXiao_Shop_Preview_CurPage = 0
	
	this:Hide()
	
end

function YuanXiao_Shop_Preview_Close()

	YuanXiao_Shop_Preview_OnHiden()
	
end
