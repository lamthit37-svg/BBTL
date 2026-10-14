--!!!reloadscript =SpringFestival_CaiQiuEnter
local g_UnifiedPosition = ""

--=========
--PreLoad==
--=========
function SpringFestival_CaiQiuEnter_PreLoad()
	this:RegisterEvent("OPEN_CAIQIUENTER")
	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--=========
--OnLoad
--=========
function SpringFestival_CaiQiuEnter_OnLoad()
	g_UnifiedPosition = SpringFestival_CaiQiuEnter_Frame:GetProperty("UnifiedPosition")
end
--=========
--OnEvent
--=========
function SpringFestival_CaiQiuEnter_OnEvent(event)

	if event == "OPEN_CAIQIUENTER" then
		if tonumber(arg0)==0 and this:IsVisible() then
			this:Hide()
		else
			SpringFestival_CaiQiuEnter_OnShow()
		end	
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 89298009 ) then
		local bForceOpen = Get_XParam_INT( 0 );
		if bForceOpen == 1 then 
			SpringFestival_CaiQiuEnter_OnShow()
		else
			this:Hide()
		end
	end
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SpringFestival_CaiQiuEnter_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition)
	end

end

function SpringFestival_CaiQiuEnter_OnShow()
	this:Show()

	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(172) > 0 then
		SpringFestival_CaiQiuEnter_Text:SetText("#{KWCQ_251224_02}")
	else
		SpringFestival_CaiQiuEnter_Text:SetText("#{KWCQ_220106_02}")
	end
end

function SpringFestival_CaiQiuEnter_OnHide()
	this:Hide()
end

function SpringFestival_CaiQiuEnter_ShowHelp()
	PushEvent("CAIQIUENTER_OPEN_HELP")
end

function SpringFestival_CaiQiuEnter_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGotoDispatchNPC" );
		Set_XSCRIPT_ScriptID( 892980 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()

	this:Hide()
end