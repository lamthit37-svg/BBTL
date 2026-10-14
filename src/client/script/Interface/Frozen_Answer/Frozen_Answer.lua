-- 2024Q4冰雪节答题活动
--答题界面
--!!!reloadscript =Frozen_Answer

local g_Frame_Pos = nil

--=========
-- PreLoad
--=========
function Frozen_Answer_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end

--=========
-- OnLoad
--=========
function Frozen_Answer_OnLoad()
	g_Frame_Pos = Frozen_Answer_Frame:GetProperty("UnifiedPosition")
end

--=========
-- OnEvent
--=========
function Frozen_Answer_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99948301 )  then
		local flag = Get_XParam_INT(0)
		if flag == nil or flag <= 0 then
			Frozen_Answer_Close()
		else
			local nStep = tonumber(Get_XParam_INT(1))
			local nCurNum = tonumber(Get_XParam_INT(2))
			local nValue = tonumber(Get_XParam_INT(3))
			local nState = tonumber(Get_XParam_INT(4))
			local delTime = tonumber(Get_XParam_INT(5))
			local szQuestion = Get_XParam_STR(0)
			local szAnswer1 = Get_XParam_STR(1)
			local szAnswer2 = Get_XParam_STR(2)
			local szAnswer3 = Get_XParam_STR(3)
			local szAnswer4 = Get_XParam_STR(4)
			if flag == 1 then
				--显示界面
				this:Show()
				Frozen_Answer_Open(flag,nStep,nCurNum,nValue,nState,delTime,szQuestion,szAnswer1,szAnswer2,szAnswer3,szAnswer4)
			elseif flag == 2 then
				--刷新界面
				if( this:IsVisible() ) then
					Frozen_Answer_Open(flag,nStep,nCurNum,nValue,nState,delTime,szQuestion,szAnswer1,szAnswer2,szAnswer3,szAnswer4)
				end
			end
		end
	elseif event == "ADJEST_UI_POS" then
		Frozen_Answer_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_Answer_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_Answer_Close()
	end
end

--=========
-- 重置
--=========
function Frozen_Answer_On_ResetPos()
	Frozen_Answer_Frame:SetProperty("UnifiedPosition", g_Frame_Pos)
end

--=========
-- 打开
--=========
function Frozen_Answer_Open(flag,nStep,nCurNum,nValue,nState,delTime,szQuestion,szAnswer1,szAnswer2,szAnswer3,szAnswer4)
	--
	if flag == 1 or nStep <= 0 then
		--
		Frozen_Answer_Info2:SetText(ScriptGlobal_Format("#{DXDT_240920_39}", 0))
		--
		Frozen_Answer_Info4:SetText("#{DXDT_240920_98}")
		--
		Frozen_Answer_TimeText2:Show()
		Frozen_Answer_TimeText:Hide()
		Frozen_Answer_Time:Hide()
		--
		Frozen_Answer_BK:Show()
		Frozen_Answer_BK2:Hide()
		Frozen_Answer_Info5:SetText("#{DXDT_240920_34}")
	else
		--
		Frozen_Answer_Info2:SetText(ScriptGlobal_Format("#{DXDT_240920_39}", nCurNum))
		--
		Frozen_Answer_Info4:SetText(ScriptGlobal_Format("#{DXDT_240920_41}", nValue))
		--
		if nStep == 1 then
			Frozen_Answer_TimeText2:Hide()
			if delTime ~= nil and delTime > 0 then
				Frozen_Answer_TimeText:Show()
				Frozen_Answer_Time:Show()
				Frozen_Answer_Time:SetProperty("Timer",delTime)
			else
				Frozen_Answer_TimeText:Hide()
				Frozen_Answer_Time:Hide()
			end
			if nState == 1 then
				Frozen_Answer_BK:Hide()
				Frozen_Answer_BK2:Show()
				Frozen_Answer_Info6:SetText(""..szQuestion)
				Frozen_Answer_Choice1:SetText(""..szAnswer1)
				Frozen_Answer_Choice2:SetText(""..szAnswer2)
				Frozen_Answer_Choice3:SetText(""..szAnswer3)
				Frozen_Answer_Choice4:SetText(""..szAnswer4)
			elseif nState == 2 then
				Frozen_Answer_BK:Show()
				Frozen_Answer_BK2:Hide()
				Frozen_Answer_Info5:SetText(""..szQuestion)
			end
		else
			Frozen_Answer_TimeText2:Show()
			Frozen_Answer_TimeText:Hide()
			Frozen_Answer_Time:Hide()
			--Frozen_Answer_BK:Show()
			--Frozen_Answer_BK2:Hide()
			--Frozen_Answer_Info5:SetText("#{DXDT_240920_36}")
		end
	end
	
end

--=========
-- 关闭
--=========
function Frozen_Answer_Close()
	this:Hide()
end

--=========
-- 帮助按钮
--=========
function Frozen_Answer_Clicked()
	PushEvent("CCSHOP_HELP", 227)
end
