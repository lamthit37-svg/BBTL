local g_InfoBrowser_Pseudo_Frame_UnifiedXPosition = 0
local g_InfoBrowser_Pseudo_Frame_UnifiedYPosition = 0

function InfoBrowser_Pseudo_PreLoad()

	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function InfoBrowser_Pseudo_OnLoad()
 g_InfoBrowser_Pseudo_Frame_UnifiedXPosition = InfoBrowser_Pseudo_Frame:GetProperty("UnifiedXPosition")
 g_InfoBrowser_Pseudo_Frame_UnifiedYPosition = InfoBrowser_Pseudo_Frame:GetProperty("UnifiedYPosition")
end

function InfoBrowser_Pseudo_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		InfoBrowser_Pseudo_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		InfoBrowser_Pseudo_ResetPos()	
	elseif(event == "UI_COMMAND" ) then
		if arg0 == "890902" then
			InfoBrowser_Pseudo_OnUICommand()
		end
	end
end

function InfoBrowser_Pseudo_ResetPos()
	InfoBrowser_Pseudo_Frame : SetProperty("UnifiedXPosition", g_InfoBrowser_Pseudo_Frame_UnifiedXPosition);
	InfoBrowser_Pseudo_Frame : SetProperty("UnifiedYPosition", g_InfoBrowser_Pseudo_Frame_UnifiedYPosition);
end

function InfoBrowser_Pseudo_OnUICommand()
	
	InfoBrowser_Pseudo_Time:SetText("#{BXJH_140815_102}"..DataPool:GetFormatTimeString())
	this:Show()

end


