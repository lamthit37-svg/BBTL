-- T300宋辽 比赛开始、结束提示界面

-- 界面自动关闭时间
local SongliaoKuafu_Quest_LiveTime = 20000
-- 副本场景资源id
local SongliaoKuafu_Quest_LocalSceneId = 548
-- 保存UI默认位置
local SongliaoKuafu_Quest_UnifiedPosition = nil


function SongliaoKuafu_Quest_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func SongliaoKuafu_Quest_PreLoad()

function SongliaoKuafu_Quest_OnLoad()
    SongliaoKuafu_Quest_UnifiedPosition = SongliaoKuafu_Quest_Frame:GetProperty("UnifiedPosition")
end -- end func SongliaoKuafu_Quest_OnLoad()

function SongliaoKuafu_Quest_OnEvent(event)
    if (event == "UI_COMMAND") then
        if (tonumber(arg0) == 5020112) then
            SongliaoKuafu_Quest_Show()
            SongliaoKuafu_Quest_ShowMessage()
        end
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        local nLocalScene = CSongliaoWarData:TSLGetLocalSceneID()
        if (nLocalScene ~= SongliaoKuafu_Quest_LocalSceneId) then
            SongliaoKuafu_Quest_Hide()
        end
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        SongliaoKuafu_Quest_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        SongliaoKuafu_Quest_UnifiedPos()
    end
end -- end func SongliaoKuafu_Quest_OnEvent()

-- 界面默认位置
function SongliaoKuafu_Quest_UnifiedPos()
    if (this:IsVisible()) then
        if (SongliaoKuafu_Quest_UnifiedPosition ~= nil) then
            SongliaoKuafu_Quest_Frame:SetProperty("UnifiedPosition", SongliaoKuafu_Quest_UnifiedPosition)
        end
    end
end -- end func SongliaoKuafu_Quest_UnifiedPos()

function SongliaoKuafu_Quest_Show()
    if (not this:IsVisible()) then
        this:Show()
        SongliaoKuafu_Quest_Help:Hide()

        --SetTimer("SongliaoKuafu_Quest", "SongliaoKuafu_Quest_OnTimer()", SongliaoKuafu_Quest_LiveTime)
    end
end -- end func SongliaoKuafu_Quest_Show()

function SongliaoKuafu_Quest_Hide()
    this:Hide()

    --KillTimer("SongliaoKuafu_Quest_OnTimer()")
end -- end func SongliaoKuafu_Quest_Hide()

-- 定时器事件
function SongliaoKuafu_Quest_OnTimer()
    -- 到时关闭
    SongliaoKuafu_Quest_Hide()
end -- end func SongliaoKuafu_Quest_OnTimer()

function SongliaoKuafu_Quest_OnMoved()
end -- end func SongliaoKuafu_Quest_OnMoved()

function SongliaoKuafu_Quest_OnHidden()
    SongliaoKuafu_Quest_Hide()
end -- end func SongliaoKuafu_Quest_OnHidden()

function SongliaoKuafu_QuestRefuse_Clicked()
    SongliaoKuafu_Quest_Hide()
end -- end func SongliaoKuafu_QuestRefuse_Clicked()

function SongliaoKuafu_QuestAccept_Clicked()
    SongliaoKuafu_Quest_Hide()
end -- end func SongliaoKuafu_QuestAccept_Clicked()

function SongliaoKuafu_MissionContinue_Clicked()
    SongliaoKuafu_Quest_Hide()
end -- end func SongliaoKuafu_MissionContinue_Clicked()

-- 显示信息
function SongliaoKuafu_Quest_ShowMessage()
    SongliaoKuafu_QuestGreeting_Desc:ClearAllElement()

    SongliaoKuafu_Quest_Button_Accept:Disable()
	SongliaoKuafu_Quest_Button_Continue:Disable()
	SongliaoKuafu_Quest_Button_Refuse:SetText("再见")
    SongliaoKuafu_Quest_Frame_Debug:SetText(" ")
    
	local tipmsg = Get_XParam_STR(0)
	SongliaoKuafu_QuestGreeting_Desc:AddTextElement(tipmsg)
end -- end func SongliaoKuafu_Quest_ShowMessage()