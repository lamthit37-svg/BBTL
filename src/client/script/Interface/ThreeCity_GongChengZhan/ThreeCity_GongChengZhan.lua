--  图片提示

-- 图片显示时间(毫秒)
local ThreeCity_GongChengZhan_ShowTime = 3000

-- 提示类型
local ThreeCity_GongChengZhan_Type =
{
    FirstKill = 1,      -- 首杀
    SerialKill = 2,     -- 连杀
} -- end ThreeCity_GongChengZhan_Type

-- 数字图片资源
local ThreeCity_GongChengZhan_Image =
{
    [1] = "set:GongChengZhan image:GongChengZhan_Tips01",
	[2] = "set:GongChengZhan image:GongChengZhan_Tips02",
} -- end ThreeCity_GongChengZhan_NumImage

-- 阵营背景图片资源
local ThreeCity_GongChengZhan_CampBackImage =
{
	[1] = "set:T3ZhengBaSai3 image:FengShan",
	[2] = "set:T3ZhengBaSai3 image:LongJiang",
	[3] = "set:T3ZhengBaSai3 image:ZongLin",
} -- end ThreeCity_GongChengZhan_CampBackImage

-- 图片资源
local ThreeCity_GongChengZhan_CityBackImage =
{
	[0] = "set:GongChengZhan image:GongChengZhan_R",
	[1] = "set:GongChengZhan image:GongChengZhan_B",
	[2] = "set:GongChengZhan image:GongChengZhan_Y",
} 

-- 保存UI默认位置
local ThreeCity_GongChengZhan_UnifiedPosition = nil

-- 消息队列
local ThreeCity_GongChengZhan_MessageQuene = nil
--  是否正在显示图片提示
local ThreeCity_GongChengZhan_IsProcessing =nil

