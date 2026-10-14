--******************************************************************************
-- 入口界面
--******************************************************************************
local g_Frozen_Entry_Frame_UnifiedXPosition;
local g_Frozen_Entry_Frame_UnifiedYPosition;

--UI
local g_Frozen_Entry_Btn  --按钮

--NPC
local g_Frozen_Entry_NPCPosX = 109
local g_Frozen_Entry_NPCPosZ = 251
local g_Frozen_Entry_SceneId = 1007
local g_Frozen_Entry_Name = "赵冰清"

--===============================================
-- OnLoad()
--===============================================
function Frozen_Entry_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function Frozen_Entry_OnLoad()

	-- 保存界面的默认相对位置
	g_Frozen_Entry_Frame_UnifiedXPosition = Frozen_Entry_Frame_BK:GetProperty("UnifiedXPosition");
	g_Frozen_Entry_Frame_UnifiedYPosition = Frozen_Entry_Frame_BK:GetProperty("UnifiedYPosition");
	
end


--===============================================Frozen_Entry

-- OnEvent()
--===============================================

function Frozen_Entry_OnEvent(event)
	if(event == "UI_COMMAND") then
		
		local arg = tonumber(arg0)
		
		--打开界面
		if arg == 99949601 then
			local param = Get_XParam_INT(0)
			if param == 1 then
				this:Show()
			elseif param == 2 then
				Frozen_Entry_FindNPC()
			else
				Frozen_Entry_Close()
			end
		end
		return
	end


	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS"  and this:IsVisible()) then
		Frozen_Entry_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()) then
		Frozen_Entry_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Frozen_Entry_Close()
	end
end

function Frozen_Entry_FindNPC(id)
	AutoRuntoTargetExWithName(g_Frozen_Entry_NPCPosX, g_Frozen_Entry_NPCPosZ, g_Frozen_Entry_SceneId, g_Frozen_Entry_Name)
	Frozen_Entry_Close()
end


function Frozen_Entry_OnClickedGoto()	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGoto")
		Set_XSCRIPT_ScriptID(999496)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Frozen_Entry_Close()
	Frozen_Entry_OnHiden()
end

function Frozen_Entry_OnClickedHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenHelp")
		Set_XSCRIPT_ScriptID(999496)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--===============================================
-- OnHiden
--===============================================
function Frozen_Entry_OnHiden()

	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Entry_Frame_On_ResetPos()
	Frozen_Entry_Frame_BK : SetProperty("UnifiedXPosition", g_Frozen_Entry_Frame_UnifiedXPosition);
	Frozen_Entry_Frame_BK : SetProperty("UnifiedYPosition", g_Frozen_Entry_Frame_UnifiedYPosition);
end
