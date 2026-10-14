local g_Expansion_Grade_YindaoLetter_Frame_UnifiedXPosition
local g_Expansion_Grade_YindaoLetter_Frame_UnifiedYPosition

local g_Target_PosX = 100
local g_Target_PosZ = 102
local g_Target_Scene = 2
local g_Target_Name = "萧峰"


--预加载函数，可以而且只能在这里注册脚本关心的事件
function Expansion_Grade_YindaoLetter_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Expansion_Grade_YindaoLetter_OnLoad()
	-- 保存界面的默认相对位置
	g_Expansion_Grade_YindaoLetter_Frame_UnifiedXPosition	= Expansion_Grade_YindaoLetter_Frame:GetProperty("UnifiedXPosition");
	g_Expansion_Grade_YindaoLetter_Frame_UnifiedYPosition	= Expansion_Grade_YindaoLetter_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Expansion_Grade_YindaoLetter_ResetPos()
	Expansion_Grade_YindaoLetter_Frame:SetProperty("UnifiedXPosition", g_Expansion_Grade_YindaoLetter_Frame_UnifiedXPosition);
	Expansion_Grade_YindaoLetter_Frame:SetProperty("UnifiedYPosition", g_Expansion_Grade_YindaoLetter_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Expansion_Grade_YindaoLetter_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 99974402 then
		--打开界面
		Expansion_Grade_YindaoLetter_Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99974403 then
		--前往寻路
		AutoRuntoTargetExWithName(g_Target_PosX, g_Target_PosZ, g_Target_Scene, g_Target_Name)
		Expansion_Grade_YindaoLetter_OnHide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Expansion_Grade_YindaoLetter_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Expansion_Grade_YindaoLetter_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Expansion_Grade_YindaoLetter_ResetPos()
	end
end

--显示UI
function Expansion_Grade_YindaoLetter_Show()
	this:Show()
end

--隐藏UI
function Expansion_Grade_YindaoLetter_OnHide()
	this:Hide()
end

--关闭界面
function Expansion_Grade_YindaoLetter_OnClose()
	this:Hide()
end

function Expansion_Grade_YindaoLetter_OnGoButtonClicked()
	local nLevel = Player:GetLevel();
    if nLevel < 119  then        
		PushDebugMessage("#{KDJYD_250814_03}")
		return
    end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GoTo")
		Set_XSCRIPT_ScriptID(999744)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

