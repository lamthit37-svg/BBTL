local g_Dunhuang_Preview_UnifiedPosition

function Dunhuang_Preview_PreLoad()
	this:RegisterEvent("OPEN_WINDOW", true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function Dunhuang_Preview_OnLoad()	
	g_Dunhuang_Preview_UnifiedPosition = Dunhuang_Preview_Frame:GetProperty("UnifiedPosition")
end

function Dunhuang_Preview_OnEvent(event)
	if ( event == "OPEN_WINDOW" and arg0 == "Dunhuang_Preview" ) then
		this:Activate()
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		Dunhuang_Preview_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Dunhuang_Preview_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function Dunhuang_Preview_On_ResetPos()
	Dunhuang_Preview_Frame:SetProperty("UnifiedPosition", g_Dunhuang_Preview_UnifiedPosition);
end

function Dunhuang_Preview_Close()
	this:Hide()
end

