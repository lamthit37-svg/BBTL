local g_Frame_UnifiedPosition
local g_Index = 1
local g_Index_Max = 5
local g_Image = {
    [1] = "set:Frozen_PVP image:Frozen_PVPImage4",
    [2] = "set:Frozen_PVP2 image:Frozen_PVPImage5",
    [3] = "set:Frozen_PVP2 image:Frozen_PVPImage6",
    [4] = "set:Frozen_PVP3 image:Frozen_PVPImage7",
    [5] = "set:Frozen_PVP3 image:Frozen_PVPImage8",
}

function Frozen_PVPGuide_PreLoad()
    this:RegisterEvent("UI_COMMAND")
    -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("ADJEST_UI_POS",false)
    -- 游戏分辨率发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("PLAYER_LEAVE_WORLD",false)

end
function Frozen_PVPGuide_OnLoad()
    g_Index = 1
    g_Frame_UnifiedPosition = Frozen_PVPGuide_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPGuide_OnEvent(event)

    if event == "UI_COMMAND" and tonumber(arg0) == 80030604 then
        g_Index = 1
        Frozen_PVPGuide_ImageBk_01:SetProperty("Image",g_Image[g_Index])
        this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_PVPGuide_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_PVPGuide_ResetPos()
    elseif event == "PLAYER_LEAVE_WORLD" then
        this:Hide()
    end
end


function Frozen_PVPGuide_OnClose()
    g_Index = 1
    Frozen_PVPGuide_ImageBk_01:SetProperty("Image",g_Image[g_Index])
    this:Hide()
end

function Frozen_PVPGuide_Page_Left()

    if g_Index <= 1 then
        g_Index = 1
    else
        g_Index = g_Index - 1
    end
    Frozen_PVPGuide_ImageBk_01:SetProperty("Image",g_Image[g_Index])
end

function Frozen_PVPGuide_Page_Right()

    if g_Index >= g_Index_Max then
        g_Index = g_Index_Max
    else
        g_Index = g_Index + 1
    end
    Frozen_PVPGuide_ImageBk_01:SetProperty("Image",g_Image[g_Index])
end


function Frozen_PVPGuide_ResetPos()
	Frozen_PVPGuide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end