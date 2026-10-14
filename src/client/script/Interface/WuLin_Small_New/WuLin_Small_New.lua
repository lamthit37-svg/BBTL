-- 决战武林之巅 boss挑战倒计时

-- 保存UI默认位置
local WuLin_Small_New_UnifiedPosition = nil

-- NPC
local WuLin_Small_New_BossInfo =
{
	-- 明教
	[1] = {name = "#{JZGSH_210222_83}"},
	-- 丐帮
	[2] = {name = "#{JZGSH_210222_84}"},
	-- 唐门
	[3] = {name = "#{JZGSH_210222_76}"},
	-- 峨嵋
	[4] = {name = "#{JZGSH_210222_77}"},
	-- 星宿
	[5] = {name = "#{JZGSH_210222_87}"},
	-- 武当
	[6] = {name = "#{JZGSH_210222_85}"},
	-- 桃花岛
	[7] = {name = "#{JZGSH_210222_78}"},
	-- 天龙
	[8] = {name = "#{JZGSH_210222_86}"},
	-- 天山
	[9] = {name = "#{JZGSH_210222_75}"},
	-- 逍遥
	[10] = {name = "#{JZGSH_210222_80}"},
	-- 慕容
	[11] = {name = "#{JZGSH_210222_81}"},
	-- 少林
	[12] = {name = "#{JZGSH_210222_82}"},
	-- 鬼谷
	[13] = {name = "#{JZGSH_210222_79}"},
} -- end WuLin_Small_New_BossInfo

-- 数字图片资源
local WuLin_Small_New_NumImageInfo =
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
} -- end WuLin_Small_New_NumImageInfo

