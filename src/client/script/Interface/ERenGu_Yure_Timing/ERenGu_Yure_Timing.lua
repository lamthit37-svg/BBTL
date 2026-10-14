--ERenGu_Yure_Timing
local g_ERenGu_Yure_Timing_UnifiedPosition;
local g_ERenGu_Yure_Timing_UICOMMAND = 99939103;
local g_ERenGu_Yure_Timing_CloseUI_UICOMMAND = 99939104;
local g_ERenGu_Yure_Timing_LeftTime = 0;
function ERenGu_Yure_Timing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

function ERenGu_Yure_Timing_OnLoad()
	g_ERenGu_Yure_Timing_UnifiedPosition=ERenGu_Yure_Timing_Frame:GetProperty("UnifiedPosition")
	
end

function ERenGu_Yure_Timing_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_ERenGu_Yure_Timing_UICOMMAND ) then
		g_ERenGu_Yure_Timing_LeftTime   = Get_XParam_INT(0)
		if g_ERenGu_Yure_Timing_LeftTime == 0 then
			ERenGu_Yure_Timing_TikTok_Text:SetText( ScriptGlobal_Format( "#{ERYR_240701_322}", "0","00" ) )
			ERenGu_Yure_Timing_TikTok_Text:Show()
			PushDebugMessage("#{ERYR_240701_319}")
		else
			ERenGu_Yure_Timing_TikTok_Text:Hide()
			ERenGu_Yure_Timing_TikTok : SetProperty("Timer",tostring(g_ERenGu_Yure_Timing_LeftTime));
			ERenGu_Yure_Timing_TikTok : Show();
		end
		this:Show()
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_ERenGu_Yure_Timing_CloseUI_UICOMMAND ) then
		ERenGu_Yure_Timing_OnHide()
	end	
	if (event == "ADJEST_UI_POS") then
		ERenGu_Yure_Timing_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		ERenGu_Yure_Timing_On_ResetPos()
		return
	end

end

function ERenGu_Yure_Timing_TimeOut()
	ERenGu_Yure_Timing_TikTok_Text:SetText( ScriptGlobal_Format( "#{ERYR_240701_322}", "0","00" ) )
	ERenGu_Yure_Timing_TikTok_Text:Show()
		PushDebugMessage("#{ERYR_240701_319}")

end

function ERenGu_Yure_Timing_On_ResetPos()
  ERenGu_Yure_Timing_Frame:SetProperty("UnifiedPosition", g_ERenGu_Yure_Timing_UnifiedPosition);
end

function ERenGu_Yure_Timing_OnHide()
	if (IsWindowShow("ERenGu_Yure_Timing")) then
		KillTimer( "ERenGu_Yure_Timing_ApproveTimerProc()" );
		this:Hide()
	end
end