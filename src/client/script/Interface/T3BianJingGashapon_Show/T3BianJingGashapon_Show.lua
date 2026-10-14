local g_T3BianJingGashapon_Show_UnifiedPosition

function T3BianJingGashapon_Show_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function T3BianJingGashapon_Show_OnLoad()	
	g_T3BianJingGashapon_Show_UnifiedPosition = T3BianJingGashapon_Show_Frame:GetProperty("UnifiedPosition")
end

function T3BianJingGashapon_Show_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88820603 ) then
		this:Show()
		this:Activate()
	elseif (event == "ADJEST_UI_POS" ) then
		T3BianJingGashapon_Show_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		T3BianJingGashapon_Show_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function T3BianJingGashapon_Show_On_ResetPos()
	T3BianJingGashapon_Show_Frame:SetProperty("UnifiedPosition", g_T3BianJingGashapon_Show_UnifiedPosition);
end

function T3BianJingGashapon_Show_Close()
	this:Hide()
end

