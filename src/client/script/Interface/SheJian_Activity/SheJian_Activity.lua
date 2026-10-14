-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


function SheJian_Activity_PreLoad()

	this:RegisterEvent("SHENSHE_ACTIVITY", true);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function SheJian_Activity_OnLoad()

	g_Frame_UnifiedXPosition	= SheJian_Activity_Frame_BK:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= SheJian_Activity_Frame_BK:GetProperty("UnifiedYPosition");
		
end

function SheJian_Activity_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		SheJian_Activity_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SheJian_Activity_ResetPos()	
	elseif event == "SHENSHE_ACTIVITY"  then
		this:Show()
		if KaJi:LuaFnIsKaJiServer() == 1 then
			SheJian_Activity_Text:SetText("#{YXSJ_251205_04}")
		else
			SheJian_Activity_Text:SetText("#{YXSJ_220107_02}")
		end
	end
end



function SheJian_Activity_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GoToNPC" );
		Set_XSCRIPT_ScriptID( 893021 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()	
	PushDebugMessage("#{RACL_181206_657}")
end




function SheJian_Activity_ShowHelp()
	PushEvent("CCSHOP_HELP", 148)
end

function SheJian_Activity_OnHiden()	
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SheJian_Activity_ResetPos()
	SheJian_Activity_Frame_BK:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	SheJian_Activity_Frame_BK:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end