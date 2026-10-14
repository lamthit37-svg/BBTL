-- T300 新天外 普通战场夺旗 倒计时

-- 帮会图标
local T3MatchTimeDup_GuildIcon =
{
    [1] = 38004096,
    [2] = 38004095,
    [3] = 38004094,
} -- end T3MatchTimeDup_GuildIcon
-- 保存UI默认位置
local T3MatchTimeDup_UnifiedPosition = nil
-- 阵营以及未占领底图
local T3MatchTimeDup_Image =
{
    [0] = "set:T3ZhengBaSai3  image:UnNamed",     -- 未占领
    [1] = "set:T3ZhengBaSai3 image:Feng",        -- 阵营 凤山军
    [2] = "set:T3ZhengBaSai3 image:Long",        -- 阵营 龙江军
    [3] = "set:T3ZhengBaSai3 image:Song",        -- 阵营 松林军
} -- end T3MatchTimeDup_Image

function T3MatchTimeDup_PreLoad()
    --this:RegisterEvent("NORMAL_DATA_MATCHCOUNTDOWN", true)-- 比赛倒计时UI挪到T3TopList中了 这里注释掉 不需要了
    this:RegisterEvent("NORMAL_DATA_FLAGCOUNTDOWN", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
    this:RegisterEvent("TDOMAIN20S_DATA_FINISH", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func T3MatchTimeDup_PreLoad()

function T3MatchTimeDup_OnLoad()
	T3MatchTimeDup_UnifiedPosition = T3MatchTimeDup_Frame:GetProperty("UnifiedPosition")
end -- end func T3MatchTimeDup_OnLoad()

function T3MatchTimeDup_OnEvent(event)
    if (event == "NORMAL_DATA_MATCHCOUNTDOWN") then
        -- 比赛倒计时UI挪到T3TopList中了 这里注释掉 不需要了
        --T3MatchTimeDup_UpdateMatchCountdown(arg0)
    elseif (event == "NORMAL_DATA_FLAGCOUNTDOWN") then
        T3MatchTimeDup_UpdateFlagCountdown(arg0, arg1, arg2)
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        T3MatchTimeDup_Hide()
    elseif (event == "TDOMAIN20S_DATA_FINISH") then
        T3MatchTimeDup_UpdateMatchFinish()    
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        T3MatchTimeDup_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        T3MatchTimeDup_UnifiedPos()
    end
end -- end func T3MatchTimeDup_OnEvent()

-- 界面默认位置
function T3MatchTimeDup_UnifiedPos()
    if (this:IsVisible()) then
        if (T3MatchTimeDup_UnifiedPosition ~= nil) then
            T3MatchTimeDup_Frame:SetProperty("UnifiedPosition", T3MatchTimeDup_UnifiedPosition)
        end
    end
end -- end func T3MatchTimeDup_UnifiedPos()

-- 打开界面
function T3MatchTimeDup_Show()
    this:Show()


end -- end func T3MatchTimeDup_Show()

-- 显示战旗倒计时
function T3MatchTimeDup_Show_FlagCountdown()

end -- end func T3MatchTimeDup_Show_FlagCountdown()

-- 关闭战旗倒计时显示
function T3MatchTimeDup_Hide_FlagCountdown()

end -- end func T3MatchTimeDup_Hide_FlagCountdown()

-- 关闭界面
function T3MatchTimeDup_Hide()
	this:Hide()
end -- end func T3MatchTimeDup_Hide()

-- 比赛倒计时UI挪到T3TopList中了 这里注释掉 不需要了
-- 刷新比赛倒计时
-- function T3MatchTimeDup_UpdateMatchCountdown(matchCountdown)
--     if (not this:IsVisible()) then
--         T3MatchTimeDup_Show()
--     end

--     -- 计算比赛倒计时时间（服务器传过来的是秒 解析成分：秒形式）
--     local matchCountdownMin = math.floor(tonumber(matchCountdown) / 60)
--     local strMatchCountdownMin = ""
--     if (matchCountdownMin < 0) then
--         strMatchCountdownMin = "00"
--     elseif (matchCountdownMin >= 0 and matchCountdownMin < 10) then
--         strMatchCountdownMin = string.format("0%d", matchCountdownMin)
--     elseif (matchCountdownMin >= 10 and matchCountdownMin < 60) then
--         strMatchCountdownMin = string.format("%d", matchCountdownMin)
--     else
--         strMatchCountdownMin = "59"
--     end

--     local matchCountdownSec = math.mod(tonumber(matchCountdown), 60)
--     local strMatchCountdownSec = ""
--     if (matchCountdownSec < 0) then
--         strMatchCountdownSec = "00"
--     elseif (matchCountdownSec >= 0 and matchCountdownSec < 10) then
--         strMatchCountdownSec = string.format("0%d", matchCountdownSec)
--     elseif (matchCountdownSec >= 10 and matchCountdownSec < 60) then
--         strMatchCountdownSec = string.format("%d", matchCountdownSec)
--     else
--         strMatchCountdownSec = "59"
--     end
    
--     local strMatchCountdown = strMatchCountdownMin .. ":" .. strMatchCountdownSec
--     -- 设置比赛倒计时时间

--     T3MatchTimeDup_Time1:SetText(strMatchCountdown)
-- end -- end func T3MatchTimeDup_UpdateMatchCountdown()

-- 刷新中心战旗倒计时
function T3MatchTimeDup_UpdateFlagCountdown(guildId, worldId, flagCountdown)

    if (not this:IsVisible()) then
        T3MatchTimeDup_Show()
    end

    if (tonumber(flagCountdown) < 0) then
        -- 应该是战旗没有被占领 不显示战旗倒计时
        if (T3MatchTimeDup_Image[0] ~= nil) then
            T3MatchTimeDup_TextPic1:SetProperty("Image", T3MatchTimeDup_Image[0])
        end
        T3MatchTimeDup_Text2:SetText("#{JLDQZ_200814_162}")
        T3MatchTimeDup_Text2:Show()

        T3MatchTimeDup_Time2:Hide()
        ----T3MatchTimeDup_CapPic1:Hide()
        T3MatchTimeDup_Victory:Hide()
    else

        local guildIndex = T20DomainServerUI:GetGuildIndex(tonumber(guildId), tonumber(worldId))
        if (guildIndex ~= nil and guildIndex > 0) then
            if (T3MatchTimeDup_Image[guildIndex] ~= nil) then
                T3MatchTimeDup_TextPic1:SetProperty("Image", T3MatchTimeDup_Image[guildIndex])
            end
            T3MatchTimeDup_Time2:Show()
            --T3MatchTimeDup_CapPic1:Show()
        end

        local guildName = T20DomainServerUI:GetGuildNameByWorldID(tonumber(guildId), tonumber(worldId))

        if (guildName ~= nil) then
            T3MatchTimeDup_Text2:SetText(guildName)
            T3MatchTimeDup_Text2:Show()
        end

        -- 计算比赛倒计时时间（服务器传过来的是秒 解析成分：秒形式）
        local flagCountdownMin = math.floor(tonumber(flagCountdown) / 60)
        local strFlagCountdownMin = ""
        if (flagCountdownMin < 0) then
            strFlagCountdownMin = "00"
        elseif (flagCountdownMin >= 0 and flagCountdownMin < 10) then
            strFlagCountdownMin = string.format("0%d", flagCountdownMin)
        elseif (flagCountdownMin >= 10 and flagCountdownMin < 60) then
            strFlagCountdownMin = string.format("%d", flagCountdownMin)
        else
            strFlagCountdownMin = "59"
        end

        local flagCountdownSec = math.mod(tonumber(flagCountdown), 60)
        local strFlagCountdownSec = ""
        if (flagCountdownSec < 0) then
            strFlagCountdownSec = "00"
        elseif (flagCountdownSec >= 0 and flagCountdownSec < 10) then
            strFlagCountdownSec = string.format("0%d", flagCountdownSec)
        elseif (flagCountdownSec >= 10 and flagCountdownSec < 60) then
            strFlagCountdownSec = string.format("%d", flagCountdownSec)
        else
            strFlagCountdownSec = "59"
        end

        local strFlagCountdown = strFlagCountdownMin .. ":" .. strFlagCountdownSec

        -- 设置比赛倒计时时间
        T3MatchTimeDup_Time2:SetText(strFlagCountdown)
        T3MatchTimeDup_Time2:Show()
        T3MatchTimeDup_Victory:Hide()
    end
end -- end func T3MatchTimeDup_UpdateFlagCountdown()



-- 刷新比赛结束提示
function T3MatchTimeDup_UpdateMatchFinish()

    T3MatchTimeDup_TextPic1:Show()
    T3MatchTimeDup_Text2:Show()
    T3MatchTimeDup_Time2:Hide()

    -- 获取获胜帮会信息
    local nResult, winGuildId, winGuildWorldId, winGuildIndex = T20DomainServerUI:GetMemRecordResult()
    if (winGuildId < 0) then
        -- 无帮会获胜
        T3MatchTimeDup_TextPic1:SetImage(T3MatchTimeDup_Image[0])
        T3MatchTimeDup_Text2:SetText("#{JLDQZ_200814_162}")

        ----T3MatchTimeDup_CapPic1:Hide()
    else
        if (T3MatchTimeDup_Image[winGuildIndex] ~= nil) then
            T3MatchTimeDup_TextPic1:SetProperty("Image", T3MatchTimeDup_Image[winGuildIndex])
        else
            T3MatchTimeDup_TextPic1:Hide()
        end
        -- 有帮会获胜
        local guildName = T20DomainServerUI:GetGuildNameByWorldID(tonumber(winGuildId), tonumber(winGuildWorldId))
        if (guildName ~= nil) then
            ----T3MatchTimeDup_CapPic1:Show()
            T3MatchTimeDup_Text2:SetText(guildName)
            T3MatchTimeDup_Victory:Show()

        else
            T3MatchTimeDup_Text2:Hide()

        end

    end
end -- end func T3MatchTimeDupUpdateMatchFinish()