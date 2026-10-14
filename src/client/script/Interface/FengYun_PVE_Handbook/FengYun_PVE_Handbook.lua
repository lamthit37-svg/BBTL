-- 风云联动 指南展示UI
local FengYun_PVE_Handbook_MaxPageNum = 0
local FengYun_PVE_Handbook_CurPage = 0
-- 默认位置
local FengYun_PVE_Handbook_UnifiedPosition = nil

-- 指南图片列表
local FengYun_PVE_Handbook_PageImageList =
{
    [1] = "set:FengYun_PVE4 image:FengYun_PVE_Handbook_1",
    [2] = "set:FengYun_PVE5 image:FengYun_PVE_Handbook_2",
    [3] = "set:FengYun_PVE5 image:FengYun_PVE_Handbook_3",
    [4] = "set:FengYun_PVE6 image:FengYun_PVE_Handbook_4",
    [5] = "set:FengYun_PVE6 image:FengYun_PVE_Handbook_5",
} -- end local FengYun_PVE_Handbook_PageImageList



function FengYun_PVE_Handbook_PreLoad()
	this:RegisterEvent("FYPVE_OPENHANDBOOK", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func FengYun_PVE_Handbook_PreLoad()

function FengYun_PVE_Handbook_OnEvent(event)
    if (event == "FYPVE_OPENHANDBOOK") then
        FengYun_PVE_Handbook_InitPageInfo()
		FengYun_PVE_Handbook_UpdateInfo()
		FengYun_PVE_Handbook_Show()
    elseif (event == "PLAYER_LEAVE_WORLD") then
		FengYun_PVE_Handbook_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_PVE_Handbook_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		FengYun_PVE_Handbook_UnifiedPos()
	end
end -- end func FengYun_PVE_Handbook_OnEvent()

function FengYun_PVE_Handbook_OnLoad()
	FengYun_PVE_Handbook_UnifiedPosition = FengYun_PVE_Handbook_Frame:GetProperty("UnifiedPosition")
end -- end func FengYun_PVE_Handbook_OnLoad()

-- 界面默认位置
function FengYun_PVE_Handbook_UnifiedPos()
	if (FengYun_PVE_Handbook_UnifiedPosition ~= nil) then
		FengYun_PVE_Handbook_Frame:SetProperty("UnifiedPosition", FengYun_PVE_Handbook_UnifiedPosition)
	end
end -- end func FengYun_PVE_Handbook_UnifiedPos()

function FengYun_PVE_Handbook_Show()
    this:Show()
end -- end func FengYun_PVE_Handbook_Show()

function FengYun_PVE_Handbook_Hide()
    this:Hide()
end -- end func FengYun_PVE_Handbook_Hide()

--*************************************************************************************************
--
--*************************************************************************************************

-- 关闭按钮点击事件
function FengYun_PVE_Handbook_OnClose()
	FengYun_PVE_Handbook_Hide()
end -- end func FengYun_PVE_Handbook_OnClose()

-- 上一页按钮点击事件
function FengYun_PVE_Handbook_Page_Left()
    if (FengYun_PVE_Handbook_MaxPageNum <= 0) then
        return
    end

    if (FengYun_PVE_Handbook_CurPage == 1) then
        return
    end

    FengYun_PVE_Handbook_CurPage = FengYun_PVE_Handbook_CurPage - 1
    if (FengYun_PVE_Handbook_CurPage < 1) then
        FengYun_PVE_Handbook_CurPage = 1
    end

    FengYun_PVE_Handbook_UpdateInfo()
end -- end func FengYun_PVE_Handbook_Page_Left()

-- 下一页按钮点击事件
function FengYun_PVE_Handbook_Page_Right()
    if (FengYun_PVE_Handbook_MaxPageNum <= 0) then
        return
    end

    if (FengYun_PVE_Handbook_CurPage == FengYun_PVE_Handbook_MaxPageNum) then
        return
    end

    FengYun_PVE_Handbook_CurPage = FengYun_PVE_Handbook_CurPage + 1
    if (FengYun_PVE_Handbook_CurPage > FengYun_PVE_Handbook_MaxPageNum) then
        FengYun_PVE_Handbook_CurPage = FengYun_PVE_Handbook_MaxPageNum
    end

    FengYun_PVE_Handbook_UpdateInfo()
end -- end func FengYun_PVE_Handbook_Page_Right()

--*************************************************************************************************
--
--*************************************************************************************************

function FengYun_PVE_Handbook_InitPageInfo()
    if (FengYun_PVE_Handbook_PageImageList == nil) then
        FengYun_PVE_Handbook_MaxPageNum = 0
        FengYun_PVE_Handbook_CurPage = 0
        return
    end

    if (FengYun_PVE_Handbook_MaxPageNum <= 0) then
        FengYun_PVE_Handbook_MaxPageNum = table.getn(FengYun_PVE_Handbook_PageImageList)
    end

    if (FengYun_PVE_Handbook_CurPage <= 0) then
        FengYun_PVE_Handbook_CurPage = 1
    elseif (FengYun_PVE_Handbook_CurPage > FengYun_PVE_Handbook_MaxPageNum) then
        FengYun_PVE_Handbook_CurPage = FengYun_PVE_Handbook_MaxPageNum
    end
end -- end func FengYun_PVE_Handbook_InitPageInfo()

-- 指南信息
function FengYun_PVE_Handbook_UpdateInfo()
    if (FengYun_PVE_Handbook_MaxPageNum <= 0) then
        return
    end

    FengYun_PVE_Handbook_LeftArrow:Enable()
    FengYun_PVE_Handbook_RightArrow:Enable()
    if (FengYun_PVE_Handbook_CurPage <= 1) then
        FengYun_PVE_Handbook_LeftArrow:Disable()
    elseif (FengYun_PVE_Handbook_CurPage >= FengYun_PVE_Handbook_MaxPageNum) then
        FengYun_PVE_Handbook_RightArrow:Disable()
    end

    local imageInfo = FengYun_PVE_Handbook_PageImageList[FengYun_PVE_Handbook_CurPage]
    if (imageInfo ~= nil) then
        FengYun_PVE_Handbook_Image:SetProperty("Image", imageInfo)
    else
        FengYun_PVE_Handbook_Image:SetProperty("Image", "")
    end
end -- end func FengYun_PVE_Handbook_UpdateItemInfo()