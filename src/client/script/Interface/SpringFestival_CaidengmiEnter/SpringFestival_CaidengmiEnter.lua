-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


function SpringFestival_CaidengmiEnter_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("YUANXIAO_DENGMI", true);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function SpringFestival_CaidengmiEnter_OnLoad()

	g_Frame_UnifiedXPosition = SpringFestival_CaidengmiEnter_Frame_BK:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = SpringFestival_CaidengmiEnter_Frame_BK:GetProperty("UnifiedYPosition");
		
end

function SpringFestival_CaidengmiEnter_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		SpringFestival_CaidengmiEnter_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_CaidengmiEnter_ResetPos()	
	elseif (event == "YUANXIAO_DENGMI")  then
		--2025元宵节猜灯谜-ypl
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(171) > 0 then  --卡级
			SpringFestival_CaidengmiEnter_Text:SetText("#{YXCDM_251210_02}")
		else
			SpringFestival_CaidengmiEnter_Text:SetText("#{YXCDM_220111_02}")
		end
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89238401) then
		AutoRuntoTargetExWithName(274, 341, 0, "蔡弥")
		PushDebugMessage("#{RACL_181206_658}")
		SpringFestival_CaidengmiEnter_OnHide()	
	end
end

function SpringFestival_CaidengmiEnter_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GoToNPC" );
		Set_XSCRIPT_ScriptID( 892384 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()	
end

function SpringFestival_CaidengmiEnter_ShowHelp()
	PushEvent("CCSHOP_HELP", 149)
end

function SpringFestival_CaidengmiEnter_OnHide()	
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SpringFestival_CaidengmiEnter_ResetPos()
	SpringFestival_CaidengmiEnter_Frame_BK:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	SpringFestival_CaidengmiEnter_Frame_BK:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end