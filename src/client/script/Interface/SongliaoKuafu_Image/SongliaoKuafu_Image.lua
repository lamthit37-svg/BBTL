-- T300宋辽 比赛开始、结束提示界面

-- 界面自动关闭时间
local SongliaoKuafu_Image_LiveTime = 3000
-- 类型（开始、结束、胜利）
local SongliaoKuafu_Image_ResulType = -1
local SongliaoKuafu_Image_ServerScriptId = 502011

-- 保存UI默认位置
local SongliaoKuafu_Image_UnifiedPosition = nil

local SongliaoKuafu_Image_TipType =
{
    Begin = 1,      -- 开始
    End = 2,        -- 结束
    Win = 11,       -- 胜利
    Lose = 12,      -- 失败
    Draw = 13,      -- 平局
} -- end SongliaoKuafu_Image_Type

function SongliaoKuafu_Image_PreLoad()
    this:RegisterEvent("TSL_BATTLEBEGIN", true)
    this:RegisterEvent("TSL_BATTLEEND", true)
    this:RegisterEvent("TSL_BATTLERESULT", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func SongliaoKuafu_Image_PreLoad()

function SongliaoKuafu_Image_OnLoad()
    SongliaoKuafu_Image_UnifiedPosition = SongliaoKuafu_Image_Frame:GetProperty("UnifiedPosition")
end -- end func SongliaoKuafu_Image_OnLoad()

function SongliaoKuafu_Image_OnEvent(event)
    if (event == "TSL_BATTLEBEGIN") then
        -- 比赛开始
        SongliaoKuafu_Image_ResulType = SongliaoKuafu_Image_TipType.Begin

        SongliaoKuafu_Image_Show()
        SongliaoKuafu_Image_ShowResult()
    elseif (event == "TSL_BATTLEEND") then
        -- 比赛结束
        SongliaoKuafu_Image_ResulType = SongliaoKuafu_Image_TipType.End

        SongliaoKuafu_Image_Show()
        SongliaoKuafu_Image_ShowResult()
    elseif (event == "TSL_BATTLERESULT") then
        -- 比赛结果
        local result = tonumber(arg0)
        if (result > 0) then
            -- 胜利
            SongliaoKuafu_Image_ResulType = SongliaoKuafu_Image_TipType.Win
        elseif (result == 0) then
            -- 平局
            SongliaoKuafu_Image_ResulType = SongliaoKuafu_Image_TipType.Draw
        else
            -- 失败
            SongliaoKuafu_Image_ResulType = SongliaoKuafu_Image_TipType.Lose
        end

        SongliaoKuafu_Image_Show()
        SongliaoKuafu_Image_ShowResult()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        SongliaoKuafu_Image_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        SongliaoKuafu_Image_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        SongliaoKuafu_Image_UnifiedPos()
    end
end -- end func SongliaoKuafu_Image_OnEvent()

-- 界面默认位置
function SongliaoKuafu_Image_UnifiedPos()
    if (this:IsVisible()) then
        if (SongliaoKuafu_Image_UnifiedPosition ~= nil) then
            SongliaoKuafu_Image_Frame:SetProperty("UnifiedPosition", SongliaoKuafu_Image_UnifiedPosition)
        end
    end
end -- end func SongliaoKuafu_Image_UnifiedPos()

function SongliaoKuafu_Image_Show()
    if (not this:IsVisible()) then
        this:Show()

        SetTimer("SongliaoKuafu_Image", "SongliaoKuafu_Image_OnTimer()", SongliaoKuafu_Image_LiveTime)
    end
end -- end func SongliaoKuafu_Image_Show()

function SongliaoKuafu_Image_Hide()
    this:Hide()

    KillTimer("SongliaoKuafu_Image_OnTimer()")
end -- end func SongliaoKuafu_Image_Hide()

-- 定时器事件
function SongliaoKuafu_Image_OnTimer()
    -- 到时关闭
    SongliaoKuafu_Image_Hide()

    if (SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.Win or
        SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.Draw or
        SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.Lose) then
            -- 请求排行榜数据 打开结算界面
            Clear_XSCRIPT()
                Set_XSCRIPT_Function_Name("SyncRankList")
                Set_XSCRIPT_ScriptID(SongliaoKuafu_Image_ServerScriptId)
                Set_XSCRIPT_ParamCount(0)
            Send_XSCRIPT()
    end
end -- end func SongliaoKuafu_Image_OnTimer()

function SongliaoKuafu_Image_ShowResult()
    if (SongliaoKuafu_Image_ResulType <= 0) then
        SongliaoKuafu_Image_Hide()
    end

    if (SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.Begin) then
        -- 开始
        SongliaoKuafu_Image_Start:Show()
        SongliaoKuafu_Image_Win1:Hide()
        SongliaoKuafu_Image_Win2:Hide()
        SongliaoKuafu_Image_End:Hide()
        SongliaoKuafu_Image_Fail:Hide()
    elseif (SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.End) then
        -- 结束
        SongliaoKuafu_Image_Start:Hide()
        SongliaoKuafu_Image_Win1:Hide()
        SongliaoKuafu_Image_Win2:Hide()
        SongliaoKuafu_Image_End:Show()
        SongliaoKuafu_Image_Fail:Hide()
    elseif (SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.Win) then
        -- 胜利
        SongliaoKuafu_Image_Start:Hide()
        SongliaoKuafu_Image_Win1:Show()
        SongliaoKuafu_Image_Win2:Hide()
        SongliaoKuafu_Image_End:Hide()
        SongliaoKuafu_Image_Fail:Hide()
    elseif (SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.Lose) then
        -- 失败
        SongliaoKuafu_Image_Start:Hide()
        SongliaoKuafu_Image_Win1:Hide()
        SongliaoKuafu_Image_Win2:Hide()
        SongliaoKuafu_Image_End:Hide()
        SongliaoKuafu_Image_Fail:Show()
    elseif (SongliaoKuafu_Image_ResulType == SongliaoKuafu_Image_TipType.Draw) then
        -- 平局
        SongliaoKuafu_Image_Start:Hide()
        SongliaoKuafu_Image_Win1:Hide()
        SongliaoKuafu_Image_Win2:Show()
        SongliaoKuafu_Image_End:Hide()
        SongliaoKuafu_Image_Fail:Hide()
    end
end -- end func SongliaoKuafu_Image_ShowResult()