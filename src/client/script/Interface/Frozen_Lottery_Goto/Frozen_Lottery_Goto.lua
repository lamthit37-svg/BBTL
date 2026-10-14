--******************************************
--冰雪舞会抽奖goto
--create by  wangsaifei 
--2025-10-19
--******************************************

local g_Frozen_Lottery_Goto_Frame_UnifiedPosition;


--===============================================
-- OnLoad()
--===============================================
function Frozen_Lottery_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--===============================================
-- OnLoad()
--===============================================
function Frozen_Lottery_Goto_OnLoad()   
	-- 保存界面的默认相对位置
	g_Frozen_Lottery_Goto_Frame_UnifiedPosition = Frozen_Lottery_Goto_Frame:GetProperty("UnifiedPosition");
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Lottery_Goto_Frame_On_ResetPos()
	Frozen_Lottery_Goto_Frame:SetProperty("UnifiedPosition", g_Frozen_Lottery_Goto_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_Lottery_Goto_OnEvent(event)
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Frozen_Lottery_Goto_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_Lottery_Goto_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
		Frozen_Lottery_Goto_OnHide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99978002 then
		if not this:IsVisible() then
			this:Show()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99978001 then
		Frozen_Lottery_Goto_GoToFindNpc()
    end
         
end

--===============================================
-- Frozen_Lottery_Goto_OnHide()
--===============================================
function Frozen_Lottery_Goto_OnHide()
	this:Hide()
end

--=========================================================
--帮助
--=========================================================
function Frozen_Lottery_Goto_ShowHelp()
	PushEvent("CCSHOP_HELP", 238)
end

-- 初始化
function Frozen_Lottery_Goto()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GotoNpc")
		Set_XSCRIPT_ScriptID(999780)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--响应：通过server判断，可以寻路找npc
function Frozen_Lottery_Goto_GoToFindNpc()
	AutoRuntoTargetExWithName(181, 148, 1007, "范二彪") --替代
	Frozen_Lottery_Goto_OnHide()
end