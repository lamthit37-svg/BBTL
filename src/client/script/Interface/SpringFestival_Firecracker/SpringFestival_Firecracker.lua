local g_SpringFestival_Firecracker_UnifiedPosition

function SpringFestival_Firecracker_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_WINDOW", true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function SpringFestival_Firecracker_OnLoad()	
	g_SpringFestival_Firecracker_UnifiedPosition = SpringFestival_Firecracker_Frame:GetProperty("UnifiedPosition")
end

function SpringFestival_Firecracker_OnEvent(event)
	if ( event == "OPEN_WINDOW" and arg0 == "SpringFestival_Firecracker" ) then
		this:Activate()
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		SpringFestival_Firecracker_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_Firecracker_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89080301 ) then
		--寻路
		AutoRunToTargetEx(215, 275, 0)	
		PushDebugMessage("#{RACL_181206_680}")
	end
end

function SpringFestival_Firecracker_On_ResetPos()
	SpringFestival_Firecracker_Frame:SetProperty("UnifiedPosition", g_SpringFestival_Firecracker_UnifiedPosition);
end

function SpringFestival_Firecracker_Close()
	this:Hide()
end

function SpringFestival_Firecracker_GoToLY()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 890803 )
		Set_XSCRIPT_Function_Name( "OpenSPFUI" )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end
function SpringFestival_Firecracker_Text_HelpClk()
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(52) > 0 then 
		PushEvent("QUEST_HELP_MSG","#{LYYJKJ_211210_3}")
	else
		PushEvent("QUEST_HELP_MSG","#{LYYJ_181206_2}")
	end
end