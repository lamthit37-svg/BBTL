-- 武林之巅 挑战层数选择（升层）

-- 保存UI默认位置
local WuLin_Up_UnifiedPosition = nil

-- 界面控件
local WuLinUp_ctrlTextCurStage = nil
local WuLinUp_ctrlTextTime = nil
local WuLinUp_ctrlListChoice = nil
local WuLinUp_ctrlBtnConfirm = nil
local WuLinUp_ctrlBtnLeave = nil

local WuLin_Up_HideFlag = 0

function WuLin_Up_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_UPGRADE", true)
	this:RegisterEvent("WLZD_CLOSE_UPGRADE", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Up_PreLoad()

function WuLin_Up_OnLoad()
	WuLin_Up_InitControl()

	WuLin_Up_HideFlag = 0
	WuLin_Up_UnifiedPosition = WuLin_Up_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_Up_OnLoad()

function WuLin_Up_OnEvent(event)
	if (event == "WLZD_OPEN_UPGRADE") then
		WuLin_Up_Show(arg0, arg1, arg2)
	elseif (event == "WLZD_CLOSE_UPGRADE") then
		WuLin_Up_Hide()
	elseif (event =="WLZD_CLOSE_ALL") then
		WuLin_Up_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (WuLinZhiDian:IsWuLinZhiDianScene() < 0) then
			WuLin_Up_Hide()
			WuLin_Up_UnifiedPos()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Up_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Up_UnifiedPos()
	end
end -- end func WuLin_Up_OnEvent()

function WuLin_Up_OnHidden()
	if (WuLin_Up_HideFlag == 0) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("LeaderUpgradeAbort")
			Set_XSCRIPT_ScriptID(893399)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end -- end WuLin_Up_OnHidden()

-- 界面默认位置
function WuLin_Up_UnifiedPos()
	if (WuLin_Up_UnifiedPosition ~= nil) then
		WuLin_Up_Frame:SetProperty("UnifiedPosition", WuLin_Up_UnifiedPosition)
	end
end -- end func WuLin_Up_UnifiedPos()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Up_InitControl()
	WuLinUp_ctrlTextCurStage = WuLin_Up_FloorText
	WuLinUp_ctrlTextTime = WuLin_Up_TimeText
	WuLinUp_ctrlListChoice = WuLin_Up_Choice
	WuLinUp_ctrlBtnConfirm = WuLin_Up_OK
	WuLinUp_ctrlBtnLeave = WuLin_Up_Waive

	WuLinUp_ctrlBtnConfirm:SetEvent("Clicked", "WuLin_Up_StageConfirm()")
end -- end func WuLin_Up_InitControl()

-- 开启UI
function WuLin_Up_Show(ar0, arg1, arg2)
	WuLin_Up_HideFlag = 0

	local curStage = tonumber(arg0)
	local upStage = tonumber(arg1)
	local matchTimeSec = tonumber(arg2)

	if (WuLinUp_ctrlTextCurStage ~= nil) then
		local curStageText = ScriptGlobal_Format("#{PTFB_191228_116}", curStage)
		WuLinUp_ctrlTextCurStage:SetText(curStageText)
	end

	if (WuLinUp_ctrlTextTime ~= nil) then
		local minStr, secStr = WuLin_Up_TimeConvert(matchTimeSec)
		local ctrlText = ScriptGlobal_Format("#{PTFB_191228_102}", minStr, secStr)
		WuLinUp_ctrlTextTime:SetText(ctrlText)
	end

	WuLinUp_ctrlListChoice:ResetList()
	for i = 1, upStage, 1 do
		WuLinUp_ctrlListChoice:AddTextItem(tostring(curStage + i), i-1)
	end
	WuLinUp_ctrlListChoice:SetCurrentSelect(upStage-1)
	this:Show()
end -- end func WuLin_Up_Show()

-- 关闭UI
function WuLin_Up_Hide()
	WuLin_Up_HideFlag = 1
	this:Hide()
end -- end func WuLin_Up_Hide()

-- 层数选择确定按钮事件
function WuLin_Up_StageConfirm()
	-- 获取当前选择的挑战层数
	local str, index = WuLinUp_ctrlListChoice:GetCurrentSelect()
	local choseStage = tonumber(str)

	WuLinZhiDian:SetChooseStage(choseStage)
	if (choseStage <= 0) then
		PushDebugMessage("#{PTFB_191228_108}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LeaderUpgradeConfirm")
		Set_XSCRIPT_ScriptID(893399)
		Set_XSCRIPT_Parameter(0, choseStage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func WuLin_Up_StageConfirm()

-- 离开按钮事件
function WuLin_Up_Leave()
	--MessageBoxCommon("", "#{PTFB_191228_106}", "WuLin_Up", "LeaveConfirm()", "LeaveAbort()")

	WuLin_Up_LeaveConfirm()
end -- end func WuLin_Up_Leave()

-- 离开 确认
function WuLin_Up_LeaveConfirm()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LeaderUpgradeAbort")
		Set_XSCRIPT_ScriptID(893399)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	WuLin_Up_Hide()
end -- end func WuLin_Up_LeaveConfirm()

-- 离开 取消
function WuLin_Up_LeaveAbort()
end -- end func WuLin_Up_LeaveAbort()

-- 计算时间 将时间转换成信息xx xx的格式
function WuLin_Up_TimeConvert(timeSecond)
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

	return strMinute, strSecond
end -- end func WuLin_Up_TimeConvert()