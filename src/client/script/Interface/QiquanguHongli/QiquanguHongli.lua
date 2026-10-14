local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_bagId = -1;

function QiquanguHongli_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function QiquanguHongli_OnEvent(event)
	if event == "UI_COMMAND"  and tonumber(arg0) == 20131024 then
		QiquanguHongli_OnShown()
	elseif( event == "ADJEST_UI_POS" ) then
		QiquanguHongli_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		QiquanguHongli_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function QiquanguHongli_OnLoad()
		-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= QiquanguHongli_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= QiquanguHongli_Frame:GetProperty("UnifiedYPosition");
		
end

function QiquanguHongli_OnShown()
	if g_bagId >=0 then
		LifeAbility : Lock_Packet_Item(g_bagId,0);
	end

	g_bagId = Get_XParam_INT(0);
	local ActiveCnt = Get_XParam_INT(1);
	local Hongli = Get_XParam_INT(2);
	local curTime = Get_XParam_INT(3);
	
	local tempstr = ScriptGlobal_Format( "#{QQG_20130902_17}", ActiveCnt, Hongli);
	QiquanguHongli_Text:SetText(tempstr);

	LifeAbility : Lock_Packet_Item(g_bagId,1);
	TodayCampaignList_SelectQQG:Show();
	if curTime >= 2013112500 and curTime <= 2013120124 then
		TodayCampaignList_GetQQG:Enable();
	else
		TodayCampaignList_GetQQG:Disable();
	end
	this:Show();
end

function QiquanguHongli_CheckQQG_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("CheckTrend");
		Set_XSCRIPT_ScriptID(890688);
		Set_XSCRIPT_Parameter(0, g_bagId);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function QiquanguHongli_GetQQG_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ReceiveHongli");
		Set_XSCRIPT_ScriptID(890688);
		Set_XSCRIPT_Parameter(0, g_bagId);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	this:Hide();
end
--================================================
-- 界面的默认相对位置
--================================================
function QiquanguHongli_ResetPos()
	QiquanguHongli_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	QiquanguHongli_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function QiquanguHongli_Close()
	LifeAbility : Lock_Packet_Item(g_bagId,0)
	this:Hide();
end