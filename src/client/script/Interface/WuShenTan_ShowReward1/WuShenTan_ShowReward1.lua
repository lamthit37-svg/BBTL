--WuShenTan_ShowReward1

function WuShenTan_ShowReward1_PreLoad()
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("OPEN_WST_HUACHE_REWARD")
end

function WuShenTan_ShowReward1_OnLoad()
    g_WuShenTan_ShowReward1_UnifiedPosition = WuShenTan_ShowReward1_Frame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function WuShenTan_ShowReward1_OnEvent(event) 
    if event == "OPEN_WST_HUACHE_REWARD" then
      if tonumber(arg0) == 1 then
        this:Show ()
      end
    elseif event == "VIEW_RESOLUTION_CHANGED" then
        WuShenTan_ShowReward1_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
    elseif event == "ADJEST_UI_POS" then
        WuShenTan_ShowReward1_On_ResetPos()
    end
end
 
--=========
-- 重置
--=========
function WuShenTan_ShowReward1_On_ResetPos()
    WuShenTan_ShowReward1_Frame:SetProperty("UnifiedPosition", g_WuShenTan_ShowReward1_UnifiedPosition)
end

function WuShenTan_ShowReward1_OnHidden()
end