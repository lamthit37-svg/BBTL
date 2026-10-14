--WuShenTan_ShowReward2

function WuShenTan_ShowReward2_PreLoad()
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("OPEN_WST_HUACHE_REWARD")
end

function WuShenTan_ShowReward2_OnLoad()
    g_WuShenTan_ShowReward2_UnifiedPosition = WuShenTan_ShowReward2_Frame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function WuShenTan_ShowReward2_OnEvent(event) 
    if event == "OPEN_WST_HUACHE_REWARD" then
    	if tonumber(arg0) == 2 then
        this:Show ()
      end
    elseif event == "VIEW_RESOLUTION_CHANGED" then
        WuShenTan_ShowReward2_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
    elseif event == "ADJEST_UI_POS" then
        WuShenTan_ShowReward2_On_ResetPos()
    end
end
 
--=========
-- 重置
--=========
function WuShenTan_ShowReward2_On_ResetPos()
    WuShenTan_ShowReward2_Frame:SetProperty("UnifiedPosition", g_WuShenTan_ShowReward2_UnifiedPosition)
end

function WuShenTan_ShowReward2_OnHidden()
end