-- 武林之巅 boss挑战倒计时

local WuLin_Small_SceneType = 0
-- 保存UI默认位置
local WuLin_Small_UnifiedPosition = nil

local WuLin_Small_SceneTypeInfo =
{
	team = 1,
	single = 2,
} -- end WuLin_Small_SceneTypeInfo

-- NPC
local WuLin_Small_BossInfo =
{
	-- 明教
	[1] = {name = "#{PTFB_191228_86}"},
	-- 丐帮
	[2] = {name = "#{PTFB_191228_87}"},
	-- 唐门
	[3] = {name = "#{PTFB_191228_79}"},
	-- 峨嵋
	[4] = {name = "#{PTFB_191228_80}"},
	-- 星宿
	[5] = {name = "#{PTFB_191228_90}"},
	-- 武当
	[6] = {name = "#{PTFB_191228_88}"},
	-- 桃花岛
	[7] = {name = "#{PTFB_191228_81}"},
	-- 天龙
	[8] = {name = "#{PTFB_191228_89}"},
	-- 天山
	[9] = {name = "#{PTFB_191228_78}"},
	-- 逍遥
	[10] = {name = "#{PTFB_191228_83}"},
	-- 慕容
	[11] = {name = "#{PTFB_191228_84}"},
	-- 少林
	[12] = {name = "#{PTFB_191228_85}"},
	-- 鬼谷
	[13] = {name = "#{PTFB_191228_82}"},
} -- end WuLin_Small_BossInfo

-- 数字图片资源
local WuLin_Small_NumImageInfo =
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
} -- end WuLin_Small_NumImageInfo

