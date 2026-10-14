--******************************************************************************
-- 入口界面
--******************************************************************************
local g_ShuangDan_Huoguo_Guide_Frame_UnifiedXPosition;
local g_ShuangDan_Huoguo_Guide_Frame_UnifiedYPosition;

--UI
local g_ShuangDan_Huoguo_Guide_Btn  --按钮

--NPC
local g_ShuangDan_Huoguo_Guide_NPCPosX = 311
local g_ShuangDan_Huoguo_Guide_NPCPosZ = 269
local g_ShuangDan_Huoguo_Guide_Name = "郝有味"

--===============================================
-- OnLoad()
--===============================================
function ShuangDan_Huoguo_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function ShuangDan_Huoguo_Guide_OnLoad()

	-- 保存界面的默认相对位置
	g_ShuangDan_Huoguo_Guide_Frame_UnifiedXPosition = ShuangDan_Huoguo_Guide_Frame:GetProperty("UnifiedXPosition");
	g_ShuangDan_Huoguo_Guide_Frame_UnifiedYPosition = ShuangDan_Huoguo_Guide_Frame:GetProperty("UnifiedYPosition");
	
	--按钮
	g_ShuangDan_Huoguo_Guide_Btn = ShuangDan_Huoguo_Guide_Goto
	
end


--===============================================Shuangdan_Huoguo_Guide

-- OnEvent()
--===============================================

function ShuangDan_Huoguo_Guide_OnEvent(event)
	if(event == "UI_COMMAND") then
		
		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 88881201 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				this:Show()
			elseif param == 2 then
				ShuangDan_Huoguo_Guide_FindNPC()
			elseif param == 0 then
				ShuangDan_Huoguo_Guide_Close()
				return				
			end
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		ShuangDan_Huoguo_Guide_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		ShuangDan_Huoguo_Guide_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ShuangDan_Huoguo_Guide_Close()
	end
end

function ShuangDan_Huoguo_Guide_FindNPC(id)
	AutoRuntoTargetExWithName(g_ShuangDan_Huoguo_Guide_NPCPosX, g_ShuangDan_Huoguo_Guide_NPCPosZ, 0, g_ShuangDan_Huoguo_Guide_Name)
	ShuangDan_Huoguo_Guide_Close()
end


function ShuangDan_Huoguo_Guide_Goto_Click(id)	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGuideGoto")
		Set_XSCRIPT_ScriptID(888812)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ShuangDan_Huoguo_Guide_Close()
	ShuangDan_Huoguo_Guide_OnHiden()
end

function ShuangDan_Huoguo_Guide_OnClickedHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenHelp")
		Set_XSCRIPT_ScriptID(888812)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--===============================================
-- OnHiden
--===============================================
function ShuangDan_Huoguo_Guide_OnHiden()

	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ShuangDan_Huoguo_Guide_Frame_On_ResetPos()
	ShuangDan_Huoguo_Guide_Frame : SetProperty("UnifiedXPosition", g_ShuangDan_Huoguo_Guide_Frame_UnifiedXPosition);
	ShuangDan_Huoguo_Guide_Frame : SetProperty("UnifiedYPosition", g_ShuangDan_Huoguo_Guide_Frame_UnifiedYPosition);
end
