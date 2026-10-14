-- 露荷撷香活动 采集计数界面

-- 保存UI默认位置
local ErtongjieHoudongNum_UnifiedPosition = nil

-- 游戏类型 低级（红莲子）、高级（玉莲子）
local ErtongjieHoudongNum_GameType =
{
	honglianzi = 0,		-- 红莲子局
	yulianiz = 1,		-- 玉莲子局
} -- end ErtongjieHoudongNum_GameType

function ErtongjieHoudongNum_PreLoad()
	this:RegisterEvent("ETJFUBEN_2022_GAMEDATA", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end -- end func ErtongjieHoudongNum_PreLoad()

function ErtongjieHoudongNum_OnLoad()
	ErtongjieHoudongNum_UnifiedPosition = ErtongjieHoudongNumFrame_BK:GetProperty("UnifiedPosition")
end -- end func ErtongjieHoudongNum_OnLoad()

function ErtongjieHoudongNum_OnEvent(event)
	if (event == "ETJFUBEN_2022_GAMEDATA") then
		ErtongjieHoudongNum_Show()
		ErtongjieHoudongNum_UpdateInfo(arg0, arg1, arg2, arg3, arg4, arg5)
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ErtongjieHoudongNum_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		ErtongjieHoudongNum_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ErtongjieHoudongNum_Hide()
	end
end -- end func ErtongjieHoudongNum_OnEvent()

function ErtongjieHoudongNum_On_ResetPos()
	ErtongjieHoudongNumFrame_BK:SetProperty("UnifiedPosition", ErtongjieHoudongNum_UnifiedPosition)
end -- end func ErtongjieHoudongNum_On_ResetPos()

--*****************************************************************************
-- UI关闭事件
--*****************************************************************************
function ErtongjieHoudongNum_OnHidden()
end -- end func ErtongjieHoudongNum_OnHidden()



function ErtongjieHoudongNum_UpdateInfo(lotusType, daibiTotalNum, daibiCreateNum, daibiCollectNum, collectNum, leftTick)
	local gameType = tonumber(lotusType)
	local daibiLotusNum = tonumber(daibiTotalNum)
	local daibiLotusCreateNum = tonumber(daibiCreateNum)
	local daibiLotusCollectNum = tonumber(daibiCollectNum)
	local totalCollectNum = tonumber(collectNum)
	local leftTickCount = tonumber(leftTick)

	-- 代币荷花名称
	local daibiName = ""
	if (gameType == ErtongjieHoudongNum_GameType.honglianzi) then
		-- 红莲子局 并蒂荷
		daibiName = "#{ETDDS_220406_97}"
	elseif (gameType == ErtongjieHoudongNum_GameType.yulianiz) then
		-- 玉莲子局 千重荷
		daibiName = "#{ETDDS_220406_96}"
	end
	ErtongjieHoudongNumPage_text2:SetText(daibiName)

	-- 代币荷花已刷出数量
	if (daibiLotusCreateNum < 0) then
		daibiLotusCreateNum = 0
	end
	ErtongjieHoudongNumPage_text3:SetText("#L" .. tostring(daibiLotusCreateNum))

	-- 代币荷花已采集数量
	if (daibiLotusCollectNum < 0) then
		daibiLotusCollectNum = 0
	end
	ErtongjieHoudongNumPage_text5:SetText("#L" .. tostring(daibiLotusCollectNum))

	-- 代币荷花总数
	if (daibiLotusNum < 0) then
		daibiLotusNum = 0
	end
	ErtongjieHoudongNumPage_text4:SetText("#L" .. tostring(daibiLotusNum))

	-- 倒计时
	local countDown = ErtongjieHoudongNum_GetCountdownStr(leftTickCount)
	ErtongjieHoudongNumPage_text7:SetText("#cff0000" .. countDown)

	-- 采集
	if (totalCollectNum < 0) then
		totalCollectNum = 0
	end
	ErtongjieHoudongNumPage_text9:SetText("#L" .. tostring(totalCollectNum))
end -- end func ErtongjieHoudongNum_UpdateInfo()

function ErtongjieHoudongNum_GetCountdownStr(tickCount)
	local countdown = tickCount
	if (countdown < 0) then
		countdown = 0
	end

	local minStr = ""
	local min = math.floor(countdown / 60)
	if (min < 10) then
		minStr = string.format("0%d", min)
	else
		minStr = tostring(min)
	end

	local secStr = ""
	local sec = math.mod(countdown, 60)
	if (sec < 10) then
		secStr = string.format("0%d", sec)
	else
		secStr = tostring(sec)
	end

	local countdownStr = string.format("%s:%s", minStr, secStr)
	return countdownStr
end -- end func ErtongjieHoudongNum_GetCountdownStr()

function ErtongjieHoudongNum_Show()
    if (not this:IsVisible()) then
		this:Show()
		ErtongjieHoudongNum_On_ResetPos()
	end
end -- end func ErtongjieHoudongNum_Show()

function ErtongjieHoudongNum_Hide()
    this:Hide()
end -- end func ErtongjieHoudongNum_Hide()