function WuLin_Small_New_PreLoad()
	this:RegisterEvent("JZWLZD_CLOSE_ALL", true)
	this:RegisterEvent("JZWLZD_OPEN_BOSSCOUNTDOWN", true)
	this:RegisterEvent("JZWLZD_CLOSE_BOSSCOUNTDOWN", true)
	this:RegisterEvent("JZWLZD_BOSSCOUNTDOWN", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Small_New_PreLoad()

function WuLin_Small_New_OnLoad()
	WuLin_Small_New_Initctrl()

	WuLin_Small_New_UnifiedPosition = WuLin_Small_New_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_Small_New_OnLoad()

function WuLin_Small_New_OnEvent(event)
	if (event == "JZWLZD_CLOSE_ALL") then
		WuLin_Small_New_Hide()
	elseif (event == "JZWLZD_OPEN_BOSSCOUNTDOWN") then
		WuLin_Small_New_Show(arg0, arg1, arg2)
	elseif (event == "JZWLZD_CLOSE_BOSSCOUNTDOWN") then
		WuLin_Small_New_Hide()
	elseif (event == "JZWLZD_BOSSCOUNTDOWN") then
		WuLin_Small_New_UpdateCountdown(arg0, arg1)
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (JueZhanWuLinZhiDian:IsJueZhanWuLinZhiDianScene() < 0) then
			WuLin_Small_New_Hide()
			WuLin_Small_New_UnifiedPos()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Small_New_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Small_New_UnifiedPos()
	end
end -- end func WuLin_Small_New_OnEvent()

-- 界面默认位置
function WuLin_Small_New_UnifiedPos()
	if (WuLin_Small_New_UnifiedPosition ~= nil) then
		WuLin_Small_New_Frame:SetProperty("UnifiedPosition", WuLin_Small_New_UnifiedPosition)
	end
end -- end func WuLin_Small_New_UnifiedPos()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Small_New_Initctrl()
	if (WuLin_Small_New_Btn ~= nil) then
		WuLin_Small_New_Btn:SetEvent("Clicked", "WuLin_Small_New_ShowBossInfo()")
	end
end -- end func WuLin_Small_New_Initctrl()

-- 开启UI
function WuLin_Small_New_Show(countTime, stage, bossIndex)
	-- 打开后刷新一下 要不会从默认值一下跳到倒计时的层数和时间
	WuLin_Small_New_UpdateCountdown(countTime, stage)
	this:Show()
end -- end func WuLin_Small_New_Show()

-- 关闭UI
function WuLin_Small_New_Hide()
	this:Hide()
end -- end func WuLin_Small_New_Hide()

-- 打开攻略页面
function WuLin_Small_New_ShowBossInfo()
	PushEvent("JZWLZD_OPEN_BOSSINFO", 0)
end -- end func WuLin_Small_New_ShowBossInfo()

-- 更新计时时间
function WuLin_Small_New_UpdateCountdown(countTime, stage)
	if (tonumber(countTime) >= 0) then
		if (not this:IsVisible()) then
			this:Show()
		end
	end

	local min1, min2, sec1, sec2 = WuLin_Small_New_TimeConvert(countTime)

	if (WuLin_Small_New_NumImageInfo[min1] ~= nil) then
		WuLin_Small_New_1BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[min1])
	end
	if (WuLin_Small_New_NumImageInfo[min2] ~= nil) then
		WuLin_Small_New_2BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[min2])
	end
	if (WuLin_Small_New_NumImageInfo[sec1] ~= nil) then
		WuLin_Small_New_3BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[sec1])
	end
	if (WuLin_Small_New_NumImageInfo[sec2] ~= nil) then
		WuLin_Small_New_4BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[sec2])
	end

	local curStage = tonumber(stage)
	local stage1, stage2, stage3 = WuLin_Small_New_StageConvert(stage)
	if (curStage < 10) then
		-- 1 ~ 9层
		WuLin_Small_New_Layer1BKG:Hide()
		WuLin_Small_New_Layer2BKG:Hide()
		WuLin_Small_New_Layer3BKG:Hide()

		-- 个位数时显示在中间位置
		if (WuLin_Small_New_NumImageInfo[stage3] ~= nil) then
			WuLin_Small_New_Layer2BKG:Show()
			WuLin_Small_New_Layer2BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[stage3])
		end
	elseif (curStage >= 10 and curStage < 100) then
		-- 10 ~ 99层
		WuLin_Small_New_Layer1BKG:Hide()
		WuLin_Small_New_Layer2BKG:Hide()
		WuLin_Small_New_Layer3BKG:Hide()

		if (WuLin_Small_New_NumImageInfo[stage2] ~= nil) then
			WuLin_Small_New_Layer2BKG:Show()
			WuLin_Small_New_Layer2BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[stage2])
		end

		if (WuLin_Small_New_NumImageInfo[stage3] ~= nil) then
			WuLin_Small_New_Layer3BKG:Show()
			WuLin_Small_New_Layer3BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[stage3])
		end
	else
		-- 100层
		WuLin_Small_New_Layer1BKG:Hide()
		WuLin_Small_New_Layer2BKG:Hide()
		WuLin_Small_New_Layer3BKG:Hide()

		if (WuLin_Small_New_NumImageInfo[stage1] ~= nil) then
			WuLin_Small_New_Layer1BKG:Show()
			WuLin_Small_New_Layer1BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[stage1])
		end

		if (WuLin_Small_New_NumImageInfo[stage2] ~= nil) then
			WuLin_Small_New_Layer2BKG:Show()
			WuLin_Small_New_Layer2BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[stage2])
		end

		if (WuLin_Small_New_NumImageInfo[stage3] ~= nil) then
			WuLin_Small_New_Layer3BKG:Show()
			WuLin_Small_New_Layer3BKG:SetProperty("Image", WuLin_Small_New_NumImageInfo[stage3])
		end
	end
end -- end func WuLin_Small_New_UpdateCountdown()

-- 计算时间 将时间转换成信息分(十位)，分（各位），秒（十位），秒（各位）的格式
function WuLin_Small_New_TimeConvert(time)
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
end -- end func WuLin_Small_New_TimeConvert()

-- 计算层数 将层数转换成百位、十位，个位的格式
function  WuLin_Small_New_StageConvert(stage)
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
end -- end func WuLin_Small_New_StageConvert()
