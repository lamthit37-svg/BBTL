--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_TargetId = -1

function NoDiffMatch_Intro_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function NoDiffMatch_Intro_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Intro_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Intro_Frame:GetProperty("UnifiedYPosition");
end

function NoDiffMatch_Intro_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Intro_ResetPos()

	elseif event == "UI_COMMAND" then
	    if tonumber(arg0) ~= 8926942 then
	        return
	    end

		g_TargetId = Get_XParam_INT(0)
        local npcid = Target:GetServerId2ClientId(g_TargetId)
        if not npcid or npcid < 0 then
            return
        end
		this:CareObject(npcid, 1)

		NoDiffMatch_Intro_OnShow()

	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		NoDiffMatch_Intro_Hide()
	end
end

function NoDiffMatch_Intro_ResetPos()

	NoDiffMatch_Intro_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Intro_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);

end

function NoDiffMatch_Intro_OnShow()
	this:Show()
end

function NoDiffMatch_Intro_Hide()
	g_TargetId = -1
	this:Hide()
end

function NoDiffMatch_Intro_Help(index)
	if index<1 or index>3 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientAskNpcTalk")
		Set_XSCRIPT_ScriptID(892694)
		Set_XSCRIPT_Parameter(0,tonumber(g_TargetId));
		Set_XSCRIPT_Parameter(1,tonumber(index));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT()
end
