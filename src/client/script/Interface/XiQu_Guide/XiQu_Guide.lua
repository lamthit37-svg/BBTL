--******************************************************************************
-- 入口界面
--******************************************************************************
local g_XiQu_Guide_Frame_UnifiedXPosition;
local g_XiQu_Guide_Frame_UnifiedYPosition;

--UI
local g_XiQu_Guide_Btn  --按钮

--NPC
local g_XiQu_Guide_NPCPosX = 398
local g_XiQu_Guide_NPCPosZ = 216
local g_XiQu_Guide_Name = "曲慕戏"

--===============================================
-- OnLoad()
--===============================================
function XiQu_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function XiQu_Guide_OnLoad()

	-- 保存界面的默认相对位置
	g_XiQu_Guide_Frame_UnifiedXPosition = XiQu_Guide_Frame:GetProperty("UnifiedXPosition");
	g_XiQu_Guide_Frame_UnifiedYPosition = XiQu_Guide_Frame:GetProperty("UnifiedYPosition");
	
	--按钮
	g_XiQu_Guide_Btn = XiQu_Guide_GoBtn
	
end


--===============================================Shuangdan_Huoguo_Guide

-- OnEvent()
--===============================================

function XiQu_Guide_OnEvent(event)
	if(event == "UI_COMMAND") then
		
		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 99812001 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				this:Show()
			elseif param == 2 then
				XiQu_Guide_FindNPC()
			elseif param == 0 then
				XiQu_Guide_Close()
				return				
			end
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		XiQu_Guide_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		XiQu_Guide_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		XiQu_Guide_Close()
	end
end

function XiQu_Guide_FindNPC(id)
	AutoRuntoTargetExWithName(g_XiQu_Guide_NPCPosX, g_XiQu_Guide_NPCPosZ, 0, g_XiQu_Guide_Name)
	XiQu_Guide_Close()
end


function XiQu_Guide_Goto(id)	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGuideGoto")
		Set_XSCRIPT_ScriptID(998120)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function XiQu_Guide_Close()
	XiQu_Guide_OnHide()
end

function XiQu_Guide_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenHelp")
		Set_XSCRIPT_ScriptID(998120)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--===============================================
-- OnHiden
--===============================================
function XiQu_Guide_OnHide()

	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function XiQu_Guide_Frame_On_ResetPos()
	XiQu_Guide_Frame : SetProperty("UnifiedXPosition", g_XiQu_Guide_Frame_UnifiedXPosition);
	XiQu_Guide_Frame : SetProperty("UnifiedYPosition", g_XiQu_Guide_Frame_UnifiedYPosition);
end
