
local g_strTargetSceneName = nil;
local g_waiting = false;

function SceneTrans_PreLoad()
	this:RegisterEvent("PLAYER_LEAVE_WORLD",true);
	this:RegisterEvent("SCENE_TRANSED",false);
	this:RegisterEvent("ON_SCENE_TRANSING",false);
	this:RegisterEvent("UI_COMMAND",true)
end

function SceneTrans_OnLoad()

end

function SceneTrans_KillBieYeWaiting()
	g_waiting = false
	KillTimer("SceneTrans_CloseBieYeWaitingHandler()")
	DataPool:SetCanUseHotKey(1)
end

function SceneTrans_SetBieYeWaiting()
	g_waiting = true
	SceneTrans_TargetScene:SetText( "#{JYGZ_160809_265}" )
	DataPool:SetCanUseHotKey(0)
	SetTimer( "WuhunQuest", "SceneTrans_CloseBieYeWaitingHandler()", 1000 * 10 )
end

function SceneTrans_OnEvent(event)
	if ( event == "PLAYER_LEAVE_WORLD" ) then
		SceneTrans_KillBieYeWaiting()
		g_strTargetSceneName = arg0;
		SceneTrans_TargetScene:SetText("前往" .. g_strTargetSceneName);
		this:Show();
	elseif( event == "ON_SCENE_TRANSING") then
		SceneTrans_KillBieYeWaiting()
		if(this:IsVisible()) then
			SceneTrans_TargetScene:SetText("前往" .. g_strTargetSceneName .. "[" .. tostring(arg0) .. "]");
		end
	elseif ( event == "SCENE_TRANSED" ) then
		SceneTrans_KillBieYeWaiting()
		this:Hide();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89187003 ) then
		local bOpen = Get_XParam_INT(0)
		if bOpen ~= 1 and g_waiting then
			SceneTrans_KillBieYeWaiting()
			this:Hide()
			return
		elseif bOpen == 1 and not g_waiting then
			SceneTrans_SetBieYeWaiting()
			this:Show()
			return
		end
	end
end

function SceneTrans_CloseBieYeWaitingHandler()
	SceneTrans_KillBieYeWaiting()
	this:Hide()
end
