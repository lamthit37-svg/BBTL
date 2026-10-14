local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_Targetid = -1
local g_Object = -1
local objCared = -1


function LanghuanQuest_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 打开城战结果界面
	this:RegisterEvent("OPEN_BATTLE_RESULT_UI")

	this:RegisterEvent("UI_COMMAND");

end

function LanghuanQuest_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= LanghuanQuest_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= LanghuanQuest_Frame:GetProperty("UnifiedYPosition");


end

function LanghuanQuest_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		LanghuanQuest_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		LanghuanQuest_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89180204 then
		g_Targetid = Get_XParam_INT(0)

		objCared = -1;
		local tempID = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(tempID);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end

		LanghuanQuest_BeginCareObject(objCared)

		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89180205 then
		this:Hide()
	end
--	elseif (event == "OPEN_BATTLE_RESULT_UI" ) then
--		if (this:IsVisible()) then
--			this:Hide()
--		else
--			KVKLeague_ChengZhan_JieGuo_RefreshData(  )
--			this:Show()
--		end
--	end
end



--================================================
-- 恢复界面的默认相对位置
--================================================
function LanghuanQuest_ResetPos()
	LanghuanQuest_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	LanghuanQuest_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 关闭当前界面
--================================================
function LanghuanQuest_OnHiden()
	g_Targetid = -1
	g_Object = -1
	objCared = -1
	LanghuanQuest_StopCareObject()
	this:Hide()
end

function LanghuanQuest_Closed()
	this:Hide()
end

function LanghuanQuest_open_Clicked()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SetMissionComplete" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 891802 );						-- 脚本编号
	--	Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
		Set_XSCRIPT_Parameter(0,g_Targetid);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT()

end

--=========================================================
--开始关心NPC
--=========================================================
function LanghuanQuest_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "LanghuanQuest");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "LanghuanQuest")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function LanghuanQuest_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "LanghuanQuest");
		g_Object = -1;
	end
end

