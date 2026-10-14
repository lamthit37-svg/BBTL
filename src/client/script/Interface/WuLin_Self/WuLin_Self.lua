-- 武林之巅 自己挑战层数详情（升层）

function WuLin_Self_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_MYSELFINFO", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end -- end func WuLin_Self_PreLoad()

function WuLin_Self_OnLoad()
	WuLin_Self_InitControl()
end -- end func WuLin_Self_OnLoad()

function WuLin_Self_OnEvent(event)
	if (event == "WLZD_OPEN_MYSELFINFO") then
		WuLin_Self_Show(arg0, arg1, arg2, arg3, arg4)
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_Self_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_Self_Hide()
	end
end -- end func WuLin_Self_OnEvent()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Self_InitControl()
end -- end func WuLin_Self_InitControl()

-- 开启UI
function WuLin_Self_Show(curStage, weekCount, maxWeekCount, maxStage, maxStageTime)
	-- 当前层数
	local strStage = ScriptGlobal_Format("#{PTFB_191228_117}", curStage)
	WuLin_Self_LeftNum:SetText(strStage)

	-- 剩余挑战次数
	local strNum = ""
	if (tonumber(weekCount) < tonumber(maxWeekCount)) then
		strNum = ScriptGlobal_Format("#{PTFB_191228_119}", weekCount, maxWeekCount)
	else
		strNum = ScriptGlobal_Format("#{PTFB_191228_118}", weekCount, maxWeekCount)
	end
	WuLin_Self_LeftText2:SetText(strNum)

	-- 历史最高层数
	local strMaxStage = ScriptGlobal_Format("#{PTFB_191228_117}", maxStage)
	WuLin_Self_RightText2:SetText(strMaxStage)

	-- 最高层数挑战用时
	local strMaxStageTime = WuLin_Self_TimeConvert(math.ceil(tonumber(maxStageTime) / 1000))
	WuLin_Self_RightTime:SetText(strMaxStageTime)

	this:Show()
end -- end func WuLin_Self_Show()

-- 关闭UI
function WuLin_Self_Hide()
	this:Hide()
end -- end func WuLin_Self_Hide()

-- 关闭按钮事件
function WuLin_Self_Close()
	WuLin_Self_Hide()
end -- end func WuLin_Self_Close()

-- 计算时间 将时间转换成分:秒
function WuLin_Self_TimeConvert(timeSecond)
	-- 分
	local strMinute = ""
	local minute = math.floor(timeSecond / 60)
	if (minute < 10) then
		strMinute = "0" .. tostring(minute)
	else
		strMinute = tostring(minute)
	end

	-- 秒
	local strSecond = ""
	local second = math.mod(timeSecond, 60)
	if (second < 10) then
		strSecond = "0" .. tostring(second)
	else
		strSecond = tostring(second)
	end

	return strMinute .. ":" .. strSecond
end -- end func WuLin_Self_TimeConvert()