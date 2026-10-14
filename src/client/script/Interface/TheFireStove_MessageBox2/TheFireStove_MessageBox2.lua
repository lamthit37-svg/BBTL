local g_TheFireStove_MessageBox2_Frame_UnifiedPosition
local Server_Script_Function = "";
local Server_Script_strPrint = "";
local Server_Script_ID = "";
local ObjCaredID = -1
local MAX_OBJ_DISTANCE = 3.0;

--===============================================
-- PreLoad()
--===============================================
function TheFireStove_MessageBox2_PreLoad()
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);--切场景
end

--===============================================
-- OnLoad()
--===============================================
function TheFireStove_MessageBox2_OnLoad()
	g_TheFireStove_MessageBox2_Frame_UnifiedPosition = TheFireStove_MessageBox2_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function TheFireStove_MessageBox2_OnEvent(event)
	
	-- 游戏分辨率发生了变化
	if (event == "ADJEST_UI_POS" ) then
		TheFireStove_MessageBox2_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TheFireStove_MessageBox2_Frame_On_ResetPos()
		--切场景
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		TheFireStove_MessageBox2_Cancel_Clicked()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= ObjCaredID) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			TheFireStove_MessageBox2_Cancel_Clicked()
		end
	elseif (event == "UI_COMMAND") then
		if (tonumber(arg0) == 20130819 ) then
			Server_Script_Function = Get_XParam_STR(0);
			Server_Script_strPrint = Get_XParam_STR(1);
			Server_Script_ID = Get_XParam_INT(0);
			TheFireStove_MessageBox2_Text:SetText(Get_XParam_STR(1))
			local xx = Get_XParam_INT(1);
			ObjCaredID = DataPool : GetNPCIDByServerID(xx);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "TheFireStove_MessageBox2");
			end
			this:Show()
		end
		if (tonumber(arg0) == 89092101 ) then
			Server_Script_Function = Get_XParam_STR(0);
			Server_Script_strPrint = Get_XParam_STR(1);
			Server_Script_ID = Get_XParam_INT(0);
			TheFireStove_MessageBox2_Text:SetText(Get_XParam_STR(1))
			local xx = Get_XParam_INT(1);
			ObjCaredID = DataPool : GetNPCIDByServerID(xx);
			if ObjCaredID ~= -1 then
				--开始关心NPC
				this:CareObject(ObjCaredID, 1, "TheFireStove_MessageBox2");
			end
			this:Show()
		end 
	end
end


--===============================================
-- 点击确定（IDOK）
--===============================================
function TheFireStove_MessageBox2_OK_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name(Server_Script_Function);
		Set_XSCRIPT_ScriptID(Server_Script_ID);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
		
	TheFireStove_MessageBox2_Cancel_Clicked()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function TheFireStove_MessageBox2_Frame_On_ResetPos()
	TheFireStove_MessageBox2_Frame:SetProperty("UnifiedPosition", g_TheFireStove_MessageBox2_Frame_UnifiedPosition);
end

--================================================
-- 帮助按钮
--================================================
function TheFireStove_MessageBox2_Help()
	Helper:GotoHelper("*TheFireStove_MessageBox2");
end

--================================================
-- 关闭
--================================================
function TheFireStove_MessageBox2_Cancel_Clicked()
	this:Hide();
	this:CareObject( ObjCaredID, 0, "TheFireStove_MessageBox2" )
end
