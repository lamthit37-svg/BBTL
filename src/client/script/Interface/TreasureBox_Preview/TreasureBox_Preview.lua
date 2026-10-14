local g_TreasureBox_Preview_UnifiedPosition

function TreasureBox_Preview_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function TreasureBox_Preview_OnLoad()	
	g_TreasureBox_Preview_UnifiedPosition = TreasureBox_Preview_Frame:GetProperty("UnifiedPosition")
end

function TreasureBox_Preview_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88819003 ) then
		TreasureBox_Preview_DragTitle:SetText("#{RCLS_200731_167}")
		TreasureBox_Preview_FrameImage:SetProperty( "Image", "set:Qiongzhenge image:Fensetaozhuang" )
		this:Show()
		this:Activate()
	--elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88819006 ) then
	--	TreasureBox_Preview_DragTitle:SetText("#{RCLS_200731_168}")
	--	TreasureBox_Preview_FrameImage:SetProperty( "Image", "set:LLZBG03 image:LLZBG_HSWQ" )
	--	this:Show()
	--	this:Activate()
	elseif (event == "ADJEST_UI_POS" ) then
		TreasureBox_Preview_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TreasureBox_Preview_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function TreasureBox_Preview_On_ResetPos()
	TreasureBox_Preview_Frame:SetProperty("UnifiedPosition", g_TreasureBox_Preview_UnifiedPosition);
end

function TreasureBox_Preview_Close()
	this:Hide()
end