function WuLin_Small_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_BOSSCOUNTDOWN", true)
	this:RegisterEvent("WLZD_SYNC_BOSSCOUNTDOWN", true)
	this:RegisterEvent("WLZD_CLOSE_BOSSCOUNTDOWN", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Small_PreLoad()

function WuLin_Small_OnLoad()
	WuLin_Small_Initctrl()

	WuLin_Small_UnifiedPosition = WuLin_Small_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_Small_OnLoad()

function WuLin_Small_OnEvent(event)
	if (event == "WLZD_OPEN_BOSSCOUNTDOWN") then
		WuLin_Small_SceneType = tonumber(arg3)
		WuLin_Small_Show(arg0, arg1, arg2)
	elseif (event == "WLZD_SYNC_BOSSCOUNTDOWN") then
		WuLin_Small_SceneType = tonumber(arg2)
		WuLin_Small_UpdateCountdown(arg0, arg1)
	elseif (event == "WLZD_CLOSE_BOSSCOUNTDOWN") then
		WuLin_Small_Hide()
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_Small_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (WuLinZhiDian:IsWuLinZhiDianScene() < 0) then
			WuLin_Small_Hide()
			WuLin_Small_UnifiedPos()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Small_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Small_UnifiedPos()
	end
end -- end func WuLin_Small_OnEvent()

-- 界面默认位置
function WuLin_Small_UnifiedPos()
	if (WuLin_Small_UnifiedPosition ~= nil) then
		WuLin_Small_Frame:SetProperty("UnifiedPosition", WuLin_Small_UnifiedPosition)
	end
end -- end func WuLin_Small_UnifiedPos()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Small_Initctrl()
	if (WuLin_Small_Btn ~= nil) then
		WuLin_Small_Btn:SetEvent("Clicked", "WuLin_Small_ShowBossInfo()")
	end
end -- end func WuLin_Small_Initctrl()

-- 开启UI
function WuLin_Small_Show(countTime, stage, bossIndex)
	if (WuLin_Small_SceneType == WuLin_Small_SceneTypeInfo.single) then
		WuLin_Small_Btn:Hide()
	else
		WuLin_Small_Btn:Show()
	end
	-- 打开后刷新一下 要不会从默认值一下跳到倒计时的层数和时间
	WuLin_Small_UpdateCountdown(countTime, stage)
	this:Show()
end -- end func WuLin_Small_Show()

-- 关闭UI
function WuLin_Small_Hide()
	this:Hide()
end -- end func WuLin_Small_Hide()

-- 打开攻略页面
function WuLin_Small_ShowBossInfo()
	if (WuLin_Small_SceneType ~= WuLin_Small_SceneTypeInfo.single) then
		PushEvent("WLZD_OPEN_BOSSINFO", 0)
	end
end -- end func WuLin_Small_ShowBossInfo()

-- 更新计时时间
function WuLin_Small_UpdateCountdown(countTime, stage)
	if (tonumber(countTime) >= 0) then
		if (not this:IsVisible()) then
			this:Show()
		end
	end

	local min1, min2, sec1, sec2 = WuLin_Small_TimeConvert(countTime)

	if (WuLin_Small_NumImageInfo[min1] ~= nil) then
		WuLin_Small_1BKG:SetProperty("Image", WuLin_Small_NumImageInfo[min1])
	end
	if (WuLin_Small_NumImageInfo[min2] ~= nil) then
		WuLin_Small_2BKG:SetProperty("Image", WuLin_Small_NumImageInfo[min2])
	end
	if (WuLin_Small_NumImageInfo[sec1] ~= nil) then
		WuLin_Small_3BKG:SetProperty("Image", WuLin_Small_NumImageInfo[sec1])
	end
	if (WuLin_Small_NumImageInfo[sec2] ~= nil) then
		WuLin_Small_4BKG:SetProperty("Image", WuLin_Small_NumImageInfo[sec2])
	end

	local curStage = tonumber(stage)
	local stage1, stage2, stage3 = WuLin_Small_StageConvert(stage)
	if (curStage < 10) then
		-- 1 ~ 9层
		WuLin_Small_Layer1BKG:Hide()
		WuLin_Small_Layer2BKG:Hide()
		WuLin_Small_Layer3BKG:Hide()

		-- 个位数时显示在中间位置
		if (WuLin_Small_NumImageInfo[stage3] ~= nil) then
			WuLin_Small_Layer2BKG:Show()
			WuLin_Small_Layer2BKG:SetProperty("Image", WuLin_Small_NumImageInfo[stage3])
		end
	elseif (curStage >= 10 and curStage < 100) then
		-- 10 ~ 99层
		WuLin_Small_Layer1BKG:Hide()
		WuLin_Small_Layer2BKG:Hide()
		WuLin_Small_Layer3BKG:Hide()

		if (WuLin_Small_NumImageInfo[stage2] ~= nil) then
			WuLin_Small_Layer2BKG:Show()
			WuLin_Small_Layer2BKG:SetProperty("Image", WuLin_Small_NumImageInfo[stage2])
		end

		if (WuLin_Small_NumImageInfo[stage3] ~= nil) then
			WuLin_Small_Layer3BKG:Show()
			WuLin_Small_Layer3BKG:SetProperty("Image", WuLin_Small_NumImageInfo[stage3])
		end
	else
		-- 100层
		WuLin_Small_Layer1BKG:Hide()
		WuLin_Small_Layer2BKG:Hide()
		WuLin_Small_Layer3BKG:Hide()

		if (WuLin_Small_NumImageInfo[stage1] ~= nil) then
			WuLin_Small_Layer1BKG:Show()
			WuLin_Small_Layer1BKG:SetProperty("Image", WuLin_Small_NumImageInfo[stage1])
		end

		if (WuLin_Small_NumImageInfo[stage2] ~= nil) then
			WuLin_Small_Layer2BKG:Show()
			WuLin_Small_Layer2BKG:SetProperty("Image", WuLin_Small_NumImageInfo[stage2])
		end

		if (WuLin_Small_NumImageInfo[stage3] ~= nil) then
			WuLin_Small_Layer3BKG:Show()
			WuLin_Small_Layer3BKG:SetProperty("Image", WuLin_Small_NumImageInfo[stage3])
		end
	end
end -- end func WuLin_Small_UpdateCountdown()

-- 计算时间 将时间转换成信息分(十位)，分（各位），秒（十位），秒（各位）的格式
function WuLin_Small_TimeConvert(time)
	-- -- 将时间转换成秒
	-- local timeSecond = math.floor(tonumber(time) / 1000)
	-- if (timeSecond <= 0) then
	-- 	return "00:00"
	-- end

	-- -- 分
	-- local strMinute = ""
	-- local minute = math.floor(timeSecond / 60)
	-- if (minute < 10) then
	-- 	strMinute = "0" .. tostring(minute)
	-- else
	-- 	strMinute = tostring(minute)
	-- end

	-- -- 秒
	-- local strSecond = ""
	-- local second = math.mod(timeSecond, 60)
	-- if (second < 10) then
	-- 	strSecond = "0" .. tostring(second)
	-- else
	-- 	strSecond = tostring(second)
	-- end

	-- return strMinute .. ":" ..strSecond

	-- 将时间转换成秒
	local timeSecond = tonumber(time)
	if (timeSecond <= 0) then
		return 0, 0, 0, 0
	end

	-- 分
	local min = math.floor(timeSecond / 60)
	if (min >= 100) then
		min = 99
	end
	-- 分(十位)
	local min1 = math.floor(min / 10)
	-- 分（各位）
	local min2 = math.mod(min, 10)

	-- 秒
	local sec = math.mod(timeSecond, 60)
	-- 秒（十位）
	local sec1 = math.floor(sec / 10)
	-- 秒（各位）
	local sec2 = math.mod(sec, 10)

	return min1, min2, sec1, sec2
end -- end func WuLin_Small_TimeConvert()

-- 计算层数 将层数转换成百位、十位，个位的格式
function  WuLin_Small_StageConvert(stage)
	if (tonumber(stage) <= 0) then
		return 0, 0, 0
	end

	-- 百位
	local stage1 = math.floor(tonumber(stage) / 100)
	-- 十位
	local stage2 = math.floor((tonumber(stage) - stage1*100) / 10)
	-- 个位
	local stage3 = math.mod(tonumber(stage), 10)

	return stage1, stage2, stage3
end -- end func WuLin_Small_StageConvert()
