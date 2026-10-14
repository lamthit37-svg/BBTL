-- 决战武林之巅 开始、结束图片展示UI

-- 计时器ID
local WuLin_StartEnd_New_TimerID = -1
-- 计时器时间（毫秒）
local WuLin_StartEnd_New_TimerTime = 3000
-- 挑战成功
local WuLin_StartEnd_New_Success = 1
-- 挑战失败
local WuLin_StartEnd_New_Failed = 2

-- 数字图片资源
local WuLin_StartEnd_New_NumImageInfo =
{
	[0] = "set:GuanShanHai03 image:Ceng0",
	[1] = "set:GuanShanHai03 image:Ceng1",
	[2] = "set:GuanShanHai03 image:Ceng2",
	[3] = "set:GuanShanHai03 image:Ceng3",
	[4] = "set:GuanShanHai03 image:Ceng4",
	[5] = "set:GuanShanHai03 image:Ceng5",
	[6] = "set:GuanShanHai03 image:Ceng6",
	[7] = "set:GuanShanHai03 image:Ceng7",
	[8] = "set:GuanShanHai03 image:Ceng8",
	[9] = "set:GuanShanHai03 image:Ceng9",
} -- end WuLin_StartEnd_New_NumImageInfo


function WuLin_StartEnd_New_PreLoad()
	this:RegisterEvent("JZWLZD_OPEN_START", true)
	this:RegisterEvent("JZWLZD_OPEN_FINISH", true)
	this:RegisterEvent("JZWLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end -- end func WuLin_StartEnd_New_PreLoad()

function WuLin_StartEnd_New_OnLoad()
	WuLin_StartEnd_New_Initctrl()
end -- end func WuLin_StartEnd_New_OnLoad()

function WuLin_StartEnd_New_OnEvent(event)
	if (event == "JZWLZD_OPEN_START") then
		WuLin_StartEnd_New_ShowStart(tonumner(arg0))
	elseif (event == "JZWLZD_OPEN_FINISH") then
		WuLin_StartEnd_New_ShowEnd(tonumner(arg0), tonumner(arg1))
	elseif (event == "JZWLZD_CLOSE_ALL") then
		WuLin_StartEnd_New_Hide()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (this:IsVisible() and JueZhanWuLinZhiDian:IsJueZhanWuLinZhiDianScene() < 0) then
        	WuLin_StartEnd_New_Hide()
        end
	end
end -- end func WuLin_StartEnd_New_OnEvent()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_StartEnd_New_Initctrl()
end -- end func WuLin_StartEnd_New_Initctrl()

function WuLin_StartEnd_New_Show()
    this:Show()
end -- end func WuLin_StartEnd_New_Show()

function WuLin_StartEnd_New_Hide()
    WuLin_StartEnd_New_CloseTimer()
	this:Hide()
end -- end func WuLin_StartEnd_New_Hide()

-- 开启开始UI
function WuLin_StartEnd_New_ShowStart(stage)
    WuLin_StartEnd_New_Show()
    WuLin_StartEnd_New_HideEnd()
    WuLin_StartEnd_New_SetTimer()

    if (WuLin_StartEnd_New_Num_1BKG ~= nil) then
        WuLin_StartEnd_New_Num_1BKG:Hide()
    end
    if (WuLin_StartEnd_New_Num_2BKG ~= nil) then
        WuLin_StartEnd_New_Num_2BKG:Hide()
    end
    if (WuLin_StartEnd_New_Num_3BKG ~= nil) then
        WuLin_StartEnd_New_Num_3BKG:Hide()
    end
    if (WuLin_StartEnd_New_Num_Ceng ~= nil) then
        WuLin_StartEnd_New_Num_Ceng:Show()
    end
    
    if (stage >= 0 and stage <= 9) then
        if (WuLin_StartEnd_New_Num_2BKG ~= nil) then
            WuLin_StartEnd_New_Num_2BKG:Show()
        end

        WuLin_StartEnd_New_Num_2BKG:SetProperty("Image", WuLin_StartEnd_New_NumImageInfo[stage])
    end
end -- end func WuLin_StartEnd_New_ShowStart()

-- 隐藏开始UI相关控件
function WuLin_StartEnd_New_HideStart()
    if (WuLin_StartEnd_New_Num_1BKG ~= nil) then
        WuLin_StartEnd_New_Num_1BKG:Hide()
    end
    if (WuLin_StartEnd_New_Num_2BKG ~= nil) then
        WuLin_StartEnd_New_Num_2BKG:Hide()
    end
    if (WuLin_StartEnd_New_Num_3BKG ~= nil) then
        WuLin_StartEnd_New_Num_3BKG:Hide()
    end
    if (WuLin_StartEnd_New_Num_Ceng ~= nil) then
        WuLin_StartEnd_New_Num_Ceng:Hide()
    end
end -- end func WuLin_StartEnd_New_Hide()

-- 开启结束UI
-- flag：1为挑战成功，2为挑战失败
function WuLin_StartEnd_New_ShowEnd(stage, flag)
    WuLin_StartEnd_New_Show()
    WuLin_StartEnd_New_HideStart()
    WuLin_StartEnd_New_SetTimer()

    if (flag == WuLin_StartEnd_New_Success) then
        -- 挑战成功
        if (WuLin_StartEnd_New_FailureAnimate ~= nil) then
            WuLin_StartEnd_New_FailureAnimate:Hide()
        end
        if (WuLin_StartEnd_New_VictoryAnimate ~= nil) then
            WuLin_StartEnd_New_VictoryAnimate:Show()
            WuLin_StartEnd_New_VictoryAnimate:Play(true)
        end
    elseif (flag == WuLin_StartEnd_New_Failed) then
        -- 挑战失败
        if (WuLin_StartEnd_New_VictoryAnimate ~= nil) then
            WuLin_StartEnd_New_VictoryAnimate:Hide()
        end
        if (WuLin_StartEnd_New_FailureAnimate ~= nil) then
            WuLin_StartEnd_New_FailureAnimate:Show()
            WuLin_StartEnd_New_FailureAnimate:Play(true)
        end
    end
end -- end func WuLin_StartEnd_New_ShowEnd()

-- 隐藏结束UI相关控件
function WuLin_StartEnd_New_HideEnd()
    if (WuLin_StartEnd_New_VictoryAnimate ~= nil) then
        WuLin_StartEnd_New_VictoryAnimate:Hide()
    end
    if (WuLin_StartEnd_New_FailureAnimate ~= nil) then
        WuLin_StartEnd_New_FailureAnimate:Hide()
    end
end -- end func WuLin_StartEnd_New_HideEnd()

-- 设置计时器
function WuLin_StartEnd_New_SetTimer()
	if (WuLin_StartEnd_New_TimerID < 0) then
		WuLin_StartEnd_New_TimerID = SetTimer("WuLin_StartEnd_New", "WuLin_StartEnd_New_Hide()", WuLin_StartEnd_New_TimerTime)
	end
end -- end WuLin_StartEnd_New_SetTimer()

-- 关闭计数器
function WuLin_StartEnd_New_CloseTimer()
	if (WuLin_StartEnd_New_TimerID >= 0) then
		KillTimer(WuLin_StartEnd_New_TimerID)
		WuLin_StartEnd_New_TimerID = -1
	end
end -- end func WuLin_StartEnd_New_CloseTimer()

-- 层数转换 将层数的百位、十位、个位分别返回
function WuLin_StartEnd_New_StageConvert(stage)
	if (stage <= 0) then
		return 0, 0, 0
	end

	-- 百位
	local stage1 = math.floor(stage / 100)
	-- 十位
	local stage2 = math.floor((stage - stage1*100) / 10)
	-- 个位
	local stage3 = math.mod(stage, 10)

	return stage1, stage2, stage3
end -- end func WuLin_StartEnd_New_StageConvert()