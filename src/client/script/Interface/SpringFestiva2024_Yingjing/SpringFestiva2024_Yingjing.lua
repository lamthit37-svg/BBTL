--******************************************************************************
-- 倒计时界面
--******************************************************************************
local g_SpringFestiva2024_Yingjing_Frame_UnifiedXPosition;
local g_SpringFestiva2024_Yingjing_Frame_UnifiedYPosition;

g_SpringFestiva2024_Yingjing_NPC_PosX = 286;
g_SpringFestiva2024_Yingjing_NPC_PosZ = 270;
g_SpringFestiva2024_Yingjing_NPC_Scene = 0;
g_SpringFestiva2024_Yingjing_NPC_Name = "雪小悠";


--===============================================
-- OnLoad();
--===============================================
function SpringFestiva2024_Yingjing_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function SpringFestiva2024_Yingjing_OnLoad()

	-- 保存界面的默认相对位置
	g_SpringFestiva2024_Yingjing_Frame_UnifiedXPosition = SpringFestiva2024_Yingjing_Frame:GetProperty("UnifiedXPosition");
	g_SpringFestiva2024_Yingjing_Frame_UnifiedYPosition = SpringFestiva2024_Yingjing_Frame:GetProperty("UnifiedYPosition");


end


--===============================================
-- OnEvent();
--===============================================

function SpringFestiva2024_Yingjing_OnEvent(event)
	if(event == "UI_COMMAND") then
		local arg = tonumber(arg0)
		--打开界面
		if arg == 99896501 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				this:Show()
			elseif param == 2 then
				SpringFestiva2024_Yingjing_FindNPC()
			elseif param == 0 then
				SpringFestiva2024_Yingjing_Close()
				return
			end
		end
		return
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		SpringFestiva2024_Yingjing_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		SpringFestiva2024_Yingjing_Frame_On_ResetPos();
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SpringFestiva2024_Yingjing_Frame_On_ResetPos()
	SpringFestiva2024_Yingjing_Frame : SetProperty("UnifiedXPosition", g_SpringFestiva2024_Yingjing_Frame_UnifiedXPosition);
	SpringFestiva2024_Yingjing_Frame : SetProperty("UnifiedYPosition", g_SpringFestiva2024_Yingjing_Frame_UnifiedYPosition);
end

function SpringFestiva2024_Yingjing_FindNPC()
	AutoRuntoTargetExWithName(g_SpringFestiva2024_Yingjing_NPC_PosX, g_SpringFestiva2024_Yingjing_NPC_PosZ, 0, g_SpringFestiva2024_Yingjing_NPC_Name);
	SpringFestiva2024_Yingjing_Close()
end


function SpringFestiva2024_Yingjing_Close()
	this:Hide();
end

--================================================
-- 问号提示
--================================================
function SpringFestiva2024_Yingjing_OnClickedHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenHelp")
		Set_XSCRIPT_ScriptID(998965)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--**********************************
--寻路去npc
--**********************************
function SpringFestiva2024_Yingjing_OnClickedBtn()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGuideGoto")
		Set_XSCRIPT_ScriptID(998965)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end