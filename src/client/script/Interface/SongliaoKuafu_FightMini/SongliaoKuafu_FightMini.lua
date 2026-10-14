-- T300宋辽 比赛信息mini界面

-- 保存UI默认位置
local SongliaoKuafu_FightMini_UnifiedPosition = nil



function SongliaoKuafu_FightMini_PreLoad()
    this:RegisterEvent("TSL_OPENMINI", true)
    this:RegisterEvent("TSL_CLOSEMINI", true)
    this:RegisterEvent("TSL_BATTLEDATA", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func SongliaoKuafu_FightMini_PreLoad()

function SongliaoKuafu_FightMini_OnLoad()
    SongliaoKuafu_FightMini_UnifiedPosition = SongliaoKuafu_FightMini_Frame:GetProperty("UnifiedPosition")
end -- end func SongliaoKuafu_FightMini_OnLoad()

function SongliaoKuafu_FightMini_OnEvent(event)
    if (event == "TSL_OPENMINI") then
        SongliaoKuafu_FightMini_Show()
        SongliaoKuafu_FightMini_UpdateInfo()
    elseif (event == "TSL_CLOSEMINI") then
        SongliaoKuafu_FightMini_Show()
    elseif (event == "TSL_BATTLEDATA") then
        SongliaoKuafu_FightMini_UpdateInfo()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        SongliaoKuafu_FightMini_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        SongliaoKuafu_FightMini_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        SongliaoKuafu_FightMini_UnifiedPos()
    end
end -- end func SongliaoKuafu_FightMini_OnEvent()

-- 界面默认位置
function SongliaoKuafu_FightMini_UnifiedPos()
    if (this:IsVisible()) then
        if (SongliaoKuafu_FightMini_UnifiedPosition ~= nil) then
            SongliaoKuafu_FightMini_Frame:SetProperty("UnifiedPosition", SongliaoKuafu_FightMini_UnifiedPosition)
        end
    end
end -- end func SongliaoKuafu_FightMini_UnifiedPos()

function SongliaoKuafu_FightMini_Show()
    if (not this:IsVisible()) then
        this:Show()
    end
end -- end func SongliaoKuafu_FightMini_Show()

function SongliaoKuafu_FightMini_Hide()
    this:Hide()
end -- end func SongliaoKuafu_FightMini_Hide()

function SongliaoKuafu_FightMini_SmallClicked()
    SongliaoKuafu_FightMini_Hide()

    PushEvent("TSL_OPENFIGHT")
end -- end func SongliaoKuafu_FightMini_SmallClicked()

function SongliaoKuafu_FightMini_UpdateInfo()
    -- 获取战斗数据（倒计时、积分、排名等）
    local timeLeft, myRank, myScore, songScore, liaoScore, winner = CSongliaoWarData:TSLGetBattleData()

    -- 自己的排名
    local rankTips = ScriptGlobal_Format("#{SLDZ_220216_19}", myRank+1)
    SongliaoKuafu_FightMini_Info1:SetText(rankTips)
    -- 自己的积分
    local scoreTips = ScriptGlobal_Format("#{SLDZ_220216_20}", myScore)
    SongliaoKuafu_FightMini_Info2:SetText(scoreTips)
end -- end func SongliaoKuafu_FightMini_UpdateInfo()