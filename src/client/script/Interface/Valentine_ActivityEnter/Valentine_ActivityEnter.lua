local g_Valentine_ActivityEnter_Frame_UnifiedXPosition
local g_Valentine_ActivityEnter_Frame_UnifiedYPosition
local g_SuShi_PosX = 181
local g_SuShi_PosZ = 107
local g_SuShi_Scene = 164
local g_SuShi_Name = "秦玫"

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Valentine_ActivityEnter_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Valentine_ActivityEnter_OnLoad()
	-- 保存界面的默认相对位置
	g_Valentine_ActivityEnter_Frame_UnifiedXPosition	= Valentine_ActivityEnter_Frame_BK:GetProperty("UnifiedXPosition");
	g_Valentine_ActivityEnter_Frame_UnifiedYPosition	= Valentine_ActivityEnter_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Valentine_ActivityEnter_ResetPos()
	Valentine_ActivityEnter_Frame_BK:SetProperty("UnifiedXPosition", g_Valentine_ActivityEnter_Frame_UnifiedXPosition);
	Valentine_ActivityEnter_Frame_BK:SetProperty("UnifiedYPosition", g_Valentine_ActivityEnter_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Valentine_ActivityEnter_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 99836601 then
		--打开界面
		Valentine_ActivityEnter_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99836602 then
		--前往寻路
		AutoRuntoTargetExWithName(g_SuShi_PosX, g_SuShi_PosZ, g_SuShi_Scene, g_SuShi_Name)
		Valentine_ActivityEnter_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Valentine_ActivityEnter_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Valentine_ActivityEnter_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Valentine_ActivityEnter_ResetPos()
	end
end

--显示UI
function Valentine_ActivityEnter_Show()

	this:Show()
end

--隐藏UI
function Valentine_ActivityEnter_OnHide()
	this:Hide()
end

--关闭界面
function Valentine_ActivityEnter_Hide()
	this:Hide()
end


function Valentine_ActivityEnter_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Help")
		Set_XSCRIPT_ScriptID(998366)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Valentine_ActivityEnter_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GOTO")
		Set_XSCRIPT_ScriptID(998366)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


