-- 2024Q4冰雪节答题活动
--活动界面
--!!!reloadscript =Frozen_AnswerEnter

local g_Frame_Pos = nil

--=========
-- PreLoad
--=========
function Frozen_AnswerEnter_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end

--=========
-- OnLoad
--=========
function Frozen_AnswerEnter_OnLoad()
	g_Frame_Pos = Frozen_AnswerEnter_Frame_BK:GetProperty("UnifiedPosition")
end

--=========
-- OnEvent
--=========
function Frozen_AnswerEnter_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99948201 )  then
		--打开界面
		Frozen_AnswerEnter_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99948202 )  then 
		--自动寻路
		AutoRuntoTargetExWithName(215,199,1007,"狍跑")
	elseif event == "ADJEST_UI_POS" then
		Frozen_AnswerEnter_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_AnswerEnter_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_AnswerEnter_OnHide()
	end
end

--=========
-- 重置
--=========
function Frozen_AnswerEnter_On_ResetPos()
	Frozen_AnswerEnter_Frame_BK:SetProperty("UnifiedPosition", g_Frame_Pos)
end

--=========
-- 打开
--=========
function Frozen_AnswerEnter_Open()
	--显示界面
	this:Show()
end

--=========
-- 关闭
--=========
function Frozen_AnswerEnter_OnHide()
	this:Hide()
end

--=========
-- 点击前往
--=========
function Frozen_AnswerEnter_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AutoNpc")
		Set_XSCRIPT_ScriptID(999482)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	Frozen_AnswerEnter_OnHide()
end

--=========
-- 帮助按钮
--=========
function Frozen_AnswerEnter_ShowHelp()
	PushEvent("CCSHOP_HELP", 225)
end
