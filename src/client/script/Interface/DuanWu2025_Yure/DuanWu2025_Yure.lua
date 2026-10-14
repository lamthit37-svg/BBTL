local g_DuanWu2025_Frame_UnifiedXPosition
local g_DuanWu2025_Frame_UnifiedYPosition

local g_DuanWu2025_PlayerList = {}
local g_DuanWu2025_ButtonList = {}
local g_DuanWu2025_ButtonListOpen = {}

local g_DuanWu2025_SignStepMax = 4
local g_KJ_2025DUANWU_YURE = 168

local g_DuanWu2025_ButtonTips_Undo = {
	[1]="#{JOGSH_250418_08}",
	[2]="#{JOGSH_250418_09}",
	[3]="#{JOGSH_250418_10}",
	[4]="#{JOGSH_250418_11}",
}

local g_DuanWu2025_ButtonTips_do = {
	[1]="#{JOGSH_250418_12}",
	[2]="#{JOGSH_250418_13}",
	[3]="#{JOGSH_250418_14}",
	[4]="#{JOGSH_250418_15}",
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function DuanWu2025_Yure_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS", false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function DuanWu2025_Yure_OnLoad()
	-- 保存界面的默认相对位置
	g_DuanWu2025_Frame_UnifiedXPosition	= DuanWu2025_Yure_FrameNULL:GetProperty("UnifiedXPosition")
	g_DuanWu2025_Frame_UnifiedYPosition	= DuanWu2025_Yure_FrameNULL:GetProperty("UnifiedYPosition")

	g_DuanWu2025_PlayerList[0] = DuanWu2025_Yure_P1
	g_DuanWu2025_PlayerList[1] = DuanWu2025_Yure_P2
	g_DuanWu2025_PlayerList[2] = DuanWu2025_Yure_P3
	g_DuanWu2025_PlayerList[3] = DuanWu2025_Yure_P4
	g_DuanWu2025_PlayerList[4] = DuanWu2025_Yure_P5

	-- g_DuanWu2025_ButtonList[1] = DuanWu2025_Yure_Day_Start
	g_DuanWu2025_ButtonList[1] = DuanWu2025_Yure_Day1
	g_DuanWu2025_ButtonList[2] = DuanWu2025_Yure_Day2
	g_DuanWu2025_ButtonList[3] = DuanWu2025_Yure_Day3
	g_DuanWu2025_ButtonList[4] = DuanWu2025_Yure_Day4

	-- g_DuanWu2025_ButtonListOpen[1] = DuanWu2025_Yure_Day_Start_Open
	g_DuanWu2025_ButtonListOpen[1] = DuanWu2025_Yure_Day1_Open
	g_DuanWu2025_ButtonListOpen[2] = DuanWu2025_Yure_Day2_Open
	g_DuanWu2025_ButtonListOpen[3] = DuanWu2025_Yure_Day3_Open
	g_DuanWu2025_ButtonListOpen[4] = DuanWu2025_Yure_Day4_Open
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DuanWu2025_Yure_ResetPos()
	DuanWu2025_Yure_FrameNULL:SetProperty("UnifiedXPosition", g_DuanWu2025_Frame_UnifiedXPosition)
	DuanWu2025_Yure_FrameNULL:SetProperty("UnifiedYPosition", g_DuanWu2025_Frame_UnifiedYPosition)
end

--响应事件的函数，当注册的事件发生时会调用的函数
function DuanWu2025_Yure_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 99968301 then
		local g_DuanWu2025_type = tonumber(Get_XParam_INT(0))
		local g_DuanWu2025_LastSignDate = tonumber(Get_XParam_INT(1))
		local g_DuanWu2025_SignStep = tonumber(Get_XParam_INT(2))
		if g_DuanWu2025_type == 1 then -- 打开界面
			DuanWu2025_Yure_Show(g_DuanWu2025_LastSignDate, g_DuanWu2025_SignStep)
		elseif g_DuanWu2025_type == 2 then -- 刷新界面
			if this:IsVisible() then
				DuanWu2025_Yure_Refresh(g_DuanWu2025_LastSignDate, g_DuanWu2025_SignStep)
			end
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99968302 then
		-- 签到按钮红点
		if this:IsVisible() then
			local redPoint = tonumber(Get_XParam_INT(0))
			if redPoint == 1 then
				DuanWu2025_Yure_Guide_Tips:Show()
			else
				DuanWu2025_Yure_Guide_Tips:Hide()
			end
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DuanWu2025_Yure_Hide()
	elseif event == "ADJEST_UI_POS" then
		DuanWu2025_Yure_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu2025_Yure_ResetPos()
	end
end

--显示UI
function DuanWu2025_Yure_Show(LastSignDate, SignStep)
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_KJ_2025DUANWU_YURE) > 0 then --卡级
		DuanWu2025_Yure_Text:SetText("#{JOGSH_250418_06}")
	else
		DuanWu2025_Yure_Text:SetText("#{JOGSH_250418_05}")
	end
	DuanWu2025_Yure_Guide_Button:SetToolTip("#{JOGSH_250418_17}")
	DuanWu2025_Yure_Refresh(LastSignDate, SignStep)
	this:Show()
