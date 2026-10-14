-- T300 新天外 金陵夺旗 图片提示

-- 图片显示时间(毫秒)
local T3Broadcast_ShowTime = 3000

-- 提示类型
local T3Broadcast_Type =
{
    FirstKill = 1,      -- 首杀
    SerialKill = 2,     -- 连杀
} -- end T3Broadcast_Type

-- 数字图片资源
local T3Broadcast_NumImage =
{
    [0] = "set:T3ZhengBaSai3 image:0",
	[1] = "set:T3ZhengBaSai3 image:1",
	[2] = "set:T3ZhengBaSai3 image:2",
	[3] = "set:T3ZhengBaSai3 image:3",
	[4] = "set:T3ZhengBaSai3 image:4",
	[5] = "set:T3ZhengBaSai3 image:5",
	[6] = "set:T3ZhengBaSai3 image:6",
	[7] = "set:T3ZhengBaSai3 image:7",
	[8] = "set:T3ZhengBaSai3 image:8",
	[9] = "set:T3ZhengBaSai3 image:9",
} -- end T3Broadcast_NumImage

-- 阵营背景图片资源
local T3Broadcast_CampBackImage =
{
	[1] = "set:T3ZhengBaSai3 image:FengShan",
	[2] = "set:T3ZhengBaSai3 image:LongJiang",
	[3] = "set:T3ZhengBaSai3 image:ZongLin",
} -- end T3Broadcast_CampBackImage

-- 保存UI默认位置
local T3Broadcast_UnifiedPosition = nil

-- 消息队列
local T3Broadcast_MessageQuene = nil
--  是否正在显示图片提示
local T3Broadcast_IsProcessing =nil

