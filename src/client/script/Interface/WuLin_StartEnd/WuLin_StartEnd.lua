-- 武林之巅 开始、结束图片展示UI

-- 计时器ID
local WuLin_StartEnd_TimerID = -1
-- 计时器时间（毫秒）
local WuLin_StartEnd_TimerTime = 3000

-- 数字图片资源
local WuLin_StartEnd_NumImageInfo =
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
} -- end WuLin_StartEnd_NumImageInfo

function WuLin_StartEnd_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_START", true)
	this:RegisterEvent("WLZD_OPEN_END", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
end -- end func WuLin_StartEnd_PreLoad()

function WuLin_StartEnd_OnLoad()
	WuLin_StartEnd_Initctrl()
end -- end func WuLin_StartEnd_OnLoad()

function WuLin_StartEnd_OnEvent(event)
	if (event == "WLZD_OPEN_START") then
		WuLin_StartEnd_ShowStart(arg0)
	elseif (event == "WLZD_OPEN_END") then
		WuLin_StartEnd_ShowEnd(arg0, arg1)
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_StartEnd_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (WuLinZhiDian:IsWuLinZhiDianScene() < 0) then
        	WuLin_StartEnd_Hide()
        end
	end
end -- end func WuLin_StartEnd_OnEvent()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_StartEnd_Initctrl()
end -- end func WuLin_StartEnd_Initctrl()

-- 开启开始UI
function WuLin_StartEnd_ShowStart(stage)
	this:Show()
	-- 隐藏结束UI相关控件
	WuLin_StartEnd_HideEnd()
	-- 关闭已有的计时器
	--WuLin_StartEnd_CloseTimer()
	-- 开启新的计时器
	WuLin_StartEnd_SetTimer()

	-- 显示层数底图
	if (WuLin_StartEnd_NumBK ~= nil) then
		WuLin_StartEnd_NumBK:Show()
	end
	-- 显示层字
	if (WuLin_StartEnd_Num_Ceng ~= nil) then
		WuLin_StartEnd_Num_Ceng:Show()
	end
	
	local curStage = tonumber(stage)
	local stage1, stage2, stage3 = WuLin_StartEnd_StageConvert(curStage)
	-- 显示百位
	if (stage1 <= 0) then
		-- 百位为0 不显示
		if (WuLin_StartEnd_Num_1BKG ~= nil) then
			WuLin_StartEnd_Num_1BKG:Hide()
		end
	else
		if (WuLin_StartEnd_Num_1BKG ~= nil) then
			WuLin_StartEnd_Num_1BKG:Show()
			WuLin_StartEnd_Num_1BKG:SetProperty("Image", WuLin_StartEnd_NumImageInfo[stage1])
		end
	end
	-- 显示十位
	if(stage1 <= 0 and stage2 <= 0) then
		-- 十位、百位均为0 不显示
		if (WuLin_StartEnd_Num_2BKG ~= nil) then
			WuLin_StartEnd_Num_2BKG:Hide()
		end
	else
		if (WuLin_StartEnd_Num_2BKG ~= nil) then
			WuLin_StartEnd_Num_2BKG:Show()
			WuLin_StartEnd_Num_2BKG:SetProperty("Image", WuLin_StartEnd_NumImageInfo[stage2])
		end
	end
	-- 显示个位
	if(stage1 <= 0 and stage2 <= 0 and stage3 <= 0) then
		-- 个位、十位、百位均为0 不显示
		if (WuLin_StartEnd_Num_3BKG ~= nil) then
			WuLin_StartEnd_Num_3BKG:Hide()
		end
		if (WuLin_StartEnd_Num_Ceng ~= nil) then
			WuLin_StartEnd_Num_Ceng:Hide()
		end
	else
		if (WuLin_StartEnd_Num_3BKG ~= nil) then
			WuLin_StartEnd_Num_3BKG:Show()
			WuLin_StartEnd_Num_3BKG:SetProperty("Image", WuLin_StartEnd_NumImageInfo[stage3])
		end
	end
end -- end func WuLin_StartEnd_Show()

-- 隐藏开始UI相关控件
function WuLin_StartEnd_HideStart()
	if (WuLin_StartEnd_NumBK ~= nil) then
		WuLin_StartEnd_NumBK:Hide()
	end
	if (WuLin_StartEnd_Num_1BKG ~= nil) then
		WuLin_StartEnd_Num_1BKG:Hide()
	end
	if (WuLin_StartEnd_Num_2BKG ~= nil) then
		WuLin_StartEnd_Num_2BKG:Hide()
	end
	if (WuLin_StartEnd_Num_3BKG ~= nil) then
		WuLin_StartEnd_Num_3BKG:Hide()
	end
	if (WuLin_StartEnd_Num_Ceng ~= nil) then
		WuLin_StartEnd_Num_Ceng:Hide()
	end
end -- end func WuLin_StartEnd_Hide()

-- 开启结束UI
-- flag：1为挑战成功，2为挑战失败
function WuLin_StartEnd_ShowEnd(stage, flag)
	this:Show()
	-- 隐藏开始UI相关控件
	WuLin_StartEnd_HideStart()
	-- 关闭已有的计时器
	--WuLin_StartEnd_CloseTimer()
	-- 开启新的计时器
	WuLin_StartEnd_SetTimer()

	local curStage = tonumber(stage)
	local curFlag = tonumber(flag)
	if (curFlag == 1) then
		-- 挑战成功
		if (WuLin_StartEnd_VictoryAnimate ~= nil) then
			WuLin_StartEnd_VictoryAnimate:Show()
			WuLin_StartEnd_VictoryAnimate:Play(true)
		end
		if (WuLin_StartEnd_FailureAnimate ~= nil) then
			WuLin_StartEnd_FailureAnimate:Hide()
		end
	else
		-- 挑战失败
		if (WuLin_StartEnd_VictoryAnimate ~= nil) then
			WuLin_StartEnd_VictoryAnimate:Hide()
		end
		if (WuLin_StartEnd_FailureAnimate ~= nil) then
			WuLin_StartEnd_FailureAnimate:Show()
			WuLin_StartEnd_FailureAnimate:Play(true)
		end
	end
end -- end func WuLin_StartEnd_ShowEnd()

-- 隐藏结束UI相关控件
function WuLin_StartEnd_HideEnd()
	if (WuLin_StartEnd_VictoryAnimate ~= nil) then
		WuLin_StartEnd_VictoryAnimate:Hide()
	end
	if (WuLin_StartEnd_FailureAnimate ~= nil) then
		WuLin_StartEnd_FailureAnimate:Hide()
	end
end -- end func WuLin_StartEnd_HideEnd()

-- 关闭
function WuLin_StartEnd_Hide()
	WuLin_StartEnd_CloseTimer()
	this:Hide()
end -- end func WuLin_StartEnd_Hide()

-- 设置计时器
function WuLin_StartEnd_SetTimer()
	if (WuLin_StartEnd_TimerID < 0) then
		WuLin_StartEnd_TimerID = SetTimer("WuLin_StartEnd", "WuLin_StartEnd_Hide()", WuLin_StartEnd_TimerTime)
	end
end -- end WuLin_StartEnd_SetTimer()

-- 关闭计数器
function WuLin_StartEnd_CloseTimer()
	if (WuLin_StartEnd_TimerID >= 0) then
		KillTimer(WuLin_StartEnd_TimerID)
		WuLin_StartEnd_TimerID = -1
	end
end -- end func WuLin_StartEnd_CloseTimer()

-- 层数转换 将层数的百位、十位、个位分别返回
function WuLin_StartEnd_StageConvert(stage)
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
end -- end func WuLin_StartEnd_StageConvert()