-- QIXIPVE 指南展示UI
local g_ui_commonid = 05123804
local QiXi_PVE_Handbook_MaxPageNum = 0
local QiXi_PVE_Handbook_CurPage = 0
-- 默认位置
local QiXi_PVE_Handbook_UnifiedPosition = nil

-- 指南图片列表
local QiXi_PVE_Handbook_PageImageList =
{
    "set:QiXi_PVE5 image:QiXi_PVE_Handbook1_1",
    "set:QiXi_PVE5 image:QiXi_PVE_Handbook1_2",

    "set:QiXi_PVE6 image:QiXi_PVE_Handbook1_3",
    "set:QiXi_PVE6 image:QiXi_PVE_Handbook1_4",

    "set:QiXi_PVE7 image:QiXi_PVE_Handbook2_1",
    "set:QiXi_PVE7 image:QiXi_PVE_Handbook2_2",

    "set:QiXi_PVE8 image:QiXi_PVE_Handbook2_3",
    "set:QiXi_PVE8 image:QiXi_PVE_Handbook3_1",

    "set:QiXi_PVE9 image:QiXi_PVE_Handbook3_2",
    "set:QiXi_PVE9 image:QiXi_PVE_Handbook3_3",

    "set:QiXi_PVE10 image:QiXi_PVE_Handbook4_1",
    "set:QiXi_PVE10 image:QiXi_PVE_Handbook4_2",

} -- end local QiXi_PVE_Handbook_PageImageList



function QiXi_PVE_Handbook_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func QiXi_PVE_Handbook_PreLoad()

function QiXi_PVE_Handbook_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_ui_commonid then
        local opt = Get_XParam_INT( 0 )
        if opt == 0 then
            QiXi_PVE_Handbook_OnClose()
        elseif  opt == 1 then
            QiXi_PVE_Handbook_InitPageInfo()
            QiXi_PVE_Handbook_UpdateInfo()
            QiXi_PVE_Handbook_Show()
        end
    elseif (event == "PLAYER_LEAVE_WORLD") then
		QiXi_PVE_Handbook_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QiXi_PVE_Handbook_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		QiXi_PVE_Handbook_UnifiedPos()
	end
end -- end func QiXi_PVE_Handbook_OnEvent()

function QiXi_PVE_Handbook_OnLoad()
	QiXi_PVE_Handbook_UnifiedPosition = QiXi_PVE_Handbook_Frame:GetProperty("UnifiedPosition")
end -- end func QiXi_PVE_Handbook_OnLoad()

-- 界面默认位置
function QiXi_PVE_Handbook_UnifiedPos()
	if (QiXi_PVE_Handbook_UnifiedPosition ~= nil) then
		QiXi_PVE_Handbook_Frame:SetProperty("UnifiedPosition", QiXi_PVE_Handbook_UnifiedPosition)
	end
end -- end func QiXi_PVE_Handbook_UnifiedPos()

function QiXi_PVE_Handbook_Show()
    this:Show()
end -- end func QiXi_PVE_Handbook_Show()

function QiXi_PVE_Handbook_Hide()
    this:Hide()
end -- end func QiXi_PVE_Handbook_Hide()

--*************************************************************************************************
--
--*************************************************************************************************

-- 关闭按钮点击事件
function QiXi_PVE_Handbook_OnClose()
	QiXi_PVE_Handbook_Hide()
end -- end func QiXi_PVE_Handbook_OnClose()

-- 上一页按钮点击事件
function QiXi_PVE_Handbook_Page_Left()
    if (QiXi_PVE_Handbook_MaxPageNum <= 0) then
        return
    end

    if (QiXi_PVE_Handbook_CurPage == 1) then
        return
    end

    QiXi_PVE_Handbook_CurPage = QiXi_PVE_Handbook_CurPage - 1
    if (QiXi_PVE_Handbook_CurPage < 1) then
        QiXi_PVE_Handbook_CurPage = 1
    end

    QiXi_PVE_Handbook_UpdateInfo()
end -- end func QiXi_PVE_Handbook_Page_Left()

-- 下一页按钮点击事件
function QiXi_PVE_Handbook_Page_Right()
    if (QiXi_PVE_Handbook_MaxPageNum <= 0) then
        return
    end

    if (QiXi_PVE_Handbook_CurPage == QiXi_PVE_Handbook_MaxPageNum) then
        return
    end

    QiXi_PVE_Handbook_CurPage = QiXi_PVE_Handbook_CurPage + 1
    if (QiXi_PVE_Handbook_CurPage > QiXi_PVE_Handbook_MaxPageNum) then
        QiXi_PVE_Handbook_CurPage = QiXi_PVE_Handbook_MaxPageNum
    end

    QiXi_PVE_Handbook_UpdateInfo()
end -- end func QiXi_PVE_Handbook_Page_Right()

--*************************************************************************************************
--
--*************************************************************************************************

function QiXi_PVE_Handbook_InitPageInfo()
    if (QiXi_PVE_Handbook_PageImageList == nil) then
        QiXi_PVE_Handbook_MaxPageNum = 0
        QiXi_PVE_Handbook_CurPage = 0
        return
    end

    if (QiXi_PVE_Handbook_MaxPageNum <= 0) then
        QiXi_PVE_Handbook_MaxPageNum = table.getn(QiXi_PVE_Handbook_PageImageList)
    end

    if (QiXi_PVE_Handbook_CurPage <= 0) then
        QiXi_PVE_Handbook_CurPage = 1
    elseif (QiXi_PVE_Handbook_CurPage > QiXi_PVE_Handbook_MaxPageNum) then
        QiXi_PVE_Handbook_CurPage = QiXi_PVE_Handbook_MaxPageNum
    end
end -- end func QiXi_PVE_Handbook_InitPageInfo()

-- 指南信息
function QiXi_PVE_Handbook_UpdateInfo()
    if (QiXi_PVE_Handbook_MaxPageNum <= 0) then
        return
    end

    QiXi_PVE_Handbook_LeftArrow:Enable()
    QiXi_PVE_Handbook_RightArrow:Enable()
    if (QiXi_PVE_Handbook_CurPage <= 1) then
        QiXi_PVE_Handbook_LeftArrow:Disable()
    elseif (QiXi_PVE_Handbook_CurPage >= QiXi_PVE_Handbook_MaxPageNum) then
        QiXi_PVE_Handbook_RightArrow:Disable()
    end

    local imageInfo = QiXi_PVE_Handbook_PageImageList[QiXi_PVE_Handbook_CurPage]
    if (imageInfo ~= nil) then
        QiXi_PVE_Handbook_Image:SetProperty("Image", imageInfo)
    else
        QiXi_PVE_Handbook_Image:SetProperty("Image", "")
    end
end -- end func QiXi_PVE_Handbook_UpdateItemInfo()