function T3Broadcast_PreLoad()
    this:RegisterEvent("JLZD_UI_KILLNOTICE", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func T3Broadcast_PreLoad()

function T3Broadcast_OnLoad()
    T3Broadcast_UnifiedPosition = T3Broadcast_Frame:GetProperty("UnifiedPosition")
    T3Broadcast_IsProcessing = 0
end -- end func T3Broadcast_OnLoad()

function T3Broadcast_OnEvent(event)
    if (event == "JLZD_UI_KILLNOTICE") then
        T3Broadcast_AddMessage(tonumber(arg0), tonumber(arg1), tonumber(arg2), arg3, arg4)
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        T3Broadcast_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        T3Broadcast_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        T3Broadcast_UnifiedPos()
    end
end -- end func T3Broadcast_OnEvent()

-- 界面默认位置
function T3Broadcast_UnifiedPos()
    if (this:IsVisible()) then
        if (T3Broadcast_UnifiedPosition ~= nil) then
            T3Broadcast_Frame:SetProperty("UnifiedPosition", T3Broadcast_UnifiedPosition)
        end
    end
end -- end func T3Broadcast_UnifiedPos()

-- 打开界面
function T3Broadcast_Show()
    this:Show()
end -- end func T3Broadcast_Show()

-- 关闭界面
function T3Broadcast_Hide()
    KillTimer("T3Broadcast_MessageLogic()")
    T3Broadcast_MessageQuene = nil
    T3Broadcast_IsProcessing = 0

    this:Hide()
end -- end func T3Broadcast_Hide()

-- 击杀数转换 转换为百位、十位、个位
function T3Broadcast_KillCountConvert(killCount)
    if (killCount <= 0) then
        return 0, 0, 0
    end

    local tensAndOnes = math.mod(killCount, 100)

    -- 百位
    local handreds = math.floor(killCount / 100)
    -- 十位
    local tens = math.floor(tensAndOnes / 10)
    -- 个位
    local ones = math.mod(tensAndOnes, 10)

    return handreds, tens, ones
end -- end func T3Broadcast_KillCountConvert()

-- 弹出提示图片
function T3Broadcast_ShowPic(msgType, killCount, killerCampIndex, killerName, beKilledName)
    -- if (this:IsVisible() == false) then
    --     T3Broadcast_Show()
    -- end

    -- 设置杀人玩家阵营背景
    if (T3Broadcast_CampBackImage[killerCampIndex] ~= nil) then
        T3Broadcast_Player1BK:SetProperty("Image", T3Broadcast_CampBackImage[killerCampIndex])
    else
        T3Broadcast_Player1BK:SetProperty("Image", "")
    end

    -- 设置杀人玩家
    if (killerName ~= nil) then
        T3Broadcast_Player1Text:SetText(tostring(killerName))
    else
        T3Broadcast_Player1Text:SetText(" ")
    end
    -- 需求修改 被杀玩家名字不要了
    --T3Broadcast_Player2Text:SetText(beKilledName)

    if (msgType == T3Broadcast_Type.FirstKill) then
        -- 首杀
        -- 显示首杀图片
        T3Broadcast_SeriesKillBK:Hide()
        T3Broadcast_FirstBloodBK:Show()
    elseif (msgType == T3Broadcast_Type.SerialKill) then
        -- 连杀
        -- 获取击杀数
        local handreds, tens, ones = T3Broadcast_KillCountConvert(killCount)
        -- 设置击杀数图片
        -- 百位
        if (handreds <= 0) then
            T3Broadcast_1BKG:Hide()
        else
            if (T3Broadcast_NumImage[handreds] ~= nil) then
                T3Broadcast_1BKG:SetProperty("Image", T3Broadcast_NumImage[handreds])
                T3Broadcast_1BKG:Show()
            else
                T3Broadcast_1BKG:Hide()
            end
        end
        -- 十位
        if (tens <= 0 and handreds <= 0) then
            T3Broadcast_2BKG:Hide()
        else
            if (T3Broadcast_NumImage[tens] ~= nil) then
                T3Broadcast_2BKG:SetProperty("Image", T3Broadcast_NumImage[tens])
                T3Broadcast_2BKG:Show()
            else
                T3Broadcast_2BKG:Hide()
            end
        end
        --个位
        if (T3Broadcast_NumImage[ones] ~= nil) then
            T3Broadcast_3BKG:SetProperty("Image", T3Broadcast_NumImage[ones])
            T3Broadcast_3BKG:Show()
        else
            T3Broadcast_3BKG:Hide()
        end

        -- 显示击杀图片
        T3Broadcast_FirstBloodBK:Hide()
        T3Broadcast_SeriesKillBK:Show()
    else
        -- 按说不应该到这
    end
end -- end func T3Broadcast_ShowPic()

-- 向消息队列中添加新消息
function T3Broadcast_AddMessage(msgType, killCount, killerCampIndex, killerName, beKilledName)
    if (T3Broadcast_MessageQuene == nil) then
        T3Broadcast_MessageQuene = {}
    end

    -- -- 杀人者和被杀者的角色名可能是带有服务器组号 目前的格式是“@组号角色名” 需要处理一下变成“角色名@组号”
    -- local killer = nil
    -- local pos = string.find(killerName, "@")
    -- if (pos == nil) then
    --     killer = killerName
    -- else
    --     local server = string.sub(killerName, 1, 5)
    --     local name = string.sub(killerName, 6)
    --     killer = name .. server
    -- end

    -- local beKilled = nil
    -- pos = string.find(beKilledName, "@")
    -- if (pos == nil) then
    --     beKilled = beKilledName
    -- else
    --     local server = string.sub(beKilledName, 1, 5)
    --     local name = string.sub(beKilledName, 6)
    --     beKilled = name .. server
    -- end

    -- 目前传过来的名字不带服务器组号 所以这里不需要特殊处理了
    local killer = killerName
    local beKilled = beKilledName

    local msgQueneCount = table.getn(T3Broadcast_MessageQuene)
    T3Broadcast_MessageQuene[msgQueneCount + 1] = {}
    T3Broadcast_MessageQuene[msgQueneCount + 1].msgtype = msgType
    T3Broadcast_MessageQuene[msgQueneCount + 1].killcount = killCount
    T3Broadcast_MessageQuene[msgQueneCount + 1].killercamp = killerCampIndex
    T3Broadcast_MessageQuene[msgQueneCount + 1].killername = killer
    T3Broadcast_MessageQuene[msgQueneCount + 1].bekilledname = beKilled

    -- 如果UI处于show状态 则说明当前正在显示其他的提示信息 等待其他信息显示完毕
    -- 如果UI处于hide状态 则说明这是第一个消息 执行消息逻辑 显示此消息
    -- 这里不能使用IsVisible()判断 貌似这个结果有延迟 如果消息是同一个tick到达这个函数返回值都是一样的
    if (T3Broadcast_IsProcessing == 0) then
        -- 当前UI处于hide状态 应该是第一个消息 直接执行消息逻辑显示此消息
        T3Broadcast_IsProcessing = 1
        T3Broadcast_Show()
        SetTimer("T3Broadcast", "T3Broadcast_MessageLogic()", T3Broadcast_ShowTime)
        T3Broadcast_MessageLogic()
    end
end -- end func T3Broadcast_AddMessage()

-- 从消息队列中删除消息
function T3Broadcast_RemoveMessage(index)
    if (T3Broadcast_MessageQuene[index] ~= nil) then
        T3Broadcast_MessageQuene[index].msgtype = -1
        T3Broadcast_MessageQuene[index].killcount = -1
        T3Broadcast_MessageQuene[index].killercamp = -1
        T3Broadcast_MessageQuene[index].killername = nil
        T3Broadcast_MessageQuene[index].bekilledname = nil
    end
end -- end func T3Broadcast_RemoveMessage()

-- 消息队列逻辑
function T3Broadcast_MessageLogic()
    local msgQueneCount = table.getn(T3Broadcast_MessageQuene)
    if (msgQueneCount < 1) then
        -- 消息队列是空的 直接关闭UI吧
        T3Broadcast_Hide()
        return
    end

    -- 有效消息数量（未显示过的）
    local effectiveMsgCount = 0
    local firstEffectiveMsgIndex = 0
    for i = 1, msgQueneCount, 1 do
        if (T3Broadcast_MessageQuene[i] ~= nil) then
            if (T3Broadcast_MessageQuene[i].msgtype > 0) then
                effectiveMsgCount = effectiveMsgCount + 1
                if (firstEffectiveMsgIndex < 1) then
                    firstEffectiveMsgIndex = i
                end
            end
        end
    end -- end for
    if (effectiveMsgCount < 1) then
        -- 消息都显示完了 关闭UI吧
        T3Broadcast_Hide()
        return
    end
    if (T3Broadcast_MessageQuene[firstEffectiveMsgIndex] == nil) then
        -- 按说不应该到这的 关闭UI吧
        T3Broadcast_Hide()
        return
    end

    if (T3Broadcast_MessageQuene[firstEffectiveMsgIndex].msgtype > 0) then
        T3Broadcast_ShowPic(T3Broadcast_MessageQuene[firstEffectiveMsgIndex].msgtype,
                            T3Broadcast_MessageQuene[firstEffectiveMsgIndex].killcount,
                            T3Broadcast_MessageQuene[firstEffectiveMsgIndex].killercamp,
                            T3Broadcast_MessageQuene[firstEffectiveMsgIndex].killername,
                            T3Broadcast_MessageQuene[firstEffectiveMsgIndex].bekilledname)

        T3Broadcast_RemoveMessage(firstEffectiveMsgIndex)
        return
    end

    -- 按说也不应该到这的 做个保险吧
    T3Broadcast_Hide()
end -- end func T3Broadcast_MessageLogic()