-- 
local g_TuanyuanyanEnter_Frame_UnifiedXPosition;
local g_TuanyuanyanEnter_UnifiedYPosition;


function SpringFestival_TuanyuanyanEnter_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function SpringFestival_TuanyuanyanEnter_OnLoad()

	g_TuanyuanyanEnter_UnifiedXPosition = SpringFestival_TuanyuanyanEnter_Frame_BK:GetProperty("UnifiedXPosition");
	g_TuanyuanyanEnter_UnifiedYPosition = SpringFestival_TuanyuanyanEnter_Frame_BK:GetProperty("UnifiedYPosition");
		
end

function SpringFestival_TuanyuanyanEnter_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		SpringFestival_TuanyuanyanEnter_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_TuanyuanyanEnter_ResetPos()	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SpringFestival_TuanyuanyanEnter_OnHide()	
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89266002) then 
		this:Show()		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89266001) then
		AutoRunToTargetEx(256, 285, 0)	
		PushDebugMessage("#{RACL_181206_654}")	
		SpringFestival_TuanyuanyanEnter_OnHide()	
	end
	
end

function SpringFestival_TuanyuanyanEnter_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GoToTYYNPC" );
		Set_XSCRIPT_ScriptID( 892660 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()	
end

function SpringFestival_TuanyuanyanEnter_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowTYYHelp" );
		Set_XSCRIPT_ScriptID( 892660 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()	
end

function SpringFestival_TuanyuanyanEnter_OnHide()	
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SpringFestival_TuanyuanyanEnter_ResetPos()
	SpringFestival_TuanyuanyanEnter_Frame_BK:SetProperty("UnifiedXPosition", g_TuanyuanyanEnter_UnifiedXPosition);
	SpringFestival_TuanyuanyanEnter_Frame_BK:SetProperty("UnifiedYPosition", g_TuanyuanyanEnter_UnifiedYPosition);
end