end

--刷新界面
function DuanWu2025_Yure_Refresh(LastSignDate, SignStep)
	if SignStep == 0 then
		g_DuanWu2025_PlayerList[0]:Show()
	else
		g_DuanWu2025_PlayerList[0]:Hide()
	end
	--宝箱和tooltips显示
	for i = 1, table.getn(g_DuanWu2025_ButtonList) do
		-- 人物图片显隐
		if i == SignStep then
			g_DuanWu2025_PlayerList[i]:Show()
		else
			g_DuanWu2025_PlayerList[i]:Hide()
		end
	--完成签到
		if i <= SignStep then
			g_DuanWu2025_ButtonList[i]:Hide()
			g_DuanWu2025_ButtonListOpen[i]:Show()
			g_DuanWu2025_ButtonListOpen[i]:SetToolTip(g_DuanWu2025_ButtonTips_do[i])
	--未完成签到
		else
			g_DuanWu2025_ButtonListOpen[i]:Hide()
			g_DuanWu2025_ButtonList[i]:Show()
			g_DuanWu2025_ButtonList[i]:SetToolTip(g_DuanWu2025_ButtonTips_Undo[i])
		end
	end
	local curDay = tonumber(DataPool:GetServerDayTime());
	if SignStep == g_DuanWu2025_SignStepMax then
		DuanWu2025_Yure_LY:Hide()
		DuanWu2025_Yure_LY_H:Show()
		DuanWu2025_Yure_DownImage:Show()
		DuanWu2025_Yure_ButtonImage:Hide()
		DuanWu2025_Yure_Guide_Button:Disable()
	elseif LastSignDate == curDay then
		DuanWu2025_Yure_LY:Show()
		DuanWu2025_Yure_LY_H:Hide()
		DuanWu2025_Yure_DownImage:Hide()
		DuanWu2025_Yure_ButtonImage:Show()
		DuanWu2025_Yure_Guide_Button:Enable()
	else
		DuanWu2025_Yure_LY:Show()
		DuanWu2025_Yure_LY_H:Hide()
		DuanWu2025_Yure_DownImage:Hide()
		DuanWu2025_Yure_ButtonImage:Hide()
		DuanWu2025_Yure_Guide_Button:Enable()
	end
	DuanWu2025_Yure_Guide_Tips:Hide()
end

--隐藏UI
function DuanWu2025_Yure_Hide()
	this:Hide()
end

--关闭界面
function DuanWu2025_Yure_Close()
	this:Hide()
end

function DuanWu2025_Yure_Help_Clicked()
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_KJ_2025DUANWU_YURE) > 0 then --卡级
		PushEvent("QUEST_HELP_MSG", "#{JOGSH_250418_25}")
	else
		PushEvent("QUEST_HELP_MSG", "#{JOGSH_250418_07}")
	end
end

function DuanWu2025_Yure_Guide_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnSignClick")
		Set_XSCRIPT_ScriptID(999683)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


