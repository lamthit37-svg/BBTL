-- !!!reloadscript =MonthPVP_RestMini
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_RestMini_PreLoad()
	this:RegisterEvent("PVPCAR_UIOP", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_RestMini_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= MonthPVP_RestMini_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= MonthPVP_RestMini_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_RestMini_ResetPos()
	MonthPVP_RestMini_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	MonthPVP_RestMini_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_RestMini_OnEvent(event)
	if (event == "PVPCAR_UIOP") then
		local opType = tonumber(arg0) 
		if opType == 2 then
			if (this:IsVisible()) then
				return
			end
			MonthPVP_RestMini_Show()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		MonthPVP_RestMini_Hide()
	elseif event == "ADJEST_UI_POS" then
		MonthPVP_RestMini_ResetPos()
	end
end

--显示UI
function MonthPVP_RestMini_Show()
	MonthPVP_RestMini_ClearData()
	this:Show()
	
end
--隐藏UI
function MonthPVP_RestMini_Hide()

	MonthPVP_RestMini_ClearData()

	this:Hide()
end

--清除数据
function MonthPVP_RestMini_ClearData()
end
--更新
function MonthPVP_RestMini_Update()
end
--##############点击事件##############
function MonthPVP_RestMini_OnClose()
	PushEvent("PVPCAR_UIOP", 1)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("RestUIOp");
		Set_XSCRIPT_ScriptID(820022);
		Set_XSCRIPT_Parameter(0,2);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	MonthPVP_RestMini_Hide()
end
--####################################