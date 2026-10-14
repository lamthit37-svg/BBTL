--丹引药成
--
--
--界面数据

local g_Qixi_HuaJuan_ZoomFrame_UnifiedPosition
local g_UICOMMAND = 99972601
--OnLoad数据
local Qixi_HuaJuan_Zoom_ClientList = {}
function Qixi_HuaJuan_Zoom_PreLoad()
    this:RegisterEvent("OPEN_QIXI_HUAJUAN_ZOOMMODE", true)
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function Qixi_HuaJuan_Zoom_OnLoad()
    g_Qixi_HuaJuan_ZoomFrame_UnifiedPosition = Qixi_HuaJuan_Zoom_Frame:GetProperty("UnifiedPosition")
end

function Qixi_HuaJuan_Zoom_OnHidden()
    this:Hide()
end

function Qixi_HuaJuan_Zoom_Close()
    Qixi_HuaJuan_Zoom_OnHidden()
end

function Qixi_HuaJuan_Zoom_ResetPos()
    Qixi_HuaJuan_Zoom_Frame:SetProperty("UnifiedPosition", g_Qixi_HuaJuan_ZoomFrame_UnifiedPosition)
end

function Qixi_HuaJuan_Zoom_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        this:Show()
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
            event == "VIEW_RESOLUTION_CHANGED" then
            Qixi_HuaJuan_Zoom_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            Qixi_HuaJuan_Zoom_OnHidden()
        end
    end
end