function ThreeCity_GongChengZhan_PreLoad()
	this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("JLZD_UI_KILLNOTICE", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func ThreeCity_GongChengZhan_PreLoad()

function ThreeCity_GongChengZhan_OnLoad()
    ThreeCity_GongChengZhan_UnifiedPosition = ThreeCity_GongChengZhan_Frame:GetProperty("UnifiedPosition")
    ThreeCity_GongChengZhan_IsProcessing = 0
end -- end func ThreeCity_GongChengZhan_OnLoad()

function ThreeCity_GongChengZhan_OnEvent(event)
    if (event == "UI_COMMAND") and tonumber(arg0) == 99816304 then
        ThreeCity_GongChengZhan_AddMessage(Get_XParam_INT(0), Get_XParam_STR(0), Get_XParam_STR(1))
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        ThreeCity_GongChengZhan_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        ThreeCity_GongChengZhan_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        ThreeCity_GongChengZhan_UnifiedPos()
    end
end -- end func ThreeCity_GongChengZhan_OnEvent()

-- 界面默认位置
function ThreeCity_GongChengZhan_UnifiedPos()
    if (this:IsVisible()) then
        if (ThreeCity_GongChengZhan_UnifiedPosition ~= nil) then
            ThreeCity_GongChengZhan_Frame:SetProperty("UnifiedPosition", ThreeCity_GongChengZhan_UnifiedPosition)
        end
    end
end -- end func ThreeCity_GongChengZhan_UnifiedPos()

-- 打开界面
function ThreeCity_GongChengZhan_Show()
    this:Show()
end -- end func ThreeCity_GongChengZhan_Show()

-- 关闭界面
function ThreeCity_GongChengZhan_Hide()
    KillTimer("ThreeCity_GongChengZhan_MessageLogic()")
    ThreeCity_GongChengZhan_MessageQuene = nil
    ThreeCity_GongChengZhan_IsProcessing = 0

    this:Hide()
end -- end func ThreeCity_GongChengZhan_Hide()


-- 弹出提示图片
function ThreeCity_GongChengZhan_ShowPic(msgType, strmsg, strname)
 
  if msgType == 0 or msgType == 1 or msgType == 2 then
	--ThreeCity_GongChengZhan_Player1BK:Hide()
	ThreeCity_GongChengZhan_Player1Text:Hide()
	ThreeCity_GongChengZhan_FirstBloodBK:Hide()
	ThreeCity_GongChengZhan_Img:Show()
	ThreeCity_GongChengZhan_Img:SetProperty("Image", ThreeCity_GongChengZhan_CityBackImage[msgType])
	ThreeCity_GongChengZhan_Img_Text:SetText(strmsg)
	ThreeCity_GongChengZhan_EndBK:Hide()
	ThreeCity_GongChengZhan_BH:Show()
	ThreeCity_GongChengZhan_JS:Hide()
  elseif msgType == 3 then
	--ThreeCity_GongChengZhan_Player1BK:Show()
	ThreeCity_GongChengZhan_Player1Text:Show()
	ThreeCity_GongChengZhan_FirstBloodBK:Show()
	ThreeCity_GongChengZhan_Img:Hide()
	ThreeCity_GongChengZhan_Player1Text:SetText(strname)
	ThreeCity_GongChengZhan_FirstBloodBK:SetProperty("Image", ThreeCity_GongChengZhan_Image[2])
	ThreeCity_GongChengZhan_EndBK:Hide()
	ThreeCity_GongChengZhan_BH:Hide()
	ThreeCity_GongChengZhan_JS:Show()
  elseif msgType == 4 then
	--ThreeCity_GongChengZhan_Player1BK:Show()
	ThreeCity_GongChengZhan_Player1Text:Show()
	ThreeCity_GongChengZhan_FirstBloodBK:Show()
	ThreeCity_GongChengZhan_Img:Hide()
	ThreeCity_GongChengZhan_Player1Text:SetText(strname)
	ThreeCity_GongChengZhan_FirstBloodBK:SetProperty("Image", ThreeCity_GongChengZhan_Image[1])
	ThreeCity_GongChengZhan_EndBK:Hide()
	ThreeCity_GongChengZhan_BH:Hide()
	ThreeCity_GongChengZhan_JS:Show()
  elseif msgType == 5 then
	--ThreeCity_GongChengZhan_Player1BK:Hide()
	ThreeCity_GongChengZhan_Player1Text:Hide()
	ThreeCity_GongChengZhan_FirstBloodBK:Hide()
	ThreeCity_GongChengZhan_Img:Hide()
	ThreeCity_GongChengZhan_EndBK:Show()
	ThreeCity_GongChengZhan_EndBK:SetProperty("Image", "set:T3ZhengBaSai1 image:End")
	ThreeCity_GongChengZhan_BH:Hide()
	ThreeCity_GongChengZhan_JS:Show()
  elseif msgType == 6 then
    ThreeCity_GongChengZhan_EndBK:Hide ()
    ThreeCity_GongChengZhan_BH:Hide()
	ThreeCity_GongChengZhan_JS:Show()
    ThreeCity_GongChengZhan_Player1Text:Show ()

    ThreeCity_GongChengZhan_Player1Text:SetText (strmsg)
    ThreeCity_GongChengZhan_FirstBloodBK:SetProperty ("Image", "set:GongChengZhan image:GongChengZhan_Tips03")
  elseif msgType == 7 then
    ThreeCity_GongChengZhan_EndBK:Hide ()
    ThreeCity_GongChengZhan_BH:Hide()
	ThreeCity_GongChengZhan_JS:Show()
    ThreeCity_GongChengZhan_Player1Text:Show ()

    ThreeCity_GongChengZhan_Player1Text:SetText (strmsg)
    ThreeCity_GongChengZhan_FirstBloodBK:SetProperty ("Image", "set:GongChengZhan image:GongChengZhan_Tips04")
  end
end -- end func ThreeCity_GongChengZhan_ShowPic()

-- 向消息队列中添加新消息
function ThreeCity_GongChengZhan_AddMessage(msgType, strmsg, strname)
    if (ThreeCity_GongChengZhan_MessageQuene == nil) then
        ThreeCity_GongChengZhan_MessageQuene = {}
    end

    -- 目前传过来的名字不带服务器组号 所以这里不需要特殊处理了

    local msgQueneCount = table.getn(ThreeCity_GongChengZhan_MessageQuene)
    ThreeCity_GongChengZhan_MessageQuene[msgQueneCount + 1] = {}
    ThreeCity_GongChengZhan_MessageQuene[msgQueneCount + 1].msgtype = msgType
    ThreeCity_GongChengZhan_MessageQuene[msgQueneCount + 1].strmsg = strmsg
    ThreeCity_GongChengZhan_MessageQuene[msgQueneCount + 1].strname = strname
  

    -- 如果UI处于show状态 则说明当前正在显示其他的提示信息 等待其他信息显示完毕
    -- 如果UI处于hide状态 则说明这是第一个消息 执行消息逻辑 显示此消息
    -- 这里不能使用IsVisible()判断 貌似这个结果有延迟 如果消息是同一个tick到达这个函数返回值都是一样的
    if (ThreeCity_GongChengZhan_IsProcessing == 0) then
        -- 当前UI处于hide状态 应该是第一个消息 直接执行消息逻辑显示此消息
        ThreeCity_GongChengZhan_IsProcessing = 1
        ThreeCity_GongChengZhan_Show()
        SetTimer("ThreeCity_GongChengZhan", "ThreeCity_GongChengZhan_MessageLogic()", ThreeCity_GongChengZhan_ShowTime)
        ThreeCity_GongChengZhan_MessageLogic()
    end
end -- end func ThreeCity_GongChengZhan_AddMessage()

-- 从消息队列中删除消息
function ThreeCity_GongChengZhan_RemoveMessage(index)
    if (ThreeCity_GongChengZhan_MessageQuene[index] ~= nil) then
        ThreeCity_GongChengZhan_MessageQuene[index].msgtype = -1
        ThreeCity_GongChengZhan_MessageQuene[index].strmsg = nil
        ThreeCity_GongChengZhan_MessageQuene[index].strname = nil
    end
end -- end func ThreeCity_GongChengZhan_RemoveMessage()

-- 消息队列逻辑
function ThreeCity_GongChengZhan_MessageLogic()
    local msgQueneCount = table.getn(ThreeCity_GongChengZhan_MessageQuene)
    if (msgQueneCount < 1) then
        -- 消息队列是空的 直接关闭UI吧
        ThreeCity_GongChengZhan_Hide()
        return
    end

    -- 有效消息数量（未显示过的）
    local effectiveMsgCount = 0
    local firstEffectiveMsgIndex = 0
    for i = 1, msgQueneCount, 1 do
        if (ThreeCity_GongChengZhan_MessageQuene[i] ~= nil) then
            if (ThreeCity_GongChengZhan_MessageQuene[i].msgtype >= 0) then
                effectiveMsgCount = effectiveMsgCount + 1
                if (firstEffectiveMsgIndex < 1) then
                    firstEffectiveMsgIndex = i
                end
            end
        end
    end -- end for
    if (effectiveMsgCount < 1) then
        -- 消息都显示完了 关闭UI吧
        ThreeCity_GongChengZhan_Hide()
        return
    end
    if (ThreeCity_GongChengZhan_MessageQuene[firstEffectiveMsgIndex] == nil) then
        -- 按说不应该到这的 关闭UI吧
        ThreeCity_GongChengZhan_Hide()
        return
    end

    if (ThreeCity_GongChengZhan_MessageQuene[firstEffectiveMsgIndex].msgtype >= 0) then
        ThreeCity_GongChengZhan_ShowPic(ThreeCity_GongChengZhan_MessageQuene[firstEffectiveMsgIndex].msgtype,
                            ThreeCity_GongChengZhan_MessageQuene[firstEffectiveMsgIndex].strmsg,
                            ThreeCity_GongChengZhan_MessageQuene[firstEffectiveMsgIndex].strname)                        

        ThreeCity_GongChengZhan_RemoveMessage(firstEffectiveMsgIndex)
        return
    end

    -- 按说也不应该到这的 做个保险吧
    ThreeCity_GongChengZhan_Hide()
end -- end func ThreeCity_GongChengZhan_MessageLogic()