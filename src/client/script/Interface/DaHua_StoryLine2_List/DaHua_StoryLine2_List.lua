
-- 界面的默认相对位置
local g_DaHua_StoryLine2_List_Frame_UnifiedXPosition;
local g_DaHua_StoryLine2_List_Frame_UnifiedYPosition;

local g_DaHua_StoryLine2_List_LastMission = 3054

local g_TargetId = -1

function DaHua_StoryLine2_List_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_FAKE_OBJECT")
end

function DaHua_StoryLine2_List_OnLoad()

	-- 保存界面的默认相对位置
	g_DaHua_StoryLine2_List_Frame_UnifiedXPosition	= DaHua_StoryLine2_List_Frame : GetProperty("UnifiedXPosition");
	g_DaHua_StoryLine2_List_Frame_UnifiedYPosition	= DaHua_StoryLine2_List_Frame : GetProperty("UnifiedYPosition");

end

function DaHua_StoryLine2_List_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0)==99916401 then
		local xx = Get_XParam_INT(0);
		if tonumber(xx) == 1 then
			g_TargetId = Get_XParam_INT(1);
			local ObjCared = DataPool:GetNPCIDByServerID(g_TargetId);
			if ObjCared==-1 then
				return
			end
			this:CareObject(ObjCared, 1, "DaHua_StoryLine2_List");

			if DataPool:Lua_IsHaveMission( g_DaHua_StoryLine2_List_LastMission ) > 0 then
				DaHua_StoryLine2_List_TextSelect:SetProperty("Image", "set:DaHua_StoryLine2_List2 image:DaHua_StoryLine2_List_over")
			else
				DaHua_StoryLine2_List_TextSelect:SetProperty("Image", "set:DaHua_StoryLine2_List2 image:DaHua_StoryLine2_List_continue")
			end
			this:Show()
		else
			this:Hide()
		end

	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		DaHua_StoryLine2_List_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		DaHua_StoryLine2_List_Frame_On_ResetPos()

	elseif (event == "CLOSE_DaHua_StoryLine2_List_DLG")	then
		DaHua_StoryLine2_List_OnHiden()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaHua_StoryLine2_List_Frame_On_ResetPos()

	DaHua_StoryLine2_List_Frame : SetProperty("UnifiedXPosition", g_DaHua_StoryLine2_List_Frame_UnifiedXPosition);
	DaHua_StoryLine2_List_Frame : SetProperty("UnifiedYPosition", g_DaHua_StoryLine2_List_Frame_UnifiedYPosition);

end

function DaHua_StoryLine2_List_Letter_Btn_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnPlanRead")
		Set_XSCRIPT_ScriptID(999164) 
		Set_XSCRIPT_Parameter(0, g_TargetId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	DaHua_StoryLine2_List_OnHiden()
end

function DaHua_StoryLine2_List_OnHiden()
	this:Hide()
end

function DaHua_StoryLine2_List_Help()
	PushEvent("QUEST_HELP_MSG", "#{DHEJ_240521_237}")
end